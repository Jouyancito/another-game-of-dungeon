extends Node3D

## Test de ghosting con muchos CSG — simula la carga de la pradera

var mouse_sensitivity := 0.003

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Generar 500 CSGBox3D esparcidos (simula árboles, rocas, cristales)
	for i in range(500):
		var box := CSGBox3D.new()
		box.size = Vector3(randf_range(0.5, 3.0), randf_range(1.0, 5.0), randf_range(0.5, 3.0))
		box.position = Vector3(
			randf_range(-100, 100),
			box.size.y * 0.5,
			randf_range(-100, 100)
		)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(randf_range(0.2, 0.8), randf_range(0.2, 0.6), randf_range(0.1, 0.4))
		box.material_override = mat
		box.use_collision = false
		add_child(box)

	# Piso
	var floor_box := CSGBox3D.new()
	floor_box.size = Vector3(250, 0.3, 250)
	floor_box.position = Vector3(0, -0.15, 0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.3, 0.5, 0.2)
	floor_box.material_override = floor_mat
	add_child(floor_box)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		$Camera3D.rotate_y(-event.relative.x * mouse_sensitivity)
		$Camera3D.rotation.x = clamp(
			$Camera3D.rotation.x + (-event.relative.y * mouse_sensitivity),
			-PI / 2, PI / 2
		)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()
