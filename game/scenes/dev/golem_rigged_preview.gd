extends Node3D
## Golem RIGGED preview — UniRig skinned mesh (golem_rigged.glb).
##
## ALIVE pass: per-limb bone animation (spine, L-arm, R-arm, head bob).
## bone_0..bone_27 anatomy (UniRig 28-bone output on our hunched stone golem):
##
##   bone_0       — root / pelvis (all others follow)
##   bone_1       — spine base
##   bone_2       — spine mid
##   bone_3       — spine upper / chest
##   bone_4       — neck / head base
##   bone_5       — head top
##   bone_6       — L shoulder / clavicle
##   bone_7       — L upper arm
##   bone_8       — L forearm
##   bone_9       — L wrist
##   bone_10      — L hand / fist (near ground — knuckle-drag)
##   bone_11      — L finger tip (optional leaf end)
##   bone_12      — R shoulder / clavicle
##   bone_13      — R upper arm
##   bone_14      — R forearm
##   bone_15      — R wrist
##   bone_16      — R hand / fist
##   bone_17      — R finger tip
##   bone_18..21  — L leg chain (hip → knee → ankle → toe)
##   bone_22..27  — R leg chain (NOTE: branches from L shin in UniRig output —
##                  will co-move with L leg; acceptable for idle/slam)
##
## Idle: staggered spine sway + L/R shoulder droop/rise + head bob.
## Attack: R arm slam (anticipation raise → crash down → hold → recover).
##         Spine leans into it. L arm stays relaxed.
##
## Controls:
##   Left-drag  = orbit camera
##   Mouse wheel = zoom
##   SPACE/RMB   = skip to next clip
##
## IMPORTANT: Disable "Embed Game on Play" in the Game panel so this opens in
## its own window and _place_window_on_2nd_screen() can move it.

const RIGGED_GLB     := "res://tools/blender/golem_rigged.glb"
const CHUNKS_GLB     := "res://assets/art/piso1_pradera/enemies/big/golem_dp_chunks_01.glb"
const TREE_GLB       := "res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_01.gltf"
const TOON_SHADER    := preload("res://scenes/levels/dp_toon_grounded.gdshader")
const OUTLINE_SHADER := preload("res://assets/art/shaders/toon_outline.gdshader")

const EYE_COLOR  := Color(0.373, 0.847, 1.0)   # #5FD8FF canon
const EYE_ENERGY := 1.6
# Warm desaturated stone — replaces the saturated green vertex-color look
const STONE_ALBEDO := Color(0.52, 0.50, 0.46)

# Target standing height in Godot units (meters)
const TARGET_HEIGHT_M := 4.8

# ---------------------------------------------------------------------------
# Bone index map (UniRig 28-bone output — confirmed by golem_bone_discover.gd)
# ---------------------------------------------------------------------------
# VERIFIED against golem_bone_discover.gd output (2026-06-14).
# bone_6..12 = L arm chain (shoulder→upper→forearm→wrist→fist→tip→tip_end)
# bone_13..19 = R arm chain (parent=bone_3, the spine upper)
# bone_20..23 = L leg; bone_24..27 = R leg (parent=bone_22, L shin — UniRig flaw)
const BONE_ROOT        := 0
const BONE_SPINE_BASE  := 1
const BONE_SPINE_MID   := 2
const BONE_SPINE_UPPER := 3   # parent of both shoulders (bone_6 and bone_13)
const BONE_HEAD_BASE   := 4
const BONE_HEAD_TOP    := 5
const BONE_L_SHOULDER  := 6
const BONE_L_UPPER_ARM := 7
const BONE_L_FOREARM   := 8
const BONE_L_WRIST     := 9
const BONE_L_FIST      := 10
# bone_11, 12 = L fingertips (knuckle near ground)
const BONE_R_SHOULDER  := 13  # CORRECTED: 13, not 12 (12 is L fingertip)
const BONE_R_UPPER_ARM := 14
const BONE_R_FOREARM   := 15
const BONE_R_WRIST     := 16
const BONE_R_FIST      := 17

# ---------------------------------------------------------------------------
# Floating ornament spring state
# ---------------------------------------------------------------------------
class OrnamentData:
	var node: Node3D
	var target_pos: Vector3
	var spring_pos: Vector3
	var spring_vel: Vector3
	const OMEGA := 5.5
	const ZETA  := 0.68

var _ornaments: Array = []
var _ornament_angle := 0.0

var _rig: Node3D          = null
var _skeleton: Skeleton3D = null
var _anim_player: AnimationPlayer = null

var _cam: Camera3D
var _target := Vector3(0.0, 2.8, 0.0)
var _yaw    := 0.7
var _pitch  := 0.18
var _dist   := 10.0
var _dragging := false

var _label: Label      = null
var _hint_label: Label = null
var _skip := false


# ---------------------------------------------------------------------------
# Window placement (2nd screen)
# ---------------------------------------------------------------------------
func _place_window_on_2nd_screen() -> void:
	if DisplayServer.get_screen_count() <= 1:
		return
	var primary := DisplayServer.get_primary_screen()
	for s in DisplayServer.get_screen_count():
		if s != primary:
			DisplayServer.window_set_current_screen(s)
			break


# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	_place_window_on_2nd_screen()
	_add_lights()
	_add_environment()
	_add_scale_reference()

	if not ResourceLoader.exists(RIGGED_GLB):
		push_error("golem_rigged_preview: rigged GLB not found: " + RIGGED_GLB)
		return

	var packed := load(RIGGED_GLB) as PackedScene
	if packed == null:
		push_error("golem_rigged_preview: failed to load PackedScene from " + RIGGED_GLB)
		return

	_rig = packed.instantiate() as Node3D
	_rig.name = "GolemRig"
	add_child(_rig)
	# UniRig merge exports with Blender Y-up → GLB Y-up, but the mesh was built
	# standing in Blender Z-up space. Apply -90° X to stand the rig upright.
	_rig.rotation_degrees.x = -90.0

	# Scale rig to TARGET_HEIGHT_M. Measure the GLB's Y extent from its AABB.
	_auto_scale_rig()

	# Find the Skeleton3D anywhere inside the rig
	_skeleton = _find_skeleton(_rig)
	if _skeleton == null:
		push_warning("golem_rigged_preview: no Skeleton3D found — per-limb animations disabled")

	# Apply stone toon materials (flat stone albedo — NO vertex color)
	_apply_toon_materials(_rig)

	# Build per-limb AnimationPlayer
	if _skeleton != null:
		_anim_player = _build_animations()

	# Attach tree to spine bone via BoneAttachment3D
	if _skeleton != null:
		_attach_tree()

	# Spawn floating rock ornaments
	_spawn_ornaments()

	# Camera
	_cam = Camera3D.new()
	_cam.fov = 65.0
	add_child(_cam)
	_cam.current = true

	_add_hud()

	# Wait a few frames for GLB import to settle
	for _i in range(30):
		await get_tree().process_frame

	if _anim_player != null:
		_anim_player.play("idle-loop")

	while is_inside_tree():
		await _run_preview_cycle()


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result != null:
			return result
	return null


# ---------------------------------------------------------------------------
# Auto-scale: measure AABB Y extent, compute uniform scale for TARGET_HEIGHT_M
# ---------------------------------------------------------------------------
func _auto_scale_rig() -> void:
	if _rig == null:
		return
	var aabb := AABB()
	var found := false
	for mi_node in _rig.find_children("*", "MeshInstance3D", true, false):
		var mi := mi_node as MeshInstance3D
		if mi.mesh == null:
			continue
		var local_aabb := mi.transform * mi.get_aabb()
		if not found:
			aabb = local_aabb
			found = true
		else:
			aabb = aabb.merge(local_aabb)

	if not found:
		push_warning("golem_rigged_preview: could not measure AABB, using scale=2.0")
		_rig.scale = Vector3.ONE * 2.0
		return

	# After -90°X rotation, the golem's standing height is in the Z dimension of
	# its local AABB (Blender Z-up → Godot Y-up via rig node rotation).
	# Use max of all dims to find the tall axis safely.
	var height := maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	if height < 0.01:
		_rig.scale = Vector3.ONE * 2.0
		return
	var scale_factor := TARGET_HEIGHT_M / height
	_rig.scale = Vector3.ONE * scale_factor
	print("[golem_preview] AABB max_dim=%.2f → scale=%.3f → target %.1fm" % [
		height, scale_factor, TARGET_HEIGHT_M
	])


# ---------------------------------------------------------------------------
# _process — camera orbit + ornament spring update
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if _cam != null:
		var off := Vector3(
			cos(_pitch) * sin(_yaw),
			sin(_pitch),
			cos(_pitch) * cos(_yaw)
		) * _dist
		_cam.position = _target + off
		_cam.look_at(_target, Vector3.UP)

	_ornament_angle += delta * 0.35

	if _rig == null:
		return
	# Ornaments orbit at shoulder height (~70% of target height)
	var base_world := _rig.global_position + Vector3(0.0, TARGET_HEIGHT_M * 0.70, 0.0)

	for i in range(_ornaments.size()):
		var od: OrnamentData = _ornaments[i]
		if od.node == null:
			continue
		var angle_offset := _ornament_angle + i * (TAU / float(maxi(_ornaments.size(), 1)))
		var radius := 1.1 + float(i) * 0.18
		var height_offset := 0.25 * float(i) - 0.25
		od.target_pos = base_world + Vector3(
			cos(angle_offset) * radius,
			height_offset,
			sin(angle_offset) * radius
		)
		var w  := OrnamentData.OMEGA
		var dw := 2.0 * OrnamentData.ZETA * w
		var force := -w * w * (od.spring_pos - od.target_pos) - dw * od.spring_vel
		od.spring_vel += force * delta
		od.spring_pos += od.spring_vel * delta
		od.node.global_position = od.spring_pos


# ---------------------------------------------------------------------------
# Input — orbit drag + zoom
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mbe := event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mbe.pressed
		if mbe.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = maxf(_dist - 0.5, 2.0)
		if mbe.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(_dist + 0.5, 25.0)
		if mbe.button_index == MOUSE_BUTTON_RIGHT and mbe.pressed:
			_skip = true
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.keycode == KEY_SPACE and ke.pressed:
			_skip = true
	if event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		_yaw   -= mm.relative.x * 0.01
		_pitch -= mm.relative.y * 0.01
		_pitch = clampf(_pitch, -1.2, 1.2)


# ---------------------------------------------------------------------------
# Preview cycle
# ---------------------------------------------------------------------------
func _run_preview_cycle() -> void:
	_set_label("idle-loop", "PER-LIMB idle: spine sway · L/R shoulder droop · head bob (staggered)")
	if _anim_player != null:
		_anim_player.play("idle-loop")
	await _wait(6.0)

	_set_label("attack", "R-ARM SLAM: anticipation raise → crash down → 2-frame freeze → recover")
	if _anim_player != null:
		_anim_player.play("attack")
	await _wait(3.0)


func _wait(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		if _skip:
			_skip = false
			return
		await get_tree().process_frame
		elapsed += get_process_delta_time()


func _set_label(clip_name: String, hint: String) -> void:
	if _label != null:
		_label.text = clip_name
	if _hint_label != null:
		_hint_label.text = hint


# ---------------------------------------------------------------------------
# AnimationPlayer — PER-LIMB bone tracks.
#
# The Skeleton3D rest pose has its own local coordinate system per bone.
# UniRig bones: all named bone_0..bone_27.
# Rotation conventions in rest pose (Blender Z-up, exported Y-up, then we
# rotate the rig node -90 X in Godot):
#   - Rotating a spine bone around local X = forward/backward lean
#   - Rotating a spine bone around local Z = side lean
#   - Rotating a shoulder bone around local Z (or X) = arm raise/lower
#   - Rotating an upper-arm bone around local Z = elbow flex
#
# We use small amplitudes: this is a STONE GOLEM breathing, not a human.
# The magic is the STAGGER: each bone's phase is offset so they don't peak
# simultaneously — that is what makes it read ALIVE vs a rigid block.
# ---------------------------------------------------------------------------
func _build_animations() -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	_rig.add_child(ap)
	ap.root_node = _rig.get_path()

	var lib := AnimationLibrary.new()
	var sp := str(_rig.get_path_to(_skeleton))  # e.g. "Armature/Skeleton3D"

	# ── IDLE — staggered per-limb breathing sway ───────────────────────────
	# Duration: 4 s, loops. All rotations are ADDITIVE to rest (small angles).
	# We express everything as local rotations around the bone's local axes.
	#
	# Phase offsets (in seconds) stagger the peaks:
	#   spine_base=0.0  spine_mid=0.3  spine_upper=0.6  head=0.9
	#   L_shoulder=0.5  R_shoulder=1.1
	#
	# Amplitudes (deg): spine 2-4°, head 3°, shoulders 5-7° (heavy droop)
	var idle := Animation.new()
	idle.length = 4.0
	idle.loop_mode = Animation.LOOP_LINEAR

	# Helper to add a looping sine-like Y-sway track on a bone.
	# peak_time: when the bone peaks at max_deg, valley at peak_time+half_period
	var _add_sway: Callable = func(anim: Animation, bone: int, axis: Vector3,
			max_deg: float, period: float, phase: float) -> void:
		var t := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(t, sp + ":bone_%d" % bone)
		var steps := 8
		for s in range(steps + 1):
			var time := float(s) * (anim.length / float(steps))
			# Sine wave: sin(2π*(time+phase)/period) * max_deg
			var angle_deg := max_deg * sin(TAU * (time + phase) / period)
			anim.rotation_track_insert_key(t, time, Quaternion(axis, deg_to_rad(angle_deg)))

	# Spine base — gentle forward-backward sway (X axis)
	_add_sway.call(idle, BONE_SPINE_BASE,  Vector3.RIGHT, 2.5,  4.0, 0.0)
	# Spine mid — slight side lean (Z axis), offset from base
	_add_sway.call(idle, BONE_SPINE_MID,   Vector3.BACK,  2.0,  4.0, 0.3)
	# Spine upper — forward lean, more pronounced (chest heave = "breathing")
	_add_sway.call(idle, BONE_SPINE_UPPER, Vector3.RIGHT, 3.0,  4.0, 0.6)
	# Head — subtle bob (opposite phase to spine for life)
	_add_sway.call(idle, BONE_HEAD_BASE,   Vector3.RIGHT, 3.5,  4.0, 0.9)

	# L shoulder droop/rise — heavy knuckle-drag arm sways slightly
	# Use Z axis (lateral) for shoulder droop
	_add_sway.call(idle, BONE_L_SHOULDER,  Vector3.BACK,  6.0,  4.0, 0.5)
	# L upper arm — slight swing (follows shoulder at lag)
	_add_sway.call(idle, BONE_L_UPPER_ARM, Vector3.BACK,  3.5,  4.0, 0.7)

	# R shoulder — opposite phase to L (contralateral rhythm)
	_add_sway.call(idle, BONE_R_SHOULDER,  Vector3.BACK,  6.0,  4.0, 1.1)
	# R upper arm
	_add_sway.call(idle, BONE_R_UPPER_ARM, Vector3.BACK,  3.5,  4.0, 1.3)

	lib.add_animation("idle-loop", idle)

	# ── ATTACK — R ARM SLAM with spine lean ────────────────────────────────
	# Timeline (1.8 s total):
	#   0.00  rest
	#   0.25  anticipation: R shoulder pulls BACK (-X), spine leans back
	#   0.55  crash: R shoulder swings DOWN+FORWARD hard (big +Z), R upper arm extends,
	#         spine lunges forward
	#   0.70  impact HOLD (2-frame freeze — peak positions, no change)
	#   1.80  recover smoothly to rest (long easing = weight settling)
	var atk := Animation.new()
	atk.length = 1.8
	atk.loop_mode = Animation.LOOP_NONE

	# Spine lean — leans back on anticipation, lunges forward on slam
	var t_sp := atk.add_track(Animation.TYPE_ROTATION_3D)
	atk.track_set_path(t_sp, sp + ":bone_%d" % BONE_SPINE_UPPER)
	atk.rotation_track_insert_key(t_sp, 0.00, Quaternion.IDENTITY)
	atk.rotation_track_insert_key(t_sp, 0.25, Quaternion(Vector3.RIGHT, deg_to_rad(-12.0)))  # lean back
	atk.rotation_track_insert_key(t_sp, 0.55, Quaternion(Vector3.RIGHT, deg_to_rad( 20.0)))  # lunge fwd
	atk.rotation_track_insert_key(t_sp, 0.70, Quaternion(Vector3.RIGHT, deg_to_rad( 22.0)))  # hold
	atk.rotation_track_insert_key(t_sp, 1.80, Quaternion.IDENTITY)

	# Also lean mid spine on the slam
	var t_sm := atk.add_track(Animation.TYPE_ROTATION_3D)
	atk.track_set_path(t_sm, sp + ":bone_%d" % BONE_SPINE_MID)
	atk.rotation_track_insert_key(t_sm, 0.00, Quaternion.IDENTITY)
	atk.rotation_track_insert_key(t_sm, 0.25, Quaternion(Vector3.RIGHT, deg_to_rad(-8.0)))
	atk.rotation_track_insert_key(t_sm, 0.55, Quaternion(Vector3.RIGHT, deg_to_rad(15.0)))
	atk.rotation_track_insert_key(t_sm, 0.70, Quaternion(Vector3.RIGHT, deg_to_rad(16.0)))
	atk.rotation_track_insert_key(t_sm, 1.80, Quaternion.IDENTITY)

	# R shoulder — anticipation BACK, then SLAM DOWN (large negative Z = downward)
	var t_rs := atk.add_track(Animation.TYPE_ROTATION_3D)
	atk.track_set_path(t_rs, sp + ":bone_%d" % BONE_R_SHOULDER)
	atk.rotation_track_insert_key(t_rs, 0.00, Quaternion.IDENTITY)
	atk.rotation_track_insert_key(t_rs, 0.25, Quaternion(Vector3.BACK, deg_to_rad(-25.0)))  # pull back/up
	atk.rotation_track_insert_key(t_rs, 0.55, Quaternion(Vector3.BACK, deg_to_rad( 45.0)))  # crash down
	atk.rotation_track_insert_key(t_rs, 0.70, Quaternion(Vector3.BACK, deg_to_rad( 48.0)))  # hold
	atk.rotation_track_insert_key(t_rs, 1.80, Quaternion.IDENTITY)

	# R upper arm — extends forward on slam (X axis = forward)
	var t_ra := atk.add_track(Animation.TYPE_ROTATION_3D)
	atk.track_set_path(t_ra, sp + ":bone_%d" % BONE_R_UPPER_ARM)
	atk.rotation_track_insert_key(t_ra, 0.00, Quaternion.IDENTITY)
	atk.rotation_track_insert_key(t_ra, 0.25, Quaternion(Vector3.RIGHT, deg_to_rad(-20.0)))  # pulls back
	atk.rotation_track_insert_key(t_ra, 0.55, Quaternion(Vector3.RIGHT, deg_to_rad( 35.0)))  # extends fwd+down
	atk.rotation_track_insert_key(t_ra, 0.70, Quaternion(Vector3.RIGHT, deg_to_rad( 38.0)))  # hold
	atk.rotation_track_insert_key(t_ra, 1.80, Quaternion.IDENTITY)

	# R forearm — slight extension (straightens on impact)
	var t_rf := atk.add_track(Animation.TYPE_ROTATION_3D)
	atk.track_set_path(t_rf, sp + ":bone_%d" % BONE_R_FOREARM)
	atk.rotation_track_insert_key(t_rf, 0.00, Quaternion.IDENTITY)
	atk.rotation_track_insert_key(t_rf, 0.55, Quaternion(Vector3.RIGHT, deg_to_rad(18.0)))
	atk.rotation_track_insert_key(t_rf, 0.70, Quaternion(Vector3.RIGHT, deg_to_rad(20.0)))
	atk.rotation_track_insert_key(t_rf, 1.80, Quaternion.IDENTITY)

	# L arm — stays relatively still (slight counter-swing for balance)
	var t_ls := atk.add_track(Animation.TYPE_ROTATION_3D)
	atk.track_set_path(t_ls, sp + ":bone_%d" % BONE_L_SHOULDER)
	atk.rotation_track_insert_key(t_ls, 0.00, Quaternion.IDENTITY)
	atk.rotation_track_insert_key(t_ls, 0.55, Quaternion(Vector3.BACK, deg_to_rad(-8.0)))  # slight counter-swing
	atk.rotation_track_insert_key(t_ls, 1.80, Quaternion.IDENTITY)

	lib.add_animation("attack", atk)

	ap.add_animation_library("", lib)
	return ap


# ---------------------------------------------------------------------------
# Tree attachment — BoneAttachment3D on BONE_SPINE_UPPER
# ---------------------------------------------------------------------------
func _attach_tree() -> void:
	if not ResourceLoader.exists(TREE_GLB):
		push_warning("golem_rigged_preview: tree GLB not found: " + TREE_GLB)
		return

	var ba := BoneAttachment3D.new()
	ba.bone_idx = BONE_SPINE_UPPER
	ba.bone_name = "bone_%d" % BONE_SPINE_UPPER
	_skeleton.add_child(ba)

	var tree_packed := load(TREE_GLB) as PackedScene
	if tree_packed == null:
		push_warning("golem_rigged_preview: failed to load tree GLB")
		return

	var tree := tree_packed.instantiate() as Node3D
	tree.name = "BackTree"
	ba.add_child(tree)

	# Small sapling growing from the golem's back — NOT a full-size tree.
	# bone-local space: back of spine is roughly +Z local after the -90X rig fix.
	tree.position = Vector3(-0.15, 0.05, 0.30)
	tree.rotation_degrees = Vector3(0.0, 15.0, -5.0)
	tree.scale = Vector3(0.18, 0.18, 0.18)  # sapling — clearly smaller than golem body

	# Teal foliage: material_override on every MeshInstance3D in the tree
	# Use material_override (NOT set_surface_override_material) so alpha-blend
	# leaves aren't silently ignored in Forward+.
	var foliage_mat := ShaderMaterial.new()
	foliage_mat.shader = TOON_SHADER
	foliage_mat.set_shader_parameter("albedo_color", Color(0.18, 0.55, 0.48))   # teal
	foliage_mat.set_shader_parameter("use_vertex_color", false)
	foliage_mat.set_shader_parameter("rim_intensity", 0.04)
	foliage_mat.set_shader_parameter("shadow_darkness", 0.32)

	var bark_mat := ShaderMaterial.new()
	bark_mat.shader = TOON_SHADER
	bark_mat.set_shader_parameter("albedo_color", Color(0.32, 0.25, 0.18))   # dark bark
	bark_mat.set_shader_parameter("use_vertex_color", false)
	bark_mat.set_shader_parameter("rim_intensity", 0.03)
	bark_mat.set_shader_parameter("shadow_darkness", 0.35)

	for mi_node in tree.find_children("*", "MeshInstance3D", true, false):
		var mi := mi_node as MeshInstance3D
		if mi.mesh == null:
			continue
		var name_lower := mi.name.to_lower()
		if name_lower.contains("leaf") or name_lower.contains("leaves") or name_lower.contains("foliage"):
			mi.material_override = foliage_mat
		elif name_lower.contains("bark") or name_lower.contains("trunk") or name_lower.contains("branch"):
			mi.material_override = bark_mat
		else:
			# Unknown — default to foliage teal for visibility
			mi.material_override = foliage_mat


# ---------------------------------------------------------------------------
# Materials — StandardMaterial3D for the body.
# dp_toon_grounded has ambient_light_disabled which makes skinned meshes go
# black when NdotL is low on all directional lights. StandardMaterial3D handles
# ambient correctly and gives a readable stone surface in the preview.
# ---------------------------------------------------------------------------
func _apply_toon_materials(root: Node3D) -> void:
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = STONE_ALBEDO
	stone_mat.roughness = 0.92
	stone_mat.metallic = 0.0
	stone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX  # flat-ish look

	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.42, 0.40, 0.36)
	eye_mat.roughness = 0.95
	eye_mat.emission_enabled = true
	eye_mat.emission = EYE_COLOR
	eye_mat.emission_energy_multiplier = EYE_ENERGY

	for mi_node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := mi_node as MeshInstance3D
		if mi.mesh == null:
			continue
		if mi.name.to_lower().contains("eye"):
			mi.material_override = eye_mat
		else:
			mi.material_override = stone_mat


# ---------------------------------------------------------------------------
# Floating rock ornaments
# ---------------------------------------------------------------------------
func _spawn_ornaments() -> void:
	if not ResourceLoader.exists(CHUNKS_GLB):
		push_warning("golem_rigged_preview: chunks GLB not found, skipping ornaments")
		return

	var packed := load(CHUNKS_GLB) as PackedScene
	if packed == null:
		return

	var chunks_root := packed.instantiate() as Node3D
	var candidates: Array = []
	for child in chunks_root.get_children():
		if child is Node3D:
			var has_mesh := false
			for mi in (child as Node3D).find_children("*", "MeshInstance3D", true, false):
				if (mi as MeshInstance3D).mesh != null:
					has_mesh = true
					break
			if has_mesh:
				candidates.append(child)
		if candidates.size() >= 5:
			break

	var count := mini(4, candidates.size())  # up to 4 ornaments
	for i in range(count):
		var src := candidates[i] as Node3D
		var orn := src.duplicate() as Node3D
		orn.name = "Ornament_%d" % i
		add_child(orn)

		var rock_mat := ShaderMaterial.new()
		rock_mat.shader = TOON_SHADER
		rock_mat.set_shader_parameter("albedo_color", Color(0.60, 0.58, 0.54))
		rock_mat.set_shader_parameter("use_vertex_color", false)
		rock_mat.set_shader_parameter("rim_intensity", 0.05)
		rock_mat.set_shader_parameter("shadow_darkness", 0.30)
		for mi in orn.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = rock_mat

		# Scale ornaments relative to the golem height
		var orn_scale := 0.40 + float(i) * 0.06
		orn.scale = Vector3.ONE * orn_scale

		var start_pos := Vector3(
			cos(float(i) * (TAU / float(count))) * 1.1,
			TARGET_HEIGHT_M * 0.70,
			sin(float(i) * (TAU / float(count))) * 1.1
		)
		if _rig != null:
			start_pos += _rig.global_position
		orn.global_position = start_pos

		var od := OrnamentData.new()
		od.node = orn
		od.target_pos = start_pos
		od.spring_pos = start_pos
		od.spring_vel = Vector3.ZERO
		_ornaments.append(od)

	chunks_root.queue_free()


# ---------------------------------------------------------------------------
# Lights + environment + scale reference
# ---------------------------------------------------------------------------
func _add_lights() -> void:
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.95, 0.85)
	key.light_energy = 1.55
	key.rotation_degrees = Vector3(-48, 140, 0)
	key.shadow_enabled = true
	add_child(key)

	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.55, 0.66, 0.92)
	fill.light_energy = 0.55
	fill.rotation_degrees = Vector3(-55, -38, 0)
	add_child(fill)

	var back := DirectionalLight3D.new()
	back.light_color = Color(0.80, 0.72, 0.60)
	back.light_energy = 0.30
	back.rotation_degrees = Vector3(-20, -155, 0)
	add_child(back)


func _add_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.18, 0.20, 0.24)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.44, 0.58)
	env.ambient_light_energy = 0.60
	env.glow_enabled = false
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _add_scale_reference() -> void:
	var post := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.35, 1.8, 0.35)
	post.mesh = box
	post.position = Vector3(4.5, 0.9, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.35, 0.28)
	post.material_override = mat
	add_child(post)


# ---------------------------------------------------------------------------
# HUD
# ---------------------------------------------------------------------------
func _add_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)

	_label = Label.new()
	_label.position = Vector2(14, 12)
	_label.add_theme_font_size_override("font_size", 22)
	_label.text = "golem_rigged_preview"
	cl.add_child(_label)

	_hint_label = Label.new()
	_hint_label.position = Vector2(14, 42)
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.modulate = Color(0.9, 0.85, 0.75)
	_hint_label.text = ""
	cl.add_child(_hint_label)

	var legend := Label.new()
	legend.position = Vector2(14, 696)
	legend.add_theme_font_size_override("font_size", 11)
	legend.modulate = Color(0.8, 0.8, 0.8, 0.85)
	legend.text = "Ref post = 1.8 m  |  Golem target %.1f m  |  UniRig 28 bones — per-limb anim" % TARGET_HEIGHT_M
	cl.add_child(legend)

	var controls := Label.new()
	controls.position = Vector2(14, 680)
	controls.add_theme_font_size_override("font_size", 11)
	controls.modulate = Color(0.8, 0.8, 0.8, 0.85)
	controls.text = "LMB drag = orbit   |   Scroll = zoom   |   SPACE/RMB = skip clip"
	cl.add_child(controls)
