# Reference: village_watchtower — physically-correct wooden watchtower (2026-07-18)

Triggered by PO feedback: our `village_gen.py` watchtower legs were rotated
outward ("chuecos") — Joan: "físicamente esa torre no se mantendría." Before
re-modeling, hunted MULTI-SOURCE structural references (never a single
source — a lone bad source poisons the model with nobody to catch it).

## Images

| File | What it shows |
|---|---|
| `chelan_butte_lookout_base.jpg` | Chelan Butte fire lookout (HABS survey photo, Washington state) — base structure, eyeballed 2026-07-18 |
| `castrum_vechtense_01.jpg` | Castrum Vechtense (reconstructed Roman watchtower, Netherlands) — full elevation, eyeballed 2026-07-18 |
| `elk_mountain_fire_lookout.jpg` | Elk Mountain overlook (South Dakota) — picnic table shot, tower itself out of frame; KEPT for provenance but NOT used for structure (caught by eyeballing — a bad/irrelevant hit in a multi-source set is expected and should be discarded, not silently trusted) |

## Qué se VE (chelan_butte_lookout_base.jpg — the load-bearing reference)

- **4 legs, PERFECTLY STRAIGHT vertical** (no lean/splay) — this is the
  literal fix for our bug. The legs run parallel, plumb, from concrete
  footings straight up to the platform underside.
- **TWO tiers of diagonal X-cross bracing** per face (bottom tier + top
  tier), not just one — each tier is a full X between two legs.
- **A horizontal collar/ring brace band** between the two X-cross tiers,
  running around all 4 faces at roughly mid-height — this is what makes the
  X-braces read as ONE braced frame instead of two disconnected sets.
  A second ring sits right under the platform.
  4 legs → the load path is direct and vertical, exactly what "no se
  mantendría" was pointing at.
- **Ladder** zig-zags up through the middle of the frame, anchored to the
  cross-bracing at each landing.
- Individual X-braces are FLAT boards (not round poles) bolted/lashed at
  each crossing point — thin cross-section relative to the legs.

## Qué se VE (castrum_vechtense_01.jpg)

- Different tower TYPE (a raised timber gatehouse, not a stilt lookout) but
  confirms: **weathered grey-brown vertical plank cladding**, gabled shingle
  roof, staircase (not ladder) on this variant, sits on a raised earthen
  bank with its own palisade — i.e., towers in real fortified sites are
  INTEGRATED with the palisade/bank, not a standalone stilt structure in
  open air. Reinforces our tower-on-highest-ring-point placement (already
  correct in the generator).

## Qué capturar (reusable takeaway for village_gen.py `build_tower`)

1. **Legs**: `rotation_euler = (0,0,0)` — straight, no per-leg lean. This is
   THE fix (root cause of the bug was literally `leg.rotation_euler = (sx*-0.08, ...)`).
2. **Two bracing tiers, not one**: X-cross between legs at ~[0.15h-0.5h]
   AND ~[0.5h-0.85h], with a horizontal ring brace at the ~0.5h seam.
3. Ring braces also at the very top (just under the floor) for rigidity.
4. Optional ladder on one face reads as "used/functional," not just static
   decoration.
5. Colors: weathered structural wood is NEVER pure dark/black even in
   "gloomy" biomes — Castrum's plank tone reads as a cool grey-brown, not
   near-black. Used to retune `wood_dark` per biome (see village_palisade
   synthesis — same palette rule applied there).

## Fuentes

- [Chelan Butte Lookout, HABS WASH,4-CHELAN.V (Library of Congress / Wikimedia Commons)](https://commons.wikimedia.org/wiki/File:Close-up_view_of_bottom_of_lookout_tower,_NW_corner._Shown_are_four_concrete_point_led_footings,_wooden_structure_and_stairs._-_Chelan_Butte_Lookout,_Summit_of_Chelan_Butte,_HABS_WASH,4-CHELAN.V,2-10.tif), public domain (HABS), downloaded 2026-07-18.
- [Castrum Vechtense (Wikimedia Commons)](https://commons.wikimedia.org/wiki/File:Castrum_Vechtense_01.JPG), CC-BY-SA, downloaded 2026-07-18.
- Elk Mountain overlook (Wikimedia Commons), downloaded 2026-07-18 — kept as a documented miss, not used.

## GAP

- No second INDEPENDENT source for the two-tier-bracing detail beyond
  Chelan Butte — Castrum Vechtense is a different tower type and doesn't
  show leg bracing. Ideally add a medieval-specific wooden siege/lookout
  tower reconstruction photo next pass (Wikimedia Commons rate-limited us
  mid-session — 429 "too many requests" — before a 3rd structural source
  could be pulled).
