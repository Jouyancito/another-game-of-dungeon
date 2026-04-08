extends Node

const SAVE_PATH = "user://characters.json"

var characters: Array = []

# Stats por defecto indexados por scene path
const CLASS_DEFAULTS := {
	"res://scenes/player/player.tscn": {
		"class_name": "Guerrero",
		"str_stat": 12, "int_stat": 3, "dex_stat": 6, "def_stat": 10, "vit_stat": 10
	},
	"res://scenes/player/mage.tscn": {
		"class_name": "Mago",
		"str_stat": 4, "int_stat": 12, "dex_stat": 5, "def_stat": 3, "vit_stat": 5
	},
	"res://scenes/player/archer.tscn": {
		"class_name": "Arquero",
		"str_stat": 5, "int_stat": 3, "dex_stat": 12, "def_stat": 5, "vit_stat": 7
	},
	"res://scenes/player/necromancer.tscn": {
		"class_name": "Nigromante",
		"str_stat": 3, "int_stat": 10, "dex_stat": 4, "def_stat": 4, "vit_stat": 6
	},
	"res://scenes/player/cleric.tscn": {
		"class_name": "Clérigo",
		"str_stat": 8, "int_stat": 6, "dex_stat": 4, "def_stat": 8, "vit_stat": 9
	},
}


func _ready() -> void:
	load_characters()


func load_characters() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		characters = []
		return

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(content)
	if err != OK:
		push_warning("SaveManager: archivo de guardado corrupto, iniciando vacío.")
		characters = []
		return

	var parsed = json.get_data()
	if parsed is Array:
		characters = parsed
	else:
		push_warning("SaveManager: formato inesperado en el archivo de guardado.")
		characters = []


func save_characters() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: no se pudo abrir el archivo para guardar.")
		return

	file.store_string(JSON.stringify(characters, "\t"))
	file.close()


func create_character(char_name: String, class_scene: String, class_display_name: String) -> int:
	var defaults: Dictionary = CLASS_DEFAULTS.get(class_scene, {
		"class_name": class_display_name,
		"str_stat": 5, "int_stat": 5, "dex_stat": 5, "def_stat": 5, "vit_stat": 5
	})

	var new_char := {
		"name": char_name,
		"class_scene": class_scene,
		"class_name": defaults.get("class_name", class_display_name),
		"level": 1,
		"xp": 0.0,
		"str_stat": defaults.get("str_stat", 5),
		"int_stat": defaults.get("int_stat", 5),
		"dex_stat": defaults.get("dex_stat", 5),
		"def_stat": defaults.get("def_stat", 5),
		"vit_stat": defaults.get("vit_stat", 5),
		"stat_points": 0,
		"created_at": Time.get_date_string_from_system(),
	}

	characters.append(new_char)
	save_characters()
	return characters.size() - 1


func get_character(index: int) -> Dictionary:
	if index < 0 or index >= characters.size():
		push_error("SaveManager: índice de personaje inválido: %d" % index)
		return {}
	return characters[index]


func update_character(index: int, data: Dictionary) -> void:
	if index < 0 or index >= characters.size():
		push_error("SaveManager: índice de personaje inválido: %d" % index)
		return
	characters[index].merge(data, true)
	save_characters()


func delete_character(index: int) -> void:
	if index < 0 or index >= characters.size():
		push_error("SaveManager: índice de personaje inválido: %d" % index)
		return
	characters.remove_at(index)
	save_characters()


func get_character_count() -> int:
	return characters.size()
