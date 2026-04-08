class_name BaseEnemy
extends CharacterBody3D

## Tipos de agresividad
enum AggressionType { AGGRESSIVE, NEUTRAL }

# Stats base
@export var speed := 3.0
@export var health := 100.0
@export var damage := 10.0
@export var attack_range := 2.0
@export var detection_range := 15.0
@export var xp_reward := 30.0
@export var attack_cooldown := 1.0
@export var aggression: AggressionType = AggressionType.AGGRESSIVE

# Estado
var target: Node3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_dead := false
var can_attack := true
var is_provoked := false  # Para neutrales: se activa al recibir daño

# Referencia al mesh — cada hijo define su nodo
@onready var mesh: MeshInstance3D = $MeshInstance3D

# Color original del mesh (cada hijo lo define)
var default_color := Color(0.8, 0.2, 0.2)


func _ready() -> void:
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
	_on_enemy_ready()


## Override en subclases para setup específico
func _on_enemy_ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_apply_gravity(delta)
	_validate_target()

	if target == null:
		_idle_behavior(delta)
		move_and_slide()
		return

	var distance = global_position.distance_to(target.global_position)
	var should_chase = _should_pursue(distance)

	if should_chase and distance <= detection_range:
		_look_at_target()

		if distance > attack_range:
			_move_toward_target(delta)
		else:
			velocity.x = 0
			velocity.z = 0
			if can_attack and target.has_method("take_damage"):
				perform_attack()
	else:
		_idle_behavior(delta)

	move_and_slide()


## Determina si este enemigo debería perseguir al jugador
func _should_pursue(distance: float) -> bool:
	if aggression == AggressionType.AGGRESSIVE:
		return distance <= detection_range
	# NEUTRAL: solo si fue provocado
	return is_provoked and distance <= detection_range


## Comportamiento cuando no persigue — override para deambular
func _idle_behavior(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0


## Movimiento hacia el target — override para movimiento custom (ej: saltos)
func _move_toward_target(_delta: float) -> void:
	var direction = (target.global_position - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta


func _validate_target() -> void:
	if target != null and not is_instance_valid(target):
		target = null


func _look_at_target() -> void:
	var look_pos = target.global_position
	look_pos.y = global_position.y
	look_at(look_pos)


func perform_attack() -> void:
	can_attack = false
	if is_instance_valid(target):
		target.take_damage(damage)
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true


func take_damage(amount: float) -> void:
	if is_dead:
		return

	# Provocar si es neutral
	if aggression == AggressionType.NEUTRAL and not is_provoked:
		is_provoked = true

	health -= amount
	_flash_damage()

	if health <= 0:
		die()


func _flash_damage() -> void:
	if not mesh:
		return
	var material = mesh.get_surface_override_material(0)
	if material == null:
		material = mesh.mesh.surface_get_material(0)
		if material:
			material = material.duplicate()
			mesh.set_surface_override_material(0, material)
	if material and material is StandardMaterial3D:
		material.albedo_color = Color(1, 0, 0)
		await get_tree().create_timer(0.2).timeout
		if not is_instance_valid(self) or is_dead:
			return
		material.albedo_color = default_color


func die() -> void:
	is_dead = true
	remove_from_group("enemies")
	var col = get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", true)
	if target and target.has_method("gain_xp"):
		target.gain_xp(xp_reward)
	_on_death()
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.5)
	tween.tween_callback(queue_free)


## Override para efectos de muerte custom
func _on_death() -> void:
	pass
