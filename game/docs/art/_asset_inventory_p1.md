# Inventario de assets — Piso 1 Pradera

Levantado 2026-08-07 a pedido de Joan: *"mostrarme todo lo que tú tienes en este juego
actualmente, diferentes pastos, diferentes flores, diferentes piedras, diferentes árboles,
ese tipo de cosas y sus variables. Lo mismo con los monstruos, el ambiente."*

Fuente: barrido de `game/assets/art/piso1_pradera/**`, `game/scenes/enemy/*.tscn` y las
referencias reales en `floor1_prairie.gd`. **Contado, no recordado.**

## La regla que ordena todo

| extensión | origen | cómo se regenera |
|---|---|---|
| `.glb` | **motor propio de Blender** | `game/tools/blender/<pack>/build_<pack>.py` |
| `.gltf` | **pack CC0 importado** (Kenney / Quaternius) | no se regenera — se reemplaza |

Se verificó pack por pack contra los generadores, no por convención de nombre.

---

## 1. Vegetación

### Árboles — 17 en disco, 17 usados

| variante | origen | estado |
|---|---|---|
| `env_tree_prairie_01` / `_tall_01` / `_wide_01` / `env_tree_young_01` / `env_tree_dry_01` | **motor** (`tree_pack`) | usados |
| `env_tree_birch_01..05` (5) | CC0 | usados 01 y 02; **03/04/05 muertos en disco** |
| `env_tree_maple_01..03` (3) | CC0 | usados |
| `env_tree_common_01..03` (3) | CC0 | usados |
| `env_tree_dead_01` | CC0 | usado |

**5 de 17 son del motor.** Coincide con lo que Joan vio en el playtest: *"de los tres
árboles del frente solo uno es hecho con el motor"*.

### Pastos — 7, seis del motor

`env_grass_lawn_dense_01`, `_wispy_seedhead_01`, `_broad_clump_01`, `_sparse_dry_01`,
`_windswept_01`, `_wildflower_mix_01` — **motor** (`grass_pack`), todos usados.
`env_grass_small_01` — CC0, usado como junco de ribera.

### Flores — 9 en disco, 6 usadas

**Motor** (`flower_pack`), las 6 usadas: `env_flower_pale_glow_01`, `_yellow_clover_01`,
`_bicolor_mix_01`, `_violet_cluster_01`, `_white_star_01`, `_tall_stalk_01`.

**CC0 excluidas a propósito**: `env_flower_clump_01..03` — cartas fotorrealistas de la era
caverna, quedaron fuera en BREAK #1 y no se reintroducen.

### Arbustos — 9 en disco, 7 usados

**Motor** (`bush_pack`): `env_bush_round_01`, `_large_01`, `_flowering_01`, `_low_01`,
`_dry_01` — los 5 usados.
CC0: `env_bush_01` y `env_bush_small_flowers_01` usados; `env_bush_flowers_01` y el
`.gltf` `env_bush_large_01` sin usar. **Los CC0 de arbusto son los que Joan pidió eliminar
tres veces** — ver `_asset_rework_queue.md` grupo A.

### Otros — hongos `env_mushroom_common_01` / `_laetiporus_01`, trébol `env_clover_01`,
guijarro `env_pebble_round_01`, parche `env_terrain_grass_patch_01`. Todos CC0.

## 2. Rocas — 9, seis del motor

**Motor** (`rock_pack`): `prop_rock_boulder_large_01`, `_boulder_mossy_01`,
`_cluster_broken_01`, `_outcrop_hollow_01`, `_scatter_pebbles_01`, `_slab_flat_01`.
CC0: `prop_rock_large_01`, `_small_01`, `_wide_01` — **estas son "el huevo"** que Joan
marcó en el playtest. Brief de roca irregular en `_asset_rework_queue.md` grupo C.

## 3. Agua — 5, todas del motor

`river_pack`: `env_river_reed_clump_01`, `_reed_clump_small_01`, `_rock_river_dry_01`,
`_rock_river_wet_01`, `_rock_river_wet_cluster_01`.

## 4. Cristales — 3 del motor, 1 usado en el piso 1

`crystal_dp_single_01` (usado), `crystal_dp_cluster_01`, `crystal_amethyst_01`.

## 5. Enemigos — 28 escenas, **4 con malla**

Éste es el hallazgo grueso del inventario.

| escena | malla |
|---|---|
| `slime`, `mini_slime` | `slime_dp_01.glb` — **motor** |
| `king_slime` | `king_slime_dp_01.glb` — **motor** |
| `frog` | `enemy_frog.gltf` — CC0 |
| **los otros 24** | **ninguna — primitivas armadas en GDScript** |

Sin malla: `bandit_archer`, `bandit_leader`, `bandit_melee`, `bird`, `enemy_basic`,
`forest_watcher`, `fox`, `giant_moth`, `goat`, `golem`, `golem_assembly`,
`guardian_cuervo`, `hawk`, `jabali`, `jotun_giant`, `mimic_chest`, `rat`, `samum`,
`scorpion`, `snake`, `spider`, `turtle`, `wasp`, `wolf`.

Esto es exactamente lo que Joan reportó: *"del cuervo, siguen siendo una pelota con dos
alas, sin movimiento, sin nada"*.

### Generadores que existen pero NO están cableados

Hay script de motor terminado para enemigos que en el juego siguen siendo primitivas:

`bird_prey/build_bird.py` · `rat/build_rat.py` · `snake/build_snake.py` ·
`turtle/build_turtle.py` · `wasp/build_wasp.py` · `golem_floating/build_golem.py` ·
`golem_guardian/build_golem_guardian.py`

**Antes de modelar nada nuevo, correr estos y ver qué sale.** Puede haber trabajo hecho
esperando ser promovido — es más barato que rehacerlo. (Regla ponytail: verificar contra el
código antes de construir.)

Piezas de dressing del golem ya en disco (10): `golem_dp_body_01`, `_chunks_01`,
`_rock_chip_01`, `_moss_patch_01`, `_moss_tuft_02`, `_grass_clump_01`, `_branch_nest_01`,
`_flower_pink/white/yellow_01`.

## 6. Props CC0 — 29, ninguno del motor

`town/` 5 · `outpost/` 16 · `outpost_extras/` 8. Incluye las vallas y la torre que Joan
marcó como ilegibles (`_asset_rework_queue.md` grupo B).

---

## Resumen

| categoría | total | motor | CC0 | sin malla |
|---|---|---|---|---|
| Árboles | 17 | 5 | 12 | — |
| Pastos | 7 | 6 | 1 | — |
| Flores | 9 | 6 | 3 | — |
| Arbustos | 9 | 5 | 4 | — |
| Rocas | 9 | 6 | 3 | — |
| Agua | 5 | 5 | 0 | — |
| Cristales | 3 | 3 | 0 | — |
| Props | 29 | 0 | 29 | — |
| Enemigos | 28 escenas | 3 | 1 | **24** |

**El ambiente está mayormente hecho con el motor. Los enemigos casi no existen como
modelos.** Ahí está el desbalance.

## Pendientes que salieron de este inventario

1. **Medir el tamaño nativo de las flores del `flower_pack`.** El scatter las escala 0.7-1.6×
   (`_scatter_cluster(POOL_GROUND, ..., 0.7, 1.6, ...)`), que es un rango sano — así que si en
   el juego se ven *"del porte de un ratón"* (Joan, 2026-08-07), el problema es el tamaño con
   que salen del generador, no el scatter. **Medir antes de tocar cualquiera de los dos.**
2. **Correr los 7 generadores sin cablear** y ver qué hay antes de modelar enemigos nuevos.
3. **Densidad y variedad de pradera** contra las referencias en
   `_references/prairie_ecology/`. El sistema de nichos (`FLORA_NICHES`, humedad × sombra
   por especie) **ya existe y funciona** — no hay que construirlo, hay que subirle densidad
   y contraste de color.
4. **Los 3 birch CC0 muertos** (03/04/05) — o se cablean o se borran.
