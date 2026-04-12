class_name DamageFormula
extends RefCounted

# Fórmulas puras de daño. Sin dependencias en nodos Godot.
# Diseño MMO-ready: server y client usan las MISMAS fórmulas para predicción sincronizada.
#
# Inputs: valores ya resueltos (stats totales, weapon damage, etc.)
# Outputs: damage final (float)
#
# NO leen del equipment/inventory — eso es responsabilidad del caller.

## Daño físico: base + weapon + (STR × 2)
static func physical(base_dmg: float, total_str: int, weapon_dmg: int = 0) -> float:
	return base_dmg + float(weapon_dmg) + (total_str * 2.0)

## Daño mágico: base + weapon + (INT × 2)
static func magic(base_dmg: float, total_int: int, weapon_dmg: int = 0) -> float:
	return base_dmg + float(weapon_dmg) + (total_int * 2.0)

## Daño dex: base + weapon + (DEX × 2)
static func dex(base_dmg: float, total_dex: int, weapon_dmg: int = 0) -> float:
	return base_dmg + float(weapon_dmg) + (total_dex * 2.0)

## Reducción por defensa física: daño final = max(raw - DEF, 1.0)
static func apply_physical_defense(raw_damage: float, total_def: int) -> float:
	return maxf(raw_damage - float(total_def), 1.0)

## Reducción por resistencia elemental: daño × (1 - clamp(res, 0, 0.75))
static func apply_elemental_resistance(raw_damage: float, resistance: float) -> float:
	return raw_damage * (1.0 - clampf(resistance, 0.0, 0.75))
