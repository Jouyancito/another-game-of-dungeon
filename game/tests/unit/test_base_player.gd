extends GutTest

# Tests para BasePlayer — fórmulas de daño, defensa, stats, progresión

var player: BasePlayer


func before_each() -> void:
	player = BasePlayer.new()
	# Setear stats base conocidos para tests predecibles
	player.str_stat = 10
	player.int_stat = 8
	player.dex_stat = 6
	player.def_stat = 5
	player.vit_stat = 7
	player.base_health = 100.0
	player.base_mana = 80.0
	player.res_fire = 0.2
	player.res_ice = 0.5
	player.res_lightning = 0.0
	player.recalculate_stats()
	player.health = player.max_health
	player.mana = player.max_mana


func after_each() -> void:
	if is_instance_valid(player):
		player.free()


# ─── recalculate_stats ───

func test_max_health_formula() -> void:
	# max_health = base_health + (vit_stat * 5)
	assert_eq(player.max_health, 135.0, "HP = 100 + (7 * 5) = 135")


func test_max_mana_formula() -> void:
	# max_mana = base_mana + (int_stat * 3)
	assert_eq(player.max_mana, 104.0, "MP = 80 + (8 * 3) = 104")


func test_recalculate_updates_on_stat_change() -> void:
	player.vit_stat = 20
	player.recalculate_stats()
	assert_eq(player.max_health, 200.0, "HP = 100 + (20 * 5) = 200")


# ─── Fórmulas de daño ───

func test_physical_damage() -> void:
	# get_physical_damage = base + (str * 2)
	var dmg = player.get_physical_damage(35.0)
	assert_eq(dmg, 55.0, "35 + (10 * 2) = 55")


func test_magic_damage() -> void:
	# get_magic_damage = base + (int * 2)
	var dmg = player.get_magic_damage(25.0)
	assert_eq(dmg, 41.0, "25 + (8 * 2) = 41")


func test_dex_damage() -> void:
	# get_dex_damage = base + (dex * 2)
	var dmg = player.get_dex_damage(20.0)
	assert_eq(dmg, 32.0, "20 + (6 * 2) = 32")


func test_physical_damage_zero_str() -> void:
	player.str_stat = 0
	assert_eq(player.get_physical_damage(10.0), 10.0, "Sin STR, daño = base")


func test_magic_damage_zero_int() -> void:
	player.int_stat = 0
	assert_eq(player.get_magic_damage(10.0), 10.0, "Sin INT, daño = base")


# ─── Defensa física ───

func test_physical_defense_reduces_damage() -> void:
	# apply_physical_defense = max(raw - def, 1.0)
	var reduced = player.apply_physical_defense(20.0)
	assert_eq(reduced, 15.0, "20 - 5 DEF = 15")


func test_physical_defense_minimum_one() -> void:
	var reduced = player.apply_physical_defense(1.0)
	assert_eq(reduced, 1.0, "Mínimo siempre es 1")


func test_physical_defense_below_def_clamps_to_one() -> void:
	var reduced = player.apply_physical_defense(3.0)
	assert_eq(reduced, 1.0, "3 - 5 = -2, clamped a 1")


# ─── Resistencias elementales ───

func test_fire_resistance() -> void:
	# apply_elemental_damage = raw * (1 - res)
	var dmg = player.apply_elemental_damage(100.0, "fire")
	assert_eq(dmg, 80.0, "100 * (1 - 0.2) = 80")


func test_ice_resistance() -> void:
	var dmg = player.apply_elemental_damage(100.0, "ice")
	assert_eq(dmg, 50.0, "100 * (1 - 0.5) = 50")


func test_lightning_no_resistance() -> void:
	var dmg = player.apply_elemental_damage(100.0, "lightning")
	assert_eq(dmg, 100.0, "Sin resistencia, daño completo")


func test_resistance_caps_at_75_percent() -> void:
	player.res_fire = 0.9
	var dmg = player.apply_elemental_damage(100.0, "fire")
	assert_eq(dmg, 25.0, "Cap 75% → 100 * 0.25 = 25")


func test_resistance_zero_minimum() -> void:
	player.res_fire = 0.0
	var dmg = player.apply_elemental_damage(100.0, "fire")
	assert_eq(dmg, 100.0, "0% resistencia = daño completo")


# ─── heal / use_mana / restore_mana ───

func test_heal_restores_health() -> void:
	player.health = 50.0
	player.heal(30.0)
	assert_eq(player.health, 80.0, "50 + 30 = 80")


func test_heal_does_not_exceed_max() -> void:
	player.health = 130.0
	player.heal(50.0)
	assert_eq(player.health, player.max_health, "No puede superar max_health")


func test_heal_does_nothing_when_dead() -> void:
	player.is_dead = true
	player.health = 0.0
	player.heal(50.0)
	assert_eq(player.health, 0.0, "No se cura estando muerto")


func test_use_mana_subtracts() -> void:
	var initial = player.mana
	var result = player.use_mana(20.0)
	assert_true(result, "Debe retornar true si tiene suficiente")
	assert_eq(player.mana, initial - 20.0)


func test_use_mana_fails_when_insufficient() -> void:
	player.mana = 5.0
	var result = player.use_mana(10.0)
	assert_false(result, "Debe retornar false si no alcanza")
	assert_eq(player.mana, 5.0, "Maná no debe cambiar si falla")


func test_restore_mana() -> void:
	player.mana = 50.0
	player.restore_mana(30.0)
	assert_eq(player.mana, 80.0, "50 + 30 = 80")


func test_restore_mana_caps_at_max() -> void:
	player.mana = player.max_mana - 5.0
	player.restore_mana(20.0)
	assert_eq(player.mana, player.max_mana, "No supera max_mana")


# ─── Progresión (XP / Level Up) ───

func test_gain_xp_adds_xp() -> void:
	player.gain_xp(50.0)
	assert_eq(player.xp, 50.0)
	assert_eq(player.level, 1, "No sube de nivel con 50 XP")


func test_gain_xp_triggers_level_up() -> void:
	player.gain_xp(100.0)
	assert_eq(player.level, 2, "100 XP = nivel 2")
	assert_eq(player.stat_points, 3, "3 puntos por nivel")


func test_gain_xp_multiple_levels() -> void:
	# Level 1 → 2: 100 XP, Level 2 → 3: 115 XP (100 * 1.15)
	player.gain_xp(250.0)
	assert_eq(player.level, 3, "250 XP cubre nivel 2 y 3")
	assert_eq(player.stat_points, 6, "2 subidas * 3 puntos = 6")


func test_xp_to_next_level_scales() -> void:
	player.gain_xp(100.0)
	# Después de nivel 2: xp_to_next = 100 * 1.15^1 = 115
	assert_almost_eq(player.xp_to_next_level, 115.0, 0.01, "Curva 1.15x")


func test_xp_remainder_carries_over() -> void:
	player.gain_xp(120.0)
	assert_eq(player.level, 2)
	assert_eq(player.xp, 20.0, "120 - 100 = 20 de sobra")


# ─── assign_stat ───

func test_assign_stat_str() -> void:
	player.stat_points = 3
	var original = player.str_stat
	var result = player.assign_stat("str")
	assert_true(result)
	assert_eq(player.str_stat, original + 1)
	assert_eq(player.stat_points, 2)


func test_assign_stat_int_recalculates_mana() -> void:
	player.stat_points = 1
	var old_max = player.max_mana
	player.assign_stat("int")
	assert_eq(player.max_mana, old_max + 3.0, "+1 INT = +3 max MP")


func test_assign_stat_vit_recalculates_health() -> void:
	player.stat_points = 1
	var old_max = player.max_health
	player.assign_stat("vit")
	assert_eq(player.max_health, old_max + 5.0, "+1 VIT = +5 max HP")


func test_assign_stat_fails_no_points() -> void:
	player.stat_points = 0
	var result = player.assign_stat("str")
	assert_false(result, "Sin puntos disponibles")


func test_assign_stat_fails_invalid_name() -> void:
	player.stat_points = 5
	var result = player.assign_stat("luck")
	assert_false(result, "Stat inválido")
	assert_eq(player.stat_points, 5, "No consume puntos si es inválido")


func test_assign_stat_all_types() -> void:
	player.stat_points = 5
	for stat in ["str", "int", "dex", "def", "vit"]:
		assert_true(player.assign_stat(stat), "Debe aceptar: %s" % stat)
	assert_eq(player.stat_points, 0, "5 asignaciones = 0 puntos")


# ─── take_damage ───

func test_take_damage_physical() -> void:
	var initial = player.health
	player.take_damage(20.0)
	# 20 - 5 DEF = 15 daño real
	assert_eq(player.health, initial - 15.0)


func test_take_damage_elemental() -> void:
	var initial = player.health
	player.take_damage(100.0, "fire")
	# 100 * (1 - 0.2) = 80 daño
	assert_eq(player.health, initial - 80.0)


func test_take_damage_kills_at_zero() -> void:
	player.take_damage(999.0)
	assert_eq(player.health, 0.0)
	assert_true(player.is_dead)


func test_take_damage_ignored_when_dead() -> void:
	player.is_dead = true
	player.health = 0.0
	player.take_damage(50.0)
	assert_eq(player.health, 0.0, "No recibe daño estando muerto")


func test_take_damage_resets_combat_timer() -> void:
	player.time_since_last_hit = 20.0
	player.take_damage(5.0)
	assert_eq(player.time_since_last_hit, 0.0, "Timer reseteado al recibir daño")


# ─── Señales ───

func test_signal_health_changed_on_damage() -> void:
	watch_signals(player)
	player.take_damage(10.0)
	assert_signal_emitted(player, "health_changed")


func test_signal_health_changed_on_heal() -> void:
	player.health = 50.0
	watch_signals(player)
	player.heal(10.0)
	assert_signal_emitted(player, "health_changed")


func test_signal_mana_changed_on_use() -> void:
	watch_signals(player)
	player.use_mana(5.0)
	assert_signal_emitted(player, "mana_changed")


func test_signal_mana_changed_on_restore() -> void:
	player.mana = 50.0
	watch_signals(player)
	player.restore_mana(10.0)
	assert_signal_emitted(player, "mana_changed")


func test_signal_player_died() -> void:
	watch_signals(player)
	player.take_damage(999.0)
	assert_signal_emitted(player, "player_died")


func test_signal_not_emitted_when_dead() -> void:
	player.is_dead = true
	player.health = 0.0
	watch_signals(player)
	player.take_damage(10.0)
	assert_signal_not_emitted(player, "health_changed", "Sin señal si ya está muerto")


func test_signal_xp_changed() -> void:
	watch_signals(player)
	player.gain_xp(50.0)
	assert_signal_emitted(player, "xp_changed")


func test_signal_level_up() -> void:
	watch_signals(player)
	player.gain_xp(100.0)
	assert_signal_emitted(player, "level_up")


func test_signal_level_up_not_emitted_below_threshold() -> void:
	watch_signals(player)
	player.gain_xp(50.0)
	assert_signal_not_emitted(player, "level_up")


func test_die_is_idempotent_via_take_damage() -> void:
	watch_signals(player)
	player.take_damage(999.0)  # Primera muerte
	player.take_damage(999.0)  # Segunda llamada — ya está muerto, take_damage guarda con is_dead
	assert_signal_emit_count(player, "player_died", 1, "take_damage no re-emite player_died")


func test_die_direct_double_call_emits_twice() -> void:
	# NOTA: die() NO tiene guard contra doble llamada — esto documenta el comportamiento actual.
	# Si se agrega guard en el futuro, cambiar expected count a 1.
	watch_signals(player)
	player.die()
	player.die()
	assert_signal_emit_count(player, "player_died", 2, "die() sin guard emite 2 veces (bug conocido)")


func test_signal_health_changed_params() -> void:
	watch_signals(player)
	player.take_damage(20.0)
	# take_damage(20) → apply_physical_defense(20) → max(20-5, 1) = 15
	var expected_health = player.max_health - 15.0
	var params = get_signal_parameters(player, "health_changed")
	assert_eq(params[0], expected_health, "Señal con HP actual correcto")
	assert_eq(params[1], player.max_health, "Señal con max HP correcto")


func test_signal_mana_changed_params() -> void:
	watch_signals(player)
	player.use_mana(20.0)
	var params = get_signal_parameters(player, "mana_changed")
	assert_eq(params[0], player.max_mana - 20.0, "Señal con MP actual correcto")
	assert_eq(params[1], player.max_mana, "Señal con max MP correcto")


# ─── Regeneración ───

func test_mana_regen_always_active() -> void:
	player.mana = 50.0
	player.time_since_last_hit = 0.0  # En combate
	var old_mana = player.mana
	# Simular _regenerate manualmente
	player._regenerate(1.0)
	assert_gt(player.mana, old_mana, "MP se regenera incluso en combate")


func test_health_regen_blocked_in_combat() -> void:
	player.health = 50.0
	player.time_since_last_hit = 0.0  # Recién golpeado
	var old_health = player.health
	player._regenerate(1.0)
	assert_eq(player.health, old_health, "HP NO se regenera en combate")


func test_health_regen_after_delay() -> void:
	player.health = 50.0
	player.time_since_last_hit = 15.0  # Fuera de combate (delay = 15s)
	var old_health = player.health
	player._regenerate(1.0)
	assert_gt(player.health, old_health, "HP se regenera fuera de combate")


func test_mana_regen_formula() -> void:
	player.mana = 50.0
	# mp_regen = (1.0 + int_stat * 0.1) * delta
	# Con int_stat=8, delta=1.0: 1.0 + 0.8 = 1.8
	player._regenerate(1.0)
	assert_almost_eq(player.mana, 51.8, 0.01, "MP regen = 1.0 + (8 * 0.1) = 1.8/s")


func test_health_regen_formula() -> void:
	player.health = 50.0
	player.time_since_last_hit = 20.0
	# hp_regen = (0.5 + vit_stat * 0.15) * delta
	# Con vit_stat=7, delta=1.0: 0.5 + 1.05 = 1.55
	player._regenerate(1.0)
	assert_almost_eq(player.health, 51.55, 0.01, "HP regen = 0.5 + (7 * 0.15) = 1.55/s")


func test_mana_regen_caps_at_max() -> void:
	player.mana = player.max_mana - 0.5
	player._regenerate(1.0)
	assert_eq(player.mana, player.max_mana, "MP no supera max_mana")


func test_health_regen_caps_at_max() -> void:
	player.health = player.max_health - 0.5
	player.time_since_last_hit = 20.0
	player._regenerate(1.0)
	assert_eq(player.health, player.max_health, "HP no supera max_health")


func test_no_mana_regen_when_full() -> void:
	player.mana = player.max_mana
	watch_signals(player)
	player._regenerate(1.0)
	assert_signal_not_emitted(player, "mana_changed", "Sin señal si MP ya está full")


func test_no_health_regen_when_full() -> void:
	player.health = player.max_health
	player.time_since_last_hit = 20.0
	watch_signals(player)
	player._regenerate(1.0)
	assert_signal_not_emitted(player, "health_changed", "Sin señal si HP ya está full")
