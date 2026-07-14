extends Node3D
## Golem RIGGED animation frame capture — dense 30-frame capture of idle + attack
## from the UniRig skinned golem (golem_rigged.glb).
##
## ALIVE pass: same per-limb bone animation as golem_rigged_preview.gd.
## NON-INTRUSIVE: renders into an off-screen SubViewport (640x720).
## Main window parked at (-4000,-4000) shrunk to 1x1 px, FLAG_NO_FOCUS set.
##
## Run (from repo root):
##   Godot_v4.6.2-stable_win64.exe --path game res://scenes/dev/golem_rigged_capture.tscn
##
## Output:
##   game/tools/godot/anim_capture/alive_idle/frame_NNN.png
##   game/tools/godot/anim_capture/alive_attack/frame_NNN.png
## Cap: 30 frames per clip. Exits automatically.
##
## NOTE: requires a real render device (NOT --headless).

const RIGGED_GLB     := "res://tools/blender/golem_rigged.glb"
const CHUNKS_GLB     := "res://assets/art/piso1_pradera/enemies/big/golem_dp_chunks_01.glb"
const TREE_GLB       := "res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_01.gltf"
const TOON_SHADER    := preload("res://scenes/levels/dp_toon_grounded.gdshader")
const OUTLINE_SHADER := preload("res://assets/art/shaders/toon_outline.gdshader")

const EYE_COLOR    := Color(0.373, 0.847, 1.0)
const EYE_ENERGY   := 1.6
const STONE_ALBEDO := Color(0.52, 0.50, 0.46)
const TARGET_HEIGHT_M := 4.8

const OUT_DIR_IDLE   := "res://tools/godot/anim_capture/alive_idle/"
const OUT_DIR_ATTACK := "res://tools/godot/anim_capture/alive_attack/"
const MAX_FRAMES     := 30

const SV_SIZE := Vector2i(640, 720)

# Bone indices (same map as preview)
# VERIFIED against golem_bone_discover.gd (2026-06-14).
# bone_6..12 = L arm chain; bone_13..19 = R arm; bone_20..23 = L leg; bone_24..27 = R leg
const BONE_ROOT        := 0
const BONE_SPINE_BASE  := 1
const BONE_SPINE_MID   := 2
const BONE_SPINE_UPPER := 3
const BONE_HEAD_BASE   := 4
const BONE_HEAD_TOP    := 5
const BONE_L_SHOULDER  := 6
const BONE_L_UPPER_ARM := 7
const BONE_L_FOREARM   := 8
const BONE_L_WRIST     := 9
const BONE_L_FIST      := 10
const BONE_R_SHOULDER  := 13  # CORRECTED: 13 not 12
const BONE_R_UPPER_ARM := 14
const BONE_R_FOREARM   := 15
const BONE_R_WRIST     := 16
const BONE_R_FIST      := 17

var _sv:    SubViewport   = null
var _cam:   Camera3D      = null
var _rig:   Node3D        = null
var _skeleton: Skeleton3D = null
var _anim_player: AnimationPlayer = null

var _target := Vector3(0.0, 2.5, 0.0)
var _yaw    := 0.7
var _pitch  := 0.18
var _dist   := 11.0

var _frame_index := 0

class OrnamentData:
	var node: Node3D
	var target_pos: Vector3
	var spring_pos: Vector3
	var spring_vel: Vector3
	const OMEGA := 5.5
	const ZETA  := 0.68

var _ornaments: Array = []
var _ornament_angle := 0.0


func _ready() -> void:
	# Park main window off-screen
	var win := get_window()
	win.size = Vector2i(1, 1)
	win.position = Vector2i(-4000, -4000)
	win.set_flag(Window.FLAG_NO_FOCUS, true)

	# Off-screen SubViewport
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(SV_SIZE)
	add_child(svc)

	_sv = SubViewport.new()
	_sv.size = SV_SIZE
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.transparent_bg = false
	svc.add_child(_sv)

	_add_lights()
	_add_environment()
	_add_scale_reference()

	# Load rigged GLB
	if not ResourceLoader.exists(RIGGED_GLB):
		push_error("golem_rigged_capture: rigged GLB not found: " + RIGGED_GLB)
		get_tree().quit()
		return

	var packed := load(RIGGED_GLB) as PackedScene
	if packed == null:
		push_error("golem_rigged_capture: failed to load PackedScene")
		get_tree().quit()
		return

	_rig = packed.instantiate() as Node3D
	_rig.name = "GolemRig"
	_sv.add_child(_rig)
	_rig.rotation_degrees.x = -90.0

	# Scale to target height
	_auto_scale_rig()

	# Find Skeleton3D
	_skeleton = _find_skeleton(_rig)
	if _skeleton == null:
		push_warning("golem_rigged_capture: no Skeleton3D found")

	# Apply stone toon materials
	_apply_toon_materials(_rig)

	# Build per-limb AnimationPlayer
	if _skeleton != null:
		var skel_path := str(_rig.get_path_to(_skeleton))
		print("[alive_capture] skeleton relative path from rig: '%s'" % skel_path)
		_anim_player = _build_animations()

	# Attach tree
	if _skeleton != null:
		_attach_tree()

	# Spawn ornaments
	_spawn_ornaments()

	# Camera
	_cam = Camera3D.new()
	_cam.fov = 65.0
	_sv.add_child(_cam)
	_cam.current = true

	# Wait for GLB import to settle (more frames for capture = stable image)
	for _i in range(90):
		await get_tree().process_frame

	# Ensure output dirs exist
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUT_DIR_IDLE))
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUT_DIR_ATTACK))

	# Capture idle (30 frames over one full 4s cycle → 1 frame every ~8 render frames)
	print("[alive_capture] Starting idle capture...")
	await _capture_clip("idle-loop", OUT_DIR_IDLE, 4.0)

	await get_tree().create_timer(0.3).timeout

	# Capture attack (30 frames over 1.8s → ~every 2 render frames at 30fps)
	print("[alive_capture] Starting attack capture...")
	await _capture_clip("attack", OUT_DIR_ATTACK, 1.8)

	await get_tree().create_timer(0.3).timeout
	print("[alive_capture] Done. idle→%s  attack→%s" % [OUT_DIR_IDLE, OUT_DIR_ATTACK])
	get_tree().quit()


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var r := _find_skeleton(child)
		if r != null:
			return r
	return null


# ---------------------------------------------------------------------------
# Auto-scale: measure the largest AABB dimension, compute scale for TARGET_HEIGHT_M.
# The rig node has -90° X rotation applied (Blender Z-up → Godot Y-up).
# After that rotation, the golem's height is in the Z dimension of its local AABB
# (Blender-Z = Godot height after -90°X). Use max(x,y,z) to find the long axis.
# ---------------------------------------------------------------------------
func _auto_scale_rig() -> void:
	var aabb := AABB()
	var found := false
	for mi_node in _rig.find_children("*", "MeshInstance3D", true, false):
		var mi := mi_node as MeshInstance3D
		if mi.mesh == null:
			continue
		# mi.transform is relative to the Armature parent inside the rig; merge all.
		var local_aabb := mi.transform * mi.get_aabb()
		if not found:
			aabb = local_aabb
			found = true
		else:
			aabb = aabb.merge(local_aabb)

	if not found:
		_rig.scale = Vector3.ONE * 2.0
		push_warning("[alive_capture] no mesh found for AABB, using scale=2.0")
		return

	# The height axis after -90°X rotation: Blender Z-up → this rig's local Z is the tall axis.
	# Take max of all three to be safe.
	var height := maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	if height < 0.01:
		_rig.scale = Vector3.ONE * 2.0
		return

	var scale_factor := TARGET_HEIGHT_M / height
	_rig.scale = Vector3.ONE * scale_factor
	print("[alive_capture] AABB max_dim=%.2f → scale=%.3f → %.1fm" % [height, scale_factor, TARGET_HEIGHT_M])


# ---------------------------------------------------------------------------
# _process — camera + ornament spring
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
# Capture clip — plays animation, saves MAX_FRAMES evenly-spaced frames
# ---------------------------------------------------------------------------
func _capture_clip(clip_name: String, out_dir: String, clip_duration: float) -> void:
	_frame_index = 0
	print("[alive_capture] Capturing '%s' → %s" % [clip_name, out_dir])

	if _anim_player != null:
		_anim_player.play(clip_name)

	# We want MAX_FRAMES samples spread across the full clip_duration.
	# At ~30 fps, total render frames = clip_duration * 30.
	# Skip = total_render_frames / MAX_FRAMES.
	var total_render_frames: int = int(ceil(clip_duration * 30.0))
	var skip: int = maxi(1, total_render_frames / MAX_FRAMES)
	var render_count: int = 0

	while _frame_index < MAX_FRAMES:
		await RenderingServer.frame_post_draw
		render_count += 1
		if render_count >= skip:
			render_count = 0
			await _save_frame(out_dir)
		# Loop attack animation to fill 30 frames
		if _anim_player != null and clip_name == "attack":
			if not _anim_player.is_playing():
				_anim_player.play(clip_name)


func _save_frame(out_dir: String) -> void:
	if _frame_index >= MAX_FRAMES or _sv == null:
		return
	await RenderingServer.frame_post_draw
	var img := _sv.get_texture().get_image()
	if img == null:
		push_warning("[alive_capture] get_image() returned null")
		return
	var path := out_dir + "frame_%03d.png" % _frame_index
	var err := img.save_png(path)
	if err == OK:
		print("[alive_capture] saved: %s" % path)
	else:
		push_warning("[alive_capture] save_png error frame_%03d (err=%d)" % [_frame_index, err])
	_frame_index += 1


# ---------------------------------------------------------------------------
# AnimationPlayer — identical per-limb animations to the preview
# ---------------------------------------------------------------------------
func _build_animations() -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	_rig.add_child(ap)
	ap.root_node = _rig.get_path()

	var lib := AnimationLibrary.new()
	var sp := str(_rig.get_path_to(_skeleton))

	# IDLE — staggered per-limb sway
	var idle := Animation.new()
	idle.length = 4.0
	idle.loop_mode = Animation.LOOP_LINEAR

	var _add_sway: Callable = func(anim: Animation, bone: int, axis: Vector3,
			max_deg: float, period: float, phase: float) -> void:
		var t := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(t, sp + ":bone_%d" % bone)
		var steps := 8
		for s in range(steps + 1):
			var time := float(s) * (anim.length / float(steps))
			var angle_deg := max_deg * sin(TAU * (time + phase) / period)
			anim.rotation_track_insert_key(t, time, Quaternion(axis, deg_to_rad(angle_deg)))

	_add_sway.call(idle, BONE_SPINE_BASE,  Vector3.RIGHT, 2.5, 4.0, 0.0)
	_add_sway.call(idle, BONE_SPINE_MID,   Vector3.BACK,  2.0, 4.0, 0.3)
	_add_sway.call(idle, BONE_SPINE_UPPER, Vector3.RIGHT, 3.0, 4.0, 0.6)
	_add_sway.call(idle, BONE_HEAD_BASE,   Vector3.RIGHT, 3.5, 4.0, 0.9)
	_add_sway.call(idle, BONE_L_SHOULDER,  Vector3.BACK,  6.0, 4.0, 0.5)
	_add_sway.call(idle, BONE_L_UPPER_ARM, Vector3.BACK,  3.5, 4.0, 0.7)
	_add_sway.call(idle, BONE_R_SHOULDER,  Vector3.BACK,  6.0, 4.0, 1.1)
	_add_sway.call(idle, BONE_R_UPPER_ARM, Vector3.BACK,  3.5, 4.0, 1.3)

	lib.add_animation("idle-loop", idle)

	# ATTACK — R arm slam with spine lean
	var atk := Animation.new()
	atk.length = 1.8
	atk.loop_mode = Animation.LOOP_NONE

	var t_sp := atk.add_track(Animation.TYPE_ROTATION_3D)
	atk.track_set_path(t_sp, sp + ":bone_%d" % BONE_SPINE_UPPER)
	atk.rotation_track_insert_key(t_sp, 0.00, Quaternion.IDENTITY)
	atk.rotation_track_insert_key(t_sp, 0.25, Quaternion(Vector3.RIGHT, deg_to_rad(-12.0)))
	atk.rotation_track_insert_key(t_sp, 0.55, Quaternion(Vector3.RIGHT, deg_to_rad( 20.0)))
	atk.rotation_track_insert_key(t_sp, 0.70, Quaternion(Vector3.RIGHT, deg_to_rad( 22.0)))
	atk.rotation_track_insert_key(t_sp, 1.80, Quaternion.IDENTITY)

	var t_sm := atk.add_track(Animation.TYPE_ROTATION_3D)
	atk.track_set_path(t_sm, sp + ":bone_%d" % BONE_SPINE_MID)
	atk.rotation_track_insert_key(t_sm, 0.00, Quaternion.IDENTITY)
	atk.rotation_track_insert_key(t_sm, 0.25, Quaternion(Vector3.RIGHT, deg_to_rad(-8.0)))
	atk.rotation_track_insert_key(t_sm, 0.55, Quaternion(Vector3.RIGHT, deg_to_rad(15.0)))
	atk.rotation_track_insert_key(t_sm, 0.70, Quaternion(Vector3.RIGHT, deg_to_rad(16.0)))
	atk.rotation_track_insert_key(t_sm, 1.80, Quaternion.IDENTITY)

	var t_rs := atk.add_track(Animation.TYPE_ROTATION_3D)
	atk.track_set_path(t_rs, sp + ":bone_%d" % BONE_R_SHOULDER)
	atk.rotation_track_insert_key(t_rs, 0.00, Quaternion.IDENTITY)
	atk.rotation_track_insert_key(t_rs, 0.25, Quaternion(Vector3.BACK, deg_to_rad(-25.0)))
	atk.rotation_track_insert_key(t_rs, 0.55, Quaternion(Vector3.BACK, deg_to_rad( 45.0)))
	atk.rotation_track_insert_key(t_rs, 0.70, Quaternion(Vector3.BACK, deg_to_rad( 48.0)))
	atk.rotation_track_insert_key(t_rs, 1.80, Quaternion.IDENTITY)

	var t_ra := atk.add_track(Animation.TYPE_ROTATION_3D)
	atk.track_set_path(t_ra, sp + ":bone_%d" % BONE_R_UPPER_ARM)
	atk.rotation_track_insert_key(t_ra, 0.00, Quaternion.IDENTITY)
	atk.rotation_track_insert_key(t_ra, 0.25, Quaternion(Vector3.RIGHT, deg_to_rad(-20.0)))
	atk.rotation_track_insert_key(t_ra, 0.55, Quaternion(Vector3.RIGHT, deg_to_rad( 35.0)))
	atk.rotation_track_insert_key(t_ra, 0.70, Quaternion(Vector3.RIGHT, deg_to_rad( 38.0)))
	atk.rotation_track_insert_key(t_ra, 1.80, Quaternion.IDENTITY)

	var t_rf := atk.add_track(Animation.TYPE_ROTATION_3D)
	atk.track_set_path(t_rf, sp + ":bone_%d" % BONE_R_FOREARM)
	atk.rotation_track_insert_key(t_rf, 0.00, Quaternion.IDENTITY)
	atk.rotation_track_insert_key(t_rf, 0.55, Quaternion(Vector3.RIGHT, deg_to_rad(18.0)))
	atk.rotation_track_insert_key(t_rf, 0.70, Quaternion(Vector3.RIGHT, deg_to_rad(20.0)))
	atk.rotation_track_insert_key(t_rf, 1.80, Quaternion.IDENTITY)

	var t_ls := atk.add_track(Animation.TYPE_ROTATION_3D)
	atk.track_set_path(t_ls, sp + ":bone_%d" % BONE_L_SHOULDER)
	atk.rotation_track_insert_key(t_ls, 0.00, Quaternion.IDENTITY)
	atk.rotation_track_insert_key(t_ls, 0.55, Quaternion(Vector3.BACK, deg_to_rad(-8.0)))
	atk.rotation_track_insert_key(t_ls, 1.80, Quaternion.IDENTITY)

	lib.add_animation("attack", atk)   # ← was missing, caused "Animation not found: attack"

	ap.add_animation_library("", lib)
	return ap


# ---------------------------------------------------------------------------
# Tree attachment (same as preview)
# ---------------------------------------------------------------------------
func _attach_tree() -> void:
	if not ResourceLoader.exists(TREE_GLB):
		return

	var ba := BoneAttachment3D.new()
	ba.bone_idx = BONE_SPINE_UPPER
	ba.bone_name = "bone_%d" % BONE_SPINE_UPPER
	_skeleton.add_child(ba)

	var tree_packed := load(TREE_GLB) as PackedScene
	if tree_packed == null:
		return

	var tree := tree_packed.instantiate() as Node3D
	tree.name = "BackTree"
	ba.add_child(tree)
	# Small sapling growing from back — NOT a full-size tree dominating the frame
	tree.position = Vector3(-0.15, 0.05, 0.30)
	tree.rotation_degrees = Vector3(0.0, 15.0, -5.0)
	tree.scale = Vector3(0.18, 0.18, 0.18)

	var foliage_mat := ShaderMaterial.new()
	foliage_mat.shader = TOON_SHADER
	foliage_mat.set_shader_parameter("albedo_color", Color(0.18, 0.55, 0.48))
	foliage_mat.set_shader_parameter("use_vertex_color", false)
	foliage_mat.set_shader_parameter("rim_intensity", 0.04)
	foliage_mat.set_shader_parameter("shadow_darkness", 0.32)

	var bark_mat := ShaderMaterial.new()
	bark_mat.shader = TOON_SHADER
	bark_mat.set_shader_parameter("albedo_color", Color(0.32, 0.25, 0.18))
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
			mi.material_override = foliage_mat


# ---------------------------------------------------------------------------
# Materials — use StandardMaterial3D for the body so it reads correctly with
# the ambient light. dp_toon_grounded has ambient_light_disabled which makes
# skinned meshes go black when normals don't align with directional lights.
# ---------------------------------------------------------------------------
func _apply_toon_materials(root: Node3D) -> void:
	# Stone body: StandardMaterial3D — warm desaturated stone, reads correctly
	# on skinned meshes with ambient light, no ambient_light_disabled issue.
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = STONE_ALBEDO
	stone_mat.roughness = 0.92
	stone_mat.metallic = 0.0
	stone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX  # flat toon-ish

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
# Floating ornaments
# ---------------------------------------------------------------------------
func _spawn_ornaments() -> void:
	if not ResourceLoader.exists(CHUNKS_GLB):
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

	var count := mini(4, candidates.size())
	for i in range(count):
		var src := candidates[i] as Node3D
		var orn := src.duplicate() as Node3D
		orn.name = "Ornament_%d" % i
		_sv.add_child(orn)

		var rock_mat := ShaderMaterial.new()
		rock_mat.shader = TOON_SHADER
		rock_mat.set_shader_parameter("albedo_color", Color(0.60, 0.58, 0.54))
		rock_mat.set_shader_parameter("use_vertex_color", false)
		rock_mat.set_shader_parameter("rim_intensity", 0.05)
		rock_mat.set_shader_parameter("shadow_darkness", 0.30)
		for mi in orn.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = rock_mat

		orn.scale = Vector3.ONE * (0.40 + float(i) * 0.06)

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
# Lights + environment + scale reference (inside SubViewport)
# ---------------------------------------------------------------------------
func _add_lights() -> void:
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.95, 0.85)
	key.light_energy = 1.55
	key.rotation_degrees = Vector3(-48, 140, 0)
	key.shadow_enabled = true
	_sv.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.55, 0.66, 0.92)
	fill.light_energy = 0.55
	fill.rotation_degrees = Vector3(-55, -38, 0)
	_sv.add_child(fill)

	var back := DirectionalLight3D.new()
	back.light_color = Color(0.80, 0.72, 0.60)
	back.light_energy = 0.30
	back.rotation_degrees = Vector3(-20, -155, 0)
	_sv.add_child(back)


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
	_sv.add_child(we)


func _add_scale_reference() -> void:
	var post := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.35, 1.8, 0.35)
	post.mesh = box
	post.position = Vector3(4.5, 0.9, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.35, 0.28)
	post.material_override = mat
	_sv.add_child(post)
