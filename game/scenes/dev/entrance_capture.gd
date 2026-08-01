extends Node3D
## DEV HARNESS — renders the floor-1 entrance antechamber from fixed viewpoints.
##
## The antechamber is the first thing a player sees on every run, and it is built
## from procedural terrain (a carved trench) plus hand-placed stone. Whether those
## two actually meet cannot be read off the source: a slab can float, the roof can
## surface, the mouth can end up buried. So it gets looked at.
##
## Instantiates the real floor1_prairie with the player and enemies off, resolves
## the entrance anchor through the SAME POISystem call the level uses, and shoots
## the four views that can each hide a different failure:
##   00 inside, facing the exit     — is the doorway clear and the room lit?
##   01 inside, facing the portal   — does the far end read as a destination?
##   02 outside on the ramp         — does the mouth read as a way in?
##   03 high oblique                — does the trench sit in the prairie or gash it?
##
## Run:
##   Godot_v4.6.2-stable_win64_console.exe --path game \
##       res://scenes/dev/entrance_capture.tscn -- --seed=12345
##
## Output: game/tools/godot/entrance_capture/*.png

const OUT_DIR := "res://tools/godot/entrance_capture/"
const SV_SIZE := Vector2i(1280, 720)
const EYE := 1.7

var _sv: SubViewport
var _cam: Camera3D
var _floor: Node3D
var _seed := 12345


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			_seed = int(a.split("=", true, 1)[1])

	var win := get_window()
	win.size = Vector2i(1, 1)
	win.position = Vector2i(-4000, -4000)
	win.set_flag(Window.FLAG_NO_FOCUS, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(SV_SIZE)
	add_child(svc)
	_sv = SubViewport.new()
	_sv.size = SV_SIZE
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(_sv)

	_floor = (load("res://scenes/levels/floor1_prairie.tscn") as PackedScene).instantiate() as Node3D
	_floor.set("world_seed", _seed)
	# Player off: it would spawn inside the room and stand in every shot. Enemies off
	# for the same reason. Everything that SHAPES the entrance stays on.
	_floor.set("active_layers", {
		"terrain": true, "pois": true, "vegetation": true, "border": true,
		"streams": true, "player": false, "enemies": false, "hud": false,
	})
	_sv.add_child(_floor)

	_cam = Camera3D.new()
	_cam.fov = 70.0
	_sv.add_child(_cam)
	_cam.current = true

	for _i in range(45):
		await get_tree().process_frame

	# Read the level's OWN anchor, not a second call to POISystem: the level snaps the
	# mouth to a terrain vertex after resolving it, so an independently recomputed
	# anchor lands a few metres off and every measurement below samples the wrong
	# spot — which is exactly how a "buried doorway" reading survived one round.
	var anchor: Vector3 = _floor.get("_entrance_anchor")
	var surface: float = _floor.call("get_terrain_height", anchor.x, anchor.z)
	var hall_len: float = _floor.get("ENTRANCE_HALL_LEN")
	var depth: float = _floor.get("ENTRANCE_DEPTH")
	var run: float = _floor.get("ENTRANCE_TRENCH_RUN")
	var floor_y: float = _floor.get("_entrance_floor_y")
	var mouth_x: float = anchor.x + hall_len * 0.5

	print("[entrance_capture] seed=%d anchor=(%.1f, %.1f) surface=%.2f floor=%.2f mouth_x=%.1f"
		% [_seed, anchor.x, anchor.z, surface, floor_y, mouth_x])
	# Terrain profile along the trench: the numbers that say whether the ramp is
	# walkable and whether the room actually ended up underground.
	for f in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var px: float = mouth_x + run * f
		print("[entrance_capture]   trench %3d%%  x=%7.1f  terrain=%6.2f  (%.2f under prairie)"
			% [int(f * 100.0), px, _floor.call("get_terrain_height", px, anchor.z),
			   surface - _floor.call("get_terrain_height", px, anchor.z)])

	await _shot("00_inside_to_exit",
		Vector3(anchor.x - hall_len * 0.5 + 3.0, floor_y + EYE, anchor.z),
		Vector3(mouth_x + 8.0, floor_y + 2.0, anchor.z))
	await _shot("01_inside_to_portal",
		Vector3(mouth_x - 2.0, floor_y + EYE, anchor.z),
		Vector3(anchor.x - hall_len * 0.5, floor_y + 1.9, anchor.z))
	# Eye height from the ground UNDER THE CAMERA, not from the anchor: the anchor is
	# excavated now, so deriving it there put the camera below the mound, shooting the
	# underside of the mesh.
	var ramp_x: float = mouth_x + run * 0.7
	await _shot("02_outside_ramp",
		Vector3(ramp_x, _floor.call("get_terrain_height", ramp_x, anchor.z) + EYE, anchor.z),
		Vector3(mouth_x, floor_y + 2.2, anchor.z))
	await _shot("03_high_oblique",
		Vector3(mouth_x + run * 1.1, surface + 26.0, anchor.z + 30.0),
		Vector3(anchor.x, surface - 3.0, anchor.z))

	print("[entrance_capture] DONE -> %s" % OUT_DIR)
	get_tree().quit(0)


func _shot(name: String, eye: Vector3, look: Vector3) -> void:
	_cam.global_position = eye
	_cam.look_at(look, Vector3.UP)
	for _i in range(6):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := _sv.get_texture().get_image()
	if img == null:
		print("[entrance_capture] [FATAL] %s: get_image() null" % name)
		return
	img.save_png(OUT_DIR + name + ".png")
	print("[entrance_capture] shot %s" % name)
