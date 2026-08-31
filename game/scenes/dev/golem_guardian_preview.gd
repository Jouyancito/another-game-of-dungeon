extends Node3D
## Interactive preview for the golem_guardian GLB (block-vocabulary sub-boss).
## Dev/QA scene — not shipped. Joan drives it with his own eye.
##
## Controls:
##   1..6      = play clip (mapping shown on screen)
##   Free cam  = WASD + mouse (see free_cam.gd), ESC releases the mouse
##
## Run:
##   Godot_v4.6.2-stable_win64.exe --path game res://scenes/dev/golem_guardian_preview.tscn

const GLB_PATH := "res://tools/blender/golem_guardian/golem_guardian.glb"
const CLIP_ORDER := ["dormant", "awaken", "idle", "move", "attack", "hit", "death"]
# PO 2026-08-26: the sub-boss is a ~10m hill-that-becomes-a-golem. The GLB
# stands ~4.6m; the real enemy wiring will use EnemyModelFitter with a 10m
# target — the preview approximates it with a plain scale.
const HILL_SCALE := 2.2

var _anim: AnimationPlayer = null
var _key_to_clip: Dictionary = {}
var _label: Label = null
var _head: Node3D = null
var _glow_head: Node3D = null
var _cam: Camera3D = null
var _head_yaw := 0.0
var _head_base_rot_y := 0.0
var _glow_base_pos := Vector3.ZERO
var _glow_base_rot_y := 0.0
var _head_base_pos := Vector3.ZERO
var _bases_valid := false


func _ready() -> void:
	# Track-after-animate, deterministically: higher priority = processed
	# AFTER the (default-priority) AnimationPlayer, so every frame we read
	# the clip's fresh pose and layer the head yaw on top. This kills the
	# "ojos locos" for good in BOTH states — playing (fresh base each frame)
	# and stopped (stored base, absolute offset).
	process_priority = 100
	_build_environment()
	_build_ground_and_reference()
	_spawn_guardian()
	_build_camera()
	_build_hud()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	# Dark warm ground tone: bright sky bleeds through foliage and washes
	# glow materials out (blender-asset-smith capture gotcha).
	env.background_color = Color(0.13, 0.11, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.42, 0.52)
	env.ambient_light_energy = 0.9
	# PO 2026-08-27: the seam glows must read as ENERGY, not blue polygons —
	# bloom makes the emissives radiate. The real wiring adds particles too.
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.15
	env.glow_hdr_threshold = 0.95
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, 35, 0)
	key.light_color = Color(1.0, 0.93, 0.82)
	key.light_energy = 1.4
	add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, -140, 0)
	fill.light_color = Color(0.55, 0.62, 0.85)
	fill.light_energy = 0.5
	add_child(fill)


func _build_ground_and_reference() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.38, 0.30, 0.24)
	mat.roughness = 1.0
	ground.material_override = mat
	add_child(ground)

	# 1.8m player reference post — mandatory in every judgement view.
	var post := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.35, 1.8, 0.35)
	post.mesh = box
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.75, 0.15, 0.15)
	post.material_override = post_mat
	post.position = Vector3(-4.0, 0.9, 0.0)
	add_child(post)


func _spawn_guardian() -> void:
	var packed: PackedScene = load(GLB_PATH)
	if packed == null:
		push_error("golem_guardian.glb not found/imported at " + GLB_PATH)
		return
	var model: Node3D = packed.instantiate()
	model.scale = Vector3.ONE * HILL_SCALE
	add_child(model)
	_head = model.find_child("head", true, false) as Node3D
	_glow_head = model.find_child("glow_head", true, false) as Node3D
	_anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim == null:
		push_error("No AnimationPlayer inside the GLB")
		return
	var available: Array[StringName] = []
	for clip_name in _anim.get_animation_list():
		available.append(clip_name)
	var key := KEY_1
	for wanted in CLIP_ORDER:
		if available.has(StringName(wanted)):
			_key_to_clip[key] = wanted
			key += 1
	for clip_name in available:
		if not _key_to_clip.values().has(String(clip_name)) and key <= KEY_9:
			_key_to_clip[key] = String(clip_name)
			key += 1
	if _key_to_clip.has(KEY_1):
		_anim.play(_key_to_clip[KEY_1])  # dormant: motionless stone until woken


func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(6.0, 6.5, -19.0)
	cam.set_script(load("res://scenes/dev/free_cam.gd"))
	add_child(cam)
	cam.look_at(Vector3(0.0, 5.0, 0.0))
	_cam = cam


func _process(delta: float) -> void:
	# Head tracks the viewer (Joan: "que la cara te siga, como el halcon").
	# Additive yaw on top of whatever the current clip keys, clamped so the
	# stone neck never spins ghost-like. Game wiring will do the same toward
	# the player.
	if _head == null or _cam == null:
		return
	# Capture the CLEAN animation pose only while the player is writing it.
	# The first version added yaw every frame; once a one-shot clip ended and
	# the AnimationPlayer stopped resetting the pose, the addition compounded
	# and the head/eyes spun endlessly (Joan: "la cabeza gira como loca...
	# los ojos giran en 360").
	# Only an AWAKE golem tracks (PO: a dead/dormant stone must not stare) —
	# and never fight awaken's own head-look choreography.
	var awake := _anim != null and _anim.is_playing() \
		and String(_anim.current_animation) in ["idle", "move", "attack", "hit"]
	if not awake:
		_head_yaw = 0.0
		_bases_valid = false
		return
	_head_base_rot_y = _head.rotation.y
	_head_base_pos = _head.position
	if _glow_head != null:
		_glow_base_pos = _glow_head.position
		_glow_base_rot_y = _glow_head.rotation.y
	_bases_valid = true
	var to_cam := _cam.global_position - _head.global_position
	to_cam.y = 0.0
	if to_cam.length() < 0.5:
		return
	# Blender front is -Y; with export_yup that lands on +Z in Godot, so
	# yaw 0 = facing +Z and the target yaw is atan2(x, z).
	var target := clampf(wrapf(atan2(to_cam.x, to_cam.z), -PI, PI), -0.9, 0.9)
	_head_yaw = lerp_angle(_head_yaw, target, minf(1.0, delta * 3.0))
	# ABSOLUTE offset over the captured base — never additive on itself.
	_head.rotation.y = _head_base_rot_y + _head_yaw
	if _glow_head != null:
		var off := _glow_base_pos - _head_base_pos
		_glow_head.position = _head_base_pos + off.rotated(Vector3.UP, _head_yaw)
		_glow_head.rotation.y = _glow_base_rot_y + _head_yaw


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(14, 12)
	_label.add_theme_font_size_override("font_size", 17)
	layer.add_child(_label)
	_refresh_hud("-")


func _refresh_hud(current: String) -> void:
	if _label == null:
		return
	var lines := ["GOLEM GUARDIAN preview (~10m hill scale)  |  clip: " + current,
		"WASD+mouse: free cam  ESC: release mouse  wheel: speed"]
	var keys := _key_to_clip.keys()
	keys.sort()
	var mapping := []
	for k in keys:
		mapping.append("%d=%s" % [k - KEY_0, _key_to_clip[k]])
	lines.append("  ".join(mapping))
	_label.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if _anim != null and _key_to_clip.has(event.keycode):
			var clip: String = _key_to_clip[event.keycode]
			_anim.stop()
			_anim.play(clip)
			_refresh_hud(clip)
