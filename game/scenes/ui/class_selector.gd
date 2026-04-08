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


func _ready() -> void:
	$CenterContainer/VBoxContainer/BtnGuerrero.pressed.connect(func() -> void: _select_class("Guerrero"))
	$CenterContainer/VBoxContainer/BtnMago.pressed.connect(func() -> void: _select_class("Mago"))
	$CenterContainer/VBoxContainer/BtnArquero.pressed.connect(func() -> void: _select_class("Arquero"))
	$CenterContainer/VBoxContainer/BtnNigromante.pressed.connect(func() -> void: _select_class("Nigromante"))
	$CenterContainer/VBoxContainer/BtnClerigo.pressed.connect(func() -> void: _select_class("Clérigo"))
	$CenterContainer/VBoxContainer/BtnVolver.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
	)


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


func _select_class(class_key: String) -> void:
	var data: Dictionary = CLASS_DATA[class_key]
	var scene_path: String = data["scene"]
	var display_name: String = data["display"]

	var char_name: String = _unique_character_name(display_name)

	SaveManager.create_character(char_name, scene_path, class_key)

	var new_index: int = SaveManager.get_character_count() - 1
	GameManager.selected_character_index = new_index
	GameManager.selected_class_scene = scene_path

	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
