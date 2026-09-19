extends BanditMelee

## Jefe de bandidos — sub-tier C (alfa del campamento).
##
## The "bandit_leader" loot table has existed since the economy pass — with real GEAR in
## it (sword, reinforced vest, belt) — but no leader ever dropped it. A bandit camp whose
## bandits answer to nobody is a spawn point, not a camp.
##
## Extends BanditMelee rather than reimplementing it: the 3-move cycle (slash / shield-bash
## / telegraphed heavy), the 30% block and the strafe already work and are exactly what a
## leader should fight like. What makes him the LEADER is command, not new footwork:
##   - hurt him and he rallies the camp (the wasp/wolf alert pattern)
##   - kill him and the camp breaks (the wolf alpha-death pattern)
##
## Sub-tier C scaling per docs/enemy_tier_system.md §3: C is 2.4x base vs B's 1.6x, so
## 1.5x over a regular bandit, and XP 3.5x/2.0x = 1.75x.

## Radius in which the leader's shout reaches his men.
const RALLY_RANGE: float = 16.0

## Bandit enemy_types that answer to him.
const FOLLOWER_TYPES: Array[String] = ["bandit", "bandit_archer"]

var _rallied := false


func _on_enemy_ready() -> void:
	super._on_enemy_ready()

	enemy_type = "bandit_leader"
	display_name = "Jefe Bandido"
	sub_tier = SubTier.C
	habitat_type = "open_field"

	# Sub-tier C — canon enemy_tier_system.md §3.
	health = 180.0
	damage = 18.0
	xp_reward = 60.0
	mass = 1.6
	knockback_resistance = 0.5
	block_chance = 0.4   # he is simply better at this than his men

	default_color = Color(0.42, 0.20, 0.16)
	scale = Vector3(1.15, 1.15, 1.15)  # reads as the biggest man in the camp


## Hitting the leader brings the camp down on you. Without this, the player could pull him
## alone and duel the alpha in peace — which is the opposite of what a camp should be.
func take_damage(
	amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0,
	attacker_str := 0, attacker: Node = null, element: String = "physical",
	is_crit: bool = false
) -> void:
	var was_alive := not is_dead
	super.take_damage(amount, hit_direction, knockback_force, attacker_str, attacker, element, is_crit)
	if was_alive and not _rallied:
		_rallied = true
		_rally_camp(attacker)


## Wakes every bandit in RALLY_RANGE and points them at the attacker.
func _rally_camp(attacker: Node) -> void:
	for follower: BaseEnemy in _nearby_followers():
		follower.is_provoked = true
		if attacker != null and is_instance_valid(attacker):
			follower.target = attacker


## The camp breaks with him — canon wolf pattern: the alpha dies, the pack scatters.
## Morale is the whole reason a bandit camp holds together; take the man and it goes.
func _on_death() -> void:
	for follower: BaseEnemy in _nearby_followers():
		# Same lever the wolf uses to rout its pack. Guarded: a follower without the flag
		# simply keeps fighting rather than erroring.
		if "alpha_dead" in follower:
			follower.set("alpha_dead", true)
		else:
			follower.is_provoked = false
			follower.target = null


## Living bandits within RALLY_RANGE. Matches on enemy_type, not class_name: base_enemy.gd
## deliberately avoids class_name on enemies to dodge load-order issues.
func _nearby_followers() -> Array[BaseEnemy]:
	var found: Array[BaseEnemy] = []
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not (node is BaseEnemy):
			continue
		var other := node as BaseEnemy
		if other.is_dead or not FOLLOWER_TYPES.has(other.enemy_type):
			continue
		if global_position.distance_to(other.global_position) <= RALLY_RANGE:
			found.append(other)
	return found
