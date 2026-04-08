extends Node

# Escena de la clase seleccionada por el jugador en el selector
var selected_class_scene: String = "res://scenes/player/mage.tscn"

# Índice del personaje activo (apunta a SaveManager.characters)
var selected_character_index: int = -1

# Inventario del jugador activo (se crea al entrar al juego)
var player_inventory: Inventory = null

# Monedas del jugador (espejo de player_inventory.coins para acceso rápido)
var player_coins: int = 0
