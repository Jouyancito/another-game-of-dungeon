class_name GroundItem
extends Area3D

## Drop en mundo tipo Metin2 — manejado por DropController.
## Ownership, expiración y bind_on_drop se agregan en commits posteriores.

signal despawned(item: GroundItem, reason: String)

@export var despawn_time := 120.0

var item_id: String = ""
var item_quantity: int = 1
var item_data: Dictionary = {}
var owner_id: int = 0               # 0 = libre / instance_id del player dueño
var owner_name: String = ""
var is_free := false
var is_despawning := false
var bind_on_drop := false

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var aura_light: OmniLight3D = $AuraLight
@onready var label_3d: Label3D = $Label3D

var _label_bg: MeshInstance3D


func _ready() -> void:
	add_to_group("drops")
	if item_id != "":
		_apply_visuals()


## Llamar ANTES de add_child.
func setup(id: String, quantity: int = 1, owner_player: Node = null) -> void:
	item_id = id
	item_quantity = quantity
	item_data = ItemDatabase.get_item(id)
	bind_on_drop = item_data.get("bind_on_drop", false)
	if owner_player != null:
		owner_id = owner_player.get_instance_id()
		var n: Variant = owner_player.get("display_name")
		owner_name = str(n) if n != null and str(n) != "" else owner_player.name


func can_pickup_by(player: Node) -> bool:
	if is_despawning:
		return false
	if is_free or owner_id == 0:
		return true
	return player.get_instance_id() == owner_id


func mark_free() -> void:
	is_free = true
	owner_id = 0
	owner_name = ""
	_refresh_label()


func pickup() -> Dictionary:
	is_despawning = true
	var result := {"item_id": item_id, "quantity": item_quantity, "data": item_data}
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.15)
	tween.tween_callback(queue_free)
	return result


func despawn_now(reason: String = "expired") -> void:
	if is_despawning:
		return
	is_despawning = true
	despawned.emit(self, reason)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.4)
	tween.tween_callback(queue_free)


func show_label() -> void:
	if label_3d:
		label_3d.visible = true
	if _label_bg:
		_label_bg.visible = true


func hide_label() -> void:
	if label_3d:
		label_3d.visible = false
	if _label_bg:
		_label_bg.visible = false


func _apply_visuals() -> void:
	if item_data.is_empty():
		queue_free()
		return
	var rarity: String = item_data.get("rarity", "common")
	var color: Color = ItemDatabase.get_rarity_color(rarity)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_type_color(item_data.get("type", "material"))
	if rarity != "common":
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
	mesh.set_surface_override_material(0, mat)

	aura_light.light_color = color
	var energy_by_rarity := {"common": 0.3, "magic": 0.6, "rare": 1.0, "unique": 1.5}
	aura_light.light_energy = energy_by_rarity.get(rarity, 0.3)

	_build_label_bg()
	_refresh_label()
	label_3d.visible = false
	if _label_bg:
		_label_bg.visible = false


func _refresh_label() -> void:
	if item_data.is_empty() or label_3d == null:
		return
	var rarity: String = item_data.get("rarity", "common")
	var color: Color = ItemDatabase.get_rarity_color(rarity)
	var name_txt: String = item_data.get("name", "???")
	if item_quantity > 1:
		name_txt += " x%d" % item_quantity
	if owner_id != 0 and owner_name != "":
		name_txt += "\n[owner: %s]" % owner_name
	label_3d.text = name_txt
	label_3d.modulate = color
	label_3d.fixed_size = true
	label_3d.pixel_size = 0.00055
	label_3d.font_size = 24
	label_3d.outline_size = 3
	label_3d.no_depth_test = false           # OCLUIBLE por paredes (brief)
	label_3d.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label_3d.width = 500.0
	label_3d.render_priority = 1


func _build_label_bg() -> void:
	var bg := MeshInstance3D.new()
	bg.name = "LabelBackground"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.85, 0.26)
	bg.mesh = quad
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.05, 0.05, 0.1, 0.75)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.no_depth_test = false              # ocluido por geometry
	bg_mat.render_priority = 0
	bg.material_override = bg_mat
	bg.position = label_3d.position
	add_child(bg)
	bg.visible = false
	_label_bg = bg


func _get_type_color(t: String) -> Color:
	match t:
		"weapon": return Color(0.7, 0.7, 0.75)
		"armor": return Color(0.5, 0.5, 0.55)
		"consumable": return Color(0.8, 0.3, 0.3)
		"material": return Color(0.6, 0.5, 0.3)
		_: return Color(0.6, 0.6, 0.6)
