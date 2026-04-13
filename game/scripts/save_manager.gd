extends Node

const SAVE_PATH = "user://characters.json"
const SAVE_PATH_TMP = "user://characters.json.tmp"

var characters: Array = []

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
		characters = parsed.filter(func(e): return e is Dictionary)
	else:
		push_warning("SaveManager: formato inesperado en el archivo de guardado.")
		characters = []


func save_characters() -> void:
	var file := FileAccess.open(SAVE_PATH_TMP, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: no se pudo abrir el archivo temporal para guardar.")
		return

	file.store_string(JSON.stringify(characters, "\t"))
	file.close()

	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("SaveManager: no se pudo acceder al directorio de guardado.")
		return
	# En Windows, rename falla si el destino ya existe — eliminarlo primero
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	var err := dir.rename(SAVE_PATH_TMP, SAVE_PATH)
	if err != OK:
		push_error("SaveManager: no se pudo renombrar el archivo temporal. Error: %d" % err)


func create_character(char_name: String, class_scene: String, class_display_name: String) -> int:
	var defaults: Dictionary = ClassBaseStats.DEFAULTS.get(class_scene, {
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
		"titles": [],
		"active_title": "",
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


func grant_title(char_index: int, title: String) -> void:
	var data = get_character(char_index)
	if data.is_empty():
		return
	var titles: Array = data.get("titles", [])
	if title not in titles:
		titles.append(title)
		update_character(char_index, {"titles": titles})


func set_active_title(char_index: int, title: String) -> void:
	var data = get_character(char_index)
	if data.is_empty():
		return
	var titles: Array = data.get("titles", [])
	if title in titles or title == "":
		update_character(char_index, {"active_title": title})


func delete_character(index: int) -> void:
	if index < 0 or index >= characters.size():
		push_error("SaveManager: índice de personaje inválido: %d" % index)
		return
	characters.remove_at(index)
	save_characters()


func get_character_count() -> int:
	return characters.size()
