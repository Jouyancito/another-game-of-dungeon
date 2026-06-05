extends Node3D

## Floor 1 — Pradera Interior
## Mundo abierto 600×600m con borde orgánico, techo de caverna,
## diamante de luz, vegetación procedural y spawn escalado.

@export var world_seed: int = 12345

# ── Map dimensions ────────────────────────────────────────────────────────────
const MAP_SIZE: Vector2 = Vector2(600.0, 600.0)
const MAP_CENTER: Vector3 = Vector3.ZERO

# Border
const BORDER_RADIUS_BASE: float = 250.0
const BORDER_NOISE_AMP: float = 45.0
const BORDER_NOISE_FREQ: float = 4.0
const BORDER_WALL_HEIGHT: float = 25.0
const BORDER_WALL_SEGMENTS: int = 64

# Ceiling — NO projeta sombras para evitar oscuridad invertida
const CEILING_HEIGHT: float = 45.0

# Crystal field — cuarzos distribuidos en curva S (vía láctea mineral)
const CRYSTAL_PATH_CLUSTERS: int = 35       # clusters a lo largo de la curva
const CRYSTAL_SCATTER_WIDTH: float = 60.0    # ancho de dispersión lateral
const CRYSTAL_MIN_HEIGHT: float = 32.0       # altura mínima (cuelgan del techo)
const CRYSTAL_MAX_HEIGHT: float = 42.0
const CRYSTAL_LIGHT_RANGE: float = 80.0      # rango grande — menos luces, más cobertura
const CRYSTAL_LIGHT_ENERGY: float = 0.9
const CRYSTAL_AMBIENT_ENERGY: float = 0.25   # ambient global para que se sienta pradera
const CRYSTAL_MONARCH_COUNT: int = 3         # cristales gigantes "príncipe"
const CRYSTAL_LIGHTS_EVERY: int = 3          # luz real cada N clusters (reduce OmniLights)
const CEILING_BIOLUM_PATCHES: int = 50       # parches bioluminiscentes en el techo
const CEILING_BIOLUM_COLOR: Color = Color(0.4, 0.7, 0.55)  # verde azulado orgánico

# Landmarks
const PILLAR_COUNT: int = 6
const PILLAR_MIN_HEIGHT: float = 30.0
const PILLAR_MAX_HEIGHT: float = 50.0

# Vegetation
const TREE_COUNT: int = 200
const ROCK_COUNT: int = 120
const TALL_GRASS_COUNT: int = 80

# Enemies
const FIELD_ENEMY_COUNT: int = 35
const PATROL_ENEMY_COUNT: int = 8

# Terrain (heightmap)
const TERRAIN_RESOLUTION: int = 96       # grid cells por lado (96*96 = 9216 verts)
const TERRAIN_MAX_HEIGHT: float = 9.0    # alto max de colinas
const TERRAIN_NOISE_FREQ: float = 0.004  # frecuencia baja = features grandes
const TERRAIN_NOISE_OCTAVES: int = 3
const TERRAIN_EDGE_RISE: float = 6.0     # subida hacia los bordes (acantilados)

# ── Colors ────────────────────────────────────────────────────────────────────
const COLOR_FLOOR: Color       = Color(0.290, 0.478, 0.180)
const COLOR_TRUNK: Color       = Color(0.361, 0.227, 0.118)
const COLOR_CANOPY: Color      = Color(0.176, 0.353, 0.118)
const COLOR_CANOPY_DARK: Color = Color(0.118, 0.275, 0.078)
const COLOR_TALL_GRASS: Color  = Color(0.118, 0.290, 0.055)
const COLOR_ROCK: Color        = Color(0.502, 0.502, 0.502)
const COLOR_ROCK_DARK: Color   = Color(0.380, 0.380, 0.380)
const COLOR_RUIN: Color        = Color(0.627, 0.627, 0.627)
const COLOR_BOSS_WALL: Color   = Color(0.314, 0.314, 0.314)
const COLOR_PATH: Color        = Color(0.420, 0.259, 0.149)
const COLOR_BORDER: Color      = Color(0.345, 0.290, 0.235)
const COLOR_CEILING: Color     = Color(0.250, 0.220, 0.200)
const COLOR_CRYSTAL_WARM: Color = Color(1.0, 0.95, 0.85)   # cuarzo blanco cálido
const COLOR_CRYSTAL_COOL: Color = Color(0.85, 0.9, 1.0)    # cuarzo azulado
const COLOR_CRYSTAL_ROSE: Color = Color(1.0, 0.88, 0.92)   # cuarzo rosa pálido
const COLOR_PILLAR: Color      = Color(0.400, 0.380, 0.340)
const COLOR_WATER: Color       = Color(0.2, 0.4, 0.6, 0.6)
const COLOR_CAMP_TENT: Color   = Color(0.550, 0.350, 0.200)
const COLOR_ALTAR: Color       = Color(0.700, 0.650, 0.550)
const COLOR_GIANT_TRUNK: Color = Color(0.300, 0.200, 0.100)
const COLOR_GIANT_CANOPY: Color = Color(0.130, 0.300, 0.080)

# ── Scene references ──────────────────────────────────────────────────────────
var SCENE_PLAYER: PackedScene
const SCENE_ENEMY_BASIC: PackedScene = preload("res://scenes/enemy/enemy_basic.tscn")
const SCENE_SLIME: PackedScene       = preload("res://scenes/enemy/slime.tscn")
const SCENE_BIRD: PackedScene        = preload("res://scenes/enemy/bird.tscn")
const SCENE_HUD: PackedScene         = preload("res://scenes/hud/hud.tscn")

# Nuevos enemigos — load() en vez de preload() para debugging
var SCENE_RAT: PackedScene
var SCENE_SNAKE: PackedScene
var SCENE_FOX: PackedScene
var SCENE_WOLF: PackedScene
var SCENE_BANDIT_MELEE: PackedScene
var SCENE_BANDIT_ARCHER: PackedScene
var SCENE_GOLEM: PackedScene
var SCENE_SCORPION: PackedScene
var SCENE_HAWK: PackedScene
var SCENE_GOAT: PackedScene
var SCENE_WASP: PackedScene
var SCENE_TURTLE: PackedScene

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _border_noise_offsets: Array[float] = []

# Terrain state
var _terrain_noise: FastNoiseLite
var _terrain_heights: PackedFloat32Array
var _terrain_stride: int = 0  # TERRAIN_RESOLUTION + 1

# ── Ready ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Cargar escenas de enemigos nuevos
	SCENE_RAT = load("res://scenes/enemy/rat.tscn")
	SCENE_SNAKE = load("res://scenes/enemy/snake.tscn")
	SCENE_FOX = load("res://scenes/enemy/fox.tscn")
	SCENE_WOLF = load("res://scenes/enemy/wolf.tscn")
	SCENE_BANDIT_MELEE = load("res://scenes/enemy/bandit_melee.tscn")
	SCENE_BANDIT_ARCHER = load("res://scenes/enemy/bandit_archer.tscn")
	SCENE_GOLEM = load("res://scenes/enemy/golem.tscn")
	SCENE_SCORPION = load("res://scenes/enemy/scorpion.tscn")
	SCENE_HAWK = load("res://scenes/enemy/hawk.tscn")
	SCENE_GOAT = load("res://scenes/enemy/goat.tscn")
	SCENE_WASP = load("res://scenes/enemy/wasp.tscn")
	SCENE_TURTLE = load("res://scenes/enemy/turtle.tscn")

	var class_path: String = GameManager.selected_class_scene
	if not ResourceLoader.exists(class_path):
		class_path = "res://scenes/player/player.tscn"
	SCENE_PLAYER = load(class_path)

	_rng.seed = world_seed
	_precalculate_border()
	_setup_terrain_noise()

	# 1. Atmósfera
	_build_ceiling()
	_build_crystal_field()
	_build_landmark_pillars()

	# 2. Borde orgánico
	_build_organic_border()

	# 2.5. Terreno con relieve
	_generate_terrain_mesh()
	_hide_flat_ground()

	# 3. POIs — ajustar al terreno antes de construir
	var poi_system: POISystem = POISystem.new()
	var pois: Array = poi_system.generate_pois(world_seed, MAP_SIZE, _is_inside_border)

	for poi in pois:
		var p: POISystem.POI = poi as POISystem.POI
		p.position.y = get_terrain_height(p.position.x, p.position.z)
		match p.type:
			"entrance":   _build_entrance(p)
			"ruins":      _build_ruins(p)
			"boss":       _build_boss_arena(p)
			"camp":       _build_camp(p)
			"giant_tree": _build_giant_tree(p)
			"altar":      _build_altar(p)
			"well":       _build_well(p)
			"pond":       _build_pond(p)

	# 4. Vegetación
	_generate_vegetation(pois)

	# 5. Jugador — ajustar a la altura del terreno
	var entrance_pos: Vector3 = _find_entrance_pos(pois)
	entrance_pos.y = get_terrain_height(entrance_pos.x, entrance_pos.z)
	var player: CharacterBody3D = SCENE_PLAYER.instantiate() as CharacterBody3D
	add_child(player)
	player.global_position = entrance_pos + Vector3(0, 2.0, 0)

	# 6. Enemigos
	_spawn_poi_enemies(pois)
	_spawn_field_enemies(pois, entrance_pos)

	# 6.5. Ajustar todos los enemigos y vegetación al terreno
	_snap_all_to_terrain()

	# 7. HUD
	var hud: CanvasLayer = SCENE_HUD.instantiate() as CanvasLayer
	add_child(hud)
	if hud.has_method("connect_to_player"):
		hud.connect_to_player(player)

	# 8. Starter items si el personaje es nuevo (inventario vacío)
	GameUISetup.grant_starter_items(GameManager.selected_class_scene)

	# 9. UI compartida — pausa, ventana de personaje, diario, inventario
	# Va DESPUÉS del player y starter items porque inventory_ui usa GameManager.player_inventory
	GameUISetup.setup_ui(self)

# ── Border system ─────────────────────────────────────────────────────────────

func _precalculate_border() -> void:
	_border_noise_offsets.clear()
	for i in range(360):
		var angle_rad: float = deg_to_rad(float(i))
		var noise_val: float = (
			sin(angle_rad * BORDER_NOISE_FREQ) * 0.5 +
			sin(angle_rad * BORDER_NOISE_FREQ * 2.3 + 1.7) * 0.3 +
			sin(angle_rad * BORDER_NOISE_FREQ * 0.7 + 3.1) * 0.2
		)
		_border_noise_offsets.append(noise_val * BORDER_NOISE_AMP)

func _get_border_radius_at_angle(angle_deg: float) -> float:
	var idx: int = wrapi(int(angle_deg), 0, 360)
	var idx_next: int = wrapi(idx + 1, 0, 360)
	var frac: float = angle_deg - floor(angle_deg)
	var noise: float = lerp(_border_noise_offsets[idx], _border_noise_offsets[idx_next], frac)
	return BORDER_RADIUS_BASE + noise

func _is_inside_border(pos: Variant) -> bool:
	var world_pos: Vector3
	if pos is Vector3:
		world_pos = pos
	else:
		return false
	var dx: float = world_pos.x - MAP_CENTER.x
	var dz: float = world_pos.z - MAP_CENTER.z
	var dist: float = sqrt(dx * dx + dz * dz)
	var angle_deg: float = rad_to_deg(atan2(dz, dx))
	if angle_deg < 0:
		angle_deg += 360.0
	return dist < _get_border_radius_at_angle(angle_deg) - 10.0

# ── Terrain (heightmap con relieve) ──────────────────────────────────────────

func _setup_terrain_noise() -> void:
	_terrain_noise = FastNoiseLite.new()
	_terrain_noise.seed = world_seed
	_terrain_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_terrain_noise.frequency = TERRAIN_NOISE_FREQ
	_terrain_noise.fractal_octaves = TERRAIN_NOISE_OCTAVES
	_terrain_noise.fractal_lacunarity = 2.0
	_terrain_noise.fractal_gain = 0.5


## Calcula la altura en una coordenada world (x, z).
## Suma: noise base + subida hacia bordes + flattening en el centro.
func _compute_height_at(x: float, z: float) -> float:
	# 1. Noise base — colinas suaves
	var n: float = _terrain_noise.get_noise_2d(x, z)  # -1..1
	n = (n + 1.0) * 0.5  # 0..1
	var h: float = n * TERRAIN_MAX_HEIGHT

	# 2. Distancia al centro (normalizada 0..1)
	var dist_center: float = sqrt(x * x + z * z)
	var max_r: float = BORDER_RADIUS_BASE
	var t: float = clampf(dist_center / max_r, 0.0, 1.0)

	# 3. Flatten en el centro (radio 50m) para que la entrada sea plana
	var flat_radius: float = 50.0
	if dist_center < flat_radius:
		var flat_t: float = dist_center / flat_radius
		h = lerpf(0.0, h, smoothstep(0.0, 1.0, flat_t))

	# 4. Subida hacia los bordes (acantilados naturales)
	if t > 0.7:
		var edge_t: float = (t - 0.7) / 0.3
		h += TERRAIN_EDGE_RISE * edge_t * edge_t

	return h


func _precompute_terrain_heights() -> void:
	_terrain_stride = TERRAIN_RESOLUTION + 1
	_terrain_heights = PackedFloat32Array()
	_terrain_heights.resize(_terrain_stride * _terrain_stride)

	var step: float = MAP_SIZE.x / float(TERRAIN_RESOLUTION)
	var half: float = MAP_SIZE.x * 0.5
	for ix in range(_terrain_stride):
		for iz in range(_terrain_stride):
			var wx: float = -half + float(ix) * step
			var wz: float = -half + float(iz) * step
			_terrain_heights[ix * _terrain_stride + iz] = _compute_height_at(wx, wz)


## Consulta la altura del terreno en cualquier coordenada world.
## Usado por POIs, enemigos y vegetación para ajustarse al terreno.
func get_terrain_height(x: float, z: float) -> float:
	if _terrain_heights.is_empty():
		return 0.0
	var half: float = MAP_SIZE.x * 0.5
	var step: float = MAP_SIZE.x / float(TERRAIN_RESOLUTION)
	var fx: float = (x + half) / step
	var fz: float = (z + half) / step
	var ix: int = clampi(int(fx), 0, TERRAIN_RESOLUTION - 1)
	var iz: int = clampi(int(fz), 0, TERRAIN_RESOLUTION - 1)
	var tx: float = fx - float(ix)
	var tz: float = fz - float(iz)

	# Bilinear interp
	var h00: float = _terrain_heights[ix * _terrain_stride + iz]
	var h10: float = _terrain_heights[(ix + 1) * _terrain_stride + iz]
	var h01: float = _terrain_heights[ix * _terrain_stride + (iz + 1)]
	var h11: float = _terrain_heights[(ix + 1) * _terrain_stride + (iz + 1)]
	var h0: float = lerpf(h00, h10, tx)
	var h1: float = lerpf(h01, h11, tx)
	return lerpf(h0, h1, tz)


func _generate_terrain_mesh() -> void:
	_precompute_terrain_heights()

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var step: float = MAP_SIZE.x / float(TERRAIN_RESOLUTION)
	var half: float = MAP_SIZE.x * 0.5

	for ix in range(TERRAIN_RESOLUTION):
		for iz in range(TERRAIN_RESOLUTION):
			var x0: float = -half + float(ix) * step
			var x1: float = x0 + step
			var z0: float = -half + float(iz) * step
			var z1: float = z0 + step

			var h00: float = _terrain_heights[ix * _terrain_stride + iz]
			var h10: float = _terrain_heights[(ix + 1) * _terrain_stride + iz]
			var h01: float = _terrain_heights[ix * _terrain_stride + (iz + 1)]
			var h11: float = _terrain_heights[(ix + 1) * _terrain_stride + (iz + 1)]

			var v00 := Vector3(x0, h00, z0)
			var v10 := Vector3(x1, h10, z0)
			var v01 := Vector3(x0, h01, z1)
			var v11 := Vector3(x1, h11, z1)

			# Color por altura: verde oscuro bajo, verde claro medio, marrón/gris alto
			var c00: Color = _height_to_color(h00)
			var c10: Color = _height_to_color(h10)
			var c01: Color = _height_to_color(h01)
			var c11: Color = _height_to_color(h11)

			# Triángulo 1: v00 - v10 - v11
			st.set_color(c00); st.add_vertex(v00)
			st.set_color(c10); st.add_vertex(v10)
			st.set_color(c11); st.add_vertex(v11)
			# Triángulo 2: v00 - v11 - v01
			st.set_color(c00); st.add_vertex(v00)
			st.set_color(c11); st.add_vertex(v11)
			st.set_color(c01); st.add_vertex(v01)

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()

	# Material: usar vertex colors
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9

	var terrain_mi := MeshInstance3D.new()
	terrain_mi.name = "TerrainMesh"
	terrain_mi.mesh = mesh
	terrain_mi.material_override = mat
	add_child(terrain_mi)

	# Colisión
	var body := StaticBody3D.new()
	body.name = "TerrainBody"
	add_child(body)
	var col := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.data = mesh.get_faces()
	col.shape = shape
	body.add_child(col)


func _height_to_color(h: float) -> Color:
	var t: float = clampf(h / TERRAIN_MAX_HEIGHT, 0.0, 1.0)
	# Bajo: verde oscuro pradera — Medio: verde claro — Alto: marrón/gris roca
	if t < 0.4:
		return Color(0.18, 0.38, 0.12).lerp(Color(0.29, 0.48, 0.18), t / 0.4)
	elif t < 0.75:
		return Color(0.29, 0.48, 0.18).lerp(Color(0.42, 0.45, 0.22), (t - 0.4) / 0.35)
	else:
		return Color(0.42, 0.45, 0.22).lerp(Color(0.45, 0.40, 0.30), (t - 0.75) / 0.25)


func _hide_flat_ground() -> void:
	var old: Node = get_node_or_null("GroundFloor")
	if old:
		old.visible = false
		# Mantener la colisión del CSG como fallback en caso de huecos
		if old.has_method("set_use_collision"):
			old.call("set_use_collision", false)


## Ajusta la Y de todos los enemigos al terreno.
## Los voladores (pájaros, halcones, avispas) mantienen su offset vertical actual.
func _snap_all_to_terrain() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for node: Node in enemies:
		if not is_instance_valid(node):
			continue
		var body: CharacterBody3D = node as CharacterBody3D
		if body == null:
			continue
		var terrain_y: float = get_terrain_height(body.global_position.x, body.global_position.z)
		# Conservar offset vertical para voladores
		var existing_offset: float = body.global_position.y
		# Si ya estaba alto (aire), mantener altura relativa
		if existing_offset > 2.5:
			body.global_position.y = terrain_y + existing_offset
		else:
			body.global_position.y = terrain_y + 1.0


func _build_organic_border() -> void:
	for i in range(BORDER_WALL_SEGMENTS):
		var angle1: float = float(i) / float(BORDER_WALL_SEGMENTS) * 360.0
		var angle2: float = float(i + 1) / float(BORDER_WALL_SEGMENTS) * 360.0
		var r1: float = _get_border_radius_at_angle(angle1)
		var r2: float = _get_border_radius_at_angle(angle2)
		var rad1: float = deg_to_rad(angle1)
		var rad2: float = deg_to_rad(angle2)

		var p1: Vector3 = Vector3(cos(rad1) * r1, 0, sin(rad1) * r1)
		var p2: Vector3 = Vector3(cos(rad2) * r2, 0, sin(rad2) * r2)
		var mid: Vector3 = (p1 + p2) * 0.5
		var seg_len: float = p1.distance_to(p2)
		var seg_angle: float = atan2(p2.z - p1.z, p2.x - p1.x)

		var wall: CSGBox3D = CSGBox3D.new()
		wall.name = "BorderWall%d" % i
		wall.size = Vector3(seg_len + 0.5, BORDER_WALL_HEIGHT, 3.0)
		wall.use_collision = true
		wall.material_override = _make_material(COLOR_BORDER)
		wall.position = mid + Vector3(0, BORDER_WALL_HEIGHT * 0.5, 0)
		wall.rotation.y = -seg_angle
		add_child(wall)

# ── Atmosphere ────────────────────────────────────────────────────────────────

func _build_ceiling() -> void:
	var ceiling: CSGBox3D = CSGBox3D.new()
	ceiling.name = "CavernCeiling"
	ceiling.size = Vector3(MAP_SIZE.x + 100, 2.0, MAP_SIZE.y + 100)
	ceiling.position = Vector3(0, CEILING_HEIGHT, 0)
	ceiling.use_collision = false
	ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# El techo NECESITA emisión propia — Godot no tiene GI, sin esto es negro
	var ceil_mat: StandardMaterial3D = StandardMaterial3D.new()
	ceil_mat.albedo_color = Color(0.35, 0.32, 0.28)
	ceil_mat.emission_enabled = true
	ceil_mat.emission = Color(0.18, 0.17, 0.15)  # emisión sutil — roca visible, no brillante
	ceil_mat.emission_energy_multiplier = 1.0
	ceiling.material_override = ceil_mat
	add_child(ceiling)

func _build_crystal_field() -> void:
	# Ambient general — pradera debe sentirse abierta, no mazmorra
	var ambient: OmniLight3D = OmniLight3D.new()
	ambient.name = "CrystalAmbient"
	ambient.light_color = Color(0.75, 0.8, 0.9)
	ambient.light_energy = CRYSTAL_AMBIENT_ENERGY
	ambient.omni_range = 350.0
	ambient.omni_attenuation = 0.5
	ambient.shadow_enabled = false
	ambient.position = Vector3(0, CEILING_HEIGHT - 5.0, 0)
	add_child(ambient)

	var crystal_colors: Array[Color] = [COLOR_CRYSTAL_WARM, COLOR_CRYSTAL_COOL, COLOR_CRYSTAL_ROSE]

	# ── 1. Cristales monarca — los "príncipes" del techo ──────────────────────
	var monarch_positions: Array[Vector3] = []
	for m in range(CRYSTAL_MONARCH_COUNT):
		var t: float = float(m + 1) / float(CRYSTAL_MONARCH_COUNT + 1)
		var mx: float = lerp(-160.0, 160.0, t) + _rng.randf_range(-30.0, 30.0)
		var mz: float = sin(t * PI * 1.6 + 0.3) * 110.0 + _rng.randf_range(-20.0, 20.0)
		if not _is_inside_border(Vector3(mx, 0, mz)):
			continue

		monarch_positions.append(Vector3(mx, 0, mz))
		var monarch_color: Color = crystal_colors[m % crystal_colors.size()]

		# Cristal central gigante
		_spawn_crystal_shard("Monarch%d_Core" % m,
			Vector3(mx, CEILING_HEIGHT - 3.0, mz), monarch_color,
			8.0, 18.0, 3.0, 5.0)  # ENORME

		# 8-12 cristales medianos/grandes alrededor
		var escort_count: int = _rng.randi_range(8, 12)
		for e in range(escort_count):
			var angle: float = float(e) / float(escort_count) * TAU + _rng.randf_range(-0.3, 0.3)
			var dist: float = _rng.randf_range(3.0, 10.0)
			var epos: Vector3 = Vector3(
				mx + cos(angle) * dist,
				_rng.randf_range(CEILING_HEIGHT - 8.0, CEILING_HEIGHT - 1.0),
				mz + sin(angle) * dist
			)
			# Mezcla de tamaños: algunos grandes, algunos chiquitos
			if _rng.randf() < 0.3:
				_spawn_crystal_shard("Monarch%d_Big%d" % [m, e], epos, monarch_color,
					3.0, 10.0, 1.5, 3.0)
			else:
				_spawn_crystal_shard("Monarch%d_Sm%d" % [m, e], epos, monarch_color,
					0.5, 3.0, 0.2, 0.8)

		# 5-8 cristales diminutos esparcidos (fragmentos)
		for f in range(_rng.randi_range(5, 8)):
			var fpos: Vector3 = Vector3(
				mx + _rng.randf_range(-12.0, 12.0),
				_rng.randf_range(CEILING_HEIGHT - 10.0, CEILING_HEIGHT - 2.0),
				mz + _rng.randf_range(-12.0, 12.0)
			)
			_spawn_crystal_shard("Monarch%d_Frag%d" % [m, f], fpos, monarch_color,
				0.2, 1.5, 0.1, 0.4)

		# Luz potente para los monarcas — ilumina mucho más
		var ml: OmniLight3D = OmniLight3D.new()
		ml.name = "MonarchLight%d" % m
		ml.light_color = Color(monarch_color.r, monarch_color.g * 0.95, monarch_color.b * 0.9)
		ml.light_energy = 1.5
		ml.omni_range = 80.0
		ml.omni_attenuation = 1.5
		ml.shadow_enabled = false
		ml.position = Vector3(mx, CEILING_HEIGHT - 8.0, mz)
		add_child(ml)

		# (sin luz up secundaria — el techo ya tiene emisión propia)

	# ── 2. Clusters regulares — variedad de tamaños ──────────────────────────
	for i in range(CRYSTAL_PATH_CLUSTERS):
		var t: float = float(i) / float(CRYSTAL_PATH_CLUSTERS - 1)

		var path_x: float = lerp(-200.0, 200.0, t)
		var path_z: float = sin(t * PI * 1.6 + 0.3) * 130.0
		path_x += _rng.randf_range(-25.0, 25.0)
		path_z += _rng.randf_range(-CRYSTAL_SCATTER_WIDTH * 0.5, CRYSTAL_SCATTER_WIDTH * 0.5)

		var cluster_pos: Vector3 = Vector3(path_x, 0, path_z)
		if not _is_inside_border(cluster_pos):
			continue

		# Evitar solapamiento con monarcas
		var too_close: bool = false
		for mp in monarch_positions:
			if Vector2(path_x - mp.x, path_z - mp.z).length() < 30.0:
				too_close = true
				break
		if too_close:
			continue

		var cluster_color: Color = crystal_colors[_rng.randi_range(0, crystal_colors.size() - 1)]

		# Tipo de cluster: variedad real
		var cluster_type: float = _rng.randf()
		if cluster_type < 0.2:
			# Tipo A: Un cristal grande dominante + muchos chiquitos
			var cy: float = _rng.randf_range(CRYSTAL_MIN_HEIGHT + 4.0, CRYSTAL_MAX_HEIGHT)
			_spawn_crystal_shard("Crystal%d_Dom" % i,
				Vector3(path_x, cy, path_z), cluster_color,
				4.0, 10.0, 1.5, 3.0)
			for s in range(_rng.randi_range(6, 10)):
				_spawn_crystal_shard("Crystal%d_%d" % [i, s],
					Vector3(path_x, cy, path_z), cluster_color,
					0.3, 2.0, 0.15, 0.6)
		elif cluster_type < 0.5:
			# Tipo B: Formación densa — muchos medianos agrupados
			var cy: float = _rng.randf_range(CRYSTAL_MIN_HEIGHT, CRYSTAL_MAX_HEIGHT)
			for s in range(_rng.randi_range(5, 9)):
				_spawn_crystal_shard("Crystal%d_%d" % [i, s],
					Vector3(path_x, cy, path_z), cluster_color,
					1.0, 5.0, 0.4, 1.5)
		elif cluster_type < 0.75:
			# Tipo C: Disperso — pocos cristales sueltos esparcidos
			var cy: float = _rng.randf_range(CRYSTAL_MIN_HEIGHT, CRYSTAL_MAX_HEIGHT)
			for s in range(_rng.randi_range(2, 4)):
				var spread: float = 8.0
				_spawn_crystal_shard("Crystal%d_%d" % [i, s],
					Vector3(
						path_x + _rng.randf_range(-spread, spread),
						cy + _rng.randf_range(-3.0, 3.0),
						path_z + _rng.randf_range(-spread, spread)
					), cluster_color,
					1.5, 6.0, 0.5, 1.8)
		else:
			# Tipo D: Cascada — cristales que bajan del techo en escalera
			for s in range(_rng.randi_range(4, 7)):
				var step_y: float = CEILING_HEIGHT - 2.0 - float(s) * _rng.randf_range(1.5, 3.0)
				var drift: float = float(s) * _rng.randf_range(0.5, 1.5)
				_spawn_crystal_shard("Crystal%d_%d" % [i, s],
					Vector3(path_x + drift, step_y, path_z + drift * 0.5),
					cluster_color,
					0.8, 4.5, 0.3, 1.2)

		# Luz real solo cada N clusters — reduce OmniLights, más rango compensa
		if i % CRYSTAL_LIGHTS_EVERY == 0:
			var cy_light: float = _rng.randf_range(CRYSTAL_MIN_HEIGHT - 2.0, CRYSTAL_MAX_HEIGHT - 2.0)
			var cl: OmniLight3D = OmniLight3D.new()
			cl.name = "CrystalLight%d" % i
			cl.light_color = Color(
				cluster_color.r * 0.9 + 0.1,
				cluster_color.g * 0.9 + 0.1,
				cluster_color.b * 0.85 + 0.1
			)
			cl.light_energy = CRYSTAL_LIGHT_ENERGY + _rng.randf_range(-0.15, 0.15)
			cl.omni_range = CRYSTAL_LIGHT_RANGE + _rng.randf_range(-10.0, 10.0)
			cl.omni_attenuation = 1.4
			cl.shadow_enabled = false
			cl.position = Vector3(path_x, cy_light, path_z)
			add_child(cl)

	# ── 3. Flush cristales acumulados a MultiMesh ────────────────────────────
	_flush_crystal_multimeshes()

	# ── 4. Bioluminiscencia del techo — parches que brillan ──────────────────
	_build_ceiling_bioluminescence()

func _build_ceiling_bioluminescence() -> void:
	var biolum_transforms: Array[Transform3D] = []

	for i in range(CEILING_BIOLUM_PATCHES):
		var angle: float = _rng.randf() * TAU
		var dist: float = _rng.randf_range(10.0, BORDER_RADIUS_BASE - 40.0)
		var bx: float = cos(angle) * dist
		var bz: float = sin(angle) * dist

		if not _is_inside_border(Vector3(bx, 0, bz)):
			continue

		var patch_w: float = _rng.randf_range(5.0, 20.0)
		var patch_d: float = _rng.randf_range(4.0, 16.0)
		var drop_h: float = _rng.randf_range(1.5, 4.0)
		var rot_y: float = _rng.randf_range(0, TAU)

		var pos := Vector3(bx, CEILING_HEIGHT - drop_h, bz)
		var basis := Basis.from_euler(Vector3(0, rot_y, 0))
		basis = basis.scaled(Vector3(patch_w, 0.15, patch_d))
		biolum_transforms.append(Transform3D(basis, pos))

	_create_multimesh_emissive("BiolumPatches", biolum_transforms,
		CEILING_BIOLUM_COLOR, 1.0)

# Acumuladores de cristales — se flushean con _flush_crystal_multimeshes()
var _crystal_warm_transforms: Array[Transform3D] = []
var _crystal_cool_transforms: Array[Transform3D] = []
var _crystal_rose_transforms: Array[Transform3D] = []

func _spawn_crystal_shard(_shard_name: String, center: Vector3, base_color: Color,
		min_len: float = 1.5, max_len: float = 6.0,
		min_width: float = 0.3, max_width: float = 1.2) -> void:
	var length: float = _rng.randf_range(min_len, max_len)
	var width: float = _rng.randf_range(min_width, max_width)
	var depth: float = width * _rng.randf_range(0.5, 1.0)

	var spread: float = max_len * 0.6
	var pos: Vector3 = center + Vector3(
		_rng.randf_range(-spread, spread),
		_rng.randf_range(-length * 0.3, length * 0.3),
		_rng.randf_range(-spread, spread)
	)

	# Construir transform con rotación + escala
	var rot_x: float = _rng.randf_range(deg_to_rad(150), deg_to_rad(210))
	var rot_y: float = _rng.randf_range(0, TAU)
	var rot_z: float = _rng.randf_range(deg_to_rad(-30), deg_to_rad(30))
	var basis := Basis.from_euler(Vector3(rot_x, rot_y, rot_z))
	basis = basis.scaled(Vector3(width, length, depth))
	var xform := Transform3D(basis, pos)

	# Acumular por color
	if base_color == COLOR_CRYSTAL_COOL:
		_crystal_cool_transforms.append(xform)
	elif base_color == COLOR_CRYSTAL_ROSE:
		_crystal_rose_transforms.append(xform)
	else:
		_crystal_warm_transforms.append(xform)


func _flush_crystal_multimeshes() -> void:
	_create_multimesh_emissive("CrystalsWarm", _crystal_warm_transforms,
		COLOR_CRYSTAL_WARM, 1.2)
	_create_multimesh_emissive("CrystalsCool", _crystal_cool_transforms,
		COLOR_CRYSTAL_COOL, 1.2)
	_create_multimesh_emissive("CrystalsRose", _crystal_rose_transforms,
		COLOR_CRYSTAL_ROSE, 1.2)


func _create_multimesh_emissive(mm_name: String, transforms: Array[Transform3D],
		color: Color, emission_energy: float) -> void:
	if transforms.is_empty():
		return

	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r * 0.95, color.g * 0.9, color.b * 0.85)
	mat.emission_energy_multiplier = emission_energy
	mesh.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()

	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])

	var mmi := MultiMeshInstance3D.new()
	mmi.name = mm_name
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

func _build_landmark_pillars() -> void:
	for i in range(PILLAR_COUNT):
		var angle: float = (float(i) / float(PILLAR_COUNT)) * TAU + _rng.randf_range(-0.2, 0.2)
		var dist: float = _rng.randf_range(100.0, 200.0)
		var pos: Vector3 = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		if not _is_inside_border(pos):
			continue
		var height: float = _rng.randf_range(PILLAR_MIN_HEIGHT, PILLAR_MAX_HEIGHT)

		var pillar: CSGCylinder3D = CSGCylinder3D.new()
		pillar.name = "LandmarkPillar%d" % i
		pillar.radius = _rng.randf_range(2.0, 4.0)
		pillar.height = height
		pillar.sides = 8
		pillar.use_collision = true
		pillar.material_override = _make_material(COLOR_PILLAR)
		pillar.position = pos + Vector3(0, height * 0.5, 0)
		add_child(pillar)

# ── POI builders ──────────────────────────────────────────────────────────────

func _find_entrance_pos(pois: Array) -> Vector3:
	for poi in pois:
		var p: POISystem.POI = poi as POISystem.POI
		if p.is_entrance:
			return p.position
	return Vector3.ZERO

func _build_entrance(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position
	var sz: Vector2 = poi.size

	_add_csg_box("EntranceGround", pos + Vector3(0, 0.02, 0),
		Vector3(sz.x, 0.04, sz.y), COLOR_PATH, false)

	for side in [-1.0, 1.0]:
		_add_csg_box("EntranceStone%s" % ("N" if side < 0 else "S"),
			pos + Vector3(0, 0.6, side * sz.y * 0.5),
			Vector3(sz.x * 0.8, 1.2, 0.8), COLOR_ROCK, true)

	for side in [-1.0, 1.0]:
		var pillar: CSGCylinder3D = CSGCylinder3D.new()
		pillar.name = "EntrancePillar%s" % ("L" if side < 0 else "R")
		pillar.radius = 0.5
		pillar.height = 4.0
		pillar.sides = 8
		pillar.use_collision = true
		pillar.material_override = _make_material(COLOR_ROCK)
		pillar.position = pos + Vector3(sz.x * 0.4 * side, 2.0, -sz.y * 0.5)
		add_child(pillar)

func _build_ruins(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position
	var sz: Vector2 = poi.size

	_add_csg_box("RuinsGround", pos + Vector3(0, 0.02, 0),
		Vector3(sz.x, 0.04, sz.y), COLOR_RUIN, false)

	var wall_count: int = _rng.randi_range(5, 8)
	for i in range(wall_count):
		var ox: float = _rng.randf_range(-sz.x * 0.35, sz.x * 0.35)
		var oz: float = _rng.randf_range(-sz.y * 0.35, sz.y * 0.35)
		var wh: float = _rng.randf_range(1.5, 4.0)
		var ww: float = _rng.randf_range(4.0, 10.0)
		var wd: float = _rng.randf_range(0.5, 1.0)
		if _rng.randf() > 0.5:
			var tmp: float = ww; ww = wd; wd = tmp
		_add_csg_box("RuinWall%d" % i, pos + Vector3(ox, wh * 0.5, oz),
			Vector3(ww, wh, wd), COLOR_RUIN, true)

	var well: CSGCylinder3D = CSGCylinder3D.new()
	well.name = "RuinsWell"
	well.radius = 1.2
	well.height = 1.2
	well.use_collision = true
	well.material_override = _make_material(COLOR_ROCK)
	well.position = pos + Vector3(0, 0.6, 0)
	add_child(well)

	for i in range(4):
		var rx: float = _rng.randf_range(-sz.x * 0.3, sz.x * 0.3)
		var rz: float = _rng.randf_range(-sz.y * 0.3, sz.y * 0.3)
		var rs: float = _rng.randf_range(0.8, 1.8)
		_add_csg_box("RuinsRock%d" % i,
			pos + Vector3(rx, rs * 0.5, rz),
			Vector3(rs * 1.2, rs, rs), COLOR_ROCK_DARK, true)

func _build_boss_arena(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position
	var sz: Vector2 = poi.size
	var hw: float = sz.x * 0.5
	var hd: float = sz.y * 0.5
	var wall_h: float = 6.0
	var wall_t: float = 1.2

	_add_csg_box("BossGround", pos + Vector3(0, 0.02, 0),
		Vector3(sz.x, 0.04, sz.y), COLOR_BOSS_WALL, false)

	_add_csg_box("BossWallN", pos + Vector3(0, wall_h * 0.5, -hd),
		Vector3(sz.x, wall_h, wall_t), COLOR_BOSS_WALL, true)
	_add_csg_box("BossWallS", pos + Vector3(0, wall_h * 0.5, hd),
		Vector3(sz.x, wall_h, wall_t), COLOR_BOSS_WALL, true)
	_add_csg_box("BossWallE", pos + Vector3(hw, wall_h * 0.5, 0),
		Vector3(wall_t, wall_h, sz.y), COLOR_BOSS_WALL, true)

	var gate_w: float = 12.0
	var side_len: float = (sz.y - gate_w) * 0.5
	_add_csg_box("BossWallW_N",
		pos + Vector3(-hw, wall_h * 0.5, -(gate_w * 0.5 + side_len * 0.5)),
		Vector3(wall_t, wall_h, side_len), COLOR_BOSS_WALL, true)
	_add_csg_box("BossWallW_S",
		pos + Vector3(-hw, wall_h * 0.5, gate_w * 0.5 + side_len * 0.5),
		Vector3(wall_t, wall_h, side_len), COLOR_BOSS_WALL, true)
	_add_csg_box("BossWallW_Top",
		pos + Vector3(-hw, wall_h - 0.75, 0),
		Vector3(wall_t, 1.5, gate_w), COLOR_BOSS_WALL, true)

	for i in range(5):
		var rx: float = _rng.randf_range(-hw * 0.6, hw * 0.6)
		var rz: float = _rng.randf_range(-hd * 0.6, hd * 0.6)
		_add_csg_box("BossRubble%d" % i,
			pos + Vector3(rx, 0.5, rz),
			Vector3(_rng.randf_range(2.0, 4.0), 1.0, _rng.randf_range(1.5, 3.0)),
			COLOR_BOSS_WALL, true)

	# ── Boss spawn trigger ──────────────────────────────────────────
	# Area3D en la entrada del gate oeste. Spawnea al Rey Slime una sola vez
	# cuando el jugador cruza. El boss aparece en el centro de la arena.
	var trigger := Area3D.new()
	trigger.name = "BossSpawnTrigger"
	trigger.monitoring = true
	trigger.collision_mask = 1  # Player está en layer 1 por default (inconsistencia vs CLAUDE.md, doc dice layer 2 pero tscn no la setea)
	var trigger_shape := CollisionShape3D.new()
	var trigger_box := BoxShape3D.new()
	trigger_box.size = Vector3(wall_t * 3.0, wall_h, gate_w)
	trigger_shape.shape = trigger_box
	trigger.add_child(trigger_shape)
	trigger.position = pos + Vector3(-hw + wall_t * 0.5, wall_h * 0.5, 0)
	add_child(trigger)

	var spawn_center: Vector3 = pos + Vector3(0, 1.5, 0)
	var spawned := [false]  # Array wrapper para mutar desde lambda
	trigger.body_entered.connect(func(body: Node) -> void:
		if spawned[0]:
			return
		if not body.is_in_group("player"):
			return
		spawned[0] = true
		var king_scene: PackedScene = load("res://scenes/enemy/king_slime.tscn")
		if king_scene == null:
			push_error("floor1_prairie: no se pudo cargar king_slime.tscn")
			return
		var king: Node3D = king_scene.instantiate()
		king.global_position = spawn_center
		add_child(king)
		trigger.set_deferred("monitoring", false)
	)

func _build_camp(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position
	var sz: Vector2 = poi.size

	_add_csg_box("CampGround", pos + Vector3(0, 0.02, 0),
		Vector3(sz.x, 0.04, sz.y), COLOR_PATH, false)

	var tent_count: int = _rng.randi_range(2, 3)
	for i in range(tent_count):
		var tx: float = _rng.randf_range(-sz.x * 0.25, sz.x * 0.25)
		var tz: float = _rng.randf_range(-sz.y * 0.25, sz.y * 0.25)
		_add_csg_box("CampTent%d" % i,
			pos + Vector3(tx, 1.2, tz),
			Vector3(4.0, 2.4, 3.0), COLOR_CAMP_TENT, true)

	var fire: CSGCylinder3D = CSGCylinder3D.new()
	fire.name = "CampFire"
	fire.radius = 0.6
	fire.height = 0.3
	fire.use_collision = false
	fire.material_override = _make_material(Color(0.2, 0.1, 0.05))
	fire.position = pos + Vector3(0, 0.15, 0)
	add_child(fire)

	var fire_light: OmniLight3D = OmniLight3D.new()
	fire_light.name = "CampFireLight"
	fire_light.light_color = Color(1.0, 0.6, 0.2)
	fire_light.light_energy = 0.6
	fire_light.omni_range = 15.0
	fire_light.position = pos + Vector3(0, 1.0, 0)
	add_child(fire_light)

	for i in range(3):
		var angle: float = float(i) * TAU / 3.0
		_add_csg_box("CampLog%d" % i,
			pos + Vector3(cos(angle) * 2.0, 0.2, sin(angle) * 2.0),
			Vector3(2.0, 0.4, 0.5), COLOR_TRUNK, true)

func _build_giant_tree(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position
	var trunk_h: float = 20.0
	var trunk_r: float = 3.0
	var canopy_r: float = 15.0

	var trunk: CSGCylinder3D = CSGCylinder3D.new()
	trunk.name = "GiantTreeTrunk"
	trunk.radius = trunk_r
	trunk.height = trunk_h
	trunk.sides = 12
	trunk.use_collision = true
	trunk.material_override = _make_material(COLOR_GIANT_TRUNK)
	trunk.position = pos + Vector3(0, trunk_h * 0.5, 0)
	add_child(trunk)

	_add_csg_box("GiantTreeCanopy",
		pos + Vector3(0, trunk_h + canopy_r * 0.4, 0),
		Vector3(canopy_r * 2, canopy_r * 0.8, canopy_r * 2),
		COLOR_GIANT_CANOPY, false)

	for i in range(5):
		var angle: float = float(i) * TAU / 5.0 + _rng.randf_range(-0.2, 0.2)
		var root_len: float = _rng.randf_range(4.0, 7.0)
		_add_csg_box("GiantRoot%d" % i,
			pos + Vector3(cos(angle) * (trunk_r + root_len * 0.5), 0.4, sin(angle) * (trunk_r + root_len * 0.5)),
			Vector3(root_len, 0.8, 1.5), COLOR_GIANT_TRUNK, true)

func _build_altar(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position

	var base: CSGCylinder3D = CSGCylinder3D.new()
	base.name = "AltarBase"
	base.radius = 3.0
	base.height = 0.4
	base.use_collision = true
	base.material_override = _make_material(COLOR_ALTAR)
	base.position = pos + Vector3(0, 0.2, 0)
	add_child(base)

	_add_csg_box("AltarStone", pos + Vector3(0, 0.9, 0),
		Vector3(1.5, 1.4, 1.5), COLOR_ALTAR, true)

	for i in range(4):
		var angle: float = float(i) * TAU / 4.0
		_add_csg_box("AltarPillar%d" % i,
			pos + Vector3(cos(angle) * 2.2, 0.6, sin(angle) * 2.2),
			Vector3(0.5, 1.2, 0.5), COLOR_ROCK, true)

func _build_well(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position

	var well: CSGCylinder3D = CSGCylinder3D.new()
	well.name = "WellStruct"
	well.radius = 1.0
	well.height = 1.0
	well.use_collision = true
	well.material_override = _make_material(COLOR_ROCK)
	well.position = pos + Vector3(0, 0.5, 0)
	add_child(well)

	var water: CSGCylinder3D = CSGCylinder3D.new()
	water.name = "WellWater"
	water.radius = 0.8
	water.height = 0.05
	water.use_collision = false
	var water_mat: StandardMaterial3D = StandardMaterial3D.new()
	water_mat.albedo_color = COLOR_WATER
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.material_override = water_mat
	water.position = pos + Vector3(0, 0.3, 0)
	add_child(water)

func _build_pond(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position
	var sz: Vector2 = poi.size

	var water: CSGCylinder3D = CSGCylinder3D.new()
	water.name = "PondWater"
	water.radius = sz.x * 0.4
	water.height = 0.1
	water.sides = 16
	water.use_collision = false
	var water_mat: StandardMaterial3D = StandardMaterial3D.new()
	water_mat.albedo_color = COLOR_WATER
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.material_override = water_mat
	water.position = pos + Vector3(0, -0.05, 0)
	add_child(water)

	for i in range(8):
		var angle: float = float(i) * TAU / 8.0
		var br: float = sz.x * 0.4 + 0.5
		_add_csg_box("PondRock%d" % i,
			pos + Vector3(cos(angle) * br, 0.25, sin(angle) * br),
			Vector3(_rng.randf_range(0.6, 1.2), 0.5, _rng.randf_range(0.6, 1.2)),
			COLOR_ROCK, true)

# ── Vegetation (gltf scatter — assets reales CC0) ────────────────────────────
# Pools de assets reales para scatter procedural. Reemplaza el viejo BoxMesh
# placeholder: el mapa entero se puebla con los gltf integrados, no cajas planas.

const POOL_TREES: Array[PackedScene] = [
	preload("res://assets/art/piso1_pradera/vegetation/birch/env_tree_birch_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/birch/env_tree_birch_02.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/birch/env_tree_birch_03.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/birch/env_tree_birch_04.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/birch/env_tree_birch_05.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_02.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_03.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/common/env_tree_common_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/common/env_tree_common_02.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/common/env_tree_common_03.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/dead/env_tree_dead_01.gltf"),
]
const POOL_BUSHES: Array[PackedScene] = [
	preload("res://assets/art/piso1_pradera/vegetation/bush/env_bush_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/bush/env_bush_large_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/bush/env_bush_flowers_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/bush/env_bush_small_flowers_01.gltf"),
]
const POOL_ROCKS: Array[PackedScene] = [
	preload("res://assets/art/piso1_pradera/props/rocks/prop_rock_large_01.glb"),
	preload("res://assets/art/piso1_pradera/props/rocks/prop_rock_small_01.glb"),
	preload("res://assets/art/piso1_pradera/props/rocks/prop_rock_wide_01.glb"),
	preload("res://assets/art/piso1_pradera/terrain/pebbles/env_pebble_round_01.gltf"),
]
const POOL_GROUND: Array[PackedScene] = [
	preload("res://assets/art/piso1_pradera/vegetation/flowers/env_flower_clump_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/flowers/env_flower_clump_02.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/flowers/env_flower_clump_03.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/clover/env_clover_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/mushroom/env_mushroom_common_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/mushroom/env_mushroom_laetiporus_01.gltf"),
]

func _generate_vegetation(pois: Array) -> void:
	var container := Node3D.new()
	container.name = "VegetationScatter"
	add_child(container)

	# ── 1. Biome clusters anclados a POIs (placement curado) ──────────────────
	# Cada POI temático se viste con su bioma: el estanque con árboles al borde,
	# la arena del boss con un acantilado rocoso, el árbol gigante con bosque denso.
	# Crea "lugares" con intención en vez de scatter uniforme.
	for poi in pois:
		var p: POISystem.POI = poi as POISystem.POI
		var c: Vector3 = p.position
		var r: float = p.size.x * 0.5
		# Rangos de escala AMPLIOS (con sesgo de edad en _age_scale): conviven
		# árboles recién crecidos, medianos y patriarcas añosos. Da profundidad.
		# El "halo" de transición deshilacha cada cluster hacia el campo (conexión).
		# Escala de árboles calibrada a proporción real: nativo birch 5.45m /
		# common 7.26m / maple 6.64m. Rango 0.8-1.7 → mayoría 3-5x el player (1.8m),
		# con jóvenes ~2.5x y patriarcas añosos ~6x (el sesgo de _age_scale reparte).
		match p.type:
			"pond":
				# Estanque: anillo de árboles + flores/juncos pegados al agua
				_scatter_cluster(POOL_TREES, 16, c, r + 2.0, r + 12.0, 0.85, 1.6, container)
				_scatter_cluster(POOL_GROUND, 24, c, r - 1.0, r + 6.0, 0.7, 1.6, container)
				_scatter_cluster(POOL_BUSHES, 8, c, r + 1.0, r + 8.0, 0.6, 1.6, container)
				_scatter_cluster(POOL_TREES, 12, c, r + 12.0, r + 32.0, 0.7, 1.15, container)  # halo
			"boss":
				# Acantilado: cúmulo de rocas grandes rodeando la arena
				_scatter_cluster(POOL_ROCKS, 28, c, r + 2.0, r + 18.0, 0.7, 2.9, container)
				_scatter_cluster(POOL_ROCKS, 16, c, r + 18.0, r + 40.0, 0.4, 1.4, container)  # halo
			"giant_tree":
				# Bosque denso alrededor del árbol gigante + halo que se deshilacha
				_scatter_cluster(POOL_TREES, 30, c, r * 0.4, r + 16.0, 0.85, 1.7, container)
				_scatter_cluster(POOL_BUSHES, 12, c, r * 0.4, r + 14.0, 0.6, 1.7, container)
				_scatter_cluster(POOL_TREES, 22, c, r + 16.0, r + 48.0, 0.7, 1.2, container)  # halo
			"entrance":
				# Grove de bienvenida: pocos árboles enmarcando, claro abierto al centro
				_scatter_cluster(POOL_TREES, 10, c, r + 4.0, r + 18.0, 0.85, 1.6, container)
				_scatter_cluster(POOL_GROUND, 16, c, r, r + 12.0, 0.7, 1.7, container)
				_scatter_cluster(POOL_TREES, 12, c, r + 18.0, r + 38.0, 0.7, 1.15, container)  # halo
			"ruins":
				# Escombros: rocas dispersas + arbustos invasores
				_scatter_cluster(POOL_ROCKS, 14, c, r * 0.5, r + 8.0, 0.6, 2.0, container)
				_scatter_cluster(POOL_BUSHES, 10, c, r * 0.5, r + 6.0, 0.6, 1.5, container)
			"camp":
				_scatter_cluster(POOL_BUSHES, 8, c, r + 1.0, r + 8.0, 0.6, 1.4, container)
			"altar", "well":
				_scatter_cluster(POOL_GROUND, 12, c, r, r + 6.0, 0.7, 1.6, container)

	# ── 2. Tejido conectivo entre clusters (cose los mini-biomas) ─────────────
	# Subido respecto al ralo anterior: llena los huecos muertos entre lugares
	# para que el mapa se lea continuo, no como islas sueltas. Escala amplia.
	_scatter_pool(POOL_TREES, int(TREE_COUNT * 0.7), pois, 18.0, 0.8, 1.6, container)
	_scatter_pool(POOL_ROCKS, int(ROCK_COUNT * 0.45), pois, 12.0, 0.5, 2.0, container)
	_scatter_pool(POOL_BUSHES, int(ROCK_COUNT * 0.4), pois, 9.0, 0.6, 1.6, container)
	_scatter_pool(POOL_GROUND, int(TALL_GRASS_COUNT * 0.7), pois, 7.0, 0.7, 1.6, container)

## Esparce instancias en un anillo (inner_r..outer_r) alrededor de `center`.
## Es el placement temático: rodea un POI con su bioma característico.
func _scatter_cluster(
	pool: Array, count: int, center: Vector3,
	inner_r: float, outer_r: float, scale_min: float, scale_max: float, parent: Node3D
) -> void:
	if pool.is_empty():
		return
	for i in range(count):
		var angle: float = _rng.randf() * TAU
		var dist: float = _rng.randf_range(inner_r, outer_r)
		var pos: Vector3 = center + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		if not _is_inside_border(pos):
			continue
		pos.y = get_terrain_height(pos.x, pos.z)
		_place_instance(pool, pos, scale_min, scale_max, parent)

## Scatter uniforme por el mapa abierto, evitando POIs (tejido conectivo).
func _scatter_pool(
	pool: Array, count: int, pois: Array,
	min_poi_dist: float, scale_min: float, scale_max: float, parent: Node3D
) -> void:
	if pool.is_empty():
		return
	for i in range(count):
		var pos: Vector3 = _random_open_pos(pois, min_poi_dist)
		if pos == Vector3.INF:
			continue
		pos.y = get_terrain_height(pos.x, pos.z)
		_place_instance(pool, pos, scale_min, scale_max, parent)

## Instancia un PackedScene random del pool con rotación Y + escala por edad.
func _place_instance(
	pool: Array, pos: Vector3, scale_min: float, scale_max: float, parent: Node3D
) -> void:
	var scene: PackedScene = pool[_rng.randi() % pool.size()]
	var inst: Node3D = scene.instantiate() as Node3D
	if inst == null:
		return
	var s: float = _age_scale(scale_min, scale_max)
	var rot_y: float = _rng.randf() * TAU
	inst.transform = Transform3D(Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s)), pos)
	parent.add_child(inst)

## Escala con sesgo de "edad" en vez de uniforme: ~45% jóvenes (chicas),
## ~35% medianas, ~20% añosas (grandes). Da los tres grupos visibles y profundidad.
func _age_scale(smin: float, smax: float) -> float:
	var roll: float = _rng.randf()
	if roll < 0.45:
		return _rng.randf_range(smin, lerpf(smin, smax, 0.4))
	elif roll < 0.8:
		return _rng.randf_range(lerpf(smin, smax, 0.4), lerpf(smin, smax, 0.75))
	return _rng.randf_range(lerpf(smin, smax, 0.75), smax)

func _random_open_pos(pois: Array, min_distance_from_poi: float) -> Vector3:
	for _t in range(30):
		var angle: float = _rng.randf() * TAU
		var dist: float = _rng.randf_range(20.0, BORDER_RADIUS_BASE - 30.0)
		var candidate: Vector3 = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		if not _is_inside_border(candidate):
			continue
		var valid: bool = true
		for poi in pois:
			var p: POISystem.POI = poi as POISystem.POI
			var poi_hw: float = p.size.x * 0.5 + min_distance_from_poi
			var poi_hd: float = p.size.y * 0.5 + min_distance_from_poi
			if abs(candidate.x - p.position.x) < poi_hw and abs(candidate.z - p.position.z) < poi_hd:
				valid = false
				break
		if valid:
			return candidate
	return Vector3.INF

# ── Enemy spawning ────────────────────────────────────────────────────────────

func _spawn_poi_enemies(pois: Array) -> void:
	for poi in pois:
		var p: POISystem.POI = poi as POISystem.POI
		if p.enemy_count <= 0:
			continue

		# Elegir tabla de spawn según tipo de POI
		var table: Array = _get_poi_spawn_table(p.type)
		for i in range(p.enemy_count):
			var offset: Vector3 = Vector3(
				_rng.randf_range(-p.size.x * 0.3, p.size.x * 0.3),
				0.8,
				_rng.randf_range(-p.size.y * 0.3, p.size.y * 0.3)
			)
			var enemy: CharacterBody3D = _pick_from_table(table).instantiate() as CharacterBody3D
			add_child(enemy)
			enemy.global_position = p.position + offset

## Devuelve una posición en el anillo alrededor de un POI del tipo dado (si existe),
## o Vector3.INF si no hay ninguno. Para spawn ecológico: criaturas que PERTENECEN
## a un lugar (slimes junto al agua, lobos en el bosque) en vez de scatter uniforme.
func _pos_near_poi_type(pois: Array, poi_type: String, spread: float) -> Vector3:
	var matches: Array = []
	for poi in pois:
		var p: POISystem.POI = poi as POISystem.POI
		if p.type == poi_type:
			matches.append(p)
	if matches.is_empty():
		return Vector3.INF
	var chosen: POISystem.POI = matches[_rng.randi() % matches.size()] as POISystem.POI
	var r0: float = chosen.size.x * 0.5
	var angle: float = _rng.randf() * TAU
	var dist: float = _rng.randf_range(r0, r0 + spread)
	return chosen.position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)

func _spawn_field_enemies(_pois: Array, _player_pos: Vector3 = Vector3.ZERO) -> void:
	# ═══ Sub-tier A: fauna básica — abundante, variada ═══

	# Slimes: 8 packs. Ecología Axlin — la mitad se agrupa junto al agua (pond),
	# donde se alimentan de la bioluminiscencia de los cristales. Resto disperso.
	for _pack in range(8):
		var center: Vector3 = Vector3.INF
		if _pack < 4:
			center = _pos_near_poi_type(_pois, "pond", 10.0)
		if center == Vector3.INF:
			center = _random_open_pos(_pois, 20.0)
		if center == Vector3.INF:
			continue
		var pack_size: int = _rng.randi_range(1, 5)  # 1 suelto, 2-3 medio, 4-5 full
		for _i in range(pack_size):
			var offset := Vector3(_rng.randf_range(-3.0, 3.0), 0.8, _rng.randf_range(-3.0, 3.0))
			var slime: CharacterBody3D = SCENE_SLIME.instantiate()
			add_child(slime)
			slime.global_position = center + offset

	# Serpientes: 8 sueltas escondidas por todo el mapa
	for _i in range(8):
		var spos: Vector3 = _random_open_pos(_pois, 15.0)
		if spos == Vector3.INF:
			continue
		var snake: CharacterBody3D = SCENE_SNAKE.instantiate()
		add_child(snake)
		snake.global_position = spos + Vector3(0, 0.3, 0)

	# Ratas: 3 grupos (4-8 en ruinas, 2-3 sueltas)
	for _pack in range(3):
		var center: Vector3 = _random_open_pos(_pois, 20.0)
		if center == Vector3.INF:
			continue
		var pack_size: int = _rng.randi_range(2, 6)
		for _i in range(pack_size):
			var offset := Vector3(_rng.randf_range(-2.0, 2.0), 0.5, _rng.randf_range(-2.0, 2.0))
			var rat: CharacterBody3D = SCENE_RAT.instantiate()
			add_child(rat)
			rat.global_position = center + offset

	# Cabras: 2 packs (3-5 en colinas)
	for _pack in range(2):
		var center: Vector3 = _random_open_pos(_pois, 25.0)
		if center == Vector3.INF:
			continue
		for _i in range(_rng.randi_range(3, 5)):
			var offset := Vector3(_rng.randf_range(-5.0, 5.0), 0.8, _rng.randf_range(-5.0, 5.0))
			var goat: CharacterBody3D = SCENE_GOAT.instantiate()
			add_child(goat)
			goat.global_position = center + offset

	# Tortugas: 4 sueltas cerca del agua
	for _i in range(4):
		var tpos: Vector3 = _random_open_pos(_pois, 20.0)
		if tpos == Vector3.INF:
			continue
		var turtle: CharacterBody3D = SCENE_TURTLE.instantiate()
		add_child(turtle)
		turtle.global_position = tpos + Vector3(0, 0.5, 0)

	# ═══ Sub-tier B: depredadores — packs medianos + sueltos ═══

	# Pájaros: 5 packs (1-3 cada uno)
	for _pack in range(5):
		var center: Vector3 = _random_open_pos(_pois, 25.0)
		if center == Vector3.INF:
			continue
		for _i in range(_rng.randi_range(1, 3)):
			var offset := Vector3(_rng.randf_range(-5.0, 5.0), 0.0, _rng.randf_range(-5.0, 5.0))
			var bird: CharacterBody3D = SCENE_BIRD.instantiate()
			add_child(bird)
			bird.global_position = center + offset + Vector3(0, 3.0, 0)

	# Zorros: 3 packs (1-3 cada uno)
	for _pack in range(3):
		var center: Vector3 = _random_open_pos(_pois, 25.0)
		if center == Vector3.INF:
			continue
		for _i in range(_rng.randi_range(1, 3)):
			var offset := Vector3(_rng.randf_range(-4.0, 4.0), 0.8, _rng.randf_range(-4.0, 4.0))
			var fox: CharacterBody3D = SCENE_FOX.instantiate()
			add_child(fox)
			fox.global_position = center + offset

	# Lobos: 3 manadas (1 alfa + 1-3 pack). Ecología — cazan desde la cobertura
	# del bosque denso (giant_tree), no en campo abierto. Su presencia marca la zona.
	for _pack in range(3):
		var center: Vector3 = _pos_near_poi_type(_pois, "giant_tree", 14.0)
		if center == Vector3.INF:
			center = _random_open_pos(_pois, 30.0)
		if center == Vector3.INF:
			continue
		var alpha: CharacterBody3D = SCENE_WOLF.instantiate()
		alpha.set("is_alpha", true)
		add_child(alpha)
		alpha.global_position = center + Vector3(0, 0.8, 0)
		for _i in range(_rng.randi_range(1, 3)):
			var offset := Vector3(_rng.randf_range(-4.0, 4.0), 0.8, _rng.randf_range(-4.0, 4.0))
			var wolf: CharacterBody3D = SCENE_WOLF.instantiate()
			add_child(wolf)
			wolf.global_position = center + offset

	# Escorpiones: 3 packs (1-4 cada uno)
	for _pack in range(3):
		var center: Vector3 = _random_open_pos(_pois, 20.0)
		if center == Vector3.INF:
			continue
		for _i in range(_rng.randi_range(1, 4)):
			var offset := Vector3(_rng.randf_range(-3.0, 3.0), 0.5, _rng.randf_range(-3.0, 3.0))
			var scorp: CharacterBody3D = SCENE_SCORPION.instantiate()
			add_child(scorp)
			scorp.global_position = center + offset

	# Halcones: 4 sueltos en vuelo alto
	for _i in range(4):
		var hpos: Vector3 = _random_open_pos(_pois, 30.0)
		if hpos == Vector3.INF:
			continue
		var hawk: CharacterBody3D = SCENE_HAWK.instantiate()
		add_child(hawk)
		hawk.global_position = hpos + Vector3(0, 5.0, 0)

	# Avispas: 3 nidos (4-8 por nido)
	for _nest in range(3):
		var nest_center: Vector3 = _random_open_pos(_pois, 25.0)
		if nest_center == Vector3.INF:
			continue
		for _i in range(_rng.randi_range(4, 8)):
			var offset := Vector3(_rng.randf_range(-2.0, 2.0), _rng.randf_range(1.5, 2.5), _rng.randf_range(-2.0, 2.0))
			var wasp: CharacterBody3D = SCENE_WASP.instantiate()
			add_child(wasp)
			wasp.global_position = nest_center + offset

	# ═══ Sub-tier C: peligrosos — pocos, en zonas específicas ═══

	# Bandidos: 3 escuadras (full 2m+1a, media 1m+1a, solo 1 suelto)
	# Escuadra completa
	var bandit_center: Vector3 = _random_open_pos(_pois, 35.0)
	if bandit_center != Vector3.INF:
		for _i in range(3):
			var offset := Vector3(_rng.randf_range(-2.0, 2.0), 0.8, _rng.randf_range(-2.0, 2.0))
			var bm: CharacterBody3D = SCENE_BANDIT_MELEE.instantiate()
			add_child(bm)
			bm.global_position = bandit_center + offset
		for _i in range(2):
			var archer: CharacterBody3D = SCENE_BANDIT_ARCHER.instantiate()
			add_child(archer)
			archer.global_position = bandit_center + Vector3(_rng.randf_range(-4.0, 4.0), 0.8, _rng.randf_range(4.0, 7.0))

	# Escuadra media
	var bandit_center2: Vector3 = _random_open_pos(_pois, 35.0)
	if bandit_center2 != Vector3.INF:
		var bm2: CharacterBody3D = SCENE_BANDIT_MELEE.instantiate()
		add_child(bm2)
		bm2.global_position = bandit_center2 + Vector3(0, 0.8, 0)
		var archer2: CharacterBody3D = SCENE_BANDIT_ARCHER.instantiate()
		add_child(archer2)
		archer2.global_position = bandit_center2 + Vector3(3.0, 0.8, 4.0)

	# Bandido suelto (patrulla)
	var bandit_solo_pos: Vector3 = _random_open_pos(_pois, 30.0)
	if bandit_solo_pos != Vector3.INF:
		var bm_solo: CharacterBody3D = SCENE_BANDIT_MELEE.instantiate()
		add_child(bm_solo)
		bm_solo.global_position = bandit_solo_pos + Vector3(0, 0.8, 0)

	# Golems: 3 sueltos camuflados
	for _i in range(3):
		var gpos: Vector3 = _random_open_pos(_pois, 30.0)
		if gpos == Vector3.INF:
			continue
		var golem: CharacterBody3D = SCENE_GOLEM.instantiate()
		add_child(golem)
		golem.global_position = gpos + Vector3(0, 0.8, 0)

func _get_poi_spawn_table(poi_type: String) -> Array:
	match poi_type:
		"ruins":
			return [
				[0.30, SCENE_RAT],
				[0.55, SCENE_BANDIT_MELEE],
				[0.80, SCENE_BANDIT_ARCHER],
				[1.00, SCENE_SNAKE],
			]
		"camp":
			return [
				[0.40, SCENE_RAT],
				[0.70, SCENE_BANDIT_MELEE],
				[1.00, SCENE_BANDIT_ARCHER],
			]
		"giant_tree":
			return [
				[0.35, SCENE_FOX],
				[0.60, SCENE_BIRD],
				[0.80, SCENE_SNAKE],
				[1.00, SCENE_SLIME],
			]
		"boss":
			return [
				[0.50, SCENE_SLIME],
				[0.75, SCENE_BIRD],
				[1.00, SCENE_SCORPION],
			]
		_:
			return [
				[0.40, SCENE_SLIME],
				[0.65, SCENE_BIRD],
				[0.85, SCENE_RAT],
				[1.00, SCENE_SNAKE],
			]

func _pick_from_table(table: Array) -> PackedScene:
	var roll: float = _rng.randf()
	for entry in table:
		if roll <= entry[0]:
			return entry[1]
	return table[-1][1]

# ── CSG factory ───────────────────────────────────────────────────────────────

func _add_csg_box(node_name: String, world_pos: Vector3, size: Vector3, color: Color, with_collision: bool) -> CSGBox3D:
	var box: CSGBox3D = CSGBox3D.new()
	box.name = node_name
	box.size = size
	box.use_collision = with_collision
	box.material_override = _make_material(color)
	box.position = world_pos
	add_child(box)
	return box

func _make_material(color: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	return mat


# ── DEBUG: tecla K spawnea King Slime frente al player ──────────────
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_K:
				_debug_spawn_king_slime()
			KEY_1:
				_debug_force_attack("rebote")
			KEY_2:
				_debug_force_attack("embestida")
			KEY_3:
				_debug_force_attack("escupitajo")


func _debug_spawn_king_slime() -> void:
	var existing: Array = get_tree().get_nodes_in_group("enemies").filter(
		func(n: Node) -> bool: return n.name.begins_with("KingSlime") or (n.get_script() != null and str(n.get_script().resource_path).ends_with("king_slime.gd"))
	)
	if not existing.is_empty():
		print("DEBUG: King Slime ya existe — usa 1/2/3 para forzar ataques")
		return
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		push_warning("DEBUG: no player found")
		return
	var player: Node3D = players[0]
	var king_scene: PackedScene = load("res://scenes/enemy/king_slime.tscn")
	if king_scene == null:
		push_error("DEBUG: king_slime.tscn no carga")
		return
	var king: Node3D = king_scene.instantiate()
	var fwd: Vector3 = -player.global_transform.basis.z
	fwd.y = 0.0
	king.global_position = player.global_position + fwd.normalized() * 6.0 + Vector3(0, 1.5, 0)
	add_child(king)
	print("DEBUG: King Slime spawned at ", king.global_position)


func _debug_force_attack(attack: String) -> void:
	var bosses: Array = get_tree().get_nodes_in_group("enemies").filter(
		func(n: Node) -> bool: return n.get_script() != null and str(n.get_script().resource_path).ends_with("king_slime.gd")
	)
	if bosses.is_empty():
		print("DEBUG: no hay King Slime — presiona K primero")
		return
	var boss: Node = bosses[0]
	if not boss.has_method("_debug_perform"):
		print("DEBUG: boss no expone _debug_perform — agregar al script")
		return
	boss._debug_perform(attack)
	print("DEBUG: forzado ataque=", attack)
