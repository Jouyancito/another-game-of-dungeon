extends Control

const CLASSES: Array = [
	{
		"key": "Guerrero",
		"scene": "res://scenes/player/player.tscn",
		"display": "Guerrero",
		"desc": "Tanque melee. Golpea fuerte de cerca.",
		"color": Color(0.9, 0.9, 0.9, 1.0),
	},
	{
		"key": "Mago",
		"scene": "res://scenes/player/mage.tscn",
		"display": "Mago",
		"desc": "Daño mágico a distancia. Bolitas de energía y rayo canalizado.",
		"color": Color(0.3, 0.3, 0.8, 1.0),
	},
	{
		"key": "Arquero",
		"scene": "res://scenes/player/archer.tscn",
		"display": "Arquero",
		"desc": "Daño físico a distancia. Flechas rápidas y carga potente.",
		"color": Color(0.2, 0.6, 0.3, 1.0),
	},
	{
		"key": "Nigromante",
		"scene": "res://scenes/player/necromancer.tscn",
		"display": "Nigromante",
		"desc": "Orbes oscuros y drenaje de vida. Daña y se cura.",
		"color": Color(0.4, 0.1, 0.5, 1.0),
	},
	{
		"key": "Clérigo",
		"scene": "res://scenes/player/cleric.tscn",
		"display": "Clérigo",
		"desc": "Melee con maza y castigo divino. Fuerte contra no-muertos.",
		"color": Color(0.8, 0.7, 0.2, 1.0),
	},
	{
		"key": "Danzante",
		"scene": "res://scenes/player/danzante.tscn",
		"display": "Danzante de Sombras",
		"desc": "Sigilo y burst crítico. Combo Points, clon sombrío y cortes encadenados.",
		"color": Color(0.35, 0.2, 0.5, 1.0),
	},
]

var current_index: int = 0

@onready var class_icon: ColorRect = $VBoxContainer/CarouselRow/ClassDisplay/ClassIcon
@onready var class_name_label: Label = $VBoxContainer/CarouselRow/ClassDisplay/ClassName
@onready var class_desc: Label = $VBoxContainer/CarouselRow/ClassDisplay/ClassDesc
@onready var name_input: LineEdit = $VBoxContainer/NameRow/NameInput


func _ready() -> void:
	$VBoxContainer/CarouselRow/BtnLeft.pressed.connect(_on_prev)
	$VBoxContainer/CarouselRow/BtnRight.pressed.connect(_on_next)
	$VBoxContainer/ButtonRow/BtnCrear.pressed.connect(_on_crear)
	$VBoxContainer/ButtonRow/BtnVolver.pressed.connect(_on_volver)
	name_input.text_submitted.connect(func(_text: String) -> void: _on_crear())
	_update_display()


func _on_prev() -> void:
	current_index -= 1
	if current_index < 0:
		current_index = CLASSES.size() - 1
	_update_display()


func _on_next() -> void:
	current_index += 1
	if current_index >= CLASSES.size():
		current_index = 0
	_update_display()


func _update_display() -> void:
	var data: Dictionary = CLASSES[current_index]
	class_icon.color = data["color"]
	class_name_label.text = data["display"]
	class_desc.text = data["desc"]
	name_input.placeholder_text = "Nombre de tu %s..." % data["display"]


func _on_crear() -> void:
	var data: Dictionary = CLASSES[current_index]
	var char_name: String = name_input.text.strip_edges()

	if char_name.is_empty():
		char_name = _unique_character_name(data["display"])

	SaveManager.create_character(char_name, data["scene"], data["key"])

	var new_index: int = SaveManager.get_character_count() - 1
	GameManager.selected_character_index = new_index
	GameManager.selected_class_scene = data["scene"]

	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")


func _on_volver() -> void:
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
