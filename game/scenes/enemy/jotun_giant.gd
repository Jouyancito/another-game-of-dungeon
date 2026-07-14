extends BaseEnemy

## El Jötun — jefe del Piso 3 (Jötunheim, hielo nórdico).
##
## Canon `enemy_tier_system.md`: "el boss de cada piso es un GATE: sus stats base igualan al
## tier siguiente sub-A, pero su dificultad viene de MECÁNICAS, combos y fases".
##
## LA MECÁNICA: está BLINDADO en hielo, y el hielo hay que romperlo.
## Mientras la coraza aguanta, casi todo el daño rebota (95% reducción). La coraza tiene su
## propia vida y se ROMPE con golpes pesados — y cuando revienta, el Jötun queda expuesto
## unos segundos y recibe daño DOBLE. Después se vuelve a congelar.
##
## Es el combo canon de `docs/skills/_status_effects.md`: "Freeze → shatter si recibe golpe
## físico fuerte mientras frozen → bonus dmg". Acá el frozen no se lo hacés vos: nace
## congelado, y romperlo es la pelea. Pegarle rápido y flojo no sirve. Hay que PEGAR FUERTE.
##
## El piso te lo venía diciendo: el frío no es oscuro, es expuesto. No hay dónde esconderse,
## y no hay forma de rasguñar esto hasta matarlo.

const TIER: int = 3

## Cuánto daño aguanta la coraza antes de reventar.
const ARMOR_HP: float = 900.0

## Un golpe tiene que superar esto para siquiera dañar la coraza. Rasguñarla no la rompe.
const HEAVY_HIT_THRESHOLD: float = 35.0

## Reducción de daño mientras la coraza aguanta.
const ARMORED_REDUCTION: float = 0.95

## Cuánto queda expuesto tras romperse, y el multiplicador de daño en esa ventana.
const EXPOSED_S: float = 5.0
const EXPOSED_DAMAGE_MULT: float = 2.0

var _armor: float = ARMOR_HP
var _exposed: bool = false
var _exposed_left: float = 0.0
var _shell: MeshInstance3D = null


func _on_enemy_ready() -> void:
	enemy_type = "jotun_giant"
	display_name = "El Jötun"
	enemy_tier = TIER
	sub_tier = SubTier.BOSS
	habitat_type = "boss_arena"

	health = 4800.0
	damage = 34.0
	speed = 2.0              # lento. No te persigue: te ALCANZA.
	mass = 6.0
	knockback_resistance = 1.0
	attack_range = 4.0
	detection_range = 32.0
	attack_cooldown = 2.6
	xp_reward = 520.0

	default_color = Color(0.62, 0.72, 0.82)
	mesh.visible = false
	_build_model()


# ── La mecánica: la coraza ────────────────────────────────────────────────────

## Golpes flojos rebotan. Golpes pesados agrietan. Cuando la coraza cae, el gigante es
## vidrio por cinco segundos.
func take_damage(
	amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0,
	attacker_str := 0, attacker: Node = null, element: String = "physical",
	is_crit: bool = false
) -> void:
	if is_dead:
		return

	if _exposed:
		# Sin coraza: el doble. Esta ventana es toda la pelea, y hay que ganársela.
		super.take_damage(
			amount * EXPOSED_DAMAGE_MULT, hit_direction, knockback_force,
			attacker_str, attacker, element, is_crit
		)
		return

	# Blindado. Sólo un golpe PESADO le hace algo a la coraza.
	if amount >= HEAVY_HIT_THRESHOLD:
		_armor -= amount
		_update_shell()
		if _armor <= 0.0:
			_shatter()

	# Lo que se filtra por el hielo. Casi nada — pero no cero: quedarse sin daño posible es
	# frustración, no dificultad.
	super.take_damage(
		amount * (1.0 - ARMORED_REDUCTION), hit_direction, knockback_force,
		attacker_str, attacker, element, is_crit
	)


## La coraza revienta. Es el momento de la pelea, y tiene que LEERSE como tal.
func _shatter() -> void:
	_exposed = true
	_exposed_left = EXPOSED_S
	_armor = 0.0

	if _shell != null:
		_shell.visible = false
	if AudioManager:
		AudioManager.play_sfx(&"block_success", global_position)   # el crujido del vidrio
	if CameraShake:
		CameraShake.shake_heavy()


## Se vuelve a congelar. Si no lo mataste en la ventana, empezás de nuevo — pero la coraza
## vuelve más fina cada vez, así que la pelea AVANZA. Nunca es un ciclo estéril.
func _refreeze() -> void:
	_exposed = false
	var pct: float = health / _max_health if _max_health > 0.0 else 1.0
	_armor = ARMOR_HP * maxf(0.35, pct)   # cuanto más herido, menos hielo le queda
	if _shell != null:
		_shell.visible = true
		_update_shell()


func _physics_process(delta: float) -> void:
	if _exposed and not is_dead:
		_exposed_left -= delta
		if _exposed_left <= 0.0:
			_refreeze()
	super._physics_process(delta)


## La coraza se ve morir: se va poniendo transparente a medida que se agrieta.
func _update_shell() -> void:
	if _shell == null:
		return
	var pct: float = clampf(_armor / ARMOR_HP, 0.0, 1.0)
	var mat: StandardMaterial3D = _shell.material_override
	if mat != null:
		mat.albedo_color = Color(0.70, 0.85, 0.95, 0.25 + 0.45 * pct)


## Pisotón. Lento y telegrafiado — su peligro es el daño, no la sorpresa.
func perform_attack() -> void:
	if has_status(&"stun"):
		return
	can_attack = false

	if is_instance_valid(target):
		target.take_damage(damage * outgoing_damage_mult())
		if target.has_method("apply_status"):
			target.apply_status(&"stun", 0.7, self)
		if CameraShake:
			CameraShake.shake_heavy()

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true


# ── Modelo ────────────────────────────────────────────────────────────────────

func _build_model() -> void:
	var model := Node3D.new()
	model.name = "Model"

	var body := EnemyModelBuilder.build_humanoid(default_color, 2.8, 1.6)  # alto y ancho: es un gigante
	if body != null:
		model.add_child(body)

	# La coraza: un bloque de hielo translúcido envolviéndolo. Es el HUD de la mecánica —
	# el jugador tiene que poder VER cuánto le queda sin leer un número.
	_shell = MeshInstance3D.new()
	_shell.name = "IceShell"
	var shell_mesh := BoxMesh.new()
	shell_mesh.size = Vector3(3.0, 5.8, 2.4)
	_shell.mesh = shell_mesh
	_shell.position = Vector3(0, 2.9, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.70, 0.85, 0.95, 0.70)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.15
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.75, 0.90)
	mat.emission_energy_multiplier = 0.5
	_shell.material_override = mat
	model.add_child(_shell)

	add_child(model)
