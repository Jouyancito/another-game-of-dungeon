extends GutTest

# Tests de Fase 1 — 4 skills canon Mage (mage.md §3 v2.0).

# ─── Canon .tres cargan valores exactos de mage.md §3 ───

func test_unstable_orb_tres_canon_values() -> void:
	var s: SkillResource = load("res://shared/skills/resources/mage/unstable_orb.tres")
	assert_not_null(s)
	assert_eq(s.id, &"mage_unstable_orb")
	assert_eq(s.class_id, &"mage")
	assert_eq(s.resource_cost, 8)
	assert_eq(s.resource_type, SkillResource.ResourceCostType.MP)
	assert_eq(s.cooldown_s, 0.4)
	assert_eq(s.base_damage, 18)
	assert_eq(s.damage_formula, SkillResource.DamageFormulaType.MAGIC_V2)
	assert_eq(s.radius_m, 1.0, "AOE_SMALL 1m explotar")
	assert_eq(s.unlock_level, 1)
	assert_true(s.tags.has(&"magic"))
	assert_true(s.tags.has(&"projectile"))


func test_arcane_storm_tres_canon_values() -> void:
	var s: SkillResource = load("res://shared/skills/resources/mage/arcane_storm.tres")
	assert_not_null(s)
	assert_eq(s.id, &"mage_arcane_storm")
	assert_eq(s.cast_type, SkillResource.CastType.CHANNELED)
	assert_eq(s.cooldown_s, 3.0)
	assert_eq(s.base_damage, 6)
	assert_eq(s.tick_interval_s, 0.25)
	assert_eq(s.tick_resource_cost, 5, "5 MP/tick = 20 MP/s canon")
	assert_eq(s.range_m, 8.0)
	assert_eq(s.cone_angle_deg, 45.0)
	assert_eq(s.unlock_level, 4)
	assert_true(s.tags.has(&"channel"))


func test_prismatic_barrier_tres_canon_values() -> void:
	var s: SkillResource = load("res://shared/skills/resources/mage/prismatic_barrier.tres")
	assert_not_null(s)
	assert_eq(s.id, &"mage_prismatic_barrier")
	assert_eq(s.target_type, SkillResource.TargetType.SELF)
	assert_eq(s.resource_cost, 25)
	assert_eq(s.cooldown_s, 15.0)
	assert_eq(s.status_duration_s, 6.0)
	assert_true(s.status_applied.has(&"shield"))
	assert_eq(s.base_damage, 80, "absorb placeholder = 80 + INT*3 (sistema shield futuro)")
	assert_eq(s.unlock_level, 8)


func test_supernova_tres_canon_values() -> void:
	var s: SkillResource = load("res://shared/skills/resources/mage/supernova.tres")
	assert_not_null(s)
	assert_eq(s.id, &"mage_supernova")
	assert_eq(s.target_type, SkillResource.TargetType.AOE)
	assert_eq(s.resource_cost, 70)
	assert_eq(s.cooldown_s, 120.0)
	assert_eq(s.radius_m, 10.0, "AOE_LARGE 10m")
	assert_eq(s.base_damage, 200)
	assert_eq(s.damage_formula, SkillResource.DamageFormulaType.MAGIC_V2)
	assert_eq(s.unlock_level, 12)
	assert_true(s.tags.has(&"ultimate"))


# ─── SkillDB registra los 4 canon al autoload ───

func test_skill_db_has_all_4_mage_canon() -> void:
	var db = get_node_or_null("/root/SkillDB")
	if db == null:
		pending("SkillDB autoload no disponible en contexto test")
		return
	assert_true(db.has_skill(&"mage_unstable_orb"))
	assert_true(db.has_skill(&"mage_arcane_storm"))
	assert_true(db.has_skill(&"mage_prismatic_barrier"))
	assert_true(db.has_skill(&"mage_supernova"))


# ─── Sanity: SkillDB filtra _archive/ (shield_bash.tres zombie) ───

func test_skill_db_does_not_load_archived_skills() -> void:
	var db = get_node_or_null("/root/SkillDB")
	if db == null:
		pending("SkillDB autoload no disponible en contexto test")
		return
	# shield_bash.tres está en _archive/ — NO debe estar registrado
	assert_false(db.has_skill(&"warrior_shield_bash"), "shield_bash archivado no debe registrarse")
