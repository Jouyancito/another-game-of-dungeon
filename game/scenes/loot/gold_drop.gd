extends Area3D
class_name GoldDrop

## Monedas en el suelo. Se recogen automáticamente al pasar encima.

@export var bob_speed := 3.0
@export var bob_amplitude := 0.1
@export var rotation_speed := 3.0
@export var despawn_time := 300.0  # 5 minutos

var amount: int = 1

var _base_y := 0.0
var _time := 0.0
var _picked := false

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var label_3d: Label3D = $Label3D


const MERGE_RADIUS := 2.0  # Radio para fusionar monedas cercanas

func _ready() -> void:
	add_to_group("drops")
	add_to_group("gold_drops")
	_base_y = global_position.y
	_time = randf() * TAU
	body_entered.connect(_on_body_entered)

	label_3d.text = "%d oro" % amount
	label_3d.visible = false

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


func _physics_process(delta: float) -> void:
	_time += delta
	global_position.y = _base_y + sin(_time * bob_speed) * bob_amplitude
	rotate_y(rotation_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	if _picked:
		return
	if body.is_in_group("player"):
		_picked = true
		if body.has_method("add_gold"):
			body.add_gold(amount)
		var tween = create_tween()
		tween.tween_property(self, "global_position:y", global_position.y + 1.0, 0.2)
		tween.parallel().tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.2)
		tween.tween_callback(queue_free)


func show_label() -> void:
	label_3d.visible = true


func hide_label() -> void:
	label_3d.visible = false
