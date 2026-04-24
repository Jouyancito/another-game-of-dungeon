extends GutTest

# Tests de Fase 1 — Danzante de Sombras.
# Cobertura inicial (wave3 combo-fix-vfx 2026-04-24):
# - Fix Auditor 2 CRITICAL: skills INSTANT con combo_consume_all=true consumen
#   combo PRE-cálculo de daño (no después). Valida orden + atomicidad.
# - Comportamientos derivados: mult correcto por combo points, recurso a 0 post-cast,
#   combo consumido aunque no haya target (commit-on-cast, no commit-on-hit).

var player: BasePlayer
var skills: PlayerSkills
var combo: ClassResource


func before_each() -> void:
	player = BasePlayer.new()
	player.str_stat = 6
	player.int_stat = 5
	player.dex_stat = 14  # DEX primario Danzante
	player.def_stat = 5
	player.vit_stat = 7
	player.base_health = 100.0
	player.base_mana = 80.0
	player.inventory = Inventory.new()
	player.equipment = Equipment.new()
	player.recalculate_stats()
	player.health = player.max_health
	player.mana = player.max_mana
	skills = PlayerSkills.new()
	combo = ClassResource.new()
	combo.type = ClassResource.Type.COMBO
	combo.max_value = 5  # Danzante cap canon 5 combo points
	combo.combat_decay_rate = 0.0  # no decay en tests
	skills.setup(player, combo)
	player.add_child(skills)
	player.add_child(combo)
	player.class_resource = combo
	player.skills = skills


func after_each() -> void:
	if is_instance_valid(player):
		player.free()


# ─── Mock enemy reutilizable ───

class MockEnemy extends Node3D:
	var health: float = 1000.0
	var is_dead: bool = false
	var last_damage: float = 0.0

	func _init() -> void:
		add_to_group("enemies")

	func take_damage(amount: float, _dir: Vector3, _kb: float, _attacker_str: int, _attacker) -> void:
		last_damage = amount
		health -= amount
		if health <= 0:
			is_dead = true

	func apply_status(_name: StringName, _duration: float) -> void:
		pass


# ─── Skill stub: finisher INSTANT + combo_consume_all ───

func _make_finisher_skill() -> SkillResource:
	# Proxy de danzante_thousand_shadows: INSTANT single-enemy, mult escalante por combo.
	var s := SkillResource.new()
	s.id = &"danzante_thousand_shadows_stub"
	s.class_id = &"danzante"
	s.cast_type = SkillResource.CastType.INSTANT
	s.target_type = SkillResource.TargetType.SINGLE_ENEMY
	s.range_m = 5.0
	s.resource_cost = 0
	s.resource_type = SkillResource.ResourceCostType.NONE
	s.cooldown_s = 0.0
	s.damage_formula = SkillResource.DamageFormulaType.TRUE_DAMAGE  # base puro, sin stats
	s.base_damage = 10
	s.combo_consume_all = true
	# Mult por puntos: 1 → 1.5x, 2 → 2.0x, 3 → 3.0x, 4 → 4.0x, 5 → 5.5x
	s.combo_damage_multipliers = PackedFloat32Array([1.5, 2.0, 3.0, 4.0, 5.5])
	return s


# ─── Fix combo pre-consume: orden correcto mult → consume ───

func test_finisher_with_3_combo_deals_3x_base_damage() -> void:
	var finisher := _make_finisher_skill()
	skills.set_slot(0, finisher)
	combo.add(3)
	var enemy := MockEnemy.new()
	player.add_child(enemy)
	enemy.global_position = player.global_position + Vector3(0, 0, -2.0)
	skills.cast_slot(0)
	# base 10 * mult[2]=3.0 → 30 de daño
	assert_eq(enemy.last_damage, 30.0, "daño = base 10 × combo mult 3 puntos (3.0x)")


func test_finisher_consumes_all_combo_points_after_cast() -> void:
	var finisher := _make_finisher_skill()
	skills.set_slot(0, finisher)
	combo.add(4)
	var enemy := MockEnemy.new()
	player.add_child(enemy)
	enemy.global_position = player.global_position + Vector3(0, 0, -2.0)
	skills.cast_slot(0)
	assert_eq(combo.get_current(), 0, "combo pool vaciado después de finisher")


func test_finisher_mult_scales_with_each_combo_tier() -> void:
	var finisher := _make_finisher_skill()
	skills.set_slot(0, finisher)
	# Probar los 5 tiers de combo en secuencia fresca — mult debe escalar exacto.
	var expected: Array = [15.0, 20.0, 30.0, 40.0, 55.0]  # base 10 × [1.5, 2.0, 3.0, 4.0, 5.5]
	for points in range(1, 6):
		combo.add(points)  # start from 0, set to `points`
		var enemy := MockEnemy.new()
		player.add_child(enemy)
		enemy.global_position = player.global_position + Vector3(0, 0, -2.0)
		skills.cast_slot(0)
		assert_eq(enemy.last_damage, expected[points - 1], \
			"tier %d combo points → %.1f dmg" % [points, expected[points - 1]])
		# combo ya se consumió en cast_slot — reset limpio para próxima iteración
		assert_eq(combo.get_current(), 0, "combo consumido post-cast tier %d" % points)
		# Free sync para evitar que el enemy persista y contamine la próxima iteración
		enemy.free()


# ─── Fix clave: combo consumido aunque no haya target (commit-on-cast) ───

func test_finisher_consumes_combo_even_without_target() -> void:
	# Sin enemy en rango — _execute_single_enemy retorna early pero el combo
	# ya debe haber sido consumido en _pre_consume_combo (dispatch atómico).
	var finisher := _make_finisher_skill()
	skills.set_slot(0, finisher)
	combo.add(3)
	# No spawneamos enemy — acquire_target retornará null.
	skills.cast_slot(0)
	assert_eq(combo.get_current(), 0, \
		"combo consumido aunque no haya target (commit-on-cast, no commit-on-hit)")


# ─── Guard: sin combo_consume_all, el recurso se mantiene ───

func test_non_consume_skill_keeps_combo() -> void:
	var skill := _make_finisher_skill()
	skill.combo_consume_all = false  # ahora es builder, no finisher
	skills.set_slot(0, skill)
	combo.add(3)
	var enemy := MockEnemy.new()
	player.add_child(enemy)
	enemy.global_position = player.global_position + Vector3(0, 0, -2.0)
	skills.cast_slot(0)
	# Mult igual se aplica (base 10 × 3.0 = 30), pero combo intacto.
	assert_eq(enemy.last_damage, 30.0, "mult combo aplica aunque no consume")
	assert_eq(combo.get_current(), 3, "combo intacto sin combo_consume_all")


# ─── Guard: sin combo points, finisher dispara sin bonus pero consume nothing ───

func test_finisher_with_zero_combo_deals_base_damage_no_mult() -> void:
	var finisher := _make_finisher_skill()
	skills.set_slot(0, finisher)
	# combo = 0 de entrada
	var enemy := MockEnemy.new()
	player.add_child(enemy)
	enemy.global_position = player.global_position + Vector3(0, 0, -2.0)
	skills.cast_slot(0)
	assert_eq(enemy.last_damage, 10.0, "sin combo = base damage puro (mult 1.0)")
	assert_eq(combo.get_current(), 0, "combo sigue en 0")


# ─── Sanity: VFX hooks Danzante flaggeados como TODO ───

func test_danzante_vfx_todo_entries_declared() -> void:
	# Audit W1: DANZANTE_VFX_TODO debe listar los 4 paths canon esperados
	# para que B pueda wirear handlers cuando D cree los .tscn.
	var expected := [
		&"danzante_swift_cut",
		&"danzante_shadow_step",
		&"danzante_night_veil",
		&"danzante_thousand_shadows",
	]
	for skill_id in expected:
		assert_true(SkillVFXHooks.DANZANTE_VFX_TODO.has(skill_id), \
			"DANZANTE_VFX_TODO lista '%s' como TODO a crear por D" % skill_id)
