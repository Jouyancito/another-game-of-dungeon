class_name VFXBase
extends Node3D

## Base canon para VFX warrior (y futuras clases).
## API mínima consumida por player_skills.gd: play() / stop().
##
## Flujo:
##   var vfx = preload("res://scenes/fx/warrior/charge_vfx.tscn").instantiate()
##   parent.add_child(vfx)
##   vfx.global_position = origin
##   vfx.play()
##
## Si duration_s > 0 → auto-stop tras duration y queue_free si auto_free.
## Si duration_s == 0 → sostenida; el caller decide cuándo llamar stop().

signal vfx_started
signal vfx_finished

## Duración total del VFX en segundos. 0 = sostenido (toggle/reactive) — stop() manual.
@export var duration_s: float = 0.3

## Si true, queue_free() al terminar (stop automático o manual). Default true.
@export var auto_free: bool = true

## Tiempo de fade-out opcional post-stop (para particles con lifetime mayor que duration).
@export var fade_out_s: float = 0.0

var _playing: bool = false
var _timer: SceneTreeTimer = null


func play() -> void:
	if _playing:
		return
	_playing = true
	_on_play()
	vfx_started.emit()
	if duration_s > 0.0:
		_timer = get_tree().create_timer(duration_s)
		_timer.timeout.connect(_auto_stop)


func stop() -> void:
	if not _playing:
		return
	_playing = false
	_on_stop()
	if fade_out_s > 0.0:
		await get_tree().create_timer(fade_out_s).timeout
	vfx_finished.emit()
	if auto_free and is_inside_tree():
		queue_free()


func _auto_stop() -> void:
	if _playing:
		stop()


## Override en hijas — arrancar particles/animations acá.
func _on_play() -> void:
	pass


## Override en hijas — apagar particles/animations acá.
func _on_stop() -> void:
	pass
