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
var _forced_next_attack: String = ""

# Contact damage / slow aura — slime "absorbe" si te toca.
const CONTACT_TICK: float = 0.4      # cada 0.4s aplica daño
const CONTACT_DAMAGE: float = 4.0    # daño por tick
const CONTACT_SLOW: float = 0.2      # multiplicador de velocidad del player en contacto (0.2 = 80% slower)
var _contact_timer: float = 0.0
var _players_in_contact: Array = []

# Modo furia (Fase 4) — se activa una vez al entrar a fase 4.
var _fury_active: bool = false
const FURY_SPEED_MULT: float = 1.5
const FURY_DAMAGE_MULT: float = 1.35  # +35% daño — observable en los números de golpe

# Último aliento — se dispara una sola vez cuando hp <= 5%.
var _last_breath_triggered: bool = false
const LAST_BREATH_HP_PCT: float = 0.05

# Mini-slimes invocados activos — para reabsorción.
var _spawned_minis: Array = []

# Reabsorción mini-slime: distancia máxima al boss para tragárselo + cura.
const REABSORB_RADIUS: float = 4.0
const REABSORB_DELAY: float = 10.0
const REABSORB_HEAL: float = 30.0


func _on_enemy_ready() -> void:
	print("[KingSlime] >>> READY <<< script v=S2 | hp=", health, " damage=", damage)
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
		_attach_gelatin_overlay(body)


func _on_contact_aura_exited(body: Node) -> void:
	_players_in_contact.erase(body)
	_restore_player_speed(body)
	_detach_gelatin_overlay(body)


# ── Overlay verde "dentro del slime" ──────────────────────────────────
# ColorRect fullscreen hijo del player. Feel: estás metido en gelatina.
func _attach_gelatin_overlay(body: Node) -> void:
	if not is_instance_valid(body):
		return
	if body.has_node("KingSlimeGelatinOverlay"):
		return
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "KingSlimeGelatinOverlay"
	layer.layer = 50
	var rect: ColorRect = ColorRect.new()
	rect.name = "Tint"
	rect.color = Color(0.2, 0.85, 0.25, 0.4)
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	# Borde más oscuro (vignette simple): segundo ColorRect con gradient via shader simple.
	var edge: ColorRect = ColorRect.new()
	edge.name = "Edge"
	edge.anchor_right = 1.0
	edge.anchor_bottom = 1.0
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv) * 1.4;
	float a = smoothstep(0.35, 0.9, d) * 0.55;
	COLOR = vec4(0.05, 0.35, 0.1, a);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	edge.material = mat
	layer.add_child(edge)
	body.add_child(layer)


func _detach_gelatin_overlay(body: Node) -> void:
	if not is_instance_valid(body):
		return
	var layer: Node = body.get_node_or_null("KingSlimeGelatinOverlay")
	if layer:
		layer.queue_free()


func _restore_player_speed(body: Node) -> void:
	if is_instance_valid(body) and body.has_meta("king_slime_orig_speed"):
		body.speed = body.get_meta("king_slime_orig_speed")
		body.remove_meta("king_slime_orig_speed")


func _exit_tree() -> void:
	# Safety: si el boss muere/despawnea, restaurar speed y overlay de players.
	for p in _players_in_contact:
		_restore_player_speed(p)
		_detach_gelatin_overlay(p)


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
	# Último aliento — una sola vez cuando bajamos de 5% HP.
	if not _last_breath_triggered and _max_health > 0.0 and (health / _max_health) <= LAST_BREATH_HP_PCT:
		_trigger_last_breath()


func _update_phase() -> void:
	var hp_pct: float = health / _max_health if _max_health > 0.0 else 0.0
	var target_phase: Phase = Phase.ONE
	if hp_pct <= 0.25:
		target_phase = Phase.FOUR
	elif hp_pct <= 0.50:
		target_phase = Phase.THREE
	elif hp_pct <= 0.75:
		target_phase = Phase.TWO
	# Avanzar fase por fase — si el player tira 800 dmg en un golpe
	# queremos que igual se disparen _on_phase_changed de fase 2 Y 3 antes
	# de la 4 (spawns minis, charco, etc). Si no, se ven sólo los efectos
	# de la fase final.
	while int(current_phase) < int(target_phase):
		var next_int: int = int(current_phase) + 1
		match next_int:
			1: current_phase = Phase.TWO
			2: current_phase = Phase.THREE
			3: current_phase = Phase.FOUR
		print("[KingSlime] >>> FASE ", int(current_phase) + 1, " <<< hp=", health, "/", _max_health, " (", int(hp_pct * 100), "%)")
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
			# Spawn inmediato para que se note la transición aunque el player
			# mate rápido y no alcance el primer tick del timer.
			_summon_mini_slimes(3)
		Phase.THREE:
			summon_timer.wait_time = 15.0
			summon_timer.start()
			_summon_mini_slimes(5)
			# Charco de entrada — si el overkill mata al boss antes de rebotar,
			# igual queda un charco visible como marca de que entró a fase 3.
			_spawn_acid_pool(global_position)
			# Forzar un rebote inmediato → charco adicional al aterrizar.
			_force_combo_rebote_soon()
		Phase.FOUR:
			summon_timer.stop()
			_enter_fury()


# Al entrar fase 3, encolar combo rebote como próximo ataque (override).
func _force_combo_rebote_soon() -> void:
	_next_attack_cooldown = 0.5
	# Sobrescribir _pick_attack via flag one-shot
	_forced_next_attack = "combo_rebote"


# ── Modo furia (entrada Fase 4) ───────────────────────────────────────
func _enter_fury() -> void:
	if _fury_active:
		return
	_fury_active = true
	var old_speed: float = speed
	var old_dmg: float = damage
	speed *= FURY_SPEED_MULT
	damage *= FURY_DAMAGE_MULT
	# Emisión roja pulsante en el mesh del slime.
	var mi: MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mi and mi.mesh is SphereMesh:
		var sphere_mesh: SphereMesh = mi.mesh
		if sphere_mesh.material is StandardMaterial3D:
			var m: StandardMaterial3D = (sphere_mesh.material as StandardMaterial3D).duplicate()
			m.emission = Color(0.95, 0.15, 0.1)
			m.emission_energy_multiplier = 1.4
			sphere_mesh.material = m
		# Tween pulsante para que vibre visualmente
		var tw: Tween = create_tween().set_loops()
		tw.tween_property(mi, "scale", mi.scale * 1.08, 0.35)
		tw.tween_property(mi, "scale", mi.scale, 0.35)
	print("[KingSlime] ============================")
	print("[KingSlime] MODO FURIA ACTIVADO")
	print("[KingSlime] speed: ", old_speed, " → ", speed)
	print("[KingSlime] damage: ", old_dmg, " → ", damage)
	print("[KingSlime] ============================")


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
	print("[KingSlime] invocando ", count, " mini-slimes (fase ", int(current_phase) + 1, ")")
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
	if _forced_next_attack != "":
		_current_attack = _forced_next_attack
		_forced_next_attack = ""
	else:
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
		"combo_rebote":
			_attack_combo_rebote()
		"onda_choque":
			_attack_onda_choque()


func _pick_attack() -> String:
	# Híbrido: distancia decide base, fase decide variantes/intensidad.
	# - Fase 1: rebote simple, escupitajo simple.
	# - Fase 2: escupitajo → abanico.
	# - Fase 3: rebote → combo_rebote (y deja charco ácido on-land).
	# - Fase 4: cerca, 40% onda_choque en vez de embestida.
	var dist: float = INF
	if is_instance_valid(target):
		dist = global_position.distance_to(target.global_position)
	var spit: String = "escupitajo_abanico" if current_phase >= Phase.TWO else "escupitajo"
	var bounce: String = "combo_rebote" if current_phase >= Phase.THREE else "rebote"
	if dist > 12.0:
		return spit
	elif dist > 5.0:
		return bounce
	else:
		if current_phase == Phase.FOUR and randf() < 0.4:
			return "onda_choque"
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
	await _do_single_rebote(1.5, 0.9)
	if is_dead or not is_instance_valid(self):
		return
	_schedule_next_attack(4.0)


# Combo rebote (Fase 3+): 3 saltos rápidos, telegraph corto en el primero.
func _attack_combo_rebote() -> void:
	for i in 3:
		if is_dead or not is_instance_valid(self):
			return
		var tele: float = 1.0 if i == 0 else 0.3
		await _do_single_rebote(tele, 0.7)
	if is_dead or not is_instance_valid(self):
		return
	_schedule_next_attack(7.0)


# Un único rebote: telegraph → salto arco → land → AoE + charco (si fase ≥ 3).
func _do_single_rebote(telegraph: float, air_time: float) -> void:
	action_state = ActionState.TELEGRAPH
	await get_tree().create_timer(telegraph).timeout
	if is_dead or not is_instance_valid(self):
		return
	action_state = ActionState.EXECUTE

	var land_pos: Vector3 = target.global_position if is_instance_valid(target) else global_position
	velocity.y = 0.5 * gravity * air_time
	var dir: Vector3 = land_pos - global_position
	dir.y = 0.0
	if dir.length() > 0.1:
		var horiz: Vector3 = dir / air_time
		velocity.x = horiz.x
		velocity.z = horiz.z

	var max_wait: float = 2.5
	var elapsed: float = 0.0
	while elapsed < max_wait and not is_dead and is_instance_valid(self):
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
		if is_on_floor() and elapsed > 0.2:
			break

	if is_dead or not is_instance_valid(self):
		return
	velocity.x = 0.0
	velocity.z = 0.0
	_rebote_land_aoe()


func _rebote_land_aoe() -> void:
	var aoe_radius: float = 4.0
	var aoe_damage: float = base_damage_for_attack() + 10.0
	var knockback_up: float = 6.0
	var knockback_out: float = 10.0
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node3D and p.global_position.distance_to(global_position) <= aoe_radius:
			if p.has_method("take_damage"):
				p.take_damage(aoe_damage)
			if p is CharacterBody3D:
				var push: Vector3 = p.global_position - global_position
				push.y = 0.0
				if push.length() < 0.1:
					push = Vector3(1, 0, 0)
				push = push.normalized() * knockback_out
				push.y = knockback_up
				p.velocity = push
	# Fase 3+: charco ácido en el punto de aterrizaje.
	if current_phase >= Phase.THREE:
		_spawn_acid_pool(global_position)


# ── Charco ácido (Fase 3+) ────────────────────────────────────────────
# Area3D inline: cilindro verde + DoT. Radio 2m, 3 dmg/s, dura 5s.
func _spawn_acid_pool(pos: Vector3) -> void:
	var pool: Area3D = Area3D.new()
	pool.name = "AcidPool"
	pool.monitoring = true
	pool.monitorable = false
	pool.collision_mask = 1

	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 2.0
	cyl.height = 0.5
	cs.shape = cyl
	pool.add_child(cs)

	var mesh_vis := MeshInstance3D.new()
	var cmesh := CylinderMesh.new()
	cmesh.top_radius = 2.0
	cmesh.bottom_radius = 2.0
	cmesh.height = 0.15
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.95, 0.15, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.8, 0.1)
	mat.emission_energy_multiplier = 0.6
	cmesh.material = mat
	mesh_vis.mesh = cmesh
	mesh_vis.position = Vector3(0, 0.08, 0)
	pool.add_child(mesh_vis)

	get_tree().current_scene.add_child(pool)
	pool.global_position = Vector3(pos.x, pos.y + 0.05, pos.z)

	_drive_acid_pool(pool)


# ── Onda de choque (Fase 4) ───────────────────────────────────────────
# Infla 0.6s, libera AoE 5m con knockback. Daño 8 + base.
func _attack_onda_choque() -> void:
	var telegraph: float = 0.6
	action_state = ActionState.TELEGRAPH
	var mi: MeshInstance3D = get_node_or_null("MeshInstance3D")
	var orig_scale: Vector3 = mi.scale if mi else Vector3.ONE
	if mi:
		var tw: Tween = create_tween()
		tw.tween_property(mi, "scale", orig_scale * 1.25, telegraph)
	await get_tree().create_timer(telegraph).timeout
	if is_dead or not is_instance_valid(self):
		return
	if mi:
		mi.scale = orig_scale
	action_state = ActionState.EXECUTE

	var aoe_radius: float = 5.0
	var aoe_damage: float = base_damage_for_attack() + 8.0
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node3D and p.global_position.distance_to(global_position) <= aoe_radius:
			if p.has_method("take_damage"):
				p.take_damage(aoe_damage)
			if p is CharacterBody3D:
				var push: Vector3 = p.global_position - global_position
				push.y = 0.0
				if push.length() < 0.1:
					push = Vector3(1, 0, 0)
				push = push.normalized() * 14.0
				push.y = 8.0
				p.velocity = push
	_schedule_next_attack(10.0)


# ── Último aliento (Fase 4, hp ≤ 5%) ──────────────────────────────────
# Pausa IA, infla 3s como telegraph masivo, explota AoE 8m 20 dmg y muere.
func _trigger_last_breath() -> void:
	if _last_breath_triggered or is_dead:
		return
	_last_breath_triggered = true
	action_state = ActionState.TELEGRAPH
	_next_attack_cooldown = 999.0  # bloquear cualquier otro ataque
	velocity = Vector3.ZERO
	print("[KingSlime] ÚLTIMO ALIENTO — 3s para explotar")

	var mi: MeshInstance3D = get_node_or_null("MeshInstance3D")
	var orig_scale: Vector3 = mi.scale if mi else Vector3.ONE
	if mi:
		var tw: Tween = create_tween()
		tw.tween_property(mi, "scale", orig_scale * 1.8, 3.0)

	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self):
		return

	var aoe_radius: float = 8.0
	var aoe_damage: float = base_damage_for_attack() + 20.0
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node3D and p.global_position.distance_to(global_position) <= aoe_radius:
			if p.has_method("take_damage"):
				p.take_damage(aoe_damage)
			if p is CharacterBody3D:
				var push: Vector3 = p.global_position - global_position
				push.y = 0.0
				if push.length() < 0.1:
					push = Vector3(1, 0, 0)
				push = push.normalized() * 18.0
				push.y = 10.0
				p.velocity = push
	# Morir — usar take_damage masivo para disparar la cadena de muerte de BaseEnemy.
	take_damage(health + 9999.0)


func _drive_acid_pool(pool: Area3D) -> void:
	const DOT: float = 3.0
	const TICK: float = 1.0
	const LIFETIME: float = 5.0
	var elapsed: float = 0.0
	while elapsed < LIFETIME and is_instance_valid(pool):
		await get_tree().create_timer(TICK).timeout
		if not is_instance_valid(pool):
			return
		elapsed += TICK
		for body in pool.get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(DOT)
	if is_instance_valid(pool):
		pool.queue_free()


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
