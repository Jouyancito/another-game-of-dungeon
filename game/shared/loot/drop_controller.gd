extends Node
## DropController — manejador global de drops tipo Metin2.
## Spawn radial + (commit 2) ownership + (commit 3) expiración + (commit 4) VFX.
## Autoload: accesible como DropController.

signal drop_spawned(drop: GroundItem)
signal drop_expired(drop: GroundItem, reason: String)

const GROUND_ITEM_SCENE := preload("res://scenes/loot/ground_item.tscn")
const GOLD_SCENE := preload("res://scenes/loot/gold_drop.tscn")

const RING_INNER := 1.0
const RING_OUTER := 2.0
const CELL_SIZE := 0.5
const MAX_SPAWN_ATTEMPTS := 20


## Entry point — base_enemy.die() llama esto.
## loot: {"gold": int, "items": [{"item_id", "quantity"}]}
func spawn_drops(enemy_position: Vector3, loot: Dictionary, query_node: Node) -> void:
	var scene_root: Node = query_node.get_tree().current_scene
	var occupied_cells: Dictionary = {}

	# Gold — compat sistema viejo, sin ownership
	if loot.get("gold", 0) > 0:
		var gold = GOLD_SCENE.instantiate()
		gold.setup(loot["gold"])
		gold.global_position = _pick_radial_position(enemy_position, occupied_cells, query_node)
		scene_root.call_deferred("add_child", gold)

	var items: Array = loot.get("items", [])
	for entry in items:
		var drop: GroundItem = GROUND_ITEM_SCENE.instantiate()
		drop.setup(entry["item_id"], entry["quantity"], null)
		drop.global_position = _pick_radial_position(enemy_position, occupied_cells, query_node)
		scene_root.call_deferred("add_child", drop)
		drop_spawned.emit(drop)


func _pick_radial_position(center: Vector3, occupied: Dictionary, query_node: Node) -> Vector3:
	for _i in MAX_SPAWN_ATTEMPTS:
		var angle := randf() * TAU
		var r := randf_range(RING_INNER, RING_OUTER)
		var candidate := center + Vector3(cos(angle) * r, 0.0, sin(angle) * r)
		var cell := _cell_key(candidate)
		if cell in occupied:
			continue
		occupied[cell] = true
		return _snap_ground(candidate, query_node)
	return _snap_ground(center + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3)), query_node)


func _cell_key(pos: Vector3) -> Vector2i:
	return Vector2i(int(floor(pos.x / CELL_SIZE)), int(floor(pos.z / CELL_SIZE)))


func _snap_ground(pos: Vector3, query_node: Node) -> Vector3:
	var space := query_node.get_world_3d().direct_space_state
	var from := pos + Vector3(0, 2.0, 0)
	var to := pos + Vector3(0, -5.0, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		return Vector3(pos.x, hit.position.y + 0.05, pos.z)
	return pos
