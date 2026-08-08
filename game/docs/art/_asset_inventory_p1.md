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

> **CORRECCIÓN (2026-08-07, mismo día).** La primera versión de este inventario trató
> "hecho con el motor" como binario. **No lo es.** `_motor_tiers.md` define tres niveles
> medibles (M1/M2/M3) y ya tiene la asignación hecha. Un `.glb` puede ser M3 (`rock_pack`)
> o M1 (`wasp`, que llega **blanco** al juego porque su color vive en nodos de shader que
> glTF descarta). **Para decidir qué se rehace, mandan los tiers, no la extensión.**
>
> Regla vigente de ese doc: *"Ningún asset entra al juego en M1"*, y *"todo asset nuevo
> arranca en M3"*.

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

### Generadores que existen pero NO están cableados — y en qué tier están

**CORREGIDO.** La primera versión de esta sección decía "correr estos siete, puede haber
trabajo hecho". Joan lo refutó de memoria y `_motor_tiers.md` le da la razón en 6 de 7:
son de la época en que el motor todavía no tenía las técnicas que hoy son estándar, y
**llegan blancos al juego**.

| generador | tier | veredicto |
|---|---|---|
| `golem_guardian/build_golem_guardian.py` | **M3** | **CABLEAR.** 2182 líneas, FLOAT_COLOR con el fix de sRGB, roca noise-displaced, animación con curvas de cascada (peso y lag). El cuervo del juego sigue siendo primitivas mientras esto existe hecho. |
| `rat/build_rat.py` | M1+ | rehacer — BYTE_COLOR, tonos ~12× oscuros |
| `snake/build_snake.py` | M1 | rehacer — buena geometría (spine+loft paramétrico), VCOL ausente |
| `turtle/build_turtle.py` | M1 | rehacer — shape keys maduras, VCOL ausente |
| `bird_prey/build_bird.py` | M1 | rehacer — loft real en pico y ala, VCOL ausente |
| `wasp/build_wasp.py` | M1 | rehacer — primitivas + card de ala; Joan además la marcó por escala |
| `golem_floating/build_golem.py` | M2 | rehacer — BYTE_COLOR, anterior al fix |

La lección: **la existencia de un script no dice nada sobre su tier.** Verificar contra
`_motor_tiers.md` antes de proponer rescatar código viejo.

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

## PURGA M3 ejecutada (2026-08-07)

Directiva de Joan: *"eliminamos todos los modelos que no son M3"*, *"todo esto trabajando
con el motor en máximo rendimiento"*.

**Método**: la vegetación de scatter se saca de los pools; NO se reemplaza por cubos. Son
miles de instancias y un bosque de cubos contradice el objetivo del mismo pedido (*"que se
vea bien, que sea bonita"*). Los props únicos y contados sí van a cubo marcado — esa parte
está **pendiente**.

### Reemplazos (el rol se mantiene, cambia la fuente)

| era | pasa a | por qué |
|---|---|---|
| `env_grass_small_01.gltf` (alfombra MultiMesh, **~193 000 briznas**) | `env_grass_lawn_dense_01` + `env_grass_wispy_seedhead_01` | el elemento más visible de la pradera salía de un CC0. Dos mallas en vez de una: el MultiMesh reparte, así que deja de ser un solo tufo clonado |
| `env_tree_common_01.gltf` (árbol gigante) | `env_tree_prairie_wide_01` | el tree_pack lo construyó como *"shade tree in clearings, deliberately rare/standout"* — mismo rol de hito |
| `env_pebble_round_01` + `prop_rock_small_01` (ribera) | `env_river_rock_river_dry_01` + `_wet_01` | el river_pack se construyó PARA la orilla: seco contra mojado partido por cara |
| `env_grass_small_01` escalado alto como junco | `env_river_reed_clump_01` | había un junco de verdad sin usar |
| `prop_rock_large_01` | `prop_rock_boulder_large_01` | "el huevo" → Perlin doble capa |
| `env_clover_01` | `env_grass_lawn_dense_01` | mismo nicho de mata baja al ras |
| `env_bush_01` + `env_bush_small_flowers_01` (ribera) | `env_bush_flowering_01` + `_low_01` | bush_pack M3 |

### Bajas sin reemplazo — deuda REAL que el motor tiene que cubrir

1. **Especie de árbol tolerante a la sombra.** Se fueron los 7 slots de maple, que eran el
   sotobosque (`shade [0.3, 1.0]`). Las 5 especies del tree_pack **no cubren ese extremo**:
   hoy el scatter reparte a ciegas bajo copa. Es la baja que más se nota.
2. **Especie de copa ancha / color otoñal.** Se fueron 3 common + 2 birch. El mapa perdió
   el rojo — comparar los renders del `entrance_capture` antes y después.
3. **Árbol muerto** (`_scatter_dead_trees` se saltea sola).
4. **Hongo de repisa** y **hongo de sotobosque** (`_scatter_understory_mushrooms` idem).

Cuando lleguen, hay que **devolverles su entrada en `FLORA_NICHES`** o el scatter los
reparte sin nicho.

### Gotcha de GDScript que costó una ronda

Poner `const SCENE_X: PackedScene = null` y después llamar `SCENE_X.instantiate()` —aunque
sea dentro de un ternario que nunca ejecuta esa rama— hace que el analizador intente
resolver el método builtin en tiempo de análisis y escupe **16 × `Parameter "method" is
null`** sin backtrace útil en `validate.ps1`. La const se pliega. **Copiar la const a una
variable local corta el plegado.** Y el error aparecía atribuido a `entrance_capture.gd:53`,
no al archivo culpable: hizo falta comparar con y sin cambios (`git stash`) para saber
siquiera que era propio.

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
