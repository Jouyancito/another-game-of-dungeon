extends Node3D

## Floor 1 — Prairie
## Toda la geometría y los actores se generan por código.
## La escena .tscn solo tiene: piso, luz y ambiente.
##
## Cambiá world_seed desde el inspector de Godot para ver distintos layouts.

@export var world_seed: int = 12345

# Tamaño del prototipo — 200×200m (escalar aquí no rompe nada)
const MAP_SIZE: Vector2 = Vector2(200.0, 200.0)

# --- Colores ---
const COLOR_FLOOR: Color       = Color(0.290, 0.478, 0.180, 1)
const COLOR_TRUNK: Color       = Color(0.361, 0.227, 0.118, 1)
const COLOR_CANOPY: Color      = Color(0.176, 0.353, 0.118, 1)
const COLOR_TALL_GRASS: Color  = Color(0.118, 0.290, 0.055, 1)
const COLOR_ROCK: Color        = Color(0.502, 0.502, 0.502, 1)
const COLOR_RUIN: Color        = Color(0.627, 0.627, 0.627, 1)
const COLOR_BOSS_WALL: Color   = Color(0.314, 0.314, 0.314, 1)
const COLOR_PATH: Color        = Color(0.420, 0.259, 0.149, 1)

# Escenas de actores
var SCENE_PLAYER: PackedScene  # Se resuelve en _ready() según la clase elegida
const SCENE_ENEMY: PackedScene   = preload("res://scenes/enemy/enemy_basic.tscn")
const SCENE_HUD: PackedScene     = preload("res://scenes/hud/hud.tscn")

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	# Resolver escena del jugador según la clase elegida
	var class_path = GameManager.selected_class_scene
	if not ResourceLoader.exists(class_path):
		class_path = "res://scenes/player/player.tscn"
	SCENE_PLAYER = load(class_path)

	_rng.seed = world_seed

	# 1. Sistema de POIs
	var poi_system: POISystem = POISystem.new()
	var pois: Array = poi_system.generate_pois(world_seed, MAP_SIZE)

	# 2. Generar zonas
	for poi in pois:
		var p: POISystem.POI = poi as POISystem.POI
		match p.type:
			"entrance": _build_entrance(p)
			"ruins":    _build_ruins(p)
			"boss":     _build_boss_arena(p)

	# 3. Decoración del campo abierto (árboles, rocas, pasto)
	_generate_field_decoration(pois)

	# 4. Instanciar enemigos en zonas de combate + patrulladores en campo
	_spawn_zone_enemies(pois)
	_spawn_patrol_enemies(pois)

	# 5. Instanciar jugador en la entrada
	var entrance_pos: Vector3 = _find_entrance_pos(pois)
	var player: CharacterBody3D = SCENE_PLAYER.instantiate() as CharacterBody3D
	add_child(player)
	player.global_position = entrance_pos + Vector3(0, 0.9, 0)

	# 6. HUD — conectar al jugador explícitamente
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

# ── Helpers ────────────────────────────────────────────────────────────────────

# ── Border system ─────────────────────────────────────────────────────────────

func _precalculate_border() -> void:
	_border_noise_offsets.clear()
	var noise_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	noise_rng.seed = world_seed + 9999
	for i in range(360):
		var angle_rad: float = deg_to_rad(float(i))
		# Simple noise: suma de senos con diferentes frecuencias
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
	var border_r: float = _get_border_radius_at_angle(angle_deg)
	return dist < border_r - 10.0  # 10m de margen de seguridad

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
	add_child(ceiling)

func _build_diamond_light() -> void:
	# Diamante emisivo en el techo
	var diamond: CSGBox3D = CSGBox3D.new()
	diamond.name = "DiamondLight"
	diamond.size = Vector3(DIAMOND_SIZE, DIAMOND_SIZE * 1.5, DIAMOND_SIZE)
	diamond.position = Vector3(0, DIAMOND_HEIGHT, 0)
	diamond.rotation.y = deg_to_rad(45)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = COLOR_DIAMOND
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.7)
	mat.emission_energy_multiplier = 3.0
	diamond.material_override = mat
	diamond.use_collision = false
	add_child(diamond)

	# OmniLight para que el diamante ilumine
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
		var px: float = cos(angle) * dist
		var pz: float = sin(angle) * dist
		var pos: Vector3 = Vector3(px, 0, pz)
		if not _is_inside_border(pos):
			continue
		var height: float = _rng.randf_range(PILLAR_MIN_HEIGHT, PILLAR_MAX_HEIGHT)
		var radius: float = _rng.randf_range(2.0, 4.0)

		var pillar: CSGCylinder3D = CSGCylinder3D.new()
		pillar.name = "LandmarkPillar%d" % i
		pillar.radius = radius
		pillar.height = height
		pillar.sides = 8
		pillar.use_collision = true
		pillar.material_override = _make_material(COLOR_PILLAR)
		pillar.position = pos + Vector3(0, height * 0.5, 0)
		add_child(pillar)

# ── POI builders ──────────────────────────────────────────────────────────────
>>>>>>> 1807c1e (feat: add practice arena and full game modes with menu selection)

func _find_entrance_pos(pois: Array) -> Vector3:
	for poi in pois:
		var p: POISystem.POI = poi as POISystem.POI
		if p.is_entrance:
			return p.position
	return Vector3.ZERO

# ── Zone builders ──────────────────────────────────────────────────────────────

func _build_entrance(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position
	var sz: Vector2 = poi.size

	_add_csg_box(
		"EntranceStoneN",
		pos + Vector3(0, 0.4, -sz.y * 0.5),
		Vector3(sz.x, 0.8, 0.4),
		COLOR_ROCK, true
	)
	_add_csg_box(
		"EntranceStoneS",
		pos + Vector3(0, 0.4, sz.y * 0.5),
		Vector3(sz.x, 0.8, 0.4),
		COLOR_ROCK, true
	)

	_add_csg_box(
		"EntranceGround",
		pos + Vector3(0, 0.01, 0),
		Vector3(sz.x, 0.02, sz.y),
		COLOR_PATH, false
	)

func _build_ruins(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position
	var sz: Vector2 = poi.size

	_add_csg_box("RuinsGround", pos + Vector3(0, 0.01, 0),
		Vector3(sz.x, 0.02, sz.y), COLOR_RUIN, false)

	# Muros caídos — 4 fragmentos con offset y tamaño
	var walls: Array[Dictionary] = [
		{"offset": Vector3(-sz.x * 0.3, 0.75, -sz.y * 0.3), "size": Vector3(6, 1.5, 0.6)},
		{"offset": Vector3( sz.x * 0.2, 1.0,  -sz.y * 0.1), "size": Vector3(0.6, 2.0, 5)},
		{"offset": Vector3(-sz.x * 0.1, 0.6,   sz.y * 0.3), "size": Vector3(5, 1.2, 0.6)},
		{"offset": Vector3( sz.x * 0.35, 0.5,  sz.y * 0.1), "size": Vector3(0.6, 1.0, 4)},
	]
	for i in range(walls.size()):
		var wall_offset: Vector3 = walls[i]["offset"]
		var wall_size: Vector3 = walls[i]["size"]
		_add_csg_box(
			"RuinWall%d" % i,
			pos + wall_offset,
			wall_size,
			COLOR_RUIN, true
		)

	# Pocito (cylinder)
	var well: CSGCylinder3D = CSGCylinder3D.new()
	well.name = "RuinsWell"
	well.radius = 0.8
	well.height = 1.0
	well.use_collision = true
	well.material_override = _make_material(COLOR_ROCK)
	well.position = pos + Vector3(sz.x * 0.1, 0.5, -sz.y * 0.1)
	add_child(well)

	# Rocas dispersas
	var rock_positions: Array[Vector3] = [
		Vector3(-sz.x * 0.25, 0.35, sz.y * 0.2),
		Vector3( sz.x * 0.3,  0.3,  sz.y * 0.35),
	]
	for i in range(rock_positions.size()):
		_add_csg_box("RuinsRock%d" % i, pos + rock_positions[i],
			Vector3(1.0, 0.7, 0.9), COLOR_ROCK, true)

func _build_boss_arena(poi: POISystem.POI) -> void:
	var pos: Vector3 = poi.position
	var sz: Vector2 = poi.size
	var hw: float = sz.x * 0.5
	var hd: float = sz.y * 0.5
	var wall_h: float = 4.0
	var wall_t: float = 0.8

	_add_csg_box("BossGround", pos + Vector3(0, 0.01, 0),
		Vector3(sz.x, 0.02, sz.y), COLOR_BOSS_WALL, false)

	# Paredes N, S, E
	_add_csg_box("BossWallN", pos + Vector3(0, wall_h * 0.5, -hd),
		Vector3(sz.x, wall_h, wall_t), COLOR_BOSS_WALL, true)
	_add_csg_box("BossWallS", pos + Vector3(0, wall_h * 0.5, hd),
		Vector3(sz.x, wall_h, wall_t), COLOR_BOSS_WALL, true)
	_add_csg_box("BossWallE", pos + Vector3(hw, wall_h * 0.5, 0),
		Vector3(wall_t, wall_h, sz.y), COLOR_BOSS_WALL, true)

	# Pared W con apertura central (entrada de 6m)
	var gate_w: float = 6.0
	var side_len: float = (sz.y - gate_w) * 0.5
	_add_csg_box("BossWallW_N", pos + Vector3(-hw, wall_h * 0.5, -(gate_w * 0.5 + side_len * 0.5)),
		Vector3(wall_t, wall_h, side_len), COLOR_BOSS_WALL, true)
	_add_csg_box("BossWallW_S", pos + Vector3(-hw, wall_h * 0.5, gate_w * 0.5 + side_len * 0.5),
		Vector3(wall_t, wall_h, side_len), COLOR_BOSS_WALL, true)
	_add_csg_box("BossWallW_Top", pos + Vector3(-hw, wall_h - 0.5, 0),
		Vector3(wall_t, 1.0, gate_w), COLOR_BOSS_WALL, true)

	# Escombros interiores como cobertura
	var rubble_positions: Array[Vector3] = [
		Vector3(-hw * 0.4, 0.4, -hd * 0.4),
		Vector3( hw * 0.3, 0.5,  hd * 0.5),
		Vector3( 0.0,      0.4, -hd * 0.6),
	]
	for i in range(rubble_positions.size()):
		_add_csg_box("BossRubble%d" % i, pos + rubble_positions[i],
			Vector3(3, 0.8, 1.2), COLOR_BOSS_WALL, true)

# ── Field decoration ───────────────────────────────────────────────────────────

func _generate_field_decoration(pois: Array) -> void:
	var tree_count: int = 40
	for i in range(tree_count):
		var tree_pos: Vector3 = _random_open_pos(pois, 25.0)
		if tree_pos == Vector3.INF:
			continue
		_spawn_tree("FieldTree%d" % i, tree_pos)

	var rock_count: int = 30
	for i in range(rock_count):
		var rock_pos: Vector3 = _random_open_pos(pois, 18.0)
		if rock_pos == Vector3.INF:
			continue
		var rsize: Vector3 = Vector3(
			_rng.randf_range(0.8, 2.0),
			_rng.randf_range(0.5, 1.2),
			_rng.randf_range(0.8, 1.8)
		)
		_add_csg_box("FieldRock%d" % i,
			rock_pos + Vector3(0, rsize.y * 0.5, 0), rsize, COLOR_ROCK, true)

	var grass_count: int = 25
	for i in range(grass_count):
		var grass_pos: Vector3 = _random_open_pos(pois, 15.0)
		if grass_pos == Vector3.INF:
			continue
		var gh: float = _rng.randf_range(1.0, 1.5)
		var gw: float = _rng.randf_range(1.5, 3.5)
		var gd: float = _rng.randf_range(1.5, 3.5)
		_add_csg_box("FieldGrass%d" % i,
			grass_pos + Vector3(0, gh * 0.5, 0),
			Vector3(gw, gh, gd), COLOR_TALL_GRASS, false)

func _random_open_pos(pois: Array, min_distance_from_poi: float) -> Vector3:
	var half_x: float = MAP_SIZE.x * 0.5 - 10.0
	var half_z: float = MAP_SIZE.y * 0.5 - 10.0
	for _t in range(50):
		var rx: float = _rng.randf_range(-half_x, half_x)
		var rz: float = _rng.randf_range(-half_z, half_z)
		var candidate: Vector3 = Vector3(rx, 0, rz)
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
	var trunk_h: float = _rng.randf_range(2.5, 4.0)
	var trunk_r: float = _rng.randf_range(0.2, 0.35)
	var canopy_size: float = _rng.randf_range(2.5, 4.5)

	var trunk: CSGCylinder3D = CSGCylinder3D.new()
	trunk.name = base_name + "Trunk"
	trunk.radius = trunk_r
	trunk.height = trunk_h
	trunk.use_collision = true
	trunk.material_override = _make_material(COLOR_TRUNK)
	trunk.position = tree_pos + Vector3(0, trunk_h * 0.5, 0)
	add_child(trunk)

	_add_csg_box(
		base_name + "Canopy",
		tree_pos + Vector3(0, trunk_h + canopy_size * 0.5, 0),
		Vector3(canopy_size, canopy_size, canopy_size),
		COLOR_CANOPY, true
	)

# ── Enemy spawning ─────────────────────────────────────────────────────────────

func _spawn_zone_enemies(pois: Array) -> void:
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
			var enemy: CharacterBody3D = SCENE_ENEMY.instantiate() as CharacterBody3D
			add_child(enemy)
			enemy.global_position = p.position + offset

func _spawn_patrol_enemies(pois: Array) -> void:
	var count: int = _rng.randi_range(2, 3)
	for i in range(count):
		var patrol_pos: Vector3 = _random_open_pos(pois, 30.0)
		if patrol_pos == Vector3.INF:
			continue
		var enemy: CharacterBody3D = SCENE_ENEMY.instantiate() as CharacterBody3D
		add_child(enemy)
		enemy.global_position = patrol_pos + Vector3(0, 0.8, 0)

# ── CSG factory helpers ────────────────────────────────────────────────────────

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
