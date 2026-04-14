# P1 Pradera — Assets Sourcing

**Estado**: Draft v1 — 2026-04-13
**Dept**: Art
**Base**: `p1_pradera.md` (lista completa de assets con IDs)
**Pipeline**: `art_pipeline.md` (jerarquía asset-first)

> Este doc dice **de dónde sale cada asset** de `p1_pradera.md`. Tres rutas:
> 1. **CC0 pack** — Kenney / Quaternius / Poly Pizza — lo más rápido, 80% del piso.
> 2. **AI gen + cleanup Blender** — Meshy / Rodin / Tripo — hero assets únicos.
> 3. **Blender from scratch** — último recurso, solo cuando no hay opción viable.

---

## 0. Cómo usar este doc (beginner-friendly)

1. Abrís `p1_pradera.md` y elegís un asset (ej: `V05 tree_oak_a`).
2. Venís acá y buscás la fila de ese ID.
3. La columna **Source** te dice qué ruta seguir.
4. La columna **Link / prompt / notas** te da el punto de partida exacto.
5. Seguís el workflow que dice `art_pipeline.md` para esa ruta.

**Regla de oro**: siempre buscás en Kenney/Quaternius/Poly Pizza ANTES de abrir Blender o Meshy. Si existe un asset CC0 que cumple "80% de lo que necesito", lo usás y editás el material para que matchee la paleta canon. Modelar desde cero = última opción.

---

## 1. Catálogos CC0 de cabecera

| Catálogo | URL | Uso en P1 |
|----------|-----|-----------|
| **Kenney** | https://kenney.nl/assets — filtro "3D" | Props humanos (outpost, barriles, cofres), tiles, vegetación low-poly, enemigos humanoides genéricos |
| **Quaternius** | https://quaternius.com/packs.html | Nature Pack (árboles, rocas, flores), Animated Animals (zorro, lobo, ciervo), Ultimate RPG (humanoides), Monsters Pack (slime, golem) |
| **Poly Pizza** | https://poly.pizza/ | Buscador agregador — fallback si Kenney/Quaternius no tienen algo específico |

**Licencias**: los tres son CC0 (uso comercial sin atribución). Confirmar siempre en la página de descarga. Guardar licencia en `game/assets/art/LICENSES.md` si agregás otra fuente.

### Packs Kenney recomendados P1
- **Nature Kit** — árboles, rocas, hierba, flores, hongos.
- **Survival Kit** — tiendas, fogatas, barriles, campamento, antorchas.
- **Medieval Kit / Castle Kit** — empalizadas, torres, muros, ruinas.
- **Prototype Textures** — tiles terreno temporales (mientras no hay versión final).
- **Fantasy Town Kit** — casas outpost.

### Packs Quaternius recomendados P1
- **Ultimate Nature Pack** — árboles variados (robles, sauces), rocas, flores.
- **Ultimate Animated Animals Pack** — lobo, zorro, rata, pájaro, murciélago, serpiente, cabra (rigged).
- **Ultimate Monsters Pack** — slime variantes, golem piedra.
- **Ultimate RPG Pack** — bandidos humanoides (mercenario, arquero).

---

## 2. AI generation — cuándo y cómo

### Herramientas
| Tool | URL | Gratis? | Fuerte en |
|------|-----|---------|-----------|
| **Meshy** | https://meshy.ai | Free tier limitado (~200 créditos/mes) | Text→3D rápido, PBR auto |
| **Rodin (Hyper3D)** | https://hyper3d.ai | Free tier | Calidad topológica mejor que Meshy |
| **Tripo** | https://tripo3d.ai | Free tier | Mejor para assets orgánicos |

### Regla de uso
AI gen **siempre** requiere cleanup en Blender:
- Topología sucia → retopo manual o Quad Remesh (RetopoFlow gratis).
- Escala random → fijar a 1 unidad = 1m.
- Pivot desplazado → mover al base.
- UVs malos → re-unwrap si vas a texturizar.
- Materiales PBR → bajar a unlit/vertex color para matchear estilo Tier I.

### Prompt pattern para Meshy/Rodin (low-poly Tier I)
```
[asset], low poly, stylized, flat colors, no PBR, clean topology,
game-ready, 1000-3000 triangles, matte finish, soft organic shapes,
fantasy RPG aesthetic similar to Valheim or Risk of Rain 2
```

Sustituí `[asset]` por el item. Siempre **variá** el prompt 2-3 veces y elegís la mejor salida.

---

## 3. Blender from scratch — cuándo

Solo cuando:
- No existe en CC0 ni Poly Pizza.
- AI gen sale mal 3 intentos seguidos.
- Asset es ÚNICO del proyecto (ej: diamante del techo con emisión específica, bandera bandidos con logo custom).

Tutoriales recomendados (beginner): **Grant Abbitt** (YouTube, low-poly), **Imphenzia** (YouTube, 10-min low-poly). Ver `art_pipeline.md` §14.

---

## 4. Tabla master — sourcing por asset

Leyenda:
- **K** = Kenney, **Q** = Quaternius, **P** = Poly Pizza, **AI** = Meshy/Rodin/Tripo, **B** = Blender from scratch.

### 4.1 Terreno

| id | asset | Source | Link / prompt / notas |
|----|-------|--------|-----------------------|
| T01 | ground_grass | K | Nature Kit → textures, o Prototype Textures para placeholder |
| T02 | ground_dirt_path | K | Nature Kit → ground textures |
| T03 | ground_stone | K | Medieval Kit → stone textures |
| T04 | ground_rocky | K/AI | Kenney rock texture, o AI: "rocky dry ground texture, tileable, low poly, flat colors" |
| T05 | ground_sand_shore | K | Nature Kit → sand texture |
| T06 | cliff_rock_face | Q | Ultimate Nature Pack → cliff modules |

### 4.2 Vegetación

| id | asset | Source | Link / prompt / notas |
|----|-------|--------|-----------------------|
| V01 | grass_tuft_a/b/c | K/Q | Kenney Nature Kit (grass tufts), variantes directo |
| V02 | flower_yellow | K | Nature Kit — flower_yellowA.glb |
| V03 | flower_white_daisy | K | Nature Kit — flower_whiteA.glb |
| V04 | flower_blue | K/Q | Nature Kit o Ultimate Nature (flower_blueA) |
| V05 | tree_oak_a/b/c | Q | Ultimate Nature Pack → oak tree variants (3 meshes) |
| V06 | tree_willow | Q | Ultimate Nature Pack → willow; fallback AI: "low poly willow tree, flat colors" |
| V07 | bush_berry | K | Nature Kit → bush + overlay bayas (edit material color) |
| V08 | bush_thorny | Q | Ultimate Nature → thorny bush |
| V09 | reed_water | Q | Ultimate Nature → reeds |
| V10 | water_lily | P | buscar "water lily low poly" en Poly Pizza |
| V11 | fern | K/Q | Nature Kit → fern |
| V12 | mushroom_common_a/b | K | Nature Kit → mushroom variants |
| V13 | ivy_wall | P/AI | Poly Pizza "ivy low poly", fallback AI |
| V14 | moss_rock | — | Material/shader, NO es mesh. Vertex color verde + noise |
| V15 | cactus_small | K | Nature Kit → cactus (si existe) o Poly Pizza |

### 4.3 Rocas y props naturales

| id | asset | Source | Link / prompt / notas |
|----|-------|--------|-----------------------|
| N01 | rock_small_a/b/c | K/Q | Nature Kit → rock_small (3 variants) |
| N02 | rock_medium_a/b | K/Q | Nature Kit → rock_medium |
| N03 | rock_boulder | Q | Ultimate Nature → large boulder |
| N04 | log_fallen | K | Nature Kit → log / fallen tree |
| N05 | stump_tree | K | Nature Kit → stump |
| N06 | crystal_ceiling_a/b | AI | Meshy prompt: "glowing blue crystal cluster, low poly, emissive, stylized, 500 tris"; cleanup Blender + emission material (#A8D4E8) |
| N07 | **giant_diamond** (hero) | AI+B | Meshy/Rodin: "giant golden diamond, faceted, emissive glow, low poly, 2000 tris"; cleanup Blender obligatorio; material custom con emission #F5D576 energy 10. **Hero asset — iterar hasta quedar bien.** |
| N08 | waterfall_mesh | B+shader | Mesh simple en Blender (plano con deformación) + shader water del catálogo `shader_system.md` |

### 4.4 Props humanos

| id | asset | Source | Link / prompt / notas |
|----|-------|--------|-----------------------|
| H01 | wood_palisade_section | K | Medieval Kit / Castle Kit → palisade |
| H02 | wood_watchtower | K | Medieval Kit → watchtower |
| H03 | wood_gate | K | Medieval Kit → gate |
| H04 | wood_house_small | K | Fantasy Town Kit → small house |
| H05 | chimney_smoke_emitter | K+FX | Kenney chimney + partículas Godot |
| H06 | barrel_wood | K | Survival Kit → barrel |
| H07 | crate_wood | K | Survival Kit → crate |
| H08 | chest_common | K | Survival Kit / RPG Kit → chest |
| H09 | campfire_lit | K+FX | Kenney campfire + partículas fuego |
| H10 | tent_cloth | K | Survival Kit → tent |
| H11 | ruin_column_broken | K/Q | Castle Kit → broken column, o Quaternius ruins |
| H12 | ruin_wall_section | K | Castle Kit → broken wall |
| H13 | ruin_stairs | K | Castle Kit → stairs |
| H14 | ruin_floor_tile | K | Castle Kit → stone floor |
| H15 | bandit_banner | B | Blender: plano + textura bandera. Logo bandido custom (Krita) |
| H16 | torch_wall | K | Medieval Kit → wall torch + partículas fuego |

### 4.5 Skybox / techo

| id | asset | Source | Link / prompt / notas |
|----|-------|--------|-----------------------|
| S01 | cave_ceiling_dome | B | Blender: UV sphere hemisférica invertida, low-poly, material vertex color roca oscura |
| S02 | cave_ceiling_rock_material | B/shader | Material Godot con gradient + noise. No mesh |
| S03 | distant_mountains_billboard | B+Krita | Billboards (planos con alpha) pintados en Krita, 3-4 capas parallax |

### 4.6 Enemigos

| id | asset | Source | Link / prompt / notas |
|----|-------|--------|-----------------------|
| E01 | slime_green | Q | Ultimate Monsters → slime (ya animado) |
| E02 | slime_mini | Q | Mismo mesh E01 escalado 0.5 |
| E03 | slime_water_blue | Q | E01 con material #5C84A0 + shader translúcido |
| E04 | rat_small | Q | Ultimate Animated Animals → rat |
| E05 | fox_red | Q | Ultimate Animated Animals → fox |
| E06 | wolf_gray | Q | Ultimate Animated Animals → wolf |
| E07 | spider_small | Q/P | Ultimate Monsters → spider, o Poly Pizza |
| E08 | bird_crow | Q | Ultimate Animated Animals → crow/raven |
| E09 | hawk | Q/P | Ultimate Animated Animals → hawk, fallback Poly Pizza |
| E10 | bandit_melee | Q | Ultimate RPG Pack → mercenary/bandit humanoid (rigged Mixamo-compat) |
| E11 | bandit_archer | Q | Ultimate RPG → archer variant (misma rig, distinto equipo) |
| E12 | bat | Q | Ultimate Animated Animals → bat |
| E13 | golem_rock | Q | Ultimate Monsters → stone golem; ajustar material a paleta canon (grises + verdes musgo). No hero — sub-C normal |
| E14 | scorpion | P | Poly Pizza "scorpion low poly" |
| E15 | snake | P/Q | Poly Pizza o Quaternius reptiles |
| E16 | **bandit_leader** (hero) | AI+B | Rodin/Meshy: "bandit warlord, humanoid, fur cloak, horned helmet, scarred, low poly, 4000 tris, stylized fantasy"; cleanup pesado (topología + rigging Mixamo-compat + Rigify). **Hero narrativo P1** — mini-boss ruinas. Identidad facción bandidos. |

### 4.6b Decorativos living world

| id | asset | Source | Link / prompt / notas |
|----|-------|--------|-----------------------|
| D01 | butterfly_deco | P/Q | Poly Pizza "butterfly low poly animated" o Quaternius insects |
| D02 | rabbit_deco | Q | Ultimate Animated Animals → rabbit |
| D03 | bird_songbird_deco | Q | Ultimate Animated Animals → small bird |
| D04 | frog_deco | P | Poly Pizza "frog low poly" |
| D05 | fish_deco | Q | Ultimate Animated Animals → fish |
| D06 | turtle_deco | Q/P | Quaternius o Poly Pizza |
| D07 | goat_deco | Q | Ultimate Animated Animals → goat |

### 4.7 VFX / shaders

Todos viven en `shader_system.md` — acá solo decidimos sourcing de las partículas/shaders no catalogados.

| id | asset | Source | Notas |
|----|-------|--------|-------|
| FX01 | god_rays_volumetric | catálogo shader_system | Ya definido, implementar |
| FX02 | water_lake_shader | catálogo shader_system | Shader canon proyecto |
| FX03 | waterfall_foam_particles | Godot built-in | GPUParticles3D con sphere emitter |
| FX04 | campfire_fire_particles | Godot built-in | GPUParticles3D + sprite fuego Kenney |
| FX05 | chimney_smoke_particles | Godot built-in | GPUParticles3D gris |
| FX06 | firefly_particles | Godot built-in | GPUParticles3D emisivos amarillo |
| FX07 | leaves_wind_shader | catálogo shader_system | Ya definido |
| FX08 | dust_motes_particles | Godot built-in | GPUParticles3D pequeño |

### 4.8 UI diegético

| id | asset | Source | Notas |
|----|-------|--------|-------|
| U01 | portal_entrance | AI+B | Meshy: "magic portal, swirling energy, stone arch, low poly"; cleanup + shader custom |
| U02 | portal_boss | AI+B | Variante U01, paleta más roja/amenazante |
| U03 | sign_post_wood | K | Survival Kit → sign post |

---

## 5. Hero assets — lista concentrada

Son los que **NO** salen de Kenney/Quaternius. Requieren AI + Blender cleanup o Blender from scratch. Son los que dan identidad a P1.

1. **N07 giant_diamond** — el "sol" del piso, visible desde todo el mapa. **P0 semana 1**.
2. **N06 crystal_ceiling_a/b** — vía láctea del techo.
3. **S01 cave_ceiling_dome** — el techo de caverna en sí (Blender directo, es trivial).
4. **E16 bandit_leader** — hero enemy narrativo P1, mini-boss ruinas.
5. **U01/U02 portals** — transiciones canon.
6. **S03 distant_mountains** — parallax de fondo pintado.
7. **H15 bandit_banner** — identidad facción bandidos.

Nota: **E13 golem_rock degradado** de hero a estándar Quaternius — es sub-C normal según GD, no justifica 2 días de laburo. El esfuerzo hero se movió a **E16 bandit_leader** (enemigo que el jugador va a recordar).

Todo lo demás = **Kenney/Quaternius directo** con ajuste de material para matchear paleta.

---

## 6. Workflow resumido por ruta (ver `art_pipeline.md` para detalle)

### Ruta K/Q/P (CC0)
1. Descargar pack.
2. Abrir `.glb` / `.fbx` en Blender.
3. Ajustar escala a 1u = 1m.
4. Pivot a base.
5. Simplificar material a vertex color / unlit si trae PBR pesado.
6. Export `.glb` a `game/assets/art/piso1_pradera/<categoria>/`.
7. Import en Godot, verificar lighting canon.

### Ruta AI + cleanup
1. Escribir prompt (patrón §2).
2. Generar 2-3 variantes en Meshy/Rodin/Tripo.
3. Descargar mejor resultado como `.glb`/`.obj`.
4. Blender: retopo si es necesario (Quad Remesh), fijar escala + pivot, re-UV, aplicar material canon.
5. Export `.glb`.
6. Import en Godot.

### Ruta B (Blender from scratch)
1. Seguir tutorial Imphenzia/Grant Abbitt si es primera vez con ese tipo de asset.
2. Modelar low-poly dentro del budget (§6 `p1_pradera.md`).
3. UV + vertex color / atlas compartido.
4. Export `.glb`.

---

## 7. Próximos pasos

1. Descargar los 4 packs Kenney recomendados + 4 Quaternius → guardar en `game/assets/art/_raw/kenney/` y `_raw/quaternius/` (no commitear `_raw/`, agregar a `.gitignore`).
2. Primer commit de prueba: importar `V05 tree_oak_a` en Godot con lighting canon P1 y tomar screenshot → validar paleta.
3. Arrancar iteración AI de **N07 giant_diamond** (hero bloqueante para que el piso "se sienta" P1).

---

## 8. Links cruzados

- Lista de assets: `p1_pradera.md`
- Pipeline operativo: `../art_pipeline.md`
- Catálogo shaders: `../shader_system.md`
- Canon visual por piso: `../visual_bible.md`
- Tutoriales beginner: `../art_pipeline.md` §14
