class_name ChargeVFX
extends VFXBase

## Embestida — dash ofensivo Warrior.
## Canon: trail polvo dorado One Piece Gear Second + speed lines + dust kick inicial.
## Duración debe matchear dash tween de B (0.3s) — coord via vfx_canon.md.
##
## Triggered desde player_skills.gd _execute_dash() al inicio del dash.
## El scene se parenta al player (sigue posición) y stop() al terminar el dash.

@onready var _dust_kick: GPUParticles3D = $DustKick
@onready var _trail: GPUParticles3D = $Trail
@onready var _speed_lines: GPUParticles3D = $SpeedLines


func _on_play() -> void:
	if _dust_kick:
		_dust_kick.restart()
		_dust_kick.emitting = true
	if _trail:
		_trail.restart()
		_trail.emitting = true
	if _speed_lines:
		_speed_lines.restart()
		_speed_lines.emitting = true


func _on_stop() -> void:
	if _trail:
		_trail.emitting = false
	if _speed_lines:
		_speed_lines.emitting = false
