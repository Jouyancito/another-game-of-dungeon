# Big-Game Design Lessons → Dungeon Party (Floor 1 Crystal Cavern)

**Status**: actionable synthesis · 2026-06-06 · scope = alpha 5-map demo
**Sources**: 4 research lenses — Valheim (devblogs/interviews), Metin2 (project canon + historical), placement/immersion errors (postmortems + GDC), generator architecture (codebase audit).
**Filter**: every lesson answers "what do we DO differently in Dungeon Party?" Confidence tags: `[HIGH]` = devblog/GDC/postmortem/code-verified · `[MED]` = inferred/community · `[LOW]` = hearsay, treat as hypothesis.

Code ground-truth (verified against `floor1_prairie.gd` this session):
- `_snap_all_to_terrain()` EXISTS (L396): uses `terrain_y + existing_offset`, fallback `terrain_y + 1.0`.
- Water IS implemented (`water_toon.gdshader`, CSGCylinder3D L966/982) — the "fake water" risk is LOWER than generic research assumed.
- Per-instance `randf() * TAU` rotation applied everywhere (L614/1108/1139/1205). `_age_scale()` exists.
- Shadows explicitly OFF on ceiling + crystal lights (L516/600).
- NO `VisibleOnScreenNotifier` / LOD. NO `NavigationRegion3D` in floor. Pools are hardcoded `const` arrays (L1007-1040). No floor-generation determinism test in `game/tests/unit/` (24 GUT files, none cover generation).

---

## 1. TOP LESSONS TO ADOPT (prioritized, deduped)

### Tier 1 — do for the alpha demo (cheap, high player-facing payoff)

| # | Lesson | Concrete change in Dungeon Party | Conf |
|---|--------|----------------------------------|------|
| L1 | **Composition + lighting > poly/texture.** Low-poly gains soul from fog, bloom, directional shadows, silhouettes — not detail. (Valheim CEO, multi-lens) | Floor 1 looks washed-out NOW. Re-enable a strong `DirectionalLight3D` (energy ~1.2, az 40° / el 55° per `_world_coherence.md §8`) WITH `shadow_enabled = true` on it (the ceiling/crystal lights stay shadowless — that's correct). Add bloom on crystals + luminescent flora instead of brighter textures. Crystal pillars must get emissive/toon material (they're dark un-materialed now — see §2). Grayscale test: screenshot → desaturate → can you still read depth? If no, lighting is flat. | HIGH |
| L2 | **Distant-visible landmarks drive exploration without UI markers.** Tall towers/spires = natural waypoints; "just one more hill" pull. (Valheim + Metin2 both) | We already spawn 6 pillars (30-50m) + monarch crystals. ENFORCE 2-4 of them are visible from spawn AND from every Major POI (silhouette readable 40-80m, no UI). Validate with a grayscale silhouette pass: each landmark must be "describable to a friend," not generic. The 3 monarch crystals are the natural hero-waypoints — make them the tallest, most saturated objects in the scene. | HIGH |
| L3 | **No floating / wrong-scale objects — the #1 instant immersion break.** Players flag floaters in <5 min. Scale anchors to the player (1.8m). | `_snap_all_to_terrain()` already runs (L179/396) — but AUDIT it covers ALL scatter (trees, bushes, rocks, props, crystals on ceiling), not just enemies. Add a debug viz: log `terrain_y` vs placed `position.y`; flag delta. Confirm every imported gltf has Y=0 at its BASE (lowest vertex), not center, or you get sink/float + z-fighting at bases. Keep `_age_scale` extremes inside ~0.3-1.7× of the master table; histogram 100 instances → bell curve centred ~1.0, no outliers >2.0. | HIGH |
| L4 | **Sharp biome/zone boundaries beat smooth blending.** Abrupt edges signal "new zone" and let co-op teams read threat fast. (Valheim + Metin2) | Define a **safe inner ring** (spawn + docile creatures, sparse) vs **deep outer ring** (tier-2 enemies, ore/herbs, denser). Mark the boundary with a HARD visual cue (elevation drop / crystal-wall formation / `TERRAIN_EDGE_RISE` cliffs), NOT a color gradient. Field patrols = weak swarms; POIs = tight clusters; boss = ONE terrifying foe (anomaly read). Do NOT blend enemy tiers across the line. | HIGH / MED |
| L5 | **Mob density: tight POI clusters + breathing room between.** Victories feel earned; players recover/plan between fights. (Metin2) | Skew the ~75-135 enemy budget: ~40% inside POIs (4-6 tightly packed per Major POI, radius 40-60m), ~30% field patrols spaced 200-250m apart, ~30% perimeter. Field patrols NEVER include elites — elites only spawn POI-internal. Make the boss arena spawn a single high-tier enemy, not a pack. | HIGH |
| L6 | **"Feel-first" design, not constraint-list-first.** Name the emotion, then build rules to reinforce it. (Iron Gate) | Write Floor 1's feeling in one line at top of the biome doc: *"a safe but eerie crystal meadow; squad feels small against a vast luminous cavern; landmarks visible but distances deceive."* Then justify each generator constant against it. Tune: make monarch spires feel always-farther-than-they-look so navigation is gently disorienting. | MED |
| L7 | **Warm/inviting palette = deliberate "false security" (DP inverts Metin2's dark=danger signal).** Danger is MECHANICAL (fall, DoT plants, water slow), not visual horror. | Hold Floor 1 to warm golds + pastel greens (60/25/15 per `_art_canon.md §5.2`). NO desaturation (that's Floor 5). Threat comes from hazards, not scary art. This is canon-consistent — don't let "make it look dangerous" creep in. | HIGH |

### Tier 2 — adopt if cheap, otherwise defer post-alpha

| # | Lesson | Concrete change | Conf |
|---|--------|-----------------|------|
| L8 | **Deterministic seed → repeatable, shareable worlds.** Same seed = same world; enables co-op sync w/o streaming, seed-sharing, speedrun pathing. (Valheim) | We already seed POIs + terrain. Make `_generate_vegetation` reseed explicitly from `world_seed` (currently uses `self._rng` — see §3). Log the seed in world metadata. This is also the co-op netcode foundation: clients regenerate from seed, not stream geometry. | HIGH |
| L9 | **Hidden POIs / fog-of-war reveal beats wiki-able maps.** Discovery feels earned. (Valheim) | Reveal crystal clusters / boss only within ~300m. Don't pre-mark everything. LOW priority for a 5-map alpha (small maps) — note as nice-to-have, not blocker. | MED |
| L10 | **Repetition kills the "lived world" feel.** Same tree-clump 3× in a 50m walk reads as fake. | Verified: rotation is per-instance `randf()*TAU`, `_age_scale` varies scale, pools pick `randi() % size`. Risk is **asset poverty** (Quaternius packs have only 3-4 tree models). Mitigation = age-scale + rotation variety (already present). Audit: walk a 30m² patch, count ≥3 distinct trees + ≥2 scale tiers. "Twins" = a seed-reuse bug. | HIGH |

---

## 2. PLAYER-NOTICED ERRORS CHECKLIST (audit Floor 1 against this)

Cross-referenced with our known issues: **washed-out floor**, **floating-object concern**, **placeholder boxes**, **dark un-materialed crystal pillars**.

| Symptom | Why players notice (instant, pre-conscious) | Our risk NOW | Fix | Conf |
|---------|---------------------------------------------|--------------|-----|------|
| **Flat / washed-out lighting** | Brain uses shading to judge depth/shape; uniform ambient = 2D backdrop | **HIGH — known issue.** Floor reads washed-out; strong shadowed DirectionalLight likely missing/weak | Strong `DirectionalLight3D` energy ~1.2 + `shadow_enabled=true` (ceiling/crystal lights stay shadowless). Add SSAO + volumetric fog for depth. Grayscale-screenshot test. | HIGH |
| **Dark, un-materialed crystal pillars** | A "hero" landmark rendering as a flat dark blob screams unfinished; kills the waypoint read (L2) | **HIGH — known issue.** Monarch crystals are the intended waypoints but have no material | Give crystals emissive toon material + bloom; they should be the most saturated, brightest objects. This directly enables the landmark-navigation lesson. | HIGH |
| **Placeholder boxes** | Untextured cubes read as "debug build," break the world fiction immediately | **HIGH — known issue.** Placeholder geometry still in scene | Swap remaining placeholder boxes for curated CC0 assets (Kenney/Quaternius) or hide them; nothing box-shaped should ship in the recorded slice | HIGH |
| **Floating objects** | Flagged by every Valheim/D&D playtester in <5 min; reads "unfinished" before consciously seen | **MED.** `_snap_all_to_terrain()` exists but may not cover all scatter types; ceiling crystals hang by design (OK) | Audit snap covers trees/bushes/rocks/props. Debug-log `terrain_y` vs `position.y` delta. Verify gltf Y=0 at base, not center. | HIGH |
| **Wrong scale** | Player (1.8m) is the anchor; a 2m tree or building-sized rock reads wrong instantly | **MED.** `_age_scale` exists; risk = imported gltf native heights differ (Kenney ~5.4m vs Quaternius ~4.2m birch) | Log native gltf height pre-scale, compare to `_world_coherence.md §1` master table. Histogram 100 instances → bell curve ~1.0, no >2.0 outliers. | HIGH |
| **Z-fighting at asset bases** | Flickering horizontal lines where terrain + asset collision misalign | **MED.** Depends on gltf export center; no audit done | 360° camera sweep at a few asset clusters; look for flicker lines at bases. Fix = Y=0-at-base export (same root cause as floating). | HIGH |
| **Repetitive scatter ("twins")** | Same clump repeated breaks lived-world feel | **LOW-MED.** Rotation + age-scale variety verified present; risk is small asset pool | Walk-test 30m² → ≥3 trees, ≥2 scale tiers. If identical twins appear, it's a seed-reuse bug. | HIGH |
| **Enemy clipping through rocks / navmesh gaps** | In co-op, teammates see enemies walk through "solid" rocks or get stuck → reads as bug | **HIGH (untested).** NO `NavigationRegion3D` in floor; rocks may lack baking collision. Worse in co-op (all clients must match) | Confirm `POOL_ROCKS` assets have collision shapes; add a baked `NavigationRegion3D`; test enemy walking at a rock cluster (must route around). Bake offline, identical across clients. | HIGH |
| **Fake / plastic water** | Flat reflections, no ripple/foam, wrong Y clipping land | **LOW.** Water uses `water_toon.gdshader` already (verified) | Verify shader has SOME motion (scroll/vertex wave) + edge foam; water Y sits in terrain depressions (`altura < 0.3×TERRAIN_MAX_HEIGHT`). Lower priority than research implied. | MED |
| **Pop-in / LOD desync in co-op** | One player sees a cluster, teammate doesn't → spatial incoherence | **LOW for alpha.** No LOD system = no pop-in yet (but also no culling). Becomes real only with netcode | Don't add aggressive LOD pre-netcode. If added later, sync LOD state across clients. Defer. | MED |

---

## 3. ARCHITECTURE TAKEAWAYS (generator + proc_lab harness + scaling to 5 maps)

Goal: build ONE generator harness so Floors 2-5 reuse ~80% of the code, swapping only data. `floor1_prairie.gd` is ~1500 lines with ~40 `const` values — the refactor target.

| # | Takeaway | Concrete move | Conf |
|---|----------|---------------|------|
| A1 | **Data-as-Resource (DAR): generation constants → `.tres`, not `const`.** Designers tune without recompiling. We already do this for skills/items/materials. | Create `BiomeConfig(Resource)` in `game/shared/resources/biome_config.tres` with `@export`: size, `tree_count`, `rock_count`, `crystal_clusters`, colors, border/terrain params, `field_count`, `patrol_count`, `enemy_types`, `spawn_weight_map`. Instantiate once at floor load, pass to all gen functions. Floors 2-5 = new `.tres`, same `.gd`. (Dir `game/shared/resources/` does NOT exist yet — greenfield.) | HIGH |
| A2 | **Per-layer seed propagation.** Each sub-generator seeds its own RNG = `world_seed ^ hash(layer_name)`. Per-layer rerolls without breaking determinism. | Add `_seed_from_layer(name) -> int`. Fix `_generate_vegetation` to reseed from `world_seed` (it currently rides `self._rng`). Comment: "same world_seed always reproduces the same output." | HIGH |
| A3 | **POI catalog → data table.** Move the `POI_CATALOG` Dict (`poi_system.gd` L24) into `poi_definitions.tres`. | `POICatalog(Resource)`: name, size (Vector2), enemy_count, category (anchor/major/minor). Load via `ResourceLoader`. Unblocks per-floor POI variation (P2 boss arena 120×120 vs P1 80×80) with zero programmer time. | HIGH |
| A4 | **Vegetation pools → data.** `POOL_TREES/BUSHES/ROCKS/GROUND` (L1007-1040 hardcoded `preload`) → `VegetationPool(Resource)`. | `VegetationPool`: name, biome, `assets: Array[String]`, density_weight, scale_min/max. `pradera_pool.tres` (current assets), `bosque_pool.tres` (Floor 2), etc. `_scatter_cluster` stays identical — only the pool swaps. This is "content as data" = the key to 5 maps / 1 harness. | HIGH |
| A5 | **Harness = composition of stateless generators, not a monolith.** Each takes `(config, seed)` → returns placement data (Transform3D arrays), separate from spawning. | Split `floor1_prairie.gd` into `TerrainGenerator`, `POIGenerator`, `VegetationGenerator`, `EnemyGenerator`. Each: `generate(config, seed) -> placement_data`. Floor 2 inherits, swaps config. Testable in isolation. This IS the `proc_lab` harness from the scope-reset notes. | HIGH |
| A6 | **Determinism integration test.** Lock the Valheim-grade reproducibility contract so future refactors can't silently break it. | Add `game/tests/unit/test_floor_generation.gd` (GUT): generate twice with `world_seed=12345`, serialize POI + terrain + vegetation positions to JSON, assert byte-identical. Runs on every generator PR, <200ms. GUT is already integrated; 24 tests exist, none cover generation — this is the gap. | HIGH |
| A7 | **Layer-based culling, NOT chunk streaming.** Bounded single maps don't need Valheim chunking. | If perf needs it: wrap vegetation MultiMesh pools in `VisibleOnScreenNotifier3D` culling boxes by distance band (~100/200/300m). Cheaper than chunking, layer-agnostic across floors. Profile first — ~400 base instances may not need it yet. | MED |

---

## 4. WHAT TO IGNORE (scope traps for a 5-map co-op alpha)

| Big-game thing | Why it does NOT fit our alpha | Verdict |
|----------------|-------------------------------|---------|
| **Chunk streaming / infinite procedural world** (Valheim) | Our floors are bounded ~600×600m. Chunking solves infinite worlds we don't have. | SKIP. Use layer-culling (A7) only if profiler demands. |
| **Aggressive multi-distance LOD** | No netcode yet; LOD desync across co-op clients is a real bug source. No LOD = no pop-in. | DEFER to post-netcode. |
| **Undisclosed-seed reverse-engineering community meta** (Valheim forums) | Cute long-tail engagement; irrelevant to shipping a 10-min demo slice. | IGNORE for alpha. Determinism (A2/A6) is the part that matters now. |
| **Full fog-of-war POI reveal system** | Maps are small; players see most of a floor quickly. Reveal-at-300m is marginal payoff. | NICE-TO-HAVE, not blocker. |
| **NPC social-anchoring inside field POIs** (Metin2 "meet me at the shop") | Floor 1 is enemy-only this alpha; NPCs live in the Taberna (post-phase-0). | POST-ALPHA. Reserve POI structure rules, don't build now. |
| **GodotWater plugin / advanced water sim** | We already have a toon water shader that's good enough; full sim is polish. | SKIP. Just verify motion + foam on existing shader. |
| **Mini-biome transition zones** | Iron Gate deliberately rejected these; sharp boundaries are the design (L4). | IGNORE — sharp edges are correct, not a deficiency. |

> Scope guard (from `CLAUDE.md`): before adopting anything here, ask *"¿Esto sale en el video de 10 min del demo?"* Tier-1 lessons + the §2 known-issue fixes do. Most of §4 doesn't.

---

### Provenance note
Lenses 1 (Valheim) and 2 (Metin2) are external research; treat web-sourced claims as `[HIGH]` only where tied to a named devblog/interview/GDC talk, `[MED]`/`[LOW]` for community/forum claims. Lenses 3 (placement errors) and 4 (architecture) were partly **code-verified this session** against `floor1_prairie.gd` / `poi_system.gd` / `game/tests/unit/` — those carry the highest confidence and override generic research where they conflict (notably: water already implemented, snap already implemented, rotation/scale variety already present).
