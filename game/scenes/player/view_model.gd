extends Node3D
class_name ViewModel
## Brazos en primera persona — pegados a la cámara, solo visibles para el jugador local.
## Cada clase llama play_attack_right/left/both para animar ataques.

var right_shoulder: Node3D
var left_shoulder: Node3D
var right_elbow: Node3D
var left_elbow: Node3D
var right_hand: MeshInstance3D
var left_hand: MeshInstance3D

# Estado de animación
var _idle_time := 0.0
var _walk_bob := 0.0
var _is_moving := false
var _is_sprinting := false
var _attack_tween: Tween

# Posiciones de reposo de los brazos (idle pose)
const RIGHT_SHOULDER_POS := Vector3(0.28, -0.15, -0.15)
const LEFT_SHOULDER_POS := Vector3(-0.28, -0.15, -0.15)
const IDLE_SHOULDER_ROT := Vector3(deg_to_rad(50), 0, 0)  # brazos hacia adelante y abajo
const IDLE_ELBOW_ROT := Vector3(deg_to_rad(-60), 0, 0)    # antebrazos levantados

func setup(color: Color) -> void:
	# Construir ambos brazos
	right_shoulder = MannequinBuilder.build_arm(color, 1.0)
	right_shoulder.name = "RightArm"
	right_shoulder.position = RIGHT_SHOULDER_POS
	right_shoulder.rotation = IDLE_SHOULDER_ROT
	add_child(right_shoulder)

	left_shoulder = MannequinBuilder.build_arm(color, -1.0)
	left_shoulder.name = "LeftArm"
	left_shoulder.position = LEFT_SHOULDER_POS
	left_shoulder.rotation = IDLE_SHOULDER_ROT
	add_child(left_shoulder)

	# Guardar referencias a codos y manos para animaciones
	right_elbow = right_shoulder.get_node("ElbowPivot")
	left_elbow = left_shoulder.get_node("ElbowPivot")
	right_hand = right_shoulder.get_node("ElbowPivot/Hand")
	left_hand = left_shoulder.get_node("ElbowPivot/Hand")

	# Pose idle: antebrazos levantados
	right_elbow.rotation = IDLE_ELBOW_ROT
	left_elbow.rotation = IDLE_ELBOW_ROT

	# Visibility layer: solo cámara local ve esto
	MannequinBuilder.set_visual_layer_recursive(self, MannequinBuilder.LAYER_VIEW_MODEL)

func _process(delta: float) -> void:
	_idle_time += delta
	_animate_idle(delta)
	if _is_moving:
		_animate_walk(delta)

func _animate_idle(delta: float) -> void:
	# Sutil movimiento de respiración — sube y baja muy leve
	var breath := sin(_idle_time * 1.5) * 0.003
	right_shoulder.position.y = RIGHT_SHOULDER_POS.y + breath
	left_shoulder.position.y = LEFT_SHOULDER_POS.y + breath

func _animate_walk(delta: float) -> void:
	var walk_speed := 8.0 if _is_sprinting else 5.0
	_walk_bob += delta * walk_speed
	var swing := sin(_walk_bob) * 0.06
	# Balanceo opuesto (brazo derecho adelante cuando pie izquierdo adelante)
	right_shoulder.rotation.x = IDLE_SHOULDER_ROT.x + swing
	left_shoulder.rotation.x = IDLE_SHOULDER_ROT.x - swing

func set_moving(moving: bool, sprinting: bool = false) -> void:
	if moving and not _is_moving:
		_walk_bob = 0.0
	_is_moving = moving
	_is_sprinting = sprinting
	if not moving:
		# Volver a pose idle suavemente
		_reset_to_idle()

func _reset_to_idle() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(right_shoulder, "rotation", IDLE_SHOULDER_ROT, 0.15)
	tw.tween_property(left_shoulder, "rotation", IDLE_SHOULDER_ROT, 0.15)

## --- Animaciones de ataque ---

## Golpe con brazo derecho (Warrior melee, Cleric mace)
func play_attack_right(duration := 0.15) -> void:
	_kill_attack_tween()
	_attack_tween = create_tween()
	# Swing hacia adelante
	_attack_tween.tween_property(right_shoulder, "rotation",
		Vector3(deg_to_rad(10), 0, 0), duration * 0.4).set_ease(Tween.EASE_OUT)
	_attack_tween.parallel().tween_property(right_elbow, "rotation",
		Vector3(deg_to_rad(-20), 0, 0), duration * 0.4).set_ease(Tween.EASE_OUT)
	# Volver a idle
	_attack_tween.tween_property(right_shoulder, "rotation",
		IDLE_SHOULDER_ROT, duration * 0.6).set_ease(Tween.EASE_IN)
	_attack_tween.parallel().tween_property(right_elbow, "rotation",
		IDLE_ELBOW_ROT, duration * 0.6).set_ease(Tween.EASE_IN)

## Golpe con brazo izquierdo
func play_attack_left(duration := 0.15) -> void:
	_kill_attack_tween()
	_attack_tween = create_tween()
	_attack_tween.tween_property(left_shoulder, "rotation",
		Vector3(deg_to_rad(10), 0, 0), duration * 0.4).set_ease(Tween.EASE_OUT)
	_attack_tween.parallel().tween_property(left_elbow, "rotation",
		Vector3(deg_to_rad(-20), 0, 0), duration * 0.4).set_ease(Tween.EASE_OUT)
	_attack_tween.tween_property(left_shoulder, "rotation",
		IDLE_SHOULDER_ROT, duration * 0.6).set_ease(Tween.EASE_IN)
	_attack_tween.parallel().tween_property(left_elbow, "rotation",
		IDLE_ELBOW_ROT, duration * 0.6).set_ease(Tween.EASE_IN)

## Ambos brazos adelante (Mage cast, Necro cast, Warrior finisher)
func play_attack_both(duration := 0.2) -> void:
	_kill_attack_tween()
	_attack_tween = create_tween().set_parallel(true)
	# Ambos brazos se extienden hacia adelante
	var cast_rot := Vector3(deg_to_rad(15), 0, 0)
	var cast_elbow := Vector3(deg_to_rad(-10), 0, 0)
	_attack_tween.tween_property(right_shoulder, "rotation", cast_rot, duration * 0.4)
	_attack_tween.tween_property(left_shoulder, "rotation", cast_rot, duration * 0.4)
	_attack_tween.tween_property(right_elbow, "rotation", cast_elbow, duration * 0.4)
	_attack_tween.tween_property(left_elbow, "rotation", cast_elbow, duration * 0.4)
	# Secuencial: volver
	_attack_tween.chain().tween_property(right_shoulder, "rotation", IDLE_SHOULDER_ROT, duration * 0.6)
	_attack_tween.tween_property(left_shoulder, "rotation", IDLE_SHOULDER_ROT, duration * 0.6)
	_attack_tween.tween_property(right_elbow, "rotation", IDLE_ELBOW_ROT, duration * 0.6)
	_attack_tween.tween_property(left_elbow, "rotation", IDLE_ELBOW_ROT, duration * 0.6)

## Brazos extendidos al frente — para canalizar (beam, drain). No vuelve solo.
func play_channel_start(duration := 0.2) -> void:
	_kill_attack_tween()
	var cast_rot := Vector3(deg_to_rad(15), 0, 0)
	var cast_elbow := Vector3(deg_to_rad(-10), 0, 0)
	_attack_tween = create_tween().set_parallel(true)
	_attack_tween.tween_property(right_shoulder, "rotation", cast_rot, duration)
	_attack_tween.tween_property(left_shoulder, "rotation", cast_rot, duration)
	_attack_tween.tween_property(right_elbow, "rotation", cast_elbow, duration)
	_attack_tween.tween_property(left_elbow, "rotation", cast_elbow, duration)

## Volver a idle desde canalización
func play_channel_end(duration := 0.2) -> void:
	_kill_attack_tween()
	_attack_tween = create_tween().set_parallel(true)
	_attack_tween.tween_property(right_shoulder, "rotation", IDLE_SHOULDER_ROT, duration)
	_attack_tween.tween_property(left_shoulder, "rotation", IDLE_SHOULDER_ROT, duration)
	_attack_tween.tween_property(right_elbow, "rotation", IDLE_ELBOW_ROT, duration)
	_attack_tween.tween_property(left_elbow, "rotation", IDLE_ELBOW_ROT, duration)

## Archer: brazo izquierdo adelante (arco), derecho atrás (cuerda)
func play_draw_bow(duration := 0.3) -> void:
	_kill_attack_tween()
	_attack_tween = create_tween().set_parallel(true)
	# Izquierdo extiende hacia adelante
	_attack_tween.tween_property(left_shoulder, "rotation",
		Vector3(deg_to_rad(10), 0, 0), duration)
	_attack_tween.tween_property(left_elbow, "rotation",
		Vector3(deg_to_rad(-5), 0, 0), duration)
	# Derecho tira hacia atrás
	_attack_tween.tween_property(right_shoulder, "rotation",
		Vector3(deg_to_rad(70), 0, 0), duration)
	_attack_tween.tween_property(right_elbow, "rotation",
		Vector3(deg_to_rad(-120), 0, 0), duration)

## Soltar flecha: ambos vuelven a idle
func play_release_bow(duration := 0.1) -> void:
	_kill_attack_tween()
	_attack_tween = create_tween().set_parallel(true)
	_attack_tween.tween_property(right_shoulder, "rotation", IDLE_SHOULDER_ROT, duration)
	_attack_tween.tween_property(left_shoulder, "rotation", IDLE_SHOULDER_ROT, duration)
	_attack_tween.tween_property(right_elbow, "rotation", IDLE_ELBOW_ROT, duration)
	_attack_tween.tween_property(left_elbow, "rotation", IDLE_ELBOW_ROT, duration)

func _kill_attack_tween() -> void:
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()
	_attack_tween = null
