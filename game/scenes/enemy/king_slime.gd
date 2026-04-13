class_name KingSlime
extends BaseEnemy

## Boss piso 1 — pradera. Spec: game/docs/boss_king_slime_spec.md
## Sesión 1: state machine 4 fases + ataques Rebote/Embestida/Escupitajo.
## Sesiones futuras añaden: invocación mini-slimes, charcos ácido, modo furia.

signal phase_changed(phase: int)

enum Phase { ONE, TWO, THREE, FOUR }

enum ActionState { IDLE, PURSUE, TELEGRAPH, EXECUTE, RECOVER }

# Hook para sesiones futuras — sin uso Sesión 1, se deja seteable en Inspector.
@export var mini_slime_scene: PackedScene

var current_phase: Phase = Phase.ONE
var action_state: ActionState = ActionState.IDLE
var _last_attack: String = ""
var _next_attack_cooldown: float = 0.0
var _current_attack: String = ""


func _on_enemy_ready() -> void:
	# enemy_type se setea en .tscn — si quedó vacío, fallback
	if enemy_type == "" or enemy_type == "enemy_basic":
		enemy_type = "king_slime"
	sub_tier = SubTier.BOSS
	add_to_group("enemies")


# ──────────────────────────────────────────────────────────────────────
# State machine — reemplaza _physics_process de BaseEnemy para evitar
# la lógica chase/attack genérica. Gravedad + knockback siguen viniendo
# de BaseEnemy._apply_gravity.
# ──────────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if has_meta("is_preview"):
		return
	_update_nameplate()
	if is_dead:
		return

	_apply_gravity(delta)
	_validate_target()

	if target == null:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	match action_state:
		ActionState.IDLE, ActionState.PURSUE:
			_pursue_tick(delta)
		ActionState.TELEGRAPH, ActionState.EXECUTE, ActionState.RECOVER:
			# Durante telegraph/execute/recover el boss no persigue
			# (cada ataque controla su propio movimiento si lo necesita).
			pass

	move_and_slide()


func _pursue_tick(delta: float) -> void:
	var dist: float = global_position.distance_to(target.global_position)
	if dist > detection_range:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	_look_at_target()

	# Cooldown entre ataques
	_next_attack_cooldown -= delta
	if _next_attack_cooldown <= 0.0 and dist <= detection_range:
		_start_attack()
		return

	# Aproximarse si está lejos
	if dist > attack_range:
		_move_toward_target(delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0


# ──────────────────────────────────────────────────────────────────────
# Phase transitions
# ──────────────────────────────────────────────────────────────────────
func take_damage(amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0, attacker_str := 0) -> void:
	super(amount, hit_direction, knockback_force, attacker_str)
	if is_dead:
		return
	_update_phase()


func _update_phase() -> void:
	var hp_pct: float = health / _max_health if _max_health > 0.0 else 0.0
	var new_phase: Phase = current_phase
	if hp_pct <= 0.25:
		new_phase = Phase.FOUR
	elif hp_pct <= 0.50:
		new_phase = Phase.THREE
	elif hp_pct <= 0.75:
		new_phase = Phase.TWO
	else:
		new_phase = Phase.ONE
	if new_phase != current_phase:
		current_phase = new_phase
		phase_changed.emit(int(current_phase))


# ──────────────────────────────────────────────────────────────────────
# Ataques — Sesión 1: rebote, embestida, escupitajo (Fase 1+).
# Fases 2+ añaden más en sesiones futuras.
# ──────────────────────────────────────────────────────────────────────
func _start_attack() -> void:
	_current_attack = _pick_attack()
	_last_attack = _current_attack
	action_state = ActionState.TELEGRAPH
	match _current_attack:
		"rebote":
			_attack_rebote()
		"embestida":
			_attack_embestida()
		"escupitajo":
			_attack_escupitajo()


func _pick_attack() -> String:
	var pool: Array = []
	match current_phase:
		Phase.ONE:
			pool = ["rebote", "embestida", "escupitajo"]
		Phase.TWO, Phase.THREE, Phase.FOUR:
			# Sesiones futuras añaden ataques de fase superior.
			# Hasta entonces, fases 2-4 usan el pool de Fase 1.
			pool = ["rebote", "embestida", "escupitajo"]
	# Evitar repetir el mismo ataque dos veces seguidas si hay alternativas
	var filtered: Array = pool.filter(func(a: String) -> bool: return a != _last_attack)
	if filtered.is_empty():
		filtered = pool
	return filtered.pick_random()


# Multiplier de cooldown por fase — spec: reducir 15% por fase.
func _cooldown_mult() -> float:
	match current_phase:
		Phase.TWO: return 0.85
		Phase.THREE: return 0.72
		Phase.FOUR: return 0.61
		_: return 1.0


# ── Rebote ────────────────────────────────────────────────────────────
func _attack_rebote() -> void:
	var telegraph: float = 1.5
	await get_tree().create_timer(telegraph).timeout
	if is_dead or not is_instance_valid(self):
		return
	action_state = ActionState.EXECUTE

	# Salto arco hacia la posición actual del target — resolvemos aterrizaje
	# en _finish_rebote tras un timer corto (simula el tiempo en el aire).
	var land_pos: Vector3 = target.global_position if is_instance_valid(target) else global_position
	var air_time: float = 0.6
	velocity.y = 9.0
	# Desplazamiento horizontal distribuido en el tiempo aéreo.
	var dir: Vector3 = land_pos - global_position
	dir.y = 0.0
	if dir.length() > 0.1:
		var horiz: Vector3 = dir / air_time
		velocity.x = horiz.x
		velocity.z = horiz.z

	await get_tree().create_timer(air_time).timeout
	if is_dead or not is_instance_valid(self):
		return
	_finish_rebote()


func _finish_rebote() -> void:
	# AoE radio 3m alrededor del boss al aterrizar.
	var aoe_radius: float = 3.0
	var aoe_damage: float = base_damage_for_attack() + 10.0
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node3D and p.global_position.distance_to(global_position) <= aoe_radius:
			if p.has_method("take_damage"):
				p.take_damage(aoe_damage)
	_schedule_next_attack(4.0)


# ── Embestida ─────────────────────────────────────────────────────────
func _attack_embestida() -> void:
	var telegraph: float = 1.0
	# Pequeña "compresión" visual: encoger mesh 15% durante telegraph.
	if mesh:
		var tween: Tween = create_tween()
		tween.tween_property(mesh, "scale", mesh.scale * 0.85, telegraph * 0.5)
		tween.tween_property(mesh, "scale", mesh.scale, telegraph * 0.5)
	await get_tree().create_timer(telegraph).timeout
	if is_dead or not is_instance_valid(self):
		return
	action_state = ActionState.EXECUTE

	# Dash rápido hacia target durante 0.6s
	var dash_time: float = 0.6
	var dash_speed: float = 12.0
	if is_instance_valid(target):
		var dir: Vector3 = target.global_position - global_position
		dir.y = 0.0
		dir = dir.normalized()
		velocity.x = dir.x * dash_speed
		velocity.z = dir.z * dash_speed

	# Chequeo de colisión con target durante el dash
	var hit_registered: bool = false
	var elapsed: float = 0.0
	while elapsed < dash_time and not is_dead and is_instance_valid(self):
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
		if hit_registered or not is_instance_valid(target):
			continue
		if global_position.distance_to(target.global_position) <= 2.5:
			if target.has_method("take_damage"):
				target.take_damage(base_damage_for_attack() + 12.0)
			hit_registered = true

	if is_dead or not is_instance_valid(self):
		return
	velocity.x = 0.0
	velocity.z = 0.0
	_schedule_next_attack(5.0)


# ── Escupitajo ────────────────────────────────────────────────────────
func _attack_escupitajo() -> void:
	var telegraph: float = 0.8
	await get_tree().create_timer(telegraph).timeout
	if is_dead or not is_instance_valid(self):
		return
	action_state = ActionState.EXECUTE

	# Proyectil inline: CSGSphere + Area3D con seguimiento lineal 3s de vida.
	_spawn_spit_projectile()
	_schedule_next_attack(3.0)


func _spawn_spit_projectile() -> void:
	if not is_instance_valid(target):
		return
	var origin: Vector3 = global_position + Vector3(0, 1.5, 0)
	var dir: Vector3 = (target.global_position + Vector3(0, 1.0, 0)) - origin
	dir = dir.normalized()

	var proj: Area3D = Area3D.new()
	proj.name = "SpitProjectile"
	proj.monitoring = true
	proj.monitorable = false

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.3
	shape.shape = sphere
	proj.add_child(shape)

	var mesh_vis := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.3
	sm.height = 0.6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.9, 0.3, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.7, 0.1)
	mat.emission_energy_multiplier = 0.8
	sm.material = mat
	mesh_vis.mesh = sm
	proj.add_child(mesh_vis)

	get_tree().current_scene.add_child(proj)
	proj.global_position = origin

	var damage: float = base_damage_for_attack() + 8.0
	var speed_proj: float = 18.0
	var lifetime: float = 3.0
	proj.set_meta("dir", dir)
	proj.set_meta("damage", damage)
	proj.set_meta("speed", speed_proj)
	proj.set_meta("lifetime", lifetime)

	proj.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage)
			proj.queue_free()
	)

	# Movimiento y despawn por lifetime via callable attached al arbol
	_drive_projectile(proj)


func _drive_projectile(proj: Area3D) -> void:
	var dir: Vector3 = proj.get_meta("dir")
	var speed_proj: float = proj.get_meta("speed")
	var lifetime: float = proj.get_meta("lifetime")
	var elapsed: float = 0.0
	while elapsed < lifetime and is_instance_valid(proj):
		await get_tree().physics_frame
		if not is_instance_valid(proj):
			return
		var dt: float = get_physics_process_delta_time()
		proj.global_position += dir * speed_proj * dt
		elapsed += dt
	if is_instance_valid(proj):
		proj.queue_free()


# ──────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────
func base_damage_for_attack() -> float:
	# Daño base del boss + el damage del ataque suman en cada ataque.
	return damage


func _schedule_next_attack(base_cooldown: float) -> void:
	_next_attack_cooldown = base_cooldown * _cooldown_mult()
	action_state = ActionState.PURSUE
	_current_attack = ""
