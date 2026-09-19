extends Node3D

## Piso 2 — el bosque bajo la luna llena. La antesala.
##
## Canon `lore/_alpha_5_maps.md` §"P2 — Alcance del Demo": el demo incluye ~un cuarto del
## piso 2 como gancho —
##   1. descenso por el acantilado (la bioluminiscencia drena hacia abajo)
##   2. 2-3 min de bosque: "cambio sensorial total: lluvia, oscuridad, árboles con luces
##      fluorescentes" (Kimetsu), tono místico/élfico
##   3. algo te observa (silueta que desaparece)
##   4. corte "continuará"
##
## Por eso este piso NO es otra pradera con enemigos más duros. Es un CAMBIO DE SENTIDOS:
## el jugador acaba de salir de una caverna luminosa y quieta, y cae a lluvia, oscuridad y
## un bosque que respira. La dificultad no es el punto — el punto es que se sienta OTRO
## MUNDO. Por eso el camino es lineal y corto: es un pasillo de atmósfera, no un sandbox.
##
## Canon `tower_biome_system.md`: el tier de un piso = su número. Los enemigos de acá son
## tier 2 (búhos, serpientes, polillas gigantes). Su jefe es El Vigilante — la misma silueta
## que te observa a mitad de camino, esperándote al fondo.

const SCENE_PLAYER_FALLBACK: String = "res://scenes/player/player.tscn"
const SCENE_HUD: PackedScene = preload("res://scenes/hud/hud.tscn")

const TREE_BIRCH: String = "res://assets/art/piso1_pradera/vegetation/birch/env_tree_birch_01.gltf"
const TREE_DEAD: String = "res://assets/art/piso1_pradera/vegetation/dead/env_tree_dead_01.gltf"
const TREE_COMMON: String = "res://assets/art/piso1_pradera/vegetation/common/env_tree_common_01.gltf"

## El corredor. Largo pero angosto: es un camino, no un mapa.
const PATH_LENGTH: float = 220.0
const PATH_HALF_WIDTH: float = 26.0

## Dónde aparece el que te observa, y dónde termina todo.
const WATCHER_Z: float = -120.0
const ENDING_Z: float = -205.0

## Luna llena — azul frío, débil. Lo suficiente para ver siluetas, no para sentirse seguro.
const MOON_COLOR: Color = Color(0.55, 0.68, 0.95)
const FLUORESCENT: Color = Color(0.35, 0.95, 0.80)  # las luces de los árboles (Kimetsu)

var _rng := RandomNumberGenerator.new()
var _watcher: Node3D = null
var _watcher_seen := false
var _player: Node3D = null
var _boss_spawned := false


func _ready() -> void:
	# El seed del mundo hace que el mismo mundo dé el mismo bosque, igual que el piso 1.
	_rng.seed = GameManager.world_seed if GameManager.world_seed >= 0 else 2

	_build_environment()
	_build_ground()
	_build_forest()
	_build_rain()
	_spawn_bestiary()
	_spawn_watcher()
	_spawn_ending_trigger()
	_spawn_player_and_hud()


## Bestiario canon del P2 (`lore/_alpha_5_maps.md`): "búhos, serpientes entre arbustos,
## polillas gigantes". Sembrado RALO a propósito: la antesala es un pasillo de atmósfera,
## y un bosque lleno de mobs se convierte en una arena. Tienen que interrumpir el silencio,
## no llenarlo.
##
## Búho = hawk retierado a 2. El halcón ya ES un depredador aéreo con dive-bomb y grab; un
## búho es ese mismo animal, de noche. No hace falta una IA nueva para cambiarle el turno.
func _spawn_bestiary() -> void:
	var moth: PackedScene = load("res://scenes/enemy/giant_moth.tscn")
	var snake: PackedScene = load("res://scenes/enemy/snake.tscn")
	var owl: PackedScene = load("res://scenes/enemy/hawk.tscn")

	# (escena, cantidad, altura de spawn)
	var roster: Array = [[moth, 7, 2.4], [snake, 5, 0.6], [owl, 3, 4.0]]

	for entry: Array in roster:
		var packed: PackedScene = entry[0]
		if packed == null:
			continue
		for i in range(int(entry[1])):
			var enemy: CharacterBody3D = packed.instantiate()
			# Repartidos a lo largo del camino, nunca en la entrada: el jugador acaba de
			# caer por un acantilado y merece tres segundos para mirar antes de pelear.
			var z: float = _rng.randf_range(-PATH_LENGTH + 20.0, -35.0)
			var x: float = _rng.randf_range(-PATH_HALF_WIDTH * 0.7, PATH_HALF_WIDTH * 0.7)
			add_child(enemy)
			enemy.global_position = Vector3(x, float(entry[2]), z)
			# Tier 2: es el piso 2 (canon enemy_tier_system.md — el tier de un piso es su número).
			if enemy is BaseEnemy:
				(enemy as BaseEnemy).enemy_tier = 2


# ── Atmósfera ─────────────────────────────────────────────────────────────────

## Lluvia, niebla y oscuridad. Este bloque ES el piso: si se siente igual que el piso 1,
## el piso 2 falló, por más enemigos que tenga.
func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.05, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.17, 0.28)
	env.ambient_light_energy = 0.55

	# Niebla: recorta la vista y hace que el bosque parezca continuar sin fin.
	env.fog_enabled = true
	env.fog_light_color = Color(0.18, 0.26, 0.38)
	env.fog_density = 0.035
	env.fog_sky_affect = 0.0

	env.glow_enabled = true          # las luces de los árboles tienen que SANGRAR
	env.glow_intensity = 0.9
	env.glow_bloom = 0.35

	var we := WorldEnvironment.new()
	we.name = "Environment"
	we.environment = env
	add_child(we)

	var moon := DirectionalLight3D.new()
	moon.name = "Moon"
	moon.light_color = MOON_COLOR
	moon.light_energy = 0.45      # débil a propósito: la luna no ilumina, insinúa
	moon.shadow_enabled = true
	moon.rotation_degrees = Vector3(-58.0, 35.0, 0.0)
	add_child(moon)


## Lluvia. Parenteada al player en _spawn_player_and_hud, así llueve donde él esté en vez
## de simular una tormenta sobre 200m de bosque que nadie ve.
func _build_rain() -> void:
	var rain := GPUParticles3D.new()
	rain.name = "Rain"
	rain.amount = 900
	rain.lifetime = 1.4
	rain.visibility_aabb = AABB(Vector3(-18, -12, -18), Vector3(36, 24, 36))

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(16.0, 0.5, 16.0)
	pm.direction = Vector3(0.08, -1.0, 0.0)
	pm.spread = 2.0
	pm.initial_velocity_min = 14.0
	pm.initial_velocity_max = 18.0
	pm.gravity = Vector3(0, -9.0, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	pm.color = Color(0.62, 0.75, 0.92, 0.55)
	rain.process_material = pm

	var drop := BoxMesh.new()
	drop.size = Vector3(0.015, 0.32, 0.015)
	rain.draw_pass_1 = drop

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.75, 0.92, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.70, 0.90)
	mat.emission_energy_multiplier = 0.7
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain.material_override = mat

	rain.position = Vector3(0, 11.0, 0)
	add_child(rain)


# ── El bosque ─────────────────────────────────────────────────────────────────

func _build_ground() -> void:
	var ground := CSGBox3D.new()
	ground.name = "Ground"
	ground.size = Vector3(PATH_HALF_WIDTH * 2.0 + 40.0, 1.0, PATH_LENGTH + 60.0)
	ground.position = Vector3(0, -0.5, -PATH_LENGTH * 0.5)
	ground.use_collision = true

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.11, 0.09)   # suelo mojado, casi negro
	mat.roughness = 0.85
	ground.material_override = mat
	add_child(ground)


## Árboles a ambos lados, cerrando el camino. Algunos con luz fluorescente: canon Kimetsu —
## el bosque no está iluminado, el bosque BRILLA.
func _build_forest() -> void:
	var trees: Array[PackedScene] = []
	for path: String in [TREE_BIRCH, TREE_DEAD, TREE_COMMON]:
		var packed: PackedScene = load(path)
		if packed != null:
			trees.append(packed)
	if trees.is_empty():
		push_warning("floor2_forest: no cargó ningún árbol — el bosque queda vacío")
		return

	var count: int = 190
	for i in range(count):
		var z: float = _rng.randf_range(-PATH_LENGTH - 20.0, 10.0)
		# Empujados a los costados: el centro queda libre para caminar.
		var side: float = 1.0 if _rng.randf() > 0.5 else -1.0
		var x: float = side * _rng.randf_range(6.0, PATH_HALF_WIDTH)

		var tree: Node3D = trees[_rng.randi() % trees.size()].instantiate()
		tree.position = Vector3(x, 0.0, z)
		tree.rotation.y = _rng.randf() * TAU
		var s: float = _rng.randf_range(1.3, 2.6)   # altos: el jugador se siente chico
		tree.scale = Vector3(s, s * _rng.randf_range(1.0, 1.35), s)
		add_child(tree)

		# ~1 de cada 5 lleva luz. Suficiente para que el bosque respire, no tanto como para
		# iluminar el camino — la oscuridad tiene que seguir doliendo.
		if _rng.randf() < 0.2:
			var glow := OmniLight3D.new()
			glow.light_color = FLUORESCENT
			glow.light_energy = _rng.randf_range(0.7, 1.5)
			glow.omni_range = _rng.randf_range(6.0, 11.0)
			glow.position = Vector3(x, _rng.randf_range(2.5, 5.5), z)
			add_child(glow)
			_pulse(glow)


## Respiración lenta y desfasada. Si todas las luces pulsaran juntas, leería como una
## máquina; desfasadas, lee como algo vivo.
func _pulse(light: OmniLight3D) -> void:
	var base: float = light.light_energy
	var t := create_tween().set_loops()
	var period: float = _rng.randf_range(2.2, 4.5)
	t.tween_interval(_rng.randf_range(0.0, period))
	t.tween_property(light, "light_energy", base * 1.7, period).set_trans(Tween.TRANS_SINE)
	t.tween_property(light, "light_energy", base * 0.6, period).set_trans(Tween.TRANS_SINE)


# ── "Algo te observa" ─────────────────────────────────────────────────────────

## Canon: "Algo te observa (silueta que desaparece)". No pelea, no habla, no dropea.
## Su único trabajo es que el jugador dude de si lo vio.
func _spawn_watcher() -> void:
	_watcher = Node3D.new()
	_watcher.name = "Watcher"
	_watcher.position = Vector3(14.0, 0.0, WATCHER_Z)

	# Silueta: una forma humanoide negra. Legible de lejos, sin detalle que la explique.
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 2.35
	body.mesh = capsule
	body.position = Vector3(0, 1.2, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.01, 0.01, 0.02)
	mat.roughness = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # una sombra recortada, no un cuerpo
	body.material_override = mat
	_watcher.add_child(body)

	# Dos ojos. Es lo único que emite: lo que ves primero son los ojos.
	for side: float in [-0.16, 0.16]:
		var eye := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.055
		sphere.height = 0.11
		eye.mesh = sphere
		eye.position = Vector3(side, 2.02, -0.36)
		var eye_mat := StandardMaterial3D.new()
		eye_mat.albedo_color = FLUORESCENT
		eye_mat.emission_enabled = true
		eye_mat.emission = FLUORESCENT
		eye_mat.emission_energy_multiplier = 6.0
		eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		eye.material_override = eye_mat
		_watcher.add_child(eye)

	_watcher.visible = false
	add_child(_watcher)


func _process(_delta: float) -> void:
	if _player == null or _watcher == null or _watcher_seen:
		return
	if not is_instance_valid(_player):
		return
	# Aparece cuando el jugador llega a su altura. Que aparezca por tiempo lo volvería una
	# cinemática; que aparezca por posición lo vuelve un lugar.
	if _player.global_position.z <= WATCHER_Z + 22.0:
		_watcher_seen = true
		_reveal_watcher()


## Se muestra, te sostiene la mirada, y se va. Nunca se acerca.
func _reveal_watcher() -> void:
	_watcher.visible = true
	var t := create_tween()
	t.tween_interval(1.9)                       # el tiempo justo para que dudes
	t.tween_property(_watcher, "position:x", 26.0, 0.9).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(_watcher, "visible", false, 0.0).set_delay(0.85)


# ── Fin del demo ──────────────────────────────────────────────────────────────

## Al fondo del bosque te espera lo que te venía mirando.
##
## Canon `enemy_tier_system.md`: "el boss de cada piso es un GATE". El Vigilante es ese gate,
## y es el mismo que se te apareció a mitad de camino y desapareció. No se inventó un jefe
## para llenar un casillero: se le cobró la deuda a la escena que el propio canon monta —
## "el bosque vivo que te observa", "algo te observa (silueta que desaparece)".
##
## El paso al Piso 3 se abre cuando cae.
func _spawn_ending_trigger() -> void:
	var trigger := Area3D.new()
	trigger.name = "BossSpawnTrigger"
	trigger.collision_mask = 2   # capa del player — con 1 el trigger es ciego (bug histórico)
	trigger.position = Vector3(0, 2.0, ENDING_Z + 30.0)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(PATH_HALF_WIDTH * 2.0, 8.0, 5.0)
	shape.shape = box
	trigger.add_child(shape)

	trigger.body_entered.connect(func(body: Node) -> void:
		if _boss_spawned or not body.is_in_group("player"):
			return
		_boss_spawned = true
		trigger.set_deferred("monitoring", false)
		_spawn_watcher_boss.call_deferred()
	)
	add_child(trigger)


func _spawn_watcher_boss() -> void:
	var packed: PackedScene = load("res://scenes/enemy/forest_watcher.tscn")
	if packed == null:
		push_error("floor2_forest: no cargó el Vigilante")
		return
	var boss: BaseEnemy = packed.instantiate()
	add_child(boss)
	boss.global_position = Vector3(0, 1.0, ENDING_Z)
	boss.died.connect(_on_watcher_died)

	# La silueta que te seguía ya no hace falta: se paró enfrente tuyo.
	if _watcher != null and is_instance_valid(_watcher):
		_watcher.queue_free()


## Muerto el Vigilante, el bosque te deja ir.
func _on_watcher_died(boss: BaseEnemy) -> void:
	var descent := FloorDescent.new()
	descent.name = "FloorDescent"
	descent.from_floor = 2
	add_child(descent)
	descent.global_position = boss.global_position + Vector3(0, 0.2, 6.0)


# ── Player + HUD ──────────────────────────────────────────────────────────────

func _spawn_player_and_hud() -> void:
	var scene_path: String = GameManager.selected_class_scene
	if scene_path == "":
		scene_path = SCENE_PLAYER_FALLBACK
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("floor2_forest: no se pudo cargar el player en '%s'" % scene_path)
		return

	_player = packed.instantiate()
	add_child(_player)
	# Entra por arriba del camino: acaba de bajar el acantilado.
	_player.global_position = Vector3(0, 2.0, 0)

	var hud: CanvasLayer = SCENE_HUD.instantiate()
	add_child(hud)
	if hud.has_method("connect_to_player"):
		hud.connect_to_player(_player)

	# La lluvia sigue al jugador — simularla sobre 200m de bosque sería pagar por agua que
	# nadie ve caer.
	var rain := get_node_or_null("Rain")
	if rain != null:
		remove_child(rain)
		_player.add_child(rain)
		(rain as Node3D).position = Vector3(0, 11.0, 0)
