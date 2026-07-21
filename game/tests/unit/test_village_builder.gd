extends GutTest

# VillageBuilder — terrain/biome-aware village generator (2026-07-18).
# Canon: game/docs/art/_references/bandit_camp/_synthesis.md (7 numbered traits).
#
# These tests use test-double Callables instead of real POISystem/floor
# plumbing so they run fast and stay decoupled from the terrain/scatter
# systems — they only pin the STRUCTURE contract (trait 2's "never place
# other openings" + trait 3's tower + determinism), not the visual result
# (that is a proc_lab eyeball pass, per the project's verify-by-view rule).

var _recorded_calls: Array = []


func _fake_flat_terrain(_x: float, _z: float) -> float:
	return 0.0


func _record_prop(scene: PackedScene, node_name: String, world_pos: Vector3, rot_y: float, scale: float = 1.0, lean_rad: float = 0.0) -> void:
	_recorded_calls.append({
		"scene": scene, "name": node_name, "pos": world_pos,
		"rot_y": rot_y, "scale": scale, "lean": lean_rad,
	})


func _make_camp_poi() -> POISystem.POI:
	return POISystem.POI.new("camp", Vector2(40.0, 40.0), Vector3.ZERO)


func _run_build(p_seed: int) -> Node3D:
	_recorded_calls = []
	var parent := Node3D.new()
	add_child_autofree(parent)
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	VillageBuilder.build(
		parent, _make_camp_poi(), Callable(self, "_fake_flat_terrain"),
		rng, Callable(self, "_record_prop"), VillageBuilder.STYLE_BANDIT_PRAIRIE
	)
	return parent


func _names_with_prefix(prefix: String) -> Array:
	return _recorded_calls.filter(func(c): return String(c["name"]).begins_with(prefix))


func test_airlock_is_exactly_two_gates_and_two_stubs() -> void:
	_run_build(12345)
	var gate_calls: Array = _names_with_prefix("VillageGate")
	assert_eq(gate_calls.size(), 4, "double-gate airlock = exterior + interior + 2 corridor stubs, never more/less")


func test_gate_segment_never_doubles_as_a_normal_palisade_segment() -> void:
	var segment_count: int = VillageBuilder.STYLE_BANDIT_PRAIRIE.get("segment_count", 12)
	_run_build(777)
	var palisade_calls: Array = _names_with_prefix("VillagePalisade")
	# The airlock replaces exactly one ring slot — trait 2's "never place other
	# openings" means the ring must be short exactly one segment, no more.
	assert_eq(palisade_calls.size(), segment_count - 1)


func test_patches_never_land_on_the_gate_slot() -> void:
	var segment_count: int = VillageBuilder.STYLE_BANDIT_PRAIRIE.get("segment_count", 12)
	_run_build(4242)
	var present_indices: Dictionary = {}
	for c in _names_with_prefix("VillagePalisade"):
		present_indices[String(c["name"]).trim_prefix("VillagePalisade").to_int()] = true
	var gate_index: int = -1
	for i in range(segment_count):
		if not present_indices.has(i):
			gate_index = i
			break
	assert_ne(gate_index, -1, "exactly one segment index must be missing (the gate slot)")
	for c in _names_with_prefix("VillagePatch"):
		var patch_index: int = String(c["name"]).trim_prefix("VillagePatch").to_int()
		assert_ne(patch_index, gate_index, "a reinforcement patch must never land on the gate's own slot")


func test_watchtower_and_central_hut_are_built() -> void:
	var parent: Node3D = _run_build(99)
	assert_not_null(parent.find_child("VillageWatchtowerScaffold", false, false))
	assert_not_null(parent.find_child("VillageCentralHut", false, false))
	assert_not_null(parent.find_child("VillageHearth", false, false))
	var topper_calls: Array = _names_with_prefix("VillageWatchtowerTopper")
	assert_eq(topper_calls.size(), 1, "exactly one prop tops the watchtower")


func test_inner_ring_count_is_within_style_bounds() -> void:
	# Inner-ring slots land as either a real prop (via add_prop_cb, recorded) or
	# a CSG tent box (added directly as a child) — count both.
	var parent: Node3D = _run_build(2026)
	var count_range: Vector2i = VillageBuilder.STYLE_BANDIT_PRAIRIE.get("lesser_structure_count", Vector2i(2, 4))
	var prop_count: int = _names_with_prefix("VillageInnerStructure").size()
	var tent_count := 0
	for child in parent.get_children():
		if String(child.name).begins_with("VillageInnerTent"):
			tent_count += 1
	assert_between(prop_count + tent_count, count_range.x, count_range.y)


func test_build_is_deterministic_for_the_same_seed() -> void:
	_run_build(555)
	var first_calls: Array = _recorded_calls.duplicate(true)
	_run_build(555)
	var second_calls: Array = _recorded_calls
	assert_eq(first_calls.size(), second_calls.size())
	for i in range(first_calls.size()):
		assert_eq(first_calls[i]["name"], second_calls[i]["name"])
		assert_eq(first_calls[i]["pos"], second_calls[i]["pos"])
		assert_eq(first_calls[i]["rot_y"], second_calls[i]["rot_y"])
