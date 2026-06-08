extends Node3D

## Floor 1 — Pradera Interior
## Mundo abierto 600×600m con borde orgánico, techo de caverna,
## diamante de luz, vegetación procedural y spawn escalado.

@export var world_seed: int = 12345

# ── Proc-lab parameterization (defaults preserve the curated demo map EXACTLY) ──
# The alpha demo (floor1_prairie.tscn) is ONE curated deterministic map. With
# proc_bounds = (600, 600) and all active_layers true, every value below resolves
# to the historical constants and the map renders byte-identical to before.
# The dev harness (proc_lab) overrides these to iterate small cells fast.

## Bounds del mundo procedural en metros. Default (600, 600) = mapa demo.
## proc_lab usa celdas chicas (~120x120) para iterar rápido.
@export var proc_bounds: Vector2 = Vector2(600.0, 600.0)

## Capas activas. Permite generar solo lo que interesa al iterar.
## TODO true = pipeline completo (idéntico al demo).
@export var active_layers: Dictionary = {
	"ceiling": true,
	"crystals": true,
	"pillars": true,
	"border": true,
	"terrain": true,
	"pois": true,
	"vegetation": true,
	"grass": true,
	"player": true,
	"enemies": true,
	"hud": true,
}

## Multiplicador de densidad del tapiz de hierba. 1.0 = presupuesto nominal (≤120k blades a 600m).
## Reduce para iterar más rápido o en hardware débil.
## Default 1.0 = ~120k blades en el mapa completo (70m cull makes rendered count ~13k max).
@export var grass_density: float = 1.0

## Distancia de culling de la hierba en metros. Los MultiMeshInstance3D de hierba usan
## visibility_range_end = este valor con fade SELF para que desaparezcan suavemente.
@export var grass_cull_distance: float = 70.0

## Si true, omite el setup de UI compartida (pausa/inventario/etc).
## proc_lab lo desactiva: es un banco de pruebas visual, no una partida.
@export var skip_game_ui: bool = false

## ── Crystal glass material tweaks ────────────────────────────────────────────
## Alpha 0-1: 0 = invisible, 1 = opaque. ~0.65 = translucent gem look (Danmachi F18).
@export var crystal_alpha: float = 0.65
## Emission energy multiplier for crystal MultiMeshes. Lowered 2.0->0.8: at 2.0 the
## glow + env bloom blew the crystals to pure white and the per-color tint was lost.
@export var crystal_emission_energy: float = 0.8

# ── Map dimensions ────────────────────────────────────────────────────────────
# MAP_SIZE conservado como const de referencia histórica (600x600 base de calibración).
# El código vivo usa proc_bounds; con default == MAP_SIZE no hay cambio de comportamiento.
const MAP_SIZE: Vector2 = Vector2(600.0, 600.0)
const MAP_CENTER: Vector3 = Vector3.ZERO

## Factor de escala respecto al mapa demo de 600m. 1.0 en el demo, <1 en proc_lab.
## Escala las constantes geométricas absolutas (borde, vía de cristales, POIs) para
## que la celda chica de proc_lab no quede con el borde o los cristales fuera de cuadro.
func _proc_scale() -> float:
	return proc_bounds.x / MAP_SIZE.x

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
const CRYSTAL_LIGHT_ENERGY: float = 1.1      # subido (0.9→1.1) para que los charcos lean contra la oscuridad
const CRYSTAL_AMBIENT_ENERGY: float = 0.25   # legacy — ya no se usa (flood gigante eliminado; fill en WorldEnv)
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
const FLAT_RADIUS_BASE: float = 50.0     # spawn-bowl flatten radius (pre-scale) — single source

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

# ── Cavern key light (direccional cálido con sombras — el "sol filtrado") ──
# Warm-WHITE, no ámbar: el ámbar saturado tiñe todo de amarillo-desierto.
@export var key_light_energy: float = 1.3
@export var key_light_pitch: float = -52.0
@export var key_light_yaw: float = -35.0
@export var key_light_color: Color = Color(1.0, 0.93, 0.78)

# ── Monarcas: spotlight con sombra dinámica (solo los 3 cristales grandes) ───────
@export var monarch_shadows: bool = false      # true = sombra dinámica (perf red-line; off by default)
@export var monarch_light_energy: float = 1.5
@export var monarch_spot_angle: float = 52.0

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
## Dedicated noise for terrain color variation — decoupled from _terrain_noise so
## color patch frequencies are independent of _scale and always match the documented
## sizes: ~40m large patches (sample * 0.025) and ~8m fine grain (sample * 0.125).
var _color_noise: FastNoiseLite
## Dedicated noise for dirt/rock outcrops (Feature Round-A #2).
## Frequency 0.05 is scale-independent (sampled in world coords, not divided by _scale).
## Cells where this > OUTCROP_THRESHOLD AND dist_center > flat_radius get a height bump.
var _outcrop_noise: FastNoiseLite
## Dedicated low-frequency noise for broad terrain swells (Feature Round-A #3).
## Frequency 0.0015 — one full wave ≈ 667 m, so at 600m we get gentle rolls (not flat disc).
var _swell_noise: FastNoiseLite
var _terrain_heights: PackedFloat32Array
var _terrain_stride: int = 0  # TERRAIN_RESOLUTION + 1

# Scaled geometry (resueltos en generate() a partir de proc_bounds).
# En el demo (scale 1.0) coinciden con las constantes históricas.
var _scale: float = 1.0
var _border_radius_base: float = BORDER_RADIUS_BASE

# Snapshot de hijos pre-generación: lo que NO está acá se considera generado
# y se libera en regenerate() para un reseed limpio.
var _baseline_children: Array[Node] = []

## Round-A #1: Material memo cache for _make_cave_material.
## Keyed by Color so repeated calls with the same color share one StandardMaterial3D
## (and therefore one NoiseTexture2D pair) instead of allocating a new one per CSG node.
## Reset in regenerate() to avoid holding stale materials across reseeds.
var _cave_mat_cache: Dictionary = {}

## Cavern key light — UN DirectionalLight CÁLIDO con sombras: el "sol filtrado"
## dorado del golden-hour ACOGEDOR (DanMachi F18). Da forma/profundidad y aporta la
## mitad cálida del contraste warm-key/cool-shadow. Perf: shadow-caster principal.
func _build_key_light() -> void:
	var key := DirectionalLight3D.new()
	key.name = "CavernKeyLight"
	key.rotation_degrees = Vector3(key_light_pitch, key_light_yaw, 0.0)
	key.light_color = key_light_color
	key.light_energy = key_light_energy
	key.shadow_enabled = true
	key.shadow_bias = 0.04
	add_child(key)


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

	# Snapshot de los hijos declarados en el .tscn (techo de cristal, fauna ambiental,
	# vegetación curada, props). Todo lo que generate() agregue queda FUERA de este set
	# y por tanto se puede liberar limpio en regenerate() sin tocar la escena base.
	_baseline_children = get_children()

	# Seed del mundo elegido en el world select (modelo Valheim). Si no hay mundo
	# activo (world_seed < 0), se conserva el world_seed por defecto del .tscn.
	if GameManager.world_seed >= 0:
		world_seed = GameManager.world_seed

	generate()


## Pipeline de generación completo. Idempotente: regenerate() lo re-invoca tras limpiar.
## Cada fase está protegida por active_layers para que proc_lab itere subconjuntos.
func generate() -> void:
	_rng.seed = world_seed
	_scale = _proc_scale()
	_border_radius_base = BORDER_RADIUS_BASE * _scale
	_precalculate_border()
	_setup_terrain_noise()
	_build_key_light()

	# 1. Atmósfera
	if active_layers.get("ceiling", true):
		_build_ceiling()
	if active_layers.get("crystals", true):
		_build_crystal_field()
	if active_layers.get("pillars", true):
		_build_landmark_pillars()

	# 2. Borde orgánico
	if active_layers.get("border", true):
		_build_organic_border()

	# 2.5. Terreno con relieve — siempre se genera (todo lo demás lee su altura).
	if active_layers.get("terrain", true):
		_generate_terrain_mesh()
		_hide_flat_ground()

	# 3. POIs — ajustar al terreno antes de construir
	var pois: Array = []
	if active_layers.get("pois", true):
		var poi_system: POISystem = POISystem.new()
		pois = poi_system.generate_pois(world_seed, proc_bounds, _is_inside_border)
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
	if active_layers.get("vegetation", true):
		_generate_vegetation(pois)

	# 4.5. Tapiz de hierba densa — MultiMeshInstance3D chunkeado (S3 perf red-line #3)
	if active_layers.get("grass", true):
		_build_grass_carpet()

	# 4.6. Ground detail scatter — sparse pebbles + small rocks + clover clumps.
	# No colliders, low count, RNG-wrapped so enemy placement stays deterministic.
	if active_layers.get("vegetation", true):
		_scatter_ground_detail(pois)

	# 5. Jugador — ajustar a la altura del terreno
	var entrance_pos: Vector3 = _find_entrance_pos(pois)
	# Defensive: a procedural entrance can land out of bounds (or terrain may be
	# absent), which spawns the player into the void. Never trust it blindly — fall
	# back to the always-safe, flattened map center so a new world is always playable.
	if _terrain_heights.is_empty() or not _is_inside_border(entrance_pos):
		entrance_pos = MAP_CENTER
	entrance_pos.y = get_terrain_height(entrance_pos.x, entrance_pos.z)
	if active_layers.get("player", true):
		var player: CharacterBody3D = SCENE_PLAYER.instantiate() as CharacterBody3D
		add_child(player)
		player.global_position = entrance_pos + Vector3(0, 2.0, 0)

		# 7. HUD — depende del player
		if active_layers.get("hud", true):
			var hud: CanvasLayer = SCENE_HUD.instantiate() as CanvasLayer
			add_child(hud)
			if hud.has_method("connect_to_player"):
				hud.connect_to_player(player)

	# 6. Enemigos
	if active_layers.get("enemies", true):
		_spawn_poi_enemies(pois)
		_spawn_field_enemies(pois, entrance_pos)

	# 6.5. Ajustar todos los enemigos y vegetación al terreno
	_snap_all_to_terrain()

	# 8 + 9. UI compartida — starter items + pausa/inventario/diario.
	# proc_lab la omite: es banco de pruebas visual, no una partida.
	if not skip_game_ui:
		GameUISetup.grant_starter_items(GameManager.selected_class_scene)
		# Va DESPUÉS del player y starter items porque inventory_ui usa GameManager.player_inventory
		GameUISetup.setup_ui(self)


## Limpia los nodos generados (todo lo que no estaba en el .tscn) y regenera con
## una nueva semilla. Usado por proc_lab (hotkey R) para ver variaciones en segundos.
func regenerate(new_seed: int = -1) -> void:
	if new_seed >= 0:
		world_seed = new_seed
	# Liberar SOLO los hijos generados; preservar los declarados en el .tscn.
	for child in get_children():
		if child in _baseline_children:
			continue
		child.queue_free()
	# Reset de acumuladores de cristales (se rellenan de cero en cada generate).
	_crystal_warm_transforms.clear()
	_crystal_cool_transforms.clear()
	_crystal_rose_transforms.clear()
	# Reset tree positions (refilled during _generate_vegetation for understory fungi).
	_tree_positions.clear()
	# Reset cave material cache — new generation allocates fresh materials.
	_cave_mat_cache.clear()
	# queue_free es diferido: esperar un frame para que el árbol quede limpio
	# antes de re-poblar (evita nombres duplicados y dobles colisiones).
	await get_tree().process_frame
	generate()

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
		# La amplitud del ruido también escala con el mundo; en demo (_scale 1.0) idéntico.
		_border_noise_offsets.append(noise_val * BORDER_NOISE_AMP * _scale)

func _get_border_radius_at_angle(angle_deg: float) -> float:
	var idx: int = wrapi(int(angle_deg), 0, 360)
	var idx_next: int = wrapi(idx + 1, 0, 360)
	var frac: float = angle_deg - floor(angle_deg)
	var noise: float = lerp(_border_noise_offsets[idx], _border_noise_offsets[idx_next], frac)
	return _border_radius_base + noise

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
	# Frecuencia inversa a la escala: en una celda chica subimos la frecuencia para
	# que el relieve conserve detalle (si no, 80m de mapa quedan casi planos).
	# En el demo (_scale 1.0) == TERRAIN_NOISE_FREQ, idéntico.
	_terrain_noise.frequency = TERRAIN_NOISE_FREQ / maxf(_scale, 0.0001)
	_terrain_noise.fractal_octaves = TERRAIN_NOISE_OCTAVES
	_terrain_noise.fractal_lacunarity = 2.0
	_terrain_noise.fractal_gain = 0.5

	# Dedicated color noise — frequency=1.0 (neutral base); actual spatial frequencies
	# are applied at the call site via coordinate scaling (*0.025 = ~40m patches,
	# *0.125 = ~8m fine grain). This keeps color patches independent of _scale,
	# so proc_lab and the full 600m map produce the same documented patch sizes.
	_color_noise = FastNoiseLite.new()
	_color_noise.seed = world_seed + 11
	_color_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_color_noise.frequency = 1.0
	_color_noise.fractal_octaves = 2
	_color_noise.fractal_lacunarity = 2.0
	_color_noise.fractal_gain = 0.5

	# Round-A #2: Outcrop noise — sampled in raw world coords so frequency is always
	# 0.05 regardless of _scale. ~20m feature size. Two octaves for crinkled edges.
	_outcrop_noise = FastNoiseLite.new()
	_outcrop_noise.seed = world_seed + 37
	_outcrop_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_outcrop_noise.frequency = 0.05
	_outcrop_noise.fractal_octaves = 2
	_outcrop_noise.fractal_lacunarity = 2.0
	_outcrop_noise.fractal_gain = 0.5

	# Round-A #3: Swell noise — very low frequency for broad undulations.
	# 0.0015 = one full wave period ≈ 667m; at 600m we see roughly one roll across
	# the map so the terrain feels hilly instead of a flat disc.
	_swell_noise = FastNoiseLite.new()
	_swell_noise.seed = world_seed + 53
	_swell_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_swell_noise.frequency = 0.0015
	_swell_noise.fractal_octaves = 1
	_swell_noise.fractal_lacunarity = 2.0
	_swell_noise.fractal_gain = 0.5


## Calcula la altura en una coordenada world (x, z).
## Suma: noise base + broad swell + subida hacia bordes + flattening en el centro
## + dirt/rock outcrops (outside flat_radius only).
## SAFETY: flat_radius zone is NEVER touched by the new additive terms.
func _compute_height_at(x: float, z: float) -> float:
	# 1. Noise base — colinas suaves
	var n: float = _terrain_noise.get_noise_2d(x, z)  # -1..1
	n = (n + 1.0) * 0.5  # 0..1
	var h: float = n * TERRAIN_MAX_HEIGHT

	# 2. Distancia al centro (normalizada 0..1)
	var dist_center: float = sqrt(x * x + z * z)
	var max_r: float = _border_radius_base
	var t: float = clampf(dist_center / max_r, 0.0, 1.0)

	# 3. Flatten en el centro (radio 50m) para que la entrada sea plana
	var flat_radius: float = FLAT_RADIUS_BASE * _scale
	if dist_center < flat_radius:
		var flat_t: float = dist_center / flat_radius
		h = lerpf(0.0, h, smoothstep(0.0, 1.0, flat_t))

	# Round-A #3: Broad swell — low-frequency undulation summed AFTER the flatten guard.
	# Applied at ALL dist_center values but ATTENUATED to zero inside flat_radius via
	# the same smoothstep as the base noise above, so the spawn bowl stays flat.
	# Amplitude 3.5m → gentle rolling hills visible from the distance but no cliffs.
	# _swell_noise is sampled in raw world coords (scale-independent).
	if _swell_noise != null:
		var sw: float = _swell_noise.get_noise_2d(x, z)  # -1..1
		sw = (sw + 1.0) * 0.5  # 0..1
		var swell_h: float = sw * 3.5
		# Attenuate to zero inside flat_radius (same envelope as the base flatten).
		var swell_blend: float = 1.0
		if dist_center < flat_radius:
			swell_blend = smoothstep(0.0, 1.0, dist_center / flat_radius)
		h += swell_h * swell_blend

	# 4. Subida hacia los bordes (acantilados naturales)
	if t > 0.7:
		var edge_t: float = (t - 0.7) / 0.3
		h += TERRAIN_EDGE_RISE * edge_t * edge_t

	# Round-A #2: Dirt/rock outcrops — ONLY outside the flat_radius spawn bowl.
	# _outcrop_noise is scale-independent (sampled in world coords, freq=0.05).
	# Where noise > OUTCROP_THRESHOLD we add a smooth bump capped at OUTCROP_MAX_ADD
	# so the steepest slope stays climbable for CharacterBody3D (~1.5m over ~6m).
	const OUTCROP_THRESHOLD: float = 0.7    # top ~15% of noise values trigger an outcrop
	const OUTCROP_MAX_ADD: float   = 2.5    # max added metres; ~1.5m/6m slope ≈ 14° — climbable
	if _outcrop_noise != null and dist_center > flat_radius:
		var on: float = _outcrop_noise.get_noise_2d(x, z)  # -1..1
		on = (on + 1.0) * 0.5  # 0..1
		if on > OUTCROP_THRESHOLD:
			# Smooth ramp from threshold to 1.0 → clean bump edges, no hard ledges.
			var ramp: float = (on - OUTCROP_THRESHOLD) / (1.0 - OUTCROP_THRESHOLD)
			ramp = smoothstep(0.0, 1.0, ramp)
			h += ramp * OUTCROP_MAX_ADD

	return h


func _precompute_terrain_heights() -> void:
	_terrain_stride = TERRAIN_RESOLUTION + 1
	_terrain_heights = PackedFloat32Array()
	_terrain_heights.resize(_terrain_stride * _terrain_stride)

	var step: float = proc_bounds.x / float(TERRAIN_RESOLUTION)
	var half: float = proc_bounds.x * 0.5
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
	var half: float = proc_bounds.x * 0.5
	var step: float = proc_bounds.x / float(TERRAIN_RESOLUTION)
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

	var step: float = proc_bounds.x / float(TERRAIN_RESOLUTION)
	var half: float = proc_bounds.x * 0.5

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

			# Color por altura + noise XZ variation (parches suelo/musgo/tiza)
			var c00: Color = _height_to_color_at(h00, x0, z0)
			var c10: Color = _height_to_color_at(h10, x1, z0)
			var c01: Color = _height_to_color_at(h01, x0, z1)
			var c11: Color = _height_to_color_at(h11, x1, z1)

			# World-scaled UVs — required for detail_albedo to sample correctly.
			# uv1_triplanar does NOT apply to the detail layer; explicit per-vertex
			# UVs are the only way Godot 4 drives detail_albedo on a SurfaceTool mesh.
			const UV_SCALE: float = 0.22
			var uv00 := Vector2(x0, z0) * UV_SCALE
			var uv10 := Vector2(x1, z0) * UV_SCALE
			var uv01 := Vector2(x0, z1) * UV_SCALE
			var uv11 := Vector2(x1, z1) * UV_SCALE

			# Triángulo 1: v00 - v10 - v11
			st.set_color(c00); st.set_uv(uv00); st.add_vertex(v00)
			st.set_color(c10); st.set_uv(uv10); st.add_vertex(v10)
			st.set_color(c11); st.set_uv(uv11); st.add_vertex(v11)
			# Triángulo 2: v00 - v11 - v01
			st.set_color(c00); st.set_uv(uv00); st.add_vertex(v00)
			st.set_color(c11); st.set_uv(uv11); st.add_vertex(v11)
			st.set_color(c01); st.set_uv(uv01); st.add_vertex(v01)

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()

	# Material: vertex colors + procedural detail texture for surface micro-relief.
	# Mirrors _make_cave_material() pattern: NoiseTexture2D detail_albedo MUL +
	# triplanar world mapping. Fine frequency (0.35) = ~3m texture tiles = visible
	# ground grain up close without competing with vertex color patches at distance.
	# vertex_color_use_as_albedo stays ON — the detail layer multiplies on top.
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.92
	mat.metallic = 0.0

	# ── Procedural detail noise (stand-in for a real ground atlas) ────────────
	var detail_noise := FastNoiseLite.new()
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	detail_noise.frequency = 0.35   # fine surface grain
	detail_noise.fractal_octaves = 2
	detail_noise.seed = world_seed + 7  # offset from terrain height noise

	# Color ramp biased high so MUL blend modulates subtly instead of darkening.
	# Range 0.78..1.0 means detail never drops albedo below 78% — grain reads as
	# surface texture, not a dark filter.
	var detail_ramp := Gradient.new()
	detail_ramp.set_color(0, Color(0.78, 0.78, 0.78))
	detail_ramp.set_color(1, Color(1.0, 1.0, 1.0))

	var detail_tex := NoiseTexture2D.new()
	detail_tex.noise = detail_noise
	detail_tex.width = 256
	detail_tex.height = 256
	detail_tex.seamless = true
	detail_tex.color_ramp = detail_ramp  # subtly modulate, not darken

	mat.detail_enabled = true
	mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	mat.detail_albedo = detail_tex

	# uv1_triplanar does NOT affect the detail layer — detail uses UV0 (set per vertex
	# above). Triplanar was removed here because it only applies to the base albedo
	# channel (which uses vertex colors, so scale is irrelevant there too).
	# UV0 world-scale is set in the vertex loop: uv_scale=0.22 → ~4.5m tile.

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
	# Verdes DESATURADOS (oliva/apagado) — descansan la vista y respetan el
	# principio Kimetsu del _art_canon: bioma desaturado para que las skills
	# (color saturado) resalten. Evita la fatiga/after-images del verde chillón.
	# Bajo: verde-oliva pradera — Medio: oliva claro — Alto: tierra/roca.
	var base_color: Color
	if t < 0.4:
		base_color = Color(0.22, 0.31, 0.17).lerp(Color(0.31, 0.39, 0.23), t / 0.4)
	elif t < 0.75:
		base_color = Color(0.31, 0.39, 0.23).lerp(Color(0.40, 0.41, 0.28), (t - 0.4) / 0.35)
	else:
		base_color = Color(0.40, 0.41, 0.28).lerp(Color(0.44, 0.40, 0.32), (t - 0.75) / 0.25)
	# Base height-only color; see _height_to_color_at() for the world-XZ noise-varied wrapper.
	return base_color


## Noise-varied terrain color. Call this instead of _height_to_color when you
## have the XZ world position available (i.e. from _generate_terrain_mesh).
## Blends the height-based color toward 3 nearby earthy tones:
##   dark_soil  — darker, slightly cooler (damp cavity soil)
##   mossy      — muted green-grey (lichen patches near walls)
##   pale_chalk — lighter warm beige (mineral surface breaks)
## Uses _color_noise (frequency=1.0, seed=world_seed+11) with coordinate scaling:
##   x * 0.025 → ~40m large patches  |  x * 0.125 → ~8m fine grain
## Decoupled from _terrain_noise so patch sizes are independent of _scale.
## All tones are desaturated to respect Kimetsu canon.
func _height_to_color_at(h: float, x: float, z: float) -> Color:
	var base: Color = _height_to_color(h)
	if _color_noise == null:
		return base

	# Large-scale patch noise (~40m patches at frequency=1.0 * coord scale 0.025).
	var n_large: float = _color_noise.get_noise_2d(x * 0.025, z * 0.025)
	n_large = (n_large + 1.0) * 0.5  # 0..1

	# Fine-grain noise (~8m speckling at frequency=1.0 * coord scale 0.125).
	var n_fine: float = _color_noise.get_noise_2d(x * 0.125 + 500.0, z * 0.125 + 500.0)
	n_fine = (n_fine + 1.0) * 0.5  # 0..1

	# Three earthy blend targets (all desaturated — Kimetsu canon)
	const DARK_SOIL: Color   = Color(0.17, 0.19, 0.13)   # damp dark humus
	const MOSSY_GREY: Color  = Color(0.27, 0.31, 0.22)   # lichen/moss patch
	const PALE_CHALK: Color  = Color(0.42, 0.40, 0.33)   # mineral/chalk break

	# Blend: large-patch drives soil vs. base; fine noise adds chalk highlights
	var patch_color: Color = base.lerp(DARK_SOIL, clampf((n_large - 0.55) * 2.2, 0.0, 0.38))
	patch_color = patch_color.lerp(MOSSY_GREY, clampf((0.35 - n_large) * 2.0, 0.0, 0.28))
	var result: Color = patch_color.lerp(PALE_CHALK, clampf((n_fine - 0.72) * 1.8, 0.0, 0.20))

	# Round-A #2: Outcrop color bias — raised cells get an extra chalk/rock shift.
	# Gated by flat_radius EXACTLY like the geometry bump in _compute_height_at, so the
	# chalk tint only appears where the terrain actually bumps — never on the flat spawn
	# bowl (also skips the redundant noise sample for in-bowl cells).
	const OUTCROP_THRESHOLD_C: float = 0.7
	if _outcrop_noise != null and sqrt(x * x + z * z) > FLAT_RADIUS_BASE * _scale:
		var on: float = _outcrop_noise.get_noise_2d(x, z)
		on = (on + 1.0) * 0.5
		if on > OUTCROP_THRESHOLD_C:
			var ramp: float = (on - OUTCROP_THRESHOLD_C) / (1.0 - OUTCROP_THRESHOLD_C)
			ramp = smoothstep(0.0, 1.0, ramp)
			# Blend toward chalk/mineral tone (desaturated, slightly warm)
			result = result.lerp(PALE_CHALK, ramp * 0.55)

	return result


func _hide_flat_ground() -> void:
	var old: Node = get_node_or_null("GroundFloor")
	if old:
		old.visible = false
		# Mantener la colisión del CSG como fallback en caso de huecos
		if old.has_method("set_use_collision"):
			old.call("set_use_collision", false)


# Tipos de fauna que vuelan: su offset vertical es intencional, NO se aplastan al suelo.
const AERIAL_ENEMY_SCRIPTS: Array[String] = ["bird.gd", "hawk.gd", "wasp.gd"]


## Clasifica una entidad de combate como aérea (vuela) según su script.
func _is_aerial_enemy(node: Node) -> bool:
	var scr: Script = node.get_script()
	if scr == null:
		return false
	var path: String = str(scr.resource_path)
	for aerial in AERIAL_ENEMY_SCRIPTS:
		if path.ends_with(aerial):
			return true
	return false


## Ajusta la Y de todos los enemigos al terreno y los etiqueta por intención.
## La ARITMÉTICA de snap se conserva idéntica al demo (offset > 2.5 = volador) para
## no mover ni un cm el mapa curado. ENCIMA se añade tagging semántico: fauna que
## vuela (bird/hawk/wasp, por script) → grupo "aerial"; el resto → "grounded".
## Ese tag es la señal que consulta GroundSnapUtility (no adivina por altura).
func _snap_all_to_terrain() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for node: Node in enemies:
		if not is_instance_valid(node):
			continue
		var body: CharacterBody3D = node as CharacterBody3D
		if body == null:
			continue
		var terrain_y: float = get_terrain_height(body.global_position.x, body.global_position.z)
		# Tagging por intención (no altera la posición).
		if _is_aerial_enemy(body):
			body.add_to_group("aerial")
		else:
			body.add_to_group("grounded")
		# Snap — aerials keep their spawn height; ground enemies land on terrain.
		# Branch on the aerial tag already set above (semantic, not heuristic height).
		if _is_aerial_enemy(body):
			# Preserve the absolute spawn offset set in _on_enemy_ready (e.g. fly_height).
			# The enemy's own _apply_gravity keeps it at that height at runtime.
			pass  # no ground snap for aerial enemies
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
		# FIX #5: cave stone material — roughness + triplanar noise instead of flat color
		wall.material_override = _make_cave_material(COLOR_BORDER)
		wall.position = mid + Vector3(0, BORDER_WALL_HEIGHT * 0.5, 0)
		wall.rotation.y = -seg_angle
		add_child(wall)

# ── Atmosphere ────────────────────────────────────────────────────────────────

func _build_ceiling() -> void:
	var ceiling: CSGBox3D = CSGBox3D.new()
	ceiling.name = "CavernCeiling"
	ceiling.size = Vector3(proc_bounds.x + 100, 2.0, proc_bounds.y + 100)
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
	# NOTE: el flood OmniLight gigante (omni_range=350, CRYSTAL_AMBIENT_ENERGY) fue ELIMINADO (2026-06-06).
	# Era el anti-patrón raíz del lighting plano/quemado. Fill global ahora viene del WorldEnvironment
	# ambient_light_energy (0.13 cool tint) — oscuridad domina, cristales son los héroes de luz.

	var crystal_colors: Array[Color] = [COLOR_CRYSTAL_WARM, COLOR_CRYSTAL_COOL, COLOR_CRYSTAL_ROSE]

	# ── 1. Cristales monarca — los "príncipes" del techo ──────────────────────
	var monarch_positions: Array[Vector3] = []
	for m in range(CRYSTAL_MONARCH_COUNT):
		var t: float = float(m + 1) / float(CRYSTAL_MONARCH_COUNT + 1)
		var mx: float = lerp(-160.0 * _scale, 160.0 * _scale, t) + _rng.randf_range(-30.0, 30.0) * _scale
		var mz: float = sin(t * PI * 1.6 + 0.3) * 110.0 * _scale + _rng.randf_range(-20.0, 20.0) * _scale
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

		# Luz del monarca — SPOTLIGHT hacia abajo (la luz BAJA del cristal del techo).
		# Sombra dinámica SOLO en los 3 monarcas: spot = 1 shadow map (barato vs el
		# cubemap de un omni). monarch_shadows=false la apaga para co-op pesado.
		var ml: SpotLight3D = SpotLight3D.new()
		ml.name = "MonarchLight%d" % m
		ml.light_color = Color(monarch_color.r, monarch_color.g * 0.95, monarch_color.b * 0.9)
		ml.light_energy = monarch_light_energy
		ml.spot_range = CEILING_HEIGHT + 25.0
		ml.spot_angle = monarch_spot_angle
		ml.spot_attenuation = 1.2
		ml.shadow_enabled = monarch_shadows
		ml.shadow_bias = 0.05
		ml.position = Vector3(mx, CEILING_HEIGHT - 8.0, mz)
		ml.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		add_child(ml)

		# (sin luz up secundaria — el techo ya tiene emisión propia)

	# ── 2. Clusters regulares — variedad de tamaños ──────────────────────────
	for i in range(CRYSTAL_PATH_CLUSTERS):
		var t: float = float(i) / float(CRYSTAL_PATH_CLUSTERS - 1)

		var path_x: float = lerp(-200.0 * _scale, 200.0 * _scale, t)
		var path_z: float = sin(t * PI * 1.6 + 0.3) * 130.0 * _scale
		path_x += _rng.randf_range(-25.0, 25.0) * _scale
		path_z += _rng.randf_range(-CRYSTAL_SCATTER_WIDTH * 0.5, CRYSTAL_SCATTER_WIDTH * 0.5) * _scale

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

	# ── 4. Bioluminiscencia del techo — DISABLED ────────────────────────────
	# Rendered as flat parallelograms floating 1.5-4m BELOW the ceiling, reading as
	# "random floating tiles" rather than glow on the roof. Removed per art direction;
	# ceiling interest comes from the crystal shards. Re-enable FLUSH to the ceiling
	# (drop_h = 0) if a proper glowing-roof effect is wanted later.
	# _build_ceiling_bioluminescence()

func _build_ceiling_bioluminescence() -> void:
	var biolum_transforms: Array[Transform3D] = []

	for i in range(CEILING_BIOLUM_PATCHES):
		var angle: float = _rng.randf() * TAU
		var dist: float = _rng.randf_range(10.0 * _scale, _border_radius_base - 40.0 * _scale)
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

# World-space base positions of every placed tree trunk — filled by _place_instance
# ("trunk") and consumed by _scatter_understory_mushrooms() to grow fungi in shade.
var _tree_positions: Array[Vector3] = []

# Acumuladores de cristales — se flushean con _flush_crystal_multimeshes()
var _crystal_warm_transforms: Array[Transform3D] = []
var _crystal_cool_transforms: Array[Transform3D] = []
var _crystal_rose_transforms: Array[Transform3D] = []

# Real faceted crystal model (TRELLIS-generated). When importable, the crystal
# MultiMeshes instance THIS mesh (tinted + glowing via material_override) instead
# of a plain box. Falls back to the box if Godot hasn't imported the .glb yet.
const SCENE_CRYSTAL_GLB: String = "res://assets/art/piso1_pradera/crystals/crystal_amethyst_01.glb"
## Uniform size multiplier for the GLB crystals (they were too small for the light
## they cast). Tunable from the inspector.
@export var crystal_glb_size_mult: float = 2.0
var _crystal_mesh_cache: Mesh = null
var _crystal_mesh_norm: float = 1.0     # 1 / max AABB extent → treats the model as ~unit
var _crystal_mesh_tried: bool = false

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
	# emission_energy arg is ignored when gem_mode=true (uses crystal_emission_energy export).
	_create_multimesh_emissive("CrystalsWarm", _crystal_warm_transforms,
		COLOR_CRYSTAL_WARM, 1.2, true)
	_create_multimesh_emissive("CrystalsCool", _crystal_cool_transforms,
		COLOR_CRYSTAL_COOL, 1.2, true)
	_create_multimesh_emissive("CrystalsRose", _crystal_rose_transforms,
		COLOR_CRYSTAL_ROSE, 1.2, true)


## gem_mode=true: aplica material vidrio/gema translucente + emisivo (cristales).
## gem_mode=false (default): opaco con emisión (biolum patches, etc).
func _create_multimesh_emissive(mm_name: String, transforms: Array[Transform3D],
		color: Color, emission_energy: float, gem_mode: bool = false) -> void:
	if transforms.is_empty():
		return

	var mat := StandardMaterial3D.new()
	if gem_mode:
		# Translucent gem / crystal glass — Danmachi Floor 18 style.
		# TRANSPARENCY_ALPHA enables alpha blending; alpha ~0.65 = see-through but
		# clearly present. CULL_DISABLED shows back faces through the front face,
		# giving the "solid glass block" look. Low roughness = glassy specular.
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(color.r, color.g, color.b, crystal_alpha)
		mat.roughness = 0.12
		mat.metallic = 0.05
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission = Color(color.r * 0.95, color.g * 0.9, color.b * 0.85)
		mat.emission_energy_multiplier = crystal_emission_energy
	else:
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = Color(color.r * 0.95, color.g * 0.9, color.b * 0.85)
		mat.emission_energy_multiplier = emission_energy

	# Use the real faceted crystal model when gem_mode AND the .glb is imported;
	# otherwise fall back to a unit box (also covers the opaque biolum patches).
	var crystal_mesh: Mesh = _get_crystal_mesh() if gem_mode else null
	var use_glb: bool = crystal_mesh != null
	var mesh: Mesh
	if use_glb:
		mesh = crystal_mesh        # shared GLB resource — tint/glow via MMI material_override
	else:
		var box := BoxMesh.new()
		box.size = Vector3.ONE
		box.material = mat
		mesh = box

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()

	for i in range(transforms.size()):
		var t: Transform3D = transforms[i]
		if use_glb:
			# The model is a CLUSTER — apply a UNIFORM scale (no per-axis stretch),
			# sized from the shard's original scale, normalized to the model AABB and
			# bumped by crystal_glb_size_mult so crystals are big enough for their light.
			var sc: Vector3 = t.basis.get_scale()
			var uniform: float = ((sc.x + sc.y + sc.z) / 3.0) * _crystal_mesh_norm * crystal_glb_size_mult
			t = Transform3D(t.basis.orthonormalized().scaled(Vector3(uniform, uniform, uniform)), t.origin)
		mm.set_instance_transform(i, t)

	var mmi := MultiMeshInstance3D.new()
	mmi.name = mm_name
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if use_glb:
		mmi.material_override = mat
	add_child(mmi)


## Lazily loads + caches the TRELLIS crystal model's mesh, normalized to ~unit via
## its AABB (so the existing per-shard scaling stays sane). Returns null if Godot
## hasn't imported the .glb yet → callers fall back to the box.
func _get_crystal_mesh() -> Mesh:
	if _crystal_mesh_tried:
		return _crystal_mesh_cache
	_crystal_mesh_tried = true
	if not ResourceLoader.exists(SCENE_CRYSTAL_GLB):
		return null
	var m: Mesh = _extract_mesh_from_gltf(SCENE_CRYSTAL_GLB)
	if m == null:
		return null
	var ab: AABB = m.get_aabb()
	var maxext: float = maxf(ab.size.x, maxf(ab.size.y, ab.size.z))
	if maxext > 0.0001:
		_crystal_mesh_norm = 1.0 / maxext
	_crystal_mesh_cache = m
	return m

func _build_landmark_pillars() -> void:
	for i in range(PILLAR_COUNT):
		var angle: float = (float(i) / float(PILLAR_COUNT)) * TAU + _rng.randf_range(-0.2, 0.2)
		var dist: float = _rng.randf_range(100.0 * _scale, 200.0 * _scale)
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
		# Round-A #1: landmark pillars use cave material (worked stone, not flat color)
		pillar.material_override = _make_cave_material(COLOR_PILLAR)
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
		# Round-A #1: entrance stones use cave material (worked stone blocks)
		_add_cave_csg_box("EntranceStone%s" % ("N" if side < 0 else "S"),
			pos + Vector3(0, 0.6, side * sz.y * 0.5),
			Vector3(sz.x * 0.8, 1.2, 0.8), COLOR_ROCK, true)

	for side in [-1.0, 1.0]:
		var pillar: CSGCylinder3D = CSGCylinder3D.new()
		pillar.name = "EntrancePillar%s" % ("L" if side < 0 else "R")
		pillar.radius = 0.5
		pillar.height = 4.0
		pillar.sides = 8
		pillar.use_collision = true
		# Round-A #1: entrance pillars use cave material (worked stone)
		pillar.material_override = _make_cave_material(COLOR_ROCK)
		pillar.position = pos + Vector3(sz.x * 0.4 * side, 2.0, -sz.y * 0.5)
		add_child(pillar)

func _build_ruins(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position
	var sz: Vector2 = poi.size

	# Ground slab — thin, stays flat color (it's a floor, not a wall)
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
		# FIX #5: ruins walls → cave stone material
		_add_cave_csg_box("RuinWall%d" % i, pos + Vector3(ox, wh * 0.5, oz),
			Vector3(ww, wh, wd), COLOR_RUIN, true)

	var well: CSGCylinder3D = CSGCylinder3D.new()
	well.name = "RuinsWell"
	well.radius = 1.2
	well.height = 1.2
	well.use_collision = true
	# FIX #5: well → cave stone material
	well.material_override = _make_cave_material(COLOR_ROCK)
	well.position = pos + Vector3(0, 0.6, 0)
	add_child(well)

	for i in range(4):
		var rx: float = _rng.randf_range(-sz.x * 0.3, sz.x * 0.3)
		var rz: float = _rng.randf_range(-sz.y * 0.3, sz.y * 0.3)
		var rs: float = _rng.randf_range(0.8, 1.8)
		# FIX #5: ruins rock rubble → cave stone material
		_add_cave_csg_box("RuinsRock%d" % i,
			pos + Vector3(rx, rs * 0.5, rz),
			Vector3(rs * 1.2, rs, rs), COLOR_ROCK_DARK, true)

func _build_boss_arena(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position
	var sz: Vector2 = poi.size
	var hw: float = sz.x * 0.5
	var hd: float = sz.y * 0.5
	var wall_h: float = 6.0
	var wall_t: float = 1.2

	# Ground slab — flat color OK (it's a floor surface)
	_add_csg_box("BossGround", pos + Vector3(0, 0.02, 0),
		Vector3(sz.x, 0.04, sz.y), COLOR_BOSS_WALL, false)

	# FIX #5: boss arena walls → cave stone material (not blockout flat gray)
	_add_cave_csg_box("BossWallN", pos + Vector3(0, wall_h * 0.5, -hd),
		Vector3(sz.x, wall_h, wall_t), COLOR_BOSS_WALL, true)
	_add_cave_csg_box("BossWallS", pos + Vector3(0, wall_h * 0.5, hd),
		Vector3(sz.x, wall_h, wall_t), COLOR_BOSS_WALL, true)
	_add_cave_csg_box("BossWallE", pos + Vector3(hw, wall_h * 0.5, 0),
		Vector3(wall_t, wall_h, sz.y), COLOR_BOSS_WALL, true)

	var gate_w: float = 12.0
	var side_len: float = (sz.y - gate_w) * 0.5
	_add_cave_csg_box("BossWallW_N",
		pos + Vector3(-hw, wall_h * 0.5, -(gate_w * 0.5 + side_len * 0.5)),
		Vector3(wall_t, wall_h, side_len), COLOR_BOSS_WALL, true)
	_add_cave_csg_box("BossWallW_S",
		pos + Vector3(-hw, wall_h * 0.5, gate_w * 0.5 + side_len * 0.5),
		Vector3(wall_t, wall_h, side_len), COLOR_BOSS_WALL, true)
	_add_cave_csg_box("BossWallW_Top",
		pos + Vector3(-hw, wall_h - 0.75, 0),
		Vector3(wall_t, 1.5, gate_w), COLOR_BOSS_WALL, true)

	for i in range(5):
		var rx: float = _rng.randf_range(-hw * 0.6, hw * 0.6)
		var rz: float = _rng.randf_range(-hd * 0.6, hd * 0.6)
		# FIX #5: rubble in boss arena → cave stone material
		_add_cave_csg_box("BossRubble%d" % i,
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
		# body_entered corre en flush de física: diferir add_child + posición juntos
		# evita "flushing queries" y el is_inside_tree del global_position pre-árbol.
		_spawn_king_deferred.call_deferred(king, spawn_center)
		trigger.set_deferred("monitoring", false)
	)

func _spawn_king_deferred(king: Node3D, pos: Vector3) -> void:
	if not is_instance_valid(king):
		return
	add_child(king)
	king.global_position = pos


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
	# Round-A #1: altar base uses cave material (worked stone platform)
	base.material_override = _make_cave_material(COLOR_ALTAR)
	base.position = pos + Vector3(0, 0.2, 0)
	add_child(base)

	# Round-A #1: altar stone and pillars use cave material
	_add_cave_csg_box("AltarStone", pos + Vector3(0, 0.9, 0),
		Vector3(1.5, 1.4, 1.5), COLOR_ALTAR, true)

	for i in range(4):
		var angle: float = float(i) * TAU / 4.0
		_add_cave_csg_box("AltarPillar%d" % i,
			pos + Vector3(cos(angle) * 2.2, 0.6, sin(angle) * 2.2),
			Vector3(0.5, 1.2, 0.5), COLOR_ROCK, true)

func _build_well(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position

	var well: CSGCylinder3D = CSGCylinder3D.new()
	well.name = "WellStruct"
	well.radius = 1.0
	well.height = 1.0
	well.use_collision = true
	# Round-A #1: well structure uses cave material (rough stone ring)
	well.material_override = _make_cave_material(COLOR_ROCK)
	well.position = pos + Vector3(0, 0.5, 0)
	add_child(well)

	var water: CSGCylinder3D = CSGCylinder3D.new()
	water.name = "WellWater"
	water.radius = 0.8
	water.height = 0.05
	water.use_collision = false
	var water_mat: ShaderMaterial = ShaderMaterial.new()
	water_mat.shader = load("res://scenes/levels/water_toon.gdshader")
	water_mat.set_shader_parameter("water_color", COLOR_WATER)
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
	var water_mat: ShaderMaterial = ShaderMaterial.new()
	water_mat.shader = load("res://scenes/levels/water_toon.gdshader")
	water_mat.set_shader_parameter("water_color", COLOR_WATER)
	water.material_override = water_mat
	water.position = pos + Vector3(0, -0.05, 0)
	add_child(water)

	for i in range(8):
		var angle: float = float(i) * TAU / 8.0
		var br: float = sz.x * 0.4 + 0.5
		# Round-A #1: pond border rocks use cave material (natural stone, not flat gray)
		_add_cave_csg_box("PondRock%d" % i,
			pos + Vector3(cos(angle) * br, 0.25, sin(angle) * br),
			Vector3(_rng.randf_range(0.6, 1.2), 0.5, _rng.randf_range(0.6, 1.2)),
			COLOR_ROCK, true)

# ── Vegetation (gltf scatter — assets reales CC0) ────────────────────────────
# Pools de assets reales para scatter procedural. Reemplaza el viejo BoxMesh
# placeholder: el mapa entero se puebla con los gltf integrados, no cajas planas.

## FIX #4 (MEDIUM) — Birch is shade-intolerant (pioneer species); reduced from 5 slots
## to 2. Dead tree removed from pool (now via _scatter_dead_trees() for FIX #2).
## 4 freed slots → maple (understory-tolerant). Pool size stays 12:
##   Before: 5 birch / 3 maple / 3 common / 1 dead = 12
##   After:  2 birch / 7 maple / 3 common / 0 dead = 12
## See _coherence_target_sheet.md §BREAK #4.
const POOL_TREES: Array[PackedScene] = [
	# 2 birch (down from 5) — sparse, near crystal-spotlight zones by chance
	preload("res://assets/art/piso1_pradera/vegetation/birch/env_tree_birch_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/birch/env_tree_birch_02.gltf"),
	# 7 maple (up from 3) — best-fit understory tree for dim cavern
	preload("res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_02.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_03.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_02.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_03.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_01.gltf"),
	# 3 common broadleaf (unchanged)
	preload("res://assets/art/piso1_pradera/vegetation/common/env_tree_common_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/common/env_tree_common_02.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/common/env_tree_common_03.gltf"),
]

## Dead tree scene — managed separately so laetiporus can attach at spawn time.
## FIX #2: placed via _scatter_dead_trees(), not in POOL_TREES.
const SCENE_DEAD_TREE: PackedScene = preload("res://assets/art/piso1_pradera/vegetation/dead/env_tree_dead_01.gltf")

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
## FIX #1 (CRITICAL) — flower_clump_01/02/03 removed from general scatter.
## Full-sun wildflowers are incoherent in a dim cavern. Their weight replaced with
## extra mushroom_common slots so density stays equivalent.
## See _coherence_target_sheet.md §BREAK #1.
##
## FIX #2 (HIGH) — mushroom_laetiporus_01 removed from ground scatter.
## Laetiporus is a bracket fungus that grows FROM dead wood, not bare soil.
## It is now spawned at the base of dead-tree instances in _generate_vegetation().
## See _coherence_target_sheet.md §BREAK #2.
## SHADE FIX — mushrooms removed from this open-field pool. Fungi need shade, not
## full open ground, so they are now placed at tree bases by _scatter_understory_
## mushrooms() instead of scattered uniformly. POOL_GROUND is low ground cover only.
const POOL_GROUND: Array[PackedScene] = [
	preload("res://assets/art/piso1_pradera/vegetation/clover/env_clover_01.gltf"),
]

## The laetiporus scene — spawned at base of dead trees only (see _generate_vegetation).
const SCENE_LAETIPORUS: PackedScene = preload("res://assets/art/piso1_pradera/vegetation/mushroom/env_mushroom_laetiporus_01.gltf")

## Common mushroom — spawned in the SHADE at the base of trees (see
## _scatter_understory_mushrooms), never in open field.
const SCENE_MUSHROOM_COMMON: PackedScene = preload("res://assets/art/piso1_pradera/vegetation/mushroom/env_mushroom_common_01.gltf")

## ── Ground detail scatter (S4) ───────────────────────────────────────────────
## Sparse pebble + small-rock + clover-clump pass. No colliders. Low count.
## Gives the eye micro-landmarks on the ground surface so it doesn't read as empty.
## Wrapped in _rng.state save/restore — MUST NOT shift the enemy-placement sequence.
func _scatter_ground_detail(pois: Array) -> void:
	var container := Node3D.new()
	container.name = "GroundDetail"
	add_child(container)

	# Save RNG state so this pass is invisible to subsequent passes (enemies, etc.)
	var rng_state: int = _rng.state

	# Pool: pebble_round + rock_small alternating. Clover separately below.
	const DETAIL_POOL: Array[String] = [
		"res://assets/art/piso1_pradera/terrain/pebbles/env_pebble_round_01.gltf",
		"res://assets/art/piso1_pradera/props/rocks/prop_rock_small_01.glb",
	]
	var detail_scenes: Array[PackedScene] = []
	for path in DETAIL_POOL:
		if ResourceLoader.exists(path):
			detail_scenes.append(load(path))

	# Clover clump scene
	var clover_scene: PackedScene = null
	const CLOVER_PATH: String = "res://assets/art/piso1_pradera/vegetation/clover/env_clover_01.gltf"
	if ResourceLoader.exists(CLOVER_PATH):
		clover_scene = load(CLOVER_PATH)

	# Count scales with map area; at demo scale (1.0) → 180 pebbles + 60 clover clumps.
	var pebble_count: int = int(180.0 * _scale * _scale)
	var clover_count: int = int(60.0 * _scale * _scale)

	# ── Pebbles / small rocks ────────────────────────────────────────────────
	if not detail_scenes.is_empty():
		for _i in range(pebble_count):
			var pos: Vector3 = _random_open_pos(pois, 4.0)   # small clearance — tiny props
			if pos == Vector3.INF:
				continue
			pos.y = get_terrain_height(pos.x, pos.z)
			var scene: PackedScene = detail_scenes[_rng.randi() % detail_scenes.size()]
			var inst: Node3D = scene.instantiate() as Node3D
			if inst == null:
				continue
			var s: float = _rng.randf_range(0.25, 0.7)   # small scale — ground-level clutter
			var rot_y: float = _rng.randf() * TAU
			inst.transform = Transform3D(Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s)), pos)
			# gltf root is Node3D; set shadow/visibility on MeshInstance3D children
			_detail_apply_geo_flags(inst, 45.0)
			container.add_child(inst)

	# ── Clover clumps ────────────────────────────────────────────────────────
	if clover_scene != null:
		for _i in range(clover_count):
			var pos: Vector3 = _random_open_pos(pois, 5.0)
			if pos == Vector3.INF:
				continue
			pos.y = get_terrain_height(pos.x, pos.z)
			var inst: Node3D = clover_scene.instantiate() as Node3D
			if inst == null:
				continue
			var s: float = _rng.randf_range(0.5, 1.1)
			var rot_y: float = _rng.randf() * TAU
			inst.transform = Transform3D(Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s)), pos)
			_detail_apply_geo_flags(inst, 35.0)
			container.add_child(inst)

	# Restore RNG — enemy placement sequence unchanged
	_rng.state = rng_state
	print("[GroundDetail] pebbles+rocks budget=%d clover=%d placed=%d" % [pebble_count, clover_count, container.get_child_count()])


## Applies SHADOW_CASTING_SETTING_OFF + visibility_range_end to all MeshInstance3D
## descendants of a gltf root node. gltf roots are plain Node3D wrappers; the actual
## geometry lives one or more levels deeper as MeshInstance3D.
func _detail_apply_geo_flags(root: Node3D, vis_range_end: float) -> void:
	# Apply flags to the node itself if it is a MeshInstance3D.
	var mi: MeshInstance3D = root as MeshInstance3D
	if mi != null:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = vis_range_end
		# Fade margin prevents hard pop: 15% of the cull distance, minimum 5m.
		mi.visibility_range_end_margin = maxf(5.0, vis_range_end * 0.15)
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	# Always recurse into children regardless of whether root was a MeshInstance3D.
	# gltf roots are plain Node3D wrappers — geometry lives in child MeshInstance3Ds.
	for child in root.get_children():
		var child_node: Node3D = child as Node3D
		if child_node != null:
			_detail_apply_geo_flags(child_node, vis_range_end)


## ── Grass carpet (S3) ────────────────────────────────────────────────────────
## Dense ground-cover layer via chunked MultiMeshInstance3D.
## Perf contract (red-line §3): ≤13k visible blades, hard-cull grass_cull_distance,
## ≤40m chunk tiles, no per-blade Node3D, SHADOW_CASTING_SETTING_OFF.
##
## Mesh source: res://assets/art/piso1_pradera/vegetation/grass/env_grass_small_01.gltf
## (already imported as PackedScene). We instantiate it, find the MeshInstance3D child,
## and extract its Mesh resource so MultiMesh can use it.
## If extraction fails we fall back to a simple crossed-quad blade mesh.
##
## Density scales with map area (_scale²): at proc_bounds=(120,120) → _scale=0.2 →
## ~192 total blades vs ~12 000 at the full 600m map.
func _build_grass_carpet() -> void:
	# ── 1. Resolve meshes — mix several ground-cover gltf for variety ──────────
	var blade_meshes: Array[Mesh] = _extract_grass_meshes()
	if blade_meshes.is_empty():
		push_warning("[GrassCarpet] no gltf grass meshes loaded — using fallback blade mesh")
		blade_meshes = [_make_fallback_blade_mesh()]

	# ── 2. Shared material — wind-sway ShaderMaterial (desaturated olive, cavern) ──
	# Replaced StandardMaterial3D with a ShaderMaterial whose VERTEX stage sways
	# blades by TIME. Phase = world-position hash so blades move independently.
	# Base swings top vertices only (tip moves, base stays planted) by biasing
	# displacement by vertex Y in model space. Amplitude ~2-3cm — perceptible but
	# not distracting. Kimetsu canon: desaturated olive so skills still pop.
	var grass_mat := ShaderMaterial.new()
	var grass_shader := Shader.new()
	grass_shader.code = """
shader_type spatial;
// cull_disabled is INTENTIONAL: env_grass_small_01 is a crossed-tuft mesh that
// must be readable from both sides. cull_back would make tufts invisible from
// behind (half the viewing angles). The ~2× fragment cost is accepted and stays
// within the ≤13k-blade rendered red-line enforced by visibility_range_end.
render_mode cull_disabled, shadows_disabled;

uniform vec4 albedo : source_color = vec4(0.34, 0.38, 0.22, 1.0);
uniform float sway_amplitude : hint_range(0.0, 0.1) = 0.028;
uniform float sway_speed : hint_range(0.0, 5.0) = 1.4;
// blade_height: real measured height of env_grass_small_01 AABB (metres).
// Set at runtime after mesh extraction so height_bias is calibrated to actual geometry.
uniform float blade_height : hint_range(0.01, 2.0) = 0.6;

void vertex() {
	// World-space position of this vertex (model → world)
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Phase based on world XZ so each blade sways independently
	float phase = world_pos.x * 1.7 + world_pos.z * 2.3;
	// Bias: top of blade (high local Y) sways fully; base (Y≈0) stays planted.
	// blade_height driven from measured AABB so amplitude is correct for real geometry.
	float height_bias = clamp(VERTEX.y / blade_height, 0.0, 1.0);
	float sway = sin(TIME * sway_speed + phase) * sway_amplitude * height_bias;
	VERTEX.x += sway;
	VERTEX.z += sway * 0.4;
}

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 0.9;
	METALLIC = 0.0;
}
"""
	grass_mat.shader = grass_shader

	# Set blade_height from the first extracted mesh's AABB so the sway height_bias
	# is calibrated to the real geometry (env_grass_small_01 is ~0.39m, not 0.6m).
	# Falls back to 0.6 (the shader uniform default) if the mesh list is empty.
	if not blade_meshes.is_empty():
		var aabb_h: float = blade_meshes[0].get_aabb().size.y
		grass_mat.set_shader_parameter("blade_height", maxf(aabb_h, 0.01))

	# Billboard is not used (tufts look fine in 3D); shadows off for perf
	for bm in blade_meshes:
		for si in range(bm.get_surface_count()):
			bm.surface_set_material(si, grass_mat)

	# ── 3. Budget calculation ──────────────────────────────────────────────────
	# Max instances at full 600m map (scale=1.0). Scales quadratically with area.
	# 120 000 total at scale=1.0 is fine: visibility_range_end=70m culls to ~13k
	# rendered blades at any given moment (MultiMesh draws only visible instances).
	# At proc_lab scale=0.2 (120m cell): 120000 * 0.04 ≈ 4800 blades — dense but fast.
	const MAX_INSTANCES_BASE: int = 120000
	var total_budget: int = int(float(MAX_INSTANCES_BASE) * _scale * _scale * grass_density)
	total_budget = clampi(total_budget, 0, MAX_INSTANCES_BASE)
	if total_budget == 0:
		return

	# ── 4. Chunk grid ─────────────────────────────────────────────────────────
	# Each chunk = CHUNK_SIZE × CHUNK_SIZE metres. Keeps triangle count per draw
	# call low and allows per-chunk visibility_range culling.
	const CHUNK_SIZE: float = 40.0
	var half_x: float = proc_bounds.x * 0.5
	var half_z: float = proc_bounds.y * 0.5
	var chunks_x: int = ceili(proc_bounds.x / CHUNK_SIZE)
	var chunks_z: int = ceili(proc_bounds.y / CHUNK_SIZE)

	# Playable area ≈ circle; estimate fraction of each chunk that is inside border
	# to distribute budget proportionally. We sample the chunk center.
	var chunk_data: Array[Array] = []  # each entry: [world_x_min, world_z_min]
	for cx in range(chunks_x):
		for cz in range(chunks_z):
			var wx: float = -half_x + cx * CHUNK_SIZE
			var wz: float = -half_z + cz * CHUNK_SIZE
			var cx_center: Vector3 = Vector3(wx + CHUNK_SIZE * 0.5, 0.0, wz + CHUNK_SIZE * 0.5)
			# Only create MMI for chunks whose CENTER is inside the border.
			# Chunks on the edge will partially overlap but that's acceptable.
			if _is_inside_border(cx_center):
				chunk_data.append([wx, wz])

	if chunk_data.is_empty():
		return

	# Distribute budget evenly across valid chunks
	var instances_per_chunk: int = maxi(1, total_budget / chunk_data.size())

	# ── 5. Build one MultiMeshInstance3D per chunk ────────────────────────────
	var container := Node3D.new()
	container.name = "GrassCarpet"
	add_child(container)

	# Save RNG state so grass does not disturb the deterministic sequence of
	# later passes (enemies, etc.) — we restore it after.
	var rng_state: int = _rng.state

	for chunk_entry in chunk_data:
		var wx_min: float = chunk_entry[0]
		var wz_min: float = chunk_entry[1]

		# One transform bucket per mesh variant — each instance is randomly assigned
		# a variant so every chunk mixes all grass types (one MMI per variant below).
		var buckets: Array = []
		for _m in blade_meshes:
			buckets.append([])

		for _i in range(instances_per_chunk):
			var x: float = _rng.randf_range(wx_min, wx_min + CHUNK_SIZE)
			var z: float = _rng.randf_range(wz_min, wz_min + CHUNK_SIZE)
			var sample: Vector3 = Vector3(x, 0.0, z)
			if not _is_inside_border(sample):
				continue
			var y: float = get_terrain_height(x, z)
			# Random Y rotation + slight scale variation (0.8–1.2)
			var rot_y: float = _rng.randf() * TAU
			# Slight forward tilt (−10°..+10°) for organic look
			var tilt: float = _rng.randf_range(-0.17, 0.17)  # ~±10°
			var basis: Basis = Basis.from_euler(Vector3(tilt, rot_y, 0.0))
			var s: float = _rng.randf_range(0.8, 1.2)
			basis = basis.scaled(Vector3(s, s, s))
			var variant: int = _rng.randi() % blade_meshes.size()
			buckets[variant].append(Transform3D(basis, Vector3(x, y, z)))

		# Emit one MultiMeshInstance3D per non-empty variant bucket. Total instance
		# count across buckets == instances_per_chunk, so the perf budget is unchanged;
		# only the draw-call count grows (× variant count), still within the red-line.
		for variant in range(blade_meshes.size()):
			var transforms: Array = buckets[variant]
			if transforms.is_empty():
				continue

			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = blade_meshes[variant]
			mm.instance_count = transforms.size()
			for i in range(transforms.size()):
				mm.set_instance_transform(i, transforms[i])

			var mmi := MultiMeshInstance3D.new()
			mmi.name = "GrassCarpet_chunk_%d_%d_v%d" % [int(wx_min + half_x), int(wz_min + half_z), variant]
			mmi.multimesh = mm
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# Cull grass beyond grass_cull_distance — fade SELF so the transition
			# is smooth and doesn't pop. This is the primary perf protection.
			mmi.visibility_range_end = grass_cull_distance
			mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			container.add_child(mmi)

	# Restore RNG so subsequent passes stay deterministic
	_rng.state = rng_state

	# Summary log (useful in proc_lab to verify instance counts)
	var total_placed: int = 0
	for child in container.get_children():
		var mmi2: MultiMeshInstance3D = child as MultiMeshInstance3D
		if mmi2 != null:
			total_placed += mmi2.multimesh.instance_count
	print("[GrassCarpet] %d chunks × ~%d = %d blades placed (budget=%d, scale=%.2f)" % [
		container.get_child_count(), instances_per_chunk, total_placed, total_budget, _scale])


## Ground-cover gltf mixed into the carpet for variety. All must be ALREADY
## imported (have a .import sibling); a path that fails to load is skipped, so
## adding a not-yet-imported entry degrades gracefully to the rest.
## env_grass_small = short tufts. Add biome-COHERENT variants here (dim cavern-
## prairie: pale grasses, moss, ferns — NOT aquatic/lily plants). Each new entry
## must pass the coherence intake (_coherence_target_sheet.md) before being added.
## NOTE: env_clover was tried here but read as aquatic lily-pads at carpet density
## in a dry cavern — removed as a coherence break.
const GRASS_MESH_PATHS: Array[String] = [
	"res://assets/art/piso1_pradera/vegetation/grass/env_grass_small_01.gltf",
]


## Loads every mesh in GRASS_MESH_PATHS (skipping any that fail). Returns a
## DUPLICATED Mesh per entry so the carpet's material override does not mutate
## the shared imported resource that scatter pools also use (e.g. clover).
func _extract_grass_meshes() -> Array[Mesh]:
	var meshes: Array[Mesh] = []
	for path in GRASS_MESH_PATHS:
		var m: Mesh = _extract_mesh_from_gltf(path)
		if m != null:
			meshes.append(m.duplicate(true))
	return meshes


## Extracts the first MeshInstance3D's Mesh from an imported gltf (recursive, so
## nested/skinned meshes are found too). Returns null if it can't be loaded.
func _extract_mesh_from_gltf(path: String) -> Mesh:
	if not ResourceLoader.exists(path):
		return null
	var packed: PackedScene = load(path)
	if packed == null:
		return null
	var root: Node = packed.instantiate()
	if root == null:
		return null
	var mesh_inst: MeshInstance3D = root as MeshInstance3D
	if mesh_inst == null:
		var found: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
		if not found.is_empty():
			mesh_inst = found[0] as MeshInstance3D
	var result: Mesh = null
	if mesh_inst != null and mesh_inst.mesh != null:
		result = mesh_inst.mesh
	root.queue_free()
	return result


## Fallback: two crossed quad planes forming a simple blade tuft.
## Used when the gltf mesh cannot be extracted at runtime.
## Each blade is ~0.4m wide × 0.6m tall; crossing gives volume from all angles.
func _make_fallback_blade_mesh() -> Mesh:
	var arr_mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Two quads rotated 90° around Y — each 0.4w × 0.6h
	for rot_deg in [0.0, 90.0]:
		var r: float = deg_to_rad(rot_deg)
		var rx: float = cos(r) * 0.2
		var rz: float = sin(r) * 0.2
		# quad: bottom-left, bottom-right, top-right, top-left (two tris)
		var v0 := Vector3(-rx, 0.0, -rz)
		var v1 := Vector3( rx, 0.0,  rz)
		var v2 := Vector3( rx, 0.6,  rz)
		var v3 := Vector3(-rx, 0.6, -rz)
		st.set_uv(Vector2(0, 1)); st.add_vertex(v0)
		st.set_uv(Vector2(1, 1)); st.add_vertex(v1)
		st.set_uv(Vector2(1, 0)); st.add_vertex(v2)
		st.set_uv(Vector2(0, 1)); st.add_vertex(v0)
		st.set_uv(Vector2(1, 0)); st.add_vertex(v2)
		st.set_uv(Vector2(0, 0)); st.add_vertex(v3)
	st.generate_normals()
	return st.commit()


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
				_scatter_cluster(POOL_TREES, 16, c, r + 2.0, r + 12.0, 0.85, 1.6, container, "trunk")
				_scatter_cluster(POOL_GROUND, 24, c, r - 1.0, r + 6.0, 0.7, 1.6, container)
				_scatter_cluster(POOL_BUSHES, 8, c, r + 1.0, r + 8.0, 0.6, 1.6, container)
				_scatter_cluster(POOL_TREES, 12, c, r + 12.0, r + 32.0, 0.7, 1.15, container, "trunk")  # halo
			"boss":
				# Acantilado: cúmulo de rocas grandes rodeando la arena
				_scatter_cluster(POOL_ROCKS, 28, c, r + 2.0, r + 18.0, 0.7, 2.9, container, "rock")
				_scatter_cluster(POOL_ROCKS, 16, c, r + 18.0, r + 40.0, 0.4, 1.4, container, "rock")  # halo
			"giant_tree":
				# Bosque denso alrededor del árbol gigante + halo que se deshilacha
				_scatter_cluster(POOL_TREES, 30, c, r * 0.4, r + 16.0, 0.85, 1.7, container, "trunk")
				_scatter_cluster(POOL_BUSHES, 12, c, r * 0.4, r + 14.0, 0.6, 1.7, container)
				_scatter_cluster(POOL_TREES, 22, c, r + 16.0, r + 48.0, 0.7, 1.2, container, "trunk")  # halo
			"entrance":
				# Grove de bienvenida: pocos árboles enmarcando, claro abierto al centro
				_scatter_cluster(POOL_TREES, 10, c, r + 4.0, r + 18.0, 0.85, 1.6, container, "trunk")
				_scatter_cluster(POOL_GROUND, 16, c, r, r + 12.0, 0.7, 1.7, container)
				_scatter_cluster(POOL_TREES, 12, c, r + 18.0, r + 38.0, 0.7, 1.15, container, "trunk")  # halo
			"ruins":
				# Escombros: rocas dispersas + arbustos invasores
				_scatter_cluster(POOL_ROCKS, 14, c, r * 0.5, r + 8.0, 0.6, 2.0, container, "rock")
				_scatter_cluster(POOL_BUSHES, 10, c, r * 0.5, r + 6.0, 0.6, 1.5, container)
			"camp":
				_scatter_cluster(POOL_BUSHES, 8, c, r + 1.0, r + 8.0, 0.6, 1.4, container)
			"altar", "well":
				_scatter_cluster(POOL_GROUND, 12, c, r, r + 6.0, 0.7, 1.6, container)

	# ── 2. Tejido conectivo entre clusters (cose los mini-biomas) ─────────────
	# Subido respecto al ralo anterior: llena los huecos muertos entre lugares
	# para que el mapa se lea continuo, no como islas sueltas. Escala amplia.
	_scatter_pool(POOL_TREES, int(TREE_COUNT * 0.7), pois, 18.0, 0.8, 1.6, container, "trunk")
	_scatter_pool(POOL_ROCKS, int(ROCK_COUNT * 0.45), pois, 12.0, 0.5, 2.0, container, "rock")
	_scatter_pool(POOL_BUSHES, int(ROCK_COUNT * 0.4), pois, 9.0, 0.6, 1.6, container)
	_scatter_pool(POOL_GROUND, int(TALL_GRASS_COUNT * 0.7), pois, 7.0, 0.7, 1.6, container)

	# ── 3. Dead trees — separate pass so laetiporus can attach at base ────────
	# FIX #2: ~5-8% of total tree count as dead snags. 40% chance each gets
	# a laetiporus bracket fungus at its trunk base (ecologically correct substrate).
	# Dead trees are excluded from POOL_TREES — this pass is their only source.
	var dead_count: int = max(3, int(TREE_COUNT * 0.06))
	_scatter_dead_trees(dead_count, pois, container)

	# ── 4. Understory mushrooms — fungi in the SHADE at tree bases (coherent). ──
	# Replaces the old uniform open-field mushroom scatter. Wrapped in RNG save/restore
	# so adding this pass does NOT shift later passes (enemy placement) for a seed.
	var rng_state_um: int = _rng.state
	_scatter_understory_mushrooms(container)
	_rng.state = rng_state_um

	# ── 5. Round-A #2: Rock emphasis near outcrop zones. ─────────────────────
	# Outcrop cells are geologically convincing with extra surface rocks. Wrapped in
	# RNG save/restore — MUST NOT shift the enemy placement sequence.
	var rng_state_oc: int = _rng.state
	_scatter_outcrop_rocks(pois, container)
	_rng.state = rng_state_oc

## Esparce instancias en un anillo (inner_r..outer_r) alrededor de `center`.
## Es el placement temático: rodea un POI con su bioma característico.
## collider_kind: "" = none, "trunk" = CapsuleShape3D for trees, "rock" = BoxShape3D for rocks.
func _scatter_cluster(
	pool: Array, count: int, center: Vector3,
	inner_r: float, outer_r: float, scale_min: float, scale_max: float, parent: Node3D,
	collider_kind: String = ""
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
		_place_instance(pool, pos, scale_min, scale_max, parent, collider_kind)

## Scatter uniforme por el mapa abierto, evitando POIs (tejido conectivo).
## collider_kind: "" = none, "trunk" = CapsuleShape3D for trees, "rock" = BoxShape3D for rocks.
func _scatter_pool(
	pool: Array, count: int, pois: Array,
	min_poi_dist: float, scale_min: float, scale_max: float, parent: Node3D,
	collider_kind: String = ""
) -> void:
	if pool.is_empty():
		return
	for i in range(count):
		var pos: Vector3 = _random_open_pos(pois, min_poi_dist)
		if pos == Vector3.INF:
			continue
		pos.y = get_terrain_height(pos.x, pos.z)
		_place_instance(pool, pos, scale_min, scale_max, parent, collider_kind)

## FIX #2 — Scatter dead trees as open-field connective tissue, then attach
## laetiporus bracket fungus at the trunk base with 40% probability.
## This keeps the fungus on its correct substrate (dead wood) without ever
## placing it on bare ground. RNG calls are deterministic (same seed = same result).
func _scatter_dead_trees(count: int, pois: Array, parent: Node3D) -> void:
	for i in range(count):
		var pos: Vector3 = _random_open_pos(pois, 14.0)
		if pos == Vector3.INF:
			continue
		pos.y = get_terrain_height(pos.x, pos.z)

		# Instantiate dead tree
		var tree: Node3D = SCENE_DEAD_TREE.instantiate() as Node3D
		if tree == null:
			continue
		var s: float = _age_scale(0.8, 1.5)
		var rot_y: float = _rng.randf() * TAU
		tree.transform = Transform3D(Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s)), pos)
		tree.add_to_group("grounded")
		parent.add_child(tree)
		# Trunk collider — same shape as POOL_TREES instances (no extra _rng calls).
		var dt_body := StaticBody3D.new()
		dt_body.collision_layer = 1
		dt_body.collision_mask  = 0
		var dt_col := CollisionShape3D.new()
		var dt_cap := CapsuleShape3D.new()
		dt_cap.radius = 0.35 * s
		dt_cap.height = 2.5 * s
		dt_col.shape = dt_cap
		dt_col.position = Vector3(0.0, 1.25 * s, 0.0)
		dt_body.add_child(dt_col)
		parent.add_child(dt_body)
		dt_body.global_position = pos

		# 40% chance: attach laetiporus at trunk base (local origin = base of tree)
		if _rng.randf() < 0.4:
			var fungus: Node3D = SCENE_LAETIPORUS.instantiate() as Node3D
			if fungus != null:
				# Place at world base of tree, slight random offset to side of trunk
				var fx: float = _rng.randf_range(-0.3, 0.3)
				var fz: float = _rng.randf_range(-0.3, 0.3)
				var fungus_scale: float = _rng.randf_range(0.5, 0.9)
				var fungus_rot: float = _rng.randf() * TAU
				fungus.transform = Transform3D(
					Basis(Vector3.UP, fungus_rot).scaled(Vector3(fungus_scale, fungus_scale, fungus_scale)),
					pos + Vector3(fx, 0.0, fz)
				)
				fungus.add_to_group("grounded")
				parent.add_child(fungus)

## Grows common mushrooms in the SHADE at the base of recorded trees. Fungi belong
## on shaded ground near trees — never the open field — so this replaces the old
## uniform mushroom scatter. ~35% of trees get a small clump of 1-3 mushrooms.
func _scatter_understory_mushrooms(parent: Node3D) -> void:
	for tree_pos in _tree_positions:
		if _rng.randf() > 0.35:
			continue
		var clump: int = _rng.randi_range(1, 3)
		for _m in range(clump):
			var off := Vector3(_rng.randf_range(-1.2, 1.2), 0.0, _rng.randf_range(-1.2, 1.2))
			var mpos: Vector3 = tree_pos + off
			mpos.y = get_terrain_height(mpos.x, mpos.z)
			var inst: Node3D = SCENE_MUSHROOM_COMMON.instantiate() as Node3D
			if inst == null:
				continue
			var s: float = _rng.randf_range(0.5, 1.0)
			var rot_y: float = _rng.randf() * TAU
			inst.transform = Transform3D(Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s)), mpos)
			inst.add_to_group("grounded")
			parent.add_child(inst)


## Round-A #2: Place extra rocks near heightmap outcrop zones for geological realism.
## Only candidates where _outcrop_noise > OUTCROP_THRESHOLD are accepted.
## Wrapped in rng save/restore at the call site (_generate_vegetation) so this pass
## is invisible to the enemy-placement RNG sequence.
## Count: ~30 extra rocks at scale=1.0; scales quadratically for proc_lab.
func _scatter_outcrop_rocks(pois: Array, parent: Node3D) -> void:
	if _outcrop_noise == null or POOL_ROCKS.is_empty():
		return
	const OUTCROP_THRESHOLD_R: float = 0.65  # slightly lower than geometry threshold → wider halo
	var flat_radius: float = FLAT_RADIUS_BASE * _scale
	var count: int = int(30.0 * _scale * _scale)
	# Count PLACEMENTS, not attempts — outcrop noise + spawn-bowl rejections used to
	# burn the whole budget so far fewer than `count` rocks actually landed. Bounded
	# attempt cap avoids spinning when noise rarely clears the threshold. (RNG-safe:
	# this whole pass is wrapped in _rng.state save/restore at the call site.)
	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = count * 6
	while placed < count and attempts < max_attempts:
		attempts += 1
		var pos: Vector3 = _random_open_pos(pois, 10.0)
		if pos == Vector3.INF:
			continue
		# Accept only if this position is actually on/near an outcrop ridge.
		var on: float = _outcrop_noise.get_noise_2d(pos.x, pos.z)
		on = (on + 1.0) * 0.5
		if on < OUTCROP_THRESHOLD_R:
			continue
		# Respect spawn bowl — no outcrops inside flat_radius.
		var dist_c: float = sqrt(pos.x * pos.x + pos.z * pos.z)
		if dist_c < flat_radius:
			continue
		pos.y = get_terrain_height(pos.x, pos.z)
		_place_instance(POOL_ROCKS, pos, 0.5, 1.8, parent, "rock")
		placed += 1

## Instancia un PackedScene random del pool con rotación Y + escala por edad.
## collider_kind: "" = no collider (bushes/grass/ground cover)
##   "trunk" → CapsuleShape3D (radius 0.35*s, height 2.5*s) blocking the trunk only.
##   "rock"  → BoxShape3D (1.0*s cube) centered 0.5*s above base.
## CRITICAL: no _rng calls inside collider creation — scale s is already computed,
## so deterministic RNG sequence for later passes is fully preserved.
func _place_instance(
	pool: Array, pos: Vector3, scale_min: float, scale_max: float, parent: Node3D,
	collider_kind: String = ""
) -> void:
	var scene: PackedScene = pool[_rng.randi() % pool.size()]
	var inst: Node3D = scene.instantiate() as Node3D
	if inst == null:
		return
	var s: float = _age_scale(scale_min, scale_max)
	var rot_y: float = _rng.randf() * TAU
	inst.transform = Transform3D(Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s)), pos)
	# Marca de intención: toda la vegetación (árboles, rocas, arbustos, flora de suelo)
	# DEBE apoyarse en el terreno. El detector de flotantes (GroundSnapUtility) sólo
	# considera nodos del grupo "grounded"; cristales y fauna aérea quedan excluidos.
	inst.add_to_group("grounded")
	parent.add_child(inst)
	# ── Cheap primitive collision for solid props ──────────────────────────────
	# StaticBody3D on Layer 1 (World), mask 0 (only player/enemies test against us).
	# All dimensions derived from already-computed `s` — zero extra _rng calls.
	if collider_kind != "":
		var body := StaticBody3D.new()
		body.collision_layer = 1   # World layer
		body.collision_mask  = 0   # passive — others query us, we don't query
		var col := CollisionShape3D.new()
		match collider_kind:
			"trunk":
				# Capsule covers the trunk only, not the canopy.
				# radius 0.35*s, total height 2.5*s, center at 1.25*s (half-height up).
				var cap := CapsuleShape3D.new()
				cap.radius = 0.35 * s
				cap.height = 2.5 * s
				col.shape = cap
				# CapsuleShape3D center is its geometric center; offset up so base = pos.
				col.position = Vector3(0.0, 1.25 * s, 0.0)
				# Record trunk base so understory mushrooms grow in tree shade (coherent
				# fungi placement) — consumed by _scatter_understory_mushrooms().
				_tree_positions.append(pos)
			"rock":
				# Convex hull from the rock's OWN mesh — follows the real silhouette
				# (incl. tiered/stepped profiles) far better than an AABB box, while
				# staying a single cheap convex shape (no trimesh cost). The shape is
				# in mesh-local space, so apply the SAME rot_y + scale s as the visual
				# `inst` to keep collider and model aligned.
				var rock_mesh: Mesh = null
				var rfound: Array[Node] = inst.find_children("*", "MeshInstance3D", true, false)
				if not rfound.is_empty():
					rock_mesh = (rfound[0] as MeshInstance3D).mesh
				if rock_mesh != null:
					col.shape = rock_mesh.create_convex_shape()
					col.transform = Transform3D(Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s)), Vector3.ZERO)
				else:
					# Fallback: box cube if the gltf has no extractable mesh.
					var box := BoxShape3D.new()
					box.size = Vector3(1.0 * s, 1.0 * s, 1.0 * s)
					col.shape = box
					col.position = Vector3(0.0, 0.5 * s, 0.0)
		body.add_child(col)
		# Add at world position (pos) with no extra transform — body is a sibling,
		# not a child of inst, so inst's scaled transform doesn't affect the collider.
		# add_child FIRST, then set global_position (global_position before the node is
		# in the tree is unreliable — would leave the collider at the container origin).
		parent.add_child(body)
		body.global_position = pos

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
		var dist: float = _rng.randf_range(20.0 * _scale, _border_radius_base - 30.0 * _scale)
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

## FIX #5 — Variant of _add_csg_box that applies _make_cave_material() instead of the
## flat-color material. Used for structural stone surfaces (walls, pillars, rubble) in
## the border, boss arena, and ruins so they read as carved stone rather than blockout.
func _add_cave_csg_box(node_name: String, world_pos: Vector3, size: Vector3, color: Color, with_collision: bool) -> CSGBox3D:
	var box: CSGBox3D = CSGBox3D.new()
	box.name = node_name
	box.size = size
	box.use_collision = with_collision
	box.material_override = _make_cave_material(color)
	box.position = world_pos
	add_child(box)
	return box

func _make_material(color: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	return mat


## FIX #5 (MEDIUM) + Round-A #1 — Cave stone material for structural CSG surfaces
## (border walls, boss arena, ruins, landmark pillars, entrance pillars, altar, well, pond rocks).
## Adds roughness + triplanar noise detail + normal map for real surface relief.
## No external texture files needed — NoiseTexture2D + FastNoiseLite are built-in.
##
## Round-A #1 additions:
##   - Normal map: a second NoiseTexture2D with as_normal_map=true provides real bump shading.
##   - Memo cache (_cave_mat_cache keyed by Color): repeated calls with the same color reuse
##     one material + one NoiseTexture2D pair instead of allocating dozens at load time.
func _make_cave_material(color: Color) -> StandardMaterial3D:
	# Cache check — return existing material if this color was already built.
	if _cave_mat_cache.has(color):
		return _cave_mat_cache[color] as StandardMaterial3D

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mat.metallic = 0.0

	# ── Albedo detail: triplanar noise → wet-stone veining ────────────────────
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.18   # coarse rock-vein scale
	noise.fractal_octaves = 3

	var noise_tex: NoiseTexture2D = NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.width = 128
	noise_tex.height = 128
	noise_tex.seamless = true

	mat.detail_enabled = true
	mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	mat.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2  # ignored when triplanar is on
	mat.detail_albedo = noise_tex

	# Triplanar mapping so the noise aligns with world-space (no UV stretching on CSG)
	mat.uv1_triplanar = true
	mat.uv1_triplanar_sharpness = 4.0
	mat.uv1_scale = Vector3(0.3, 0.3, 0.3)   # tile size ≈ 3m per noise period

	# ── Normal map: finer noise interpreted as bump for real surface relief ───
	# A different seed + higher frequency gives smaller bumps independent of the vein detail.
	# as_normal_map=true converts the greyscale noise to a tangent-space normal map.
	# bump_strength controls perceived depth (1.5 = noticeable, not overwhelming).
	var norm_noise: FastNoiseLite = FastNoiseLite.new()
	norm_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	norm_noise.frequency = 0.45   # finer than the albedo detail → smaller surface facets
	norm_noise.fractal_octaves = 2
	norm_noise.seed = 9999  # fixed seed — normal map is the same for all stone surfaces

	var norm_tex: NoiseTexture2D = NoiseTexture2D.new()
	norm_tex.noise = norm_noise
	norm_tex.width = 128
	norm_tex.height = 128
	norm_tex.seamless = true
	norm_tex.as_normal_map = true
	norm_tex.bump_strength = 1.5

	mat.normal_enabled = true
	mat.normal_texture = norm_tex
	mat.normal_scale = 1.0

	# Store in memo cache so subsequent calls with the same color reuse this instance.
	_cave_mat_cache[color] = mat
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
	add_child(king)
	king.global_position = player.global_position + fwd.normalized() * 6.0 + Vector3(0, 1.5, 0)
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
