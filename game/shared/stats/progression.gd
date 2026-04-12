class_name Progression
extends RefCounted

# Progresión de niveles y XP. Fórmulas puras.

const BASE_XP_PER_LEVEL: float = 100.0
const XP_CURVE_EXPONENT: float = 1.15
const STAT_POINTS_PER_LEVEL: int = 3

## XP requerido para pasar del nivel N al N+1
static func xp_for_level(level: int) -> float:
	return BASE_XP_PER_LEVEL * pow(XP_CURVE_EXPONENT, level - 1)

## HP máximo a partir de base + VIT
static func max_health(base_health: float, total_vit: int) -> float:
	return base_health + (total_vit * 5.0)

## MP máximo a partir de base + INT
static func max_mana(base_mana: float, total_int: int) -> float:
	return base_mana + (total_int * 3.0)

## HP regen por segundo (fuera de combate)
static func hp_regen_rate(vit_stat: int) -> float:
	return 0.5 + (vit_stat * 0.15)

## MP regen por segundo (siempre activo)
static func mp_regen_rate(int_stat: int) -> float:
	return 1.0 + (int_stat * 0.1)
