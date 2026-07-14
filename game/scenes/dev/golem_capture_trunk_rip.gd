extends Node3D
## Dense frame capture of ONLY the trunk_rip animation.
##
## Captures ~35-40 frames of trunk_rip at 0.065s interval (≈15 fps review rate)
## covering the full 2.2s animation arc with good density at the key beats.
##
## NON-INTRUSIVE: same off-screen SubViewport approach as golem_anim_capture.gd.
## Main window is parked at (-4000,-4000) and sized 1x1.
##
## Output: game/tools/godot/anim_capture/trunk_rip/frame_NNN.png
##
## Run:
##   Godot_v4.6.2-stable_win64.exe --path game res://scenes/dev/golem_capture_trunk_rip.tscn

## Dense interval: 2.2s / 0.065s ≈ 34 frames — enough to see every phase transition.
## Spec phase boundaries at this interval:
##   P1 GRIP   0.00–0.50s  → frames 00–07
##   P2 STRAIN 0.50–0.92s  → frames 08–14
##   P3 WRENCH 0.92–1.17s  → frames 15–18
##   P4 RECOV  1.17–2.20s  → frames 18–34 (settled at end)

const CAPTURE_INTERVAL := 0.065  # seconds between frames (dense — ~15fps review)
const OUT_DIR          := "res://tools/godot/anim_capture/trunk_rip/"
const MAX_FRAMES       := 38     # 38 × 0.065 = 2.47s — slight over to catch settle

## Camera: tighter than the full-cycle capture. Pull in close to upper-body focus.
const SV_SIZE := Vector2i(720, 810)

var _cam: Camera3D
var _golem: Node  = null
var _label: Label = null
var _phase_label: Label = null
var _sv: SubViewport = null

## Camera orbit — upper-body focus on the trunk_rip motion.
## Slightly higher pitch and shorter distance than the full-cycle capture.
var _target := Vector3(0.0, 2.8, 0.0)   # aim at the chest/shoulder area
var _yaw    := 0.55                       # slight angle (not dead-on) to see arm reach
var _pitch  := 0.22
var _dist   := 6.8                        # close enough to read the body clearly

# Capture state
var _frame_index  := 0
var _capture_done := false
var _capture_acc  := 0.0


func _ready() -> void:
	# ── NON-INTRUSIVE: park main window off-screen ───────────────────────────
	var win := get_window()
	win.size = Vector2i(1, 1)
	win.position = Vector2i(-4000, -4000)
	win.set_flag(Window.FLAG_NO_FOCUS, true)

	# ── Build off-screen SubViewport ──────────────────────────────────────────
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(SV_SIZE)
	add_child(svc)

	_sv = SubViewport.new()
	_sv.size = SV_SIZE
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.transparent_bg = false
	svc.add_child(_sv)

	# ── Scene content ──────────────────────────────────────────────────────────
	_add_lights()
	_add_environment()
	_add_scale_reference()

	var golem_scene := load("res://scenes/enemy/golem_assembly.tscn")
	_golem = golem_scene.instantiate()
	_sv.add_child(_golem)
	# Disable normal process loops — we drive it manually
	if _golem is Node:
		_golem.set_physics_process(false)
		_golem.set_process(false)

	_cam = Camera3D.new()
	_cam.fov = 58.0   # slightly narrower than full-cycle capture = more fill
	_sv.add_child(_cam)
	_cam.current = true

	_add_hud()

	# Ensure output dir exists
	var da := DirAccess.open("res://")
	if da:
		da.make_dir_recursive("tools/godot/anim_capture/trunk_rip")

	# Wait for GLB chunks, materials, EnemyModelFitter to settle
	for _i in range(60):
		await get_tree().process_frame

	await _run_trunk_rip_capture()
	await get_tree().create_timer(0.5).timeout
	print("[trunk_rip_capture] Done: %d frames → %s" % [_frame_index, OUT_DIR])
	get_tree().quit()


func _process(delta: float) -> void:
	if _cam != null:
		var off := Vector3(
			cos(_pitch) * sin(_yaw),
			sin(_pitch),
			cos(_pitch) * cos(_yaw)
		) * _dist
		_cam.position = _target + off
		_cam.look_at(_target, Vector3.UP)

	if _capture_done:
		return
	_capture_acc += delta
	if _capture_acc >= CAPTURE_INTERVAL:
		_capture_acc -= CAPTURE_INTERVAL
		_save_frame()


func _save_frame() -> void:
	if _frame_index >= MAX_FRAMES or _sv == null:
		return
	await RenderingServer.frame_post_draw
	var img := _sv.get_texture().get_image()
	if img == null:
		push_warning("[trunk_rip_capture] SubViewport.get_image() returned null at frame %d" % _frame_index)
		return
	var path := OUT_DIR + "frame_%03d.png" % _frame_index
	var err := img.save_png(path)
	if err == OK:
		print("[trunk_rip_capture] Saved %s" % path)
	else:
		push_warning("[trunk_rip_capture] save_png failed frame_%03d (err=%d)" % [_frame_index, err])
	_frame_index += 1


func _run_trunk_rip_capture() -> void:
	# Brief pre-roll: ensure the golem is in stand pose with full tree visible
	_set_labels("PRE-ROLL: stand + tree visible", "")
	if _golem.has_method("reset_to_stand"):
		_golem.call("reset_to_stand")
	if _golem.has_method("_light_up_eyes"):
		_golem.call("_light_up_eyes")
	# Re-enable physics_process for the spring-damper secondary sway
	if _golem is Node:
		_golem.set_physics_process(true)

	# Settle a few frames before starting
	await get_tree().create_timer(0.25).timeout

	# Start capture exactly when trunk_rip fires
	_set_labels("trunk_rip", "P1 GRIP ANTICIPATION — both arms reach back [CUBIC EASE_IN]")
	if _golem.has_method("play_trunk_rip"):
		_golem.call("play_trunk_rip")

	# Capture runs via _process at CAPTURE_INTERVAL during the anim
	# Phase annotations via timed label updates for context in each frame
	await get_tree().create_timer(0.48).timeout
	_set_labels("trunk_rip", "P2 STRAIN — near-stillness HOLD then micro-tremor [the key phase]")

	await get_tree().create_timer(0.44).timeout
	_set_labels("trunk_rip", "P3 WRENCH — explosive EXPO+LINEAR, 6f, both arms snap fwd")

	await get_tree().create_timer(0.25).timeout
	_set_labels("trunk_rip", "P4 RECOVERY — overshoot + 3 diminishing settle oscillations")

	# Wait for the full animation + a tiny tail for the final settled frame
	await get_tree().create_timer(1.10).timeout
	_capture_done = true


func _set_labels(clip: String, hint: String) -> void:
	if _label != null:
		_label.text = clip
	if _phase_label != null:
		_phase_label.text = hint


func _add_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	_sv.add_child(cl)

	_label = Label.new()
	_label.position = Vector2(14, 10)
	_label.add_theme_font_size_override("font_size", 20)
	_label.text = "trunk_rip capture"
	_label.modulate = Color(1.0, 0.85, 0.3)   # yellow — distinct from the regular capture
	cl.add_child(_label)

	_phase_label = Label.new()
	_phase_label.position = Vector2(14, 36)
	_phase_label.add_theme_font_size_override("font_size", 12)
	_phase_label.text = ""
	cl.add_child(_phase_label)

	var legend := Label.new()
	legend.position = Vector2(14, SV_SIZE.y - 22)
	legend.add_theme_font_size_override("font_size", 10)
	legend.modulate = Color(0.8, 0.8, 0.8, 0.85)
	legend.text = ("Interval %.3fs (~%.0f fps review)   |   Spec: P1 0-7  P2 8-14  P3 15-18  P4 18+"
		% [CAPTURE_INTERVAL, 1.0 / CAPTURE_INTERVAL])
	cl.add_child(legend)


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
	box.size = Vector3(0.30, 1.8, 0.30)
	post.mesh = box
	post.position = Vector3(3.0, 0.9, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.35, 0.28)
	post.material_override = mat
	_sv.add_child(post)
