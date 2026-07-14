extends Node

## Persistencia de mundos — dominio separado de los personajes.
## Modelo Valheim: un personaje (SaveManager) entra a cualquier mundo; el mundo
## guarda su propio progreso (pisos despejados, trofeos, marcas). Cuando llegue
## netcode, esta capa local se reemplaza por sync server-side, pero el contrato
## (world_id / seed / world_flags) ya queda fijado acá.
##
## Espeja el patrón robusto de SaveManager: escritura atómica vía .tmp + rename,
## backup del save corrupto a .bak.

const SAVE_PATH := "user://worlds.json"
const SAVE_PATH_TMP := "user://worlds.json.tmp"
const SAVE_PATH_BAK := "user://worlds.json.bak"

# v1: world base (world_id, name, seed, created_at, playtime_seconds,
#     highest_floor_cleared, boss_trophies, world_flags)
const SCHEMA_VERSION := 1

const MAX_WORLDS := 12

var worlds: Array = []


func _ready() -> void:
	load_worlds()


func load_worlds() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		worlds = []
		return

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(content)
	if err != OK:
		push_warning("WorldManager: worlds.json corrupto — backup → .bak, iniciando vacío.")
		_backup_corrupt_save()
		worlds = []
		return

	var parsed = json.get_data()
	if parsed is Array:
		worlds = parsed.filter(func(e): return e is Dictionary)
	else:
		push_warning("WorldManager: formato inesperado en worlds.json.")
		worlds = []


func _backup_corrupt_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	if FileAccess.file_exists(SAVE_PATH_BAK):
		DirAccess.remove_absolute(SAVE_PATH_BAK)
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("WorldManager: no se pudo respaldar el save corrupto.")
		return
	dir.rename(SAVE_PATH, SAVE_PATH_BAK)


func save_worlds() -> void:
	var file := FileAccess.open(SAVE_PATH_TMP, FileAccess.WRITE)
	if file == null:
		push_error("WorldManager: no se pudo abrir el archivo temporal para guardar.")
		return

	file.store_string(JSON.stringify(worlds, "\t"))
	file.close()

	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("WorldManager: no se pudo acceder al directorio de guardado.")
		return
	# En Windows, rename falla si el destino ya existe — eliminarlo primero.
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	var err := dir.rename(SAVE_PATH_TMP, SAVE_PATH)
	if err != OK:
		push_error("WorldManager: no se pudo renombrar el archivo temporal. Error: %d" % err)


func _generate_world_id() -> String:
	# UUID v4 simplificado — suficiente entropía para singleplayer offline.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var parts := PackedStringArray()
	for i in 4:
		parts.append("%08x" % rng.randi())
	return "world-" + "-".join(parts)


## Crea un mundo. seed_value < 0 → seed aleatoria. Devuelve el índice del nuevo mundo.
func create_world(world_name: String, seed_value: int = -1) -> int:
	var final_seed := seed_value
	if final_seed < 0:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		# randi_range(1, ...) evita seed 0, que se lee como "sin asignar" a ojo humano.
		final_seed = rng.randi_range(1, 999999)

	var name_clean := world_name.strip_edges()
	if name_clean == "":
		name_clean = "Mundo %d" % (worlds.size() + 1)

	var new_world := {
		"version": SCHEMA_VERSION,
		"world_id": _generate_world_id(),
		"name": name_clean,
		"seed": final_seed,
		"created_at": Time.get_date_string_from_system(),
		"playtime_seconds": 0,
		# World-state colectivo (modelo Descubrimiento→Conquista→Civilización).
		# En el alpha viven local; cuando llegue netcode se sincronizan por server.
		"highest_floor_cleared": 0,
		"boss_trophies": [],
		"world_flags": {},
	}

	worlds.append(new_world)
	save_worlds()
	return worlds.size() - 1


func get_world(index: int) -> Dictionary:
	if index < 0 or index >= worlds.size():
		push_error("WorldManager: índice de mundo inválido: %d" % index)
		return {}
	return worlds[index]


func update_world(index: int, data: Dictionary) -> void:
	if index < 0 or index >= worlds.size():
		push_error("WorldManager: índice de mundo inválido: %d" % index)
		return
	worlds[index].merge(data, true)
	save_worlds()


## Records a floor clear on the ACTIVE world (GameManager.world_index).
## Idempotent: re-clearing a floor never lowers progress nor duplicates a trophy,
## so a replayed boss is safe. Returns true if this was the world's first clear
## of that floor (the caller uses it to decide whether to show a victory screen).
func mark_floor_cleared(floor_number: int, trophy: StringName = &"") -> bool:
	var index: int = GameManager.world_index
	# No world selected (dev/test scene) is a normal state, not an error — check it
	# before get_world(), which push_error()s on an invalid index by design.
	if index < 0 or index >= worlds.size():
		return false
	var world := get_world(index)
	if world.is_empty():
		return false

	var previous_best: int = int(world.get("highest_floor_cleared", 0))
	var trophies: Array = (world.get("boss_trophies", []) as Array).duplicate()
	var is_first_clear := floor_number > previous_best

	if trophy != &"" and not trophies.has(String(trophy)):
		trophies.append(String(trophy))

	update_world(index, {
		"highest_floor_cleared": maxi(previous_best, floor_number),
		"boss_trophies": trophies,
	})
	return is_first_clear


func delete_world(index: int) -> void:
	if index < 0 or index >= worlds.size():
		push_error("WorldManager: índice de mundo inválido: %d" % index)
		return
	worlds.remove_at(index)
	save_worlds()


func get_world_count() -> int:
	return worlds.size()
