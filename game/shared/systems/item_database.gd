extends Node

# Base de datos de items. Autoload: accesible como ItemDatabase desde cualquier script.

const RARITY_COLORS := {
	"common": Color(1.0, 1.0, 1.0, 1.0),
	"rare":   Color(0.3, 0.5, 1.0, 1.0),
	"magic":  Color(1.0, 0.85, 0.0, 1.0),
	"epic":   Color(0.6, 0.2, 0.8, 1.0),
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

	# --- Materiales de Pradera ---

	_add({
		"id": "material_slime_gel",
		"name": "Gel de Slime",
		"description": "Sustancia viscosa y elástica. Componente de pociones y adhesivos.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 3,
	})
	_add({
		"id": "material_leather",
		"name": "Cuero Crudo",
		"description": "Piel de animal sin tratar. Se puede curtir para hacer armaduras.",
		"type": "material", "subtype": "hide", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 4,
	})
	_add({
		"id": "material_fang",
		"name": "Colmillo Afilado",
		"description": "Un colmillo de depredador. Componente para armas y amuletos.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 5,
	})
	_add({
		"id": "material_venom_sac",
		"name": "Saco de Veneno",
		"description": "Glándula venenosa intacta. Usar con precaución.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 6,
	})
	_add({
		"id": "material_shell",
		"name": "Fragmento de Caparazón",
		"description": "Trozo de caparazón resistente. Ideal para escudos y armaduras.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 5,
	})
	_add({
		"id": "material_stinger",
		"name": "Aguijón de Avispa",
		"description": "Púa afilada con restos de toxina. Material para flechas envenenadas.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 4,
	})
	_add({
		"id": "material_feather",
		"name": "Pluma",
		"description": "Pluma ligera y suave. Usada en flechas y accesorios.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 1,
	})

	# --- Armaduras básicas de Piso 1 ---

	_add({
		"id": "armor_leather_vest",
		"name": "Chaleco de Cuero",
		"description": "Protección básica hecha con cuero curtido. Mejor que nada.",
		"type": "armor", "subtype": "chest", "slot": "chest",
		"grid_size": Vector2i(2, 3), "rarity": "common",
		"stats": {"def": 3}, "level_req": 1, "item_level": 2,
		"stackable": false, "max_stack": 1, "value": 25,
	})
	_add({
		"id": "armor_cloth_robe",
		"name": "Túnica de Tela",
		"description": "Túnica ligera imbuida con fibras que canalizan mejor la magia.",
		"type": "armor", "subtype": "chest", "slot": "chest",
		"grid_size": Vector2i(2, 3), "rarity": "common",
		"stats": {"def": 1, "int": 2}, "level_req": 1, "item_level": 2,
		"stackable": false, "max_stack": 1, "value": 28,
	})
	_add({
		"id": "armor_leather_boots",
		"name": "Botas de Cuero",
		"description": "Botas resistentes para caminar por terreno difícil.",
		"type": "armor", "subtype": "boots", "slot": "feet",
		"grid_size": Vector2i(2, 2), "rarity": "common",
		"stats": {"def": 1, "dex": 1}, "level_req": 1, "item_level": 1,
		"stackable": false, "max_stack": 1, "value": 15,
	})
	_add({
		"id": "ring_copper",
		"name": "Anillo de Cobre",
		"description": "Un anillo simple. Ligeramente encantado.",
		"type": "accessory", "subtype": "ring", "slot": "ring",
		"grid_size": Vector2i(1, 1), "rarity": "magic",
		"stats": {"vit": 2}, "level_req": 1, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 40,
	})

	# --- Materiales de Pradera (fauna completa) ---

	_add({
		"id": "material_rat_tail",
		"name": "Cola de Rata",
		"description": "Cola fibrosa de roedor. Componente para trampas y cebos.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 1,
	})
	_add({
		"id": "material_spider_silk",
		"name": "Seda de Araña",
		"description": "Hilo resistente y elástico. Imprescindible para cuerdas y arcos.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 4,
	})
	_add({
		"id": "material_rabbit_pelt",
		"name": "Piel de Conejo",
		"description": "Piel suave y ligera. Ideal para guantes y forros.",
		"type": "material", "subtype": "hide", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 2,
	})
	_add({
		"id": "material_goat_horn",
		"name": "Cuerno de Cabra",
		"description": "Cuerno curvado y duro. Se usa en empuñaduras y amuletos.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 3,
	})
	_add({
		"id": "material_fox_pelt",
		"name": "Piel de Zorro",
		"description": "Pelaje rojizo y sedoso. Material para capas y accesorios.",
		"type": "material", "subtype": "hide", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 5,
	})
	_add({
		"id": "material_scorpion_chitin",
		"name": "Quitina de Escorpión",
		"description": "Placa exoesquelética dura como piedra. Excelente para armaduras.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 6,
	})
	_add({
		"id": "material_hawk_talon",
		"name": "Garra de Halcón",
		"description": "Garra afilada de rapaz. Componente para flechas perforantes.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 5,
	})
	_add({
		"id": "material_wasp_honey",
		"name": "Miel de Avispa",
		"description": "Sustancia dulce con propiedades curativas menores.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 3,
	})
	_add({
		"id": "material_stone_core",
		"name": "Núcleo de Piedra",
		"description": "Corazón mineral de un golem. Palpita con energía elemental.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "rare",
		"stats": {}, "level_req": 1, "item_level": 3,
		"stackable": true, "max_stack": 99, "value": 15,
	})
	_add({
		"id": "material_black_feather",
		"name": "Pluma Negra",
		"description": "Pluma oscura de córvido. Material para amuletos sombríos.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 2,
	})

	# --- Mímico (issue #60) — material flag garantizado ---

	_add({
		"id": "dentellada_mimica",
		"name": "Dentellada Mímica",
		"description": "Colmillo de un mímico cazado. Trofeo temático — crafting gate futuro.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "rare",
		"stats": {}, "level_req": 1, "item_level": 3,
		"stackable": true, "max_stack": 99, "value": 12,
		"bind_on_drop": false,  # Canon _mimic.md §4.4: NO bind (floor+random standard)
	})

	# --- Bind items sub-C P1 (bandit_archer / bandit_melee) ---

	_add({
		"id": "emblema_bandido",
		"name": "Emblema del Bandido",
		"description": "Insignia de rango de los bandidos de la pradera. Un outpost pagaría bien por esto.",
		"type": "material", "subtype": "quest", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "rare",
		"stats": {}, "level_req": 1, "item_level": 3,
		"stackable": true, "max_stack": 5, "value": 15,
		"bind_on_drop": true,  # Quest item — owner-only 300s, sin free phase
	})
	_add({
		"id": "corona_oxidada_menor",
		"name": "Corona Oxidada (menor)",
		"description": "Corona de hojalata torcida del líder de bandidos. (+2 STR, +5% XP local). Epic drop del jefe de las praderas.",
		"type": "accessory", "subtype": "head", "slot": "head",
		"grid_size": Vector2i(2, 1), "rarity": "epic",
		"stats": {"str": 2}, "level_req": 3, "item_level": 4,
		"stackable": false, "max_stack": 1, "value": 80,
		"bind_on_drop": true,  # Epic ritual drop — owner-only 300s, sin free phase
	})

	# --- Boss drops (Rey Slime) ---

	_add({
		"id": "boss_crown_rusty",
		"name": "Corona Oxidada",
		"description": "La corona torcida del Rey Slime. Un NPC pagaría bien por esto.",
		"type": "accessory", "subtype": "quest", "slot": "",
		"grid_size": Vector2i(2, 1), "rarity": "unique",
		"stats": {"vit": 1}, "level_req": 1, "item_level": 5,
		"stackable": false, "max_stack": 1, "value": 100,
		"bind_on_drop": true,  # Quest item — despawn si owner no recoge en 300s
	})
	_add({
		"id": "boss_royal_gel",
		"name": "Núcleo de Gelatina Real",
		"description": "El corazón del Rey Slime. Material para armadura anti-slime.",
		"type": "material", "subtype": "monster_drop", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "rare",
		"stats": {}, "level_req": 1, "item_level": 5,
		"stackable": true, "max_stack": 10, "value": 25,
		"bind_on_drop": true,  # Material boss — despawn si owner no recoge en 300s
	})

	# --- Equipamiento rare/magic/unique de Piso 1 (drops) ---

	_add({
		"id": "sword_bandit",
		"name": "Espada de Bandido",
		"description": "Hoja robada pero bien afilada. Mejor de lo que parece.",
		"type": "weapon", "subtype": "sword", "slot": "main_hand",
		"grid_size": Vector2i(1, 3), "rarity": "rare",
		"stats": {"damage": 8, "str": 2}, "level_req": 3, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 35,
	})
	_add({
		"id": "bow_hunter",
		"name": "Arco de Cazador",
		"description": "Arco reforzado con tendón de lobo. Preciso y potente.",
		"type": "weapon", "subtype": "bow", "slot": "main_hand",
		"grid_size": Vector2i(1, 3), "rarity": "rare",
		"stats": {"damage": 7, "dex": 3}, "level_req": 3, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 38,
	})
	_add({
		"id": "armor_reinforced_vest",
		"name": "Chaleco Reforzado",
		"description": "Cuero curtido con placas de hierro remachadas.",
		"type": "armor", "subtype": "chest", "slot": "chest",
		"grid_size": Vector2i(2, 3), "rarity": "rare",
		"stats": {"def": 6, "vit": 1}, "level_req": 3, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 50,
	})
	_add({
		"id": "ring_slime",
		"name": "Anillo Gelatinoso",
		"description": "Un anillo que pulsa como si estuviera vivo. Absorbe impactos.",
		"type": "accessory", "subtype": "ring", "slot": "ring",
		"grid_size": Vector2i(1, 1), "rarity": "magic",
		"stats": {"vit": 3, "def": 2}, "level_req": 3, "item_level": 4,
		"stackable": false, "max_stack": 1, "value": 55,
	})

	# =========================================================
	#  EQUIPAMIENTO PISO 1 — por slot
	#  Common = compra en tienda. Rare/Magic = drop de enemigos.
	# =========================================================

	# --- CABEZA (head) ---

	_add({
		"id": "head_leather_cap",
		"name": "Gorra de Cuero",
		"description": "Gorra simple que protege la cabeza del sol y de golpes leves.",
		"type": "armor", "subtype": "helmet", "slot": "head",
		"grid_size": Vector2i(2, 2), "rarity": "common",
		"stats": {"def": 1}, "level_req": 1, "item_level": 1,
		"stackable": false, "max_stack": 1, "value": 12,
	})
	_add({
		"id": "head_cloth_hood",
		"name": "Capucha de Tela",
		"description": "Capucha discreta que canaliza mejor la concentración mágica.",
		"type": "armor", "subtype": "helmet", "slot": "head",
		"grid_size": Vector2i(2, 2), "rarity": "common",
		"stats": {"int": 1}, "level_req": 1, "item_level": 1,
		"stackable": false, "max_stack": 1, "value": 14,
	})
	_add({
		"id": "head_iron_helm",
		"name": "Yelmo de Hierro",
		"description": "Casco básico de hierro forjado. Pesado pero resistente.",
		"type": "armor", "subtype": "helmet", "slot": "head",
		"grid_size": Vector2i(2, 2), "rarity": "rare",
		"stats": {"def": 3, "vit": 1}, "level_req": 3, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 35,
	})

	# --- PIERNAS (legs) ---

	_add({
		"id": "legs_cloth_pants",
		"name": "Pantalones de Tela",
		"description": "Pantalones holgados y cómodos. No protegen mucho.",
		"type": "armor", "subtype": "legs", "slot": "legs",
		"grid_size": Vector2i(2, 2), "rarity": "common",
		"stats": {"def": 1}, "level_req": 1, "item_level": 1,
		"stackable": false, "max_stack": 1, "value": 10,
	})
	_add({
		"id": "legs_leather_greaves",
		"name": "Grebas de Cuero",
		"description": "Protección de cuero endurecido para las piernas.",
		"type": "armor", "subtype": "legs", "slot": "legs",
		"grid_size": Vector2i(2, 2), "rarity": "common",
		"stats": {"def": 2, "dex": 1}, "level_req": 1, "item_level": 2,
		"stackable": false, "max_stack": 1, "value": 18,
	})
	_add({
		"id": "legs_iron_greaves",
		"name": "Grebas de Hierro",
		"description": "Piezas de hierro remachadas sobre cuero. Protección seria.",
		"type": "armor", "subtype": "legs", "slot": "legs",
		"grid_size": Vector2i(2, 2), "rarity": "rare",
		"stats": {"def": 4, "vit": 1}, "level_req": 3, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 40,
	})

	# --- MANOS (hands) ---

	_add({
		"id": "hands_cloth_wraps",
		"name": "Vendas de Tela",
		"description": "Tiras de tela envueltas en las manos. Mínima protección.",
		"type": "armor", "subtype": "gloves", "slot": "hands",
		"grid_size": Vector2i(2, 2), "rarity": "common",
		"stats": {"def": 1}, "level_req": 1, "item_level": 1,
		"stackable": false, "max_stack": 1, "value": 8,
	})
	_add({
		"id": "hands_leather_gloves",
		"name": "Guantes de Cuero",
		"description": "Guantes flexibles ideales para manejar armas con precisión.",
		"type": "armor", "subtype": "gloves", "slot": "hands",
		"grid_size": Vector2i(2, 2), "rarity": "common",
		"stats": {"def": 1, "dex": 1}, "level_req": 1, "item_level": 2,
		"stackable": false, "max_stack": 1, "value": 15,
	})
	_add({
		"id": "hands_iron_gauntlets",
		"name": "Guanteletes de Hierro",
		"description": "Guantes blindados. Ideales para un guerrero de primera línea.",
		"type": "armor", "subtype": "gloves", "slot": "hands",
		"grid_size": Vector2i(2, 2), "rarity": "rare",
		"stats": {"def": 3, "str": 1}, "level_req": 3, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 38,
	})

	# --- CINTURÓN (belt) ---

	_add({
		"id": "belt_rope",
		"name": "Cinturón de Cuerda",
		"description": "Una cuerda anudada a la cintura. Funcional, no elegante.",
		"type": "armor", "subtype": "belt", "slot": "belt",
		"grid_size": Vector2i(2, 1), "rarity": "common",
		"stats": {"vit": 1}, "level_req": 1, "item_level": 1,
		"stackable": false, "max_stack": 1, "value": 6,
	})
	_add({
		"id": "belt_leather",
		"name": "Cinturón de Cuero",
		"description": "Cinturón resistente con hebilla de hierro. Tiene bolsillos.",
		"type": "armor", "subtype": "belt", "slot": "belt",
		"grid_size": Vector2i(2, 1), "rarity": "common",
		"stats": {"def": 1, "vit": 1}, "level_req": 1, "item_level": 2,
		"stackable": false, "max_stack": 1, "value": 14,
	})
	_add({
		"id": "belt_bandit",
		"name": "Cinturón de Bandido",
		"description": "Cinturón ancho con compartimentos ocultos. Huele a pólvora.",
		"type": "armor", "subtype": "belt", "slot": "belt",
		"grid_size": Vector2i(2, 1), "rarity": "rare",
		"stats": {"dex": 2, "str": 1}, "level_req": 3, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 30,
	})

	# --- MANO SECUNDARIA (off_hand) — escudos, libros, carcaj ---

	_add({
		"id": "shield_wood",
		"name": "Escudo de Madera",
		"description": "Escudo circular de madera. Frágil pero mejor que nada.",
		"type": "armor", "subtype": "shield", "slot": "off_hand",
		"grid_size": Vector2i(2, 3), "rarity": "common",
		"stats": {"def": 4}, "level_req": 1, "item_level": 1,
		"stackable": false, "max_stack": 1, "value": 18,
	})
	_add({
		"id": "shield_iron",
		"name": "Escudo de Hierro",
		"description": "Escudo sólido reforzado con bandas de hierro. Pesa pero aguanta.",
		"type": "armor", "subtype": "shield", "slot": "off_hand",
		"grid_size": Vector2i(2, 3), "rarity": "rare",
		"stats": {"def": 7, "vit": 2}, "level_req": 3, "item_level": 4,
		"stackable": false, "max_stack": 1, "value": 55,
	})
	_add({
		"id": "offhand_tome_elements",
		"name": "Tomo Elemental",
		"description": "Grimorio de consulta que amplifica los hechizos elementales.",
		"type": "weapon", "subtype": "tome", "slot": "off_hand",
		"grid_size": Vector2i(2, 2), "rarity": "common",
		"stats": {"int": 2}, "level_req": 1, "item_level": 2,
		"stackable": false, "max_stack": 1, "value": 20,
	})
	_add({
		"id": "offhand_quiver",
		"name": "Carcaj de Cuero",
		"description": "Carcaj con capacidad para 20 flechas. Mejora la cadencia.",
		"type": "armor", "subtype": "quiver", "slot": "off_hand",
		"grid_size": Vector2i(1, 3), "rarity": "common",
		"stats": {"dex": 2}, "level_req": 1, "item_level": 1,
		"stackable": false, "max_stack": 1, "value": 16,
	})
	_add({
		"id": "offhand_holy_symbol",
		"name": "Símbolo Sagrado",
		"description": "Emblema de fe tallado en hueso. Amplifica la magia divina.",
		"type": "weapon", "subtype": "focus", "slot": "off_hand",
		"grid_size": Vector2i(1, 2), "rarity": "common",
		"stats": {"int": 1, "vit": 1}, "level_req": 1, "item_level": 1,
		"stackable": false, "max_stack": 1, "value": 15,
	})
	_add({
		"id": "offhand_skull_lantern",
		"name": "Linterna Cráneo",
		"description": "Un cráneo que emite luz fantasmal. Fuente de poder oscuro.",
		"type": "weapon", "subtype": "focus", "slot": "off_hand",
		"grid_size": Vector2i(1, 2), "rarity": "magic",
		"stats": {"int": 3}, "level_req": 2, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 35,
	})

	# --- AMULETO (amulet) ---

	_add({
		"id": "amulet_bone",
		"name": "Amuleto de Hueso",
		"description": "Colgante tallado en hueso de bestia. Dicen que da suerte.",
		"type": "accessory", "subtype": "amulet", "slot": "amulet",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {"vit": 1}, "level_req": 1, "item_level": 1,
		"stackable": false, "max_stack": 1, "value": 10,
	})
	_add({
		"id": "amulet_fang",
		"name": "Collar de Colmillos",
		"description": "Colmillos de lobo ensartados en un cordel. Inspira ferocidad.",
		"type": "accessory", "subtype": "amulet", "slot": "amulet",
		"grid_size": Vector2i(1, 1), "rarity": "magic",
		"stats": {"str": 2, "vit": 1}, "level_req": 2, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 40,
	})
	_add({
		"id": "amulet_shell",
		"name": "Medallón de Caparazón",
		"description": "Fragmento de tortuga pulido como medallón. Resistente al daño.",
		"type": "accessory", "subtype": "amulet", "slot": "amulet",
		"grid_size": Vector2i(1, 1), "rarity": "magic",
		"stats": {"def": 3, "vit": 1}, "level_req": 2, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 45,
	})

	# --- CAPA (cape) ---

	_add({
		"id": "cape_tattered",
		"name": "Capa Raída",
		"description": "Una capa vieja con agujeros. Al menos protege del viento.",
		"type": "armor", "subtype": "cape", "slot": "cape",
		"grid_size": Vector2i(2, 2), "rarity": "common",
		"stats": {"def": 1}, "level_req": 1, "item_level": 1,
		"stackable": false, "max_stack": 1, "value": 8,
	})
	_add({
		"id": "cape_hunter",
		"name": "Capa de Cazador",
		"description": "Capa de piel de zorro. Ligera y cálida, ideal para exploradores.",
		"type": "armor", "subtype": "cape", "slot": "cape",
		"grid_size": Vector2i(2, 2), "rarity": "rare",
		"stats": {"dex": 2, "def": 1}, "level_req": 3, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 42,
	})

	# --- ARMAS ADICIONALES (main_hand) ---

	# Ballesta — arma genérica, cualquier clase puede usarla
	_add({
		"id": "crossbow_light",
		"name": "Ballesta Ligera",
		"description": "Ballesta de mano. Más lenta que un arco pero pega más fuerte.",
		"type": "weapon", "subtype": "crossbow", "slot": "main_hand",
		"grid_size": Vector2i(2, 3), "rarity": "common",
		"stats": {"damage": 8, "dex": 1}, "level_req": 1, "item_level": 2,
		"stackable": false, "max_stack": 1, "value": 22,
	})
	_add({
		"id": "crossbow_iron",
		"name": "Ballesta Reforzada",
		"description": "Ballesta con arco de hierro. Penetra armaduras ligeras.",
		"type": "weapon", "subtype": "crossbow", "slot": "main_hand",
		"grid_size": Vector2i(2, 3), "rarity": "rare",
		"stats": {"damage": 12, "dex": 2, "str": 1}, "level_req": 4, "item_level": 4,
		"stackable": false, "max_stack": 1, "value": 50,
	})
	# Maza — para Cleric / Warrior
	_add({
		"id": "mace_iron",
		"name": "Maza de Hierro",
		"description": "Maza contundente de hierro. Efectiva contra armaduras.",
		"type": "weapon", "subtype": "mace", "slot": "main_hand",
		"grid_size": Vector2i(1, 3), "rarity": "common",
		"stats": {"damage": 6, "str": 2}, "level_req": 1, "item_level": 2,
		"stackable": false, "max_stack": 1, "value": 16,
	})
	# Daga — arma genérica ligera
	_add({
		"id": "dagger_rusty",
		"name": "Daga Oxidada",
		"description": "Una daga corta y oxidada. Rápida pero débil.",
		"type": "weapon", "subtype": "dagger", "slot": "main_hand",
		"grid_size": Vector2i(1, 2), "rarity": "common",
		"stats": {"damage": 3, "dex": 2}, "level_req": 1, "item_level": 1,
		"stackable": false, "max_stack": 1, "value": 7,
	})
	# Bastón — para casters
	_add({
		"id": "staff_oak",
		"name": "Bastón de Roble",
		"description": "Bastón tallado de roble. Focaliza la energía mágica.",
		"type": "weapon", "subtype": "staff", "slot": "main_hand",
		"grid_size": Vector2i(1, 4), "rarity": "common",
		"stats": {"damage": 4, "int": 3}, "level_req": 1, "item_level": 2,
		"stackable": false, "max_stack": 1, "value": 20,
	})
	_add({
		"id": "staff_venom",
		"name": "Bastón Venenoso",
		"description": "Bastón imbuido con veneno de serpiente. Arde al contacto.",
		"type": "weapon", "subtype": "staff", "slot": "main_hand",
		"grid_size": Vector2i(1, 4), "rarity": "magic",
		"stats": {"damage": 6, "int": 4}, "level_req": 3, "item_level": 4,
		"stackable": false, "max_stack": 1, "value": 55,
	})

	# --- ANILLOS ADICIONALES (ring) ---

	_add({
		"id": "ring_iron",
		"name": "Anillo de Hierro",
		"description": "Banda gruesa de hierro. Simple pero efectivo.",
		"type": "accessory", "subtype": "ring", "slot": "ring",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {"def": 1}, "level_req": 1, "item_level": 1,
		"stackable": false, "max_stack": 1, "value": 8,
	})
	_add({
		"id": "ring_viper",
		"name": "Anillo Víbora",
		"description": "Anillo con forma de serpiente enroscada. Aumenta la agilidad.",
		"type": "accessory", "subtype": "ring", "slot": "ring",
		"grid_size": Vector2i(1, 1), "rarity": "magic",
		"stats": {"dex": 3}, "level_req": 2, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 42,
	})
	_add({
		"id": "amulet_fire_ward",
		"name": "Amuleto Ígneo",
		"description": "Rubí tallado que irradia calor. Mitiga el daño de fuego.",
		"type": "accessory", "subtype": "amulet", "slot": "amulet",
		"grid_size": Vector2i(1, 1), "rarity": "magic",
		"stats": {"res_fire": 0.2}, "level_req": 2, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 50,
	})
	_add({
		"id": "ring_frostbite",
		"name": "Anillo de Escarcha",
		"description": "Banda helada que nunca se funde. Reduce el daño de hielo.",
		"type": "accessory", "subtype": "ring", "slot": "ring",
		"grid_size": Vector2i(1, 1), "rarity": "magic",
		"stats": {"res_ice": 0.25}, "level_req": 2, "item_level": 3,
		"stackable": false, "max_stack": 1, "value": 50,
	})

	# --- Light sources (fuentes de luz portables) ---
	# stats.light_range / light_energy / light_color / light_duration (segundos, 0 = infinito)

	_add({
		"id": "torch_wood",
		"name": "Antorcha de Madera",
		"description": "Una rama con tela y brea. Arde bien pero no dura mucho.",
		# Canon 2026-04-24: torch va a off_hand (no slot "light" específico).
		# Items con stats.light_range > 0 en off_hand auto-iluminan. El slot
		# "light" queda reservado para un futuro quick_use_slot genérico.
		"type": "light", "subtype": "torch", "slot": "off_hand",
		"grid_size": Vector2i(1, 2), "rarity": "common",
		"stats": {
			"light_range": 6.0,
			"light_energy": 1.5,
			"light_color_r": 1.0, "light_color_g": 0.7, "light_color_b": 0.4,
			"light_duration": 300,  # 5 min
		},
		"level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 5, "value": 8,
	})
	_add({
		"id": "lantern_oil",
		"name": "Linterna de Aceite",
		"description": "Un farol con reserva de aceite. Luz estable y de mayor alcance.",
		"type": "light", "subtype": "lantern", "slot": "light",
		"grid_size": Vector2i(1, 2), "rarity": "common",
		"stats": {
			"light_range": 10.0,
			"light_energy": 2.0,
			"light_color_r": 1.0, "light_color_g": 0.85, "light_color_b": 0.6,
			"light_duration": 900,  # 15 min
		},
		"level_req": 1, "item_level": 2,
		"stackable": false, "max_stack": 1, "value": 30,
	})
	_add({
		"id": "orb_arcane",
		"name": "Orbe Arcano",
		"description": "Una esfera de luz azulada que no se apaga jamás. Magia pura.",
		"type": "light", "subtype": "magic_light", "slot": "light",
		"grid_size": Vector2i(1, 1), "rarity": "rare",
		"stats": {
			"light_range": 12.0,
			"light_energy": 2.5,
			"light_color_r": 0.6, "light_color_g": 0.8, "light_color_b": 1.0,
			"light_duration": 0,  # infinito
		},
		"level_req": 3, "item_level": 4,
		"stackable": false, "max_stack": 1, "value": 150,
	})
	_add({
		"id": "mushroom_biolum",
		"name": "Hongo Bioluminiscente",
		"description": "Brilla con una luz verdosa tenue. Débil pero no se agota.",
		"type": "light", "subtype": "biolum", "slot": "light",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {
			"light_range": 4.0,
			"light_energy": 1.0,
			"light_color_r": 0.5, "light_color_g": 1.0, "light_color_b": 0.6,
			"light_duration": 0,  # infinito
		},
		"level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 5, "value": 5,
	})

	# --- Consumibles adicionales ---

	_add({
		"id": "potion_mp_small",
		"name": "Poción de Maná Chica",
		"description": "Restaura 25 puntos de maná al consumirla.",
		"type": "consumable", "subtype": "potion", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {"restore_mana": 25}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 10, "value": 5,
	})
	_add({
		"id": "potion_antidote",
		"name": "Antídoto",
		"description": "Cura envenenamiento. Sabe horrible.",
		"type": "consumable", "subtype": "potion", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {"cure_poison": true}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 10, "value": 8,
	})
	_add({
		"id": "food_bread",
		"name": "Pan Duro",
		"description": "Un trozo de pan. Restaura vida lentamente durante 10 segundos.",
		"type": "consumable", "subtype": "food", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {"heal_over_time": 20, "duration": 10}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 20, "value": 2,
	})
	_add({
		"id": "saeta_pack",
		"name": "Saetas (x10)",
		"description": "Paquete de saetas para ballesta. Punta de hierro.",
		"type": "consumable", "subtype": "ammo", "slot": "",
		"grid_size": Vector2i(1, 1), "rarity": "common",
		"stats": {"ammo_type": "bolt", "quantity": 10}, "level_req": 1, "item_level": 1,
		"stackable": true, "max_stack": 99, "value": 5,
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
