extends GutTest

# El contrato de capas de colisión del jugador.
#
# Esto no es burocracia: un Area3D que escanea la layer equivocada NO FALLA, simplemente
# nunca dispara. Es invisible en compilación, invisible en el editor, y en juego se ve como
# "el boss no aparece" o "el ataque no hace nada". Fue exactamente lo que pasó.
#
# Bugs reales que este contrato cazó (2026-07-14):
#   - BossSpawnTrigger del Piso 1 escaneaba la layer 1 → el King Slime NUNCA spawneaba.
#     El boss que el canon llama "pelea OBLIGATORIA, el boss ES el paso" era inalcanzable
#     salvo por el spawner de debug.
#   - El aura de contacto, la baba bombardero y los charcos de ácido del King Slime también
#     escaneaban la layer 1 → ninguno podía tocar al jugador.
#
# El código llevaba un comentario afirmando "player está en layer 1 por default". Los .tscn
# decían lo contrario. Nadie lo verificó.

const PLAYER_LAYER: int = 2

const CLASS_SCENES: Array[String] = [
	"res://scenes/player/player.tscn",       # Guerrero
	"res://scenes/player/mage.tscn",
	"res://scenes/player/archer.tscn",
	"res://scenes/player/cleric.tscn",
	"res://scenes/player/necromancer.tscn",
	"res://scenes/player/danzante.tscn",
]


func test_every_class_is_on_the_player_layer() -> void:
	# Si una clase se sale de la layer 2, TODO lo que apunta al jugador deja de verla:
	# triggers de boss, AoE, charcos, pickups. Silenciosamente.
	for path: String in CLASS_SCENES:
		var packed: PackedScene = load(path)
		assert_not_null(packed, "no cargó %s" % path)

		var player: CharacterBody3D = packed.instantiate()
		autofree(player)
		assert_eq(player.collision_layer, PLAYER_LAYER,
			"%s debe estar en collision_layer %d o nada que apunte al jugador lo detecta"
				% [path.get_file(), PLAYER_LAYER])


func test_an_area_that_scans_the_player_layer_actually_detects_a_player() -> void:
	# El test que le faltaba al proyecto: probar la CONVENCIÓN, no el número.
	# Un Area3D con mask = PLAYER_LAYER tiene que ver a un player real.
	var player: CharacterBody3D = load("res://scenes/player/player.tscn").instantiate()
	add_child_autofree(player)
	player.global_position = Vector3.ZERO

	var area := Area3D.new()
	area.collision_mask = PLAYER_LAYER
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 4, 4)
	shape.shape = box
	area.add_child(shape)
	add_child_autofree(area)
	area.global_position = Vector3.ZERO

	# Dos frames: uno para entrar al árbol, otro para que la física resuelva overlaps.
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_true(area.get_overlapping_bodies().has(player),
		"un Area3D con mask=%d DEBE detectar al jugador — si esto falla, todo trigger de boss, AoE y charco del juego está ciego"
			% PLAYER_LAYER)


func test_an_area_scanning_the_world_layer_does_not_see_the_player() -> void:
	# El bug exacto, invertido: mask = 1 (World) NO ve al jugador. Esto es lo que hacían el
	# BossSpawnTrigger y los 4 ataques de área del King Slime.
	var player: CharacterBody3D = load("res://scenes/player/player.tscn").instantiate()
	add_child_autofree(player)
	player.global_position = Vector3.ZERO

	var area := Area3D.new()
	area.collision_mask = 1  # World
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 4, 4)
	shape.shape = box
	area.add_child(shape)
	add_child_autofree(area)
	area.global_position = Vector3.ZERO

	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_false(area.get_overlapping_bodies().has(player),
		"mask=1 es la layer World, NO la del jugador — apuntarle al jugador con 1 es el bug")
