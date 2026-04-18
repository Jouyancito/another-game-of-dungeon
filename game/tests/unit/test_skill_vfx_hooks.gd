extends GutTest

# Verifica que SkillVFXHooks conecta signals de PlayerSkills a spawn de VFX.
#
# No usamos BasePlayer.new() porque _ready() depende de GameManager/SaveManager/Camera3D.
# Usamos DummyPlayer — mismo patrón de test_dash_tween.gd.
# Los VFXBase .tscn reales se precargan; si falla el preload el test lo reporta limpio.

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
var hooks: SkillVFXHooks


func before_each() -> void:
	player = DummyPlayer.new()
	add_child_autofree(player)
	skills = PlayerSkills.new()
	skills.setup(player, null)
	player.add_child(skills)
	player.skills = skills
	# Instanciar y conectar hooks manualmente (sin _setup_skills() de BasePlayer)
	hooks = SkillVFXHooks.new()
	player.add_child(hooks)
	hooks.setup(player)


# ─── dash_started → charge_vfx como child del player ─────────────────────────

func test_dash_started_spawns_vfx_child_on_player() -> void:
	var children_before: int = player.get_child_count()
	skills.dash_started.emit(&"warrior_charge")
	await get_tree().process_frame
	# Debe haber al menos un child nuevo con script VFXBase
	var found := false
	for child in player.get_children():
		if child is VFXBase:
			found = true
			break
	assert_true(found, "dash_started debería spawnear un VFXBase child en el player")

func test_dash_started_ignored_for_other_skills() -> void:
	var children_before: int = _count_vfx_children(player)
	skills.dash_started.emit(&"warrior_war_cry")  # no es charge — ignorar
	await get_tree().process_frame
	assert_eq(_count_vfx_children(player), children_before,
		"dash_started con skill_id ≠ warrior_charge no debería spawnear VFX")


# ─── toggle_changed → war_cry persist ────────────────────────────────────────

func test_toggle_on_spawns_war_cry_vfx_child() -> void:
	skills.toggle_changed.emit(&"warrior_war_cry", true)
	await get_tree().process_frame
	assert_true(_count_vfx_children(player) > 0,
		"toggle_changed(true) debería spawnear war_cry VFX en el player")

func test_toggle_on_registers_in_active_dict() -> void:
	skills.toggle_changed.emit(&"warrior_war_cry", true)
	await get_tree().process_frame
	assert_true(hooks._active_toggle_vfx.has(&"warrior_war_cry"),
		"war_cry debería quedar en _active_toggle_vfx tras toggle ON")

func test_toggle_on_twice_does_not_duplicate() -> void:
	skills.toggle_changed.emit(&"warrior_war_cry", true)
	await get_tree().process_frame
	var count_after_first: int = _count_vfx_children(player)
	skills.toggle_changed.emit(&"warrior_war_cry", true)
	await get_tree().process_frame
	assert_eq(_count_vfx_children(player), count_after_first,
		"Doble toggle ON no debería duplicar VFX")

func test_toggle_off_calls_stop_and_removes_from_dict() -> void:
	skills.toggle_changed.emit(&"warrior_war_cry", true)
	await get_tree().process_frame
	assert_true(hooks._active_toggle_vfx.has(&"warrior_war_cry"), "precondición: activo")

	skills.toggle_changed.emit(&"warrior_war_cry", false)
	await get_tree().process_frame
	assert_false(hooks._active_toggle_vfx.has(&"warrior_war_cry"),
		"toggle OFF debería eliminar war_cry de _active_toggle_vfx")


# ─── skill_hit → punch_impact en hit_position ────────────────────────────────

func test_skill_hit_warrior_punch_spawns_in_scene() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		pending("No hay current_scene — ejecutar dentro de Godot editor")
		return
	var vfx_before: int = _count_vfx_in_tree(scene_root)
	var hit_pos := Vector3(1.0, 0.0, 0.0)
	skills.skill_hit.emit(&"warrior_punch", null, hit_pos)
	await get_tree().process_frame
	var vfx_after: int = _count_vfx_in_tree(scene_root)
	assert_gt(vfx_after, vfx_before,
		"skill_hit(warrior_punch) debería spawnear VFXBase en la escena")

func test_skill_hit_warrior_charge_shares_impact_vfx() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		pending("No hay current_scene — ejecutar dentro de Godot editor")
		return
	var vfx_before: int = _count_vfx_in_tree(scene_root)
	skills.skill_hit.emit(&"warrior_charge", null, Vector3(2.0, 0.0, 0.0))
	await get_tree().process_frame
	assert_gt(_count_vfx_in_tree(scene_root), vfx_before,
		"skill_hit(warrior_charge) también debería spawnear punch_impact_vfx")

func test_skill_hit_ignored_for_unknown_skill() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		pending("No hay current_scene")
		return
	var vfx_before: int = _count_vfx_in_tree(scene_root)
	skills.skill_hit.emit(&"warrior_war_cry", null, Vector3.ZERO)
	await get_tree().process_frame
	assert_eq(_count_vfx_in_tree(scene_root), vfx_before,
		"skill_hit con skill sin impact VFX no debería spawnear nada")


# ─── reactive_window_opened → perfect_block VFX frontal ──────────────────────

func test_reactive_window_opened_spawns_vfx_on_player() -> void:
	skills.reactive_window_opened.emit(&"warrior_perfect_block", 0.5)
	await get_tree().process_frame
	assert_true(hooks._active_toggle_vfx.has(&"warrior_perfect_block"),
		"reactive_window_opened debería registrar perfect_block VFX en _active_toggle_vfx")

func test_reactive_window_vfx_positioned_frontal() -> void:
	skills.reactive_window_opened.emit(&"warrior_perfect_block", 0.5)
	await get_tree().process_frame
	var vfx: VFXBase = hooks._active_toggle_vfx.get(&"warrior_perfect_block")
	if vfx == null:
		fail_test("VFX de perfect_block no encontrado en _active_toggle_vfx")
		return
	assert_lt(vfx.position.z, 0.0, "perfect_block VFX debería estar adelante del player (z < 0)")


# ─── reactive_triggered → burst one-shot ─────────────────────────────────────

func test_reactive_triggered_clears_window_vfx() -> void:
	skills.reactive_window_opened.emit(&"warrior_perfect_block", 0.5)
	await get_tree().process_frame
	assert_true(hooks._active_toggle_vfx.has(&"warrior_perfect_block"), "precondición: window activa")

	skills.reactive_triggered.emit(&"warrior_perfect_block", 50.0, 0.0)
	await get_tree().process_frame
	assert_false(hooks._active_toggle_vfx.has(&"warrior_perfect_block"),
		"reactive_triggered debería cerrar la window VFX del dict")


# ─── Helpers ──────────────────────────────────────────────────────────────────

func _count_vfx_children(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child is VFXBase:
			count += 1
	return count


func _count_vfx_in_tree(root: Node) -> int:
	var count := 0
	for node in root.get_children():
		if node is VFXBase:
			count += 1
		count += _count_vfx_in_tree(node)
	return count
