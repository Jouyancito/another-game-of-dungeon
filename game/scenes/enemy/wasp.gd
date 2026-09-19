extends BaseEnemy

## Avispa — mob neutral ligado a un nido
## Pacífica en su nido. Si el jugador se acerca al nido (8m), toda la colmena agro.
## Si el jugador se aleja más de 12m del nido, las avispas vuelven y se desagro.
## Ataque: picadura rápida + 2 ticks de veneno (1 DMG cada uno).

# Nido
@export var nest_position := Vector3.ZERO

# Vuelo
var fly_height := 1.5  # Aleatorio por avispa: 1.5-2.5m

# Umbrales de agro por distancia al NIDO (no a la avispa)
const NEST_AGRO_RANGE := 8.0
const NEST_LEASH_RANGE := 12.0

## Radius in which a struck wasp calls its neighbours in (canon _floor1_integral_plan.md §7).
const SWARM_ALERT_RANGE := 8.0

# Movimiento errático (buzz)
var _buzz_offset := Vector3.ZERO
var _buzz_timer := 0.0
const BUZZ_INTERVAL := 0.08


## Raycast down to get terrain Y at pos, returns terrain_y + offset.
func _terrain_fly_y_at(pos: Vector3, offset: float) -> float:
	var space := get_world_3d().direct_space_state
	if space == null:
		return pos.y + offset
	var ray_from := Vector3(pos.x, pos.y + 100.0, pos.z)
	var ray_to := Vector3(pos.x, pos.y - 100.0, pos.z)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.collision_mask = 1  # Layer World only
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return pos.y + offset
	return hit.position.y + offset


## Swatting one wasp brings the swarm. Without this, aggro only ever came from walking
## near the NEST — so an archer could pick the colony off one by one from 15m and the
## hive would never react. Now the sting travels: hurt one, and its neighbours come.
func take_damage(
	amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0,
	attacker_str := 0, attacker: Node = null, element: String = "physical",
	is_crit: bool = false
) -> void:
	var was_alive := not is_dead
	super.take_damage(amount, hit_direction, knockback_force, attacker_str, attacker, element, is_crit)
	if was_alive:
		_alert_swarm(attacker)


## Wakes every wasp within SWARM_ALERT_RANGE and points it at whoever threw the punch.
## Matches on enemy_type rather than a class_name: base_enemy.gd deliberately avoids
## class_name on enemies to dodge load-order issues, and enemy_type IS the roster id.
func _alert_swarm(attacker: Node) -> void:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not (node is BaseEnemy):
			continue
		var other := node as BaseEnemy
		if other.enemy_type != "wasp" or other.is_dead or other.is_provoked:
			continue
		if global_position.distance_to(other.global_position) > SWARM_ALERT_RANGE:
			continue
		other.is_provoked = true
		if attacker != null and is_instance_valid(attacker):
			other.target = attacker


func _on_enemy_ready() -> void:
	enemy_type = "wasp"
	default_color = Color(0.9, 0.8, 0.1)
	# Aerial niche — it owns the air above the field, not a patch of ground.
	habitat_type = "aerial"
	nest_position = global_position
	# fly_height offset is relative; compute absolute Y from terrain under spawn.
	var height_offset: float = randf_range(1.5, 2.5)
	fly_height = _terrain_fly_y_at(global_position, height_offset)
	global_position.y = fly_height
	mesh.visible = false
	var model := EnemyModelBuilder.build_arthropod(
		default_color,
		0.12,
		0.06,
		0.05,
		6,
		false,
		false
	)
	model.name = "Model"
	add_child(model)
	var wing_mat := MannequinBuilder.create_material(Color(0.9, 0.9, 1.0, 0.5))
	for side in [-1, 1]:
		var wing := MannequinBuilder.create_box(Vector3(0.08, 0.005, 0.04), wing_mat)
		wing.name = "Wing_%s" % ("R" if side > 0 else "L")
		wing.rotation_degrees = Vector3(0, 0, side * -15.0)
		wing.position = Vector3(side * 0.05, 0.06, 0.0)
		model.add_child(wing)


func _apply_gravity(_delta: float) -> void:
	# Mantener altura de vuelo en todo momento
	velocity.y = (fly_height - global_position.y) * 4.0


## Solo perseguir si el jugador está dentro del rango del nido
func _should_pursue(distance: float) -> bool:
	if target == null:
		return false

	# Si el jugador ya se fue lejos del nido, desagroar
	var dist_player_to_nest = target.global_position.distance_to(nest_position)
	if is_provoked and dist_player_to_nest > NEST_LEASH_RANGE:
		is_provoked = false
		return false

	# Agroar si el jugador se acerca al nido (aunque la avispa esté lejos)
	if not is_provoked and dist_player_to_nest <= NEST_AGRO_RANGE:
		is_provoked = true

	return super._should_pursue(distance)


func _idle_behavior(delta: float) -> void:
	# Deambular aleatoriamente dentro de 3m del nido
	_buzz_timer -= delta
	if _buzz_timer <= 0.0:
		_buzz_timer = BUZZ_INTERVAL
		var angle = randf() * TAU
		var dist = randf_range(0.5, 3.0)
		var wander_pos = nest_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		# Target the current fly_height (terrain-relative absolute Y set at spawn).
		wander_pos.y = fly_height
		var dir = (wander_pos - global_position).normalized()
		_buzz_offset = dir * speed * 0.4

	velocity.x = _buzz_offset.x
	velocity.z = _buzz_offset.z


func _move_toward_target(delta: float) -> void:
	# Acercarse con movimiento errático tipo zumbido
	_buzz_timer -= delta
	if _buzz_timer <= 0.0:
		_buzz_timer = BUZZ_INTERVAL
		# Offset aleatorio en XZ para simular el vuelo errático
		_buzz_offset = Vector3(
			randf_range(-1.5, 1.5),
			0.0,
			randf_range(-1.5, 1.5)
		)

	var direction = (target.global_position - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * speed + _buzz_offset.x
	velocity.z = direction.z * speed + _buzz_offset.z

	_look_at_target()


## Picadura: daño base + 2 ticks de veneno de 1 DMG c/u
func perform_attack() -> void:
	if has_status(&"stun"):
		return  # stun pausa ataque (canon _status_effects.md §2.2)
	can_attack = false
	if is_instance_valid(target):
		target.take_damage(damage * outgoing_damage_mult())
		# Tick 1 de veneno
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(target) and not target.get("is_dead"):
			target.take_damage(1.0)
		# Tick 2 de veneno
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(target) and not target.get("is_dead"):
			target.take_damage(1.0)
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true


func _on_death() -> void:
	velocity.y = -5.0
