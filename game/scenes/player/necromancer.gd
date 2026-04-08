extends BasePlayer

# Combate — click: orbe oscuro, mantener: drenar vida (daño + cura al necro)
@export var base_orb_damage := 22.0
@export var base_drain_damage := 6.0
@export var drain_mana_cost := 2.5
@export var drain_tick := 0.15
@export var drain_range := 12.0
@export var heavy_cooldown_orb := 0.9
@export var drain_heal_percent := 0.25
@export var drain_end_cooldown := 0.5

# Estado del drenaje
var is_draining := false
var _drain_active := false
var drain_line: MeshInstance3D = null

# Referencia al proyectil
var orb_scene: PackedScene = preload("res://scenes/projectile/necro_projectile.tscn")

func _on_class_ready() -> void:
	speed = 4.5
	sprint_speed = 7.0
	crouch_speed = 2.0
	str_stat = 3
	int_stat = 10
	dex_stat = 4
	def_stat = 4
	vit_stat = 6
	res_fire = 0.0
	res_ice = 0.0
	res_lightning = 0.0
	base_health = 80.0
	base_mana = 110.0
	attack_range = 15.0
	heavy_cooldown = heavy_cooldown_orb
	recalculate_stats()
	health = max_health
	mana = max_mana

func _on_attack_pressed() -> void:
	is_holding_attack = false
	_stop_drain()
	_attack_orb()

func _on_attack_released() -> void:
	is_holding_attack = false
	_stop_drain()

func _attack_orb() -> void:
	if not can_attack:
		return
	can_attack = false

	var orb = orb_scene.instantiate()
	orb.damage = get_magic_damage(base_orb_damage)
	var spawn_pos = camera.global_position + (-camera.global_basis.z) * 0.8
	orb.global_position = spawn_pos
	orb.direction = -camera.global_basis.z
	get_tree().current_scene.add_child(orb)

	await get_tree().create_timer(heavy_cooldown).timeout
	if not is_instance_valid(self) or is_dead:
		return
	can_attack = true

	# Si sigue manteniendo, activar drenaje canalizado
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		is_holding_attack = true
		is_draining = true
		_start_drain()
		_channel_drain()

func _start_drain() -> void:
	if drain_line != null:
		return
	drain_line = MeshInstance3D.new()
	var mesh = ImmediateMesh.new()
	drain_line.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.0, 0.6, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.0, 0.5)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drain_line.material_override = mat
	add_child(drain_line)

func _stop_drain() -> void:
	is_draining = false
	if is_instance_valid(drain_line):
		drain_line.queue_free()
	drain_line = null
	await get_tree().create_timer(drain_end_cooldown).timeout
	if not is_instance_valid(self):
		return
	_drain_active = false

func _channel_drain() -> void:
	if _drain_active:
		return
	_drain_active = true
	while is_draining and is_holding_attack and not is_dead:
		if not use_mana(drain_mana_cost):
			_stop_drain()
			return

		var space_state = get_world_3d().direct_space_state
		var from = camera.global_position
		var to = from + (-camera.global_basis.z) * drain_range
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [get_rid()]
		var result = space_state.intersect_ray(query)

		var end_point = to
		if result:
			end_point = result.position
			if result.collider.is_in_group("enemies") and result.collider.has_method("take_damage"):
				var dmg = get_magic_damage(base_drain_damage)
				result.collider.take_damage(dmg)
				# Curar al necromante un 25% del daño aplicado
				heal(dmg * drain_heal_percent)

		# Dibujar el rayo visual
		if is_instance_valid(drain_line) and drain_line.mesh is ImmediateMesh:
			var im: ImmediateMesh = drain_line.mesh
			im.clear_surfaces()
			im.surface_begin(Mesh.PRIMITIVE_LINES)
			im.surface_add_vertex(drain_line.to_local(from))
			im.surface_add_vertex(drain_line.to_local(end_point))
			im.surface_end()

		await get_tree().create_timer(drain_tick).timeout
		if not is_instance_valid(self) or is_dead:
			_stop_drain()
			return

	_stop_drain()
