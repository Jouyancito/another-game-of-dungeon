extends Node3D
## Golem MOVESET preview viewer — Phase A animations (REWORK 2026-06-14).
## Open scenes/dev/golem_moveset_preview.tscn and press F6.
##
## Cycles through the full moveset so Joan can review each clip in order:
##
##   dormant → awaken → idle → lumber → trunk_rip → trunk_sweep(x3)
##   → attack_basic → attack_charged → stomp → rock_throw → root_snare
##   → hit_react → death → (reset → dormant → repeat)
##
## Controls:
##   Left-drag  = orbit camera
##   Mouse wheel = zoom
##   SPACE       = skip current clip (advance to next)
##
## On-screen label shows the current clip name + weight note.
##
## REWORK NOTES:
##   - Animations now drive LIMB GROUPS (cohesive limb motion)
##   - Spring-damper sway active in _physics_process on golem script
##   - death = physics RigidBody3D collapse (not tween scatter)
##   - dormant reads as flat rock pile (not biped silhouette)

var _target := Vector3(0.0, 2.5, 0.0)
var _yaw    := 0.7
var _pitch  := 0.28
var _dist   := 8.5   # FIX 3: was 14.0 — golem fills more of the frame
var _cam: Camera3D
var _dragging := false
var _golem: Node   = null

var _label: Label         = null
var _hint_label: Label    = null
var _skip := false        # set true by SPACE to jump to next clip


func _place_window_on_2nd_screen() -> void:
	## Move the preview to a NON-PRIMARY monitor if present, so it doesn't cover
	## Joan's main screen while it loops (his request, 2026-06-14).
	## IMPORTANT: if the editor's "Embed Game on Play" is ON, the game runs INSIDE
	## the editor and this CANNOT move it — turn that toggle OFF (Game panel
	## toolbar) so it opens as a separate window. For a fully background, no-window
	## capture, use golem_capture_move.tscn (off-screen SubViewport — no window).
	if DisplayServer.get_screen_count() <= 1:
		return
	var primary := DisplayServer.get_primary_screen()
	for s in DisplayServer.get_screen_count():
		if s != primary:
			DisplayServer.window_set_current_screen(s)
			break


func _ready() -> void:
	_place_window_on_2nd_screen()
	_add_lights()
	_add_environment()
	_add_scale_reference()

	var golem_scene := load("res://scenes/enemy/golem_assembly.tscn")
	_golem = golem_scene.instantiate()
	add_child(_golem)
	# Freeze AI/physics — this is a pure animation viewer
	if _golem is Node:
		_golem.set_physics_process(false)
		_golem.set_process(false)

	_cam = Camera3D.new()
	_cam.fov = 65.0
	add_child(_cam)
	_cam.current = true

	_add_hud()

	# Wait for chunks to load, then run the cycle
	for _i in range(60):
		await get_tree().process_frame

	while is_inside_tree():
		await _run_cycle()


# ---------------------------------------------------------------------------
# Main cycle
# ---------------------------------------------------------------------------
func _run_cycle() -> void:
	## ── dormant ──────────────────────────────────────────────────────────
	## KEY CHECK: should read as a FLAT ROCK FORMATION, not a biped silhouette.
	## No clear head/arms/legs visible — just stones on the ground.
	_set_label("dormant", "FLAT pile — looks like terrain, no biped silhouette")
	_skip = false
	if _golem.has_method("_sleep"):
		_golem.call("_sleep")
	await _wait_interruptible(3.0)

	## ── awaken ───────────────────────────────────────────────────────────
	## KEY CHECK: BASE (feet/rubble) rises first, TORSO follows, HEAD last.
	## TRANS_BACK overshoot as heavy masses lock into place = settling weight.
	_set_label("awaken", "GROUND FIRST → torso → shoulders → head  [joint stagger]")
	_skip = false
	if _golem.has_method("_awaken"):
		_golem.call("_awaken")
	await _wait_interruptible(5.2)

	## ── idle ─────────────────────────────────────────────────────────────
	## KEY CHECK: whole TORSO GROUP sways as one unit, not individual chunks.
	## Spring-damper back lags behind. Arms counter-sway.
	_set_label("idle", "TORSO GROUP sway — cohesive, spring back lags")
	_skip = false
	if _golem.has_method("play_idle"):
		_golem.call("play_idle")
	await _wait_interruptible(5.5)

	## ── lumber ───────────────────────────────────────────────────────────
	## KEY CHECK: HIP DROP on each foot plant (not just side-to-side lean).
	## Arm GROUPS swing as whole units. TORSO dips down on plant side.
	_set_label("lumber", "HIP DROP on plant — arms swing as whole groups, not chunks")
	_skip = false
	if _golem.has_method("play_lumber"):
		_golem.call("play_lumber")
	await _wait_interruptible(5.5)

	## ── trunk_rip ────────────────────────────────────────────────────────
	## KEY CHECK: 3 phases — REACH (slow), STRAIN (near-stillness), WRENCH (fast snap).
	## The strain hold sells mass — a light creature would yank instantly.
	_set_label("trunk_rip", "REACH (slow) → STRAIN HOLD → WRENCH (explosive)  [LOTR troll]")
	_skip = false
	if _golem.has_method("play_trunk_rip"):
		_golem.call("play_trunk_rip")
	await _wait_interruptible(3.8)

	## ── trunk_sweep x3 ───────────────────────────────────────────────────
	## KEY CHECK: ESCALATION — swing 1 telegraphed, swing 2 faster+wider,
	## swing 3 over-committed (stumble). Recovery gets LONGER each time.
	_set_label("trunk_sweep (3x)", "ESCALATES: controlled → faster+wider → over-committed stumble")
	_skip = false
	if _golem.has_method("play_trunk_sweep"):
		_golem.call("play_trunk_sweep")
	await _wait_interruptible(7.5)

	## ── attack_basic ─────────────────────────────────────────────────────
	## KEY CHECK: ARM_R GROUP rises as unit (not individual forearm/fist chunks).
	## 2-frame impact freeze at slam. Head leads 1 beat before torso.
	_set_label("attack_basic", "ARM GROUP rises → 2-frame freeze at slam  [head leads]")
	_skip = false
	if _golem.has_method("play_attack_basic"):
		_golem.call("play_attack_basic")
	await _wait_interruptible(2.2)

	## ── attack_charged ───────────────────────────────────────────────────
	## KEY CHECK: BOTH ARM GROUPS rise together. 0.4s trembling hold at peak.
	## Torso leans BACK during raise, CRASHES forward on slam (gravity).
	_set_label("attack_charged", "BOTH ARM GROUPS + back-lean → trembling hold → CRASH")
	_skip = false
	if _golem.has_method("play_attack_charged"):
		_golem.call("play_attack_charged")
	await _wait_interruptible(4.2)

	## ── stomp ────────────────────────────────────────────────────────────
	## KEY CHECK: LEG_L GROUP rises and plants. Hip-drop on impact.
	## 2-frame freeze + Engine.time_scale dip at impact.
	_set_label("stomp", "LEG GROUP rises → hip-drop → freeze + slowmo at impact")
	_skip = false
	if _golem.has_method("play_stomp"):
		_golem.call("play_stomp")
	await _wait_interruptible(2.8)

	## ── rock_throw ───────────────────────────────────────────────────────
	## KEY CHECK: ARM_R GROUP scoops as unit (fist+fore+upper together).
	## Torso loads opposite direction, then rotates through on throw.
	_set_label("rock_throw", "ARM GROUP scoops → wind-up → THROW  [torso counter-rotate]")
	_skip = false
	if _golem.has_method("play_rock_throw"):
		_golem.call("play_rock_throw")
	await _wait_interruptible(3.2)

	## ── root_snare ───────────────────────────────────────────────────────
	## KEY CHECK: BOTH ARM GROUPS go down together (not staggered).
	## Knuckle-drag lean. 0.9s channel hold. Heave up = overshoot.
	_set_label("root_snare", "BOTH ARMS plant → channel hold → HEAVE  [knuckle-drag]")
	_skip = false
	if _golem.has_method("play_root_snare"):
		_golem.call("play_root_snare")
	await _wait_interruptible(3.8)

	## ── hit_react ────────────────────────────────────────────────────────
	## KEY CHECK: minimal — the golem barely registers the hit (it's a mountain).
	## Head snaps back, torso twitches. 0.8s total.
	_set_label("hit_react", "BRIEF stagger — barely registers (it is a mountain)")
	_skip = false
	if _golem.has_method("play_hit_react"):
		_golem.call("play_hit_react")
	await _wait_interruptible(1.5)

	## ── death ────────────────────────────────────────────────────────────
	## KEY CHECK: topples forward slowly (felled tree). Then RigidBody3D
	## physics takes over — chunks scatter with real gravity and inertia.
	## NOT the reverse of assembly. NOT a tween scatter.
	_set_label("death", "TOPPLE (felled tree) → RigidBody3D chunks scatter w/ physics")
	_skip = false
	if _golem.has_method("play_death"):
		_golem.call("play_death")
	await _wait_interruptible(4.2)

	## ── reset ────────────────────────────────────────────────────────────
	_set_label("(resetting…)", "")
	await _wait(0.8)
	if _golem.has_method("reset_to_stand"):
		_golem.call("reset_to_stand")
	await _wait(1.2)


# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _wait_interruptible(seconds: float) -> void:
	## Waits up to `seconds` but breaks early if SPACE is pressed.
	var elapsed := 0.0
	while elapsed < seconds and not _skip:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	_skip = false


func _set_label(clip_name: String, hint: String) -> void:
	if _label != null:
		_label.text = clip_name
	if _hint_label != null:
		_hint_label.text = hint + "   [SPACE = skip]"


# ---------------------------------------------------------------------------
# HUD — CanvasLayer + Label so the clip name is always visible
# ---------------------------------------------------------------------------
func _add_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)

	## Clip name — large, top-left
	_label = Label.new()
	_label.position = Vector2(24, 20)
	_label.add_theme_font_size_override("font_size", 32)
	_label.text = "golem_moveset_preview"
	cl.add_child(_label)

	## Hint / controls — smaller, below clip name
	_hint_label = Label.new()
	_hint_label.position = Vector2(24, 64)
	_hint_label.add_theme_font_size_override("font_size", 16)
	_hint_label.text = "Left-drag: orbit   Wheel: zoom   SPACE: skip"
	cl.add_child(_hint_label)

	## Scale legend — bottom-left
	var legend := Label.new()
	legend.position = Vector2(24, 740)
	legend.add_theme_font_size_override("font_size", 14)
	legend.modulate = Color(0.8, 0.8, 0.8, 0.85)
	legend.text = "Ref post = 1.8 m (player height)   |   Target golem ~4.5-5 m"
	cl.add_child(legend)


# ---------------------------------------------------------------------------
# Lights + environment (same as golem_assembly_preview.gd but slightly warmer)
# ---------------------------------------------------------------------------
func _add_lights() -> void:
	## KEY: warm directional (D2-Act-1 hybrid — warm key light from upper left)
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.95, 0.85)
	key.light_energy = 1.55
	key.rotation_degrees = Vector3(-48, 140, 0)
	key.shadow_enabled = true
	add_child(key)

	## FILL: cool directional (non-black shadow fill, canon §1)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.55, 0.66, 0.92)
	fill.light_energy = 0.55
	fill.rotation_degrees = Vector3(-55, -38, 0)
	add_child(fill)

	## BACK/RIM: second warm light from behind to read the silhouette vs sky
	var back := DirectionalLight3D.new()
	back.light_color = Color(0.80, 0.72, 0.60)
	back.light_energy = 0.30
	back.rotation_degrees = Vector3(-20, -155, 0)
	add_child(back)


func _add_environment() -> void:
	var env := Environment.new()
	# Dark-neutral background — prevents bright sky from bleeding through sparse
	# foliage geometry and making the tree canopy read as a white cloud.
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.18, 0.20, 0.24)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.44, 0.58)
	env.ambient_light_energy = 0.60
	# Glow on but only for the cyan eyes — set HDR threshold high (1.2) so
	# normal-bright surfaces (foliage albedo ~0.48) are excluded from bloom.
	env.glow_enabled = true
	env.glow_hdr_threshold = 1.2
	env.glow_intensity = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _add_scale_reference() -> void:
	## 1.8m human post — so the golem's scale reads as imposing in every screenshot
	var post := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.35, 1.8, 0.35)
	post.mesh = box
	post.position = Vector3(3.2, 0.9, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.35, 0.28)
	post.material_override = mat
	add_child(post)


# ---------------------------------------------------------------------------
# Camera orbit
# ---------------------------------------------------------------------------
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT:
			_dragging = e.pressed
		elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = maxf(3.0, _dist - 0.6)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(18.0, _dist + 0.6)
	elif e is InputEventMouseMotion and _dragging:
		_yaw -= e.relative.x * 0.010
		_pitch = clampf(_pitch - e.relative.y * 0.010, -1.3, 1.3)
	elif e is InputEventKey and e.pressed:
		if e.keycode == KEY_SPACE:
			_skip = true


func _process(_delta: float) -> void:
	if _cam == null:
		return
	var off := Vector3(
		cos(_pitch) * sin(_yaw),
		sin(_pitch),
		cos(_pitch) * cos(_yaw)
	) * _dist
	_cam.position = _target + off
	_cam.look_at(_target, Vector3.UP)
