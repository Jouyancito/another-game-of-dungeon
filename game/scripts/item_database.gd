extends Node

# Base de datos de items. Autoload: accesible como ItemDatabase desde cualquier script.

const RARITY_COLORS := {
	"common": Color(1.0, 1.0, 1.0, 1.0),
	"rare":   Color(0.3, 0.5, 1.0, 1.0),
	"magic":  Color(1.0, 0.85, 0.0, 1.0),
	"unique": Color(0.6, 0.1, 0.1, 1.0),
}

var _items: Dictionary = {}

func _ready() -> void:
	_register_items()


func _register_items() -> void:
	_add({
		"id": "sword_rusty",
		"name": "Espada Oxidada",
		"description": "Una espada vieja y oxidada. Corta, aunque a duras penas.",
		"type": "weapon",
		"subtype": "sword",
		"slot": "main_hand",
		"grid_size": Vector2i(1, 3),
		"rarity": "common",
		"stats": {"damage": 5, "str": 1},
		"level_req": 1,
		"item_level": 1,
		"stackable": false,
		"max_stack": 1,
		"value": 10,
	})
	_add({
		"id": "book_apprentice",
		"name": "Libro de Aprendiz",
		"description": "Un grimorio básico con hechizos elementales de primer nivel.",
		"type": "weapon",
		"subtype": "book",
		"slot": "main_hand",
		"grid_size": Vector2i(2, 2),
		"rarity": "common",
		"stats": {"damage": 4, "int": 2},
		"level_req": 1,
		"item_level": 1,
		"stackable": false,
		"max_stack": 1,
		"value": 12,
	})
	_add({
		"id": "bow_short",
		"name": "Arco Corto",
		"description": "Un arco ligero, ideal para iniciantes en el arte del tiro.",
		"type": "weapon",
		"subtype": "bow",
		"slot": "main_hand",
		"grid_size": Vector2i(1, 3),
		"rarity": "common",
		"stats": {"damage": 4, "dex": 2},
		"level_req": 1,
		"item_level": 1,
		"stackable": false,
		"max_stack": 1,
		"value": 10,
	})
	_add({
		"id": "wand_cracked",
		"name": "Varita Agrietada",
		"description": "Una varita con una grieta que hace chisporrotear la magia.",
		"type": "weapon",
		"subtype": "wand",
		"slot": "main_hand",
		"grid_size": Vector2i(1, 2),
		"rarity": "common",
		"stats": {"damage": 3, "int": 1},
		"level_req": 1,
		"item_level": 1,
		"stackable": false,
		"max_stack": 1,
		"value": 8,
	})
	_add({
		"id": "garrote_wood",
		"name": "Garrote de Madera",
		"description": "Un palo grueso y resistente. Rústico pero efectivo.",
		"type": "weapon",
		"subtype": "garrote",
		"slot": "main_hand",
		"grid_size": Vector2i(1, 3),
		"rarity": "common",
		"stats": {"damage": 5, "str": 1},
		"level_req": 1,
		"item_level": 1,
		"stackable": false,
		"max_stack": 1,
		"value": 6,
	})
	_add({
		"id": "potion_hp_small",
		"name": "Poción de Vida Chica",
		"description": "Restaura 30 puntos de vida al consumirla.",
		"type": "consumable",
		"subtype": "potion",
		"slot": "",
		"grid_size": Vector2i(1, 1),
		"rarity": "common",
		"stats": {"heal": 30},
		"level_req": 1,
		"item_level": 1,
		"stackable": true,
		"max_stack": 10,
		"value": 5,
	})
	_add({
		"id": "material_iron",
		"name": "Hierro",
		"description": "Un pedazo de mineral de hierro. Útil para forjar equipo.",
		"type": "material",
		"subtype": "ore",
		"slot": "",
		"grid_size": Vector2i(1, 1),
		"rarity": "common",
		"stats": {},
		"level_req": 1,
		"item_level": 1,
		"stackable": true,
		"max_stack": 99,
		"value": 2,
	})


func _add(item: Dictionary) -> void:
	_items[item["id"]] = item


func get_item(id: String) -> Dictionary:
	if _items.has(id):
		return _items[id].duplicate(true)
	push_error("ItemDatabase: item no encontrado: '%s'" % id)
	return {}


func get_items_by_type(type: String) -> Array:
	var result: Array = []
	for item in _items.values():
		if item["type"] == type:
			result.append(item.duplicate(true))
	return result


func get_rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, RARITY_COLORS["common"])
