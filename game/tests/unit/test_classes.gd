extends GutTest

# Tests for the 6 player classes — verify initial stats and configuration.
# Each class calls _on_class_ready() in _ready(), but because we cannot
# add to the SceneTree without a full scene, we call _on_class_ready() manually.
#
# IMPORTANT: _load_character_stats() reads GameManager.selected_class_scene to
# determine which ClassBaseStats.DEFAULTS entry to use.  We must set that path
# BEFORE adding the instance to the tree so _ready() picks up the right stats.
#
# HP/MP expectations use canon balance_v2 §2.1-2.2 (Progression.max_health_v2 /
# max_mana_v2). Damage expectations use balance_v2 §2.3-2.4 (DamageFormula.physical_v2 /
# magic_v2) with each class's class_mult value:
#   Warrior:      class_mult_physical = 1.5
#   Mage:         class_mult_magic    = 1.5
#   Archer:       uses DamageFormula.dex() (legacy, unchanged)
#   Necromancer:  class_mult_magic    = 1.3
#   Cleric:       class_mult_magic    = 1.2
#   Danzante:     class_mult_physical = 1.2 (combo-based)

# ─── Helpers ───

func _create_player(scene_path: String) -> BasePlayer:
	# Point GameManager at this scene BEFORE instantiation so _load_character_stats()
	# reads the correct ClassBaseStats.DEFAULTS entry.
	GameManager.selected_class_scene = scene_path
	GameManager.selected_character_index = -1
	var tscn_path = scene_path  # scene_path already ends in .tscn
	var scene = load(tscn_path)
	var instance = scene.instantiate()
	return instance


func _free_player(p: BasePlayer) -> void:
	if is_instance_valid(p):
		p.queue_free()


# ═══════════════════════════════════════════
# WARRIOR
# ═══════════════════════════════════════════

func test_warrior_stats() -> void:
	var p = _create_player("res://scenes/player/player.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.str_stat, 12, "Warrior STR")
	assert_eq(p.int_stat, 3, "Warrior INT")
	assert_eq(p.dex_stat, 6, "Warrior DEX")
	assert_eq(p.def_stat, 10, "Warrior DEF")
	assert_eq(p.vit_stat, 10, "Warrior VIT")


func test_warrior_health_mana() -> void:
	var p = _create_player("res://scenes/player/player.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	# Canon balance_v2 §2.1: max_health_v2(100, VIT=10, level=1)
	#   = 100 + 10*5 + 10^1.3*0.8 + 1*8 = 100 + 50 + 15.96 + 8 ≈ 173.96
	var expected_hp := Progression.max_health_v2(100.0, 10, 1)
	assert_almost_eq(p.max_health, expected_hp, 0.01, "Warrior max HP (v2)")
	assert_almost_eq(p.health, expected_hp, 0.01, "Warrior starts at full HP")
	# Canon balance_v2 §2.2: max_mana_v2(80, INT=3, level=1)
	#   = 80 + 3*3 + 3^1.2*0.5 + 1*5 ≈ 95.87
	var expected_mp := Progression.max_mana_v2(80.0, 3, 1)
	assert_almost_eq(p.max_mana, expected_mp, 0.01, "Warrior max MP (v2)")
	assert_almost_eq(p.mana, expected_mp, 0.01, "Warrior starts at full MP")


func test_warrior_speed() -> void:
	var p = _create_player("res://scenes/player/player.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.speed, 5.0, "Warrior speed")
	assert_eq(p.sprint_speed, 8.0, "Warrior sprint")
	assert_eq(p.crouch_speed, 2.5, "Warrior crouch")


func test_warrior_combat() -> void:
	var p = _create_player("res://scenes/player/player.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.attack_range, 3.0, "Warrior melee range")
	assert_eq(p.heavy_cooldown, 0.6, "Warrior heavy cooldown")


func test_warrior_damage_formula() -> void:
	var p = _create_player("res://scenes/player/player.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	# Canon balance_v2 §2.3: physical_v2(base, weapon=0, STR=12, level=1, class_mult=1.5)
	#   stat_mult = 1 + 12*0.02 = 1.24
	#   level_mult = 1 + 1*0.03 = 1.03
	#   heavy: 35 * 1.24 * 1.03 * 1.5 = 67.053
	var expected_heavy := DamageFormula.physical_v2(35.0, 0, 12, 1, 1.5)
	assert_almost_eq(p.get_physical_damage(35.0), expected_heavy, 0.01, "Heavy punch damage (v2)")
	# combo: 15 * 1.24 * 1.03 * 1.5 = 28.737
	var expected_combo := DamageFormula.physical_v2(15.0, 0, 12, 1, 1.5)
	assert_almost_eq(p.get_physical_damage(15.0), expected_combo, 0.01, "Combo punch damage (v2)")


# ═══════════════════════════════════════════
# MAGE
# ═══════════════════════════════════════════

func test_mage_stats() -> void:
	var p = _create_player("res://scenes/player/mage.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.str_stat, 4, "Mage STR")
	assert_eq(p.int_stat, 12, "Mage INT")
	assert_eq(p.dex_stat, 5, "Mage DEX")
	assert_eq(p.def_stat, 3, "Mage DEF")
	assert_eq(p.vit_stat, 5, "Mage VIT")


func test_mage_health_mana() -> void:
	var p = _create_player("res://scenes/player/mage.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	# Canon §2.1: max_health_v2(70, VIT=5, level=1) ≈ 109.48
	var expected_hp := Progression.max_health_v2(70.0, 5, 1)
	assert_almost_eq(p.max_health, expected_hp, 0.01, "Mage max HP (v2)")
	# Canon §2.2: max_mana_v2(120, INT=12, level=1) ≈ 170.86
	var expected_mp := Progression.max_mana_v2(120.0, 12, 1)
	assert_almost_eq(p.max_mana, expected_mp, 0.01, "Mage max MP (v2)")


func test_mage_speed() -> void:
	var p = _create_player("res://scenes/player/mage.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.speed, 4.5, "Mage speed")
	assert_eq(p.sprint_speed, 7.0, "Mage sprint")
	assert_eq(p.crouch_speed, 2.0, "Mage crouch")


func test_mage_resistances() -> void:
	var p = _create_player("res://scenes/player/mage.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_almost_eq(p.res_fire, 0.1, 0.001, "Mage fire res")
	assert_almost_eq(p.res_ice, 0.1, 0.001, "Mage ice res")
	assert_almost_eq(p.res_lightning, 0.1, 0.001, "Mage lightning res")


func test_mage_damage_formula() -> void:
	var p = _create_player("res://scenes/player/mage.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	# Canon §2.4: magic_v2(base, weapon=0, INT=12, level=1, class_mult=1.5)
	#   stat_mult = 1 + 12*0.02 = 1.24
	#   level_mult = 1 + 1*0.03 = 1.03
	#   proj: 25 * 1.24 * 1.03 * 1.5 = 47.895
	var expected_proj := DamageFormula.magic_v2(25.0, 0, 12, 1, 1.5)
	assert_almost_eq(p.get_magic_damage(25.0), expected_proj, 0.01, "Mage projectile damage (v2)")
	# beam: 8 * 1.24 * 1.03 * 1.5 = 15.326
	var expected_beam := DamageFormula.magic_v2(8.0, 0, 12, 1, 1.5)
	assert_almost_eq(p.get_magic_damage(8.0), expected_beam, 0.01, "Beam tick damage (v2)")


# ═══════════════════════════════════════════
# ARCHER
# ═══════════════════════════════════════════

func test_archer_stats() -> void:
	var p = _create_player("res://scenes/player/archer.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.str_stat, 5, "Archer STR")
	assert_eq(p.int_stat, 3, "Archer INT")
	assert_eq(p.dex_stat, 12, "Archer DEX")
	assert_eq(p.def_stat, 5, "Archer DEF")
	assert_eq(p.vit_stat, 7, "Archer VIT")


func test_archer_health_mana() -> void:
	var p = _create_player("res://scenes/player/archer.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	# Canon §2.1: max_health_v2(85, VIT=7, level=1) ≈ 138.04
	var expected_hp := Progression.max_health_v2(85.0, 7, 1)
	assert_almost_eq(p.max_health, expected_hp, 0.01, "Archer max HP (v2)")
	# Canon §2.2: max_mana_v2(70, INT=3, level=1) ≈ 85.87
	var expected_mp := Progression.max_mana_v2(70.0, 3, 1)
	assert_almost_eq(p.max_mana, expected_mp, 0.01, "Archer max MP (v2)")


func test_archer_speed() -> void:
	var p = _create_player("res://scenes/player/archer.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.speed, 5.5, "Archer speed (fastest)")
	assert_eq(p.sprint_speed, 9.0, "Archer sprint")
	assert_eq(p.crouch_speed, 2.5, "Archer crouch")


func test_archer_combat() -> void:
	var p = _create_player("res://scenes/player/archer.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.attack_range, 20.0, "Archer long range")
	assert_eq(p.heavy_cooldown, 0.7, "Archer shot cooldown")


func test_archer_damage_formula() -> void:
	var p = _create_player("res://scenes/player/archer.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	# Archer uses DamageFormula.dex() (legacy unchanged): base + weapon + DEX*2
	# Arrow: 20 + 0 + 12*2 = 44
	assert_eq(p.get_dex_damage(20.0), 44.0, "Arrow damage (dex legacy)")
	# Charged: 50 + 0 + 12*2 = 74
	assert_eq(p.get_dex_damage(50.0), 74.0, "Charged arrow damage (dex legacy)")


# ═══════════════════════════════════════════
# NECROMANCER
# ═══════════════════════════════════════════

func test_necromancer_stats() -> void:
	var p = _create_player("res://scenes/player/necromancer.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.str_stat, 3, "Necro STR")
	assert_eq(p.int_stat, 10, "Necro INT")
	assert_eq(p.dex_stat, 4, "Necro DEX")
	assert_eq(p.def_stat, 4, "Necro DEF")
	assert_eq(p.vit_stat, 6, "Necro VIT")


func test_necromancer_health_mana() -> void:
	var p = _create_player("res://scenes/player/necromancer.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	# Canon §2.1: max_health_v2(80, VIT=6, level=1) ≈ 126.22
	var expected_hp := Progression.max_health_v2(80.0, 6, 1)
	assert_almost_eq(p.max_health, expected_hp, 0.01, "Necro max HP (v2)")
	# Canon §2.2: max_mana_v2(110, INT=10, level=1) ≈ 152.92
	var expected_mp := Progression.max_mana_v2(110.0, 10, 1)
	assert_almost_eq(p.max_mana, expected_mp, 0.01, "Necro max MP (v2)")


func test_necromancer_speed() -> void:
	var p = _create_player("res://scenes/player/necromancer.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.speed, 4.5, "Necro speed")
	assert_eq(p.sprint_speed, 7.0, "Necro sprint")


func test_necromancer_damage_formula() -> void:
	var p = _create_player("res://scenes/player/necromancer.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	# Canon §2.4: magic_v2(base, weapon=0, INT=10, level=1, class_mult=1.3)
	#   stat_mult = 1 + 10*0.02 = 1.2
	#   level_mult = 1 + 1*0.03 = 1.03
	#   orb: 22 * 1.2 * 1.03 * 1.3 = 35.35
	var expected_orb := DamageFormula.magic_v2(22.0, 0, 10, 1, 1.3)
	assert_almost_eq(p.get_magic_damage(22.0), expected_orb, 0.01, "Dark orb damage (v2)")
	# drain: 6 * 1.2 * 1.03 * 1.3 = 9.64
	var expected_drain := DamageFormula.magic_v2(6.0, 0, 10, 1, 1.3)
	assert_almost_eq(p.get_magic_damage(6.0), expected_drain, 0.01, "Drain tick damage (v2)")


func test_necromancer_drain_heal_calculation() -> void:
	var p = _create_player("res://scenes/player/necromancer.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	# Verify drain_heal_percent exists and has the expected value
	assert_almost_eq(p.drain_heal_percent, 0.25, 0.001, "drain_heal_percent = 0.25")

	# drain_dmg = magic_v2(6, 0, INT=10, level=1, class_mult=1.3) ≈ 9.64
	# heal = drain_dmg * 0.25 ≈ 2.41
	var drain_dmg: float = p.get_magic_damage(6.0)
	var expected_heal: float = drain_dmg * p.drain_heal_percent
	var computed_expected_heal: float = DamageFormula.magic_v2(6.0, 0, 10, 1, 1.3) * 0.25
	assert_almost_eq(expected_heal, computed_expected_heal, 0.01, "Heal amount (v2)")

	# Verify heal() actually applies to HP
	p.health = 50.0
	p.heal(expected_heal)
	assert_almost_eq(p.health, 50.0 + computed_expected_heal, 0.01, "HP rises by drain heal amount")


# ═══════════════════════════════════════════
# CLERIC
# ═══════════════════════════════════════════

func test_cleric_stats() -> void:
	var p = _create_player("res://scenes/player/cleric.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.str_stat, 8, "Cleric STR")
	assert_eq(p.int_stat, 6, "Cleric INT")
	assert_eq(p.dex_stat, 4, "Cleric DEX")
	assert_eq(p.def_stat, 8, "Cleric DEF")
	assert_eq(p.vit_stat, 9, "Cleric VIT")


func test_cleric_health_mana() -> void:
	var p = _create_player("res://scenes/player/cleric.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	# Canon §2.1: max_health_v2(95, VIT=9, level=1) ≈ 161.92
	var expected_hp := Progression.max_health_v2(95.0, 9, 1)
	assert_almost_eq(p.max_health, expected_hp, 0.01, "Cleric max HP (v2)")
	# Canon §2.2: max_mana_v2(100, INT=6, level=1) ≈ 127.29
	var expected_mp := Progression.max_mana_v2(100.0, 6, 1)
	assert_almost_eq(p.max_mana, expected_mp, 0.01, "Cleric max MP (v2)")


func test_cleric_speed() -> void:
	var p = _create_player("res://scenes/player/cleric.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.speed, 4.5, "Cleric speed")
	assert_eq(p.sprint_speed, 7.0, "Cleric sprint")


func test_cleric_combat() -> void:
	var p = _create_player("res://scenes/player/cleric.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	assert_eq(p.attack_range, 3.0, "Cleric melee range")
	assert_eq(p.heavy_cooldown, 0.5, "Cleric mace cooldown")


func test_cleric_dual_damage_types() -> void:
	var p = _create_player("res://scenes/player/cleric.tscn")
	add_child_autofree(p)
	await get_tree().process_frame

	# Canon §2.3: physical_v2(25, 0, STR=8, level=1, class_mult=1.0)
	#   = 25 * 1.16 * 1.03 * 1.0 = 29.87
	var expected_mace := DamageFormula.physical_v2(25.0, 0, 8, 1, 1.0)
	assert_almost_eq(p.get_physical_damage(25.0), expected_mace, 0.01, "Mace hit damage (v2)")
	# Canon §2.4: magic_v2(60, 0, INT=6, level=1, class_mult=1.2)
	#   = 60 * 1.12 * 1.03 * 1.2 = 83.06
	var expected_smite := DamageFormula.magic_v2(60.0, 0, 6, 1, 1.2)
	assert_almost_eq(p.get_magic_damage(60.0), expected_smite, 0.01, "Smite damage (v2)")


# ═══════════════════════════════════════════
# COMPARISONS BETWEEN CLASSES
# ═══════════════════════════════════════════
# NOTE: add_child_autofree() triggers _ready() immediately. Because _ready() calls
# _load_character_stats() which reads GameManager.selected_class_scene, we must
# create AND add each player one at a time so the correct scene path is set when
# _ready() runs.

func test_warrior_has_highest_physical_defense() -> void:
	# Warrior: create + add with correct GameManager path
	var w = _create_player("res://scenes/player/player.tscn")
	add_child_autofree(w)
	await get_tree().process_frame

	var m = _create_player("res://scenes/player/mage.tscn")
	add_child_autofree(m)
	await get_tree().process_frame

	var a = _create_player("res://scenes/player/archer.tscn")
	add_child_autofree(a)
	await get_tree().process_frame

	# Warrior DEF=10 > Mage DEF=3, Warrior DEF=10 > Archer DEF=5
	assert_gt(w.def_stat, m.def_stat, "Warrior DEF > Mage DEF")
	assert_gt(w.def_stat, a.def_stat, "Warrior DEF > Archer DEF")


func test_mage_has_highest_mana() -> void:
	var w = _create_player("res://scenes/player/player.tscn")
	add_child_autofree(w)
	await get_tree().process_frame

	var m = _create_player("res://scenes/player/mage.tscn")
	add_child_autofree(m)
	await get_tree().process_frame

	assert_gt(m.max_mana, w.max_mana, "Mage MP > Warrior MP")


func test_archer_is_fastest() -> void:
	var a = _create_player("res://scenes/player/archer.tscn")
	add_child_autofree(a)
	await get_tree().process_frame

	var w = _create_player("res://scenes/player/player.tscn")
	add_child_autofree(w)
	await get_tree().process_frame

	var m = _create_player("res://scenes/player/mage.tscn")
	add_child_autofree(m)
	await get_tree().process_frame

	assert_gt(a.speed, w.speed, "Archer faster than Warrior")
	assert_gt(a.speed, m.speed, "Archer faster than Mage")
	assert_gt(a.sprint_speed, w.sprint_speed, "Archer sprint > Warrior sprint")
