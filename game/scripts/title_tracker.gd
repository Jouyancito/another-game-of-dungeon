extends Node

## TitleTracker — autoload que escucha eventos del juego y otorga títulos automáticamente.
## Los títulos se guardan en el personaje activo vía SaveManager.
## Emite `title_unlocked(title)` cuando se desbloquea uno nuevo.

signal title_unlocked(title: String, description: String)

## Definición de títulos y sus condiciones.
## Cada título tiene: key, nombre display, descripción, y función de check.
const TITLES := {
	"first_blood": {
		"name": "Primera Sangre",
		"desc": "Tu primer enemigo muerto",
	},
	"slime_hunter": {
		"name": "Cazaslimes",
		"desc": "Matá 10 slimes",
	},
	"exterminator": {
		"name": "Exterminador",
		"desc": "Matá 50 enemigos",
	},
	"the_fallen": {
		"name": "El Caído",
		"desc": "Tu primera muerte",
	},
	"survivor": {
		"name": "Superviviente",
		"desc": "Alcanzá nivel 5",
	},
	"veteran": {
		"name": "Veterano",
		"desc": "Alcanzá nivel 10",
	},
}


func on_enemy_killed(enemy_type: String) -> void:
	var stats := _get_stats()
	stats["enemies_killed"] = stats.get("enemies_killed", 0) + 1

	# Contador específico por tipo
	var type_key := "killed_%s" % enemy_type
	stats[type_key] = stats.get(type_key, 0) + 1

	_save_stats(stats)

	# Check títulos
	if stats["enemies_killed"] == 1:
		_grant("first_blood")
	if stats.get("killed_slime", 0) >= 10:
		_grant("slime_hunter")
	if stats["enemies_killed"] >= 50:
		_grant("exterminator")


## Mímico matado — stub, canon formato achievement "Frieren" lo define C (dept/design).
func notify_mimic_killed() -> void:
	var stats := _get_stats()
	stats["mimics_killed"] = stats.get("mimics_killed", 0) + 1
	_save_stats(stats)
	print("[TitleTracker] Mímico matado (total: %d)" % stats["mimics_killed"])


func on_player_death() -> void:
	var stats := _get_stats()
	stats["deaths"] = stats.get("deaths", 0) + 1
	_save_stats(stats)

	if stats["deaths"] == 1:
		_grant("the_fallen")


func on_level_up(new_level: int) -> void:
	if new_level >= 5:
		_grant("survivor")
	if new_level >= 10:
		_grant("veteran")


## Getter helper — devuelve el dict de stats del personaje activo.
func _get_stats() -> Dictionary:
	var idx = GameManager.selected_character_index
	if idx < 0:
		return {}
	var data: Dictionary = SaveManager.get_character(idx)
	if data.is_empty():
		return {}
	return data.get("tracker_stats", {})


func _save_stats(stats: Dictionary) -> void:
	var idx = GameManager.selected_character_index
	if idx < 0:
		return
	SaveManager.update_character(idx, {"tracker_stats": stats})


## Otorga el título si no lo tenía. Emite la señal.
func _grant(title_key: String) -> void:
	var idx = GameManager.selected_character_index
	if idx < 0:
		return
	var data: Dictionary = SaveManager.get_character(idx)
	if data.is_empty():
		return
	var titles: Array = data.get("titles", [])
	if title_key in titles:
		return

	SaveManager.grant_title(idx, title_key)
	var info: Dictionary = TITLES.get(title_key, {})
	var name: String = info.get("name", title_key)
	var desc: String = info.get("desc", "")
	title_unlocked.emit(name, desc)
	print("[TitleTracker] Título desbloqueado: %s — %s" % [name, desc])


## Devuelve el display name de un título por su key.
func get_title_name(title_key: String) -> String:
	var info: Dictionary = TITLES.get(title_key, {})
	return info.get("name", title_key)


## Devuelve la descripción de un título.
func get_title_desc(title_key: String) -> String:
	var info: Dictionary = TITLES.get(title_key, {})
	return info.get("desc", "")
