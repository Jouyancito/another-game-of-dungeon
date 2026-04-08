extends CharacterBody3D

# Stats del enemigo
@export var speed := 3.0
@export var health := 100.0
@export var damage := 10.0
@export var attack_range := 2.0
@export var detection_range := 15.0
@export var xp_reward := 30.0

# Cooldown de ataque
@export var attack_cooldown := 1.0

# Estado del enemigo
var target: Node3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_dead := false
var can_attack := true

# Referencia al mesh para cambiar color
@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	# Buscar al jugador
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Aplicar gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Si no hay objetivo, no hacer nada
	if target == null:
		return

	# Calcular distancia al jugador
	var distance = global_position.distance_to(target.global_position)

	# Si el jugador está dentro del rango de detección
	if distance <= detection_range:
		# Mirar hacia el jugador
		var look_pos = target.global_position
		look_pos.y = global_position.y
		look_at(look_pos)

		# Si está fuera del rango de ataque, moverse hacia el jugador
		if distance > attack_range:
			var direction = (target.global_position - global_position).normalized()
			direction.y = 0
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			# Está en rango de ataque — detenerse y atacar
			velocity.x = 0
			velocity.z = 0
			if can_attack and target.has_method("take_damage"):
				perform_attack()
	else:
		# Fuera de rango de detección — quedarse quieto
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func perform_attack() -> void:
	can_attack = false
	target.take_damage(damage)
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_dead:
		can_attack = true

func take_damage(amount: float) -> void:
	if is_dead:
		return
	health -= amount

	# Efecto visual de daño — ponerse rojo brevemente
	if mesh:
		var material = mesh.get_surface_override_material(0)
		if material == null:
			material = mesh.mesh.surface_get_material(0)
			if material:
				material = material.duplicate()
				mesh.set_surface_override_material(0, material)
		if material and material is StandardMaterial3D:
			material.albedo_color = Color(1, 0, 0)
			# Volver al color original después de 0.2 segundos
			await get_tree().create_timer(0.2).timeout
			if not is_dead:
				material.albedo_color = Color(0.8, 0.2, 0.2)

	if health <= 0:
		die()

func die() -> void:
	is_dead = true
	remove_from_group("enemies")
	var col = get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", true)
	# Dar XP al jugador
	if target and target.has_method("gain_xp"):
		target.gain_xp(xp_reward)
	# Animación simple de muerte — encogerse
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.5)
	tween.tween_callback(queue_free)
