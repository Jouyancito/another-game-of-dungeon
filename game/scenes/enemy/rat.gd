extends BaseEnemy

## Rata — mob neutral, pequeño y rápido
## Huye cuando está sola. Se vuelve agresiva si hay 3+ ratas cerca.
## Movimiento errático: cambia de punto destino seguido, sacudidas rápidas.

@export var pack_radius := 8.0       # Radio para contar ratas aliadas
@export var pack_threshold := 3      # Cuántas ratas activan la agresión grupal
@export var scurry_interval_min := 0.3
@export var scurry_interval_max := 1.0
@export var flee_speed_multiplier := 1.4  # Más rápida al huir

var scurry_timer := 0.0
var scurry_target := Vector3.ZERO
var spawn_position := Vector3.ZERO


func _on_enemy_ready() -> void:
	enemy_type = "rat"
	default_color = Color(0.5, 0.45, 0.4)
	mass = 0.3
	spawn_position = global_position
	_pick_scurry_target()
	mesh.visible = false
	var model := EnemyModelBuilder.build_quadruped(
		default_color,
		0.25,   # body_length (small)
		0.1,    # body_height (very flat)
		0.12,   # body_width
		0.08,   # leg_height (stubby legs)
		0.02,   # leg_radius
		true,   # has_tail
		0.2     # tail_length
	)
	model.name = "Model"
	add_child(model)


func _count_nearby_rats() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self:
			continue
		if enemy.get_script() == get_script() and enemy.global_position.distance_to(global_position) <= pack_radius:
			count += 1
	return count


func _should_pursue(distance: float) -> bool:
	if not is_provoked:
		return false
	# Solo persigue si hay suficientes ratas cerca
	return _count_nearby_rats() >= pack_threshold - 1 and distance <= detection_range


func _idle_behavior(delta: float) -> void:
	# Si está provocada pero sola, huye del jugador
	if is_provoked and target != null and _count_nearby_rats() < pack_threshold - 1:
		_flee_from_target(delta)
		return

	# Deambular erráticamente
	_scurry(delta)


func _scurry(delta: float) -> void:
	scurry_timer -= delta
	if scurry_timer <= 0.0:
		_pick_scurry_target()
		scurry_timer = randf_range(scurry_interval_min, scurry_interval_max)

	var dist = global_position.distance_to(scurry_target)
	if dist > 0.3:
		var direction = (scurry_target - global_position).normalized()
		direction.y = 0
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		var look_pos = scurry_target
		look_pos.y = global_position.y
		if look_pos.distance_to(global_position) > 0.1:
			look_at(look_pos)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 8.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 8.0)


func _flee_from_target(delta: float) -> void:
	var flee_direction = (global_position - target.global_position).normalized()
	flee_direction.y = 0
	velocity.x = flee_direction.x * speed * flee_speed_multiplier
	velocity.z = flee_direction.z * speed * flee_speed_multiplier


func _pick_scurry_target() -> void:
	var angle = randf() * TAU
	var dist = randf_range(1.0, 3.5)
	scurry_target = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)


func _on_death() -> void:
	pass  # Muerte simple: el tween de BaseEnemy encoge y listo
