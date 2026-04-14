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

# Contact damage / slow aura — slime "absorbe" si te toca.
const CONTACT_TICK: float = 0.4      # cada 0.4s aplica daño
const CONTACT_DAMAGE: float = 4.0    # daño por tick
const CONTACT_SLOW: float = 0.2      # multiplicador de velocidad del player en contacto (0.2 = 80% slower)
var _contact_timer: float = 0.0
var _players_in_contact: Array = []

# Mini-slimes invocados activos — para reabsorción.
var _spawned_minis: Array = []

# Reabsorción mini-slime: distancia máxima al boss para tragárselo + cura.
const REABSORB_RADIUS: float = 4.0
const REABSORB_DELAY: float = 10.0
const REABSORB_HEAL: float = 30.0


func _on_enemy_ready() -> void:
	# enemy_type se setea en .tscn — si quedó vacío, fallback
	if enemy_type == "" or enemy_type == "enemy_basic":
		enemy_type = "king_slime"
	sub_tier = SubTier.BOSS
	add_to_group("enemies")
	_setup_contact_aura()
	call_deferred("_setup_player_passthrough")
	phase_changed.connect(_on_phase_changed)
	var summon_timer: Timer = get_node_or_null("SummonTimer")
	if summon_timer:
		summon_timer.timeout.connect(_on_summon_timer_timeout)


func _setup_player_passthrough() -> void:
	# Ignora físicamente al player (no lo bloquea, no lo empuja) pero sigue
	# existiendo en su layer para que raycasts de ataque lo detecten.
	for p in get_tree().get_nodes_in_group("player"):
		if p is PhysicsBody3D:
			add_collision_exception_with(p)


func _setup_contact_aura() -> void:
	# Area3D envolviendo el cuerpo del boss. Detecta player en contacto
	# para daño tick + slow. No usa CollisionShape física — solo sensor.
	var aura := Area3D.new()
	aura.name = "ContactAura"
	aura.monitoring = true
	aura.monitorable = false
	aura.collision_mask = 1  # player está en layer 1 por default (ver CLAUDE.md vs tscn inconsistencia)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 3.2
	cap.height = 6.4
	cs.transform.origin = Vector3(0, 3.0, 0)  # centrar a la altura del mesh
	cs.shape = cap
	aura.add_child(cs)
	add_child(aura)
	aura.body_entered.connect(_on_contact_aura_entered)
	aura.body_exited.connect(_on_contact_aura_exited)


func _on_contact_aura_entered(body: Node) -> void:
	if body.is_in_group("player") and not _players_in_contact.has(body):
		_players_in_contact.append(body)
		# Guardar speed original y aplicar slow al stat directamente.
		if "speed" in body and not body.has_meta("king_slime_orig_speed"):
			body.set_meta("king_slime_orig_speed", body.speed)
			body.speed = body.speed * CONTACT_SLOW


func _on_contact_aura_exited(body: Node) -> void:
	_players_in_contact.erase(body)
	_restore_player_speed(body)


func _restore_player_speed(body: Node) -> void:
	if is_instance_valid(body) and body.has_meta("king_slime_orig_speed"):
		body.speed = body.get_meta("king_slime_orig_speed")
		body.remove_meta("king_slime_orig_speed")


func _exit_tree() -> void:
	# Safety: si el boss muere/despawnea, restaurar speed de todos los players.
	for p in _players_in_contact:
		_restore_player_speed(p)


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
	_contact_aura_tick(delta)

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
		print("[KingSlime] entró fase ", current_phase, " (hp_pct=", hp_pct, ")")
		phase_changed.emit(int(current_phase))


# ──────────────────────────────────────────────────────────────────────
# Phase transition handler — arranca/detiene timers, modo furia, etc.
# ──────────────────────────────────────────────────────────────────────
func _on_phase_changed(_phase: int) -> void:
	var summon_timer: Timer = get_node_or_null("SummonTimer")
	if summon_timer == null:
		return
	match current_phase:
		Phase.TWO:
			summon_timer.wait_time = 20.0
			summon_timer.start()
		Phase.THREE:
			summon_timer.wait_time = 15.0
			summon_timer.start()
		Phase.FOUR:
			summon_timer.stop()


# ──────────────────────────────────────────────────────────────────────
# Invocación mini-slimes + reabsorción
# ──────────────────────────────────────────────────────────────────────
func _on_summon_timer_timeout() -> void:
	if is_dead or current_phase == Phase.FOUR:
		return
	var count: int = 5 if current_phase == Phase.THREE else 3
	_summon_mini_slimes(count)


func _summon_mini_slimes(count: int) -> void:
	if mini_slime_scene == null:
		push_warning("[KingSlime] mini_slime_scene NO seteada en Inspector — invocación skipeada")
		return
	var scene_root: Node = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return
	for i in count:
		var mini: Node = mini_slime_scene.instantiate()
		scene_root.add_child(mini)
		if mini is Node3D:
			var angle: float = (TAU / count) * i
			var offset: Vector3 = Vector3(cos(angle) * 3.0, 1.5, sin(angle) * 3.0)
			(mini as Node3D).global_position = global_position + offset
		_spawned_minis.append(mini)
		_track_reabsorb(mini)


func _track_reabsorb(mini: Node) -> void:
	await get_tree().create_timer(REABSORB_DELAY).timeout
	if not is_instance_valid(self) or is_dead:
		return
	if not is_instance_valid(mini):
		_spawned_minis.erase(mini)
		return
	var dist: float = INF
	if mini is Node3D:
		dist = (mini as Node3D).global_position.distance_to(global_position)
	if dist <= REABSORB_RADIUS:
		health = minf(health + REABSORB_HEAL, _max_health)
		print("[KingSlime] reabsorbió mini @ dist=", dist, " hp=", health)
		mini.queue_free()
	_spawned_minis.erase(mini)


# ──────────────────────────────────────────────────────────────────────
# Ataques — Sesión 1: rebote, embestida, escupitajo (Fase 1+).
# Fases 2+ añaden más en sesiones futuras.
# ──────────────────────────────────────────────────────────────────────
func _contact_aura_tick(delta: float) -> void:
	# Daño tick + slow mientras haya player en contacto.
	if _players_in_contact.is_empty():
		_contact_timer = 0.0
		return
	# Damage tick (slow se aplica vía speed stat en enter/exit, no acá)
	_contact_timer += delta
	if _contact_timer >= CONTACT_TICK:
		_contact_timer = 0.0
		for p in _players_in_contact:
			if is_instance_valid(p) and p.has_method("take_damage"):
				p.take_damage(CONTACT_DAMAGE)


func _debug_perform(attack: String) -> void:
	# DEBUG: forzar ataque desde input (tecla 1/2/3 en floor1_prairie).
	if is_dead or not is_instance_valid(self):
		return
	if action_state != ActionState.IDLE and action_state != ActionState.PURSUE:
		print("[KingSlime] ocupado (", action_state, ") — esperá a que termine")
		return
	_current_attack = attack
	_last_attack = attack
	action_state = ActionState.TELEGRAPH
	print("[KingSlime] DEBUG FORCE=", attack)
	match attack:
		"rebote":
			_attack_rebote()
		"embestida":
			_attack_embestida()
		"escupitajo":
			_attack_escupitajo()


func _start_attack() -> void:
	_current_attack = _pick_attack()
	_last_attack = _current_attack
	action_state = ActionState.TELEGRAPH
	print("[KingSlime] ATTACK=", _current_attack, " phase=", current_phase, " dist=", global_position.distance_to(target.global_position) if is_instance_valid(target) else -1.0)
	match _current_attack:
		"rebote":
			_attack_rebote()
		"embestida":
			_attack_embestida()
		"escupitajo":
			_attack_escupitajo()
		"escupitajo_abanico":
			_attack_escupitajo_abanico()


func _pick_attack() -> String:
	# Selección por distancia al target + escalado por fase.
	# Fase 2+: escupitajo → escupitajo_abanico (3 proyectiles).
	# Fase 4: cerca, 40% chance de onda_choque vs embestida.
	var dist: float = INF
	if is_instance_valid(target):
		dist = global_position.distance_to(target.global_position)
	var spit: String = "escupitajo_abanico" if current_phase >= Phase.TWO else "escupitajo"
	if dist > 12.0:
		return spit
	elif dist > 5.0:
		return "rebote"
	else:
		return "embestida"


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

	# Arco simétrico: apex ~0.45s, land ~0.9s. Jump calc para cubrir h=4m.
	var land_pos: Vector3 = target.global_position if is_instance_valid(target) else global_position
	var air_time: float = 0.9
	velocity.y = 0.5 * gravity * air_time  # ~4.4 con gravity 9.8
	var dir: Vector3 = land_pos - global_position
	dir.y = 0.0
	if dir.length() > 0.1:
		var horiz: Vector3 = dir / air_time
		velocity.x = horiz.x
		velocity.z = horiz.z

	# Esperar hasta que toque el suelo (o timeout por seguridad)
	var max_wait: float = 2.5
	var elapsed: float = 0.0
	while elapsed < max_wait and not is_dead and is_instance_valid(self):
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
		if is_on_floor() and elapsed > 0.2:  # skip primer frame
			break

	if is_dead or not is_instance_valid(self):
		return
	velocity.x = 0.0
	velocity.z = 0.0
	_finish_rebote()


func _finish_rebote() -> void:
	# AoE radio 4m alrededor del punto de aterrizaje del boss.
	var aoe_radius: float = 4.0
	var aoe_damage: float = base_damage_for_attack() + 10.0
	var knockback_up: float = 6.0
	var knockback_out: float = 10.0
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node3D and p.global_position.distance_to(global_position) <= aoe_radius:
			if p.has_method("take_damage"):
				p.take_damage(aoe_damage)
			# Empujar al player hacia afuera + arriba — evita que boss se quede encima.
			if p is CharacterBody3D:
				var push: Vector3 = p.global_position - global_position
				push.y = 0.0
				if push.length() < 0.1:
					push = Vector3(1, 0, 0)  # fallback si overlap exacto
				push = push.normalized() * knockback_out
				push.y = knockback_up
				p.velocity = push
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


# ── Escupitajo abanico (Fase 2+) ──────────────────────────────────────
func _attack_escupitajo_abanico() -> void:
	var telegraph: float = 0.8
	await get_tree().create_timer(telegraph).timeout
	if is_dead or not is_instance_valid(self):
		return
	action_state = ActionState.EXECUTE
	# 3 proyectiles abanico ±15°
	_spawn_spit_projectile(-15.0)
	_spawn_spit_projectile(0.0)
	_spawn_spit_projectile(15.0)
	_schedule_next_attack(3.5)


func _spawn_spit_projectile(angle_offset_deg: float = 0.0) -> void:
	if not is_instance_valid(target):
		return
	var origin: Vector3 = global_position + Vector3(0, 1.5, 0)
	var dir: Vector3 = (target.global_position + Vector3(0, 1.0, 0)) - origin
	dir = dir.normalized()
	if angle_offset_deg != 0.0:
		dir = dir.rotated(Vector3.UP, deg_to_rad(angle_offset_deg))

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
