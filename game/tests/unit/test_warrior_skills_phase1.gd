extends GutTest

# Tests de Fase 1 — 4 skills canon Warrior + status system en BaseEnemy.

var player: BasePlayer
var skills: PlayerSkills
var rage: ClassResource


func before_each() -> void:
	player = BasePlayer.new()
	player.str_stat = 12
	player.int_stat = 4
	player.dex_stat = 6
	player.def_stat = 10
	player.vit_stat = 10
	player.base_health = 100.0
	player.base_mana = 80.0
	player.inventory = Inventory.new()
	player.equipment = Equipment.new()
	player.recalculate_stats()
	player.health = player.max_health
	player.mana = player.max_mana
	skills = PlayerSkills.new()
	rage = ClassResource.new()
	rage.type = ClassResource.Type.RAGE
	rage.max_value = 100
	skills.setup(player, rage)
	player.add_child(skills)
	player.add_child(rage)
	player.class_resource = rage
	player.skills = skills


func after_each() -> void:
	if is_instance_valid(player):
		player.free()


# ─── Canon .tres cargan valores exactos de warrior.md §3 ───

func test_punch_tres_canon_values() -> void:
	var s: SkillResource = load("res://shared/skills/resources/warrior/punch.tres")
	assert_not_null(s)
	assert_eq(s.id, &"warrior_punch")
	assert_eq(s.base_damage, 15)
	assert_eq(s.resource_cost, 0)
	assert_eq(s.cooldown_s, 0.5)
	assert_eq(s.range_m, 2.0)
	assert_eq(s.cone_angle_deg, 60.0)


func test_charge_tres_canon_values() -> void:
	var s: SkillResource = load("res://shared/skills/resources/warrior/charge.tres")
	assert_not_null(s)
	assert_eq(s.id, &"warrior_charge")
	assert_eq(s.base_damage, 20)
	assert_eq(s.resource_cost, 10)
	assert_eq(s.cooldown_s, 8.0)
	assert_eq(s.dash_distance_m, 6.0)
	assert_eq(s.status_duration_s, 0.8)


func test_war_cry_tres_canon_values() -> void:
	var s: SkillResource = load("res://shared/skills/resources/warrior/war_cry.tres")
	assert_not_null(s)
	assert_eq(s.id, &"warrior_war_cry")
	assert_eq(s.cast_type, SkillResource.CastType.TOGGLE)
	assert_eq(s.radius_m, 10.0)
	assert_eq(s.tick_interval_s, 5.0)
	assert_eq(s.tick_resource_cost, 20)
	assert_eq(s.ally_damage_bonus_pct, 0.15)


func test_perfect_block_tres_canon_values() -> void:
	var s: SkillResource = load("res://shared/skills/resources/warrior/perfect_block.tres")
	assert_not_null(s)
	assert_eq(s.id, &"warrior_perfect_block")
	assert_eq(s.reactive_window_s, 0.4)
	assert_eq(s.reflect_ratio, 0.5)
	assert_eq(s.reactive_rage_on_success, 10)
	assert_eq(s.cooldown_s, 4.0)
	assert_eq(s.status_duration_s, 0.5)


# ─── Mock enemy con apply_status ───

class MockEnemy extends Node3D:
	var health: float = 100.0
	var is_dead: bool = false
	var status_effects: Dictionary = {}
	var last_damage: float = 0.0

	func _init() -> void:
		add_to_group("enemies")

	func take_damage(amount: float, _dir: Vector3, _kb: float, _attacker_str: int, _attacker) -> void:
		last_damage = amount
		health -= amount
		if health <= 0:
			is_dead = true

	func apply_status(name: StringName, duration: float) -> void:
		var cur: float = float(status_effects.get(name, {}).get("time_left", 0.0))
		status_effects[name] = {"time_left": maxf(cur, duration)}

	func has_status(name: StringName) -> bool:
		return status_effects.has(name)


# ─── Puño de Guerra — cono, multi-target ───

func test_punch_hits_multiple_enemies_in_cone() -> void:
	var punch: SkillResource = load("res://shared/skills/resources/warrior/punch.tres")
	skills.set_slot(0, punch)
	# 3 enemies: 2 dentro del cono 60°/2m, 1 fuera
	var e1 := MockEnemy.new()
	var e2 := MockEnemy.new()
	var e3 := MockEnemy.new()
	player.add_child(e1)
	player.add_child(e2)
	player.add_child(e3)
	# Player mira hacia -Z (forward default). Cono 60° significa ±30° del forward.
	e1.global_position = player.global_position + Vector3(0, 0, -1.5)    # frente (-Z)
	e2.global_position = player.global_position + Vector3(0.5, 0, -1.5)  # frente-derecha dentro de ±30°
	e3.global_position = player.global_position + Vector3(3, 0, -1.5)    # fuera de cono (angle too wide)
	skills.cast_slot(0)
	assert_gt(e1.last_damage, 0.0, "enemy frente impactado")
	assert_gt(e2.last_damage, 0.0, "enemy diagonal dentro de cono impactado")
	assert_eq(e3.last_damage, 0.0, "enemy fuera de cono NO impactado")


# ─── Embestida — dash + stun ───

func test_charge_applies_stun_to_hit_enemy() -> void:
	var charge: SkillResource = load("res://shared/skills/resources/warrior/charge.tres")
	skills.set_slot(1, charge)
	var e := MockEnemy.new()
	player.add_child(e)
	e.global_position = player.global_position + Vector3(0, 0, -4.0)
	player.mana = 50.0
	skills.cast_slot(1)
	assert_gt(e.last_damage, 0.0, "dmg aplicado al impactar")
	assert_true(e.has_status(&"stun"), "stun aplicado")
	assert_almost_eq(float(e.status_effects[&"stun"]["time_left"]), 0.8, 0.01)


func test_charge_moves_player_toward_enemy() -> void:
	var charge: SkillResource = load("res://shared/skills/resources/warrior/charge.tres")
	skills.set_slot(1, charge)
	var e := MockEnemy.new()
	player.add_child(e)
	e.global_position = player.global_position + Vector3(0, 0, -4.0)
	var start: Vector3 = player.global_position
	player.mana = 50.0
	skills.cast_slot(1)
	# Player debe moverse hacia enemy — stop ~1.2m antes del enemy
	var moved_dist: float = start.distance_to(player.global_position)
	assert_gt(moved_dist, 2.0, "player se movió al menos 2m")


func test_charge_costs_10_mp() -> void:
	var charge: SkillResource = load("res://shared/skills/resources/warrior/charge.tres")
	skills.set_slot(1, charge)
	player.mana = 50.0
	skills.cast_slot(1)
	assert_eq(player.mana, 40.0, "Embestida consume 10 MP")


func test_charge_fails_insufficient_mana() -> void:
	var charge: SkillResource = load("res://shared/skills/resources/warrior/charge.tres")
	skills.set_slot(1, charge)
	player.mana = 5.0
	var ok: bool = skills.cast_slot(1)
	assert_false(ok)
	assert_eq(player.mana, 5.0, "maná no consumido si falla")


# ─── Grito de Guerra — toggle aura ───

func test_war_cry_toggles_on_and_off() -> void:
	var cry: SkillResource = load("res://shared/skills/resources/warrior/war_cry.tres")
	skills.set_slot(2, cry)
	player.mana = 80.0
	skills.cast_slot(2)
	assert_true(skills.is_toggle_active(&"warrior_war_cry"), "aura activa")
	# Re-cast apaga
	skills.cast_slot(2)
	assert_false(skills.is_toggle_active(&"warrior_war_cry"), "aura apagada")


func test_war_cry_applies_weak_to_enemies_in_radius() -> void:
	var cry: SkillResource = load("res://shared/skills/resources/warrior/war_cry.tres")
	skills.set_slot(2, cry)
	var near := MockEnemy.new()
	var far := MockEnemy.new()
	player.add_child(near)
	player.add_child(far)
	near.global_position = player.global_position + Vector3(0, 0, -5.0)   # dentro de 10m
	far.global_position = player.global_position + Vector3(0, 0, -15.0)   # fuera de 10m
	player.mana = 80.0
	skills.cast_slot(2)
	assert_true(near.has_status(&"weak"), "enemy cercano tiene Weak")
	assert_false(far.has_status(&"weak"), "enemy lejano sin Weak")


func test_war_cry_drains_mp_each_tick() -> void:
	var cry: SkillResource = load("res://shared/skills/resources/warrior/war_cry.tres")
	skills.set_slot(2, cry)
	player.mana = 80.0
	skills.cast_slot(2)
	# Consumió 20 MP inicial → 60 restantes
	assert_eq(player.mana, 60.0, "costo inicial 20 MP")
	# Simular 5s → otro tick drain
	skills._process(5.0)
	assert_eq(player.mana, 40.0, "tick drena 20 MP cada 5s")


func test_war_cry_deactivates_when_mp_runs_out() -> void:
	var cry: SkillResource = load("res://shared/skills/resources/warrior/war_cry.tres")
	skills.set_slot(2, cry)
	player.mana = 25.0
	skills.cast_slot(2)  # consume 20 → queda 5
	assert_eq(player.mana, 5.0)
	skills._process(5.0)  # quiere drain 20 pero solo hay 5 → apaga
	assert_false(skills.is_toggle_active(&"warrior_war_cry"), "aura se apaga sin MP")


func test_war_cry_buffs_caster_outgoing_damage() -> void:
	var cry: SkillResource = load("res://shared/skills/resources/warrior/war_cry.tres")
	skills.set_slot(2, cry)
	player.mana = 80.0
	var base_dmg: float = player.get_physical_damage(20.0)  # 20 + 12*2 = 44
	skills.cast_slot(2)
	var buffed_dmg: float = player.get_physical_damage(20.0)  # * 1.15
	assert_almost_eq(buffed_dmg, base_dmg * 1.15, 0.01, "+15% dmg con aura")


# ─── Bloqueo Perfecto — reactivo ventana ───

func test_perfect_block_opens_window() -> void:
	var pb: SkillResource = load("res://shared/skills/resources/warrior/perfect_block.tres")
	skills.set_slot(3, pb)
	skills.cast_slot(3)
	assert_true(skills.is_reactive_open(&"warrior_perfect_block"), "ventana abierta")


func test_perfect_block_absorbs_damage_within_window() -> void:
	var pb: SkillResource = load("res://shared/skills/resources/warrior/perfect_block.tres")
	skills.set_slot(3, pb)
	skills.cast_slot(3)
	var hp_before: float = player.health
	var attacker := MockEnemy.new()
	player.add_child(attacker)
	player.take_damage(30.0, "", attacker)
	assert_eq(player.health, hp_before, "daño absorbido 100%")
	assert_true(attacker.has_status(&"stun"), "atacante atontado")


func test_perfect_block_grants_rage_on_success() -> void:
	var pb: SkillResource = load("res://shared/skills/resources/warrior/perfect_block.tres")
	skills.set_slot(3, pb)
	assert_eq(rage.get_current(), 0)
	skills.cast_slot(3)
	var attacker := MockEnemy.new()
	player.add_child(attacker)
	player.take_damage(30.0, "", attacker)
	assert_eq(rage.get_current(), 10, "+10 Rage en parry exitoso")


func test_perfect_block_window_closes_after_duration() -> void:
	var pb: SkillResource = load("res://shared/skills/resources/warrior/perfect_block.tres")
	skills.set_slot(3, pb)
	skills.cast_slot(3)
	skills._process(0.5)  # ventana 0.4s expirada
	assert_false(skills.is_reactive_open(&"warrior_perfect_block"), "ventana cerrada post-0.4s")


func test_damage_passes_through_when_no_window() -> void:
	# Sin Bloqueo activo → daño normal
	var hp_before: float = player.health
	player.take_damage(30.0)
	assert_lt(player.health, hp_before, "daño aplicado sin parry")


# ─── BaseEnemy status system (sin mock — clase real) ───

var _real_enemy: BaseEnemy


func _make_enemy() -> BaseEnemy:
	var e := BaseEnemy.new()
	e.health = 100.0
	e._max_health = 100.0
	e.damage = 10.0
	player.add_child(e)
	return e


func test_enemy_apply_stun_flag_set() -> void:
	var e := _make_enemy()
	e.apply_status(&"stun", 1.0)
	assert_true(e.has_status(&"stun"))
	assert_almost_eq(e.get_status_time_left(&"stun"), 1.0, 0.01)


func test_enemy_stun_expires_after_duration() -> void:
	var e := _make_enemy()
	e.apply_status(&"stun", 1.0)
	e._tick_statuses(1.5)
	assert_false(e.has_status(&"stun"), "stun removido post-duración")


func test_enemy_stun_refresh_to_max() -> void:
	var e := _make_enemy()
	e.apply_status(&"stun", 2.0)
	e.apply_status(&"stun", 1.0)  # menor — debe mantener 2.0
	assert_almost_eq(e.get_status_time_left(&"stun"), 2.0, 0.01, "refresh-to-max, no suma ni reduce")


func test_enemy_weak_reduces_outgoing_damage() -> void:
	var e := _make_enemy()
	assert_eq(e.outgoing_damage_mult(), 1.0, "sin weak = mult 1")
	e.apply_status(&"weak", 5.0)
	assert_almost_eq(e.outgoing_damage_mult(), 0.75, 0.01, "weak = −25% saliente")


func test_enemy_bleed_ticks_damage() -> void:
	var e := _make_enemy()
	e.apply_status(&"bleed", 5.0, player)
	var hp_before: float = e.health
	# tick_timer empieza en 1.0, tras 1.1s dispara 1 tick
	e._tick_statuses(1.1)
	assert_lt(e.health, hp_before, "bleed aplicó tick dmg")


func test_enemy_bleed_removes_after_duration() -> void:
	var e := _make_enemy()
	e.apply_status(&"bleed", 2.0, player)
	# Simular 2.5s en chunks de 1s (para permitir ticks)
	e._tick_statuses(1.0)
	e._tick_statuses(1.0)
	e._tick_statuses(0.5)
	assert_false(e.has_status(&"bleed"), "bleed expira post-duración")


# ─── SkillDB registra los 4 canon al autoload ───

func test_skill_db_has_all_4_warrior_canon() -> void:
	var db = get_node_or_null("/root/SkillDB")
	if db == null:
		pending("SkillDB autoload no disponible en contexto test")
		return
	assert_true(db.has_skill(&"warrior_punch"))
	assert_true(db.has_skill(&"warrior_charge"))
	assert_true(db.has_skill(&"warrior_war_cry"))
	assert_true(db.has_skill(&"warrior_perfect_block"))
