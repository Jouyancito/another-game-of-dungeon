extends GutTest

# Floor-clear loop: killing a boss must persist progress on the ACTIVE world.
# Before this existed, highest_floor_cleared / boss_trophies were dead fields —
# written once at world creation and never again, so a cleared floor was forgotten.
#
# WorldManager is an autoload backed by user://worlds.json. These tests create a
# throwaway world, drive mark_floor_cleared(), and delete it again, so they never
# depend on (or corrupt) whatever worlds the developer actually has saved.

var _world_index: int = -1
var _previous_world_index: int = -1


func before_each() -> void:
	_previous_world_index = GameManager.world_index
	_world_index = WorldManager.create_world("GUT floor-clear", 1234)
	GameManager.world_index = _world_index


func after_each() -> void:
	WorldManager.delete_world(_world_index)
	GameManager.world_index = _previous_world_index


func test_clearing_a_floor_records_progress_and_trophy() -> void:
	var first := WorldManager.mark_floor_cleared(1, &"trophy_king_slime")

	var world := WorldManager.get_world(_world_index)
	assert_true(first, "first clear of a floor must report is_first_clear")
	assert_eq(int(world["highest_floor_cleared"]), 1)
	assert_has(world["boss_trophies"], "trophy_king_slime")


func test_reclearing_the_same_floor_is_idempotent() -> void:
	WorldManager.mark_floor_cleared(1, &"trophy_king_slime")
	var second := WorldManager.mark_floor_cleared(1, &"trophy_king_slime")

	var world := WorldManager.get_world(_world_index)
	assert_false(second, "a replayed boss is not a first clear")
	assert_eq(int(world["highest_floor_cleared"]), 1)
	assert_eq((world["boss_trophies"] as Array).size(), 1, "trophy must not duplicate")


func test_clearing_a_lower_floor_never_lowers_progress() -> void:
	WorldManager.mark_floor_cleared(3, &"trophy_floor3_boss")
	WorldManager.mark_floor_cleared(1, &"trophy_king_slime")

	var world := WorldManager.get_world(_world_index)
	assert_eq(int(world["highest_floor_cleared"]), 3, "replaying floor 1 must not undo floor 3")
	assert_eq((world["boss_trophies"] as Array).size(), 2, "both trophies are kept")


func test_no_active_world_records_nothing() -> void:
	# A boss killed in a dev/test scene (no world selected) must not crash or
	# write into a random world — it simply records nothing.
	GameManager.world_index = -1
	assert_false(WorldManager.mark_floor_cleared(1, &"trophy_king_slime"))
