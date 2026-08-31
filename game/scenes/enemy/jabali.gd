extends BaseEnemy

## Jabalí de campo — canon `_floor1_integral_plan.md` TIER 2 §6.
##
## The open_field predator. Aggressive but TERRITORIAL: it owns a patch of prairie and
## defends it, and it will NOT chase you across the map. Walk away and you live — that
## refusal to pursue is what makes it read as an animal rather than a monster.
##
## Reuses BaseEnemy's TERRITORIAL personality (the same leash the scorpion runs on)
## instead of hand-rolling patrol/leash logic here.

const CHARGE_SPEED_MULT: float = 3.2
const CHARGE_DURATION: float = 0.9
const CHARGE_KNOCKBACK: float = 14.0
## Canon _floor1_integral_plan.md §6: "Su carga aplica `stun` 0.5s al impactar".
const CHARGE_STUN_S: float = 0.5

var _is_charging: bool = false
var _charge_elapsed: float = 0.0
var _charge_direction: Vector3 = Vector3.ZERO


func _on_enemy_ready() -> void:
	enemy_type = "jabali"
	display_name = "Jabalí"
	sub_tier = SubTier.B
	aggression = AggressionType.AGGRESSIVE
	habitat_type = "open_field"

	# Territorial: aggro inside its patch, leash home instead of an endless hunt.
	personality = AggroPersonality.TERRITORIAL
	territorial_radius = 14.0

	health = 120.0
	damage = 12.0
	speed = 3.2
	mass = 2.5
	knockback_resistance = 0.8
	attack_range = 2.2
	detection_range = 13.0
	attack_cooldown = 2.5
	xp_reward = 35.0

	default_color = Color(0.32, 0.24, 0.20)
	mesh.visible = false

	var model := EnemyModelBuilder.build_quadruped(
		default_color,
		1.15,   # body_length — long and low, weight carried forward
		0.62,   # body_height
		0.70,   # body_width
		0.34,   # leg_height — short legs under a heavy body
		0.09,   # leg_radius
		true,   # has_tail
		0.18    # tail_length
	)
	model.name = "Model"
	add_child(model)


func _physics_process(delta: float) -> void:
	if _is_charging:
		_charge_elapsed += delta
		if _charge_elapsed >= CHARGE_DURATION:
			_is_charging = false
		else:
			# Committed: it cannot steer mid-charge. That commitment is the counterplay —
			# the player sidesteps and the boar rumbles past.
			velocity.x = _charge_direction.x * speed * CHARGE_SPEED_MULT
			velocity.z = _charge_direction.z * speed * CHARGE_SPEED_MULT
			_apply_gravity(delta)
			move_and_slide()
			return
	super._physics_process(delta)


## Frontal charge with heavy knockback (canon: "carga frontal con knockback alto").
func perform_attack() -> void:
	if has_status(&"stun"):
		return  # canon _status_effects.md §2.2
	can_attack = false

	if is_instance_valid(target):
		_charge_direction = (target.global_position - global_position).normalized()
		_charge_direction.y = 0.0
		_is_charging = true
		_charge_elapsed = 0.0

		target.take_damage(damage * outgoing_damage_mult())
		if target.has_method("apply_knockback"):
			target.apply_knockback(_charge_direction, CHARGE_KNOCKBACK)
		# Canon _floor1_integral_plan.md §6: the charge stuns for 0.5s on impact. The
		# knockback throws you; the stun is the half-second where you cannot answer.
		if target.has_method("apply_status"):
			target.apply_status(&"stun", CHARGE_STUN_S, self)

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true
