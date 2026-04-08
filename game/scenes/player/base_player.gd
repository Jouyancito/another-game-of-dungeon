extends CharacterBody3D
class_name BasePlayer

# Movimiento
@export var speed := 5.0
@export var sprint_speed := 8.0
@export var crouch_speed := 2.5
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.003
@export var crouch_height := 0.9
@export var stand_height := 1.8

# Combate (los valores se sobreescriben en cada clase)
@export var attack_range := 3.0
@export var heavy_cooldown := 0.6

# Atributos
@export var str_stat := 5
@export var int_stat := 5
@export var dex_stat := 5
@export var def_stat := 5
@export var vit_stat := 5

# Resistencias elementales (0.0 a 0.75)
@export var res_fire := 0.0
@export var res_ice := 0.0
@export var res_lightning := 0.0

# HP/MP base (antes de aplicar VIT/INT)
@export var base_health := 100.0
@export var base_mana := 80.0

# Regeneración
@export var hp_regen_delay := 15.0

# Stats calculados
var max_health: float
var max_mana: float
var health: float
var mana: float

# Progresión
var level := 1
var xp := 0.0
var xp_to_next_level := 100.0
var stat_points := 0

# Señales para el HUD
signal health_changed(new_value: float, max_value: float)
signal mana_changed(new_value: float, max_value: float)
signal xp_changed(xp: float, xp_max: float, level: int)
signal player_died
signal level_up(new_level: int, points: int)

# Estado interno
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var can_attack := true
var is_dead := false
var is_holding_attack := false
var is_crouching := false
var time_since_last_hit := 0.0
var _reloading := false

# Referencias
@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready() -> void:
	recalculate_stats()
	health = max_health
	mana = max_mana
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_on_class_ready()

# Override en cada clase si necesita setup extra
func _on_class_ready() -> void:
	pass

func recalculate_stats() -> void:
	max_health = base_health + (vit_stat * 5)
	max_mana = base_mana + (int_stat * 3)

func get_physical_damage(base_dmg: float) -> float:
	return base_dmg + (str_stat * 2)

func get_magic_damage(base_dmg: float) -> float:
	return base_dmg + (int_stat * 2)

func get_dex_damage(base_dmg: float) -> float:
	return base_dmg + (dex_stat * 2)

func apply_physical_defense(raw_damage: float) -> float:
	return maxf(raw_damage - def_stat, 1.0)

func apply_elemental_damage(raw_damage: float, element: String) -> float:
	var res := 0.0
	match element:
		"fire": res = res_fire
		"ice": res = res_ice
		"lightning": res = res_lightning
		_: push_warning("apply_elemental_damage: unknown element '%s'" % element)
	return raw_damage * (1.0 - clampf(res, 0.0, 0.75))

func _unhandled_input(event: InputEvent) -> void:
	# TEST: respawn con R (temporal para prototipo)
	if event is InputEventKey and event.pressed and event.keycode == KEY_R and is_dead:
		if not _reloading:
			_reloading = true
			get_tree().reload_current_scene()
		return

	if is_dead:
		return

	# Atacar — cada clase maneja el input de ataque
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				_on_attack_pressed()
		else:
			_on_attack_released()

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -PI / 2, PI / 2)

# Override en cada clase
func _on_attack_pressed() -> void:
	pass

func _on_attack_released() -> void:
	is_holding_attack = false

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	_regenerate(delta)

	if not is_on_floor():
		velocity.y -= gravity * delta

	# Agacharse (Ctrl)
	if Input.is_key_pressed(KEY_CTRL):
		if not is_crouching:
			is_crouching = true
			collider.shape.height = crouch_height
			head.position.y = 0.3
	else:
		if is_crouching:
			is_crouching = false
			collider.shape.height = stand_height
			head.position.y = 0.8

	# Saltar (no agachado)
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = jump_velocity

	# Velocidad según estado
	var current_speed := speed
	if is_crouching:
		current_speed = crouch_speed
	elif Input.is_key_pressed(KEY_SHIFT):
		current_speed = sprint_speed

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

func _regenerate(delta: float) -> void:
	time_since_last_hit += delta

	# Maná: siempre regenera
	if mana < max_mana:
		var mp_regen = (1.0 + int_stat * 0.1) * delta
		mana = minf(mana + mp_regen, max_mana)
		mana_changed.emit(mana, max_mana)

	# Vida: solo fuera de combate
	if time_since_last_hit >= hp_regen_delay and health < max_health:
		var hp_regen = (0.5 + vit_stat * 0.15) * delta
		health = minf(health + hp_regen, max_health)
		health_changed.emit(health, max_health)

func take_damage(amount: float, element: String = "") -> void:
	if is_dead:
		return
	time_since_last_hit = 0.0
	var final_damage: float
	if element != "":
		final_damage = apply_elemental_damage(amount, element)
	else:
		final_damage = apply_physical_defense(amount)
	health = clamp(health - final_damage, 0, max_health)
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
		stat_points += 3
		xp_to_next_level = 100.0 * pow(1.15, level - 1)
		level_up.emit(level, stat_points)
	xp_changed.emit(xp, xp_to_next_level, level)

func assign_stat(stat_name: String) -> bool:
	if stat_points <= 0:
		return false
	match stat_name:
		"str": str_stat += 1
		"int": int_stat += 1
		"dex": dex_stat += 1
		"def": def_stat += 1
		"vit": vit_stat += 1
		_: return false
	stat_points -= 1
	recalculate_stats()
	health = minf(health, max_health)
	mana = minf(mana, max_mana)
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)
	return true

func die() -> void:
	is_dead = true
	player_died.emit()
