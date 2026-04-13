# Boss Spec — Rey Slime (Piso 1)

Spec técnica de implementación. Diseño de gameplay fuente: `biome_prairie.md` §4.
Target: worktree D, skill `dept-gameplay`. Scope: primera sesión Fases 1-2, segunda sesión Fases 3-4 + polish.

## Archivos a crear

```
game/scenes/enemy/king_slime.gd       # lógica state machine + fases
game/scenes/enemy/king_slime.tscn     # escena con CharacterBody3D + modelo + Areas
```

**NO crear**: modelo 3D dedicado. Reusar `enemy_model_builder.gd` o esfera CSG verde translúcida escalada 3m.

## Node tree (tscn)

```
KingSlime (CharacterBody3D) — script king_slime.gd
├── CollisionShape3D (CapsuleShape3D r=1.5, h=3.0)
├── Mesh (CSGSphere3D r=1.5, material translúcido verde)
│   └── Crown (CSGBox pequeño, metallic, DENTRO de la esfera)
├── HitboxArea (Area3D, layer enemies)
├── DetectRange (Area3D, radio 40m)
├── AttackRange (Area3D, radio 4m)
├── ShockwaveArea (Area3D, radio 3m, monitoring off hasta Rebote land)
├── AcidPoolSpawnPoint (Node3D) — marker para charcos (Fase 3+)
├── PhaseTimer (Timer) — cooldowns ataques
├── SummonTimer (Timer) — invocación mini-slimes
└── AudioStreamPlayer3D
```

## Stats (constantes, @export)

```gdscript
@export var max_hp: float = 600.0
@export var base_damage: float = 10.0
@export var defense: float = 8.0
@export var xp_reward: int = 100
@export var move_speed: float = 3.0
@export var knockback_resistance: float = 0.8
@export var mass: float = 8.0
```

## State machine — fases

```gdscript
enum Phase { ONE, TWO, THREE, FOUR }
var current_phase: Phase = Phase.ONE

func _update_phase():
    var hp_pct = hp / max_hp
    var new_phase = current_phase
    if hp_pct <= 0.25: new_phase = Phase.FOUR
    elif hp_pct <= 0.50: new_phase = Phase.THREE
    elif hp_pct <= 0.75: new_phase = Phase.TWO
    else: new_phase = Phase.ONE
    if new_phase != current_phase:
        _on_phase_transition(current_phase, new_phase)
        current_phase = new_phase
```

Emitir `signal phase_changed(phase)` para HUD/FX.

## Ataques — tabla exacta

| Ataque | Fase disponible | Cooldown | Telegraph | Daño | Efecto extra |
|--------|-----------------|----------|-----------|------|--------------|
| Rebote | 1+ | 4.0s | Sombra suelo 1.5s | 10 + AoE 3m | Knockback suave |
| Embestida | 1+ | 5.0s | Compresión visual 1.0s | 12 | Knockback fuerte |
| Escupitajo | 1+ | 3.0s | Mejilla infla 0.8s | 8 | Slow 30% por 2s |
| Escupitajo abanico | 2+ | 3.5s | Mejilla 0.8s | 8 x3 proyectiles | Slow 30% |
| Combo Rebote x3 | 3+ | 7.0s | Sombra 1s primer salto | 10 c/u | Saltos más rápidos |
| Charco ácido | 3+ (on-landing) | — | — | 3/s por 5s | Radio 2m desde punto aterrizaje |
| Onda de choque | 4 | 10.0s | Infla pre-onda 0.6s | 8 | AoE 5m |
| Último aliento | 4 (hp ≤ 5%) | 1 vez | Infla 3.0s | 20 | AoE 8m — suicida |

**Ritmo global**: un ataque cada 3-4s fase 1. Cooldowns se reducen 15% por fase (hardcode multiplier).

## Selección de ataque — weighted

```gdscript
func _pick_attack() -> String:
    var pool: Array = []
    match current_phase:
        Phase.ONE:
            pool = ["rebote", "embestida", "escupitajo"]
        Phase.TWO:
            pool = ["rebote", "embestida", "escupitajo_abanico", "escupitajo"]
        Phase.THREE:
            pool = ["combo_rebote", "embestida", "escupitajo_abanico"]
        Phase.FOUR:
            pool = ["combo_rebote", "embestida", "escupitajo_abanico", "onda_choque"]
    return pool.pick_random()
```

Preferir variedad: no repetir mismo ataque 2 veces seguidas.

## Invocación mini-slime

Fase 2: cada 20s → 3 mini-slimes.
Fase 3: cada 15s → 5 mini-slimes.
Fase 4: desactivada.

**Mecánica reabsorción**: si mini-slime vivo dentro radio 4m cuando expira `reabsorb_window` (10s), despawnea y cura boss +30 HP.

```gdscript
func _spawn_mini_slimes(count: int):
    for i in count:
        var mini = MINI_SLIME_SCENE.instantiate()
        mini.position = global_position + _random_xz_offset(3.0)
        get_parent().add_child(mini)
        mini.add_to_group("king_slime_adds")
        # timer interno: si vivo en 10s y cerca de boss → reabsorber
```

Requiere que `mini_slime.gd` emita `died` signal y expose `position`.

## Charcos ácidos

Crear escena `acid_pool.tscn` (simple: CSGCylinder verde + Area3D DoT). Fase 3+ al aterrizar Rebote. Duración 5s, radio 2m, DoT 3/s.

Si no existe, usar decal provisorio + Area3D sin mesh dedicada.

## Modo furia (Fase 4 entrada)

```gdscript
func _enter_phase_four():
    move_speed *= 1.5
    # reduce todos los cooldowns de ataque 33%
    # material shader: emisión roja pulse
    summon_timer.stop()
```

## Último aliento

Trigger: `hp <= max_hp * 0.05` (5%). Una sola vez. Pause AI, infla 3s (telegraph VFX), explota 20 dmg AoE 8m, muere.

## Loot (POST-merge B)

**NO implementar en esta sesión.** Esperar merge Fase 1b. Luego:

```gdscript
# en loot_table.gd (post-refactor en shared/systems/)
"king_slime": [
    { "item": "corona_oxidada", "chance": 1.0 },
    { "item": "nucleo_gelatina_real", "chance": 1.0 },
    { "item": "random_rare_equipment", "chance": 0.80 },
    { "item": "random_epic_equipment", "chance": 0.15 },
    { "item": "recipe_elasticidad", "chance": 0.30 },
]
```

Items `corona_oxidada`, `nucleo_gelatina_real`, `recipe_elasticidad` **no existen en ItemDatabase** — crearlos como parte del wiring post-merge.

## Hook arena boss

`floor1_prairie.gd` línea ~800 `_build_boss_arena()` — al final, instanciar:

```gdscript
var king = preload("res://game/scenes/enemy/king_slime.tscn").instantiate()
king.position = boss_arena_center + Vector3(0, 1.5, 0)
add_child(king)
```

Flag para no spawnar hasta que el jugador entre al área (trigger Area3D grande en entrada arena).

## Scope por sesión

### Sesión 1 (primera delegación D)

- [ ] Escena `king_slime.tscn` con node tree base
- [ ] Script `king_slime.gd` extends `base_enemy.gd`
- [ ] Stats + state machine 4 fases (transiciones OK)
- [ ] Ataques Fase 1: Rebote + Embestida + Escupitajo (solo estos 3)
- [ ] Hook arena boss — instanciar en `floor1_prairie.gd`
- [ ] Smoke test: boss aparece, ataca, muere, transiciona fases

### Sesión 2 (post-sesión 1)

- [ ] Ataques Fase 2: escupitajo abanico + invocación mini-slimes + reabsorción
- [ ] Fase 3: combo rebote x3 + charco ácido
- [ ] Fase 4: modo furia + onda de choque + último aliento
- [ ] Material shader transparencia progresiva
- [ ] VFX telegraphs

### Sesión 3 (post-merge B)

- [ ] Loot wiring: 5 items en ItemDatabase + entrada en LootTable
- [ ] Corona Oxidada como quest item
- [ ] Test drop completo

## Balance — notas

Cooldowns y daño están tuneados para **1 jugador solo**. Multiplayer se ajusta con `difficulty_multiplier` global (post-MVP).

Usar skill `godot-balance-curves` (worktree C la crea hoy) para validar cooldown curve entre fases.

## Testing

GUT tests sugeridos:
- `test_king_slime.gd` — spawn, phase transitions at HP thresholds, attack pool per phase, death signal
- Smoke test manual en `floor1_prairie.tscn`: arena → entrar → boss spawns → combat → muere

## Red flags

- **NO** duplicar lógica de `base_enemy.gd`. Override solo lo necesario.
- **NO** hardcodear paths en tscn — usar `@export PackedScene MINI_SLIME_SCENE`.
- **NO** tocar `loot_table.gd` durante sesiones 1-2 (B está moviendo el archivo).
- **NO** olvidar `add_to_group("enemies")` — target frame y ataques dependen.
