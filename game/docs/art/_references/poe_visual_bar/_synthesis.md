# Reference: poe_visual_bar — the production bar Joan wants DP to reach (2026-07-23)

Not a village-structure topic (see `village_poe_style/` for that). This is Joan
naming, image-by-image, WHY Path of Exile reads as "bonito" and not just
"bien" — a whole-game visual bar spanning environment micro-detail, creature/
character material readability, cloth rendering, and dedicated skill VFX.
Triggered by the village_gen.py v13 review: the gap isn't only village
architecture, it's every layer PoE invests in that DP hasn't matched yet.

## Images

| File | What it shows |
|---|---|
| `poe_beach_tide_strider_wetsand.png` | Beach ambush: party vs. Tide Strider water-elementals + castaway "bandits", wet/dry sand gradient, driftwood, animated water |
| `poe_dock_ruins_skill_vfx_cape.jpeg` | Dockside ruins fight: weathered scaffold/crane, white-cloak character with cape, green slash + gold burst skill VFX, undead swarm |
| `poe2_temple_columns_torchlight_beam.png` | PoE 2 (sequel — higher fidelity tier than PoE 1): temple/ruins courtyard, carved statue + fluted columns, a vertical light beam through a doorway, torch braziers (streamer overlay/captions in shot, ignore — the game footage is the reference) |

## Qué se VE (Joan's own read, cross-checked against the images)

**Environment micro-detail tied to STORY, not just material (beach image):**
- Water has real motion (foam trailing off the receding wave, directional
  ripple lines) — not a static blue plane.
- Sand reads WET near the waterline (darker, foam-flecked) and progressively
  DRIER further from it (lighter, flatter) — a value/color GRADIENT keyed to
  distance-from-water, not a flat sand texture.
- Driftwood/plank debris scattered on the sand belongs to the beach's implied
  story (shipwreck) — set dressing is narratively motivated, not generic
  scatter.
- The "bandit" corpses read as CASTAWAYS specifically — torn/ragged clothing,
  not generic bandit armor — the encounter's enemy-type communicates through
  costume silhouette alone, confirmed independently of the tooltip text.
- The Tide Strider enemies read as "wave with magic inside": pale
  blue-white translucent water-mass body + saturated RED arms/tentacles —
  the material split (cool body / hot-accent limbs) is what sells "elemental,
  not humanoid" at a glance. Direct precedent for how DP should design a
  water/elemental-type enemy's material, not just its silhouette.
- Player character stays legible and centered even mid-chaos — coherent hit
  reaction/pose reads clearly against a busy background.

**Construction + wear logic (dock image):**
- Scaffold/crane timber reads as REAL structural wood — bolted joints,
  visible hardware, and where it's broken it reads as ACTUALLY broken
  (splintered, hanging at the correct structural angle), not just deleted
  geometry. This is the same "the roof doesn't float" / "members touching,
  no structural gaps" principle already canon in `village_watchtower/` and
  `village_palisade/`, cross-confirmed independently by a THIRD source.
- Stone flagstones show real color variation, grime, and worn edges — same
  claim `village_poe_style/_synthesis.md` already made from the Lioneye's
  Watch images, now cross-validated by a second, unrelated PoE screenshot.
- Joan's own framing: "imaginátelo en primera persona, sería precioso" — the
  environment detail density is meant to read at CLOSE range (first-person
  DP camera), which raises the bar further than a top-down/isometric PoE
  camera technically requires — DP's camera has LESS room to hide flat
  materials than PoE's isometric angle does.

**Cloth rendering (dock image, white-cloaked character, left-center):**
- The cape reads as actual CLOTH: visible folds/creases catching light and
  shadow independently, not a rigid flat plane with a color. Confirms cloth
  needs either real sim/physics-driven folds baked into the mesh, or at
  minimum a normal-mapped fold pattern + directional light response — a flat
  `StandardMaterial3D` color plane (current DP cape approach, if any) cannot
  produce this.
- Arms read as anatomically correct limbs (proper joint bend, connected mass)
  — cross-reference to the Naturalness Audit rubric already in
  `art-ref-critic`: PoE's own character rigs pass every item on that
  checklist, which is worth holding DP's own character models to the same
  bar, not just monsters.

**Skill VFX (dock image, green slash + gold radial burst):**
- These are NOT simple particle systems — Joan's own guess is confirmed
  correct: AAA ARPGs (PoE, Diablo, Grim Dawn) build skill VFX from
  hand-painted or rendered FLIPBOOK sprite sheets (frame-by-frame 2D texture
  sequences) composited onto a billboard/plane in 3D space, layered with
  actual particle systems for sparks/embers. This is a DISTINCT production
  discipline from the "toon shader + ImmediateMesh channel ray" VFX approach
  DP currently uses for skill effects (see `_art_canon.md` §Kimetsu canon for
  skill VFX — that canon already points at 2D-in-3D anime-style effects,
  this reference reinforces it with concrete AAA precedent).
- Joan notes the SHEER VOLUME/variety of PoE's skill effects — this is a
  scale observation, not just a quality one: DP's current per-class skill
  roster (4 skills/class, Fase 1) is nowhere near this density, and closing
  that gap is a long-term VFX production investment, not a single asset fix.

**Hero architectural geometry + volumetric light (PoE 2 temple image):**
- The columns are FLUTED (carved vertical grooves catching rim light) and the
  statue is a distinct sculpted figure with real anatomical/drapery detail —
  neither is a primitive cylinder or a flat-shaded blob. This is
  CHARACTER-MODELING-tier geometry effort applied to architecture, not the
  kit-bashed-primitive approach `village_gen.py`'s houses currently use.
  Joan's own diagnosis is correct: "es geometría nueva" — no shader or
  texture trick substitutes for actually sculpting/detailing the mesh here.
- The light shaft through the doorway is a volumetric god-ray (visible beam
  through hazy/dusty air, not just a bright rectangle on the floor) — in
  Blender this is a real, well-documented technique (Principled Volume /
  volume scatter in a cone or box mesh, or Mist Pass + compositor glare),
  confirmed buildable per Joan's own Instagram-tutorial research, not a
  speculative ask.
- Torch braziers at the base read as a secondary, WARMER, lower-intensity
  light source against the doorway beam's cooler/brighter key — reinforces
  the "light pools against darkness" contrast principle already logged in
  `village_poe_style/_synthesis.md`, now with a THIRD independent PoE source.
- Note: this is PoE **2**, not PoE 1 (the source of `village_poe_style/`'s
  Lioneye's Watch images and this doc's other two entries) — PoE2 runs on a
  newer engine build with a visibly higher geometry/lighting budget. Treat it
  as the aspirational ceiling, not the baseline DP should expect to match
  1:1 with a low-poly toon pipeline; PoE 1's bar (already documented) is the
  nearer, more realistic target.

## Qué capturar

1. **Environment gradient-by-proximity** is a reusable pattern beyond sand:
   any DP terrain material touching water (streambeds, the prairie's crystal
   pools) should get a wet/dry value gradient keyed to distance from the
   water edge — ties directly into the still-open `prairie_rivers/_synthesis.md`
   in-channel-rocks work.
2. **Narratively-motivated dressing**: village/POI set dressing should tie to
   an implied local story (a beach = shipwreck debris, a bandit camp = looted
   goods) rather than generic biome-appropriate scatter — a content/writing
   lever as much as an art one.
3. **Elemental/creature material split** (cool body / hot accent) as a
   reusable material recipe for any DP monster whose IDENTITY is elemental or
   magical (relevant to any future water/fire/ice enemy design).
4. **Cloth needs real fold information** — flag for any DP character/cape
   asset: either bake folds into geometry + normal map, or accept capes read
   flat and deprioritize them versus higher-impact fixes.
5. **Skill VFX flipbook technique is a separate research/production topic**,
   NOT something to bolt onto the village texture pass — needs its own scoping
   pass (asset pipeline: how DP would author/source flipbook sprite sheets,
   whether Godot's `GPUParticles3D` + `AnimatedTexture`/`SpriteFrames` billboard
   approach is the right target versus the current channel-ray VFX code).
   Flagged here, NOT started.
6. **Hero-tier architectural geometry belongs in `motor-blender`, not
   Godot**: fluted columns, carved statues, and any "important building"
   piece (the casona's still-missing composite volume from
   `village_casona/_synthesis.md` is the direct DP analogue) need to be
   MODELED with real detail in Blender and exported as dressed props — not
   assembled from primitive boxes/cylinders at runtime. Confirms the existing
   Blender=geometry / Godot=placement split (already logged in the
   2026-07-21 session memory) as the right pipeline for this work.
7. **Volumetric light shafts are buildable now**: Blender's volume
   scatter/Principled Volume (or a Mist Pass + compositor glare) can produce
   a PoE2-style god-ray through a doorway — a concrete, scoped technique to
   prototype for the crystal-ceiling / torch-lit interior work already
   underway, not a research unknown.

## Fuente

Images supplied directly by Joan during the village_gen.py v13 visual-bar
discussion, 2026-07-23: two Path of Exile 1 gameplay screenshots (beach
ambush, dockside ruins fight) and one Path of Exile 2 gameplay screenshot
(temple courtyard, via a streamer's recorded footage — overlay/captions in
frame are not part of the reference). No URLs to cite — treat as direct
visual reference only.
