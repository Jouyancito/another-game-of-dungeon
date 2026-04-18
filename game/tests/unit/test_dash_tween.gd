extends GutTest

# Verifica que Embestida se mueve GRADUAL (tween) y no teletransporta.
# Root cause playtest 2026-04-18: global_position = stop_pos directo → feel de teletransporte.
#
# Usamos DummyPlayer Node3D minimal en lugar de BasePlayer.new() porque _ready() de BasePlayer
# depende de nodos y autoloads (Camera3D, GameManager, SaveManager) que no existen en contexto test.

class DummyPlayer extends Node3D:
	signal health_changed(cur: float, max_: float)
	signal mana_changed(cur: float, max_: float)

	var mana: float = 80.0
	var max_mana: float = 80.0
	var health: float = 150.0
	var max_health: float = 150.0
	var str_stat: int = 12
	var dash_locked: bool = false
	var camera: Camera3D = null
	var skills: PlayerSkills = null
	var class_resource: ClassResource = null

	func use_mana(amt: float) -> bool:
		if mana < amt:
			return false
		mana -= amt
		mana_changed.emit(mana, max_mana)
		return true

	func get_effective_stat(s: String) -> int:
		if s == "str":
			return str_stat
		return 0

	func get_physical_damage(base: float) -> float:
		return base + float(str_stat) * 2.0


var player: DummyPlayer
var skills: PlayerSkills


func before_each() -> void:
	player = DummyPlayer.new()
	add_child_autofree(player)  # player en tree → tween path activo
	skills = PlayerSkills.new()
	skills.setup(player, null)
	player.add_child(skills)
	player.skills = skills


func _make_charge_skill() -> SkillResource:
	var s: SkillResource = load("res://shared/skills/resources/warrior/charge.tres")
	if s != null:
		return s
	s = SkillResource.new()
	s.id = &"warrior_charge"
	s.cast_type = SkillResource.CastType.INSTANT
	s.target_type = SkillResource.TargetType.SINGLE_ENEMY
	s.resource_cost = 10
	s.resource_type = SkillResource.ResourceCostType.MP
	s.cooldown_s = 8.0
	s.base_damage = 20
	s.damage_formula = SkillResource.DamageFormulaType.PHYSICAL_V2
	s.dash_distance_m = 6.0
	s.status_applied = [&"stun"]
	s.status_duration_s = 0.8
	return s


# ─── Core: no teletransporte ───

func test_dash_does_not_teleport_on_frame_zero() -> void:
	var charge: SkillResource = _make_charge_skill()
	skills.set_slot(1, charge)
	player.mana = 50.0
	var start: Vector3 = player.global_position
	skills.cast_slot(1)
	var dist_frame_0: float = start.distance_to(player.global_position)
	assert_lt(dist_frame_0, charge.dash_distance_m * 0.5,
		"Embestida teletransportó (movió %fm en frame 0)" % dist_frame_0)


func test_dash_moves_gradually_over_frames() -> void:
	var charge: SkillResource = _make_charge_skill()
	skills.set_slot(1, charge)
	player.mana = 50.0
	var start: Vector3 = player.global_position
	skills.cast_slot(1)
	await get_tree().process_frame
	await get_tree().process_frame
	var mid: float = start.distance_to(player.global_position)
	assert_gt(mid, 0.01, "Tween no progresó tras 2 frames")
	assert_lt(mid, charge.dash_distance_m, "Tween terminó demasiado rápido (no gradual)")


func test_dash_reaches_destination_after_tween_duration() -> void:
	var charge: SkillResource = _make_charge_skill()
	skills.set_slot(1, charge)
	player.mana = 50.0
	var start: Vector3 = player.global_position
	skills.cast_slot(1)
	await get_tree().create_timer(0.5).timeout
	var final_dist: float = start.distance_to(player.global_position)
	assert_almost_eq(final_dist, charge.dash_distance_m, 0.5, "Dash llegó al destino")


# ─── Signals VFX hook ───

func test_dash_started_signal_emits() -> void:
	var charge: SkillResource = _make_charge_skill()
	skills.set_slot(1, charge)
	player.mana = 50.0
	watch_signals(skills)
	skills.cast_slot(1)
	assert_signal_emitted(skills, "dash_started", "dash_started no emitido")


func test_dash_ended_signal_emits_after_tween() -> void:
	var charge: SkillResource = _make_charge_skill()
	skills.set_slot(1, charge)
	player.mana = 50.0
	watch_signals(skills)
	skills.cast_slot(1)
	assert_signal_not_emitted(skills, "dash_ended", "dash_ended no emite sincrónico con tree")
	await get_tree().create_timer(0.5).timeout
	assert_signal_emitted(skills, "dash_ended", "dash_ended post-tween")


# ─── Input lock durante dash ───

func test_dash_locks_player_movement_during_tween() -> void:
	var charge: SkillResource = _make_charge_skill()
	skills.set_slot(1, charge)
	player.mana = 50.0
	skills.cast_slot(1)
	assert_true(player.dash_locked, "dash_locked alzado durante tween")
	await get_tree().create_timer(0.5).timeout
	assert_false(player.dash_locked, "dash_locked liberado post-tween")
