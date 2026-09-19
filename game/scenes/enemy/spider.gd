extends BaseEnemy

## Araña — sub-tier A, cave/ambush niche.
##
## The loot table for "spider" has existed since the economy pass but no spider ever did.
## It belongs where the light does not reach: the cave crack, under the ruins. An ambush
## predator like the snake — it does not roam, it WAITS, and the player walks into it.
##
## Reuses the arthropod body the scorpion already uses and the poison DoT pattern from
## snake/scorpion. Nothing new invented: what makes a spider a spider here is the niche
## and the stillness, not a bespoke system.

const POISON_TICKS: int = 3
const POISON_TICK_DAMAGE: float = 2.0
const POISON_TICK_INTERVAL: float = 1.0


func _on_enemy_ready() -> void:
	enemy_type = "spider"
	display_name = "Araña"
	sub_tier = SubTier.A
	aggression = AggressionType.AGGRESSIVE
	habitat_type = "cave"

	health = 55.0
	damage = 7.0
	speed = 4.2          # fast in a burst — the scuttle is the scare
	mass = 0.5
	knockback_resistance = 0.0
	attack_range = 1.6
	detection_range = 7.0   # short: it does not see you coming, you arrive
	attack_cooldown = 1.4
	xp_reward = 10.0

	default_color = Color(0.18, 0.16, 0.20)
	mesh.visible = false

	var model := EnemyModelBuilder.build_arthropod(
		default_color,
		0.42,   # body_length
		0.34,   # body_width
		0.22,   # body_height
		8,      # leg_count — eight, because it is a spider
		false,  # has_tail
		false   # has_pincers
	)
	model.name = "Model"
	add_child(model)


## Ambush predator: it does not patrol. It sits until something comes close enough.
func _idle_behavior(_delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0


## Venomous bite — the bite is small, the poison is the point.
func perform_attack() -> void:
	if has_status(&"stun"):
		return  # canon _status_effects.md §2.2
	can_attack = false

	if is_instance_valid(target):
		target.take_damage(damage * outgoing_damage_mult())
		_apply_poison_dot(target)

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true


func _apply_poison_dot(dot_target: Node3D) -> void:
	for _i in range(POISON_TICKS):
		await get_tree().create_timer(POISON_TICK_INTERVAL).timeout
		if not is_instance_valid(self) or not is_instance_valid(dot_target):
			return
		if is_dead:
			return
		dot_target.take_damage(POISON_TICK_DAMAGE, "poison")
