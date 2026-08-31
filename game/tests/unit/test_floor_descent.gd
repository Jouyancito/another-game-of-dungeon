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


func test_descent_from_floor_1_leads_to_floor_2() -> void:
	# Canon _alpha_5_maps.md: matar al King Slime abre el paso, y el paso BAJA al bosque.
	# El descenso no es el final — es la puerta. Antes esto cortaba a "continuará" porque el
	# Piso 2 no existía; ahora existe, y el descenso tiene que llevarte ahí.
	var hud := _FakeHud.new()
	hud.add_to_group("hud")
	add_child_autofree(hud)

	_descent.open(null)

	assert_eq(hud.descended_to, "res://scenes/levels/floor2_forest.tscn",
		"el descenso del Piso 1 lleva al bosque, no al menú")
	assert_eq(hud.ending_from_floor, -1, "no hay cliffhanger todavía: el bosque es lo que sigue")


func test_a_floor_with_nowhere_to_go_ends_the_demo() -> void:
	# El fallback canon: un piso sin destino construido corta con el cliffhanger en vez de
	# mandar al jugador a una escena que no existe. Hoy es el Piso 5 — el último de la torre.
	var last := FloorDescent.new()
	last.from_floor = 5
	add_child_autofree(last)

	var hud := _FakeHud.new()
	hud.add_to_group("hud")
	add_child_autofree(hud)

	last.open(null)

	assert_eq(hud.ending_from_floor, 5, "sin piso siguiente, la demo corta acá")
	assert_eq(hud.descended_to, "", "y no intenta cargar una escena inexistente")


# Doble mínimo: el HUD real llamaría change_scene_to_file() y voltearía la corrida de tests.
class _FakeHud extends Node:
	var ending_from_floor: int = -1
	var descended_to: String = ""

	func show_demo_ending(from_floor: int) -> void:
		ending_from_floor = from_floor

	func show_descent(next_scene: String) -> void:
		descended_to = next_scene
