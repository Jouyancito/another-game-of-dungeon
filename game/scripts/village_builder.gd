class_name VillageBuilder
extends RefCounted

## VillageBuilder — terrain/biome-aware village generator.
##
## Replaces the old ad-hoc bandit-camp layout in `floor1_prairie.gd::_build_camp`.
## Canon reference: `game/docs/art/_references/bandit_camp/_synthesis.md`
## (fused Rivira x Axlin identity, v1 — 7 numbered traits, approved by Joan 2026-07-18).
##
## STRUCTURE vs STYLE (same split as the Blender motor: geometry vs lookdev):
##   - STRUCTURE lives in this file as the algorithm below (`build()` + private
##     helpers). It is biome-agnostic: palisade ring, double-gate airlock,
##     watchtower on the highest point, protected central building, inner ring
##     of lesser structures, palisade patches, small-prop scatter.
##   - STYLE is a plain Dictionary (see schema below) carrying every asset path
##     and every tunable (jitter amounts, counts, colors). A new biome/faction
##     (e.g. "civil_prairie", "bandit_ice") is just a new Dictionary constant —
##     zero changes to the algorithm.
##
## STYLE DICTIONARY SCHEMA (all keys required unless noted "optional"):
##   palisade_scene          PackedScene   — one ring segment (fence panel)
##   gate_scene              PackedScene   — used for BOTH the exterior and the
##                                           interior leaf of the double-gate airlock
##   reinforcement_scene     PackedScene   — patch prop overlapped on a damaged segment
##   tower_topper_scene      PackedScene   — prop mounted atop the watchtower scaffold
##   lesser_structure_scenes Array[PackedScene] — pool for the inner-ring props
##   small_prop_scenes       Array[PackedScene] — scatter pool (lantern/banner/etc.)
##   ground_color            Color         — dirt-patch CSG ground color
##   structure_color         Color         — hut/tent CSG box color
##   log_color                Color         — hearth logs CSG color
##   segment_count           int           — palisade ring segment count
##   jitter_yaw_deg          float         — per-segment yaw jitter, +/- degrees
##   jitter_scale_pct        float         — per-segment scale jitter, +/- fraction
##   jitter_lean_deg         float         — per-segment lean jitter, +/- degrees
##   patch_count             Vector2i      — min/max reinforced palisade segments
##   lesser_structure_count  Vector2i      — min/max inner-ring structures
##   small_prop_count        Vector2i      — min/max scattered small props
##   hut_size                Vector3       — central building CSG box dimensions
##   tent_size                Vector3      — inner-ring CSG tent box dimensions
##   lesser_structure_prop_chance optional float (default 0.5) — chance an
##                                           inner-ring slot uses a real prop
##                                           instead of a CSG tent box
##
## Preview: `game/scenes/dev/proc_lab.tscn` sets `lab_poi_focus = "camp"` on the
## floor script, which recenters the camp POI at world origin at true scale and
## flattens the whole cell — good for eyeballing the village in isolation, but
## every `terrain_height_cb` call there returns ~flat ground. Real slopes only
## show up on the 600m map.

const PALISADE_RADIUS_RATIO: float = 0.42
const SLOPE_TOLERANCE: float = 1.5   # meters — max height delta a candidate spot tolerates
const CENTER_SEARCH_TRIES: int = 5
const INNER_RING_TRIES: int = 8


## Entry point. `terrain_height_cb` is `Callable(x: float, z: float) -> float`
## (pass the floor script's `get_terrain_height`). `add_prop_cb` is
## `Callable(scene: PackedScene, node_name: String, world_pos: Vector3,
## rot_y: float, scale: float = 1.0, lean_rad: float = 0.0) -> void` (pass the
## floor script's `_add_camp_prop`, extended with an optional lean param — see
## that function for the grounding/geo-flags contract this preserves).
static func build(
	parent: Node3D,
	poi: POISystem.POI,
	terrain_height_cb: Callable,
	rng: RandomNumberGenerator,
	add_prop_cb: Callable,
	style: Dictionary
) -> void:
	var pos: Vector3 = poi.position
	var sz: Vector2 = poi.size
	var radius: float = minf(sz.x, sz.y) * PALISADE_RADIUS_RATIO
	var segment_count: int = style.get("segment_count", 12)
	var gate_index: int = rng.randi_range(0, segment_count - 1)

	_build_ground_patch(parent, pos, sz, style, terrain_height_cb)

	_build_palisade_ring(parent, pos, radius, segment_count, gate_index, rng, add_prop_cb, style, terrain_height_cb)
	_build_airlock(parent, pos, radius, segment_count, gate_index, rng, add_prop_cb, style, terrain_height_cb)
	_build_patches(parent, pos, radius, segment_count, gate_index, rng, add_prop_cb, style, terrain_height_cb)
	_build_watchtower(parent, pos, radius, segment_count, gate_index, rng, add_prop_cb, style, terrain_height_cb)

	var hut_pos: Vector3 = _find_flattest_spot(pos, radius * 0.2, CENTER_SEARCH_TRIES, rng, terrain_height_cb)
	_build_central_hut(parent, hut_pos, style)
	_build_hearth(parent, hut_pos, style)

	_build_inner_ring(parent, pos, radius, rng, add_prop_cb, style, terrain_height_cb)
	_scatter_small_props(parent, pos, sz, rng, add_prop_cb, style)


# ── Terrain sampling helpers ────────────────────────────────────────────────

static func _height_variance(cx: float, cz: float, sample_r: float, terrain_height_cb: Callable) -> float:
	var heights: Array[float] = [terrain_height_cb.call(cx, cz)]
	for offset in [Vector2(sample_r, 0), Vector2(-sample_r, 0), Vector2(0, sample_r), Vector2(0, -sample_r)]:
		heights.append(terrain_height_cb.call(cx + offset.x, cz + offset.y))
	return heights.max() - heights.min()


## Tries a few candidates around `center` within `search_radius` and returns
## the world position (x, z from the candidate, y from terrain) with the
## lowest local height variance — used for both the hut and inner structures.
static func _find_flattest_spot(
	center: Vector3, search_radius: float, tries: int, rng: RandomNumberGenerator, terrain_height_cb: Callable
) -> Vector3:
	var best_pos: Vector3 = center
	var best_variance: float = INF
	for i in range(tries):
		var cx: float = center.x if i == 0 else center.x + rng.randf_range(-search_radius, search_radius)
		var cz: float = center.z if i == 0 else center.z + rng.randf_range(-search_radius, search_radius)
		var variance: float = _height_variance(cx, cz, 2.0, terrain_height_cb)
		if variance < best_variance:
			best_variance = variance
			best_pos = Vector3(cx, terrain_height_cb.call(cx, cz), cz)
	return best_pos


# ── Trait 1: palisade ring following the terrain ────────────────────────────

static func _build_palisade_ring(
	parent: Node3D, pos: Vector3, radius: float, segment_count: int, gate_index: int,
	rng: RandomNumberGenerator, add_prop_cb: Callable, style: Dictionary, terrain_height_cb: Callable
) -> void:
	var jitter_yaw: float = deg_to_rad(style.get("jitter_yaw_deg", 10.0))
	var jitter_scale: float = style.get("jitter_scale_pct", 0.12)
	var jitter_lean: float = deg_to_rad(style.get("jitter_lean_deg", 6.0))
	for i in range(segment_count):
		if i == gate_index:
			continue   # the airlock (trait 2) replaces the ring segment here
		var angle: float = float(i) * TAU / float(segment_count)
		var sx: float = pos.x + cos(angle) * radius
		var sz: float = pos.z + sin(angle) * radius
		var sy: float = terrain_height_cb.call(sx, sz)
		var tangent_yaw: float = angle + PI * 0.5
		var yaw: float = tangent_yaw + rng.randf_range(-jitter_yaw, jitter_yaw)
		var scale: float = 1.0 + rng.randf_range(-jitter_scale, jitter_scale)
		var lean: float = rng.randf_range(-jitter_lean, jitter_lean)
		add_prop_cb.call(style["palisade_scene"], "VillagePalisade%d" % i, Vector3(sx, sy, sz), yaw, scale, lean)


# ── Trait 2: double-gate airlock (Axlin) ────────────────────────────────────

static func _build_airlock(
	parent: Node3D, pos: Vector3, radius: float, segment_count: int, gate_index: int,
	rng: RandomNumberGenerator, add_prop_cb: Callable, style: Dictionary, terrain_height_cb: Callable
) -> void:
	var angle: float = float(gate_index) * TAU / float(segment_count)
	var radial: Vector3 = Vector3(cos(angle), 0, sin(angle))
	var tangent: Vector3 = Vector3(-sin(angle), 0, cos(angle))
	var gate_yaw: float = angle + PI * 0.5

	var ext_pos: Vector3 = pos + radial * radius
	ext_pos.y = terrain_height_cb.call(ext_pos.x, ext_pos.z)
	var corridor_depth: float = rng.randf_range(4.0, 6.0)
	var int_pos: Vector3 = pos + radial * (radius - corridor_depth)
	int_pos.y = terrain_height_cb.call(int_pos.x, int_pos.z)

	add_prop_cb.call(style["gate_scene"], "VillageGateExterior", ext_pos, gate_yaw)
	add_prop_cb.call(style["gate_scene"], "VillageGateInterior", int_pos, gate_yaw)

	# Two short palisade stubs flanking the corridor so the airlock reads as an
	# enclosed passage, not just two gates floating in the open. ponytail: the
	# stub width approximates one ring segment's arc — good enough at this
	# scale, revisit if the pack ever ships a dedicated corridor-wall piece.
	var stub_half_width: float = radius * (TAU / float(segment_count)) * 0.5
	var mid: Vector3 = (ext_pos + int_pos) * 0.5
	for side in [-1.0, 1.0]:
		var stub_pos: Vector3 = mid + tangent * stub_half_width * side
		stub_pos.y = terrain_height_cb.call(stub_pos.x, stub_pos.z)
		var name_suffix: String = "L" if side < 0 else "R"
		add_prop_cb.call(style["palisade_scene"], "VillageGateStub%s" % name_suffix, stub_pos, angle)


# ── Trait 5 (patches): reinforced palisade segments ─────────────────────────

static func _build_patches(
	parent: Node3D, pos: Vector3, radius: float, segment_count: int, gate_index: int,
	rng: RandomNumberGenerator, add_prop_cb: Callable, style: Dictionary, terrain_height_cb: Callable
) -> void:
	var patch_range: Vector2i = style.get("patch_count", Vector2i(1, 2))
	var patch_count: int = rng.randi_range(patch_range.x, patch_range.y)
	var used: Array[int] = [gate_index]
	for p in range(patch_count):
		var idx: int = rng.randi_range(0, segment_count - 1)
		var attempts: int = 0
		while used.has(idx) and attempts < segment_count:
			idx = rng.randi_range(0, segment_count - 1)
			attempts += 1
		if used.has(idx):
			continue   # ring fully claimed already (tiny segment_count edge case)
		used.append(idx)
		var angle: float = float(idx) * TAU / float(segment_count)
		var sx: float = pos.x + cos(angle) * radius
		var sz: float = pos.z + sin(angle) * radius
		var sy: float = terrain_height_cb.call(sx, sz)
		# Overlapped at a visibly wrong angle — storytelling scar, not a clean repair.
		var patch_yaw: float = angle + PI * 0.5 + rng.randf_range(-0.6, 0.6)
		add_prop_cb.call(style["reinforcement_scene"], "VillagePatch%d" % idx, Vector3(sx, sy, sz), patch_yaw)


# ── Trait 3: watchtower on the highest ring point ───────────────────────────

static func _build_watchtower(
	parent: Node3D, pos: Vector3, radius: float, segment_count: int, gate_index: int,
	rng: RandomNumberGenerator, add_prop_cb: Callable, style: Dictionary, terrain_height_cb: Callable
) -> void:
	var best_pos: Vector3 = pos + Vector3(radius, 0, 0)
	var best_height: float = -INF
	for i in range(segment_count):
		if i == gate_index:
			continue
		var angle: float = float(i) * TAU / float(segment_count)
		var sx: float = pos.x + cos(angle) * radius
		var sz: float = pos.z + sin(angle) * radius
		var sy: float = terrain_height_cb.call(sx, sz)
		if sy > best_height:
			best_height = sy
			best_pos = Vector3(sx, sy, sz)

	# TODO(village_builder): replace this CSG scaffold with a real watchtower
	# asset once the Blender motor generates one — the outpost pack has no
	# tower-like piece (verified 2026-07-18, ~15 props: fence/gate/hedge/cart/
	# banner/pillar/planks/chimney/fountain/lantern, nothing vertical-defensive).
	var wood: StandardMaterial3D = StandardMaterial3D.new()
	wood.albedo_color = style.get("structure_color", Color(0.4, 0.3, 0.2))

	var scaffold: CSGCylinder3D = CSGCylinder3D.new()
	scaffold.name = "VillageWatchtowerScaffold"
	scaffold.radius = 0.5
	scaffold.height = 9.0
	scaffold.sides = 6
	scaffold.use_collision = true
	scaffold.material_override = wood
	scaffold.position = best_pos + Vector3(0, 4.5, 0)
	parent.add_child(scaffold)

	var platform: CSGBox3D = CSGBox3D.new()
	platform.name = "VillageWatchtowerPlatform"
	platform.size = Vector3(2.4, 0.3, 2.4)
	platform.use_collision = false
	platform.material_override = wood
	platform.position = best_pos + Vector3(0, 8.5, 0)
	parent.add_child(platform)

	add_prop_cb.call(style["tower_topper_scene"], "VillageWatchtowerTopper",
		best_pos + Vector3(0, 8.8, 0), rng.randf() * TAU)


# ── Trait 4: central building = most protected/solid ────────────────────────

static func _build_central_hut(parent: Node3D, hut_pos: Vector3, style: Dictionary) -> void:
	var hut_size: Vector3 = style.get("hut_size", Vector3(6.0, 3.2, 5.0))
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = style.get("structure_color", Color(0.45, 0.32, 0.22))
	var hut: CSGBox3D = CSGBox3D.new()
	hut.name = "VillageCentralHut"
	hut.size = hut_size
	hut.use_collision = true
	hut.material_override = mat
	hut.position = hut_pos + Vector3(0, hut_size.y * 0.5, 0)
	parent.add_child(hut)


static func _build_hearth(parent: Node3D, hut_pos: Vector3, style: Dictionary) -> void:
	var fire_pos: Vector3 = hut_pos + Vector3(3.5, 0, 3.0)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.1, 0.05)

	var fire: CSGCylinder3D = CSGCylinder3D.new()
	fire.name = "VillageHearth"
	fire.radius = 0.6
	fire.height = 0.3
	fire.use_collision = false
	fire.material_override = mat
	fire.position = fire_pos + Vector3(0, 0.15, 0)
	parent.add_child(fire)

	var fire_light: OmniLight3D = OmniLight3D.new()
	fire_light.name = "VillageHearthLight"
	fire_light.light_color = Color(1.0, 0.6, 0.2)
	fire_light.light_energy = 0.6
	fire_light.omni_range = 15.0
	fire_light.position = fire_pos + Vector3(0, 1.0, 0)
	parent.add_child(fire_light)

	var log_mat: StandardMaterial3D = StandardMaterial3D.new()
	log_mat.albedo_color = style.get("log_color", Color(0.32, 0.23, 0.16))
	for i in range(3):
		var angle: float = float(i) * TAU / 3.0
		var log: CSGBox3D = CSGBox3D.new()
		log.name = "VillageHearthLog%d" % i
		log.size = Vector3(2.0, 0.4, 0.5)
		log.use_collision = true
		log.material_override = log_mat
		log.position = fire_pos + Vector3(cos(angle) * 2.0, 0.2, sin(angle) * 2.0)
		parent.add_child(log)


# ── Trait 4/5: inner ring of lesser structures ──────────────────────────────

static func _build_inner_ring(
	parent: Node3D, pos: Vector3, palisade_radius: float,
	rng: RandomNumberGenerator, add_prop_cb: Callable, style: Dictionary, terrain_height_cb: Callable
) -> void:
	var count_range: Vector2i = style.get("lesser_structure_count", Vector2i(2, 4))
	var count: int = rng.randi_range(count_range.x, count_range.y)
	var prop_chance: float = style.get("lesser_structure_prop_chance", 0.5)
	var tent_size: Vector3 = style.get("tent_size", Vector3(4.0, 2.4, 3.0))
	var tent_mat: StandardMaterial3D = StandardMaterial3D.new()
	tent_mat.albedo_color = style.get("structure_color", Color(0.45, 0.32, 0.22))
	var pool: Array = style.get("lesser_structure_scenes", [])

	for i in range(count):
		var candidate_pos: Vector3 = pos
		var best_variance: float = INF
		for t in range(INNER_RING_TRIES):
			var r: float = rng.randf_range(palisade_radius * 0.30, palisade_radius * 0.55)
			var a: float = rng.randf() * TAU
			var cx: float = pos.x + cos(a) * r
			var cz: float = pos.z + sin(a) * r
			var variance: float = _height_variance(cx, cz, 2.0, terrain_height_cb)
			if variance <= SLOPE_TOLERANCE:
				candidate_pos = Vector3(cx, terrain_height_cb.call(cx, cz), cz)
				best_variance = variance
				break
			if variance < best_variance:
				best_variance = variance
				candidate_pos = Vector3(cx, terrain_height_cb.call(cx, cz), cz)

		if pool.size() > 0 and rng.randf() < prop_chance:
			add_prop_cb.call(pool[rng.randi() % pool.size()], "VillageInnerStructure%d" % i,
				candidate_pos, rng.randf() * TAU)
		else:
			var tent: CSGBox3D = CSGBox3D.new()
			tent.name = "VillageInnerTent%d" % i
			tent.size = tent_size
			tent.use_collision = true
			tent.material_override = tent_mat
			tent.position = candidate_pos + Vector3(0, tent_size.y * 0.5, 0)
			parent.add_child(tent)


# ── Trait 7: small-prop scatter ─────────────────────────────────────────────

static func _scatter_small_props(
	parent: Node3D, pos: Vector3, sz: Vector2,
	rng: RandomNumberGenerator, add_prop_cb: Callable, style: Dictionary
) -> void:
	var pool: Array = style.get("small_prop_scenes", [])
	if pool.is_empty():
		return
	var count_range: Vector2i = style.get("small_prop_count", Vector2i(3, 5))
	var count: int = rng.randi_range(count_range.x, count_range.y)
	for i in range(count):
		var px: float = pos.x + rng.randf_range(-sz.x * 0.32, sz.x * 0.32)
		var pz: float = pos.z + rng.randf_range(-sz.y * 0.32, sz.y * 0.32)
		add_prop_cb.call(pool[rng.randi() % pool.size()], "VillageSmallProp%d" % i,
			Vector3(px, pos.y, pz), rng.randf() * TAU)


# ── Ground dressing (dirt patch under the whole village) ───────────────────

static func _build_ground_patch(
	parent: Node3D, pos: Vector3, sz: Vector2, style: Dictionary, terrain_height_cb: Callable
) -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = style.get("ground_color", Color(0.362, 0.253, 0.172))
	var ground: CSGBox3D = CSGBox3D.new()
	ground.name = "VillageGround"
	ground.size = Vector3(sz.x, 0.04, sz.y)
	ground.use_collision = false
	ground.material_override = mat
	var ground_y: float = terrain_height_cb.call(pos.x, pos.z)
	ground.position = Vector3(pos.x, ground_y + 0.02, pos.z)
	parent.add_child(ground)


# ── Style data ───────────────────────────────────────────────────────────────

const _OUTPOST_DIR: String = "res://assets/art/piso1_pradera/props/outpost/"

## "bandit_prairie" — Rivira x Axlin fused identity (see doc header). High
## jitter, ragged reinforcement, no cultivation — raider camp, not a hamlet.
static var STYLE_BANDIT_PRAIRIE: Dictionary = {
	"palisade_scene": preload(_OUTPOST_DIR + "prop_fence_01.glb"),
	"gate_scene": preload(_OUTPOST_DIR + "prop_fence_gate_01.glb"),
	"reinforcement_scene": preload(_OUTPOST_DIR + "prop_fence_broken_01.glb"),
	"tower_topper_scene": preload(_OUTPOST_DIR + "prop_banner_red_01.glb"),
	"lesser_structure_scenes": [
		preload(_OUTPOST_DIR + "prop_cart_01.glb"),
		preload(_OUTPOST_DIR + "prop_cart_high_01.glb"),
	],
	"small_prop_scenes": [
		preload(_OUTPOST_DIR + "prop_lantern_01.glb"),
		preload(_OUTPOST_DIR + "prop_banner_green_01.glb"),
		preload(_OUTPOST_DIR + "prop_pillar_wood_01.glb"),
	],
	"ground_color": Color(0.362, 0.253, 0.172),
	"structure_color": Color(0.476, 0.340, 0.230),
	"log_color": Color(0.320, 0.234, 0.163),
	"segment_count": 12,
	"jitter_yaw_deg": 14.0,
	"jitter_scale_pct": 0.15,
	"jitter_lean_deg": 9.0,
	"patch_count": Vector2i(1, 2),
	"lesser_structure_count": Vector2i(2, 4),
	"small_prop_count": Vector2i(3, 5),
	"hut_size": Vector3(6.0, 3.2, 5.0),
	"tent_size": Vector3(4.0, 2.4, 3.0),
	"lesser_structure_prop_chance": 0.5,
}
