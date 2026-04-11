extends Area3D
class_name GoldDrop

## Monedas en el suelo. Se recogen automáticamente al acercarse (distance-based).

@export var pickup_radius := 2.0  # Radio de auto-pickup (distance-based)
@export var despawn_time := 300.0  # 5 minutos

var amount: int = 1
var _picked := false

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var label_3d: Label3D = $Label3D


const MERGE_RADIUS := 2.0  # Radio para fusionar monedas cercanas

func _ready() -> void:
	add_to_group("drops")
	add_to_group("gold_drops")

	# Mesh más chica — proporciones moneda de verdad (no tamaño cabeza)
	var cyl := mesh.mesh as CylinderMesh
	if cyl != null:
		cyl.top_radius = 0.05
		cyl.bottom_radius = 0.05
		cyl.height = 0.015

	# Label — tamaño legible, constante en pantalla
	label_3d.text = "%d oro" % amount
	label_3d.fixed_size = true
	label_3d.pixel_size = 0.00055  # ajuste final — consistente con enemy + item drops
	label_3d.font_size = 24
	label_3d.outline_size = 3
	label_3d.no_depth_test = true
	label_3d.render_priority = 1
	label_3d.visible = false

	_build_label_background()

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
			# Absorber el oro del otro
			amount += other.amount
			label_3d.text = "%d oro" % amount
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
			if not is_instance_valid(self):
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


func _physics_process(_delta: float) -> void:
	if _picked:
		return
	# Monedas FIJAS en el suelo (no bob, no rotation — los nombres no se mueven).
	# Pickup distance-based: bypassa Area3D body_entered que a veces no re-trigger.
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: Node3D = players[0] as Node3D
	if player == null:
		return
	if global_position.distance_to(player.global_position) <= pickup_radius:
		_do_pickup(player)


func _do_pickup(player: Node3D) -> void:
	if _picked:
		return
	_picked = true
	if player.has_method("add_gold"):
		player.add_gold(amount)
	var tween := create_tween()
	tween.tween_property(self, "global_position:y", global_position.y + 1.0, 0.2)
	tween.parallel().tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.2)
	tween.tween_callback(queue_free)


func show_label() -> void:
	label_3d.visible = true
	var bg: Node = label_3d.get_meta("background_node", null)
	if bg != null and bg is MeshInstance3D:
		(bg as MeshInstance3D).visible = true


func hide_label() -> void:
	label_3d.visible = false
	var bg: Node = label_3d.get_meta("background_node", null)
	if bg != null and bg is MeshInstance3D:
		(bg as MeshInstance3D).visible = false


func _build_label_background() -> void:
	var bg_mesh := MeshInstance3D.new()
	bg_mesh.name = "LabelBackground"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.85, 0.22)
	bg_mesh.mesh = quad

	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.1, 0.08, 0.02, 0.75)  # tono dorado oscuro, distintivo del oro
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.no_depth_test = true
	bg_mat.render_priority = 0
	bg_mesh.material_override = bg_mat

	bg_mesh.position = label_3d.position
	add_child(bg_mesh)
	bg_mesh.visible = false
	label_3d.set_meta("background_node", bg_mesh)
