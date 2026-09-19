# Village Expansion Canon — from static POI to living settlement

**Status**: DRAFT (2026-07-18). Grounds the `village_gen.py` (Blender motor)
iteration in the game's existing macro-world canon so the visual work and the
future systems work don't diverge. Written per PO request during the
"living village" pass (Joan, 2026-07-18) — same filter as everything else in
this repo post scope-reset: *"¿esto acerca o aleja de los 5 mapas
publicables?"* This doc is the BRIDGE plan, not new lore — every mechanic
below already exists as a seed in `game/docs/lore/_world_seeds_postalpha.md`;
this doc says HOW a village specifically expresses it.

## 1. Grounding — this is not new lore, it's an application of existing seeds

`_world_seeds_postalpha.md` §0 already defines the macro model that this
canon depends on:

- **Descubrimiento → Conquista → Civilización**: a zone starts wild
  (discovery), gets a local zone-boss (conquest), and — once a tier is
  meaningfully overleveled by the server's collective progress — civilization
  moves in and *visibly changes the floor* (roads, colonized territory).
- **World-state is collective and per-server (Valheim model)**: floor
  changes are not per-player instance state, they are SERVER progress. A
  fresh server sees floor 1 in "discovery." An old, active server may already
  show floor 1 partway into "civilización."
- **Piso 1 = discovery, by design, for the alpha.** The seeds doc is explicit:
  *"NO meter sendero/civilización ahora — todavía no entró."* This canon
  respects that boundary completely — see §4.

The village generator (bandit camp today, "aldea" + "destacamento" from this
pass) is the ASSET LAYER for the civilización phase whenever it eventually
turns on. Building the asset now (visual only) does not violate the alpha
boundary; wiring it to WorldState/missions would.

## 2. The loop (post-alpha target — RDR2-camp-style)

Mission → upgrade → visible expansion, in a loop:

1. **Mission** — party completes a quest/task tied to a village (defend it
   from a raid, clear a threat, deliver resources, escort a caravan).
2. **Upgrade** — the mission's outcome banks progress into that village's
   (or the floor's) WorldState. Progress is measured in whatever currency the
   design settles on later (resources, "trophies" per the seeds doc's
   Valheim-style boss-trophy precedent, or a simpler completion counter) —
   NOT specified here; this doc only commits to the LOOP shape, not the
   economy, per the "don't decide scope-expanding numbers in a feel doc" rule
   already established for `_world_seeds_postalpha.md`.
3. **Visible expansion** — WorldState crossing a threshold triggers a
   generator re-roll or a scripted swap: the village's `MODULE_POOL` rolls
   fresh (or specific modules unlock — e.g. a `granary` guaranteed once
   "food security" is banked), `SCALE` can step up (a `destacamento` earning
   enough progress could graduate toward `aldea`-adjacent density), or a
   `THREAT` profile's defenses visibly harden (more torches, a reinforced
   gate) as a direct response to repelled raids.
4. Loop closes — the new state opens new missions (defend the now-bigger
   village, its new granary needs guarding, etc).

This is the same shape as the seeds doc's civilización phase (§0: "coloniza:
construye carreteras... lo conquistado se vuelve tránsito seguro") applied at
village scale instead of floor scale — a village is a LOCAL instance of the
same macro pattern.

## 3. Two-tier floor-1 structure

`village_gen.py`'s `SCALE` axis is not just a render convenience — it maps
directly onto the eventual gameplay structure:

- **`destacamento`** (small outpost, 2-3 structures + wall fragment + tower):
  the SCATTER unit. Many of these exist across a floor as minor POIs/threats
  — a bandit patrol camp, a scouting post, a resource-harvesting stub. Low
  commitment to clear, low reward, but numerous — they're the floor's
  texture.
- **`aldea`** (main settlement, full functional zoning: commons, residential,
  garden, livestock, crafts, well): the ANCHOR. A floor has FEW of these
  (plausibly one primary `aldea` per floor for the alpha's single P1 map),
  and it is the mission hub — the place WorldState visibly accumulates and
  where the mission→upgrade→expansion loop plays out.

A `destacamento` clearing/converting into (or spawning near) an `aldea`'s
growth is the natural narrative bridge between the two tiers, mirroring
`_world_seeds_postalpha.md` §9's already-seeded idea of bandit camps
"rotating position" as world-state activity — a destacamento isn't
necessarily permanent set-dressing, it can be a live, disposable unit.

## 4. Staged delivery — ALPHA vs POST-ALPHA (hard boundary)

**ALPHA (in scope now — ships in the 10-min demo video)**:
- Visual village generation only: `village_gen.py` biome x threat x scale,
  settlement-logic layout, doors/windows/stairs, module-pool content variety.
- Multiple `destacamento`s scattered as POIs (replacing/extending the
  existing `bandit_camp`/`VillageBuilder` outpost prop).
- ONE `aldea` as a bigger, richer POI — still just a place to walk into and
  loot/fight, same as any other POI today. **No mission hooks, no WorldState
  read/write, no persistence beyond the seed.**
- This matches `_world_seeds_postalpha.md`'s explicit floor-1 boundary:
  discovery-phase only, no civilización mechanics live yet.

**POST-ALPHA (this canon's real payload, NOT built now)**:
- Mission system hook: a quest type that targets a specific village instance.
- WorldState schema for a village: what progress is tracked, how it maps to
  `MODULE_POOL` re-rolls / `SCALE` graduation / `THREAT` response.
- Netcode consequence: per `_world_seeds_postalpha.md` §0's explicit
  warning, persistent collective world-state touches network topology
  (today P2P GodotSteam co-op) — **consult `netcode-architect` before
  implementing**, this is not a decision made in a design doc.
- Integration with the Descubrimiento→Conquista→Civilización floor-level
  model: does a village's local growth GATE or simply FLAVOR the floor's
  phase transition? Open question, not resolved here.

**Anti-pattern to watch (inherited from the seeds doc's own closing
warning)**: don't let "giving the village a growth system" become an excuse
to build the mission/WorldState machinery now. The alpha filter applies
identically here: if it doesn't change what the 10-minute demo video shows,
it stays in this doc, not in code.

## 5. Module pools — schema (implementation detail, canonized here too)

Village CONTENT (as opposed to structure/layout) is generated from a
weighted catalog rolled once per village from the seeded RNG, decoupled from
WHERE things go (that's settlement logic, §6). This is the same shape a
mission-driven unlock would eventually hook into (§2 step 3) — a future
"upgrade" event is just a re-roll with adjusted weights or a forced
inclusion, not a new mechanism.

```
MODULE_POOL = {
  "aldea": [
    {"name": "well",           "weight": 0.90},
    {"name": "garden",         "weight": 0.60, "count_weights": {1: 0.6, 2: 0.4}},
    {"name": "livestock_pen",  "weight": 0.45},
    {"name": "crafts_area",    "weight": 0.30},
    {"name": "granary",        "weight": 0.25},
    {"name": "extra_house",    "count_weights": {0: 0.05, 1: 0.35, 2: 0.45, 3: 0.15}},
  ],
  "destacamento": [
    {"name": "bunk_hut",         "weight": 0.70},
    {"name": "third_structure",  "weight": 0.35},
  ],
}
```

`central`/`hut_storage`/`hut_kitchen`/`hut_outhouse` (aldea) and `dest_tent`
(destacamento) are NOT in the pool — they are mandatory identity per Joan's
2026-07-18 round-1 feedback (a village needs hearth/kitchen/storage/outhouse
to read as functional, non-negotiably). The pool governs everything added
this pass on top of that floor.

## 6. Settlement logic — why layout isn't random (research summary)

Full citations + cross-check methodology:
`game/docs/art/_references/village_settlement_logic/_synthesis.md`.
Cross-checked medieval-European nucleated villages, West African compound
settlements, and American Southeast ceremonial towns — three structurally
unrelated traditions that converge on the same rule: **communal functions
(well, hearth, plaza, crafts, worship) cluster toward the center; private/
residential space sits farther out toward the edge.** `village_gen.py`
implements this as concentric radius BANDS (`commons_r` → `residential_lo`/
`residential_hi` → wall), with the module pool deciding WHAT exists inside
each band and randomness only jittering position within it.

## 7. Climate-conditioned architecture — research summary

- [Vernacular Architecture Around the World: Key Examples (archthread)](https://archthread.com/vernacular-architecture-around-the-world/)
- [Understanding Vernacular Architecture: A Beginner's Guide (ArchitectureCourses.org)](https://www.architecturecourses.org/learn/vernacular-architecture)
- [Elements of the Classic Southern Porch (Houzz)](https://www.houzz.com/magazine/elements-of-the-classic-southern-porch-stsetivw-vs~108558336)
- [Back to the Future: Traditional Architectural Design Features that Beat the Heat (Formaspace)](https://formaspace.com/articles/industrial/traditional-architectural-design-features-that-beat-the-heat/)

Warm regions (prairie/floor-1) favor open, airy, semi-outdoor structures —
porches/verandas, big window openings, open-air food/hide preservation
(drying racks). Cold regions favor compact, insulated forms with small,
protected openings. Baked into `STYLES[biome]` as `window_scale`,
`porch_chance`, `drying_rack`, `stone_base_chance` — see `village_gen.py`
module docstring §"Climate-conditioned architecture" for the exact mapping.

## 8. Axlin threat axis — schema (Joan's favorite principle)

Sourced from `game/docs/art/_references/bandit_camp/_synthesis.md`
("El bestiario de Axlin," Laura Gallego — enclaves differ by local threat).
`village_gen.py`'s `THREAT_PROFILES`:

```
THREAT_PROFILES = {
  "ground_beasts":    {"wall_h_mult": 1.15, "gate_reinforced": True,  "torch_ring": False, "covered_plaza": False},
  "flyers":           {"wall_h_mult": 1.0,  "gate_reinforced": False, "torch_ring": False, "covered_plaza": True},
  "night_predators":  {"wall_h_mult": 1.10, "gate_reinforced": False, "torch_ring": True,  "covered_plaza": False},
}
```

Each floor-1 biome defaults to the profile that fits its existing bestiary
identity (`DEFAULT_THREAT_BY_BIOME`): pradera → `ground_beasts` (bandit/
golem/slime foot-traffic), bosque → `flyers` (bird/hawk canopy predators,
already in the P1 bestiary), hielo → `night_predators` (wolf + Dawnstar/
Irithyll night mood). Post-alpha, a village's ACTUAL nearby spawn table
should drive this choice directly instead of a biome default — that wiring
is deferred to whenever bestiary-per-POI logic exists.

## 10. Module-internal coherence rule (PO addendum, 2026-07-18)

Every module must self-agree with real-world logic at its OWN scale — a
large module implies MORE of its contents, a small one fewer; a vocation
prop never appears alone without its supporting detail. Examples: a big
chicken coop contains many chickens, a small one few; a garden's crop-bed
count matches its plot rows; a forge implies visible fuel/ingots next to the
anvil, not just the anvil. This rule governs any module a pass TOUCHES — it
is not a mandate to retroactively rewrite every existing module the moment
it's written down. First application: the casona/roofs pass (2026-07-18)
wired `build_crafts_area`'s `herreria`-economy variant to add a fuel/ingot
pile next to the anvil (§11) — `build_livestock_pen` (pen size already
implies its 2-3 animal count range) and `build_garden` (bed count already
matches its fixed row/col grid) already satisfied the rule and were left
untouched.

## 11. Economy/vocation axis — 5th generator input (PO principle 5, 2026-07-18)

    BIOME x THREAT x SCALE x SEED (module rolls) x ECONOMY (vocation)

A village's livelihood shapes its structures/props/permanence independently
of biome or threat — a herrería reads different from a nómada camp even in
the same biome. `village_gen.py`'s `ECONOMY_PROFILES`:

```
ECONOMY_PROFILES = {
  "agricola": {"crafts_weight_mult": 1.0, "prop_tag": None,         "permanence": "permanent"},
  "herreria": {"crafts_weight_mult": 1.8, "prop_tag": "metal",      "permanence": "permanent"},
  "pieles":   {"crafts_weight_mult": 1.0, "prop_tag": "hide",       "permanence": "permanent"},
  "nomada":   {"crafts_weight_mult": 0.6, "prop_tag": "hide_tent",  "permanence": "temporary"},
  "costera":  {"crafts_weight_mult": 1.0, "prop_tag": "nets_boats", "permanence": "permanent"},
}
```

- **`agricola`** (default for all 3 biomes today) — current behavior,
  zero-op. This is the only economy every existing render exercises unless
  the CLI's 6th positional arg overrides it.
- **`herreria`** (iron-working) — the one extra economy WIRED this pass
  (cheapest real hook available without derailing the casona/roof focus,
  and thematically fits bosque/Irontown): boosts `crafts_area`'s presence
  weight (a forge village is far more likely to actually have a forge) and
  adds a fuel/ingot prop next to the anvil per the coherence rule (§10).
- **`pieles`** (hide/pelt trade), **`costera`** (fishing — boats/nets/racks)
  — schema-only stubs, `prop_tag` documents the intended dressing, not yet
  wired to a builder.
- **`nomada`** (temporary hunting camp) — schema-only stub, but its
  `permanence: "temporary"` flag is a DELIBERATE forward-looking note: a
  nomad camp should be able to relocate/vanish under the future WorldState
  model (§2-4), unlike a permanent aldea. Not implemented, but the schema
  slot exists so a future pass doesn't have to invent the axis from scratch.

Future passes wire `pieles`/`nomada`/`costera`'s `prop_tag` into the
relevant module builder the same way `herreria` hooks `build_crafts_area`.

## 12. Threat INTENSITY — how much, not just what (PO addendum, 2026-07-18)

`THREAT_PROFILES` (§8) answers WHAT a village defends against; `village_gen.py`'s
`INTENSITY_PROFILES` answers HOW MUCH — a calm prairie does not justify a
10m fortress wall:

```
INTENSITY_PROFILES = {
  "calm":      {"wall_h_mult": 0.50, "stake_count_mult": 0.40, "ring_coverage_mult": 0.55, "gate_heavy": False},
  "wary":      {"wall_h_mult": 1.00, "stake_count_mult": 1.00, "ring_coverage_mult": 1.00, "gate_heavy": True},
  "dangerous": {"wall_h_mult": 1.30, "stake_count_mult": 1.25, "ring_coverage_mult": 1.00, "gate_heavy": True},
}
```

`calm` scales down wall height, stake density, AND ring coverage (fences
only ~55% of the perimeter — a low boundary marker, not a stockade), and
drops the reinforced double-gate airlock for a single simple gate.
`DEFAULT_INTENSITY_BY_BIOME` keeps every biome at `wary` — today's exact
existing numbers (all multipliers 1.0) — so the default 3-positional-arg
CLI invocation renders byte-identical to before this axis existed. `calm`
is reachable via the 7th positional CLI arg and was smoke-tested this pass;
it is not part of the standard 3-biome audit render set.

## 13. Open questions for Joan

1. Does village growth GATE the floor's Descubrimiento→Conquista→
   Civilización transition, or just flavor it locally? (§4 post-alpha)
2. What currency banks WorldState progress — resources, boss trophies (per
   the seeds doc's existing Valheim precedent), or a simpler completion
   counter? (§2 step 2)
3. Should a cleared/upgraded `destacamento` be able to graduate toward
   `aldea` density, or are the two tiers permanently distinct asset classes?
   (§3)
4. Threat profile currently defaults per-BIOME — should it instead read the
   POI's actual nearby spawn table once that data exists? (§8)
5. Threat INTENSITY (§12) currently defaults every biome to `wary` — should
   intensity instead derive from a village's distance-to-danger (e.g. floor
   depth, proximity to a boss zone) once that data exists, the same open
   question as #4 but for HOW MUCH instead of WHAT?
