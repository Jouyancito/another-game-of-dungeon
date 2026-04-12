# Dungeon Party — Estado Completo del Prototipo (2026-04-12)

Snapshot exhaustivo del proyecto para preservar contexto del prototipo inicial. Fuente de verdad para refactors/releases futuros. Complementa `CLAUDE.md` (convenciones) y `GDD_DungeonParty.md` (diseño).

## Snapshot git

- Commit actual: `1a17853` (post Fase 1a refactor)
- Tag estable previo: `v0.1-prototype` (commit `bda8ed2`)
- Branch: `master`
- Remote: https://github.com/Jouyancito/another-game-of-dungeon

## Estructura completa del proyecto

### Autoloads (`project.godot`)

| Autoload | Script | Rol |
|---------|--------|-----|
| `GameManager` | `scripts/game_manager.gd` | Estado global sesión: personaje seleccionado, monedas, UI setup |
| `SaveManager` | `scripts/save_manager.gd` | Persistencia perfiles (JSON), CLASS_DEFAULTS por clase |
| `ItemDatabase` | `scripts/item_database.gd` | Catálogo de items (stats, slots, types) |
| `LootTable` | `scripts/loot_table.gd` | Spawn loot por enemigo/piso |
| `Journal` | `scripts/journal.gd` | Entradas de lore/quests |
| `TitleTracker` | `scripts/title_tracker.gd` | Logros (level-ups, deaths) |

### Clases jugables (5)

| Clase | Script | Escena | Stats destacados |
|-------|--------|--------|------------------|
| Warrior | `player.gd` | `player.tscn` | STR 12, DEF 10, VIT 10 — puñetazo pesado + combo rápido |
| Mage | `mage.gd` | `mage.tscn` | INT 12, VIT 5 — proyectil energético + rayo canalizado |
| Archer | `archer.gd` | `archer.tscn` | DEX alto — arco con flechas (`arrow_projectile`) |
| Cleric | `cleric.gd` | `cleric.tscn` | (por inspeccionar — healer/buffer) |
| Necromancer | `necromancer.gd` | `necromancer.tscn` | INT alto — `necro_projectile` |

Base común: `base_player.gd` (798 líneas) con herencia + signal-driven HUD.

### Enemigos (15+ tipos)

- **Básicos**: `enemy_basic` (cubo rojo legacy), `bird`, `fox`, `goat`, `rat`, `wolf`
- **Hostiles**: `bandit_archer`, `bandit_melee`, `scorpion`, `snake`, `wasp`
- **Especiales**: `slime` (+`mini_slime` por split al recibir daño), `golem` (knockback fuerte), `hawk`, `turtle`
- **Base**: `base_enemy.gd` (parent abstracto) + `enemy_model_builder.gd` (constructor visual procedural)
- Todos en grupo `"enemies"` para detección por BasePlayer (target frame, ataques)

### Proyectiles

- `arrow_projectile` — Archer
- `mage_projectile` — Mage (bolita energía)
- `necro_projectile` — Necromancer

### Sistemas de juego

- **Inventory** (`scripts/inventory.gd`) — grilla con auto-place, stack, has_space_for, serializable
- **Equipment** (`scripts/equipment.gd`) — slots (weapon, armor, ring_1, ring_2...), resolve_slot, get_total_bonuses, get_weapon_damage
- **Item drops** — `item_drop.tscn` (pickup por E), `gold_drop.tscn` (auto-pickup), labels flotantes, cone/range detection
- **Loot chests** — `loot_chest.tscn` (interactable, open by E)
- **Loot table** — probabilidades por enemigo/piso
- **Torch system** — equipar luz desde inventario (F toggle), OmniLight3D con flicker, duración, `light_duration`/`light_color`/`light_energy` stats
- **Target frame MMO** — HUD muestra nombre/HP/tier del enemigo apuntado dentro de cono 14°, LOS checked
- **Pickup hint** — prompt "[E] para recoger/interactuar" en HUD según apuntado
- **Knockback** — física vectorial con `knockback_resistance` y `mass`; usado por golem/bosses/slime split
- **Save system** — `user://saves/profile.json` con personajes múltiples, slot selection
- **Stats** — 5 atributos (STR/INT/DEX/DEF/VIT) + 5 resistencias elementales (fire/ice/lightning/poison/void, cap 75%)
- **XP/Level** — curva 1.15^n, 3 stat points por level, level-up signal
- **Shared stats formulas** — extraídas a `game/shared/stats/` (DamageFormula, Progression)

### HUD & UI

- **HUD** (`hud.tscn`) — barras HP/MP/XP, hotbar 8 slots, crosshair, pickup hint, target frame, pantalla muerte
- **ViewModel** / **WorldModel** (`view_model.gd`, `world_model.gd`, `mannequin_builder.gd`) — brazos FPS + cuerpo 3ra persona
- **UIs principales**:
  - `main_menu.tscn` — menú inicial
  - `character_select.tscn` — selector de personaje guardado
  - `class_selector.tscn` — elegir clase para nuevo personaje
  - `character_window.tscn` — stats + assign points
  - `inventory_ui.tscn` — grilla drag&drop
  - `equipment_panel.tscn` — slots equipables con drop displacement
  - `journal_ui.tscn` — lore/quest log
  - `pause_menu.tscn` — pausa
  - `character_preview.gd` — preview 3D del personaje
  - `draggable_window.gd` — window base mobile

### Niveles

- `floor1_prairie.tscn` — Piso 1 (pradera) en desarrollo
- `main.tscn` — arena 20x20 legacy (prototipo inicial)
- 4 pisos más planeados (Bosque, Hielo, Tormenta, Dimensión Rota)

### Testing

GUT addon instalado (`addons/gut/`). Tests existentes:
- `test_base_player.gd`
- `test_classes.gd`
- `test_enemy_basic.gd`
- `test_hud.gd`
- `test_projectile.gd`
- `test_save_manager.gd`

### Shared (post-refactor Fase 1a)

- `shared/stats/damage_formula.gd` — physical/magic/dex damage, defense, elemental resist
- `shared/stats/progression.gd` — max_health, max_mana, xp_for_level, hp/mp regen rates

## Layers de física

- Layer 1: World
- Layer 2: Player
- Layer 3: Enemies
- Cull masks: world (1), viewmodel (2), worldmodel (4)

## Input maps configurados

`move_forward/backward/left/right`, `jump`, `sprint`, `crouch`, `interact` (E), `toggle_torch` (F), click izquierdo (ataque)

## Docs existentes (`game/docs/`)

- `art_direction.md`, `visual_bible.md`, `shader_system.md`
- `biome_prairie.md`, `prairie_living_world.md`
- `enemy_tier_system.md`, `tier_1_pool.md`
- `floor_transitions.md`, `tower_biome_system.md`
- `map_metrics.md`, `procedural_ecology.md`
- `party_activities.md`, `stats_system.md`

## Refactor pendiente (scope ampliado)

### Fase 1 — Shared (data + lógica pura)
- [x] **1a**: DamageFormula + Progression (DONE, commit 1a17853)
- [ ] **1b**: Mover `inventory.gd`, `equipment.gd`, `item_database.gd`, `loot_table.gd` → `shared/systems/`
- [ ] **1c**: Mover `CLASS_DEFAULTS` (en SaveManager) → `shared/classes/class_base_stats.gd`
- [ ] **1d**: Extraer constantes mágicas (cap resistencia 75%, stat points per level 3, pickup range, target frame cone) → `shared/constants.gd`

### Fase 2 — Server (autoridad)
- [ ] **2a**: `combat_resolver.gd` — `resolve(attacker, target, damage_spec) -> DamageResult`
- [ ] **2b**: Mover `base_enemy.gd` + todos los enemigos → `server/ai/`
- [ ] **2c**: `loot_generator.gd` que use `LootTable` shared
- [ ] **2d**: `save_manager.gd` — mantener pero preparar split client/server (meta-progression server-authoritative)

### Fase 3 — Client (presentación)
- [ ] **3a**: Mover `base_player.gd`, clases, view_model, world_model, mannequin_builder → `client/player/`
- [ ] **3b**: Mover `hud/`, UIs → `client/ui/`
- [ ] **3c**: Mover visuales de proyectiles → `client/projectile/` (lógica de daño stays server)
- [ ] **3d**: Torch system (visual client, duración server)
- [ ] **3e**: Fix paths en TODAS las `.tscn`

### Fase 4 — Verificación
- [ ] Abrir Godot, correr juego
- [ ] Correr tests GUT
- [ ] Probar save/load, combate, loot, levels
- [ ] Fix paths rotos

### Post-refactor — Tareas pendientes originales
- Setup testing GUT (ya instalado, falta integrar en CI/hook?)
- Saves JSON legible (ya están? verificar si usa ConfigFile o JSON)
- Convenciones memoria engram (decisiones + balance log)
- Review anti-patterns (hardcoded values, _physics_process)
- Backup externo + hygiene branches

## Próximas decisiones a tomar

1. **Timing del refactor completo**: sesiones dedicadas o incremental entre features?
2. **Multiplayer timing**: ¿cuándo entramos a networking? Fase 1 implementada local-first, OK.
3. **Balance curves**: actualmente todas fórmulas lineales. ¿Ajustar a curvas cuadráticas para stats más significativos a alto nivel?
4. **Content lock**: ¿cerramos set de clases en 5 o agregamos más (Rogue, Paladin)?
5. **Boss design**: trono viscoso ya mencionado, ¿lista de bosses por piso?
