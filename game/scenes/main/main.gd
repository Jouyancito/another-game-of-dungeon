extends Node3D

const FALLBACK_SCENE := "res://scenes/player/player.tscn"

func _ready() -> void:
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
