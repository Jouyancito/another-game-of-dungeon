extends CharacterBody3D

# Movimiento
@export var speed := 5.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.003

# Combate
@export var attack_damage := 35.0
@export var attack_range := 3.0
@export var attack_cooldown := 0.5

# Stats
@export var max_health := 100.0
@export var max_mana := 80.0
var health: float
var mana: float

# Progresión
var level := 1
var xp := 0.0
var xp_to_next_level := 100.0

# Señales para el HUD
signal health_changed(new_value: float, max_value: float)
signal mana_changed(new_value: float, max_value: float)
signal xp_changed(xp: float, xp_max: float, level: int)
signal player_died

# Estado interno
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var can_attack := true
var is_dead := false

# Referencias
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready() -> void:
	health = max_health
	mana = max_mana
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return

	# Salir del juego con Escape
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Volver a capturar el mouse al hacer click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			attack()

	# TEST: gastar maná con T (temporal)
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		use_mana(10.0)

	# Controlar la cámara con el mouse
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotar el cuerpo (izquierda/derecha)
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotar la cabeza (arriba/abajo)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		# Limitar para que no gire de más
		head.rotation.x = clamp(head.rotation.x, -PI / 2, PI / 2)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Aplicar gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Saltar
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Obtener la dirección de movimiento
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Aplicar movimiento
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func attack() -> void:
	if not can_attack:
		return

	can_attack = false

	# Buscar enemigos en rango usando un raycast desde la cámara
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_basis.z) * attack_range

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)

	if result and result.collider.is_in_group("enemies"):
		result.collider.take_damage(attack_damage)

	# Cooldown del ataque
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: float) -> void:
	if is_dead:
		return
	health = clamp(health - amount, 0, max_health)
	health_changed.emit(health, max_health)
	if health <= 0:
		die()

func heal(amount: float) -> void:
	if is_dead:
		return
	health = clamp(health + amount, 0, max_health)
	health_changed.emit(health, max_health)

func use_mana(amount: float) -> bool:
	if mana < amount:
		return false
	mana = clamp(mana - amount, 0, max_mana)
	mana_changed.emit(mana, max_mana)
	return true

func restore_mana(amount: float) -> void:
	mana = clamp(mana + amount, 0, max_mana)
	mana_changed.emit(mana, max_mana)

func gain_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		# Cada nivel necesita más XP (curva progresiva)
		xp_to_next_level = 100.0 * pow(1.15, level - 1)
	xp_changed.emit(xp, xp_to_next_level, level)

func die() -> void:
	is_dead = true
	player_died.emit()
