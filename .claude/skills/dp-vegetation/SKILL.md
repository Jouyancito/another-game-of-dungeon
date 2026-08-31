---
name: dp-vegetation
description: Contexto del dominio vegetación de Dungeon Party — árboles, arbustos, pasto, flores, hongos y juncos del piso 1. Qué tiene que cumplir una especie, cómo se construye, qué refs cargar antes, dónde se cablea y qué deuda hay abierta. Lo carga el hook domain-context-router; también sirve invocarla a mano al tocar vegetación.
---

# Dominio: Vegetación (piso 1 — Pradera)

Este archivo es el índice curado del dominio. No copia el canon: apunta a él y fija
las reglas duras que se olvidan entre sesiones. Verificado contra el código el
2026-08-08 — si algo acá contradice al código, **manda el código** y hay que
corregir este archivo en el mismo commit.

## Regla 0 — cargar referencias antes de construir

Convención obligatoria de Joan (2026-06-14). Antes de modelar/renderizar/iterar,
leer el `_synthesis.md` **y las imágenes** de los topics que apliquen, bajo
`game/docs/art/_references/`:

| Topic | Para qué |
|---|---|
| `tree_poe/` | silueta y masa de árbol, escala PoE/Valheim |
| `foliage_painterly/` | tratamiento de hoja y color de follaje |
| `prairie_ecology/` | qué crece dónde y por qué |
| `prairie_terrain/` · `prairie_rivers/` | contexto de suelo y orilla |
| `nature_anim_style/` | movimiento de follaje (viento) |
| `vine/` | enredaderas y trepadoras |

Si ninguna referencia cubre lo pedido: decirlo explícito, construir desde el corpus
y **registrar el gap** en la carpeta del topic. No inventar en silencio.

## Regla 1 — todo asset nuevo nace M3

Purga del 2026-08-07, directiva de Joan: *"eliminamos todos los modelos que no son
M3"*. Salió del scatter todo lo CC0. Los tiers mandan sobre la extensión del
archivo — canon en `game/docs/art/_motor_tiers.md`.

Consecuencia práctica: **no se repone variedad bajando un pack**. Se construye con
el motor. Un asset CC0 en el scatter del piso 1 hoy es un bug, no un placeholder.

## Regla 2 — una especie no existe hasta estar en los tres lugares

Cablear una especie nueva toca `game/scenes/levels/floor1_prairie.gd` en tres
puntos, y saltarse el tercero es el error silencioso del dominio:

1. **El pool** — `POOL_TREES` / `POOL_BUSHES` / `POOL_GROUND`. El peso se expresa
   duplicando el `preload()`: 4 slots de `env_tree_prairie_mature_02` = generalista
   dominante; 1 slot de `env_tree_prairie_old_02` = rareza deliberada. La tabla
   fuente vive en `build_tree_pack.py` (`PLAN`) y el cableado en `wire`-time.
2. **El nicho** — `FLORA_NICHES`, dict indexado por `resource_path` (no por
   identidad de `PackedScene`, que se rompe con los slots duplicados). Valores
   `{"humidity": [min,max], "shade": [min,max]}` en escala 0..1, donde
   `humidity 1` = al borde del agua y `shade 1` = bajo copa.
3. **La pasada de scatter** que la coloca. La mayoría va por `_pick_flora_for_point`;
   las excepciones tienen pasada propia (`_scatter_dead_trees`,
   `_scatter_understory_mushrooms`) porque su regla de sustrato es más específica
   que una consulta de humedad/sombra.

**Sin entrada en `FLORA_NICHES` el scatter la reparte a ciegas** con peso neutro —
uniforme, como si el sistema de nichos no existiera. No tira error. Es la falla
callada más cara del dominio.

## Regla 3 — coherencia ecológica antes que variedad

Canon: `game/docs/_world_coherence.md` y `game/docs/procedural_ecology.md`. Una
especie se justifica por el nicho que ocupa, no por sumar formas distintas. Antes
de proponer una, decir **qué banda de humedad/sombra queda descubierta hoy**.

## Estado real del pool (verificado 2026-08-08, post-taxonomía)

**Dos ejes, no uno.** Hasta hoy la tabla mezclaba especies con estadios: cuatro
variantes compartían corteza, atlas de hoja y tints —eran un mismo árbol en cuatro
formas— y `young` era literalmente un estadio archivado como especie.

- **ESPECIE = materiales.** Corteza, atlas de hoja y rango de valor del follaje.
  Dos especies se distinguen paradas una al lado de la otra, a la misma edad.
- **ESTADIO = forma en el tiempo.** Mismos knobs, otros valores: un brinzal tiene
  tronco fino, copa estrecha y cero muñones; un viejo tiene copa aplanada y
  asimétrica, tronco grueso y muchos muñones.
- **Dentro del estadio, la altura es un RANGO**, muestreado en N instancias. Eso
  cubre el patrón §17.2.4 (variación por instancia), el único que la auditoría de
  `tree_poe` tenía abierto.

| Especie | Corteza / hoja | Estadios (instancias) | Alturas construidas |
|---|---|---|---|
| **prairie** | gris-violácea / verde | young (2) · mature (3) · old (2) · ancient (1) | 2.53–22.06 m |
| **dry** | cálida / dorada | young (1) · mature (2) | 2.79–6.35 m |
| **shade** | oscura azulada / verde oscuro | young (1) · mature (2) | 2.63–6.28 m |
| **autumn** | cálida clara / **rojo óxido** | mature (2) · old (1) | 7.42–13.54 m |

17 GLB, 29 slots de pool. Todos ≤800 tris (máx 750).

### Las dos reglas duras de la taxonomía

1. **La altura no es escala libre.** Bajo auto-semejanza elástica el diámetro debe
   crecer como altura^1.5, así que `crown_dbh_ratio` se deriva de la altura y no es
   constante. Escalar un GLB uniformemente le deja el tronco flaco para su porte:
   así se veía el `giant_tree`, que era un árbol de 8.57 m inflado ×4.5 a 38.6 m.
   **Nunca escalar un árbol para agrandarlo — construirlo a su altura.**
2. **La alometría se aplica DENTRO del estadio.** Medida contra un adulto de
   referencia, los brinzales salieron con crown/DBH de 50×. La ley vale entre
   adultos; un brinzal es una vara flexible, no una columna.

### El techo de altura es una decisión de diseño

Las colinas topan en `TERRAIN_MAX_HEIGHT = 16 m`, subido de 9 la sesión pasada
para que el terreno ocluya. Los árboles comunes se quedan **debajo** para que la
tierra siga decidiendo qué ve el jugador; el tope común es 15.08 m. Los 22 m son
exclusivos del `ancient`, que es hito de navegación.

### El detalle que hace que un bosque se lea como bosque

En `FLORA_NICHES`, **el brinzal de una especie tolera más sombra que su adulto** —
las plántulas germinan bajo la copa de sus padres. Con esa sola banda corrida, el
scatter planta la regeneración debajo de los árboles grandes por su cuenta, sin
pasada dedicada.

### Altura resuelta, no predicha

`solve_height()` construye, mide el bmesh y corrige, hasta 4 pasadas. Una constante
de corrección calibrada a mano se rompe cada vez que cambiás la receta de copa: pasó
dos veces hoy — un "15 m" salió 17,28 y un "12 m" salió 10,98, empatado con un
maduro. **No calibres la constante: medí el resultado.**

## Deuda abierta — leer antes de proponer trabajo nuevo

Registro vivo en `game/docs/art/_asset_inventory_p1.md`.

- ~~**Nicho de sombra descubierto.**~~ **SALDADO 2026-08-08**: la especie `shade`
  cubre `shade [0.3,1.0]` con 3 instancias. Falta lo único que ningún número
  reemplaza: que Joan la vea plantada en el build.
- **Los otros tres packs no migraron.** `bush_pack`, `flower_pack` y `grass_pack`
  siguen flat-shaded sin texturas, en la familia que `_art_canon.md` §17 declara
  enterrada. `tree_pack` fue el piloto y quedó solo.
- ~~**Falta copa ancha / color otoñal.**~~ **SALDADO 2026-08-08** con la especie
  `autumn` (atlas de hoja rojo óxido propio, 3 instancias entre 7.42 y 13.54 m). El
  rojo volvió al mapa. Verificado en el lineup; falta verlo plantado.
- **Tres constantes en `null`**, con sus pasadas salteándose solas: `SCENE_DEAD_TREE`,
  `SCENE_LAETIPORUS`, `SCENE_MUSHROOM_COMMON`. No reemplazar por cubos — son decenas
  de instancias de scatter y un bosque de cubos contradice el objetivo.
- **Cero cobertura de tests.** Ningún archivo de `game/tests/unit/` toca vegetación
  (verificado 2026-08-08). Toda validación del dominio hoy es ojo humano en el build.

## Cómo se construye una especie

Los builders viven por pack en `game/tools/blender/<pack>/build_<pack>.py`
(`tree_pack`, `bush_pack`, `grass_pack`, `flower_pack`, `river_pack`, `rock_pack`),
con `_tex/`, `renders/` y su `truth_showcase.py` al lado. El motor compartido está
en `C:\Users\the_j\motor-blender`. Para el pipeline headless de bpy, los gotchas de
Blender y el contrato de estilo `DP_ToonGrounded`, cargar la skill
`blender-asset-smith` — este archivo no lo duplica.

Antes de dar una especie por lista: render de verdad, no viewport. `art-ref-critic`
para el veredicto visual, con número al lado.

## Canon del dominio

- `game/docs/biome_prairie.md` — el bioma
- `game/docs/prairie_living_world.md` — mundo vivo
- `game/docs/procedural_ecology.md` — modelo ecológico
- `game/docs/_prairie_environment_rework.md` — historia del rework
- `game/docs/art/_motor_tiers.md` — M1/M2/M3
- `game/docs/art/_asset_inventory_p1.md` — inventario y deuda
- `game/docs/art/_art_canon.md` §17 — escalera DnD→PoE1→PoE2, modelo Valheim

Para consultas amplias del canon conviene Calyx antes que abrir diez docs:
`python E:\Calyx\home\ingest\ask.py kernel "..."`.

## Mantenimiento

Si al trabajar el dominio descubrís una regla dura nueva, un nicho que cambió o una
deuda saldada, actualizá este archivo en el mismo commit. Es un documento vivo: su
valor es que la próxima sesión no vuelva a derivar todo esto desde cero.
