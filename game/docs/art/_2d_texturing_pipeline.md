# 2D Texturing Pipeline — free/OSS stack for Dungeon Party

**Status**: research doc v1.0 (2026-07-23). Written to ground execution of Art
Canon §17 (Visual Bar Canon — "silhouette = geometry, surface = texture",
PoE1 as the vara, DnD as the floor). Zero-budget constraint: every tool below
is free or has a free tier that fully covers our use case; paid options are
named only when relevant and flagged.

Grounded in: `_art_canon.md` §17, `_references/poe_visual_bar/_synthesis.md`,
`blender-asset-smith` SKILL.md (headless bpy pipeline this must extend), and
`game/tools/blender/render_preview.py` + `_ficha_common.py` (existing render
rigs).

---

## A. Texture authoring for 3D surfaces

| Tool | License / cost | What it's good for | Learning curve | Integration |
|---|---|---|---|---|
| **Blender Texture Paint** | Free, already installed (5.1.2) | Hand-painted albedo directly on a mesh; hero one-offs (casona, altar) that need unique grime/wear the bpy generators can't procedurally fake | Medium — needs a UV unwrap first, then it's normal digital painting | Native; paint → bake to PNG → same material slot the toon shader already reads |
| **Sculpt-high → bake-normal** (Blender built-in, no addon) | Free | The actual mechanism behind §17's "silhouette=geometry, surface=texture" rule: sculpt or geo-nodes-displace a HIGH-poly version, retopo/keep the LOW-poly game mesh, Cycles bake (Selected-to-Active) normal+AO+curvature onto the low-poly's UVs | Medium-high — sculpting is a real skill; the BAKE SETUP (scene/cage/margin) is fiddly the first time, trivial after | This is the missing link between our flat-color CSG/vertex-color assets and the PoE bar — see "build these 3 first" #2 |
| **ArmorPaint** | zlib license (OSI/FSF-approved free license). Source free to build; precompiled binaries ~$19 one-time (not subscription) [verified via itch.io listing] | The closest free equivalent to Substance Painter — smart materials, wear/grime/edge masks, PBR paint. Best fit for **equipment** (armor/weapons) where "materials read as what they are" (§17.2.8) matters most | Medium — Substance-like UI, real learning investment but transferable industry skill | Standalone app; exports albedo/normal/roughness/metallic/AO PNGs that drop straight into a Godot `StandardMaterial3D` or into the bpy material setup |
| **Material Maker** | MIT license, open source, built ON Godot 4 (v1.6 targets **Godot 4.5.1** per its Steam listing — compat with our 4.6 project is [UNVERIFIED], though its plain PNG export path is engine-version-agnostic regardless) | Node-based PROCEDURAL materials (tileable stone/dirt/wood/metal) — the right tool for **terrain** and reusable material libraries, not one-off hero props | Medium — node-graph thinking, but a graph built once is infinitely reusable/variable (seed-driven, like our `gen_*.py` philosophy) | Exports standalone albedo/normal/roughness/height/AO PNGs (any engine); also emits a Godot `.tres` material directly (untested against 4.6's material resource format) and PNGs importable to Blender (Node Wrangler's "Add Principled Texture Setup" collapses the manual hookup to a few clicks) |
| **Krita** | Free, GPL | Hand-painted 2D albedo (icons, VFX frames, flat props) + a built-in **Height→Normal filter** (`Filter → Edge Detection → Height to Normal Map`, methods Prewitt/Sobel/Simple) for quick normal maps from a painted heightmap, plus a Tangent Normal Brush Engine for painting straight into normal-map space | Low if already comfortable painting digitally | Standalone; PNG in/out, no engine-specific step |

**Recommendation by asset type**: terrain → Material Maker (tileable, procedural, matches §17.2.6's "ground = material blend, not one texture"). Hero props → sculpt-and-bake + Blender Texture Paint touch-ups. Equipment → ArmorPaint. Anything 2D-native (icons, VFX frames) → Krita.

---

## B. Item icon rig (PoE/D2R style)

**Goal**: model-once (already true — items are `.glb` like every other DP
asset) → render-icon (missing step). No maintained open-source project does
exactly our headless-bpy + Godot pairing, but **ArdCarraigh/Blender_Icon_Generator**
(GitHub, CC BY-NC 4.0 — reference/inspiration only, do not vendor its code
into a public repo under a different license) proves the concrete recipe and
is worth reading before writing our own: orthographic camera (keeps relative
scale honest across a sword vs. a potion — the D2/PoE stash-tab requirement),
3-point light (key/fill/rim) that re-centers on the object, and a
`batch_process_example.py` pattern that loops a folder of models.

**Spec for our stack** (extends `render_preview.py`, which already has the
GLB-import + bounding-box-fit + key/fill-light logic — this is the base to
fork, not rewrite):

```
game/tools/blender/render_icon.py
  - reuse render_preview.py's import + bbox-centering code
  - swap the perspective 3/4 cam for an ORTHOGRAPHIC cam, fixed
    elevation/azimuth per category (so all swords share a pose, all shields
    share another) — orthographic is what keeps icon scale consistent,
    unlike render_preview's perspective cam
  - add a THIRD light (rim) to render_preview's existing key+fill pair
  - world.use_nodes background swapped for scene.render.film_transparent =
    True (render_preview currently renders on a dark CLEAR world — icons
    need RGBA alpha, not a dark backdrop)
  - output PNG at 256x256 (render at 512 and downscale for cleaner AA if
    quality demands it)

game/tools/blender/render_icon_batch.py
  - glob a folder of item .glb, shell out to
    `blender --background --python render_icon.py -- <in> <out>` per file,
    matching the existing per-asset invocation convention (gen_*.py already
    works this way)
```

**Effort**: ~2-4 hours one-time build (real extension work, not from
scratch — most of the math already exists). After that, icon generation for
any new item is one CLI call, same as a preview render is today.

---

## C. Flipbook VFX sprite sheets

### C.1 Blender Grease Pencil (hand-drawn, Kimetsu-canon frames)

Grease Pencil was rewritten in **4.3** (layer groups, thread performance,
Geometry Nodes support) and confirmed via Blender's own **5.1 and 5.2 LTS**
release notes to be actively maintained past the rewrite (further fixes,
e.g. restored lattice-parent deform) — it is in good shape on our installed
5.1.2. Workflow: draw N frames in the Draw workspace as 2D anime-style
strokes (color trail, freeze-frame impact per §0.1's Kimetsu rule) → render
each GP frame from a flat orthographic cam → assemble into a grid sheet.
This is the right tool for the actual COLORED SKILL TRAIL — nothing else in
this list produces hand-drawn anime line/color work.

### C.2 Blender sim bakes (Mantaflow)

Domain fire/smoke sim, baked, then rendered frame-by-frame from a fixed
transparent-film camera into the same grid-sheet format. Free and fully
scriptable, but compute-heavy (bake+render can run 30min-2hr per effect
depending on resolution/samples) — use for realistic embers/smoke LAYERED
under a Grease Pencil color trail, not as the primary stylized effect. (Paid
products like JangaFX EmberGen / cgheven's flipbook packs exist and prove the
technique is standard practice — they are NOT part of our free stack, cited
only for context.)

### C.3 Free existing libraries

- **Kenney Particle Pack** — CC0, 80 sprites (fire/smoke/magic/hearts/sparks/
  electricity), also pre-packaged for Godot (`Calinou/kenney-particle-pack`
  on GitHub). Good for a filler embers/sparks LAYER, not for stylized
  class-color trails.
- **Kenney Smoke Particles** — CC0, 70 assets, same use case.
- **OpenGameArt flipbooks** — spot-checked listings (`16x16 Explosion`,
  `Explosion Spritesheet` from GMTK2023, `explosion-spritesheet-low-res`
  "made in Blender") are individually CC0, but **OpenGameArt aggregates many
  authors under different licenses on the same site** (CC-BY, CC-BY-SA, GPL,
  CC0 side by side) — check EVERY page's own license line before using
  anything from there, never assume site-wide CC0.

### C.4 Godot 4.6 consumption

Verified against Godot docs: `BaseMaterial3D.particles_anim_h_frames` /
`particles_anim_v_frames` / `particles_anim_loop` drive a flipbook, but only
activate when `billboard_mode = BILLBOARD_PARTICLES`, and the matching
`ParticleProcessMaterial.anim_speed_min` must be > 0 or the animation never
advances.

- **GPUParticles3D + flipbook material** → many simultaneous instances of the
  same effect (hit impacts, footstep dust, several party members casting at
  once) — GPU-instanced, cheap at scale.
- **AnimatedSprite3D** (`SpriteFrames` resource, built-in frame timeline) →
  ONE deliberate billboard tied tightly to a cast event, where hand-authored
  per-frame timing matters more than instance count — the right target for
  the **named ultimate skills** that are the game's "hero asset" (§3).

---

## D. Normal-map generation from 2D images

| Tool | Status | Good for | Turns to mush when |
|---|---|---|---|
| **Laigter** | Alive, actively hosted (GitHub `azagaya/laigter`, GPL 3.0), Windows+Linux builds, free/pay-what-you-want on itch.io | Auto-generates normal+parallax+specular+occlusion from ONE sprite via edge/luminance analysis — fast pass on painted icons or VFX frames | High-frequency detail; it's a heuristic, not real geometry data |
| **Materialize** (BoundingBoxSoftware) | **Explicitly marked "Abandoned" by its own GitHub issue tracker** (Aug 2019, unaddressed PRs) — source still downloadable, functionally frozen. Verify it still runs on Windows 11 before depending on it | Same class of tool as Laigter, kept only as a fallback | Same limits as Laigter, worse: unmaintained |
| **Krita height-to-normal filter** | Alive, part of current Krita | Cheap normal from a hand-painted heightmap (cloth folds, plank grain — low-frequency) | Krita's own docs admit results are hard to get smooth on complex height data — do not use for engraving/rock detail |

**When good enough vs. mush** (ties directly to canon §17.2.1): heuristic
2D→normal tools are fine for **texture-only** detail — content that changes
how light plays on a surface but never the outline (engraving, grain, cloth
fold, subtle icon bevel). They fail at high-frequency detail, close-up/
grazing-angle viewing (the PoE synthesis names this exact failure: "que no
sea un hoyo PNG haciéndose pasar por un hoyo"), or anything that should
change the actual SILHOUETTE. For those, use real 3D detail — topic A's
sculpt-and-bake — not a 2D heuristic.

---

## Recommended pipeline per asset type

| Asset type | Tool chain | Build once | Per-asset |
|---|---|---|---|
| Terrain / architecture | PolyHaven CC0 source photos (already in `village_gen.py` v12) + Material Maker for tileable variants/blend masks + Godot texture splatting shader | Splat-blend shader (§17.2.6) | Pick/tune 2-4 materials per zone |
| Props (non-hero) | bpy generator (existing `gen_*.py` family) + sculpt-and-bake for PoE-tier relief where the silhouette rule allows a texture shortcut | Bake template (.blend + script, see below) | ~1-3 hrs per prop needing real relief |
| Equipment (armor/weapons/clothing) | ArmorPaint (primary) + Blender Texture Paint (touch-ups) + geometry-baked cloth folds (texture alone can't fake fold silhouette — confirmed by the PoE cape reference) | ArmorPaint material presets library | ~2-6 hrs per hero equipment piece |
| Items/drops + inventory icons | Existing model-once `.glb` pipeline + new `render_icon.py` rig | The icon rig itself (topic B) | Seconds — one CLI call per item |
| Skill VFX flipbooks | Grease Pencil (color trail, primary) + Mantaflow/Kenney CC0 (embers layer) + sprite-sheet packer | Packer script (topic C, see below) + a per-class color/shape language reference sheet | ~4-10 hrs per skill (hand-drawn frames are the real cost) |

---

## Build these 3 things first (highest leverage)

1. **`render_icon.py` icon rig** — unlocks D2/PoE-style inventory icons for
   every item that already has a `.glb` (all of them). Cheapest of the
   three, forks existing working code, immediately visible payoff.
2. **Bake-to-normal template** (a committed `.blend` + script: high-detail
   input → low-poly retopo/cage → Cycles Selected-to-Active bake → normal +
   AO + curvature PNGs). This is what makes §17's "silhouette=geometry,
   surface=texture" rule actually EXECUTABLE per-asset instead of aspirational
   prose — every future terrain/prop/equipment pass reuses it.
3. **Flipbook sprite-sheet packer** — a small Pillow script that takes N
   rendered/painted frames (from Grease Pencil render output, a Mantaflow
   render, or hand-painted Krita frames) and packs them into a fixed grid
   PNG while printing the matching `particles_anim_h_frames`/`v_frames`
   values for Godot. Without this, every single VFX asset stalls on a manual
   "arrange in an image editor" step.

---

## Honest verification notes

- **[UNVERIFIED]** Material Maker's generated Godot `.tres` material against
  Godot **4.6** specifically — the tool's last confirmed target is Godot
  4.5.1. Its plain PNG export path is engine-version-agnostic and safe
  regardless of this gap.
- **[UNVERIFIED]** Exact current ArmorPaint version number/feature set — the
  pricing (~$19 one-time for binaries, free to self-build under zlib) is
  confirmed, the release cadence was not checked line-by-line.
- **[UNVERIFIED]** Whether Materialize still runs cleanly on Windows 11 in
  2026 — it is confirmed abandoned since 2019 by its own issue tracker; test
  before relying on it, and default to Laigter instead.
- **Materialize and Laigter are both real, but Materialize is dead weight** —
  don't invest tutorial time in it beyond a quick compatibility check;
  Laigter alone covers this niche and is actively maintained.
- Grease Pencil's Blender 5.x health is confirmed via Blender's own official
  5.1/5.2 release notes (not first-hand tested inside this repo yet) —
  reasonably high confidence, not a hands-on verification.
- `Blender_Icon_Generator`'s CC BY-NC 4.0 license means it is a **reference
  only** — do not copy its code into this (source-visible, public) repo;
  reimplement the recipe from scratch as specced in section B.
- OpenGameArt licensing is per-page, not site-wide — the specific listings
  named above were individually confirmed CC0, but that does not generalize
  to the rest of the site.
- cgheven / JangaFX EmberGen flipbook products are **paid** and are cited
  only to confirm the sim-bake-to-flipbook technique is industry-standard —
  they are explicitly NOT part of the recommended free stack.
