extends Node
## Tablas de drop por tipo de enemigo. Autoload: accesible como LootTable.
##
## Uso: var drops = LootTable.roll("slime")
## Retorna: { "gold": int, "items": [{"item_id": String, "quantity": int}] }

# Estructura de cada tabla:
# gold_min/gold_max: rango de oro (inclusive)
# drops: array de {item_id, chance (0.0-1.0), quantity_min, quantity_max}
# guaranteed: items que siempre dropean (ej: quest items)

var _tables: Dictionary = {}

func _ready() -> void:
	_register_tables()


func _register_tables() -> void:
	# --- Piso 1: Pradera ---
	# Drop rates bajos: materiales son valiosos, no basura.
	# Sub-A: ~8-12% material, casi nunca pociones
	# Sub-B: ~12-18% material, raro pociones
	# Sub-C: ~15-20% material, chance de equipo
	# Boss: drops generosos (recompensa real)

	_add("enemy_basic", {
		"gold_min": 1,
		"gold_max": 3,
		"drops": [
			{"item_id": "potion_hp_small", "chance": 0.05, "qty_min": 1, "qty_max": 1},
			{"item_id": "material_iron", "chance": 0.06, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("slime", {
		"gold_min": 1,
		"gold_max": 4,
		"drops": [
			{"item_id": "material_slime_gel", "chance": 0.12, "qty_min": 1, "qty_max": 1},
			{"item_id": "potion_hp_small", "chance": 0.03, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("mini_slime", {
		"gold_min": 0,
		"gold_max": 1,
		"drops": [
			{"item_id": "material_slime_gel", "chance": 0.08, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("wolf", {
		"gold_min": 2,
		"gold_max": 6,
		"drops": [
			{"item_id": "material_leather", "chance": 0.15, "qty_min": 1, "qty_max": 1},
			{"item_id": "material_fang", "chance": 0.08, "qty_min": 1, "qty_max": 1},
			{"item_id": "amulet_fang", "chance": 0.02, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("snake", {
		"gold_min": 1,
		"gold_max": 4,
		"drops": [
			{"item_id": "material_venom_sac", "chance": 0.10, "qty_min": 1, "qty_max": 1},
			{"item_id": "potion_hp_small", "chance": 0.03, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("turtle", {
		"gold_min": 2,
		"gold_max": 5,
		"drops": [
			{"item_id": "material_shell", "chance": 0.10, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("wasp", {
		"gold_min": 0,
		"gold_max": 2,
		"drops": [
			{"item_id": "material_stinger", "chance": 0.08, "qty_min": 1, "qty_max": 1},
			{"item_id": "material_venom_sac", "chance": 0.04, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("bandit", {
		"gold_min": 5,
		"gold_max": 12,
		"drops": [
			{"item_id": "potion_hp_small", "chance": 0.10, "qty_min": 1, "qty_max": 1},
			{"item_id": "material_iron", "chance": 0.08, "qty_min": 1, "qty_max": 2},
		],
	})

	_add("bandit_archer", {
		"gold_min": 5,
		"gold_max": 12,
		"drops": [
			{"item_id": "potion_hp_small", "chance": 0.08, "qty_min": 1, "qty_max": 1},
			{"item_id": "material_leather", "chance": 0.10, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("bird", {
		"gold_min": 0,
		"gold_max": 3,
		"drops": [
			{"item_id": "material_feather", "chance": 0.12, "qty_min": 1, "qty_max": 2},
			{"item_id": "material_black_feather", "chance": 0.04, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("rat", {
		"gold_min": 0,
		"gold_max": 2,
		"drops": [
			{"item_id": "material_rat_tail", "chance": 0.10, "qty_min": 1, "qty_max": 1},
		],
	})

	# TODO: enemy not yet implemented — table ready for when added
	_add("spider", {
		"gold_min": 1,
		"gold_max": 4,
		"drops": [
			{"item_id": "material_spider_silk", "chance": 0.10, "qty_min": 1, "qty_max": 1},
			{"item_id": "material_venom_sac", "chance": 0.05, "qty_min": 1, "qty_max": 1},
		],
	})

	# TODO: enemy not yet implemented — table ready for when added
	_add("rabbit", {
		"gold_min": 0,
		"gold_max": 1,
		"drops": [
			{"item_id": "material_rabbit_pelt", "chance": 0.12, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("goat", {
		"gold_min": 1,
		"gold_max": 4,
		"drops": [
			{"item_id": "material_goat_horn", "chance": 0.10, "qty_min": 1, "qty_max": 1},
			{"item_id": "material_leather", "chance": 0.06, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("fox", {
		"gold_min": 2,
		"gold_max": 5,
		"drops": [
			{"item_id": "material_fox_pelt", "chance": 0.10, "qty_min": 1, "qty_max": 1},
			{"item_id": "material_fang", "chance": 0.05, "qty_min": 1, "qty_max": 1},
			{"item_id": "cape_hunter", "chance": 0.01, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("scorpion", {
		"gold_min": 2,
		"gold_max": 5,
		"drops": [
			{"item_id": "material_scorpion_chitin", "chance": 0.08, "qty_min": 1, "qty_max": 1},
			{"item_id": "material_stinger", "chance": 0.06, "qty_min": 1, "qty_max": 1},
			{"item_id": "material_venom_sac", "chance": 0.03, "qty_min": 1, "qty_max": 1},
			{"item_id": "ring_viper", "chance": 0.01, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("hawk", {
		"gold_min": 2,
		"gold_max": 6,
		"drops": [
			{"item_id": "material_hawk_talon", "chance": 0.08, "qty_min": 1, "qty_max": 1},
			{"item_id": "material_feather", "chance": 0.12, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("golem", {
		"gold_min": 8,
		"gold_max": 18,
		"drops": [
			{"item_id": "material_stone_core", "chance": 0.06, "qty_min": 1, "qty_max": 1},
			{"item_id": "material_iron", "chance": 0.15, "qty_min": 1, "qty_max": 2},
			{"item_id": "shield_iron", "chance": 0.03, "qty_min": 1, "qty_max": 1},
			{"item_id": "legs_iron_greaves", "chance": 0.03, "qty_min": 1, "qty_max": 1},
			{"item_id": "amulet_shell", "chance": 0.02, "qty_min": 1, "qty_max": 1},
		],
	})

	# TODO: enemy not yet implemented — table ready for when added
	_add("bandit_leader", {
		"gold_min": 15,
		"gold_max": 35,
		"drops": [
			{"item_id": "sword_bandit", "chance": 0.10, "qty_min": 1, "qty_max": 1},
			{"item_id": "armor_reinforced_vest", "chance": 0.08, "qty_min": 1, "qty_max": 1},
			{"item_id": "belt_bandit", "chance": 0.06, "qty_min": 1, "qty_max": 1},
			{"item_id": "head_iron_helm", "chance": 0.05, "qty_min": 1, "qty_max": 1},
			{"item_id": "hands_iron_gauntlets", "chance": 0.04, "qty_min": 1, "qty_max": 1},
			{"item_id": "crossbow_iron", "chance": 0.03, "qty_min": 1, "qty_max": 1},
			{"item_id": "potion_hp_small", "chance": 0.25, "qty_min": 1, "qty_max": 2},
			{"item_id": "material_iron", "chance": 0.12, "qty_min": 1, "qty_max": 3},
		],
	})

	# --- Boss: Rey Slime (boss mantiene drops generosos) ---

	# TODO: enemy not yet implemented — table ready for when added
	_add("rey_slime", {
		"gold_min": 40,
		"gold_max": 80,
		"drops": [
			{"item_id": "armor_reinforced_vest", "chance": 0.25, "qty_min": 1, "qty_max": 1},
			{"item_id": "sword_bandit", "chance": 0.20, "qty_min": 1, "qty_max": 1},
			{"item_id": "bow_hunter", "chance": 0.15, "qty_min": 1, "qty_max": 1},
			{"item_id": "staff_venom", "chance": 0.12, "qty_min": 1, "qty_max": 1},
			{"item_id": "crossbow_iron", "chance": 0.10, "qty_min": 1, "qty_max": 1},
			{"item_id": "shield_iron", "chance": 0.10, "qty_min": 1, "qty_max": 1},
			{"item_id": "ring_slime", "chance": 0.10, "qty_min": 1, "qty_max": 1},
			{"item_id": "amulet_shell", "chance": 0.08, "qty_min": 1, "qty_max": 1},
			{"item_id": "cape_hunter", "chance": 0.08, "qty_min": 1, "qty_max": 1},
			{"item_id": "head_iron_helm", "chance": 0.10, "qty_min": 1, "qty_max": 1},
			{"item_id": "offhand_skull_lantern", "chance": 0.06, "qty_min": 1, "qty_max": 1},
			{"item_id": "potion_hp_small", "chance": 0.40, "qty_min": 2, "qty_max": 3},
			{"item_id": "potion_mp_small", "chance": 0.25, "qty_min": 1, "qty_max": 2},
		],
		"guaranteed": [
			{"item_id": "boss_crown_rusty", "qty_min": 1, "qty_max": 1},
			{"item_id": "boss_royal_gel", "qty_min": 1, "qty_max": 2},
		],
	})


	# --- Cofres ---

	_add("chest_common", {
		"gold_min": 5,
		"gold_max": 15,
		"drops": [
			{"item_id": "potion_hp_small", "chance": 0.60, "qty_min": 1, "qty_max": 3},
			{"item_id": "potion_mp_small", "chance": 0.40, "qty_min": 1, "qty_max": 2},
			{"item_id": "material_iron", "chance": 0.30, "qty_min": 1, "qty_max": 3},
			{"item_id": "material_leather", "chance": 0.25, "qty_min": 1, "qty_max": 2},
		],
	})

	_add("chest_rare", {
		"gold_min": 15,
		"gold_max": 40,
		"drops": [
			{"item_id": "potion_hp_small", "chance": 1.00, "qty_min": 2, "qty_max": 4},
			{"item_id": "sword_bandit", "chance": 0.12, "qty_min": 1, "qty_max": 1},
			{"item_id": "bow_hunter", "chance": 0.12, "qty_min": 1, "qty_max": 1},
			{"item_id": "armor_reinforced_vest", "chance": 0.11, "qty_min": 1, "qty_max": 1},
			{"item_id": "material_stone_core", "chance": 0.25, "qty_min": 1, "qty_max": 1},
		],
	})

	_add("chest_boss", {
		"gold_min": 40,
		"gold_max": 100,
		"drops": [
			{"item_id": "sword_bandit", "chance": 0.34, "qty_min": 1, "qty_max": 1},
			{"item_id": "bow_hunter", "chance": 0.33, "qty_min": 1, "qty_max": 1},
			{"item_id": "armor_reinforced_vest", "chance": 0.33, "qty_min": 1, "qty_max": 1},
			{"item_id": "ring_slime", "chance": 0.30, "qty_min": 1, "qty_max": 1},
			{"item_id": "potion_hp_small", "chance": 1.00, "qty_min": 3, "qty_max": 5},
			{"item_id": "potion_mp_small", "chance": 1.00, "qty_min": 2, "qty_max": 3},
		],
	})


func _add(enemy_type: String, table: Dictionary) -> void:
	_tables[enemy_type] = table


## Tira los dados y devuelve qué dropea este enemigo.
## Retorna: {"gold": int, "items": [{"item_id": str, "quantity": int}]}
func roll(enemy_type: String) -> Dictionary:
	var result: Dictionary = {"gold": 0, "items": []}

	var table: Dictionary = _tables.get(enemy_type, {})
	if table.is_empty():
		return result

	# Oro
	var gold_min: int = table.get("gold_min", 0)
	var gold_max: int = table.get("gold_max", 0)
	if gold_max > 0:
		result["gold"] = randi_range(gold_min, gold_max)

	# Items con probabilidad
	for drop in table.get("drops", []):
		if randf() <= drop.get("chance", 0.0):
			var qty := randi_range(drop.get("qty_min", 1), drop.get("qty_max", 1))
			result["items"].append({
				"item_id": drop["item_id"],
				"quantity": qty,
			})

	# Items garantizados
	for drop in table.get("guaranteed", []):
		var qty := randi_range(drop.get("qty_min", 1), drop.get("qty_max", 1))
		result["items"].append({
			"item_id": drop["item_id"],
			"quantity": qty,
		})

	return result
