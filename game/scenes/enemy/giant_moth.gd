extends BaseEnemy

## Polilla gigante — bestiario canon del Piso 2 (`lore/_alpha_5_maps.md`: "búhos, serpientes
## entre arbustos, polillas gigantes").
##
## Es del bosque de luna llena, y su lógica sale de eso: una polilla va a la luz. Acá la luz
## más brillante del bosque sos vos — tu antorcha. Por eso no patrulla ni acecha: DERIVA
## hacia el jugador, en zigzag, como algo que no decide sino que es atraído.
##
## Tier 2 (canon `enemy_tier_system.md`: "el tier de un piso = numero de piso").
## Sub-tier A: es fauna, no un depredador. Peligrosa en número, no de a una.

## Cuánto se desvía del rumbo directo. Una polilla no vuela recto — si lo hiciera, leería
## como un misil.
const DRIFT_AMPLITUDE: float = 1.5
const DRIFT_FREQUENCY: float = 2.2

## Altura de vuelo sobre el suelo.
const FLY_HEIGHT: float = 2.2

var _drift_time: float = 0.0


func _on_enemy_ready() -> void:
	enemy_type = "giant_moth"
	display_name = "Polilla Gigante"
	enemy_tier = 2
	sub_tier = SubTier.A
	aggression = AggressionType.AGGRESSIVE
	habitat_type = "aerial"

	# Tier 2 sub-A — canon enemy_tier_system.md §3 (sub-A = 1.0x del tier).
	health = 70.0
	damage = 11.0
	speed = 3.4
	mass = 0.4
	knockback_resistance = 0.0
	attack_range = 1.8
	detection_range = 14.0     # te ve de lejos: sos la luz
	attack_cooldown = 1.6
	xp_reward = 22.0

	default_color = Color(0.55, 0.50, 0.62)
	mesh.visible = false

	var model := EnemyModelBuilder.build_arthropod(
		default_color,
		0.55,   # body_length
		0.30,   # body_width
		0.28,   # body_height
		6,      # leg_count
		false,  # has_tail
		false   # has_pincers
	)
	model.name = "Model"
	add_child(model)
	_add_wings(model)


## Alas anchas y pálidas. Son la silueta: de noche, lo único que ves de una polilla es el
## batir. Emisivas a propósito — en un bosque negro, tienen que leerse.
func _add_wings(model: Node3D) -> void:
	for side: float in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		var quad := BoxMesh.new()
		quad.size = Vector3(0.72, 0.03, 0.5)
		wing.mesh = quad
		wing.position = Vector3(side * 0.42, 0.18, 0.0)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.78, 0.74, 0.62, 0.92)
		mat.emission_enabled = true
		mat.emission = Color(0.60, 0.58, 0.48)
		mat.emission_energy_multiplier = 0.9
		wing.material_override = mat
		model.add_child(wing)

		# Batir rápido y desfasado por ala, o parece un planeador.
		var flap := create_tween().set_loops()
		flap.tween_property(wing, "rotation:z", side * 0.55, 0.09).set_trans(Tween.TRANS_SINE)
		flap.tween_property(wing, "rotation:z", side * -0.25, 0.09).set_trans(Tween.TRANS_SINE)


## Deriva hacia la luz. No persigue: es atraída. La diferencia se ve — el zigzag dice
## "no puedo evitarlo", una línea recta diría "te estoy cazando".
func _move_toward_target(delta: float) -> void:
	_drift_time += delta

	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	var direction: Vector3 = to_target.normalized()

	# Zigzag lateral sobre el rumbo.
	var lateral: Vector3 = direction.rotated(Vector3.UP, PI * 0.5)
	var wobble: float = sin(_drift_time * DRIFT_FREQUENCY) * DRIFT_AMPLITUDE

	var move: Vector3 = direction * speed + lateral * wobble
	velocity.x = move.x
	velocity.z = move.z

	# Vuela: se mantiene a altura sobre el terreno en vez de caminar.
	var ground_y: float = _ground_y_below()
	var wanted_y: float = ground_y + FLY_HEIGHT + sin(_drift_time * 1.7) * 0.35
	velocity.y = (wanted_y - global_position.y) * 3.0


## Idle: revolotea en el sitio. Nunca se queda quieta — una polilla quieta está muerta.
func _idle_behavior(delta: float) -> void:
	_drift_time += delta
	velocity.x = cos(_drift_time * 1.1) * 0.6
	velocity.z = sin(_drift_time * 0.9) * 0.6
	var ground_y: float = _ground_y_below()
	var wanted_y: float = ground_y + FLY_HEIGHT + sin(_drift_time * 1.7) * 0.4
	velocity.y = (wanted_y - global_position.y) * 2.0


## Altura del terreno debajo. Sin esto, volar sobre una colina la hunde en la tierra.
func _ground_y_below() -> float:
	var space := get_world_3d().direct_space_state
	if space == null:
		return global_position.y - FLY_HEIGHT
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 50.0, 0),
		global_position + Vector3(0, -50.0, 0)
	)
	query.collision_mask = 1  # World
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return global_position.y - FLY_HEIGHT
	return float(hit.position.y)


## Polvo de alas: un golpe débil, pero ciega. Canon de status ya soportado por el player.
func perform_attack() -> void:
	if has_status(&"stun"):
		return
	can_attack = false

	if is_instance_valid(target):
		target.take_damage(damage * outgoing_damage_mult())

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true
