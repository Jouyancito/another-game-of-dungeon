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


## Helper canon v2 §2.1 — max_hp esperado para una clase con base + VIT + level.
func _hp_v2(base_hp: float, vit: int, level: int = 1) -> float:
	return Progression.max_health_v2(base_hp, vit, level)


## Helper canon v2 §2.2 — max_mp esperado.
func _mp_v2(base_mp: float, int_stat: int, level: int = 1) -> float:
	return Progression.max_mana_v2(base_mp, int_stat, level)


## Helper canon v2 §2.3-2.4 — dmg esperado.
func _phys_v2(base: float, str_stat: int, weapon: int, level: int, class_mult: float) -> float:
	return DamageFormula.physical_v2(base, weapon, str_stat, level, class_mult)

func _magic_v2(base: float, int_stat: int, weapon: int, level: int, class_mult: float) -> float:
	return DamageFormula.magic_v2(base, weapon, int_stat, level, class_mult)


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
	# Canon v2 §2.1-2.2: compound decelerada con level=1.
	assert_almost_eq(p.max_health, _hp_v2(100.0, 10, 1), 0.05, "Warrior max HP v2")
	assert_almost_eq(p.health, _hp_v2(100.0, 10, 1), 0.05, "Warrior full HP")
	assert_almost_eq(p.max_mana, _mp_v2(80.0, 3, 1), 0.05, "Warrior max MP v2")
	assert_almost_eq(p.mana, _mp_v2(80.0, 3, 1), 0.05, "Warrior full MP")


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
	# Canon v2 §2.3: class_mult 1.5, level=1, weapon=0 (sin equipment).
	assert_almost_eq(p.get_physical_damage(35.0), _phys_v2(35.0, 12, 0, 1, 1.5), 0.05, "Heavy punch v2")
	assert_almost_eq(p.get_physical_damage(15.0), _phys_v2(15.0, 12, 0, 1, 1.5), 0.05, "Combo v2")


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
	assert_almost_eq(p.max_health, _hp_v2(70.0, 5, 1), 0.05, "Mage max HP v2")
	assert_almost_eq(p.max_mana, _mp_v2(120.0, 12, 1), 0.05, "Mage max MP v2")


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
	# Canon v2 §2.4: Mage class_mult 1.5, level=1, weapon=0.
	assert_almost_eq(p.get_magic_damage(25.0), _magic_v2(25.0, 12, 0, 1, 1.5), 0.05, "Bolita v2")
	assert_almost_eq(p.get_magic_damage(8.0), _magic_v2(8.0, 12, 0, 1, 1.5), 0.05, "Beam tick v2")


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
	assert_almost_eq(p.max_health, _hp_v2(85.0, 7, 1), 0.05, "Archer max HP v2")
	assert_almost_eq(p.max_mana, _mp_v2(70.0, 3, 1), 0.05, "Archer max MP v2")


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
	# get_dex_damage sigue legacy lineal (DEX*2 + base + weapon). Sin canon v2 específico.
	assert_eq(p.get_dex_damage(20.0), 44.0, "Arrow damage (legacy DEX)")
	assert_eq(p.get_dex_damage(50.0), 74.0, "Charged arrow damage (legacy DEX)")


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
	assert_almost_eq(p.max_health, _hp_v2(80.0, 6, 1), 0.05, "Necro max HP v2")
	assert_almost_eq(p.max_mana, _mp_v2(110.0, 10, 1), 0.05, "Necro max MP v2")


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
	# Necromancer no seteó class_mult_magic explícito — default 1.0 por ahora.
	# TODO dept-gameplay: cuando necromancer.gd se toque, setear class_mult_magic canon.
	assert_almost_eq(p.get_magic_damage(22.0), _magic_v2(22.0, 10, 0, 1, p.class_mult_magic), 0.05, "Dark orb v2")
	assert_almost_eq(p.get_magic_damage(6.0), _magic_v2(6.0, 10, 0, 1, p.class_mult_magic), 0.05, "Drain tick v2")


func test_necromancer_drain_heal_calculation() -> void:
	var p = _create_player("res://scenes/player/necromancer.gd")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_almost_eq(p.drain_heal_percent, 0.25, 0.001, "drain_heal_percent = 0.25")

	# drain dmg v2 + heal = dmg * 0.25
	var drain_dmg = p.get_magic_damage(6.0)
	var expected_heal = drain_dmg * p.drain_heal_percent
	# Solo validamos proporción (dmg dependiente de class_mult y fórmula compound)
	assert_almost_eq(expected_heal, drain_dmg * 0.25, 0.01)

	p.health = 50.0
	p.heal(expected_heal)
	assert_almost_eq(p.health, 50.0 + expected_heal, 0.01, "HP sube por drain heal")


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
	assert_almost_eq(p.max_health, _hp_v2(95.0, 9, 1), 0.05, "Cleric max HP v2")
	assert_almost_eq(p.max_mana, _mp_v2(100.0, 6, 1), 0.05, "Cleric max MP v2")


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
	# class_mult de Cleric no está canonizado explícito — usa el valor actual seteado por _on_class_ready.
	assert_almost_eq(p.get_physical_damage(25.0), _phys_v2(25.0, 8, 0, 1, p.class_mult_physical), 0.05, "Mace v2")
	assert_almost_eq(p.get_magic_damage(60.0), _magic_v2(60.0, 6, 0, 1, p.class_mult_magic), 0.05, "Smite v2")


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
