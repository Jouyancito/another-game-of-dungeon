# Reference: village_lotr — Lord of the Rings, 4th village reference (2026-07-20)

Added by Joan as a 4th reference (after Skyrim/RDR2/DanMachi) specifically for
merchants, goods sold, animals, house form, and roofing/walls. Images live in
this folder, eyeballed directly.

## Images

| File | What it shows |
|---|---|
| `hobbiton_old_mill_stone_timber_thatch.png` | The Old Mill, Hobbiton (real film set) — stone-cut lower foundation + timber-frame upper wall + thick thatch roof + blue-painted wood shutters/door + a functioning water wheel + small dock with a rowboat |
| `lotr_market_hanging_dried_goods_baskets.png` | Bree/Hobbiton-style market stall — woven baskets, stacked barrels and sacks, coiled rope, bundles of dried goods HANGING from the stall frame overhead |

## Qué se VE

**The Old Mill (construction logic, exactly what the PO asked to "sacar
ideas"):**
- THREE materials, THREE roles, clearly separated by height: cut stone at the
  base (wet-proofing against the river, load-bearing), timber-frame + plaster
  for the living wall above, thick shaggy thatch capping it — each material
  doing the job it's actually good at, not decoration.
- Functional water feature integrated structurally (the wheel is part of the
  building, not a separate prop) — mirrors our existing well/mud-patch logic,
  suggests a MILL could be a future economy module (agrícola).
- Painted wood trim (blue shutters/door) — a single saturated accent color
  against neutral stone/thatch, same "one accent, rest quiet" principle we
  already use (banners, doors).

**Market stall (goods logic):**
- Baskets/barrels/sacks at ground level = bulk storage, stacked informally.
- Dried goods (herbs/fish/meat implied) hang OVERHEAD from the stall frame —
  this is a distinct decoration slot from our existing "hanging line between
  houses": here it's PRODUCT DISPLAY, mounted directly on the stall structure,
  not strung between two buildings. Coiled rope as a background prop.

## Qué capturar para el generador

1. If/when a `market` module is added (see `village_settlement_logic`
   addendum), stalls get their OWN hanging-goods slot (product on the stall
   frame) separate from the inter-house decoration lines.
2. A future "mill" building (economy: agrícola) could reuse the 3-material
   stone/timber/thatch stack — same technique as `build_casona()`'s plinth,
   applied to a smaller structure.
3. Confirms (independently from Skyrim/DanMachi) the material-hierarchy rule:
   stone only where structurally justified (foundation, wet-facing wall),
   never as blanket coverage on every building.

## Fuente

Images supplied directly by Joan (source unspecified — production-still /
tourism-photo style for Hobbiton, promotional LOTR-trilogy market still).
Treat as visual reference only, no URL to cite.
