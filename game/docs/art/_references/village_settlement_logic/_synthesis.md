# Reference: village_settlement_logic — why villages are organized the way they are (2026-07-18)

Triggered by PO verdict on village_gen.py v4: "no es una aldea, es una barrera con
cuatro bloques" — the generator had structure (palisade, gate, tower) but ZERO
settlement LOGIC: houses were placed by pure radius/angle randomness, nothing
distinguished a communal building from a private one, and nothing said WHY
anything sat where it sat. This folder is text/diagram research (no photo
identity to sample colors from — this topic is about SPATIAL ORGANIZATION, not
material), multi-source across two different traditions so no single culture's
quirk gets over-generalized into "how all villages work."

## Sources consulted

1. Medieval European nucleated village (church/green-centered) — multiple
   overview sources (Medievus, Battle-Merchant, Medieval Chronicles, Ludus
   Ludorum) cross-checked for the same core claim.
2. West African / Yoruba ring-compound settlements + American Southeast
   ceremonial-plaza towns (Britannica, Grokipedia, academic PDF on Tswana
   stone-walled towns) — an independent, non-European tradition, checked to
   see if the center-vs-periphery logic generalizes or is Euro-specific.

## Qué dicen las fuentes (cross-checked pattern)

**Medieval European village** (Medievus, Battle-Merchant, Medieval Chronicles):
- Nucleated layout: houses cluster tightly around a **central node** — a
  church, a green/common, a market square, or a road junction/water source.
- That central node hosts the **communal functions**: worship, gathering,
  livestock grazing on the green, shared firewood/turf collection, the mill,
  the smithy — all COMMON infrastructure serving everyone.
- Peasant dwellings ring the outside of that core; open fields, pasture, and
  woodland sit further out still, worked in strips/commons.
- Regional variants (clustered/irregular, street-village, hillside-square)
  all keep the same core-vs-periphery split even when the exact SHAPE differs.

**West African compound settlements** (Britannica, Grokipedia, Tswana study):
- Yoruba and related West African settlements form **ring-like enclosures**
  of huts around a **central open courtyard/compound** used for cooking,
  laundry, ceremonies, play, and safe overnight keeping of animals — i.e. the
  center is COMMUNAL LIFE + shared livestock safety, private sleeping huts
  ring the outside.
- American Southeast indigenous towns: ceremonial center (council house /
  temple + plaza ringed by arbors) at the town's heart, chief/dignitary
  residences nearest it, ordinary housing further out.

**Cross-check verdict**: two structurally unrelated traditions (medieval
Christian Europe, West African kinship compounds, North American ceremonial
towns) converge on the SAME rule: **common/communal functions (worship,
plaza, hearth, livestock-safety, crafts, market) cluster toward the center;
private/residential space sits farther out toward the edge/wall.** This is
not a European quirk — it is close to a settlement-pattern universal, driven
by the same logic in every case: the center is the shortest-walk point from
every house, so whatever needs EVERYONE's daily access (well, hearth, market,
worship) goes there; sleeping/private space can afford to be a longer walk.

## Qué capturar (reusable takeaway for village_gen.py)

1. **Radius-banded zoning, not radius-random placement.** Define concentric
   bands from village center outward: `commons band` (well/hearth/plaza/
   crafts, smallest radius) → `residential band` (houses, mid radius) →
   `wall/defense band` (palisade + watch structures, outer radius). A house
   is never placed by a flat `uniform(dmin, dmax)` roll across the WHOLE
   village — it's placed within its assigned band.
2. **The central plot is the busiest, not the biggest-alone.** In DP terms:
   well + hearth + plaza + a craft area (Axlin's "vida productiva adentro")
   sit at/near center; the "central building" (chief/storage) can be
   protected-central too (matches the existing Axlin defensa-concéntrica
   trait already in `bandit_camp/_synthesis.md`), but the COMMONS themselves
   — not just one dominant hut — are what earns the center.
3. **Randomness decorates the band, never invents the band.** Within a band,
   jitter angle/radius/rotation freely (that's where "organic, not gridded"
   comes from) — but which band a building TYPE belongs to is a fixed rule,
   not a roll.
4. **Livestock safety follows the same logic**: a pen sits close enough to be
   watched from the community's daily-use area (near-center or just outside
   the commons band), not stashed randomly at the wall edge where a breach
   would lose it first.

## Fuentes

- [Medieval Village Layout: How Communities Lived & Thrived (Medievus)](https://medievus.com/blog/medieval-village-layout/)
- [The medieval village: structure, everyday life and development (Battle-Merchant)](https://www.battlemerchant.com/en/blog/the-medieval-village-structure-everyday-life-and-development)
- [Medieval Village Life: Daily Life, Farming & Community (Medieval Chronicles)](https://www.medievalchronicles.com/medieval-life/medieval-village/)
- [Get Medieval: The Village in the Middle Ages (Ludus Ludorum)](https://ludusludorum.com/2014/10/28/get-medieval-the-village-in-the-middle-ages/)
- [Africa's compound house offers a model for multigenerational shared living (RIBAJ)](https://www.ribaj.com/intelligence/rising-stars-column-bushra-mohamed-finhankra-compound-house-mombasa-nairobi-kenya-ghana-communal-shared-living/)
- [Compound (enclosure) — Grokipedia](https://grokipedia.com/page/Compound_(enclosure))
- [Nucleated village — Grokipedia](https://grokipedia.com/page/Nucleated_village)
- [Indigenous peoples of the American Southeast — Settlement patterns and housing (Britannica)](https://www.britannica.com/topic/Indigenous-peoples-of-the-American-Southeast/Settlement-patterns-and-housing)
- [The spatial patterns of Tswana stone-walled towns in perspective (academia.edu PDF)](https://www.academia.edu/108634796/The_spatial_patterns_of_Tswana_stone_walled_towns_in_perspective)

## GAP

- Text/diagram sources only — no photo identity to pull hex colors from (not
  applicable to this topic; colors still come from `village_palisade`,
  `village_watchtower`, `rocks` per-material synthesis docs as before).
- Did not source an Oceanic/Pacific example directly (search returned mostly
  African + American hits for the non-European query) — the West African +
  American Southeast pair was judged sufficient cross-check (2 independent
  non-European traditions + the European baseline = 3 total), but a Pacific
  example would strengthen this further if revisited.

---

## Addendum — Joan's 5-reference drop: merchants, animals, foundations (2026-07-20)

Joan pasted 12 real images across Skyrim, DanMachi, LOTR (new, own folder
`village_lotr/`), plus real-world photos, and asked for Axlin's TEXT since no
photos exist for it. Images now live IN THIS FOLDER (see table below) —
eyeballed directly, not summarized from memory.

### Images added

| File | Reference | What it shows |
|---|---|---|
| `skyrim_rpg_map_lakeside_village.png` | Skyrim (fan RPG map) | Top-down: lake, bridges, forest, houses clustered organically along water — NOT a ring |
| `skyrim_whiterun_marketplace_stalls_well.png` | Skyrim (Whiterun) | Market stalls w/ cloth awnings around a central WELL, barrels, longhouses behind |
| `minecraft_waterfront_village.png` | Minecraft build | Multi-story waterfront row houses, boats docked, vertical density |
| `danmachi_market_street_awnings_aerial.png` | DanMachi (Orario street) | Stone-paved street, colored cloth awnings directly on the street, top-down |
| `danmachi_18f_night_lanterns_under_tree.png` | DanMachi 18F | Dense town under giant tree roots, hundreds of warm window-lights at night |
| `real_troglodyte_stone_chimney_village.png` | Real photo (cave village, Spain) | Houses dug into a hillside — only stone chimneys + doorways poke out of grass |
| `sketch_stone_cottage_row.png` | Pencil sketch | Row of stone cottages, steep multi-gabled roofline, single chimney anchoring the row |

See `village_casona/skyrim_ingame_longhouse_rocks_palisade.png` (same drop):
palisade with cone-tipped stakes, scaffolding watchtower, and — new detail —
**garden plots visible right next to the entrance**, not buried deep inside.
See `village_lotr/_synthesis.md` for the Hobbiton + LOTR-market images.

### Qué se VE — puntos en común

**Mercado/comercio (Skyrim + DanMachi):** the market is NOT a building — it's
cloth AWNINGS over stalls clustered at the highest-traffic point (the well in
Whiterun, the main street in DanMachi), each stall a DIFFERENT awning color,
barrels/baskets stacked visibly outside as "inventory lives outdoors."

**Densidad por luz, no por conteo (DanMachi 18F):** a settlement reads as
populous by how many WINDOWS glow warm at once — cheap and effective, doesn't
need more geometry.

**Casas — quiebre múltiple de techo (todas las refs):** roofs are always
taller/steeper than the walls beneath, with MULTIPLE ridge breaks per house
(annex, dormer, a second gable at a different height) — never one clean
single-pitch box.

**FUNDACIÓN — resuelve la duda de Joan** ("es medio raro encontrar cimiento de
cemento en una aldea tan chica"): `real_troglodyte_stone_chimney_village.png`
settles it — in a humble settlement the foundation IS the terrain itself (dug
into the hill), no separate cut-stone plinth. A tidy cut-stone-and-mortar
plinth (like our current casona) reads as WEALTH/status — correct for the ONE
casona, wrong for common huts. Common huts should get a poorer footing: loose
uncut fieldstones, packed earth, or a low timber sill — never the same clean
plinth as the casona. Same module-internal-coherence rule already established
(chicken coop size ↔ chicken count): here it's **settlement wealth ↔
foundation quality**, and today every house shares one plinth tier.

### Axlin (El bestiario de Axlin) — texto, sin fotos (confirmado, no inventado)

Extraído del mismo PDF oficial ya citado arriba en este documento:
- **Comercio = SOLO buhoneros itinerantes**, rarísimos, arriesgando la vida
  para viajar ENTRE enclaves — NO hay mercado interno permanente. Un enclave
  Axlin-puro se vería VACÍO de comercio comparado con Skyrim/DanMachi; esto es
  el extremo opuesto en el eje de amenaza (alta amenaza → cero mercado visible).
- **Animales**: lana de CABRA, mencionada explícitamente (calcetines
  protectores contra un monstruo) — ganado funcional, no decorativo.
- **Cultivo**: guisantes, cosechados por los NIÑOS como responsabilidad —
  la producción de alimento es trabajo diario, no un adorno de fondo.
- Sin mención textual de ovejas/cerdos/gallinas en el pasaje disponible — no
  se inventa esa atribución a Axlin; se puede usar igual por lógica agrícola
  genérica pero sin citarlo como fuente Axlin.

### Síntesis para el generador (v10)

1. **Mercado como módulo nuevo** (sorteado): 2-4 puestos con toldos de color
   variado en la plaza, barriles/canastos visibles. Peso alto si economía =
   agrícola/costera; peso bajo o CERO si amenaza = peligrosa (regla Axlin).
2. **Densidad por ventanas iluminadas** además del conteo de estructuras.
3. **Fundación por riqueza**: casona conserva el zócalo tallado; chozas comunes
   pasan a piedra suelta/tierra apisonada — nunca el mismo zócalo parejo.
4. **Techos multi-quiebre**: cumbrera más alta + anexo con su propio gable a
   otra altura, en la MISMA casa — no un solo prisma limpio.
5. **Cabras Axlin-coherentes**: si la economía es de amenaza alta/sin
   comercio, priorizar cabras (lana) por sobre ovejas genéricas.
