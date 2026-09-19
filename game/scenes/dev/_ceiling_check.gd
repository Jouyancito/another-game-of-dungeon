extends Node3D
## One-shot diagnostic capture: perspective camera at head height looking
## up/across at ~35 deg, to see the ceiling + crystal field + ground together
## in one frame -- unlike the pure top-down maquette tool, this is meant to
## catch "does the roof read as a flat brown mass" / "are crystals actually
## up near the ceiling" type problems.
## Run: Godot --path game scenes/dev/_ceiling_check.tscn --windowed --resolution 1600x1200

var _floor: Node3D = null


func _ready() -> void:
	randomize()
	var seed_val := randi() % 999999
	print("[ceiling_check] using world_seed=", seed_val)

	var scene: PackedScene = load("res://scenes/levels/floor1_prairie.tscn")
	_floor = scene.instantiate()
	_floor.world_seed = seed_val
	add_child(_floor)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(1.5).timeout

	_disable_other_cameras(get_tree().root)
	_place_camera()
	await get_tree().process_frame
	await get_tree().process_frame

	var img := get_viewport().get_texture().get_image()
	var out_path := "user://ceiling_check.png"
	img.save_png(out_path)
	print("[ceiling_check] saved: ", ProjectSettings.globalize_path(out_path))
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()


func _disable_other_cameras(node: Node) -> void:
	if node is Camera3D:
		(node as Camera3D).current = false
	for child in node.get_children():
		_disable_other_cameras(child)


func _place_camera() -> void:
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 75.0
	cam.far = 300.0
	add_child(cam)
	cam.global_position = Vector3(0.0, 6.0, 60.0)
	cam.look_at(Vector3(0.0, 55.0, -20.0), Vector3.UP)
	cam.current = true
