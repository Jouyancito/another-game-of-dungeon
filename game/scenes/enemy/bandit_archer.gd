class_name BanditArcher
extends BaseEnemy

## Bandido arquero — mantiene distancia, huye si el jugador se acerca, ataque a distancia
@export var flee_range := 5.0       # Si el jugador entra a esta distancia, huir
@export var ideal_range := 12.0     # Distancia que intenta mantener
@export var strafe_speed_mult := 0.6

# Strafe
var _strafe_direction := 1.0
var _strafe_timer := 0.0
var _strafe_interval := 2.0


func _on_enemy_ready() -> void:
	enemy_type = "bandit_archer"
	default_color = Color(0.4, 0.45, 0.3)
	_strafe_direction = 1.0 if randf() > 0.5 else -1.0
	mesh.visible = false

	# Load ninja gltf — the ninja's lean silhouette reads as an agile archer.
	# The bow attachment is preserved exactly as before (parented to model root).
	const NINJA_PATH := "res://assets/art/piso1_pradera/enemies/big/enemy_ninja.gltf"
	var packed: PackedScene = load(NINJA_PATH) if ResourceLoader.exists(NINJA_PATH) else null
	var model_root: Node3D
	if packed != null:
		model_root = packed.instantiate()
		model_root.name = "Model"
		model_root.rotation.y = PI  # Quaternius mira +Z; girar 180° (si no, de espaldas)
		add_child(model_root)
	else:
		push_warning("BanditArcher: enemy_ninja.gltf not found, using proc mesh")
		model_root = EnemyModelBuilder.build_humanoid(default_color, 0.95, 0.9)
		model_root.name = "Model"
		add_child(model_root)

	# Bow attachment — preserved from original, parented to model root
	var bow_mat := MannequinBuilder.create_material(Color(0.5, 0.3, 0.15))
	var bow := MannequinBuilder.create_cylinder(0.02, 0.5, bow_mat)
	bow.name = "Bow"
	bow.position = Vector3(-0.25, 0.6, 0.1)
	model_root.add_child(bow)


## Returns the gltf model root so EnemyAnimator can find the AnimationPlayer.
func _get_anim_model_root() -> Node3D:
	return get_node_or_null("Model")


## Lógica de movimiento: huir, holdear, o acercarse según distancia
func _move_toward_target(_delta: float) -> void:
	if target == null:
		velocity.x = 0
		velocity.z = 0
		return

	var to_target = (target.global_position - global_position)
	to_target.y = 0
	var distance = to_target.length()
	var forward = to_target.normalized()
	var right = forward.cross(Vector3.UP).normalized()

	_strafe_timer += _delta
	if _strafe_timer >= _strafe_interval:
		_strafe_timer = 0.0
		_strafe_direction *= -1.0

	if distance < flee_range:
		# HUIR — aleja del jugador
		velocity.x = -forward.x * speed
		velocity.z = -forward.z * speed

	elif distance <= ideal_range:
		# Rango cómodo — solo strafe
		velocity.x = right.x * _strafe_direction * speed * strafe_speed_mult
		velocity.z = right.z * _strafe_direction * speed * strafe_speed_mult

	else:
		# Muy lejos — acercarse hasta ideal_range
		velocity.x = forward.x * speed
		velocity.z = forward.z * speed


## El arquero SIEMPRE se mueve (no se detiene al entrar en attack_range)
## BaseEnemy para el movimiento cuando distance > attack_range; aquí overrideamos
## la lógica completa vía _physics_process no — usamos que BaseEnemy llama
## _move_toward_target cuando distance > attack_range. El arquero tiene
## attack_range = 15m, así que casi nunca llega ahí. El movimiento de flee
## necesita operar incluso cuando distance < attack_range. Para eso overrideamos
## directamente _physics_process.
func _physics_process(delta: float) -> void:
	if has_meta("is_preview"):
		return
	_update_nameplate()

	if is_dead:
		return

	_apply_gravity(delta)
	_validate_target()

	# Re-scan igual que BaseEnemy — este override no pasa por super, así que
	# el re-acquire del fix del agro debe replicarse acá para que el archer
	# también fichara al player spawneado tarde.
	if target == null:
		_try_acquire_target()
	if target == null:
		_idle_behavior(delta)
		move_and_slide()
		return

	var distance = global_position.distance_to(target.global_position)
	var should_chase = _should_pursue(distance)

	if should_chase and distance <= detection_range:
		_look_at_target()
		_move_toward_target(delta)  # siempre, lógica interna decide flee/strafe/approach

		if distance <= attack_range and can_attack and target.has_method("take_damage"):
			perform_attack()
	else:
		_idle_behavior(delta)

	move_and_slide()
	# Drive animation state (no-op when _anim is nil — procedural fallback).
	if _anim != null and not is_dead:
		var hspeed := Vector2(velocity.x, velocity.z).length()
		_anim.play_state(hspeed)


## Ataque a distancia — raycast simplificado (solo distancia)
## No instancia proyectil por ahora; aplica daño directo si hay línea de visión clara
func perform_attack() -> void:
	can_attack = false

	if is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		if distance <= attack_range:
			# Line-of-sight check con raycast al jugador
			var space = get_world_3d().direct_space_state
			var from = global_position + Vector3.UP * 0.8
			var to = target.global_position + Vector3.UP * 0.8
			var query = PhysicsRayQueryParameters3D.create(from, to)
			query.exclude = [self]
			query.collision_mask = 0b001  # Layer 1: World (paredes/suelo)
			var result = space.intersect_ray(query)

			# Si el rayo no golpeó nada (o golpeó al jugador), hay línea de visión
			if result.is_empty() or result.collider == target:
				target.take_damage(damage)

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self) or is_dead:
		return
	can_attack = true
