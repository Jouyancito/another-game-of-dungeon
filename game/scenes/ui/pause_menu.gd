extends Control

func _ready() -> void:
	visible = false
	$PanelContainer/VBoxContainer/BtnContinuar.pressed.connect(_on_continuar)
	$PanelContainer/VBoxContainer/BtnOpciones.pressed.connect(_on_opciones)
	$PanelContainer/VBoxContainer/BtnMenuPrincipal.pressed.connect(_on_menu_principal)
	$PanelContainer/VBoxContainer/BtnSalir.pressed.connect(_on_salir)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _resume() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_continuar() -> void:
	_resume()


func _on_opciones() -> void:
	pass # Próximamente


func _on_menu_principal() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_salir() -> void:
	get_tree().quit()
