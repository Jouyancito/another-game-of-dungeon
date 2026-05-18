# Dungeon Party (Another Game of Dungeon)

Dungeon crawler cooperativo en primera persona, 1-6 jugadores. Torre de 5 pisos temáticos con dificultad progresiva, loot, clases y progresión persistente.

**Repo**: https://github.com/Jouyancito/another-game-of-dungeon (privado)

## ⚠️ Scope Reset 2026-05-18

Plan post-reinicio acordado en `juego dungeon.md` (Desktop). Filtro vigente para TODA decisión:

> "¿Esto acerca o aleja de los 5 mapas publicables?"

**Stop**: specs nuevas (professions, ascendencia, evolución skill, taverna v2), más clases pulidas, workflow meta nuevo, canon expansion.
**Start**: vertical slice 10 min grabado · MVP reducido (1 mapa, 3 clases Warrior/Mage/Archer, 1 boss, ~15 enemies, lvl cap 15) · Steam wishlist · demo itch.io 30 días.
**Construcción**: incremental tipo Valheim / Hades / Vampire Survivors early access.

Las 6 clases siguen siendo canon de lanzamiento — el recorte a 3 es solo alpha demo.

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

## Estado Actual — Alpha early-access (post scope reset 2026-05-18)

### Implementado

- **Herencia de clases**: BasePlayer → Warrior / Mage / Archer / Cleric / Necromancer / Danzante de Sombras (6 clases, Fase 1 con skills .tres canon)
- **Skills Fase 1 cableadas**: Warrior + Mage + ACN parity (Archer/Cleric/Necromancer con class_mult + ClassResource) + Danzante (combo points + 4 skills + stealth)
- **Movimiento**: WASD + mouse look, salto, gravedad, sprint (Shift), agacharse (Ctrl)
- **Sistema de stats**: STR, INT, DEX, DEF, VIT con valores base por clase (ver canon `balance_v2.md`)
- **Fórmulas de daño**: migradas a canon v2 (`game/shared/stats/damage_formula.gd` + `progression.gd`)
- **Defensa**: DEF reduce daño físico (mínimo 1), resistencias elementales cap 75%
- **Regeneración**: vida fuera de combate, maná siempre
- **Downed state**: crawl + last breath bar + revive (R respawn fallback)
- **Torch**: slot off_hand, F encender/apagar, auto-on al equipar
- **15+ enemigos**: bandit, slime + mini_slime, golem, wolf, bird, fox, mimic, etc.
- **Loot completo**: drops + chests + loot table + drop ownership canon v2 (party-first, timers, bind items, seeded RNG)
- **Inventory/Equipment**: drag&drop, stack count label, context menu unequip, RichTextLabel tooltip, paper-doll D2-style
- **Character window**: tabs stats / habilidades / equipo
- **Character select**: D2-style con preview 3D + highest_floor
- **Quest system**: QuestCatalog autoload + SkillResource §12.2 schema
- **Audio + damage numbers + camera shake + hit stop + cooldown swipe** (feel MMO)
- **Visual pipeline tier1**: toon shader + env_pradera + lightmap + materials preset
- **Animation pipeline**: AnimationTree programático + FootIK
- **HUD**: barras vida/maná/XP, hotbar 8 slots, crosshair, pantalla de muerte
- **Save system**: JSON local
- **GUT testing addon** + tests (warrior skills, danzante combo, damage formulas)

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

## Próximos Pasos (plan post-reinicio 2026-05-18)

Orden estricto, antes de tocar código nuevo:

1. ✅ Sync `CLAUDE.md` a canon vigente (este edit).
2. Archivar specs huérfanas (taverna, skill tree, professions) a `docs/_archive/` con nota "revivir post-alpha".
3. Cerrar/relabelar issues #1, #2, #4, #5 (features ya implementadas, issue tracker desactualizado).
4. Definir EXPLÍCITAMENTE los 5 mapas alpha (cuáles biomas, qué enemies, qué boss). Doc corto, 1 página.
5. Grabar primer vertical slice 10 min del piso 1 actual para baseline.

Vigilancia: ante tentación de meta-trabajo (más agentes, retros, canon), preguntar: *"¿Esto sale en el video de 10 min del demo?"* Si no → posponer.

## Departamentos — Status Tracking (DESACTIVADO 2026-05-09)

Setup multi-worktree A/B/C/D archivado en `docs/_archive/dept-workflow/`. Reactivable cuando haya 2+ agentes trabajando en paralelo. Mientras sea solo dev + 1 Claude → single-worktree. Ver `docs/_archive/dept-workflow/README.md` para reactivación.

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
- **2026-04-18 (sesión 2, dept C)**: Judgment Day gap-filling — 4 per-class Fase 1 specs + taverna spec. Creados: `_fase1_spec_archer.md` (4 skills canon + Concentración recurso + schema P0/P1 completo), `_fase1_spec_cleric.md` (4 skills canon + Fe recurso + excepción 3 ramas), `_fase1_spec_necromancer.md` (4 skills canon + Vida-recurso + SummonResource skeleton_base spec + framing DARK), `_fase1_spec_danzante.md` (4 skills FROM SCRATCH — única clase sin .gd/.tscn, spec completa con nota arquitectura Combo Points), `_taverna_spec.md` (layout ASCII + 3 NPCs canon: Millaray/Kutrán/Mensajera Lefkén + save integration + transiciones). Rama: `dept/design/fase1-specs-wave2`.
- **2026-04-18 (wave 3)**: Warrior VFX Fase 1 (charge / war_cry / punch_impact / perfect_block) + vfx_canon doc · audio + damage numbers + camera shake + hit stop + cooldown swipe (feel MMO) · migración fórmulas a `balance_v2` canon · fix embestida wall raycast + war_cry exploit · Mage Fase 1 4 skills .tres + hotbar default + VFX hooks · downed state stub.
- **2026-04-21**: Visual pipeline tier1 — toon shader + env_pradera + lightmap + materials preset · tier 2 animation pipeline (AnimationTree programático + FootIK) · art direction bible v1.0 (6 clases + 5 pisos + toon canon) · skills §12 reconciliación schema con P0/P1 wave2.
- **2026-04-22**: QuestCatalog autoload + SkillResource §12.2 schema fields + naming canon quests.
- **2026-04-23**: **World canon v2.0 REWRITE — hub planetario multicultural** (descarta v1.0 chilena). Character_select D2-style con preview 3D + highest_floor · Danzante Fase 1 (combo points + stealth + 4 skills canon) · downed crawl + last breath bar + torch slot UI · MarkBehavior schema reserve · enemy alert / aggro fixes wave1.
- **2026-04-24**: ACN parity (Archer/Cleric/Necromancer class_mult + ClassResource + 13 skills .tres Fase 1) · character_window tabs (stats / habilidades / equipo) · 4 SVG icons Danzante (toon canon) · stack count label inventory (D2 esquina inf-der) · refactor torch → off_hand slot (reserva `light` para quick_use) · pre-consume combo atomic + VFX Danzante TODO.
- **2026-04-25 → 04-26**: Track Godot 4 `.uid` metadata · ignore `.claude/` coordination state · ignore `.env` files.
- **2026-05-08**: Batch playtest fixes — skills + enemy + ui (JD-cleared).
- **2026-05-09**: Inventory clamp Y + dup-on-doubleclick + golem aggro super fix · Professions tab DRAFT (PAUSADO scope reset) · **Dept multi-worktree DESACTIVADO** — archivo `docs/_archive/dept-workflow/`.
- **2026-05-18 (scope reset)**: Retrospectiva 60 días. Diagnóstico: construyendo engine RPG profundo, no juego publicable. Decisiones: Godot 4.6 stay · alpha = 5 mapas · MVP demo = 1 mapa / 3 clases (W/M/A) / 1 boss / 15 enemies / lvl cap 15 · objetivo Steam wishlist + itch.io 30 días. Plan completo en `juego dungeon.md` (Desktop). Sync `CLAUDE.md` ejecutado hoy.

## Canon de Design Vigente

**Siempre consultar antes de refactorizar sistemas de skills, stats, loot, o lore/worldbuilding:**

- `game/docs/lore/_world_canon.md` (**v2.0 hub planetario multicultural, 2026-04-23 — REWRITE completo, descarta v1.0 chilena**)
- `game/docs/lore/_class_lore_*.md` (**PAUSADOS** — esperan realineación con world_canon v2.0 post-alpha)
- `game/docs/skills/_system.md` (skills system v1.0, 2026-04-14) + §12 schema reconciliation (2026-04-21)
- `game/docs/skills/{warrior,mage,archer,cleric,necromancer,danzante_sombras}.md` (per-class v2.0, 2026-04-16)
- `game/docs/skills/_fase1_spec_{archer,cleric,necromancer,danzante}.md` (Fase 1 specs implementadas)
- `game/docs/skills/_synergies.md` (combos cross-class, 2026-04-16)
- `game/docs/skills/_status_effects.md`
- `game/docs/balance_v2.md` (curvas + fórmulas compound — fuente de damage_formula.gd + progression.gd)
- `game/docs/balance/_drop_ownership_canon.md` (v2.0, 2026-04-16)
- `game/docs/balance/_mimic.md` (v1.0, 2026-04-16)
- `game/docs/balance/p1_loot_table.md`
- `game/docs/art/_art_canon.md` (v2.0 unified canon 2026-05-18 — merges art_direction + visual_bible + _art_direction_bible · adds LOTR/Metin2/Dark and Darker/SLF/Tensura refs · Kimetsu canon for skill VFX)

**Specs en hold scope-reset** (revivir post-alpha): archivadas en `docs/_archive/post-alpha-specs/` (`_taverna_spec.md`, `_skill_tree_spec.md`, `professions_spec.md` + README con rationale). Ascendencia y evolución skill viven en `_system.md` v1.0 — siguen siendo canon, solo se posponen para implementación post-alpha.

**ESTADO COMPLETO DEL PROYECTO en `PROJECT_STATE.md`** (snapshot 2026-04-12, desactualizado — `CLAUDE.md` es la fuente de verdad hasta nuevo snapshot).
