extends Node3D
## Golem animation frame capture — runs ONE full moveset cycle, saves frames every
## 0.25 s into game/tools/godot/anim_capture/, then quits.
##
## NON-INTRUSIVE: renders into a SubViewport (off-screen render target).
## The main window is parked off-screen at (-4000,-4000) and shrunk to 1x1 px,
## so it never steals focus from Joan's work. The captured images come from the
## SubViewport texture, not the main viewport.
##
## Run command (from repo root, Godot 4.6 win64):
##   Godot_v4.6.2-stable_win64.exe --path game res://scenes/dev/golem_anim_capture.tscn
##
## Output: game/tools/godot/anim_capture/frame_NNN.png  (one per 0.25 s tick)
## Cap: 120 frames (~30 s of animation). Exits automatically when done.

const CAPTURE_INTERVAL := 0.25   # seconds between screenshots
const OUT_DIR          := "res://tools/godot/anim_capture/"
const MAX_FRAMES       := 120    # safety cap (120 frames × 0.25 s = 30 s)

## SubViewport size — large enough for clear review, small enough to be fast.
const SV_SIZE := Vector2i(640, 720)

var _cam: Camera3D
var _golem: Node   = null
var _label: Label  = null
var _hint_label: Label = null
var _sv: SubViewport = null   # off-screen render target

var _target := Vector3(0.0, 2.5, 0.0)
var _yaw    := 0.7
var _pitch  := 0.28
var _dist   := 8.5   # FIX 3: was 14.0 — golem was too small. 8.5 fills the frame.

# Capture state
var _frame_index  := 0
var _capture_done := false
var _capture_acc  := 0.0


func _ready() -> void:
	# ── NON-INTRUSIVE: park main window OFF-SCREEN and tiny ─────────────────
	# The SubViewport does the actual rendering; the main window is just a
	# host process and must not grab focus or cover Joan's screen.
	var win := get_window()
	win.size = Vector2i(1, 1)                                           # nearly invisible
	win.position = Vector2i(-4000, -4000)                               # off every monitor
	win.set_flag(Window.FLAG_NO_FOCUS, true)                            # never steal focus
	# Note: FLAG_POPUP is not settable on the main window on Windows — skip it.

	# ── Build off-screen SubViewport ─────────────────────────────────────────
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(SV_SIZE)
	add_child(svc)

	_sv = SubViewport.new()
	_sv.size = SV_SIZE
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.transparent_bg = false
	svc.add_child(_sv)

	# ── Scene content goes INTO the SubViewport ──────────────────────────────
	_add_lights()
	_add_environment()
	_add_scale_reference()

	var golem_scene := load("res://scenes/enemy/golem_assembly.tscn")
	_golem = golem_scene.instantiate()
	_sv.add_child(_golem)
	if _golem is Node:
		_golem.set_physics_process(false)
		_golem.set_process(false)

	_cam = Camera3D.new()
	_cam.fov = 65.0
	_sv.add_child(_cam)
	_cam.current = true

	_add_hud()

	# Wait for GLB chunks, EnemyModelFitter, materials to settle
	for _i in range(60):
		await get_tree().process_frame

	await _run_cycle()
	await get_tree().create_timer(0.5).timeout
	print("[anim_capture] Done: %d frames → %s" % [_frame_index, OUT_DIR])
	get_tree().quit()


# ---------------------------------------------------------------------------
# Process — camera orbit + frame capture tick (camera lives in SubViewport)
# ---------------------------------------------------------------------------
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
	# Grab the SubViewport texture (off-screen — no main-viewport dependency)
	await RenderingServer.frame_post_draw
	var img := _sv.get_texture().get_image()
	if img == null:
		push_warning("[anim_capture] SubViewport.get_image() returned null")
		return
	var path := OUT_DIR + "frame_%03d.png" % _frame_index
	var err := img.save_png(path)
	if err == OK:
		print("[anim_capture] frame_%03d.png" % _frame_index)
	else:
		push_warning("[anim_capture] save_png failed frame_%03d (err=%d)" % [_frame_index, err])
	_frame_index += 1


# ---------------------------------------------------------------------------
# Main cycle — same choreography as golem_moveset_preview.gd
# ---------------------------------------------------------------------------
func _run_cycle() -> void:
	_set_label("dormant", "FLAT pile — looks like terrain, no biped silhouette")
	if _golem.has_method("_sleep"):
		_golem.call("_sleep")
	await _wait(3.0)

	_set_label("awaken", "GROUND FIRST → torso → shoulders → head  [joint stagger]")
	if _golem.has_method("_awaken"):
		_golem.call("_awaken")
	await _wait(5.2)

	_set_label("idle", "TORSO GROUP sway — cohesive, spring back lags")
	if _golem.has_method("play_idle"):
		_golem.call("play_idle")
	await _wait(5.5)

	_set_label("lumber", "HIP DROP on plant — arms swing as whole groups, not chunks")
	if _golem.has_method("play_lumber"):
		_golem.call("play_lumber")
	await _wait(5.5)

	_set_label("trunk_rip", "REACH (slow) → STRAIN HOLD → WRENCH (explosive)  [LOTR troll]")
	if _golem.has_method("play_trunk_rip"):
		_golem.call("play_trunk_rip")
	await _wait(3.8)

	_set_label("trunk_sweep (3x)", "ESCALATES: controlled → faster+wider → over-committed stumble")
	if _golem.has_method("play_trunk_sweep"):
		_golem.call("play_trunk_sweep")
	await _wait(7.5)

	_set_label("attack_basic", "ARM GROUP rises → 2-frame freeze at slam  [head leads]")
	if _golem.has_method("play_attack_basic"):
		_golem.call("play_attack_basic")
	await _wait(2.2)

	_set_label("attack_charged", "BOTH ARM GROUPS + back-lean → trembling hold → CRASH")
	if _golem.has_method("play_attack_charged"):
		_golem.call("play_attack_charged")
	await _wait(4.2)

	_set_label("stomp", "LEG GROUP rises → hip-drop → freeze + slowmo at impact")
	if _golem.has_method("play_stomp"):
		_golem.call("play_stomp")
	await _wait(2.8)

	_set_label("rock_throw", "ARM GROUP scoops → wind-up → THROW  [torso counter-rotate]")
	if _golem.has_method("play_rock_throw"):
		_golem.call("play_rock_throw")
	await _wait(3.2)

	_set_label("root_snare", "BOTH ARMS plant → channel hold → HEAVE  [knuckle-drag]")
	if _golem.has_method("play_root_snare"):
		_golem.call("play_root_snare")
	await _wait(3.8)

	_set_label("hit_react", "BRIEF stagger — barely registers (it is a mountain)")
	if _golem.has_method("play_hit_react"):
		_golem.call("play_hit_react")
	await _wait(1.5)

	_set_label("death", "TOPPLE (felled tree) → RigidBody3D chunks scatter w/ physics")
	if _golem.has_method("play_death"):
		_golem.call("play_death")
	await _wait(4.2)

	_capture_done = true


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _set_label(clip_name: String, hint: String) -> void:
	if _label != null:
		_label.text = clip_name
	if _hint_label != null:
		_hint_label.text = hint


# ---------------------------------------------------------------------------
# HUD — lives in the SubViewport so it appears in captured frames
# ---------------------------------------------------------------------------
func _add_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	_sv.add_child(cl)

	_label = Label.new()
	_label.position = Vector2(14, 12)
	_label.add_theme_font_size_override("font_size", 22)
	_label.text = "golem_anim_capture"
	cl.add_child(_label)

	_hint_label = Label.new()
	_hint_label.position = Vector2(14, 42)
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.text = ""
	cl.add_child(_hint_label)

	var legend := Label.new()
	legend.position = Vector2(14, 696)
	legend.add_theme_font_size_override("font_size", 11)
	legend.modulate = Color(0.8, 0.8, 0.8, 0.85)
	legend.text = "Ref post = 1.8 m   |   Golem ~4.5-5 m"
	cl.add_child(legend)


# ---------------------------------------------------------------------------
# Lights + environment — inside SubViewport
# FIX: glow_enabled = false so foliage teal-green DOES NOT bloom to white.
# The cyan eyes use emission but their energy (1.6) is low enough to
# stay readable without a glow pass. If you want eye glow, enable it per
# environment and set glow_hdr_threshold high (>= 1.2) so normal-bright
# surfaces (albedo ~0.5) are excluded from the bloom pass.
# ---------------------------------------------------------------------------
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
	# Use a solid DARK-NEUTRAL background, NOT a procedural sky.
	# A bright sky (white near the sun) bleeds through sparse foliage geometry
	# and makes the tree canopy read as a white cloud. A neutral dark bg makes
	# the teal-green foliage silhouette read clearly with good contrast.
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.18, 0.20, 0.24)   # dark blue-gray
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.44, 0.58)
	env.ambient_light_energy = 0.60
	# GLOW OFF — ensures even emissive-adjacent surfaces don't bloom.
	env.glow_enabled = false
	var we := WorldEnvironment.new()
	we.environment = env
	_sv.add_child(we)


func _add_scale_reference() -> void:
	var post := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.35, 1.8, 0.35)
	post.mesh = box
	post.position = Vector3(3.2, 0.9, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.35, 0.28)
	post.material_override = mat
	_sv.add_child(post)
