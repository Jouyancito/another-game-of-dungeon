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

## Vacío = comportamiento normal. Con un tipo de POI ("camp", "ruins", etc.), proc_lab
## genera SOLO ese POI a escala real (600m, tamaño canon) y lo recentra al origen —
## ve el asset a su tamaño verdadero sin caminar el mapa completo. Ver generate().
@export var lab_poi_focus: String = ""

## ── Crystal glass material tweaks ────────────────────────────────────────────
## Alpha 0-1: 0 = invisible, 1 = opaque. ~0.65 = translucent gem look (Danmachi F18).
@export var crystal_alpha: float = 0.65
## Emission energy multiplier for crystal MultiMeshes. Lowered 2.0->1.2: at 2.0 the
## glow + env bloom blew the crystals to pure white and the per-color tint was lost.
## Wave1.5 audit: 1.2 keeps colored body visible while cores still exceed glow_hdr_threshold=0.85.
@export var crystal_emission_energy: float = 0.9

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
const BORDER_WALL_HEIGHT: float = 32.0  # Task 1 (2026-07-20): 25->32 — extra margin above the taller/rugged mountain-slope terrain now leading up to it
const BORDER_WALL_SEGMENTS: int = 64
## Judgment Day fix (2026-07-21): min gap kept between a border wall segment's
## TOP and CEILING_HEIGHT. At high-ridge azimuthal sections the flat
## BORDER_WALL_HEIGHT addition on top of real terrain height could reach/exceed
## the roof plane — see the per-segment clamp in _build_organic_border().
const BORDER_WALL_CEILING_MARGIN: float = 4.0

# Ceiling — NO projeta sombras para evitar oscuridad invertida
# Task 3 (2026-07-20, Joan): 45->68 — taller ceiling so the light source reads as
# ambiguous/deep rather than "obviously one flat plane up there" (crystal_ceiling_
# lightning gap doc). Every CEILING_HEIGHT-relative system (crystal field, landmark
# pillars, biolum) scales up automatically with this constant.
const CEILING_HEIGHT: float = 68.0

# Crystal field — Task 3 (2026-07-20): "lightning bolt" branching distribution
# across MULTIPLE height bands (see _build_lightning_branch_points +
# CRYSTAL_BAND_RANGES) replaces the old single sine-curve path at one narrow band.
## Joan (2026-07-20): the crystals must read as "un cúmulo de cristales de
## diferentes tamaños y formas como techo, y de ahí sale la iluminación" — a
## sparse scatter of a few small shards does not sell that. Doubled the
## cluster count and raised light output since the key light is now gone and
## these are the prairie's ONLY light source.
const CRYSTAL_PATH_CLUSTERS: int = 70       # clusters a lo largo de las ramas
const CRYSTAL_SCATTER_WIDTH: float = 60.0    # ancho de dispersión lateral
const CRYSTAL_MIN_HEIGHT: float = 20.0       # altura mínima (banda más baja)
const CRYSTAL_MAX_HEIGHT: float = 66.0       # altura máxima (banda más alta, casi al techo)
## Distinct height bands a lightning-branch point can land in — index = branch
## `band` (its generation/fork depth). Overlap a little at the edges so clusters
## blend naturally instead of showing a hard seam between tiers.
const CRYSTAL_BAND_RANGES: Array[Vector2] = [
	Vector2(20.0, 32.0),
	Vector2(30.0, 45.0),
	Vector2(42.0, 56.0),
	Vector2(54.0, 66.0),
]
const CRYSTAL_LIGHT_RANGE: float = 22.0      # quick-win: 10→22 for visible colored ground pools (clamp raised below)
# 3.0->4.5 (2026-07-20): crystals now carry the WHOLE scene's illumination
# (key light removed) — the old value was tuned as a fill light alongside a
# directional sun, not as the sole light source.
const CRYSTAL_LIGHT_ENERGY: float = 4.5
const CRYSTAL_AMBIENT_ENERGY: float = 0.25   # legacy — ya no se usa (flood gigante eliminado; fill en WorldEnv)
const CRYSTAL_MONARCH_COUNT: int = 3         # cristales gigantes "príncipe"
const CRYSTAL_LIGHTS_EVERY: int = 2          # 3->2: more real lights per cluster now that they're the only source
const CEILING_BIOLUM_PATCHES: int = 50       # parches bioluminiscentes en el techo
const CEILING_BIOLUM_COLOR: Color = Color(0.4, 0.7, 0.55)  # verde azulado orgánico

# Landmarks
const PILLAR_COUNT: int = 6

# Vegetation
const TREE_COUNT: int = 200
const ROCK_COUNT: int = 120
const TALL_GRASS_COUNT: int = 80

# Enemies
const FIELD_ENEMY_COUNT: int = 35
const PATROL_ENEMY_COUNT: int = 8

# Terrain (heightmap)
const TERRAIN_RESOLUTION: int = 96       # grid cells por lado (96*96 = 9216 verts)
## Amplitude of the base hill noise ONLY (Section 1 of _compute_height_at) — NOT
## the overall height ceiling of the map. Historically this doubled as the color
## ramp's normalisation divisor too, which was wrong: Round-C's bowl/mountain rise
## (added 2026-07-20, see BOWL_RISE_BASE etc. below) pushes real terrain to ~40m+
## near the border, so normalising by 9.0 clamped ~82% of the playable disc to the
## top of the color ramp (measured via game/scenes/dev/_height_probe.gd — see
## color-normalisation bugfix, 2026-07-30). Use TERRAIN_COLOR_MAX_HEIGHT below for
## normalisation; this constant stays scoped to what it actually names: hill noise.
const TERRAIN_MAX_HEIGHT: float = 9.0    # alto max de colinas (solo ruido base)
const TERRAIN_NOISE_FREQ: float = 0.004  # frecuencia baja = features grandes
const TERRAIN_NOISE_OCTAVES: int = 3
const TERRAIN_EDGE_RISE: float = 6.0     # subida hacia los bordes (acantilados)
const FLAT_RADIUS_BASE: float = 50.0     # spawn-bowl flatten radius (pre-scale) — single source

## Round-A #3 broad swell amplitude (unscaled — see _compute_height_at section 2 swell block).
const TERRAIN_SWELL_MAX_HEIGHT: float = 3.5
## Round-A #2 dirt/rock outcrop bump — threshold + max added metres (unscaled).
## Hoisted from a local const inside _compute_height_at so TERRAIN_COLOR_MAX_HEIGHT
## below can reference the same single source instead of a second copy that could drift.
const TERRAIN_OUTCROP_THRESHOLD: float = 0.7    # top ~15% of noise values trigger an outcrop
const TERRAIN_OUTCROP_MAX_ADD: float   = 2.5    # max added metres; ~1.5m/6m slope ≈ 14° — climbable
## Round-C radial bowl / Task 1 mountain-slope rise — metres at _scale=1.0 (the demo
## map). Hoisted from local consts inside _compute_height_at for the same reason.
const BOWL_RISE_BASE: float = 12.0      # metres gained from flat_radius edge to border
const BOWL_LIP_RISE_BASE: float = 4.0   # extra metres in the last 15% (visual border lip)
const MOUNTAIN_EXTRA_MAX: float = 14.0  # extra metres at full ridge (on top of the baseline)
const MOUNTAIN_JAG_MAX: float = 7.0     # extra metres of broken-rock detail at full ridge

## Theoretical ceiling of _compute_height_at() at _scale=1.0 — the sum of every
## additive term's maximum, hit simultaneously (worst case; real sampled max is
## lower, ~40.7m per _height_probe.gd, because noise/ridge/outcrop rarely peak at
## the same point). This is a DERIVED constant, not a new magic number: bump any
## term above and this updates automatically, so the color ramp cannot silently
## drift out of sync with the generator again (see TERRAIN_MAX_HEIGHT doc comment).
## _scale-dependent terms (bowl/mountain) are re-derived per map size in generate()
## as _terrain_color_max_height — this const is the scale=1.0 (demo map) case.
const TERRAIN_COLOR_MAX_HEIGHT: float = (
	TERRAIN_MAX_HEIGHT + TERRAIN_SWELL_MAX_HEIGHT + TERRAIN_OUTCROP_MAX_ADD
	+ BOWL_RISE_BASE + BOWL_LIP_RISE_BASE + MOUNTAIN_EXTRA_MAX + MOUNTAIN_JAG_MAX
)

# ── Round-B: Streams ──────────────────────────────────────────────────────────
# 3 stream channels carved deterministically from world_seed (no _rng — pure math).
# Each stream is a polyline of control points (Vector2 xz); the channel is
# a smoothstep-sided trench STREAM_DEPTH deep, STREAM_HALF_WIDTH either side.
# SPAWN BOWL SACRED: carve is clamped to dist_center > FLAT_RADIUS_BASE * _scale + STREAM_HALF_WIDTH.
const STREAM_COUNT: int = 3
const STREAM_HALF_WIDTH: float = 4.0    # metres either side of centreline (8m channel > 6.25m grid step → carve reliably lands on vertices)
const STREAM_DEPTH: float = 0.8         # max depth at channel floor (shallow → walkable)
const STREAM_SEGMENTS: int = 5          # control points per stream (interpolated)

# ── Colors ────────────────────────────────────────────────────────────────────
# D2-ACT-1 HYBRID palette: dominant dark-grounded, cool cavern fill, warm key.
# Procedural greens/browns desaturated ~28% vs Wave1 — Kimetsu rule: biome is quiet,
# skills and crystals are the saturated pixels. Crystals remain as jewel accents only.
const COLOR_FLOOR: Color       = Color(0.286, 0.406, 0.220)  # olive-green, -28% sat
const COLOR_CANOPY: Color      = Color(0.214, 0.302, 0.176)  # cavern leaf, -28% sat
const COLOR_CANOPY_DARK: Color = Color(0.165, 0.240, 0.131)  # dark understory, -27% sat
const COLOR_TALL_GRASS: Color  = Color(0.173, 0.252, 0.118)  # dim grass, -27% sat
const COLOR_ROCK: Color        = Color(0.502, 0.502, 0.502)  # neutral rock (keep)
const COLOR_ROCK_DARK: Color   = Color(0.380, 0.380, 0.380)  # dark rock (keep)
const COLOR_RUIN: Color        = Color(0.627, 0.627, 0.627)  # ruin stone (keep)
const COLOR_BOSS_WALL: Color   = Color(0.314, 0.314, 0.314)  # boss arena (keep)
const COLOR_PATH: Color        = Color(0.362, 0.253, 0.172)  # dirt path, -25% sat
const COLOR_BORDER: Color      = Color(0.345, 0.290, 0.235)  # cave stone (already muted)
const COLOR_CEILING: Color     = Color(0.250, 0.220, 0.200)  # ceiling rock (keep)
# JEWEL ACCENTS — crystals are the ONLY saturated pixels on floor 1.
# ~1/3 warm amber (echoes the warm key), ~1/3 cold cyan, ~1/3 violet.
const COLOR_CRYSTAL_WARM: Color = Color(1.0, 0.82, 0.45)   # cuarzo ámbar cálido (contrasta con cyan)
const COLOR_CRYSTAL_COOL: Color = Color(0.37, 0.85, 1.0)   # cyan frío #5FD8FF
const COLOR_CRYSTAL_ROSE: Color = Color(0.69, 0.44, 1.0)   # violeta #B06FFF
const COLOR_PILLAR: Color      = Color(0.400, 0.380, 0.340)  # stone pillar (already muted)
const COLOR_WATER: Color       = Color(0.2, 0.4, 0.6, 0.6)
const COLOR_ALTAR: Color       = Color(0.635, 0.603, 0.548)  # stone altar, -25% sat
const COLOR_GIANT_TRUNK: Color = Color(0.270, 0.210, 0.155)  # old bark, -26% sat
const COLOR_GIANT_CANOPY: Color = Color(0.172, 0.262, 0.136)  # dense canopy, -27% sat

# ── Monarcas: spotlight con sombra dinámica (solo los 3 cristales grandes) ───────
@export var monarch_shadows: bool = false      # true = sombra dinámica (perf red-line; off by default)
@export var monarch_light_energy: float = 2.6  # 1.5->2.6 (2026-07-20): monarchs are the "sun" now that the key light is gone
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
var SCENE_FROG: PackedScene
var SCENE_JABALI: PackedScene
var SCENE_SPIDER: PackedScene
var SCENE_BANDIT_LEADER: PackedScene
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
## Round-B: micro-jitter for stream centrelines. Low frequency so curves are gentle,
## not jagged. Seeded from world_seed+71 to stay independent of all other noise layers.
var _stream_jitter_noise: FastNoiseLite
## Task 1 (2026-07-20): high-frequency noise that breaks the border-ring mountain
## rise into broken rock-face masses instead of a perfectly smooth radial ramp.
## Sampled in raw world coords (scale-independent), only applied outside
## flat_radius — see _compute_height_at.
var _ridge_detail_noise: FastNoiseLite
## Deterministic per-seed phase offsets for _ridge_factor_at_angle() — hashed from
## world_seed (same idiom as _build_stream_polylines' hash_offset) so each seed
## gets a different azimuthal ruggedness pattern without needing an _rng draw.
var _ridge_phase_a: float = 0.0
var _ridge_phase_b: float = 0.0
var _ridge_phase_c: float = 0.0
## Precomputed stream polylines (xz pairs). Built once by _build_stream_polylines()
## which is called from _setup_terrain_noise(). Each stream is an Array[Vector2].
var _stream_polylines: Array = []
var _terrain_heights: PackedFloat32Array
var _terrain_stride: int = 0  # TERRAIN_RESOLUTION + 1

# Scaled geometry (resueltos en generate() a partir de proc_bounds).
# En el demo (scale 1.0) coinciden con las constantes históricas.
var _scale: float = 1.0
var _border_radius_base: float = BORDER_RADIUS_BASE
## Color-ramp normalisation ceiling for THIS map's _scale — bowl/mountain terms
## scale with _scale (same as _compute_height_at), noise/swell/outcrop don't.
## Recomputed in generate(); defaults to the _scale=1.0 value (TERRAIN_COLOR_MAX_HEIGHT)
## so any code reading it before generate() runs still gets a sane number.
var _terrain_color_max_height: float = TERRAIN_COLOR_MAX_HEIGHT

# Snapshot de hijos pre-generación: lo que NO está acá se considera generado
# y se libera en regenerate() para un reseed limpio.
var _baseline_children: Array[Node] = []

## Round-A #1: Material memo cache for _make_cave_material.
## Keyed by Color so repeated calls with the same color share one StandardMaterial3D
## (and therefore one NoiseTexture2D pair) instead of allocating a new one per CSG node.
## Reset in regenerate() to avoid holding stale materials across reseeds.
var _cave_mat_cache: Dictionary = {}

## Task 3 (2026-07-20): the single CrystalCeiling instance for this floor — either
## the one declared in floor1_prairie.tscn (the real 600m demo map) or one
## instantiated on demand (proc_lab's bare Floor1Prairie root has no pre-declared
## child nodes). Set once per generate() call by _get_or_build_crystal_ceiling().
var _crystal_ceiling: CrystalCeiling = null

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
	SCENE_FROG = load("res://scenes/enemy/frog.tscn")
	SCENE_JABALI = load("res://scenes/enemy/jabali.tscn")
	SCENE_SPIDER = load("res://scenes/enemy/spider.tscn")
	SCENE_BANDIT_LEADER = load("res://scenes/enemy/bandit_leader.tscn")
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
	# Color-ramp ceiling for _height_to_color — same additive terms as _compute_height_at,
	# with the _scale-dependent ones (bowl/mountain rise) scaled the same way so a small
	# proc_lab cell doesn't get normalised against the full 600m map's height range.
	_terrain_color_max_height = (
		TERRAIN_MAX_HEIGHT + TERRAIN_SWELL_MAX_HEIGHT + TERRAIN_OUTCROP_MAX_ADD
		+ (BOWL_RISE_BASE + BOWL_LIP_RISE_BASE + MOUNTAIN_EXTRA_MAX + MOUNTAIN_JAG_MAX) * _scale
	)
	_precalculate_border()
	_setup_terrain_noise()

	# 1. Atmósfera — CrystalCeiling ahora es el dueño único del techo: geometría del
	# techo de roca + AMBAS luces ambientales (sus propias CeilingLight/FocusLight,
	# más el ex CavernKeyLight fusionado adentro) — Task 3 (2026-07-20) reconciliación
	# de los 4 sistemas antes independientes descritos en _prairie_environment_rework.md
	# §4. Reemplaza los antiguos _build_ceiling()/_build_key_light() duplicados.
	_crystal_ceiling = _get_or_build_crystal_ceiling()
	_crystal_ceiling.size = Vector2(proc_bounds.x, proc_bounds.y)
	# CEILING_HEIGHT is intentionally NOT scaled by _scale — it never was (the old
	# _build_ceiling() used it unscaled too), so proc_lab's small cells keep the same
	# absolute roof height as the full 600m map instead of squashing it down to a
	# few metres.
	_crystal_ceiling.height = CEILING_HEIGHT
	_crystal_ceiling.build_rock_roof = active_layers.get("ceiling", true)
	# DAYLIGHT canon (2026-07-27, Joan): the prairie is a REAL open biome inside
	# the tower (DanMachi 18F model) — full daylight applies. This supersedes the
	# 2026-07-20 "crystals replace the sun" cavern-night model: the sun key light
	# is back ON with hard shadows (Valheim fidelity: dramatic directional light),
	# and the crystal monarchs downgrade from sole light source to accents.
	_crystal_ceiling.build_key_light = true
	_crystal_ceiling.key_light_energy = 1.25
	_crystal_ceiling.key_light_shadow = true
	# Judgment Day fix (2026-07-21): the rock roof (build_rock_roof above) is now
	# the ceiling's real visible geometry — the legacy tinted PlaneMesh is
	# redundant and z-fights it. floor1_prairie.tscn's pre-declared CrystalCeiling
	# already sets show_ceiling_plane=false statically, but _get_or_build_crystal_
	# ceiling() also instantiates a FRESH CrystalCeiling for proc_lab (bare root,
	# no pre-declared child) that keeps the export's `true` default — set it here
	# so both paths agree.
	_crystal_ceiling.show_ceiling_plane = false
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

	# 2.6. Round-B: Stream water ribbons + dry-channel pebble scatter.
	# Placed after terrain so get_terrain_height is valid; before POIs so the
	# channels read as existing waterways the POIs are situated around.
	if active_layers.get("terrain", true):
		_build_stream_ribbons()
		# Fix 2: Riparian bank scatter — wet-edge environment just outside stream channel.
		# Gated on vegetation layer so it toggles with the rest of scatter.
		if active_layers.get("vegetation", true):
			_scatter_stream_banks()
			# river_pack wiring (2026-07-27, _references/prairie_rivers/_synthesis.md):
			# _scatter_stream_banks() above only populates the bank OUTSIDE the channel.
			# These two passes fill the gap the synthesis called out - rocks INSIDE the
			# wet/dry channel bed, and reeds rooted right at the waterline.
			_scatter_stream_channel_rocks()
			_scatter_stream_reeds()

	# 3. POIs — ajustar al terreno antes de construir
	var pois: Array = []
	if active_layers.get("pois", true):
		var poi_system: POISystem = POISystem.new()
		if lab_poi_focus != "":
			# proc_lab mode: POISystem's sizes/margins/BOSS_MIN_DISTANCE are absolute
			# metres tuned for the 600m map and do NOT scale with proc_bounds (unlike
			# terrain height, fixed above). Feeding it a shrunk map_size breaks anchor
			# POIs (boss is 80x80m with a 350m min-distance rule — inside a 120m cell
			# it overflows the map itself). So: generate at TRUE 600m scale (real POI
			# size/position, matches the actual game 1:1), keep only the requested
			# type, and recenter it to local origin so it lands inside the small
			# terrain cell without the player having to walk to find it.
			var raw_pois: Array = poi_system.generate_pois(world_seed, Vector2(600.0, 600.0), Callable())
			for poi in raw_pois:
				var p: POISystem.POI = poi as POISystem.POI
				if p.type == lab_poi_focus:
					p.position = Vector3.ZERO
					pois = [p]
					break
			if pois.is_empty():
				push_warning("[floor1_lab] lab_poi_focus='%s' no salió con seed=%d — reseed (R)" % [lab_poi_focus, world_seed])
		else:
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
	# Reset stream polylines — rebuilt by _setup_terrain_noise() → _build_stream_polylines().
	_stream_polylines.clear()
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

	# Round-B: Stream jitter noise — gentle lateral perturbation of stream centrelines.
	# Low frequency (0.008) = ~125m wave, so curves look organic but not jagged.
	# seed=world_seed+71 is independent of all terrain/color/outcrop/swell noises.
	_stream_jitter_noise = FastNoiseLite.new()
	_stream_jitter_noise.seed = world_seed + 71
	_stream_jitter_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_stream_jitter_noise.frequency = 0.008
	_stream_jitter_noise.fractal_octaves = 1
	_stream_jitter_noise.fractal_lacunarity = 2.0
	_stream_jitter_noise.fractal_gain = 0.5

	# Task 1 (2026-07-20): ridge detail noise — big broken-rock masses (~80m
	# features) layered onto the border-ring rise, on top of the existing
	# 20m-scale _outcrop_noise texture. Two different feature sizes read as real
	# rock, not a single procedural frequency repeating at one scale.
	_ridge_detail_noise = FastNoiseLite.new()
	_ridge_detail_noise.seed = world_seed + 89
	_ridge_detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_ridge_detail_noise.frequency = 0.012
	_ridge_detail_noise.fractal_octaves = 2
	_ridge_detail_noise.fractal_lacunarity = 2.0
	_ridge_detail_noise.fractal_gain = 0.5
	_ridge_phase_a = float(hash(world_seed ^ 0x5EED1) % 6283) / 1000.0
	_ridge_phase_b = float(hash(world_seed ^ 0x5EED2) % 6283) / 1000.0
	_ridge_phase_c = float(hash(world_seed ^ 0x5EED3) % 6283) / 1000.0

	# Build stream polylines ONCE here, so _compute_height_at can use them without
	# any _rng calls. polylines reference only _stream_jitter_noise + world_seed hashes.
	_build_stream_polylines()


## Round-B: Build STREAM_COUNT stream polylines deterministically from world_seed.
## NO _rng calls — everything is derived from integer hashes of world_seed and stream index.
## Each stream:
##   - Starts at a point on the HIGH border ring (~180-210m from center, scaled).
##   - Ends at a point near the LOW center region (~60-80m from center, scaled).
##   - Has STREAM_SEGMENTS-2 interior control points curved by _stream_jitter_noise.
## The jitter displaces control points LATERALLY (perpendicular to the main axis) so
## the channel curves naturally without needing _rng.
func _build_stream_polylines() -> void:
	_stream_polylines.clear()
	var r_outer: float = 185.0 * _scale   # start ring radius (high terrain)
	var r_inner: float = 70.0 * _scale    # end ring radius (low center region)

	for si in range(STREAM_COUNT):
		# Deterministic base angle for this stream — spread evenly + hash offset.
		# hash() returns a non-negative int; int % int = int → cast to float after.
		var hash_offset: float = float(hash(world_seed ^ (si * 2654435761)) % 1000) / 1000.0
		var base_angle: float = (float(si) / float(STREAM_COUNT)) * TAU + hash_offset * 0.8

		# Start point on the outer ring (high terrain)
		var sx: float = cos(base_angle) * r_outer
		var sz: float = sin(base_angle) * r_outer

		# End point near center (low terrain) — slightly offset so streams converge but
		# don't all hit the exact same point; end is always outside the spawn bowl.
		var end_hash: float = float(hash(world_seed ^ (si * 3141592653 + 7)) % 1000) / 1000.0
		var end_angle: float = base_angle + (end_hash - 0.5) * 0.7
		var ex: float = cos(end_angle) * r_inner
		var ez: float = sin(end_angle) * r_inner

		var polyline: Array[Vector2] = []
		polyline.append(Vector2(sx, sz))

		# Interior control points — spaced evenly along the line, jittered laterally.
		for seg in range(1, STREAM_SEGMENTS - 1):
			var t: float = float(seg) / float(STREAM_SEGMENTS - 1)
			var lx: float = lerpf(sx, ex, t)
			var lz: float = lerpf(sz, ez, t)
			# Lateral direction (perpendicular to stream axis in xz plane)
			var dx: float = ex - sx
			var dz: float = ez - sz
			var inv_len: float = 1.0 / maxf(sqrt(dx * dx + dz * dz), 0.0001)
			var perp_x: float = -dz * inv_len
			var perp_z: float =  dx * inv_len
			# Jitter amplitude scales down near start/end so the stream hugs its anchors.
			var env: float = smoothstep(0.0, 0.5, t) * smoothstep(1.0, 0.5, t)
			var jitter: float = _stream_jitter_noise.get_noise_2d(lx, lz) * 28.0 * _scale * env
			polyline.append(Vector2(lx + perp_x * jitter, lz + perp_z * jitter))

		polyline.append(Vector2(ex, ez))
		_stream_polylines.append(polyline)


## Round-B: Returns the squared distance from world-xz point (px, pz) to the nearest
## stream segment across all polylines, plus which stream index it belongs to.
## Returns [dist_sq, stream_index].  Pure math, no _rng.
func _dist_sq_to_streams(px: float, pz: float) -> Array:
	var best_dist_sq: float = 1e18
	var best_si: int = -1
	for si in range(_stream_polylines.size()):
		var poly: Array = _stream_polylines[si]
		for pi in range(poly.size() - 1):
			var a: Vector2 = poly[pi] as Vector2
			var b: Vector2 = poly[pi + 1] as Vector2
			# Closest point on segment ab to (px, pz)
			var abx: float = b.x - a.x
			var abz: float = b.y - a.y
			var len2: float = abx * abx + abz * abz
			var dpx: float = px - a.x
			var dpz: float = pz - a.y
			var t_seg: float = 0.0
			if len2 > 0.0001:
				t_seg = clampf((dpx * abx + dpz * abz) / len2, 0.0, 1.0)
			var cx: float = a.x + t_seg * abx
			var cz: float = a.y + t_seg * abz
			var dx: float = px - cx
			var dz: float = pz - cz
			var d2: float = dx * dx + dz * dz
			if d2 < best_dist_sq:
				best_dist_sq = d2
				best_si = si
	return [best_dist_sq, best_si]


## Task 1 (2026-07-20): deterministic azimuthal ruggedness index for the border-ring
## mountain slope, 0..1. 0 = the gentlest sections (still the old smooth-bowl rise
## below — the whole ring stays part of the mountain, nothing goes back to flat),
## 1 = the steepest, most broken rock-face sections. Three incommensurate sine
## frequencies (same layering idiom as _precalculate_border's noise blend) keep the
## silhouette from repeating in an obvious pattern; phases are hashed per-seed.
func _ridge_factor_at_angle(angle_rad: float) -> float:
	var w: float = (
		sin(angle_rad * 2.0 + _ridge_phase_a) * 0.45 +
		sin(angle_rad * 5.0 + _ridge_phase_b) * 0.35 +
		sin(angle_rad * 9.0 + _ridge_phase_c) * 0.20
	)  # roughly -1..1
	return clampf(remap(clampf(w, -1.0, 1.0), -1.0, 1.0, 0.0, 1.0), 0.0, 1.0)


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
	if lab_poi_focus != "":
		# lab mode: el POI enfocado se recentra al origen a su tamaño REAL (puede medir
		# 40-80m, más que la celda chica de proc_lab). El bowl/outcrop está pensado para
		# un mapa de 600m — con una celda chica el POI real cruza del flat al bowl y
		# termina medio bajo terreno que sube. La celda entera se trata como "adentro del
		# flat_radius": terreno neutro y parejo para que el foco sea el asset, no el mundo.
		flat_radius = max_r * 10.0
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
		var swell_h: float = sw * TERRAIN_SWELL_MAX_HEIGHT
		# Attenuate to zero inside flat_radius (same envelope as the base flatten).
		var swell_blend: float = 1.0
		if dist_center < flat_radius:
			swell_blend = smoothstep(0.0, 1.0, dist_center / flat_radius)
		h += swell_h * swell_blend

	# 4. Round-C: Continuous radial bowl — terrain rises SMOOTHLY from the edge of the
	# spawn bowl out to the border.  Replaces the old t>0.7 cliff that left the mid band
	# flat and made streams look like they weren't flowing.
	#
	# Design:
	#   • bowl_t  = normalised dist in [flat_radius, border_radius] → [0, 1]
	#   • smoothstep(bowl_t) gives a gentle S-curve; max slope = 1.5 * BOWL_RISE / span
	#                          = 1.5 * 12 / 200 ≈ 0.09 m/m → over 6.25m grid step = 0.56m
	#                          (≈ 5° incline — well within CharacterBody3D climbable limit)
	#   • Inside flat_radius the blend is ZERO (spawn bowl stays completely flat).
	#   • An optional steeper lip in the last 15% of the ring adds a subtle visual wall
	#     without creating an impassable cliff (max extra = BOWL_LIP_RISE = 4m, same
	#     smooth curve — worst case slope still ~12° at the literal border edge).
	#
	# Total rise at border: BOWL_RISE(12) + BOWL_LIP_RISE(4) = 16m over 250m radius
	# which is a clearly-readable "edge is high / center is low" bowl for cavern P1.
	# Both constants are metres tuned for the full 600m map (proc_bounds default).
	# flat_radius/max_r already scale with _scale (proc_bounds shrinks them), so the
	# vertical rise MUST scale too — otherwise a small proc_lab cell keeps the full
	# 16m rise crushed into a much shorter radius, reading as a steep crater instead
	# of the intended gentle slope.
	#
	# Task 1 (2026-07-20 — Joan's Resolutions note, see _prairie_environment_rework.md):
	# NOT a separate landmark mound — the border ring ITSELF gets reshaped into an
	# irregular, non-climbable MOUNTAIN SLOPE across its whole circumference. The old
	# baseline rise below stays (every angle keeps at least this much — the ring never
	# goes back to a bare wall), and a NEW azimuthal "mountain extra" term + a
	# high-frequency jag noise are layered on top, both driven by _ridge_factor_at_angle
	# (0=gentle scree, 1=steep broken rock face) so the rim reads as ONE continuous
	# rugged massif with real variation, not a uniform smooth bowl-wall.
	# Non-climbability: the actual physical guarantee is BorderWall's CSGBox3D collision
	# ring (_build_organic_border), independently anchored to this same height function —
	# see that function's comment. The extra height/jag here is the VISUAL read of a
	# mountain leading up to that wall, not itself required to exceed the engine's floor
	# slope limit.
	# BOWL_RISE_BASE / BOWL_LIP_RISE_BASE / MOUNTAIN_EXTRA_MAX / MOUNTAIN_JAG_MAX are
	# now class-level consts (see TERRAIN_COLOR_MAX_HEIGHT section near TERRAIN_MAX_HEIGHT)
	# so _height_to_color's normalisation can share the exact same source values.
	var bowl_blend: float = 0.0
	if dist_center >= flat_radius:
		var bowl_span: float = max_r - flat_radius
		if bowl_span > 0.001:
			var bowl_t: float = clampf((dist_center - flat_radius) / bowl_span, 0.0, 1.0)
			bowl_blend = smoothstep(0.0, 1.0, bowl_t)
			h += bowl_blend * BOWL_RISE_BASE * _scale
			# Steeper lip — only in the outermost 15% of the bowl band
			if bowl_t > 0.85:
				var lip_t: float = (bowl_t - 0.85) / 0.15
				h += smoothstep(0.0, 1.0, lip_t) * BOWL_LIP_RISE_BASE * _scale

			var ridge: float = _ridge_factor_at_angle(atan2(z, x))
			# Steeper sections front-load the extra rise into a shorter remaining
			# span (start later) — reads as a genuinely steeper local gradient, not
			# just a taller version of the same gentle curve. Gradual sections start
			# earlier and spread the same extra height over more distance.
			var mountain_start: float = lerpf(0.35, 0.80, ridge)
			if bowl_t > mountain_start:
				var mountain_t: float = (bowl_t - mountain_start) / (1.0 - mountain_start)
				h += smoothstep(0.0, 1.0, mountain_t) * ridge * MOUNTAIN_EXTRA_MAX * _scale
			# Rock-face jag — breaks the ring into individual broken masses instead
			# of a smooth azimuthal wave. Fades in with bowl_blend (never touches the
			# flat spawn bowl) and scales with ridge (steep sections get bigger jags).
			if _ridge_detail_noise != null:
				var rd: float = _ridge_detail_noise.get_noise_2d(x, z)  # -1..1
				rd = (rd + 1.0) * 0.5
				h += bowl_blend * ridge * rd * MOUNTAIN_JAG_MAX * _scale

	# Round-A #2: Dirt/rock outcrops — ONLY outside the flat_radius spawn bowl.
	# _outcrop_noise is scale-independent (sampled in world coords, freq=0.05).
	# Where noise > TERRAIN_OUTCROP_THRESHOLD we add a smooth bump capped at
	# TERRAIN_OUTCROP_MAX_ADD so the steepest slope stays climbable for CharacterBody3D
	# (~1.5m over ~6m). Both are class-level consts (see TERRAIN_COLOR_MAX_HEIGHT).
	if _outcrop_noise != null and dist_center > flat_radius:
		var on: float = _outcrop_noise.get_noise_2d(x, z)  # -1..1
		on = (on + 1.0) * 0.5  # 0..1
		if on > TERRAIN_OUTCROP_THRESHOLD:
			# Smooth ramp from threshold to 1.0 → clean bump edges, no hard ledges.
			var ramp: float = (on - TERRAIN_OUTCROP_THRESHOLD) / (1.0 - TERRAIN_OUTCROP_THRESHOLD)
			ramp = smoothstep(0.0, 1.0, ramp)
			h += ramp * TERRAIN_OUTCROP_MAX_ADD

	# Round-B: Stream channel carve.
	# Subtracts a smoothstep trough wherever (x,z) falls within STREAM_HALF_WIDTH of
	# any stream polyline segment. SPAWN BOWL SACRED: carve is NEVER applied inside
	# flat_radius + STREAM_HALF_WIDTH (a channel can't eat into the landing pad).
	# No _rng — _stream_polylines was built deterministically in _build_stream_polylines().
	var spawn_safe_radius: float = flat_radius + STREAM_HALF_WIDTH
	if not _stream_polylines.is_empty() and dist_center > spawn_safe_radius:
		var stream_result: Array = _dist_sq_to_streams(x, z)
		var sd2: float = stream_result[0]
		var hw2: float = STREAM_HALF_WIDTH * STREAM_HALF_WIDTH
		if sd2 < hw2:
			# t = 0 at centreline, 1 at edge — smoothstep gives a rounded trough profile.
			var t_ch: float = sqrt(sd2) / STREAM_HALF_WIDTH   # 0..1
			var profile: float = 1.0 - smoothstep(0.0, 1.0, t_ch)  # 1 at center, 0 at edge
			h -= profile * STREAM_DEPTH

	# Safety clamp: Task 1's mountain-slope extras (rise + lip + jag, all layered on
	# the border ring) can theoretically stack near CEILING_HEIGHT at rare
	# constructive-noise peaks. CEILING_HEIGHT is a flat plane, not terrain-aware, so
	# an unclamped peak could poke through the roof geometry. Clamp only outside
	# flat_radius (the spawn bowl never approaches this regardless).
	if dist_center >= flat_radius:
		h = minf(h, CEILING_HEIGHT - 10.0)

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
	# The _height_to_color* palette was authored as DISPLAY (sRGB) tones. Without
	# this flag Godot feeds vertex colors to the shader as linear, which washes
	# the olive greens to pale cream ("nieve/desierto" ground, visible the moment
	# daylight landed on it, 2026-07-28). Same color-space family bug as the
	# Blender FLOAT_COLOR gotcha in blender-asset-smith.
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.6  # Wave1.5: 0.92→0.6 — damp sheen so crystal/river light streaks across ground
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
	# Bugfix 2026-07-30: normalising by TERRAIN_MAX_HEIGHT (9.0, base hill-noise
	# amplitude only) clamped ~82% of the playable disc to t=1.0 (top-of-ramp
	# "dry mud" brown) because the bowl/mountain rise added since Round-C pushes
	# real terrain to ~40m+ near the border — see game/docs/art/_references/
	# biome_landscape/_synthesis.md and game/scenes/dev/_height_probe.gd (measured
	# fraction before/after). Normalise against _terrain_color_max_height instead —
	# derived from the SAME constants that generate the height, so it tracks any
	# future change to the bowl/mountain/outcrop terms automatically.
	var t: float = clampf(h / _terrain_color_max_height, 0.0, 1.0)
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

	# Round-B: Streambed color — wet dark mud / pebble tone inside channel.
	# Uses the same spawn-bowl guard as the geometry carve (FLAT_RADIUS_BASE * _scale).
	# WET_MUD is a dark, cool, desaturated tone (Kimetsu canon: desaturated biome).
	const WET_MUD: Color = Color(0.18, 0.17, 0.14)  # dark damp streambed
	var dist_c2: float = sqrt(x * x + z * z)
	var safe_r2: float = FLAT_RADIUS_BASE * _scale + STREAM_HALF_WIDTH
	if not _stream_polylines.is_empty() and dist_c2 > safe_r2:
		var sr2: Array = _dist_sq_to_streams(x, z)
		var sd2c: float = sr2[0]
		var hw2c: float = STREAM_HALF_WIDTH * STREAM_HALF_WIDTH
		if sd2c < hw2c:
			var t_ch2: float = sqrt(sd2c) / STREAM_HALF_WIDTH
			var profile2: float = 1.0 - smoothstep(0.0, 1.0, t_ch2)
			result = result.lerp(WET_MUD, profile2 * 0.75)

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
		wall.use_collision = true
		# FIX #5: cave stone material — roughness + triplanar noise instead of flat color
		wall.material_override = _make_cave_material(COLOR_BORDER)
		# Task 1 (2026-07-20): anchor the wall's BASE to the local terrain height
		# instead of assuming y=0. This is THE actual non-climbable guarantee for the
		# new border-ring mountain slope (see _compute_height_at's Task 1 comment) —
		# a CSGBox3D with collision blocks movement regardless of terrain gradient.
		# Before this fix the wall's base silently assumed flat ground at y=0; with
		# the reshaped ring rising well above that near the edge, an unanchored wall
		# would end up partially buried with a shrinking exposed height wherever the
		# terrain is tall. _compute_height_at is safe to call here: _setup_terrain_noise()
		# already ran earlier in generate(), so every noise/stream input it needs exists.
		var ground_y: float = _compute_height_at(mid.x, mid.z)
		# Judgment Day fix (2026-07-21): clamp the wall's effective height so its
		# top never exceeds CEILING_HEIGHT (minus a small margin) — at high-ridge
		# azimuthal sections (common by construction of the terrain rework) the flat
		# BORDER_WALL_HEIGHT addition on top of real ground_y could reach/exceed the
		# roof plane. Clamped PER-SEGMENT using the real ground height at that
		# segment; BORDER_WALL_HEIGHT's own constant is untouched. Floored at 1.0 so
		# a pathological ground_y (already at/above the ceiling) never collapses the
		# CSGBox3D to a zero/negative-size degenerate shape.
		var actual_wall_height: float = maxf(
			minf(BORDER_WALL_HEIGHT, CEILING_HEIGHT - ground_y - BORDER_WALL_CEILING_MARGIN), 1.0)
		wall.size = Vector3(seg_len + 0.5, actual_wall_height, 3.0)
		wall.position = mid + Vector3(0, ground_y + actual_wall_height * 0.5, 0)
		wall.rotation.y = -seg_angle
		add_child(wall)

# ── Atmosphere ────────────────────────────────────────────────────────────────

const CRYSTAL_CEILING_SCENE: PackedScene = preload("res://scenes/levels/components/crystal_ceiling.tscn")

## Task 3 (2026-07-20): finds the floor's CrystalCeiling child, or instantiates one
## if none exists. The real 600m demo (floor1_prairie.tscn) already declares one
## statically — reused as-is (never duplicated). proc_lab's bare Floor1Prairie root
## (proc_lab.tscn only wires WorldEnvironment + ProcLabController as children, no
## CrystalCeiling) gets one created here; being outside _baseline_children, it is
## freed and rebuilt every regenerate() cycle exactly like the other procedural
## nodes (crystal field, pillars) — no special-casing needed at the cleanup site.
func _get_or_build_crystal_ceiling() -> CrystalCeiling:
	var existing: CrystalCeiling = get_node_or_null("CrystalCeiling") as CrystalCeiling
	if existing != null:
		return existing
	var inst: CrystalCeiling = CRYSTAL_CEILING_SCENE.instantiate() as CrystalCeiling
	inst.name = "CrystalCeiling"
	add_child(inst)
	return inst

## Task 3 (2026-07-20): recursive branching walk producing a "lightning bolt"
## silhouette instead of the old single sine-curve path — Joan's verbal brief
## (crystal_ceiling_lightning gap doc): "generación más tipo rayo... cristales de
## diferentes altura". 2-3 independent trunks branch outward and occasionally fork;
## each returned point carries a `band` (0 = trunk, higher = deeper into a fork)
## that _build_crystal_field() maps to a distinct CRYSTAL_BAND_RANGES height tier,
## so clusters land at genuinely varied heights along the branch instead of one
## narrow shared range. Bounded to `target_count` points (matches the old
## CRYSTAL_PATH_CLUSTERS budget — same perf envelope, no extra multimesh cost).
func _build_lightning_branch_points(target_count: int) -> Array:
	var points: Array = []
	var stack: Array = []
	var trunk_count: int = _rng.randi_range(2, 3)
	for t in range(trunk_count):
		var start_angle: float = (TAU / float(trunk_count)) * float(t) + _rng.randf_range(-0.4, 0.4)
		stack.append({
			"pos": Vector2.ZERO, "angle": start_angle,
			"len": 220.0 * _scale, "band": 0,
		})
	while points.size() < target_count:
		if stack.is_empty():
			# Judgment Day fix (2026-07-21): the walk used to stop as soon as the
			# initial 2-3 trunks + their forks drained, stalling well short of
			# target_count (~48/70 realized) — forking alone can't be relied on
			# to reach the budget since it's capped by CRYSTAL_BAND_RANGES depth
			# and a 30% roll per step. Keep seeding fresh trunks with the SAME
			# pattern as the initial loop above until points.size() >= target_count.
			stack.append({
				"pos": Vector2.ZERO, "angle": _rng.randf_range(0.0, TAU),
				"len": 220.0 * _scale, "band": 0,
			})
		var branch: Dictionary = stack.pop_front()
		var pos: Vector2 = branch["pos"]
		var angle: float = branch["angle"]
		var remaining: float = branch["len"]
		var band: int = branch["band"]
		var steps: int = _rng.randi_range(3, 6)
		var seg_len: float = remaining / float(steps)
		for s in range(steps):
			if points.size() >= target_count:
				break
			angle += _rng.randf_range(-0.55, 0.55)   # jagged kink — reads as "lightning"
			pos += Vector2(cos(angle), sin(angle)) * seg_len
			points.append({"pos": pos, "band": band})
			# Fork occasionally, one generation deeper (taller/shorter band) —
			# capped depth via band so it can't recurse past the last band tier.
			if s > 0 and band < CRYSTAL_BAND_RANGES.size() - 1 and _rng.randf() < 0.3:
				var fork_sign: float = 1.0 if _rng.randf() < 0.5 else -1.0
				var fork_angle: float = angle + _rng.randf_range(0.6, 1.4) * fork_sign
				stack.append({
					"pos": pos, "angle": fork_angle,
					"len": remaining * 0.5, "band": band + 1,
				})
	return points


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

	# Task 3 (2026-07-20): two-tier hierarchy formalization — monarch 0 is the
	# designated CORE (brightest, "sun") and anchors CrystalCeiling's FocusLight so
	# the two independently-authored systems (this field's crystals + the
	# component's ambient lights) agree on where the "sun" actually is, instead of
	# each picking its own unrelated position. SKY accents are the regular cluster
	# field below — already trends cooler by construction (2 of 3 crystal_colors —
	# cool cyan + violet — outweigh the 1 warm amber in the random draw).
	if not monarch_positions.is_empty() and _crystal_ceiling != null:
		_crystal_ceiling.anchor_focus_light(Vector2(monarch_positions[0].x, monarch_positions[0].z))

	# ── 2. Clusters — "lightning bolt" branching distribution across MULTIPLE
	# height bands (Task 3, 2026-07-20 — Joan: DanMachi's crystal-sky is one
	# mostly-flat layer; ours should read taller/deeper, with clusters at varying
	# heights along a branching path so the light source stops reading as one flat
	# plane — see crystal_ceiling_lightning gap doc). Replaces the old single
	# sine-curve path + flat [MIN,MAX] height roll shared by the whole field.
	# Judgment Day fix (2026-07-21): border/monarch-proximity rejections below
	# (both `continue`) used to drop points with no replacement, so the
	# REALIZED cluster count landed ~30% short of CRYSTAL_PATH_CLUSTERS even
	# with a one-shot over-generated batch (measured: some seeds still landed
	# ~50/70 with a flat 1.3x margin). Index-driven loop: once the current
	# batch is exhausted and the target isn't met yet, top up with another
	# batch sized to the remaining shortfall instead of stopping — bounded by
	# MAX_TOPUP_TRIES so a pathological seed can't loop forever.
	const MAX_TOPUP_TRIES: int = 4
	var branch_points: Array = _build_lightning_branch_points(int(ceil(float(CRYSTAL_PATH_CLUSTERS) * 1.3)))
	var realized_clusters: int = 0
	var topup_tries: int = 0
	var idx: int = 0
	while realized_clusters < CRYSTAL_PATH_CLUSTERS:
		if idx >= branch_points.size():
			if topup_tries >= MAX_TOPUP_TRIES:
				break
			var shortfall: int = CRYSTAL_PATH_CLUSTERS - realized_clusters
			var before_size: int = branch_points.size()
			branch_points.append_array(_build_lightning_branch_points(int(ceil(float(shortfall) * 1.5))))
			topup_tries += 1
			if branch_points.size() <= before_size:
				break  # generator produced nothing new — bail out safely
		var i: int = idx
		var bp: Dictionary = branch_points[idx]
		idx += 1
		var p2: Vector2 = bp["pos"]
		var band: int = bp["band"]
		var band_range: Vector2 = CRYSTAL_BAND_RANGES[band % CRYSTAL_BAND_RANGES.size()]

		var path_x: float = p2.x
		var path_z: float = p2.y

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
		realized_clusters += 1

		var cluster_color: Color = crystal_colors[_rng.randi_range(0, crystal_colors.size() - 1)]

		# Tipo de cluster: variedad real
		var cluster_type: float = _rng.randf()
		if cluster_type < 0.2:
			# Tipo A: Un cristal grande dominante + muchos chiquitos
			var cy: float = _rng.randf_range(band_range.x, band_range.y)
			_spawn_crystal_shard("Crystal%d_Dom" % i,
				Vector3(path_x, cy, path_z), cluster_color,
				4.0, 10.0, 1.5, 3.0)
			for s in range(_rng.randi_range(6, 10)):
				_spawn_crystal_shard("Crystal%d_%d" % [i, s],
					Vector3(path_x, cy, path_z), cluster_color,
					0.3, 2.0, 0.15, 0.6)
		elif cluster_type < 0.5:
			# Tipo B: Formación densa — muchos medianos agrupados
			var cy: float = _rng.randf_range(band_range.x, band_range.y)
			for s in range(_rng.randi_range(5, 9)):
				_spawn_crystal_shard("Crystal%d_%d" % [i, s],
					Vector3(path_x, cy, path_z), cluster_color,
					1.0, 5.0, 0.4, 1.5)
		elif cluster_type < 0.75:
			# Tipo C: Disperso — pocos cristales sueltos esparcidos
			var cy: float = _rng.randf_range(band_range.x, band_range.y)
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
			# Tipo D: Cascada — desciende DENTRO de la banda del propio punto de
			# rama, en vez de arrancar siempre desde el techo — así hay cascadas
			# en cada altura, no solo cerca del techo.
			var cascade_top: float = band_range.y
			for s in range(_rng.randi_range(4, 7)):
				var step_y: float = cascade_top - float(s) * _rng.randf_range(1.5, 3.0)
				var drift: float = float(s) * _rng.randf_range(0.5, 1.5)
				_spawn_crystal_shard("Crystal%d_%d" % [i, s],
					Vector3(path_x + drift, step_y, path_z + drift * 0.5),
					cluster_color,
					0.8, 4.5, 0.3, 1.2)

		# Luz real solo cada N clusters — Wave1.5: tight pool (range 7-12m) at energy 3.0
		# so cluster omnis actually reach the ground below the ceiling.
		if i % CRYSTAL_LIGHTS_EVERY == 0:
			var cy_light: float = _rng.randf_range(band_range.x, band_range.y)
			var cl: OmniLight3D = OmniLight3D.new()
			cl.name = "CrystalLight%d" % i
			# Tint-matched to crystal color (saturated, not washed toward white)
			cl.light_color = cluster_color
			cl.light_energy = CRYSTAL_LIGHT_ENERGY + _rng.randf_range(-0.3, 0.3)
			cl.omni_range = clampf(CRYSTAL_LIGHT_RANGE + _rng.randf_range(-3.0, 2.0), 14.0, 26.0)
			cl.omni_attenuation = 1.5
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

# Faceted crystal model — BESPOKE bpy-generated (game/tools/blender/gen_crystal.py),
# 26 tris vs the old TRELLIS amethyst's 98,809. The crystal MultiMeshes instance
# THIS mesh (tinted + glowing via material_override); the field's many rotated
# instances form the clusters. Falls back to the box if the .glb isn't imported yet.
const SCENE_CRYSTAL_GLB: String = "res://assets/art/piso1_pradera/crystals/crystal_dp_single_01.glb"
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

	# A4: clamp so the shard's bottom tip (pos.y - length*0.5) stays below
	# CEILING_HEIGHT - 1, i.e. pos.y + length*0.5 <= CEILING_HEIGHT - 1.
	# Also skip shards placed outside the playable border.
	var shard_top: float = pos.y + length * 0.5
	if shard_top > CEILING_HEIGHT - 1.0:
		pos.y -= shard_top - (CEILING_HEIGHT - 1.0)
	if not _is_inside_border(Vector3(pos.x, 0.0, pos.z)):
		return

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
		# Task 1 (2026-07-20): the first half of the pillars now crown the new
		# rugged mountain rim (per the spec's own "_build_landmark_pillars() is the
		# natural hook" suggestion) instead of all 6 scattering at the old mid-ring
		# distance — reinforces the border-ring reshape visually. The rest stay at
		# the old distance so the floor doesn't read as ringed-by-pillars-only.
		var crown: bool = i < int(PILLAR_COUNT / 2)
		var dist: float = _rng.randf_range(190.0, 235.0) * _scale if crown \
			else _rng.randf_range(100.0, 200.0) * _scale
		var base_x: float = cos(angle) * dist
		var base_z: float = sin(angle) * dist
		var pos: Vector3 = Vector3(base_x, 0, base_z)
		if not _is_inside_border(pos):
			continue
		# Snap the pillar's BASE to the actual terrain height instead of assuming
		# y=0 — with the mountain-slope rework the ring terrain is no longer near-
		# flat out here, so an unsnapped base used to end up partially buried.
		# _compute_height_at is safe here: _setup_terrain_noise() already ran.
		var ground_y: float = _compute_height_at(base_x, base_z)
		# Piso-a-techo: el pilar SIEMPRE llega al techo de la cueva (Joan, 2026-07-18 —
		# antes la altura era aleatoria 30-50m contra un techo fijo en 45m, así que la
		# mayoría de las tiradas quedaban cortas y el pilar no tocaba el techo).
		var height: float = CEILING_HEIGHT - ground_y
		if height <= 1.0:
			continue

		var pillar: CSGCylinder3D = CSGCylinder3D.new()
		pillar.name = "LandmarkPillar%d" % i
		pillar.radius = _rng.randf_range(2.0, 4.0)
		pillar.height = height
		pillar.sides = 8
		pillar.use_collision = true
		# Round-A #1: landmark pillars use cave material (worked stone, not flat color)
		pillar.material_override = _make_cave_material(COLOR_PILLAR)
		pillar.position = Vector3(base_x, ground_y + height * 0.5, base_z)
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
	# El player está en collision_layer = 2 (las 7 escenas de clase la setean explícitamente).
	# Esto escaneaba la layer 1, así que el trigger NUNCA veía al jugador y el King Slime
	# NUNCA spawneaba: el boss del canon —"pelea OBLIGATORIA, el boss ES el paso"— era
	# inalcanzable salvo por _debug_spawn_king_slime(). El comentario viejo decía que el
	# player estaba en layer 1 "por default"; los .tscn dicen lo contrario.
	trigger.collision_mask = 2
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
	# Killing the boss opens the way down — that descent is where the run ends.
	# Bound to the boss instance rather than polling: die() emits this exactly once.
	if king is BaseEnemy:
		(king as BaseEnemy).died.connect(_on_boss_died)


## Reveals the descent in the arena the boss died in.
func _on_boss_died(boss: BaseEnemy) -> void:
	var descent := FloorDescent.new()
	descent.name = "FloorDescent"
	descent.from_floor = boss.enemy_tier
	# Offset from the corpse so the descent never spawns under the loot it just dropped.
	# Reuses the boss's own Y: it is standing on the arena's CSG slab, which is flat and
	# sits above the terrain heightmap — get_terrain_height() would sink the pit into it.
	var spot: Vector3 = boss.global_position + Vector3(0.0, 0.0, 6.0)
	add_child(descent)
	descent.global_position = spot


## Bandit camp dressing — delegates to VillageBuilder (2026-07-18), a terrain/
## biome-aware village generator that replaced the old ad-hoc fence-ring +
## flat-box layout. Structure (palisade ring, double-gate airlock, watchtower,
## central hut, inner ring, patches, scatter) lives in
## `game/scripts/village_builder.gd`; the "bandit_prairie" style Dictionary
## there carries all asset paths for this pack. See
## `game/docs/village_builder.md` and `game/docs/art/_references/bandit_camp/_synthesis.md`.
##
## Instances a real-prop PackedScene as pure set dressing — visual only, no
## collision (fence/banner/lantern are thin geometry; a solid StaticBody here
## risks snagging bandit AI pathing around the camp, which this dressing pass
## must not touch). `lean_rad` is an optional extra tilt around the prop's own
## yaw-relative forward axis — used by VillageBuilder's palisade jitter for the
## "desparejo" (uneven) look; 0.0 keeps the old straight-up behavior.
func _add_camp_prop(scene: PackedScene, node_name: String, world_pos: Vector3, rot_y: float, scale: float = 1.0, lean_rad: float = 0.0) -> void:
	if scene == null:
		return
	var inst: Node3D = scene.instantiate() as Node3D
	if inst == null:
		return
	inst.name = node_name
	var yaw_basis: Basis = Basis(Vector3.UP, rot_y)
	var prop_basis: Basis = yaw_basis.scaled(Vector3(scale, scale, scale))
	if lean_rad != 0.0:
		prop_basis = prop_basis.rotated(yaw_basis * Vector3.FORWARD, lean_rad)
	inst.transform = Transform3D(prop_basis, world_pos)
	inst.add_to_group("grounded")
	_scatter_apply_geo_flags(inst, 80.0)
	add_child(inst)

func _build_camp(poi: POISystem.POI) -> void:
	VillageBuilder.build(self, poi, get_terrain_height, _rng, _add_camp_prop, VillageBuilder.STYLE_BANDIT_PRAIRIE)

## Landmark tree uses a REAL scaled gltf, not the old green-box-on-a-stick.
const SCENE_GIANT_TREE: PackedScene = preload("res://assets/art/piso1_pradera/vegetation/common/env_tree_common_01.gltf")

func _build_giant_tree(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position

	# Landmark-sized REAL tree (model native ~7m → ~31m at 4.5x) — replaces the old
	# CSGCylinder trunk + flat green CSGBox canopy that read as a box floating on a stick.
	var giant_scale: float = 4.5
	var tree: Node3D = SCENE_GIANT_TREE.instantiate() as Node3D
	if tree != null:
		var rot_y: float = _rng.randf() * TAU
		tree.transform = Transform3D(Basis(Vector3.UP, rot_y).scaled(Vector3(giant_scale, giant_scale, giant_scale)), pos)
		tree.add_to_group("grounded")
		# D1: shadow-off + 120m visibility cull for the landmark tree
		_scatter_apply_geo_flags(tree, 120.0)
		add_child(tree)
		# Thick trunk collider — blocks the player at the base (canopy is overhead).
		# Wave1.5: radius 1.6→2.8 — enemies were clipping through the trunk/roots.
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var col := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 2.8
		cap.height = 12.0
		col.shape = cap
		col.position = Vector3(0.0, 6.0, 0.0)
		body.add_child(col)
		add_child(body)
		body.global_position = pos

	# Gnarled roots fanning from the base (kept — grounds the giant tree visually).
	for i in range(5):
		var angle: float = float(i) * TAU / 5.0 + _rng.randf_range(-0.2, 0.2)
		var root_len: float = _rng.randf_range(4.0, 7.0)
		_add_csg_box("GiantRoot%d" % i,
			pos + Vector3(cos(angle) * (3.0 + root_len * 0.5), 0.4, sin(angle) * (3.0 + root_len * 0.5)),
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

	# river_pack wiring (2026-07-27) — sparse reed_clump_small at the pond edge, same
	# waterline-rooting idea as _scatter_stream_reeds() but scaled down + rarer: a
	# pond POI is a small water feature, reeds should read as an occasional accent,
	# not a full ring around it. RNG save/restore — invisible to enemy placement.
	const REED_SMALL_PATH: String = "res://assets/art/piso1_pradera/props/water/env_river_reed_clump_small_01.glb"
	var reed_small_scene: PackedScene = load(REED_SMALL_PATH) if ResourceLoader.exists(REED_SMALL_PATH) else null
	if reed_small_scene != null:
		var rng_state_pond_reeds: int = _rng.state
		for i in range(8):
			# Sparse: only ~35% of the 8 angle slots get a reed.
			if _rng.randf() > 0.35:
				continue
			var angle: float = float(i) * TAU / 8.0 + _rng.randf_range(-0.2, 0.2)
			var br: float = sz.x * 0.4 + _rng.randf_range(-0.2, 0.3)
			var rx: float = pos.x + cos(angle) * br
			var rz: float = pos.z + sin(angle) * br
			var s: float = _rng.randf_range(0.5, 0.9)
			var rot_y: float = _rng.randf_range(0.0, TAU)
			var reed_inst: Node3D = reed_small_scene.instantiate() as Node3D
			if reed_inst != null:
				reed_inst.transform = Transform3D(
					Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s)),
					Vector3(rx, get_terrain_height(rx, rz), rz)
				)
				_detail_apply_geo_flags(reed_inst, 45.0)
				add_child(reed_inst)
		_rng.state = rng_state_pond_reeds

## Fix 2 — Riparian bank scatter.
## Along every stream polyline, in the band [STREAM_HALF_WIDTH .. STREAM_HALF_WIDTH+4m]
## from the centreline, scatter a wet-edge environment:
##   - prop_rock_small_01  (small rocks, with convex collider via _place_instance "rock")
##   - env_pebble_round_01 (pebbles, no collider, tiny scale)
##   - env_grass_small_01 scaled tall as reed proxy (no dedicated reed asset)
##   - env_bush_small variants (wetland tufts)
## Placement is deterministic through _rng — fully wrapped in state save/restore so
## the enemy-placement RNG sequence is unaffected.
## No colliders on pebbles or reeds; small rocks get one via _place_instance.
## Shadows off, visibility_range on all detail via _detail_apply_geo_flags.
func _scatter_stream_banks() -> void:
	if _stream_polylines.is_empty():
		return

	# Load assets — graceful degradation if a file isn't imported yet.
	const PEBBLE_PATH: String = "res://assets/art/piso1_pradera/terrain/pebbles/env_pebble_round_01.gltf"
	const SMALL_ROCK_PATH: String = "res://assets/art/piso1_pradera/props/rocks/prop_rock_small_01.glb"
	const REED_PATH: String = "res://assets/art/piso1_pradera/vegetation/grass/env_grass_small_01.gltf"
	const BUSH_PATHS: Array[String] = [
		"res://assets/art/piso1_pradera/vegetation/bush/env_bush_small_flowers_01.gltf",
		"res://assets/art/piso1_pradera/vegetation/bush/env_bush_01.gltf",
	]

	var pebble_scene: PackedScene = load(PEBBLE_PATH) if ResourceLoader.exists(PEBBLE_PATH) else null
	var small_rock_scene: PackedScene = load(SMALL_ROCK_PATH) if ResourceLoader.exists(SMALL_ROCK_PATH) else null
	var reed_scene: PackedScene = load(REED_PATH) if ResourceLoader.exists(REED_PATH) else null
	var bush_scenes: Array[PackedScene] = []
	for bp in BUSH_PATHS:
		if ResourceLoader.exists(bp):
			bush_scenes.append(load(bp))

	var container := Node3D.new()
	container.name = "RiparianBanks"
	add_child(container)

	# Riparian band parameters
	const BAND_INNER: float = STREAM_HALF_WIDTH        # start just outside channel rim
	const BAND_OUTER: float = STREAM_HALF_WIDTH + 4.0  # 4m wide wet-edge band
	const SAMPLES_PER_SEG: int = 8  # candidate points per polyline segment

	var flat_radius: float = FLAT_RADIUS_BASE * _scale
	var spawn_safe_r: float = flat_radius + STREAM_HALF_WIDTH

	# RNG save/restore — this pass must be invisible to enemy placement
	var rng_state_banks: int = _rng.state

	for si in range(_stream_polylines.size()):
		var poly: Array = _stream_polylines[si]
		if poly.size() < 2:
			continue

		for pi in range(poly.size() - 1):
			var a2: Vector2 = poly[pi] as Vector2
			var b2: Vector2 = poly[pi + 1] as Vector2

			# Perpendicular directions to the segment (both sides of the bank)
			var seg_dx: float = b2.x - a2.x
			var seg_dz: float = b2.y - a2.y
			var seg_len: float = sqrt(seg_dx * seg_dx + seg_dz * seg_dz)
			if seg_len < 0.001:
				continue
			var inv_len: float = 1.0 / seg_len
			var perp_x: float = -seg_dz * inv_len   # left perpendicular
			var perp_z: float =  seg_dx * inv_len

			for _sp in range(SAMPLES_PER_SEG):
				# Random t along segment
				var t_seg: float = _rng.randf()
				var cx_s: float = lerpf(a2.x, b2.x, t_seg)
				var cz_s: float = lerpf(a2.y, b2.y, t_seg)

				# Skip if inside spawn bowl
				var dc: float = sqrt(cx_s * cx_s + cz_s * cz_s)
				if dc < spawn_safe_r:
					# Burn the draws below to stay RNG-neutral
					_rng.randf()   # side
					_rng.randf_range(BAND_INNER, BAND_OUTER)  # dist
					_rng.randf()   # item roll
					_rng.randf_range(0.0, TAU)  # rot_y
					_rng.randf()   # scale/type draw
					continue

				# Random side (left or right bank) + radial offset within band
				var side: float = 1.0 if _rng.randf() > 0.5 else -1.0
				var dist_from_center: float = _rng.randf_range(BAND_INNER, BAND_OUTER)
				var px: float = cx_s + perp_x * dist_from_center * side
				var pz: float = cz_s + perp_z * dist_from_center * side

				# Guard: must still be within the playable area
				if not _is_inside_border(Vector3(px, 0.0, pz)):
					_rng.randf()   # item roll
					_rng.randf_range(0.0, TAU)  # rot_y
					_rng.randf()   # scale draw
					continue

				var terrain_y: float = get_terrain_height(px, pz)

				# Determine what to place: 40% pebble, 30% small rock, 20% reed, 10% bush
				var item_roll: float = _rng.randf()
				var rot_y: float = _rng.randf_range(0.0, TAU)
				var scale_draw: float = _rng.randf()  # consumed regardless of branch

				if item_roll < 0.40 and pebble_scene != null:
					# Pebble — no collider, tiny scale, shadow off
					var inst: Node3D = pebble_scene.instantiate() as Node3D
					if inst != null:
						var s: float = lerpf(0.15, 0.45, scale_draw)
						inst.transform = Transform3D(
							Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s)),
							Vector3(px, terrain_y, pz)
						)
						_detail_apply_geo_flags(inst, 50.0)
						container.add_child(inst)

				elif item_roll < 0.70 and small_rock_scene != null:
					# Small rock — use _place_instance "rock" path for convex collider.
					# _place_instance consumes 3 _rng draws (randi() + _age_scale roll×2 + randf()).
					# We already consumed 3 draws above (item_roll, rot_y, scale_draw) before
					# arriving here, so we call _place_instance directly but must note it will
					# consume additional draws. Because this entire pass is wrapped in RNG save/
					# restore, the total draw count variation is absorbed — enemy placement is
					# protected by the restore at the end of this function.
					var s: float = lerpf(0.3, 0.8, scale_draw)
					var rock_inst: Node3D = small_rock_scene.instantiate() as Node3D
					if rock_inst != null:
						rock_inst.transform = Transform3D(
							Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s)),
							Vector3(px, terrain_y, pz)
						)
						rock_inst.add_to_group("grounded")
						container.add_child(rock_inst)
						# Cheap box collider (no extra _rng needed)
						var body := StaticBody3D.new()
						body.collision_layer = 1
						body.collision_mask = 0
						var col := CollisionShape3D.new()
						var box := BoxShape3D.new()
						box.size = Vector3(s, s, s)
						col.shape = box
						col.position = Vector3(0.0, s * 0.5, 0.0)
						body.add_child(col)
						container.add_child(body)
						body.global_position = Vector3(px, terrain_y, pz)

				elif item_roll < 0.90 and reed_scene != null:
					# Reed proxy — env_grass_small scaled tall, no collider.
					# C8: Y stretch capped at 1.8 (was 2.5) — avoids surreal stilts
					# that read as aquatic reeds needing standing water; 1.8 = tall
					# marsh grass, believable in a damp cavern bank.
					var inst: Node3D = reed_scene.instantiate() as Node3D
					if inst != null:
						var sx: float = lerpf(0.6, 1.0, scale_draw)
						var sy: float = lerpf(1.2, 1.8, scale_draw)  # C8: was (1.5, 2.5)
						inst.transform = Transform3D(
							Basis(Vector3.UP, rot_y).scaled(Vector3(sx, sy, sx)),
							Vector3(px, terrain_y, pz)
						)
						_detail_apply_geo_flags(inst, 50.0)
						container.add_child(inst)

				elif not bush_scenes.is_empty():
					# Wetland tuft (small bush variant) — no collider, shadow off
					var bscene: PackedScene = bush_scenes[int(scale_draw * bush_scenes.size()) % bush_scenes.size()]
					var inst: Node3D = bscene.instantiate() as Node3D
					if inst != null:
						var s: float = lerpf(0.3, 0.7, scale_draw)
						inst.transform = Transform3D(
							Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s)),
							Vector3(px, terrain_y, pz)
						)
						_detail_apply_geo_flags(inst, 55.0)
						container.add_child(inst)

	# Restore RNG — enemy placement sequence is unaffected
	_rng.state = rng_state_banks
	print("[RiparianBanks] %d bank objects placed" % container.get_child_count())


## Round-B: Build water ribbon + optional dry-watercourse pebble line for each stream.
## Streams 0 and 1 get a toon-water ribbon sitting partway up the carved trench.
## Stream 2 is left DRY — only a pebble line follows the channel.
## No _rng in the ribbon geometry; pebble scatter uses _rng.state save/restore.
## use_collision=false, shadows off for all stream water.
func _build_stream_ribbons() -> void:
	if _stream_polylines.is_empty():
		return
	var container := Node3D.new()
	container.name = "StreamRibbons"
	add_child(container)

	for si in range(_stream_polylines.size()):
		var poly: Array = _stream_polylines[si]
		if poly.size() < 2:
			continue

		var is_dry: bool = (si == 2)   # stream 2 = dry watercourse

		if not is_dry:
			# ── Water ribbon — flat quad mesh along the polyline ──────────────────
			# The ribbon sits at terrain_height + STREAM_DEPTH * 0.40 (partway up the
			# carved trench, below the rim) so it reads as water filling the channel.
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)

			for pi in range(poly.size() - 1):
				var a2: Vector2 = poly[pi] as Vector2
				var b2: Vector2 = poly[pi + 1] as Vector2
				var ax: float = a2.x; var az: float = a2.y
				var bx: float = b2.x; var bz: float = b2.y

				# Water surface Y = terrain height at centreline + STREAM_DEPTH * 0.40.
				# get_terrain_height already includes the carved trough, so this places
				# the ribbon partway up the trench (above the carved floor, below the rim)
				# → water visibly sits in the dip, not buried under the ground.
				var ay: float = get_terrain_height(ax, az) + STREAM_DEPTH * 0.40
				var by_: float = get_terrain_height(bx, bz) + STREAM_DEPTH * 0.40

				# Width of ribbon = slightly narrower than the full channel for visual clarity
				var ribbon_hw: float = STREAM_HALF_WIDTH * 0.65

				# Segment direction + perpendicular (xz plane)
				var dx: float = bx - ax
				var dz: float = bz - az
				var inv_len: float = 1.0 / maxf(sqrt(dx * dx + dz * dz), 0.0001)
				var px: float = -dz * inv_len   # left perpendicular
				var pz: float =  dx * inv_len

				# Four corners of the quad strip segment
				var v00 := Vector3(ax + px * ribbon_hw, ay,  az + pz * ribbon_hw)
				var v01 := Vector3(ax - px * ribbon_hw, ay,  az - pz * ribbon_hw)
				var v10 := Vector3(bx + px * ribbon_hw, by_, bz + pz * ribbon_hw)
				var v11 := Vector3(bx - px * ribbon_hw, by_, bz - pz * ribbon_hw)

				# UV along segment for flow animation in the shader
				var u0: float = float(pi)       / float(poly.size() - 1)
				var u1: float = float(pi + 1)   / float(poly.size() - 1)

				st.set_uv(Vector2(u0, 0.0)); st.add_vertex(v00)
				st.set_uv(Vector2(u0, 1.0)); st.add_vertex(v01)
				st.set_uv(Vector2(u1, 1.0)); st.add_vertex(v11)
				st.set_uv(Vector2(u0, 0.0)); st.add_vertex(v00)
				st.set_uv(Vector2(u1, 1.0)); st.add_vertex(v11)
				st.set_uv(Vector2(u1, 0.0)); st.add_vertex(v10)

			st.generate_normals()
			var ribbon_mesh: ArrayMesh = st.commit()

			# Fix 3: compute average stream direction (start → end) for flow_dir uniform.
			# Use the polyline start/end points for a stable, smooth direction.
			# Normalise; if degenerate (zero-length stream), fall back to (1, 0).
			var p_start: Vector2 = poly[0] as Vector2
			var p_end:   Vector2 = poly[poly.size() - 1] as Vector2
			var fdir: Vector2 = (p_end - p_start)
			var fdir_len: float = fdir.length()
			if fdir_len > 0.0001:
				fdir = fdir / fdir_len
			else:
				fdir = Vector2(1.0, 0.0)

			# Reuse water_toon.gdshader — same approach as _build_pond / _build_well.
			var water_mat: ShaderMaterial = ShaderMaterial.new()
			water_mat.shader = load("res://scenes/levels/water_toon.gdshader")
			# water_color is a vec3 uniform — alpha is silently dropped; use base_transparency
			# to control opacity. 0.55 < pond default (0.7) → streams are more see-through.
			# Wave1.5: molten-gold color (warm amber) so river reads as gold vs cold crystals.
			var stream_water_color: Color = Color(0.55, 0.38, 0.12)
			water_mat.set_shader_parameter("water_color", stream_water_color)
			water_mat.set_shader_parameter("base_transparency", 0.55)
			# Wave1.5: trim emission ~15% (0.06 → 0.051) — reads as molten gold, not white laser.
			water_mat.set_shader_parameter("emission_strength", 0.051)
			# Flow direction: xz world vector → shader vec2. Shader uniform hint_range is on
			# individual components; pass as Vector2 which Godot sends as vec2.
			water_mat.set_shader_parameter("flow_dir", fdir)

			var ribbon_mi := MeshInstance3D.new()
			ribbon_mi.name = "StreamWater%d" % si
			ribbon_mi.mesh = ribbon_mesh
			ribbon_mi.material_override = water_mat
			ribbon_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			container.add_child(ribbon_mi)
		else:
			# ── Dry watercourse — pebble line along the channel centreline ─────────
			# RNG save/restore so this scatter pass is INVISIBLE to enemy placement.
			var pebble_scene: PackedScene = null
			const PEBBLE_PATH: String = "res://assets/art/piso1_pradera/terrain/pebbles/env_pebble_round_01.gltf"
			if ResourceLoader.exists(PEBBLE_PATH):
				pebble_scene = load(PEBBLE_PATH)
			if pebble_scene == null:
				continue

			var rng_state_pebble: int = _rng.state

			# Place ~6 pebble clusters along the polyline using deterministic positions
			# (lerp along the curve, no _rng for positioning).
			var pebble_count: int = 6
			for pi in range(pebble_count):
				var t_p: float = (float(pi) + 0.5) / float(pebble_count)
				# Interpolate along polyline by segment count
				var total_segs: int = poly.size() - 1
				var seg_t: float = t_p * float(total_segs)
				var seg_i: int = clampi(int(seg_t), 0, total_segs - 1)
				var seg_frac: float = seg_t - float(seg_i)
				var pa2: Vector2 = poly[seg_i] as Vector2
				var pb2: Vector2 = poly[seg_i + 1] as Vector2
				var cx2: float = lerpf(pa2.x, pb2.x, seg_frac)
				var cz2: float = lerpf(pa2.y, pb2.y, seg_frac)
				var cy2: float = get_terrain_height(cx2, cz2) - STREAM_DEPTH * 0.6

				# Spawn bowl safety check (no pebbles inside the spawn bowl)
				var dc: float = sqrt(cx2 * cx2 + cz2 * cz2)
				if dc < FLAT_RADIUS_BASE * _scale:
					continue

				# Small cluster: 2-4 pebbles per placement using _rng (wrapped)
				var clump: int = _rng.randi_range(2, 4)
				for _cp in range(clump):
					var off_x: float = _rng.randf_range(-STREAM_HALF_WIDTH * 0.6, STREAM_HALF_WIDTH * 0.6)
					var off_z: float = _rng.randf_range(-0.5, 0.5)
					var pebble: Node3D = pebble_scene.instantiate() as Node3D
					if pebble == null:
						continue
					var ps: float = _rng.randf_range(0.3, 0.7)
					var prot: float = _rng.randf() * TAU
					pebble.transform = Transform3D(
						Basis(Vector3.UP, prot).scaled(Vector3(ps, ps, ps)),
						Vector3(cx2 + off_x, cy2, cz2 + off_z)
					)
					_detail_apply_geo_flags(pebble, 60.0)
					container.add_child(pebble)

			# Restore RNG — enemy placement unchanged
			_rng.state = rng_state_pebble

	print("[StreamRibbons] %d streams built (%d wet, 1 dry)" % [_stream_polylines.size(), _stream_polylines.size() - 1])


## river_pack wiring (2026-07-27) — In-channel rocks.
## _scatter_stream_banks() (Fix 2, above) only populates the BANK — the band OUTSIDE
## the channel rim (STREAM_HALF_WIDTH..+4m). The _synthesis.md gap (game/docs/art/
## _references/prairie_rivers/_synthesis.md) is that the channel itself has no rocks
## for the two wet streams; only the dry watercourse gets a pebble line
## (_build_stream_ribbons' dry branch). This pass adds rocks INSIDE the channel,
## following the centreline with irregular per-segment spacing (not a grid), slightly
## sunk into the terrain so they read as settled in the streambed rather than
## floating on the water ribbon (ribbon sits at terrain_height + STREAM_DEPTH*0.40;
## sinking the rock base below terrain_height lets its geometry poke back up through
## that surface).
## Wet streams (si 0, 1): env_river_rock_river_wet_01 (common) + _wet_cluster_01
## (rarer accent — CLUSTER_CHANCE). Dry stream (si 2): env_river_rock_river_dry_01.
## Target density ~2-4 rocks per ~15m of stream length (moderate accent, not fill) —
## ROCK_SPACING_TARGET=6m averages ~2.5 candidates per 15m.
## RNG save/restore — invisible to enemy placement, same convention as Fix 2.
func _scatter_stream_channel_rocks() -> void:
	if _stream_polylines.is_empty():
		return

	const ROCK_WET_PATH: String = "res://assets/art/piso1_pradera/props/water/env_river_rock_river_wet_01.glb"
	const ROCK_WET_CLUSTER_PATH: String = "res://assets/art/piso1_pradera/props/water/env_river_rock_river_wet_cluster_01.glb"
	const ROCK_DRY_PATH: String = "res://assets/art/piso1_pradera/props/water/env_river_rock_river_dry_01.glb"

	var rock_wet_scene: PackedScene = load(ROCK_WET_PATH) if ResourceLoader.exists(ROCK_WET_PATH) else null
	var rock_wet_cluster_scene: PackedScene = load(ROCK_WET_CLUSTER_PATH) if ResourceLoader.exists(ROCK_WET_CLUSTER_PATH) else null
	var rock_dry_scene: PackedScene = load(ROCK_DRY_PATH) if ResourceLoader.exists(ROCK_DRY_PATH) else null

	if rock_wet_scene == null and rock_dry_scene == null:
		return

	var container := Node3D.new()
	container.name = "StreamChannelRocks"
	add_child(container)

	const ROCK_SPACING_TARGET: float = 6.0   # ~2.5 candidates per 15m of stream
	const CLUSTER_CHANCE: float = 0.22       # "menos frecuente" — roughly 1 in 4-5

	var flat_radius: float = FLAT_RADIUS_BASE * _scale
	var spawn_safe_r: float = flat_radius + STREAM_HALF_WIDTH

	var rng_state_channel: int = _rng.state

	for si in range(_stream_polylines.size()):
		var poly: Array = _stream_polylines[si]
		if poly.size() < 2:
			continue
		var is_dry: bool = (si == 2)
		if is_dry and rock_dry_scene == null:
			continue
		if not is_dry and rock_wet_scene == null:
			continue

		for pi in range(poly.size() - 1):
			var a2: Vector2 = poly[pi] as Vector2
			var b2: Vector2 = poly[pi + 1] as Vector2
			var seg_dx: float = b2.x - a2.x
			var seg_dz: float = b2.y - a2.y
			var seg_len: float = sqrt(seg_dx * seg_dx + seg_dz * seg_dz)
			if seg_len < 0.001:
				continue
			var inv_len: float = 1.0 / seg_len
			var perp_x: float = -seg_dz * inv_len   # left perpendicular
			var perp_z: float =  seg_dx * inv_len

			var candidate_count: int = maxi(1, int(round(seg_len / ROCK_SPACING_TARGET)))
			for _c in range(candidate_count):
				# Irregular spacing: random t along the segment, not evenly gridded.
				var t_seg: float = _rng.randf()
				var cx_s: float = lerpf(a2.x, b2.x, t_seg)
				var cz_s: float = lerpf(a2.y, b2.y, t_seg)

				var dc: float = sqrt(cx_s * cx_s + cz_s * cz_s)
				if dc < spawn_safe_r:
					continue

				# Lateral jitter INSIDE the channel (stays within STREAM_HALF_WIDTH so
				# rocks sit in the bed, never out on the bank — that's Fix 2's job).
				var lat: float = _rng.randf_range(-STREAM_HALF_WIDTH * 0.75, STREAM_HALF_WIDTH * 0.75)
				var px: float = cx_s + perp_x * lat
				var pz: float = cz_s + perp_z * lat

				if not _is_inside_border(Vector3(px, 0.0, pz)):
					continue

				# Settle into the streambed — small sink so the rock reads as sitting IN
				# the channel floor (poking through the water ribbon), not resting on top.
				var sink: float = _rng.randf_range(0.04, 0.14)
				var terrain_y: float = get_terrain_height(px, pz) - sink
				var rot_y: float = _rng.randf_range(0.0, TAU)

				var scene: PackedScene = null
				var s: float = 1.0
				if is_dry:
					scene = rock_dry_scene
					s = _rng.randf_range(0.45, 0.95)
				else:
					var cluster_roll: float = _rng.randf()
					if cluster_roll < CLUSTER_CHANCE and rock_wet_cluster_scene != null:
						scene = rock_wet_cluster_scene
						s = _rng.randf_range(0.7, 1.3)
					else:
						scene = rock_wet_scene
						s = _rng.randf_range(0.5, 1.1)

				if scene == null:
					continue
				var inst: Node3D = scene.instantiate() as Node3D
				if inst == null:
					continue
				inst.transform = Transform3D(
					Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s)),
					Vector3(px, terrain_y, pz)
				)
				_detail_apply_geo_flags(inst, 55.0)
				container.add_child(inst)

	_rng.state = rng_state_channel
	print("[StreamChannelRocks] %d channel rocks placed" % container.get_child_count())


## river_pack wiring (2026-07-27) — Waterline reeds.
## _synthesis.md (heron_riverbank_reeds.jpg) confirms reeds root IN the water at the
## bank's edge, not set back on dry ground. This pass places env_river_reed_clump_01
## in occasional clumps straddling the channel rim — from inside the visible water
## ribbon out to the rim itself — so they read as "in shallow water or touching it",
## never out on the dry bank (that band belongs to Fix 2's bank scatter).
## Wet streams only (si 0, 1) — the dry channel has no waterline to root reeds in.
## Target density ~1-2 clump groups per ~15m — REED_SPACING_TARGET=10m averages ~1.5
## candidates per 15m, each candidate additionally gated by a 55% spawn roll so
## clumps read as occasional accents, not a continuous fringe.
## RNG save/restore — invisible to enemy placement, same convention as Fix 2.
func _scatter_stream_reeds() -> void:
	if _stream_polylines.is_empty():
		return

	const REED_PATH: String = "res://assets/art/piso1_pradera/props/water/env_river_reed_clump_01.glb"
	var reed_scene: PackedScene = load(REED_PATH) if ResourceLoader.exists(REED_PATH) else null
	if reed_scene == null:
		return

	var container := Node3D.new()
	container.name = "StreamReeds"
	add_child(container)

	const REED_SPACING_TARGET: float = 10.0   # ~1.5 candidates per 15m of stream
	const CLUMP_SPAWN_CHANCE: float = 0.55    # occasional, not continuous fringe

	var flat_radius: float = FLAT_RADIUS_BASE * _scale
	var spawn_safe_r: float = flat_radius + STREAM_HALF_WIDTH

	var rng_state_reeds: int = _rng.state

	for si in range(_stream_polylines.size()):
		if si == 2:   # dry channel — no waterline to root reeds in
			continue
		var poly: Array = _stream_polylines[si]
		if poly.size() < 2:
			continue

		for pi in range(poly.size() - 1):
			var a2: Vector2 = poly[pi] as Vector2
			var b2: Vector2 = poly[pi + 1] as Vector2
			var seg_dx: float = b2.x - a2.x
			var seg_dz: float = b2.y - a2.y
			var seg_len: float = sqrt(seg_dx * seg_dx + seg_dz * seg_dz)
			if seg_len < 0.001:
				continue
			var inv_len: float = 1.0 / seg_len
			var perp_x: float = -seg_dz * inv_len   # left perpendicular
			var perp_z: float =  seg_dx * inv_len
			var dir_x: float = seg_dx * inv_len
			var dir_z: float = seg_dz * inv_len

			var candidate_count: int = maxi(1, int(round(seg_len / REED_SPACING_TARGET)))
			for _c in range(candidate_count):
				var t_seg: float = _rng.randf()
				var cx_s: float = lerpf(a2.x, b2.x, t_seg)
				var cz_s: float = lerpf(a2.y, b2.y, t_seg)

				var dc: float = sqrt(cx_s * cx_s + cz_s * cz_s)
				if dc < spawn_safe_r:
					continue

				# Occasional clump, not every candidate — keeps reeds a natural accent.
				if _rng.randf() > CLUMP_SPAWN_CHANCE:
					continue

				var side: float = 1.0 if _rng.randf() > 0.5 else -1.0
				var clump_count: int = _rng.randi_range(1, 3)
				for _cp in range(clump_count):
					# Waterline band: from inside the visible water ribbon (ribbon_hw is
					# STREAM_HALF_WIDTH*0.65 in _build_stream_ribbons) out to the channel
					# rim — "in shallow water or touching it", never out on the dry bank.
					var dist_from_center: float = _rng.randf_range(STREAM_HALF_WIDTH * 0.5, STREAM_HALF_WIDTH * 0.98)
					var jitter_along: float = _rng.randf_range(-0.6, 0.6)
					var px: float = cx_s + perp_x * dist_from_center * side + dir_x * jitter_along
					var pz: float = cz_s + perp_z * dist_from_center * side + dir_z * jitter_along

					if not _is_inside_border(Vector3(px, 0.0, pz)):
						continue

					var terrain_y: float = get_terrain_height(px, pz)
					var s: float = _rng.randf_range(0.7, 1.25)
					var rot_y: float = _rng.randf_range(0.0, TAU)
					var inst: Node3D = reed_scene.instantiate() as Node3D
					if inst == null:
						continue
					inst.transform = Transform3D(
						Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s)),
						Vector3(px, terrain_y, pz)
					)
					_detail_apply_geo_flags(inst, 50.0)
					container.add_child(inst)

	_rng.state = rng_state_reeds
	print("[StreamReeds] %d reed clumps placed" % container.get_child_count())


# ── Vegetation (gltf scatter — assets reales CC0) ────────────────────────────
# Pools de assets reales para scatter procedural. Reemplaza el viejo BoxMesh
# placeholder: el mapa entero se puebla con los gltf integrados, no cajas planas.

## FIX #4 (MEDIUM) — Birch is shade-intolerant (pioneer species); reduced from 5 slots
## to 2. Dead tree removed from pool (now via _scatter_dead_trees() for FIX #2).
## 4 freed slots → maple (understory-tolerant). Pool size stays 12:
##   Before: 5 birch / 3 maple / 3 common / 1 dead = 12
##   After:  2 birch / 7 maple / 3 common / 0 dead = 12
## See _coherence_target_sheet.md §BREAK #4.
## 2026-07-27 (bespoke tree_pack wiring, pradera canon): +12 slots for the 5 new
## tree_pack variants (game/assets/art/piso1_pradera/vegetation/tree_pack/), kept
## roughly comparable to the 12 legacy slots below (Joan: legacy stays, new ones
## convive con pesos comparables — total replacement is a future decision). The
## combined tree_pack.glb is intentionally NOT wired — only the 5 individual
## variants. See FLORA_NICHES below for the humidity/shade niche of each.
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
	# 5 tree_prairie — dominant generalist (highest single weight among the new set)
	preload("res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_prairie_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_prairie_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_prairie_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_prairie_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_prairie_01.glb"),
	# 2 tree_prairie_tall — approximated "map edge" niche (see FLORA_NICHES comment)
	preload("res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_prairie_tall_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_prairie_tall_01.glb"),
	# 1 tree_prairie_wide — shade tree in clearings, deliberately rare/standout
	preload("res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_prairie_wide_01.glb"),
	# 2 tree_young — transition sapling between denser tree masses
	preload("res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_young_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_young_01.glb"),
	# 2 tree_dry — dry-zone companion to bush_dry
	preload("res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_dry_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_dry_01.glb"),
]

## Dead tree scene — managed separately so laetiporus can attach at spawn time.
## FIX #2: placed via _scatter_dead_trees(), not in POOL_TREES.
const SCENE_DEAD_TREE: PackedScene = preload("res://assets/art/piso1_pradera/vegetation/dead/env_tree_dead_01.gltf")

## C7: flowering bushes removed — full-sun wildflower bushes are incoherent in a
## dim cavern (same rationale as flower_clump removal in POOL_GROUND).
## env_bush_flowers_01 + env_bush_small_flowers_01 dropped; pool reduced to 2
## base shrub types that read as shade-tolerant understory brush.
## 2026-07-27 (bespoke bush_pack wiring, pradera canon): +5 slots for the 5 new
## bush_pack variants (game/assets/art/piso1_pradera/vegetation/bush/, filenames
## env_bush_{round,large,flowering,low,dry}_01.glb — note env_bush_large_01.glb is
## a DIFFERENT file from the legacy env_bush_large_01.gltf below, coexisting by
## extension). 1 slot per species (old and new alike) keeps every species'
## per-species weight comparable — visible but none monopolizes. The combined
## bush_pack.glb is intentionally NOT wired. See FLORA_NICHES for niches.
const POOL_BUSHES: Array[PackedScene] = [
	preload("res://assets/art/piso1_pradera/vegetation/bush/env_bush_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/bush/env_bush_large_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/bush/env_bush_round_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/bush/env_bush_large_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/bush/env_bush_flowering_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/bush/env_bush_low_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/bush/env_bush_dry_01.glb"),
]
## 2026-07-25: +6 rock_pack variants (game/tools/blender/rock_pack/build_rock_pack.py,
## ref game/docs/art/_references/rocks/_synthesis.md). Coherence sheet §L72-74 rates
## every rock/pebble entry "Y" — mineral scatter has no light/water/shade niche, so no
## FLORA_NICHES registration needed (same treatment as the pre-existing 3 rocks below).
## §17.2.4 per-instance variation (non-uniform scale + noise fracture) is already baked
## into each variant's own generator, on top of _place_instance's existing scale/rot jitter.
const POOL_ROCKS: Array[PackedScene] = [
	preload("res://assets/art/piso1_pradera/props/rocks/prop_rock_large_01.glb"),
	preload("res://assets/art/piso1_pradera/props/rocks/prop_rock_small_01.glb"),
	preload("res://assets/art/piso1_pradera/props/rocks/prop_rock_wide_01.glb"),
	preload("res://assets/art/piso1_pradera/terrain/pebbles/env_pebble_round_01.gltf"),
	preload("res://assets/art/piso1_pradera/props/rocks/prop_rock_scatter_pebbles_01.glb"),
	preload("res://assets/art/piso1_pradera/props/rocks/prop_rock_boulder_mossy_01.glb"),
	preload("res://assets/art/piso1_pradera/props/rocks/prop_rock_slab_flat_01.glb"),
	preload("res://assets/art/piso1_pradera/props/rocks/prop_rock_cluster_broken_01.glb"),
	preload("res://assets/art/piso1_pradera/props/rocks/prop_rock_boulder_large_01.glb"),
	preload("res://assets/art/piso1_pradera/props/rocks/prop_rock_outcrop_hollow_01.glb"),
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
##
## 2026-07-25: grass_pack (game/tools/blender/grass_pack/build_grass_pack.py, ref
## foliage_painterly/_synthesis.md — painterly dark-base/lime-tip vertex-color clumps)
## wired in as 6 accent-clump variants. Same "fantasy biome compromise" already accepted
## for the GRASS_MESH_PATHS carpet (coherence sheet §L59: "keep carpet but acknowledge
## it is a compromise") — no FLORA_NICHES entry needed, same neutral-weight treatment as
## POOL_ROCKS. wildflower_mix carries 2 tiny yellow accent buds INSIDE the grass mass
## (not a standalone bloom field) — same compromise tier, not the BREAK #1 offense.
##
## 2026-07-27 CANON UPDATE (Joan decision, engram topic bioma/pradera-canon):
## floor 1 is now a REAL, large prairie inside the tower (DanMachi 18F style), not a
## dim cavern. Full-sun flora is valid canon. This REVERSES the 2026-07-25 call kept
## below for history — the other 5 flower_pack variants (violet_cluster, yellow_clover,
## white_star, bicolor_mix, tall_stalk) are wired in below with their own FLORA_NICHES
## entries (full-sun open ground / tree semi-shade / water's edge per species — see
## FLORA_NICHES comments). The 3 env_flower_clump_* legacy texture-card variants
## (BREAK #1, still cavern-era photoreal cards) stay excluded — this is a different,
## purpose-built low-poly pack, not a reintroduction of that break.
##
## 2026-07-25 (superseded by the above): flower_pack
## (game/tools/blender/flower_pack/build_flower_pack.py) built 6 variants total; only
## flower_pale_glow is wired in here. The other 5 (violet_cluster, yellow_clover,
## white_star, bicolor_mix, tall_stalk) are saturated full-sun wildflower colors — the
## EXACT species profile BREAK #1 removed (env_flower_clump_*). They stay unwired in
## game/tools/blender/flower_pack/ (assets exist, just not promoted to assets/) rather
## than reintroducing that break. pale_glow was purpose-built as the "cave-coherent
## variant" (see its build_flower_pack.py docstring) — pale blue-white + subtle emission
## reads as damp-cave/bioluminescent-adjacent flora, not a sunlit bloom, so it gets a
## FLORA_NICHES entry biased to high humidity + high shade (same "damp shaded ground"
## niche already used for env_mushroom_laetiporus_01/common below) instead of the
## "no niche" treatment given to grass/rocks.
const POOL_GROUND: Array[PackedScene] = [
	preload("res://assets/art/piso1_pradera/vegetation/clover/env_clover_01.gltf"),
	preload("res://assets/art/piso1_pradera/vegetation/grass/env_grass_lawn_dense_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/grass/env_grass_wispy_seedhead_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/grass/env_grass_broad_clump_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/grass/env_grass_sparse_dry_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/grass/env_grass_windswept_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/grass/env_grass_wildflower_mix_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/flowers/env_flower_pale_glow_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/flowers/env_flower_yellow_clover_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/flowers/env_flower_bicolor_mix_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/flowers/env_flower_violet_cluster_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/flowers/env_flower_white_star_01.glb"),
	preload("res://assets/art/piso1_pradera/vegetation/flowers/env_flower_tall_stalk_01.glb"),
]

## The laetiporus scene — spawned at base of dead trees only (see _generate_vegetation).
const SCENE_LAETIPORUS: PackedScene = preload("res://assets/art/piso1_pradera/vegetation/mushroom/env_mushroom_laetiporus_01.gltf")

## Common mushroom — spawned in the SHADE at the base of trees (see
## _scatter_understory_mushrooms), never in open field.
const SCENE_MUSHROOM_COMMON: PackedScene = preload("res://assets/art/piso1_pradera/vegetation/mushroom/env_mushroom_common_01.gltf")

# ── Task 2 (2026-07-20): humidity + shade niche system ───────────────────────
# Lightweight proxy system (spec §3) — NOT the full per-cell procedural_ecology.md
# grid (that design is generic multi-floor and never got implemented; too big for
# what floor 1 needs). Reuses data that already exists: _stream_polylines + pond
# POIs for humidity, _tree_positions for shade. Only wired into the CONNECTIVE-
# TISSUE scatter (_scatter_pool, the flat-percentage part) — the hand-authored
# POI-anchored clusters (pond/boss/giant_tree/entrance/camp/ruins/altar/well) stay
# exactly as curated, per the spec's "keep them as an authored override layer".

## Humidity/shade range [min, max] on a 0..1 scale, per POOL entry (keyed by
## resource_path — stable across POOL_TREES' duplicate preload() slots, unlike
## PackedScene object identity). Populated directly from the ecological reasoning
## already recorded in _coherence_target_sheet.md's shade-tolerance column and the
## FIX #1-#5 comments already baked into this file (see POOL_TREES/POOL_BUSHES/
## POOL_GROUND above). humidity 1 = at the water's edge; shade 1 = directly under a
## tree canopy. Entries with no key here (POOL_ROCKS — minerals have no ecological
## niche) fall back to a neutral weight in _pick_flora_for_point, i.e. uniform
## random selection exactly like before this system existed.
const FLORA_NICHES: Dictionary = {
	# Birch — shade-intolerant pioneer (BREAK #4): confine it to the brightest
	# ground instead of relying on luck, per its own comment ("sparse, near
	# crystal-spotlight zones by chance").
	"res://assets/art/piso1_pradera/vegetation/birch/env_tree_birch_01.gltf":
		{"humidity": [0.15, 0.75], "shade": [0.0, 0.3]},
	"res://assets/art/piso1_pradera/vegetation/birch/env_tree_birch_02.gltf":
		{"humidity": [0.15, 0.75], "shade": [0.0, 0.3]},
	# Maple — the coherence sheet's best-fit understory tree (medium-high shade
	# tolerance); belongs UNDER canopy, not in the open.
	"res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_01.gltf":
		{"humidity": [0.1, 0.85], "shade": [0.3, 1.0]},
	"res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_02.gltf":
		{"humidity": [0.1, 0.85], "shade": [0.3, 1.0]},
	"res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_03.gltf":
		{"humidity": [0.1, 0.85], "shade": [0.3, 1.0]},
	# Common broadleaf — low-medium shade tolerance, sits between birch and maple.
	"res://assets/art/piso1_pradera/vegetation/common/env_tree_common_01.gltf":
		{"humidity": [0.1, 0.7], "shade": [0.0, 0.55]},
	"res://assets/art/piso1_pradera/vegetation/common/env_tree_common_02.gltf":
		{"humidity": [0.1, 0.7], "shade": [0.0, 0.55]},
	"res://assets/art/piso1_pradera/vegetation/common/env_tree_common_03.gltf":
		{"humidity": [0.1, 0.7], "shade": [0.0, 0.55]},
	# Bushes — generic understory shrubs, medium shade tolerance, mesic.
	"res://assets/art/piso1_pradera/vegetation/bush/env_bush_01.gltf":
		{"humidity": [0.1, 0.8], "shade": [0.2, 0.9]},
	"res://assets/art/piso1_pradera/vegetation/bush/env_bush_large_01.gltf":
		{"humidity": [0.1, 0.8], "shade": [0.2, 0.9]},
	# Clover — the surviving flower-adjacent entry after BREAK #1 removed the
	# full-sun wildflowers (grass_pack/flower_pale_glow added 2026-07-25 don't
	# change this verdict). White clover tolerates up to ~50% shade.
	"res://assets/art/piso1_pradera/vegetation/clover/env_clover_01.gltf":
		{"humidity": [0.15, 1.0], "shade": [0.0, 0.7]},
	# flower_pale_glow (2026-07-25) — pale blue-white + subtle emission reads as
	# damp-cave/bioluminescent-adjacent flora, not a sunlit bloom — biased to the
	# same high-humidity, high-shade "damp shaded ground" niche as the mushroom
	# entries below, i.e. near water AND under canopy. Kept as-is post the
	# 2026-07-27 pradera canon update — it is still the "damp corner" variant even
	# in an open-air prairie (pond edges, deep tree shade pockets).
	"res://assets/art/piso1_pradera/vegetation/flowers/env_flower_pale_glow_01.glb":
		{"humidity": [0.4, 1.0], "shade": [0.5, 1.0]},
	# yellow_clover + bicolor_mix (2026-07-27, pradera canon) — saturated full-sun
	# wildflowers, the species profile the old cavern canon rejected (BREAK #1).
	# Now correct: open, dry, sun-exposed prairie ground, away from tree canopy.
	"res://assets/art/piso1_pradera/vegetation/flowers/env_flower_yellow_clover_01.glb":
		{"humidity": [0.0, 0.55], "shade": [0.0, 0.25]},
	"res://assets/art/piso1_pradera/vegetation/flowers/env_flower_bicolor_mix_01.glb":
		{"humidity": [0.0, 0.55], "shade": [0.0, 0.25]},
	# violet_cluster + white_star (2026-07-27, pradera canon) — woodland-margin
	# bloomers, biased to the semi-shade band under tree canopy (same range family
	# as env_bush_01/large_01) rather than full open sun or deep shade.
	"res://assets/art/piso1_pradera/vegetation/flowers/env_flower_violet_cluster_01.glb":
		{"humidity": [0.1, 0.85], "shade": [0.35, 0.85]},
	"res://assets/art/piso1_pradera/vegetation/flowers/env_flower_white_star_01.glb":
		{"humidity": [0.1, 0.85], "shade": [0.35, 0.85]},
	# tall_stalk (2026-07-27, pradera canon) — reads as a marginal/wetland spike
	# (tall, upright silhouette), biased to high humidity near stream/pond edges,
	# tolerant of open sun since banks are rarely deep-canopy.
	"res://assets/art/piso1_pradera/vegetation/flowers/env_flower_tall_stalk_01.glb":
		{"humidity": [0.55, 1.0], "shade": [0.0, 0.5]},
	# Registered for completeness (spec §3 lists them explicitly) even though these
	# three are placed by their OWN substrate-aware passes (_scatter_dead_trees,
	# _scatter_understory_mushrooms), not through _pick_flora_for_point — a dead
	# snag's "any open ground" rule and a fungus's wood/shade-base rule are already
	# stronger, more specific placement logic than a flat humidity/shade query.
	"res://assets/art/piso1_pradera/vegetation/dead/env_tree_dead_01.gltf":
		{"humidity": [0.0, 1.0], "shade": [0.0, 1.0]},
	"res://assets/art/piso1_pradera/vegetation/mushroom/env_mushroom_laetiporus_01.gltf":
		{"humidity": [0.3, 1.0], "shade": [0.5, 1.0]},
	"res://assets/art/piso1_pradera/vegetation/mushroom/env_mushroom_common_01.gltf":
		{"humidity": [0.25, 1.0], "shade": [0.4, 1.0]},
	# ── 2026-07-27 tree_pack + bush_pack (pradera canon) ────────────────────
	# tree_prairie — dominant generalist: broadest tolerance of the new trees,
	# open sun through light-medium shade, the "fills everywhere" species.
	"res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_prairie_01.glb":
		{"humidity": [0.0, 0.9], "shade": [0.0, 0.6]},
	# tree_prairie_tall — "map edge/border" is not a modeled axis in this
	# humidity/shade proxy system (no distance-to-border query exists here).
	# Approximated the same way birch's "near crystal-spotlight zones by chance"
	# comment already does: bias to the driest, most open band, which correlates
	# with the outer ring (streams run from the outer ring toward the center, so
	# open/dry ground away from them tends toward the map's margins).
	"res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_prairie_tall_01.glb":
		{"humidity": [0.0, 0.5], "shade": [0.0, 0.25]},
	# tree_prairie_wide — shade tree standing in open clearings (low pool weight
	# keeps it a rare, deliberate "spot" tree rather than a common filler).
	"res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_prairie_wide_01.glb":
		{"humidity": [0.1, 0.85], "shade": [0.0, 0.35]},
	# tree_young — sapling reads as a transition species between denser tree
	# masses: medium shade tolerance, same family as common broadleaf.
	"res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_young_01.glb":
		{"humidity": [0.1, 0.75], "shade": [0.15, 0.6]},
	# tree_dry — dry-zone tree, paired with bush_dry below on the same low-
	# humidity band (away from streams/ponds).
	"res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_dry_01.glb":
		{"humidity": [0.0, 0.3], "shade": [0.0, 0.35]},
	# bush_round + bush_large (new) — clearing-edge shrubs, semi-shade, same
	# family as the legacy env_bush_01/large_01 generic-understory niche above.
	"res://assets/art/piso1_pradera/vegetation/bush/env_bush_round_01.glb":
		{"humidity": [0.1, 0.8], "shade": [0.3, 0.8]},
	"res://assets/art/piso1_pradera/vegetation/bush/env_bush_large_01.glb":
		{"humidity": [0.1, 0.8], "shade": [0.35, 0.9]},
	# bush_flowering — full-sun shrub paired with the open-ground wildflowers
	# (same band as yellow_clover/bicolor_mix).
	"res://assets/art/piso1_pradera/vegetation/bush/env_bush_flowering_01.glb":
		{"humidity": [0.0, 0.55], "shade": [0.0, 0.25]},
	# bush_low — ground-hugging open-prairie shrub, broad humidity tolerance,
	# needs full sun (low shade).
	"res://assets/art/piso1_pradera/vegetation/bush/env_bush_low_01.glb":
		{"humidity": [0.0, 0.7], "shade": [0.0, 0.2]},
	# bush_dry — dry-zone shrub, low humidity band shared with tree_dry above.
	"res://assets/art/piso1_pradera/vegetation/bush/env_bush_dry_01.glb":
		{"humidity": [0.0, 0.3], "shade": [0.0, 0.4]},
}

## Distance-based humidity proxy (0..1): 1 at a stream centerline or pond POI,
## falling off to 0 across a halo radius. Reuses the "humidity halo = 1.5-3x water
## body radius" rule already established in game/docs/art/_world_coherence.md §2
## instead of building a new per-cell grid.
func _humidity_at(x: float, z: float, pois: Array) -> float:
	var best: float = 0.0
	if not _stream_polylines.is_empty():
		var sr: Array = _dist_sq_to_streams(x, z)
		var d: float = sqrt(sr[0])
		var halo: float = STREAM_HALF_WIDTH * 3.0
		best = maxf(best, clampf(1.0 - d / halo, 0.0, 1.0))
	for poi in pois:
		var p: POISystem.POI = poi as POISystem.POI
		if p.type != "pond":
			continue
		var pond_r: float = p.size.x * 0.5
		var halo_p: float = maxf(pond_r * 2.5, 1.0)   # midpoint of the 1.5-3x range
		var d2: float = Vector2(x - p.position.x, z - p.position.z).length()
		best = maxf(best, clampf(1.0 - d2 / halo_p, 0.0, 1.0))
	return best

## Distance-based shade proxy (0..1): 1 directly under a recorded tree, falling off
## across a canopy-sized radius. Generalizes the ad-hoc proximity check
## _scatter_understory_mushrooms() already did (grow fungi near a tree base) into a
## reusable query any candidate point can use, not just mushroom clumps.
func _shade_at(x: float, z: float) -> float:
	if _tree_positions.is_empty():
		return 0.0
	const SHADE_RADIUS: float = 12.0
	var best_d2: float = SHADE_RADIUS * SHADE_RADIUS
	for tp in _tree_positions:
		var d2: float = Vector2(x - tp.x, z - tp.z).length_squared()
		if d2 < best_d2:
			best_d2 = d2
	return clampf(1.0 - sqrt(best_d2) / SHADE_RADIUS, 0.0, 1.0)

## 1.0 inside [bounds[0], bounds[1]], decaying linearly to 0 across a margin equal
## to the range's own span outside it — a point just past the edge still gets a
## meaningful chance, a point far outside effectively never does.
func _niche_fit(bounds: Array, value: float) -> float:
	var lo: float = bounds[0]
	var hi: float = bounds[1]
	if value >= lo and value <= hi:
		return 1.0
	var span: float = maxf(hi - lo, 0.1)
	var dist: float = (lo - value) if value < lo else (value - hi)
	return clampf(1.0 - dist / span, 0.0, 1.0)

## Picks one scene from `pool` weighted by how well its FLORA_NICHES humidity/shade
## range matches (x, z). Un-registered entries (e.g. POOL_ROCKS) get a neutral
## weight, so calling this on a pool with no niche data is equivalent to the old
## uniform `_rng.randi() % pool.size()`. Soft-matches outside the registered range
## (see _niche_fit) instead of a hard cutoff, so a point with no perfect-fit species
## still gets something — avoids empty scatter holes.
func _pick_flora_for_point(pool: Array, x: float, z: float, pois: Array) -> PackedScene:
	# Judgment Day fix (2026-07-21): guard size()==0 SEPARATELY, before the
	# size<=1 fast path — `pool[0]` on an empty pool throws out-of-range. No
	# POOL_* is empty today, but this file's own history shows pools being
	# trimmed toward zero/one entries. Caller (_scatter_pool) checks for null
	# and skips placement for that point instead of crashing.
	if pool.size() == 0:
		push_error("_pick_flora_for_point called with an empty pool")
		return null
	if pool.size() <= 1:
		return pool[0]
	var humidity: float = _humidity_at(x, z, pois)
	var shade: float = _shade_at(x, z)
	var weights: Array[float] = []
	var total: float = 0.0
	for scene in pool:
		var w: float = 0.5   # neutral fallback for un-registered entries
		var niche: Variant = FLORA_NICHES.get((scene as PackedScene).resource_path, null)
		if niche != null:
			w = _niche_fit(niche["humidity"], humidity) * _niche_fit(niche["shade"], shade)
			w = maxf(w, 0.05)   # never fully zero out a species — keeps variety
		weights.append(w)
		total += w
	if total <= 0.0:
		return pool[_rng.randi() % pool.size()]
	var roll: float = _rng.randf() * total
	var acc: float = 0.0
	for i in range(pool.size()):
		acc += weights[i]
		if roll <= acc:
			return pool[i]
	return pool[pool.size() - 1]

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

	# Fix 4: rock_large scene for outcrop-zone anchors + mushroom for debris clumps
	var rock_large_scene: PackedScene = null
	const LARGE_ROCK_PATH: String = "res://assets/art/piso1_pradera/props/rocks/prop_rock_large_01.glb"
	if ResourceLoader.exists(LARGE_ROCK_PATH):
		rock_large_scene = load(LARGE_ROCK_PATH)

	# Fix 4: Count scales with map area.
	# Was: 180 pebbles + 60 clover. Now: 380 pebbles + 100 clover + 40 large outcrop rocks.
	# All capped by _rng save/restore → enemy placement unaffected.
	# Perf note: no colliders on any detail, shadows off, visibility_range 45m → rendered
	# count stays low. At 600m map the player sees ~few dozen at any time in the cull radius.
	var pebble_count: int = int(380.0 * _scale * _scale)
	var clover_count: int = int(100.0 * _scale * _scale)
	var outcrop_rock_count: int = int(40.0 * _scale * _scale)  # Fix 4: outcrop-biased large rocks

	# ── Pebbles / small rocks ────────────────────────────────────────────────
	if not detail_scenes.is_empty():
		for _i in range(pebble_count):
			var pos: Vector3 = _random_open_pos(pois, 4.0)   # small clearance — tiny props
			if pos == Vector3.INF:
				continue
			# Fix 1: skip ground-cover inside stream channel (same guard as grass).
			if not _stream_polylines.is_empty():
				var sd_gc: Array = _dist_sq_to_streams(pos.x, pos.z)
				if sd_gc[0] < STREAM_HALF_WIDTH * STREAM_HALF_WIDTH:
					# Burn the draws that _would_ have been consumed so RNG stays neutral.
					_rng.randi()               # scene selection
					_rng.randf_range(0.25, 0.7)  # s
					_rng.randf()               # rot_y
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
			# Fix 1: skip clover inside stream channel.
			if not _stream_polylines.is_empty():
				var sd_cl: Array = _dist_sq_to_streams(pos.x, pos.z)
				if sd_cl[0] < STREAM_HALF_WIDTH * STREAM_HALF_WIDTH:
					_rng.randf_range(0.5, 1.1)  # s
					_rng.randf()                # rot_y
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

	# ── Fix 4: Outcrop-biased large rocks + debris ───────────────────────────
	# Anchors the painted terrain to 3D geology: large rocks appear where the
	# outcrop noise is highest (same threshold as terrain geometry bumps).
	# No colliders, shadows off — purely visual depth cues.
	var flat_radius_gd: float = FLAT_RADIUS_BASE * _scale
	if rock_large_scene != null and _outcrop_noise != null:
		const OUTCROP_DETAIL_THRESHOLD: float = 0.60  # wider than geometry threshold → visible halo
		var placed_oc: int = 0
		var attempts_oc: int = 0
		var max_attempts_oc: int = outcrop_rock_count * 8
		while placed_oc < outcrop_rock_count and attempts_oc < max_attempts_oc:
			attempts_oc += 1
			var pos: Vector3 = _random_open_pos(pois, 6.0)
			if pos == Vector3.INF:
				continue
			# Skip stream channel (Fix 1 guard)
			if not _stream_polylines.is_empty():
				var sd_or: Array = _dist_sq_to_streams(pos.x, pos.z)
				if sd_or[0] < STREAM_HALF_WIDTH * STREAM_HALF_WIDTH:
					continue
			# Only on outcrop ridges outside spawn bowl
			if sqrt(pos.x * pos.x + pos.z * pos.z) < flat_radius_gd:
				continue
			var on_oc: float = _outcrop_noise.get_noise_2d(pos.x, pos.z)
			on_oc = (on_oc + 1.0) * 0.5
			if on_oc < OUTCROP_DETAIL_THRESHOLD:
				continue
			pos.y = get_terrain_height(pos.x, pos.z)
			# Scale varies with outcrop strength: stronger ridge → slightly larger rock
			var ramp_oc: float = (on_oc - OUTCROP_DETAIL_THRESHOLD) / (1.0 - OUTCROP_DETAIL_THRESHOLD)
			var s_oc: float = _rng.randf_range(0.3, 0.6 + ramp_oc * 0.5)
			var rot_oc: float = _rng.randf() * TAU
			var inst: Node3D = rock_large_scene.instantiate() as Node3D
			if inst == null:
				continue
			inst.transform = Transform3D(
				Basis(Vector3.UP, rot_oc).scaled(Vector3(s_oc, s_oc, s_oc)),
				pos
			)
			inst.add_to_group("grounded")
			_detail_apply_geo_flags(inst, 55.0)
			container.add_child(inst)
			placed_oc += 1

	# Restore RNG — enemy placement sequence unchanged
	_rng.state = rng_state
	print("[GroundDetail] pebbles+rocks budget=%d clover=%d outcrop_rocks=%d placed=%d" % [pebble_count, clover_count, outcrop_rock_count, container.get_child_count()])


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
			# Fix 1: skip grass inside the stream channel (grows ON TOP of water otherwise).
			# Guard: only test when polylines exist (no cost when no streams).
			if not _stream_polylines.is_empty():
				var sd: Array = _dist_sq_to_streams(x, z)
				if sd[0] < STREAM_HALF_WIDTH * STREAM_HALF_WIDTH:
					# Consume the same _rng draws that would have happened if not skipped,
					# so the RNG sequence after this blade is unchanged.
					_rng.randf()   # rot_y
					_rng.randf_range(-0.17, 0.17)  # tilt
					_rng.randf_range(0.8, 1.2)     # s
					_rng.randi()   # variant
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
## Task 2 (2026-07-20): candidate scene now comes from _pick_flora_for_point()
## instead of a flat `_rng.randi() % pool.size()` — the connective tissue reacts to
## humidity (near water) and shade (near trees) instead of picking blind. Passing a
## single-scene "pool" of size 1 into _place_instance reuses its existing
## trunk-position-recording / collider logic unchanged.
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
		var chosen: PackedScene = _pick_flora_for_point(pool, pos.x, pos.z, pois)
		if chosen == null:
			continue
		_place_instance([chosen], pos, scale_min, scale_max, parent, collider_kind)

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
		# D1: shadow-off + 120m visibility cull (dead trees = same tier as live trees)
		_scatter_apply_geo_flags(tree, 120.0)
		parent.add_child(tree)
		# Trunk collider — same shape as POOL_TREES instances (no extra _rng calls).
		var dt_body := StaticBody3D.new()
		dt_body.collision_layer = 1
		dt_body.collision_mask  = 0
		var dt_col := CollisionShape3D.new()
		var dt_cap := CapsuleShape3D.new()
		dt_cap.radius = _trunk_radius_for(tree) * s
		dt_cap.height = maxf(2.5 * s, dt_cap.radius * 2.0 + 0.01)
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

## D1 — Apply shadow-off + visibility range end to all MeshInstance3D descendants
## of a scatter instance.  Used for heavy scatter (trees, rocks, dead trees, giant
## tree) so they don't cast shadows and are culled beyond vis_range_end.
## Colliders are NOT touched — only geometry flags.
func _scatter_apply_geo_flags(root: Node3D, vis_range_end: float) -> void:
	var mi: MeshInstance3D = root as MeshInstance3D
	if mi != null:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = vis_range_end
		mi.visibility_range_end_margin = maxf(8.0, vis_range_end * 0.10)
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	for child in root.get_children():
		var child_node: Node3D = child as Node3D
		if child_node != null:
			_scatter_apply_geo_flags(child_node, vis_range_end)


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
	# D1: shadow-off + visibility range for scatter (trees, rocks, bushes).
	# Trees/giant-tree → 120m; rocks → 80m; bushes/ground → 60m.
	var vis_r: float = 60.0
	if collider_kind == "trunk":
		vis_r = 120.0
	elif collider_kind == "rock":
		vis_r = 80.0
	_scatter_apply_geo_flags(inst, vis_r)
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
				cap.radius = _trunk_radius_for(inst) * s
				# Godot needs height >= 2*radius or the capsule degenerates into a
				# sphere — which the widest buttressed trunks would otherwise hit.
				cap.height = maxf(2.5 * s, cap.radius * 2.0 + 0.01)
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

# ── Radio del colisionador de tronco, medido del propio mesh ──────────────────
# El 0.35 fijo que había acá venía de los árboles CC0 de tronco fino. Medido contra
# el pack del motor (leyendo la geometría de corteza de cada .glb), el radio real
# entre el suelo y la rodilla va de 0.22 (joven) a 0.70 (ancho, con contrafuertes).
# Un único número para todos o te deja entrar al tronco o te frena en el aire, y el
# problema vuelve cada vez que el motor entrega un árbol nuevo. Se lee del mesh.
#
# Solo la banda tobillo-rodilla: más arriba la corteza incluye ramas bajas que salen
# hacia UN lado, y una cápsula es simétrica — usar ese radio pondría una pared
# invisible en los otros tres costados.
const TRUNK_PROBE_H := 0.7
const TRUNK_RADIUS_FALLBACK := 0.35

var _trunk_radius_cache: Dictionary = {}


## Radio de corteza a la altura del cuerpo, en unidades del mesh (sin escalar).
## Cacheado por escena: son ~5 tipos de árbol, se mide una vez cada uno.
func _trunk_radius_for(inst: Node3D) -> float:
	var key: String = inst.scene_file_path
	if key != "" and _trunk_radius_cache.has(key):
		return float(_trunk_radius_cache[key])

	var best := 0.0
	for node in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for si in range(mi.mesh.get_surface_count()):
			var mat: Material = mi.mesh.surface_get_material(si)
			var mat_name := "" if mat == null else mat.resource_name.to_lower()
			# Las hojas no son algo con lo que uno choque: solo corteza.
			if not ("bark" in mat_name or "trunk" in mat_name):
				continue
			var arrays: Array = mi.mesh.surface_get_arrays(si)
			if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
				continue
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for v in verts:
				if v.y <= TRUNK_PROBE_H:
					best = maxf(best, Vector2(v.x, v.z).length())

	var measured := best > 0.0
	if not measured:
		best = TRUNK_RADIUS_FALLBACK
	if key != "":
		_trunk_radius_cache[key] = best
		# Una línea por TIPO de árbol, no por instancia. Sin esto, un fallback
		# silencioso al 0.35 se ve exactamente igual que antes del arreglo.
		if OS.is_debug_build():
			print("[trunk] %-42s r=%.3f %s" % [
				key.get_file(), best, "(medido)" if measured else "(FALLBACK — sin material de corteza)"])
	return best


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

		# Whether this POI's roster ended up with a sub-B+ enemy decides if its chest may
		# be a mimic (canon docs/balance/_mimic.md §2.1). Read off the enemies actually
		# spawned rather than the table, so a lucky all-sub-A roll stays mimic-free.
		var has_sub_b := false

		if p.enemy_count > 0:
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
				if enemy is BaseEnemy and (enemy as BaseEnemy).sub_tier >= BaseEnemy.SubTier.B:
					has_sub_b = true

		# Every camp answers to somebody. Exactly one leader — an alpha is singular by
		# definition, and two of them would just be two bandits with better stats.
		if p.type == "camp":
			var leader: CharacterBody3D = SCENE_BANDIT_LEADER.instantiate()
			add_child(leader)
			leader.global_position = p.position + Vector3(0.0, 0.8, 0.0)
			has_sub_b = true  # sub-tier C — his chest is worth guarding

		_spawn_poi_chest(p, has_sub_b)


## POI types that hold a chest. The entrance always gets one and never a mimic: it is
## where the player learns "chest = loot", and canon (_mimic.md §2.1) refuses to break
## that lesson with a 0% gate on the intro arena.
const CHEST_POI_TYPES: Array[String] = ["entrance", "ruins", "camp", "giant_tree", "altar", "well"]

## Canon _mimic.md §2.1: Floor 1, arena with >=1 sub-B enemy -> 5%. Intro arena -> 0%.
const MIMIC_CHANCE_SUB_B: float = 0.05

## Canon _mimic.md §2.2: at most ONE mimic alive per scene. A roll that loses to the
## cooldown does NOT re-roll — a normal chest spawns in its place.
var _mimic_spawned := false


## The mimic gate, canon _mimic.md §2.1-2.2. Static and pure so the rule can be checked
## without generating a 600x600m level: `roll` is the caller's RNG draw in [0, 1).
static func should_chest_be_mimic(
	poi_type: String, has_sub_b: bool, mimic_already_spawned: bool, roll: float
) -> bool:
	# §2.1 — the intro arena is where the player learns "chest = loot". Never betray it.
	if poi_type == "entrance":
		return false
	# §2.1 — a mimic only hides among chests an arena's sub-B+ enemies are guarding.
	if not has_sub_b:
		return false
	# §2.2 — one mimic per scene, and losing to the cooldown does NOT re-roll:
	# a normal chest takes its place.
	if mimic_already_spawned:
		return false
	return roll < MIMIC_CHANCE_SUB_B


func _spawn_poi_chest(p: POISystem.POI, has_sub_b: bool) -> void:
	if not CHEST_POI_TYPES.has(p.type):
		return

	var spot: Vector3 = p.position + Vector3(
		_rng.randf_range(-p.size.x * 0.2, p.size.x * 0.2),
		0.0,
		_rng.randf_range(-p.size.y * 0.2, p.size.y * 0.2)
	)
	spot.y = get_terrain_height(spot.x, spot.z) + 0.4

	var is_mimic: bool = should_chest_be_mimic(p.type, has_sub_b, _mimic_spawned, _rng.randf())

	var scene_path := "res://scenes/enemy/mimic_chest.tscn" if is_mimic else "res://scenes/loot/loot_chest.tscn"
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("floor1_prairie: no se pudo cargar %s" % scene_path)
		return

	var chest: Node3D = packed.instantiate()
	if is_mimic:
		_mimic_spawned = true
	else:
		# A guarded POI is worth more than an unguarded one — the risk IS the price.
		(chest as LootChest).chest_tier = (
			LootChest.ChestTier.RARE if has_sub_b else LootChest.ChestTier.COMMON
		)

	add_child(chest)
	chest.global_position = spot

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
			# Spiders live in the dark the ruins make — the one place on an open prairie
			# where an ambush predator has anywhere to wait.
			return [
				[0.25, SCENE_RAT],
				[0.45, SCENE_BANDIT_MELEE],
				[0.65, SCENE_BANDIT_ARCHER],
				[0.85, SCENE_SPIDER],
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
		"pond":
			# The water's edge belongs to the things that live in it. Frogs sit here;
			# slimes gather at the water. Nothing dry-land spawns on the shoreline.
			return [
				[0.55, SCENE_FROG],
				[1.00, SCENE_SLIME],
			]
		_:
			# Open field. The jabali is its territorial predator — rare, because a boar
			# you meet every hundred metres is a mob, not a territory-holder.
			return [
				[0.35, SCENE_SLIME],
				[0.55, SCENE_BIRD],
				[0.75, SCENE_RAT],
				[0.90, SCENE_SNAKE],
				[1.00, SCENE_JABALI],
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

## DP_ToonGrounded shader resource — loaded once, shared across all _make_material calls.
## Lazy-loaded on first use; null means the shader file is not yet imported (falls back
## to a plain StandardMaterial3D so the map still runs without the shader).
var _toon_grounded_shader: Shader = null
var _toon_grounded_shader_tried: bool = false

## _make_material() — THE unification chokepoint for all procedural/CSG surfaces.
## Applies DP_ToonGrounded ShaderMaterial: 3-band toon ramp, cool non-black shadow,
## matte, optional warm gold rim. Preserves each mesh's albedo via albedo_color param.
## Falls back to a plain StandardMaterial3D if the shader is not yet imported.
## gltf scatter packs keep their own materials (future material_override pass extends this).
func _make_material(color: Color) -> Material:
	# Lazy-load the shader once
	if not _toon_grounded_shader_tried:
		_toon_grounded_shader_tried = true
		const SHADER_PATH: String = "res://scenes/levels/dp_toon_grounded.gdshader"
		if ResourceLoader.exists(SHADER_PATH):
			_toon_grounded_shader = load(SHADER_PATH) as Shader

	if _toon_grounded_shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = _toon_grounded_shader
		mat.set_shader_parameter("albedo_color", color)
		mat.set_shader_parameter("use_vertex_color", false)
		return mat

	# Shader not available — plain fallback so the map never fails to run
	var mat := StandardMaterial3D.new()
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
	if not OS.is_debug_build():
		return
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
	# 14m ahead so the 3m-radius capsule cannot overlap the player on spawn.
	# y+0.5 keeps the boss grounded without capsule-edge touching the player above.
	king.global_position = player.global_position + fwd.normalized() * 14.0 + Vector3(0, 0.5, 0)
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
