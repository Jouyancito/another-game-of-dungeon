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
const DIAMOND_HEIGHT: float = 38.0
const DIAMOND_SIZE: float = 8.0

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
const COLOR_DIAMOND: Color     = Color(1.0, 0.95, 0.8)
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

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _border_noise_offsets: Array[float] = []

# ── Ready ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	var class_path: String = GameManager.selected_class_scene
	if not ResourceLoader.exists(class_path):
		class_path = "res://scenes/player/player.tscn"
	SCENE_PLAYER = load(class_path)

	_rng.seed = world_seed
	_precalculate_border()

	# 1. Atmósfera
	_build_ceiling()
	_build_diamond_light()
	_build_landmark_pillars()

	# 2. Borde orgánico
	_build_organic_border()

	# 3. POIs
	var poi_system: POISystem = POISystem.new()
	var pois: Array = poi_system.generate_pois(world_seed, MAP_SIZE, _is_inside_border)

	for poi in pois:
		var p: POISystem.POI = poi as POISystem.POI
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

	# 5. Enemigos
	_spawn_poi_enemies(pois)
	_spawn_field_enemies(pois)

	# 6. Jugador
	var entrance_pos: Vector3 = _find_entrance_pos(pois)
	var player: CharacterBody3D = SCENE_PLAYER.instantiate() as CharacterBody3D
	add_child(player)
	player.global_position = entrance_pos + Vector3(0, 0.9, 0)

	# 7. HUD
	var hud: CanvasLayer = SCENE_HUD.instantiate() as CanvasLayer
	add_child(hud)
	if hud.has_method("connect_to_player"):
		hud.connect_to_player(player)

	# 8. UI — pausa, ventana de personaje, inventario
	var pause_menu = preload("res://scenes/ui/pause_menu.tscn").instantiate()
	add_child(pause_menu)

	var character_window = preload("res://scenes/ui/character_window.tscn").instantiate()
	add_child(character_window)

	GameManager.player_inventory = Inventory.new()
	GameManager.player_coins = 0

	# Arma inicial según clase
	var starter = {
		"res://scenes/player/player.tscn": "sword_rusty",
		"res://scenes/player/mage.tscn": "book_apprentice",
		"res://scenes/player/archer.tscn": "bow_short",
		"res://scenes/player/necromancer.tscn": "wand_cracked",
		"res://scenes/player/cleric.tscn": "garrote_wood",
	}
	var weapon: String = starter.get(GameManager.selected_class_scene, "")
	if weapon != "":
		GameManager.player_inventory.auto_place_item(weapon)
	GameManager.player_inventory.auto_place_item("potion_hp_small", 2)

	var inventory_ui = preload("res://scenes/ui/inventory_ui.tscn").instantiate()
	inventory_ui.inventory = GameManager.player_inventory
	add_child(inventory_ui)

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
	ceiling.material_override = _make_material(COLOR_CEILING)
	ceiling.use_collision = false
	# CLAVE: no proyectar sombras — si no, el techo oscurece todo el piso
	ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ceiling)

func _build_diamond_light() -> void:
	var diamond: CSGBox3D = CSGBox3D.new()
	diamond.name = "DiamondLight"
	diamond.size = Vector3(DIAMOND_SIZE, DIAMOND_SIZE * 1.5, DIAMOND_SIZE)
	diamond.position = Vector3(0, DIAMOND_HEIGHT, 0)
	diamond.rotation.y = deg_to_rad(45)
	diamond.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = COLOR_DIAMOND
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.7)
	mat.emission_energy_multiplier = 3.0
	diamond.material_override = mat
	diamond.use_collision = false
	add_child(diamond)

	var light: OmniLight3D = OmniLight3D.new()
	light.name = "DiamondOmniLight"
	light.light_color = Color(1.0, 0.92, 0.75)
	light.light_energy = 0.8
	light.omni_range = 300.0
	light.omni_attenuation = 1.5
	light.shadow_enabled = false
	light.position = Vector3(0, DIAMOND_HEIGHT - 2.0, 0)
	add_child(light)

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

# ── Vegetation ────────────────────────────────────────────────────────────────

func _generate_vegetation(pois: Array) -> void:
	for i in range(TREE_COUNT):
		var tree_pos: Vector3 = _random_open_pos(pois, 20.0)
		if tree_pos == Vector3.INF:
			continue
		_spawn_tree("Tree%d" % i, tree_pos)

	for i in range(ROCK_COUNT):
		var rock_pos: Vector3 = _random_open_pos(pois, 12.0)
		if rock_pos == Vector3.INF:
			continue
		var rs: Vector3 = Vector3(
			_rng.randf_range(0.6, 2.5),
			_rng.randf_range(0.4, 1.5),
			_rng.randf_range(0.6, 2.0)
		)
		_add_csg_box("Rock%d" % i, rock_pos + Vector3(0, rs.y * 0.5, 0), rs,
			COLOR_ROCK if _rng.randf() > 0.3 else COLOR_ROCK_DARK, true)

	for i in range(TALL_GRASS_COUNT):
		var gpos: Vector3 = _random_open_pos(pois, 8.0)
		if gpos == Vector3.INF:
			continue
		var gh: float = _rng.randf_range(0.8, 1.8)
		_add_csg_box("TallGrass%d" % i, gpos + Vector3(0, gh * 0.5, 0),
			Vector3(_rng.randf_range(1.0, 3.0), gh, _rng.randf_range(1.0, 3.0)),
			COLOR_TALL_GRASS, false)

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

func _spawn_tree(base_name: String, tree_pos: Vector3) -> void:
	var trunk_h: float = _rng.randf_range(2.5, 5.0)
	var trunk_r: float = _rng.randf_range(0.15, 0.35)
	var canopy_size: float = _rng.randf_range(2.5, 5.0)

	var trunk: CSGCylinder3D = CSGCylinder3D.new()
	trunk.name = base_name + "Trunk"
	trunk.radius = trunk_r
	trunk.height = trunk_h
	trunk.sides = 6
	trunk.use_collision = true
	trunk.material_override = _make_material(COLOR_TRUNK)
	trunk.position = tree_pos + Vector3(0, trunk_h * 0.5, 0)
	add_child(trunk)

	_add_csg_box(base_name + "Canopy",
		tree_pos + Vector3(0, trunk_h + canopy_size * 0.4, 0),
		Vector3(canopy_size, canopy_size * 0.8, canopy_size),
		COLOR_CANOPY if _rng.randf() > 0.3 else COLOR_CANOPY_DARK, false)

# ── Enemy spawning ────────────────────────────────────────────────────────────

func _spawn_poi_enemies(pois: Array) -> void:
	for poi in pois:
		var p: POISystem.POI = poi as POISystem.POI
		if p.enemy_count <= 0:
			continue
		for i in range(p.enemy_count):
			var offset: Vector3 = Vector3(
				_rng.randf_range(-p.size.x * 0.3, p.size.x * 0.3),
				0.8,
				_rng.randf_range(-p.size.y * 0.3, p.size.y * 0.3)
			)
			var enemy: CharacterBody3D = _pick_enemy_scene().instantiate() as CharacterBody3D
			add_child(enemy)
			enemy.global_position = p.position + offset

func _spawn_field_enemies(pois: Array) -> void:
	for i in range(FIELD_ENEMY_COUNT):
		var epos: Vector3 = _random_open_pos(pois, 25.0)
		if epos == Vector3.INF:
			continue
		var enemy: CharacterBody3D = _pick_enemy_scene().instantiate() as CharacterBody3D
		add_child(enemy)
		enemy.global_position = epos + Vector3(0, 0.8, 0)

	for i in range(PATROL_ENEMY_COUNT):
		var ppos: Vector3 = _random_open_pos(pois, 40.0)
		if ppos == Vector3.INF:
			continue
		var enemy: CharacterBody3D = SCENE_ENEMY_BASIC.instantiate() as CharacterBody3D
		add_child(enemy)
		enemy.global_position = ppos + Vector3(0, 0.8, 0)

func _pick_enemy_scene() -> PackedScene:
	var roll: float = _rng.randf()
	if roll < 0.45:
		return SCENE_SLIME
	elif roll < 0.80:
		return SCENE_ENEMY_BASIC
	else:
		return SCENE_BIRD

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
