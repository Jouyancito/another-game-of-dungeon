extends Node3D
## One-shot top-down "maquette" screenshot of floor1_prairie with a random seed.
## Run: Godot --path game scenes/dev/_topdown_capture.tscn --windowed --resolution 1600x1600
## Saves to user://topdown_capture.png (see log line for the real OS path) and quits.

var _floor: Node3D = null
var _frames_waited := 0


func _ready() -> void:
	randomize()
	var seed_val := randi() % 999999
	print("[topdown] using world_seed=", seed_val)

	var scene: PackedScene = load("res://scenes/levels/floor1_prairie.tscn")
	_floor = scene.instantiate()
	_floor.world_seed = seed_val
	add_child(_floor)

	# generate() runs synchronously inside _ready() of the floor scene (already
	# triggered by add_child above) -- wait a few frames for meshes/multimeshes
	# to finish building and the renderer to draw at least one real frame.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(1.5).timeout

	# The floor's own generate() spawns a player with its own Camera3D that may
	# set itself `current` during/after that same timeframe -- disable every
	# other camera in the tree so ours is guaranteed to win, and do this AFTER
	# the wait above (not before), then capture on the very next frames with
	# no further awaits that could let another camera re-claim `current`.
	_disable_other_cameras(get_tree().root)
	_place_top_camera()
	await get_tree().process_frame
	await get_tree().process_frame

	var img := get_viewport().get_texture().get_image()
	var out_path := "user://topdown_capture.png"
	img.save_png(out_path)
	print("[topdown] saved: ", ProjectSettings.globalize_path(out_path))
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()


func _disable_other_cameras(node: Node) -> void:
	if node is Camera3D:
		(node as Camera3D).current = false
	for child in node.get_children():
		_disable_other_cameras(child)


func _place_top_camera() -> void:
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 620.0  # covers the ~600m map with a small margin
	cam.far = 120.0
	cam.near = 0.1
	add_child(cam)
	# Ceiling rock roof sits around y=68 (2026-07-20 rework) -- a camera ABOVE
	# that sees the roof's unlit exterior top face (this is what produced the
	# near-black first capture). Sit just under it, still comfortably above
	# the ~30m terrain relief, so we're looking at the cave's INTERIOR.
	cam.global_position = Vector3(0.0, 58.0, 0.0)
	cam.rotation_degrees = Vector3(-90.0, 0.0, 0.0)  # straight down
	cam.current = true
