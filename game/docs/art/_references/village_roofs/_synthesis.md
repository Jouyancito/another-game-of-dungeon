# Reference: village_roofs — roofs with life (thatch / tile / snow) (2026-07-18)

Triggered by Joan's v5 verdict: current roofs are "uniform lifeless
single-color prisms" — one flat-colored `gable_roof()` per house regardless
of biome or building importance. This folder hunts what real/game roofs
actually look like so the generator can give roofs texture-read and variety
without going into particle-fur/high-poly territory (low-poly budget).

## Images

| File | What it shows |
|---|---|
| `thatch_cottage_romania.jpg` | Romanian thatched-roof cottage — full house, steep pyramid thatch over a log wall |
| `thatch_roof_detail_closeup.jpg` | Thatched roof detail (Freilandmuseum, Lübbenau) — close texture read + ridge cap |
| `tile_roof_toscana.jpg` | Tuscan hill town — terracotta tile roofs across a whole village |
| `rdr2_colter_snow_cabins.png` | Colter (RDR2) — snow-capped steep gable roofs over log cabins |
| `rdr2_colter_loading.jpg` | Colter (RDR2) loading screen — close-up gable end showing exposed knee-brace under the roof overhang |

## Qué se VE (thatch — the load-bearing pair)

- Roof is **THICK** — reads as a deep, almost blanket-like mass, never a
  thin painted plane. The bottom edge is **uneven/shaggy**, not a crisp
  line — individual bundle-ends catch light differently.
- Color is a **warm grey-straw**, muted — NOT a saturated gold/orange (our
  old `roof_thatch` value `(0.52, 0.42, 0.22)` skewed too orange/warm vs.
  what these photos actually show).
- The close-up shows a **capping ridge** at the peak — a distinct band
  (stone/moss strip in this ref) different in texture/tone from the slope,
  running the length of the roof.
- Pitch is VERY steep (near 45°+) — thatch sheds water by angle, not by
  membrane.

## Qué se VE (tile — Toscana hill town)

- Roofs are **terracotta orange-brown**, laid in visible horizontal
  **ROWS/COURSES** — from a distance this reads as subtle banding across
  the slope, not a flat color.
- Pitch is noticeably **shallower** than thatch — tile is a rigid material,
  doesn't need thatch's steep water-shedding angle.
- Roofs pack **tightly across the whole hillside**, all similar tone — this
  is the "civilized/permanent settlement" roof material, which is exactly
  why the PO calls tile out for the casona (the best-built building gets
  the best-built roof).

## Qué se VE (RDR2 Colter — snow-appropriate construction)

- Roofs are **steep gables, heavily snow-capped**, over horizontal ROUND-LOG
  walls (not plank) — thick walls read cold-appropriate on their own.
- `rdr2_colter_loading.jpg` (the single most useful shot): at the gable
  peak, where the roof overhangs past the wall's front face, there is a
  **visible triangular wood knee-brace/bracket** holding that overhang up —
  textbook "the roof doesn't float" construction logic (PO principle 4).
- Stone chimney, small windows, icicles at the eave — confirms
  `window_scale=0.65` was already the right call for hielo.

## Qué capturar (reusable takeaway for `village_gen.py`)

1. **Roofs need row/band variety, not a flat color** — cheap low-poly trick:
   subdivide the gable slope into N horizontal strips, alternate 2 tones
   (`banded_roof()`). Reads as tile coursing or shingle rows at game
   distance without particle systems.
2. **Thatch = layered geometry, not a texture** — 2-3 stacked gable slabs
   shrinking toward the ridge (slight per-layer jitter) + a ridge-cap box —
   gives the "thick, shaggy, capped" read from the photos with near-zero
   extra tris.
3. **Palette correction**: thatch → warm grey-straw `(0.58, 0.52, 0.38)`,
   NOT the old saturated gold. Tile → terracotta `(0.68, 0.40, 0.27)`.
   Both sampled directly off these photos, not invented.
4. **Every roof needs a visible support detail where it overhangs the wall**
   — short diagonal brace struts from each wall corner to the roof
   underside (`rdr2_colter_loading.jpg`'s knee-brace, simplified to fit the
   existing `strut()` helper) — applies to every biome, most visible on the
   steep hielo pitch.
5. **Per-biome roof-kind pool, not one kind per biome**: pradera mixes
   thatch (common) + tile (casona/civilized); bosque stays mostly dark
   shingle with occasional thatch; hielo stays shingle-under-snow (the snow
   cap always LAYERS on top of a banded base, never replaces it, so the
   understructure still peeks at the eaves).

## Fuentes

- [Romanian thatched roof cottage (Openverse → Flickr, quinet)](https://www.flickr.com/photos/91994044@N00/7981741789), CC BY 2.0, downloaded 2026-07-18.
- [Thatched roof detail (Openverse → Flickr, quinet)](https://www.flickr.com/photos/91994044@N00/37535279832), CC BY 2.0, downloaded 2026-07-18.
- [Toscana hill-town tile roofs (Openverse → Flickr)](https://live.staticflickr.com/2153/5703668721_47a1dc9525_b.jpg), downloaded 2026-07-18.
- [Red Dead Wiki (Fandom) — Colter](https://reddead.fandom.com/wiki/Colter), vía API MediaWiki, 2026-07-18.

## GAP

- No Skyrim thatch close-up sourced this round (Whiterun's roofs read as
  wood-shingle in most screenshots, not thatch) — the thatch identity here
  leans on the 2 real-world photos, which is enough to fix the color/texture
  claim but a game-art thatch reference would strengthen the stylization
  case further if revisited.
