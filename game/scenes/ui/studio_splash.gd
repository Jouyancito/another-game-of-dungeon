extends Control
## Studio splash: draws an angular faceted purple bunny head, fades to black,
## then loads the main menu. Any key / click / gamepad button skips.

const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"
## Studio name is pending owner decision.
const STUDIO_NAME := "AwAdeUwU"
## Name font: Russo One (owner choice, SIL OFL 1.1). Single swap point.
@export var name_font: Font = preload("res://tools/logo/fonts/RussoOne-Regular.ttf")

const BG_COLOR := Color("#f4ecdc")
const OUTLINE_COLOR := Color("#3b1f86")
const EAR_COLOR := Color("#6440c9")
const INNER_EAR_COLOR := Color("#c4a8ff")
const NOSE_COLOR := Color("#2a1660")
const FACET_COLORS: Array[Color] = [
	Color("#6b3fd4"), Color("#8a60f0"), Color("#5a31b8"), Color("#7d52e6"),
	Color("#6440c9"), Color("#9370f2"), Color("#5534ad"),
]

const FADE_START := 2.95
const FADE_END := 3.5
const TOTAL_DURATION := 3.6

const EAR_L: Array[Vector2] = [Vector2(-0.30, -0.16), Vector2(-0.46, -0.98), Vector2(-0.21, -1.03), Vector2(-0.07, -0.22)]
const IN_L: Array[Vector2] = [Vector2(-0.26, -0.26), Vector2(-0.37, -0.86), Vector2(-0.25, -0.89), Vector2(-0.14, -0.28)]
const HEAD: Array[Vector2] = [
	Vector2(-0.54, 0.04), Vector2(-0.31, -0.23), Vector2(0.31, -0.23), Vector2(0.54, 0.04),
	Vector2(0.45, 0.47), Vector2(0, 0.70), Vector2(-0.45, 0.47),
]
const HEAD_CENTER := Vector2(0, 0.17)
const EYE_L: Array[Vector2] = [Vector2(-0.27, 0.10), Vector2(-0.13, 0.06), Vector2(-0.19, 0.18)]
const NOSE: Array[Vector2] = [Vector2(-0.06, 0.36), Vector2(0.06, 0.36), Vector2(0, 0.44)]
const EAR_PIVOT := Vector2(0.16, -0.2)

## Elapsed time in seconds. Public so tools/tests can drive it deterministically.
var t := 0.0
## Test hook: if valid, called with the scene path instead of changing scene.
var transition_fn := Callable()
var _transitioned := false
var _u := 1.0
var _c := Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if t >= TOTAL_DURATION:
		go_to_menu()


func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event is InputEventMouseMotion:
		return
	if event is InputEventKey and event.echo:
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		go_to_menu()


## Runs the transition exactly once, no matter how many triggers fire.
func go_to_menu() -> void:
	if _transitioned:
		return
	_transitioned = true
	if transition_fn.is_valid():
		transition_fn.call(MAIN_MENU_PATH)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_PATH)


# --- drawing -----------------------------------------------------------

static func seg(time: float, start: float, dur: float) -> float:
	return smoothstep(0.0, 1.0, clampf((time - start) / dur, 0.0, 1.0))


static func mirrored(pts: Array[Vector2]) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in range(pts.size() - 1, -1, -1):
		out.append(Vector2(-pts[i].x, pts[i].y))
	return out


func _px(p: Vector2) -> Vector2:
	return _c + p * _u


func _poly(pts: Array[Vector2], col: Color) -> void:
	var out := PackedVector2Array()
	for p in pts:
		out.append(_px(p))
	draw_colored_polygon(out, col)


func _twitch(pts: Array[Vector2]) -> Array[Vector2]:
	var ang := -0.2 * sin(PI * seg(t, 1.65, 2.05))
	var out: Array[Vector2] = []
	for p in pts:
		out.append(EAR_PIVOT + (p - EAR_PIVOT).rotated(ang))
	return out


func _draw() -> void:
	_u = minf(size.x, size.y) * 0.30
	_c = Vector2(size.x * 0.5, size.y * 0.47)
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)
	_draw_garden(t)

	var ear_l := EAR_L
	var ear_r := _twitch(mirrored(EAR_L))
	var in_l := IN_L
	var in_r := _twitch(mirrored(IN_L))

	_poly(ear_l, _alpha(EAR_COLOR, seg(t, 0.62, 0.22)))
	_poly(ear_r, _alpha(EAR_COLOR, seg(t, 0.62, 0.22)))
	var a_in := seg(t, 0.74, 0.22)
	_poly(in_l, _alpha(INNER_EAR_COLOR, a_in))
	_poly(in_r, _alpha(INNER_EAR_COLOR, a_in))

	for i in HEAD.size():
		var a := seg(t, 0.72 + i * 0.07, 0.22)
		if a > 0.0:
			_poly([HEAD_CENTER, HEAD[i], HEAD[(i + 1) % HEAD.size()]],
				_alpha(FACET_COLORS[i % FACET_COLORS.size()], a))

	var a_face := seg(t, 1.35, 0.22)
	if a_face > 0.0:
		_poly(EYE_L, _alpha(BG_COLOR, a_face))
		_poly(mirrored(EYE_L), _alpha(BG_COLOR, a_face))
		_poly(NOSE, _alpha(NOSE_COLOR, a_face))

	_draw_outline(ear_l, ear_r)

	var a_name := seg(t, 1.85, 0.4)
	if a_name > 0.0:
		var font: Font = name_font if name_font else ThemeDB.fallback_font
		var fs := int(_u * 0.28)
		draw_string(font, Vector2(0, _c.y + _u * 1.05), STUDIO_NAME,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, _alpha(OUTLINE_COLOR, a_name))

	var fade := seg(t, FADE_START, FADE_END - FADE_START)
	if fade > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, fade))


## TODO: geometric flowers growing along the bottom edge (design pending owner approval).
func _draw_garden(_time: float) -> void:
	pass


static func _alpha(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)


## Strokes ear_l, ear_r, head in order as one progressive path of fraction p.
func _draw_outline(ear_l: Array[Vector2], ear_r: Array[Vector2]) -> void:
	var p := seg(t, 0.08, 0.92)
	if p <= 0.0:
		return
	var loops: Array = [ear_l, ear_r, HEAD]
	var total := 0.0
	for loop in loops:
		total += _loop_length(loop)
	var remaining := p * total
	var w := _u * 0.028
	for loop in loops:
		var pts := PackedVector2Array()
		for q in loop:
			pts.append(_px(q))
		pts.append(pts[0])
		var drawn := PackedVector2Array([pts[0]])
		for i in range(1, pts.size()):
			var d := pts[i - 1].distance_to(pts[i])
			if remaining >= d:
				drawn.append(pts[i])
				remaining -= d
			else:
				drawn.append(pts[i - 1].lerp(pts[i], remaining / d))
				remaining = 0.0
				break
		if drawn.size() >= 2:
			for i in range(drawn.size() - 1):
				draw_line(drawn[i], drawn[i + 1], OUTLINE_COLOR, w)
				draw_circle(drawn[i + 1], w * 0.5, OUTLINE_COLOR)
		if remaining <= 0.0:
			break


func _loop_length(loop: Array) -> float:
	var l := 0.0
	for i in loop.size():
		l += _px(loop[i]).distance_to(_px(loop[(i + 1) % loop.size()]))
	return l
