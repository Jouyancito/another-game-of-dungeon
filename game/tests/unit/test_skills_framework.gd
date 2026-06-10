extends GutTest

# Tests del framework de skills — issue Fase 0.
# Valida SkillResource carga, PlayerSkills.cast_slot flow, ClassResource (Rage), cooldowns.

var player: BasePlayer
var skills: PlayerSkills
var rage: ClassResource


func before_each() -> void:
	player = BasePlayer.new()
	# Add to tree BEFORE positioning mock enemies so global_position works.
	add_child_autofree(player)
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
	# Montar skills + rage manualmente (normalmente via _ready → _setup_skills)
	skills = PlayerSkills.new()
	rage = ClassResource.new()
	rage.type = ClassResource.Type.RAGE
	rage.max_value = 100
	rage.combat_decay_rate = 5.0
	rage.decay_delay_s = 8.0
	skills.setup(player, rage)
	player.add_child(skills)
	player.add_child(rage)
	player.class_resource = rage
	player.skills = skills


func after_each() -> void:
	pass  # add_child_autofree handles cleanup


func _make_shield_bash() -> SkillResource:
	# Stub for the shield_bash behavior. Uses CONE targeting (360° wide) so that
	# MockEnemy nodes are found via geometry (get_nodes_in_group + distance), NOT
	# raycast. SINGLE_ENEMY uses a raycast-only path that requires physics colliders;
	# MockEnemy is a plain Node3D and will never be hit. Using a wide cone is the
	# correct test-harness pattern for geometry-only mock enemies.
	var s := SkillResource.new()
	s.id = &"warrior_shield_bash"
	s.class_id = &"warrior"
	s.display_name = "Embate de Escudo"
	s.cast_type = SkillResource.CastType.INSTANT
	s.target_type = SkillResource.TargetType.CONE
	s.range_m = 3.0
	s.cone_angle_deg = 360.0  # Full-sphere cone — picks up any enemy in range regardless of facing
	s.resource_cost = 15
	s.resource_type = SkillResource.ResourceCostType.RAGE
	s.cooldown_s = 6.0
	s.damage_formula = SkillResource.DamageFormulaType.PHYSICAL_V2
	s.base_damage = 25
	s.status_applied = [&"stun"] as Array[StringName]
	s.status_duration_s = 1.5
	return s


# ─── SkillResource ───

func test_skill_resource_holds_all_fields() -> void:
	var s := _make_shield_bash()
	assert_eq(s.id, &"warrior_shield_bash")
	assert_eq(s.resource_cost, 15)
	assert_eq(s.cooldown_s, 6.0)
	assert_eq(s.base_damage, 25)
	assert_eq(s.status_applied.size(), 1)
	assert_eq(s.status_applied[0], &"stun")


func test_shield_bash_tres_loads_from_disk() -> void:
	# shield_bash.tres is a runtime extra skill not in the Fase 1 canon .tres set.
	# Only punch/charge/war_cry/perfect_block are shipped (warrior.md §3).
	# This test guards that IF the file exists it has the right schema.
	var path := "res://shared/skills/resources/warrior/shield_bash.tres"
	if not ResourceLoader.exists(path):
		pending("shield_bash.tres not yet created — Fase 2 candidate")
		return
	var s: SkillResource = load(path)
	assert_not_null(s, ".tres carga")
	assert_eq(s.id, &"warrior_shield_bash")
	assert_eq(s.resource_type, SkillResource.ResourceCostType.RAGE)
	assert_eq(s.damage_formula, SkillResource.DamageFormulaType.PHYSICAL_V2)


# ─── ClassResource (Rage) ───

func test_rage_starts_at_zero() -> void:
	assert_eq(rage.get_current(), 0)


func test_rage_add_respects_cap() -> void:
	rage.add(60)
	assert_eq(rage.get_current(), 60)
	rage.add(80)  # total 140 teórico
	assert_eq(rage.get_current(), 100, "cap en max_value")


func test_rage_consume_returns_false_when_insufficient() -> void:
	rage.add(10)
	var ok: bool = rage.consume(15)
	assert_false(ok, "consume > current devuelve false")
	assert_eq(rage.get_current(), 10, "current no se modifica si falla")


func test_rage_consume_subtracts_when_sufficient() -> void:
	rage.add(50)
	var ok: bool = rage.consume(20)
	assert_true(ok)
	assert_eq(rage.get_current(), 30)


func test_rage_decays_out_of_combat() -> void:
	rage.add(50)
	rage._time_since_combat = 10.0  # ya fuera de combate (> decay_delay 8s)
	rage._process(1.0)              # 1s de decay @ 5/s
	assert_almost_eq(rage.current, 45.0, 0.01, "decay 5/s post-delay")


func test_rage_no_decay_within_delay() -> void:
	rage.add(50)
	rage._time_since_combat = 5.0   # dentro de delay (< 8s)
	rage._process(1.0)
	assert_eq(rage.get_current(), 50, "sin decay dentro de delay")


# ─── PlayerSkills.cast_slot ───

func test_cast_slot_fails_when_slot_empty() -> void:
	var ok: bool = skills.cast_slot(0)
	assert_false(ok, "slot vacío — fail")


func test_cast_slot_fails_when_insufficient_resource() -> void:
	skills.set_slot(0, _make_shield_bash())
	# rage = 0, cost = 15 → fail
	watch_signals(skills)
	var ok: bool = skills.cast_slot(0)
	assert_false(ok)
	assert_eq(rage.get_current(), 0, "recurso NO se consume si falla")
	assert_signal_emit_count(skills, "skill_cast", 1)


func test_cast_slot_succeeds_with_resource() -> void:
	skills.set_slot(0, _make_shield_bash())
	rage.add(20)
	var ok: bool = skills.cast_slot(0)
	assert_true(ok)
	assert_eq(rage.get_current(), 5, "20 - 15 = 5")
	assert_almost_eq(skills.get_cooldown(&"warrior_shield_bash"), 6.0, 0.01, "cooldown seteado")


func test_cast_slot_fails_when_cooldown_active() -> void:
	skills.set_slot(0, _make_shield_bash())
	rage.add(50)
	skills.cast_slot(0)  # primer cast — ok, consume 15, rage=35
	var rage_before_second: int = rage.get_current()
	var ok: bool = skills.cast_slot(0)  # segundo — cooldown activo
	assert_false(ok)
	assert_eq(rage.get_current(), rage_before_second, "segundo cast no consume")


func test_cooldown_decreases_over_time() -> void:
	skills.set_slot(0, _make_shield_bash())
	rage.add(20)
	skills.cast_slot(0)
	assert_almost_eq(skills.get_cooldown(&"warrior_shield_bash"), 6.0, 0.01)
	skills._process(2.0)
	assert_almost_eq(skills.get_cooldown(&"warrior_shield_bash"), 4.0, 0.01)
	skills._process(5.0)  # pasa total 7s > 6
	assert_eq(skills.get_cooldown(&"warrior_shield_bash"), 0.0, "cooldown expira y se limpia")


# ─── Damage + status application vs mock enemy ───

class MockEnemy extends Node3D:
	var health: float = 100.0
	var is_dead: bool = false
	var last_damage: float = 0.0
	var last_attacker_str: int = 0
	var status_applied: Dictionary = {}  # name → duration

	func _init() -> void:
		add_to_group("enemies")

	func take_damage(amount: float, _dir: Vector3, _kb: float, attacker_str: int, _attacker) -> void:
		last_damage = amount
		last_attacker_str = attacker_str
		health -= amount
		if health <= 0:
			is_dead = true

	func apply_status(status: StringName, duration: float) -> void:
		status_applied[status] = duration


func test_cast_applies_physical_damage_to_target() -> void:
	var mock := MockEnemy.new()
	player.add_child(mock)
	# Place 2m in front of player. Player faces -Z by default, so front is -Z direction.
	# CONE (360°) targeting uses geometry — no physics collider needed.
	mock.global_position = player.global_position + Vector3(0, 0, -2.0)
	skills.set_slot(0, _make_shield_bash())
	rage.add(20)

	skills.cast_slot(0)
	# physical_v2(25, weapon=0, STR=12, level=1, class_mult=1.0):
	#   stat_mult = 1 + 12*0.02 = 1.24, level_mult = 1 + 1*0.03 = 1.03
	#   25 * 1.24 * 1.03 = 31.93 → with class_mult_physical=1.0 → 31.93
	# NOTE: class_mult_physical defaults to 1.0 for BasePlayer.new() (no class scene).
	# canonical warrior uses 1.5 but this test uses BasePlayer directly.
	var expected_dmg := DamageFormula.physical_v2(25.0, 0, 12, 1, 1.0)
	assert_almost_eq(mock.last_damage, expected_dmg, 0.05, "physical_v2(25, STR=12, weapon=0, class_mult=1.0)")
	assert_eq(mock.last_attacker_str, 12, "attacker_str pasado correctamente")


func test_cast_applies_stun_status_to_target() -> void:
	var mock := MockEnemy.new()
	player.add_child(mock)
	mock.global_position = player.global_position + Vector3(0, 0, -2.0)
	skills.set_slot(0, _make_shield_bash())
	rage.add(20)

	skills.cast_slot(0)
	assert_true(mock.status_applied.has(&"stun"), "stun aplicado")
	assert_almost_eq(mock.status_applied[&"stun"], 1.5, 0.01, "duración 1.5s")


func test_cast_skips_target_out_of_range() -> void:
	var mock := MockEnemy.new()
	player.add_child(mock)
	mock.global_position = player.global_position + Vector3(0, 0, -10.0)  # fuera del range 3m
	skills.set_slot(0, _make_shield_bash())
	rage.add(20)
	skills.cast_slot(0)
	# No target adquirido — sin daño. Recurso ya consumido (decisión de diseño:
	# el cast "whiff" castiga gasto para evitar spam free). Confirmamos comportamiento.
	assert_eq(mock.last_damage, 0.0, "fuera de rango → sin daño")


# ─── Rage gen por damage recibido ───

func test_rage_gains_from_damage_taken() -> void:
	assert_eq(rage.get_current(), 0)
	# Canon balance_v2 §2.5: apply_physical_defense(30, atk_lvl=1) = 30 * (1 - DEF/(DEF+50))
	# DEF=10 → 30 * (1 - 10/60) = 30 * 50/60 ≈ 25.0
	# Rage formula canon _system.md §5ter: int(final_dmg / max_health * 100)
	# max_health = Progression.max_health_v2(100, VIT=10, lvl=1) ≈ 173.96
	# rage = int(25.0 / 173.96 * 100) = int(14.37) = 14
	var final_dmg: float = DamageFormula.apply_armor_v2(30.0, 10, 1)
	var expected_rage: int = int(final_dmg / player.max_health * 100.0)
	player.take_damage(30.0)
	assert_eq(rage.get_current(), expected_rage, "Rage gained = int(final_dmg/max_health*100)")
