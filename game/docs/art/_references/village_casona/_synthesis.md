# Reference: village_casona — the central anchor building (2026-07-18)

Triggered by Joan's v5 verdict: "no es una aldea, es una barrera con cuatro
bloques" narrowed to the casona specifically — every village needs ONE big
house that reads as the anchor, and today it's just `house(..., dominant=True)`
— a scaled-up copy of the same box as every other hut. This folder hunts what
actually makes a "big house" read as the important one.

## Images

| File | What it shows |
|---|---|
| `jorrvaskr_mead_hall.png` | Jorrvaskr (Skyrim, Whiterun) — Companions' mead hall exterior, the load-bearing ref |
| `dragonsreach.jpg` | Dragonsreach (Skyrim, Whiterun) — the Jarl's palace, approach shot |
| `breezehome_exterior.jpg` | Breezehome (Skyrim) interior — stone-lower/wood-upper construction layering |
| `breezehome_entrance.jpg` | Breezehome (Skyrim) interior — post-and-beam roof structure, central hearth |

## Qué se VE (jorrvaskr_mead_hall.png — the load-bearing reference)

- **Raised on a visible stone plinth**, reached by a wide monumental stone
  STAIRCASE (8-10 steps) — the building is literally elevated above the
  surrounding ground, distinct from every hut around it that sits flat.
- **Entrance flanked symmetrically** by two carved posts + two lit braziers
  at the foot of the stairs — the door is ceremonially framed, not just a
  hole in the wall.
- **Roof = the whole building's silhouette signature** (an inverted-longship
  hull shape here) — the point is not that OUR roof needs to be a ship hull,
  but that the casona's roof shape/ornament (ridge carvings, dragon-head
  finials) is VISUALLY DISTINCT from the plain gable roofs on every hut.
- **Composite volume**: the hall isn't one box — door porch, main hull body,
  and the low stone retaining wall/steps around it read as separate
  attached pieces, not a single scaled primitive.

## Qué se VE (dragonsreach.jpg)

- Same pattern at bigger scale: stone foundation terraces → monumental stairs
  climbing toward the entrance → wood upper structure with a stepped,
  multi-gabled roofline (not one flat gable) → torches at regular intervals
  along the stair/wall. Palisade fencing flanks the approach — the casona
  sits INSIDE the defended area but is itself further fortified/elevated.

## Qué se VE (breezehome_exterior.jpg / breezehome_entrance.jpg — construction layering)

- Confirms the CONSTRUCTION ORDER for a "civilized" building even at hut
  scale: rough-cut STONE wall course at the base (visible masonry, not just
  a color) → WOOD plank/log walls above it → wood post-and-beam ceiling
  structure supporting the roof from inside (visible rafters + tie-beams,
  never a roof that looks like it floats on the walls alone).
- Central stone-ringed hearth on the floor — functional "great hall" reading
  reused for the casona's identity as the communal/chief building (ties back
  to the Axlin defensa-concéntrica trait already in `bandit_camp/_synthesis.md`
  — the most protected building is also the most solidly built).

## Qué capturar (reusable takeaway for `village_gen.py build_casona()`)

1. **Visible stone foundation/plinth**, taller and more "cut" than a hut's
   thin `stone_base` slab — the casona sits ON something, never flush with
   bare ground like a hut.
2. **Composite structure, not one scaled box**: main hall + one attached
   wing/annex (smaller volume, own lower roof, sharing a wall plane) —
   matches Jorrvaskr/Dragonsreach's multi-volume massing.
3. **Ceremonial entrance**: steps up to the door, door flanked by two posts
   + lit braziers (reuses the existing `flame_material()`).
4. **Roof kind is the biome's "civilized" choice** (tile for prairie/forest,
   snow-capped shingle for ice — see `village_roofs/_synthesis.md`) so the
   casona's roof silhouette differs from the thatch/plain huts around it.
5. **Proportions checked against MANNEQUIN_H** exactly like every hut — reuse
   `add_door`/`build_window_at`/`build_stairs`, don't hand-roll new door math.

## Fuentes

- [Elder Scrolls Wiki (Fandom) — Whiterun](https://elderscrolls.fandom.com/wiki/Whiterun) (Jorrvaskr image), vía API MediaWiki, 2026-07-18.
- [Elder Scrolls Wiki (Fandom) — Windhelm](https://elderscrolls.fandom.com/wiki/Windhelm) page image set (Dragonsreach screenshot cross-linked from the same wiki), 2026-07-18.
- [Elder Scrolls Wiki (Fandom) — Breezehome](https://elderscrolls.fandom.com/wiki/Breezehome), vía API MediaWiki, 2026-07-18.

## GAP

- Both Skyrim refs are ONE game's art direction — a non-videogame medieval
  "great hall" or manor-house photo reference would strengthen the
  cross-check (not sourced this round; time-boxed to 2 sources + 2 supporting
  construction-layering shots per the PO's 4-round iteration cap).
