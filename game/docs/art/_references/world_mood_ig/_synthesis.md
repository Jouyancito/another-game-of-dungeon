# Reference: world_mood_ig — 3 Instagram refs from Joan's "ideas para juego" (2026-07-20)

Joan asked me to pull specific frames from a screen recording of him scrolling his
own saved Instagram collection, rather than guess — traced and located all 3
correctly (confirmed order: arch/phonebooth first, sound-design second, forest
last, per his own directions). Images live in this folder.

## Images

| File | Creator | What it shows |
|---|---|---|
| `simonzhang_vine_arches.png` | @simonzhang.art | Two vine-covered arches, dense green foliage, dirt path |
| `simonzhang_phonebooth_garden.png` | @simonzhang.art (same reel) | Red British phone booth engulfed in pink flowers + ivy, at the end of the same garden path |
| `guiguiw_firewatch_soundredesign.png` | @guiguiw__ | Firewatch (game) landscape screenshot (forest/mesa/lake) + an Ableton audio-editing timeline below it |
| `wintersyndel_forest_canopy_path.png` | @wintersyndel | Hyperrealistic Blender forest render: dense tree canopy over a path, soft light |
| `wintersyndel_forest_ground_glow.png` | @wintersyndel | Same piece: sunlit forest floor, undergrowth, glowing highlights |

## Qué se VE

**simonzhang.art — "When you trust the process in blender":**
- Caption on the reel literally reads "Let me cook" over a Blender viewport (an
  Add-on/geometry-nodes generated arch) — this IS a procedural/parametric
  vine-arch generator, not hand-modeled foliage.
- The phone booth shot shows dressing objects (props) integrated believably
  into overgrown vegetation — flowers cluster at the BASE and climb the
  structure, not scattered randomly. Direct precedent for how we should dress
  ANY small prop (well, market stall, gate) with vegetation growth logic:
  denser at ground contact, thinning with height.
- Comments in the reel are critical of topology/complexity-vs-payoff — useful
  caution: don't over-invest in unseen geometry that foliage will cover anyway.

**guiguiw__ — Firewatch sound redesign:**
- Not a modeling reference — Joan wants the MOOD of the background landscape
  (soft haze, warm-to-cool gradient sky, forest silhouette against open sky)
  and the reminder that AUDIO DESIGN (ambient sound layering, seen in the
  Ableton timeline) is as much a "feel" lever as geometry/lighting. Relevant
  to the motor's mood work (mood_valheim.py currently only does visuals).
- Direct callout: Joan wants me to notice the game's landscape looks
  "bastante bien, bastante agradable" — reinforcing that painterly/soft
  atmospheric distance (haze, gradient) reads as professional even with
  simple geometry, same principle as our mood_valheim mist pass.

**wintersyndel — hyperrealistic forest (Blender, credited tutorial: YouTube
channel "Roe.num77" — could not find that exact channel independently, but
found a closely matching public tutorial: "Blender Hyper-Realistic Forest
Tutorial – Ground & Tree Scattering"):**
- Ground cover, tree density, and light shafts through canopy are the load-
  bearing elements — the actual tree/rock meshes are secondary to DENSITY and
  LIGHT SCATTERING.
- Confirms Joan's own read: "a partir de plantas base genera un bosque
  precioso" — a small base-plant library + density-driven scatter (likely
  Geometry Nodes) is the real technique, not manually placing many unique
  trees.

## Qué capturar (para un futuro pase de bosque/paisaje — NO iniciado, solo referencia)

1. Procedural arch/vine-growth generator (geometry-nodes style) as a technique
   to investigate for gates, ruins, or overgrown POIs.
2. Ground-contact-biased vegetation dressing (denser at base, thinning up) for
   ANY prop we dress with foliage.
3. Atmospheric haze/soft gradient sky as a cheap "feels expensive" lever —
   already partially covered by mood_valheim's mist pass; this validates
   pushing it further specifically for forest/distance shots.
4. Density-driven scatter (Geometry Nodes) as the core forest technique —
   flagged as a SEPARATE future research/implementation topic per Joan, not
   part of the current village work.

## Fuentes

Screen-recording frames supplied directly by Joan (Instagram Reels, saved
collection "ideas para juego"), 2026-07-20. Creators credited above from their
own on-screen usernames/captions. `wintersyndel`'s reel further credits a full
tutorial on YouTube channel "Roe.num77" (unverified independently — channel
search did not surface it directly).
