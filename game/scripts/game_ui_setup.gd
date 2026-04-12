class_name GameUISetup
extends RefCounted

## Helper compartido para inicializar la UI común del juego en cualquier nivel.
## Single source of truth — main.gd y floor1_prairie.gd (y futuros niveles) llaman acá
## en vez de duplicar el setup de pausa/ventana de personaje/inventario/diario.

const PAUSE_MENU: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
const CHARACTER_WINDOW: PackedScene = preload("res://scenes/ui/character_window.tscn")
const INVENTORY_UI: PackedScene = preload("res://scenes/ui/inventory_ui.tscn")
const JOURNAL_UI: PackedScene = preload("res://scenes/ui/journal_ui.tscn")

## Arma inicial por clase — dada SOLO cuando el inventario está vacío (personaje nuevo).
const CLASS_STARTER_WEAPON := {
	"res://scenes/player/player.tscn":      "sword_rusty",
	"res://scenes/player/mage.tscn":        "book_apprentice",
	"res://scenes/player/archer.tscn":      "bow_short",
	"res://scenes/player/necromancer.tscn": "wand_cracked",
	"res://scenes/player/cleric.tscn":      "garrote_wood",
}


## Agrega pausa, ventana de personaje, diario e inventario como hijos del `parent`.
## El inventario se conecta al GameManager.player_inventory (que el player ya cargó del save).
static func setup_ui(parent: Node) -> void:
	parent.add_child(PAUSE_MENU.instantiate())
	parent.add_child(CHARACTER_WINDOW.instantiate())
	parent.add_child(JOURNAL_UI.instantiate())

	var inv_ui = INVENTORY_UI.instantiate()
	inv_ui.inventory = GameManager.player_inventory
	parent.add_child(inv_ui)


## Da arma inicial + poción + antorcha UNA SOLA VEZ por personaje.
## Usa un flag "starter_granted" en el save para no repetir al respawnear/recargar.
static func grant_starter_items(class_scene_path: String) -> void:
	if GameManager.player_inventory == null:
		return
	# Chequear si ya se dieron los starter items a este personaje (persiste en save)
	var idx := GameManager.selected_character_index
	if idx >= 0:
		var char_data := SaveManager.get_character(idx)
		if char_data.get("starter_granted", false):
			return

	var weapon: String = CLASS_STARTER_WEAPON.get(class_scene_path, "")
	if weapon != "":
		var placed := GameManager.player_inventory.auto_place_item(weapon)
		if not placed:
			push_warning("GameUISetup: no se pudo colocar el arma inicial '%s'" % weapon)

	GameManager.player_inventory.auto_place_item("potion_hp_small", 2)
	GameManager.player_inventory.auto_place_item("torch_wood", 3)

	# Marcar como otorgado en el save — nunca más se repite
	if idx >= 0:
		SaveManager.update_character(idx, {"starter_granted": true})
