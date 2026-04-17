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


# ─── STR efectivo modifica daño físico ───

func test_equip_str_item_raises_physical_damage() -> void:
	var base_dmg := player.get_physical_damage(35.0)  # 35 + 12*2 = 59
	assert_eq(base_dmg, 59.0, "baseline pre-equip: 35 + (12*2)")
	# Equipar anillo con +2 STR (amulet_fang tiene str:2, vit:1)
	player.equipment.equip("amulet_fang")
	player.recalculate_stats()
	var buffed := player.get_physical_damage(35.0)  # 35 + (12+2)*2 = 63
	assert_eq(buffed, 63.0, "con +2 STR: 35 + (14*2) = 63")


func test_weapon_damage_sums_to_base_attack() -> void:
	# Sword rusty: damage=5, str=+1
	player.equipment.equip("sword_rusty")
	player.recalculate_stats()
	# physical = 35 + 5 (weapon) + (12+1)*2 = 35 + 5 + 26 = 66
	var dmg := player.get_physical_damage(35.0)
	assert_eq(dmg, 66.0, "35 base + 5 weapon + (13*2) = 66")


# ─── DEF efectivo reduce daño recibido ───

func test_equip_def_item_reduces_damage_taken() -> void:
	var raw_pre := player.apply_physical_defense(30.0)  # 30 - 10 = 20
	assert_eq(raw_pre, 20.0, "baseline: 30 - 10 DEF = 20")
	# Chaleco reforzado: def=6, vit=1 → DEF efectivo = 16
	player.equipment.equip("armor_reinforced_vest")
	player.recalculate_stats()
	var raw_post := player.apply_physical_defense(30.0)  # 30 - 16 = 14
	assert_eq(raw_post, 14.0, "con +6 DEF: 30 - 16 = 14")


# ─── VIT efectivo sube HP max ───

func test_equip_vit_item_raises_max_health_opcion_a() -> void:
	# Opción A canon: HP actual igual, max sube (sin escalar proporcional)
	var old_hp_actual := player.health
	var old_max := player.max_health  # 100 + 10*5 = 150
	assert_eq(old_max, 150.0, "baseline HP max = 100 + (10*5) = 150")

	# Ring slime: vit=3, def=2 → VIT efectivo = 13
	player.equipment.equip("ring_slime")
	player.recalculate_stats()
	assert_eq(player.max_health, 100.0 + 13 * 5, "HP max = 100 + (13*5) = 165")
	assert_eq(player.health, old_hp_actual, "HP actual NO escala — opción A")


# ─── INT efectivo sube MP max ───

func test_equip_int_item_raises_max_mana() -> void:
	var old_max := player.max_mana  # 80 + 4*3 = 92
	assert_eq(old_max, 92.0, "baseline MP max = 80 + (4*3) = 92")
	# Offhand holy symbol: int=1, vit=1
	player.equipment.equip("offhand_holy_symbol")
	player.recalculate_stats()
	assert_eq(player.max_mana, 80.0 + 5 * 3, "MP max = 80 + (5*3) = 95")


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
	player.equipment.equip("ring_slime")  # vit:3, def:2
	player.recalculate_stats()
	var buffed_max := player.max_health
	assert_eq(buffed_max, 165.0)

	player.equipment.unequip("ring_1")  # ring_slime entró en ring_1
	player.recalculate_stats()
	assert_eq(player.max_health, 150.0, "unequip restaura max HP base")
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
