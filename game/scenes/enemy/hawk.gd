extends BaseEnemy

## Halcón — mob neutral
## Vuela alto y deambula en círculos. Solo ataca si lo provocan.
## Ataque especial: agarra al jugador y lo suelta — daño base + 5 de caída.

# Vuelo
@export var fly_height := 5.0
@export var wander_radius := 8.0
@export var wander_interval := 3.0
@export var dive_speed := 12.0
@export var circle_radius := 4.0
@export var circle_speed := 3.0

# Estados de ataque
enum HawkState { IDLE, CIRCLING, DIVING, RETREATING }
var state := HawkState.IDLE

var wander_timer := 0.0
var wander_target := Vector3.ZERO
var spawn_position := Vector3.ZERO
var circle_angle := 0.0
var dive_cooldown := 0.0


func _on_enemy_ready() -> void:
	enemy_type = "hawk"
	default_color = Color(0.7, 0.55, 0.25)
	spawn_position = global_position
	spawn_position.y = fly_height
	global_position.y = fly_height
	_pick_wander_target()
	mesh.visible = false
	var old_beak: Node = get_node_or_null("Beak")
	if old_beak:
		old_beak.visible = false
	var model := EnemyModelBuilder.build_flyer(
		default_color,
		0.2,
		0.4,
		0.25
	)
	model.name = "Model"
	add_child(model)


func _apply_gravity(_delta: float) -> void:
	# Solo mantener altura en idle y circling
	if state == HawkState.IDLE or state == HawkState.CIRCLING:
		velocity.y = (fly_height - global_position.y) * 3.0
	elif state == HawkState.RETREATING:
		velocity.y = (fly_height - global_position.y) * 5.0


func _should_pursue(distance: float) -> bool:
	# Cuando está en retreat no perseguir — dejar que suba
	if state == HawkState.RETREATING:
		return false
	return super._should_pursue(distance)


func _idle_behavior(delta: float) -> void:
	if state == HawkState.RETREATING:
		# Subiendo después del agarre — volver a circling cuando llega arriba
		if global_position.y >= fly_height - 0.3:
			state = HawkState.CIRCLING if is_provoked else HawkState.IDLE
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 3.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 3.0)
		return

	# Deambular pacíficamente
	wander_timer -= delta

	if wander_timer <= 0.0:
		_pick_wander_target()
		wander_timer = wander_interval

	var distance_to_wander = global_position.distance_to(wander_target)
	if distance_to_wander > 0.5:
		var direction = (wander_target - global_position).normalized()
		direction.y = 0
		velocity.x = direction.x * speed * 0.5
		velocity.z = direction.z * speed * 0.5
		var look_pos = wander_target
		look_pos.y = global_position.y
		look_at(look_pos)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 3.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 3.0)

	dive_cooldown -= delta


func _move_toward_target(delta: float) -> void:
	dive_cooldown -= delta

	var distance_to_target = global_position.distance_to(target.global_position)

	match state:
		HawkState.IDLE:
			# Recién provocado — empezar a circular
			state = HawkState.CIRCLING
			circle_angle = atan2(
				global_position.z - target.global_position.z,
				global_position.x - target.global_position.x
			)

		HawkState.CIRCLING:
			# Circular alrededor del jugador a fly_height
			circle_angle += circle_speed * delta
			var target_pos = target.global_position + Vector3(
				cos(circle_angle) * circle_radius,
				0,
				sin(circle_angle) * circle_radius
			)
			target_pos.y = fly_height

			var direction = (target_pos - global_position).normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed

			_look_at_target()

			# Lanzar picada si el cooldown terminó
			if dive_cooldown <= 0.0:
				state = HawkState.DIVING

		HawkState.DIVING:
			# Picada directa hacia el jugador — más veloz que el ave común
			var direction = (target.global_position - global_position).normalized()
			velocity.x = direction.x * dive_speed
			velocity.z = direction.z * dive_speed
			velocity.y = direction.y * dive_speed

			_look_at_target()

			# Si llegó al rango de ataque o tocó el suelo, agarrar y retirarse
			if distance_to_target <= attack_range or global_position.y <= 0.5:
				if can_attack and target.has_method("take_damage"):
					perform_attack()
				state = HawkState.RETREATING
				dive_cooldown = 2.0
				velocity.y = 8.0  # Impulso fuerte hacia arriba (simula soltar)

		HawkState.RETREATING:
			# Subiendo — _idle_behavior maneja la subida
			pass


## Agarre: daño base + 5 de daño de caída (dos hits separados)
func perform_attack() -> void:
	can_attack = false
	if is_instance_valid(target):
		target.take_damage(damage)
		# Daño de caída — se aplica con pequeño delay, simula el drop
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(target):
			target.take_damage(5.0)
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true


func _pick_wander_target() -> void:
	var angle = randf() * TAU
	var dist = randf_range(2.0, wander_radius)
	wander_target = spawn_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	wander_target.y = fly_height


func _on_death() -> void:
	velocity.y = -10.0
