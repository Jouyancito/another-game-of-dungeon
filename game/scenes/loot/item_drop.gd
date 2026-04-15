extends Area3D
class_name ItemDrop

## Drop de item en el mundo. Brilla con el color de su rareza.
## Al mirar con crosshair muestra nombre. Se recoge con E o click.

@export var bob_amplitude := 0.15
@export var bob_speed := 2.0
@export var rotation_speed := 1.5
@export var despawn_time := 180.0  # 3 minutos

var item_id: String = ""
var item_quantity: int = 1
var item_data: Dictionary = {}
var dropped_by: String = ""  # Nombre del jugador que lo soltó (para party)

var _base_y := 0.0
var _time := 0.0
var _picked_up := false

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var aura_light: OmniLight3D = $AuraLight
@onready var label_3d: Label3D = $Label3D


func _ready() -> void:
	add_to_group("drops")
	_base_y = global_position.y
	_time = randf() * TAU

	if item_id != "":
		_apply_visuals()

	# Despawn timer — desaparece después de 3 minutos (blink últimos 30s)
	if despawn_time > 0.0:
		_start_despawn_timer()


## Llamar ANTES de add_child — solo guarda datos
func setup(id: String, quantity: int = 1, owner_name: String = "") -> void:
	item_id = id
	item_quantity = quantity
	item_data = ItemDatabase.get_item(id)
	dropped_by = owner_name
	if item_data.is_empty():
		push_error("ItemDrop: item no encontrado: '%s'" % id)


func _apply_visuals() -> void:
	if item_data.is_empty():
		queue_free()
		return

	var rarity: String = item_data.get("rarity", "common")
	var color: Color = ItemDatabase.get_rarity_color(rarity)

	# Nombre del item + quién lo soltó — via LootStyle (sync con GroundItem)
	var display_name: String = item_data.get("name", "???")
	if item_quantity > 1:
		display_name += " x%d" % item_quantity
	if dropped_by != "":
		display_name += "\n[%s]" % dropped_by
	LootStyle.style_world_label(label_3d, display_name, color)
	label_3d.visible = false
	LootStyle.build_label_bg(self, label_3d, display_name.count("\n") + 1, LootStyle.BG_ITEM_DARK)

	# Color del mesh según tipo + emisión por rareza
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_type_color(item_data.get("type", "material"))
	if rarity != "common":
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
	mesh.set_surface_override_material(0, mat)

	# Intensidad de aura según rareza
	aura_light.light_color = color
	var energy_by_rarity := {"common": 0.3, "magic": 0.6, "rare": 1.0, "unique": 1.5}
	aura_light.light_energy = energy_by_rarity.get(rarity, 0.3)


func _physics_process(_delta: float) -> void:
	# Items FIJOS en el suelo — no bob, no rotation.
	# Los nombres tampoco se mueven, así se leen tranquilos.
	pass


func show_label() -> void:
	LootStyle.show_label_with_bg(label_3d)


func hide_label() -> void:
	LootStyle.hide_label_with_bg(label_3d)


func pickup() -> Dictionary:
	_picked_up = true
	var result := {
		"item_id": item_id,
		"quantity": item_quantity,
		"data": item_data,
	}
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.15)
	tween.tween_callback(queue_free)
	return result


func _start_despawn_timer() -> void:
	# Parpadeo los últimos 30 segundos antes de desaparecer
	var blink_start := despawn_time - 30.0
	if blink_start > 0.0:
		await get_tree().create_timer(blink_start).timeout
		if not is_instance_valid(self):
			return
		# Parpadeo: toggle visible cada 0.5s por 30 segundos
		var blink_timer := 0.0
		while blink_timer < 30.0:
			if not is_instance_valid(self) or _picked_up:
				return
			visible = not visible
			await get_tree().create_timer(0.5).timeout
			blink_timer += 0.5
	else:
		await get_tree().create_timer(despawn_time).timeout

	if is_instance_valid(self):
		queue_free()


func _get_type_color(type: String) -> Color:
	match type:
		"weapon": return Color(0.7, 0.7, 0.75)
		"armor": return Color(0.5, 0.5, 0.55)
		"consumable": return Color(0.8, 0.3, 0.3)
		"material": return Color(0.6, 0.5, 0.3)
		_: return Color(0.6, 0.6, 0.6)
