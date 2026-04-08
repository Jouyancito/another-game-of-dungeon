extends Node3D

func _ready() -> void:
	var class_path = GameManager.selected_class_scene
	var scene: PackedScene = load(class_path)
	if scene == null:
		push_error("main.gd: no se pudo cargar la escena de clase: " + class_path)
		return
	var player = scene.instantiate()
	player.position = Vector3(0, 2, 0)
	add_child(player)
