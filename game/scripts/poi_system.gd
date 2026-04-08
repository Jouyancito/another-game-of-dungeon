extends RefCounted
class_name POISystem

# ── POI Data ───────────────────────────────────────────────────────────────────

class POI:
	var type: String
	var size: Vector2        # ancho × largo en metros
	var position: Vector3    # centro del POI en el mundo (Y = 0)
	var enemy_count: int
	var is_entrance: bool
	var is_boss: bool

	func _init(p_type: String, p_size: Vector2, p_pos: Vector3) -> void:
		type = p_type
		size = p_size
		position = p_pos
		enemy_count = 0
		is_entrance = false
		is_boss = false

# ── POI Type Catalog ───────────────────────────────────────────────────────────
# Cada entrada: { "size": Vector2, "enemy_count": int }
# Agregar más tipos acá sin tocar el resto del sistema.

const POI_CATALOG := {
	"entrance": { "size": Vector2(15, 15), "enemy_count": 0 },
	"ruins":    { "size": Vector2(25, 20), "enemy_count": 4 },
	"boss":     { "size": Vector2(32, 32), "enemy_count": 2 },
}

# ── Constants ──────────────────────────────────────────────────────────────────

const MIN_EDGE_MARGIN   := 10.0   # Margen mínimo desde el borde del mapa
const MIN_POI_GAP       := 80.0   # Distancia mínima borde a borde entre POIs
const BOSS_MIN_DISTANCE := 200.0  # Distancia mínima entre entrada y boss
const MAX_PLACE_TRIES   := 500    # Intentos máximos antes de rendirse

# ── Public API ─────────────────────────────────────────────────────────────────

## Genera y retorna un Array de POI distribuidos en el mapa.
## entrance siempre en borde West (X mínima),
## boss siempre en borde East (X máxima), mínimo BOSS_MIN_DISTANCE de la entrada.
## El resto se distribuye aleatoriamente respetando distancias mínimas.
func generate_pois(seed: int, map_size: Vector2) -> Array[POI]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var pois: Array[POI] = []

	# -- Entrada: centro en borde West, Z aleatoria ----
	var entrance_def := POI_CATALOG["entrance"]
	var entrance_size := entrance_def["size"] as Vector2
	var entrance_z := _rand_range(rng, -map_size.y * 0.25, map_size.y * 0.25)
	var entrance_pos := Vector3(
		-map_size.x * 0.5 + entrance_size.x * 0.5 + MIN_EDGE_MARGIN,
		0.0,
		entrance_z
	)
	var entrance := POI.new("entrance", entrance_size, entrance_pos)
	entrance.is_entrance = true
	entrance.enemy_count = entrance_def["enemy_count"]
	pois.append(entrance)

	# -- Boss: centro en borde East, Z aleatoria, >= BOSS_MIN_DISTANCE de entrada --
	var boss_def := POI_CATALOG["boss"]
	var boss_size := boss_def["size"] as Vector2
	var boss_poi: POI = null
	for _t in range(MAX_PLACE_TRIES):
		var boss_z := _rand_range(rng, -map_size.y * 0.35, map_size.y * 0.35)
		var boss_pos := Vector3(
			map_size.x * 0.5 - boss_size.x * 0.5 - MIN_EDGE_MARGIN,
			0.0,
			boss_z
		)
		var candidate := POI.new("boss", boss_size, boss_pos)
		if boss_pos.distance_to(entrance_pos) >= BOSS_MIN_DISTANCE:
			boss_poi = candidate
			break
	if boss_poi == null:
		# Fallback: coloca el boss al otro extremo sin restricción Z
		boss_poi = POI.new("boss", boss_size, Vector3(
			map_size.x * 0.5 - boss_size.x * 0.5 - MIN_EDGE_MARGIN, 0.0, 0.0
		))
	boss_poi.is_boss = true
	boss_poi.enemy_count = boss_def["enemy_count"]
	pois.append(boss_poi)

	# -- POIs intermedios: el resto del catálogo excluyendo entrada y boss --
	var intermediate_types := POI_CATALOG.keys().filter(func(k): return k != "entrance" and k != "boss")
	for poi_type in intermediate_types:
		var def := POI_CATALOG[poi_type] as Dictionary
		var poi_size := def["size"] as Vector2
		var placed := false
		for _t in range(MAX_PLACE_TRIES):
			var rx := _rand_range(rng, -map_size.x * 0.5 + poi_size.x * 0.5 + MIN_EDGE_MARGIN,
			                            map_size.x * 0.5 - poi_size.x * 0.5 - MIN_EDGE_MARGIN)
			var rz := _rand_range(rng, -map_size.y * 0.5 + poi_size.y * 0.5 + MIN_EDGE_MARGIN,
			                            map_size.y * 0.5 - poi_size.y * 0.5 - MIN_EDGE_MARGIN)
			var candidate := POI.new(poi_type, poi_size, Vector3(rx, 0.0, rz))
			if _no_overlap(candidate, pois):
				candidate.enemy_count = def["enemy_count"]
				pois.append(candidate)
				placed = true
				break
		if not placed:
			push_warning("POISystem: no se pudo colocar POI '%s' con seed %d" % [poi_type, seed])

	return pois

# ── Private helpers ────────────────────────────────────────────────────────────

func _rand_range(rng: RandomNumberGenerator, from: float, to: float) -> float:
	return rng.randf_range(from, to)

## Verifica que el candidato no se superponga con ningún POI existente.
## Usa distancia borde a borde basada en los radios de los bounding rectangles.
func _no_overlap(candidate: POI, existing: Array[POI]) -> bool:
	for other in existing:
		# Separación mínima = mitad de ambos tamaños + MIN_POI_GAP
		var min_x := (candidate.size.x + other.size.x) * 0.5 + MIN_POI_GAP
		var min_z := (candidate.size.y + other.size.y) * 0.5 + MIN_POI_GAP
		var dx := abs(candidate.position.x - other.position.x)
		var dz := abs(candidate.position.z - other.position.z)
		if dx < min_x and dz < min_z:
			return false
	return true
