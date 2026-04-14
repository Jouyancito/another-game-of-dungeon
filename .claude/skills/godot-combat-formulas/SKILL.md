---
name: godot-combat-formulas
description: Enforce canon combat math from balance_v2.md in Dungeon Party GDScript. Trigger when editing .gd files that compute damage, crit, resistances, DEF reduction, HP/MP maxes, or XP curves. Validates combat code against DamageFormula + Progression single source of truth.
type: pattern
---

# Godot Combat Formulas (Dungeon Party)

Canon: `game/docs/balance_v2.md`. Source of truth: `game/shared/stats/damage_formula.gd` + `game/shared/stats/progression.gd`. NUNCA inlinear math en `player.gd`, `mage.gd`, `enemy_basic.gd`, skills — siempre rutear por estos statics.

## Trigger

`.gd` que mencione: `damage`, `dmg`, `crit`, `resist`, `DEF`, `defense`, `armor`, `max_hp`, `max_mp`, `VIT`, `xp_for_level`, `level_up`, `knockback`. También `.tres` de weapons/enemies.

## Fórmulas canon (v2 compound — reemplaza v1 linear)

### Daño físico
```gdscript
var raw := DamageFormula.physical_v2(base_dmg, weapon_dmg, total_str, level, class_mult)
var final := DamageFormula.apply_armor_v2(raw, target_def, attacker_level)
```
Fórmula: `(base + weapon) * (1 + STR*0.02) * (1 + level*0.03) * class_mult`.
Armor: `DEF / (DEF + attacker_level * 50)`, aplicado como `raw * (1 - reduction)`.
**Piso daño = 1.0** post-reducción.

### Daño mágico
```gdscript
var raw := DamageFormula.magic_v2(base_dmg, weapon_dmg, total_int, level, class_mult)
var final := DamageFormula.apply_elemental_resistance(raw, resistance, has_aura_de_resguardo)
```
Resist cap: **75%** base, **80%** si Healer-Buffer con "Aura de Resguardo" vivo < 20m.
Si el Buffer muere, el cap cae instant — NO cachear el bool, re-leer por hit.
Asintótica: `res_efectiva = cap * (1 - exp(-0.025 * raw_res))`.

### Daño DEX
`physical_v2` substituyendo DEX por STR. Archer + skills DEX-scaling.

### HP / MP máximos
```gdscript
max_hp = base_hp + (VIT * 5) + pow(VIT, 1.3) * 0.8 + (level * 8)
max_mp = base_mp + (INT * 3) + pow(INT, 1.2) * 0.5 + (level * 5)
```
Vive en `Progression.max_health(base, vit, level)` / `max_mana(base, int_stat, level)`. NUNCA recomputar inline.

### Curva XP (piecewise)
```gdscript
Progression.xp_for_level_v2(level)
# <25:  100 * 1.15^(level-1)      — Tier I hook
# <50:  3000 * 1.12^(level-25)    — Tier II gradual
# <75:  45000 * 1.10^(level-50)
# <95:  500000 * 1.08^(level-75)
# else: 2500000 * 1.05^(level-95)
```
Legacy `1.15^n` constante es OBSOLETA más allá del nivel 25.

### Knockback
```gdscript
var mass_ratio := attacker_mass / maxf(target_mass, 0.01)
var force := damage_dealt * mass_ratio * KNOCKBACK_COEFF
force *= maxf(0.0, 1.0 - target.knockback_resistance)
```
Escala con daño post-reducción, no raw. Bosses `knockback_resistance >= 0.9`.

## Validators — mentales antes de escribir

1. **¿Computás daño?** → `DamageFormula.physical_v2 / magic_v2 / dex`. NO escribir `base + STR*2` directo.
2. **¿Aplicás defensa?** → `apply_armor_v2(raw, def, attacker_level)`. v1 `max(raw - DEF, 1)` OBSOLETA.
3. **¿Aplicás resist?** → `apply_elemental_resistance(raw, res, has_aura)`. Cap 75/80, nunca hardcodear otro.
4. **¿HP/MP?** → `Progression.max_health / max_mana`. Nunca `base + VIT*5` solo.
5. **¿XP?** → `Progression.xp_for_level_v2(level)`.
6. **Piso daño:** todo path final clampear `>= 1.0`.
7. **Class multipliers:** Warrior 1.5 phys, Mage 1.5 magic, Archer 1.4 dex, Necro 1.3 magic, Healer 1.0. En `GameConstants`.

## Red flags a rechazar

- `damage = stat * 2 + base` inline → mover a DamageFormula.
- `if res > 0.75: res = 0.75` hardcoded → usar `GameConstants.RESIST_CAP` + aura check.
- `max_hp = base + vit * 5` sin term nivel → undersized alto nivel.
- `xp_next = xp_next * 1.15` → switch a piecewise.
- Math duplicado cliente/servidor → DEBE vivir en `shared/stats/` (MMO-ready).

## Referencias

- `game/shared/stats/damage_formula.gd` — statics
- `game/shared/stats/progression.gd` — curvas
- `game/docs/balance_v2.md` — canon, TTK, migración
- `CLAUDE.md` → "Stats Base por Clase"
- Companion: `godot-balance-curves` para diseñar curvas NUEVAS
