class_name ShadowStepVanishVFX
extends VFXBase

## Paso de Sombra — canon §7: "disolución en partículas negras, reaparición en origen
## con chispa". The dissolve sells that the body LEFT, not that it moved fast.

@onready var _dissolve: GPUParticles3D = $Dissolve
@onready var _spark: GPUParticles3D = $ReappearSpark


func _on_play() -> void:
	if _dissolve:
		_dissolve.restart()
		_dissolve.emitting = true
	if _spark:
		_spark.restart()
		_spark.emitting = true


func _on_stop() -> void:
	if _dissolve:
		_dissolve.emitting = false
	if _spark:
		_spark.emitting = false
