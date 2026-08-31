class_name NightVeilDissolveVFX
extends VFXBase

## Velo Nocturno — canon §7: "el Danzante se desvanece entre sombras (Demon Slayer forma
## viento)". SUSTAINED: duration_s = 0, so player_skills.gd owns stop() on toggle-off.
## A toggle that auto-expired would lie about whether the veil is still up.

@onready var _veil: GPUParticles3D = $Veil
@onready var _wisps: GPUParticles3D = $Wisps


func _on_play() -> void:
	if _veil:
		_veil.restart()
		_veil.emitting = true
	if _wisps:
		_wisps.restart()
		_wisps.emitting = true


func _on_stop() -> void:
	if _veil:
		_veil.emitting = false
	if _wisps:
		_wisps.emitting = false
