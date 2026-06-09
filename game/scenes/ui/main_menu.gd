extends Control


func _ready() -> void:
	$CenterContainer/VBoxContainer/BtnJugar.pressed.connect(_on_btn_jugar_pressed)
	$CenterContainer/VBoxContainer/BtnHostear.pressed.connect(_on_btn_hostear_pressed)
	$CenterContainer/VBoxContainer/BtnTutorial.pressed.connect(_on_btn_tutorial_pressed)
	$CenterContainer/VBoxContainer/BtnOpciones.pressed.connect(_on_btn_opciones_pressed)
	$CenterContainer/VBoxContainer/BtnSalir.pressed.connect(_on_btn_salir_pressed)
	# Tutorial is not yet implemented — visibly disabled so the player knows it
	# exists but isn't available in this build (alpha demo scope).
	$CenterContainer/VBoxContainer/BtnTutorial.disabled = true
	$CenterContainer/VBoxContainer/BtnTutorial.tooltip_text = "Próximamente"


func _on_btn_jugar_pressed() -> void:
	GameManager.target_scene = "res://scenes/levels/floor1_prairie.tscn"
	GameManager.requires_world_select = true
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")


func _on_btn_hostear_pressed() -> void:
	_show_proximamente()


func _on_btn_tutorial_pressed() -> void:
	_show_proximamente()


func _on_btn_opciones_pressed() -> void:
	_show_proximamente()


func _on_btn_salir_pressed() -> void:
	get_tree().quit()


func _show_proximamente() -> void:
	var label: Label = $CenterContainer/VBoxContainer/StatusLabel
	label.visible = true
	await get_tree().create_timer(2.0).timeout
	if not is_instance_valid(self):
		return
	label.visible = false
