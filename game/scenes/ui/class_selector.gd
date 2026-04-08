extends Control

const CLASS_DATA: Dictionary = {
	"Guerrero": {
		"scene": "res://scenes/player/player.tscn",
		"display": "Guerrero",
	},
	"Mago": {
		"scene": "res://scenes/player/mage.tscn",
		"display": "Mago",
	},
	"Arquero": {
		"scene": "res://scenes/player/archer.tscn",
		"display": "Arquero",
	},
	"Nigromante": {
		"scene": "res://scenes/player/necromancer.tscn",
		"display": "Nigromante",
	},
	"Clérigo": {
		"scene": "res://scenes/player/cleric.tscn",
		"display": "Clérigo",
	},
}

var _selected_class_key: String = ""


func _ready() -> void:
	$CenterContainer/VBoxContainer/BtnGuerrero.pressed.connect(func() -> void: _show_name_panel("Guerrero"))
	$CenterContainer/VBoxContainer/BtnMago.pressed.connect(func() -> void: _show_name_panel("Mago"))
	$CenterContainer/VBoxContainer/BtnArquero.pressed.connect(func() -> void: _show_name_panel("Arquero"))
	$CenterContainer/VBoxContainer/BtnNigromante.pressed.connect(func() -> void: _show_name_panel("Nigromante"))
	$CenterContainer/VBoxContainer/BtnClerigo.pressed.connect(func() -> void: _show_name_panel("Clérigo"))
	$CenterContainer/VBoxContainer/BtnVolver.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
	)
	$NamePanel/VBox/BtnRow/BtnConfirmar.pressed.connect(_on_confirm_name)
	$NamePanel/VBox/BtnRow/BtnCancelar.pressed.connect(_on_cancel_name)
	$NamePanel/VBox/NameInput.text_submitted.connect(func(_text: String) -> void: _on_confirm_name())


func _show_name_panel(class_key: String) -> void:
	_selected_class_key = class_key
	var input: LineEdit = $NamePanel/VBox/NameInput
	input.text = ""
	input.placeholder_text = "Nombre de tu %s..." % CLASS_DATA[class_key]["display"]
	$DimBackground.visible = true
	$NamePanel.visible = true
	input.grab_focus()


func _on_cancel_name() -> void:
	$DimBackground.visible = false
	$NamePanel.visible = false
	_selected_class_key = ""


func _on_confirm_name() -> void:
	var input: LineEdit = $NamePanel/VBox/NameInput
	var char_name: String = input.text.strip_edges()

	if char_name.is_empty():
		# Si no escribe nada, usar nombre por defecto
		char_name = _unique_character_name(CLASS_DATA[_selected_class_key]["display"])

	var data: Dictionary = CLASS_DATA[_selected_class_key]
	var scene_path: String = data["scene"]

	SaveManager.create_character(char_name, scene_path, _selected_class_key)

	var new_index: int = SaveManager.get_character_count() - 1
	GameManager.selected_character_index = new_index
	GameManager.selected_class_scene = scene_path

	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")


func _unique_character_name(display_name: String) -> String:
	var existing: Array = []
	for i in range(SaveManager.get_character_count()):
		existing.append(SaveManager.get_character(i).get("name", ""))
	var candidate := display_name
	var n := 1
	while candidate in existing:
		n += 1
		candidate = "%s #%d" % [display_name, n]
	return candidate
