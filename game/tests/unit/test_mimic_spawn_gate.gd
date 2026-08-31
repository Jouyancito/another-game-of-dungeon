extends GutTest

# The mimic spawn gate — canon docs/balance/_mimic.md §2.1-2.2.
#
# The mimic (state machine, reveal, loot) has been complete for months but NEVER
# SPAWNED: nothing in the game instantiated a chest at all, so the enemy that
# disguises itself as one could not exist. This gate is what put it in the world.
#
# The rules below are canon, not taste — each one protects something specific:
# the entrance chest teaches the player "chest = loot", and a mimic there would
# teach the opposite lesson on their first chest ever.

const Floor1 := preload("res://scenes/levels/floor1_prairie.gd")

const ALWAYS := 0.0    # a roll that beats any chance
const NEVER := 0.99    # a roll that loses to any chance


func test_entrance_chest_is_never_a_mimic() -> void:
	# §2.1 — the intro arena is where "chest = loot" is taught. Even with sub-B
	# enemies present and a winning roll, the entrance must stay honest.
	assert_false(
		Floor1.should_chest_be_mimic("entrance", true, false, ALWAYS),
		"the first chest the player ever opens must not bite them"
	)


func test_no_mimic_without_a_sub_b_enemy_guarding_the_poi() -> void:
	# §2.1 — a mimic hides among chests that sub-B+ enemies guard. An all-sub-A
	# POI is not a place it belongs, no matter how good the roll.
	assert_false(Floor1.should_chest_be_mimic("ruins", false, false, ALWAYS))


func test_only_one_mimic_per_scene() -> void:
	# §2.2 — max 1 alive per scene.
	assert_false(
		Floor1.should_chest_be_mimic("ruins", true, true, ALWAYS),
		"a second mimic must not spawn once one exists"
	)


func test_a_sub_b_poi_can_roll_a_mimic() -> void:
	assert_true(Floor1.should_chest_be_mimic("ruins", true, false, ALWAYS))


func test_a_losing_roll_leaves_a_normal_chest() -> void:
	# §2.2 — "no re-roll": losing simply means a normal chest spawns there.
	assert_false(Floor1.should_chest_be_mimic("ruins", true, false, NEVER))


func test_the_gate_is_the_canon_five_percent() -> void:
	# Pins the number itself: canon says 5% on Floor 1 sub-B+. A roll just under
	# passes, a roll just over does not.
	assert_true(Floor1.should_chest_be_mimic("ruins", true, false, 0.049))
	assert_false(Floor1.should_chest_be_mimic("ruins", true, false, 0.051))
