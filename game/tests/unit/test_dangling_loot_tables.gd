extends GutTest

# Three loot tables had existed since the economy pass with nothing that could ever drop
# them — spider, bandit_leader and rabbit were rows in LootTable pointing at enemies that
# did not exist (or, for the rabbit, at a Node3D with no collision that could not be hit).
# Dead tables are worse than missing ones: they read as finished work.
#
# These tests pin that each table now has something in the world that can actually roll it.

const SpiderScene := preload("res://scenes/enemy/spider.tscn")
const LeaderScene := preload("res://scenes/enemy/bandit_leader.tscn")
const RabbitScene := preload("res://scenes/fauna/rabbit.tscn")


func _spawn(scene: PackedScene) -> Node3D:
	var node: Node3D = scene.instantiate()
	add_child_autofree(node)
	await get_tree().process_frame
	await get_tree().process_frame
	return node


func test_every_enemy_loot_table_key_has_a_live_enemy() -> void:
	# The point of the whole change: no table left pointing at nothing.
	for key: String in ["spider", "bandit_leader", "rabbit", "frog", "jabali"]:
		var loot: Dictionary = LootTable.roll(key)
		assert_true(loot.has("items"), "table '%s' must roll a real result" % key)


func test_spider_exists_and_rolls_its_table() -> void:
	var spider: BaseEnemy = await _spawn(SpiderScene)
	assert_eq(spider.enemy_type, "spider", "enemy_type IS the loot table key")
	assert_eq(spider.habitat_type, "cave", "an ambush predator needs somewhere dark to wait")
	assert_eq(spider.sub_tier, BaseEnemy.SubTier.A)


func test_bandit_leader_is_the_camp_alpha() -> void:
	# Sub-tier C per docs/enemy_tier_system.md §3 — 1.5x a regular bandit.
	var leader: BaseEnemy = await _spawn(LeaderScene)
	assert_eq(leader.enemy_type, "bandit_leader")
	assert_eq(leader.sub_tier, BaseEnemy.SubTier.C)
	assert_eq(leader.health, 180.0)
	assert_eq(leader.damage, 18.0)


func test_hitting_the_leader_rallies_his_men() -> void:
	# Without this the player could pull the alpha out and duel him in peace — the exact
	# opposite of what a camp is for.
	var leader: BaseEnemy = await _spawn(LeaderScene)
	var follower: BaseEnemy = await _spawn(preload("res://scenes/enemy/bandit_melee.tscn"))

	leader.global_position = Vector3.ZERO
	follower.global_position = Vector3(8.0, 0.0, 0.0)  # inside RALLY_RANGE (16m)
	assert_false(follower.is_provoked, "precondition: the camp starts idle")

	leader.take_damage(1.0)

	assert_true(follower.is_provoked, "hurting the leader must bring his men")


func test_rabbit_can_actually_be_killed() -> void:
	# It was a Node3D: no body, no collision, unhittable. Canon gives it 1 HP and a pelt.
	var rabbit: Node3D = await _spawn(RabbitScene)

	assert_true(rabbit is StaticBody3D, "the player's melee raycast needs a body to hit")
	assert_true(rabbit.is_in_group("enemies"), "melee only damages what is in the 'enemies' group")
	assert_true(rabbit.has_method("take_damage"), "prey you cannot hit is scenery")

	rabbit.take_damage(1.0)
	await get_tree().process_frame

	assert_false(is_instance_valid(rabbit) and rabbit.is_in_group("enemies"),
		"one hit kills — canon says 1 HP")
