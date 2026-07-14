extends Node3D
## golem_capture_move.gd — Dense frame capture of GolemAssembly skeleton animations.
##
## Instances golem_assembly.tscn, awakens it, plays a named move, captures ~30 frames
## to game/tools/godot/anim_capture/<move_name>/frame_NNN.png via SubViewport.
##
## Usage (NOT --headless — needs a real rendering device):
##   Godot --path game res://tools/godot/golem_capture_move.tscn -- <move> [angle]
##
## Moves: idle  attack_basic
## Angles: front  34  side  (default: 34)
##
## Output:
##   game/tools/godot/anim_capture/idle/frame_000.png … frame_029.png
##   game/tools/godot/anim_capture/attack_basic/frame_000.png … frame_029.png

const TARGET_TSCN := "res://scenes/enemy/golem_assembly.tscn"

const VIEW := Vector2i(640, 720)
const FRAME_COUNT := 30
const FRAME_SKIP  := 3   # process every N frames — spreads capture across anim duration

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1:
		push_error("golem_capture_move: usage -- <move> [angle]")
		push_error("  moves: idle  attack_basic")
		get_tree().quit(1)
		return
	var move_name: String = args[0]
	var angle: String = args[1] if args.size() >= 2 else "34"
	await _run(move_name, angle)


func _run(move_name: String, angle: String) -> void:
	get_window().size = VIEW
	_add_lights()
	_add_environment()

	var packed := load(TARGET_TSCN) as PackedScene
	if packed == null:
		push_error("golem_capture_move: could not load " + TARGET_TSCN)
		get_tree().quit(1)
		return

	var subject := packed.instantiate() as Node3D
	if subject == null:
		push_error("golem_capture_move: instantiation failed")
		get_tree().quit(1)
		return

	add_child(subject)

	# Wait for _on_enemy_ready / skeleton construction to complete
	for _i in range(30):
		await get_tree().process_frame

	# Force awake (skip awaken animation — we want standing pose for capture)
	if "is_dormant" in subject:
		subject.set("is_dormant", false)
	if subject.has_method("reset_to_stand"):
		subject.call("reset_to_stand")
	if "is_provoked" in subject:
		subject.set("is_provoked", true)

	# Light up eyes
	if subject.has_method("_light_up_eyes"):
		subject.call("_light_up_eyes")

	# Wait for reset to settle
	for _i in range(20):
		await get_tree().process_frame

	_frame_camera(subject, angle)

	# Render one clean frame before starting move
	await RenderingServer.frame_post_draw
	for _i in range(3):
		await get_tree().process_frame

	# Start the requested move
	var out_dir: String = "user://anim_capture/" + move_name
	DirAccess.make_dir_recursive_absolute(out_dir)

	# Also write to res:// tools path for easy access
	var res_dir: String = ProjectSettings.globalize_path("res://tools/godot/anim_capture/" + move_name)
	DirAccess.make_dir_recursive_absolute(res_dir)

	match move_name:
		"idle":
			subject.call("play_idle")
		"attack_basic":
			subject.call("play_attack_basic")
		_:
			push_error("golem_capture_move: unknown move '" + move_name + "'")
			get_tree().quit(1)
			return

	print("golem_capture_move: capturing %d frames of '%s' to %s" % [FRAME_COUNT, move_name, res_dir])

	# Capture FRAME_COUNT frames, evenly spaced (skip FRAME_SKIP process frames between each)
	var saved := 0
	while saved < FRAME_COUNT:
		for _skip in range(FRAME_SKIP):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		await get_tree().process_frame

		var img := get_viewport().get_texture().get_image()
		var fname := "frame_%03d.png" % saved
		var fpath := res_dir + "/" + fname
		var err := img.save_png(fpath)
		if err == OK:
			print("FRAME_SAVED %s" % fpath)
		else:
			push_warning("golem_capture_move: save failed (%d): %s" % [err, fpath])
		saved += 1

	print("golem_capture_move: DONE — %d frames saved to %s" % [FRAME_COUNT, res_dir])
	get_tree().quit(0)


func _add_lights() -> void:
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.9, 0.72)
	key.light_energy = 1.6
	key.rotation_degrees = Vector3(-50, 145, 0)
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.55, 0.66, 0.9)
	fill.light_energy = 0.5
	fill.rotation_degrees = Vector3(-60, -50, 0)
	add_child(fill)


func _add_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.64, 0.68)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.30, 0.34, 0.42)
	env.ambient_light_energy = 0.6
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _frame_camera(subject: Node3D, angle: String) -> void:
	var aabb := _subtree_aabb(subject)
	var center := aabb.position + aabb.size * 0.5
	var sz := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if sz <= 0.001:
		sz = 2.5
	var d := sz * 1.7

	var offset: Vector3
	match angle:
		"front":
			offset = Vector3(d * 0.15, d * 0.20, -d * 1.05)
		"side":
			offset = Vector3(d * 1.05, d * 0.10, d * 0.05)
		_:  # "34" default
			offset = Vector3(d * 0.65, d * 0.30, -d * 0.95)

	var cam := Camera3D.new()
	add_child(cam)
	cam.position = center + offset
	cam.look_at(center, Vector3.UP)
	cam.current = true


func _subtree_aabb(root: Node) -> AABB:
	var combined := AABB()
	var has := false
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var gi := mi as MeshInstance3D
		if gi.mesh == null:
			continue
		var world := gi.global_transform * gi.get_aabb()
		if not has:
			combined = world
			has = true
		else:
			combined = combined.merge(world)
	if not has:
		combined = AABB(Vector3(-1, 0, -1), Vector3(2, 2.5, 2))
	return combined
