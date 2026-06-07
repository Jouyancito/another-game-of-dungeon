class_name Golem
extends BaseEnemy

## Golem de Piedra — NEUTRAL, se camufla como roca hasta que el jugador se acerca.
## Ataques: Puñetazo (melee + knockback), Pisotón AoE, Lanzar roca (rango).

var is_dormant := true
var awaken_tween: Tween
var attack_index := 0
var stomp_range := 3.0
var throw_range := 10.0

@onready var head_mesh: MeshInstance3D = $Head


func _on_enemy_ready() -> void:
	enemy_type = "golem"
	# Personalidad: lento imparable. Una vez despierto, jamás abandona la persecución.
	# speed_mult=0.7 lo hace más lento. JUGGERNAUT_SLOW + NEUTRAL + is_provoked (set en _awaken)
	# → el golem persigue hasta 999m de distancia desde que despertó.
	personality = AggroPersonality.JUGGERNAUT_SLOW
	default_color = Color(0.5, 0.5, 0.5)
	mass = 3.0
	knockback_resistance = 0.7
	mesh.visible = false
	# Also hide the Head mesh from .tscn
	var old_head: Node = get_node_or_null("Head")
	if old_head:
		old_head.visible = false

	# Load the orc gltf as the golem visual — the orc silhouette reads as a
	# heavy humanoid creature, which sells "stone golem" better than a BoxMesh.
	# We override the material at runtime with a stone/gray tint so it reads
	# as rock, not a green orc. Scale is exaggerated (1.5× width, 1.6× height)
	# to give the golem its heavy, stocky proportions.
	const ORC_PATH := "res://assets/art/piso1_pradera/enemies/big/enemy_orc.gltf"
	var packed: PackedScene = load(ORC_PATH) if ResourceLoader.exists(ORC_PATH) else null
	if packed != null:
		var model: Node3D = packed.instantiate()
		model.name = "Model"
		# Stone tint: desaturated warm grey, slightly rougher than skin
		var stone_mat := StandardMaterial3D.new()
		stone_mat.albedo_color = Color(0.58, 0.56, 0.52)   # warm stone grey
		stone_mat.roughness = 0.92
		stone_mat.metallic = 0.0
		# Apply to every MeshInstance3D in the full subtree — gltf models are
		# SKINNED so the mesh nodes live under a Skeleton3D, not as direct
		# children.  find_children recurses the whole tree.
		for child in model.find_children("*", "MeshInstance3D", true, false):
			child.material_override = stone_mat
		# Golem proportions: wider and taller than a normal orc
		model.scale = Vector3(1.5, 1.6, 1.5)
		model.rotation.y = PI  # Quaternius mira +Z; look_at apunta -Z → girar 180° (si no, camina de espaldas)
		add_child(model)
	else:
		# Fallback: procedural humanoid (graceful degradation)
		push_warning("Golem: enemy_orc.gltf not found, using proc mesh")
		var model := EnemyModelBuilder.build_humanoid(default_color, 1.5, 1.4)
		model.name = "Model"
		add_child(model)

	# Dormant: aplastado como roca — tween re-points to self.scale (unchanged)
	scale = Vector3(1.2, 0.5, 1.2)


## Override: NEUTRAL + lógica de despertar por proximidad
func _should_pursue(distance: float) -> bool:
	if is_dormant:
		if distance <= detection_range:
			_awaken()
		return false
	# Despierto: delega a BaseEnemy (respeta alert flag para aggro ranged)
	return super._should_pursue(distance)


func _awaken() -> void:
	if awaken_tween and awaken_tween.is_running():
		return
	awaken_tween = create_tween()
	awaken_tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.5)
	awaken_tween.tween_callback(func():
		is_dormant = false
		is_provoked = true
	)


## Idle: inmóvil, camuflado como roca
func _idle_behavior(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0


## Movimiento lento y deliberado — respeta speed_mult de JUGGERNAUT_SLOW (0.7×).
func _move_toward_target(_delta: float) -> void:
	var direction = (target.global_position - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * speed * speed_mult
	velocity.z = direction.z * speed * speed_mult


## Returns the gltf model root so EnemyAnimator can find the AnimationPlayer.
func _get_anim_model_root() -> Node3D:
	return get_node_or_null("Model")


## Override take_damage: si duerme, despertar antes de recibir daño
func take_damage(amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0, attacker_str := 0, attacker: Node = null, element: String = "physical", is_crit: bool = false) -> void:
	if is_dormant:
		_awaken()
	super.take_damage(amount, hit_direction, knockback_force, attacker_str, attacker, element, is_crit)


## Cicla entre 3 ataques: Puñetazo → Pisotón AoE → Lanzar roca
func perform_attack() -> void:
	if not can_attack:
		return
	can_attack = false

	match attack_index:
		0:
			_attack_punch()
		1:
			_attack_stomp()
		2:
			_attack_rock_throw()

	attack_index = (attack_index + 1) % 3

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self) or is_dead:
		return
	can_attack = true


## Puñetazo: daño base + knockback al target
func _attack_punch() -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		target.take_damage(damage * outgoing_damage_mult())
	if target.has_method("apply_knockback"):
		var direction = (target.global_position - global_position).normalized()
		target.apply_knockback(direction, 12.0)


## Pisotón AoE: daña a TODOS los jugadores dentro de stomp_range
func _attack_stomp() -> void:
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if not is_instance_valid(player):
			continue
		var dist = global_position.distance_to(player.global_position)
		if dist <= stomp_range and player.has_method("take_damage"):
			player.take_damage(damage * 0.8 * outgoing_damage_mult())


## Lanzar roca: daño a rango, sin proyectil — hit directo simplificado
func _attack_rock_throw() -> void:
	if not is_instance_valid(target):
		return
	var dist = global_position.distance_to(target.global_position)
	if dist <= throw_range and target.has_method("take_damage"):
		target.take_damage(damage * 0.6 * outgoing_damage_mult())


## Muerte: sin efecto extra por ahora
func _on_death() -> void:
	pass


## Knockback: el golem es muy pesado, reacción mínima
func _on_knockback(_kb_velocity: Vector3) -> void:
	pass
