extends BaseEnemy

var _slither_time := 0.0
var _slither_amplitude := 0.25  # metros de desvío lateral
var _slither_frequency := 3.0   # oscilaciones por segundo


func _on_enemy_ready() -> void:
	enemy_type = "snake"
	default_color = Color(0.35, 0.4, 0.2)
	mass = 0.4
	detection_range = 3.0
	mesh.visible = false
	var model := EnemyModelBuilder.build_snake(
		default_color,
		1.0,    # length
		0.08,   # thickness
		5       # segments
	)
	model.name = "Model"
	add_child(model)


## La serpiente no se mueve en idle — depredadora de emboscada
func _idle_behavior(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0


## Movimiento serpenteante: seno sobre el eje X local mientras avanza
func _move_toward_target(delta: float) -> void:
	_slither_time += delta

	var direction := (target.global_position - global_position).normalized()
	direction.y = 0

	# Eje lateral local (perpendicular a la dirección de avance, en el plano XZ)
	var lateral := direction.rotated(Vector3.UP, PI * 0.5)
	var sine_offset := sin(_slither_time * _slither_frequency) * _slither_amplitude

	var move_vec := direction * speed + lateral * sine_offset
	velocity.x = move_vec.x
	velocity.z = move_vec.z


## Override: mordisco + veneno (3 ticks de 2 dmg, 1s de separación)
func perform_attack() -> void:
	can_attack = false

	if is_instance_valid(target):
		target.take_damage(damage)
		_apply_poison_dot(target)

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true


func _apply_poison_dot(dot_target: Node3D) -> void:
	for i in range(3):
		await get_tree().create_timer(1.0).timeout
		if not is_instance_valid(self) or not is_instance_valid(dot_target):
			return
		if is_dead:
			return
		dot_target.take_damage(2.0, "poison")
