extends Node
## DropController — manejador global de drops tipo Metin2.
## Spawn radial + ownership + (commit 3) expiración + (commit 4) VFX.
## Autoload: accesible como DropController.

signal drop_spawned(drop: GroundItem)
signal drop_expired(drop: GroundItem, reason: String)

const GROUND_ITEM_SCENE := preload("res://scenes/loot/ground_item.tscn")
const GOLD_SCENE := preload("res://scenes/loot/gold_drop.tscn")

const RING_INNER := 1.0
const RING_OUTER := 2.0
const CELL_SIZE := 0.5
const MAX_SPAWN_ATTEMPTS := 20
const OWNER_WINDOW_SEC := 120.0
const KILLER_MAJORITY_THRESHOLD := 0.60   # >=60% daño solo → ownership directa
const CONTRIB_MIN_SHARE := 0.10           # <10% del daño total = no cuenta para round-robin

# Round-robin FIFO cross-mob: recordar a quién le tocó el loot antes
# para que la próxima vez con daño compartido entre los mismos, rote.
var _round_robin_queue: Array[int] = []


## Entry point — base_enemy.die() llama esto.
## loot: {"gold": int, "items": [{"item_id", "quantity"}]}
## damage_log: {attacker_id(int) → dmg_total(float)}
## attackers_map: {attacker_id(int) → Node}
func spawn_drops(enemy_position: Vector3, loot: Dictionary, query_node: Node,
		damage_log: Dictionary = {}, attackers_map: Dictionary = {}) -> void:
	var scene_root: Node = query_node.get_tree().current_scene
	var occupied_cells: Dictionary = {}

	# Gold: sin ownership (compat legacy + pickup auto al caminar encima)
	if loot.get("gold", 0) > 0:
		var gold = GOLD_SCENE.instantiate()
		gold.setup(loot["gold"])
		gold.global_position = _pick_radial_position(enemy_position, occupied_cells, query_node)
		scene_root.call_deferred("add_child", gold)

	var items: Array = loot.get("items", [])
	if items.is_empty():
		return

	var owner_player: Node = _resolve_owner(damage_log, attackers_map)

	for entry in items:
		var drop: GroundItem = GROUND_ITEM_SCENE.instantiate()
		drop.setup(entry["item_id"], entry["quantity"], owner_player)
		drop.global_position = _pick_radial_position(enemy_position, occupied_cells, query_node)
		scene_root.call_deferred("add_child", drop)
		drop_spawned.emit(drop)


## Owner resolution:
## - Sin attackers → null (libre siempre).
## - Killing blow con >=60% daño → ese player.
## - Daño compartido (killer <60%) → round-robin FIFO entre contributors >=10%.
func _resolve_owner(damage_log: Dictionary, attackers_map: Dictionary) -> Node:
	if damage_log.is_empty():
		return null
	var total_dmg: float = 0.0
	var killer_id: int = 0
	var killer_dmg: float = 0.0
	for att_id in damage_log:
		var d: float = damage_log[att_id]
		total_dmg += d
		if d > killer_dmg:
			killer_dmg = d
			killer_id = att_id
	if total_dmg <= 0.0 or killer_id == 0:
		return null

	var killer_share: float = killer_dmg / total_dmg
	var killer_node: Node = attackers_map.get(killer_id, null)

	# Killer solo o con mayoría >=60% → owner directo
	if killer_share >= KILLER_MAJORITY_THRESHOLD:
		return _valid_or_null(killer_node)

	# Daño compartido — round-robin FIFO
	return _round_robin_pick(damage_log, attackers_map, total_dmg)


func _round_robin_pick(damage_log: Dictionary, attackers_map: Dictionary, total: float) -> Node:
	var candidates: Array[int] = []
	for att_id in damage_log:
		if (damage_log[att_id] / total) >= CONTRIB_MIN_SHARE:
			# Solo contar si el Node sigue vivo
			var n: Node = attackers_map.get(att_id, null)
			if _valid_or_null(n) != null:
				candidates.append(att_id)
	if candidates.is_empty():
		return null

	# Pick primer candidato en la queue FIFO; si queue vacía, tomar candidates[0]
	for id in _round_robin_queue:
		if id in candidates:
			_round_robin_queue.erase(id)
			_round_robin_queue.append(id)
			return attackers_map[id]

	var picked: int = candidates[0]
	_round_robin_queue.append(picked)
	return attackers_map[picked]


func _valid_or_null(n: Node) -> Node:
	return n if (n != null and is_instance_valid(n)) else null


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
