extends Control

func _ready() -> void:
	$CenterContainer/VBoxContainer/BtnGuerrero.pressed.connect(_select_warrior)
	$CenterContainer/VBoxContainer/BtnMago.pressed.connect(_select_mage)
	$CenterContainer/VBoxContainer/BtnArquero.pressed.connect(_select_archer)
	$CenterContainer/VBoxContainer/BtnNigromante.pressed.connect(_select_necromancer)
	$CenterContainer/VBoxContainer/BtnClerigo.pressed.connect(_select_cleric)

func _select_warrior() -> void:
	GameManager.selected_class_scene = "res://scenes/player/player.tscn"
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _select_mage() -> void:
	GameManager.selected_class_scene = "res://scenes/player/mage.tscn"
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _select_archer() -> void:
	GameManager.selected_class_scene = "res://scenes/player/archer.tscn"
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _select_necromancer() -> void:
	GameManager.selected_class_scene = "res://scenes/player/necromancer.tscn"
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _select_cleric() -> void:
	GameManager.selected_class_scene = "res://scenes/player/cleric.tscn"
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
