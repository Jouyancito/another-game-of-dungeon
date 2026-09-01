extends Node3D
## Stream capture — flies a scripted camera along floor1's stream channels and
## saves screenshots, so the river pass (gravel beds + worn-stone kit + natural
## water) can be judged from renders instead of asking a human to pilot every
## iteration. Same non-intrusive SubViewport pattern as biome_capture.gd.
##
## Run (repo root):
##   Godot_v4.6.2-stable_win64.exe --path game res://scenes/dev/stream_capture.tscn
##
## Output: game/tools/godot/stream_capture/NN_<name>.png + _report.txt

const OUT_DIR := "res://tools/godot/stream_capture/"
const SV_SIZE := Vector2i(1280, 720)
const WORLD_SEED := 912999   # the seed Joan flew 2026-08-31 — reproduce what he saw

var _sv: SubViewport
var _cam: Camera3D
var _floor: Node3D
var _label: Label
var _shot_index := 0
var _report_lines: Array[String] = []


func _ready() -> void:
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

	var floor_scene: PackedScene = load("res://scenes/levels/floor1_prairie.tscn")
	_floor = floor_scene.instantiate()
	_floor.set("world_seed", WORLD_SEED)
	_floor.set("skip_game_ui", true)
	_sv.add_child(_floor)

	_cam = Camera3D.new()
	_cam.fov = 65.0
	_sv.add_child(_cam)
	_cam.current = true

	var cl := CanvasLayer.new()
	add_child(cl)
	_label = Label.new()
	_label.position = Vector2(14, 12)
	cl.add_child(_label)

	for _i in range(60):
		await get_tree().process_frame

	await _run_shots()

	var f := FileAccess.open(OUT_DIR + "_report.txt", FileAccess.WRITE)
	if f != null:
		for line in _report_lines:
			f.store_line(line)
		f.close()
	print("[stream_capture] Done: %d shots -> %s" % [_shot_index, ProjectSettings.globalize_path(OUT_DIR)])
	get_tree().quit()


func _ground_y(x: float, z: float) -> float:
	if _floor.has_method("get_terrain_height"):
		return float(_floor.call("get_terrain_height", x, z))
	return 0.0


## A judging point on stream `si`: the polyline vertex FURTHEST from the map
## centre spawn bowl (the carve is suppressed inside it), stepped one vertex
## inward so the channel is fully formed there.
func _stream_point(si: int) -> Vector3:
	var polys: Array = _floor.get("_stream_polylines")
	if polys == null or si >= polys.size():
		return Vector3.ZERO
	var poly: Array = polys[si]
	# Mid-point of the OUTER half: far from the spawn bowl, far from the end.
	var idx: int = maxi(1, int(float(poly.size()) * 0.3))
	var p2: Vector2 = poly[idx] as Vector2
	return Vector3(p2.x, _ground_y(p2.x, p2.y), p2.y)


func _stream_dir(si: int) -> Vector3:
	var polys: Array = _floor.get("_stream_polylines")
	var poly: Array = polys[si]
	var idx: int = maxi(1, int(float(poly.size()) * 0.3))
	var a: Vector2 = poly[maxi(idx - 1, 0)] as Vector2
	var b: Vector2 = poly[mini(idx + 1, poly.size() - 1)] as Vector2
	var d := Vector2(b.x - a.x, b.y - a.y).normalized()
	return Vector3(d.x, 0.0, d.y)


func _run_shots() -> void:
	var report_polys: Array = _floor.get("_stream_polylines")
	_report_lines.append("=== stream_capture seed=%d — %d polylines ===" % [WORLD_SEED, 0 if report_polys == null else report_polys.size()])

	for si in range(3):
		var p := _stream_point(si)
		if p == Vector3.ZERO:
			_report_lines.append("stream %d: no polyline" % si)
			continue
		var d := _stream_dir(si)
		var perp := Vector3(-d.z, 0.0, d.x)
		var tag := "wet%d" % si if si < 2 else "dry"
		_report_lines.append("stream %d (%s): judge point %s" % [si, tag, str(p)])

		# (a) aerial: 25 m up, looking down the channel
		await _shot(p + Vector3(0, 25, 0) - d * 12.0, p + d * 10.0,
				"%02d_%s_aerial.png" % [_shot_index, tag])
		# (b) three-quarter from the bank, 8 m out, 4 m up
		await _shot(p + perp * 8.0 + Vector3(0, 4.0, 0) - d * 4.0, p + Vector3(0, 0.4, 0),
				"%02d_%s_bank34.png" % [_shot_index, tag])
		# (c) player eye standing back from the rim. 4.5 m out put the camera
		# inside the bank once the channel was genuinely carved — the near
		# slope filled the frame. 9 m clears the widest reach.
		await _shot(p + perp * 6.5 + Vector3(0, 1.75, 0), p + Vector3(0, 0.2, 0) + d * 2.0,
				"%02d_%s_playereye.png" % [_shot_index, tag])
		# (d) low close-up over the bed, 1 m up, 2.5 m back
		await _shot(p - d * 2.5 + Vector3(0, 1.0, 0), p + Vector3(0, 0.1, 0) + d * 1.5,
				"%02d_%s_bedclose.png" % [_shot_index, tag])


func _shot(pos: Vector3, look_at_pos: Vector3, filename: String) -> void:
	# Never below local ground
	pos.y = maxf(pos.y, _ground_y(pos.x, pos.z) + 0.4)
	_label.text = filename
	_cam.global_position = pos
	_cam.look_at(look_at_pos, Vector3.UP)
	for _i in range(8):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := _sv.get_texture().get_image()
	if img == null:
		_report_lines.append("[FINDING] %s: null image" % filename)
		return
	var err := img.save_png(OUT_DIR + filename)
	if err == OK:
		_shot_index += 1
		print("[stream_capture] saved ", filename)
	else:
		_report_lines.append("[FINDING] %s: save_png err=%d" % [filename, err])
