class_name BanditMelee
extends BaseEnemy

## Bandido cuerpo a cuerpo — 3 ataques ciclicos, bloqueo 30%, strafe entre ataques
@export var can_block := true
@export var block_chance := 0.3
@export var block_damage_reduction := 0.5

# Estado de ataque
var attack_index := 0  # 0 = slash, 1 = shield bash, 2 = charged heavy
var _is_charging := false
var _is_stunned := false
var _stun_timer := 0.0

# Strafe
var _strafe_direction := 1.0
var _strafe_timer := 0.0
var _strafe_interval := 1.5


func _on_enemy_ready() -> void:
	enemy_type = "bandit"
	default_color = Color(0.55, 0.35, 0.2)
	_strafe_direction = 1.0 if randf() > 0.5 else -1.0
	mesh.visible = false
	var model := EnemyModelBuilder.build_humanoid(
		default_color,    # brown Color(0.55, 0.35, 0.2)
		1.0,              # height_scale (normal human)
		1.0               # width_scale
	)
	model.name = "Model"
	add_child(model)
	# Add a weapon box (sword) in right hand area
	var weapon_mat := MannequinBuilder.create_material(Color(0.6, 0.6, 0.6))
	var sword := MannequinBuilder.create_box(Vector3(0.04, 0.5, 0.04), weapon_mat)
	sword.name = "Sword"
	sword.position = Vector3(0.25, 0.5, 0.15)
	model.add_child(sword)


func _physics_process(delta: float) -> void:
	if _is_stunned:
		_stun_timer -= delta
		if _stun_timer <= 0.0:
			_is_stunned = false
		velocity.x = 0
		velocity.z = 0
		_apply_gravity(delta)
		move_and_slide()
		return

	super._physics_process(delta)


## Strafe lateral entre ataques, en lugar de detenerse completamente
func _move_toward_target(_delta: float) -> void:
	if target == null:
		return

	var to_target = (target.global_position - global_position)
	to_target.y = 0
	var distance = to_target.length()
	var forward = to_target.normalized()

	# Perpendicular al target (strafe)
	var right = forward.cross(Vector3.UP).normalized()

	_strafe_timer += _delta
	if _strafe_timer >= _strafe_interval:
		_strafe_timer = 0.0
		_strafe_direction *= -1.0

	if distance > attack_range + 0.5:
		# Caminar hacia + leve strafe
		velocity.x = (forward.x + right.x * _strafe_direction * 0.4) * speed
		velocity.z = (forward.z + right.z * _strafe_direction * 0.4) * speed
	else:
		# Solo strafe una vez en rango
		velocity.x = right.x * _strafe_direction * (speed * 0.5)
		velocity.z = right.z * _strafe_direction * (speed * 0.5)


## Cicla: slash → shield bash → charged heavy → slash…
func perform_attack() -> void:
	if _is_charging or _is_stunned:
		return

	can_attack = false

	match attack_index:
		0:
			_attack_slash()
		1:
			_attack_shield_bash()
		2:
			_attack_charged_heavy()

	attack_index = (attack_index + 1) % 3

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self) or is_dead:
		return
	can_attack = true


## Ataque 1 — Slash horizontal (daño base)
func _attack_slash() -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)


## Ataque 2 — Shield bash: knockback + stun breve (0.8s sin atacar)
func _attack_shield_bash() -> void:
	if not is_instance_valid(target):
		return

	if target.has_method("take_damage"):
		target.take_damage(damage * 0.6)

	# Knockback al jugador
	if target.has_method("apply_knockback"):
		var dir = (target.global_position - global_position).normalized()
		target.apply_knockback(dir, 8.0)

	# El bandido no ataca brevemente después (simula el "stun" del bash)
	_is_stunned = true
	_stun_timer = 0.8


## Ataque 3 — Charged heavy: telegraph 1s, luego 1.5x daño
func _attack_charged_heavy() -> void:
	_is_charging = true

	# Telegraph visual — escalar mesh hacia arriba
	if is_instance_valid(mesh):
		var tween = create_tween()
		tween.tween_property(mesh, "scale", Vector3(1.3, 1.3, 1.3), 0.4)
		tween.tween_property(mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.2)

	await get_tree().create_timer(1.0).timeout

	if not is_instance_valid(self) or is_dead:
		_is_charging = false
		return

	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage * 1.5)

	_is_charging = false


## Override take_damage — 30% chance de bloquear (reduce daño 50%)
func take_damage(amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0, attacker_str := 0) -> void:
	if is_dead:
		return

	var final_amount := amount
	if can_block and randf() < block_chance:
		final_amount *= (1.0 - block_damage_reduction)

	super.take_damage(final_amount, hit_direction, knockback_force, attacker_str)
