extends Area3D
class_name GoldDrop

## Monedas en el suelo — canon drop-ownership v2.
## Sin owner, sin auto-pickup: el jugador presiona [E] para recoger.
## Al pickup, si hay party activa → split entre miembros vivos (si no, todo al picker).

@export var despawn_time := 300.0  # Canon v2: 5 minutos total

const MERGE_RADIUS := 2.0  # Radio para fusionar monedas cercanas

var amount: int = 1
var _picked := false

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var label_3d: Label3D = $Label3D


func _ready() -> void:
	add_to_group("drops")
	add_to_group("gold_drops")

	# Mesh mas chica — proporciones moneda de verdad (no tamano cabeza)
	var cyl := mesh.mesh as CylinderMesh
	if cyl != null:
		cyl.top_radius = 0.05
		cyl.bottom_radius = 0.05
		cyl.height = 0.015

	# Label — via LootStyle. Tinte dorado.
	LootStyle.style_world_label(label_3d, "%d oro" % amount, Color(1.0, 0.85, 0.2))
	label_3d.visible = false
	LootStyle.build_label_bg(self, label_3d, 1, LootStyle.BG_GOLD_DARK)

	# Intentar fusionar con oro cercano
	call_deferred("_try_merge_nearby")

	if despawn_time > 0.0:
		_start_despawn_timer()


func _try_merge_nearby() -> void:
	if _picked or not is_instance_valid(self):
		return
	var gold_drops: Array[Node] = get_tree().get_nodes_in_group("gold_drops")
	for node: Node in gold_drops:
		if node == self or not is_instance_valid(node):
			continue
		var other: GoldDrop = node as GoldDrop
		if other == null or other._picked:
			continue
		var dist: float = global_position.distance_to(other.global_position)
		if dist <= MERGE_RADIUS:
			amount += other.amount
			LootStyle.style_world_label(label_3d, "%d oro" % amount, Color(1.0, 0.85, 0.2))
			other._picked = true
			other.queue_free()
			break


func _start_despawn_timer() -> void:
	var blink_start := despawn_time - 30.0
	if blink_start > 0.0:
		await get_tree().create_timer(blink_start).timeout
		if not is_instance_valid(self):
			return
		var blink_timer := 0.0
		while blink_timer < 30.0:
			if not is_instance_valid(self) or _picked:
				return
			visible = not visible
			await get_tree().create_timer(0.5).timeout
			blink_timer += 0.5
	else:
		await get_tree().create_timer(despawn_time).timeout
	if is_instance_valid(self):
		queue_free()


## Llamar ANTES de add_child — solo guarda datos
func setup(gold_amount: int) -> void:
	amount = gold_amount


## Gold no tiene owner (canon v2) — cualquiera puede levantar.
func can_pickup_by(_player: Node) -> bool:
	return not _picked


## Pickup manual via [E]. Canon v2 party split entre vivos al pickup.
## Retorna Dictionary vacio (compat con pickup_item loop en base_player).
func pickup() -> Dictionary:
	if _picked:
		return {}
	_picked = true

	_distribute_gold()

	var tween := create_tween()
	tween.tween_property(self, "global_position:y", global_position.y + 1.0, 0.2)
	tween.parallel().tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.2)
	tween.tween_callback(queue_free)
	return {}


# Split entre miembros party vivos. Singleplayer (sin party) → todo al picker.
# "picker" se deduce via grupo "player" + distance minima (pickup_range ya filtro).
func _distribute_gold() -> void:
	var alive_members: Array[Node] = _find_alive_party_members()
	if alive_members.is_empty():
		return

	var per_member: int = amount / alive_members.size()
	var remainder: int = amount % alive_members.size()

	for i in alive_members.size():
		var m: Node = alive_members[i]
		var share: int = per_member
		if i < remainder:
			share += 1
		if share > 0 and m.has_method("add_gold"):
			m.call("add_gold", share)


# Devuelve players vivos de la party activa. Sin party → retorna los players vivos de la escena
# (singleplayer: el unico player local).
func _find_alive_party_members() -> Array[Node]:
	var alive: Array[Node] = []
	var party: Array[String] = Party.current_party
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("get") and p.get("is_dead"):
			continue
		if party.is_empty():
			alive.append(p)  # singleplayer: todos los players locales
			continue
		if p.has_method("get_profile_id") and str(p.call("get_profile_id")) in party:
			alive.append(p)
	return alive


func show_label() -> void:
	LootStyle.show_label_with_bg(label_3d)


func hide_label() -> void:
	LootStyle.hide_label_with_bg(label_3d)
