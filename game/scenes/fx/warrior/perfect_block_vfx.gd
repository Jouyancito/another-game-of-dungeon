class_name PerfectBlockVFX
extends VFXBase

## Bloqueo Perfecto — shield frontal + flash on reactive hit.
## Canon: flash blanco + grieta en escudo (Sekiro deflect spark).
##
## Componentes:
##   - Shield: quad kite-shape acero+oro low opacity durante ventana parry
##   - Flash: sphere blanca emission fuerte (trigger_parry_flash al block exitoso)
##   - Sparks: burst blanco+dorado radial al parry
##
## API extendida sobre VFXBase:
##   play()                    — muestra shield durante reactive window (duration_s)
##   trigger_parry_flash()     — spark+flash al detectar block exitoso (llamar en cualquier momento)
##   stop()                    — oculta shield (normalmente auto al expirar duration_s)
##
## Triggered desde player_skills.gd _execute_reactive() en play(), y al recibir hit en ventana
## llamar trigger_parry_flash() antes/después de aplicar el reflejo.

@onready var _shield: MeshInstance3D = $ShieldAnchor/Shield
@onready var _flash: MeshInstance3D = $ShieldAnchor/Flash
@onready var _sparks: GPUParticles3D = $ShieldAnchor/Sparks

var _flash_tween: Tween = null
var _shield_tween: Tween = null


func _on_play() -> void:
	_show_shield()


func _on_stop() -> void:
	_hide_shield()


func trigger_parry_flash() -> void:
	if _flash == null:
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash.visible = true
	_flash.scale = Vector3.ONE * 0.5
	var mat := _flash.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_color.a = 1.0
	_flash_tween = create_tween().set_parallel(true)
	_flash_tween.tween_property(_flash, "scale", Vector3.ONE * 1.8, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if mat:
		_flash_tween.tween_property(mat, "albedo_color:a", 0.0, 0.22).set_trans(Tween.TRANS_LINEAR)
	if _sparks:
		_sparks.restart()
		_sparks.emitting = true


func _show_shield() -> void:
	if _shield == null:
		return
	if _shield_tween and _shield_tween.is_valid():
		_shield_tween.kill()
	_shield.visible = true
	var mat := _shield.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_color.a = 0.0
	_shield_tween = create_tween()
	if mat:
		_shield_tween.tween_property(mat, "albedo_color:a", 0.55, 0.08).set_trans(Tween.TRANS_LINEAR)


func _hide_shield() -> void:
	if _shield == null:
		return
	if _shield_tween and _shield_tween.is_valid():
		_shield_tween.kill()
	var mat := _shield.get_surface_override_material(0) as StandardMaterial3D
	_shield_tween = create_tween()
	if mat:
		_shield_tween.tween_property(mat, "albedo_color:a", 0.0, 0.15).set_trans(Tween.TRANS_LINEAR)
	_shield_tween.tween_callback(_hide_shield_mesh)


func _hide_shield_mesh() -> void:
	if _shield:
		_shield.visible = false
