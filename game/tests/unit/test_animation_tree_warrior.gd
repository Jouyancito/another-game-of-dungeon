extends GutTest

# Verifica pipeline AnimationTree Tier 2 — wave3 dept B.
#
# Tests covering:
# 1. BlendSpace2D: update_locomotion lerpea blend_position hacia speed_norm
# 2. OneShot: trigger_attack + animation_finished emite attack_finished con variant
# 3. FootIK: update() respeta is_on_floor (start/stop)
#
# No instanciamos player.tscn (depende de GameManager/SaveManager/Camera3D).
# Construimos AnimationPlayer + AnimationTree + AnimationController3D + FootIKController
# standalone con anims sintéticas (empty Animation con nombres "idle"/"walk"/"run"/"punch").


var ap: AnimationPlayer
var tree: AnimationTree
var ctrl: AnimationController3D
var ik: FootIKController
var host: Node3D


func _make_empty_anim(name: String, length: float = 0.5) -> Animation:
	var a := Animation.new()
	a.length = length
	return a


func before_each() -> void:
	host = Node3D.new()
	add_child_autofree(host)
	ap = AnimationPlayer.new()
	host.add_child(ap)

	# Library con anims sintéticas — _resolve_anims() las detecta por substring
	var lib := AnimationLibrary.new()
	lib.add_animation(&"Idle", _make_empty_anim("idle", 1.0))
	lib.add_animation(&"Walking", _make_empty_anim("walk", 1.0))
	lib.add_animation(&"Running", _make_empty_anim("run", 1.0))
	lib.add_animation(&"Punching", _make_empty_anim("punch", 0.4))
	lib.add_animation(&"Death", _make_empty_anim("dead", 2.0))
	ap.add_animation_library(&"", lib)

	tree = AnimationTree.new()
	host.add_child(tree)

	ctrl = AnimationController3D.new()
	host.add_child(ctrl)
	ctrl.tree = tree
	ctrl.setup(host, ap)

	ik = FootIKController.new()
	host.add_child(ik)
	# setup requiere CharacterBody3D + Skeleton3D hijo. Sin esqueleto → _active=false.
	var body := CharacterBody3D.new()
	host.add_child(body)
	ik.setup(body)


func after_each() -> void:
	# autofree maneja host; no es necesario free manual
	pass


# ─── Test 1: BlendSpace2D responde a velocity ────────────────────────────────

func test_blend_position_approaches_run_speed_on_sprint() -> void:
	assert_not_null(ctrl, "AnimationController3D debería estar listo")
	assert_true(tree.active, "tree debería quedar active tras setup (anims detectadas)")

	# Simular sprint: velocity horizontal = 8 m/s (sprint_speed Warrior), max_speed=8.
	var sprint_vel := Vector3(0.0, 0.0, -8.0)
	var max_speed: float = 8.0
	# Lerp damp 10.0 → con delta 0.1 por N iter converge a ~1.0
	for i in range(60):
		ctrl.update_locomotion(sprint_vel, max_speed, 0.05)

	var blend: Vector2 = tree.get(AnimationController3D.PARAM_BLEND_POS)
	assert_almost_eq(blend.y, 1.0, 0.05, "blend_position.y debería converger cerca 1.0 (run) con sprint")
	assert_almost_eq(blend.x, 0.0, 0.05, "blend_position.x debería quedar 0.0 (strafe no en wave3)")


func test_blend_position_converges_to_zero_idle() -> void:
	# Primero llevamos a run, después a idle — validar que vuelve a 0.
	for i in range(60):
		ctrl.update_locomotion(Vector3(0, 0, -8.0), 8.0, 0.05)
	for i in range(60):
		ctrl.update_locomotion(Vector3.ZERO, 8.0, 0.05)

	var blend: Vector2 = tree.get(AnimationController3D.PARAM_BLEND_POS)
	assert_almost_eq(blend.y, 0.0, 0.05, "blend_position.y debería volver cerca 0.0 en idle")


# ─── Test 2: OneShot attack triggerea + animation_finished emite ─────────────

func test_trigger_attack_emits_attack_finished_signal() -> void:
	watch_signals(ctrl)
	var fired: bool = ctrl.trigger_attack(&"attack_punch")
	assert_true(fired, "trigger_attack debería retornar true con tree activo")

	# Simular fin de anim — en lugar de esperar la duración real (0.4s → lento para unit test),
	# emitimos manualmente el signal interno (como haría el AnimationTree al terminar).
	ctrl._on_tree_anim_finished(&"attack_punch")
	assert_signal_emitted_with_parameters(ctrl, "attack_finished", [&"attack_punch"])


func test_trigger_attack_returns_false_when_inactive() -> void:
	var inactive_ctrl := AnimationController3D.new()
	host.add_child(inactive_ctrl)
	# sin setup → _active=false
	var fired: bool = inactive_ctrl.trigger_attack(&"attack_punch")
	assert_false(fired, "trigger_attack debería retornar false con tree inactive")


# ─── Test 3: FootIK activa/desactiva según is_on_floor ───────────────────────

func test_foot_ik_inactive_without_skeleton() -> void:
	# El DummyPlayer no tiene Skeleton3D hijo — FootIK debería quedar inactive.
	assert_false(ik.is_active(), "FootIK debería estar inactive sin Skeleton3D (fallback wave2)")
	# update() con cualquier valor no debe crashear
	ik.update(true)
	ik.update(false)
	# No assert — simplemente validamos que no tirás error (no-op)
	pass_test("FootIK update es no-op sin skeleton — correcto fallback")


func test_foot_ik_toggles_with_skeleton() -> void:
	# Instanciamos un Skeleton3D synthetic con huesos mínimos Humanoid.
	var body := CharacterBody3D.new()
	host.add_child(body)
	var skel := Skeleton3D.new()
	body.add_child(skel)
	# Mínimos bones — SkeletonIK3D necesita cadena root → tip
	skel.add_bone("Hips")
	skel.add_bone("LeftUpLeg")
	skel.set_bone_parent(1, 0)
	skel.add_bone("LeftLeg")
	skel.set_bone_parent(2, 1)
	skel.add_bone("LeftFoot")
	skel.set_bone_parent(3, 2)
	skel.add_bone("RightUpLeg")
	skel.set_bone_parent(4, 0)
	skel.add_bone("RightLeg")
	skel.set_bone_parent(5, 4)
	skel.add_bone("RightFoot")
	skel.set_bone_parent(6, 5)
	skel.reset_bone_poses()

	var ik2 := FootIKController.new()
	host.add_child(ik2)
	ik2.setup(body)
	assert_true(ik2.is_active(), "FootIK debería activate con Skeleton3D + bones Humanoid")

	# is_on_floor=false → IK desactiva (aire)
	ik2.update(false)
	assert_not_null(ik2.left_ik, "left_ik debería existir post-setup")
	assert_false(ik2.left_ik.is_running(), "left_ik debería detenerse en aire (is_on_floor=false)")

	# is_on_floor=true → IK activa (piso)
	ik2.update(true)
	assert_true(ik2.left_ik.is_running(), "left_ik debería arrancar en piso (is_on_floor=true)")
