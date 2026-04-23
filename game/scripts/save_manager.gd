extends Node

const SAVE_PATH = "user://characters.json"
const SAVE_PATH_TMP = "user://characters.json.tmp"
const SAVE_PATH_BAK = "user://characters.json.bak"

# Schema version — bump cuando cambie la estructura del save.
# v1: char base (stats, level, xp, profile_id)
# v2: + inventory (items + coins), + equipment (slots), + gold, + version field
# v3: + hotbar (Array[String] 8 slots, "" = vacío) — persiste loadout drag&drop
# v4: + highest_floor (int, piso más alto alcanzado — display en character select)
const SCHEMA_VERSION := 4

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
		push_warning("SaveManager: archivo de guardado corrupto — backup → .bak, iniciando vacío.")
		_backup_corrupt_save()
		characters = []
		return

	var parsed = json.get_data()
	if parsed is Array:
		characters = parsed.filter(func(e): return e is Dictionary)
		_migrate_characters()
	else:
		push_warning("SaveManager: formato inesperado en el archivo de guardado.")
		characters = []


# Migración transparente: characters viejos reciben:
#   v0 → profile_id generado
#   v1 → v2: inventory{} / equipment{} / gold vacíos + version bump
# Inventory/equipment como dict vacío es funcionalmente equivalente al load actual
# (from_save_data skipea keys ausentes), el bump explicíta el schema.
func _migrate_characters() -> void:
	var changed := false
	for c in characters:
		# Skip malformed entries (save corrupto o editado a mano con tipos raros).
		if not (c is Dictionary):
			push_warning("SaveManager: entry no-Dictionary ignorada en migración.")
			continue
		if not c.has("profile_id") or str(c.get("profile_id", "")) == "":
			c["profile_id"] = _generate_profile_id()
			changed = true
		var cur_version: int = int(c.get("version", 1))
		if cur_version < 2:
			if not c.has("inventory"):
				c["inventory"] = {}
			if not c.has("equipment"):
				c["equipment"] = {}
			if not c.has("gold"):
				c["gold"] = 0
			c["version"] = 2
			cur_version = 2
			changed = true
		if cur_version < 3:
			if not c.has("hotbar"):
				c["hotbar"] = []
			c["version"] = 3
			cur_version = 3
			changed = true
		if cur_version < 4:
			if not c.has("highest_floor"):
				c["highest_floor"] = 1
			c["version"] = 4
			changed = true
		# Safety net: saves con version=N pero campos faltantes (edit manual, save custom,
		# carga parcial). Garantiza schema completo independiente del path de migración.
		if not c.has("inventory"):
			c["inventory"] = {}
			changed = true
		if not c.has("equipment"):
			c["equipment"] = {}
			changed = true
		if not c.has("hotbar"):
			c["hotbar"] = []
			changed = true
		if not c.has("gold"):
			c["gold"] = 0
			changed = true
		if not c.has("highest_floor"):
			c["highest_floor"] = 1
			changed = true
	if changed:
		save_characters()


func _backup_corrupt_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	if FileAccess.file_exists(SAVE_PATH_BAK):
		DirAccess.remove_absolute(SAVE_PATH_BAK)
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("SaveManager: no se pudo crear backup del save corrupto.")
		return
	dir.rename(SAVE_PATH, SAVE_PATH_BAK)


func _generate_profile_id() -> String:
	# UUID v4 simplificado — suficiente entropia para singleplayer offline.
	# Cuando haya backend MMO, este ID se registra server-side y queda canonico.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var parts := PackedStringArray()
	for i in 4:
		parts.append("%08x" % rng.randi())
	return "local-" + "-".join(parts)


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
		"version": SCHEMA_VERSION,
		"profile_id": _generate_profile_id(),
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
		"inventory": {},
		"equipment": {},
		"gold": 0,
		"hotbar": [],
		"highest_floor": 1,
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


# ── Hotbar persistence (v3+) ────────────────────────────────────────────────

func update_character_hotbar(index: int, skill_ids: Array) -> void:
	if index < 0 or index >= characters.size():
		push_error("SaveManager: índice de personaje inválido: %d" % index)
		return
	var serialized: Array = []
	for s in skill_ids:
		serialized.append(String(s))
	characters[index]["hotbar"] = serialized
	save_characters()


func get_character_hotbar(index: int) -> Array:
	if index < 0 or index >= characters.size():
		return []
	return characters[index].get("hotbar", [])
