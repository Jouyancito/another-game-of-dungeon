extends GutTest

# The descent is what ENDS a run. Before it existed, killing the boss left the player
# wandering a cleared map with nothing to do and no way to finish.
#
# Canon (lore/_alpha_5_maps.md, "P2 — Alcance del Demo"): the forest antechamber is
# the first thing to cut, and the doc names this exact fallback — "solo el descenso
# como cliffhanger". These tests pin the contract the level and player rely on.

var _descent: FloorDescent


func before_each() -> void:
	_descent = FloorDescent.new()
	_descent.from_floor = 1
	add_child_autofree(_descent)


func test_descent_is_interactable_by_the_player_contract() -> void:
	# BasePlayer._try_interact_nearby() finds interactables by group and calls open().
	# Break either half and the descent becomes scenery the player cannot use.
	assert_true(_descent.is_in_group("interactables"), "player only sees the 'interactables' group")
	assert_true(_descent.has_method("open"), "player calls open(player) on interact")


func test_taking_the_descent_consumes_it() -> void:
	# Guards a double-fire: open() runs a scene transition, and a second interact
	# mid-outro would stack a second transition on top of it.
	_descent.open(null)
	assert_false(_descent.is_in_group("interactables"), "a used descent must stop offering itself")


func test_descent_shows_the_cliffhanger_on_the_hud() -> void:
	var hud := _FakeHud.new()
	hud.add_to_group("hud")
	add_child_autofree(hud)

	_descent.open(null)

	assert_eq(hud.ending_from_floor, 1, "the HUD is told which floor the player left")


# Minimal stand-in: the real HUD would change_scene_to_file() and tear down the test run.
class _FakeHud extends Node:
	var ending_from_floor: int = -1

	func show_demo_ending(from_floor: int) -> void:
		ending_from_floor = from_floor
