extends Node3D
## golem_capture_move.gd — Parameterized dense-frame capture for ANY golem move.
##
## Captures 28-32 dense frames of a single move into:
##   game/tools/godot/anim_capture/<move>/frame_NNN.png
##
## NON-INTRUSIVE: off-screen SubViewport (main window parked at -4000,-4000,
## size 1x1, FLAG_NO_FOCUS). Never steals focus from Joan's screen.
##
## Run (Godot 4.6 win64):
##   Godot_v4.6.2-stable_win64.exe --path game \
##     res://scenes/dev/golem_capture_move.tscn -- <move>
##
## <move> must be one of:
##   idle  lumber  attack_basic  attack_charged  stomp  rock_throw
##   root_snare  trunk_rip  trunk_sweep  hit_react  death  awaken
##
## Example:
##   Godot_v4.6.2-stable_win64.exe --path game \
##     res://scenes/dev/golem_capture_move.tscn -- trunk_rip
##
## All 12 moves (PowerShell one-liner):
##   $godot = "Godot_v4.6.2-stable_win64.exe"; $moves = @("idle","lumber","attack_basic","attack_charged","stomp","rock_throw","root_snare","trunk_rip","trunk_sweep","hit_react","death","awaken"); foreach ($m in $moves) { & $godot --path game res://scenes/dev/golem_capture_move.tscn -- $m }

const SV_SIZE := Vector2i(720, 810)

## Per-move config: [interval_s, max_frames, duration_s, cam_dist, cam_target_y, cam_yaw, cam_pitch, label_hint]
## interval_s × max_frames should cover duration_s plus a short tail.
## ~28-32 frames per move is the target (interval chosen accordingly).
const MOVE_CONFIG := {
	"idle":           [0.18,  30, 5.0,   8.2, 2.4,  0.7,  0.26, "GENTLE TORSO SWAY — loop, mass reads vs. spring lag"],
	"lumber":         [0.16,  32, 4.5,   8.0, 2.2,  0.7,  0.24, "HIP DROP per step — body dips on plant side (EXPO EASE_IN)"],
	"attack_basic":   [0.06,  30, 1.6,   7.5, 2.6,  0.6,  0.30, "WIND-UP BACK → SLAM FORWARD — 2f freeze at impact"],
	"attack_charged": [0.12,  32, 3.5,   7.5, 2.5,  0.6,  0.28, "BACK-LEAN → TREMOR HOLD → CRASH — longest commit"],
	"stomp":          [0.08,  30, 2.2,   7.8, 2.2,  0.75, 0.22, "BODY DIPS LEFT → CRASH + FREEZE — feel the leg raise"],
	"rock_throw":     [0.10,  30, 2.8,   7.8, 2.4,  0.5,  0.26, "SCOOP LOAD → TORSO UNCOIL THROW — counter-rotate"],
	"root_snare":     [0.12,  30, 3.4,   7.5, 2.0,  0.7,  0.20, "DEEP FORWARD LEAN → HOLD → HEAVE — knuckle-drag"],
	"trunk_rip":      [0.07,  32, 2.3,   6.8, 2.8,  0.55, 0.22, "GRIP(slow) → STRAIN HOLD → WRENCH(EXPO) → RECOVER"],
	"trunk_sweep":    [0.22,  32, 6.5,   7.0, 2.6,  0.5,  0.24, "3 ESCALATING SWEEPS — arc widens, recover lengthens"],
	"hit_react":      [0.04,  30, 0.9,   7.5, 2.5,  0.65, 0.28, "BRIEF STAGGER — barely registers (it is a mountain)"],
	"death":          [0.10,  32, 3.2,   8.5, 2.0,  0.7,  0.22, "RECOGNITION DELAY → LEAN → PHYSICS SCATTER"],
	"awaken":         [0.12,  32, 3.8,   8.5, 2.2,  0.7,  0.24, "GROUND FIRST → torso → shoulders → head [stagger]"],
}

var _move_name: String = ""
var _config: Array    = []

var _cam: Camera3D
var _golem: Node    = null
var _label: Label   = null
var _phase_label: Label = null
var _sv: SubViewport = null

var _target := Vector3(0.0, 2.5, 0.0)
var _yaw    := 0.7
var _pitch  := 0.25
var _dist   := 7.5

var _frame_index  := 0
var _capture_done := false
var _capture_acc  := 0.0
var _capture_interval := 0.10
var _max_frames := 30
var _out_dir := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("golem_capture_move: usage -- <move>")
		get_tree().quit(1)
		return

	_move_name = args[0].strip_edges().to_lower()
	if not MOVE_CONFIG.has(_move_name):
		push_error("golem_capture_move: unknown move '%s'. Valid: %s" % [_move_name, str(MOVE_CONFIG.keys())])
		get_tree().quit(1)
		return

	_config = MOVE_CONFIG[_move_name]
	_capture_interval = float(_config[0])
	_max_frames       = int(_config[1])
	# _config[2] = duration, used for timing in _run_move()
	_dist   = float(_config[3])
	_target = Vector3(0.0, float(_config[4]), 0.0)
	_yaw    = float(_config[5])
	_pitch  = float(_config[6])
	_out_dir = "res://tools/godot/anim_capture/%s/" % _move_name

	# ── NON-INTRUSIVE: park main window off-screen ────────────────────────────
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

	# ── Scene content in SubViewport ──────────────────────────────────────────
	_add_lights()
	_add_environment()
	_add_scale_reference()

	var golem_scene := load("res://scenes/enemy/golem_assembly.tscn")
	_golem = golem_scene.instantiate()
	_sv.add_child(_golem)
	# Disable autonomous process — we drive manually except spring (re-enabled below)
	if _golem is Node:
		_golem.set_physics_process(false)
		_golem.set_process(false)

	_cam = Camera3D.new()
	_cam.fov = 56.0
	_sv.add_child(_cam)
	_cam.current = true

	_add_hud()

	# Ensure output dir exists
	var da := DirAccess.open("res://")
	if da:
		da.make_dir_recursive("tools/godot/anim_capture/%s" % _move_name)

	# Wait for GLB chunks, materials, EnemyModelFitter to settle
	for _i in range(60):
		await get_tree().process_frame

	await _run_move()
	await get_tree().create_timer(0.5).timeout
	print("[golem_capture_move] Done '%s': %d frames → %s" % [_move_name, _frame_index, _out_dir])
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
	if _capture_acc >= _capture_interval:
		_capture_acc -= _capture_interval
		_save_frame()


func _save_frame() -> void:
	if _frame_index >= _max_frames or _sv == null:
		return
	await RenderingServer.frame_post_draw
	var img := _sv.get_texture().get_image()
	if img == null:
		push_warning("[golem_capture_move] SubViewport returned null at frame %d" % _frame_index)
		return
	var path := _out_dir + "frame_%03d.png" % _frame_index
	var err := img.save_png(path)
	if err == OK:
		print("[golem_capture_move:%s] Saved %s" % [_move_name, path])
	else:
		push_warning("[golem_capture_move] save_png failed frame_%03d (err=%d)" % [_frame_index, err])
	_frame_index += 1


# ---------------------------------------------------------------------------
# Move dispatch — sets up the golem and runs the animation for timing.
# ---------------------------------------------------------------------------
func _run_move() -> void:
	var duration: float = float(_config[2])
	var hint: String    = str(_config[7])

	_set_labels(_move_name, hint)

	# For most moves: reset to stand (awake, lights on), enable spring damper.
	match _move_name:
		"awaken":
			# Start in pile/sleep, then awaken
			if _golem.has_method("_sleep"):
				_golem.call("_sleep")
			# Brief pre-roll to show pile state
			await get_tree().create_timer(0.30).timeout
			_set_labels("awaken", "DORMANT PILE — pebbles rattle, then chunks assemble bottom→up")
			if _golem.has_method("_awaken"):
				_golem.call("_awaken")
			if _golem is Node:
				_golem.set_physics_process(true)
			await get_tree().create_timer(duration).timeout

		"death":
			# Start from stand, awake
			_reset_to_stand_awake()
			if _golem is Node:
				_golem.set_physics_process(true)
			await get_tree().create_timer(0.20).timeout
			if _golem.has_method("play_death"):
				_golem.call("play_death")
			await get_tree().create_timer(duration).timeout

		"idle":
			_reset_to_stand_awake()
			if _golem is Node:
				_golem.set_physics_process(true)
			await get_tree().create_timer(0.20).timeout
			if _golem.has_method("play_idle"):
				_golem.call("play_idle")
			await get_tree().create_timer(duration).timeout

		"lumber":
			_reset_to_stand_awake()
			if _golem is Node:
				_golem.set_physics_process(true)
			await get_tree().create_timer(0.20).timeout
			if _golem.has_method("play_lumber"):
				_golem.call("play_lumber")
			await get_tree().create_timer(duration).timeout

		"trunk_rip":
			_reset_to_stand_awake()
			if _golem is Node:
				_golem.set_physics_process(true)
			await get_tree().create_timer(0.20).timeout
			_set_labels("trunk_rip", "P1 GRIP ANTICIPATION — body leans back as one mass [CUBIC EIN]")
			if _golem.has_method("play_trunk_rip"):
				_golem.call("play_trunk_rip")
			# Phase annotation updates
			await get_tree().create_timer(0.48).timeout
			_set_labels("trunk_rip", "P2 STRAIN — near-stillness HOLD + micro-tremor (mass sell)")
			await get_tree().create_timer(0.44).timeout
			_set_labels("trunk_rip", "P3 WRENCH — EXPO+LINEAR 6f, body snaps fwd, trunk yanks free")
			await get_tree().create_timer(0.25).timeout
			_set_labels("trunk_rip", "P4 RECOVERY — recoil -4° → settle 2° forward (trunk weight)")
			await get_tree().create_timer(1.20).timeout

		"trunk_sweep":
			# trunk_sweep requires the trunk to already be in hand — call trunk_rip silently first
			_reset_to_stand_awake()
			if _golem is Node:
				_golem.set_physics_process(true)
			# Quick setup: manually rip the tree without capturing
			_golem.set("_has_tree", true)
			if _golem.has_method("_on_tree_ripped_new"):
				_golem.call("_on_tree_ripped_new")
			# Set trunk weapon to held position
			var tw_node = _golem.get("_trunk_weapon")
			if tw_node != null:
				tw_node.position = Vector3(-1.1, 0.5, 0.3)
				tw_node.rotation_degrees = Vector3(-20.0, 15.0, 0.0)
				tw_node.scale = Vector3(0.22, 0.22, 0.22)
				tw_node.visible = true
			await get_tree().create_timer(0.20).timeout
			_set_labels("trunk_sweep", "SWEEP 1 — controlled, 180° arc, lag/drag sells trunk weight")
			if _golem.has_method("play_trunk_sweep"):
				_golem.call("play_trunk_sweep")
			await get_tree().create_timer(2.0).timeout
			_set_labels("trunk_sweep", "SWEEP 2 — faster + wider 200° — golem commits more mass")
			await get_tree().create_timer(1.9).timeout
			_set_labels("trunk_sweep", "SWEEP 3 — barely controlled 220° — long punish recovery")
			await get_tree().create_timer(2.1).timeout

		"attack_basic":
			_reset_to_stand_awake()
			if _golem is Node:
				_golem.set_physics_process(true)
			await get_tree().create_timer(0.20).timeout
			if _golem.has_method("play_attack_basic"):
				_golem.call("play_attack_basic")
			await get_tree().create_timer(duration).timeout

		"attack_charged":
			_reset_to_stand_awake()
			if _golem is Node:
				_golem.set_physics_process(true)
			await get_tree().create_timer(0.20).timeout
			if _golem.has_method("play_attack_charged"):
				_golem.call("play_attack_charged")
			await get_tree().create_timer(duration).timeout

		"stomp":
			_reset_to_stand_awake()
			if _golem is Node:
				_golem.set_physics_process(true)
			await get_tree().create_timer(0.20).timeout
			if _golem.has_method("play_stomp"):
				_golem.call("play_stomp")
			await get_tree().create_timer(duration).timeout

		"rock_throw":
			_reset_to_stand_awake()
			if _golem is Node:
				_golem.set_physics_process(true)
			await get_tree().create_timer(0.20).timeout
			if _golem.has_method("play_rock_throw"):
				_golem.call("play_rock_throw")
			await get_tree().create_timer(duration).timeout

		"root_snare":
			_reset_to_stand_awake()
			if _golem is Node:
				_golem.set_physics_process(true)
			await get_tree().create_timer(0.20).timeout
			if _golem.has_method("play_root_snare"):
				_golem.call("play_root_snare")
			await get_tree().create_timer(duration).timeout

		"hit_react":
			_reset_to_stand_awake()
			if _golem is Node:
				_golem.set_physics_process(true)
			await get_tree().create_timer(0.20).timeout
			if _golem.has_method("play_hit_react"):
				_golem.call("play_hit_react")
			await get_tree().create_timer(duration).timeout

	_capture_done = true


func _reset_to_stand_awake() -> void:
	if _golem.has_method("reset_to_stand"):
		_golem.call("reset_to_stand")
	if _golem.has_method("_light_up_eyes"):
		_golem.call("_light_up_eyes")
	if "_is_dormant" in _golem or "is_dormant" in _golem:
		_golem.set("is_dormant", false)


func _set_labels(clip: String, hint: String) -> void:
	if _label != null:
		_label.text = clip
	if _phase_label != null:
		_phase_label.text = hint


# ---------------------------------------------------------------------------
# HUD — lives inside the SubViewport so it appears in captured frames
# ---------------------------------------------------------------------------
func _add_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	_sv.add_child(cl)

	_label = Label.new()
	_label.position = Vector2(14, 10)
	_label.add_theme_font_size_override("font_size", 20)
	_label.text = _move_name
	_label.modulate = Color(1.0, 0.85, 0.3)
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
	legend.text = ("golem_capture_move  |  interval %.3fs (~%.0f fps review)  |  max %d frames"
		% [_capture_interval, 1.0 / _capture_interval, _max_frames])
	cl.add_child(legend)


# ---------------------------------------------------------------------------
# Lights + environment — inside SubViewport
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
