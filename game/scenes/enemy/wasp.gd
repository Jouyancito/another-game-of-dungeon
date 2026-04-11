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

# Movimiento errático (buzz)
var _buzz_offset := Vector3.ZERO
var _buzz_timer := 0.0
const BUZZ_INTERVAL := 0.08


func _on_enemy_ready() -> void:
	enemy_type = "wasp"
	default_color = Color(0.9, 0.8, 0.1)
	nest_position = global_position
	fly_height = randf_range(1.5, 2.5)
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
	can_attack = false
	if is_instance_valid(target):
		target.take_damage(damage)
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
