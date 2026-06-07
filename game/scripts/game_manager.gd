extends Node

# Escena de la clase seleccionada por el jugador en el selector
var selected_class_scene: String = "res://scenes/player/mage.tscn"

# Índice del personaje activo (apunta a SaveManager.characters)
var selected_character_index: int = -1

# Escena destino después del character select (arena o nivel real)
var target_scene: String = "res://scenes/main/main.tscn"

# Mundo activo elegido en el world select (modelo Valheim: seed → mundo).
# world_seed < 0 = sin mundo elegido; el nivel usa su seed por defecto.
var world_seed: int = -1
var world_id: String = ""
var world_name: String = ""
var world_index: int = -1

# El menú lo setea según el destino: true para niveles procedurales (pasan por
# el world select), false para la arena legacy (entra directo). Evita adivinar
# por el path de la escena.
var requires_world_select: bool = false


# Limpia el mundo activo. Llamar al salir del world select sin entrar a un mundo.
func clear_active_world() -> void:
	world_seed = -1
	world_id = ""
	world_name = ""
	world_index = -1

# Inventario del jugador activo (se crea al entrar al juego)
var player_inventory: Inventory = null

# Monedas del jugador (espejo de player_inventory.coins para acceso rápido)
var player_coins: int = 0
