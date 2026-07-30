extends BaseEnemy

## Slime — enemigo básico agresivo
## Se mueve a saltitos hacia el jugador. Lento pero persistente.
## Al morir se divide en 4 mini-slimes (si no es mini).

# Saltitos
@export var hop_force := 4.0
@export var hop_interval := 1.6

# División
@export var is_mini := false
@export var split_count := 4

var hop_timer := 0.0
var is_hopping := false

var mini_slime_scene: PackedScene

# ── Deformación direccional del gel ──────────────────────────────────────────
# El slime se derrama hacia donde viaja (pedido de Joan, 2026-07-30). Vive acá y
# no en un clip de Blender porque depende de la velocidad en runtime: la regla
# del motor es que un loop fijo va en bpy y todo lo que dependa de una variable
# de gameplay va en Godot.
#
# Los shape keys lean_x / lean_y no los anima ningún clip, así que el script es
# su único dueño. Aceptan pesos con signo — un morph target es un delta de
# vértices, así que -1 es exactamente la inclinación opuesta — y con eso dos
# keys cubren las cuatro direcciones.

## Velocidad a la que la inclinación llega a su máximo. El slime alcanza
## speed * 1.5 al saltar (3.0 m/s con los valores por defecto), así que a 3.2 el
## gel casi satura en pleno salto y se queda corto al arrastrarse.
const LEAN_SATURATION_SPEED := 3.2
## Cuánto se inclina como máximo. Por encima de ~0.85 el domo se ve tumbado en
## vez de derramado.
const LEAN_MAX := 0.8
## Rapidez con la que el gel ALCANZA su forma inclinada. Bajo a propósito: el
## retraso es lo que lo hace leer como gel y no como un sólido pintado de verde,
## y sobrepasa al frenar porque la masa sigue de largo.
const LEAN_RESPONSE := 6.5

var _lean := Vector2.ZERO
var _lean_mesh: MeshInstance3D = null
var _lean_idx_x := -1
var _lean_idx_y := -1
var _lean_anim: AnimationPlayer = null


## Returns the gltf model root (embedded in .tscn as SlimeMesh).
func _get_anim_model_root() -> Node3D:
	return get_node_or_null("SlimeMesh")


func _on_enemy_ready() -> void:
	enemy_type = "mini_slime" if is_mini else "slime"
	# Personalidad: curioso. Se acerca lentamente a investigar al jugador.
	# Solo ataca si el jugador entra en rango cercano (attack_range*1.5) o provoca.
	# Cuando está en rango de ataque, usa los saltos normales (_move_toward_target).
	personality = AggroPersonality.CURIOUS
	aggression = AggressionType.NEUTRAL
	default_color = Color(0.2, 0.75, 0.2) if not is_mini else Color(0.3, 0.85, 0.3)
	# El GLB bespoke tiene la cara en Blender -Y, que export_yup mapea a +Z;
	# girar 180° para que mire al frente de Godot (-Z), si no queda de espaldas.
	var _slime_mesh: Node3D = get_node_or_null("SlimeMesh")
	if _slime_mesh != null:
		_slime_mesh.rotation.y = PI
	mass = 0.5 if not is_mini else 0.2
	hop_timer = hop_interval
	if not is_mini:
		mini_slime_scene = load("res://scenes/enemy/mini_slime.tscn")
	_cache_lean_shapes(_slime_mesh)


## Finds the skinned mesh and the index of each lean shape key. Indices are
## looked up by NAME because morph order is an export detail, not a contract.
func _cache_lean_shapes(model_root: Node3D) -> void:
	if model_root == null:
		return
	_lean_mesh = _find_mesh_with_blendshapes(model_root)
	if _lean_mesh == null or _lean_mesh.mesh == null:
		return
	var mesh := _lean_mesh.mesh
	for i in mesh.get_blend_shape_count():
		match mesh.get_blend_shape_name(i):
			&"lean_x":
				_lean_idx_x = i
			&"lean_y":
				_lean_idx_y = i
	if _lean_idx_x < 0 and _lean_idx_y < 0:
		return
	# glTF packs the WHOLE morph-weight array into a single animation channel, so
	# a clip rewrites every weight when it evaluates — including the two shapes
	# it was never meant to own. Measured: setting lean_y to 0.8 read back as
	# 0.000 two frames later. Relying on process order to win that race is
	# fragile, so take the clock instead: drive the player by hand from _process
	# and write the lean immediately afterwards, which makes the ordering
	# explicit rather than incidental.
	_lean_anim = _find_animation_player(_lean_mesh)
	if _lean_anim != null:
		_lean_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL


func _find_animation_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	var parent := n.get_parent()
	# The player is a sibling of the mesh inside the imported scene, so search
	# from the imported root rather than only downward from the mesh.
	var root: Node = parent if parent != null else n
	return _search_animation_player(root)


func _search_animation_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		var f := _search_animation_player(c)
		if f != null:
			return f
	return null


func _find_mesh_with_blendshapes(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh != null and mi.mesh.get_blend_shape_count() > 0:
			return mi
	for c in n.get_children():
		var found := _find_mesh_with_blendshapes(c)
		if found != null:
			return found
	return null


func _process(delta: float) -> void:
	if _lean_mesh == null:
		return
	# Advance the clip FIRST (it owns squash/stretch/sway/lunge/melt), then write
	# the lean on top. Manual mode makes this order a guarantee.
	if _lean_anim != null and _lean_anim.is_playing():
		_lean_anim.advance(delta)
	if is_dead:
		return
	# Horizontal velocity in the body's OWN frame. The body look_at()s its
	# target, so -Z is forward and the lean reads correctly however it is turned.
	var local_vel := global_transform.basis.inverse() * velocity
	local_vel.y = 0.0
	var target := Vector2(
		-local_vel.x / LEAN_SATURATION_SPEED,
		-local_vel.z / LEAN_SATURATION_SPEED)
	if target.length() > 1.0:
		target = target.normalized()
	target *= LEAN_MAX
	# Exponential approach: frame-rate independent, and the lag IS the effect.
	var k := 1.0 - exp(-LEAN_RESPONSE * delta)
	_lean = _lean.lerp(target, k)
	if _lean_idx_x >= 0:
		_lean_mesh.set_blend_shape_value(_lean_idx_x, _lean.x)
	if _lean_idx_y >= 0:
		_lean_mesh.set_blend_shape_value(_lean_idx_y, _lean.y)


func _move_toward_target(delta: float) -> void:
	# El slime se mueve a saltos, no caminando
	hop_timer -= delta

	if hop_timer <= 0.0 and is_on_floor():
		hop_timer = hop_interval
		is_hopping = true
		# Trigger Jump animation at hop launch (no-op if no AnimationPlayer).
		if _anim != null:
			_anim.play_jump()

		# Impulso hacia el jugador + hacia arriba
		var direction = (target.global_position - global_position).normalized()
		direction.y = 0
		velocity.x = direction.x * speed * 1.5
		velocity.z = direction.z * speed * 1.5
		velocity.y = hop_force

	# Fricción: más fuerte en el suelo, leve en el aire para evitar spinning
	if is_on_floor() and not is_hopping:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 5.0)
	elif not is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 1.5)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 1.5)

	if is_hopping and is_on_floor() and velocity.y <= 0:
		is_hopping = false
		# Return to idle after landing (no-op if no AnimationPlayer).
		if _anim != null:
			_anim.play_idle()


func _idle_behavior(delta: float) -> void:
	# Frenar suavemente
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 5.0)


func _on_knockback(kb_velocity: Vector3) -> void:
	# Efecto jelly: se estira en la dirección del golpe y rebota de vuelta
	var stretch_dir = kb_velocity.normalized()
	var stretch_x = 1.0 + absf(stretch_dir.x) * 0.3
	var stretch_z = 1.0 + absf(stretch_dir.z) * 0.3
	var squish_y = 0.8

	var jelly = create_tween()
	jelly.tween_property(self, "scale", Vector3(stretch_x, squish_y, stretch_z), 0.1)
	jelly.tween_property(self, "scale", Vector3(0.85, 1.2, 0.85), 0.1)
	jelly.tween_property(self, "scale", Vector3(1, 1, 1), 0.15).set_ease(Tween.EASE_OUT)


func _on_death() -> void:
	if not is_mini:
		_spawn_mini_slimes()

	# Squash visual al morir — se aplasta antes de encogerse
	var squash = create_tween()
	squash.tween_property(self, "scale", Vector3(1.5, 0.3, 1.5), 0.2)


func _spawn_mini_slimes() -> void:
	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return
	if mini_slime_scene == null:
		push_warning("slime: mini_slime_scene no cargada, no se spawean minis")
		return

	for i in split_count:
		var mini = mini_slime_scene.instantiate()
		# Ángulo y dirección de impulso totalmente random — cada mini por donde quiera
		var spawn_angle = randf() * TAU
		var spawn_radius = randf_range(0.4, 1.0)
		var offset = Vector3(cos(spawn_angle) * spawn_radius, 0.3, sin(spawn_angle) * spawn_radius)
		var spawn_pos = global_position + offset

		# Impulso independiente del spawn — dirección random, fuerza variable
		var explode_angle = randf() * TAU
		var explode_force = randf_range(3.0, 8.0)
		var kb = Vector3(cos(explode_angle), 0, sin(explode_angle)) * explode_force
		kb.y = randf_range(2.5, 6.0)

		# _on_death() corre dentro del flush de física (die() se invoca tras un hit que
		# puede venir de un body_entered de proyectil). Diferir add_child + la posición
		# JUNTOS evita "flushing queries" y el is_inside_tree del global_position pre-árbol.
		_add_mini_deferred.call_deferred(scene_root, mini, spawn_pos, kb)


func _add_mini_deferred(parent: Node, mini: Node, spawn_pos: Vector3, kb: Vector3) -> void:
	if not is_instance_valid(parent) or not is_instance_valid(mini):
		return
	parent.add_child(mini)
	mini.global_position = spawn_pos
	mini.knockback_velocity = kb
