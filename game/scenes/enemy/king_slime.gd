class_name KingSlime
extends BaseEnemy

## Boss piso 1 — pradera. Spec: game/docs/boss_king_slime_spec.md
## Sesión 1: state machine 4 fases + ataques Rebote/Embestida/Escupitajo.
## Sesiones futuras añaden: invocación mini-slimes, charcos ácido, modo furia.

signal phase_changed(phase: int)

enum Phase { ONE, TWO, THREE, FOUR }

enum ActionState { IDLE, PURSUE, TELEGRAPH, EXECUTE, RECOVER, SHIELDING }

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

# Shield pose — mientras hay minis vivos, boss se agazapa y reduce daño.
# Break cuando los minis caen a menos del threshold.
const SHIELD_MIN_MINIS: int = 2
const SHIELD_DAMAGE_MULT: float = 0.2      # recibe 20% del daño — shield DURO
const SHIELD_MINI_SPEED: float = 1.2       # minis forzados a esta speed (spec: "mucho más lentos")
const BOMB_INTERVAL: float = 2.0           # cada cuánto lanza baba bombardero durante shield
const BOMB_TELEGRAPH: float = 1.2          # tiempo entre marca en el suelo y impacto
const BOMB_AOE_RADIUS: float = 2.0
const BOMB_DAMAGE: float = 10.0

# Acid pool (charco) — radio más grande para forzar al melee a salirse.
const ACID_POOL_RADIUS: float = 5.5       # grande — el melee NO puede ignorarlo
const ACID_POOL_DOT: float = 7.0          # DPS serio: 7/s
const ACID_POOL_LIFETIME: float = 6.0
const ACID_POOL_SLOW_MULT: float = 0.5    # 50% slow — te cuesta salirte

# Slow aplicado por escupitajos y bombardero — 30% ralentización breve.
const PROJECTILE_SLOW_MULT: float = 0.7
const PROJECTILE_SLOW_DURATION: float = 2.0
const BOMB_SLOW_DURATION: float = 1.5
var _shielding: bool = false
var _bomb_timer: float = 0.0

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


# ──────────────────────────────────────────────────────────────────────
# Shield pose — boss se agazapa mientras minis vivos. Reduce daño +
# bombardea babas con marca en el suelo.
# ──────────────────────────────────────────────────────────────────────
func _update_shield_state() -> void:
	if is_dead:
		return
	# Contar minis vivos
	var alive: int = 0
	for m in _spawned_minis:
		if is_instance_valid(m):
			alive += 1
	var should_shield: bool = alive >= SHIELD_MIN_MINIS
	if should_shield and not _shielding:
		_enter_shield()
	elif not should_shield and _shielding:
		_exit_shield()


func _enter_shield() -> void:
	_shielding = true
	if action_state == ActionState.IDLE or action_state == ActionState.PURSUE:
		action_state = ActionState.SHIELDING
	_bomb_timer = BOMB_INTERVAL * 0.5
	velocity.x = 0.0
	velocity.z = 0.0
	# Animación "caída de resguardo" — single tween, sin loops.
	var mi: MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mi:
		var tw: Tween = create_tween()
		tw.tween_property(mi, "scale", Vector3(1.35, 0.55, 1.35), 0.18)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	print("[KingSlime] === SHIELD POSE === esperando minis (", _spawned_minis.size(), " vivos)")


func _exit_shield() -> void:
	_shielding = false
	if action_state == ActionState.SHIELDING:
		action_state = ActionState.PURSUE
	var mi: MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mi:
		var tw: Tween = create_tween()
		tw.tween_property(mi, "scale", Vector3.ONE, 0.2)
	print("[KingSlime] === SHIELD BREAK === vuelve al combate")


func _shield_tick(delta: float) -> void:
	# No avanza, no melee. Solo bombardea.
	velocity.x = 0.0
	velocity.z = 0.0
	_look_at_target()
	_bomb_timer -= delta
	if _bomb_timer <= 0.0:
		_bomb_timer = BOMB_INTERVAL
		_attack_baba_bombardero()


# ── Baba bombardero (durante shield) ──────────────────────────────────
# Telegraph: marca en el suelo donde va a caer. Impacto: AoE 2m.
func _attack_baba_bombardero() -> void:
	if not is_instance_valid(target):
		return
	var impact_pos: Vector3 = target.global_position
	impact_pos.y = global_position.y
	# Baba que gotea bajo el boss al disparar — deja charquito pequeño
	# temporal (penaliza al melee parado abajo).
	_spawn_drool_puddle(global_position)
	_spawn_ground_marker(impact_pos, BOMB_TELEGRAPH, BOMB_AOE_RADIUS)
	_spawn_bomb_baba(impact_pos, BOMB_TELEGRAPH, false)
	# Splatter: 5 sub-babas en patrón estrella alrededor del impacto,
	# escalonadas 0.15s. Cubre 4m radio alrededor del impacto principal.
	var splatter_count: int = 3
	var splatter_spread: float = 3.0
	for i in splatter_count:
		var ang: float = (TAU / splatter_count) * i + randf_range(-0.2, 0.2)
		var dist: float = splatter_spread * randf_range(0.6, 1.0)
		var sub_pos: Vector3 = impact_pos + Vector3(cos(ang) * dist, 0, sin(ang) * dist)
		var sub_delay: float = BOMB_TELEGRAPH + 0.3 + i * 0.15
		_spawn_ground_marker(sub_pos, sub_delay, 1.3)
		_spawn_bomb_baba(sub_pos, sub_delay, true)


func _spawn_ground_marker(pos: Vector3, lifetime: float, radius: float = BOMB_AOE_RADIUS) -> void:
	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.name = "BombMarker"
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.08
	var mat := StandardMaterial3D.new()
	# Opaco + emissive — transparencia en Godot es cara, la evitamos.
	mat.albedo_color = Color(0.9, 0.15, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.15)
	mat.emission_energy_multiplier = 1.5
	disc.material = mat
	marker.mesh = disc
	get_tree().current_scene.add_child(marker)
	marker.global_position = Vector3(pos.x, pos.y + 0.05, pos.z)
	# Pulso: escala crece hasta 1.0 durante el telegraph (feedback de "ya llega").
	marker.scale = Vector3(0.3, 1.0, 0.3)
	var tw: Tween = create_tween()
	tw.tween_property(marker, "scale", Vector3(1.1, 1.0, 1.1), lifetime)
	tw.tween_callback(func():
		if is_instance_valid(marker):
			marker.queue_free()
	)


func _spawn_bomb_baba(impact_pos: Vector3, delay: float, is_splatter: bool = false) -> void:
	var baba: Area3D = Area3D.new()
	baba.name = "BabaBomba"
	baba.monitoring = true
	baba.monitorable = false
	baba.collision_mask = 1
	baba.set_meta("is_splatter", is_splatter)

	var r: float = 0.35 if is_splatter else 0.5
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = r
	cs.shape = sph
	baba.add_child(cs)

	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.9, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.7, 0.1)
	mat.emission_energy_multiplier = 0.9
	sm.material = mat
	mi.mesh = sm
	baba.add_child(mi)

	get_tree().current_scene.add_child(baba)
	var start: Vector3 = global_position + Vector3(0, 8.0, 0)
	baba.global_position = start
	_drive_bomb_baba(baba, start, impact_pos, delay)


func _drive_bomb_baba(baba: Area3D, start: Vector3, impact: Vector3, duration: float) -> void:
	var elapsed: float = 0.0
	var apex: Vector3 = (start + impact) * 0.5 + Vector3(0, 4.0, 0)
	while elapsed < duration and is_instance_valid(baba):
		await get_tree().physics_frame
		if not is_instance_valid(baba):
			return
		var dt: float = get_physics_process_delta_time()
		elapsed += dt
		var t: float = clamp(elapsed / duration, 0.0, 1.0)
		# Bezier cuadrático start → apex → impact (arco).
		var a: Vector3 = start.lerp(apex, t)
		var b: Vector3 = apex.lerp(impact, t)
		baba.global_position = a.lerp(b, t)
	if not is_instance_valid(baba):
		return
	# Impacto: AoE + slow. Splatters hacen menos daño y radio menor.
	var is_splat: bool = baba.get_meta("is_splatter", false)
	var aoe: float = 1.3 if is_splat else BOMB_AOE_RADIUS
	var dmg: float = (BOMB_DAMAGE * 0.5) if is_splat else BOMB_DAMAGE
	for p in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p) or not p is Node3D:
			continue
		if p.global_position.distance_to(impact) <= aoe:
			if p.has_method("take_damage"):
				p.take_damage(base_damage_for_attack() + dmg)
			if is_instance_valid(p):
				_apply_slow(p, PROJECTILE_SLOW_MULT, BOMB_SLOW_DURATION)
	if is_instance_valid(baba):
		baba.queue_free()


# ── Helper: slow con restore vía timer ────────────────────────────────
# Aplica speed * mult por duration segundos. Meta clave única para no
# pisar el slow del ContactAura (que usa "king_slime_orig_speed").
func _apply_slow(body: Node, mult: float, duration: float) -> void:
	if not is_instance_valid(body):
		return
	if not "speed" in body:
		return
	var meta_key: String = "king_slime_proj_slow"
	if body.has_meta(meta_key):
		body.set_meta(meta_key + "_until", Time.get_ticks_msec() + int(duration * 1000))
		return
	var orig: float = body.speed
	body.set_meta(meta_key, orig)
	body.set_meta(meta_key + "_until", Time.get_ticks_msec() + int(duration * 1000))
	body.speed = orig * mult
	_slow_restore_watcher(body, meta_key)


func _slow_restore_watcher(body: Node, meta_key: String) -> void:
	while true:
		if not is_instance_valid(body):
			return
		if not body.has_meta(meta_key):
			return
		await get_tree().create_timer(0.1).timeout
		if not is_instance_valid(body):
			return
		if not body.has_meta(meta_key):
			return
		var until: int = body.get_meta(meta_key + "_until", 0)
		if Time.get_ticks_msec() >= until:
			if not is_instance_valid(body):
				return
			var orig: float = body.get_meta(meta_key, body.speed if "speed" in body else 0.0)
			if "speed" in body and not body.has_meta("king_slime_orig_speed"):
				body.speed = orig
			if is_instance_valid(body):
				body.remove_meta(meta_key)
				body.remove_meta(meta_key + "_until")
			return


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
		ActionState.SHIELDING:
			_shield_tick(delta)
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
	var final_amount: float = amount
	if _shielding:
		final_amount = amount * SHIELD_DAMAGE_MULT
	super(final_amount, hit_direction, knockback_force, attacker_str)
	if is_dead:
		return
	_update_phase()
	_update_shield_state()
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
		# NO loop tween acá — provocaba stacking con otros tweens de scale
		# (shield squash, onda_choque inflate) y hang del motor.
		# Feedback visual de furia es solo la emisión roja.
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
	# Limpiar entradas muertas antes de contar
	_spawned_minis = _spawned_minis.filter(func(m): return is_instance_valid(m))
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
		# Spec: "mucho más lentos" — cruza el cuerpo como gelatina, no como bicho ágil.
		if "speed" in mini:
			mini.speed = SHIELD_MINI_SPEED
		_spawned_minis.append(mini)
		_track_reabsorb(mini)
	# Activar shield después de invocar
	_update_shield_state()


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
		# Marcar is_dead antes del free para que el target_frame del player
		# lo skipee en el mismo frame (evita race "assign invalid freed instance").
		if "is_dead" in mini:
			mini.is_dead = true
		mini.call_deferred("queue_free")
	_spawned_minis.erase(mini)
	_update_shield_state()


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


# Combo rebote (Fase 3+): 4 saltos frenéticos, telegraph corto.
# User feedback: se podía tanquear — ahora más saltos + telegraphs cortos.
func _attack_combo_rebote() -> void:
	for i in 4:
		if is_dead or not is_instance_valid(self):
			return
		var tele: float = 0.7 if i == 0 else 0.2
		await _do_single_rebote(tele, 0.6)
	if is_dead or not is_instance_valid(self):
		return
	_schedule_next_attack(6.5)


# Un único rebote: telegraph → salto arco → land → AoE + charco (si fase ≥ 3).
func _do_single_rebote(telegraph: float, air_time: float) -> void:
	# Reset velocity al inicio para no acarrear state de ataques previos.
	velocity = Vector3.ZERO
	action_state = ActionState.TELEGRAPH
	await get_tree().create_timer(telegraph).timeout
	if is_dead or not is_instance_valid(self):
		return
	action_state = ActionState.EXECUTE

	var land_pos: Vector3 = target.global_position if is_instance_valid(target) else global_position
	velocity.y = 0.5 * gravity * air_time
	var dir: Vector3 = land_pos - global_position
	dir.y = 0.0
	# Cap horizontal: máx 8m de distancia por salto — evita "teleport".
	const MAX_JUMP_DIST: float = 8.0
	if dir.length() > MAX_JUMP_DIST:
		dir = dir.normalized() * MAX_JUMP_DIST
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
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node3D and p.global_position.distance_to(global_position) <= aoe_radius:
			if p.has_method("take_damage"):
				p.take_damage(aoe_damage)
			# Sin knockback — user feedback: frustra, rompe combate.
			# En su lugar: slow breve al recibir la onda.
			_apply_slow(p, 0.75, 0.6)
	# Onda de choque visual — ring que se expande en el suelo
	_spawn_shockwave_ring(global_position, aoe_radius)
	# Fase 3+: charco ácido en el punto de aterrizaje.
	if current_phase >= Phase.THREE:
		_spawn_acid_pool(global_position)


# Ring de onda de choque — puramente visual. Aparece al aterrizar un rebote
# y se expande hasta el radio del AoE en 0.4s, luego desvanece.
func _spawn_shockwave_ring(pos: Vector3, max_radius: float) -> void:
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.name = "ShockwaveRing"
	var torus := TorusMesh.new()
	torus.inner_radius = max_radius * 0.95
	torus.outer_radius = max_radius
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.85, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.3)
	mat.emission_energy_multiplier = 2.0
	torus.material = mat
	ring.mesh = torus
	get_tree().current_scene.add_child(ring)
	ring.global_position = Vector3(pos.x, pos.y + 0.15, pos.z)
	ring.scale = Vector3(0.2, 1.0, 0.2)
	var tw: Tween = create_tween()
	tw.tween_property(ring, "scale", Vector3(1.0, 1.0, 1.0), 0.4)
	tw.parallel().tween_property(ring, "scale:y", 0.2, 0.4)
	tw.tween_callback(func():
		if is_instance_valid(ring):
			ring.queue_free()
	)


# ── Charco ácido (Fase 3+) ────────────────────────────────────────────
# Area3D inline: cilindro verde + DoT. Radio 2m, 3 dmg/s, dura 5s.
# Charquito pequeño que gotea del boss mientras bombardea — versión lite
# del acid pool: radio menor, duración corta, DoT menor, sin slow.
func _spawn_drool_puddle(pos: Vector3) -> void:
	var pool: Area3D = Area3D.new()
	pool.name = "DroolPuddle"
	pool.monitoring = true
	pool.monitorable = false
	pool.collision_mask = 1
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 2.5
	cyl.height = 0.4
	cs.shape = cyl
	pool.add_child(cs)
	var mv := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 2.5
	cm.bottom_radius = 2.5
	cm.height = 0.1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.85, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.6, 0.15)
	mat.emission_energy_multiplier = 0.5
	cm.material = mat
	mv.mesh = cm
	pool.add_child(mv)
	get_tree().current_scene.add_child(pool)
	pool.global_position = Vector3(pos.x, pos.y + 0.03, pos.z)
	_drive_drool_puddle(pool)


func _drive_drool_puddle(pool: Area3D) -> void:
	const TICK: float = 0.5
	const LIFETIME: float = 3.0
	const DOT_DROOL: float = 3.0
	var elapsed: float = 0.0
	while elapsed < LIFETIME and is_instance_valid(pool):
		await get_tree().create_timer(TICK).timeout
		if not is_instance_valid(pool):
			return
		elapsed += TICK
		for body in pool.get_overlapping_bodies():
			if not is_instance_valid(body):
				continue
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(DOT_DROOL * TICK)
	if is_instance_valid(pool):
		pool.queue_free()


func _spawn_acid_pool(pos: Vector3) -> void:
	var pool: Area3D = Area3D.new()
	pool.name = "AcidPool"
	pool.monitoring = true
	pool.monitorable = false
	pool.collision_mask = 1

	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = ACID_POOL_RADIUS
	cyl.height = 0.5
	cs.shape = cyl
	pool.add_child(cs)

	var mesh_vis := MeshInstance3D.new()
	var cmesh := CylinderMesh.new()
	cmesh.top_radius = ACID_POOL_RADIUS
	cmesh.bottom_radius = ACID_POOL_RADIUS
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
	const TICK: float = 0.5
	var elapsed: float = 0.0
	while elapsed < ACID_POOL_LIFETIME and is_instance_valid(pool):
		await get_tree().create_timer(TICK).timeout
		if not is_instance_valid(pool):
			return
		elapsed += TICK
		for body in pool.get_overlapping_bodies():
			if not is_instance_valid(body):
				continue
			if body.is_in_group("player"):
				if body.has_method("take_damage"):
					body.take_damage(ACID_POOL_DOT * TICK)
				if is_instance_valid(body):
					_apply_slow(body, ACID_POOL_SLOW_MULT, 0.8)
	if is_instance_valid(pool):
		pool.queue_free()


# ── Embestida ─────────────────────────────────────────────────────────
func _attack_embestida() -> void:
	velocity = Vector3.ZERO
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
		if not is_instance_valid(body):
			return
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage)
			if is_instance_valid(body):
				_apply_slow(body, PROJECTILE_SLOW_MULT, PROJECTILE_SLOW_DURATION)
			if is_instance_valid(proj):
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
	# Si entramos a shield mientras estábamos atacando, volver al SHIELDING al terminar.
	action_state = ActionState.SHIELDING if _shielding else ActionState.PURSUE
	_current_attack = ""
