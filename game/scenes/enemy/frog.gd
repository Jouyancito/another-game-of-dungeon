extends BaseEnemy

## Rana de estanque — canon `_floor1_integral_plan.md` TIER 2 §5.
##
## Fills the water_edge niche: it belongs to the pond the way the snake belongs to the
## damp hollows. NEUTRAL like the goat — it sits at the water and only fights if you
## start it. Killing frogs is a choice the player makes, not one the frog makes.
##
## Reuses the slime's hop locomotion (canon says so explicitly) and answers at range
## with a tongue lash, so it threatens the shoreline without chasing you across the map.

## Reach of the tongue. Longer than attack_range would suggest for a small animal —
## that reach IS the frog's whole threat.
const TONGUE_RANGE: float = 3.0

@export var hop_force: float = 3.5
@export var hop_interval: float = 1.2

var _hop_timer: float = 0.0
var _is_hopping: bool = false


func _on_enemy_ready() -> void:
	enemy_type = "frog"
	display_name = "Rana"
	sub_tier = SubTier.A
	aggression = AggressionType.NEUTRAL
	habitat_type = "water_edge"

	health = 80.0
	damage = 8.0
	speed = 2.4
	mass = 0.6
	knockback_resistance = 0.3
	attack_range = TONGUE_RANGE
	detection_range = 8.0
	attack_cooldown = 2.0
	xp_reward = 12.0

	default_color = Color(0.30, 0.55, 0.25)
	_hop_timer = hop_interval


## Hop locomotion, per canon "patrón hop de slime reutilizable".
func _move_toward_target(delta: float) -> void:
	_hop_timer -= delta

	if _hop_timer <= 0.0 and is_on_floor():
		_hop_timer = hop_interval
		_is_hopping = true
		if _anim != null:
			_anim.play_jump()

		var direction: Vector3 = (target.global_position - global_position).normalized()
		direction.y = 0.0
		velocity.x = direction.x * speed * 1.5
		velocity.z = direction.z * speed * 1.5
		velocity.y = hop_force

	# Grounded between hops: bleed off speed so it settles instead of skating.
	if is_on_floor() and not _is_hopping:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 5.0)
	elif not is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 1.5)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 1.5)

	if _is_hopping and is_on_floor() and velocity.y <= 0.0:
		_is_hopping = false


## Sits still at the water's edge. It is not hunting anyone.
func _idle_behavior(_delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0


## Tongue lash — reaches TONGUE_RANGE, so the frog can answer without closing distance.
func perform_attack() -> void:
	if has_status(&"stun"):
		return  # canon _status_effects.md §2.2
	can_attack = false

	if is_instance_valid(target):
		target.take_damage(damage * outgoing_damage_mult())

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true
