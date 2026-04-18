extends GutTest

# Tests P0 + P1 del audit de C (_framework_audit.md).
# G1 dual cost, G2 resource gen, G3 HP cost, G4 combo mult,
# G5 channeled tick, G9 invul, G10 summon, G11 quest-gate.

var player: BasePlayer
var skills: PlayerSkills
var resource: ClassResource  # genérico — tests setean type según lo que necesiten


func before_each() -> void:
	player = BasePlayer.new()
	player.str_stat = 12
	player.int_stat = 10
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
	resource = ClassResource.new()
	resource.type = ClassResource.Type.RAGE
	resource.max_value = 100
	skills.setup(player, resource)
	player.add_child(skills)
	player.add_child(resource)
	player.class_resource = resource
	player.skills = skills


func after_each() -> void:
	if is_instance_valid(player):
		player.free()


class MockEnemy extends Node3D:
	var health: float = 100.0
	var is_dead: bool = false
	var status_effects: Dictionary = {}
	var last_damage: float = 0.0

	func _init() -> void:
		add_to_group("enemies")

	func take_damage(amount: float, _dir: Vector3 = Vector3.ZERO, _kb: float = 0.0, _as: int = 0, _a = null) -> void:
		last_damage = amount
		health -= amount
		if health <= 0:
			is_dead = true

	func apply_status(name: StringName, duration: float) -> void:
		status_effects[name] = {"time_left": duration}

	func has_status(name: StringName) -> bool:
		return status_effects.has(name)


func _make_skill(id: StringName) -> SkillResource:
	var s := SkillResource.new()
	s.id = id
	s.class_id = &"test"
	s.cast_type = SkillResource.CastType.INSTANT
	s.target_type = SkillResource.TargetType.SINGLE_ENEMY
	s.range_m = 10.0
	s.damage_formula = SkillResource.DamageFormulaType.PHYSICAL_V2
	s.base_damage = 20
	return s


# ─── G1: Dual cost (MP + Rage) ───

func test_g1_dual_cost_succeeds_with_both_resources() -> void:
	var s := _make_skill(&"dual_cost_skill")
	s.resource_cost = 10
	s.resource_type = SkillResource.ResourceCostType.MP
	s.secondary_resource_cost = 15
	s.secondary_resource_type = SkillResource.ResourceCostType.RAGE
	skills.set_slot(0, s)
	resource.add(50)
	player.mana = 50.0
	# Target en rango
	var e := MockEnemy.new()
	player.add_child(e)
	e.global_position = player.global_position + Vector3(0, 0, -3)
	var ok: bool = skills.cast_slot(0)
	assert_true(ok)
	assert_eq(player.mana, 40.0, "MP primary consumido")
	assert_eq(resource.get_current(), 35, "Rage secondary consumido")


func test_g1_dual_cost_fails_if_secondary_missing() -> void:
	var s := _make_skill(&"dual_cost_skill")
	s.resource_cost = 10
	s.resource_type = SkillResource.ResourceCostType.MP
	s.secondary_resource_cost = 30
	s.secondary_resource_type = SkillResource.ResourceCostType.RAGE
	skills.set_slot(0, s)
	resource.add(10)  # insuficiente (30 requerido)
	player.mana = 50.0
	var ok: bool = skills.cast_slot(0)
	assert_false(ok)
	assert_eq(player.mana, 50.0, "primary NO consumido si secondary falla")
	assert_eq(resource.get_current(), 10, "secondary intacto")


func test_g1_rollback_primary_on_secondary_failure() -> void:
	# Caso edge: primary OK pero secondary se vacía entre check y pay.
	# Mi implementación valida TODO antes de pagar, así que este caso no ocurre.
	# Test documenta el invariante.
	var s := _make_skill(&"dual_cost_skill")
	s.resource_cost = 10
	s.resource_type = SkillResource.ResourceCostType.MP
	s.secondary_resource_cost = 15
	s.secondary_resource_type = SkillResource.ResourceCostType.RAGE
	skills.set_slot(0, s)
	player.mana = 5.0  # insuficiente primary
	resource.add(50)
	var ok: bool = skills.cast_slot(0)
	assert_false(ok)
	assert_eq(player.mana, 5.0, "sin consumir")
	assert_eq(resource.get_current(), 50, "sin consumir")


# ─── G2: Resource gen per-skill ───

func test_g2_gen_on_hit_applies_after_target_damage() -> void:
	var s := _make_skill(&"gen_test")
	s.resource_gen_on_hit = 5
	s.resource_gen_type = SkillResource.ResourceCostType.RAGE
	skills.set_slot(0, s)
	var e := MockEnemy.new()
	player.add_child(e)
	e.global_position = player.global_position + Vector3(0, 0, -3)
	skills.cast_slot(0)
	assert_eq(resource.get_current(), 5, "+5 Rage on hit")


func test_g2_gen_on_cast_applies_regardless_of_target() -> void:
	var s := _make_skill(&"gen_on_cast")
	s.target_type = SkillResource.TargetType.SELF
	s.damage_formula = SkillResource.DamageFormulaType.HEAL
	s.base_damage = 10
	s.resource_gen_on_cast = 3
	s.resource_gen_type = SkillResource.ResourceCostType.RAGE
	skills.set_slot(0, s)
	skills.cast_slot(0)
	assert_eq(resource.get_current(), 3, "+3 al castear (sin target requerido)")


func test_g2_gen_per_target_multiplies_by_hits() -> void:
	var s := _make_skill(&"gen_per_target")
	s.target_type = SkillResource.TargetType.CONE
	s.range_m = 5.0
	s.cone_angle_deg = 120.0  # cono amplio para atrapar 3 enemies
	s.resource_gen_per_target = 2
	s.resource_gen_type = SkillResource.ResourceCostType.RAGE
	skills.set_slot(0, s)
	for i in 3:
		var e := MockEnemy.new()
		player.add_child(e)
		e.global_position = player.global_position + Vector3(i * 0.5 - 0.5, 0, -2)
	skills.cast_slot(0)
	# 3 targets * 2 Rage/target = 6
	assert_eq(resource.get_current(), 6, "+2 Rage × 3 targets")


# ─── G3: HP cost variants ───

func test_g3_fixed_hp_cost_subtracts_from_health() -> void:
	var s := _make_skill(&"hp_fixed")
	s.target_type = SkillResource.TargetType.SELF
	s.hp_cost_type = SkillResource.HpCostType.FIXED
	s.hp_cost_value = 20.0
	skills.set_slot(0, s)
	var hp_before: float = player.health
	skills.cast_slot(0)
	assert_eq(player.health, hp_before - 20.0)


func test_g3_percent_hp_cost_uses_max() -> void:
	var s := _make_skill(&"hp_percent")
	s.target_type = SkillResource.TargetType.SELF
	s.hp_cost_type = SkillResource.HpCostType.PERCENT_MAX
	s.hp_cost_value = 0.1  # 10% de max_health
	skills.set_slot(0, s)
	var expected_cost: float = player.max_health * 0.1
	var hp_before: float = player.health
	skills.cast_slot(0)
	assert_almost_eq(player.health, hp_before - expected_cost, 0.01)


func test_g3_hp_cost_fails_if_would_kill() -> void:
	var s := _make_skill(&"hp_fixed")
	s.target_type = SkillResource.TargetType.SELF
	s.hp_cost_type = SkillResource.HpCostType.FIXED
	s.hp_cost_value = 200.0  # más que max_health
	skills.set_slot(0, s)
	var ok: bool = skills.cast_slot(0)
	assert_false(ok, "cast falla si HP cost mataría")
	assert_gt(player.health, 0.0, "HP no se toca")


func test_g3_drain_per_second_toggle_decreases_hp() -> void:
	var s := _make_skill(&"hp_drain")
	s.cast_type = SkillResource.CastType.TOGGLE
	s.target_type = SkillResource.TargetType.AOE
	s.radius_m = 5.0
	s.tick_interval_s = 1.0
	s.hp_cost_type = SkillResource.HpCostType.DRAIN_PER_SECOND
	s.hp_cost_value = 5.0  # 5 HP/s
	skills.set_slot(0, s)
	var hp_before: float = player.health
	skills.cast_slot(0)  # activar
	skills._process(2.0)  # 2 segundos — 10 HP drenados
	assert_almost_eq(player.health, hp_before - 10.0, 0.1, "DRAIN_PER_SECOND × 2s = 10 HP")


# ─── G4: Combo damage multiplier ───

func test_g4_combo_multiplier_scales_damage_by_points() -> void:
	# Cambiar resource a COMBO
	resource.type = ClassResource.Type.COMBO
	resource.max_value = 5
	var s := _make_skill(&"finisher")
	s.combo_damage_multipliers = PackedFloat32Array([1.0, 1.4, 1.8, 2.4, 3.0])
	s.combo_consume_all = true
	skills.set_slot(0, s)
	resource.add(3)  # 3 combo points
	var e := MockEnemy.new()
	player.add_child(e)
	e.global_position = player.global_position + Vector3(0, 0, -3)
	skills.cast_slot(0)
	# 3 points → idx 2 → mult 1.8
	# get_physical_damage(20) = 20 + 12*2 = 44. × 1.8 = 79.2
	assert_almost_eq(e.last_damage, 79.2, 0.1)
	assert_eq(resource.get_current(), 0, "consume_all vació el pool")


func test_g4_combo_without_points_uses_base_damage() -> void:
	resource.type = ClassResource.Type.COMBO
	var s := _make_skill(&"finisher_empty")
	s.combo_damage_multipliers = PackedFloat32Array([1.0, 1.4, 1.8])
	skills.set_slot(0, s)
	# Sin combo points — mult no aplica
	var e := MockEnemy.new()
	player.add_child(e)
	e.global_position = player.global_position + Vector3(0, 0, -3)
	skills.cast_slot(0)
	# Daño base 20 + (12*2) = 44
	assert_almost_eq(e.last_damage, 44.0, 0.01)


# ─── G5: Channeled tick ───

func test_g5_channeled_tick_damages_per_interval() -> void:
	var s := _make_skill(&"channeled_test")
	s.cast_type = SkillResource.CastType.CHANNELED
	s.target_type = SkillResource.TargetType.SINGLE_ENEMY
	s.tick_interval_s = 0.5
	s.tick_resource_cost = 0
	s.base_damage = 10
	skills.set_slot(0, s)
	var e := MockEnemy.new()
	player.add_child(e)
	e.global_position = player.global_position + Vector3(0, 0, -3)
	skills.cast_slot(0)  # activar channel
	# Tick immediate consumed primer 0.5s? No — el tick_timer arranca en tick_interval_s.
	skills._process(0.6)  # pasa primer tick
	assert_gt(e.last_damage, 0.0, "primer tick aplicó damage")
	var dmg_after_first: float = e.last_damage
	skills._process(0.6)  # segundo tick
	# No podemos verificar acumulación porque mock recibe "last_damage" — solo el último.
	assert_true(skills.is_toggle_active(&"channeled_test"), "channel sigue activo")


func test_g5_channeled_drains_tick_resource_cost() -> void:
	var s := _make_skill(&"channeled_mp")
	s.cast_type = SkillResource.CastType.CHANNELED
	s.target_type = SkillResource.TargetType.SINGLE_ENEMY
	s.tick_interval_s = 0.5
	s.tick_resource_cost = 10
	s.resource_type = SkillResource.ResourceCostType.MP
	skills.set_slot(0, s)
	player.mana = 50.0
	skills.cast_slot(0)
	skills._process(0.6)
	assert_eq(player.mana, 40.0, "primer tick drena 10 MP")
	skills._process(0.6)
	assert_eq(player.mana, 30.0, "segundo tick drena 10 más")


func test_g5_channeled_stops_when_resource_out() -> void:
	var s := _make_skill(&"channeled_mp_out")
	s.cast_type = SkillResource.CastType.CHANNELED
	s.target_type = SkillResource.TargetType.SINGLE_ENEMY
	s.tick_interval_s = 0.5
	s.tick_resource_cost = 10
	s.resource_type = SkillResource.ResourceCostType.MP
	skills.set_slot(0, s)
	player.mana = 5.0
	skills.cast_slot(0)
	skills._process(0.6)  # drain falla, channel apaga
	assert_false(skills.is_toggle_active(&"channeled_mp_out"))


func test_g5_stop_channel_starts_cooldown() -> void:
	var s := _make_skill(&"channeled_cd")
	s.cast_type = SkillResource.CastType.CHANNELED
	s.target_type = SkillResource.TargetType.SINGLE_ENEMY
	s.tick_interval_s = 0.5
	s.cooldown_s = 5.0
	skills.set_slot(0, s)
	skills.cast_slot(0)
	skills.stop_channel(&"channeled_cd")
	assert_false(skills.is_toggle_active(&"channeled_cd"))
	assert_almost_eq(skills.get_cooldown(&"channeled_cd"), 5.0, 0.01, "stop_channel arranca cooldown")


# ─── G9: Invul frames ───

func test_g9_invul_blocks_damage_during_window() -> void:
	var s := _make_skill(&"dash_with_invul")
	s.target_type = SkillResource.TargetType.SELF
	s.invul_duration_s = 0.5
	skills.set_slot(0, s)
	var hp_before: float = player.health
	skills.cast_slot(0)
	assert_true(player.has_meta("invul_time_left"))
	# Intentar damage durante ventana
	player.take_damage(50.0)
	assert_eq(player.health, hp_before, "daño bloqueado en ventana invul")


func test_g9_invul_expires_after_duration() -> void:
	var s := _make_skill(&"dash_invul")
	s.target_type = SkillResource.TargetType.SELF
	s.invul_duration_s = 0.3
	skills.set_slot(0, s)
	skills.cast_slot(0)
	skills._process(0.4)  # expirar ventana
	assert_false(player.has_meta("invul_time_left"))
	var hp_before: float = player.health
	player.take_damage(20.0)
	assert_lt(player.health, hp_before, "daño aplica post-ventana")


# ─── G10: SummonResource ───

func test_g10_summon_resource_eval_formula() -> void:
	var result: float = SummonResource.eval_formula("INT * 5 + level * 10", player)
	# INT=10, level=1 → 10*5 + 1*10 = 60
	assert_eq(result, 60.0)


func test_g10_summon_formula_handles_zero() -> void:
	var result: float = SummonResource.eval_formula("STR - 100", player)
	assert_eq(result, -88.0, "formula con negativos OK")  # 12 - 100


func test_g10_summon_invalid_formula_returns_zero() -> void:
	var result: float = SummonResource.eval_formula("INVALID SYNTAX ^^", player)
	assert_eq(result, 0.0)


# ─── G11: Quest-gated unlock ───

func test_g11_quest_gated_skill_blocked_without_completion() -> void:
	var s := _make_skill(&"ascendance_skill")
	s.quest_gate = &"muro_inquebrantable"
	skills.set_slot(0, s)
	watch_signals(skills)
	var ok: bool = skills.cast_slot(0)
	assert_false(ok, "skill bloqueada sin quest")
	# Verify reason = "quest_locked"
	var params = get_signal_parameters(skills, "skill_cast", 0)
	assert_eq(params[2], "quest_locked")


func test_g11_no_quest_gate_allows_cast() -> void:
	var s := _make_skill(&"no_gate")
	s.quest_gate = &""  # sin gate
	skills.set_slot(0, s)
	var e := MockEnemy.new()
	player.add_child(e)
	e.global_position = player.global_position + Vector3(0, 0, -3)
	var ok: bool = skills.cast_slot(0)
	assert_true(ok)


# ─── StatusCatalog validator ───

func test_status_catalog_canon_statuses_valid() -> void:
	assert_true(StatusCatalog.is_valid(&"stun"))
	assert_true(StatusCatalog.is_valid(&"bleed"))
	assert_true(StatusCatalog.is_valid(&"weak"))
	assert_true(StatusCatalog.is_valid(&"burn"))
	assert_true(StatusCatalog.is_valid(&"invul"))


func test_status_catalog_unknown_status_invalid() -> void:
	assert_false(StatusCatalog.is_valid(&"made_up_status"))


func test_status_catalog_implemented_subset() -> void:
	assert_true(StatusCatalog.is_implemented(&"stun"))
	assert_true(StatusCatalog.is_implemented(&"bleed"))
	assert_true(StatusCatalog.is_implemented(&"weak"))
	assert_false(StatusCatalog.is_implemented(&"burn"), "burn canon pero sin runtime Fase 1")


# ─── Migración Warrior .tres — G2 fields ───

func test_punch_tres_has_resource_gen_on_hit_5_rage() -> void:
	var s: SkillResource = load("res://shared/skills/resources/warrior/punch.tres")
	assert_not_null(s)
	assert_eq(s.resource_gen_on_hit, 5)
	assert_eq(s.resource_gen_type, SkillResource.ResourceCostType.RAGE)


func test_perfect_block_tres_has_resource_gen_on_cast_10() -> void:
	var s: SkillResource = load("res://shared/skills/resources/warrior/perfect_block.tres")
	assert_not_null(s)
	assert_eq(s.resource_gen_on_cast, 10)
	assert_eq(s.resource_gen_type, SkillResource.ResourceCostType.RAGE)
