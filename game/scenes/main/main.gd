extends Node3D

const FALLBACK_SCENE := "res://scenes/player/player.tscn"

# Mapa de clase → item inicial de arma
const CLASS_STARTER_WEAPON := {
	"res://scenes/player/player.tscn":      "sword_rusty",
	"res://scenes/player/mage.tscn":        "book_apprentice",
	"res://scenes/player/archer.tscn":      "bow_short",
	"res://scenes/player/necromancer.tscn": "wand_cracked",
	"res://scenes/player/cleric.tscn":      "garrote_wood",
}

var pause_menu_scene: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
var character_window_scene: PackedScene = preload("res://scenes/ui/character_window.tscn")
var inventory_ui_scene: PackedScene = preload("res://scenes/ui/inventory_ui.tscn")

func _ready() -> void:
	# Agregar menú de pausa
	var pause_menu = pause_menu_scene.instantiate()
	add_child(pause_menu)

	# Agregar ventana de personaje
	var character_window = character_window_scene.instantiate()
	add_child(character_window)

	# Crear inventario del jugador
	GameManager.player_inventory = Inventory.new()
	GameManager.player_coins = 0

	# Instanciar al jugador según la clase elegida
	var class_path = GameManager.selected_class_scene
	if not ResourceLoader.exists(class_path):
		push_error("main.gd: escena no encontrada: " + class_path + " — usando fallback")
		class_path = FALLBACK_SCENE
	var scene: PackedScene = load(class_path)
	if scene == null:
		push_error("main.gd: no se pudo cargar la escena de clase: " + class_path)
		return
	var player = scene.instantiate()
	player.position = Vector3(0, 2, 0)
	add_child(player)

	# Dar arma inicial según clase
	var starter_weapon: String = CLASS_STARTER_WEAPON.get(class_path, "")
	if starter_weapon != "":
		var placed := GameManager.player_inventory.auto_place_item(starter_weapon)
		if not placed:
			push_warning("main.gd: no se pudo colocar el arma inicial '%s'" % starter_weapon)

	# También dar una poción de vida de bienvenida
	GameManager.player_inventory.auto_place_item("potion_hp_small", 2)

	# Instanciar UI de inventario y conectarla al inventario del jugador
	var inventory_ui = inventory_ui_scene.instantiate()
	add_child(inventory_ui)
	inventory_ui.inventory = GameManager.player_inventory
