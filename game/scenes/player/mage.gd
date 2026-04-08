extends BasePlayer

# Combate — click: bolita (gratis, lenta), mantener: rayo canalizado
@export var base_heavy_damage := 25.0
@export var base_beam_damage := 8.0
@export var beam_mana_cost := 3.0
@export var beam_tick := 0.15
@export var beam_range := 15.0

# Estado del rayo
var is_channeling := false
var beam_line: MeshInstance3D = null

# Referencia al proyectil
var projectile_scene: PackedScene = preload("res://scenes/projectile/mage_projectile.tscn")

func _on_class_ready() -> void:
	# Stats del Mago
	speed = 4.5
	sprint_speed = 7.0
	crouch_speed = 2.0
	str_stat = 4
	int_stat = 12
	dex_stat = 5
	def_stat = 3
	vit_stat = 5
	res_fire = 0.1
	res_ice = 0.1
	res_lightning = 0.1
	base_health = 70.0
	base_mana = 120.0
	attack_range = 15.0
	heavy_cooldown = 1.0
	recalculate_stats()
	health = max_health
	mana = max_mana

func _on_attack_pressed() -> void:
	is_holding_attack = false
	_stop_beam()
	_attack_heavy()

func _on_attack_released() -> void:
	is_holding_attack = false
	_stop_beam()

func _attack_heavy() -> void:
	if not can_attack:
		return
	can_attack = false

	# Disparar bolita con daño mágico
	var projectile = projectile_scene.instantiate()
	projectile.damage = get_magic_damage(base_heavy_damage)
	var spawn_pos = camera.global_position + (-camera.global_basis.z) * 0.8
	projectile.global_position = spawn_pos
	projectile.direction = -camera.global_basis.z
	get_tree().current_scene.add_child(projectile)

	await get_tree().create_timer(heavy_cooldown).timeout
	if not is_instance_valid(self) or is_dead:
		return
	can_attack = true

	# Si sigue manteniendo, cambiar a rayo canalizado
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		is_holding_attack = true
		is_channeling = true
		_start_beam()
		_channel_beam()

func _start_beam() -> void:
	if beam_line != null:
		return
	beam_line = MeshInstance3D.new()
	var mesh = ImmediateMesh.new()
	beam_line.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.6, 1.0, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.5, 1.0)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_line.material_override = mat
	add_child(beam_line)

func _stop_beam() -> void:
	is_channeling = false
	if is_instance_valid(beam_line):
		beam_line.queue_free()
	beam_line = null

func _channel_beam() -> void:
	while is_channeling and is_holding_attack and not is_dead:
		if not use_mana(beam_mana_cost):
			_stop_beam()
			return

		var space_state = get_world_3d().direct_space_state
		var from = camera.global_position
		var to = from + (-camera.global_basis.z) * beam_range
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [get_rid()]
		var result = space_state.intersect_ray(query)

		var end_point = to
		if result:
			end_point = result.position
			if result.collider.is_in_group("enemies") and result.collider.has_method("take_damage"):
				result.collider.take_damage(get_magic_damage(base_beam_damage))

		# Dibujar el rayo visual
		if is_instance_valid(beam_line) and beam_line.mesh is ImmediateMesh:
			var im: ImmediateMesh = beam_line.mesh
			im.clear_surfaces()
			im.surface_begin(Mesh.PRIMITIVE_LINES)
			im.surface_add_vertex(from)
			im.surface_add_vertex(end_point)
			im.surface_end()

		await get_tree().create_timer(beam_tick).timeout
		if not is_instance_valid(self) or is_dead:
			_stop_beam()
			return

	_stop_beam()
