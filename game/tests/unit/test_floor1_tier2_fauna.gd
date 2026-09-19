extends GutTest

# Floor 1 TIER-2 fauna — canon _floor1_integral_plan.md §5-§7.
#
# These three close the prairie's ecological roster: the pond had no resident, the open
# field had no territorial predator, and the wasps could be picked off one at a time from
# range without the hive ever reacting.
#
# The stat lines below are canon numbers, not taste. A test that just re-asserts whatever
# the script happens to say would be worthless — these are pinned against the doc.

const FrogScene := preload("res://scenes/enemy/frog.tscn")
const JabaliScene := preload("res://scenes/enemy/jabali.tscn")
const WaspScene := preload("res://scenes/enemy/wasp.tscn")


## BaseEnemy._ready() awaits a process frame before it calls _on_enemy_ready(), which is
## where every enemy applies its own stats. Assert before that frame and you are reading
## the .tscn defaults, not the enemy.
func _spawn(scene: PackedScene) -> BaseEnemy:
	var enemy: BaseEnemy = scene.instantiate()
	add_child_autofree(enemy)
	await get_tree().process_frame
	await get_tree().process_frame
	return enemy


func test_frog_matches_canon_stats() -> void:
	# Canon §5: HP 80, dmg 8, mass 0.6, knockback_resistance 0.3, SubTier A, NEUTRAL.
	var frog: BaseEnemy = await _spawn(FrogScene)
	assert_eq(frog.health, 80.0)
	assert_eq(frog.damage, 8.0)
	assert_eq(frog.mass, 0.6)
	assert_eq(frog.knockback_resistance, 0.3)
	assert_eq(frog.sub_tier, BaseEnemy.SubTier.A)
	assert_eq(frog.aggression, BaseEnemy.AggressionType.NEUTRAL, "the frog only fights if provoked")
	assert_eq(frog.habitat_type, "water_edge", "the frog belongs to the pond")


func test_jabali_matches_canon_stats() -> void:
	# Canon §6: HP 120, dmg 12, mass 2.5, knockback_resistance 0.8, SubTier B, AGGRESSIVE.
	var boar: BaseEnemy = await _spawn(JabaliScene)
	assert_eq(boar.health, 120.0)
	assert_eq(boar.damage, 12.0)
	assert_eq(boar.mass, 2.5)
	assert_eq(boar.knockback_resistance, 0.8)
	assert_eq(boar.sub_tier, BaseEnemy.SubTier.B)
	assert_eq(boar.aggression, BaseEnemy.AggressionType.AGGRESSIVE)
	assert_eq(boar.habitat_type, "open_field")


func test_jabali_is_territorial_and_will_not_chase_forever() -> void:
	# Canon §6: "NO persigue infinito (territorial)". The refusal to pursue is what makes
	# it read as an animal defending a patch rather than a monster hunting the player.
	var boar: BaseEnemy = await _spawn(JabaliScene)
	assert_eq(boar.personality, BaseEnemy.AggroPersonality.TERRITORIAL)
	assert_gt(boar.territorial_radius, 0.0, "a territorial enemy with no territory leashes nowhere")


func test_wasp_is_aerial() -> void:
	# Canon §7: habitat_type = "aerial".
	var wasp: BaseEnemy = await _spawn(WaspScene)
	assert_eq(wasp.habitat_type, "aerial")


func test_stinging_one_wasp_alerts_the_neighbours() -> void:
	# Canon §7: "provocar una avispa alerta a las demás cercanas (radio 8m)".
	# Before this, aggro came ONLY from nest proximity — an archer at 15m could delete
	# the colony one wasp at a time and the hive would never notice.
	var struck: BaseEnemy = await _spawn(WaspScene)
	var neighbour: BaseEnemy = await _spawn(WaspScene)
	var distant: BaseEnemy = await _spawn(WaspScene)

	struck.global_position = Vector3.ZERO
	neighbour.global_position = Vector3(5.0, 0.0, 0.0)    # inside SWARM_ALERT_RANGE (8m)
	distant.global_position = Vector3(20.0, 0.0, 0.0)     # well outside it

	assert_false(neighbour.is_provoked, "precondition: the hive starts calm")

	struck.take_damage(1.0)

	assert_true(neighbour.is_provoked, "a wasp within 8m must answer the sting")
	assert_false(distant.is_provoked, "a wasp 20m away is not part of that swarm")
