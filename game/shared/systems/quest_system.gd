extends Node

# Singleton stub para canon quest-gate de skills T3/B3 (_system.md §5bis).
# Registrado como autoload con nombre "QuestSystem" en project.godot.
#
# Fase actual (prototipo): stub in-memory — completa/desloguea quests via API.
# TODO Fase post-MVP: persistencia por save slot, trackers pasivos, NPC dialog,
# integración con save_manager, evento worldcast cuando se completa una quest.

signal quest_completed(quest_id: StringName)

var _completed: Dictionary = {}  # StringName quest_id → bool


func is_completed(quest_id: StringName) -> bool:
	return _completed.get(quest_id, false)


func mark_completed(quest_id: StringName) -> void:
	if _completed.get(quest_id, false):
		return  # idempotente
	_completed[quest_id] = true
	quest_completed.emit(quest_id)


## Para tests — resetea el estado sin afectar otros nodos.
func reset_all() -> void:
	_completed.clear()
