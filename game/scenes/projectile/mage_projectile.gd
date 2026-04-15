extends Area3D

@export var speed := 20.0
@export var damage := 20.0
@export var max_range := 15.0

var direction := Vector3.FORWARD
var distance_traveled := 0.0
var shooter: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var movement = direction * speed * delta
	global_position += movement
	distance_traveled += movement.length()

	if distance_traveled >= max_range:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if not is_instance_valid(self):
		return
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, Vector3.ZERO, 0.0, 0, shooter)
	# Desaparecer al impactar cualquier cosa (enemigo o pared)
	queue_free()
