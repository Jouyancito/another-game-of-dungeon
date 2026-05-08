extends GutTest

# Test regresión bug 2026-04-29 — Lluvia de Flechas no aplicaba daño.
# Root cause: arrow_storm.tres tenía cast_type=1 (TOGGLE) que solo aplica auras
# de debuff, no daño. CHANNELED=2 llama _apply_skill_to_targets per-tick.
# Además secondary_resource_cost=30 CONC bloqueaba (Archer arranca con 0).
#
# Si alguien re-edita el .tres y rompe estos invariantes, este test falla.

const ARROW_STORM_PATH := "res://shared/skills/resources/archer/arrow_storm.tres"


func test_arrow_storm_is_channeled_not_toggle() -> void:
	var s: SkillResource = load(ARROW_STORM_PATH)
	assert_not_null(s, "arrow_storm.tres debe cargar")
	# CRÍTICO: enum order es { INSTANT=0, CHANNELED=1, TOGGLE=2, PASSIVE=3, CHARGED=4 }.
	# El .tres con cast_type=2 (lo que parecía intuitivo "CHANNELED") iba realmente
	# a TOGGLE → _apply_aura_enemy_debuff, que retorna sin daño si status_applied=[].
	# Bug 2026-04-29 se "fixó" mal: 1→2 pensando que era CHANNELED. Re-fix 2026-05-07: 2→1.
	assert_eq(
		s.cast_type,
		SkillResource.CastType.CHANNELED,
		"cast_type debe ser CHANNELED (=1) — TOGGLE (=2) o INSTANT (=0) no aplican damage per-tick AOE"
	)


func test_arrow_storm_has_damage() -> void:
	var s: SkillResource = load(ARROW_STORM_PATH)
	assert_gt(s.base_damage, 0, "base_damage debe ser >0 — sino tick no hace daño")
	assert_ne(
		s.damage_formula,
		SkillResource.DamageFormulaType.NONE,
		"damage_formula debe estar seteada (PHYSICAL_V2) para que tick aplique daño"
	)


func test_arrow_storm_secondary_cost_does_not_block_at_zero_conc() -> void:
	# Archer arranca con 0 CONC y NO gana CONC al disparar (gap design).
	# Si secondary_resource_cost > 0 con CONCENTRACION, la skill nunca se puede castear.
	# TODO design: cuando se implemente gen CONC en arrow_projectile on_hit,
	#              restaurar canon CONC=30 en el .tres (issue #9 en sesión 2026-04-29).
	var s: SkillResource = load(ARROW_STORM_PATH)
	if s.secondary_resource_type == SkillResource.ResourceCostType.CONCENTRACION:
		assert_eq(
			s.secondary_resource_cost,
			0,
			"Mientras Archer no genere CONC, costo CONC debe ser 0 — sino skill bloqueada"
		)


func test_arrow_storm_has_tick_interval() -> void:
	# CHANNELED requiere tick_interval_s > 0 para que _process aplique daño per-tick.
	var s: SkillResource = load(ARROW_STORM_PATH)
	assert_gt(s.tick_interval_s, 0.0, "CHANNELED sin tick_interval no aplica damage")
