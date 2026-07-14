extends GutTest

# El Guardián-Cuervo, "El Que Recuerda" — jefe del Piso 5.
#
# Canon lore/_mundo_entrevista.md §4.4: "memoria persistente por jugador (ya lo conoce en el
# segundo run → NO PELEA)".
#
# Esa memoria ES el personaje. Todo boss del juego te ataca; este te MIRA, y si ya te vio,
# se aparta. Si la memoria se pierde entre runs, el Cuervo no es nada — es un pájaro grande
# con mucha vida. Por eso estos tests, y por eso la memoria vive en el MUNDO
# (WorldManager.world_flags), no en el enemigo: matarlo, morir o salir al menú no la borra.

const CuervoScene := preload("res://scenes/enemy/guardian_cuervo.tscn")

var _world_index: int = -1
var _previous_index: int = -1


func before_each() -> void:
	_previous_index = GameManager.world_index
	_world_index = WorldManager.create_world("GUT cuervo", 99)
	GameManager.world_index = _world_index


func after_each() -> void:
	WorldManager.delete_world(_world_index)
	GameManager.world_index = _previous_index


func _spawn_cuervo() -> BaseEnemy:
	var cuervo: BaseEnemy = CuervoScene.instantiate()
	add_child_autofree(cuervo)
	# Apartado del origen: si otro test dejó un player en (0,0,0), el Cuervo lo ficha como
	# target y quedan superpuestos. Un boss encima del jugador no es un caso que probar.
	cuervo.global_position = Vector3(0, 0, -20)
	# BaseEnemy._ready() espera un frame antes de _on_enemy_ready(), que es donde el Cuervo
	# consulta la memoria del mundo.
	await get_tree().process_frame
	await get_tree().process_frame
	return cuervo


func test_the_first_time_he_fights() -> void:
	var cuervo: BaseEnemy = await _spawn_cuervo()
	assert_eq(cuervo.aggression, BaseEnemy.AggressionType.AGGRESSIVE,
		"la primera vez que te ve, pelea")


func test_meeting_him_marks_the_world() -> void:
	# Recuerda haberte VISTO — no haberte matado, ni que lo mates. Encontrarlo alcanza.
	await _spawn_cuervo()

	var world: Dictionary = WorldManager.get_world(_world_index)
	var flags: Dictionary = world.get("world_flags", {})
	assert_true(flags.get("cuervo_remembers", false),
		"encontrarlo debe marcar el mundo, aunque el jugador huya")


func test_the_second_time_he_steps_aside() -> void:
	# El momento entero del personaje: volvés, y simplemente te deja pasar.
	await _spawn_cuervo()   # primer encuentro — marca el mundo

	var second: BaseEnemy = await _spawn_cuervo()

	assert_eq(second.aggression, BaseEnemy.AggressionType.NEUTRAL,
		"ya te conoce: NO pelea")
	assert_false(second._should_pursue(1.0),
		"y no te persigue ni si le caminás encima")


func test_the_memory_belongs_to_the_world_not_the_run() -> void:
	# Si la memoria viviera en el enemigo o en la escena, recargar el piso la borraría y el
	# Cuervo volvería a atacarte — que es exactamente lo que el canon NO quiere.
	await _spawn_cuervo()

	# Otro mundo: nunca lo vio. La memoria es del mundo, no del jugador ni del juego.
	var other_index: int = WorldManager.create_world("GUT cuervo otro", 100)
	GameManager.world_index = other_index

	var stranger: BaseEnemy = await _spawn_cuervo()
	assert_eq(stranger.aggression, BaseEnemy.AggressionType.AGGRESSIVE,
		"en un mundo nuevo no te conoce — la memoria es del MUNDO")

	WorldManager.delete_world(other_index)
	GameManager.world_index = _world_index
