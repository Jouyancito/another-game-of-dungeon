extends GutTest

const TitleScene := preload("res://scenes/ui/title_screen.tscn")

var _calls: Array = []


func _make() -> Node3D:
	_calls.clear()
	var s: Node3D = TitleScene.instantiate()
	s.transition_fn = func(path: String) -> void: _calls.append(path)
	add_child_autofree(s)
	return s


func _run(s: Node3D, seconds: float) -> void:
	var step := 1.0 / 30.0
	var elapsed := 0.0
	while elapsed < seconds:
		s.advance(step)
		elapsed += step


func test_starts_in_dark_state() -> void:
	var s := _make()
	assert_eq(s.state, s.State.DARK)
	assert_false(s.is_idle())
	# Starts exactly on the splash's end color: veil opaque, fire unlit.
	assert_eq(s.DUNGEON_DARK, Color("#120d0b"))
	assert_eq(s._veil.color, s.DUNGEON_DARK)
	assert_almost_eq(s._veil.modulate.a, 1.0, 0.001)
	assert_almost_eq(s._fire_light.light_energy, 0.0, 0.001)


func test_fire_ignites_before_torch() -> void:
	var s := _make()
	_run(s, 1.0)
	assert_eq(s.state, s.State.INTRO)
	assert_gt(s._fire_light.light_energy, 0.2)
	assert_almost_eq(s._torch_light.light_energy, 0.0, 0.001)


func test_intro_ends_idle_within_budget() -> void:
	var s := _make()
	_run(s, 4.5)
	assert_true(s.is_idle())
	assert_almost_eq(s._menu.modulate.a, 1.0, 0.01)


func test_skip_jumps_to_idle() -> void:
	var s := _make()
	_run(s, 0.5)
	s.skip()
	assert_true(s.is_idle())


func test_jugar_uses_main_menu_flow() -> void:
	var s := _make()
	s.skip()
	s._btn_jugar.pressed.emit()
	assert_eq(_calls, ["res://scenes/ui/character_select.tscn"])
	assert_eq(GameManager.target_scene, "res://scenes/levels/floor1_prairie.tscn")
	assert_true(GameManager.requires_world_select)
	s._btn_jugar.pressed.emit()
	assert_eq(_calls.size(), 1, "transition fires once")


func test_wheel_does_not_skip() -> void:
	var s := _make()
	var ev := InputEventMouseButton.new()
	ev.pressed = true
	ev.button_index = MOUSE_BUTTON_WHEEL_UP
	s._input(ev)
	assert_false(s.is_idle())


func test_eye_blink_is_brief_and_not_constant() -> void:
	var s := _make()
	s.skip()
	var closed := 0
	var frames := 0
	for i in 900:  # 30 s
		s.advance(1.0 / 30.0)
		for e in s._eyes:
			frames += 1
			if e.node.scale.y < 0.5:
				closed += 1
	assert_gt(closed, 0, "eyes blink")
	assert_lt(float(closed) / frames, 0.1, "eyes are open most of the time")
