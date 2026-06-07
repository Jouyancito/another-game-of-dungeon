extends BaseEnemy

## Cabra Montesa — neutral, pasiva hasta que la atacan
## Stats: HP 60, DMG 4, DEF 2, XP 8, speed 3.0, mass 0.9
## Al recibir daño: una carga potente (3x speed + knockback) → flee 10s → calma

@export var has_charged := false

const CHARGE_SPEED_MULTIPLIER := 3.0
const FLEE_DURATION := 10.0
const CHARGE_DAMAGE_MULTIPLIER := 2.5
const CHARGE_KNOCKBACK := 18.0

var _is_charging := false
var _charge_elapsed := 0.0
const CHARGE_DURATION := 0.35

var _is_fleeing := false
var _flee_timer := 0.0

# Wander idle (pacer lento)
var spawn_position := Vector3.ZERO
var _wander_timer := 0.0
var _wander_dir := Vector3.ZERO


func _on_enemy_ready() -> void:
	enemy_type = "goat"
	# Personalidad: esquivo/miedoso. Huye si el jugador se acerca a < 6m.
	# Si acorralado (sin escape), lanza su carga única via perform_attack().
	# Los estados internos _is_charging/_is_fleeing siguen activos en perform_attack.
	personality = AggroPersonality.SKITTISH
	aggression = AggressionType.NEUTRAL
	default_color = Color(0.8, 0.8, 0.75)
	mass = 0.9
	spawn_position = global_position
	_pick_wander_dir()
	mesh.visible = false
	var model := EnemyModelBuilder.build_quadruped(
		default_color,
		0.5,    # body_length
		0.25,   # body_height
		0.25,   # body_width
		0.25,   # leg_height
		0.04,   # leg_radius
		false,  # no tail
		0.0
	)
	model.name = "Model"
	add_child(model)
	# Add horns (two small cylinders on the head)
	var horn_mat := MannequinBuilder.create_material(Color(0.6, 0.55, 0.4))
	var head_node := model.get_node("Head")
	if head_node:
		for side in [-1, 1]:
			var horn := MannequinBuilder.create_cylinder(0.02, 0.12, horn_mat)
			horn.name = "Horn_%s" % ("R" if side > 0 else "L")
			horn.rotation_degrees = Vector3(0, 0, side * 25.0)
			horn.position = Vector3(side * 0.05, 0.08, 0.0)
			head_node.add_child(horn)


# ─── Idle: deambula lentamente (pasta) ──────────────────────────────────────

func _idle_behavior(delta: float) -> void:
	if _is_fleeing:
		_flee_step(delta)
		return

	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_wander_dir()

	var dist_from_spawn := global_position.distance_to(spawn_position)
	if dist_from_spawn > 6.0:
		_wander_dir = (spawn_position - global_position).normalized()
		_wander_dir.y = 0.0

	velocity.x = _wander_dir.x * speed * 0.3
	velocity.z = _wander_dir.z * speed * 0.3


# ─── Persecución / carga ────────────────────────────────────────────────────

func _move_toward_target(delta: float) -> void:
	if _is_fleeing:
		_flee_step(delta)
		return

	if _is_charging:
		_charge_elapsed += delta
		if _charge_elapsed >= CHARGE_DURATION:
			_end_charge()
		# La velocidad de la carga ya fue aplicada en _start_charge — solo mantener
		return

	# Si ya cargó, no persigue más — huye
	if has_charged:
		_start_flee()
		return

	# Movimiento normal hacia el jugador antes de cargar
	# (la carga se lanza desde perform_attack cuando está en rango)
	var direction := (target.global_position - global_position).normalized()
	direction.y = 0.0
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


## Override de perform_attack: lanza la carga en lugar de daño simple
func perform_attack() -> void:
	if has_status(&"stun"):
		return  # stun pausa ataque (canon _status_effects.md §2.2)
	if has_charged or _is_charging:
		return
	can_attack = false
	_start_charge()


func _start_charge() -> void:
	if not is_instance_valid(target):
		return
	_is_charging = true
	_charge_elapsed = 0.0

	var direction := (target.global_position - global_position).normalized()
	direction.y = 0.0
	velocity.x = direction.x * speed * CHARGE_SPEED_MULTIPLIER
	velocity.z = direction.z * speed * CHARGE_SPEED_MULTIPLIER

	# Daño + knockback al momento del impacto (respeta Weak debuff)
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage * CHARGE_DAMAGE_MULTIPLIER * outgoing_damage_mult())
		# Knockback si el target lo soporta
		if target.has_method("apply_knockback"):
			var hit_dir := (target.global_position - global_position).normalized()
			target.apply_knockback(hit_dir, CHARGE_KNOCKBACK)


func _end_charge() -> void:
	_is_charging = false
	has_charged = true
	_start_flee()


# ─── Huida ──────────────────────────────────────────────────────────────────

func _start_flee() -> void:
	_is_fleeing = true
	_flee_timer = FLEE_DURATION
	is_provoked = false


func _flee_step(delta: float) -> void:
	_flee_timer -= delta
	if _flee_timer <= 0.0:
		_calm_down()
		return

	if not is_instance_valid(target):
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var away := (global_position - target.global_position).normalized()
	away.y = 0.0
	velocity.x = away.x * speed * 1.8
	velocity.z = away.z * speed * 1.8


func _calm_down() -> void:
	_is_fleeing = false
	has_charged = false
	can_attack = true
	spawn_position = global_position
	_pick_wander_dir()


# ─── Utils ───────────────────────────────────────────────────────────────────

func _pick_wander_dir() -> void:
	_wander_timer = randf_range(2.5, 5.0)
	var angle := randf_range(0.0, TAU)
	_wander_dir = Vector3(cos(angle), 0.0, sin(angle))
