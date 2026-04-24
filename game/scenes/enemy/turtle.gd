extends BaseEnemy

## Tortuga — neutral, lenta, resistente
## Stats: HP 90, DMG 3, DEF 8, XP 12, speed 1.5, mass 1.5, knockback_resistance 0.5
## Mechanic: al recibir daño → retracción (DEF 20, 3s, no ataca ni persigue)

const BASE_DEF := 8.0
const SHELL_DEF := 20.0
const SHELL_DURATION := 3.0

var _in_shell := false
var _shell_timer := 0.0
var _current_def := BASE_DEF

# Wander lento cerca del agua
var spawn_position := Vector3.ZERO
var _wander_timer := 0.0
var _wander_dir := Vector3.ZERO

func _on_enemy_ready() -> void:
	enemy_type = "turtle"
	default_color = Color(0.35, 0.45, 0.3)
	mass = 1.5
	knockback_resistance = 0.5
	spawn_position = global_position
	_pick_wander_dir()
	mesh.visible = false
	var model := EnemyModelBuilder.build_shelled(
		default_color,
		Color(0.45, 0.5, 0.35),  # shell_color (slightly different green)
		0.25,   # shell_radius
		0.08,   # body_height
		4       # leg_count
	)
	model.name = "Model"
	add_child(model)


# ─── Physics override: shell timer ──────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _in_shell:
		_shell_timer -= delta
		if _shell_timer <= 0.0:
			_exit_shell()
		# En retracción: no se mueve, no ataca
		velocity.x = 0.0
		velocity.z = 0.0
		_apply_gravity(delta)
		move_and_slide()
		return

	super._physics_process(delta)


# ─── Idle: deambula muy lento ────────────────────────────────────────────────

func _idle_behavior(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_wander_dir()

	var dist_from_spawn := global_position.distance_to(spawn_position)
	if dist_from_spawn > 5.0:
		_wander_dir = (spawn_position - global_position).normalized()
		_wander_dir.y = 0.0

	velocity.x = _wander_dir.x * speed * 0.5
	velocity.z = _wander_dir.z * speed * 0.5


# ─── Shell mechanic ─────────────────────────────────────────────────────────

## Override take_damage: cualquier golpe dispara la retracción
func take_damage(amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0, attacker_str := 0, attacker: Node = null, element: String = "physical", is_crit: bool = false) -> void:
	if is_dead:
		return

	# Aplicar DEF actual antes de pasar al base
	var effective_amount := maxf(amount - _current_def, 1.0)

	# Provocar si es neutral
	if aggression == AggressionType.NEUTRAL and not is_provoked:
		is_provoked = true

	# Pasar el daño ya reducido — evitar doble reducción en la base
	# Llamamos directamente sin el hook de DEF (que base_enemy no tiene por defecto)
	health -= effective_amount
	_flash_damage()

	if knockback_force > 0.0 and hit_direction != Vector3.ZERO:
		apply_knockback(hit_direction, knockback_force, attacker_str)

	# Killing blow tracking — canon drop-ownership v2.
	if health <= 0:
		if attacker != null and is_instance_valid(attacker) and attacker.has_method("get_profile_id"):
			_killer_profile_id = str(attacker.call("get_profile_id"))
		die()
		return

	# Entrar al caparazón si no está ya adentro
	if not _in_shell:
		_enter_shell()


func _enter_shell() -> void:
	_in_shell = true
	_shell_timer = SHELL_DURATION
	_current_def = SHELL_DEF
	can_attack = false

	# Squash visual: aplanar la tortuga como si se metiera al caparazón
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3(1.2, 0.6, 1.2), 0.15)


func _exit_shell() -> void:
	_in_shell = false
	_current_def = BASE_DEF
	can_attack = true

	# Restaurar escala
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.2)


# ─── Utils ───────────────────────────────────────────────────────────────────

func _pick_wander_dir() -> void:
	_wander_timer = randf_range(3.0, 6.0)
	var angle := randf_range(0.0, TAU)
	_wander_dir = Vector3(cos(angle), 0.0, sin(angle))
