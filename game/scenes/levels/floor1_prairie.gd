extends Node3D

## Floor 1 — Prairie
## Toda la geometría y los actores se generan por código.
## La escena .tscn solo tiene: piso, luz y ambiente.
##
## Cambiá world_seed desde el inspector de Godot para ver distintos layouts.

@export var world_seed: int = 12345

# Tamaño del prototipo — 200×200m (escalar aquí no rompe nada)
const MAP_SIZE := Vector2(200.0, 200.0)

# --- Colores ---
const COLOR_FLOOR       := Color(0.290, 0.478, 0.180, 1)   # #4A7A2E
const COLOR_TRUNK       := Color(0.361, 0.227, 0.118, 1)   # #5C3A1E
const COLOR_CANOPY      := Color(0.176, 0.353, 0.118, 1)   # #2D5A1E
const COLOR_TALL_GRASS  := Color(0.118, 0.290, 0.055, 1)   # #1E4A0E
const COLOR_ROCK        := Color(0.502, 0.502, 0.502, 1)   # #808080
const COLOR_RUIN        := Color(0.627, 0.627, 0.627, 1)   # #A0A0A0
const COLOR_BOSS_WALL   := Color(0.314, 0.314, 0.314, 1)   # #505050
const COLOR_PATH        := Color(0.420, 0.259, 0.149, 1)   # #6B4226

# Escenas de actores
const SCENE_PLAYER  := preload("res://scenes/player/player.tscn")
const SCENE_ENEMY   := preload("res://scenes/enemy/enemy_basic.tscn")
const SCENE_HUD     := preload("res://scenes/hud/hud.tscn")

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = world_seed

	# 1. Sistema de POIs
	var poi_system := POISystem.new()
	var pois := poi_system.generate_pois(world_seed, MAP_SIZE)

	# 2. Generar zonas
	for poi in pois:
		match poi.type:
			"entrance": _build_entrance(poi)
			"ruins":    _build_ruins(poi)
			"boss":     _build_boss_arena(poi)

	# 3. Decoración del campo abierto (árboles, rocas, pasto)
	_generate_field_decoration(pois)

	# 4. Instanciar enemigos en zonas de combate + patrulladores en campo
	_spawn_zone_enemies(pois)
	_spawn_patrol_enemies(pois)

	# 5. Instanciar jugador en la entrada
	var entrance_pos := _find_entrance_pos(pois)
	var player := SCENE_PLAYER.instantiate()
	add_child(player)
	player.global_position = entrance_pos + Vector3(0, 0.9, 0)

	# 6. HUD
	var hud := SCENE_HUD.instantiate()
	add_child(hud)

# ── Helpers ────────────────────────────────────────────────────────────────────

func _find_entrance_pos(pois: Array) -> Vector3:
	for poi in pois:
		if (poi as POISystem.POI).is_entrance:
			return (poi as POISystem.POI).position
	return Vector3.ZERO

# ── Zone builders ──────────────────────────────────────────────────────────────

func _build_entrance(poi: POISystem.POI) -> void:
	var pos := poi.position
	var sz  := poi.size

	# Marcadores de entrada: dos piedras al norte y sur
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

	# Suelo diferenciado (sendero de tierra)
	_add_csg_box(
		"EntranceGround",
		pos + Vector3(0, 0.01, 0),
		Vector3(sz.x, 0.02, sz.y),
		COLOR_PATH, false
	)

func _build_ruins(poi: POISystem.POI) -> void:
	var pos := poi.position
	var sz  := poi.size

	# Suelo de zona
	_add_csg_box("RuinsGround", pos + Vector3(0, 0.01, 0),
		Vector3(sz.x, 0.02, sz.y), COLOR_RUIN, false)

	# Muros caídos — 4 fragmentos con variación posicional relativa
	var wall_offsets := [
		Vector3(-sz.x * 0.3, 0.75, -sz.y * 0.3),
		Vector3( sz.x * 0.2, 1.0,  -sz.y * 0.1),
		Vector3(-sz.x * 0.1, 0.6,   sz.y * 0.3),
		Vector3( sz.x * 0.35, 0.5,  sz.y * 0.1),
	]
	var wall_sizes := [
		Vector3(6, 1.5, 0.6),
		Vector3(0.6, 2.0, 5),
		Vector3(5, 1.2, 0.6),
		Vector3(0.6, 1.0, 4),
	]
	for i in range(wall_offsets.size()):
		_add_csg_box(
			"RuinWall%d" % i,
			pos + wall_offsets[i],
			wall_sizes[i],
			COLOR_RUIN, true
		)

	# Pocito (cylinder)
	var well := CSGCylinder3D.new()
	well.name = "RuinsWell"
	well.radius = 0.8
	well.height = 1.0
	well.use_collision = true
	well.material_override = _make_material(COLOR_ROCK)
	well.position = pos + Vector3(sz.x * 0.1, 0.5, -sz.y * 0.1)
	add_child(well)

	# Rocas dispersas
	var rock_off := [
		Vector3(-sz.x * 0.25, 0.35, sz.y * 0.2),
		Vector3( sz.x * 0.3,  0.3,  sz.y * 0.35),
	]
	for i in range(rock_off.size()):
		_add_csg_box("RuinsRock%d" % i, pos + rock_off[i],
			Vector3(1.0, 0.7, 0.9), COLOR_ROCK, true)

func _build_boss_arena(poi: POISystem.POI) -> void:
	var pos := poi.position
	var sz  := poi.size
	var hw  := sz.x * 0.5   # half-width
	var hd  := sz.y * 0.5   # half-depth
	var wall_h := 4.0
	var wall_t := 0.8

	# Suelo
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
	var gate_w := 6.0
	var side_len := (sz.y - gate_w) * 0.5
	_add_csg_box("BossWallW_N", pos + Vector3(-hw, wall_h * 0.5, -(gate_w * 0.5 + side_len * 0.5)),
		Vector3(wall_t, wall_h, side_len), COLOR_BOSS_WALL, true)
	_add_csg_box("BossWallW_S", pos + Vector3(-hw, wall_h * 0.5, gate_w * 0.5 + side_len * 0.5),
		Vector3(wall_t, wall_h, side_len), COLOR_BOSS_WALL, true)
	# Dintel superior
	_add_csg_box("BossWallW_Top", pos + Vector3(-hw, wall_h - 0.5, 0),
		Vector3(wall_t, 1.0, gate_w), COLOR_BOSS_WALL, true)

	# Escombros interiores como cobertura
	var rubble_offsets := [
		Vector3(-hw * 0.4, 0.4, -hd * 0.4),
		Vector3( hw * 0.3, 0.5,  hd * 0.5),
		Vector3( 0.0,      0.4, -hd * 0.6),
	]
	for i in range(rubble_offsets.size()):
		_add_csg_box("BossRubble%d" % i, pos + rubble_offsets[i],
			Vector3(3, 0.8, 1.2), COLOR_BOSS_WALL, true)

# ── Field decoration ───────────────────────────────────────────────────────────

func _generate_field_decoration(pois: Array) -> void:
	# Árboles cada 20-30m aleatorios
	var tree_count := 40
	for i in range(tree_count):
		var pos := _random_open_pos(pois, 25.0)
		if pos == Vector3.INF:
			continue
		_spawn_tree("FieldTree%d" % i, pos)

	# Rocas cada 15-25m aleatorios
	var rock_count := 30
	for i in range(rock_count):
		var pos := _random_open_pos(pois, 18.0)
		if pos == Vector3.INF:
			continue
		var rsize := Vector3(
			_rng.randf_range(0.8, 2.0),
			_rng.randf_range(0.5, 1.2),
			_rng.randf_range(0.8, 1.8)
		)
		_add_csg_box("FieldRock%d" % i,
			pos + Vector3(0, rsize.y * 0.5, 0), rsize, COLOR_ROCK, true)

	# Pasto alto en clusters
	var grass_count := 25
	for i in range(grass_count):
		var pos := _random_open_pos(pois, 15.0)
		if pos == Vector3.INF:
			continue
		var gh := _rng.randf_range(1.0, 1.5)
		var gw := _rng.randf_range(1.5, 3.5)
		var gd := _rng.randf_range(1.5, 3.5)
		_add_csg_box("FieldGrass%d" % i,
			pos + Vector3(0, gh * 0.5, 0),
			Vector3(gw, gh, gd), COLOR_TALL_GRASS, false)

## Retorna una posición aleatoria dentro del mapa con margen mínimo de los POIs.
## Devuelve Vector3.INF si no encontró posición libre en 50 intentos.
func _random_open_pos(pois: Array, min_distance_from_poi: float) -> Vector3:
	var half_x := MAP_SIZE.x * 0.5 - 10.0
	var half_z := MAP_SIZE.y * 0.5 - 10.0
	for _t in range(50):
		var rx := _rng.randf_range(-half_x, half_x)
		var rz := _rng.randf_range(-half_z, half_z)
		var candidate := Vector3(rx, 0, rz)
		var valid := true
		for poi in pois:
			var p := poi as POISystem.POI
			var hw := p.size.x * 0.5 + min_distance_from_poi
			var hd := p.size.y * 0.5 + min_distance_from_poi
			if abs(candidate.x - p.position.x) < hw and abs(candidate.z - p.position.z) < hd:
				valid = false
				break
		if valid:
			return candidate
	return Vector3.INF

func _spawn_tree(base_name: String, pos: Vector3) -> void:
	var trunk_h := _rng.randf_range(2.5, 4.0)
	var trunk_r := _rng.randf_range(0.2, 0.35)
	var canopy  := _rng.randf_range(2.5, 4.5)

	var trunk := CSGCylinder3D.new()
	trunk.name = base_name + "Trunk"
	trunk.radius = trunk_r
	trunk.height = trunk_h
	trunk.use_collision = true
	trunk.material_override = _make_material(COLOR_TRUNK)
	trunk.position = pos + Vector3(0, trunk_h * 0.5, 0)
	add_child(trunk)

	_add_csg_box(
		base_name + "Canopy",
		pos + Vector3(0, trunk_h + canopy * 0.5, 0),
		Vector3(canopy, canopy, canopy),
		COLOR_CANOPY, true
	)

# ── Enemy spawning ─────────────────────────────────────────────────────────────

func _spawn_zone_enemies(pois: Array) -> void:
	for poi in pois:
		var p := poi as POISystem.POI
		if p.enemy_count <= 0:
			continue
		for i in range(p.enemy_count):
			var offset := Vector3(
				_rng.randf_range(-p.size.x * 0.3, p.size.x * 0.3),
				0.8,
				_rng.randf_range(-p.size.y * 0.3, p.size.y * 0.3)
			)
			var enemy := SCENE_ENEMY.instantiate()
			add_child(enemy)
			enemy.global_position = p.position + offset

func _spawn_patrol_enemies(pois: Array) -> void:
	# 2-3 patrulleros entre zonas en campo abierto
	var count := _rng.randi_range(2, 3)
	for i in range(count):
		var pos := _random_open_pos(pois, 30.0)
		if pos == Vector3.INF:
			continue
		var enemy := SCENE_ENEMY.instantiate()
		add_child(enemy)
		enemy.global_position = pos + Vector3(0, 0.8, 0)

# ── CSG factory helpers ────────────────────────────────────────────────────────

func _add_csg_box(node_name: String, world_pos: Vector3, size: Vector3, color: Color, with_collision: bool) -> CSGBox3D:
	var box := CSGBox3D.new()
	box.name = node_name
	box.size = size
	box.use_collision = with_collision
	box.material_override = _make_material(color)
	box.position = world_pos
	add_child(box)
	return box

func _make_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat
