class_name ThousandShadowsVFX
extends VFXBase

## Danza de Mil Sombras — canon §7: "4s de afterimages superpuestos, grid de cortes
## visibles". The ultimate: the screen should read as more Danzantes than there are.

@onready var _afterimages: GPUParticles3D = $Afterimages
@onready var _cut_grid: GPUParticles3D = $CutGrid


func _on_play() -> void:
	if _afterimages:
		_afterimages.restart()
		_afterimages.emitting = true
	if _cut_grid:
		_cut_grid.restart()
		_cut_grid.emitting = true


func _on_stop() -> void:
	if _afterimages:
		_afterimages.emitting = false
	if _cut_grid:
		_cut_grid.emitting = false
