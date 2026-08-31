extends Camera3D
## Free-fly debug camera. No collision, no player, just a floating eye.
##
## Controls:
##   WASD          = move forward/back/strafe (camera-relative)
##   Space / Ctrl  = up / down
##   Shift         = speed boost (x4)
##   Mouse         = look around (captured; ESC to release/quit)
##   Mouse wheel   = adjust base speed

var _speed := 18.0
var _yaw := 0.0
var _pitch := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	current = true
	rotation_order = EULER_ORDER_YXZ
	# Judgment Day fix (2026-07-21): sync _yaw/_pitch FROM the node's current
	# rotation (already reflecting whatever the caller's look_at() set — the
	# caller sets position/look_at before add_child(), and add_child() invokes
	# _ready() synchronously). Without this, _yaw/_pitch stayed at their 0.0
	# init value and the FIRST MouseMotion snapped rotation away from the
	# look_at()-set framing instantly.
	_pitch = rotation.x
	_yaw = rotation.y


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * 0.0025
		_pitch = clampf(_pitch - event.relative.y * 0.0025, -1.55, 1.55)
		rotation = Vector3(_pitch, _yaw, 0.0)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_speed = clampf(_speed * 1.2, 1.0, 400.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_speed = clampf(_speed / 1.2, 1.0, 400.0)


func _process(delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		dir += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		dir += transform.basis.x
	if Input.is_key_pressed(KEY_SPACE):
		dir += Vector3.UP
	if Input.is_key_pressed(KEY_CTRL):
		dir -= Vector3.UP
	if dir.length_squared() > 0.0:
		var mult := 4.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0
		global_position += dir.normalized() * _speed * mult * delta
