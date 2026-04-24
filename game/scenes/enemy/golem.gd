class_name Golem
extends BaseEnemy

## Golem de Piedra — NEUTRAL, se camufla como roca hasta que el jugador se acerca.
## Ataques: Puñetazo (melee + knockback), Pisotón AoE, Lanzar roca (rango).

var is_dormant := true
var awaken_tween: Tween
var attack_index := 0
var stomp_range := 3.0
var throw_range := 10.0

@onready var head_mesh: MeshInstance3D = $Head


func _on_enemy_ready() -> void:
	enemy_type = "golem"
	default_color = Color(0.5, 0.5, 0.5)
	mass = 3.0
	knockback_resistance = 0.7
	mesh.visible = false
	# Also hide the Head mesh from .tscn
	var old_head: Node = get_node_or_null("Head")
	if old_head:
		old_head.visible = false
	var model := EnemyModelBuilder.build_humanoid(
		default_color,
		1.5,    # height_scale (tall golem, 2.5m)
		1.4     # width_scale (wide, stocky)
	)
	model.name = "Model"
	add_child(model)
	# Dormant: aplastado como roca
	scale = Vector3(1.2, 0.5, 1.2)


## Override: NEUTRAL + lógica de despertar por proximidad
func _should_pursue(distance: float) -> bool:
	if is_dormant:
		if distance <= detection_range:
			_awaken()
		return false
	# Una vez despierto, comportamiento NEUTRAL estándar
	return is_provoked and distance <= detection_range


func _awaken() -> void:
	if awaken_tween and awaken_tween.is_running():
		return
	awaken_tween = create_tween()
	awaken_tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.5)
	awaken_tween.tween_callback(func():
		is_dormant = false
		is_provoked = true
	)


## Idle: inmóvil, camuflado como roca
func _idle_behavior(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0


## Movimiento lento y deliberado — sin cambios sobre la base
func _move_toward_target(_delta: float) -> void:
	var direction = (target.global_position - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


## Override take_damage: si duerme, despertar antes de recibir daño
func take_damage(amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0, attacker_str := 0, attacker: Node = null, element: String = "physical", is_crit: bool = false) -> void:
	if is_dormant:
		_awaken()
	super.take_damage(amount, hit_direction, knockback_force, attacker_str, attacker, element, is_crit)


## Cicla entre 3 ataques: Puñetazo → Pisotón AoE → Lanzar roca
func perform_attack() -> void:
	if not can_attack:
		return
	can_attack = false

	match attack_index:
		0:
			_attack_punch()
		1:
			_attack_stomp()
		2:
			_attack_rock_throw()

	attack_index = (attack_index + 1) % 3

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self) or is_dead:
		return
	can_attack = true


## Puñetazo: daño base + knockback al target
func _attack_punch() -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		target.take_damage(damage)
	if target.has_method("apply_knockback"):
		var direction = (target.global_position - global_position).normalized()
		target.apply_knockback(direction, 12.0)


## Pisotón AoE: daña a TODOS los jugadores dentro de stomp_range
func _attack_stomp() -> void:
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if not is_instance_valid(player):
			continue
		var dist = global_position.distance_to(player.global_position)
		if dist <= stomp_range and player.has_method("take_damage"):
			player.take_damage(damage * 0.8)


## Lanzar roca: daño a rango, sin proyectil — hit directo simplificado
func _attack_rock_throw() -> void:
	if not is_instance_valid(target):
		return
	var dist = global_position.distance_to(target.global_position)
	if dist <= throw_range and target.has_method("take_damage"):
		target.take_damage(damage * 0.6)


## Muerte: sin efecto extra por ahora
func _on_death() -> void:
	pass


## Knockback: el golem es muy pesado, reacción mínima
func _on_knockback(_kb_velocity: Vector3) -> void:
	pass
