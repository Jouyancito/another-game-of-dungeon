extends Camera3D

## Cámara simple para testear ghosting — mover mouse para girar

var mouse_sensitivity := 0.003

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotation.x = clamp(rotation.x + (-event.relative.y * mouse_sensitivity), -PI / 2, PI / 2)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()
