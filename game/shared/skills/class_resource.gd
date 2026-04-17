class_name ClassResource extends Node

# Recurso único por clase — Rage (Warrior), Fe (Cleric), Combo (Danzante), etc.
# Fase 0 implementa solo Rage como referencia. Otros fases añaden su comportamiento.
# MP es universal y vive en BasePlayer — no acá.

enum Type { RAGE, FE, COMBO, CONCENTRACION, VIDA }

signal resource_changed(current: int, max_value: int)

@export var type: Type = Type.RAGE
@export var max_value: int = 100
# Rage NO regenera pasivo. Decae fuera de combate.
@export var regen_rate: float = 0.0          # /s — positivo = regen pasivo
@export var combat_decay_rate: float = 5.0   # /s — se aplica si time_since_combat >= decay_delay
@export var decay_delay_s: float = 8.0       # s sin combate antes de empezar a decaer

var current: float = 0.0                     # float para decay smooth — current_int expuesto
var _time_since_combat: float = 0.0


func _process(delta: float) -> void:
	_time_since_combat += delta
	# Regen (ej. Concentración recargándose) — para clases que lo usen
	if regen_rate > 0.0 and current < max_value:
		_set_current(current + regen_rate * delta)
	# Decay por inactividad en combate
	elif _time_since_combat >= decay_delay_s and current > 0.0:
		_set_current(current - combat_decay_rate * delta)


func add(amount: int) -> void:
	if amount == 0:
		return
	_set_current(current + float(amount))
	_mark_in_combat()


func consume(amount: int) -> bool:
	if amount <= 0:
		return true
	if int(current) < amount:
		return false
	_set_current(current - float(amount))
	_mark_in_combat()
	return true


func get_current() -> int:
	return int(current)


func set_current(value: int) -> void:
	_set_current(float(value))


func _mark_in_combat() -> void:
	_time_since_combat = 0.0


func _set_current(value: float) -> void:
	var clamped: float = clampf(value, 0.0, float(max_value))
	if clamped == current:
		return
	current = clamped
	resource_changed.emit(int(current), max_value)
