extends GutTest

# Player status effects — canon docs/skills/_status_effects.md §2.2.
#
# Enemies have carried statuses since Fase 1 (BaseEnemy.apply_status). The PLAYER never
# could: BasePlayer had apply_knockback() and no apply_status(), so nothing in the game
# was able to stun them — even though canon has always said heavy hits (Embestida, the
# jabali's charge) do exactly that. This is that missing half.
#
# The contract deliberately MIRRORS BaseEnemy's, so an attack never has to ask whether it
# hit a player or an enemy — it just calls apply_status().

const PlayerScene := preload("res://scenes/player/player.tscn")

var _player: BasePlayer


func before_each() -> void:
	_player = PlayerScene.instantiate()
	add_child_autofree(_player)
	await get_tree().process_frame


func test_player_can_be_stunned() -> void:
	assert_false(_player.is_stunned(), "precondition: nobody starts stunned")

	_player.apply_status(&"stun", 0.5)

	assert_true(_player.is_stunned())
	assert_true(_player.has_status(&"stun"))
	assert_almost_eq(_player.get_status_time_left(&"stun"), 0.5, 0.01)


func test_stun_refreshes_to_max_and_never_stacks() -> void:
	# Canon §2.2: "Stack: NO (refresh-to-max)". A second, SHORTER stun must not cut a
	# longer one short — otherwise a fast weak hit would rescue you from a heavy one.
	_player.apply_status(&"stun", 2.0)
	_player.apply_status(&"stun", 0.5)

	assert_almost_eq(_player.get_status_time_left(&"stun"), 2.0, 0.01,
		"a shorter stun must not shorten the one already running")


func test_stun_expires() -> void:
	_player.apply_status(&"stun", 0.05)
	assert_true(_player.is_stunned())

	await wait_seconds(0.3)

	assert_false(_player.is_stunned(), "a stun must end on its own — no permanent lock")
	assert_false(_player.has_status(&"stun"))


func test_a_downed_player_takes_no_new_statuses() -> void:
	# Downed is already total incapacitation (canon MVP #5). Stacking a stun on top of it
	# would do nothing but risk outliving the revive and locking a revived player.
	_player.is_downed = true

	_player.apply_status(&"stun", 1.0)

	assert_false(_player.is_stunned())


func test_status_signals_fire_for_the_hud() -> void:
	# The HUD tells the player they cannot act by listening to these. No signal, no
	# feedback, and being stunned just reads as the game having frozen.
	watch_signals(_player)

	_player.apply_status(&"stun", 0.05)
	assert_signal_emitted(_player, "status_applied")

	await wait_seconds(0.3)
	assert_signal_emitted(_player, "status_removed")
