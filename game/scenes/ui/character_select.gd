extends Control

const CLASS_COLORS: Dictionary = {
	"Guerrero": Color(1.0, 1.0, 1.0, 1.0),
	"Mago": Color(0.3, 0.3, 0.8, 1.0),
	"Arquero": Color(0.2, 0.6, 0.3, 1.0),
	"Nigromante": Color(0.4, 0.1, 0.5, 1.0),
	"Clérigo": Color(0.8, 0.7, 0.2, 1.0),
}

const MAX_CHARACTERS: int = 6

var selected_index: int = -1
var _delete_pending: bool = false


func _ready() -> void:
	$CenterContainer/VBoxContainer/ActionRow/BtnJugar.pressed.connect(_on_btn_jugar_pressed)
	$CenterContainer/VBoxContainer/ActionRow/BtnEliminar.pressed.connect(_on_btn_eliminar_pressed)
	$CenterContainer/VBoxContainer/BtnVolver.pressed.connect(_on_btn_volver_pressed)
	_refresh_characters()


func _refresh_characters() -> void:
	selected_index = -1
	_delete_pending = false
	_update_buttons()

	var container: HBoxContainer = $CenterContainer/VBoxContainer/CardContainer
	for child in container.get_children():
		child.queue_free()

	for i in range(SaveManager.get_character_count()):
		var character: Dictionary = SaveManager.get_character(i)
		var card := _create_character_card(character, i)
		container.add_child(card)

	if SaveManager.get_character_count() < MAX_CHARACTERS:
		var create_card := _create_new_card()
		container.add_child(create_card)


func _create_character_card(character: Dictionary, index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 200)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var color_rect := ColorRect.new()
	color_rect.custom_minimum_size = Vector2(80, 80)
	color_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var class_key: String = character.get("class_name", "Guerrero")
	color_rect.color = CLASS_COLORS.get(class_key, Color(1.0, 1.0, 1.0, 1.0))
	vbox.add_child(color_rect)

	var name_label := Label.new()
	name_label.text = character.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	var class_label := Label.new()
	class_label.text = character.get("class_name", "")
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_label.add_theme_font_size_override("font_size", 14)
	class_label.modulate = Color(1.0, 1.0, 1.0, 0.7)
	vbox.add_child(class_label)

	var level_label := Label.new()
	level_label.text = "Nv. %d" % character.get("level", 1)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.modulate = Color(1.0, 0.85, 0.3, 1.0)
	vbox.add_child(level_label)

	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_select_card(index)
	)

	return panel


func _create_new_card() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 200)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var plus_label := Label.new()
	plus_label.text = "+"
	plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus_label.add_theme_font_size_override("font_size", 48)
	plus_label.modulate = Color(1.0, 1.0, 1.0, 0.6)
	vbox.add_child(plus_label)

	var text_label := Label.new()
	text_label.text = "Crear\nNuevo"
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.modulate = Color(1.0, 1.0, 1.0, 0.6)
	vbox.add_child(text_label)

	panel.set_meta("is_new_card", true)

	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_tree().change_scene_to_file("res://scenes/ui/class_selector.tscn")
	)

	return panel


func _select_card(index: int) -> void:
	selected_index = index
	_delete_pending = false
	$CenterContainer/VBoxContainer/ActionRow/BtnEliminar.text = "Eliminar"
	_update_buttons()
	_highlight_selected()


func _highlight_selected() -> void:
	var container: HBoxContainer = $CenterContainer/VBoxContainer/CardContainer
	for i in range(container.get_child_count()):
		var card = container.get_child(i)
		if not card is PanelContainer:
			continue
		if card.get_meta("is_new_card", false):
			continue
		if i == selected_index:
			card.modulate = Color(1.0, 0.85, 0.3, 1.0)
		else:
			card.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _update_buttons() -> void:
	var has_selection := selected_index >= 0
	$CenterContainer/VBoxContainer/ActionRow/BtnJugar.disabled = not has_selection
	$CenterContainer/VBoxContainer/ActionRow/BtnEliminar.disabled = not has_selection


func _on_btn_jugar_pressed() -> void:
	if selected_index < 0:
		return
	var character: Dictionary = SaveManager.get_character(selected_index)
	if character.is_empty() or character.get("class_scene", "") == "":
		return
	GameManager.selected_class_scene = character.get("class_scene", "")
	GameManager.selected_character_index = selected_index
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_btn_eliminar_pressed() -> void:
	if selected_index < 0:
		return
	if not _delete_pending:
		_delete_pending = true
		$CenterContainer/VBoxContainer/ActionRow/BtnEliminar.text = "Confirmar?"
		return
	_delete_pending = false
	$CenterContainer/VBoxContainer/ActionRow/BtnEliminar.text = "Eliminar"
	SaveManager.delete_character(selected_index)
	_refresh_characters()


func _on_btn_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
