extends BasePlayer

# Combate — click: puñetazo pesado, mantener: combo rápido
@export var base_heavy_damage := 35.0
@export var base_combo_damage := 15.0
@export var combo_cooldown := 0.25

func _on_class_ready() -> void:
	# Stats del Guerrero
	speed = 5.0
	sprint_speed = 8.0
	crouch_speed = 2.5
	str_stat = 12
	int_stat = 3
	dex_stat = 6
	def_stat = 10
	vit_stat = 10
	res_fire = 0.0
	res_ice = 0.0
	res_lightning = 0.0
	base_health = 100.0
	base_mana = 80.0
	attack_range = 3.0
	heavy_cooldown = 0.6
	recalculate_stats()
	health = max_health
	mana = max_mana

func _on_attack_pressed() -> void:
	is_holding_attack = false
	_attack_heavy()

func _on_attack_released() -> void:
	is_holding_attack = false

func _attack_heavy() -> void:
	if not can_attack:
		return
	can_attack = false

	_do_melee(base_heavy_damage)

	await get_tree().create_timer(heavy_cooldown).timeout
	if not is_instance_valid(self) or is_dead:
		return
	can_attack = true

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		is_holding_attack = true
		_attack_combo()

func _attack_combo() -> void:
	while can_attack and is_holding_attack and not is_dead:
		can_attack = false

		_do_melee(base_combo_damage)

		await get_tree().create_timer(combo_cooldown).timeout
		if not is_instance_valid(self) or is_dead:
			return
		can_attack = true

		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			is_holding_attack = false

func _do_melee(base_dmg: float) -> void:
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_basis.z) * attack_range
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)
	if result and result.collider.is_in_group("enemies"):
		var final_damage = get_physical_damage(base_dmg)
		result.collider.take_damage(final_damage)
