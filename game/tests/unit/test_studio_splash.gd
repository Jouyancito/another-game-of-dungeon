extends GutTest

const SplashScene := preload("res://scenes/ui/studio_splash.tscn")

var _calls: Array = []


func _make() -> Control:
	_calls.clear()
	var s: Control = SplashScene.instantiate()
	s.transition_fn = func(path: String) -> void: _calls.append(path)
	add_child_autofree(s)
	return s


func test_targets_main_menu() -> void:
	var s := _make()
	assert_eq(s.MAIN_MENU_PATH, "res://scenes/ui/main_menu.tscn")
	assert_true(ResourceLoader.exists(s.MAIN_MENU_PATH))


func test_duration_within_bounds() -> void:
	var s := _make()
	assert_between(s.TOTAL_DURATION, 4.0, 5.0)


func test_skip_input_transitions_once() -> void:
	var s := _make()
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_SPACE
	s._input(ev)
	s._input(ev)
	s.go_to_menu()
	assert_eq(_calls.size(), 1)
	assert_eq(_calls[0], "res://scenes/ui/main_menu.tscn")


func test_timeout_transitions_once() -> void:
	var s := _make()
	s._process(s.TOTAL_DURATION + 0.1)
	s._process(0.1)
	assert_eq(_calls.size(), 1)
