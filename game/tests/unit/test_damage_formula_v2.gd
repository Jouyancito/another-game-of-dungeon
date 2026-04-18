extends GutTest

# Tests canon balance_v2.md §2.3-2.5 — fórmulas compound v2.
# Verifica curvas lvl 1/25/50/75/100 contra tabla canon §2.3.

# ─── physical_v2 — tabla canon §2.3 (Warrior class_mult 1.5) ───

func test_physical_v2_level_1_warrior() -> void:
	# Canon §2.3: lvl 1, STR 12, weapon 20, base 10, class_mult 1.5
	# (10 + 20) * (1 + 12*0.02) * (1 + 1*0.03) * 1.5 = 30 * 1.24 * 1.03 * 1.5 ≈ 57.47
	var dmg: float = DamageFormula.physical_v2(10.0, 20, 12, 1, 1.5)
	assert_almost_eq(dmg, 57.47, 0.1, "lvl 1 STR 12 ≈ 57")


func test_physical_v2_level_25_warrior() -> void:
	# Canon §2.3: lvl 25, STR 40, weapon 40, base 10, class_mult 1.5
	# (10 + 40) * (1 + 40*0.02) * (1 + 25*0.03) * 1.5 = 50 * 1.80 * 1.75 * 1.5 = 236.25
	var dmg: float = DamageFormula.physical_v2(10.0, 40, 40, 25, 1.5)
	assert_almost_eq(dmg, 236.25, 0.5, "lvl 25 STR 40 ≈ 236")


func test_physical_v2_level_50_warrior() -> void:
	# Canon §2.3: lvl 50, STR 70, weapon 80, base 10, class_mult 1.5
	# (10 + 80) * (1 + 70*0.02) * (1 + 50*0.03) * 1.5 = 90 * 2.40 * 2.50 * 1.5 = 810
	var dmg: float = DamageFormula.physical_v2(10.0, 80, 70, 50, 1.5)
	assert_almost_eq(dmg, 810.0, 1.0, "lvl 50 STR 70 ≈ 810")


func test_physical_v2_level_75_warrior() -> void:
	# Canon §2.3: lvl 75, STR 100, weapon 120, base 10, class_mult 1.5
	# 130 * 3.00 * 3.25 * 1.5 = 1901.25
	var dmg: float = DamageFormula.physical_v2(10.0, 120, 100, 75, 1.5)
	assert_almost_eq(dmg, 1901.25, 2.0, "lvl 75 STR 100 ≈ 1902")


func test_physical_v2_level_100_warrior() -> void:
	# Canon §2.3: lvl 100, STR 140, weapon 200, base 10, class_mult 1.5
	# 210 * 3.80 * 4.00 * 1.5 = 4788
	var dmg: float = DamageFormula.physical_v2(10.0, 200, 140, 100, 1.5)
	assert_almost_eq(dmg, 4788.0, 5.0, "lvl 100 STR 140 ≈ 4788")


func test_physical_v2_default_class_mult_1() -> void:
	# class_mult=1.0 (no multiplier) — (base+weapon) * stat_mult * level_mult
	var dmg: float = DamageFormula.physical_v2(10.0, 0, 10, 1, 1.0)
	# 10 * 1.20 * 1.03 = 12.36
	assert_almost_eq(dmg, 12.36, 0.1)


# ─── magic_v2 — misma fórmula con INT ───

func test_magic_v2_same_curve_as_physical() -> void:
	# magic_v2 con INT 12 debe dar igual que physical_v2 con STR 12 (misma fórmula).
	var phys: float = DamageFormula.physical_v2(10.0, 20, 12, 1, 1.5)
	var magic: float = DamageFormula.magic_v2(10.0, 20, 12, 1, 1.5)
	assert_almost_eq(magic, phys, 0.01)


func test_magic_v2_level_50_mage() -> void:
	# Mage INT 70, weapon 80, base 10, class_mult 1.5 (mage tambien 1.5 canon §2.4).
	var dmg: float = DamageFormula.magic_v2(10.0, 80, 70, 50, 1.5)
	assert_almost_eq(dmg, 810.0, 1.0)


# ─── armor_reduction_v2 — tabla canon §2.5 ───

func test_armor_reduction_def_20_vs_lvl10() -> void:
	# Canon §2.5: DEF 20 vs atk lvl 10 (k=500) → 20/520 = 0.0385 ≈ 3.8%
	var r: float = DamageFormula.armor_reduction_v2(20, 10)
	assert_almost_eq(r, 0.0385, 0.001, "DEF 20 vs lvl10 ≈ 3.8%")


func test_armor_reduction_def_100_vs_lvl10() -> void:
	# Canon §2.5: DEF 100 vs atk lvl 10 (k=500) → 100/600 = 0.1667 ≈ 16.7%
	var r: float = DamageFormula.armor_reduction_v2(100, 10)
	assert_almost_eq(r, 0.1667, 0.001, "DEF 100 vs lvl10 ≈ 16.7%")


func test_armor_reduction_def_500_vs_lvl10() -> void:
	# Canon §2.5: DEF 500 vs atk lvl 10 (k=500) → 500/1000 = 0.50 = 50%
	var r: float = DamageFormula.armor_reduction_v2(500, 10)
	assert_almost_eq(r, 0.50, 0.001, "DEF 500 vs lvl10 = 50%")


func test_armor_reduction_def_2000_vs_lvl50() -> void:
	# Canon §2.5: DEF 2000 vs atk lvl 50 (k=2500) → 2000/4500 = 0.4444 ≈ 44.4%
	var r: float = DamageFormula.armor_reduction_v2(2000, 50)
	assert_almost_eq(r, 0.4444, 0.001, "DEF 2000 vs lvl50 ≈ 44.4%")


func test_armor_reduction_never_100_percent() -> void:
	# Self-capping: con DEF enorme se acerca a 1 pero nunca llega.
	var r: float = DamageFormula.armor_reduction_v2(1000000, 1)
	assert_lt(r, 1.0, "reduction NUNCA llega a 100%")
	assert_gt(r, 0.99, "pero se acerca con DEF masiva")


func test_armor_reduction_zero_def_zero_reduction() -> void:
	var r: float = DamageFormula.armor_reduction_v2(0, 10)
	assert_eq(r, 0.0, "DEF 0 = 0% reducción")


# ─── apply_armor_v2 ───

func test_apply_armor_v2_reduces_damage() -> void:
	# raw 100, DEF 500, atk lvl 10 → reduction 50% → 100 * 0.5 = 50
	var final_dmg: float = DamageFormula.apply_armor_v2(100.0, 500, 10)
	assert_almost_eq(final_dmg, 50.0, 0.5)


func test_apply_armor_v2_floors_at_1() -> void:
	# raw 2, DEF masiva → reducción extrema, pero floor = 1.0.
	var final_dmg: float = DamageFormula.apply_armor_v2(2.0, 1000000, 1)
	assert_eq(final_dmg, 1.0, "floor mínimo 1 dmg")


# ─── v1 legacy deprecado redirige a v2 ───

func test_physical_v1_legacy_delegates_to_v2() -> void:
	# physical(base, STR, weapon) = physical_v2(base, weapon, STR, 1, 1.0)
	var v1: float = DamageFormula.physical(10.0, 10, 5)
	var v2: float = DamageFormula.physical_v2(10.0, 5, 10, 1, 1.0)
	assert_almost_eq(v1, v2, 0.001)


func test_magic_v1_legacy_delegates_to_v2() -> void:
	var v1: float = DamageFormula.magic(10.0, 10, 5)
	var v2: float = DamageFormula.magic_v2(10.0, 5, 10, 1, 1.0)
	assert_almost_eq(v1, v2, 0.001)


# ─── elemental resistance sin cambios v1 ───

func test_elemental_resistance_cap_75() -> void:
	# Cap 0.75 — aún si pasas 0.9, reduce solo 75%.
	var final_dmg: float = DamageFormula.apply_elemental_resistance(100.0, 0.9)
	assert_almost_eq(final_dmg, 25.0, 0.5)
