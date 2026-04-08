extends BaseEnemy

## Ave — mob neutral
## Vuela y deambula pacíficamente. Solo ataca si la provocan.
## Ataque en picada: baja, pega, sube de vuelta.

# Vuelo
@export var fly_height := 3.0
@export var wander_radius := 8.0
@export var wander_interval := 3.0
@export var dive_speed := 8.0
@export var circle_radius := 4.0
@export var circle_speed := 2.0

# Estados de ataque
enum BirdState { IDLE, CIRCLING, DIVING, RETREATING }
var state := BirdState.IDLE

var wander_timer := 0.0
var wander_target := Vector3.ZERO
var spawn_position := Vector3.ZERO
var circle_angle := 0.0
var dive_cooldown := 0.0


func _on_enemy_ready() -> void:
	default_color = Color(0.6, 0.45, 0.25)
	spawn_position = global_position
	spawn_position.y = fly_height
	global_position.y = fly_height
	_pick_wander_target()


func _apply_gravity(_delta: float) -> void:
	# Solo mantener altura en idle y circling
	if state == BirdState.IDLE or state == BirdState.CIRCLING:
		velocity.y = (fly_height - global_position.y) * 3.0
	elif state == BirdState.RETREATING:
		velocity.y = (fly_height - global_position.y) * 5.0


func _should_pursue(distance: float) -> bool:
	# Cuando está en retreat, no perseguir — dejar que suba
	if state == BirdState.RETREATING:
		return false
	return super._should_pursue(distance)


func _idle_behavior(delta: float) -> void:
	if state == BirdState.RETREATING:
		# Subiendo después de un picotazo — volver a circling cuando llega arriba
		if global_position.y >= fly_height - 0.3:
			state = BirdState.CIRCLING if is_provoked else BirdState.IDLE
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
		BirdState.IDLE:
			# Recién provocado — empezar a circular
			state = BirdState.CIRCLING
			circle_angle = atan2(
				global_position.z - target.global_position.z,
				global_position.x - target.global_position.x
			)

		BirdState.CIRCLING:
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
				state = BirdState.DIVING

		BirdState.DIVING:
			# Picada directa hacia el jugador
			var direction = (target.global_position - global_position).normalized()
			velocity.x = direction.x * dive_speed
			velocity.z = direction.z * dive_speed
			velocity.y = direction.y * dive_speed

			_look_at_target()

			# Si llegó al rango de ataque o tocó el suelo, atacar y retirarse
			if distance_to_target <= attack_range or global_position.y <= 0.5:
				if can_attack and target.has_method("take_damage"):
					perform_attack()
				state = BirdState.RETREATING
				dive_cooldown = 2.5
				velocity.y = 6.0  # Impulso hacia arriba

		BirdState.RETREATING:
			# Subiendo — no perseguir, _idle_behavior maneja la subida
			pass


func _pick_wander_target() -> void:
	var angle = randf() * TAU
	var dist = randf_range(2.0, wander_radius)
	wander_target = spawn_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	wander_target.y = fly_height


func _on_death() -> void:
	velocity.y = -10.0
