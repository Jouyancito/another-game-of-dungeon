class_name HotbarSlot extends PanelContainer

# Slot del hotbar 1-8. Drag&drop: swap entre slots propios o accept de skill tree (futuro).
# Emite señales; HUD delega al PlayerSkills.

signal skill_dropped(slot_index: int, skill: SkillResource)
signal slot_swap_requested(from_index: int, to_index: int)

@export var slot_index: int = -1

var skill: SkillResource = null

var _icon: TextureRect = null
var _empty_hint: Label = null


func _ready() -> void:
	# Deducir slot_index del nombre (Slot1 → 0) si no vino seteado.
	if slot_index < 0:
		var n: String = name
		if n.begins_with("Slot"):
			var suffix: String = n.substr(4)
			if suffix.is_valid_int():
				slot_index = int(suffix) - 1
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_icon()


func _ensure_icon() -> void:
	if _icon != null:
		return
	_icon = TextureRect.new()
	_icon.name = "SkillIcon"
	_icon.anchor_right = 1.0
	_icon.anchor_bottom = 1.0
	_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	move_child(_icon, 0)  # KeyLabel queda encima


func set_skill(s: SkillResource) -> void:
	skill = s
	_ensure_icon()
	if s != null and s.icon != null:
		_icon.texture = s.icon
	else:
		_icon.texture = null


# ── Godot drag&drop API ─────────────────────────────────────────────────────

func _get_drag_data(_at_position: Vector2) -> Variant:
	if skill == null:
		return null
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(48, 48)
	preview.texture = skill.icon
	preview.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(preview)
	return {
		"type": "hotbar_skill",
		"from_slot": slot_index,
		"skill": skill,
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var t: String = str(data.get("type", ""))
	return t == "hotbar_skill" or t == "skill_tree"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var t: String = str(data.get("type", ""))
	if t == "hotbar_skill":
		var from: int = int(data.get("from_slot", -1))
		if from == slot_index or from < 0:
			return
		slot_swap_requested.emit(from, slot_index)
		return
	if t == "skill_tree":
		var sk = data.get("skill", null)
		if sk is SkillResource:
			skill_dropped.emit(slot_index, sk)
