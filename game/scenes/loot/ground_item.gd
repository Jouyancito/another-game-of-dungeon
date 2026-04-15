class_name GroundItem
extends Area3D

## Drop en mundo tipo Metin2 — manejado por DropController.
## Ownership, expiración y bind_on_drop se agregan en commits posteriores.

signal despawned(item: GroundItem, reason: String)
signal vfx_despawn_requested(item: GroundItem, reason: String, color: Color)

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
	# Stagger vertical del label para que drops cercanos no se apilen en pantalla
	if label_3d:
		label_3d.position.y = randf_range(0.45, 1.05)
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
		if n != null and str(n) != "":
			owner_name = str(n)
		else:
			owner_name = String(owner_player.name)


## Animacion de spawn estilo Metin2: arco pequeno desde el mob hacia la posicion final.
func arc_to(target: Vector3) -> void:
	var start := global_position
	var peak := start.lerp(target, 0.5)
	peak.y = maxf(start.y, target.y) + 0.7
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "global_position", peak, 0.18).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", target, 0.20).set_ease(Tween.EASE_IN)
	# Pequeno "rebote" al aterrizar
	tween.tween_property(self, "scale", Vector3(1.15, 0.85, 1.15), 0.06)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.10)


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
	hide_label()

	var rarity: String = item_data.get("rarity", "common")
	var color: Color = ItemDatabase.get_rarity_color(rarity)

	despawned.emit(self, reason)
	vfx_despawn_requested.emit(self, reason, color)

	_play_despawn_vfx(color)


func _play_despawn_vfx(color: Color) -> void:
	# Pulse rapido del aura + expansion del mesh + fade a transparente.
	# Hook para FX externos (particulas reales) via signal vfx_despawn_requested.
	var tween := create_tween()
	tween.set_parallel(true)

	# Aura: pulse energetico luego fade
	if aura_light:
		aura_light.light_color = color
		tween.tween_property(aura_light, "light_energy", 3.0, 0.15)
		tween.chain().tween_property(aura_light, "light_energy", 0.0, 0.4)
		tween.parallel().tween_property(aura_light, "omni_range", 3.0, 0.4)

	# Mesh: expand + fade via material transparency
	if mesh:
		var mat: StandardMaterial3D = mesh.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = 2.5
			tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.55)
			tween.parallel().tween_property(mat, "emission_energy_multiplier", 0.0, 0.55)
		tween.parallel().tween_property(mesh, "scale", Vector3(2.0, 2.0, 2.0), 0.55)

	# Root node: scale down final + queue_free
	tween.chain().tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.15)
	tween.chain().tween_callback(queue_free)


func show_label() -> void:
	LootStyle.show_label_with_bg(label_3d)


func hide_label() -> void:
	LootStyle.hide_label_with_bg(label_3d)


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

	# Light solo para rareza >= rare — evita saturar el forward renderer
	# con N OmniLights dinamicas cuando hay muchos commons en el piso.
	if aura_light:
		if rarity == "rare" or rarity == "unique" or rarity == "magic":
			aura_light.light_color = color
			aura_light.light_energy = 0.8 if rarity == "magic" else (1.2 if rarity == "rare" else 1.8)
			aura_light.omni_range = 1.2
		else:
			aura_light.visible = false
			aura_light.light_energy = 0.0

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
	LootStyle.style_world_label(label_3d, name_txt, color)
	LootStyle.resize_label_bg(_label_bg, label_3d, name_txt.count("\n") + 1)


func _build_label_bg() -> void:
	var bg_color: Color = LootStyle.BG_QUEST_DARK if bind_on_drop else LootStyle.BG_ITEM_DARK
	_label_bg = LootStyle.build_label_bg(self, label_3d, 1, bg_color)


func _get_type_color(t: String) -> Color:
	match t:
		"weapon": return Color(0.7, 0.7, 0.75)
		"armor": return Color(0.5, 0.5, 0.55)
		"consumable": return Color(0.8, 0.3, 0.3)
		"material": return Color(0.6, 0.5, 0.3)
		_: return Color(0.6, 0.6, 0.6)
