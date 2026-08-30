extends BaseEnemy

## Halcón — mob neutral
## Vuela alto y deambula en círculos. Solo ataca si lo provocan.
## Ataque especial: agarra al jugador y lo suelta — daño base + 5 de caída.

# Vuelo — canon fauna_spec.md Fase 1 (2026-05-07): halcón verdadero, alto 10m.
# Fuera del range de arco normal en altura. Solo atacable durante DIVING (y<=1.5).
# fly_height is terrain-relative offset (set in _on_enemy_ready via raycast).
const HAWK_MODEL := "res://assets/art/piso1_pradera/enemies/flying/hawk_dp_01.glb"
# In-game scale over the real 1.22 m wingspan. Joan picked 1.33 off the ramp
# (2026-08-25): the bestiary wants the high flyer scaled up to read at 10-14 m,
# and the GLB stays at real scale so the choice lives HERE, adjustable.
const HAWK_SCALE := 1.33

@export var fly_height := 14.0  # meters above local terrain
@export var wander_radius := 8.0
@export var wander_interval := 3.0
@export var dive_speed := 12.0
# ADDENDUM del spec: radios amplios y vuelta lenta (~10 s) --
# carga alar alta = radio de giro grande. Es fisica, no estilo.
@export var circle_radius := 16.0
# circle_speed DEPRECATED (2026-08-25): the angular rate is now DERIVED
# from flight speed (w = speed / circle_radius), so the orbit point can
# never outrun the bird. A fixed rate did: 0.6 rad/s x 10 m = 6 m/s of
# tangential speed against a 5 m/s hawk -- it hovered, chasing a point it
# could not catch, which read as "se queda estatico y gira".
@export var circle_speed := 0.6

# ---- caza natural: el halcon caza RATAS (Joan, 2026-08-25) ----
# "podriamos hacer que los halcones cacen ratas y quizas dejen el loot tirado".
# The loot comes free: killing the rat fires ITS OWN death -> _spawn_loot(),
# so the drop lies where the rat died. The hawk only provides the death.
# Hunting reuses the SAME CIRCLING/DIVING states, so the state->clip mapping
# animates the hunt with zero extra wiring.
@export var hunt_radius := 16.0
@export var hunt_interval := 30.0   # seconds between hunts -- a predator that
                                    # exterminates the map is a vacuum cleaner
var _prey: Node3D = null
var _hunt_cooldown := 5.0

# ---- inercia de vuelo (Joan: "cambia de direccion inmediatamente, un ave
# necesita seguir su trayectoria") ----
# La velocidad se ACERCA a la deseada con aceleracion finita, y el pico gira
# suave hacia el rumbo real: el resultado es la curva, no el teletransporte.
const FLY_ACCEL := 9.0      # m/s^2 en crucero/circulo
const DIVE_ACCEL := 16.0    # la picada corrige mas rapido
const WANDER_ACCEL := 6.0
var _heading := Vector3.FORWARD


func _steer(desired_x: float, desired_z: float, accel: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, desired_x, accel * delta)
	velocity.z = move_toward(velocity.z, desired_z, accel * delta)

# Estados de ataque
enum HawkState { IDLE, CIRCLING, DIVING, RETREATING }
var state := HawkState.IDLE

var wander_timer := 0.0
var wander_target := Vector3.ZERO
var spawn_position := Vector3.ZERO
var circle_angle := 0.0
var dive_cooldown := 0.0

# Absolute Y the hawk tries to maintain at runtime.
# fly_height remains the constant terrain-relative OFFSET and is NEVER overwritten.
# _fly_target_y is set once at spawn and updated per wander target via _terrain_fly_y_at.
var _fly_target_y: float = 0.0


## Raycast down to find terrain Y, then return terrain_y + fly_height (absolute).
func _terrain_fly_y_at(pos: Vector3) -> float:
	var space := get_world_3d().direct_space_state
	if space == null:
		return pos.y + fly_height
	var ray_from := Vector3(pos.x, pos.y + 200.0, pos.z)
	var ray_to := Vector3(pos.x, pos.y - 200.0, pos.z)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.collision_mask = 1  # Layer World only
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return pos.y + fly_height
	return hit.position.y + fly_height


func _on_enemy_ready() -> void:
	enemy_type = "hawk"
	# Personalidad: cazador veloz. HUNTER_FAST activa detección amplia + persistencia alta.
	# speed_mult de HUNTER_FAST NO aplica al hawk (su _move_toward_target es estado-máquina
	# independiente con dive_speed propio). La detección y persistencia sí aplican.
	personality = AggroPersonality.HUNTER_FAST
	default_color = Color(0.7, 0.55, 0.25)
	spawn_position = global_position
	# fly_height stays as the constant terrain-relative OFFSET — never overwrite it.
	# Compute the absolute Y once at spawn and store in _fly_target_y.
	_fly_target_y = _terrain_fly_y_at(global_position)
	spawn_position.y = _fly_target_y
	global_position.y = _fly_target_y
	dive_cooldown = 2.0  # Delay primer dive — da tiempo a circular cuando se provoca
	_pick_wander_target()
	mesh.visible = false
	var old_beak: Node = get_node_or_null("Beak")
	if old_beak:
		old_beak.visible = false
	# Bespoke model from the Blender motor (build_hawk.py): feather-built buteo,
	# glide pose, vertex-colour plumage. Falls back to the primitive flyer so a
	# missing asset looks wrong rather than absent (same pattern as turtle.gd).
	var model: Node3D = null
	var glb := load(HAWK_MODEL) if ResourceLoader.exists(HAWK_MODEL) else null
	if glb != null:
		model = glb.instantiate()
	else:
		push_warning("hawk: no encuentro %s, uso el modelo primitivo" % HAWK_MODEL)
		model = EnemyModelBuilder.build_flyer(default_color, 0.35, 0.7, 0.4)
	model.name = "Model"
	model.scale = Vector3.ONE * HAWK_SCALE
	# El GLB mira +Z (Blender -Y a traves del export y-up) y look_at apunta
	# -Z: sin este giro el halcon vuela DE COLA (Joan lo vio cazar de cola).
	model.rotation_degrees.y = 180.0
	add_child(model)
	_hawk_anim = _find_anim_player(model)
	_play_clip("idle")


# ---- clip playback: the AI owns the trajectory, the clip owns the body ------
# (motion/_motion_spec.md). Clip per state: soar while idling/circling, flap
# while climbing away, the dive strike while diving, the tucked fall on death.
var _hawk_anim: AnimationPlayer = null
var _current_clip := ""


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var found := _find_anim_player(c)
		if found != null:
			return found
	return null


func _play_clip(name: String) -> void:
	if _hawk_anim == null or _current_clip == name:
		return
	if not _hawk_anim.has_animation(name):
		return
	_current_clip = name
	_hawk_anim.play(name)


func _apply_gravity(_delta: float) -> void:
	match state:
		HawkState.IDLE:
			# Planear es para QUEDARSE; para trasladarse se aletea (Joan:
			# "mientras se esta moviendo deberia aletear como cualquier
			# pajaro"). El umbral separa deriva de viaje.
			if Vector2(velocity.x, velocity.z).length() > 1.2:
				_play_clip("move")
			else:
				_play_clip("idle")
		HawkState.CIRCLING:
			# El circulo en termica ES planeo -- ala quieta, como buitre.
			_play_clip("idle")
		HawkState.RETREATING:
			# Remontar cuesta: siempre aleteando ("cuando sale de la picada,
			# volviendo al cielo, tambien tiene que aletear").
			_play_clip("move")
		HawkState.DIVING:
			_play_clip("attack")
	# Solo mantener altura en idle y circling
	if state == HawkState.IDLE or state == HawkState.CIRCLING:
		velocity.y = (_fly_target_y - global_position.y) * 3.0
	elif state == HawkState.RETREATING:
		# Subida simétrica al dive — el descenso usa dive_speed*0.6 (~7 m/s),
		# el lift debe ser ~7 m/s para sentirse natural, no más rápido que la picada.
		velocity.y = (_fly_target_y - global_position.y) * 0.5
	elif state == HawkState.DIVING:
		# Cerca del suelo, no clavarse — corta caída
		if global_position.y <= 1.0:
			velocity.y = maxf(velocity.y, 0.0)


func _should_pursue(distance: float) -> bool:
	# Cuando está en retreat no perseguir — dejar que suba
	if state == HawkState.RETREATING:
		return false
	return super._should_pursue(distance)


func _idle_behavior(delta: float) -> void:
	if state == HawkState.RETREATING:
		# Subiendo después del agarre — volver a circling cuando llega arriba
		if global_position.y >= _fly_target_y - 0.3:
			state = HawkState.CIRCLING if is_provoked else HawkState.IDLE
		# Amortiguar suave: el impulso del fly-through debe LLEVARLO lejos del
		# punto del golpe mientras sube, no frenarse encima de la presa.
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 0.6)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 0.6)
		_face_flight_direction()
		return

	# Cazar: si hay una rata a tiro y no estamos provocados, el halcon vive
	# su vida de halcon. La trayectoria es de la IA; el clip solo el cuerpo.
	_hunt_cooldown -= delta
	if _prey == null and not is_provoked and _hunt_cooldown <= 0.0:
		_prey = _find_prey()
		if _prey != null:
			state = HawkState.CIRCLING
			circle_angle = atan2(global_position.z - _prey.global_position.z,
					global_position.x - _prey.global_position.x)
			dive_cooldown = 2.2      # un par de vueltas de buitre y baja
	if _prey != null:
		if not is_instance_valid(_prey) or _prey.get("is_dead"):
			_prey = null
			state = HawkState.RETREATING
		else:
			_hunt_step(delta)
			return

	# Deambular pacíficamente
	wander_timer -= delta

	if wander_timer <= 0.0:
		_pick_wander_target()
		wander_timer = wander_interval

	var distance_to_wander = global_position.distance_to(wander_target)
	if distance_to_wander > 0.5:
		var direction = (wander_target - global_position).normalized()
		direction.y = 0
		_steer(direction.x * speed * 0.5, direction.z * speed * 0.5,
				WANDER_ACCEL, delta)
		_face_flight_direction()
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 3.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 3.0)

	dive_cooldown -= delta


func _find_prey() -> Node3D:
	var best: Node3D = null
	var best_d := hunt_radius
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not is_instance_valid(e):
			continue
		if e.get("enemy_type") != "rat" or e.get("is_dead"):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _hunt_step(delta: float) -> void:
	_stalk(delta, _prey, true)


func _stalk(delta: float, victim: Node3D, lethal: bool) -> void:
	"""THE hunt: wide circle, slanting dive, strike, fly-through. One
	implementation for prey and for the provoked target -- Joan judged the rat
	version right ("funciono superbien") and asked for exactly it against the
	post. `lethal` is the only difference: prey dies (its death drops its own
	loot); the player/dummy takes perform_attack and the hawk moves on."""
	dive_cooldown -= delta
	var victim_pos: Vector3 = victim.global_position
	match state:
		HawkState.CIRCLING:
			circle_angle += (speed / circle_radius) * delta
			var target_pos := victim_pos + Vector3(
				cos(circle_angle) * circle_radius, 0,
				sin(circle_angle) * circle_radius)
			target_pos.y = _fly_target_y
			var direction := (target_pos - global_position).normalized()
			_steer(direction.x * speed, direction.z * speed, FLY_ACCEL, delta)
			velocity.y = (_fly_target_y - global_position.y) * 3.0
			_face_flight_direction()
			if dive_cooldown <= 0.0:
				state = HawkState.DIVING
		HawkState.DIVING:
			var direction := (victim_pos - global_position).normalized()
			_steer(direction.x * dive_speed, direction.z * dive_speed,
					DIVE_ACCEL, delta)
			velocity.y = direction.y * dive_speed * 0.45
			_face_flight_direction()
			# Llegar por rango, por suelo, O POR CHOQUE: un blanco con cuerpo
			# (el dummy mide 1.75 m) bloquea antes del rango y sin el OR de
			# colision el halcon quedaba pegado empujando.
			if global_position.distance_to(victim_pos) <= maxf(attack_range, 0.9) \
					or global_position.y <= 0.4 \
					or get_slide_collision_count() > 0:
				if lethal:
					if victim.has_method("take_damage"):
						victim.take_damage(99999.0)   # su muerte tira SU loot
					_prey = null
					_hunt_cooldown = hunt_interval
				else:
					if can_attack and victim.has_method("take_damage"):
						perform_attack()
					# Golpea UNA vez y vuelve a planear (Joan: "asi deberia
					# ser"). Si lo vuelven a danar, vuelve.
					is_provoked = false
				state = HawkState.RETREATING
				dive_cooldown = 3.5
				# FLY-THROUGH: el golpe es al pasar; el impulso lo saca en
				# subida por delante, nunca clavado sobre la victima.
				var through := Vector3(velocity.x, 0.0, velocity.z)
				if through.length() < 0.1:
					through = -global_transform.basis.z
				through = through.normalized()
				velocity.x = through.x * dive_speed * 0.8
				velocity.z = through.z * dive_speed * 0.8
				velocity.y = 6.0
		_:
			state = HawkState.CIRCLING

func _move_toward_target(delta: float) -> void:
	# Provocado: EXACTAMENTE la misma caza que contra la rata, con la unica
	# diferencia de que la victima no muere (lethal=false).
	if state == HawkState.IDLE:
		state = HawkState.CIRCLING
		circle_angle = atan2(
			global_position.z - target.global_position.z,
			global_position.x - target.global_position.x)
		dive_cooldown = 2.2
	_stalk(delta, target, false)

func perform_attack() -> void:
	can_attack = false
	if is_instance_valid(target):
		target.take_damage(damage * outgoing_damage_mult(), "", self)
		_retreat_push()
		# Daño de caída — se aplica con pequeño delay, simula el drop
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(target):
			target.take_damage(5.0, "", self)
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true


func _retreat_push() -> void:
	# Continuar la dirección del vuelo (forward) en vez de invertir hacia atrás.
	# Realismo: un ave que pica no frena y vuelve por donde vino — atraviesa la presa
	# y sigue el arco hacia adelante, ganando altura gradualmente.
	state = HawkState.RETREATING
	dive_cooldown = 3.5
	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0
	if forward.length() < 0.1:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	velocity.x = forward.x * dive_speed * 0.8
	velocity.z = forward.z * dive_speed * 0.8
	velocity.y = 3.0  # Impulso vertical menor — _apply_gravity hace el lift gradual
	global_position.y += 1.5  # Romper collision con player CharacterBody3D


func _pick_wander_target() -> void:
	var angle = randf() * TAU
	var dist = randf_range(2.0, wander_radius)
	wander_target = spawn_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	# Terrain-relative: recalculate absolute fly Y for this wander position.
	var new_fly_y: float = _terrain_fly_y_at(wander_target)
	wander_target.y = new_fly_y
	# Update runtime absolute target so _apply_gravity tracks the new terrain height.
	_fly_target_y = new_fly_y


func _face_flight_direction() -> void:
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if flat.length_squared() < 0.04:
		return
	# El rumbo visual persigue al real con retardo exponencial: el pico entra
	# a la curva en vez de saltar a ella.
	var dt := get_physics_process_delta_time()
	_heading = _heading.slerp(flat.normalized(), 1.0 - exp(-3.5 * dt))
	if _heading.length_squared() > 0.001:
		look_at(global_position + _heading.normalized())


func _on_death() -> void:
	_play_clip("death")
	# BaseEnemy._physics_process returns early once is_dead, so no gravity and
	# no move_and_slide ever run again: a dead flyer HUNG at 14 m (Joan: "la
	# caida deberia hacerlo caer al suelo"). The fall is therefore a tween --
	# quadratic ease-in, like gravity -- down to the terrain under the body.
	velocity = Vector3.ZERO
	var ground_y := 0.0
	var space := get_world_3d().direct_space_state
	if space != null:
		var q := PhysicsRayQueryParameters3D.create(
			global_position, global_position + Vector3(0, -200, 0))
		var hit := space.intersect_ray(q)
		if hit.has("position"):
			ground_y = hit["position"].y
	var h: float = maxf(0.0, global_position.y - ground_y)
	var dur: float = clampf(sqrt(h / 4.9), 0.5, 2.0)   # t = sqrt(2h/g)
	var tw := create_tween()
	tw.tween_property(self, "global_position:y", ground_y + 0.15, dur) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _death_anim_hold() -> float:
	# The body must not shrink away mid-air: hold until the fall lands.
	return 2.4
