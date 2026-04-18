class_name PunchImpactVFX
extends VFXBase

## Puño de Guerra — impact visual en punto de hit.
## Canon: shockwave tierra low-poly naranja (Demon Slayer Pilar de Piedra).
##
## Componentes:
##   - Flash: sphere mesh emission fuerte fade (0.12s)
##   - Sparks: burst radial partículas rojo rage + dorado (0.25s)
##
## Triggered por player_skills.gd en cada hit conectado (`_apply_skill_to_targets` for punch).
## El caller debe setear global_position al punto de impacto antes de play().

@onready var _flash: MeshInstance3D = $Flash
@onready var _sparks: GPUParticles3D = $Sparks

var _flash_tween: Tween = null


func _on_play() -> void:
	if _sparks:
		_sparks.restart()
		_sparks.emitting = true
	_play_flash()


func _play_flash() -> void:
	if _flash == null:
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash.visible = true
	_flash.scale = Vector3.ONE * 0.4
	var mat := _flash.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_color.a = 1.0
		mat.emission_energy_multiplier = 3.5
	_flash_tween = create_tween().set_parallel(true)
	_flash_tween.tween_property(_flash, "scale", Vector3.ONE * 1.4, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if mat:
		_flash_tween.tween_property(mat, "albedo_color:a", 0.0, 0.18).set_trans(Tween.TRANS_LINEAR)


func _on_stop() -> void:
	if _sparks:
		_sparks.emitting = false
