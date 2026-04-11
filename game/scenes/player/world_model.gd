extends Node3D
class_name WorldModel
## Maniquí de cuerpo completo — visible para otros jugadores en coop.
## El jugador local NO ve su propio WorldModel (visibility layers).

var head_mesh: MeshInstance3D
var torso: MeshInstance3D
var right_shoulder: Node3D
var left_shoulder: Node3D
var right_elbow: Node3D
var left_elbow: Node3D
var right_hip: Node3D
var left_hip: Node3D
var right_knee: Node3D
var left_knee: Node3D

# Animación
var _walk_time := 0.0
var _is_moving := false
var _is_sprinting := false
var _attack_tween: Tween

func setup(color: Color) -> void:
	# Torso — centro del cuerpo, a la altura del pecho
	torso = MannequinBuilder.build_torso(color)
	torso.name = "Torso"
	torso.position = Vector3(0, 0.1, 0)  # relativo al centro del CharacterBody3D
	add_child(torso)

	# Cabeza
	head_mesh = MannequinBuilder.build_head_mesh(color)
	head_mesh.name = "HeadMesh"
	head_mesh.position = Vector3(0, 0.44, 0)
	add_child(head_mesh)

	# Brazos — hombros a los lados del torso
	right_shoulder = MannequinBuilder.build_arm(color, 1.0)
	right_shoulder.name = "RightArm"
	right_shoulder.position = Vector3(0.19, 0.26, 0)
	add_child(right_shoulder)

	left_shoulder = MannequinBuilder.build_arm(color, -1.0)
	left_shoulder.name = "LeftArm"
	left_shoulder.position = Vector3(-0.19, 0.26, 0)
	add_child(left_shoulder)

	right_elbow = right_shoulder.get_node("ElbowPivot")
	left_elbow = left_shoulder.get_node("ElbowPivot")

	# Piernas — caderas debajo del torso
	right_hip = MannequinBuilder.build_leg(color, 1.0)
	right_hip.name = "RightLeg"
	right_hip.position = Vector3(0.08, -0.12, 0)
	add_child(right_hip)

	left_hip = MannequinBuilder.build_leg(color, -1.0)
	left_hip.name = "LeftLeg"
	left_hip.position = Vector3(-0.08, -0.12, 0)
	add_child(left_hip)

	right_knee = right_hip.get_node("KneePivot")
	left_knee = left_hip.get_node("KneePivot")

	# Visibility layer: solo otros jugadores ven esto
	MannequinBuilder.set_visual_layer_recursive(self, MannequinBuilder.LAYER_WORLD_MODEL)

func _process(delta: float) -> void:
	if _is_moving:
		_animate_walk(delta)

func set_moving(moving: bool, sprinting: bool = false) -> void:
	_is_moving = moving
	_is_sprinting = sprinting
	if not moving:
		_reset_limbs()

func _animate_walk(delta: float) -> void:
	var walk_speed := 8.0 if _is_sprinting else 5.0
	_walk_time += delta * walk_speed

	var arm_swing := sin(_walk_time) * 0.4
	var leg_swing := sin(_walk_time) * 0.5

	# Brazos oscilan opuestos a las piernas
	right_shoulder.rotation.x = arm_swing
	left_shoulder.rotation.x = -arm_swing

	# Piernas
	right_hip.rotation.x = -leg_swing
	left_hip.rotation.x = leg_swing

	# Rodillas se doblan en el paso trasero
	right_knee.rotation.x = max(0, sin(_walk_time - 0.5)) * 0.6
	left_knee.rotation.x = max(0, sin(_walk_time - 0.5 + PI)) * 0.6

func _reset_limbs() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(right_shoulder, "rotation", Vector3.ZERO, 0.2)
	tw.tween_property(left_shoulder, "rotation", Vector3.ZERO, 0.2)
	tw.tween_property(right_hip, "rotation", Vector3.ZERO, 0.2)
	tw.tween_property(left_hip, "rotation", Vector3.ZERO, 0.2)
	tw.tween_property(right_knee, "rotation", Vector3.ZERO, 0.2)
	tw.tween_property(left_knee, "rotation", Vector3.ZERO, 0.2)

## Sincroniza la rotación de la cabeza con el Head node del jugador
func sync_head_rotation(head_pitch: float) -> void:
	head_mesh.rotation.x = head_pitch

## --- Animaciones de ataque (espejean las del ViewModel para que otros vean lo mismo) ---

func play_attack_right(duration := 0.15) -> void:
	_kill_attack_tween()
	_attack_tween = create_tween()
	_attack_tween.tween_property(right_shoulder, "rotation",
		Vector3(-1.2, 0, 0), duration * 0.4).set_ease(Tween.EASE_OUT)
	_attack_tween.tween_property(right_shoulder, "rotation",
		Vector3.ZERO, duration * 0.6).set_ease(Tween.EASE_IN)

func play_attack_left(duration := 0.15) -> void:
	_kill_attack_tween()
	_attack_tween = create_tween()
	_attack_tween.tween_property(left_shoulder, "rotation",
		Vector3(-1.2, 0, 0), duration * 0.4).set_ease(Tween.EASE_OUT)
	_attack_tween.tween_property(left_shoulder, "rotation",
		Vector3.ZERO, duration * 0.6).set_ease(Tween.EASE_IN)

func play_attack_both(duration := 0.2) -> void:
	_kill_attack_tween()
	_attack_tween = create_tween().set_parallel(true)
	_attack_tween.tween_property(right_shoulder, "rotation",
		Vector3(-1.2, 0, 0), duration * 0.4)
	_attack_tween.tween_property(left_shoulder, "rotation",
		Vector3(-1.2, 0, 0), duration * 0.4)
	_attack_tween.chain().tween_property(right_shoulder, "rotation", Vector3.ZERO, duration * 0.6)
	_attack_tween.tween_property(left_shoulder, "rotation", Vector3.ZERO, duration * 0.6)

func play_channel_start(duration := 0.2) -> void:
	_kill_attack_tween()
	_attack_tween = create_tween().set_parallel(true)
	_attack_tween.tween_property(right_shoulder, "rotation", Vector3(-1.0, 0, 0), duration)
	_attack_tween.tween_property(left_shoulder, "rotation", Vector3(-1.0, 0, 0), duration)

func play_channel_end(duration := 0.2) -> void:
	_kill_attack_tween()
	_attack_tween = create_tween().set_parallel(true)
	_attack_tween.tween_property(right_shoulder, "rotation", Vector3.ZERO, duration)
	_attack_tween.tween_property(left_shoulder, "rotation", Vector3.ZERO, duration)

func _kill_attack_tween() -> void:
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()
	_attack_tween = null
