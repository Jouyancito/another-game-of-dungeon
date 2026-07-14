extends GutTest

# La torre, de punta a punta.
#
# Cada piso lleva al siguiente y el último corta con el cliffhanger. Es la clase de cosa que
# nadie testea y que se rompe callada: alcanza con que un piso apunte a una escena que no
# existe para que el jugador llegue al fondo de un mapa y quede encerrado ahí, sin error,
# sin crash, sin nada. Un callejón sin salida no falla — simplemente no pasa nada.

const FLOORS: Dictionary = {
	1: "res://scenes/levels/floor1_prairie.tscn",
	2: "res://scenes/levels/floor2_forest.tscn",
	3: "res://scenes/levels/floor3_jotunheim.tscn",
	4: "res://scenes/levels/floor4_alsamum.tscn",
	5: "res://scenes/levels/floor5_umbral.tscn",
}

const LAST_FLOOR: int = 5


func test_every_floor_scene_exists_and_loads() -> void:
	# Un piso que no carga es un piso al que nunca vas a llegar.
	for number: int in FLOORS:
		var path: String = FLOORS[number]
		assert_true(ResourceLoader.exists(path), "el Piso %d no existe en '%s'" % [number, path])
		assert_not_null(load(path), "el Piso %d no carga" % number)


func test_the_descent_chain_reaches_the_top_floor() -> void:
	# Bajar desde el 1 tiene que poder llegar hasta el 5, un piso por vez. Si algún eslabón
	# falta, la torre se corta ahí y todo lo de abajo es contenido muerto.
	for from_floor: int in range(1, LAST_FLOOR):
		var next_scene: String = FloorDescent.FLOOR_SCENES.get(from_floor + 1, "")
		assert_eq(next_scene, FLOORS[from_floor + 1],
			"el descenso del Piso %d debe llevar al Piso %d" % [from_floor, from_floor + 1])
		assert_true(ResourceLoader.exists(next_scene),
			"el Piso %d apunta a una escena que no existe" % from_floor)


func test_the_last_floor_ends_the_demo_instead_of_falling_into_nothing() -> void:
	# El 5 es el último construido. Sin destino, corta con el cliffhanger — NO manda al
	# jugador a un floor6 inexistente.
	assert_false(FloorDescent.FLOOR_SCENES.has(LAST_FLOOR + 1),
		"el Piso %d no está construido: el %d tiene que cortar, no cargarlo"
			% [LAST_FLOOR + 1, LAST_FLOOR])

	var descent := FloorDescent.new()
	descent.from_floor = LAST_FLOOR
	add_child_autofree(descent)

	var hud := _FakeHud.new()
	hud.add_to_group("hud")
	add_child_autofree(hud)

	descent.open(null)

	assert_eq(hud.ending_from_floor, LAST_FLOOR, "el último piso cierra la demo")
	assert_eq(hud.descended_to, "", "y no intenta cargar un piso que no existe")


class _FakeHud extends Node:
	var ending_from_floor: int = -1
	var descended_to: String = ""

	func show_demo_ending(from_floor: int) -> void:
		ending_from_floor = from_floor

	func show_descent(next_scene: String) -> void:
		descended_to = next_scene
