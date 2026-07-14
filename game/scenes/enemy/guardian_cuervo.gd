extends BaseEnemy

## Guardián-Cuervo, "El Que Recuerda" — jefe del Piso 5.
##
## Canon `lore/_mundo_entrevista.md` §4.4 + `_world_seeds_postalpha.md` §1:
##   "Guardián-Cuervo 'El Que Recuerda' con memoria persistente por jugador
##    (ya lo conoce en el segundo run → NO PELEA). Es JEFE DE RANGO — distinto a los jefes
##    de zona de los pisos anteriores."
##
## Esa memoria ES el personaje, no un detalle de implementación. Todo boss de este juego te
## ataca. Este te MIRA, y si ya te vio antes, se hace a un lado. La primera vez que un
## jugador vuelve al piso 5 y el Cuervo simplemente lo deja pasar, el juego le dice algo que
## ninguna barra de vida puede decirle.
##
## Persistencia: `WorldManager.world_flags` del mundo activo — el mismo lugar donde vive el
## world-state colectivo (canon: Descubrimiento→Conquista→Civilización). Si el Cuervo te
## recuerda es porque el MUNDO te recuerda.
##
## El doc marca su boceto como ESPECULATIVO y su tabla "¿Confirmás?" sigue sin llenar.
## Construido desde lo dicho, pendiente de firma.

## La marca que deja en el mundo. Verla es lo que lo hace no pelear la próxima vez.
const MEMORY_FLAG: String = "cuervo_remembers"

## Cuánto se demora en reconocerte antes de apartarse.
const RECOGNITION_S: float = 3.5

var _remembers_player: bool = false
var _stepped_aside: bool = false


func _on_enemy_ready() -> void:
	enemy_type = "guardian_cuervo"
	display_name = "El Que Recuerda"
	enemy_tier = 5
	sub_tier = SubTier.BOSS
	habitat_type = "boss_arena"

	# Tier 5 BOSS — canon enemy_tier_system.md §3 (BOSS = 3.0x, XP 10x).
	health = 8200.0
	damage = 52.0
	speed = 3.6
	mass = 5.0
	knockback_resistance = 1.0   # canon: los bosses son inmunes al knockback
	attack_range = 3.2
	detection_range = 30.0
	attack_cooldown = 1.8
	xp_reward = 1400.0

	default_color = Color(0.06, 0.05, 0.09)
	mesh.visible = false
	_build_model()

	# ORDEN CRÍTICO: primero LEER la memoria, después grabar este encuentro. Al revés, el
	# Cuervo se lee a sí mismo recordándote en tu primer encuentro y no pelea nunca.
	_remembers_player = _world_remembers()
	if _remembers_player:
		# No pelea. No es pasividad: es RECONOCIMIENTO.
		aggression = AggressionType.NEUTRAL
		_recognise_and_step_aside()
	else:
		aggression = AggressionType.AGGRESSIVE

	# Verte alcanza. Lo recuerda aunque lo mates, aunque te mate, aunque huyas.
	_remember_this_encounter()


# ── Memoria ───────────────────────────────────────────────────────────────────

## ¿Este mundo ya lo vio? La memoria vive en el mundo, no en el enemigo: matarlo, morir, o
## salir al menú no la borra. Ese es el punto.
func _world_remembers() -> bool:
	# Sin mundo activo (escena dev/test) es un estado normal, no un error — hay que chequearlo
	# antes de get_world(), que push_error()a con un índice inválido por diseño.
	if GameManager.world_index < 0:
		return false
	var world: Dictionary = WorldManager.get_world(GameManager.world_index)
	if world.is_empty():
		return false
	var flags: Dictionary = world.get("world_flags", {})
	return bool(flags.get(MEMORY_FLAG, false))


## Grabar el encuentro. Se llama al ENCONTRARLO, no al matarlo — porque lo que recuerda es
## haberte visto, y eso pasa aunque lo mates, aunque te mate, aunque huyas.
func _remember_this_encounter() -> void:
	var index: int = GameManager.world_index
	if index < 0:
		return
	var world: Dictionary = WorldManager.get_world(index)
	if world.is_empty():
		return
	var flags: Dictionary = (world.get("world_flags", {}) as Dictionary).duplicate()
	if flags.get(MEMORY_FLAG, false):
		return
	flags[MEMORY_FLAG] = true
	WorldManager.update_world(index, {"world_flags": flags})


## Ya te conoce. Se aparta del camino y deja pasar. Sin pelea, sin XP, sin loot —
## no hay recompensa por un enemigo que decidió no serlo.
func _recognise_and_step_aside() -> void:
	if _stepped_aside:
		return
	_stepped_aside = true

	var t := create_tween()
	t.tween_interval(RECOGNITION_S)          # te mira. Esa pausa ES el diálogo.
	t.tween_property(self, "position:x", position.x + 9.0, 2.2).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(self, "rotation:y", rotation.y + PI * 0.5, 2.2)


# ── Modelo ────────────────────────────────────────────────────────────────────

## Un cuervo enorme, negro, sin brillo. Lo único que emite son los ojos —
## y los ojos son lo único que necesita para el papel que tiene.
func _build_model() -> void:
	var model := Node3D.new()
	model.name = "Model"

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 1.1
	body_mesh.height = 3.6
	body.mesh = body_mesh
	body.position = Vector3(0, 1.9, 0)
	body.material_override = _matte_black()
	model.add_child(body)

	# Alas: anchas, plegadas. Nunca vuela — está de guardia, no de caza.
	for side: float in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		var wing_mesh := BoxMesh.new()
		wing_mesh.size = Vector3(2.4, 0.14, 1.5)
		wing.mesh = wing_mesh
		wing.position = Vector3(side * 1.35, 2.3, 0.2)
		wing.rotation = Vector3(0.0, 0.0, side * 0.55)
		wing.material_override = _matte_black()
		model.add_child(wing)

	# Pico.
	var beak := MeshInstance3D.new()
	var beak_mesh := BoxMesh.new()
	beak_mesh.size = Vector3(0.28, 0.28, 1.1)
	beak.mesh = beak_mesh
	beak.position = Vector3(0, 3.2, -0.85)
	beak.material_override = _matte_black()
	model.add_child(beak)

	# Los ojos. Lo único vivo.
	for side: float in [-0.35, 0.35]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.16
		eye_mesh.height = 0.32
		eye.mesh = eye_mesh
		eye.position = Vector3(side, 3.45, -0.42)

		var eye_mat := StandardMaterial3D.new()
		var eye_color := Color(0.70, 0.60, 1.0)
		eye_mat.albedo_color = eye_color
		eye_mat.emission_enabled = true
		eye_mat.emission = eye_color
		eye_mat.emission_energy_multiplier = 7.0
		eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		eye.material_override = eye_mat
		model.add_child(eye)

	add_child(model)


func _matte_black() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = default_color
	mat.roughness = 1.0
	mat.metallic = 0.0
	return mat


# ── Combate ───────────────────────────────────────────────────────────────────

## Si te recuerda, no persigue. Nunca.
func _should_pursue(distance: float) -> bool:
	if _remembers_player:
		return false
	return super._should_pursue(distance)


func perform_attack() -> void:
	if _remembers_player or has_status(&"stun"):
		return
	can_attack = false

	if is_instance_valid(target):
		target.take_damage(damage * outgoing_damage_mult())
		# Un picotazo de un cuervo de cinco metros tira. Reusa el contrato de status que el
		# jugador ya tiene desde el jabalí.
		if target.has_method("apply_status"):
			target.apply_status(&"stun", 0.6, self)

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true
