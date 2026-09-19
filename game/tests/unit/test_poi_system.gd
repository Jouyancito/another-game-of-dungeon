extends GutTest

# POISystem — pond-guarantee regression (audit bioma/cobertura-assets-vs-visible, 2026-07-30).
#
# Pond is a minor POI drawn with replacement across 3 types (altar/well/pond).
# Before this fix, minor_count = randi_range(2,4) meant ~31% of seeds landed
# zero ponds — no damp-water dressing anywhere on the map for that run. The
# fix forces one pond first, then fills the rest of the minor slots normally,
# so altar/well keep their existing distribution.

const SEED_SAMPLE_SIZE: int = 200
const MAP_SIZE: Vector2 = Vector2(600.0, 600.0)


func _poi_types(pois: Array) -> Array:
	return pois.map(func(p): return (p as POISystem.POI).type)


func test_every_seed_has_at_least_one_pond() -> void:
	var system: POISystem = POISystem.new()
	for seed_val in range(SEED_SAMPLE_SIZE):
		var pois: Array = system.generate_pois(seed_val, MAP_SIZE, Callable())
		var types: Array = _poi_types(pois)
		assert_true(types.has("pond"), "seed %d produced no pond" % seed_val)


func test_minor_poi_total_count_is_unchanged() -> void:
	# The guarantee must not change how many minor POIs exist overall (2-4) —
	# only which types they resolve to.
	var system: POISystem = POISystem.new()
	for seed_val in range(SEED_SAMPLE_SIZE):
		var pois: Array = system.generate_pois(seed_val, MAP_SIZE, Callable())
		var minor_total: int = 0
		for p in pois:
			var poi: POISystem.POI = p as POISystem.POI
			if POISystem.POI_CATALOG[poi.type]["category"] == "minor":
				minor_total += 1
		assert_between(minor_total, 2, 4, "seed %d had %d minor POIs, expected 2-4" % [seed_val, minor_total])


func test_altar_and_well_still_appear_across_seeds() -> void:
	# Guard against an over-correction that always forces pond and starves the
	# other two minor types out of existence entirely.
	var system: POISystem = POISystem.new()
	var altar_seen := false
	var well_seen := false
	for seed_val in range(SEED_SAMPLE_SIZE):
		var pois: Array = system.generate_pois(seed_val, MAP_SIZE, Callable())
		var types: Array = _poi_types(pois)
		if types.has("altar"):
			altar_seen = true
		if types.has("well"):
			well_seen = true
		if altar_seen and well_seen:
			break
	assert_true(altar_seen, "altar never appeared across %d seeds" % SEED_SAMPLE_SIZE)
	assert_true(well_seen, "well never appeared across %d seeds" % SEED_SAMPLE_SIZE)
