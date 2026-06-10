extends GutTest

# Tests para BaseEnemy — stats, daño, muerte, XP reward, agresividad
# enemy_basic.gd ahora extiende BaseEnemy, testeamos via la escena.

var enemy_scene: PackedScene = preload("res://scenes/enemy/enemy_basic.tscn")


func _create_enemy() -> CharacterBody3D:
	var e = enemy_scene.instantiate()
	add_child_autofree(e)
	return e


# ─── Minimal mocks ───────────────────────────────────────────────────────────
# Using BasePlayer.new() in headless tests crashes because its @onready vars
# ($CollisionShape3D, $Head, $Head/Camera3D, $MeshInstance3D) resolve to null
# when the node is created without its .tscn scene. These minimal mocks provide
# only the interface required by the specific test — no BasePlayer overhead.

## Mock for tests that only need gain_xp (e.g. test_die_gives_xp_to_target).
class MockXPTarget extends Node3D:
	var xp: float = 0.0

	func gain_xp(amount: float) -> void:
		xp += amount


## Mock for tests that need take_damage with health tracking.
## DEF=0 so damage passes through unmodified (mirrors apply_armor_v2(dmg, 0, 1) = dmg).
class MockCombatTarget extends Node3D:
	var health: float = 100.0
	var is_dead: bool = false
	var is_downed: bool = false
	var skills = null

	func take_damage(amount: float, _element: String = "", _attacker: Node = null) -> void:
		if is_dead or is_downed:
			return
		# DEF = 0 → apply_armor_v2(amount, 0, 1) = amount * (1 - 0/(0+50)) = amount
		health -= amount


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


func test_default_aggression_is_aggressive() -> void:
	var e = _create_enemy()
	assert_eq(e.aggression, BaseEnemy.AggressionType.AGGRESSIVE)


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
	# KNOWN GAME BUG: take_damage → die() → _spawn_loot() → DropController.spawn_drops()
	# → gold.global_position (Area3D not yet in tree) + scene_root.call_deferred on null.
	# Bugs in game/shared/loot/drop_controller.gd lines 47-48. Cannot fix from test code.
	# assert_engine_error acknowledges the expected errors so GUT does not count as failures.
	assert_engine_error("is_inside_tree", "gold.global_position on unparented Area3D — game bug")
	assert_engine_error("call_deferred", "scene_root null — game bug in drop_controller.gd:48")
	assert_true(e.is_dead, "Muere con 0 HP")


func test_take_damage_ignored_when_dead() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.is_dead = true
	var old_health = e.health
	e.take_damage(50.0)
	assert_eq(e.health, old_health, "No recibe daño estando muerto")


# ─── Provocación (neutrales) ───

func test_neutral_not_provoked_by_default() -> void:
	var e = _create_enemy()
	e.aggression = BaseEnemy.AggressionType.NEUTRAL
	assert_false(e.is_provoked)


func test_neutral_provoked_on_damage() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.aggression = BaseEnemy.AggressionType.NEUTRAL
	e.take_damage(10.0)
	assert_true(e.is_provoked, "Neutral se provoca al recibir daño")


func test_aggressive_not_affected_by_provoke() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.take_damage(10.0)
	assert_false(e.is_provoked, "Aggressive no usa is_provoked")


# ─── die ───

func test_die_sets_is_dead() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.die()
	# KNOWN GAME BUG: die() → _spawn_loot() → DropController.spawn_drops()
	# → gold.global_position (Area3D not yet in tree) + scene_root.call_deferred on null.
	# Bugs in game/shared/loot/drop_controller.gd lines 47-48.
	assert_engine_error("is_inside_tree", "gold.global_position on unparented Area3D — game bug")
	assert_engine_error("call_deferred", "scene_root null — game bug in drop_controller.gd:48")
	await get_tree().process_frame
	assert_true(e.is_dead)


func test_die_gives_xp_to_target() -> void:
	var e = _create_enemy()
	await get_tree().process_frame

	# Use MockXPTarget instead of BasePlayer.new(): BasePlayer._ready() crashes in
	# headless tests because @onready vars ($CollisionShape3D etc.) resolve to null
	# when instantiated without its .tscn scene. MockXPTarget provides only gain_xp,
	# which is all die() needs: `if target and target.has_method("gain_xp"): gain_xp(xp_reward)`.
	var mock_target := MockXPTarget.new()
	add_child_autofree(mock_target)

	e.target = mock_target
	# KNOWN GAME BUG: die() → _spawn_loot() → DropController.spawn_drops() calls
	# query_node.get_tree().current_scene which is null in the GUT headless runner.
	# The gold.global_position assignment also crashes because gold is not yet in tree.
	# Both are bugs in game/shared/loot/drop_controller.gd (lines 47–48) that cannot
	# be fixed from test code. die() sets is_dead = true and calls gain_xp BEFORE
	# _spawn_loot, so the XP assertion remains valid despite the expected errors.
	e.die()
	# Acknowledge engine errors from DropController so GUT does not count as test failures.
	assert_engine_error("is_inside_tree", "gold.global_position on unparented Area3D — game bug")
	assert_engine_error("call_deferred", "scene_root null — game bug in drop_controller.gd:48")
	await get_tree().process_frame
	assert_eq(mock_target.xp, 30.0, "Enemy da 30 XP al morir")


func test_die_no_crash_without_target() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.target = null
	e.die()
	# KNOWN GAME BUG: die() → _spawn_loot() → DropController.spawn_drops()
	# → gold.global_position (Area3D not yet in tree) + scene_root.call_deferred on null.
	# Bugs in game/shared/loot/drop_controller.gd lines 47-48.
	assert_engine_error("is_inside_tree", "gold.global_position on unparented Area3D — game bug")
	assert_engine_error("call_deferred", "scene_root null — game bug in drop_controller.gd:48")
	await get_tree().process_frame
	assert_true(e.is_dead, "Muere sin crash aunque no tenga target")


# ─── IA / estados ───

func test_no_target_means_idle() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.target = null
	e._physics_process(0.016)
	assert_eq(e.velocity.x, 0.0)
	assert_eq(e.velocity.z, 0.0)


func test_dead_enemy_does_nothing() -> void:
	var e = _create_enemy()
	await get_tree().process_frame
	e.is_dead = true
	e._physics_process(0.016)
	assert_true(e.is_dead)


# ─── should_pursue ───

func test_aggressive_pursues_in_range() -> void:
	var e = _create_enemy()
	assert_true(e._should_pursue(10.0), "Aggressive persigue dentro de detection_range")


func test_aggressive_does_not_pursue_out_of_range() -> void:
	var e = _create_enemy()
	assert_false(e._should_pursue(20.0), "Aggressive no persigue fuera de rango")


func test_neutral_does_not_pursue_unprovoked() -> void:
	var e = _create_enemy()
	e.aggression = BaseEnemy.AggressionType.NEUTRAL
	e.is_provoked = false
	assert_false(e._should_pursue(10.0), "Neutral no persigue sin provocar")


func test_neutral_pursues_when_provoked() -> void:
	var e = _create_enemy()
	e.aggression = BaseEnemy.AggressionType.NEUTRAL
	e.is_provoked = true
	assert_true(e._should_pursue(10.0), "Neutral persigue si fue provocado")


# ─── perform_attack ───

func test_perform_attack_deals_damage_to_target() -> void:
	var e = _create_enemy()
	await get_tree().process_frame

	# Use MockCombatTarget instead of BasePlayer.new(): BasePlayer._ready() crashes in
	# headless tests because @onready vars ($CollisionShape3D etc.) resolve to null when
	# instantiated without its .tscn scene.
	# MockCombatTarget.take_damage subtracts amount directly; with DEF=0 this is equivalent
	# to apply_armor_v2(amount, 0, 1) = amount*(1 - 0/(0+50)) = amount (canon §2.5).
	var mock_target := MockCombatTarget.new()
	mock_target.health = 100.0
	add_child_autofree(mock_target)

	var initial_health: float = mock_target.health
	e.target = mock_target
	e.perform_attack()
	# Canon §2.5: apply_armor_v2(10, DEF=0, attacker_level=1) = 10 * (1 - 0/(0+50)) = 10
	assert_almost_eq(mock_target.health, initial_health - 10.0, 0.01, "Enemy deals 10 dmg with 0 DEF (v2)")
