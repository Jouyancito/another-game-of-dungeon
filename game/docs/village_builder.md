# Village Builder

**Version**: 1.0
**Date**: 2026-07-18
**Status**: Implemented (bandit_prairie style only)
**Script**: `game/scripts/village_builder.gd` (`class_name VillageBuilder`, `RefCounted`, static entry point `build()`)

## What it does

Terrain/biome-aware village generator. Replaces the old ad-hoc bandit-camp
builder that used to live inline in `floor1_prairie.gd::_build_camp` (a loose
10-segment fence ring + a handful of CSG boxes, none of it terrain-aware).

Canon reference (read before touching this file): the fused Rivira x Axlin
identity synthesis at `game/docs/art/_references/bandit_camp/_synthesis.md`
(7 numbered traits, approved by Joan 2026-07-18). Every trait maps to a
private helper in `village_builder.gd`:

1. Palisade ring following the terrain — `_build_palisade_ring()`
2. Double-gate airlock at the entrance — `_build_airlock()`
3. Watchtower on the highest ring point — `_build_watchtower()`
4. Central hut = most protected/solid spot — `_build_central_hut()` + `_find_flattest_spot()`
5. Inner ring of 2-4 lesser structures — `_build_inner_ring()`
6. Palisade patches (storytelling scars) — `_build_patches()`
7. Small-prop scatter — `_scatter_small_props()`

## Structure vs. style

Same split as the Blender asset motor: geometry vs. lookdev.

- **Structure** is the algorithm in `village_builder.gd`. It is biome-agnostic
  — it only knows about ring math, terrain sampling, and slope/variance
  checks. It never hardcodes an asset path or a color.
- **Style** is a plain `Dictionary` passed into `build()`. It carries every
  asset path and every tunable (jitter amounts, counts, colors). Adding a new
  biome or faction (e.g. `civil_prairie`, `bandit_ice`) means adding a new
  Dictionary constant — zero changes to the algorithm.

Today only one style exists: `VillageBuilder.STYLE_BANDIT_PRAIRIE`, reusing
the existing outpost prop pack (`game/assets/art/piso1_pradera/props/outpost/`).

### Style dictionary schema

| Key | Type | Meaning |
|---|---|---|
| `palisade_scene` | PackedScene | one ring segment (fence panel) |
| `gate_scene` | PackedScene | used for both leaves of the double-gate airlock |
| `reinforcement_scene` | PackedScene | patch prop overlapped on a damaged segment |
| `tower_topper_scene` | PackedScene | prop mounted atop the watchtower scaffold |
| `lesser_structure_scenes` | Array[PackedScene] | inner-ring prop pool |
| `small_prop_scenes` | Array[PackedScene] | scatter pool (lantern/banner/etc.) |
| `ground_color` | Color | dirt-patch CSG ground color |
| `structure_color` | Color | hut/tent CSG box color |
| `log_color` | Color | hearth logs CSG color |
| `segment_count` | int | palisade ring segment count |
| `jitter_yaw_deg` | float | per-segment yaw jitter, +/- degrees |
| `jitter_scale_pct` | float | per-segment scale jitter, +/- fraction |
| `jitter_lean_deg` | float | per-segment lean jitter, +/- degrees |
| `patch_count` | Vector2i | min/max reinforced palisade segments |
| `lesser_structure_count` | Vector2i | min/max inner-ring structures |
| `small_prop_count` | Vector2i | min/max scattered small props |
| `hut_size` | Vector3 | central building CSG box dimensions |
| `tent_size` | Vector3 | inner-ring CSG tent box dimensions |
| `lesser_structure_prop_chance` | float (optional, default 0.5) | chance an inner-ring slot uses a real prop instead of a CSG tent box |

A bandit style leans on high jitter (`jitter_yaw_deg`/`jitter_scale_pct`/
`jitter_lean_deg` all high) for the Rivira "desparejo" look. A future civil
style would drop those toward zero and swap in ordered props.

## Integration

`floor1_prairie.gd::_build_camp(poi)` is now a one-line delegate:

```gdscript
func _build_camp(poi: POISystem.POI) -> void:
    VillageBuilder.build(self, poi, get_terrain_height, _rng, _add_camp_prop, VillageBuilder.STYLE_BANDIT_PRAIRIE)
```

- `get_terrain_height` (bound Callable) — `Callable(x: float, z: float) -> float`,
  used for every per-segment Y-snap and every slope/variance check.
- `_rng` — the floor's seeded `RandomNumberGenerator`. Passed by reference
  (RefCounted); every random draw inside `VillageBuilder` advances the same
  seeded sequence, so worlds stay reproducible. **Never** call `randi()`/
  `randf()` globals inside this file.
- `_add_camp_prop` — unchanged instantiate → `Transform3D` → `"grounded"`
  group → `_scatter_apply_geo_flags(inst, 80.0)` → `add_child` pattern, with
  one new optional parameter: `lean_rad` (extra tilt around the prop's own
  yaw-relative forward axis, used only by the palisade ring's jitter).

CSG-built structural pieces (ground patch, watchtower scaffold, central hut,
hearth, inner-ring tents) are added directly via `parent.add_child()` with a
plain `StandardMaterial3D` — same pattern the old `_build_camp` used for its
tents/logs, so no new material plumbing was introduced.

## Preview in proc_lab

`game/scenes/dev/proc_lab.tscn` sets `lab_poi_focus = "camp"` on the floor
script. `generate()` then produces ONLY the camp POI, recentered at world
origin at true scale, and `_compute_height_at` flattens the whole cell —
useful for eyeballing the layout in isolation, but every
`terrain_height_cb` call there returns ~flat ground (variance ~0), so slope
rejection and Y-snapping have nothing to react to. Real slopes only appear on
the full 600m map. Press the seed-reroll key to see different jitter/gate/
patch rolls.

## Known gaps / TODOs

- No watchtower-like asset exists in the outpost pack (verified 2026-07-18 —
  ~15 props: fence/gate/hedge/cart/banner/pillar/planks/chimney/fountain/
  lantern, nothing vertical-defensive). `_build_watchtower()` builds a plain
  CSG scaffold (hexagonal cylinder + platform box) topped with a banner prop.
  Marked with a `TODO(village_builder)` comment in the source — replace once
  the Blender motor ships a real tower.
- No "building" prop exists in the pack either, so the central hut and
  inner-ring tents are always CSG boxes today. The style dict has no
  `hut_scene` key yet; add one (with a `null` check falling back to the CSG
  box) once a real hut/tent asset ships.
- Only `bandit_prairie` is implemented. A `civil_prairie` variant (low
  jitter, cultivation, ordered props) is scoped by the synthesis doc but not
  built.
