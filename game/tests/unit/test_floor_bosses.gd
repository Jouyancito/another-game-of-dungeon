extends GutTest

# Los jefes de piso, y sus mecánicas.
#
# Canon `enemy_tier_system.md`: "el boss de cada piso es un GATE: sus stats base igualan al
# tier siguiente sub-A, pero su dificultad viene de MECÁNICAS, combos y fases".
#
# Esa frase es la spec. Un boss cuya única idea es tener mucha vida no es un gate, es una
# pared — y estos tests prueban la MECÁNICA de cada uno, no su barra de HP. Si un día alguien
# "simplifica" el Vigilante a un enemigo normal con más vida, esto falla.

const Watcher := preload("res://scenes/enemy/forest_watcher.tscn")
const Jotun := preload("res://scenes/enemy/jotun_giant.tscn")
const Samum := preload("res://scenes/enemy/samum.tscn")
const KingSlime := preload("res://scenes/enemy/king_slime.tscn")
const Cuervo := preload("res://scenes/enemy/guardian_cuervo.tscn")


func _spawn(scene: PackedScene) -> BaseEnemy:
	var boss: BaseEnemy = scene.instantiate()
	add_child_autofree(boss)
	boss.global_position = Vector3(0, 0, -30)  # lejos de cualquier player que otro test dejó
	await get_tree().process_frame
	await get_tree().process_frame
	return boss


func test_every_floor_has_a_boss_and_each_is_stronger_than_the_last() -> void:
	# Canon: "salto claro entre tiers — sin overlap. Si superaste el tier 1, el tier 2 se
	# SIENTE mas fuerte". Un boss de piso 4 con menos vida que el del piso 1 rompe la torre.
	var bosses: Array = [
		await _spawn(KingSlime),
		await _spawn(Watcher),
		await _spawn(Jotun),
		await _spawn(Samum),
		await _spawn(Cuervo),
	]

	for i in range(bosses.size()):
		var boss: BaseEnemy = bosses[i]
		assert_eq(boss.sub_tier, BaseEnemy.SubTier.BOSS, "%s debe ser sub_tier BOSS" % boss.enemy_type)
		assert_eq(boss.enemy_tier, i + 1, "%s pertenece al piso %d" % [boss.enemy_type, i + 1])
		if i > 0:
			var prev: BaseEnemy = bosses[i - 1]
			assert_gt(boss.health, prev.health,
				"el boss del piso %d tiene que ser MÁS duro que el del %d" % [i + 1, i])


func test_the_watcher_cannot_be_hit_while_it_stalks() -> void:
	# LA mecánica del Vigilante: es invisible e inmune mientras acecha. El jugador no aprende
	# a esquivarlo — aprende a ESPERARLO. Si se le puede pegar en la sombra, no hay pelea.
	var watcher: BaseEnemy = await _spawn(Watcher)
	var full: float = watcher.health

	watcher.take_damage(500.0)

	assert_eq(watcher.health, full, "acechando es INMUNE — pegarle al aire no lastima a nadie")


func test_the_watcher_is_vulnerable_once_it_strikes() -> void:
	var watcher: BaseEnemy = await _spawn(Watcher)
	var full: float = watcher.health

	watcher._strike()          # aparece a golpear: esa es toda la ventana del jugador
	watcher.take_damage(500.0)

	assert_lt(watcher.health, full, "expuesto SÍ recibe daño — si no, la pelea es infinita")


func test_the_jotun_shrugs_off_weak_hits_and_breaks_on_heavy_ones() -> void:
	# LA mecánica del Jötun: pegarle rápido y flojo no sirve. Hay que PEGAR FUERTE.
	var jotun: BaseEnemy = await _spawn(Jotun)

	var armor_before: float = jotun._armor
	jotun.take_damage(10.0)    # rasguño: por debajo del umbral
	assert_eq(jotun._armor, armor_before, "un golpe flojo no agrieta el hielo")

	jotun.take_damage(80.0)    # golpe pesado
	assert_lt(jotun._armor, armor_before, "un golpe pesado SÍ agrieta")


func test_the_jotun_is_glass_once_the_ice_breaks() -> void:
	var jotun: BaseEnemy = await _spawn(Jotun)
	jotun._shatter()

	var before: float = jotun.health
	jotun.take_damage(100.0)

	# Sin coraza recibe el DOBLE: la ventana es la pelea entera, y hay que ganársela.
	assert_almost_eq(before - jotun.health, 200.0, 1.0,
		"expuesto recibe daño doble — esa ventana ES la recompensa por romper el hielo")


func test_the_samum_cannot_be_hit_while_it_is_wind() -> void:
	# LA mecánica del Samum: no tiene cuerpo. La tormenta no tiene dónde recibir un golpe.
	var samum: BaseEnemy = await _spawn(Samum)
	var full: float = samum.health

	samum.take_damage(500.0)

	assert_eq(samum.health, full, "disperso es VIENTO: intocable")


func test_the_samum_can_be_hit_once_it_condenses() -> void:
	var samum: BaseEnemy = await _spawn(Samum)
	var full: float = samum.health

	samum._condense()
	samum.take_damage(300.0)

	assert_lt(samum.health, full, "condensado SÍ se puede matar — esa es tu única ventana")
