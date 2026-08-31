class_name BiomeFloor
extends Node3D

## Piso genérico dirigido por config. Los pisos 3, 4 y 5 son el MISMO código con distinta
## config — porque canon `tower_biome_system.md` dice que un piso ES un bioma más un tier,
## y no hay razón para escribir tres monolitos de 3000 líneas que se diferencian en la
## paleta y en qué mob spawnea.
##
## El Piso 1 (pradera) y el Piso 2 (bosque) siguen siendo escenas propias: el 1 es un
## sandbox proc-gen enorme y el 2 tiene su vigilante scripteado. Este archivo no los
## reemplaza — cubre a los que no necesitan nada bespoke.
##
## Canon `enemy_tier_system.md`: "el tier de un piso = numero de piso". La config trae el
## piso; los enemigos se retieran solos.

## Lo que define un piso. Todo lo visual sale de acá, nada está hardcodeado abajo.
class BiomeConfig:
	var floor_number: int = 3
	var display_name: String = ""

	# Atmósfera
	var sky_color: Color = Color(0.05, 0.07, 0.12)
	var ambient_color: Color = Color(0.2, 0.25, 0.35)
	var ambient_energy: float = 0.6
	var fog_color: Color = Color(0.3, 0.35, 0.45)
	var fog_density: float = 0.02
	var sun_color: Color = Color(0.8, 0.85, 1.0)
	var sun_energy: float = 0.8
	var sun_angle: Vector3 = Vector3(-55.0, 30.0, 0.0)

	# Suelo
	var ground_color: Color = Color(0.7, 0.75, 0.85)
	var ground_roughness: float = 0.9

	# Props: se dispersan como cuerpos rígidos del bioma (rocas de hielo, dunas, esquirlas).
	var prop_color: Color = Color(0.8, 0.88, 0.95)
	var prop_count: int = 120
	var prop_min_scale: float = 0.8
	var prop_max_scale: float = 3.5
	var prop_emissive: bool = false

	# Clima: partículas cayendo (nieve, arena, esquirlas). 0 = sin clima.
	var weather_amount: int = 0
	var weather_color: Color = Color(1, 1, 1, 0.8)
	var weather_velocity: float = 6.0
	var weather_drift: Vector3 = Vector3(0, -1, 0)

	# Gravedad. El P5 la rompe a propósito (canon: "gravedad variable").
	var gravity_scale: float = 1.0

	# Bestiario: [[ruta_escena, cantidad, altura_spawn], ...]
	var bestiary: Array = []

	# Boss opcional al final del piso. "" = sin boss.
	var boss_scene: String = ""

	# Adónde baja. "" = último piso construido → cliffhanger.
	var next_floor_scene: String = ""


const SCENE_HUD: PackedScene = preload("res://scenes/hud/hud.tscn")
const SCENE_PLAYER_FALLBACK: String = "res://scenes/player/player.tscn"

const PATH_LENGTH: float = 240.0
const PATH_HALF_WIDTH: float = 30.0
const BOSS_Z: float = -215.0

var config: BiomeConfig = BiomeConfig.new()

var _rng := RandomNumberGenerator.new()
var _player: Node3D = null
var _boss_spawned := false


## Las subclases sobreescriben esto y devuelven su bioma. Es el único punto de variación.
func _get_config() -> BiomeConfig:
	return BiomeConfig.new()


func _ready() -> void:
	config = _get_config()
	# El seed del mundo hace reproducible el piso, igual que el 1 y el 2.
	_rng.seed = (GameManager.world_seed if GameManager.world_seed >= 0 else 0) + config.floor_number

	_build_environment()
	_build_ground()
	_scatter_props()
	_build_weather()
	_spawn_bestiary()
	_spawn_boss_trigger()
	_spawn_player_and_hud()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = config.sky_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = config.ambient_color
	env.ambient_light_energy = config.ambient_energy
	env.fog_enabled = config.fog_density > 0.0
	env.fog_light_color = config.fog_color
	env.fog_density = config.fog_density
	env.fog_sky_affect = 0.0
	env.glow_enabled = true
	env.glow_intensity = 0.8

	var we := WorldEnvironment.new()
	we.name = "Environment"
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "KeyLight"
	sun.light_color = config.sun_color
	sun.light_energy = config.sun_energy
	sun.shadow_enabled = true
	sun.rotation_degrees = config.sun_angle
	add_child(sun)


func _build_ground() -> void:
	var ground := CSGBox3D.new()
	ground.name = "Ground"
	ground.size = Vector3(PATH_HALF_WIDTH * 2.0 + 50.0, 1.0, PATH_LENGTH + 70.0)
	ground.position = Vector3(0, -0.5, -PATH_LENGTH * 0.5)
	ground.use_collision = true

	var mat := StandardMaterial3D.new()
	mat.albedo_color = config.ground_color
	mat.roughness = config.ground_roughness
	ground.material_override = mat
	add_child(ground)


## Props del bioma. Cajas rotadas y escaladas: bloques de hielo, rocas de arena, esquirlas
## del vacío. Deliberadamente primitivas — un piso legible con formas simples vale más que
## uno bonito que no existe.
func _scatter_props() -> void:
	for i in range(config.prop_count):
		var prop := MeshInstance3D.new()
		var box := BoxMesh.new()
		var s: float = _rng.randf_range(config.prop_min_scale, config.prop_max_scale)
		box.size = Vector3(s, s * _rng.randf_range(0.6, 2.2), s)
		prop.mesh = box

		var mat := StandardMaterial3D.new()
		mat.albedo_color = config.prop_color
		mat.roughness = 0.7
		if config.prop_emissive:
			mat.emission_enabled = true
			mat.emission = config.prop_color
			mat.emission_energy_multiplier = 1.4
		prop.material_override = mat

		var z: float = _rng.randf_range(-PATH_LENGTH - 20.0, 10.0)
		# Empujados a los bordes: el centro es el camino.
		var side: float = 1.0 if _rng.randf() > 0.5 else -1.0
		var x: float = side * _rng.randf_range(7.0, PATH_HALF_WIDTH + 12.0)
		prop.position = Vector3(x, s * 0.3, z)
		prop.rotation = Vector3(
			_rng.randf_range(-0.3, 0.3),
			_rng.randf() * TAU,
			_rng.randf_range(-0.3, 0.3)
		)
		add_child(prop)


## Clima: nieve, arena, esquirlas. Parenteado al player en _spawn_player_and_hud — simularlo
## sobre 240m sería pagar por partículas que nadie ve caer.
func _build_weather() -> void:
	if config.weather_amount <= 0:
		return

	var w := GPUParticles3D.new()
	w.name = "Weather"
	w.amount = config.weather_amount
	w.lifetime = 3.0
	w.visibility_aabb = AABB(Vector3(-20, -14, -20), Vector3(40, 28, 40))

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(18.0, 0.5, 18.0)
	pm.direction = config.weather_drift
	pm.spread = 12.0
	pm.initial_velocity_min = config.weather_velocity * 0.7
	pm.initial_velocity_max = config.weather_velocity
	pm.gravity = Vector3(0, -1.5, 0)
	pm.scale_min = 0.4
	pm.scale_max = 1.0
	pm.color = config.weather_color
	w.process_material = pm

	var flake := BoxMesh.new()
	flake.size = Vector3(0.08, 0.08, 0.08)
	w.draw_pass_1 = flake

	var mat := StandardMaterial3D.new()
	mat.albedo_color = config.weather_color
	mat.emission_enabled = true
	mat.emission = config.weather_color
	mat.emission_energy_multiplier = 0.6
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	w.material_override = mat

	w.position = Vector3(0, 12.0, 0)
	add_child(w)


## Enemigos del bioma, retierados al piso. Ralos: son pisos-corredor.
func _spawn_bestiary() -> void:
	for entry: Array in config.bestiary:
		var packed: PackedScene = load(String(entry[0]))
		if packed == null:
			continue
		for i in range(int(entry[1])):
			var enemy: CharacterBody3D = packed.instantiate()
			var z: float = _rng.randf_range(-PATH_LENGTH + 25.0, -30.0)
			var x: float = _rng.randf_range(-PATH_HALF_WIDTH * 0.7, PATH_HALF_WIDTH * 0.7)
			add_child(enemy)
			enemy.global_position = Vector3(x, float(entry[2]), z)
			if enemy is BaseEnemy:
				# Canon: el tier de un piso es su número. Un mob del P4 pega como el P4.
				(enemy as BaseEnemy).enemy_tier = config.floor_number


## El boss espera al fondo. Un Area3D lo trae cuando el jugador llega, igual que el
## King Slime — y con la MISMA máscara de capa que aquel tenía mal (layer 2 = player).
func _spawn_boss_trigger() -> void:
	if config.boss_scene == "":
		# Sin boss: el descenso (o el cliffhanger) espera al fondo del camino.
		_spawn_descent(Vector3(0, 0, BOSS_Z))
		return

	var trigger := Area3D.new()
	trigger.name = "BossSpawnTrigger"
	trigger.collision_mask = 2  # capa del player — con 1 el trigger es ciego (bug histórico)
	trigger.position = Vector3(0, 2.0, BOSS_Z + 35.0)

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
		_spawn_boss.call_deferred()
	)
	add_child(trigger)


func _spawn_boss() -> void:
	var packed: PackedScene = load(config.boss_scene)
	if packed == null:
		push_error("BiomeFloor: no cargó el boss '%s'" % config.boss_scene)
		return
	var boss: Node3D = packed.instantiate()
	add_child(boss)
	boss.global_position = Vector3(0, 1.0, BOSS_Z)
	if boss is BaseEnemy:
		var be := boss as BaseEnemy
		be.enemy_tier = config.floor_number
		be.died.connect(_on_boss_died)


## Muerto el boss, se abre el paso — el mismo contrato que el piso 1.
func _on_boss_died(boss: BaseEnemy) -> void:
	_spawn_descent(boss.global_position + Vector3(0, 0, 6.0))


func _spawn_descent(spot: Vector3) -> void:
	var descent := FloorDescent.new()
	descent.name = "FloorDescent"
	descent.from_floor = config.floor_number
	add_child(descent)
	descent.global_position = spot


func _spawn_player_and_hud() -> void:
	var scene_path: String = GameManager.selected_class_scene
	if scene_path == "":
		scene_path = SCENE_PLAYER_FALLBACK
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("BiomeFloor: no cargó el player en '%s'" % scene_path)
		return

	_player = packed.instantiate()
	add_child(_player)
	_player.global_position = Vector3(0, 2.0, 0)

	# Gravedad del bioma. El P5 flota (canon: "gravedad variable") — y eso cambia cómo se
	# CAMINA, no solo cómo se ve: saltás más alto y caés más lento, y el piso se siente roto
	# antes de que nadie te explique que lo está.
	if config.gravity_scale != 1.0 and "gravity" in _player:
		_player.set("gravity", float(_player.get("gravity")) * config.gravity_scale)

	var hud: CanvasLayer = SCENE_HUD.instantiate()
	add_child(hud)
	if hud.has_method("connect_to_player"):
		hud.connect_to_player(_player)

	var weather := get_node_or_null("Weather")
	if weather != null:
		remove_child(weather)
		_player.add_child(weather)
		(weather as Node3D).position = Vector3(0, 12.0, 0)
