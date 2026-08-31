extends GutTest

# Alpha level cap — CLAUDE.md "Scope Reset 2026-05-18": the agreed MVP is
# "1 mapa, 3 clases, 1 boss, ~15 enemies, lvl cap 15".
#
# Nothing enforced the cap. gain_xp() levelled forever, so a player farming Floor 1 could
# walk past the only content the game has and outscale its own boss.

const PlayerScene := preload("res://scenes/player/player.tscn")

var _player: BasePlayer


func before_each() -> void:
	_player = PlayerScene.instantiate()
	add_child_autofree(_player)
	await get_tree().process_frame


func test_the_cap_is_the_agreed_fifteen() -> void:
	assert_eq(Progression.MAX_LEVEL, 15, "the scope reset agreed on lvl cap 15")


func test_xp_cannot_push_the_player_past_the_cap() -> void:
	# One absurd XP dump: without a cap this levels into the hundreds.
	_player.gain_xp(10_000_000.0)

	assert_eq(_player.level, Progression.MAX_LEVEL, "levelling must stop at the cap")
	assert_true(_player.is_at_level_cap())


func test_xp_at_the_cap_is_not_hoarded() -> void:
	# If capped XP silently accumulated, raising the cap later would dump a pile of levels
	# on a returning save the moment they killed one rat.
	_player.gain_xp(10_000_000.0)
	var xp_at_cap: float = _player.xp

	_player.gain_xp(10_000_000.0)

	assert_eq(_player.level, Progression.MAX_LEVEL)
	assert_eq(_player.xp, xp_at_cap, "XP at cap must not keep piling up")


func test_the_bar_reads_full_at_the_cap() -> void:
	# A capped player staring at a half-filled XP bar reads as "still progressing".
	_player.gain_xp(10_000_000.0)
	assert_eq(_player.xp, _player.xp_to_next_level, "the bar sits full, not mid-way")


func test_levelling_still_works_below_the_cap() -> void:
	# Guard against the cap being so eager it breaks normal progression.
	var starting_level: int = _player.level
	# Enough for exactly one level at level 1 (Progression.xp_for_level).
	_player.gain_xp(_player.xp_to_next_level)

	assert_eq(_player.level, starting_level + 1, "a normal kill must still level you")
	assert_false(_player.is_at_level_cap())
