extends GutTest

# Tests para las 5 clases — verificar stats iniciales y configuración
# Cada clase llama _on_class_ready() en _ready(), pero como no podemos
# añadir al SceneTree sin escena completa, llamamos _on_class_ready() manualmente.

# ─── Helpers ───

func _create_player(script_path: String) -> BasePlayer:
	var scene_path = script_path.replace(".gd", ".tscn")
	var scene = load(scene_path)
	var instance = scene.instantiate()
	return instance


func _free_player(p: BasePlayer) -> void:
	if is_instance_valid(p):
		p.queue_free()


# ═══════════════════════════════════════════
# WARRIOR
# ═══════════════════════════════════════════

func test_warrior_stats() -> void:
	var p = _create_player("res://scenes/player/player.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.str_stat, 12, "Warrior STR")
	assert_eq(p.int_stat, 3, "Warrior INT")
	assert_eq(p.dex_stat, 6, "Warrior DEX")
	assert_eq(p.def_stat, 10, "Warrior DEF")
	assert_eq(p.vit_stat, 10, "Warrior VIT")


func test_warrior_health_mana() -> void:
	var p = _create_player("res://scenes/player/player.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	# HP = 100 + (10 * 5) = 150
	assert_eq(p.max_health, 150.0, "Warrior max HP")
	assert_eq(p.health, 150.0, "Warrior starts at full HP")
	# MP = 80 + (3 * 3) = 89
	assert_eq(p.max_mana, 89.0, "Warrior max MP")
	assert_eq(p.mana, 89.0, "Warrior starts at full MP")


func test_warrior_speed() -> void:
	var p = _create_player("res://scenes/player/player.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.speed, 5.0, "Warrior speed")
	assert_eq(p.sprint_speed, 8.0, "Warrior sprint")
	assert_eq(p.crouch_speed, 2.5, "Warrior crouch")


func test_warrior_combat() -> void:
	var p = _create_player("res://scenes/player/player.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.attack_range, 3.0, "Warrior melee range")
	assert_eq(p.heavy_cooldown, 0.6, "Warrior heavy cooldown")


func test_warrior_damage_formula() -> void:
	var p = _create_player("res://scenes/player/player.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	# Puñetazo: 35 + (12 STR * 2) = 59
	assert_eq(p.get_physical_damage(35.0), 59.0, "Heavy punch damage")
	# Combo: 15 + (12 * 2) = 39
	assert_eq(p.get_physical_damage(15.0), 39.0, "Combo punch damage")


# ═══════════════════════════════════════════
# MAGE
# ═══════════════════════════════════════════

func test_mage_stats() -> void:
	var p = _create_player("res://scenes/player/mage.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.str_stat, 4, "Mage STR")
	assert_eq(p.int_stat, 12, "Mage INT")
	assert_eq(p.dex_stat, 5, "Mage DEX")
	assert_eq(p.def_stat, 3, "Mage DEF")
	assert_eq(p.vit_stat, 5, "Mage VIT")


func test_mage_health_mana() -> void:
	var p = _create_player("res://scenes/player/mage.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	# HP = 70 + (5 * 5) = 95
	assert_eq(p.max_health, 95.0, "Mage max HP")
	# MP = 120 + (12 * 3) = 156
	assert_eq(p.max_mana, 156.0, "Mage max MP")


func test_mage_speed() -> void:
	var p = _create_player("res://scenes/player/mage.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.speed, 4.5, "Mage speed")
	assert_eq(p.sprint_speed, 7.0, "Mage sprint")
	assert_eq(p.crouch_speed, 2.0, "Mage crouch")


func test_mage_resistances() -> void:
	var p = _create_player("res://scenes/player/mage.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_almost_eq(p.res_fire, 0.1, 0.001, "Mage fire res")
	assert_almost_eq(p.res_ice, 0.1, 0.001, "Mage ice res")
	assert_almost_eq(p.res_lightning, 0.1, 0.001, "Mage lightning res")


func test_mage_damage_formula() -> void:
	var p = _create_player("res://scenes/player/mage.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	# Bolita: 25 + (12 INT * 2) = 49
	assert_eq(p.get_magic_damage(25.0), 49.0, "Mage projectile damage")
	# Rayo tick: 8 + (12 * 2) = 32
	assert_eq(p.get_magic_damage(8.0), 32.0, "Beam tick damage")


# ═══════════════════════════════════════════
# ARCHER
# ═══════════════════════════════════════════

func test_archer_stats() -> void:
	var p = _create_player("res://scenes/player/archer.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.str_stat, 5, "Archer STR")
	assert_eq(p.int_stat, 3, "Archer INT")
	assert_eq(p.dex_stat, 12, "Archer DEX")
	assert_eq(p.def_stat, 5, "Archer DEF")
	assert_eq(p.vit_stat, 7, "Archer VIT")


func test_archer_health_mana() -> void:
	var p = _create_player("res://scenes/player/archer.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	# HP = 85 + (7 * 5) = 120
	assert_eq(p.max_health, 120.0, "Archer max HP")
	# MP = 70 + (3 * 3) = 79
	assert_eq(p.max_mana, 79.0, "Archer max MP")


func test_archer_speed() -> void:
	var p = _create_player("res://scenes/player/archer.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.speed, 5.5, "Archer speed (fastest)")
	assert_eq(p.sprint_speed, 9.0, "Archer sprint")
	assert_eq(p.crouch_speed, 2.5, "Archer crouch")


func test_archer_combat() -> void:
	var p = _create_player("res://scenes/player/archer.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.attack_range, 20.0, "Archer long range")
	assert_eq(p.heavy_cooldown, 0.7, "Archer shot cooldown")


func test_archer_damage_formula() -> void:
	var p = _create_player("res://scenes/player/archer.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	# Flecha: 20 + (12 DEX * 2) = 44
	assert_eq(p.get_dex_damage(20.0), 44.0, "Arrow damage")
	# Cargada: 20 * 2.5 = 50 base → 50 + (12 * 2) = 74
	assert_eq(p.get_dex_damage(50.0), 74.0, "Charged arrow damage")


# ═══════════════════════════════════════════
# NECROMANCER
# ═══════════════════════════════════════════

func test_necromancer_stats() -> void:
	var p = _create_player("res://scenes/player/necromancer.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.str_stat, 3, "Necro STR")
	assert_eq(p.int_stat, 10, "Necro INT")
	assert_eq(p.dex_stat, 4, "Necro DEX")
	assert_eq(p.def_stat, 4, "Necro DEF")
	assert_eq(p.vit_stat, 6, "Necro VIT")


func test_necromancer_health_mana() -> void:
	var p = _create_player("res://scenes/player/necromancer.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	# HP = 80 + (6 * 5) = 110
	assert_eq(p.max_health, 110.0, "Necro max HP")
	# MP = 110 + (10 * 3) = 140
	assert_eq(p.max_mana, 140.0, "Necro max MP")


func test_necromancer_speed() -> void:
	var p = _create_player("res://scenes/player/necromancer.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.speed, 4.5, "Necro speed")
	assert_eq(p.sprint_speed, 7.0, "Necro sprint")


func test_necromancer_damage_formula() -> void:
	var p = _create_player("res://scenes/player/necromancer.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	# Orbe: 22 + (10 INT * 2) = 42
	assert_eq(p.get_magic_damage(22.0), 42.0, "Dark orb damage")
	# Drain tick: 6 + (10 * 2) = 26
	assert_eq(p.get_magic_damage(6.0), 26.0, "Drain tick damage")


func test_necromancer_drain_heal_calculation() -> void:
	var p = _create_player("res://scenes/player/necromancer.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	# Verificar que drain_heal_percent existe y tiene el valor esperado
	assert_almost_eq(p.drain_heal_percent, 0.25, 0.001, "drain_heal_percent = 0.25")

	# drain dmg = 6 + (10 INT * 2) = 26, heal = 26 * 0.25 = 6.5
	var drain_dmg = p.get_magic_damage(6.0)
	var expected_heal = drain_dmg * p.drain_heal_percent
	assert_almost_eq(expected_heal, 6.5, 0.01, "Heal amount = 6.5")

	# Verificar que heal() realmente aplica al HP
	p.health = 50.0
	p.heal(expected_heal)
	assert_almost_eq(p.health, 56.5, 0.01, "HP sube de 50 a 56.5 con drain heal")


# ═══════════════════════════════════════════
# CLERIC
# ═══════════════════════════════════════════

func test_cleric_stats() -> void:
	var p = _create_player("res://scenes/player/cleric.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.str_stat, 8, "Cleric STR")
	assert_eq(p.int_stat, 6, "Cleric INT")
	assert_eq(p.dex_stat, 4, "Cleric DEX")
	assert_eq(p.def_stat, 8, "Cleric DEF")
	assert_eq(p.vit_stat, 9, "Cleric VIT")


func test_cleric_health_mana() -> void:
	var p = _create_player("res://scenes/player/cleric.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	# HP = 95 + (9 * 5) = 140
	assert_eq(p.max_health, 140.0, "Cleric max HP")
	# MP = 100 + (6 * 3) = 118
	assert_eq(p.max_mana, 118.0, "Cleric max MP")


func test_cleric_speed() -> void:
	var p = _create_player("res://scenes/player/cleric.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.speed, 4.5, "Cleric speed")
	assert_eq(p.sprint_speed, 7.0, "Cleric sprint")


func test_cleric_combat() -> void:
	var p = _create_player("res://scenes/player/cleric.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.attack_range, 3.0, "Cleric melee range")
	assert_eq(p.heavy_cooldown, 0.5, "Cleric mace cooldown")


func test_cleric_dual_damage_types() -> void:
	var p = _create_player("res://scenes/player/cleric.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	# Mazazo (físico): 25 + (8 STR * 2) = 41
	assert_eq(p.get_physical_damage(25.0), 41.0, "Mace hit damage")
	# Smite (mágico): 60 + (6 INT * 2) = 72
	assert_eq(p.get_magic_damage(60.0), 72.0, "Smite damage")


# ═══════════════════════════════════════════
# COMPARACIONES ENTRE CLASES
# ═══════════════════════════════════════════

func test_warrior_has_highest_physical_defense() -> void:
	var w = _create_player("res://scenes/player/player.gd")
	var m = _create_player("res://scenes/player/mage.gd")
	var a = _create_player("res://scenes/player/archer.gd")
	add_child_autofree(w)
	add_child_autofree(m)
	add_child_autofree(a)
	await get_tree().process_frame

	assert_gt(w.def_stat, m.def_stat, "Warrior DEF > Mage DEF")
	assert_gt(w.def_stat, a.def_stat, "Warrior DEF > Archer DEF")


func test_mage_has_highest_mana() -> void:
	var w = _create_player("res://scenes/player/player.gd")
	var m = _create_player("res://scenes/player/mage.gd")
	add_child_autofree(w)
	add_child_autofree(m)
	await get_tree().process_frame

	assert_gt(m.max_mana, w.max_mana, "Mage MP > Warrior MP")


func test_archer_is_fastest() -> void:
	var a = _create_player("res://scenes/player/archer.gd")
	var w = _create_player("res://scenes/player/player.gd")
	var m = _create_player("res://scenes/player/mage.gd")
	add_child_autofree(a)
	add_child_autofree(w)
	add_child_autofree(m)
	await get_tree().process_frame

	assert_gt(a.speed, w.speed, "Archer faster than Warrior")
	assert_gt(a.speed, m.speed, "Archer faster than Mage")
	assert_gt(a.sprint_speed, w.sprint_speed, "Archer sprint > Warrior sprint")
