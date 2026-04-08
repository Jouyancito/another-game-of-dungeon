extends GutTest

# Tests para EnemyBasic — stats, daño, muerte, XP reward

var enemy_scene: PackedScene = preload("res://scenes/enemy/enemy_basic.tscn")


func _create_enemy() -> CharacterBody3D:
	var e = enemy_scene.instantiate()
	add_child_autofree(e)
	return e


# ─── Stats por defecto ───

func test_default_health() -> void:
	var e = _create_enemy()
	assert_eq(e.health, 100.0, "100 HP por defecto")


func test_default_speed() -> void:
	var e = _create_enemy()
	assert_eq(e.speed, 3.0)


func test_default_damage() -> void:
	var e = _create_enemy()
	assert_eq(e.damage, 10.0)


func test_default_attack_range() -> void:
	var e = _create_enemy()
	assert_eq(e.attack_range, 2.0)


func test_default_detection_range() -> void:
	var e = _create_enemy()
	assert_eq(e.detection_range, 15.0)


func test_default_xp_reward() -> void:
	var e = _create_enemy()
	assert_eq(e.xp_reward, 30.0)


func test_default_attack_cooldown() -> void:
	var e = _create_enemy()
	assert_eq(e.attack_cooldown, 1.0)


func test_starts_alive() -> void:
	var e = _create_enemy()
	assert_false(e.is_dead)
	assert_true(e.can_attack)


# ─── take_damage ───

func test_take_damage_reduces_health() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.take_damage(30.0)
	assert_eq(e.health, 70.0, "100 - 30 = 70")


func test_take_damage_multiple_hits() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.take_damage(25.0)
	e.take_damage(25.0)
	assert_eq(e.health, 50.0, "100 - 25 - 25 = 50")


func test_take_damage_kills_at_zero() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.take_damage(100.0)
	assert_true(e.is_dead, "Muere con 0 HP")


func test_take_damage_overkill() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.take_damage(999.0)
	assert_true(e.is_dead, "Muere con daño excesivo")
	assert_lt(e.health, 0.0, "HP puede ir debajo de 0")


# ─── die ───

func test_die_sets_is_dead() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.die()
	# Await a frame so the tween's queue_free callback doesn't conflict with autofree
	await get_tree().process_frame
	assert_true(e.is_dead)


func test_die_gives_xp_to_target() -> void:
	var e = _create_enemy()
	await get_tree().process_frame

	# Crear un target mock con gain_xp
	var mock_target = BasePlayer.new()
	mock_target.str_stat = 5
	mock_target.int_stat = 5
	mock_target.dex_stat = 5
	mock_target.def_stat = 5
	mock_target.vit_stat = 5
	mock_target.recalculate_stats()
	mock_target.health = mock_target.max_health
	mock_target.mana = mock_target.max_mana
	add_child_autofree(mock_target)

	e.target = mock_target
	e.die()
	await get_tree().process_frame
	assert_eq(mock_target.xp, 30.0, "Enemy da 30 XP al morir")


func test_die_no_crash_without_target() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.target = null
	e.die()
	await get_tree().process_frame
	assert_true(e.is_dead, "Muere sin crash aunque no tenga target")


# ─── Detección (lógica de estados) ───

func test_no_target_means_idle() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.target = null
	# Sin target, velocity debería quedarse en 0
	e._physics_process(0.016)
	assert_eq(e.velocity.x, 0.0)
	assert_eq(e.velocity.z, 0.0)


func test_dead_enemy_does_nothing() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.is_dead = true
	e._physics_process(0.016)
	# No debería hacer nada
	assert_true(e.is_dead)


# ─── perform_attack ───

func test_perform_attack_deals_damage_to_target() -> void:
	var e = _create_enemy()
	await get_tree().process_frame

	var mock_target = BasePlayer.new()
	mock_target.str_stat = 5
	mock_target.int_stat = 5
	mock_target.dex_stat = 5
	mock_target.def_stat = 0
	mock_target.vit_stat = 5
	mock_target.recalculate_stats()
	mock_target.health = mock_target.max_health
	mock_target.mana = mock_target.max_mana
	add_child_autofree(mock_target)

	var initial_health = mock_target.health
	e.target = mock_target
	e.perform_attack()
	# damage = 10.0, target def = 0 → apply_physical_defense(10) = max(10-0, 1) = 10
	assert_eq(mock_target.health, initial_health - 10.0, "Enemy deals 10 dmg with 0 DEF")
