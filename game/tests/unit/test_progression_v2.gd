extends GutTest

# Tests canon balance_v2.md §2.1, §2.2, §5 — progression v2.

# ─── max_health_v2 — tabla canon §2.1 ───

func test_max_health_v2_level_1_warrior() -> void:
	# Canon §2.1: base 100, VIT 10, level 1 → 100 + 50 + 10^1.3*0.8 + 8 = 100+50+16.04+8 ≈ 174
	var hp: float = Progression.max_health_v2(100.0, 10, 1)
	assert_almost_eq(hp, 174.0, 1.0)


func test_max_health_v2_level_25_warrior() -> void:
	# Canon §2.1: base 100, VIT 30, level 25
	#   100 + 30*5 + 30^1.3*0.8 + 25*8 = 100+150+66.58+200 = 516.58
	var hp: float = Progression.max_health_v2(100.0, 30, 25)
	assert_almost_eq(hp, 516.58, 1.0)


func test_max_health_v2_level_50_warrior() -> void:
	# Canon §2.1: base 100, VIT 50, level 50
	#   100 + 50*5 + 50^1.3*0.8 + 50*8 = 100+250+129.35+400 = 879.35
	var hp: float = Progression.max_health_v2(100.0, 50, 50)
	assert_almost_eq(hp, 879.35, 1.0)


func test_max_health_v2_level_75_warrior() -> void:
	# Canon §2.1: base 100, VIT 75, level 75
	#   100 + 75*5 + 75^1.3*0.8 + 75*8 = 100+375+219.11+600 = 1294.11
	var hp: float = Progression.max_health_v2(100.0, 75, 75)
	assert_almost_eq(hp, 1294.11, 1.0)


func test_max_health_v2_level_100_warrior() -> void:
	# Canon §2.1: base 100, VIT 100, level 100
	#   100 + 100*5 + 100^1.3*0.8 + 100*8 = 100+500+318.49+800 = 1718.49
	var hp: float = Progression.max_health_v2(100.0, 100, 100)
	assert_almost_eq(hp, 1718.49, 1.0)


# ─── max_mana_v2 — §2.2 ───

func test_max_mana_v2_level_1_mage() -> void:
	# base 120, INT 12, level 1 → 120 + 36 + 12^1.2*0.5 + 5 ≈ 170
	var mp: float = Progression.max_mana_v2(120.0, 12, 1)
	# 12^1.2 ≈ 19.39 → 19.39 * 0.5 = 9.70. 120 + 36 + 9.70 + 5 = 170.70
	assert_almost_eq(mp, 170.7, 1.0)


func test_max_mana_v2_level_50_mage() -> void:
	# base 120, INT 70, level 50 → 120 + 210 + 70^1.2*0.5 + 250
	# 70^1.2 ≈ 163.22 → 81.6. 120+210+81.6+250 = 661.6
	var mp: float = Progression.max_mana_v2(120.0, 70, 50)
	assert_almost_eq(mp, 661.6, 2.0)


# ─── xp_for_level_v2 — tabla canon §5 ───

func test_xp_for_level_v2_tier1_lvl1() -> void:
	# Tier I lvl 1→2: 100 * 1.15^0 = 100
	assert_almost_eq(Progression.xp_for_level_v2(1), 100.0, 0.1)


func test_xp_for_level_v2_tier1_lvl10() -> void:
	# Tier I lvl 10→11: 100 * 1.15^9 ≈ 351
	assert_almost_eq(Progression.xp_for_level_v2(10), 351.79, 1.0)


func test_xp_for_level_v2_tier2_lvl25() -> void:
	# Tier II lvl 25→26: 3000 * 1.12^0 = 3000
	assert_almost_eq(Progression.xp_for_level_v2(25), 3000.0, 1.0)


func test_xp_for_level_v2_tier3_lvl50() -> void:
	# Tier III lvl 50→51: 46000 * 1.10^0 = 46000 (base raised from 45000,
	# errata 2026-06-10: old base backtracked vs tier II lvl 49 ~= 45535)
	assert_almost_eq(Progression.xp_for_level_v2(50), 46000.0, 1.0)


func test_xp_for_level_v2_tier4_lvl75() -> void:
	# Tier IV lvl 75→76: 500000 * 1.08^0 = 500000
	assert_almost_eq(Progression.xp_for_level_v2(75), 500000.0, 1.0)


func test_xp_for_level_v2_tier5_lvl95() -> void:
	# Tier V lvl 95→96: 2500000 * 1.05^0 = 2500000
	assert_almost_eq(Progression.xp_for_level_v2(95), 2500000.0, 1.0)


func test_xp_for_level_v2_no_negative_discontinuity_at_boundaries() -> void:
	# Validates that tier transitions do not backtrack (next tier start >= prev tier end).
	# lvl 24 final tier I vs lvl 25 initial tier II
	var xp_24: float = Progression.xp_for_level_v2(24)
	var xp_25: float = Progression.xp_for_level_v2(25)
	assert_gt(xp_25, xp_24, "tier II start greater than tier I end (no backtrack)")

	# lvl 49 final tier II vs lvl 50 initial tier III (regression guard for the
	# 2026-06-10 errata: tier III base 45000 backtracked vs lvl 49 ~= 45535).
	var xp_49: float = Progression.xp_for_level_v2(49)
	var xp_50: float = Progression.xp_for_level_v2(50)
	assert_gt(xp_50, xp_49, "tier III start greater than tier II end (no backtrack)")

	var xp_74: float = Progression.xp_for_level_v2(74)
	var xp_75: float = Progression.xp_for_level_v2(75)
	assert_gt(xp_75, xp_74, "tier IV start greater than tier III end (no backtrack)")

	var xp_94: float = Progression.xp_for_level_v2(94)
	var xp_95: float = Progression.xp_for_level_v2(95)
	assert_gt(xp_95, xp_94, "tier V start greater than tier IV end (no backtrack)")


# ─── v1 legacy delegan a v2 ───

func test_max_health_v1_delegates_to_v2_level_1() -> void:
	var v1: float = Progression.max_health(100.0, 10)
	var v2: float = Progression.max_health_v2(100.0, 10, 1)
	assert_almost_eq(v1, v2, 0.01)


func test_max_mana_v1_delegates_to_v2_level_1() -> void:
	var v1: float = Progression.max_mana(120.0, 12)
	var v2: float = Progression.max_mana_v2(120.0, 12, 1)
	assert_almost_eq(v1, v2, 0.01)


func test_xp_for_level_v1_delegates_to_v2() -> void:
	var v1: float = Progression.xp_for_level(10)
	var v2: float = Progression.xp_for_level_v2(10)
	assert_almost_eq(v1, v2, 0.01)
