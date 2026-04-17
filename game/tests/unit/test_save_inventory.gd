extends GutTest

# Tests para issue #43 — persistencia de inventory + equipment via SaveManager.
# Valida round-trip to_save_data → from_save_data en Inventory y Equipment,
# migración v1→v2, y edge cases (item inválido, quantity > stack_max).

var inv: Inventory
var eq: Equipment


func before_each() -> void:
	inv = Inventory.new()
	eq = Equipment.new()


# ─── Inventory round-trip ───

func test_inventory_save_and_load_preserves_items() -> void:
	inv.place_item("amulet_fang", Vector2i(0, 0))
	inv.place_item("sword_rusty", Vector2i(2, 0))
	inv.coins = 42

	var data: Dictionary = inv.to_save_data()

	var fresh := Inventory.new()
	fresh.from_save_data(data)

	assert_eq(fresh.items.size(), 2, "2 items preserved")
	assert_eq(fresh.coins, 42, "coins preserved")
	assert_eq(fresh.get_item_at(Vector2i(0, 0))["item_id"], "amulet_fang")
	assert_eq(fresh.get_item_at(Vector2i(2, 0))["item_id"], "sword_rusty")


func test_inventory_save_preserves_quantity() -> void:
	# potion_hp_small es stackable, max_stack=10
	inv.place_item("potion_hp_small", Vector2i(0, 0), 7)
	var data := inv.to_save_data()

	var fresh := Inventory.new()
	fresh.from_save_data(data)

	var entry: Dictionary = fresh.get_item_at(Vector2i(0, 0))
	assert_eq(entry["quantity"], 7, "stack quantity preserved")


func test_inventory_load_skips_invalid_item_id() -> void:
	# Simular save corrupto con item_id inexistente
	var fake_data := {
		"items": [
			{"item_id": "this_id_does_not_exist", "grid_pos_x": 0, "grid_pos_y": 0, "quantity": 1},
			{"item_id": "sword_rusty", "grid_pos_x": 3, "grid_pos_y": 0, "quantity": 1},
		],
		"coins": 10,
	}
	inv.from_save_data(fake_data)
	# Solo el item válido se cargó
	assert_eq(inv.items.size(), 1, "item inválido skipeado, item válido cargado")
	assert_eq(inv.items[0]["item_id"], "sword_rusty")


func test_inventory_load_caps_quantity_to_max_stack() -> void:
	# potion_hp_small max_stack=10, save corrupto dice 99
	var fake_data := {
		"items": [
			{"item_id": "potion_hp_small", "grid_pos_x": 0, "grid_pos_y": 0, "quantity": 99},
		],
		"coins": 0,
	}
	inv.from_save_data(fake_data)
	assert_eq(inv.items.size(), 1)
	assert_eq(inv.items[0]["quantity"], 10, "quantity capeada a max_stack")


func test_inventory_load_empty_save_yields_empty_inventory() -> void:
	inv.from_save_data({})
	assert_eq(inv.items.size(), 0)
	assert_eq(inv.coins, 0)


# ─── Equipment round-trip ───

func test_equipment_save_and_load_preserves_slots() -> void:
	eq.equip("sword_rusty")  # main_hand
	eq.equip("amulet_fang")  # amulet
	var data := eq.to_save_data()

	var fresh := Equipment.new()
	fresh.from_save_data(data)

	assert_eq(fresh.get_slot("main_hand").get("item_id", ""), "sword_rusty")
	assert_eq(fresh.get_slot("amulet").get("item_id", ""), "amulet_fang")


func test_equipment_save_empty_slots_not_serialized() -> void:
	eq.equip("sword_rusty")
	var data := eq.to_save_data()
	# Solo main_hand debe aparecer, no los 11 slots vacíos
	assert_eq(data.size(), 1, "solo slots ocupados serializados")
	assert_true(data.has("main_hand"))


func test_equipment_load_invalid_item_id_leaves_slot_empty() -> void:
	var fake_data := {
		"main_hand": {"item_id": "this_does_not_exist", "quantity": 1},
		"amulet": {"item_id": "amulet_fang", "quantity": 1},
	}
	eq.from_save_data(fake_data)
	assert_true(eq.get_slot("main_hand").is_empty(), "item inválido → slot vacío")
	assert_eq(eq.get_slot("amulet").get("item_id", ""), "amulet_fang", "válido cargado")


func test_equipment_load_unknown_slot_key_ignored() -> void:
	var fake_data := {
		"made_up_slot": {"item_id": "sword_rusty", "quantity": 1},
		"main_hand": {"item_id": "sword_rusty", "quantity": 1},
	}
	eq.from_save_data(fake_data)
	assert_eq(eq.get_slot("main_hand").get("item_id", ""), "sword_rusty")
	# "made_up_slot" no existe en SLOT_NAMES → skipeado


func test_equipment_load_non_equippable_item_leaves_slot_empty() -> void:
	# potion_hp_small no tiene slot (es consumable) — no debe equiparse
	var fake_data := {
		"main_hand": {"item_id": "potion_hp_small", "quantity": 1},
	}
	eq.from_save_data(fake_data)
	assert_true(eq.get_slot("main_hand").is_empty(), "item no-equipable → unequip")


# ─── Migración v1 → v2 ───

func test_inventory_migration_v1_save_without_inventory_key() -> void:
	# Save v1 no tiene key "items" — debe dar inventory vacío sin crashear
	var v1_data := {"coins": 15}  # schema viejo solo coins
	inv.from_save_data(v1_data)
	assert_eq(inv.items.size(), 0, "v1 sin items → inventory vacío")
	assert_eq(inv.coins, 15, "coins legacy preservado")


func test_equipment_migration_v1_save_without_equipment_data() -> void:
	# Save v1 sin equipment dict → from_save_data({}) → todos slots vacíos
	eq.from_save_data({})
	for slot_key in Equipment.SLOT_NAMES:
		assert_true(eq.get_slot(slot_key).is_empty(), "slot %s vacío" % slot_key)


# ─── Integración: stats bonus aplicados post-load ───

func test_equipment_bonuses_sum_correctly_after_load() -> void:
	# Save con items que dan stats conocidos
	var save_data := {
		"main_hand": {"item_id": "sword_rusty", "quantity": 1},   # damage:5, str:1
		"amulet": {"item_id": "amulet_fang", "quantity": 1},      # str:2, vit:1
	}
	eq.from_save_data(save_data)
	var bonuses: Dictionary = eq.get_total_bonuses()
	assert_eq(int(bonuses.get("str", 0)), 3, "STR sumado = 1 (sword) + 2 (amulet)")
	assert_eq(int(bonuses.get("vit", 0)), 1, "VIT sumado = 1 (amulet)")
	assert_eq(eq.get_weapon_damage(), 5, "weapon damage = 5 (sword_rusty)")
