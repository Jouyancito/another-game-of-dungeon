# Estado vivo — Dungeon Party
> Censo 2026-07-17 verificado contra código (los docs mienten; esto no). REGLA DE USO: cargar al inicio de cada sesión del juego, actualizar al cierre. Misma convención anti-olvido del corpóreo.

Fuente: censo de 3 agentes (mobs/combate, progresión/loot, canon/docs) sobre `DungeonParty-A` a fecha 2026-07-17. La sección **Assets 3D y pipeline** es la excepción: el census file dedicado llegó vacío (0 bytes) a esta sesión, así que esa sección está reconstruida por inspección directa de código (mismo criterio "código = verdad" que usa todo este documento) — recomendado re-correr ese leg del censo para profundidad completa.

---

## Mobs y combate

### ✅ TENEMOS

**Arquitectura base** — `game/scenes/enemy/base_enemy.gd` (`BaseEnemy extends CharacterBody3D`):
- `enum SubTier {A, B, C, BOSS}` (A=fauna, B=depredador, C=alfa, BOSS=jefe), `enum AggressionType {AGGRESSIVE, NEUTRAL}`, `enum AggroPersonality {DEFAULT, HUNTER_FAST, JUGGERNAUT_SLOW, CURIOUS, SKITTISH, TERRITORIAL}` + flag `is_pack`, `habitat_type: String` (open_field/water_edge/cave/aerial/boss_arena).
- Status effects (stun/bleed/weak) · alerta-por-daño 15s (ignora detection_range) · re-acquire de target por frame · knockback masa/resistencia · nameplate + Journal.sight · loot vía `LootTable.roll(enemy_type)` + `DropController` · señal `died(enemy)` en `die()` (línea 934) con **floor-clear hook**: `is_boss = sub_tier == BOSS or enemy_tier >= 10` → `_report_floor_cleared()` → `WorldManager.mark_floor_cleared` (líneas 919-932, 994-1002).

**Roster completo** (28 scripts / 27 escenas, HP/DMG/SPD desde `.tscn` y/o `_on_enemy_ready`):

| Mob | Sub-tier | Archivos | HP/DMG/SPD | Conducta |
|---|---|---|---|---|
| Slime | A | slime.gd/tscn | 150/8/2.0 | CURIOUS+NEUTRAL, hop; muere → 4 mini-slimes |
| Mini Slime | A | mini_slime.tscn | 30/4/3.5 | ídem, sin división |
| Rata | A | rat.gd/tscn | 30/3/5.0 | huye sola; agresiva con 3+ cerca; errático |
| Cabra | A | goat.gd/tscn | 60/4/3.0 | SKITTISH+NEUTRAL; dañada → carga 3x + flee 10s |
| Tortuga | A | turtle.gd/tscn | 90/3/1.5 | dañada → retracción (DEF 20, 3s, no ataca) |
| Rana | A | frog.gd/tscn | 80/8/2.4 | NEUTRAL, water_edge; hop + lengua a rango |
| Araña | A | spider.gd/tscn | 55/7/4.2 | cave; detection 7m; scuttle-burst |
| Serpiente | A | snake.gd/tscn | 40/6/3.5 | emboscada (3m); veneno 3 ticks×2 |
| Polilla Gigante | A (Tier 2) | giant_moth.gd/tscn | 70/11/3.4 | aerial; zigzag hacia la luz |
| Lobo | B | wolf.gd/tscn | 90/10/4.5 | HUNTER_FAST+pack; alfa lidera, lunge 3x/0.3s |
| Zorro | B | fox.gd/tscn | 70/9/5.5 | SKITTISH; flanqueo; 20% dodge melee |
| Córvido | B | bird.gd/tscn | 40/5/4.0 | FSM {IDLE, CIRCLING, DIVING, RETREATING} |
| Halcón | B | hawk.gd/tscn | 65/11/5.0 | mismo FSM+grab/drop; reusado "búho" P2 |
| Avispa | B | wasp.gd/tscn | 25/6/6.0 | nido leash 12m; veneno 2×1; swarm-alert |
| Escorpión | B | scorpion.gd/tscn | 75/8/4.0 | TERRITORIAL; pinch/sting; veneno 4×3 |
| Jabalí | B | jabali.gd/tscn | 120/12/3.2 | carga frontal + knockback + stun 0.5s |
| Golem | B | golem.gd/tscn | 160/13/2.0 | JUGGERNAUT_SLOW; camuflado → awaken proximidad |
| Bandido | C | bandit_melee.gd/tscn | 120/12/3.5 | slash→shield-bash(stun)→heavy; 30% block |
| Bandido Arquero | C | bandit_archer.gd/tscn | 80/14/4.0 | kiting 15m; huye; daño directo por LOS |
| Jefe Bandido | C | bandit_leader.gd **extends BanditMelee** | 180/18 | rally al ser golpeado; colapso moral al morir |
| Mímico | C | mimic.gd + mimic_chest.tscn | 86/8/3.5 | FSM {DISGUISED, REVEALING, AGGRESSIVE} |
| Legacy | — | enemy_basic.gd/tscn | 100/10/3 | cubo rojo original, retrocompat |

**Spawn por piso**: P1 `floor1_prairie.gd` (~3400 líneas) — `_get_poi_spawn_table()` (tablas por POI) + `_spawn_poi_enemies()` (1 bandit_leader/camp + mimic-gate) + `_spawn_field_enemies()` (ecología Axlin: 8 packs slime, 3 manadas lobo con alfa, 4 halcones, 3 golems camuflados, etc.). P2 `floor2_forest.gd` bespoke (roster ralo, retierado T2). P3-P5 `biome_floor.gd` genérico config-driven (`config.bestiary`), retierea `enemy_tier = floor_number`. Fauna ambiental (`scenes/fauna/`, no combate) es sistema aparte.

### 🔨 FALTA

- **Mini-boss sin categoría formal**: `bandit_leader` (SubTier.C) y `wolf` alfa actúan como mini-bosses pero no hay SubTier/flag uniforme para que UI/loot/journal los distingan.
- **King Slime HP sin verificar en juego**: `king_slime.tscn:35` trae TODO propio — 2200 configurado vs ~71000 reportado on-screen, nadie confirmó si es misread.
- **`enemy_basic.gd` legacy** sigue precargado en `floor1_prairie.gd:167` — sin confirmar si aún se instancia o se puede archivar.
- **Mecánica "errante"** (mob overleveled que baja de piso): 0% código. Único rastro es el north-star post-alpha del golem.

### ⬜ SIN TRABAJAR

- **Rarezas de mobs** ("normal/especial/raro/único"): no existen en ningún doc ni código. Lo más cercano es SubTier A/B/C/BOSS + "Veterano" (drop único, `balance/p1_economy.md §2`).
- **Razas/especies como eje taxonómico**: la palabra "raza" tiene 0 hits en todo el repo de docs; "especie" solo informal en `fauna_spec.md`.
- **"Errantes" como sistema propio** (intra-piso o entre-pisos): sin diseño formal más allá de 3 menciones textuales dispersas y no relacionadas entre sí (ver Canon).

---

## Bosses y pisos

### ✅ TENEMOS

**Los 5 bosses** (todos `sub_tier = BOSS`, `knockback_resistance ≈ 1.0`, `habitat_type = "boss_arena"`):

| Boss | Piso | Archivo | HP/DMG | Mecánica de gate |
|---|---|---|---|---|
| Rey Slime | 1 | king_slime.gd/tscn | 2200/12 | 4 fases HP-gated (75/50/25%); invoca minis; shield pose; furia F4; último aliento ≤5% HP |
| El Vigilante | 2 | forest_watcher.gd/tscn | 3400/22 | FSM STALKING/EXPOSED: invisible e inmune acechando, golpeable solo en ventana post-ataque |
| El Jötun | 3 | jotun_giant.gd/tscn | 4800/34 | coraza de hielo (95% reducción); rota → expuesto ×2 daño; se re-congela más fina |
| Al-Samum | 4 | samum.gd/tscn | 6400/40 | FSM SCATTERED (intocable, DoT) / CONDENSED (única ventana) |
| Guardián-Cuervo "El Que Recuerda" | 5 | guardian_cuervo.gd/tscn | 8200/52 | jefe de **RANGO**: memoria en `WorldManager.world_flags`; 2do run = neutral, sin XP/loot |

**Contrato de boss-gate común**: Area3D trigger `collision_mask = 2` → spawn del boss → `died.connect(_on_boss_died)` → instancia `FloorDescent` (`scenes/levels/components/floor_descent.gd`) a +6m del cadáver → el descenso ES la pantalla de carga al piso siguiente. Implementado limpio en `biome_floor.gd:229-281` (spawn y connect en el MISMO método, P3-P5).

### 🔨 FALTA

- **BUG VIGENTE del K-spawn del Rey Slime** — ver detalle + fix de una línea en "Candidatos de refactorización".
- **Contrato boss-gate triplicado**: `floor1_prairie.gd` (inline, 1497-1557), `biome_floor.gd` (limpio, 229-281) y `floor2_forest.gd` (bespoke) reimplementan el mismo pipeline por separado.

### ⬜ SIN TRABAJAR

- **Guardián-Cuervo en alpha**: ¿su memoria persistente por jugador entra a los 5 mapas publicables o requiere netcode que se reserva a lanzamiento? Sin decisión.
- **Cadencia de bosses a largo plazo**: depende de si se resuelve torre-100-pisos vs 5-pisos-culturales (ver Canon) — sin ese acuerdo, no hay diseño de bosses más allá de P5.

---

## Progresión y clases

### ✅ TENEMOS

- **XP**: única fuente = matar enemigos (`base_enemy.gd:909-910`, `die()` → `target.gain_xp(xp_reward)` sobre el ÚLTIMO target, no la party). Curva piecewise canon (`shared/stats/progression.gd::xp_for_level_v2()`): Tier I-V con bases/multiplicadores propios por balance_v2 §5. Cap `Progression.MAX_LEVEL = 15` (alpha), enforcement en `base_player.gd:995-1026`, tests `test_level_cap.gd` / `test_progression_v2.gd`.
- **Level-up**: +3 stat points/nivel, señal `level_up`, `TitleTracker.on_level_up`, `assign_stat()` reparte STR/INT/DEX/DEF/VIT. HP/MP derivados vía fórmulas cuadrática-soft.
- **Persistencia**: nivel/xp/stats **persistentes por personaje**, NO per-run (`base_player.gd:1048-1061` → `SaveManager`, JSON `user://characters.json`, SCHEMA_VERSION 4).
- **6 clases jugables** (herencia BasePlayer), stats fuente de verdad en `shared/classes/class_base_stats.gd` (indexado por scene path):

| Clase | Archivo | Recurso | Skills Fase 1 |
|---|---|---|---|
| Guerrero | player.gd | Rage (gen por %HP perdido) | punch, charge, war_cry, perfect_block |
| Mago | mage.gd | MP only | unstable_orb, prismatic_barrier, arcane_storm, supernova |
| Arquero | archer.gd | Concentración | precise_shot, charged_arrow, evasive_roll, arrow_storm |
| Clérigo | cleric.gd | Fe | healing_light, divine_aegis, prayer, sacred_circle |
| Nigromante | necromancer.gd | Vida | bone_slash, withering_curse, summon_skeleton, rite_of_abyss |
| Danzante de Sombras | danzante.gd + shadow_clone.gd | Combo Points | swift_cut, shadow_step, night_veil, thousand_shadows |

- **Skills data-driven**: `shared/skills/skill_resource.gd` (schema rico: costos duales, HP cost, marks G12, charge, reactive, summon, quest_gate, evolution) + 24 `.tres` activos + 1 archivado. Dispatch central en `scenes/player/player_skills.gd`.

### 🔨 FALTA

- **15 sinergias cross-class: 0 en código.** Grep `synerg|sinerg` sobre `**/*.gd` = 0 hits. Canon `game/docs/skills/_synergies.md` (matriz 6×6).
- **Status effects: 3 de 23.** `status_catalog.gd::IMPLEMENTED_STATUSES = [stun, bleed, weak]`; Shatter/Ignite/Electrocute/Plagued Land/Vulnerable Strike (detonantes de combo) sin runtime.
- **Skill points sin runtime**: `max_skill_level=15` y `level_effects` son solo schema en `skill_resource.gd` — cero código de `skill_point`. Ascendencia solo como `quest_gate` schema; evolución solo metadata.
- **Pérdida de loot al morir vs GDD** (pilar 3 "cada run importa"): NO implementada — la muerte no toca inventario ni oro; solo hay downed state + respawn.
- **Enhancement +1..+9** (GDD): no existe en código.

### ⬜ SIN TRABAJAR

- Nada adicional más allá de lo listado arriba — todo lo "no implementado" de progresión tiene al menos schema o mención GDD explícita (bucket FALTA, no vacío de intención).

---

## Loot y economía

### ✅ TENEMOS

- **Pipeline**: `LootTable.roll(enemy_type)` → `DropController.spawn_drops()` → `GroundItem`/`GoldDrop` en el mundo.
- **Tablas**: `shared/systems/loot_table.gd` (autoload, ~440 líneas) — ~30 tablas hardcodeadas (20+ enemigos P1, bosses de piso, rey_slime, guardián-cuervo, mimic, 3 cofres). Test anti-huérfanos: `tests/unit/test_dangling_loot_tables.gd`.
- **Ownership canon v2** (sólido, testeado): `shared/loot/drop_controller.gd` — pool party-vivos + supporters 10s, reparto floor+random, RNG seeded por kill, timers 180s owner-lock / 120s free / 300s despawn, bind items 300s.
- **Cofres**: `scenes/loot/loot_chest.gd`, `enum ChestTier {COMMON, RARE, BOSS}` → delega a `DropController.spawn_chest_drops`.
- **Economía**: oro vía `base_player.gd:77 var gold` + `add_gold()` → `GameManager.player_coins`, persiste en save.
- **Items**: `shared/systems/item_database.gd` (autoload) — ~70 items como Dictionaries (type/subtype/slot/rarity/stats/level_req/value/stackable/bind_on_drop).

### 🔨 FALTA

- **Rareza sin taxonomía real**: string libre, no enum. `RARITY_COLORS = {common, rare, magic, epic, unique}` (`item_database.gd:5-11`) es la única definición formal; `material_tusk` usa `"uncommon"` que NO existe ahí → fallback color silencioso. Afecta SOLO visual, 0 efecto en stats/drop-rate.
- **Contradicción de rarezas (3 vías)**: GDD (Común/Raro/Épico/Legendario, lo implementado) vs DESIGN_BRIEF §9.8 ("No Épica. Solo Común/Raro/Mágico/Único. Esto es canon") vs `stats_system.md:426` (sigue al brief). Sin reconciliar.
- **XP va solo al target**, no al killer real ni a la party — inconsistente con el modelo party-first de `DropController`.
- **Tiendas: no existen.** `value` de items es dato muerto (0 lecturas en código). Oro entra y no sale — cero sinks. Taverna spec archivada en `docs/_archive/post-alpha-specs/`.
- **Mimic `pool_pick` placeholder**: 60%/40% Rare/Epic genérico (`loot_table.gd:162-166`) — no es el pool canon de `_mimic.md §4.3`.
- **Duplicación item-en-suelo**: `scenes/loot/ground_item.gd` (canon v2) vs `scenes/loot/item_drop.gd` (solo usado por `inventory_ui.gd:696`), con mapas rareza→aura de luz divergentes (ninguno incluye "epic").

### ⬜ SIN TRABAJAR

- Nada — todo lo pendiente de loot/economía está al menos definido en GDD o en código parcial (bucket FALTA).

---

## Assets 3D y pipeline

*Nota de fuente: el census file de este leg llegó vacío (0 bytes); lo de abajo es verificación directa contra código/repo, no transcript de agente. Recomendado re-correr ese leg para profundidad completa (p. ej. contrato de clips por mob individual, cobertura pack-por-pack).*

### ✅ TENEMOS

- **`EnemyModelFitter`** (`game/scenes/enemy/enemy_model_fitter.gd`, `class_name EnemyModelFitter`) — single source of truth para consistencia visual↔hitbox en enemigos gltf. `fit()` (static) resuelve un gotcha medido en Godot 4.6: en modelos gltf skinned, `Mesh.get_aabb()` y `MeshInstance3D.get_aabb()` devuelven el bind-pose (T-pose) con brazos abiertos → el ancho horizontal es basura para hitbox (ej. bind width del orc = 4.68m para un personaje de ~0.6m). Fix: altura desde el Y medido, girth desde un ratio explícito de `target_height`, nunca desde X/Z medido.
- **`EnemyAnimator`** (`enemy_animator.gd`, `class_name EnemyAnimator`) — contrato de nombres de clip, auto-detectado desde `AnimationPlayer.get_animation_list()`: tipo **humanoide/"big"** (`Idle`, `Walk`, `Run`, `Jump`, `Punch`, `Death`), tipo **blob/slime** (`Bite_Front` como ataque), tipo **volador** (`Flying_Idle`, `Fast_Flying`, `Headbutt`). API: `play_state()`, `play_idle/walk/run/attack/jump/death()`, fallback a Walk si no hay Run, a Punch/ataque si no hay Jump.
- **`EnemyModelBuilder`** (`enemy_model_builder.gd`) — fallback procedural low-poly (silueta, no detalle): `build_quadruped/build_humanoid/build_arthropod/build_flyer/build_snake`, reutiliza primitivos de `MannequinBuilder`.
- **Pipeline Blender headless** (`game/tools/blender/`): generadores bpy `gen_golem.py`, `gen_golem_chunks.py`, `gen_golem_dressing.py`, `gen_crystal.py` + previews PNG por iteración (v2/v3/v4) + `golem_rigged.glb` (28 huesos, salida de UniRig).
- **UniRig** — auto-rigging local/gratis en GTX1080 vía WSL2 (~2-3min/mesh), establecido 2026-06-14 como base de todo el bestiario (libera VRAM cerrando Ollama antes de riggear).
- **Assets reales importados**: `game/assets/art/piso1_pradera/enemies/{big,blob,flying,slime}/` — ej. 3 variantes gltf de Slime (green/pink/spiky), 8 gltf de tipo "big" (alien/demon/dino/frog/ninja/orc/orc_skull/monkroose/tribal/boss_mushroom_king), props de dressing del golem (flores/musgo/pasto en .glb).
- **Docs canon de pipeline**: `game/docs/art/_modeling_knowledge_base.md` (2026-07-07, "single source of truth" modelado Blender→Godot, 4 fundaciones Topology/Rigging/Shading/Pipeline) y `game/docs/art/golem_decision_brief.md` (2026-07-02, decisión Joan §7: arquitectura A = esqueleto invisible + piedras ancladas sincronizadas).
- **Convención reference-library SAVE+USE**: toda referencia visual se commitea en `game/docs/art/_references/<X>/` + `_synthesis.md` + puntero engram, y se carga ANTES de construir/renderizar (regla obligatoria, CLAUDE.md).

### 🔨 FALTA

- **Golem chunk-anchoring: decidido pero no consolidado.** El golem jugable en pisos 1/3/5 (`scenes/enemy/golem.gd`) SI carga su cuerpo Blender propio (`golem_dp_body_01.glb`, golem.gd:57 — los `BoxMesh` del .tscn son solo fallback si falta el archivo) — el trabajo de rig+chunks (`golem_assembly.gd`, `class_name GolemAssembly`, re-arch v3 "joint-positioned skeleton" 2026-06-14, con historial documentado v1→v2→v3 en el propio archivo) vive SOLO en `scenes/dev/golem_preview.tscn` / `golem_assembly_preview.gd` y nunca llegó al enemy real.
- **King Slime no tiene modelo propio.** `king_slime.tscn` usa un `SphereMesh` verde (radius 3) + `BoxMesh` dorado como "Crown" — cero glTF importado, mientras el Slime normal SÍ tiene 3 variantes gltf reales (`enemy_slime_{green,pink,spiky}.gltf`).
- **Tooling de dev del golem fragmentado**: 10+ scripts de exploración sin consolidar — `golem_bone_discover.gd`, `golem_axis_probe.gd`, `golem_chunk_inspect.gd`, `golem_rigged_capture.gd`/`golem_rigged_preview.gd`, `golem_anim_capture.gd`, `golem_capture_trunk_rip.gd`, y `golem_capture_move.gd` **duplicado** en `scenes/dev/` Y en `game/tools/godot/`.
- **Contrato de animación incompleto**: los 3 "tipos" de clip (big/blob/flying) no cubren conductas únicas (fases de boss, reveal del mimic) — sin contrato documentado para esos casos.

### ⬜ SIN TRABAJAR

- **Provenance sidecar por asset**: la convención de `_shared/asset-provenance-sidecar.md` (usada en el corpóreo, trackea licencia/origen por `.glb`) no tiene equivalente en Dungeon Party — no hay tracking formal de qué pack CC0 originó cada archivo.
- **Auditoría de shader toon**: se ve `toon_enemy_stone.tres` en el golem, pero no está verificado si el resto del bestiario comparte un contrato de shader/outline único o son casos sueltos.

---

## Canon y docs

### ✅ TENEMOS

**Jerarquía de fuentes** (regla del repo: "los docs de diseño mienten — verificá contra el código"):

| Doc | Rol | Estado |
|---|---|---|
| `CLAUDE.md` | Fuente de verdad operativa; scope reset 2026-05-18 (MVP = 1 mapa/3 clases/1 boss/~15 enemies/cap 15) | Vigente |
| `GDD_DungeonParty.md` | Mecánica base | Parcialmente obsoleto |
| `DESIGN_BRIEF.md` | Identidad/tono, torre 100 pisos | Pre-scope-reset, choca con canon nuevo |
| `game/docs/lore/_world_canon.md` (v2.0) | Canon central de mundo, 5 pisos §13 | Vigente con parches 07-03 |
| `game/docs/lore/_alpha_5_maps.md` | Doc de 1 página de los 5 mapas alpha | Vigente; P1 completo, P2 parcial, P3-P5 boceto |
| `game/docs/lore/_mundo_entrevista.md` | Entrevista de mundo con Joan | Acta vigente, gaps listados |
| `game/docs/lore/_world_seeds_postalpha.md` | Semillas post-alfa | Explícitamente "NO canon vigente" |
| `game/docs/art/_bestiary_visual_bible.md` | ADN visual del bestiario | Vivo |
| `game/docs/art/golem_decision_brief.md` | Decisión golem (arquitectura A) | Decidido |

**Taxonomía intencional de criaturas** (docs, no código): categoría funcional (combat vs fauna ambient) · familias de silueta (blob/cuadrúpedo/volador/artrópodo/construct/humanoide/objeto-mimetiza) · endemismo criterio Axlin (endémico vs no-endémico intencional) · sub-tiers A/B/C/BOSS con multiplicadores 1.0/1.6/2.4/3.0 + packs (manada/patrulla/escuadra/mixto/nido/pre-boss) · build-method "3 baldes" (orgánico=pack-reskin, construct=bpy-bespoke, blob=bpy+jiggle) · jerarquía de jefes (zona / RANGO / mini subjefe) · eje color-por-tier.

**Pisos 1-5 intencionales**: P1 "Pradera Interior" (decidido 07-03, mundo humano, King Slime boss) · P2 bosque encantado (dirección decidida, nombre/boss ⌛) · P3 Jötunheim (boceto) · P4 Al-Samum (boceto) · P5 Umbral Fragmentado (boceto salvo rol del Guardián-Cuervo). Principios de torre decididos 07-03: climas=identidad, **torre bidireccional** (P1→P2 desciende), gradiente humano→fantasía, world-state colectivo del gate.

### 🔨 FALTA

- **Contradicción rarezas loot (3 vías)** — ver Loot y economía.
- **`CLAUDE.md` "Canon de Design Vigente" desactualizada**: no incluye `_alpha_5_maps.md`, `_mundo_entrevista.md`, `_bestiary_visual_bible.md`, `golem_decision_brief.md` ni `_modeling_knowledge_base.md` (todo canon de julio).
- **`enemy_tier_system.md` v1.0 diverge de `balance_v2.md §3` vigente** (HP tier1=50 vs ≈54 citado en CLAUDE.md:228); su boss de ejemplo ("Oso corrupto", "Treant") es incompatible con el P2 nuevo.
- **`DESIGN_BRIEF.md:34/§10.8`** ("primeros pisos civilizados, caminos, guardias, mercaderes") contradice el modelo Descubrimiento→Conquista→Civilización (alfa = fase salvaje sin senderos) — nunca se parchó.
- **Torre bidireccional** (P1→P2 desciende) contradice el lenguaje "ascender/subir" de `_world_canon.md §3`, GDD y DESIGN_BRIEF — ningún doc viejo fue anotado.
- **4 docs de fauna sin fusionar**: `fauna_spec.md`, `art/ambient_fauna.md`, `prairie_living_world.md`, `_bestiary_visual_bible.md §4-6`.
- **`PROJECT_STATE.md`** snapshot 2026-04-12 desactualizado (el propio CLAUDE.md:334 lo marca así).

### ⬜ SIN TRABAJAR

- **Reconciliación torre 100 pisos vs 5 pisos culturales**: `tower_biome_system.md` (100 pisos, 24 biomas, regla §C Δ2) vs `_world_canon.md §13` (5 pisos; Jötunheim→Al-Samum viola esa regla con Δ4). Decisión parcial 2026-06-08 (portal = válvula de bypass), reconciliación formal sigue pendiente post-alfa.
- **Estructura de pisos contradicha**: `_DESIGN_INDEX.md` ("bloque familiar → cuervo → distorsión, NO curva gradual") vs `_floor_sketches.md` (documenta curva gradual P2→P5). Preguntas 2.2/2.3 de `_mundo_entrevista.md` sin responder.
- **`_floor_sketches.md §P2`** (Aokigahara completo) obsoleto tras el descarte 2026-07-03, nunca reescrito ni marcado.
- **Rarezas de mobs y razas/especies como ejes taxonómicos nuevos** — ver Mobs y combate.

---

## Decisiones del PO — RESPONDIDAS 2026-07-17 (canon)

> Fuente: Joan por voz, sesion 2026-07-17 (engram #2150, #2151, #2152). Estas responden parte de las preguntas de abajo.

1. **Rareza de LOOT oficial: Comun -> Raro -> Magico -> Unico** (estilo Path of Exile). "Epico" SE ELIMINA (el codigo hoy tiene common/rare/magic/epic/unique — migrar). Magico = mod fuerte (pega como Unico) sin identidad; Unico = objeto con nombre y LORE ("hacha personalizada", bases que cambian de forma). Gana la escala del DESIGN_BRIEF sobre el GDD.
2. **Rareza de MOBS: la MISMA escala** (mismo vocabulario que loot). Mob basico del piso = Comun. Raro paga mas XP. **Unicos de mob RESERVADOS a misiones/eventos, siempre con lore, nunca spawn al azar**; Comun/Raro si al azar. Eje ortogonal a los sub-tiers A/B/C/BOSS.
3. **Errantes** (canon inicial): mobs de pisos superiores que bajan (ej. el del piso 40 vagando en el 10), automaticamente Raro+, QUIZAS mas pasivos; Joan les inventara historias. Pendiente: ¿alpha o post-alpha?
4. **Golem — NUEVA DIRECCION: piedras FLOTANTES** enlazadas al esqueleto. No sincronizar piedra por piedra: el esqueleto define los movimientos posibles y las piedras lo siguen levitando; awaken magico/fantasioso. Los "huecos entre cubos" que mataron el intento anterior pasan de bug a DISENO (gaps = magia). Supersede el anclaje apretado de golem_assembly v3 y el "GAP documentado" de _references/golem/_synthesis.md.
5. **XP: repartido a la party, estilo Metin2** — bono si los miembros estan CERCA al matar; lejos = solo division sin bono (penalizacion). Reemplaza el modelo actual killer/target-unico (base_enemy.gd:909-910). Numeros (radio/bono) pendientes de balance.
6. **Protocolo referencia-primero** (convencion permanente): ante cualquier concepto, consultar TODA la biblioteca de referencias ANTES de crear; lo hallado es la base; sin ref -> imaginar desde el corpus y REGISTRAR el hueco. Biblioteca madre: `game/docs/lore/_world_references.md` (60+ refs; sweep completo 2026-07-17). Ref ya identificada para el slime propio: **Tensura** (variedad/personalidad de monstruos de pradera, _art_canon.md).

Pendiente de proximo pase: anotar el pase de ENTORNO pedido por el PO (pasto, arboles, caminos, rocas — mejora en Blender).

## Decisiones pendientes del PO

### Mobs, golem y bosses
1. ¿Cuál golem es el canónico: `golem.gd` (en uso en 3 pisos) o `golem_assembly.gd` (esqueleto v3)? ¿El assembly lo reemplaza cuando esté pulido, o queda como experimento?
2. El "mob errante" que baja de pisos superiores: ¿entra al plan alpha como mecánica propia, o se mantiene atado al world-state post-alpha?
3. ¿Formalizamos "poison" como status effect canon en BaseEnemy (unificando snake/scorpion/wasp)?
4. ¿El "búho" de P2 merece identidad propia (escena/nombre/skin) o seguir siendo hawk retierado está bien para el alpha?
5. Fuente de verdad de stats de balance: ¿`.tscn` (inspector) o `_on_enemy_ready()` (script)? Hoy conviven y varios mobs duplican los números en ambos lados.
6. ¿Un SubTier o flag formal de mini-boss (bandit_leader, wolf alfa) para que UI/loot/journal los distingan, o alcanza con C + `is_alpha`?
7. Fix del bug K-spawn del King Slime: ¿conectamos `died` también en el debug spawn (para playtestear el loop con K), o eliminamos la tecla K ahora que el trigger natural funciona?
8. ¿Alguien re-verificó en juego el HP on-screen del King Slime (TODO en `king_slime.tscn:35`, ~71000 vs 2200 configurados)?

### Progresión y skills
9. ¿Las 15 sinergias cross-class son objetivo de alpha (aunque sea 2-3 combos con los 3 status ya implementados) o quedan post-alpha completo?
10. ¿Skill points (1/nivel, cap 15/skill) entran al alpha con cap 15 de personaje, o el demo se juega solo con las 4 skills fijas por clase?

### Loot y economía
11. ¿La pérdida de loot al morir (pilar GDD) entra al MVP demo o se pospone oficialmente post-alpha? Hoy el código contradice al GDD sin decisión registrada.
12. ¿El XP debe repartirse a toda la party (como el loot canon v2) o quedarse en el killer/target actual?
13. **Rarezas de LOOT definitivas** (pregunta planteada por 2 agentes del censo, en progresión y en canon): ¿GDD/implementación (Común/Raro/Épico/Legendario) o DESIGN_BRIEF (Común/Raro/Mágico/Único, "No Épica")? ¿Existe "magic" como tier real o es error histórico?
14. ¿Habrá tienda/sink de oro en el demo, o se recorta el campo `value` y la economía queda solo loot-driven para el alpha?
15. Rarezas de MOBS: ¿es un eje nuevo ortogonal a los sub-tiers A/B/C (y con nombres distintos a la rareza de loot para no colisionar), o se mapea sobre lo existente (A/B=normal, C=especial, Veterano=raro, ¿único=?)?

### Mundo, pisos y canon
16. P1 — nombre: ¿"Erindar" se mantiene redefinido, se descarta, o P1 queda como "Pradera Interior" hasta ver el video?
17. Errantes: ¿qué son exactamente (¿mobs overleveled que bajan de piso?), son mecánica de alpha o semilla post-alfa, y cómo interactúan con el filtro "¿sale en el video de 10 min?"?
18. "Razas/especies": ¿refiere a las familias de silueta de la biblia (blob/cuadrúpedo/etc.), al endemismo por piso, o es un eje taxonómico nuevo? Ningún doc usa la palabra hoy.
19. Estructura de la torre: ¿curva gradual P1→P5 o bloque familiar + salto (y en qué piso ocurre el primer quiebre de reglas)?
20. Torre bidireccional: tras P1→P2 (descenso), ¿qué dirección toma cada piso posterior, y se reescribe el lenguaje "ascender la torre" del canon viejo?
21. P2: ¿nombre del piso?, ¿bosque valdiviano confirmado como base estructural?, ¿palafitos en risco entran?, ¿boss de zona y mini subjefes de P2?
22. Gradiente mecánico P2-P5: ¿se decide ahora una regla de juego que cambia por piso, o se pospone al post-video?
23. Reconciliación 100-pisos-procedural vs 5-pisos-culturales: ¿el juego largo es 100 pisos con bandas/biomas y los 5 del alpha son el primer bloque, u otra estructura?
24. Guardián-Cuervo en el alpha: ¿la memoria persistente por jugador entra en los 5 mapas publicables, o se reserva al lanzamiento (requiere netcode)?

---

## Candidatos de refactorización (ranked)

> **BUG VIGENTE — King Slime, K-spawn no genera descenso.** `floor1_prairie.gd:3391` `_debug_spawn_king_slime()` hace `add_child(king)` pero **nunca conecta** `died` (a diferencia del spawn natural en líneas 1536-1544, que sí lo hace) → matar un King Slime spawneado con la tecla K jamás dispara el `FloorDescent`. **Fix de una línea**: agregar `(king as BaseEnemy).died.connect(_on_boss_died)` en `_debug_spawn_king_slime()` — o, mejor, unificar ambos caminos en un solo spawn method compartido, tal como ya hace `biome_floor.gd:256-267` para P3-P5 (spawn + connect en el mismo método, imposible que se desincronice).

1. **Dedup FSM bird/hawk** — `game/scenes/enemy/bird.gd` y `hawk.gd` tienen el MISMO `enum {IDLE, CIRCLING, DIVING, RETREATING}` copy-pasteado (bird.gd:16, hawk.gd:18) + raycast-al-suelo repetido. Candidato a base class `FlyingDiver` (hawk solo agrega grab+drop y HUNTER_FAST).
2. **Veneno → status effect canon** — hand-rolled 3 veces (`snake.gd` 3×2, `scorpion.gd` 4×3, `wasp.gd` 2×1), cada uno con su propio loop de ticks, mientras `base_enemy.gd:466-561` ya tiene infraestructura de status (stun/bleed/weak) donde "poison" no existe. Candidato: `apply_status(&"poison")` canon en `shared/skills/status_catalog.gd`.
3. **Patrón "alertar al grupo" ×3** — `wasp.gd` (swarm alert, ~43-59), `wolf.gd` (manada/alfa), `bandit_leader.gd` (rally, 47-67 — su propio comentario admite "the wasp/wolf alert pattern"). Candidato: `alert_group(enemy_types, radius, attacker)` compartido en BaseEnemy.
4. **Contrato boss-gate ×3** — `floor1_prairie.gd` (inline, 1497-1557), `biome_floor.gd` (limpio, `_spawn_boss_trigger`/`_spawn_boss`/`_on_boss_died`, 229-281) y `floor2_forest.gd` (bespoke) implementan el mismo pipeline Area3D-mask2→spawn→died→FloorDescent por separado. El de `biome_floor` es el limpio; P1 y P2 podrían delegarle.
5. **Stats en .tscn Y en script (dos fuentes)** — mobs nuevos (frog, jabalí, spider, giant_moth, bandit_leader, bosses P2-P5) duplican números en `_on_enemy_ready()` Y en overrides `.tscn` (ej. `frog.gd:30-38` vs `frog.tscn:13-28`; `forest_watcher.gd:49-57` vs `forest_watcher.tscn:13-21`). Mobs viejos solo usan `.tscn`. CLAUDE.md dice "@export para todo valor de balance" → definir `.tscn`/inspector como única fuente.
6. **Dos golems completos** — `game/scenes/enemy/golem.gd` (en uso, floors 1/3/5) y `golem_assembly.gd` (1800+ líneas, re-arch v3 esqueleto por chunks, solo referenciado por `scenes/dev/golem_preview.tscn`) — ambos `enemy_type='golem'`, JUGGERNAUT_SLOW, mismos stats. Decidir cuál es canónico y archivar/fusionar el otro (ver también sección Assets 3D).
7. **Rareza → enum** — `item_database.gd:5-11` (`RARITY_COLORS`) es la única fuente formal pero rareza es string libre ("uncommon" huérfano cae a fallback); `item_drop.gd:78` y `ground_item.gd:181-183` traen mapas rareza→aura DIVERGENTES (ninguno incluye "epic"). Candidato: `enum Rarity` + orden + color en un solo lugar, validado al registrar cada item.
8. **Loot/items data-en-código → resources** — `loot_table.gd` (~440 líneas) e `item_database.gd` (~890 líneas) son Dictionaries hardcodeados en autoloads. Candidato: mover a `.tres`/JSON por piso con validación al cargar (ya existe `test_dangling_loot_tables.gd` como base anti-huérfanos).
9. **XP por tier, no copy-paste** — `xp_reward` hardcodeado en el `_ready()` de ~25 enemigos (`spider.gd:33`, `jabali.gd:42`, `samum.gd:61`, etc.) pese a que `enemy_tier_system.md`/`balance_v2 §3` prometen XP derivado de tier. Candidato: derivar `xp_reward` de `enemy_tier` + `sub_tier` en `base_enemy.gd`.
10. **El resto** (gaps menores, uno por línea, con path):
    - Colisión de nombres `bird`: `scenes/fauna/bird.gd` (ambiental) vs `scenes/enemy/bird.gd` (combate) — renombrar la fauna a `ambient_bird`.
    - Raycast "altura sobre terreno" repetido en `bird.gd:39`, `hawk.gd:33`, `wasp.gd:27` — util compartida.
    - `enemy_basic.gd/tscn` legacy sigue precargado en `floor1_prairie.gd:167` — confirmar uso real o archivar.
    - Mini-boss sin flag formal: `wolf` alfa se setea vía `set()` en `floor1_prairie.gd:3112`, ni siquiera `@export`.
    - Duplicación item-en-suelo: `scenes/loot/ground_item.gd` (canon v2) vs `scenes/loot/item_drop.gd` (solo `inventory_ui.gd:696`).
    - XP al target, no a la party: `base_enemy.gd:909-910` — inconsistente con el drop ownership party-first.
    - `ClassBaseStats.DEFAULTS` indexado por scene path (`res://scenes/player/player.tscn`) en vez de class id — frágil ante renames.
    - Mimic `pool_pick` placeholder (`loot_table.gd:162-166`) — no es el pool canon de `_mimic.md §4.3`.
    - Gen de Rage del Warrior hardcodeada con `if` por `ClassResource.Type` en `base_player.gd:954-957` — no escala a más clases/pasivas.
    - Dos modelos de torre sin reconciliar: `tower_biome_system.md` vs `_world_canon.md §13`.
    - Estructura de pisos contradicha: `_DESIGN_INDEX.md` vs `_floor_sketches.md`.
    - `_floor_sketches.md §P2` (Aokigahara) obsoleto, no reescrito ni marcado.
    - `enemy_tier_system.md` v1.0 diverge de `balance_v2.md §3` vigente.
    - `CLAUDE.md` "Canon de Design Vigente" desactualizada (falta canon de julio).
    - 4 docs de fauna sin fusionar bajo `_bestiary_visual_bible.md`.
    - `PROJECT_STATE.md` snapshot 2026-04-12 desactualizado.
    - **Assets 3D** (hallazgo directo de código, ver nota de fuente arriba): golem chunk-anchoring decidido pero desconectado del enemy real (`golem.gd` sigue en BoxMesh) · King Slime sin modelo propio (SphereMesh+BoxMesh) · tooling de dev del golem fragmentado en 10+ scripts sin consolidar.
