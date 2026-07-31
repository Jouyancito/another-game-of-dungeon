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
	# Anchor POIs (siempre presentes)
	"entrance":   { "size": Vector2(30, 30),  "enemy_count": 0,  "category": "anchor" },
	"boss":       { "size": Vector2(80, 80),  "enemy_count": 8,  "category": "anchor" },

	# Major POIs (3-5 por piso)
	"ruins":      { "size": Vector2(60, 60),  "enemy_count": 8,  "category": "major" },
	"camp":       { "size": Vector2(40, 40),  "enemy_count": 3,  "category": "major" },
	"giant_tree": { "size": Vector2(50, 50),  "enemy_count": 5,  "category": "major" },

	# Minor POIs (2-4 por piso)
	"altar":      { "size": Vector2(15, 15),  "enemy_count": 2,  "category": "minor" },
	"well":       { "size": Vector2(12, 12),  "enemy_count": 0,  "category": "minor" },
	"pond":       { "size": Vector2(25, 25),  "enemy_count": 2,  "category": "minor" },
}

# ── Constants ──────────────────────────────────────────────────────────────────

const MIN_EDGE_MARGIN: float   = 30.0
const MIN_POI_GAP: float       = 80.0
const BOSS_MIN_DISTANCE: float = 350.0
const MAX_PLACE_TRIES: int     = 500

# ── Public API ─────────────────────────────────────────────────────────────────

func generate_pois(p_seed: int, map_size: Vector2, border_func: Callable = Callable()) -> Array[POI]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = p_seed

	var pois: Array[POI] = []

	# -- Entrada: borde West --
	var entrance_def: Dictionary = POI_CATALOG["entrance"]
	var entrance_size: Vector2 = entrance_def["size"] as Vector2
	var entrance_z: float = rng.randf_range(-map_size.y * 0.15, map_size.y * 0.15)
	var entrance_pos: Vector3 = Vector3(
		-map_size.x * 0.5 + entrance_size.x * 0.5 + MIN_EDGE_MARGIN + 20.0,
		0.0,
		entrance_z
	)
	# The organic border varies per seed; this west-edge entrance was placed WITHOUT
	# validating it (unlike the boss/major/minor POIs below), so for some seeds it
	# landed outside the playable terrain and the player spawned into the void.
	# Pull it toward center until it is inside — center is always inside → terminates.
	var pull_tries: int = 0
	while not _is_inside_border(entrance_pos, border_func) and pull_tries < 64:
		entrance_pos = entrance_pos.lerp(Vector3.ZERO, 0.1)
		pull_tries += 1
	var entrance: POI = POI.new("entrance", entrance_size, entrance_pos)
	entrance.is_entrance = true
	entrance.enemy_count = entrance_def["enemy_count"]
	pois.append(entrance)

	# -- Boss: borde East --
	var boss_def: Dictionary = POI_CATALOG["boss"]
	var boss_size: Vector2 = boss_def["size"] as Vector2
	var boss_poi: POI = null
	for _t in range(MAX_PLACE_TRIES):
		var boss_z: float = rng.randf_range(-map_size.y * 0.25, map_size.y * 0.25)
		var boss_pos: Vector3 = Vector3(
			map_size.x * 0.5 - boss_size.x * 0.5 - MIN_EDGE_MARGIN - 20.0,
			0.0,
			boss_z
		)
		if boss_pos.distance_to(entrance_pos) >= BOSS_MIN_DISTANCE:
			if _is_inside_border(boss_pos, border_func):
				boss_poi = POI.new("boss", boss_size, boss_pos)
				break
	if boss_poi == null:
		boss_poi = POI.new("boss", boss_size, Vector3(
			map_size.x * 0.5 - boss_size.x * 0.5 - MIN_EDGE_MARGIN - 20.0, 0.0, 0.0
		))
	boss_poi.is_boss = true
	boss_poi.enemy_count = boss_def["enemy_count"]
	pois.append(boss_poi)

	# -- Major POIs (3-5) --
	var major_types: Array = _get_types_by_category("major")
	var major_count: int = rng.randi_range(3, 5)
	for i in range(major_count):
		var poi_type: String = major_types[rng.randi() % major_types.size()]
		_try_place_poi(poi_type, pois, rng, map_size, border_func)

	# -- Minor POIs (2-4) --
	var minor_types: Array = _get_types_by_category("minor")
	var minor_count: int = rng.randi_range(2, 4)
	# Targeted guarantee: pond is a minor POI split 3 ways with replacement, so
	# an unguaranteed draw left ~31% of runs with ZERO ponds (audit
	# bioma/cobertura-assets-vs-visible, 2026-07-30) — and no ponds means no
	# damp-water dressing (reeds, future mushroom clusters) anywhere on the map.
	# Force one pond first, then fill the rest with the normal random draw so
	# altar/well keep their existing distribution untouched.
	_try_place_poi("pond", pois, rng, map_size, border_func)
	for i in range(minor_count - 1):
		var poi_type: String = minor_types[rng.randi() % minor_types.size()]
		_try_place_poi(poi_type, pois, rng, map_size, border_func)

	return pois

# ── Private helpers ────────────────────────────────────────────────────────────

func _get_types_by_category(category: String) -> Array:
	var result: Array = []
	for key: String in POI_CATALOG:
		if POI_CATALOG[key]["category"] == category:
			result.append(key)
	return result

func _try_place_poi(poi_type: String, pois: Array[POI], rng: RandomNumberGenerator, map_size: Vector2, border_func: Callable) -> void:
	var def: Dictionary = POI_CATALOG[poi_type] as Dictionary
	var poi_size: Vector2 = def["size"] as Vector2
	for _t in range(MAX_PLACE_TRIES):
		var rx: float = rng.randf_range(-map_size.x * 0.4 + poi_size.x * 0.5,
									map_size.x * 0.4 - poi_size.x * 0.5)
		var rz: float = rng.randf_range(-map_size.y * 0.4 + poi_size.y * 0.5,
									map_size.y * 0.4 - poi_size.y * 0.5)
		var candidate_pos: Vector3 = Vector3(rx, 0.0, rz)
		var candidate: POI = POI.new(poi_type, poi_size, candidate_pos)
		if _no_overlap(candidate, pois) and _is_inside_border(candidate_pos, border_func):
			candidate.enemy_count = def["enemy_count"]
			pois.append(candidate)
			return
	push_warning("POISystem: no se pudo colocar POI '%s'" % poi_type)

func _is_inside_border(pos: Vector3, border_func: Callable) -> bool:
	if not border_func.is_valid():
		return true
	return border_func.call(pos) as bool

func _no_overlap(candidate: POI, existing: Array[POI]) -> bool:
	for other in existing:
		var min_x: float = (candidate.size.x + other.size.x) * 0.5 + MIN_POI_GAP
		var min_z: float = (candidate.size.y + other.size.y) * 0.5 + MIN_POI_GAP
		var dx: float = abs(candidate.position.x - other.position.x)
		var dz: float = abs(candidate.position.z - other.position.z)
		if dx < min_x and dz < min_z:
			return false
	return true
