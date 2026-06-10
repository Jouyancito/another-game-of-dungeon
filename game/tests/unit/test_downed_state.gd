extends GutTest

# Tests canon MVP #5 — downed state stub en BasePlayer.
# 3 casos core: downed → revive 30%, downed → timeout → dead, downed no regen.

var player: BasePlayer


func before_each() -> void:
	player = BasePlayer.new()
	player.str_stat = 10
	player.int_stat = 8
	player.dex_stat = 6
	player.def_stat = 5
	player.vit_stat = 7
	player.base_health = 100.0
	player.base_mana = 80.0
	player.downed_time_s = 30.0
	# Add to scene tree so _physics_process (is_on_floor, move_and_slide) works.
	add_child_autofree(player)
	player.recalculate_stats()
	player.health = player.max_health
	player.mana = player.max_mana


func after_each() -> void:
	pass  # add_child_autofree handles cleanup


# ─── Caso 1: die() ya no mata instant — entra en downed ───

func test_die_enters_downed_state_not_dead() -> void:
	player.die()
	assert_true(player.is_downed, "player entra downed")
	assert_false(player.is_dead, "NO es_dead en downed")
	assert_eq(player.health, 0.0, "HP visualmente 0")


func test_die_emits_player_downed_signal() -> void:
	watch_signals(player)
	player.die()
	assert_signal_emitted(player, "player_downed", "emite player_downed (no player_died)")
	assert_signal_not_emitted(player, "player_died", "player_died sólo en muerte real")


func test_take_damage_lethal_triggers_downed_not_dead() -> void:
	player.take_damage(9999.0)
	assert_true(player.is_downed)
	assert_false(player.is_dead)


# ─── Caso 2: revive() → HP a 30% max ───

func test_revive_restores_to_30_percent_hp() -> void:
	player.die()
	var ok: bool = player.revive()
	assert_true(ok)
	assert_false(player.is_downed, "ya no downed")
	assert_false(player.is_dead)
	assert_almost_eq(player.health, player.max_health * 0.3, 0.01, "HP a 30% max")


func test_revive_emits_player_revived_signal() -> void:
	player.die()
	watch_signals(player)
	player.revive()
	assert_signal_emitted(player, "player_revived")


func test_revive_with_healer_passes_argument() -> void:
	player.die()
	var healer: Node = Node.new()
	add_child_autofree(healer)
	watch_signals(player)
	player.revive(healer)
	var params = get_signal_parameters(player, "player_revived")
	assert_eq(params[1], healer, "healer pasado como 2º param")


func test_revive_fails_if_not_downed() -> void:
	var ok: bool = player.revive()
	assert_false(ok, "no estaba downed")


func test_revive_fails_if_already_dead() -> void:
	player.die()
	player._actual_die()  # fuerza muerte real
	var ok: bool = player.revive()
	assert_false(ok, "muerto real — no revive")


# ─── Caso 3: timeout → _actual_die ───

func test_downed_timer_ticks_to_actual_die() -> void:
	player.downed_time_s = 2.0
	player.die()
	# Simular 2 segundos — usa _physics_process (downed early-return path)
	watch_signals(player)
	for i in range(3):  # 3 * 1.0s = 3s (más que 2s)
		player._physics_process(1.0)
	assert_true(player.is_dead, "timeout → muerte real")
	assert_false(player.is_downed, "ya no downed")
	assert_signal_emitted(player, "player_died", "player_died emite al actual_die")


func test_downed_survives_timer_not_yet_expired() -> void:
	player.downed_time_s = 5.0
	player.die()
	player._physics_process(2.0)  # 2s pasaron, quedan 3s
	assert_true(player.is_downed, "todavía downed")
	assert_false(player.is_dead)


# ─── Caso extra: take_damage ignorado en downed (no re-trigger) ───

func test_take_damage_ignored_during_downed() -> void:
	player.die()
	# Ya en downed, dmg adicional no debe hacer nada (no re-triggerea downed ni
	# avanza a muerte; ignorado canon §8.3 "Estado downed").
	player.take_damage(50.0)
	assert_true(player.is_downed, "sigue downed")
	assert_false(player.is_dead)


# ─── Regen: durante downed, HP no regenera (tick=0 implícito) ───

func test_no_hp_regen_during_downed() -> void:
	player.die()
	var hp_before: float = player.health
	# _physics_process en downed NO llama _regenerate
	player._physics_process(5.0)
	assert_eq(player.health, hp_before, "sin regen en downed (HP queda 0)")


# ─── Idempotencia ───

func test_die_idempotent_does_not_reset_timer() -> void:
	player.downed_time_s = 30.0
	player.die()
	var t_before: float = player._downed_time_left
	player._physics_process(5.0)
	var t_mid: float = player._downed_time_left
	# Llamar die() otra vez no resetea el timer
	player.die()
	assert_eq(player._downed_time_left, t_mid, "die() re-entrante no resetea _downed_time_left")


# ─── _actual_die forzado (para casos instant kill como abismo) ───

func test_actual_die_bypass_downed() -> void:
	watch_signals(player)
	player._actual_die()
	assert_true(player.is_dead, "muerte real directa")
	assert_false(player.is_downed)
	assert_signal_emitted(player, "player_died")
