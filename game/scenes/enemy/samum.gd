extends BaseEnemy

## El Samum — jefe del Piso 4 (Al-Samum).
##
## "Al-Samum" es, literalmente, el viento venenoso del desierto. El piso lleva su nombre, así
## que el jefe del piso ES el viento. No una criatura que lo invoca: la tormenta misma.
##
## Canon `enemy_tier_system.md`: "la dificultad viene de MECÁNICAS, combos y fases".
##
## LA MECÁNICA: no tiene cuerpo. La mayor parte del tiempo es una tormenta —
## intocable, y te desgasta con daño constante mientras estés dentro de ella. Cada tantos
## segundos se CONDENSA en una figura, y esa figura sí se puede matar. Cuando la lastimás
## lo suficiente, se deshace en viento otra vez.
##
## La pelea es una carrera contra tu propia vida: el veneno del samum no para nunca, así que
## no podés jugar a la defensiva. Tenés que entrarle a la figura cuando aparece, aunque estés
## herido. Es el desierto haciendo lo que hace el desierto: no te mata de un golpe, te MATA
## DE ESPERAR.

const TIER: int = 4

## Cuánto se queda condensado (y golpeable).
const CONDENSED_S: float = 6.0

## Cuánto pasa disperso antes de volver. Baja con las fases.
const SCATTER_S_BY_PHASE: Array[float] = [7.0, 5.0, 3.0]

## Daño por segundo mientras el jugador está dentro de la tormenta. No para NUNCA.
const STORM_DPS: float = 6.0
const STORM_RADIUS: float = 26.0

## Cuánto daño en una condensación hace que se disperse de nuevo.
const CONDENSED_HP_CHUNK: float = 1900.0

enum State { SCATTERED, CONDENSED }

var _state: int = State.SCATTERED
var _phase: int = 0
var _timer: float = 0.0
var _chunk_taken: float = 0.0
var _storm_tick: float = 0.0
var _body: Node3D = null
var _storm: GPUParticles3D = null


func _on_enemy_ready() -> void:
	enemy_type = "samum"
	display_name = "Al-Samum"
	enemy_tier = TIER
	sub_tier = SubTier.BOSS
	habitat_type = "boss_arena"

	health = 6400.0
	damage = 40.0
	speed = 4.0
	mass = 5.0
	knockback_resistance = 1.0
	attack_range = 3.5
	detection_range = 40.0
	attack_cooldown = 1.4
	xp_reward = 900.0

	default_color = Color(0.80, 0.68, 0.45)
	mesh.visible = false
	_build_model()
	_scatter()


# ── La mecánica ───────────────────────────────────────────────────────────────

## Disperso, es viento: no se le puede pegar. La tormenta no tiene dónde recibir un golpe.
func take_damage(
	amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0,
	attacker_str := 0, attacker: Node = null, element: String = "physical",
	is_crit: bool = false
) -> void:
	if _state == State.SCATTERED:
		return
	super.take_damage(amount, hit_direction, knockback_force, attacker_str, attacker, element, is_crit)

	_chunk_taken += amount
	_update_phase()
	if _chunk_taken >= CONDENSED_HP_CHUNK and not is_dead:
		_scatter()   # le sacaste bastante: se deshace y hay que esperarlo de nuevo


func _update_phase() -> void:
	if _max_health <= 0.0:
		return
	var pct: float = health / _max_health
	if pct <= 0.33:
		_phase = 2
	elif pct <= 0.66:
		_phase = 1


func _physics_process(delta: float) -> void:
	if is_dead:
		super._physics_process(delta)
		return

	_tick_storm(delta)

	_timer -= delta
	if _timer <= 0.0:
		if _state == State.SCATTERED:
			_condense()
		else:
			_scatter()

	if _state == State.SCATTERED:
		# El viento deriva alrededor del jugador. No lo persigue — lo RODEA.
		if is_instance_valid(target):
			var around: Vector3 = target.global_position - global_position
			around.y = 0.0
			velocity.x = around.normalized().x * speed * 0.5
			velocity.z = around.normalized().z * speed * 0.5
		_apply_gravity(delta)
		move_and_slide()
		return

	super._physics_process(delta)


## El veneno. Constante, sin cooldown, sin forma de bloquearlo — sólo de terminar la pelea.
## Esto es lo que impide jugar a la defensiva: el reloj corre sobre TU vida.
func _tick_storm(delta: float) -> void:
	if not is_instance_valid(target):
		return
	_storm_tick -= delta
	if _storm_tick > 0.0:
		return
	_storm_tick = 1.0
	if global_position.distance_to(target.global_position) <= STORM_RADIUS:
		target.take_damage(STORM_DPS, "poison")


## Se deshace en viento. Intocable.
func _scatter() -> void:
	_state = State.SCATTERED
	_timer = SCATTER_S_BY_PHASE[_phase]
	_chunk_taken = 0.0
	if _body != null:
		_body.visible = false
	if _storm != null:
		_storm.emitting = true


## Se condensa en una figura. Esta es tu ventana, y no hay otra.
func _condense() -> void:
	_state = State.CONDENSED
	_timer = CONDENSED_S
	_chunk_taken = 0.0
	if _body != null:
		_body.visible = true
	if AudioManager:
		AudioManager.play_sfx(&"war_cry_activate", global_position)
	if CameraShake:
		CameraShake.shake_light()


func perform_attack() -> void:
	if _state == State.SCATTERED or has_status(&"stun"):
		return
	can_attack = false

	if is_instance_valid(target):
		target.take_damage(damage * outgoing_damage_mult())

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true


# ── Modelo ────────────────────────────────────────────────────────────────────

func _build_model() -> void:
	var model := Node3D.new()
	model.name = "Model"

	# La tormenta: siempre visible, siempre girando. ES el boss — el cuerpo es lo raro.
	_storm = GPUParticles3D.new()
	_storm.name = "Storm"
	_storm.amount = 600
	_storm.lifetime = 2.4
	_storm.visibility_aabb = AABB(Vector3(-14, -4, -14), Vector3(28, 16, 28))

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 7.0
	pm.direction = Vector3(0, 0.25, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 8.0
	pm.orbit_velocity_min = 0.35   # gira: es un remolino, no una nube
	pm.orbit_velocity_max = 0.6
	pm.gravity = Vector3(0, -0.4, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.4
	pm.color = Color(0.86, 0.74, 0.50, 0.6)
	_storm.process_material = pm

	var grain := BoxMesh.new()
	grain.size = Vector3(0.14, 0.14, 0.14)
	_storm.draw_pass_1 = grain

	var storm_mat := StandardMaterial3D.new()
	storm_mat.albedo_color = Color(0.86, 0.74, 0.50, 0.55)
	storm_mat.emission_enabled = true
	storm_mat.emission = Color(0.80, 0.66, 0.42)
	storm_mat.emission_energy_multiplier = 0.5
	storm_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_storm.material_override = storm_mat
	_storm.position = Vector3(0, 2.5, 0)
	model.add_child(_storm)

	# La figura. Arena apretada con forma de hombre: se ve que es la misma tormenta,
	# sostenida un momento. Por eso es del mismo color, y por eso brilla.
	_body = Node3D.new()
	_body.name = "Figure"
	var figure := EnemyModelBuilder.build_humanoid(default_color, 1.5, 1.1)
	if figure != null:
		_body.add_child(figure)
	_body.visible = false
	model.add_child(_body)

	add_child(model)
