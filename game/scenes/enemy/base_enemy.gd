class_name BaseEnemy
extends CharacterBody3D

## Tipos de agresividad
enum AggressionType { AGGRESSIVE, NEUTRAL }

## Sub-tier dentro de un piso — define el rol del enemigo en el ecosistema
enum SubTier { A, B, C, BOSS }

# Stats base
@export var speed := 3.0
@export var health := 100.0
@export var damage := 10.0
@export var attack_range := 2.0
@export var detection_range := 15.0
@export var xp_reward := 30.0
@export var attack_cooldown := 1.0
@export var aggression: AggressionType = AggressionType.AGGRESSIVE
@export var enemy_type: String = "enemy_basic"  # Clave para LootTable

# Tier — define la peligrosidad y el badge en el target frame
@export var enemy_tier: int = 1  # Tier = piso de procedencia (1-100)
@export var sub_tier: SubTier = SubTier.A  # A=fauna, B=depredador, C=alfa, BOSS=jefe

# Knockback
@export var mass := 1.0  # 0.5 = liviano (slime), 1.0 = normal, 5.0 = pesado (boss)
@export var knockback_resistance := 0.0  # 0.0 = sin resistencia, 1.0 = inmune

# Estado
var target: Node3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var knockback_velocity := Vector3.ZERO
var is_dead := false
var can_attack := true
var is_provoked := false  # Para neutrales: se activa al recibir daño

# Nameplate
@export var display_name: String = ""
@export var enemy_level: int = 1

# Offset para target frame (altura del "centro visible").
# Enemigos bajos (rat, slime): 0.8. Bosses grandes (king_slime): 3.0+.
@export var target_frame_offset: Vector3 = Vector3(0, 0.8, 0)
const NAMEPLATE_VISIBLE_RANGE := 15.0
const NAMEPLATE_AIM_RANGE := 30.0

# Referencia al mesh — cada hijo define su nodo
@onready var mesh: MeshInstance3D = $MeshInstance3D

# Color original del mesh (cada hijo lo define)
var default_color := Color(0.8, 0.2, 0.2)

# Nameplate nodes
var _nameplate: Node3D
var _name_label: Label3D
var _hp_bar_bg: MeshInstance3D
var _hp_bar_fill: MeshInstance3D
var _max_health: float
var _sighted_once := false  # flag para Journal.sight — evitar spam cada frame


func _ready() -> void:
	await get_tree().process_frame
	var is_preview: bool = has_meta("is_preview")
	if not is_preview:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
	_on_enemy_ready()
	_max_health = health
	if not is_preview:
		_setup_nameplate()


func get_tier_label() -> String:
	var tier_names := {SubTier.A: "A", SubTier.B: "B", SubTier.C: "C", SubTier.BOSS: "BOSS"}
	return "T%d %s" % [enemy_tier, tier_names.get(sub_tier, "?")]


func get_display_name() -> String:
	if display_name != "":
		return display_name
	return scene_file_path.get_file().get_basename().capitalize()


## Override en subclases para setup específico
func _on_enemy_ready() -> void:
	pass


func _setup_nameplate() -> void:
	# Determinar nombre para mostrar
	var show_name: String = display_name
	if show_name == "":
		# Auto-detect from scene filename
		show_name = scene_file_path.get_file().get_basename().capitalize()

	# Root del nameplate (billboard — siempre mira la cámara)
	_nameplate = Node3D.new()
	_nameplate.name = "Nameplate"
	add_child(_nameplate)

	# Posicionar encima del enemigo
	var height_offset := 2.0
	var col: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if col:
		height_offset = col.position.y + 1.2
	_nameplate.position = Vector3(0, height_offset, 0)
	_nameplate.visible = false

	# Nombre + Nivel
	_name_label = Label3D.new()
	_name_label.name = "NameLabel"
	_name_label.text = "%s  Lv.%d" % [show_name, enemy_level]
	_name_label.font_size = 32
	_name_label.pixel_size = 0.00055  # ajuste final — legible sin saturar
	_name_label.fixed_size = true
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.no_depth_test = true
	_name_label.width = 600.0  # ancho suficiente para "Bandido Arquero Lv.1"
	_name_label.modulate = Color(1, 1, 1, 0.9)
	_name_label.outline_modulate = Color(0, 0, 0, 0.8)
	_name_label.outline_size = 6
	_name_label.position = Vector3(0, 0.12, 0)
	_nameplate.add_child(_name_label)

	# Barra HP — fondo (gris oscuro)
	var bar_width := 0.8
	var bar_height := 0.06
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.2, 0.2, 0.2, 0.8)
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg_mat.no_depth_test = true
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_hp_bar_bg = MeshInstance3D.new()
	_hp_bar_bg.name = "HPBarBG"
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(bar_width, bar_height)
	bg_mesh.material = bg_mat
	_hp_bar_bg.mesh = bg_mesh
	_nameplate.add_child(_hp_bar_bg)

	# Barra HP — relleno (verde → rojo según vida)
	var fill_mat := StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.2, 0.8, 0.2, 0.9)
	fill_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fill_mat.no_depth_test = true
	fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_hp_bar_fill = MeshInstance3D.new()
	_hp_bar_fill.name = "HPBarFill"
	var fill_mesh := QuadMesh.new()
	fill_mesh.size = Vector2(bar_width, bar_height)
	fill_mesh.material = fill_mat
	_hp_bar_fill.mesh = fill_mesh
	_nameplate.add_child(_hp_bar_fill)


func _update_nameplate() -> void:
	if _nameplate == null or target == null:
		return
	# No actualizar el nameplate si el enemigo está muerto (evita que el tween
	# de muerte arrastre también el nameplate encogiéndolo)
	if is_dead:
		_nameplate.visible = false
		return

	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		_nameplate.visible = false
		return

	var dist: float = global_position.distance_to(cam.global_position)

	# Siempre visible si está cerca (<12m)
	# Visible hasta 25m si el jugador apunta al enemigo (centro de pantalla)
	var show := false
	if dist <= NAMEPLATE_VISIBLE_RANGE:
		show = true
	elif dist <= NAMEPLATE_AIM_RANGE:
		# Check si la cámara apunta hacia este enemigo (dot product)
		var to_enemy: Vector3 = (global_position - cam.global_position).normalized()
		var cam_forward: Vector3 = -cam.global_transform.basis.z.normalized()
		if to_enemy.dot(cam_forward) > 0.95:  # ~18 grados
			show = true

	_nameplate.visible = show

	# Registrar avistamiento en el diario UNA SOLA VEZ (no cada frame)
	if show and not _sighted_once and Journal:
		Journal.sight(enemy_type)
		_sighted_once = true

	if not show:
		return

	# Actualizar barra de HP
	var hp_ratio: float = health / _max_health if _max_health > 0 else 0.0
	hp_ratio = clampf(hp_ratio, 0.0, 1.0)

	# Escala horizontal del fill según vida
	_hp_bar_fill.scale.x = hp_ratio
	# Offset para que la barra se vacíe de derecha a izquierda
	_hp_bar_fill.position.x = -(1.0 - hp_ratio) * 0.25

	# Color: verde → amarillo → rojo
	var fill_mat: StandardMaterial3D = _hp_bar_fill.mesh.material as StandardMaterial3D
	if fill_mat:
		if hp_ratio > 0.5:
			fill_mat.albedo_color = Color(0.2, 0.8, 0.2, 0.9)  # verde
		elif hp_ratio > 0.25:
			fill_mat.albedo_color = Color(0.9, 0.8, 0.1, 0.9)  # amarillo
		else:
			fill_mat.albedo_color = Color(0.9, 0.2, 0.1, 0.9)  # rojo


func _physics_process(delta: float) -> void:
	if has_meta("is_preview"):
		return
	_update_nameplate()

	if is_dead:
		return

	_apply_gravity(delta)
	_validate_target()

	if target == null:
		_idle_behavior(delta)
		move_and_slide()
		return

	var distance = global_position.distance_to(target.global_position)
	var should_chase = _should_pursue(distance)

	if should_chase and distance <= detection_range:
		_look_at_target()

		if distance > attack_range:
			_move_toward_target(delta)
		else:
			velocity.x = 0
			velocity.z = 0
			if can_attack and target.has_method("take_damage"):
				perform_attack()
	else:
		_idle_behavior(delta)

	move_and_slide()


## Determina si este enemigo debería perseguir al jugador
func _should_pursue(distance: float) -> bool:
	if aggression == AggressionType.AGGRESSIVE:
		return distance <= detection_range
	# NEUTRAL: solo si fue provocado
	return is_provoked and distance <= detection_range


## Comportamiento cuando no persigue — override para deambular
func _idle_behavior(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0


## Movimiento hacia el target — override para movimiento custom (ej: saltos)
func _move_toward_target(_delta: float) -> void:
	var direction = (target.global_position - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Aplicar knockback como impulso directo (no acumulativo)
	if knockback_velocity.length() > 0.1:
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
		if knockback_velocity.y > 0:
			velocity.y = knockback_velocity.y
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, delta * 10.0)
	else:
		knockback_velocity = Vector3.ZERO


## Aplica knockback al enemigo. hit_direction = dirección del golpe, force = fuerza base
func apply_knockback(hit_direction: Vector3, force: float, attacker_str: int = 0) -> void:
	if is_dead:
		return
	var effective_force = force + (attacker_str * 0.05)
	effective_force *= (1.0 - knockback_resistance) / maxf(mass, 0.3)
	knockback_velocity = hit_direction.normalized() * effective_force
	_on_knockback(knockback_velocity)


func _validate_target() -> void:
	if target != null and not is_instance_valid(target):
		target = null


func _look_at_target() -> void:
	var look_pos = target.global_position
	look_pos.y = global_position.y
	look_at(look_pos)


func perform_attack() -> void:
	can_attack = false
	if is_instance_valid(target):
		target.take_damage(damage)
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true


func take_damage(amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0, attacker_str := 0) -> void:
	if is_dead:
		return

	# Provocar si es neutral
	if aggression == AggressionType.NEUTRAL and not is_provoked:
		is_provoked = true

	health -= amount
	_flash_damage()

	if knockback_force > 0.0 and hit_direction != Vector3.ZERO:
		apply_knockback(hit_direction, knockback_force, attacker_str)

	if health <= 0:
		die()


func _flash_damage() -> void:
	if not mesh or not mesh.mesh:
		return
	var material = mesh.get_surface_override_material(0)
	if material == null:
		material = mesh.mesh.surface_get_material(0)
		if material:
			material = material.duplicate()
			mesh.set_surface_override_material(0, material)
	if material and material is StandardMaterial3D:
		material.albedo_color = Color(1, 0, 0)
		await get_tree().create_timer(0.2).timeout
		if not is_instance_valid(self) or is_dead:
			return
		material.albedo_color = default_color


func die() -> void:
	is_dead = true
	remove_from_group("enemies")
	var col = get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", true)
	if target and target.has_method("gain_xp"):
		target.gain_xp(xp_reward)
	# Registrar kill en el diario
	if Journal:
		Journal.record_kill(enemy_type)
	# Registrar kill en el tracker de títulos
	if TitleTracker:
		TitleTracker.on_enemy_killed(enemy_type)
	_spawn_loot()
	_on_death()
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.5)
	tween.tween_callback(queue_free)


func _spawn_loot() -> void:
	var loot: Dictionary = LootTable.roll(enemy_type)
	# DropController maneja spawn radial (anillo 1-2m, grid 0.5m dedup) + ground snap.
	DropController.spawn_drops(global_position, loot, self)


## Raycast hacia abajo desde pos para encontrar el suelo — evita que los drops floten.
func _ground_drop_position(pos: Vector3) -> Vector3:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var ray_from: Vector3 = pos + Vector3(0, 2.0, 0)
	var ray_to: Vector3 = pos + Vector3(0, -5.0, 0)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.exclude = [get_rid()]
	query.collision_mask = 1  # Layer World
	var hit: Dictionary = space.intersect_ray(query)
	if not hit.is_empty():
		return Vector3(pos.x, hit.position.y + 0.05, pos.z)
	# Fallback: 0.8m debajo (aprox feet level para la mayoría de enemigos)
	return pos - Vector3(0, 0.8, 0)


## Override para efectos de muerte custom
func _on_death() -> void:
	pass


## Override para reacciones de knockback custom (ej: slime jelly bounce)
func _on_knockback(_kb_velocity: Vector3) -> void:
	pass
