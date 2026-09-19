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

## Las 6 clases, abiertas. Las 6 son canon de lanzamiento (CLAUDE.md) y las 6 están
## code-complete: stats, skills, recurso propio y VFX — el Danzante era la última muda y ya
## no lo es. El recorte a 3 existía para el demo de 1 mapa; con la torre entera construida,
## esconder tres clases terminadas es dejar trabajo hecho fuera del juego.
##
## Volver a recortar es escribir los nombres acá: ["Guerrero", "Mago", "Arquero"].
const ALPHA_ONLY: Array = []

var _classes: Array = []
var current_index: int = 0
var _preview: CharacterPreview = null

@onready var class_icon: ColorRect = $VBoxContainer/CarouselRow/ClassDisplay/ClassIcon
@onready var class_name_label: Label = $VBoxContainer/CarouselRow/ClassDisplay/ClassName
@onready var class_desc: Label = $VBoxContainer/CarouselRow/ClassDisplay/ClassDesc
@onready var name_input: LineEdit = $VBoxContainer/NameRow/NameInput


func _ready() -> void:
	_classes = _alpha_filtered_classes()
	$VBoxContainer/CarouselRow/BtnLeft.pressed.connect(_on_prev)
	$VBoxContainer/CarouselRow/BtnRight.pressed.connect(_on_next)
	$VBoxContainer/ButtonRow/BtnCrear.pressed.connect(_on_crear)
	$VBoxContainer/ButtonRow/BtnVolver.pressed.connect(_on_volver)
	name_input.text_submitted.connect(func(_text: String) -> void: _on_crear())
	_update_display()


func _on_prev() -> void:
	current_index -= 1
	if current_index < 0:
		current_index = _classes.size() - 1
	_update_display()


func _on_next() -> void:
	current_index += 1
	if current_index >= _classes.size():
		current_index = 0
	_update_display()


func _update_display() -> void:
	var data: Dictionary = _classes[current_index]
	class_name_label.text = data["display"]
	class_desc.text = data["desc"]
	name_input.placeholder_text = "Nombre de tu %s..." % data["display"]

	# Destruir preview anterior si existe
	if _preview != null and is_instance_valid(_preview):
		_preview.queue_free()
		_preview = null

	# Instanciar CharacterPreview 3D en lugar del ColorRect plano
	_preview = CharacterPreview.new()
	_preview.custom_minimum_size = Vector2(150, 150)
	_preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	class_icon.get_parent().add_child(_preview)
	class_icon.get_parent().move_child(_preview, class_icon.get_index())
	_preview.setup_character(data["color"], data["key"])
	class_icon.visible = false


func _on_crear() -> void:
	var data: Dictionary = _classes[current_index]
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


## Devuelve las clases visibles en el selector. Si ALPHA_ONLY tiene keys,
## filtra a esas (orden de CLASSES); si está vacío, devuelve las 6.
func _alpha_filtered_classes() -> Array:
	if ALPHA_ONLY.is_empty():
		return CLASSES
	var out: Array = []
	for c: Dictionary in CLASSES:
		if c["key"] in ALPHA_ONLY:
			out.append(c)
	return out
