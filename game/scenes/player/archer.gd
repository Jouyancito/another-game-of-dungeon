extends BasePlayer

# Combate — click: flecha rápida, mantener: flecha cargada (2.5x daño, 1s de carga)
@export var base_arrow_damage := 20.0
@export var charge_time := 1.0
@export var charge_multiplier := 2.5
@export var charge_interrupt_cooldown := 0.5

# Estado de carga
var is_charging := false

# Referencia al proyectil
var arrow_scene: PackedScene = preload("res://scenes/projectile/arrow_projectile.tscn")

func get_class_color() -> Color:
	return Color(0.2, 0.6, 0.3)  # verde archer

func _on_class_ready() -> void:
	speed = 5.5
	sprint_speed = 9.0
	crouch_speed = 2.5
	base_health = 85.0
	base_mana = 70.0
	attack_range = 20.0
	heavy_cooldown = 0.7

func _stop_charge() -> void:
	var was_charging := is_charging
	is_charging = false
	is_holding_attack = false
	if was_charging:
		can_attack = false
		await get_tree().create_timer(charge_interrupt_cooldown).timeout
		if not is_instance_valid(self) or is_dead:
			return
		can_attack = true

func _on_attack_pressed() -> void:
	_stop_charge()
	_attack_arrow()

func _on_attack_released() -> void:
	_stop_charge()

func _attack_arrow() -> void:
	if not can_attack:
		return
	can_attack = false

	_fire_arrow(base_arrow_damage)

	await get_tree().create_timer(heavy_cooldown).timeout
	if not is_instance_valid(self) or is_dead:
		return
	can_attack = true

	# Si sigue manteniendo, iniciar bucle de flecha cargada
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		is_holding_attack = true
		_charge_loop()

func _charge_loop() -> void:
	while is_holding_attack and not is_dead:
		is_charging = true
		# Animación de tensar arco
		if view_model:
			view_model.play_draw_bow(charge_time)

		# Esperar el tiempo de carga o soltar el botón
		var timer = get_tree().create_timer(charge_time)
		await timer.timeout
		if not is_instance_valid(self) or is_dead:
			is_charging = false
			return

		# Si fue interrumpido durante la espera, _stop_charge() ya maneja el recovery
		if not is_charging:
			return

		# Solo dispara si aún mantiene y sigue cargando
		if is_charging and is_holding_attack:
			_fire_arrow(base_arrow_damage * charge_multiplier)
			is_charging = false

			# Cooldown antes de poder volver a cargar
			can_attack = false
			await get_tree().create_timer(heavy_cooldown).timeout
			if not is_instance_valid(self) or is_dead:
				return
			can_attack = true

		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			is_holding_attack = false

func _fire_arrow(dmg: float) -> void:
	if not is_instance_valid(self) or is_dead:
		return
	# Animación de soltar flecha
	if view_model:
		view_model.play_release_bow(0.1)
	if world_model:
		world_model.play_attack_both(0.15)
	var arrow = arrow_scene.instantiate()
	arrow.damage = get_dex_damage(dmg)
	var spawn_pos = camera.global_position + (-camera.global_basis.z) * 0.8
	arrow.global_position = spawn_pos
	arrow.direction = -camera.global_basis.z
	arrow.shooter = self
	get_tree().current_scene.add_child(arrow)
