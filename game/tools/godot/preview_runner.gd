extends Node3D
## preview_runner.gd — Dungeon Party in-engine screenshot harness.
##
## Instances a target scene (an enemy .tscn, or a .glb/.gltf), frames a 3/4 camera
## on it, renders the viewport to a PNG, then quits. This is the Godot equivalent of
## the Blender render_preview loop — it lets us SEE runtime-built visuals (a golem
## with its moss + cyan eyes + floating rocks) without opening the editor by hand.
##
## Run (NOT --headless: the viewport needs a real rendering device to capture):
##   Godot --path game res://tools/godot/preview_runner.tscn -- <target_res_path> <out.png> [angle] [pose]
##
## pose = "awake": forces dormant/camouflaged enemies (is_dormant) out of their
## squashed idle so the standing visual can be judged.
##
## Examples:
##   ... -- res://scenes/enemy/golem.tscn  C:/tmp/golem_front.png  front
##   ... -- res://scenes/enemy/golem.tscn  C:/tmp/golem_up.png  34  awake
##   ... -- res://assets/.../golem_dp_body_01.glb  C:/tmp/body.png  34

const VIEW := Vector2i(640, 720)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()   # everything after '--'
	if args.size() < 2:
		push_error("preview_runner: usage -- <target> <out.png> [front|34|side]")
		get_tree().quit(1)
		return
	var target: String = args[0]
	var out_path: String = args[1]
	var angle: String = args[2] if args.size() >= 3 else "34"
	var pose: String = args[3] if args.size() >= 4 else ""
	await _run(target, out_path, angle, pose)


func _run(target: String, out_path: String, angle: String, pose: String) -> void:
	get_window().size = VIEW

	_add_lights()
	_add_environment()

	var subject := _instance_target(target)
	if subject == null:
		get_tree().quit(1)
		return
	add_child(subject)

	# Let runtime model-building settle (_on_enemy_ready, EnemyModelFitter, tweens).
	for _i in range(24):
		await get_tree().process_frame

	if pose == "awake":
		# Use the real awaken path when present (lights eyes via _awaken), else just
		# un-squash so the standing visual can be judged.
		if subject.has_method("_awaken"):
			subject.call("_awaken")
		elif "is_dormant" in subject:
			subject.set("is_dormant", false)
			subject.scale = Vector3.ONE
		for _i in range(150):
			await get_tree().process_frame

	_frame_camera(subject, angle)

	# Render a few frames, then grab the backbuffer.
	await RenderingServer.frame_post_draw
	for _i in range(3):
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(out_path)
	if err != OK:
		push_error("preview_runner: save_png failed (%d) -> %s" % [err, out_path])
	else:
		print("PREVIEW_SAVED ", out_path)
	get_tree().quit(0 if err == OK else 1)


func _instance_target(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		push_error("preview_runner: resource not found: " + path)
		return null
	var res := load(path)
	if res is PackedScene:
		var n := (res as PackedScene).instantiate()
		return n as Node3D
	push_error("preview_runner: not a PackedScene: " + path)
	return null


func _add_lights() -> void:
	# Key lights the FACE side (-Z authored forward, camera sits at -Z too).
	var key := DirectionalLight3D.new()       # warm key (D2 Act-1 hybrid)
	key.light_color = Color(1.0, 0.9, 0.72)
	key.light_energy = 1.6
	key.rotation_degrees = Vector3(-50, 145, 0)
	add_child(key)
	var fill := DirectionalLight3D.new()       # cool-dark fill on the back
	fill.light_color = Color(0.55, 0.66, 0.9)
	fill.light_energy = 0.5
	fill.rotation_degrees = Vector3(-60, -50, 0)
	add_child(fill)


func _add_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.64, 0.68)  # light gray so dark outlines read
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.30, 0.34, 0.42)
	env.ambient_light_energy = 0.6
	env.glow_enabled = true                    # so the cyan emissive eyes bloom
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

	# Models are authored facing -Z (Godot forward), so the camera must sit on
	# the -Z side to film the FACE. "back" films the +Z side.
	var offset: Vector3
	match angle:
		"front":
			offset = Vector3(d * 0.15, d * 0.20, -d * 1.05)
		"side":
			offset = Vector3(d * 1.05, d * 0.10, d * 0.05)
		"back":
			offset = Vector3(d * 0.15, d * 0.20, d * 1.05)
		_:  # "34" default — front-right three-quarter
			offset = Vector3(d * 0.65, d * 0.30, -d * 0.95)

	var cam := Camera3D.new()
	add_child(cam)
	if angle == "inside":
		# Debug: camera buried in the torso, looking at an inner wall. With a
		# magenta bg, see-through shows magenta; a double-sided mesh shows solid stone.
		cam.position = center + Vector3(0.0, 0.0, 0.05)
		cam.look_at(center + Vector3(0.0, 0.0, -1.0), Vector3.UP)
	else:
		cam.position = center + offset
		cam.look_at(center, Vector3.UP)
	cam.current = true


## AABB of every MeshInstance3D under `root`, expressed in world space. Uses
## global_transform (valid: the node is already in the tree when this runs).
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
