extends RefCounted
class_name GroundSnapUtility

## Lector de altura de terreno + detector de objetos flotantes "intent-aware".
##
## Inserción Integral: en el piso 1 conviven cosas que DEBEN tocar el suelo
## (árboles, rocas, vegetación, fauna terrestre) y cosas que NO (cristales que
## cuelgan del techo, fauna voladora, luciérnagas a la deriva). Este util sólo
## evalúa lo marcado con intención de apoyo — grupo "grounded" — y deja en paz
## lo aéreo. La marca la ponen los spawners (floor1_prairie._place_instance,
## _snap_all_to_terrain, firefly._ready), no este script: acá no se adivina.
##
## Uso típico (desde proc_lab o floor1_prairie):
##   var util := GroundSnapUtility.new()
##   var report := util.analyze(self, get_terrain_height)   # solo lee + reporta
##   util.print_report(report)
##   var n := util.snap_grounded(self, get_terrain_height)   # baja los flotantes

## Tolerancia de flotación: por debajo de esto NO se considera flotante (juego de
## raíces/escala de los gltf). 30 cm es el umbral que separa "asentado" de "flota".
const DEFAULT_THRESHOLD: float = 0.3

## Grupos semánticos. Sólo "grounded" es snap-eligible; "aerial" se excluye SIEMPRE.
const GROUP_GROUNDED: String = "grounded"
const GROUP_AERIAL: String = "aerial"


## Calcula el mínimo Y MUNDIAL de todas las mallas visibles de un Node3D y sus hijos.
## Para gltf scatter: el root es Node3D, los MeshInstance3D son hijos.
## Recorre recursivamente buscando VisualInstance3D y transforma su AABB a espacio mundo.
## Devuelve INF si el nodo no tiene mallas (sin crashear).
##
## Nota: get_aabb() en MeshInstance3D devuelve el AABB en espacio LOCAL de la malla.
## Multiplicar por vi.global_transform lo lleva a espacio mundo.
## Esto es correcto incluso cuando el root tiene scale/rotation bakeados en su transform.
static func _world_min_y(root: Node3D) -> float:
	var min_y: float = INF
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is VisualInstance3D:
			var vi: VisualInstance3D = n as VisualInstance3D
			var local_aabb: AABB = vi.get_aabb()
			if local_aabb.size != Vector3.ZERO:
				# Transformar AABB local → mundo usando la global_transform de la malla.
				var world_aabb: AABB = vi.global_transform * local_aabb
				var bot_y: float = world_aabb.position.y  # mínimo Y del AABB
				if bot_y < min_y:
					min_y = bot_y
		for c in n.get_children():
			stack.append(c)
	return min_y


## Altura de la base del objeto en espacio mundo.
## Usa _world_min_y para encontrar el AABB bottom real.
## Si no hay mallas visibles (min_y == INF), cae a global_position.y como último recurso.
static func _object_base_y(obj: Node3D) -> float:
	var min_y: float = _world_min_y(obj)
	if min_y == INF:
		# Sin mallas — usar posición de la raíz (evita crash; delta será ~0)
		return obj.global_position.y
	return min_y


## Lee el terreno y clasifica los objetos "grounded": correctamente apoyados vs
## flotando por encima del suelo más que `threshold`. NO modifica nada.
##
## floor: el generador (debe exponer el grupo "grounded" y la función de altura).
## terrain_height_func: Callable (x, z) -> float (típicamente floor.get_terrain_height).
func analyze(floor: Node, terrain_height_func: Callable,
		threshold: float = DEFAULT_THRESHOLD) -> Dictionary:
	var report := {
		"grounded_total": 0,
		"floating": [],          # objetos grounded que flotan (> threshold)
		"sunken": [],            # objetos grounded enterrados (< -threshold)
		"ok": 0,                 # correctamente asentados
		"aerial_excluded": 0,    # excluidos por intención (no se evalúan)
		"threshold": threshold,
	}
	if not terrain_height_func.is_valid():
		push_warning("[GroundSnapUtility] terrain_height_func inválida")
		return report

	report["aerial_excluded"] = floor.get_tree().get_nodes_in_group(GROUP_AERIAL).size()

	var grounded: Array = floor.get_tree().get_nodes_in_group(GROUP_GROUNDED)
	report["grounded_total"] = grounded.size()
	for obj in grounded:
		if not is_instance_valid(obj) or not (obj is Node3D):
			continue
		var node3d: Node3D = obj as Node3D
		var pos: Vector3 = node3d.global_position
		var terrain_y: float = terrain_height_func.call(pos.x, pos.z)
		var base_y: float = _object_base_y(node3d)
		var delta: float = base_y - terrain_y
		if delta > threshold:
			report["floating"].append({
				"name": str(node3d.name),
				"position": pos,
				"terrain_y": terrain_y,
				"base_y": base_y,
				"float_amount": delta,
			})
		elif delta < -threshold:
			report["sunken"].append({
				"name": str(node3d.name),
				"position": pos,
				"terrain_y": terrain_y,
				"base_y": base_y,
				"sink_amount": -delta,
			})
		else:
			report["ok"] += 1
	return report


## Baja (o sube) todos los objetos "grounded" para que su base toque el terreno.
## Excluye SIEMPRE lo aéreo (no está en el grupo "grounded"). Devuelve cuántos movió.
## Imprime un resumen claro: total evaluados, cuántos movidos, cuántos sin AABB.
func snap_grounded(floor: Node, terrain_height_func: Callable,
		threshold: float = DEFAULT_THRESHOLD) -> int:
	if not terrain_height_func.is_valid():
		push_warning("[GroundSnapUtility] terrain_height_func inválida")
		return 0
	var moved: int = 0
	var no_mesh: int = 0  # nodos sin AABB válido (solo pivot disponible)
	var grounded: Array = floor.get_tree().get_nodes_in_group(GROUP_GROUNDED)
	print_rich("[color=cyan][GroundSnap] snap_grounded → %d nodos en grupo 'grounded'[/color]" % grounded.size())
	for obj in grounded:
		if not is_instance_valid(obj) or not (obj is Node3D):
			continue
		var node3d: Node3D = obj as Node3D
		var pos: Vector3 = node3d.global_position
		var terrain_y: float = terrain_height_func.call(pos.x, pos.z)
		var min_y: float = _world_min_y(node3d)
		if min_y == INF:
			# Sin mallas — no se puede calcular base real; se usa posición del pivot
			no_mesh += 1
			continue
		# base_y es el Y mundial del fondo de la malla.
		# center_to_base: distancia (signed) del pivot a la base en mundo Y.
		var base_y: float = min_y
		var center_to_base: float = base_y - pos.y
		var delta: float = base_y - terrain_y
		if absf(delta) <= threshold:
			continue
		# Reposicionar para que base == terreno: nuevo centro = terreno - center_to_base.
		node3d.global_position.y = terrain_y - center_to_base
		moved += 1
	print_rich("[color=green][GroundSnap] movidos=%d   sin_malla=%d   umbral=%.2fm[/color]" % [moved, no_mesh, threshold])
	return moved


## Imprime un reporte legible (RichText) del resultado de analyze().
func print_report(report: Dictionary) -> void:
	var floating: Array = report.get("floating", [])
	var sunken: Array = report.get("sunken", [])
	print_rich("[color=cyan]── GroundSnap: detector de flotantes (intent-aware) ──[/color]")
	print_rich("  grounded evaluados: [b]%d[/b]   aéreos excluidos: %d   umbral: %.2fm" % [
		report.get("grounded_total", 0),
		report.get("aerial_excluded", 0),
		report.get("threshold", DEFAULT_THRESHOLD),
	])
	print_rich("  [color=green]OK (asentados): %d[/color]" % report.get("ok", 0))
	print_rich("  [color=orange]flotando: %d[/color]   [color=yellow]enterrados: %d[/color]" % [
		floating.size(), sunken.size(),
	])
	for entry in floating:
		print_rich("    [color=orange]↑ %s  +%.2fm  @ (%.0f, %.0f)[/color]" % [
			entry["name"], entry["float_amount"],
			entry["position"].x, entry["position"].z,
		])
	for entry in sunken:
		print_rich("    [color=yellow]↓ %s  -%.2fm  @ (%.0f, %.0f)[/color]" % [
			entry["name"], entry["sink_amount"],
			entry["position"].x, entry["position"].z,
		])
