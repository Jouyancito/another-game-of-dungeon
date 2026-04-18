class_name HotbarSlot extends PanelContainer

# Slot del hotbar 1-8. Drag&drop: swap entre slots propios o accept de skill tree (futuro).
# Emite señales; HUD delega al PlayerSkills.

signal skill_dropped(slot_index: int, skill: SkillResource)
signal slot_swap_requested(from_index: int, to_index: int)

@export var slot_index: int = -1

var skill: SkillResource = null

var _icon: TextureRect = null
var _empty_hint: Label = null
var _cooldown_overlay: ColorRect = null
var _key_label: Label = null

# Cooldown overlay — shader radial
# Materiales y shader se crean en código para no depender de assets externos.
var _overlay_material: ShaderMaterial = null

const COOLDOWN_SHADER_CODE := """
shader_type canvas_item;
uniform float cooldown_ratio : hint_range(0.0, 1.0) = 0.0;
uniform vec4 overlay_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	// Ángulo desde arriba (12 o'clock), sentido horario
	float angle = atan(uv.x, uv.y);  // -PI a PI
	// Normalizar a 0..1 (0 = arriba, 1 = vuelta completa)
	float normalized = (angle + PI) / (2.0 * PI);
	// Mostrar overlay donde la animación aún no llegó (zona cubierta)
	float show = step(1.0 - cooldown_ratio, normalized) > 0.0 ? 1.0 : 0.0;
	// Zona cubierta = ratio desde arriba en sentido horario
	show = step(normalized, cooldown_ratio);
	COLOR = overlay_color * show;
}
"""


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
	_ensure_cooldown_overlay()
	_ensure_key_label()


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


func _ensure_cooldown_overlay() -> void:
	if _cooldown_overlay != null:
		return

	# Shader radial de cooldown
	var shader := Shader.new()
	shader.code = COOLDOWN_SHADER_CODE

	_overlay_material = ShaderMaterial.new()
	_overlay_material.shader = shader
	_overlay_material.set_shader_parameter("cooldown_ratio", 0.0)
	_overlay_material.set_shader_parameter("overlay_color", Color(0, 0, 0, 0.5))

	_cooldown_overlay = ColorRect.new()
	_cooldown_overlay.name = "CooldownOverlay"
	_cooldown_overlay.anchor_right = 1.0
	_cooldown_overlay.anchor_bottom = 1.0
	_cooldown_overlay.material = _overlay_material
	_cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cooldown_overlay.visible = false
	add_child(_cooldown_overlay)


func _ensure_key_label() -> void:
	if _key_label != null:
		return
	_key_label = Label.new()
	_key_label.name = "KeyLabel"
	# Top-right corner — ancla a esquina superior derecha del slot
	_key_label.anchor_left = 1.0
	_key_label.anchor_right = 1.0
	_key_label.anchor_top = 0.0
	_key_label.anchor_bottom = 0.0
	_key_label.offset_left = -18
	_key_label.offset_right = 0
	_key_label.offset_top = 2
	_key_label.offset_bottom = 18
	_key_label.add_theme_font_size_override("font_size", 10)
	_key_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.7))
	_key_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_key_label.add_theme_constant_override("shadow_offset_x", 1)
	_key_label.add_theme_constant_override("shadow_offset_y", 1)
	_key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# Texto = número del slot (1-based)
	if slot_index >= 0:
		_key_label.text = str(slot_index + 1)
	add_child(_key_label)


## Actualiza el label de keybind cuando cambia el slot_index.
func _update_key_label() -> void:
	if _key_label == null:
		return
	if slot_index >= 0:
		_key_label.text = str(slot_index + 1)


func set_skill(s: SkillResource) -> void:
	skill = s
	_ensure_icon()
	if s != null and s.icon != null:
		_icon.texture = s.icon
	else:
		_icon.texture = null


## Actualiza el overlay de cooldown radial.
## remaining_s: tiempo restante. total_s: duración total del cooldown.
## Si total_s <= 0, oculta el overlay.
func set_cooldown(remaining_s: float, total_s: float) -> void:
	_ensure_cooldown_overlay()
	if total_s <= 0.0 or remaining_s <= 0.0:
		_cooldown_overlay.visible = false
		if _overlay_material != null:
			_overlay_material.set_shader_parameter("cooldown_ratio", 0.0)
		return
	var ratio: float = clampf(remaining_s / total_s, 0.0, 1.0)
	_cooldown_overlay.visible = ratio > 0.001
	if _overlay_material != null:
		_overlay_material.set_shader_parameter("cooldown_ratio", ratio)


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
