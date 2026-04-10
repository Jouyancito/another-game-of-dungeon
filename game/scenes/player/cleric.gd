extends BasePlayer

# Combate — click: maza (melee físico), mantener: Smite Divino (mágico, raycast)
@export var base_heavy_damage := 25.0
@export var base_smite_damage := 60.0
@export var smite_mana_cost := 15.0
@export var smite_cooldown := 0.8
@export var smite_range := 12.0


func get_class_color() -> Color:
	return Color(0.8, 0.7, 0.2)  # dorado cleric

func _on_class_ready() -> void:
	speed = 4.5
	sprint_speed = 7.0
	crouch_speed = 2.0
	base_health = 95.0
	base_mana = 100.0
	attack_range = 3.0
	heavy_cooldown = 0.5

func _on_attack_pressed() -> void:
	is_holding_attack = false
	_attack_mace()

func _on_attack_released() -> void:
	is_holding_attack = false

func _attack_mace() -> void:
	if not can_attack:
		return
	can_attack = false

	_animate_attack("mace")
	_do_mace_hit()

	await get_tree().create_timer(heavy_cooldown).timeout
	if not is_instance_valid(self) or is_dead:
		return
	can_attack = true

	# Si sigue manteniendo, usar Smite Divino (repetible mientras mantenga)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		is_holding_attack = true
		_smite_loop()

func _smite_loop() -> void:
	while is_holding_attack and not is_dead:
		if mana < smite_mana_cost:
			# Sin maná, salir del loop
			is_holding_attack = false
			return

		_animate_attack("smite")
		_do_smite()

		await get_tree().create_timer(smite_cooldown).timeout
		if not is_instance_valid(self) or is_dead:
			return

		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			is_holding_attack = false

func _animate_attack(type: String) -> void:
	if type == "mace":
		if view_model:
			view_model.play_attack_right(heavy_cooldown)
		if world_model:
			world_model.play_attack_right(heavy_cooldown)
	elif type == "smite":
		if view_model:
			view_model.play_attack_both(smite_cooldown)
		if world_model:
			world_model.play_attack_both(smite_cooldown)

func _do_mace_hit() -> void:
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_basis.z) * attack_range
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)
	if result and result.collider.is_in_group("enemies") and result.collider.has_method("take_damage"):
		result.collider.take_damage(get_physical_damage(base_heavy_damage))

func _do_smite() -> void:
	use_mana(smite_mana_cost)

	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_basis.z) * smite_range
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)

	if result and result.collider.is_in_group("enemies") and result.collider.has_method("take_damage"):
		result.collider.take_damage(get_magic_damage(base_smite_damage))
		_spawn_light_pillar(result.position)

func _spawn_light_pillar(pos: Vector3) -> void:
	# Efecto visual: pilar de luz dorada temporal
	var pillar = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.3
	mesh.bottom_radius = 0.3
	mesh.height = 4.0
	pillar.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.3, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.2)
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pillar.material_override = mat

	pillar.global_position = pos + Vector3(0, 2.0, 0)
	get_tree().current_scene.add_child(pillar)

	# Desaparecer tras 0.4 segundos
	await get_tree().create_timer(0.4).timeout
	if not is_instance_valid(self):
		if is_instance_valid(pillar):
			pillar.queue_free()
		return
	if is_instance_valid(pillar):
		pillar.queue_free()
