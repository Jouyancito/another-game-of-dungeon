# Dungeon Party (Another Game of Dungeon)

Dungeon crawler cooperativo en primera persona, 1-6 jugadores. Torre de 5 pisos temáticos con dificultad progresiva, loot, clases y progresión persistente.

**Repo**: https://github.com/Jouyancito/another-game-of-dungeon (privado)

## Stack

- **Engine**: Godot 4.6
- **Lenguaje**: GDScript
- **Networking** (futuro): Steam via GodotSteam
- **Plataformas**: Windows, Mac, Linux

## Estructura del Proyecto

```
game/
├── project.godot                  # Config: 1920x1080, windowed, input maps
├── scenes/
│   ├── main/main.tscn            # Arena 20x20, 4 paredes, luz direccional, 3 enemigos
│   ├── player/
│   │   ├── base_player.gd        # ~190 líneas — clase base: movimiento, stats, regen, daño
│   │   ├── player.gd             # ~65 líneas — Guerrero: melee pesado + combo
│   │   ├── player.tscn           # CharacterBody3D: cápsula + cámara + head
│   │   ├── mage.gd              # ~110 líneas — Mago: proyectil + rayo canalizado
│   │   └── mage.tscn            # CharacterBody3D: cápsula azul + cámara + head
│   ├── projectile/
│   │   ├── mage_projectile.gd    # Bolita de energía: viaja, impacta, daño
│   │   └── mage_projectile.tscn  # Esfera blanca con emisión azulada
│   ├── enemy/
│   │   ├── enemy_basic.gd        # 108 líneas — IA: idle/pursue/attack
│   │   └── enemy_basic.tscn      # CharacterBody3D: cubo rojo 0.8×1.6×0.8
│   ├── hud/
│   │   ├── hud.gd                # 50 líneas — barras, hotbar, muerte
│   │   ├── hud.tscn              # CanvasLayer: vida/maná/XP, hotbar, crosshair
│   │   └── crosshair.gd          # 20 líneas — 4 líneas + punto central
│   └── levels/                    # Vacío — futuro: generación procedural
├── assets/                        # models/, sounds/, textures/ — vacíos
└── scripts/                       # Vacío — futuro: utilidades
```

## Estado Actual — Fase de Prototipo

### Implementado

- **Herencia de clases**: BasePlayer → Warrior/Mage (código compartido sin duplicar)
- **Movimiento**: WASD + mouse look, salto, gravedad, sprint (Shift), agacharse (Ctrl)
- **Guerrero**: puñetazo pesado (click, 35 dmg base) + combo rápido (mantener, 15 dmg base)
- **Mago**: bolita de energía (click, 25 dmg base, gratis) + rayo canalizado (mantener, 8 dmg/tick, gasta maná)
- **Sistema de stats**: STR, INT, DEX, DEF, VIT con valores base por clase
- **Fórmulas de daño**: físico = base + (STR×2), mágico = base + (INT×2)
- **Defensa**: DEF reduce daño físico (mínimo 1), resistencias elementales cap 75%
- **HP/MP calculados**: HP = base + (VIT×5), MP = base + (INT×3)
- **Regeneración**: vida fuera de combate (15s delay), maná siempre
- **3 stat points por nivel** + función assign_stat() lista para UI
- **Enemigo básico**: cubos rojos, 100 HP, IA con detección 15m, ataque 2m, 30 XP
- **HUD**: barras vida/maná/XP, hotbar 8 slots, crosshair, pantalla de muerte
- **Respawn**: tecla R recarga la escena (temporal para prototipo)

### Stats Base por Clase

| Stat | Guerrero | Mago |
|------|----------|------|
| STR | 12 | 4 |
| INT | 3 | 12 |
| DEX | 6 | 5 |
| DEF | 10 | 3 |
| VIT | 10 | 5 |
| HP base | 100 | 70 |
| MP base | 80 | 120 |
| HP total | 150 | 95 |
| MP total | 89 | 156 |
| Velocidad | 5 m/s | 4.5 m/s |
| Sprint | 8 m/s | 7 m/s |

### Layers de Física

- Layer 1: World
- Layer 2: Player
- Layer 3: Enemies

## Arquitectura

### Herencia
```
BasePlayer (base_player.gd) — class_name BasePlayer
├── Warrior (player.gd) — extends BasePlayer
└── Mage (mage.gd) — extends BasePlayer
```

Métodos override por clase: `_on_class_ready()`, `_on_attack_pressed()`, `_on_attack_released()`

### Señales (Signal-Driven)
- BasePlayer emite: `health_changed`, `mana_changed`, `xp_changed`, `player_died`, `level_up`
- `hud.gd` busca por grupo `"player"` y conecta señales

### Grupos
- `"player"` — identificación del jugador para colisiones/IA
- `"enemies"` — identificación de enemigos para ataques

### Patrones
- `CharacterBody3D` para player y enemigos
- Raycast para melee, Area3D para proyectiles
- Tween para animaciones de muerte
- `StandardMaterial3D` para feedback visual
- `ImmediateMesh` para el rayo canalizado del mago
- Variables `@export` para tunear balance

## Resumen del GDD (fuente de verdad: `GDD_DungeonParty.md`)

### Pilares de Diseño
1. Coordinación es poder — dificultad fija, no escala con jugadores
2. Sinergias ganan batallas — combinaciones de clases desbloquean efectos
3. Cada run importa — permadeath con pérdida de loot
4. Tu dungeon, tu historia — mundo persistente con marcas
5. Fácil de aprender, difícil de dominar — sistemas simples, profundidad emergente

### 6 Clases (lanzamiento)
1. **Warrior**: Tanque (escudo) / Berserk (furia) — recurso: Rage
2. **Mage**: Elementalista (fuego/hielo/rayo) / Arcano (espacio) — recurso: MP only (fantasy lock)
3. **Archer**: Ranger (rapid fire) / Artillero (explosivos) — recurso: Concentración
4. **Cleric**: Sanador / Buffer / Exorcista (excepción 3 ramas) — recurso: Fe
5. **Necromancer**: Maldiciones (debuffs) / Creador (invocaciones) — recurso: Vida
6. **Danzante de Sombras**: Sombra (stealth burst) / Trickster (control) — recurso: Combo Points

### Progresión
- Niveles 1-50, curva XP 1.15x, 3 stat points por nivel (150 totales)
- **Skill points**: 1/nivel, cap 15 por skill (canon `_system.md` v1.0)
- **Ascendencia**: lvl 25 (no lvl 10) — desbloquea rama
- **Evolución skill**: lvl 15 skill + char 50 + ítem raro (forma alternativa)
- 6 resets máximo → después "The Lost"

### Sistema de Skills (canon v1.0 — 2026-04-14)

- **Canon central**: `game/docs/skills/_system.md`
- **64 skills documentadas** (10-12 por clase fase prototipo, target 25 endgame)
- **Per-class docs**: `game/docs/skills/{warrior,mage,archer,cleric,necromancer,danzante_sombras}.md`
- **Sinergias cross-class**: `game/docs/skills/_synergies.md` (15 combos canon)
- **Status effects**: `game/docs/skills/_status_effects.md`
- Recursos únicos por clase (ver lista de clases arriba) — descartado XP por uso + Maestría por drop

### Loot y Muerte
- Raridades: Common → Rare → Epic → Legendary
- Enhancement +1 a +9 con chance de romper
- Items modifican stats (+2 DEF, +1 Rango, etc.)
- Muerte = pierde loot del run; inventario en taverna seguro

### Escalado de Enemigos por Piso
| Piso | HP | Daño | DEF |
|------|----|------|-----|
| 1 - Pradera | 100 | 10 | 0 |
| 2 - Bosque | 200 | 20 | 5 |
| 3 - Hielo | 350 | 35 | 12 |
| 4 - Tormenta | 500 | 50 | 20 |
| 5 - Dimensión Rota | 700 | 70 | 30 |

### MVP (Fase 1)
1. Movimiento first-person ✅
2. 2 clases funcionales ✅ (Warrior + Mage base implementados)
3. 2-3 tipos de enemigo con IA
4. 1 piso + 1 boss
5. Sistema vida/muerte con pérdida de loot
6. Loot básico + raridades
7. Taverna simple (lobby)
8. Multiplayer 2 jugadores (Steam)
9. Guardado de perfil local

## Issues Abiertos (GitHub)

Ver https://github.com/Jouyancito/another-game-of-dungeon/issues

## Próximos Pasos

- Probar refactor (BasePlayer herencia) — verificar que todo funcione igual
- Selector de clase (issue #1)
- Ventana de personaje para asignar stat points (issue #2)
- Más tipos de enemigos (issue #4)

## Departamentos — Status Tracking (OBLIGATORIO)

### Worktrees y roles

- **A** (`master`) — 🔴 Main/coordinador. Esta ventana decide estrategia y coordina conflictos entre B/C/D.
- **B** (`idle/b` → `dept/{code}/{feature}` al asignar tarea) — 🟢
- **C** (`idle/c` → `dept/{code}/{feature}` al asignar tarea) — 🔵
- **D** (`idle/d` → `dept/{code}/{feature}` al asignar tarea) — 🟡

Cuando se asigna tarea a B/C/D: `git branch -m idle/x dept/{code}/{feature}`.

### Protocolo obligatorio al ARRANCAR sesión (cualquier worktree)

**SIEMPRE al iniciar una sesión en B, C o D, hacer en ESTE orden:**

1. **Leer `.dept-status/*.json`** — todos los archivos que hay en la carpeta.
2. Por cada archivo válido, **sincronizar a engram**:
   ```
   mem_save(
     title: "Dept {CODE} — estado actual",
     type: "config",
     scope: "project",
     topic_key: "dept-status/{code}",
     content: <contenido del JSON formateado como markdown>
   )
   ```
3. Reportar estado propio con `mem_save` y topic_key `dept-status/{tu-código}` + estado `INICIADO`.

En **A (master)**: al arrancar, ADEMÁS hacer `mem_search(query: "dept-status")` y mostrar tabla resumida del estado de B/C/D.

### Al hacer commit (automático)

Hook `post-commit` escribe `.dept-status/{code}.json` con branch, último commit, archivos tocados. No hay que hacer nada manual.

### Al hacer push (automático)

Hook `pre-push` aplica semáforo de conflictos:
- 🟢 Verde → push libre
- 🟡 Amarillo → overlap de archivos, merge limpio, pide confirmación
- 🔴 Rojo → conflicto real, bloquea push. Lista worktrees a coordinar.

Cuando A (master) detecta rojo/amarillo, debe generar **prompts copy-paste** para las ventanas afectadas con instrucciones concretas de qué tocar.

### Al cerrar sesión

1. `mem_save` con topic_key `dept-status/{code}` + estado `INACTIVO`.
2. Si hay commits sin pushear → `git push` (para sincronizar local ↔ remoto).

Detalle completo en `DEPARTMENTS.md` → sección "Protocolo de Estado".

Para ver estado de todos: `mem_search(query: "dept-status")`.

## Convenciones

- GDD en `GDD_DungeonParty.md` — consultar antes de decisiones de diseño
- Godot standalone en la raíz del proyecto
- Estilo visual: low-poly, modelos simples, texturas planas
- Herencia BasePlayer para todas las clases
- Señales para comunicar estado entre sistemas
- @export para todo valor de balance
- Grupos para identificar entidades
- Explicar términos de Git con mini-definición entre paréntesis

## Notas de Sesión

- **2026-04-07**: Prototipo inicial — movimiento, combate melee, enemigos, HUD.
- **2026-04-07 (sesión 2)**: Clase Mago (proyectil + rayo canalizado), sistema de stats (STR/INT/DEX/DEF/VIT), defensa, resistencias elementales, regeneración HP/MP, sprint, agacharse, refactor a herencia BasePlayer, repo GitHub creado, 10 issues creados.
- **2026-04-12**: Expansión masiva — 5 clases jugables (Warrior/Mage/Archer/Cleric/Necromancer), 15+ tipos de enemigos (bandit, slime+mini_slime, golem, wolf, bird, fox, etc.), sistema loot completo (drops, chests, loot table), inventory+equipment con drag&drop, torch system, target frame MMO, knockback, save system JSON, piso 1 pradera en desarrollo, GUT testing addon + 6 test files, docs extensivos en `game/docs/`.
- **2026-04-12 (coordinación)**: Setup worktrees A/B/C/D + hooks semáforo conflictos + dept-status protocol. Tag `v0.1-prototype`.
- **2026-04-12 (refactor 1a)**: Extracción `DamageFormula` + `Progression` a `game/shared/stats/`. MMO-ready. Commit `1a17853`.
- **2026-04-14**: Skills system canon v1.0 — `_system.md` (skill points + ascendencia lvl 25 + recursos únicos). 6 per-class docs base + drop_ownership canon v1.
- **2026-04-15**: Drop ownership canon v2 post Judgment Day — party-first model, floor+random reparto, timers 180/120/300s, bind items, seeded RNG. Tag `v0.4`.
- **2026-04-16**: Mimic enemy completo (issue #60 — state machine + mesh + canon + integration), equipment context menu unequip (#58), tooltip RichTextLabel (#59), skills MIGRATE 6 per-class al `_system.md` v1.0 + `_synergies.md` (15 combos cross-class, #46).
- **2026-04-17**: Class lore canon (#47 — 6 docs lore + identidad cultural, órdenes preexistentes). World canon chileno central (`_world_canon.md`) + naming chileno (Pire-Mapu/Nahuelbuta/Lota/San Pedro de Atacama/Tres Cumbres volcanes/Quicaví-Caleuche) + Necromancer rewrite DARK (excepción tonal canon — pisa "moralmente gris" anterior).
- **2026-04-18**: Tag `v0.5` — mergeadas 3 ramas: C `refs-approved-monster-feast` (world_references v1.1 + framework_audit v1.0 con 11 gaps schema), B `skills-schema-p0-fix` (SkillResource schema P0/P1 completo + 430L tests + 4 warrior .tres re-wired), D `mage-skill-icons` (4 SVG canon Fase 2 prep). Playtest reveló 3 gaps polish Fase 1: VFX faltantes (issue #63), embestida teletransporte (issue #64), no skill tree UI (issue #65). 3 ramas dept/* nuevas asignadas en paralelo: `dept/art/warrior-vfx-fase1`, `dept/gameplay/warrior-skills-polish`, `dept/design/skill-tree-ui-spec`.

## Canon de Design Vigente

**Siempre consultar antes de refactorizar sistemas de skills, stats, loot, o lore/worldbuilding:**

- `game/docs/lore/_world_canon.md` (world canon central + naming chileno + Necromancer DARK, 2026-04-17)
- `game/docs/lore/_class_lore_{warrior,mage,archer,cleric,necromancer,danzante_sombras}.md` (lore per-class v2.0 naming chileno, 2026-04-17 — Necromancer v2.0 DARK)
- `game/docs/skills/_system.md` (skills system v1.0, 2026-04-14)
- `game/docs/skills/{warrior,mage,archer,cleric,necromancer,danzante_sombras}.md` (per-class v2.0, 2026-04-16)
- `game/docs/skills/_synergies.md` (combos cross-class, 2026-04-16)
- `game/docs/skills/_status_effects.md`
- `game/docs/balance_v2.md` (curvas + fórmulas compound)
- `game/docs/balance/_drop_ownership_canon.md` (v2.0, 2026-04-16)
- `game/docs/balance/_mimic.md` (v1.0, 2026-04-16)
- `game/docs/balance/p1_loot_table.md`

**ESTADO COMPLETO DEL PROYECTO en `PROJECT_STATE.md`** (snapshot 2026-04-12, parcialmente desactualizado por skills/mimic post 14-16).
