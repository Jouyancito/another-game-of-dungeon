extends Node
## LootStyle — single source of truth para el look de labels en mundo
## (items en suelo, oro, tooltips world-space). Autoload: LootStyle.
##
## Usar desde cualquier drop/UI:
##   LootStyle.style_world_label(label_3d, "Texto\n[owner:Pepe]", Color.WHITE, 2)
##   LootStyle.build_label_bg(parent, label_3d, 2, LootStyle.BG_ITEM_DARK)

# ── Constantes de estilo ──────────────────────────────────────────────
const PIXEL_SIZE: float = 0.0038
const FONT_SIZE: int = 20
const OUTLINE_SIZE: int = 3
const LABEL_WIDTH: float = 400.0
const PAD_X: float = 0.08
const PAD_Y: float = 0.035
const TEXT_WIDTH_CAP_PX: float = 240.0

# Colores de fondo preset
const BG_ITEM_DARK := Color(0.05, 0.05, 0.1, 0.75)     # items genericos
const BG_GOLD_DARK := Color(0.12, 0.09, 0.02, 0.78)    # oro (tinte dorado oscuro)
const BG_QUEST_DARK := Color(0.15, 0.04, 0.04, 0.82)   # quest/bind items (rojizo)


## Configura un Label3D existente con el estilo canonico world-space.
## `color` modula el texto (tipicamente color de rareza).
func style_world_label(label: Label3D, text: String, color: Color, occlude: bool = true) -> void:
	if label == null:
		return
	label.text = text
	label.modulate = color
	label.fixed_size = false
	label.pixel_size = PIXEL_SIZE
	label.font_size = FONT_SIZE
	label.outline_size = OUTLINE_SIZE
	label.no_depth_test = not occlude       # false = ocluible por paredes
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label.width = LABEL_WIDTH
	label.render_priority = 1


## Crea un MeshInstance3D con QuadMesh como fondo del label.
## Auto-sizea segun lineas del texto + padding. Devuelve el node
## (invisible por default — llamar .visible = true desde show_label).
func build_label_bg(parent: Node3D, label: Label3D, lines: int, bg_color: Color = BG_ITEM_DARK, occlude: bool = true) -> MeshInstance3D:
	var bg := MeshInstance3D.new()
	bg.name = "LabelBackground"
	var quad := QuadMesh.new()
	quad.size = _bg_size_for_lines(label, lines)
	bg.mesh = quad

	var mat := StandardMaterial3D.new()
	mat.albedo_color = bg_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = not occlude
	mat.render_priority = 0
	bg.material_override = mat

	bg.position = label.position
	parent.add_child(bg)
	bg.visible = false
	# Guardar ref en meta para show_label/hide_label consumers
	label.set_meta("background_node", bg)
	return bg


## Re-ajusta el QuadMesh del bg cuando el texto cambia de numero de lineas.
func resize_label_bg(bg: MeshInstance3D, label: Label3D, lines: int) -> void:
	if bg == null or label == null:
		return
	var quad := bg.mesh as QuadMesh
	if quad == null:
		return
	quad.size = _bg_size_for_lines(label, lines)


## Conveniencia — muestra label + bg juntos.
func show_label_with_bg(label: Label3D) -> void:
	if label == null:
		return
	label.visible = true
	var bg: Variant = label.get_meta("background_node", null)
	if bg != null and bg is MeshInstance3D:
		(bg as MeshInstance3D).visible = true


func hide_label_with_bg(label: Label3D) -> void:
	if label == null:
		return
	label.visible = false
	var bg: Variant = label.get_meta("background_node", null)
	if bg != null and bg is MeshInstance3D:
		(bg as MeshInstance3D).visible = false


# ── Helpers privados ──────────────────────────────────────────────────

func _bg_size_for_lines(label: Label3D, lines: int) -> Vector2:
	var line_h: float = float(label.font_size) * label.pixel_size
	var text_w: float = min(float(label.width), TEXT_WIDTH_CAP_PX) * label.pixel_size
	return Vector2(maxf(0.45, text_w + PAD_X), line_h * maxi(lines, 1) + PAD_Y)
