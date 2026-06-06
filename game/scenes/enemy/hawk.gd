extends BaseEnemy

## Halcón — mob neutral
## Vuela alto y deambula en círculos. Solo ataca si lo provocan.
## Ataque especial: agarra al jugador y lo suelta — daño base + 5 de caída.

# Vuelo — canon fauna_spec.md Fase 1 (2026-05-07): halcón verdadero, alto 10m.
# Fuera del range de arco normal en altura. Solo atacable durante DIVING (y<=1.5).
@export var fly_height := 14.0
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
	# Personalidad: cazador veloz. HUNTER_FAST activa detección amplia + persistencia alta.
	# speed_mult de HUNTER_FAST NO aplica al hawk (su _move_toward_target es estado-máquina
	# independiente con dive_speed propio). La detección y persistencia sí aplican.
	personality = AggroPersonality.HUNTER_FAST
	default_color = Color(0.7, 0.55, 0.25)
	spawn_position = global_position
	spawn_position.y = fly_height
	global_position.y = fly_height
	dive_cooldown = 2.0  # Delay primer dive — da tiempo a circular cuando se provoca
	_pick_wander_target()
	mesh.visible = false
	var old_beak: Node = get_node_or_null("Beak")
	if old_beak:
		old_beak.visible = false
	# Mesh canon fauna_spec.md Fase 1 — escalado para que sea visible desde abajo a 10m.
	# Body 0.35 (antes 0.2), alas 0.7 (antes 0.4), cola 0.4 (antes 0.25).
	var model := EnemyModelBuilder.build_flyer(
		default_color,
		0.35,
		0.7,
		0.4
	)
	model.name = "Model"
	add_child(model)


func _apply_gravity(_delta: float) -> void:
	# Solo mantener altura en idle y circling
	if state == HawkState.IDLE or state == HawkState.CIRCLING:
		velocity.y = (fly_height - global_position.y) * 3.0
	elif state == HawkState.RETREATING:
		# Subida simétrica al dive — el descenso usa dive_speed*0.6 (~7 m/s),
		# el lift debe ser ~7 m/s para sentirse natural, no más rápido que la picada.
		velocity.y = (fly_height - global_position.y) * 0.5
	elif state == HawkState.DIVING:
		# Cerca del suelo, no clavarse — corta caída
		if global_position.y <= 1.0:
			velocity.y = maxf(velocity.y, 0.0)


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
			# Picada directa hacia el jugador — descenso controlado (Y más lento que XZ)
			var direction = (target.global_position - global_position).normalized()
			velocity.x = direction.x * dive_speed
			velocity.z = direction.z * dive_speed
			velocity.y = direction.y * dive_speed * 0.6

			# Guard: cerca del suelo, no clavarse — frenar caída antes del hit
			if global_position.y <= 1.5:
				velocity.y = maxf(velocity.y, 0.0)

			_look_at_target()

			# Si llegó al rango de ataque o tocó el suelo, agarrar y retirarse
			if distance_to_target <= attack_range or global_position.y <= 0.5:
				if can_attack and target.has_method("take_damage"):
					perform_attack()
				state = HawkState.RETREATING
				dive_cooldown = 3.5  # tiempo de subir + circular antes próxima picada
				# Despegarse del player — sino CharacterBody3D collision lo deja
				# pegado al cuerpo y daño constante. Reset velocity x/z hacia AFUERA
				# del player + teleport vertical para romper collision instantáneo.
				var away: Vector3 = global_position - target.global_position
				away.y = 0
				if away.length() < 0.1:
					away = Vector3.RIGHT
				away = away.normalized()
				velocity.x = away.x * dive_speed * 1.2
				velocity.z = away.z * dive_speed * 1.2
				velocity.y = 8.0  # Impulso fuerte hacia arriba (simula soltar)
				# Teleport up 1.5m para romper collision con player CharacterBody3D.
				global_position.y += 1.5

		HawkState.RETREATING:
			# Subiendo — _idle_behavior maneja la subida
			pass


## Agarre: daño base + 5 de daño de caída (dos hits separados).
## Push-back inmediato post-hit: base_enemy._physics_process pone velocity=0
## ANTES de llamar perform_attack, así que setear vel hacia afuera DENTRO de
## este método es la única forma de despegarse del player.
func perform_attack() -> void:
	can_attack = false
	if is_instance_valid(target):
		target.take_damage(damage * outgoing_damage_mult(), "", self)
		_retreat_push()
		# Daño de caída — se aplica con pequeño delay, simula el drop
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(target):
			target.take_damage(5.0, "", self)
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true


func _retreat_push() -> void:
	# Continuar la dirección del vuelo (forward) en vez de invertir hacia atrás.
	# Realismo: un ave que pica no frena y vuelve por donde vino — atraviesa la presa
	# y sigue el arco hacia adelante, ganando altura gradualmente.
	state = HawkState.RETREATING
	dive_cooldown = 3.5
	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0
	if forward.length() < 0.1:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	velocity.x = forward.x * dive_speed * 0.8
	velocity.z = forward.z * dive_speed * 0.8
	velocity.y = 3.0  # Impulso vertical menor — _apply_gravity hace el lift gradual
	global_position.y += 1.5  # Romper collision con player CharacterBody3D


func _pick_wander_target() -> void:
	var angle = randf() * TAU
	var dist = randf_range(2.0, wander_radius)
	wander_target = spawn_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	wander_target.y = fly_height


func _on_death() -> void:
	velocity.y = -10.0
