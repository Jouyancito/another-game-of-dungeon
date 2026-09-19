class_name SwiftCutTrailVFX
extends VFXBase

## Corte Fugaz — canon `docs/skills/danzante_sombras.md` §7:
## "trails de sombra violeta-negra, hits encadenados = afterimages".
##
## One-shot attached to the player. The trail is the cut; the afterimages are the speed.

@onready var _trail: GPUParticles3D = $ShadowTrail
@onready var _afterimages: GPUParticles3D = $Afterimages


func _on_play() -> void:
	if _trail:
		_trail.restart()
		_trail.emitting = true
	if _afterimages:
		_afterimages.restart()
		_afterimages.emitting = true


func _on_stop() -> void:
	if _trail:
		_trail.emitting = false
	if _afterimages:
		_afterimages.emitting = false
