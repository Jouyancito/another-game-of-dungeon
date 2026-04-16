extends Node
## DropController — canon drop-ownership v2 (Judgment Day 2026-04-16).
## Party-auto pool + floor+random + timers 180/120/300 + support window 10s.
## Autoload: accesible como DropController.

signal drop_spawned(drop: GroundItem)
signal drop_expired(drop: GroundItem, reason: String)

const GROUND_ITEM_SCENE := preload("res://scenes/loot/ground_item.tscn")
const GOLD_SCENE := preload("res://scenes/loot/gold_drop.tscn")

const RING_INNER := 1.0
const RING_OUTER := 2.0
const CELL_SIZE := 0.7              # gap visual claro entre items (mesh ~0.25m)
const MAX_SPAWN_ATTEMPTS := 30

# Canon v2 timers
const OWNER_LOCK_SEC := 180.0       # drop normal: fase owner-only
const FREE_WINDOW_SEC := 120.0      # drop normal: fase free-for-all
const DESPAWN_TOTAL_SEC := 300.0    # sanity total = OWNER_LOCK + FREE_WINDOW
const BIND_LOCK_SEC := 300.0        # bind items: owner-only hasta despawn, sin free
const SUPPORT_WINDOW_SEC := 10.0    # cleric/buffer window para entrar al pool

# Registros activos: drop_instance_id → {drop: GroundItem, owner_profile_id: String}
var _active_drops: Dictionary = {}

# Canon §2.2 seed entropy: incrementado en cada spawn_drops para evitar colisiones same-frame.
static var _kill_counter: int = 0


## Entry point — base_enemy.die() o kill por ambiente.
## loot: {"gold": int, "items": [{"item_id", "quantity"}]}
## killer_profile_id: "" → free-for-all desde spawn (kill por ambiente)
func spawn_drops(enemy_position: Vector3, loot: Dictionary, query_node: Node,
		killer_profile_id: String = "") -> void:
	var scene_root: Node = query_node.get_tree().current_scene
	var occupied_cells: Dictionary = {}

	# Gold: canon v2 = sin owner, auto-pickup OFF, split al pickup entre party vivos.
	var gold_amount: int = loot.get("gold", 0)
	if gold_amount > 0:
		var gold = GOLD_SCENE.instantiate()
		gold.setup(gold_amount)
		var gold_target := _pick_radial_position(enemy_position, occupied_cells, query_node)
		gold.global_position = enemy_position + Vector3(0, 0.4, 0)
		scene_root.call_deferred("add_child", gold)
		gold.call_deferred("arc_to", gold_target)

	var items: Array = loot.get("items", [])
	if items.is_empty():
		return

	# Pool de owners segun canon v2
	var pool: Array[String] = _resolve_pool(killer_profile_id, query_node)

	# Canon §2.2: RNG seeded por kill para reproducibilidad debug.
	var rng := RandomNumberGenerator.new()
	var seed_base: int = killer_profile_id.hash() if killer_profile_id != "" else 0
	# Canon §2.2 + seed entropy fix: XOR con ticks y kill counter para evitar colisiones.
	_kill_counter += 1
	if killer_profile_id == "":
		rng.randomize()
	else:
		rng.seed = seed_base ^ Time.get_ticks_msec() ^ _kill_counter

	# Canon §5.1: bind items ignorar reparto floor+random — asignar directo al killer.
	var bind_items: Array = []
	var normal_items: Array = []
	for entry in items:
		var item_data: Dictionary = ItemDatabase.get_item(entry["item_id"])
		if item_data.get("bind_on_drop", false):
			bind_items.append(entry)
		else:
			normal_items.append(entry)

	# Reparto floor+random sobre items normales
	var assignments: Array[String] = _floor_random_split(normal_items.size(), pool, rng)

	# Combinar: bind items primero (asignados al killer), luego normales
	var all_entries: Array = []
	var all_owners: Array[String] = []
	for bind_entry in bind_items:
		all_entries.append(bind_entry)
		all_owners.append(killer_profile_id)  # directo al killer (o "" si ambient — fallback en _register_drop)
	for i in normal_items.size():
		all_entries.append(normal_items[i])
		all_owners.append(assignments[i] if i < assignments.size() else "")

	for i in all_entries.size():
		var entry: Dictionary = all_entries[i]
		var owner_pid: String = all_owners[i]
		var owner_node: Node = _find_player_by_profile(owner_pid, query_node) if owner_pid != "" else null

		var drop: GroundItem = GROUND_ITEM_SCENE.instantiate()
		drop.setup(entry["item_id"], entry["quantity"], owner_node, owner_pid)
		var target_pos := _pick_radial_position(enemy_position, occupied_cells, query_node)
		drop.global_position = enemy_position + Vector3(0, 0.4, 0)
		scene_root.call_deferred("add_child", drop)
		drop.call_deferred("arc_to", target_pos)
		_register_drop(drop, owner_pid)
		drop_spawned.emit(drop)


## Entry alternativa para cofres — misma regla party+floor+random.
## opener_profile_id = profile_id del player que abrio el cofre.
func spawn_chest_drops(chest_position: Vector3, loot: Dictionary, query_node: Node,
		opener_profile_id: String) -> void:
	spawn_drops(chest_position, loot, query_node, opener_profile_id)


## Resuelve pool segun canon v2:
## - killer_profile_id == "" → pool vacio → drops free-for-all.
## - Con killer → Party.get_party_of(killer) + supporters que healed/buffed ultimos 10s.
## - Canon §1.1: miembros muertos al momento del kill quedan fuera del reparto.
func _resolve_pool(killer_profile_id: String, query_node: Node) -> Array[String]:
	if killer_profile_id == "":
		return []
	var party: Array[String] = Party.get_party_of(killer_profile_id)
	if party.is_empty():
		party = [killer_profile_id]

	# Canon §1.1: filtrar miembros muertos — no participan en el reparto.
	var alive_party: Array[String] = []
	for pid in party:
		var node: Node = _find_player_by_profile(pid, query_node)
		if node == null or node.get("is_dead") == true:
			continue
		alive_party.append(pid)
	party = alive_party

	# Support participants: supporters que estan EN party y aplicaron heal/buff ultimos 10s.
	var now := Time.get_unix_time_from_system()
	var supporters: Array[String] = []
	for member_pid in party:
		var member: Node = _find_player_by_profile(member_pid, query_node)
		if member == null:
			continue
		var ts_dict: Variant = member.get("last_support_ts")
		if ts_dict == null or not (ts_dict is Dictionary):
			continue
		for supporter_pid in ts_dict:
			var ts: float = float(ts_dict[supporter_pid])
			if (now - ts) >= SUPPORT_WINDOW_SEC:
				continue
			if supporter_pid in party and supporter_pid not in supporters:
				supporters.append(supporter_pid)

	# Filtrar supporters muertos/offline antes de agregar al pool.
	var alive_supporters: Array[String] = []
	for sup_pid in supporters:
		var sup_node: Node = _find_player_by_profile(sup_pid, query_node)
		if sup_node == null or sup_node.get("is_dead") == true:
			continue
		alive_supporters.append(sup_pid)

	# Merge: party viva + supporters vivos (dedup)
	var pool: Array[String] = party.duplicate()
	for s in alive_supporters:
		if s not in pool:
			pool.append(s)
	return pool


## floor+random: N drops, M miembros.
## floor(N/M) drops garantizados c/u + N mod M drops sorteados random.
## Retorna array de tamano N con profile_id por indice de drop.
## rng: RandomNumberGenerator seeded por el caller (canon §2.2 — reproducible en debug).
func _floor_random_split(drop_count: int, pool: Array[String], rng: RandomNumberGenerator) -> Array[String]:
	var out: Array[String] = []
	if drop_count <= 0:
		return out
	if pool.is_empty():
		# Sin pool → todos free-for-all (owner="")
		for i in drop_count:
			out.append("")
		return out

	var members: Array[String] = pool.duplicate()
	var m: int = members.size()
	var guaranteed: int = drop_count / m
	var leftover: int = drop_count % m

	# guaranteed drops por miembro
	for pid in members:
		for _j in guaranteed:
			out.append(pid)

	# leftover: sortear sin reemplazo usando rng seeded (Fisher-Yates parcial)
	for i in range(members.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = members[i]
		members[i] = members[j]
		members[j] = tmp
	for k in leftover:
		out.append(members[k])

	# Shuffle final para que el ORDEN de drops no delate el reparto (usando rng seeded)
	for i in range(out.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out


## Busca player en la escena por profile_id. null si no esta.
func _find_player_by_profile(profile_id: String, query_node: Node) -> Node:
	if profile_id == "":
		return null
	for p in query_node.get_tree().get_nodes_in_group("player"):
		if p.has_method("get_profile_id") and str(p.call("get_profile_id")) == profile_id:
			return p
	return null


## Registra drop con owner profile_id. Arma timer de expiracion segun bind_on_drop.
func _register_drop(drop: GroundItem, owner_profile_id: String) -> void:
	var drop_id := drop.get_instance_id()
	_active_drops[drop_id] = {
		"drop": drop,
		"owner_profile_id": owner_profile_id,
	}
	drop.tree_exited.connect(func(): _active_drops.erase(drop_id))

	# Free-for-all desde spawn (kill ambiente o pool vacio) → solo timer total 300s.
	if owner_profile_id == "":
		# Canon §7: bind items requieren trigger player identificado; sin killer, fallback a
		# expired (300s sin owner lock). Log para diagnostico — no hay owner posible.
		if drop.bind_on_drop:
			push_warning("Bind item %s desde kill ambient sin trigger player — tratando como expired" % drop.item_id)
		_schedule_final_despawn(drop_id, DESPAWN_TOTAL_SEC)
		return

	# Bind: 300s owner-only → despawn directo.
	if drop.bind_on_drop:
		_schedule_bind_despawn(drop_id)
		return

	# Normal: 180s owner-lock → mark_free → 120s free → despawn.
	_schedule_owner_lock_expire(drop_id)


func _schedule_owner_lock_expire(drop_id: int) -> void:
	var timer := get_tree().create_timer(OWNER_LOCK_SEC)
	timer.timeout.connect(func(): _on_owner_lock_expired(drop_id))


func _schedule_final_despawn(drop_id: int, delay: float) -> void:
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(func(): _force_despawn(drop_id, "expired"))


func _schedule_bind_despawn(drop_id: int) -> void:
	var timer := get_tree().create_timer(BIND_LOCK_SEC)
	timer.timeout.connect(func(): _force_despawn(drop_id, "bind_expired"))


func _on_owner_lock_expired(drop_id: int) -> void:
	var rec: Dictionary = _active_drops.get(drop_id, {})
	if rec.is_empty():
		return
	var drop: GroundItem = rec["drop"]
	if not is_instance_valid(drop):
		_active_drops.erase(drop_id)
		return
	if drop.is_despawning:
		return
	drop.mark_free()
	drop_expired.emit(drop, "free_for_all")
	# Segundo timer: 120s free → despawn.
	_schedule_final_despawn(drop_id, FREE_WINDOW_SEC)


func _force_despawn(drop_id: int, reason: String) -> void:
	var rec: Dictionary = _active_drops.get(drop_id, {})
	if rec.is_empty():
		return
	var drop: GroundItem = rec["drop"]
	if not is_instance_valid(drop):
		_active_drops.erase(drop_id)
		return
	if drop.is_despawning:
		return
	drop.despawn_now(reason)
	drop_expired.emit(drop, reason)
	_active_drops.erase(drop_id)


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
	var space: PhysicsDirectSpaceState3D = query_node.get_world_3d().direct_space_state
	var from := pos + Vector3(0, 2.0, 0)
	var to := pos + Vector3(0, -5.0, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1
	var hit: Dictionary = space.intersect_ray(q)
	if not hit.is_empty():
		return Vector3(pos.x, hit.position.y + 0.05, pos.z)
	return pos
