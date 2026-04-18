class_name WarCryVFX
extends VFXBase

## Grito de Guerra — aura toggle 10m radio.
## Canon: onda sonora concéntrica dorada (JJK Domain preview).
##
## Componentes:
##   - Burst: particle burst inicial dorado radial (one-shot, ~0.5s)
##   - Shockwave: ring torus escala 0→10m (tween, ~0.5s, fade opacity)
##   - DomeMarker: ring persistente marca borde aura mientras toggle activo
##   - SustainedAura: partículas low-opacity flotando dentro radius (continuo)
##
## duration_s = 0 → sostenida. El caller (player_skills toggle) llama stop() cuando el toggle off.

@export var aura_radius_m: float = 10.0
@export var shockwave_expand_time: float = 0.55

@onready var _burst: GPUParticles3D = $Burst
@onready var _shockwave: MeshInstance3D = $Shockwave
@onready var _dome_marker: MeshInstance3D = $DomeMarker
@onready var _sustained: GPUParticles3D = $SustainedAura

var _shockwave_tween: Tween = null


func _on_play() -> void:
	if _burst:
		_burst.restart()
		_burst.emitting = true
	if _sustained:
		_sustained.restart()
		_sustained.emitting = true
	if _dome_marker:
		_dome_marker.visible = true
		_dome_marker.scale = Vector3(aura_radius_m, 1.0, aura_radius_m)
	_play_shockwave()


func _on_stop() -> void:
	if _sustained:
		_sustained.emitting = false
	if _dome_marker:
		_dome_marker.visible = false


func _play_shockwave() -> void:
	if _shockwave == null:
		return
	if _shockwave_tween and _shockwave_tween.is_valid():
		_shockwave_tween.kill()
	_shockwave.visible = true
	_shockwave.scale = Vector3(0.5, 1.0, 0.5)
	var mat := _shockwave.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_color.a = 0.85
	_shockwave_tween = create_tween().set_parallel(true)
	_shockwave_tween.tween_property(_shockwave, "scale", Vector3(aura_radius_m, 1.0, aura_radius_m), shockwave_expand_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if mat:
		_shockwave_tween.tween_property(mat, "albedo_color:a", 0.0, shockwave_expand_time).set_trans(Tween.TRANS_LINEAR)
