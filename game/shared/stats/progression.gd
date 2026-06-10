class_name Progression
extends RefCounted

# Progresión de niveles y XP. Fórmulas puras.
#
# Canon vigente: balance_v2.md §2.1, §2.2, §5.
# v1 (xp_for_level, max_health, max_mana) están DEPRECATED y redirigen a v2.
# level se asume = 1 en v1 cuando no se pasa (preserva behavior legacy para saves fase prototipo).

const BASE_XP_PER_LEVEL: float = 100.0
const XP_CURVE_EXPONENT: float = 1.15
const STAT_POINTS_PER_LEVEL: int = 3


# ─── v2 canon balance_v2.md ──────────────────────────────────────────────────

## HP máximo decelerada cuadrática soft — canon §2.1.
##   max_hp = base + VIT*5 + VIT^1.3 * 0.8 + level*8
static func max_health_v2(base_health: float, total_vit: int, level: int) -> float:
	var vit_f: float = float(total_vit)
	var lvl_f: float = float(level)
	return base_health + vit_f * 5.0 + pow(vit_f, 1.3) * 0.8 + lvl_f * 8.0


## MP máximo decelerada — canon §2.2.
##   max_mp = base + INT*3 + INT^1.2 * 0.5 + level*5
static func max_mana_v2(base_mana: float, total_int: int, level: int) -> float:
	var int_f: float = float(total_int)
	var lvl_f: float = float(level)
	return base_mana + int_f * 3.0 + pow(int_f, 1.2) * 0.5 + lvl_f * 5.0


## XP requerido para pasar del nivel N al N+1 — canon §5 piecewise.
##   Tier I  (1-24):  100   * 1.15^(lvl-1)
##   Tier II (25-49): 3000  * 1.12^(lvl-25)
##   Tier III(50-74): 46000 * 1.10^(lvl-50) — base 46000 (errata 2026-06-10:
##                    45000 retrocedía vs tier II lvl 49 ≈ 45535)
##   Tier IV (75-94): 500000 * 1.08^(lvl-75)
##   Tier V  (95+):  2500000 * 1.05^(lvl-95)
static func xp_for_level_v2(level: int) -> float:
	if level < 25:
		return 100.0 * pow(1.15, float(level - 1))
	elif level < 50:
		return 3000.0 * pow(1.12, float(level - 25))
	elif level < 75:
		return 46000.0 * pow(1.10, float(level - 50))
	elif level < 95:
		return 500000.0 * pow(1.08, float(level - 75))
	else:
		return 2500000.0 * pow(1.05, float(level - 95))


# ─── v1 legacy (DEPRECATED — redirigen a v2 con level=1) ─────────────────────

## @deprecated — usar xp_for_level_v2(level). Canon §5 piecewise.
## Legacy exponencial constante 1.15x. Redirige a v2 para usar la curva correcta.
static func xp_for_level(level: int) -> float:
	return xp_for_level_v2(level)


## @deprecated — usar max_health_v2(base, VIT, level). Canon §2.1.
## Legacy lineal `base + VIT*5`. Redirige a v2 con level=1 (compat saves prototipo).
static func max_health(base_health: float, total_vit: int) -> float:
	return max_health_v2(base_health, total_vit, 1)


## @deprecated — usar max_mana_v2(base, INT, level). Canon §2.2.
static func max_mana(base_mana: float, total_int: int) -> float:
	return max_mana_v2(base_mana, total_int, 1)


## HP regen por segundo (fuera de combate) — sin cambios canon v1.
static func hp_regen_rate(vit_stat: int) -> float:
	return 0.5 + (vit_stat * 0.15)


## MP regen por segundo (siempre activo) — sin cambios canon v1.
## Nota: canon balance_v2 §2.2 menciona 5/s fuera combate + 2/s en combate pero
## el wire acá queda como single rate. TODO post-MVP: split in_combat vs safe.
static func mp_regen_rate(int_stat: int) -> float:
	return 1.0 + (int_stat * 0.1)
