class_name Wolf
extends BaseEnemy

## Wolf (Lobo) — pack predator
## Se mueve en manada. El alpha lidera, los demás flanquean.
## Ataque de carga: lunge recto a 3x velocidad durante 0.3s.
## Cuando el alpha muere, todos los lobos cercanos huyen y desaparecen.

@export var is_alpha := false

# Carga
var charge_timer := 0.0
var charge_cooldown := 4.5  # segundos entre cargas
var is_charging := false
var charge_elapsed := 0.0
const CHARGE_DURATION := 0.3
const CHARGE_SPEED_MULTIPLIER := 3.0
const CHARGE_MIN_DISTANCE := 3.0

# Pack / muerte del alpha
var alpha_dead := false
var flee_timer := 0.0
const FLEE_DURATION := 5.0
const ALPHA_DETECTION_RADIUS := 20.0

# Patrulla idle
var spawn_position := Vector3.ZERO
var patrol_direction := Vector3.ZERO
var patrol_timer := 0.0


func _on_enemy_ready() -> void:
	enemy_type = "wolf"
	if is_alpha:
		default_color = Color(0.35, 0.35, 0.35)
		health *= 1.2  # +20% HP → 108
		scale = Vector3(1.15, 1.15, 1.15)
	else:
		default_color = Color(0.5, 0.5, 0.5)

	mass = 0.8
	spawn_position = global_position
	charge_timer = randf_range(2.0, charge_cooldown)  # offset inicial para que no carguen todos a la vez

	# Aplicar color al mesh si ya está disponible
	if mesh and mesh.get_surface_override_material(0) == null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = default_color
		mesh.set_surface_override_material(0, mat)

	mesh.visible = false
	var model := EnemyModelBuilder.build_quadruped(
		default_color,
		0.6,    # body_length (bigger than fox)
		0.25,   # body_height
		0.25,   # body_width
		0.3,    # leg_height (taller)
		0.04,   # leg_radius
		true,   # has_tail
		0.25    # tail_length
	)
	model.name = "Model"
	add_child(model)


func _move_toward_target(delta: float) -> void:
	# Si el alpha murió: huir en lugar de perseguir
	if alpha_dead:
		_flee_behavior(delta)
		return

	var distance := global_position.distance_to(target.global_position)

	# Manejar carga activa
	if is_charging:
		charge_elapsed += delta
		if charge_elapsed >= CHARGE_DURATION:
			is_charging = false
			charge_elapsed = 0.0
		else:
			# Mantener impulso de carga (dirección ya aplicada)
			return

	# Temporizador de carga
	charge_timer -= delta
	if charge_timer <= 0.0 and distance > CHARGE_MIN_DISTANCE:
		_start_charge()
		charge_timer = randf_range(charge_cooldown - 0.5, charge_cooldown + 0.5)
		return

	# Movimiento normal hacia el target
	var direction := (target.global_position - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


func _start_charge() -> void:
	if not is_instance_valid(target):
		return
	is_charging = true
	charge_elapsed = 0.0
	var direction := (target.global_position - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * speed * CHARGE_SPEED_MULTIPLIER
	velocity.z = direction.z * speed * CHARGE_SPEED_MULTIPLIER

	# Daño extra al llegar (se evalúa en physics_process via attack normal —
	# la velocidad alta hace que llegue a attack_range más rápido)


func _flee_behavior(delta: float) -> void:
	flee_timer -= delta
	if flee_timer <= 0.0:
		# Tiempo de huida terminado — detener y despawnear
		velocity.x = 0
		velocity.z = 0
		queue_free()
		return

	if not is_instance_valid(target):
		return

	# Moverse en dirección opuesta al target
	var away := (global_position - target.global_position).normalized()
	away.y = 0
	velocity.x = away.x * speed * 1.5
	velocity.z = away.z * speed * 1.5


func _idle_behavior(delta: float) -> void:
	if alpha_dead:
		_flee_behavior(delta)
		return

	# Patrulla simple alrededor del punto de spawn
	patrol_timer -= delta
	if patrol_timer <= 0.0:
		patrol_timer = randf_range(2.0, 4.0)
		var angle := randf_range(0.0, TAU)
		patrol_direction = Vector3(cos(angle), 0.0, sin(angle))

	var dist_from_spawn := global_position.distance_to(spawn_position)
	if dist_from_spawn > 5.0:
		# Volver al spawn si se alejó demasiado
		patrol_direction = (spawn_position - global_position).normalized()
		patrol_direction.y = 0

	velocity.x = patrol_direction.x * (speed * 0.4)
	velocity.z = patrol_direction.z * (speed * 0.4)


func _on_death() -> void:
	if is_alpha:
		_notify_pack_alpha_dead()


func _notify_pack_alpha_dead() -> void:
	var all_enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for node in all_enemies:
		if not is_instance_valid(node):
			continue
		if not node is Wolf:
			continue
		var wolf := node as Wolf
		if wolf == self:
			continue
		var dist := global_position.distance_to(wolf.global_position)
		if dist <= ALPHA_DETECTION_RADIUS:
			wolf._on_alpha_died()


func _on_alpha_died() -> void:
	alpha_dead = true
	flee_timer = FLEE_DURATION
	aggression = AggressionType.NEUTRAL
	is_provoked = false
