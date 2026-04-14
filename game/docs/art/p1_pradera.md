# P1 Pradera — Art Package (Tier I, Piso 1)

**Estado**: Draft v1 — 2026-04-13
**Dept**: Art (worktree D — `dept/art/p1-pradera`)
**Base canon**: `game/docs/visual_bible.md` §P1, `game/docs/biome_prairie.md`, `game/docs/art_direction.md`, `game/docs/refs/p1_prairie/canon_main.jpg`
**Pipeline**: `game/docs/art_pipeline.md` (asset-first híbrido)

> Este doc junta **moodboard + paleta + lista completa de assets** de P1 en un solo lugar para que cualquiera (vos mañana, QA, otro dept) sepa qué se necesita fabricar. El **sourcing concreto** (links Kenney, qué va a AI, qué a Blender) vive en `p1_assets_sourcing.md`.

---

## 1. Concepto (una línea)

Campo verde DENTRO de una caverna colosal; un diamante gigante en el techo hace de sol artificial. Falsa seguridad: tranquilo y bonito, pero peligroso.

**Emoción objetivo**: asombro + nostalgia + calma que se rompe.
**Escala**: 600×600m. **Nivel jugador**: 1 → 2-3.

---

## 2. Moodboard / References

Canon oficial (imagen final a igualar):
- `game/docs/refs/p1_prairie/canon_main.jpg` — composición panorámica: outpost central, diamante arriba, god rays, cristales "vía láctea" en el techo, cascadas en los bordes.

Referencias externas de estilo (buscar en Google/Pinterest con estos keywords para inspiración, **no copiar**):
- **SAO Piso 1 (Aincrad)** — pradera abierta con horizonte artificial.
- **Valheim Meadows** — paleta verde pastel, árboles simples, low-poly legible.
- **Ragnarok Online — Prontera Fields** — flores dispersas, densidad media.
- **Metin2 — Map1** — caminos de tierra, outpost de madera.
- **Risk of Rain 2** — shape language low-poly + lectura instantánea a distancia.
- **Kimetsu no Yaiba (anime)** — luz volumétrica cálida + shape organicidad (filosofía visual del proyecto, ver `art_direction.md`).

**NO copiar**: cielo abierto con nubes. Acá el "cielo" es techo de roca + diamante + cristales emisivos.

---

## 3. Paleta (hex codes — fuente de verdad)

### Cálidos (dominan 60-70%)
| Hex | Uso |
|-----|-----|
| `#F5D576` | Dorado diamante emisivo (el "sol") |
| `#E8D4A0` | God rays cayendo |
| `#F5D8A0` | Luz direccional DirectionalLight3D |
| `#7B5A3C` | Madera del outpost, empalizadas |
| `#8C7856` | Tierra, caminos |

### Verdes (sostienen 20-25%)
| Hex | Uso |
|-----|-----|
| `#8FAE6B` | Verde pradera pastel (dominante del terreno) |
| `#6B8B3A` | Hierba iluminada alta |
| `#5C7A34` | Musgo denso sobre piedra |

### Fríos (acentos 10-15%)
| Hex | Uso |
|-----|-----|
| `#7A8FC4` | Azul-lavanda del techo (cielo interior) |
| `#A8D4E8` | Azul emisión cristales vía láctea |
| `#5C84A0` | Azul agua del lago |
| `#6B7C9E` | Gris-azul montañas lejanas |
| `#F5F5F2` | Blanco cascadas / espuma |

### Ambient / fog (Godot)
```
ambient_light_color = #B8C4D8   (azul-lavanda suave, energy 0.4)
fog_light_color     = #C8D4E0   (density 0.002)
background_color    = #B8C4D8   (solid, NO sky node)
```

**Regla 60/25/15**: cálidos / verdes / fríos. Si una screenshot rompe esa proporción, está mal iluminada.

---

## 4. Lighting canon (Godot 4.6)

```gdscript
DirectionalLight3D:
  rotation_degrees = Vector3(-75, -30, 0)    # diamante arriba-izquierda
  light_energy     = 3.5
  light_color      = Color(0.96, 0.85, 0.63) # #F5D8A0
  shadow_enabled   = true

WorldEnvironment:
  ambient_light_color  = Color(0.72, 0.77, 0.85)  # #B8C4D8
  ambient_light_energy = 0.4
  fog_enabled          = true
  fog_density          = 0.002
  fog_light_color      = Color(0.78, 0.83, 0.88)  # #C8D4E0
  background_mode      = CLEAR_COLOR
  background_color     = Color(0.72, 0.77, 0.85)
```

God rays = **firma visual** del Tier I. Obligatorios donde se vea el techo. Implementación: shader volumétrico o partículas grandes semi-transparentes apuntando al diamante (ver `shader_system.md`).

---

## 5. Lista completa de assets — P1

Formato: `[id] nombre — descripción — prioridad (P0/P1/P2) — ruta destino`
- **P0** = bloqueante para jugar el piso (sin esto no hay P1).
- **P1** = necesario para "piso terminado" (lista completa del GDD).
- **P2** = nice-to-have, puede esperar a post-MVP.

### Mapeo IDs → filenames (skill `kenney-quaternius-sourcer` canon)

Los IDs (T/V/N/H/S/E/D/FX/U) son **referencia interna del doc**. Los **filenames reales** siguen patrón `{prefix}_{descripcion_snake_case}.glb`:

| Categoría doc | Prefix filename | Ejemplo |
|----|----|----|
| T (terrain) | `env_` | `env_ground_grass.glb` |
| V (vegetation) | `env_` | `env_tree_oak_01.glb`, `env_grass_tuft_01.glb` |
| N (props naturales) | `env_` (rocas, cristales, dome) o `prop_` (cofres, etc.) | `env_rock_small_01.glb`, `prop_giant_diamond.glb` |
| H (props humanos) | `prop_` | `prop_chest_common.glb`, `prop_palisade_section.glb` |
| S (skybox) | `env_` | `env_cave_ceiling_dome.glb` |
| E (enemigos) | `enemy_` | `enemy_slime_green.glb`, `enemy_bandit_leader.glb` |
| D (deco fauna) | `enemy_` (subcarpeta `deco/`) | `enemy_butterfly_01.glb` |
| FX | `fx_` | `fx_god_rays_volumetric.tres` |
| U (UI diegético) | `prop_` | `prop_portal_entrance.glb` |

**Variantes**: usar sufijo numérico `_01/_02/_03` (canon skill), NO `_a/_b/_c`.

### 5.1 Terreno / tiles

| id | asset | desc | prio | destino |
|----|-------|------|------|---------|
| T01 | `ground_grass` | Tile hierba verde pastel, 2×2m, tileable | P0 | `game/assets/art/piso1_pradera/terrain/` |
| T02 | `ground_dirt_path` | Tile camino tierra, 2×2m, tileable | P1 | `terrain/` |
| T03 | `ground_stone` | Tile piedra ruinas, 2×2m | P1 | `terrain/` |
| T04 | `ground_rocky` | Tile zona rocosa/árida | P1 | `terrain/` |
| T05 | `ground_sand_shore` | Tile arena orilla lago | P2 | `terrain/` |
| T06 | `cliff_rock_face` | Pared acantilado borde mapa, 8×20m | P1 | `terrain/` |

### 5.2 Vegetación

| id | asset | desc | prio | destino |
|----|-------|------|------|---------|
| V01 | `grass_tuft_a/b/c` | 3 variantes tuft hierba (MultiMesh) | P0 | `vegetation/` |
| V02 | `flower_yellow` | Flor silvestre amarilla | P1 | `vegetation/` |
| V03 | `flower_white_daisy` | Margarita | P1 | `vegetation/` |
| V04 | `flower_blue` | Flor silvestre azul | P1 | `vegetation/` |
| V05 | `tree_oak_a/b/c` | 3 variantes roble bajo, 3-5m | P0 | `vegetation/` |
| V06 | `tree_willow` | Sauce llorón (orilla lago) | P1 | `vegetation/` |
| V07 | `bush_berry` | Arbusto de bayas (recolectable) | P1 | `vegetation/` |
| V08 | `bush_thorny` | Arbusto espinoso (colinas) | P2 | `vegetation/` |
| V09 | `reed_water` | Juncos orilla lago | P1 | `vegetation/` |
| V10 | `water_lily` | Nenúfar flotante | P2 | `vegetation/` |
| V11 | `fern` | Helecho (bosquecito) | P1 | `vegetation/` |
| V12 | `mushroom_common_a/b` | Hongos tronco (recolectable) | P1 | `vegetation/` |
| V13 | `ivy_wall` | Hiedra sobre muro (ruinas) | P2 | `vegetation/` |
| V14 | `moss_rock` | Musgo sobre roca (material) | P2 | `vegetation/` |
| V15 | `cactus_small` | Cactus enano (zona rocosa) | P2 | `vegetation/` |

### 5.3 Props — naturales

| id | asset | desc | prio | destino |
|----|-------|------|------|---------|
| N01 | `rock_small_a/b/c` | Rocas pequeñas dispersas | P1 | `props/rocks/` |
| N02 | `rock_medium_a/b` | Rocas medianas | P1 | `props/rocks/` |
| N03 | `rock_boulder` | Roca grande (cover combat) | P1 | `props/rocks/` |
| N04 | `log_fallen` | Tronco caído (cover bosquecito) | P1 | `props/rocks/` |
| N05 | `stump_tree` | Tocón | P2 | `props/rocks/` |
| N06 | `crystal_ceiling_a/b` | Cristales del techo (vía láctea), MultiMesh | P0 | `props/ceiling/` |
| N07 | `giant_diamond` | Diamante gigante del techo (hero asset, emisivo) | P0 | `props/ceiling/` |
| N08 | `waterfall_mesh` | Mesh cascada + shader translúcido | P1 | `props/water/` |

### 5.4 Props — humanos (outpost + ruinas + campamento)

| id | asset | desc | prio | destino |
|----|-------|------|------|---------|
| H01 | `wood_palisade_section` | Sección empalizada madera, 4m | P1 | `props/outpost/` |
| H02 | `wood_watchtower` | Torre vigía 8m | P1 | `props/outpost/` |
| H03 | `wood_gate` | Portón outpost | P1 | `props/outpost/` |
| H04 | `wood_house_small` | Casa pequeña outpost | P1 | `props/outpost/` |
| H05 | `chimney_smoke_emitter` | Chimenea + partículas humo | P1 | `props/outpost/` |
| H06 | `barrel_wood` | Barril (loot container) | P0 | `props/common/` |
| H07 | `crate_wood` | Caja madera (loot) | P1 | `props/common/` |
| H08 | `chest_common` | Cofre común (loot clave) | P0 | `props/common/` |
| H09 | `campfire_lit` | Fogata con partículas fuego | P1 | `props/common/` |
| H10 | `tent_cloth` | Tienda tela (campamento) | P1 | `props/common/` |
| H11 | `ruin_column_broken` | Columna rota antigua | P1 | `props/ruins/` |
| H12 | `ruin_wall_section` | Sección muro piedra roto | P1 | `props/ruins/` |
| H13 | `ruin_stairs` | Escalones piedra | P1 | `props/ruins/` |
| H14 | `ruin_floor_tile` | Piso piedra tallado | P1 | `props/ruins/` |
| H15 | `bandit_banner` | Bandera/estandarte bandidos (ruinas) | P1 | `props/ruins/` |
| H16 | `torch_wall` | Antorcha pared (sótano ruinas) | P1 | `props/common/` |

### 5.5 Skybox / techo de caverna

**No hay skybox tradicional**. El "cielo" se arma con:
- Background solid color `#B8C4D8` (canon).
- Plano/dome de techo con shader gradient (roca oscura + cristales emisivos MultiMesh).
- Diamante emisivo central (hero asset N07).
- Shader volumétrico de god rays.

| id | asset | desc | prio | destino |
|----|-------|------|------|---------|
| S01 | `cave_ceiling_dome` | Mesh dome techo de caverna (low-poly) | P0 | `skybox/` |
| S02 | `cave_ceiling_rock_material` | Material roca oscura techo | P1 | `skybox/` |
| S03 | `distant_mountains_billboard` | Montañas lejanas borde mapa (billboards) | P1 | `skybox/` |

### 5.6 Enemigos (arte) — lista definida por Game Design

Los GDs/stats viven en `biome_prairie.md` y `enemy_tier_system.md`. Acá solo lista de lo que Art tiene que fabricar.

| id | asset | desc | prio | destino |
|----|-------|------|------|---------|
| E01 | `slime_green` | Slime verde básico | P0 | `enemies/` |
| E02 | `slime_mini` | Mini slime (split) | P1 | `enemies/` |
| E03 | `slime_water_blue` | Slime agua variante | P1 | `enemies/` |
| E04 | `rat_small` | Rata sótano ruinas | P1 | `enemies/` |
| E05 | `fox_red` | Zorro bosquecito | P1 | `enemies/` |
| E06 | `wolf_gray` | Lobo pack AI | P1 | `enemies/` |
| E07 | `spider_small` | Araña telaraña | P1 | `enemies/` |
| E08 | `bird_crow` | Pájaro/cuervo | P1 | `enemies/` |
| E09 | `hawk` | Halcón colinas (ataque picado) | P2 | `enemies/` |
| E10 | `bandit_melee` | Bandido humanoide con espada | P0 | `enemies/` |
| E11 | `bandit_archer` | Bandido arquero | P1 | `enemies/` |
| E12 | `bat` | Murciélago (techo ruinas) | P2 | `enemies/` |
| E13 | `golem_rock` | Golem piedra (sub-C zona rocosa, Quaternius directo) | P1 | `enemies/` |
| E14 | `scorpion` | Escorpión zona rocosa | P2 | `enemies/` |
| E15 | `snake` | Serpiente grietas | P2 | `enemies/` |
| E16 | `bandit_leader` | **Hero enemy P1** — líder bandido ruinas, mini-boss narrativo, AI+Blender cleanup | P1 | `enemies/` |

**Decorativos living world (fauna no combate)** — subidos de P2 a P1 porque el pilar emocional del piso es "falsa seguridad": sin vida decorativa P1 se siente arena, no mundo.

| id | asset | desc | prio | destino |
|----|-------|------|------|---------|
| D01 | `butterfly_deco` | Mariposa (pradera abierta) | P1 | `enemies/deco/` |
| D02 | `rabbit_deco` | Conejo decorativo | P1 | `enemies/deco/` |
| D03 | `bird_songbird_deco` | Pajarito decorativo (vuelo) | P1 | `enemies/deco/` |
| D04 | `frog_deco` | Rana orilla lago | P2 | `enemies/deco/` |
| D05 | `fish_deco` | Pez lago (recolectable) | P2 | `enemies/deco/` |
| D06 | `turtle_deco` | Tortuga pasiva orilla | P2 | `enemies/deco/` |
| D07 | `goat_deco` | Cabra montesa colinas | P2 | `enemies/deco/` |

### 5.7 VFX / shaders (dept Art colabora con dept Gameplay)

| id | asset | desc | prio |
|----|-------|------|------|
| FX01 | `god_rays_volumetric` | Shader rayos desde diamante | P0 |
| FX02 | `water_lake_shader` | Shader agua lago (reflejo + translucencia) | P1 |
| FX03 | `waterfall_foam_particles` | Partículas espuma cascada | P1 |
| FX04 | `campfire_fire_particles` | Partículas fogata | P1 |
| FX05 | `chimney_smoke_particles` | Humo chimenea outpost | P1 |
| FX06 | `firefly_particles` | Luciérnagas decorativas | P2 |
| FX07 | `leaves_wind_shader` | Wind sway hojas/hierba | P1 |
| FX08 | `dust_motes_particles` | Motas polvo en god rays | P2 |

### 5.8 UI diegético

| id | asset | desc | prio |
|----|-------|------|------|
| U01 | `portal_entrance` | Portal entrada al piso (mesh + shader) | P0 |
| U02 | `portal_boss` | Portal arena boss | P1 |
| U03 | `sign_post_wood` | Cartel madera (POIs) | P1 |

---

## 6. Budget poly (resumen — detalle en `art_pipeline.md`)

| Categoría | Target tris |
|-----------|------------|
| Hero asset (diamante N07, bandit_leader E16, portales) | 3k-8k |
| Enemy standard (slime, lobo, bandido) | 800-2500 |
| Prop medio (cofre, árbol, cascada) | 300-1500 |
| Prop pequeño (roca, flor, hongo) | 50-300 |
| Tile terreno | <200 |

**Sin PBR. Sin normal maps (Tier I). Vertex color preferido. Atlas 1024 por bioma.**

---

## 7. Definition of Done — asset P1

Un asset está "listo" cuando:
1. ✅ Archivo en `game/assets/art/piso1_pradera/<categoria>/` con naming `snake_case`.
2. ✅ Formato Godot: `.glb` (meshes) o `.png` (texturas/atlas).
3. ✅ Escala correcta (1 unidad Godot = 1m).
4. ✅ Pivot en base del objeto (al piso) para props verticales.
5. ✅ Material usa paleta canon (§3) y atlas compartido si aplica.
6. ✅ Poly budget dentro del rango (§6).
7. ✅ Commit con mensaje `art(p1): add <asset_id> <nombre>`.
8. ✅ Screenshot en Godot con lighting canon (§4).

---

## 8. Orden de fabricación sugerido (roadmap beginner)

**Semana 1 — mínimo jugable P0 (12 assets)**: T01 grass, V01 grass_tuft, V05 oak, N07 **giant_diamond** (hero bloqueante visual), S01 dome, H06 barrel, H08 chest, E01 slime, E10 bandit_melee, U01 portal_entrance, FX01 god_rays, D01 butterfly. Con esto el piso **camina, combate funciona, y se siente P1** (diamante + god rays + mariposas = identidad visual).

**Semana 2 — completar P1**: outpost completo (H01-H05), ruinas (H11-H15 + bandit_banner), tiles extra (T02-T04, T06), vegetación P1 (flores, sauce, juncos, hongos), rocas (N01-N04), enemigos P1 (wolf, fox, rat, spider, bird, bandit_archer, slime_water, slime_mini, golem Quaternius), **E16 bandit_leader hero** (AI+Blender), portal_boss U02, shaders agua/cascada, living world P1 (rabbit, songbird).

**Semana 3 — P2 + pulido**: decorativos restantes (rana, pez, tortuga, cabra, murciélago, halcón, escorpión, serpiente), VFX secundarios (fireflies, dust motes), variantes texturas.

---

## 9. Links cruzados

- Filosofía visual: `game/docs/art_direction.md`
- Pipeline operativo (cómo fabricar): `game/docs/art_pipeline.md`
- Shaders catálogo: `game/docs/shader_system.md`
- Transiciones entre pisos: `game/docs/floor_transitions.md`
- Enemigos stats/design: `game/docs/biome_prairie.md`, `game/docs/enemy_tier_system.md`
- Living world deco: `game/docs/prairie_living_world.md`
- Sourcing concreto por asset: `game/docs/art/p1_assets_sourcing.md`
