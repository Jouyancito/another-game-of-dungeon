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

const POI_CATALOG: Dictionary = {
	"entrance": { "size": Vector2(15, 15), "enemy_count": 0 },
	"ruins":    { "size": Vector2(25, 20), "enemy_count": 4 },
	"boss":     { "size": Vector2(32, 32), "enemy_count": 2 },
}

# ── Constants ──────────────────────────────────────────────────────────────────

const MIN_EDGE_MARGIN: float   = 10.0
const MIN_POI_GAP: float       = 80.0
const BOSS_MIN_DISTANCE: float = 200.0
const MAX_PLACE_TRIES: int     = 500

# ── Public API ─────────────────────────────────────────────────────────────────

func generate_pois(p_seed: int, map_size: Vector2) -> Array[POI]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = p_seed

	var pois: Array[POI] = []

	# -- Entrada: centro en borde West, Z aleatoria ----
	var entrance_def: Dictionary = POI_CATALOG["entrance"]
	var entrance_size: Vector2 = entrance_def["size"] as Vector2
	var entrance_z: float = rng.randf_range(-map_size.y * 0.25, map_size.y * 0.25)
	var entrance_pos: Vector3 = Vector3(
		-map_size.x * 0.5 + entrance_size.x * 0.5 + MIN_EDGE_MARGIN,
		0.0,
		entrance_z
	)
	var entrance: POI = POI.new("entrance", entrance_size, entrance_pos)
	entrance.is_entrance = true
	entrance.enemy_count = entrance_def["enemy_count"]
	pois.append(entrance)

	# -- Boss: centro en borde East, Z aleatoria, >= BOSS_MIN_DISTANCE de entrada --
	var boss_def: Dictionary = POI_CATALOG["boss"]
	var boss_size: Vector2 = boss_def["size"] as Vector2
	var boss_poi: POI = null
	for _t in range(MAX_PLACE_TRIES):
		var boss_z: float = rng.randf_range(-map_size.y * 0.35, map_size.y * 0.35)
		var boss_pos: Vector3 = Vector3(
			map_size.x * 0.5 - boss_size.x * 0.5 - MIN_EDGE_MARGIN,
			0.0,
			boss_z
		)
		var candidate: POI = POI.new("boss", boss_size, boss_pos)
		if boss_pos.distance_to(entrance_pos) >= BOSS_MIN_DISTANCE:
			boss_poi = candidate
			break
	if boss_poi == null:
		boss_poi = POI.new("boss", boss_size, Vector3(
			map_size.x * 0.5 - boss_size.x * 0.5 - MIN_EDGE_MARGIN, 0.0, 0.0
		))
	boss_poi.is_boss = true
	boss_poi.enemy_count = boss_def["enemy_count"]
	pois.append(boss_poi)

	# -- POIs intermedios --
	var intermediate_types: Array = POI_CATALOG.keys().filter(func(k: String) -> bool: return k != "entrance" and k != "boss")
	for poi_type: String in intermediate_types:
		var def: Dictionary = POI_CATALOG[poi_type] as Dictionary
		var poi_size: Vector2 = def["size"] as Vector2
		var placed: bool = false
		for _t in range(MAX_PLACE_TRIES):
			var rx: float = rng.randf_range(-map_size.x * 0.5 + poi_size.x * 0.5 + MIN_EDGE_MARGIN,
										map_size.x * 0.5 - poi_size.x * 0.5 - MIN_EDGE_MARGIN)
			var rz: float = rng.randf_range(-map_size.y * 0.5 + poi_size.y * 0.5 + MIN_EDGE_MARGIN,
										map_size.y * 0.5 - poi_size.y * 0.5 - MIN_EDGE_MARGIN)
			var candidate: POI = POI.new(poi_type, poi_size, Vector3(rx, 0.0, rz))
			if _no_overlap(candidate, pois):
				candidate.enemy_count = def["enemy_count"]
				pois.append(candidate)
				placed = true
				break
		if not placed:
			push_warning("POISystem: no se pudo colocar POI '%s' con seed %d" % [poi_type, p_seed])

	return pois

# ── Private helpers ────────────────────────────────────────────────────────────

func _no_overlap(candidate: POI, existing: Array[POI]) -> bool:
	for other in existing:
		var min_x: float = (candidate.size.x + other.size.x) * 0.5 + MIN_POI_GAP
		var min_z: float = (candidate.size.y + other.size.y) * 0.5 + MIN_POI_GAP
		var dx: float = abs(candidate.position.x - other.position.x)
		var dz: float = abs(candidate.position.z - other.position.z)
		if dx < min_x and dz < min_z:
			return false
	return true
