# Floor 1 Prairie — Environment Rework Spec

## Resolutions (Joan, 2026-07-20 — answers the 3 open questions below)

1. **Terrain**: NOT Option A/C (a separate central mound). Joan clarified he means the
   EXISTING border ring (`BOWL_RISE_BASE`+`BOWL_LIP_RISE_BASE`, §1) itself — reshape the
   WHOLE ring into an irregular, non-climbable MOUNTAIN SLOPE (not a uniform smooth
   bowl-wall). This is a stronger version of Option B (azimuthal variation + rugged
   silhouette across the entire border), not a point landmark. **Map diameter +50%**
   is confirmed wanted but explicitly DEFERRED to a separate future pass (affects POI
   spacing/spawns/performance, deserves its own scoping).
2. **Flora second axis**: humidity + SHADE, confirmed (matches existing canon).
3. **Ceiling**: FULL architectural merge (all 4 systems → one owner), confirmed. PLUS a
   new creative direction that supersedes the DanMachi single-flat-layer reference:
   Joan wants the crystal ceiling TALLER, with crystals at VARYING heights in a
   lightning-bolt/branching-like distribution (not one mostly-uniform height layer like
   DanMachi 18F) — specifically so the light source reads as ambiguous/deep, not
   "obviously one flat ceiling," making the floor feel taller/more mysterious. **No
   reference image exists for this specific "lightning-branch crystal, varied height"
   idea** — gap noted, building from Joan's verbal description per reference-first
   protocol's fallback rule (imagine from corpus, record the gap).

---

Status: **SPEC ONLY — no code changes applied.** Written 2026-07-18 following Joan's
departure-backlog instruction (engram `dungeon-party/backlog-2026-07-18`): apply the
same reference-first workflow used on the village (refs → synthesis → spec) to the
floor-1 prairie environment itself. Scope: terrain, rivers, flora ecology, ceiling.
Per this repo's "Develop-before-implement" convention (`CLAUDE.md`), this doc proposes
interpretations and asks the open questions that block implementation — it does not
implement.

All code facts below were verified directly against `game/scenes/levels/floor1_prairie.gd`
(3459 lines) and `game/scenes/levels/components/crystal_ceiling.gd` (128 lines), not
guessed from prior docs (several existing docs — see §3 and §4 — describe an
aspirational or stale version of the code; this spec calls those discrepancies out).

---

## 1. Terrain — from "hole toward the center" to a landscape with verticality

### Current state (verified, `_compute_height_at`, lines 618-723)

1. Noise base: `_terrain_noise` → `TERRAIN_MAX_HEIGHT = 9.0`.
2. **Flatten center**: inside `flat_radius = FLAT_RADIUS_BASE(50.0) * _scale`, height is
   force-lerped to a **completely flat pancake** via `smoothstep`.
3. Broad swell (±3.5m) — also zeroed inside `flat_radius`.
4. **The bowl rise** (lines 657-690) — the mechanism the PO reads as a crater:
   `BOWL_RISE_BASE = 12.0` + `BOWL_LIP_RISE_BASE = 4.0` → **+16m total rise** from
   `flat_radius` out to `BORDER_RADIUS_BASE` (~250m), via smoothstep, uniform around
   the full ring. The code's own comment names this intentionally: *"edge is high /
   center is low bowl for cavern P1."*
5. Outcrop bumps, capped at `OUTCROP_MAX_ADD = 2.5m` — texture, not relief.
6. Stream channel carve, up to `STREAM_DEPTH = 0.8m`.

**Net shape: flat disc → smooth uniform bowl wall rising 16m at the border.** There is
no positive landmark anywhere in the height field. The 6 `_build_landmark_pillars()`
(lines 1394-1415) are purely decorative CSG cylinders at a fixed height matching the
cave ceiling (`CEILING_HEIGHT = 45.0`) — they don't affect terrain relief, and their
placement (random radius 100-200m·`_scale`) is independent of any landmark concept.

This confirms the PO's read is objectively correct, not a misreading: the only
large-scale vertical feature in the geometry is a uniform depression. A real landscape
reads center-out via peaks/ridges breaking a flat plane, not via a uniform rim.

### Proposed alternatives

**Option A — Add a landmark mound/mountain (Joan's suggestion).**
Add one (or two) positive terrain landmarks that RISE from mid-ring ground, giving the
floor a focal point and counteracting the "everything sinks toward the middle" read.
- New constants: `LANDMARK_COUNT = 1`, `LANDMARK_RADIUS_BASE` (~40-60m),
  `LANDMARK_HEIGHT_BASE` (~20-25m), `LANDMARK_MIN_DIST`/`LANDMARK_MAX_DIST` (placed
  between `flat_radius` and `BORDER_RADIUS_BASE`, e.g. 90-160m·`_scale` — inside the
  playable ring, not on the far wall).
- New function `_landmark_height_at(x, z) -> float`: additive dome/cone falloff
  (smoothstep, same style as the existing bowl code) around 1-2 deterministic
  positions picked once from `world_seed` (mirrors how `_stream_polylines` are
  deterministic, not `_rng`-drawn).
- Call site: add this term into `_compute_height_at` between the bowl-rise (step 4)
  and outcrop (step 5) contributions.
- Dressing: the existing 6 decorative pillars and `_build_crystal_field()` shards
  currently float independently of any relief — propose **anchoring 2-3 of the 6
  landmark pillars to crown the new mound** instead of scattering all 6 randomly,
  unifying "landmark" as one concept (currently it's two unconnected systems: fake
  height via pillars, real height via nothing). This also gives the DanMachi-style
  crystal accents in §4 a natural place to sit ("on formations, not floating").
- Cost: O(1) extra height-field evaluation per query — negligible against the existing
  `TERRAIN_RESOLUTION = 96` precompute.
- Risk: must not overlap `pois` placement or block spawn/pathing — clamp
  `LANDMARK_MIN_DIST` comfortably outside `flat_radius` and check against existing POI
  positions before finalizing exact placement (needs the POI list at generation time,
  which the terrain pass already has access to via `pois`).

**Option B — Soften the bowl only (tuning, lower risk, weaker payoff).**
Reduce `BOWL_RISE_BASE`/`BOWL_LIP_RISE_BASE`, and vary the rise **azimuthally** via a
new low-frequency angular noise term so the rim isn't a perfectly uniform ring (a
perfect ring reads as an artificial crater lip even at lower height — breaking its
uniformity alone helps). Also soften the `flat_radius` cutoff from a hard smoothstep-to-
zero into a gentler blend so the center doesn't read as an artificial pancake next to a
noisy exterior. This alone does **not** add verticality — it only makes the existing
bowl less severe/uniform. Good as a companion tuning pass, not a replacement for A.

**Option C — Hybrid (recommended).**
Keep the flat spawn guarantee (gameplay needs a flat combat area) but: (i) apply
Option B's azimuthal variation to the rim so it stops reading as a perfect crater lip,
AND (ii) add Option A's 1 landmark mound for verticality and a focal point. This
directly answers Joan's brief ("height that rises somewhere instead of sinking; maybe
a mountain landmark") while keeping the parts of the current system that already work
(flat spawn, stream carving, outcrop texture).

### Reference validation (`game/docs/art/_references/prairie_terrain/_synthesis.md`, NEW
this session — 5 images: DanMachi 18F central-tree screenshot, 2 Made in Abyss
screenshots, 2 real karst-cave photos, cross-validated)

- `danmachi_18f_central_tree.png` is the direct composition fix reference: a single
  giant tree stands on a raised mound at the EXACT CENTER of the floor, ringed by a low
  palisade, with surrounding terrain staying lower — literally the inverse of our
  current shape (which rises toward the border instead). This validates Option A/C's
  direction: the landmark should rise **inward, near/just past `flat_radius`**, not be
  scattered at the border.
- `yana_caves_alien.png` (real karst tsingy formation) independently confirms a massive
  single vertical rock landmark dominating a landscape is a real geological feature —
  and importantly, its scale (peaks clearly taller than a tree line, several building-
  heights) roughly matches our EXISTING `BOWL_RISE_BASE + BOWL_LIP_RISE_BASE` magnitude
  (12-16m). **The synthesis's conclusion: the problem is not the amount of relief we
  already build, it's the direction/placement** — the fix is centering the rise near
  the spawn disc instead of ramping it uniformly to the border.
- `gadime_cave_stalagmite.jpg` (real stalagmite/flowstone column) is a surface-texture
  reference for when the landmark gets modeled (vertical fluted grooves that catch
  light) — not a composition reference.
- `abyss_3rd_layer.webp`'s vertigo shot sells scale via small reference objects (birds)
  against the vastness, not raw height alone — suggests dressing the landmark's base
  with small-scale props (rocks, crystal clusters, low vegetation) so its height reads
  clearly against the player, the same trick `_build_crystal_field` already uses for
  point accents.
- Synthesis's direct code recommendation: **`_build_landmark_pillars()` is the natural
  hook** to plant either the single-dominant-mass version (Made in Abyss / karst style)
  or the mound+dominant-object version (DanMachi tree style) — anchoring 2-3 of the 6
  existing pillars there instead of scattering all 6 randomly (matches this spec's own
  proposal above, arrived at independently by the reference synthesis too).

### Open question
Where exactly should the landmark sit relative to the gate/entrance and existing POIs
(pond/boss/giant_tree/entrance/camp/ruins/altar/well)? This spec can propose the
*mechanism* but not a specific seed-independent position without risking a POI/pathing
collision — needs either Joan's steer on "which direction should the mountain loom
in" or a placement pass that queries `pois` at generation time and rejects collisions
(gate/POI clearance would follow the same pattern as `find_flat_spot()`'s already-solved
clearance problem in `motor-blender/recetas/village_gen.py`, adapted to GDScript).

---

## 2. Rivers — rocks in the channel, fauna at the banks

### Current state (verified)

- `_build_stream_ribbons()` (lines 1926-2076): builds a flat water-ribbon mesh for
  streams 0/1 (`water_toon.gdshader`, molten-gold tint, `base_transparency = 0.55`) and
  a **dry watercourse with pebble scatter** for stream 2 only (`is_dry` branch).
  **No rocks exist inside the two WET channels** — only the dry bed gets pebbles.
- `_scatter_stream_banks()` (lines 1753-1918): already places pebbles (40%)/small rocks
  with colliders (30%)/reeds (20%)/wetland bush tufts (10%) in a band
  (`BAND_INNER = STREAM_HALF_WIDTH = 4.0` to `BAND_OUTER = 8.0`) around **all** stream
  polylines. **No fauna is placed here** — fauna is handled entirely separately by
  `ambient_fauna_spawner.gd` via a habitat/POI-niche table, not tied to river geometry
  at all.

### Proposed changes

1. **In-channel rocks** — new function `_scatter_channel_rocks()` (sibling to
   `_build_stream_ribbons()`, called right after it) that places partially-submerged
   boulder props along the centerline of the two WET streams (reuse
   `prop_rock_small_01.glb` or a slightly larger variant), y-positioned a touch below
   the ribbon surface (`terrain_height + STREAM_DEPTH*0.4`, matching the ribbon's own Y
   from line 1957) so it reads as sitting IN the water, not floating on it. Scatter with
   small perpendicular jitter (within `STREAM_HALF_WIDTH*0.5`) so rocks don't form a
   perfect row down the centerline — density should be LOW (a handful per stream
   segment) so it reads as natural debris, not a dam.
2. **Riverbank fauna** — rather than writing a new bespoke spawn pass, register the
   stream-bank band (`BAND_INNER`/`BAND_OUTER`, already computed in
   `_scatter_stream_banks()`) as a habitat zone that `ambient_fauna_spawner.gd`'s
   existing habitat/POI-niche table can query (e.g. a `"riverbank"` habitat_type
   alongside whatever it already recognizes for ponds/forest/etc.) — this reuses the
   spawner's existing logic instead of duplicating it (repo's own Ponytail rule:
   "¿ya existe acá?" before writing new code). Concretely: emit the stream polylines
   (or a few sampled points along them) into whatever registration mechanism
   `ambient_fauna_spawner.gd` already uses for other habitats, tagged `"riverbank"`.
3. **Canon update**: `game/docs/art/_world_coherence.md` §2 (hydrology rules H1-H5)
   already establishes the "humidity halo" concept for rivers/ponds — extending it
   with an explicit "riverbank fauna niche" rule is a natural continuation of existing
   canon rather than a new system, and should be added there as a canon addendum once
   this spec is approved.

### Reference validation (`game/docs/art/_references/prairie_rivers/_synthesis.md`, NEW
this session — 5 images: 3 real river/creek photos, 1 real riverbank-heron photo, 1
Zelda wiki screenshot as a style-gapped composition reference, cross-validated)

- `river_boulders_rapids.jpg` (real mountain stream, verified by direct read): multiple
  ~0.5-1m granite boulders sit IN the middle of the current, water visibly splitting and
  foaming around them, some create small stepped drops — direct confirmation rocks
  belong inside the flow, not just the banks.
- `frog_on_rocks_stream.jpg` cross-validates: several rocks break the surface across a
  shallow channel, with a moss/shade split (darker, wetter moss on the shaded/wet-
  contact side, lighter/drier tone on the sun side) — the synthesis recommends this as
  a concrete material detail (a vertical color gradient or two rock-material variants
  by contact-with-water), not a flat rock color. Honest gap noted by the sub-agent: the
  named "frog" in that photo's title wasn't actually visible in the downloaded crop —
  its contribution is limited to rock/bank vegetation, not confirmed fauna.
- `heron_riverbank_reeds.jpg` (real riverbank photo): a heron stands INSIDE a reed bed
  right at the waterline (reeds rooted in the shallow water itself, not set back on dry
  land) — validates placing a wading-bird-type fauna prop specifically inside reed
  clusters at the immediate waterline, not scattered generically across the whole bank
  band.
- `rogue_river_boulders.jpg` — secondary/composition-only: here cliff/boulder walls
  form the channel itself rather than mid-stream rocks; useful only as a "waterfall
  into a calm rock-walled pool" composition idea, less relevant to the channel-rock
  scatter than the two images above.
- `zelda_zoras_river_rapids.webp` (Zelda: Twilight Princess, style-gap explicitly
  noted — stylized N64/GameCube 3D vs. our toon-shaded low-poly) is an exact-scenario
  composition precedent (a river running through a rock cavern/tunnel) decorated with
  light-orbs hung over the water — flagged by the synthesis as an OPTIONAL, low-
  priority bonus idea (light accents over water tying into the crystal-ceiling rework
  in §4), not a rock/vegetation fix.
- Synthesis's direct code recommendation: extend the in-channel rock pass to the two
  WET streams (today only the dry streambed, index 2, gets pebbles), position rocks
  poking a few cm ABOVE the ribbon's own water-surface Y
  (`get_terrain_height + STREAM_DEPTH * 0.40`, from `_build_stream_ribbons()` line
  1957) rather than floating above or fully submerged, and add the wet/dry material
  split.

### Open questions
1. Does the in-channel rock density risk snagging player movement/pathing across
   streams (are streams currently crossable at all points, or only at fixed
   fords/bridges)? If crossability matters, channel-rock placement needs a clearance
   rule (skip rocks within N meters of any designated crossing point) — this spec
   doesn't yet know whether floor1 has authored crossing points or expects free wading;
   needs a quick check against the stream-carve code's playability assumptions before
   implementation.
2. Is the Zelda-style "light accents hanging over the water" idea in scope for this
   pass, or should it be deferred entirely to the crystal-ceiling rework (§4) so the
   two specs don't get entangled? Flagged optional/low-priority either way.

---

## 3. Flora ecology — humidity/temperature-driven generation

### Current state (verified) — three layers of PRIOR, disconnected work found

1. **`_generate_vegetation()`** (lines 2585-2661, the actual runtime code) is
   POI-anchored `match` branching (pond/boss/giant_tree/entrance/camp/ruins/
   altar/well get hand-tuned scatter clusters) plus flat-percentage connective-tissue
   scatter (`TREE_COUNT*0.7` etc.) with **zero reference to distance-to-water or any
   temperature value**. The only conditional placements are keyed to *local structural
   facts* — tree position (`_scatter_understory_mushrooms`, shade-proxy) and outcrop
   noise threshold (`_scatter_outcrop_rocks`) — not a humidity/temperature field.
2. **`game/docs/procedural_ecology.md`** (v1.0, 686 lines) is a full, **never
   implemented**, generic per-cell humidity/temperature/light/elevation/nutrient grid
   design (2×2m cells, propagation formulas, a 19-species lookup table). Grepping
   `floor1_prairie.gd` for its documented `@export` identifiers (`heat_attenuation_air`,
   `humidity_falloff_flat`, `vegetation_density_multiplier`, etc.) confirms **none of
   them exist in code** — this is aspirational, not current state.
3. **`game/docs/art/_world_coherence.md`** §3 + **`game/docs/lore/_coherence_target_sheet.md`**
   together describe a **one-time manual audit** (Y/Y*/NW/N verdicts per asset) that
   was hand-converted into the `# FIX #1`-`#5` / `# BREAK #1`-`#4` comments scattered
   through `_generate_vegetation()` (e.g. FIX #1 removed full-sun flowers from a
   cavern floor; FIX #2 moved a bracket fungus onto dead-tree bases because it needs
   wood substrate). This is real, already-applied ecological reasoning — but it's
   frozen into hardcoded per-asset placement, not a queryable rule a new asset could
   be checked against automatically.

### Proposed: a LIGHTWEIGHT proxy system (not the full `procedural_ecology.md` grid)

The task asks for "simple rules," and the full per-cell propagation grid in
`procedural_ecology.md` is a much bigger system than this floor needs (it's a generic
multi-floor design, not floor-1-specific). Proposal:

1. **Humidity proxy** — `_humidity_at(x, z) -> float` (0..1): distance-based falloff
   from the nearest of (a) `_stream_polylines` (already exist) and (b) pond-type POI
   centers, using the halo-radius idea already established in `_world_coherence.md`
   §2 ("humidity halo = 1.5-3x water body radius") — reuses existing data, no new
   grid needed.
2. **Second axis — recommend SHADE, not temperature** (see open question below):
   `_shade_at(x, z) -> float` derived from proximity to `_tree_positions` (already
   recorded) — generalizes the existing understory-mushroom proxy into a reusable
   query instead of a one-off.
3. **Data-driven niche table**: new dict `FLORA_NICHES` mapping each existing
   `PackedScene` pool entry (`POOL_TREES`, `POOL_BUSHES`, `POOL_GROUND`,
   `SCENE_DEAD_TREE`, `SCENE_LAETIPORUS`, `SCENE_MUSHROOM_COMMON`, etc.) to
   `{humidity: [min, max], shade: [min, max]}`, populated directly from the verdicts
   already recorded in `_coherence_target_sheet.md` — this converts the existing
   one-time manual audit into reusable DATA instead of scattered code comments,
   satisfying "design simple rules" without building the full grid engine.
4. **`_pick_flora_for_point(x, z)`**: queries `FLORA_NICHES` against
   `_humidity_at`/`_shade_at` at a candidate point, returns a weighted candidate list.
   The connective-tissue scatter in `_generate_vegetation()` (the flat-percentage
   part, NOT the hand-authored POI branches) switches to call this instead of picking
   from a flat pool percentage.
5. **Keep POI-anchored branches as an authored override layer** — curated set-pieces
   (pond ring, boss arena, giant tree grove) stay hand-placed; only the generic
   background scatter becomes humidity/shade-driven. This limits the blast radius of
   the change and keeps Joan's hand-tuned "storytelling" placements intact.

### Open question (important — affects the whole design)
**Does "temperature" make physical/narrative sense for an indoor crystal cavern
floor at all?** The existing manual-audit docs (`_world_coherence.md` §3) already use
LIGHT/SHADE as the practical second axis for mushrooms etc., not temperature — a cave
doesn't have meaningfully varying air temperature the way an outdoor biome does. This
spec defaults to **humidity + shade** rather than **humidity + temperature** for that
reason, but this is a real interpretation choice the task brief didn't fully resolve
("driven by humidity + temperature") — needs Joan's confirmation before the niche
table gets built, since it changes what the second axis of `FLORA_NICHES` even means
(and whether it should instead be reserved for later outdoor floors where temperature
is meaningful).

---

## 4. Ceiling — reconcile the two systems, redesign toward DanMachi crystal-sky

### Current state (verified) — confirmed FOUR independently-authored systems layered

1. **`CrystalCeiling` component** (`crystal_ceiling.gd`, instanced in
   `floor1_prairie.tscn`, `bioma="pradera"`, `size=(120,120)`, `height=25.0`,
   `show_ceiling_plane=false`) — owns a tinted `PlaneMesh` (hidden) + `CeilingLight`
   (cool DirectionalLight3D, no shadow) + `FocusLight` (warm OmniLight3D). Its own
   header comment already documents WHY the plane is hidden: it read as "a white
   square cloud" floating mid-map, because...
2. **...`_build_ceiling()`** (floor1_prairie.gd, lines 1037-1052) builds the ACTUAL
   visible cave roof — a big flat `CSGBox3D` at y=45 with its own hardcoded emissive
   stone material, entirely unrelated to `CrystalCeiling`'s tint/bioma system.
3. **`_build_key_light()`** (lines 234-242) — a THIRD, independent warm
   `DirectionalLight3D` with hard shadows (`shadow_bias = 0.04`), separate from both of
   `CrystalCeiling`'s own lights.
4. **`_build_crystal_field()`** (lines 1054-1212) — the actual DanMachi-style "techo de
   cristal" crystal shards, with their own `SpotLight3D`/`OmniLight3D` instances,
   structurally disconnected from `CrystalCeiling.gd`'s light-and-tint API even though
   it's visually the intended realization of that component's concept.

**None of this is dead code** — all four execute on every `generate()` call. A prior
session patched the symptom (hide `CrystalCeiling`'s plane) without merging the
duplicate roof geometry or light rigs — this is the reconciliation problem named in
the task brief.

### Reference validation (`game/docs/art/_references/crystal_ceiling/_synthesis.md`,
already populated, 5 real DanMachi screenshots, cross-validated against 3 text
sources — no new reference hunting needed here, only architecture work)

- DanMachi's 18F "crystal sky" reads as diffuse, omnidirectional, **soft-shadow**
  lighting — directly contradicts our current hard-shadowed `CavernKeyLight`.
- Crystals appear as a **two-tier hierarchy**: one bright core (reads as "sun") +
  scattered smaller crystals (reads as "sky"), and crystal accents sit **on rock
  formations**, never floating.
- A day/night tint cycle is confirmed in the source material and already logged as a
  TODO in `crystal_ceiling.md` §10 (not yet built).

### Proposed reconciliation

1. **Single ceiling-geometry owner.** Move `_build_ceiling()`'s CSGBox3D roof logic
   INTO `crystal_ceiling.gd` behind a new `@export var build_rock_roof: bool = true`
   (a `_build_rock_roof()` method mirroring floor1's current code, using the
   component's own `size`/`height` exports instead of `floor1_prairie.gd`'s local
   `proc_bounds`/`CEILING_HEIGHT` constants). Delete `_build_ceiling()` from
   `floor1_prairie.gd`; `active_layers.ceiling` gates the component call instead.
   Result: ONE object owns the visible roof mesh, tint, and both ambient lights.
2. **Single ceiling-lighting owner.** Fold `_build_key_light()`'s function into
   `CrystalCeiling` as well, OR (lower-risk) keep it in floor1_prairie.gd but disable
   its hard shadow (`shadow_enabled = false`, or drop energy substantially) per the
   reference's "soft, near-absent shadow" finding — this is the smaller, safer change
   if a full light-ownership merge is deferred (see open question below).
3. **Formalize the two-tier crystal hierarchy.** In `_build_crystal_field()`,
   designate one cluster as CORE (brightest, position anchors `FocusLight`) and the
   rest as SKY accents (cooler, anchors `CeilingLight`'s general fill tone) — ties the
   DanMachi reference's explicit two-tier structure directly to code structure instead
   of three independently-placed lights that happen to look plausible together.
4. **Anchor crystal accents to formations.** Attach small emissive crystal props onto
   the terrain landmark (§1) and the rock roof itself, rather than scattering them at
   arbitrary floating positions — direct callout from the reference's "Qué capturar"
   #3.
5. **Day/night tint cycle** — already a documented TODO; this spec does not expand
   scope to build it now (see open question).

### Open question (biggest scope/priority call in this whole spec)
**Is a ceiling-system merge (touching `floor1_prairie.gd`, `crystal_ceiling.gd`, AND
the `.tscn`) worth doing now, or should it wait post-alpha?** This repo's own
scope-reset filter (`CLAUDE.md`, 2026-05-18) asks of every change: *"¿Esto acerca o
aleja de los 5 mapas publicables?"* A full architectural merge is the riskiest, most
invasive item in this whole spec (three files, runtime lighting behavior change) for
a payoff that's visual polish, not new mechanics. The SAFE, LOW-RISK subset (soften
the hard shadow per item 2's fallback, anchor crystal accents per item 4) could ship
without the full merge. Recommend scoping this to Joan explicitly before touching
code — this spec defaults to describing the FULL reconciliation as the "correct"
end-state, but the incremental subset may be the right actual next step for MVP scope.

---

## Summary — top open questions for Joan

1. **Terrain landmark placement**: where should the new mound sit relative to the
   gate/POIs, and is 1 landmark enough or does he want 2 for a more dramatic
   silhouette? (§1)
2. **Flora's second axis**: humidity + SHADE (this spec's recommendation, matches
   existing canon) or does he specifically want a temperature concept preserved for
   consistency with future outdoor floors, even if it's mostly inert on floor 1? (§3)
3. **Ceiling merge scope**: full 3-file architectural reconciliation now, or the
   smaller safe subset (soft shadows + anchor crystal accents) now with the full merge
   deferred post-alpha? (§4)

Secondary/smaller open questions are inline in each section (river crossability vs.
channel-rock placement in §2; exact landmark radius/height tuning in §1).

---

## References used

- `game/docs/art/_references/crystal_ceiling/_synthesis.md` — already populated
  (5 DanMachi screenshots), reused directly for §4, no new hunting needed.
- `game/docs/art/_references/prairie_terrain/_synthesis.md` — NEW, this session. 5
  images: `danmachi_18f_central_tree.png` (DanMachi Fandom wiki), `abyss_1st_layer.webp`
  + `abyss_3rd_layer.webp` (Made in Abyss Fandom wiki), `yana_caves_alien.png` +
  `gadime_cave_stalagmite.jpg` (real karst-cave photography, Wikimedia Commons via
  Openverse). See §1.
- `game/docs/art/_references/prairie_rivers/_synthesis.md` — NEW, this session. 5
  images: `river_boulders_rapids.jpg`, `frog_on_rocks_stream.jpg`,
  `rogue_river_boulders.jpg` (real river photography, Flickr via Openverse),
  `heron_riverbank_reeds.jpg` (Geograph via Openverse), `zelda_zoras_river_rapids.webp`
  (Zelda Fandom wiki, style-gap noted). See §2.
- `game/docs/procedural_ecology.md`, `game/docs/art/_world_coherence.md`,
  `game/docs/lore/_coherence_target_sheet.md` — existing design docs consulted for §3,
  discrepancies vs. actual code flagged where found.
