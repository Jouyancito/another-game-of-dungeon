extends GutTest

# Tests para issue #42 — items equipados modifican fórmulas de combate.
# Verifica el gear loop completo: equipar → recalc → fórmulas usan stats efectivos.

var player: BasePlayer


func before_each() -> void:
	player = BasePlayer.new()
	# Stats base Warrior canónicos (para números predecibles)
	player.str_stat = 12
	player.int_stat = 4
	player.dex_stat = 6
	player.def_stat = 10
	player.vit_stat = 10
	player.base_health = 100.0
	player.base_mana = 80.0
	player.res_fire = 0.0
	player.res_ice = 0.0
	# Wire inventory + equipment (normalmente los crea _ready() / _setup_inventory())
	player.inventory = Inventory.new()
	player.equipment = Equipment.new()
	player.recalculate_stats()
	player.health = player.max_health
	player.mana = player.max_mana


func after_each() -> void:
	if is_instance_valid(player):
		player.free()


# ─── STR efectivo modifica daño físico (canon v2 §2.3) ───

func test_equip_str_item_raises_physical_damage() -> void:
	# v2: (base+weapon) * (1+STR*0.02) * (1+level*0.03) * class_mult
	# base=35, STR=12, weapon=0, lvl=1, class_mult=1 → 35 * 1.24 * 1.03 ≈ 44.702
	var base_dmg := player.get_physical_damage(35.0)
	assert_almost_eq(base_dmg, 44.702, 0.05)
	# +2 STR via amulet_fang (str:2, vit:1) → STR=14 → 35 * 1.28 * 1.03 ≈ 46.144
	player.equipment.equip("amulet_fang")
	player.recalculate_stats()
	var buffed := player.get_physical_damage(35.0)
	assert_almost_eq(buffed, 46.144, 0.05)
	assert_gt(buffed, base_dmg, "item +STR sube dmg")


func test_weapon_damage_sums_to_base_attack() -> void:
	# Sword rusty: damage=5, str=+1 → (35+5) * (1+13*0.02) * 1.03 * 1 = 40 * 1.26 * 1.03 ≈ 51.912
	player.equipment.equip("sword_rusty")
	player.recalculate_stats()
	var dmg := player.get_physical_damage(35.0)
	assert_almost_eq(dmg, 51.912, 0.05)


# ─── DEF efectivo reduce daño recibido (canon v2 §2.5 armor self-capping) ───

func test_equip_def_item_reduces_damage_taken() -> void:
	# v2: raw * (1 - DEF/(DEF + atk_lvl*50))
	# raw=30, DEF=10, atk_lvl=1 → 30 * (1 - 10/60) = 30 * 50/60 = 25
	var raw_pre := player.apply_physical_defense(30.0, 1)
	assert_almost_eq(raw_pre, 25.0, 0.05)
	# Chaleco reforzado: def=6, vit=1 → DEF efectivo = 16 → 30 * (1 - 16/66) = 30 * 50/66 ≈ 22.727
	player.equipment.equip("armor_reinforced_vest")
	player.recalculate_stats()
	var raw_post := player.apply_physical_defense(30.0, 1)
	assert_almost_eq(raw_post, 22.727, 0.05)
	assert_lt(raw_post, raw_pre, "más DEF reduce más dmg (self-capping v2)")


# ─── VIT efectivo sube HP max (canon v2 §2.1) ───

func test_equip_vit_item_raises_max_health_opcion_a() -> void:
	# v2 §2.1: 100 + VIT*5 + VIT^1.3*0.8 + level*8
	var old_hp_actual := player.health
	var expected_base: float = 100.0 + 10.0 * 5.0 + pow(10.0, 1.3) * 0.8 + 8.0
	assert_almost_eq(player.max_health, expected_base, 0.01)

	# Ring slime: vit=3, def=2 → VIT efectivo = 13
	player.equipment.equip("ring_slime")
	player.recalculate_stats()
	var expected_buffed: float = 100.0 + 13.0 * 5.0 + pow(13.0, 1.3) * 0.8 + 8.0
	assert_almost_eq(player.max_health, expected_buffed, 0.01)
	assert_eq(player.health, old_hp_actual, "HP actual NO escala — opción A")


# ─── INT efectivo sube MP max (canon v2 §2.2) ───

func test_equip_int_item_raises_max_mana() -> void:
	# v2 §2.2: 80 + INT*3 + INT^1.2*0.5 + level*5
	var expected_base: float = 80.0 + 4.0 * 3.0 + pow(4.0, 1.2) * 0.5 + 5.0
	assert_almost_eq(player.max_mana, expected_base, 0.01)
	# Offhand holy symbol: int=1, vit=1 → INT efectivo = 5
	player.equipment.equip("offhand_holy_symbol")
	player.recalculate_stats()
	var expected_buffed: float = 80.0 + 5.0 * 3.0 + pow(5.0, 1.2) * 0.5 + 5.0
	assert_almost_eq(player.max_mana, expected_buffed, 0.01)


# ─── Resistencias elementales suman de items ───

func test_equip_fire_resistance_item_raises_effective_res() -> void:
	assert_eq(player.get_effective_resistance("fire"), 0.0, "baseline res_fire = 0")
	player.equipment.equip("amulet_fire_ward")  # res_fire: 0.2
	assert_almost_eq(player.get_effective_resistance("fire"), 0.2, 0.001, "+0.2 de item")


func test_fire_damage_reduced_by_item_resistance() -> void:
	# Sin resistencia: daño completo
	assert_eq(player.apply_elemental_damage(100.0, "fire"), 100.0)
	player.equipment.equip("amulet_fire_ward")  # res_fire: 0.2
	# Con 0.2: 100 * (1 - 0.2) = 80
	assert_almost_eq(player.apply_elemental_damage(100.0, "fire"), 80.0, 0.01)


func test_resistance_caps_at_75_percent_with_base_plus_items() -> void:
	player.res_fire = 0.6
	player.equipment.equip("amulet_fire_ward")  # +0.2 → total teórico 0.8
	# apply_elemental_resistance clampa a 0.75 → 100 * 0.25 = 25
	assert_eq(player.apply_elemental_damage(100.0, "fire"), 25.0, "cap 75%: base 0.6 + item 0.2 → clamped")


func test_ice_resistance_from_ring() -> void:
	player.equipment.equip("ring_frostbite")  # res_ice: 0.25
	assert_almost_eq(player.get_effective_resistance("ice"), 0.25, 0.001)
	assert_almost_eq(player.apply_elemental_damage(100.0, "ice"), 75.0, 0.01)


# ─── Unequip vuelve todo a base ───

func test_unequip_restores_base_stats() -> void:
	# v2 §2.1: expected values computed with compound formula.
	var base_hp: float = 100.0 + 10.0 * 5.0 + pow(10.0, 1.3) * 0.8 + 8.0
	player.equipment.equip("ring_slime")  # vit:3, def:2 → VIT=13
	player.recalculate_stats()
	var buffed_max := player.max_health
	var expected_buffed: float = 100.0 + 13.0 * 5.0 + pow(13.0, 1.3) * 0.8 + 8.0
	assert_almost_eq(buffed_max, expected_buffed, 0.01)

	player.equipment.unequip("ring_1")  # ring_slime entró en ring_1
	player.recalculate_stats()
	assert_almost_eq(player.max_health, base_hp, 0.01, "unequip restaura max HP base v2")
	assert_eq(player.get_effective_stat("def"), 10, "DEF vuelve a base")


# ─── Stats no-cruzados (que un item NO afecta stats fuera de sus keys) ───

func test_item_does_not_affect_unrelated_stats() -> void:
	var baseline_str := player.get_effective_stat("str")  # 12
	player.equipment.equip("ring_slime")  # vit:3, def:2 — sin STR
	player.recalculate_stats()
	assert_eq(player.get_effective_stat("str"), baseline_str, "STR no afectado por ring_slime")
	assert_eq(player.get_effective_stat("def"), 12, "DEF efectivo = 10 + 2")
	# Nota: la suma es algebraica (int + int) — items con stats negativos (cursed)
	# también funcionarían correctamente vía get_total_bonuses. Sin items cursed en DB actual.


# ─── Regen usa stats efectivos ───

func test_mp_regen_uses_effective_int() -> void:
	# Baseline: mp_regen = 1.0 + (4 * 0.1) = 1.4/s
	player.mana = 50.0
	player._regenerate(1.0)
	var base_regen := player.mana - 50.0
	assert_almost_eq(base_regen, 1.4, 0.01)

	# Equipar tome +2 INT → effective = 6 → regen = 1.0 + 0.6 = 1.6/s
	player.equipment.equip("offhand_tome_elements")  # int:2
	player.recalculate_stats()
	player.mana = 50.0
	player._regenerate(1.0)
	var buffed_regen := player.mana - 50.0
	assert_almost_eq(buffed_regen, 1.6, 0.01, "regen MP usa INT efectivo")


func test_hp_regen_uses_effective_vit() -> void:
	player.health = 50.0
	player.time_since_last_hit = 20.0
	player._regenerate(1.0)
	var base_regen := player.health - 50.0
	# hp_regen = 0.5 + (10 * 0.15) = 2.0
	assert_almost_eq(base_regen, 2.0, 0.01)

	player.equipment.equip("ring_slime")  # vit:3, def:2 → VIT efectivo 13
	player.recalculate_stats()
	player.health = 50.0
	player.time_since_last_hit = 20.0
	player._regenerate(1.0)
	var buffed_regen := player.health - 50.0
	# 0.5 + (13 * 0.15) = 2.45
	assert_almost_eq(buffed_regen, 2.45, 0.01, "regen HP usa VIT efectivo")


# ─── equipment_changed signal post-equip/unequip ───

func test_equipment_changed_emitted_on_equip() -> void:
	# Usamos equip_item del player que emite la señal (no equipment.equip directo)
	player.inventory.place_item("sword_rusty", Vector2i(0, 0))
	watch_signals(player)
	player.equip_item("sword_rusty", Vector2i(0, 0))
	assert_signal_emitted(player, "equipment_changed", "equip dispara equipment_changed")


func test_equipment_changed_emitted_on_unequip() -> void:
	player.inventory.place_item("sword_rusty", Vector2i(0, 0))
	player.equip_item("sword_rusty", Vector2i(0, 0))
	watch_signals(player)
	player.unequip_slot("main_hand")
	assert_signal_emitted(player, "equipment_changed", "unequip dispara equipment_changed")
