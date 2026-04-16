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

	# Canon drop-ownership v2: chest delega en DropController (mismo modelo party + floor+random).
	var loot := _roll_chest_table()
	var opener_pid: String = ""
	if player != null and player.has_method("get_profile_id"):
		opener_pid = str(player.call("get_profile_id"))

	await get_tree().create_timer(0.3).timeout
	DropController.spawn_chest_drops(global_position + Vector3(0, 0.5, 0), loot, self, opener_pid)


func _roll_chest_table() -> Dictionary:
	return LootTable.roll(_get_table_name())


func _get_table_name() -> String:
	match chest_tier:
		ChestTier.RARE: return "chest_rare"
		ChestTier.BOSS: return "chest_boss"
	return "chest_common"


func show_label() -> void:
	if not is_opened:
		label_3d.visible = true


func hide_label() -> void:
	label_3d.visible = false
