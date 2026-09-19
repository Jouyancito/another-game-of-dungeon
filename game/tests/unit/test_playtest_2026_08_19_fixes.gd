extends GutTest

# Regressions found in the 2026-08-19 floor-1 playtest. Both bugs share a shape:
# a rule that was stated in one place and quietly not honoured in another.
#
#   1. Attacking while downed — _unhandled_input() refuses to START an action, but
#      the per-class attack loops are coroutines that outlive the event and only
#      tested is_dead.
#   2. The enemy HP bar floated instead of emptying leftwards — the builder used a
#      0.8-wide bar while the update sild it by a hardcoded 0.25 half-width.
#
# Findings recorded in game/docs/_playtest_2026-08-19.md.


# ─── 1. is_incapacitated() covers every state that must stop an in-flight attack ───

var _player: BasePlayer


## Deliberately NOT added to the scene tree, following test_base_player.gd. BasePlayer's
## @onready vars ($CollisionShape3D, $Head, $Head/Camera3D, $MeshInstance3D) only resolve
## inside player.tscn, so entering the tree bare floods the run with "Node not found"
## engine errors that GUT counts against the test. None of the state below needs a tree.
func before_each() -> void:
	_player = BasePlayer.new()
	_player.base_health = 100.0
	_player.base_mana = 80.0
	_player.recalculate_stats()
	_player.health = _player.max_health


func after_each() -> void:
	if is_instance_valid(_player):
		_player.free()


func test_incapacitated_is_false_while_healthy() -> void:
	# Positive control. Without this the three assertions below would also pass on a
	# function that returns true unconditionally.
	assert_false(_player.is_incapacitated(), "un jugador sano puede actuar")


func test_incapacitated_while_downed() -> void:
	_player.is_downed = true
	assert_true(_player.is_incapacitated(), "downed = incapacitado (canon MVP #5)")


func test_incapacitated_while_dead() -> void:
	_player.is_dead = true
	assert_true(_player.is_incapacitated(), "dead = incapacitado")


func test_incapacitated_while_stunned() -> void:
	_player.apply_status(&"stun", 5.0)
	assert_true(_player.is_stunned(), "el status stun quedó aplicado")
	assert_true(_player.is_incapacitated(), "stun = sin acción (canon §2.2)")


# ─── 2. Every class attack loop asks is_incapacitated(), not is_dead ─────────────
#
# A behavioural test per class would have to instantiate each .tscn and await real
# attack timers. The defect is structural — a loop written with the wrong condition —
# so it is caught structurally, and this also catches a NEW class added later with
# the old pattern copied from its neighbours, which no per-class test would.

const CLASS_SCRIPTS: Array[String] = [
	"res://scenes/player/player.gd",
	"res://scenes/player/mage.gd",
	"res://scenes/player/archer.gd",
	"res://scenes/player/cleric.gd",
	"res://scenes/player/necromancer.gd",
]


func _attack_loop_lines(path: String) -> Array[String]:
	var f := FileAccess.open(path, FileAccess.READ)
	assert_not_null(f, "se puede leer %s" % path)
	var out: Array[String] = []
	if f == null:
		return out
	for line in f.get_as_text().split("\n"):
		var t: String = line.strip_edges()
		if t.begins_with("while ") and t.contains("is_holding_attack"):
			out.append(t)
	f.close()
	return out


func test_every_class_has_an_attack_loop_to_check() -> void:
	# Positive control for the scan below: if the search string ever stops matching,
	# the two tests after this would pass vacuously on an empty list.
	for path in CLASS_SCRIPTS:
		assert_gt(_attack_loop_lines(path).size(), 0,
			"%s tiene al menos un loop de ataque que inspeccionar" % path)


func test_attack_loops_stop_when_incapacitated() -> void:
	for path in CLASS_SCRIPTS:
		for line in _attack_loop_lines(path):
			assert_true(line.contains("is_incapacitated()"),
				"%s: el loop de ataque consulta is_incapacitated() — %s" % [path, line])


func test_attack_loops_do_not_test_is_dead_alone() -> void:
	for path in CLASS_SCRIPTS:
		for line in _attack_loop_lines(path):
			assert_false(line.contains("not is_dead"),
				"%s: `not is_dead` no cubre downed ni stun — %s" % [path, line])


# ─── 3. The enemy HP bar empties leftwards and its left edge never moves ────────

var _enemy_scene: PackedScene = preload("res://scenes/enemy/enemy_basic.tscn")


class MockTarget extends Node3D:
	pass


## Left edge of the fill quad in nameplate-local metres. The quad is centred and
## scaled about its centre, so the edge is the centre minus half the SCALED width.
func _fill_left_edge(enemy: Node) -> float:
	var fill: MeshInstance3D = enemy._hp_bar_fill
	return fill.position.x - (BaseEnemy.HP_BAR_WIDTH * fill.scale.x) / 2.0


## BaseEnemy._ready() opens with `await get_tree().process_frame`, so _max_health is
## still 0 on the frame the node is added — reading it any earlier makes every ratio
## below collapse to zero and the assertions pass or fail for the wrong reason.
## `target` is assigned after that await too, or _ready's own group lookup wins.
func _enemy_showing_nameplate() -> Node:
	var e := _enemy_scene.instantiate()
	add_child_autofree(e)
	await get_tree().process_frame
	await get_tree().process_frame
	# _update_nameplate() bails without a target, and without a camera inside
	# NAMEPLATE_VISIBLE_RANGE it hides the plate before touching the bar.
	var target := MockTarget.new()
	add_child_autofree(target)
	e.target = target
	var cam := Camera3D.new()
	add_child_autofree(cam)
	cam.global_position = e.global_position + Vector3(0, 0, 3.0)
	cam.current = true
	assert_gt(e._max_health, 0.0, "_max_health quedó inicializado tras el await")
	return e


func test_full_health_bar_spans_the_whole_track() -> void:
	var e = await _enemy_showing_nameplate()
	e._update_nameplate()
	assert_almost_eq(e._hp_bar_fill.scale.x, 1.0, 0.001, "a vida llena el fill es entero")
	assert_almost_eq(_fill_left_edge(e), -BaseEnemy.HP_BAR_WIDTH / 2.0, 0.001,
		"el borde izquierdo arranca en el extremo del riel")


func test_left_edge_is_pinned_at_every_health_level() -> void:
	# The bug Joan saw: at 20% the fill sat detached from the left edge, ending at 35%
	# of the track, so the bar read as far fuller than the health behind it. With the
	# old hardcoded 0.25 the left edge at ratio 0.2 landed on -0.28 instead of -0.40.
	var e = await _enemy_showing_nameplate()
	var expected: float = -BaseEnemy.HP_BAR_WIDTH / 2.0
	for ratio in [1.0, 0.75, 0.5, 0.25, 0.2, 0.1, 0.0]:
		e.health = e._max_health * ratio
		e._update_nameplate()
		assert_almost_eq(_fill_left_edge(e), expected, 0.001,
			"con %d%% de vida el borde izquierdo sigue clavado" % int(ratio * 100.0))


func test_bar_length_tracks_the_health_ratio() -> void:
	var e = await _enemy_showing_nameplate()
	for ratio in [1.0, 0.5, 0.2]:
		e.health = e._max_health * ratio
		e._update_nameplate()
		assert_almost_eq(e._hp_bar_fill.scale.x, ratio, 0.001,
			"el largo del fill es la fracción de vida (%s)" % ratio)


func test_colour_and_length_agree_at_low_health() -> void:
	# The tell that exposed the bug: the bar turned red (the <=25% threshold) while
	# still looking more than half full. Colour and length must describe one state.
	var e = await _enemy_showing_nameplate()
	e.health = e._max_health * 0.2
	e._update_nameplate()
	var mat: StandardMaterial3D = e._hp_bar_fill.mesh.material as StandardMaterial3D
	assert_not_null(mat, "el fill tiene material")
	assert_gt(mat.albedo_color.r, mat.albedo_color.g, "a 20% de vida el fill es rojo")
	assert_lt(e._hp_bar_fill.scale.x, 0.25, "…y mide menos de un cuarto del riel")
