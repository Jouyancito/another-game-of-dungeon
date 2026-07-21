extends Node3D
## Floor1_prairie with a free-fly debug camera instead of the player, so Joan
## can pilot the level directly and judge the terrain/flora/ceiling rework
## himself. Random seed each run (printed to console).
##
## Run: Godot --path game scenes/dev/floor1_freecam.tscn
## Controls: see free_cam.gd (WASD, mouse look, Space/Ctrl up-down, Shift fast, ESC to release mouse)


func _ready() -> void:
	randomize()
	var seed_val := randi() % 999999
	print("[freecam] world_seed=", seed_val)
	get_window().title = "Floor1 Freecam — seed %d" % seed_val

	var scene: PackedScene = load("res://scenes/levels/floor1_prairie.tscn")
	var floor_node: Node3D = scene.instantiate()
	floor_node.world_seed = seed_val
	add_child(floor_node)

	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	_disable_other_cameras(get_tree().root)

	var cam := Camera3D.new()
	cam.set_script(load("res://scenes/dev/free_cam.gd"))
	add_child(cam)
	# Start centered over the map, a bit above ground, angled slightly down —
	# a good orientation point before flying wherever.
	cam.global_position = Vector3(0.0, 25.0, 40.0)
	cam.look_at(Vector3(0.0, 5.0, 0.0), Vector3.UP)


func _disable_other_cameras(node: Node) -> void:
	if node is Camera3D:
		(node as Camera3D).current = false
	for child in node.get_children():
		_disable_other_cameras(child)
