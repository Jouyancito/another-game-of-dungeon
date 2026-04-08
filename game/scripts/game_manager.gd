extends Node

# Escena de la clase seleccionada por el jugador en el selector
var selected_class_scene: String = "res://scenes/player/mage.tscn"

# Índice del personaje activo (apunta a SaveManager.characters)
var selected_character_index: int = -1
