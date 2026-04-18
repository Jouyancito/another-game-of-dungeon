extends Node
class_name HitStopSingleton

## HitStop — singleton global para freeze frames de impacto.
## Autoload registrado en project.godot como "HitStop".
##
## Uso:
##   HitStop.stop_crit()    # preset crítico 0.08s
##   HitStop.stop_heavy()   # preset pesado 0.12s
##   HitStop.stop(0.06)     # duración custom en segundos
##
## Implementación: Engine.time_scale → 0.05 durante la duración real ajustada,
## luego resetea a 1.0. Usa un timer real (no de juego) para que el freeze
## no se vea afectado por su propio time_scale.
##
## NOTA: no stackeable — si ya hay un stop activo y el nuevo es más corto, se ignora.

# ── Señales ───────────────────────────────────────────────────────────────────
signal hit_stop_started(duration_s: float)
signal hit_stop_finished

# ── Config tuneable ────────────────────────────────────────────────────────────
@export var freeze_time_scale: float = 0.05  # escala de tiempo durante el freeze

# ── Estado ────────────────────────────────────────────────────────────────────
var _active: bool = false
var _remaining_real_s: float = 0.0  # tiempo real restante del stop actual


# ── Presets ───────────────────────────────────────────────────────────────────

## Preset crítico — 0.08s de freeze.
func stop_crit() -> void:
	stop(0.08)


## Preset pesado — 0.12s de freeze (reactive / boss).
func stop_heavy() -> void:
	stop(0.12)


# ── API principal ─────────────────────────────────────────────────────────────

## Congela el tiempo durante duration_s segundos reales.
## Si ya hay un stop activo con duración mayor, no interrumpe.
func stop(duration_s: float) -> void:
	if duration_s <= 0.0:
		return

	# El tiempo real del freeze es duration_s ajustado al time_scale del freeze
	var real_duration := duration_s * freeze_time_scale

	# Si ya activo con más tiempo restante, no reemplazar
	if _active and real_duration <= _remaining_real_s:
		return

	_remaining_real_s = real_duration
	if _active:
		return  # Solo actualizamos el tiempo — el _process ya corre

	_active = true
	Engine.time_scale = freeze_time_scale
	hit_stop_started.emit(duration_s)


func _process(delta: float) -> void:
	if not _active:
		return

	# delta aquí es real-time delta (no afectado por time_scale) si usamos
	# process_mode = PROCESS_MODE_ALWAYS — ver configuración abajo.
	_remaining_real_s -= delta

	if _remaining_real_s <= 0.0:
		_finish_stop()


func _finish_stop() -> void:
	_active = false
	_remaining_real_s = 0.0
	Engine.time_scale = 1.0
	hit_stop_finished.emit()


func _ready() -> void:
	# CRÍTICO: process_mode ALWAYS para que el timer corra aunque Engine.time_scale sea ~0
	process_mode = Node.PROCESS_MODE_ALWAYS
