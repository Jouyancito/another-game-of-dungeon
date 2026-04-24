class_name Fox
extends BaseEnemy

## Zorro — enemigo rápido que flanquea en grupo, muerde rápido y esquiva melee.
## Stats: HP 70, DMG 9, XP 18, speed 5.5, mass 0.6

var spawn_position := Vector3.ZERO
var _weave_time := 0.0          # acumulador para el sine de weaving
var _strafe_dir := 1.0          # 1 o -1: sentido del circle-strafe


func _on_enemy_ready() -> void:
	enemy_type = "fox"
	default_color = Color(0.85, 0.45, 0.15)
	mass = 0.6
	spawn_position = global_position

	# Randomizar fase del weaving para que zorros en grupo no se sincronicen
	_weave_time = randf_range(0.0, TAU)
	_strafe_dir = 1.0 if randf() > 0.5 else -1.0

	mesh.visible = false
	var model := EnemyModelBuilder.build_quadruped(
		default_color,    # orange Color(0.85, 0.45, 0.15)
		0.5,    # body_length (elongated)
		0.2,    # body_height
		0.2,    # body_width
		0.2,    # leg_height
		0.03,   # leg_radius (slim legs)
		true,   # has_tail
		0.35    # tail_length (bushy tail — long)
	)
	model.name = "Model"
	add_child(model)
	# Fox ears: two small boxes on head
	var head_node := model.get_node("Head")
	if head_node:
		var ear_mat := MannequinBuilder.create_material(default_color, true)
		for side in [-1, 1]:
			var ear := MannequinBuilder.create_box(Vector3(0.03, 0.08, 0.03), ear_mat)
			ear.name = "Ear_%s" % ("R" if side > 0 else "L")
			ear.position = Vector3(side * 0.06, 0.1, -0.02)
			head_node.add_child(ear)


# ─── Movimiento ───────────────────────────────────────────────────────────────

func _move_toward_target(delta: float) -> void:
	if target == null:
		return

	var to_target = target.global_position - global_position
	to_target.y = 0.0
	var dist = to_target.length()

	if dist < 0.001:
		return

	var forward = to_target.normalized()

	_weave_time += delta * 3.5  # frecuencia de zigzag

	if dist <= attack_range * 2.0:
		# Circle-strafe: avanza levemente, gira alrededor del target
		var right = Vector3(forward.z, 0.0, -forward.x) * _strafe_dir
		var strafe_weight: float = clampf(1.0 - (dist - attack_range) / attack_range, 0.0, 1.0)
		var dir = forward.lerp(right, strafe_weight * 0.7).normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		# Weaving: desplazamiento lateral sinusoidal perpendicular al avance
		var right = Vector3(forward.z, 0.0, -forward.x)
		var weave_offset = right * sin(_weave_time) * 0.6
		var dir = (forward + weave_offset).normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed


# ─── Idle ─────────────────────────────────────────────────────────────────────

func _idle_behavior(delta: float) -> void:
	_weave_time += delta * 1.5
	# Deambula lentamente en radio pequeño alrededor del spawn
	var wander_radius := 2.5
	var angle = _weave_time * 0.4
	var target_wander = spawn_position + Vector3(cos(angle), 0.0, sin(angle)) * wander_radius

	var diff = target_wander - global_position
	diff.y = 0.0
	if diff.length() > 0.2:
		var dir = diff.normalized()
		velocity.x = dir.x * speed * 0.35
		velocity.z = dir.z * speed * 0.35
	else:
		velocity.x = 0.0
		velocity.z = 0.0


# ─── Dodge (esquive melee 20%) ────────────────────────────────────────────────

func take_damage(amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0, attacker_str := 0, attacker: Node = null, element: String = "physical", is_crit: bool = false) -> void:
	if is_dead:
		return

	# 20% chance de esquivar — solo esquiva golpes con dirección (melee/proyectil)
	if randf() < 0.20:
		_play_sidestep(hit_direction)
		return

	super.take_damage(amount, hit_direction, knockback_force, attacker_str, attacker, element, is_crit)


func _play_sidestep(hit_direction: Vector3) -> void:
	# Calcula dirección de esquive: perpendicular al golpe entrante
	var dodge_right := Vector3(hit_direction.z, 0.0, -hit_direction.x).normalized()
	if randf() > 0.5:
		dodge_right = -dodge_right

	var start_pos := global_position
	var end_pos := start_pos + dodge_right * 0.8

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", end_pos, 0.12)
	tween.tween_property(self, "global_position", start_pos, 0.10)
