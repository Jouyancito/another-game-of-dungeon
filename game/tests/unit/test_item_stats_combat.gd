extends GutTest

# Tests for issue #42 — equipped items modify combat formulas.
# Verifies the full gear loop: equip → recalc → formulas use effective stats.
#
# This fixture instantiates BasePlayer.new() directly with manually assigned stats,
# so class_mult_physical and class_mult_magic remain at their BasePlayer defaults (1.0).
#
# HP/MP expectations use canon balance_v2 §2.1-2.2 (Progression.max_health_v2 /
# max_mana_v2 with level=1).
#
# Damage expectations use balance_v2 §2.3 (DamageFormula.physical_v2, class_mult=1.0).
# Defense expectations use balance_v2 §2.5 (DamageFormula.apply_armor_v2, attacker_level=1).

var player: BasePlayer


func before_each() -> void:
	player = BasePlayer.new()
	# Warrior-canonical base stats (for predictable numbers)
	player.str_stat = 12
	player.int_stat = 4
	player.dex_stat = 6
	player.def_stat = 10
	player.vit_stat = 10
	player.base_health = 100.0
	player.base_mana = 80.0
	player.res_fire = 0.0
	player.res_ice = 0.0
	# Wire inventory + equipment (normally created by _ready() / _setup_inventory())
	player.inventory = Inventory.new()
	player.equipment = Equipment.new()
	player.recalculate_stats()
	player.health = player.max_health
	player.mana = player.max_mana


func after_each() -> void:
	if is_instance_valid(player):
		player.free()


# ─── Effective STR modifies physical damage ───

func test_equip_str_item_raises_physical_damage() -> void:
	# Canon §2.3: physical_v2(35, weapon=0, STR=12, level=1, class_mult=1.0) = 44.702
	var expected_base: float = DamageFormula.physical_v2(35.0, 0, 12, 1, 1.0)
	var base_dmg := player.get_physical_damage(35.0)
	assert_almost_eq(base_dmg, expected_base, 0.01, "baseline pre-equip (v2)")
	# Equip amulet_fang (+2 STR, +1 VIT). Effective STR = 14.
	player.equipment.equip("amulet_fang")
	player.recalculate_stats()
	# physical_v2(35, 0, STR=14, level=1, class_mult=1.0) = 46.144
	var expected_buffed: float = DamageFormula.physical_v2(35.0, 0, 14, 1, 1.0)
	var buffed := player.get_physical_damage(35.0)
	assert_almost_eq(buffed, expected_buffed, 0.01, "con +2 STR: physical_v2 (v2)")


func test_weapon_damage_sums_to_base_attack() -> void:
	# sword_rusty: damage=5, str=+1. Effective STR = 13.
	player.equipment.equip("sword_rusty")
	player.recalculate_stats()
	# physical_v2(35, weapon=5, STR=13, level=1, class_mult=1.0) = 51.912
	var expected: float = DamageFormula.physical_v2(35.0, 5, 13, 1, 1.0)
	var dmg := player.get_physical_damage(35.0)
	assert_almost_eq(dmg, expected, 0.01, "35 base + 5 weapon + STR=13 (v2)")


# ─── Effective DEF reduces incoming damage ───

func test_equip_def_item_reduces_damage_taken() -> void:
	# Canon §2.5: apply_armor_v2(30, DEF=10, attacker_level=1)
	#   reduction = 10/(10+50) = 0.1667, final = 30*(1-0.1667) = 25.0
	var expected_pre: float = DamageFormula.apply_armor_v2(30.0, 10, 1)
	var raw_pre := player.apply_physical_defense(30.0)
	assert_almost_eq(raw_pre, expected_pre, 0.01, "baseline: apply_armor_v2(30, DEF=10, lvl=1) (v2)")
	# armor_reinforced_vest: def=6, vit=1 → effective DEF = 16
	player.equipment.equip("armor_reinforced_vest")
	player.recalculate_stats()
	# apply_armor_v2(30, DEF=16, attacker_level=1)
	#   reduction = 16/(16+50) = 0.2424, final = 30*0.7576 = 22.73
	var expected_post: float = DamageFormula.apply_armor_v2(30.0, 16, 1)
	var raw_post := player.apply_physical_defense(30.0)
	assert_almost_eq(raw_post, expected_post, 0.01, "con +6 DEF: apply_armor_v2(30, DEF=16, lvl=1) (v2)")


# ─── Effective VIT raises max HP ───

func test_equip_vit_item_raises_max_health_opcion_a() -> void:
	# Option A canon: current HP stays, max rises (no proportional scaling)
	var old_hp_actual := player.health
	# Canon §2.1: max_health_v2(100, VIT=10, level=1) ≈ 173.96
	var expected_base: float = Progression.max_health_v2(100.0, 10, 1)
	assert_almost_eq(player.max_health, expected_base, 0.01, "baseline HP max (v2)")

	# ring_slime: vit=3, def=2 → effective VIT = 13
	player.equipment.equip("ring_slime")
	player.recalculate_stats()
	# max_health_v2(100, VIT=13, level=1) ≈ 195.45
	var expected_buffed: float = Progression.max_health_v2(100.0, 13, 1)
	assert_almost_eq(player.max_health, expected_buffed, 0.01, "HP max con VIT=13 (v2)")
	assert_eq(player.health, old_hp_actual, "HP actual NO escala — opcion A")


# ─── Effective INT raises max MP ───

func test_equip_int_item_raises_max_mana() -> void:
	# Canon §2.2: max_mana_v2(80, INT=4, level=1) ≈ 99.64
	var expected_base: float = Progression.max_mana_v2(80.0, 4, 1)
	assert_almost_eq(player.max_mana, expected_base, 0.01, "baseline MP max (v2)")
	# offhand_holy_symbol: int=1, vit=1 → effective INT = 5
	player.equipment.equip("offhand_holy_symbol")
	player.recalculate_stats()
	# max_mana_v2(80, INT=5, level=1) ≈ 103.45
	var expected_buffed: float = Progression.max_mana_v2(80.0, 5, 1)
	assert_almost_eq(player.max_mana, expected_buffed, 0.01, "MP max con INT=5 (v2)")


# ─── Elemental resistances sum from items ───

func test_equip_fire_resistance_item_raises_effective_res() -> void:
	assert_eq(player.get_effective_resistance("fire"), 0.0, "baseline res_fire = 0")
	player.equipment.equip("amulet_fire_ward")  # res_fire: 0.2
	assert_almost_eq(player.get_effective_resistance("fire"), 0.2, 0.001, "+0.2 de item")


func test_fire_damage_reduced_by_item_resistance() -> void:
	# Without resistance: full damage
	assert_eq(player.apply_elemental_damage(100.0, "fire"), 100.0)
	player.equipment.equip("amulet_fire_ward")  # res_fire: 0.2
	# With 0.2: 100 * (1 - 0.2) = 80
	assert_almost_eq(player.apply_elemental_damage(100.0, "fire"), 80.0, 0.01)


func test_resistance_caps_at_75_percent_with_base_plus_items() -> void:
	player.res_fire = 0.6
	player.equipment.equip("amulet_fire_ward")  # +0.2 → theoretical total 0.8
	# apply_elemental_resistance clamps at 0.75 → 100 * 0.25 = 25
	assert_eq(player.apply_elemental_damage(100.0, "fire"), 25.0, "cap 75%: base 0.6 + item 0.2 → clamped")


func test_ice_resistance_from_ring() -> void:
	player.equipment.equip("ring_frostbite")  # res_ice: 0.25
	assert_almost_eq(player.get_effective_resistance("ice"), 0.25, 0.001)
	assert_almost_eq(player.apply_elemental_damage(100.0, "ice"), 75.0, 0.01)


# ─── Unequip restores base stats ───

func test_unequip_restores_base_stats() -> void:
	player.equipment.equip("ring_slime")  # vit:3, def:2
	player.recalculate_stats()
	var expected_buffed: float = Progression.max_health_v2(100.0, 13, 1)
	assert_almost_eq(player.max_health, expected_buffed, 0.01)

	player.equipment.unequip("ring_1")  # ring_slime went into ring_1
	player.recalculate_stats()
	var expected_base: float = Progression.max_health_v2(100.0, 10, 1)
	assert_almost_eq(player.max_health, expected_base, 0.01, "unequip restores max HP base (v2)")
	assert_eq(player.get_effective_stat("def"), 10, "DEF back to base")


# ─── Non-crossed stats (an item does NOT affect stats outside its keys) ───

func test_item_does_not_affect_unrelated_stats() -> void:
	var baseline_str := player.get_effective_stat("str")  # 12
	player.equipment.equip("ring_slime")  # vit:3, def:2 — no STR
	player.recalculate_stats()
	assert_eq(player.get_effective_stat("str"), baseline_str, "STR not affected by ring_slime")
	assert_eq(player.get_effective_stat("def"), 12, "DEF effective = 10 + 2")
	# Note: algebraic sum (int + int) — cursed items with negative stats would also
	# work correctly via get_total_bonuses. No cursed items in current DB.


# ─── Regen uses effective stats ───

func test_mp_regen_uses_effective_int() -> void:
	# Baseline: mp_regen = 1.0 + (4 * 0.1) = 1.4/s
	player.mana = 50.0
	player._regenerate(1.0)
	var base_regen := player.mana - 50.0
	assert_almost_eq(base_regen, 1.4, 0.01)

	# Equip tome +2 INT → effective = 6 → regen = 1.0 + 0.6 = 1.6/s
	player.equipment.equip("offhand_tome_elements")  # int:2
	player.recalculate_stats()
	player.mana = 50.0
	player._regenerate(1.0)
	var buffed_regen := player.mana - 50.0
	assert_almost_eq(buffed_regen, 1.6, 0.01, "regen MP uses effective INT")


func test_hp_regen_uses_effective_vit() -> void:
	player.health = 50.0
	player.time_since_last_hit = 20.0
	player._regenerate(1.0)
	var base_regen := player.health - 50.0
	# hp_regen = 0.5 + (10 * 0.15) = 2.0
	assert_almost_eq(base_regen, 2.0, 0.01)

	player.equipment.equip("ring_slime")  # vit:3, def:2 → effective VIT 13
	player.recalculate_stats()
	player.health = 50.0
	player.time_since_last_hit = 20.0
	player._regenerate(1.0)
	var buffed_regen := player.health - 50.0
	# 0.5 + (13 * 0.15) = 2.45
	assert_almost_eq(buffed_regen, 2.45, 0.01, "regen HP uses effective VIT")


# ─── equipment_changed signal on equip/unequip ───

func test_equipment_changed_emitted_on_equip() -> void:
	# Use player.equip_item() which emits the signal (not equipment.equip() directly)
	player.inventory.place_item("sword_rusty", Vector2i(0, 0))
	watch_signals(player)
	player.equip_item("sword_rusty", Vector2i(0, 0))
	assert_signal_emitted(player, "equipment_changed", "equip triggers equipment_changed")


func test_equipment_changed_emitted_on_unequip() -> void:
	player.inventory.place_item("sword_rusty", Vector2i(0, 0))
	player.equip_item("sword_rusty", Vector2i(0, 0))
	watch_signals(player)
	player.unequip_slot("main_hand")
	assert_signal_emitted(player, "equipment_changed", "unequip triggers equipment_changed")
