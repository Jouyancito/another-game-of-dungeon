# Floor 1 "Pradera" — Sprint 1 Build Package (synthesis, ready-to-apply)

**Date:** 2026-06-06 · **Owner:** Joan · **Filter:** "Does this ship in the 10-min demo video?"
**Scope canon (Joan-confirmed 2026-06-06):** bounded prairie = one tower level · far boundary reads as **tower edge** · **partial** mountain crown (1 sector, NOT 360°) as non-traversable depth · water = **pool + short stream inside the clearing only** (no boundary lake, seas deferred) · **visible equipment DEFERRED to post-alpha** · **organic folk music** (Valheim-style, CC0/CC-BY) is the ONLY new workstream this round.

> This package SYNTHESIZES five inputs (map audit, music sources, asset sources, world-architect layout, perf budget, impl spec) into ONE applicable plan. Where an input was **factually wrong against the live code**, this doc corrects it and flags the correction in **bold**. Execute this doc; do not re-plan.

---

## 0. Live-code corrections folded in (read first)

These were verified against the repo on 2026-06-06. They override the raw inputs:

1. **Asset git-commit list was WRONG.** The IMPL SPEC said `vegetation/clover`, `mushroom`, `common`, `props/outpost_extras`, `terrain/pebbles` are uncommitted. They are **already tracked** (`git ls-files` returns 3/5/9/22/3 files respectively). The **actually-uncommitted** asset folder is `game/assets/art/ui/` (UI theme + fonts + foozle). See §S1-d for the corrected list.
2. **An `AmbientFaunaSpawner` already exists** (`game/scenes/levels/components/ambient_fauna_spawner.gd`, `class_name AmbientFaunaSpawner`) and is **already wired into the tscn** (ext_resource id `3_spawner`), with `butterfly.tscn` / `bird.tscn` / `rabbit.tscn` already referenced (ids 4/5/6). Firefly MUST conform to the spawner contract (`@export creature_scene`, `count`, `spawn_radius`, emits `despawned`) — NOT be a standalone self-driving node as the IMPL SPEC drafted. Corrected firefly script in §S1-b.
3. **No fauna script calls `add_to_group("ambient")`** — butterfly/bird/rabbit are plain `Node3D` (no `CharacterBody3D`, so no collision layer to clear, but the **group is genuinely missing**). Adding the group is a real 1-line fix per fauna script (§S1-b), needed so AI/raycasts/AoE can ignore ambient fauna by group.
4. **`CRYSTAL_LIGHTS_EVERY = 3`** (confirmed, line 32). With ~35 crystals → ~11-12 cluster OmniLights + 3 monarch + 1 ambient + 1 fire ≈ **16-17 baseline lights**. This answers the perf open question: the firefly light cap drops from 8 to **≤4** to stay under the 20-light red line. See §RISKS.
5. Confirmed line refs: `COLOR_WATER` L74, `COLOR_BORDER` L68, `_build_well` L961, `_build_pond` L985, `_build_organic_border` L414, `_generate_vegetation` L1049, `get_terrain_height` L283, `TERRAIN_EDGE_RISE` L55, `base_enemy.gd sub_tier` L23.
6. **No `assets/audio/` dir exists** — Sprint 1 creates it (§S1-a target folders).

---

## 1. SPRINT SEQUENCE (Floor 1 to done)

Each sprint is a reviewable slice **< ~400 changed lines**, ordered by **camera impact** (what the 10-min video shows first). TIER refs map to `_floor1_integral_plan.md`.

| Sprint | Name | Camera impact | Plan TIER | What the video gains | ~Lines |
|---|---|---|---|---|---|
| **S1** | **Water + Ambient life + Music + habitat hook** | HIGH — first thing on screen: living water, fauna, folk score | TIER 1 (water, fauna, audio) | Pool/stream get a real toon-water shader (was flat disc); fireflies + butterflies populate the pool halo; organic folk music plays; `habitat_type` field lands for ecology | ~330 |
| **S2** | **Tower-edge re-skin + partial mountain crown** | HIGH — the boundary reads as a colossal tower, not a brown wall | TIER 1 (boundary) / TIER 2 (sky) | Border masonry re-skin + baked sky/mountain crown in 1 sector → the "you're inside something vast" read | ~250 |
| **S3** | **Ground-cover MultiMesh (grass/clover/juncos) + chunked culling** | HIGH — ground reads dense + alive, perf stays safe | TIER 2 (density) | Dense desaturated ground layer via MMI chunks (≤13k blades, hard-cull 70m); juncos ring the pool | ~280 |
| **S4** | **Habitat-aware spawn wiring + ecology placement** | MED — enemies sit where they belong (slimes by water, goats on hill) | TIER 2 (ecology) | Spawners set `habitat_type` per POI/zone; fauna clusters read coherent | ~220 |
| **S5** | **Landmark pass: rock-outcrop + crack-cave + stream source + soft hill + boss beacon** | MED-HIGH — navigation landmarks + boss direction read | TIER 2/3 (landmarks) | The single "down" signal (crack-cave) + west boss glow + vista hill | ~300 |
| **S6** | **Polish: SFX (water splash/ambient), LOD pass on trees, final palette/lightmap, video baseline** | LOW-MED — final coat, then record | TIER 3 (polish) | Splash SFX, tree MultiMesh migration (perf red-line #8), record 10-min slice | ~350 |

**Explicitly POST-ALPHA / future-floor (NOT in any sprint above):**
- **Visible equipment** (weapon-in-hand / armor / transmog) — DEFERRED, out of scope, no design/source/spec this cycle. Player model stays as-is.
- **Large water / seas / boundary lakes** — DEFERRED to a future floor. Floor 1 water is pool + short stream only.
- **Tree/rock migration to MultiMesh** is started in S6 but the *full* streaming-chunk system is post-alpha (S6 does the minimum to clear red-line #8).

---

## 2. SPRINT 1 — full ready-to-apply package

Sprint 1 visibly adds to the demo video: **a real animated toon-water pool + stream**, **fireflies pulsing over the pool at dusk-cavern light**, **butterflies over the spawn clearing**, and **organic folk music** playing on load. Plus the invisible-but-required `habitat_type` hook for later ecology.

### S1-a · ASSET DOWNLOAD LIST

Target root: `game/assets/`. **Music is the priority** (only new workstream). Create folders if missing.

| # | Need | Pick | License | Source page | Target folder |
|---|---|---|---|---|---|
| 1 | Main exploration loop | **Windswept** — Kevin MacLeod | CC-BY 4.0 (attrib req.) | https://incompetech.com/wordpress/2010/09/windswept-with-sheet-music/ | `game/assets/audio/music/` |
| 2 | Calm/safe-zone variant | **Elf Meditation** — Kevin MacLeod | CC-BY 4.0 | https://incompetech.com/music/royalty-free/?keywords=meditation | `game/assets/audio/music/` |
| 3 | Short ambient loop (menu/calm) | **Heavenly Loop** — isaiah658 | **CC0** | https://opengameart.org/content/heavenly-loop | `game/assets/audio/music/` |
| 4 | Folk POI ambient (outpost/camp) | **Medieval: The Old Tower Inn** — RandomMind | **CC0** | https://opengameart.org/content/medieval-the-old-tower-inn | `game/assets/audio/music/` |
| 5 | Extended exploration (16m) | **Tranquility** — Kevin MacLeod | CC-BY 3.0 | https://freemusicarchive.org/music/Kevin_MacLeod/Calming/Tranquility/ | `game/assets/audio/music/` |
| 6 | Light travel/transition | **Carefree** — Kevin MacLeod | CC-BY 4.0 | https://incompetech.com/wordpress/2014/08/carefree/ | `game/assets/audio/music/` |
| 7 | Water-edge reeds/cattails (juncos) | **Kenney Nature Kit** (330 assets) | **CC0** | https://kenney.nl/assets/nature-kit | `game/assets/art/piso1_pradera/vegetation/reeds/` |
| 8 | Distant mountain crown (1 sector) | Kenney Nature Kit terrain **OR** Blender sculpt **OR** bake to sky | CC0 / custom | https://kenney.nl/assets/nature-kit | `game/assets/art/piso1_pradera/terrain/mountains/` (S2) |
| 9 | (Optional) water normal map | ambientCG "water" | CC0 (no attrib) | https://ambientcg.com/ | `game/assets/art/piso1_pradera/props/water/` — **optional, shader is procedural** |

**Download count for S1 (core):** **6 music tracks** (the priority). Items 7-9 are S2/S3 prep — fetch opportunistically; the S1 water shader is fully procedural (no texture needed) and reeds are S3.

> **Music = 6 picks**: Windswept (main loop), Elf Meditation (calm), Heavenly Loop (CC0 short loop), Medieval: The Old Tower Inn (CC0 folk POI), Tranquility (16m extended), Carefree (light transition).

**Attribution file** — create `game/assets/audio/CREDITS.md` with:
```
Music by Kevin MacLeod (incompetech.com) licensed under Creative Commons Attribution 4.0 International.
 - Windswept, Elf Meditation, Tranquility (CC-BY 3.0), Carefree
CC0 (Public Domain, no attribution required):
 - "Heavenly Loop" by isaiah658 (OpenGameArt)
 - "Medieval: The Old Tower Inn" by RandomMind (OpenGameArt)
```

**PowerShell direct-download lines** (run from repo root; creates folders). Incompetech/OGA/FMA require navigating the page for the final media URL — page URLs are stable, media URLs rotate, so these target the canonical media endpoints where known and otherwise leave a TODO to grab the file link from the page:

```powershell
# --- folders ---
New-Item -ItemType Directory -Force -Path "game/assets/audio/music" | Out-Null
New-Item -ItemType Directory -Force -Path "game/assets/art/piso1_pradera/vegetation/reeds" | Out-Null

# --- Kevin MacLeod (incompetech) — Windswept (verify final URL on the page if 404) ---
Invoke-WebRequest -Uri "https://incompetech.com/music/royalty-free/mp3-royaltyfree/Windswept.mp3" -OutFile "game/assets/audio/music/windswept.mp3"
# --- Carefree ---
Invoke-WebRequest -Uri "https://incompetech.com/music/royalty-free/mp3-royaltyfree/Carefree.mp3" -OutFile "game/assets/audio/music/carefree.mp3"
# --- Elf Meditation (confirm exact filename on incompetech search page) ---
Invoke-WebRequest -Uri "https://incompetech.com/music/royalty-free/mp3-royaltyfree/Elf%20Meditation.mp3" -OutFile "game/assets/audio/music/elf_meditation.mp3"
# --- Tranquility (FMA mirror; if blocked, download from the FMA page) ---
Invoke-WebRequest -Uri "https://incompetech.com/music/royalty-free/mp3-royaltyfree/Tranquility.mp3" -OutFile "game/assets/audio/music/tranquility.mp3"

# --- OpenGameArt CC0 (grab the file link from the page; IDs change, so set $url from the page) ---
# Heavenly Loop:  https://opengameart.org/content/heavenly-loop  (download the .ogg)
# The Old Tower Inn: https://opengameart.org/content/medieval-the-old-tower-inn (download .mp3 + .wav loop)
# Example once you copy the real link:
# Invoke-WebRequest -Uri "<oga-file-url>.ogg" -OutFile "game/assets/audio/music/heavenly_loop.ogg"
# Invoke-WebRequest -Uri "<oga-file-url>.mp3" -OutFile "game/assets/audio/music/old_tower_inn.mp3"

# --- Kenney Nature Kit (CC0, direct, for reeds in S3) ---
Invoke-WebRequest -Uri "https://kenney.nl/media/pages/assets/nature-kit/37ac38a37b-1677698939/kenney_nature-kit.zip" -OutFile "game/assets/art/piso1_pradera/vegetation/reeds/kenney_nature-kit.zip"
```
> NOTE on incompetech URLs: the `/music/royalty-free/mp3-royaltyfree/<Track>.mp3` pattern is the canonical incompetech media path but track filenames occasionally differ (spaces vs none). If a line 404s, open the page URL from the table, copy the actual MP3 link, and substitute. OGA download IDs are not stable — always copy the file link from the content page.

### S1-b · CODE CHANGES (exact, ready-to-apply — NO equipment code)

#### (1) `base_enemy.gd` — add `habitat_type` export

File: `game/scenes/enemy/base_enemy.gd` — **after line 23** (`@export var sub_tier: SubTier = SubTier.A ...`):

```gdscript
@export var habitat_type: String = "open_field"  # "open_field" | "water_edge" | "cave" | "aerial" | "boss_arena"
```
Used by spawners (§S4) and future loot biome-modifiers. Default keeps every existing enemy valid.

#### (2) Toon water shader — NEW file

File: `game/scenes/levels/water_toon.gdshader`

```glsl
shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_opaque;

// Floor 1 toon water — desaturated, vertex ripple + procedural normal drift, fresnel edge.
// Cosmetic only (no hazard). Single transparent layer (perf red-line #5). No reflections.

uniform float time_scale : hint_range(0.1, 2.0) = 0.8;
uniform float wave_amplitude : hint_range(0.0, 0.2) = 0.05;
uniform float wave_frequency : hint_range(0.5, 3.0) = 2.0;
uniform vec3  water_color : source_color = vec3(0.20, 0.35, 0.45); // desaturated (Kimetsu palette)
uniform float base_transparency : hint_range(0.3, 1.0) = 0.7;

void vertex() {
	float w = sin(VERTEX.x * wave_frequency + TIME * time_scale) * wave_amplitude;
	w += sin(VERTEX.z * wave_frequency * 0.7 + TIME * time_scale * 0.8) * wave_amplitude * 0.5;
	VERTEX.y += w;
}

void fragment() {
	vec2 uv_flow = UV + vec2(TIME * 0.10, TIME * 0.05);
	vec2 n1 = (fract(sin(vec2(dot(uv_flow, vec2(12.9898, 78.233)),
							  dot(uv_flow, vec2(45.164, 94.673)))) * 43758.5453) - 0.5) * 2.0;
	vec2 n2 = (fract(sin(vec2(dot(uv_flow * 2.0, vec2(12.9898, 78.233)),
							  dot(uv_flow * 2.0, vec2(45.164, 94.673)))) * 43758.5453) - 0.5) * 2.0;
	vec3 n = normalize(vec3(mix(n1.x, n2.x, 0.5), 1.0, mix(n1.y, n2.y, 0.5)));
	NORMAL = n;
	float fresnel = pow(1.0 - abs(dot(VIEW, NORMAL)), 2.0);
	ALBEDO = water_color + vec3(sin(TIME * 0.5) * 0.05 + 0.05) * 0.10;
	ALPHA = mix(base_transparency * 0.6, base_transparency, fresnel);
	ROUGHNESS = 0.30;
}
```
> Godot 4.6: use `source_color` (NOT the old `hint_color`) for the color uniform, else the shader won't compile.

#### (3) Apply shader in `_build_pond` / `_build_well`

File: `game/scenes/levels/floor1_prairie.gd`.

In `_build_pond` (L995-998), replace the `StandardMaterial3D` block:
```gdscript
	var water_mat: ShaderMaterial = ShaderMaterial.new()
	water_mat.shader = load("res://scenes/levels/water_toon.gdshader")
	water.material_override = water_mat
```
In `_build_well` (L978-981), same replacement. **Keep `COLOR_WATER` (L74)** as the shader's default `water_color` fallback per the perf "reserve material slot, don't hardcode in CSG" note — set it via `water_mat.set_shader_parameter("water_color", COLOR_WATER)` if you want the const to stay the source of truth.

> The dedicated central pool + stream (S5) will reuse this same `ShaderMaterial` on a real subdivided `MeshInstance3D` plane (≤400 tris total, ≤250 m², per perf §2). The CSG pond/well get it now so the demo reads "alive water" immediately.

#### (4) Firefly fauna — NEW, conforms to existing `AmbientFaunaSpawner` contract

File: `game/scenes/fauna/firefly.gd` — **plain Node3D, emits `despawned`** (matches butterfly/bird/rabbit + spawner):

```gdscript
extends Node3D

## Luciérnaga ambiental — drift lento + OmniLight3D pulsante. Decorativa (sin combat/loot).
## Conforme al contrato de AmbientFaunaSpawner: emite `despawned` al alejarse.
## Grupo "ambient". OmniLight: shadow OFF, range chico (perf red-line #1/#2).

signal despawned(fauna: Node)

@export var drift_speed: float = 0.8
@export var drift_radius: float = 3.0
@export var light_min_energy: float = 0.10
@export var light_max_energy: float = 0.40
@export var pulse_hz: float = 1.4
@export var despawn_distance: float = 50.0

var spawner_origin: Vector3 = Vector3.ZERO
var _time: float = 0.0
var _angle: float = 0.0

@onready var _light: OmniLight3D = $OmniLight3D


func _ready() -> void:
	spawner_origin = global_position
	add_to_group("ambient")
	if _light:
		_light.shadow_enabled = false   # mandatory (perf red-line #2)
		_light.omni_range = 4.0          # tiny range (perf §4)


func _process(delta: float) -> void:
	_time += delta
	_angle += (drift_speed * delta) / maxf(drift_radius, 0.01)
	global_position = spawner_origin + Vector3(
		cos(_angle) * drift_radius,
		sin(_time * 0.8) * 0.4,
		sin(_angle * 0.7) * drift_radius * 0.8)
	if _light:
		var pulse: float = sin(_time * pulse_hz * TAU) * 0.5 + 0.5
		_light.light_energy = lerp(light_min_energy, light_max_energy, pulse)
	if global_position.distance_to(spawner_origin) > despawn_distance:
		despawned.emit(self)
		queue_free()
```

File: `game/scenes/fauna/firefly.tscn`:
```
[gd_scene load_steps=2 format=3 uid="uid://ambient_firefly"]

[ext_resource type="Script" path="res://scenes/fauna/firefly.gd" id="1_firefly"]

[node name="Firefly" type="Node3D"]
script = ExtResource("1_firefly")

[node name="OmniLight3D" type="OmniLight3D" parent="."]
light_color = Color(0.8, 1.0, 0.6, 1)
light_energy = 0.2
omni_range = 4.0
shadow_enabled = false
```
> Optional swarm glow (perf §4): a separate `GPUParticles3D` additive billboard can render the dots; keep ONLY ≤4 of these firefly nodes as actual lights. For S1, **4 firefly lights total** is the cap (see §RISKS, CRYSTAL_LIGHTS_EVERY=3 already burns ~16-17 lights).

#### (5) Add `add_to_group("ambient")` to existing fauna (real fix)

`butterfly.gd`, `bird.gd`, `rabbit.gd` do **not** add themselves to the `ambient` group. In each `_ready()`, add:
```gdscript
	add_to_group("ambient")
```
(butterfly.gd: after line 28 `spawner_origin = global_position`.) No `collision_layer` change needed — these are plain `Node3D`, not bodies.

#### (6) Music playback wiring (the priority workstream)

Add a music player to `floor1_prairie.tscn` (or to a global AudioManager if one exists — check first; none referenced in floor1). Minimal, self-contained node:

File: `game/scenes/levels/components/music_player.gd` (NEW):
```gdscript
extends AudioStreamPlayer

## Reproductor de música de exploración Floor 1. Loop simple del track principal.
## Tracks folk orgánicos CC0/CC-BY (ver game/assets/audio/CREDITS.md).

@export var track: AudioStream = null   # asignar windswept.ogg/.mp3 en el inspector
@export var music_volume_db: float = -8.0

func _ready() -> void:
	bus = "Music" if AudioServer.get_bus_index("Music") != -1 else "Master"
	volume_db = music_volume_db
	if track:
		stream = track
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		elif stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		play()
```
Place as node `MusicPlayer` (type `AudioStreamPlayer`) under the floor root, assign `track = windswept`. Prefer `.ogg` for loop-clean (re-encode the MP3s to OGG on import, or set MP3 `loop` as above).

### S1-c · `floor1_prairie.tscn` PLACEMENT PLAN (node-by-node)

Coordinates from the world-architect layout. `MAP_CENTER = (0,0)`, +X east / -X west, +Z south / -Z north. Y set at runtime by `get_terrain_height(x,z)` unless noted. **Single-writer rule applies — see §RISKS.** Most water/cave/hill landmarks are S5; S1 places only the fauna spawners + music + (shader is code, not a node). Listed here is the **full target plan across sprints** so the tscn is edited coherently; the **[S1]** tag marks what Sprint 1 adds.

| Node name | Type | Parent | Position / transform | Collision | Habitat zone | Sprint |
|---|---|---|---|---|---|---|
| `MusicPlayer` | AudioStreamPlayer | (root) | n/a (2D bus) | no | — | **[S1]** |
| `FireflySpawner_Pool` | AmbientFaunaSpawner | (root) | (-2, 0, -8), `spawn_radius=14`, `count=4`, `creature_scene=firefly.tscn` | no | water_edge | **[S1]** |
| `ButterflySpawner_Grove` | AmbientFaunaSpawner | (root) | (0, 0, 0), `spawn_radius=40`, `count=10`, `creature_scene=butterfly.tscn` | no | open_field | **[S1]** (tune existing) |
| `BirdSpawner_Aerial` | AmbientFaunaSpawner | (root) | (0, 5, -20), `spawn_radius=60`, `count=6`, `creature_scene=bird.tscn`, `spawn_height=4` | no | aerial | **[S1]** (tune existing) |
| `PoolWater` | MeshInstance3D (subdiv plane + `water_toon` ShaderMaterial) | `Water` | (-2, ~0, -8), r≈7m disc | no | water_edge | S5 (CSG pond gets shader in **[S1]**) |
| `StreamWater` | MeshInstance3D (ribbon plane + same ShaderMaterial) | `Water` | source (-13,-37)→pool (-2,-8), ~25m, width 0.6→1.2m | no | water_edge | S5 |
| `RockOutcrop` | StaticBody3D + MeshInstance3D | `Landmarks` | (-15, ~0, -40), footprint ~12×8m, h~5m | **yes (layer 1)** | cave | S5 |
| `CrackCaveMouth` | MeshInstance3D (recess) | `RockOutcrop` | faces pool, ~3m deep recess | no | cave | S5 |
| `SourceCrack` | (emitter point / particle origin) | `RockOutcrop` | (-13, base, -37) | no | water_edge | S5 |
| `SoftHill` (terrain) | (heightmap edit) | TerrainMesh | crest (+45,+35), +6m over ~30m run | inherits terrain | open_field (dry) | S5 |
| `Juncos_PoolRing` | MultiMeshInstance3D | `VegetationScatter` | halo around pool r≈8-18m, ~120 instances | no | water_edge | S3 |
| `GroundFlora_MMI_chunk_*` | MultiMeshInstance3D ×6-9 | `VegetationScatter` | ~40×40m chunks, `visibility_range_end=70` | no | open_field | S3 |
| `TowerEdgeShell` | MeshInstance3D (baked ring, ≤3k tris) | (root) | radius ~250m, separate from collision border | no (visual only) | — | S2 |
| `BorderWall%d` (existing CSG ×64) | CSGBox3D | (root) | unchanged geometry; **re-skin material** to masonry upper band | yes (layer 1) | — | S2 (re-skin) |
| `MountainCrown` | MeshInstance3D OR sky-baked | (root) / Sky | NW sector only (~310°-30°), non-traversable | no | — | S2 |
| `BossBeacon` | OmniLight3D (#90FF90, energy 0.3, range 20) | `BossClearing` | (-130, ~2, 0) WEST | no | boss_arena | S5 |
| `BossBeaconHum` | AudioStreamPlayer3D | `BossClearing` | (-130, ~2, 0), low hum loop | no | boss_arena | S5 |

**S1 tscn edits (minimal):** add `MusicPlayer`; add `FireflySpawner_Pool`; verify/tune the 3 existing fauna spawners' `count`/`radius`/`creature_scene` (butterfly→grove, bird→aerial; add a rabbit spawner near grove if desired). Everything else in the table is later-sprint and listed for coherence only.

> Perf guardrails honored in placement: fauna spawners scoped to the **playable clearing**, not the 250m map; firefly `count=4` (light cap); butterflies ≤ a few hundred particles equivalent; no MMI map-wide (chunked in S3).

### S1-d · GIT COMMIT LIST (CORRECTED — see §0.1)

The IMPL SPEC's list was wrong. The **actually uncommitted** items right now:

```
?? game/assets/art/ui/            (UI theme .tres, fonts Cinzel/EBGaramond, foozle PNGs)
?? game/docs/_DESIGN_INDEX.md
?? game/docs/_floor1_integral_plan.md
?? game/docs/_inserccion_integral.md
?? game/docs/ui/
 M game/scenes/levels/floor1_prairie.gd
 M game/scenes/levels/floor1_prairie.tscn
 M game/scenes/ui/character_select.tscn
 M game/scenes/ui/class_selector.tscn
 M game/scenes/ui/main_menu.tscn
 M game/scenes/ui/pause_menu.tscn
```

Sprint-1 NEW files to add once created: `water_toon.gdshader`, `firefly.gd/.tscn`, `music_player.gd`, downloaded music under `assets/audio/music/`, `assets/audio/CREDITS.md`.

Suggested S1 commits (single-writer; commit only when Joan asks):
```powershell
# UI assets that were already on disk but untracked (pre-existing, unrelated to S1 code)
git add game/assets/art/ui/ ; git commit -m "assets(ui): add UI theme + Cinzel/EBGaramond fonts + foozle (CC0/OFL)"

# S1 music + credits (verify CC-BY attribution file present)
git add game/assets/audio/ ; git commit -m "assets(audio): floor1 organic folk music pack (CC0 + CC-BY KevinMacLeod)"

# S1 code: water shader + fauna + music wiring + habitat field
git add game/scenes/levels/water_toon.gdshader game/scenes/fauna/firefly.gd game/scenes/fauna/firefly.tscn `
        game/scenes/levels/components/music_player.gd game/scenes/enemy/base_enemy.gd `
        game/scenes/fauna/butterfly.gd game/scenes/fauna/bird.gd game/scenes/fauna/rabbit.gd `
        game/scenes/levels/floor1_prairie.gd game/scenes/levels/floor1_prairie.tscn
git commit -m "feat(floor1): toon water shader + firefly fauna + music + habitat_type hook"
```
> The `M` UI scene files + docs are pre-existing drift unrelated to S1 — commit or stash them separately so the S1 diff stays reviewable (<400 lines).

### S1-e · INTEGRATION CHECKLIST (QA)

- [ ] `habitat_type` export added to `base_enemy.gd` after L23
- [ ] `water_toon.gdshader` created, uses `source_color` (compiles in 4.6)
- [ ] Shader applied in `_build_pond` (L995) + `_build_well` (L978)
- [ ] `firefly.gd/.tscn` created, emits `despawned`, OmniLight `shadow_enabled=false`, `omni_range≈4`
- [ ] `add_to_group("ambient")` added to butterfly/bird/rabbit/firefly `_ready()`
- [ ] `FireflySpawner_Pool` placed, `count=4` (light cap), `creature_scene=firefly.tscn`
- [ ] Music: 6 tracks downloaded to `assets/audio/music/`, `CREDITS.md` written, `MusicPlayer` plays on load, loops
- [ ] Floor loads with **zero errors**; firefly lights pulse; water animates; butterflies wander; music audible
- [ ] **Parse-check `floor1_prairie.tscn` after every tscn edit** (open in editor / `godot --check-only` headless)
- [ ] Active dynamic OmniLights ≤ 20 (verify with Debugger→Monitors after fireflies spawn)
- [ ] 10-min demo capture shows living water + fauna + folk score (TIER 1)

---

## 3. RISKS / DO-NOT-EXCEED

### Perf red-lines (mid-range GTX 1060 / RX 580, Forward+, 6-player co-op)
1. **Total active shadowless OmniLights ≤ 20.** Baseline is ALREADY ~16-17 (`CRYSTAL_LIGHTS_EVERY=3` → ~11-12 cluster + 3 monarch + 1 ambient + 1 fire). **→ Firefly lights capped at ≤4 in S1** (not 8). If you add crystal lights, subtract from fireflies. Render the rest of any swarm as additive GPUParticles billboards (no light).
2. **Zero shadow-casting point/spot lights.** Every OmniLight (fireflies, beacon, crystals) stays `shadow_enabled=false`. Only a directional/sun may shadow.
3. **Grass/clover/juncos: 1 mesh = 1 MMI = 1 draw call.** ≤13k visible instances total, hard-cull 70m, chunked into ≤40m tiles with `visibility_range_begin/end` + `visibility_range_fade_mode=SELF`. **No per-blade Node3D, ever.** (S3.)
4. **No planar reflections / SubViewport mirrors / SSR on water.** Fresnel + cheap cubemap fake only. Water shader is a single transparent layer with `depth_draw_opaque`.
5. **Transparent overdraw: water ≤ ~250 m², single layer.** No stacked foam/caustic planes. Pool ≤8m disc, stream ≤2×25m ribbon, ≤400 tris combined.
6. **Distant mountains + tower silhouette ≤ 5,000 tris combined**, `cast_shadow=OFF`. Prefer baking mountains into the sky (≈0 geometry). (S2.)
7. **GPUParticles fauna: ≤3 systems, ≤768 particles total, `fixed_fps=30`, `interpolate=true`.** Spawn AABB scoped to the clearing, not the 250m map.
8. **Total camera-facing draw calls ≤ ~600.** The existing ~500-700 per-instance GLTF trees/rocks already threaten this — grass MUST be MultiMesh (S3) and trees should migrate to MMI/chunks (S6) or this is breached before fauna is added.
9. **Anti-pattern flagged (S2/perf task):** the `omni_range=350` ambient OmniLight (L463) clusters nearly every object. Replace with `DirectionalLight3D` (shadows off) or `WorldEnvironment.ambient_light` to free light headroom — recommended before adding fireflies if you want >4.

### tscn-edit safety
- **Single-writer rule:** only ONE process/agent edits `floor1_prairie.tscn` at a time. Concurrent edits corrupt the scene (load_steps / ext_resource id collisions).
- **Parse-check after every tscn edit** (open in Godot or `godot --headless --check-only`). A broken tscn fails silently at load.
- **New ext_resource ids** (firefly.tscn, music) must not collide with existing ids (current max referenced is ~57 `load_steps`). Let the editor assign ids — don't hand-author duplicate ids.
- **Border/spawn ordering:** `_build_organic_border()` must complete BEFORE enemy/fauna spawn, or entities clip through the boundary (map-audit risk). Verify call order in `_ready`.
- **POI validation:** guard `pois.size() > 0` before terrain-height lookups; a malformed/empty POI array fails silently on garbage Vector3.

---

## 4. RESOLVED (Joan, 2026-06-06)

1. **[LORE — RESOLVED] Tower-edge + partial-mountain composition → option A "Breach in the wall" is CANON.**
   The NW tower wall is broken/ruined; through the gap you glimpse distant mountains across an unseeable gulf. NW sector only (~310°-30°), NOT a 360° ring. Story: "someone built the limit" + foreshadows the descent; the western boss approach feels ominous.
   Implementation (S2): mountains **baked into the sky** (~0 geometry cost) preferred; real ≤2k-tri fins only if parallax is wanted. Cost: one wall-breach segment in the NW border + distant baked/billboard mountains.
   - ~~B "backdrop above low rampart"~~ rejected (reads as open-world, undercuts "inside a tower").
   - ~~C "cliff across a chasm"~~ rejected (over-promises verticality, competes with crack-cave as the "down" signal).
2. **[LORE — assumed CANON unless Joan objects] Boss gate = WEST.** Mushroom King clearing due WEST (-X) of the pool, green beacon leaking west, adjacent to the NW mountain-breach so "the edge gets strange" near the boss. (world-coherence §4.1.)

---

## 5. Provenance
Synthesized from: map-audit (terrain/water/scatter/habitat-gap), music-sources (6 picks), asset-sources (reeds/butterfly/water-normal/mountains), world-architect layout (regions, water, boundary, mountain interpretations, boss beacon), godot-perf budget (light/draw/MMI red-lines), impl-spec (code snippets) — all reconciled against the live repo on 2026-06-06. Corrections in §0 override the raw inputs where they conflicted with the code.
