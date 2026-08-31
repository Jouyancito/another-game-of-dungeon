# Reference: village_palisade — real stockade construction (2026-07-18)

PO addendum (Joan, mid-session): the previous stake shape ("un tronco con
un cono arriba") was MY invention, not derived from any reference — called
out explicitly. This folder fixes that: real palisade/stockade construction,
hunted MULTI-SOURCE before touching stake geometry, plus the standing rule
that colors/materials should come from what's IN these photos, not
invented flat values.

## Images

| File | What it shows |
|---|---|
| `fort_harrod_log_palisade.jpg` | Old Fort Harrod (Harrodsburg, KY) reconstructed stockade — eyeballed 2026-07-18 |
| `james_white_fort_flickr.jpg` | James White's Fort (Knoxville, TN) — log cabin + palisade fence edge visible — eyeballed 2026-07-18 |
| `castrum_vechtense_01.jpg` | (shared with village_watchtower) Castrum Vechtense reconstructed palisade wall around the tower — eyeballed 2026-07-18 |

## Qué se VE (fort_harrod_log_palisade.jpg — the load-bearing reference)

- Logs are **THICK, ROUND, and TOUCHING** — set side by side with only hairline
  gaps, NOT individually-spaced pillars with air between them. This is the
  single biggest gap vs. our old generator (isolated stake pillars = "ni
  siquiera alambre").
- **Tops are axe-cut roughly FLAT to a shallow point** — a slight facet/angle,
  not a tall symmetric cone. Height of the cut point varies log-to-log
  (small, irregular, a few cm of stagger) — nothing like a uniform row of
  cones.
- Color: warm weathered tan-brown, medium value — NOT the near-black
  "wood_dark" our code was using. Sampled ≈ `(0.42, 0.31, 0.19)`.
- Behind/above the stockade line, cabin roofs are visible — confirms
  interior structures are taller than the wall in places (already true in
  our generator via the dominant central building).

## Qué se VE (james_white_fort_flickr.jpg)

- Secondary/independent site: a lighter picket-style fence at the frame edge
  — individual pickets, closer together than a "pillar" fence but each
  picket clearly narrower and more pointed than Fort Harrod's massive
  stockade logs. Confirms stockades vary log-diameter-to-spacing by
  culture/period, but ALWAYS touching-or-near-touching, never isolated posts
  with visible sky/gaps between each one.

## Qué se VE (castrum_vechtense_01.jpg, palisade portion)

- Vertical plank palisade (not round logs) around the earthwork — tops cut
  in a slight sawtooth (alternating tall/short), weathered grey — a second,
  visually distinct construction method that still obeys the same rule:
  **members touching side-by-side, no structural gaps**.

## Qué capturar (reusable takeaway for village_gen.py `build_palisade`)

1. **The wall must read as continuous**, not a picket fence of separated
   posts — added 2 horizontal rail beams (top ~2/3 height + mid ~1/3
   height) physically CONNECTING consecutive stakes around the ring
   (skipping the gate arc and any terrain-defended gap), so even with
   individual round-stake geometry the silhouette reads as one barrier.
2. Stake tip = a short, shallow-angle cut (small cone, height reduced vs.
   old code) rather than a tall pointy spike — closer to an axe-cut log top.
3. Color: retuned `wood_dark` per biome away from near-black toward the
   warm weathered tan Fort Harrod shows (pradera), with cooler/darker
   variants for bosque/hielo mood while staying in the same weathered-wood
   family (never flat invented values) — see hex notes in
   `village_gen.py` comments at the `STYLES` dict.

## Fuentes

- [Log palisade, Old Fort Harrod (Openverse → Flickr, Joel Abroad)](https://www.flickr.com/photos/40295335@N00/6667721629), CC BY-NC-SA 2.0, downloaded 2026-07-18.
- [James White's Fort - Knoxville, TN (Openverse → Flickr, SeeMidTN.com)](https://www.flickr.com/photos/94502827@N00/15001845481), CC BY-NC 2.0, downloaded 2026-07-18.
- Castrum Vechtense (Wikimedia Commons), CC-BY-SA, downloaded 2026-07-18 (shared with `village_watchtower/`).

## GAP

- Wikimedia Commons rate-limited this session (HTTP 429, "too many
  requests... discuss a less disruptive approach") partway through —
  planned 3rd/4th stockade sources (Ninety Six SC, Aztalan, Fort Osage,
  Bachritterburg) all failed the download and were discarded rather than
  faked. Switched successfully to Openverse→Flickr for the 2 real sources
  above, which is enough to cross-check the core claim (touching logs,
  flat-cut tops) but a wider set would strengthen it further.
