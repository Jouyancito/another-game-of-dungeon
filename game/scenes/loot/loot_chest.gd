extends Area3D
class_name LootChest

## Cofre de loot interactuable. Se abre con E, dropea items, queda vacío.

enum ChestTier { COMMON, RARE, BOSS }

@export var chest_tier: ChestTier = ChestTier.COMMON
@export var interaction_range := 2.5

var is_opened := false

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var label_3d: Label3D = $Label3D
@onready var lid: MeshInstance3D = $Lid


func _ready() -> void:
	add_to_group("interactables")
	label_3d.text = "Cofre [E]"
	label_3d.visible = false
	_apply_tier_visuals()


func _apply_tier_visuals() -> void:
	var mat := StandardMaterial3D.new()
	match chest_tier:
		ChestTier.COMMON:
			mat.albedo_color = Color(0.45, 0.30, 0.15)
		ChestTier.RARE:
			mat.albedo_color = Color(0.35, 0.35, 0.50)
			mat.emission_enabled = true
			mat.emission = Color(0.3, 0.3, 0.6)
			mat.emission_energy_multiplier = 0.5
		ChestTier.BOSS:
			mat.albedo_color = Color(0.50, 0.35, 0.10)
			mat.emission_enabled = true
			mat.emission = Color(0.6, 0.45, 0.1)
			mat.emission_energy_multiplier = 1.0
	mesh.set_surface_override_material(0, mat)
	lid.set_surface_override_material(0, mat)


func open(player: Node3D) -> void:
	if is_opened:
		return
	is_opened = true
	label_3d.visible = false

	# Animación: tapa se abre
	var tween := create_tween()
	tween.tween_property(lid, "rotation:x", deg_to_rad(-110), 0.4).set_ease(Tween.EASE_OUT)

	# Generar loot según tier
	var items := _roll_chest_loot()
	var gold := _roll_chest_gold()

	# Spawnear drops con delay para efecto visual
	await get_tree().create_timer(0.3).timeout
	_spawn_chest_drops(items, gold)


func _roll_chest_gold() -> int:
	var table_name := _get_table_name()
	var rolled := LootTable.roll(table_name)
	return rolled.get("gold", 0)


func _roll_chest_loot() -> Array:
	var table_name := _get_table_name()
	var rolled := LootTable.roll(table_name)
	return rolled.get("items", [])


func _get_table_name() -> String:
	match chest_tier:
		ChestTier.RARE: return "chest_rare"
		ChestTier.BOSS: return "chest_boss"
	return "chest_common"


func _spawn_chest_drops(items: Array, gold: int) -> void:
	var scene_root: Node = get_tree().current_scene
	var spawn_pos := global_position + Vector3(0, 0.5, 0)

	# Oro
	if gold > 0:
		var gold_scene := preload("res://scenes/loot/gold_drop.tscn")
		var gold_drop := gold_scene.instantiate() as GoldDrop
		gold_drop.setup(gold)
		gold_drop.global_position = spawn_pos + Vector3(randf_range(-0.3, 0.3), 0.2, randf_range(-0.3, 0.3))
		scene_root.call_deferred("add_child", gold_drop)

	# Items
	for i in range(items.size()):
		var item_scene := preload("res://scenes/loot/item_drop.tscn")
		var drop := item_scene.instantiate() as ItemDrop
		drop.setup(items[i]["item_id"], items[i]["quantity"])
		# Esparcir alrededor del cofre
		var angle := float(i) / float(max(items.size(), 1)) * TAU
		var offset := Vector3(cos(angle) * 0.8, 0.3, sin(angle) * 0.8)
		drop.global_position = spawn_pos + offset
		scene_root.call_deferred("add_child", drop)


func show_label() -> void:
	if not is_opened:
		label_3d.visible = true


func hide_label() -> void:
	label_3d.visible = false
