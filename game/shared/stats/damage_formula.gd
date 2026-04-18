class_name DamageFormula
extends RefCounted

# Fórmulas puras de daño. Sin dependencias en nodos Godot.
# Diseño MMO-ready: server y client usan las MISMAS fórmulas para predicción sincronizada.
#
# Inputs: valores ya resueltos (stats totales, weapon damage, etc.)
# Outputs: damage final (float)
#
# NO leen del equipment/inventory — eso es responsabilidad del caller.
#
# Canon vigente: balance_v2.md §2.3-2.5 — fórmulas compound MMO.
# v1 (`physical`, `magic`, `dex`, `apply_physical_defense`) están DEPRECATED y
# redirigen a v2 con class_mult=1.0 y level=1 para no romper callers legacy.


# ─── v2 compound (CANON balance_v2.md §2.3-2.5) ──────────────────────────────

## Daño físico compound — canon §2.3.
##   stat_mult  = 1 + STR * 0.02
##   level_mult = 1 + level * 0.03
##   final      = (base + weapon) * stat_mult * level_mult * class_mult
static func physical_v2(base_dmg: float, weapon_dmg: int, total_str: int, level: int, class_mult: float = 1.0) -> float:
	var stat_mult: float = 1.0 + float(total_str) * 0.02
	var level_mult: float = 1.0 + float(level) * 0.03
	return (base_dmg + float(weapon_dmg)) * stat_mult * level_mult * class_mult


## Daño mágico compound — canon §2.4 (misma curva, INT en vez de STR).
static func magic_v2(base_dmg: float, weapon_dmg: int, total_int: int, level: int, class_mult: float = 1.0) -> float:
	var stat_mult: float = 1.0 + float(total_int) * 0.02
	var level_mult: float = 1.0 + float(level) * 0.03
	return (base_dmg + float(weapon_dmg)) * stat_mult * level_mult * class_mult


## Reducción por armor self-capping — canon §2.5.
##   reduction = DEF / (DEF + attacker_lvl * 50)
## Retorna 0..<1 (nunca 100% reducción — self-capping).
static func armor_reduction_v2(total_def: int, attacker_level: int) -> float:
	var k: float = float(attacker_level) * 50.0
	if total_def <= 0 and k <= 0.0:
		return 0.0
	return float(total_def) / (float(total_def) + k)


## Aplica reducción de armor v2 al raw damage — canon §2.5.
##   final = raw * (1 - reduction)
static func apply_armor_v2(raw_damage: float, total_def: int, attacker_level: int) -> float:
	var reduction: float = armor_reduction_v2(total_def, attacker_level)
	var reduced: float = raw_damage * (1.0 - reduction)
	# Floor de 1.0 — evita 0-dmg por armor extrema. Consistente con v1.
	return maxf(reduced, 1.0)


# ─── v1 legacy (DEPRECATED — redirige a v2 con class_mult=1, level=1) ────────
# Se mantienen para no romper callers durante migración. Nuevo código usa v2.

## @deprecated — usar physical_v2(base, weapon, STR, level, class_mult). Canon §2.3.
static func physical(base_dmg: float, total_str: int, weapon_dmg: int = 0) -> float:
	# Redirige a v2 con level=1 class_mult=1. Mantiene compat con base_player.get_physical_damage legacy.
	return physical_v2(base_dmg, weapon_dmg, total_str, 1, 1.0)


## @deprecated — usar magic_v2(base, weapon, INT, level, class_mult). Canon §2.4.
static func magic(base_dmg: float, total_int: int, weapon_dmg: int = 0) -> float:
	return magic_v2(base_dmg, weapon_dmg, total_int, 1, 1.0)


## @deprecated — legacy lineal `base + weapon + DEX*2`. Sin versión v2 (no usada en canon v2).
## Se mantiene solo para tests legacy; reemplazar por physical_v2/magic_v2 según el flavor real.
static func dex(base_dmg: float, total_dex: int, weapon_dmg: int = 0) -> float:
	return base_dmg + float(weapon_dmg) + (total_dex * 2.0)


## @deprecated — usar apply_armor_v2(raw, DEF, attacker_level). Canon §2.5.
## Legacy: max(raw - DEF, 1).
static func apply_physical_defense(raw_damage: float, total_def: int) -> float:
	return maxf(raw_damage - float(total_def), 1.0)


## Reducción por resistencia elemental: daño × (1 - clamp(res, 0, RESIST_CAP)).
## Se mantiene v1 — canon §2.6 no cambió (cap 75%, asintótica via stats_system.md).
static func apply_elemental_resistance(raw_damage: float, resistance: float) -> float:
	return raw_damage * (1.0 - clampf(resistance, 0.0, GameConstants.RESIST_CAP))
