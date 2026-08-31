extends BaseEnemy

## El Vigilante — jefe del Piso 2 (bosque de luna llena).
##
## Es la silueta que te observó al cruzar el bosque. Canon `lore/_alpha_5_maps.md`: el P2 es
## "el bosque vivo que te observa", y su antesala termina con "algo te observa (silueta que
## desaparece)". Este es ese algo. No se inventó un jefe para llenar un casillero — se le
## cobró la deuda a la escena que el propio canon monta.
##
## Regla canon de criaturas del P2: "NATURALEZA CREADA endémica de la torre (criterio Axlin
## — NO se copian mitologías)". Por eso no es un espíritu, ni un yokai, ni un ent. Es una
## cosa que la torre hizo: alto, negro, con ojos, y que sabe cómo funciona el miedo.
##
## Canon `enemy_tier_system.md`: "el boss de cada piso es un GATE: sus stats base igualan al
## tier siguiente sub-A, pero su dificultad viene de MECÁNICAS, combos y fases". Por eso su
## pelea no es una bolsa de vida —
##
## LA MECÁNICA: es INVISIBLE, y sólo se le puede pegar cuando ataca.
## Acecha en la oscuridad, aparece para golpear, y se desvanece. Mientras está oculto es
## inmune. El jugador no aprende a esquivarlo: aprende a ESPERARLO. La pelea es el bosque
## enseñándote a mirar.

const TIER: int = 2

## Cuánto queda visible (y golpeable) después de atacar. La ventana entera del jugador.
const EXPOSED_S: float = 2.4

## Cuánto acecha antes de volver a aparecer. Baja con las fases: se pone impaciente.
const STALK_S_BY_PHASE: Array[float] = [3.2, 2.4, 1.6]

enum State { STALKING, EXPOSED }

var _state: int = State.STALKING
var _phase: int = 0
var _timer: float = 0.0
var _body: Node3D = null
var _eyes: Array[MeshInstance3D] = []


func _on_enemy_ready() -> void:
	enemy_type = "forest_watcher"
	display_name = "El Vigilante"
	enemy_tier = TIER
	sub_tier = SubTier.BOSS
	habitat_type = "boss_arena"

	# GATE del piso 2. King Slime (tier 1) tiene 2200 HP: éste tiene que SENTIRSE más fuerte
	# (canon: "salto claro entre tiers — sin overlap").
	health = 3400.0
	damage = 22.0
	speed = 6.5              # rápido: aparece encima tuyo
	mass = 3.0
	knockback_resistance = 1.0
	attack_range = 3.0
	detection_range = 40.0
	attack_cooldown = 0.6
	xp_reward = 320.0

	default_color = Color(0.01, 0.01, 0.02)
	mesh.visible = false
	_build_model()
	_enter_stalking()


# ── La mecánica ───────────────────────────────────────────────────────────────

## Oculto: invisible e INMUNE. La única forma de dañarlo es esperar a que ataque.
func take_damage(
	amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0,
	attacker_str := 0, attacker: Node = null, element: String = "physical",
	is_crit: bool = false
) -> void:
	if _state == State.STALKING:
		return  # no está acá. Pegarle al aire no lastima a nadie.
	super.take_damage(amount, hit_direction, knockback_force, attacker_str, attacker, element, is_crit)
	_update_phase()


## Tres fases. No cambian sus stats — cambian su PACIENCIA: cada vez espera menos entre
## apariciones. La presión sube porque el bosque se te viene encima, no porque pegue más.
func _update_phase() -> void:
	if _max_health <= 0.0:
		return
	var pct: float = health / _max_health
	var new_phase: int = 0
	if pct <= 0.33:
		new_phase = 2
	elif pct <= 0.66:
		new_phase = 1
	if new_phase != _phase:
		_phase = new_phase


func _physics_process(delta: float) -> void:
	if is_dead:
		super._physics_process(delta)
		return

	_timer -= delta
	if _timer <= 0.0:
		if _state == State.STALKING:
			_strike()
		else:
			_enter_stalking()

	if _state == State.STALKING:
		# Se reposiciona sin ser visto: da la vuelta al jugador mientras está oculto.
		if is_instance_valid(target):
			var to_player: Vector3 = target.global_position - global_position
			to_player.y = 0.0
			if to_player.length() > 6.0:
				velocity.x = to_player.normalized().x * speed
				velocity.z = to_player.normalized().z * speed
			else:
				velocity.x = 0.0
				velocity.z = 0.0
		_apply_gravity(delta)
		move_and_slide()
		return

	super._physics_process(delta)


## Se desvanece. Mientras acecha, lo único que queda son los ojos —
## y sólo si mirás en la dirección correcta.
func _enter_stalking() -> void:
	_state = State.STALKING
	_timer = STALK_S_BY_PHASE[_phase]
	if _body != null:
		_body.visible = false
	for eye: MeshInstance3D in _eyes:
		eye.visible = true      # los ojos NUNCA se apagan. Siempre te está mirando.


## Aparece encima tuyo y golpea. Queda expuesto EXPOSED_S: esa es tu ventana entera.
func _strike() -> void:
	_state = State.EXPOSED
	_timer = EXPOSED_S
	if _body != null:
		_body.visible = true

	if not is_instance_valid(target):
		return

	# Reaparece a espaldas del jugador. No es un teleport gratis: es lo que hace un
	# depredador de emboscada, y el jugador puede aprender a girar antes de que pase.
	var behind: Vector3 = target.global_position - target.global_basis.z * -2.6
	behind.y = target.global_position.y
	global_position = behind

	target.take_damage(damage * outgoing_damage_mult())
	if target.has_method("apply_status"):
		target.apply_status(&"stun", 0.4, self)
	if AudioManager:
		AudioManager.play_sfx(&"enemy_hit_flesh", global_position)


## Su ataque ES la mecánica: pasa por _strike(), no por el ciclo normal.
func perform_attack() -> void:
	pass


# ── Modelo ────────────────────────────────────────────────────────────────────

func _build_model() -> void:
	var model := Node3D.new()
	model.name = "Model"

	_body = Node3D.new()
	_body.name = "Silhouette"

	# Alto y delgado. Un recorte negro contra un bosque negro: la silueta ES el diseño.
	var torso := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.55
	capsule.height = 4.2
	torso.mesh = capsule
	torso.position = Vector3(0, 2.1, 0)
	torso.material_override = _void_material()
	_body.add_child(torso)

	for side: float in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(0.18, 2.6, 0.18)   # brazos demasiado largos
		arm.mesh = arm_mesh
		arm.position = Vector3(side * 0.75, 2.0, 0)
		arm.rotation = Vector3(0, 0, side * 0.12)
		arm.material_override = _void_material()
		_body.add_child(arm)

	model.add_child(_body)

	# Los ojos: fuera del cuerpo, porque siguen ahí cuando el cuerpo no está.
	for side: float in [-0.2, 0.2]:
		var eye := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.09
		sphere.height = 0.18
		eye.mesh = sphere
		eye.position = Vector3(side, 3.75, -0.42)

		var mat := StandardMaterial3D.new()
		var glow := Color(0.35, 0.95, 0.80)   # el mismo fluorescente de los árboles: ES el bosque
		mat.albedo_color = glow
		mat.emission_enabled = true
		mat.emission = glow
		mat.emission_energy_multiplier = 9.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		eye.material_override = mat

		model.add_child(eye)
		_eyes.append(eye)

	add_child(model)


func _void_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = default_color
	mat.roughness = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # no recibe luz: es un agujero
	return mat
