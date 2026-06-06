extends Node3D

## proc_lab — banco de pruebas procedural del Piso 1.
##
## Itera piezas del generador (terreno, cristales, árboles, rocas, agua, biolum,
## fauna) en una celda CHICA sin cargar el mapa de 600m. Reusa el MISMO generador
## (floor1_prairie.gd) vía proc_bounds + active_layers; no duplica lógica de gen.
##
## Controles:
##   R = reseed (regenera con semilla nueva — ver variaciones en segundos)
##   G = correr detector de flotantes (intent-aware) e imprimir reporte
##   H = snap: bajar al terreno todo lo "grounded" que flote (excluye aéreos)
##   F = ciclar capa "fauna/enemies" on/off y regenerar
##
## El root de la escena ES un Floor1Prairie con proc_bounds chico y skip_game_ui=true.
## Este script es un controller hijo: maneja hotkeys + overlay, delega gen al padre.

## Tamaño de la celda de prueba en metros (cuadrada). 120 = espacio para 1-2 POIs.
@export var cell_size: float = 120.0
## Semilla inicial. R la cambia para iterar.
@export var start_seed: int = 12345

var _floor: Node3D            # el Floor1Prairie (padre, dueño del generador)
var _overlay: Label
const GroundSnapUtilityScript := preload("res://scripts/ground_snap_utility.gd")
var _util                      # GroundSnapUtility — vía preload (class_name no resuelve en headless sin re-scan del editor)
var _busy: bool = false       # evita reseed concurrente mientras regenera


func _ready() -> void:
	_util = GroundSnapUtilityScript.new()
	# El padre es el generador. Tomamos referencia y aplicamos params de laboratorio.
	_floor = get_parent() as Node3D
	if _floor == null or not _floor.has_method("regenerate"):
		push_error("[proc_lab] el padre debe ser un Floor1Prairie (con regenerate())")
		return
	_build_overlay()
	_refresh_overlay()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_R:
			_reseed()
		KEY_G:
			_run_floating_check()
		KEY_H:
			_run_snap()
		KEY_F:
			_toggle_layer("enemies")


func _reseed() -> void:
	if _busy:
		return
	_busy = true
	var new_seed: int = randi() % 1_000_000
	if _overlay:
		_overlay.text = "Regenerando… seed=%d" % new_seed
	await _floor.regenerate(new_seed)
	_busy = false
	_refresh_overlay()
	print_rich("[color=cyan]proc_lab: reseed → %d[/color]" % new_seed)


func _toggle_layer(layer: String) -> void:
	if _busy:
		return
	var layers: Dictionary = _floor.get("active_layers")
	layers[layer] = not bool(layers.get(layer, true))
	_floor.set("active_layers", layers)
	_busy = true
	await _floor.regenerate(int(_floor.get("world_seed")))
	_busy = false
	_refresh_overlay()
	print_rich("[color=cyan]proc_lab: capa '%s' → %s[/color]" % [layer, str(layers[layer])])


func _run_floating_check() -> void:
	if not _floor.has_method("get_terrain_height"):
		return
	var report: Dictionary = _util.analyze(_floor, Callable(_floor, "get_terrain_height"))
	_util.print_report(report)
	if _overlay:
		_overlay.text = _overlay_text() + "\n[G] flotando=%d  enterrados=%d  ok=%d" % [
			report["floating"].size(), report["sunken"].size(), report["ok"],
		]


func _run_snap() -> void:
	if not _floor.has_method("get_terrain_height"):
		return
	var moved: int = _util.snap_grounded(_floor, Callable(_floor, "get_terrain_height"))
	print_rich("[color=green]proc_lab: snap → %d objetos bajados al terreno[/color]" % moved)
	if _overlay:
		_overlay.text = _overlay_text() + "\n[H] snapped=%d" % moved


# ── Overlay ────────────────────────────────────────────────────────────────────

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ProcLabOverlay"
	add_child(layer)
	_overlay = Label.new()
	_overlay.position = Vector2(16, 16)
	_overlay.add_theme_color_override("font_color", Color.WHITE)
	_overlay.add_theme_color_override("font_outline_color", Color.BLACK)
	_overlay.add_theme_constant_override("outline_size", 4)
	layer.add_child(_overlay)


func _refresh_overlay() -> void:
	if _overlay:
		_overlay.text = _overlay_text()


func _overlay_text() -> String:
	var seed_val: int = int(_floor.get("world_seed"))
	var bounds: Vector2 = _floor.get("proc_bounds")
	var layers: Dictionary = _floor.get("active_layers")
	var active: Array[String] = []
	for k in layers:
		if bool(layers[k]):
			active.append(str(k))
	return "proc_lab  seed=%d  cell=%.0fx%.0fm\nlayers: %s\n[R]eseed  [G]float-check  [H]snap  [F]toggle-enemies" % [
		seed_val, bounds.x, bounds.y, ", ".join(active),
	]
