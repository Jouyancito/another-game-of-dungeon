extends Node3D
## Floor1 biome vegetation capture — instantiates floor1_prairie.gd with the full
## POOL_TREES/POOL_BUSHES/POOL_GROUND flora (including the 15 bespoke species wired
## in 2026-07-27: 5 tree_pack trees, 5 env_bush_* bushes, 5 new flower_pack flowers),
## then drives a scripted camera through fixed waypoints and saves screenshots.
##
## NON-INTRUSIVE: renders into a SubViewport (off-screen render target). The main
## window is parked off-screen at (-4000,-4000) and shrunk to 1x1 px with
## FLAG_NO_FOCUS, so it never steals focus or screen space — same pattern as
## scenes/dev/golem_anim_capture.gd.
##
## Run command (from repo root, Godot 4.6 win64):
##   Godot_v4.6.2-stable_win64.exe --path game res://scenes/dev/biome_capture.tscn
## (or the _console.exe variant to see [biome_capture] print() output live)
##
## Output:
##   game/tools/godot/biome_capture/NN_<name>.png   — the screenshots
##   game/tools/godot/biome_capture/_report.txt     — species found/missing + shot log
##
## Species are NOT located by hardcoded world coordinates (procedural + seed-
## dependent). Instead, after generate() settles, this scans the "VegetationScatter"
## container floor1_prairie.gd builds and matches each child's scene_file_path
## against the known bespoke asset paths — the same identity FLORA_NICHES keys off.
## If a species never got instantiated for this seed, its shot is skipped and the
## miss is written to _report.txt instead of being silently swapped for something
## else — the point of this tool is to catch that, not paper over it.

const OUT_DIR   := "res://tools/godot/biome_capture/"
const SV_SIZE   := Vector2i(1280, 720)
const WORLD_SEED := 424242   # fixed for reproducibility across runs

var _sv: SubViewport
var _cam: Camera3D
var _floor: Node3D
var _player: Node3D
var _veg_container: Node3D
var _shot_index := 0
var _report_lines: Array[String] = []

# canonical species id -> substring that identifies it in scene_file_path
const SPECIES_MAP := {
	"tree_prairie":      "tree_pack/env_tree_prairie_01",
	"tree_prairie_tall":  "tree_pack/env_tree_prairie_tall_01",
	"tree_prairie_wide":  "tree_pack/env_tree_prairie_wide_01",
	"tree_young":         "tree_pack/env_tree_young_01",
	"tree_dry":           "tree_pack/env_tree_dry_01",
	"bush_round":         "bush/env_bush_round_01.glb",
	"bush_large_glb":     "bush/env_bush_large_01.glb",
	"bush_flowering":     "bush/env_bush_flowering_01",
	"bush_low":           "bush/env_bush_low_01",
	"bush_dry":           "bush/env_bush_dry_01",
	"flower_pale_glow":      "flowers/env_flower_pale_glow_01",
	"flower_yellow_clover":  "flowers/env_flower_yellow_clover_01",
	"flower_bicolor_mix":    "flowers/env_flower_bicolor_mix_01",
	"flower_violet_cluster": "flowers/env_flower_violet_cluster_01",
	"flower_white_star":     "flowers/env_flower_white_star_01",
	"flower_tall_stalk":     "flowers/env_flower_tall_stalk_01",
}
# the 15 "new" ones called out in today's wiring (pale_glow was already wired earlier)
const NEW_TREES   := ["tree_prairie", "tree_prairie_tall", "tree_prairie_wide", "tree_young", "tree_dry"]
const NEW_BUSHES  := ["bush_round", "bush_large_glb", "bush_flowering", "bush_low", "bush_dry"]
const NEW_FLOWERS := ["flower_yellow_clover", "flower_bicolor_mix", "flower_violet_cluster", "flower_white_star", "flower_tall_stalk"]

var _found: Dictionary = {}   # canonical id -> global_position (Vector3)


func _ready() -> void:
	# ── NON-INTRUSIVE: park main window OFF-SCREEN and tiny ─────────────────
	var win := get_window()
	win.size = Vector2i(1, 1)
	win.position = Vector2i(-4000, -4000)
	win.set_flag(Window.FLAG_NO_FOCUS, true)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	# ── Off-screen SubViewport ───────────────────────────────────────────────
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(SV_SIZE)
	add_child(svc)

	_sv = SubViewport.new()
	_sv.size = SV_SIZE
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.transparent_bg = false
	svc.add_child(_sv)

	# ── The biome itself, generated INSIDE the SubViewport ───────────────────
	var floor_scene: PackedScene = load("res://scenes/levels/floor1_prairie.tscn")
	_floor = floor_scene.instantiate()
	_floor.set("world_seed", WORLD_SEED)
	_floor.set("proc_bounds", Vector2(260.0, 260.0))
	_floor.set("skip_game_ui", true)
	_floor.set("active_layers", {
		"border": true, "ceiling": true, "crystals": true, "enemies": false,
		"hud": false, "pillars": true, "player": true, "pois": true,
		"terrain": true, "vegetation": true, "grass": true,
	})
	_sv.add_child(_floor)

	_cam = Camera3D.new()
	_cam.fov = 65.0
	_sv.add_child(_cam)
	_cam.current = true

	_add_hud_label()

	# generate() runs synchronously inside floor1_prairie's _ready(), but glTF
	# materials / collision / terrain-snap settle over a few frames — same
	# rationale as golem_anim_capture.gd's 60-frame wait.
	for _i in range(50):
		await get_tree().process_frame

	_locate_player()
	_scan_vegetation()
	_log_findings()

	await _run_shots()

	_write_report()
	print("[biome_capture] Done: %d shots -> %s" % [_shot_index, OUT_DIR])
	get_tree().quit()


# ---------------------------------------------------------------------------
# Vegetation discovery
# ---------------------------------------------------------------------------
func _find_node_by_name(root: Node, target_name: String) -> Node:
	if root.name == target_name:
		return root
	for child in root.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _scan_vegetation() -> void:
	_veg_container = _find_node_by_name(_floor, "VegetationScatter") as Node3D
	if _veg_container == null:
		_report_lines.append("[FINDING] VegetationScatter container not found — vegetation layer may be off or floor1_prairie.gd structure changed.")
		return
	# Pick the instance CLOSEST to the map center for each species, not just the
	# first one encountered — the first two capture passes kept landing on
	# instances sitting right against _build_organic_border()'s BorderWall
	# (e.g. flower_yellow_clover at x=-75.8, basically touching the wall), which
	# fills the whole frame with the wall's flat black face. Central instances
	# give the camera room to actually frame the subject.
	var found_dist: Dictionary = {}
	for child in _veg_container.get_children():
		if not (child is Node3D):
			continue
		var path: String = (child as Node).scene_file_path
		if path == "":
			continue   # colliders (StaticBody3D) have no scene_file_path
		var gp: Vector3 = (child as Node3D).global_position
		var d: float = Vector2(gp.x, gp.z).length()
		for id in SPECIES_MAP:
			if SPECIES_MAP[id] in path and (not _found.has(id) or d < found_dist[id]):
				_found[id] = gp
				found_dist[id] = d


func _log_findings() -> void:
	_report_lines.append("=== biome_capture — seed=%d proc_bounds=260x260 ===" % WORLD_SEED)
	_report_lines.append("")
	_report_lines.append("-- New tree_pack trees (5 expected) --")
	for id in NEW_TREES:
		_report_lines.append("  %s: %s" % [id, "FOUND @ %s" % str(_found[id]) if _found.has(id) else "MISSING (never instantiated this seed)"])
	_report_lines.append("-- New bush variants (5 expected) --")
	for id in NEW_BUSHES:
		_report_lines.append("  %s: %s" % [id, "FOUND @ %s" % str(_found[id]) if _found.has(id) else "MISSING (never instantiated this seed)"])
	_report_lines.append("-- New flower_pack flowers (5 expected, pale_glow excluded — pre-existing) --")
	for id in NEW_FLOWERS:
		_report_lines.append("  %s: %s" % [id, "FOUND @ %s" % str(_found[id]) if _found.has(id) else "MISSING (never instantiated this seed)"])
	_report_lines.append("")
	for line in _report_lines:
		print("[biome_capture] ", line)


func _write_report() -> void:
	var f := FileAccess.open(OUT_DIR + "_report.txt", FileAccess.WRITE)
	if f == null:
		push_warning("[biome_capture] could not open _report.txt for writing")
		return
	for line in _report_lines:
		f.store_line(line)
	f.close()


# ---------------------------------------------------------------------------
# Player as scale reference
# ---------------------------------------------------------------------------
func _locate_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		_report_lines.append("[FINDING] no node in group 'player' — active_layers.player may be off or BasePlayer no longer joins that group.")
		return
	_player = players[0] as Node3D
	if _player.has_method("set_physics_process"):
		_player.set_physics_process(false)
	if _player.has_method("set_process"):
		_player.set_process(false)


func _place_player_near(target: Vector3, offset: Vector3) -> void:
	if _player == null:
		return
	var p := target + offset
	if _floor.has_method("get_terrain_height"):
		p.y = float(_floor.call("get_terrain_height", p.x, p.z))
	_player.global_position = p


# ---------------------------------------------------------------------------
# HUD (frame label — burned into the capture like golem_anim_capture does)
# ---------------------------------------------------------------------------
var _label: Label

func _add_hud_label() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	_sv.add_child(cl)
	_label = Label.new()
	_label.position = Vector2(14, 12)
	_label.add_theme_font_size_override("font_size", 20)
	_label.text = "biome_capture"
	cl.add_child(_label)


func _set_label(text: String) -> void:
	if _label != null:
		_label.text = text


# ---------------------------------------------------------------------------
# Camera waypoints + capture
# ---------------------------------------------------------------------------
func _goto_and_capture(pos: Vector3, look_at_pos: Vector3, filename: String, label_text: String) -> void:
	_set_label(label_text)
	_cam.global_position = pos
	_cam.look_at(look_at_pos, Vector3.UP)
	# let visibility-range / shadow cascades / SubViewport catch up
	for _i in range(8):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := _sv.get_texture().get_image()
	if img == null:
		_report_lines.append("[FINDING] %s: SubViewport.get_image() returned null, shot skipped" % filename)
		return
	var path := OUT_DIR + filename
	var err := img.save_png(path)
	if err == OK:
		_shot_index += 1
		print("[biome_capture] saved ", filename)
	else:
		_report_lines.append("[FINDING] %s: save_png failed err=%d" % [filename, err])


func _ground_y(x: float, z: float) -> float:
	if _floor.has_method("get_terrain_height"):
		return float(_floor.call("get_terrain_height", x, z))
	return 0.0


## Clamps a desired camera Y to stay above the ACTUAL local ground at (x,z) —
## not the ground at the subject's position. On sloped/hilly terrain (this biome
## has real relief, not a flat plane) a fixed offset from the subject can put the
## camera underground at its own (x,z), which renders solid black.
func _safe_cam_y(x: float, z: float, desired_y: float, min_clearance: float = 0.4) -> float:
	return maxf(desired_y, _ground_y(x, z) + min_clearance)


## Horizontal (XZ) offset from `subject` pointing TOWARD the map center (0,0),
## scaled to `dist`. Judgment Day fix after the first two capture passes came
## back with a giant black wall filling most of the frame on subjects that sit
## in the outer half of the map (e.g. x=-75): a fixed "+x,+z" offset pushes the
## camera even further out, past _build_organic_border()'s BorderWall, so the
## shot ends up staring at the inside of the wall from point-blank range instead
## of at the subject. Offsetting inward guarantees the camera sits BETWEEN the
## subject and the map center, never past the border.
func _inward_offset(subject: Vector3, dist: float) -> Vector2:
	var xz := Vector2(subject.x, subject.z)
	var dir: Vector2 = -xz
	if dir.length() < 0.5:
		dir = Vector2(1.0, 0.0)
	return dir.normalized() * dist


func _run_shots() -> void:
	# (a) Wide aerial view of the biome. Kept well below CEILING_HEIGHT (68m
	# absolute, see floor1_prairie.gd) and well inside the organic border radius
	# — the first two passes had the camera far enough out that BorderWall
	# dominated the frame as a flat black shape. Aimed at the vegetation
	# centroid (average of the 5 new tree_pack finds) instead of pure map
	# center (0,0), which happened to point straight at a POI water feature.
	var veg_centroid := Vector3.ZERO
	var veg_n := 0
	for id in NEW_TREES:
		if _found.has(id):
			veg_centroid += _found[id]
			veg_n += 1
	if veg_n > 0:
		veg_centroid /= float(veg_n)
	else:
		veg_centroid.y = _ground_y(0.0, 0.0)
	await _goto_and_capture(
		veg_centroid + Vector3(45.0, 30.0, 45.0), veg_centroid + Vector3(0.0, 3.0, 0.0),
		"01_aerial_wide.png", "aerial wide"
	)

	# (b) Player-height (~1.7m) view of a cluster of new tree_pack trees, with
	# the actual player node placed alongside as a 1.80m scale reference.
	var tree_id := _pick_first(NEW_TREES)
	if tree_id != "":
		var tpos: Vector3 = _found[tree_id]
		var off := _inward_offset(tpos, 6.0)
		var cx: float = tpos.x + off.x
		var cz: float = tpos.z + off.y
		var cam_pos := Vector3(cx, _safe_cam_y(cx, cz, tpos.y + 1.7), cz)
		_place_player_near(tpos, Vector3(_inward_offset(tpos, 2.5).x, 0.0, _inward_offset(tpos, 2.5).y))
		await _goto_and_capture(
			cam_pos, tpos + Vector3(0.0, 2.0, 0.0),
			"02_player_height_trees.png", "player-height: %s (+player 1.80m ref)" % tree_id
		)
	else:
		_report_lines.append("[FINDING] shot (b) skipped — no new tree_pack species found this seed.")

	# (c) Close-up of a new (non-dry) bush.
	var bush_id := _pick_first(["bush_flowering", "bush_round", "bush_low", "bush_large_glb"])
	if bush_id != "":
		var bpos: Vector3 = _found[bush_id]
		var off2 := _inward_offset(bpos, 1.8)
		var cx2: float = bpos.x + off2.x
		var cz2: float = bpos.z + off2.y
		await _goto_and_capture(
			Vector3(cx2, _safe_cam_y(cx2, cz2, bpos.y + 1.1), cz2), bpos + Vector3(0.0, 0.5, 0.0),
			"03_bush_closeup.png", "bush close-up: %s" % bush_id
		)
	else:
		_report_lines.append("[FINDING] shot (c) skipped — no new bush species found this seed.")

	# (d) Close-up of a new flower (excludes pale_glow, already-canon before today).
	var flower_id := _pick_first(NEW_FLOWERS)
	if flower_id != "":
		var fpos: Vector3 = _found[flower_id]
		var off3 := _inward_offset(fpos, 0.9)
		var cx3: float = fpos.x + off3.x
		var cz3: float = fpos.z + off3.y
		await _goto_and_capture(
			Vector3(cx3, _safe_cam_y(cx3, cz3, fpos.y + 0.6, 0.25), cz3), fpos + Vector3(0.0, 0.15, 0.0),
			"04_flower_closeup.png", "flower close-up: %s" % flower_id
		)
	else:
		_report_lines.append("[FINDING] shot (d) skipped — no new flower_pack species found this seed.")

	# (e) Dry-zone (env_tree_dry_01 / env_bush_dry_01) — arid niche species.
	var dry_tree_found: bool = _found.has("tree_dry")
	var dry_bush_found: bool = _found.has("bush_dry")
	if dry_tree_found or dry_bush_found:
		var anchor: Vector3 = _found.get("tree_dry", _found.get("bush_dry"))
		var off4 := _inward_offset(anchor, 5.0)
		var cx4: float = anchor.x + off4.x
		var cz4: float = anchor.z + off4.y
		await _goto_and_capture(
			Vector3(cx4, _safe_cam_y(cx4, cz4, anchor.y + 1.7), cz4), anchor + Vector3(0.0, 1.2, 0.0),
			"05_dry_zone.png", "dry zone: tree_dry=%s bush_dry=%s" % [str(dry_tree_found), str(dry_bush_found)]
		)
		if not dry_tree_found:
			_report_lines.append("[FINDING] dry zone shot: env_tree_dry_01 MISSING, framed on bush_dry only.")
		if not dry_bush_found:
			_report_lines.append("[FINDING] dry zone shot: env_bush_dry_01 MISSING, framed on tree_dry only.")
	else:
		_report_lines.append("[FINDING] shot (e) skipped — neither tree_dry nor bush_dry found this seed.")

	# (f) Stream edge. Pick the ribbon segment closest to the map center — same
	# rationale as the species pick above: the first segment tends to sit near
	# where the stream originates/exits at the border, which put the camera
	# face-to-face with BorderWall in the first two passes.
	var stream_container := _find_node_by_name(_floor, "StreamRibbons")
	if stream_container != null and stream_container.get_child_count() > 0:
		var best_seg: Node3D = null
		var best_seg_d := INF
		for seg in stream_container.get_children():
			if not (seg is Node3D):
				continue
			var sd: float = Vector2((seg as Node3D).global_position.x, (seg as Node3D).global_position.z).length()
			if sd < best_seg_d:
				best_seg_d = sd
				best_seg = seg
		var spos: Vector3 = best_seg.global_position
		spos.y = _ground_y(spos.x, spos.z)
		var off5 := _inward_offset(spos, 4.0)
		var cx5: float = spos.x + off5.x
		var cz5: float = spos.z + off5.y
		await _goto_and_capture(
			Vector3(cx5, _safe_cam_y(cx5, cz5, spos.y + 1.7), cz5), spos + Vector3(0.0, 0.3, 0.0),
			"06_stream_edge.png", "stream edge"
		)
	else:
		_report_lines.append("[FINDING] shot (f) skipped — StreamRibbons container empty or not found.")


func _pick_first(ids: Array) -> String:
	for id in ids:
		if _found.has(id):
			return id
	return ""
