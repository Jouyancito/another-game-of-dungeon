extends Control
class_name EquipmentPanel

# Panel de paper doll — muestra los 12 slots de equipamiento alrededor de una
# silueta humanoide. Abre junto con el inventario al presionar TAB.

@export var tooltip_max_width: float = 280.0  # cap ancho tooltip

# --- Datos de equipamiento ---
var equipped: Dictionary = {}  # slot_name -> item_id (vacío = nada)

const SLOT_NAMES := {
	"head":      "Cabeza",
	"chest":     "Pecho",
	"legs":      "Piernas",
	"feet":      "Pies",
	"hands":     "Manos",
	"belt":      "Cinturón",
	"main_hand": "Arma",
	"off_hand":  "Secundaria",
	"ring_1":    "Anillo",
	"ring_2":    "Anillo",
	"amulet":    "Amuleto",
	"cape":      "Capa",
}

# --- Layout interno del PaperDoll (coordenadas dentro del Control de 280x380) ---
# Cada slot: [x, y] del centro; los rects serán 50x50 centrados ahí.
const SLOT_SIZE := Vector2(50.0, 50.0)

const SLOT_POSITIONS := {
	"head":      Vector2(140, 40),
	"cape":      Vector2(55,  100),
	"amulet":    Vector2(225, 100),
	"main_hand": Vector2(40,  175),
	"chest":     Vector2(140, 175),
	"off_hand":  Vector2(240, 175),
	"belt":      Vector2(140, 250),
	"ring_1":    Vector2(50,  310),
	"legs":      Vector2(140, 310),
	"ring_2":    Vector2(230, 310),
	"hands":     Vector2(50,  370),
	"feet":      Vector2(230, 370),
}

# Colores base
const COLOR_BG_SLOT   := Color(0.12, 0.12, 0.15, 1.0)
const COLOR_BORDER    := Color(0.30, 0.30, 0.35, 1.0)
const COLOR_HOVER     := Color(1.0, 1.0, 1.0, 0.10)
const COLOR_SILHOUETTE := Color(0.22, 0.22, 0.27, 1.0)
const COLOR_LABEL     := Color(0.45, 0.45, 0.50, 1.0)
const COLOR_FLASH_FAIL := Color(0.9, 0.15, 0.15, 0.55)
const FLASH_DURATION := 0.45

# --- Estado interno ---
var _hovered_slot: String = ""
var _paper_doll: Control = null  # nodo de dibujo
var _player: Node = null  # referencia al jugador para leer equipment

# Flash visual cuando unequip falla (inventario lleno)
var _flash_slot: String = ""
var _flash_time_left: float = 0.0

# Context menu para right-click sobre slot equipado
var _context_menu: PopupMenu = null
var _context_slot: String = ""

# Tooltip
@onready var _tooltip: PanelContainer     = $Tooltip
@onready var _tooltip_label: RichTextLabel = $Tooltip/MarginContainer/TooltipLabel


func _ready() -> void:
	# Somos un Control puro — no CanvasLayer. El InventoryUI nos maneja.
	visible = false
	_build_ui()
	_build_context_menu()
	_tooltip.custom_minimum_size = Vector2(tooltip_max_width, 0)
	_tooltip_label.custom_minimum_size = Vector2(tooltip_max_width - 16.0, 0)  # 16 = 2*8 margin
	set_process(false)


func _build_context_menu() -> void:
	_context_menu = PopupMenu.new()
	_context_menu.name = "SlotContextMenu"
	_context_menu.id_pressed.connect(_on_context_menu_item)
	add_child(_context_menu)


func _process(delta: float) -> void:
	if _flash_time_left <= 0.0:
		set_process(false)
		return
	_flash_time_left -= delta
	if _paper_doll:
		_paper_doll.queue_redraw()
	if _flash_time_left <= 0.0:
		_flash_slot = ""
		set_process(false)


func _build_ui() -> void:
	# --- Panel draggable ---
	var panel := PanelContainer.new()
	panel.set_script(load("res://scenes/ui/draggable_window.gd"))
	panel.name = "Panel"

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	style.corner_radius_top_left    = 8
	style.corner_radius_top_right   = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left  = 8
	panel.add_theme_stylebox_override("panel", style)

	# Posición: apoyado arriba del inventario, mismo borde derecho (estilo PoE)
	# Inventario está en bottom-right con offset_top = -370, así que el equipment
	# termina 4px arriba de eso y se extiende hacia arriba.
	panel.anchor_left   = 1.0
	panel.anchor_top    = 1.0
	panel.anchor_right  = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = -310.0
	panel.offset_top    = -824.0
	panel.offset_right  = -10.0
	panel.offset_bottom = -374.0
	add_child(panel)

	# --- Margin ---
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_top",    10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	# --- VBox ---
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# --- Drag bar ---
	var drag_bar := Label.new()
	drag_bar.name = "DragBar"
	drag_bar.text = "═══ Equipo ═══"
	drag_bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drag_bar.add_theme_font_size_override("font_size", 11)
	drag_bar.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	vbox.add_child(drag_bar)

	# --- Paper doll Control (dibujo custom) ---
	var doll := Control.new()
	doll.name = "PaperDoll"
	doll.custom_minimum_size = Vector2(280.0, 430.0)
	doll.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(doll)

	doll.draw.connect(_draw_paper_doll.bind(doll))
	doll.gui_input.connect(_on_doll_input.bind(doll))
	doll.mouse_exited.connect(_on_doll_mouse_exited)
	doll.set_drag_forwarding(
		_doll_get_drag_data,
		_doll_can_drop_data,
		_doll_drop_data,
	)
	_paper_doll = doll


# ---------------------------------------------------------------------------
# Dibujo del paper doll
# ---------------------------------------------------------------------------
func _draw_paper_doll(doll: Control) -> void:
	_draw_silhouette(doll)
	_draw_slots(doll)


func _draw_silhouette(doll: Control) -> void:
	var col := COLOR_SILHOUETTE
	var cx  := 140.0

	# Cabeza (círculo simulado con polígono)
	var head_center := Vector2(cx, 55.0)
	var head_r      := 18.0
	var pts: PackedVector2Array = []
	for i in range(16):
		var angle := (TAU / 16.0) * i
		pts.append(head_center + Vector2(cos(angle), sin(angle)) * head_r)
	doll.draw_colored_polygon(pts, col)

	# Cuello
	doll.draw_rect(Rect2(cx - 6, 73, 12, 12), col)

	# Torso
	doll.draw_rect(Rect2(cx - 30, 85, 60, 85), col)

	# Brazo izquierdo
	doll.draw_rect(Rect2(cx - 55, 88, 22, 70), col)
	# Mano izquierda
	doll.draw_rect(Rect2(cx - 60, 158, 28, 18), col)

	# Brazo derecho
	doll.draw_rect(Rect2(cx + 33, 88, 22, 70), col)
	# Mano derecha
	doll.draw_rect(Rect2(cx + 32, 158, 28, 18), col)

	# Cadera
	doll.draw_rect(Rect2(cx - 28, 170, 56, 22), col)

	# Pierna izquierda
	doll.draw_rect(Rect2(cx - 28, 192, 24, 90), col)
	# Pierna derecha
	doll.draw_rect(Rect2(cx + 4,  192, 24, 90), col)

	# Pie izquierdo
	doll.draw_rect(Rect2(cx - 33, 282, 32, 14), col)
	# Pie derecho
	doll.draw_rect(Rect2(cx + 1,  282, 32, 14), col)


func _draw_slots(doll: Control) -> void:
	var font      := ThemeDB.fallback_font
	var font_size := 10

	for slot_key in SLOT_POSITIONS.keys():
		var center: Vector2 = SLOT_POSITIONS[slot_key]
		var rect := Rect2(center - SLOT_SIZE * 0.5, SLOT_SIZE)

		# Fondo del slot
		doll.draw_rect(rect, COLOR_BG_SLOT)

		# Hover
		if _hovered_slot == slot_key:
			doll.draw_rect(rect, COLOR_HOVER)

		# Flash rojo — unequip falló (inventario lleno)
		if _flash_slot == slot_key and _flash_time_left > 0.0:
			var flash_col := COLOR_FLASH_FAIL
			flash_col.a = COLOR_FLASH_FAIL.a * (_flash_time_left / FLASH_DURATION)
			doll.draw_rect(rect, flash_col)

		# Borde
		var border_col := COLOR_BORDER
		var item_id: String = equipped.get(slot_key, "")
		if item_id != "":
			var item_data: Dictionary = ItemDatabase.get_item(item_id)
			if not item_data.is_empty():
				var rarity: String = item_data.get("rarity", "common")
				border_col = ItemDatabase.get_rarity_color(rarity)
		doll.draw_rect(rect, border_col, false, 1.0)

		# Contenido del slot
		if item_id != "":
			var item_data: Dictionary = ItemDatabase.get_item(item_id)
			if not item_data.is_empty():
				var fill := ItemDatabase.get_rarity_color(item_data.get("rarity", "common"))
				fill.a = 0.45
				var inner := rect.grow(-3)
				doll.draw_rect(inner, fill)

				var name_text: String = item_data.get("name", item_id)
				doll.draw_string(
					font,
					Vector2(inner.position.x + 2, inner.position.y + font_size + 2),
					name_text,
					HORIZONTAL_ALIGNMENT_LEFT,
					inner.size.x - 4,
					font_size,
					Color(1, 1, 1, 0.9)
				)

		# Etiqueta del slot debajo
		var label_text: String = SLOT_NAMES.get(slot_key, slot_key)
		var label_y := rect.position.y + SLOT_SIZE.y + font_size + 1
		doll.draw_string(
			font,
			Vector2(rect.position.x, label_y),
			label_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			SLOT_SIZE.x,
			font_size,
			COLOR_LABEL
		)


# ---------------------------------------------------------------------------
# Input sobre el paper doll
# ---------------------------------------------------------------------------
func _on_doll_input(event: InputEvent, doll: Control) -> void:
	if event is InputEventMouseMotion:
		var new_hover := _slot_at(event.position)
		if new_hover != _hovered_slot:
			_hovered_slot = new_hover
			doll.queue_redraw()
			_update_tooltip(new_hover, event.global_position)
		return

	if event is InputEventMouseButton and event.pressed:
		var slot_key := _slot_at(event.position)
		if slot_key == "":
			return
		# Double-click = atajo directo; right-click = menú contextual
		if event.double_click:
			_try_unequip(slot_key)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_open_context_menu(slot_key, event.global_position)


func _open_context_menu(slot_key: String, global_pos: Vector2) -> void:
	# Solo abrir menú si el slot tiene un item equipado
	if equipped.get(slot_key, "") == "":
		return
	_context_slot = slot_key
	_context_menu.clear()
	_context_menu.add_item("Desequipar", 0)
	_tooltip.visible = false
	_context_menu.popup(Rect2i(int(global_pos.x), int(global_pos.y), 0, 0))


func _on_context_menu_item(id: int) -> void:
	if _context_slot == "":
		return
	match id:
		0:
			_try_unequip(_context_slot)
	_context_slot = ""


func _try_unequip(slot_key: String) -> void:
	if _player == null or not _player.has_method("unequip_slot"):
		return
	var success: bool = _player.unequip_slot(slot_key)
	if not success:
		# Inventario lleno (o sin item) — feedback visual rojo
		flash_slot_fail(slot_key)
		return
	_tooltip.visible = false
	if _paper_doll:
		_paper_doll.queue_redraw()


## Dispara flash rojo sobre el slot — feedback de unequip fallido.
## Público para que inventory_ui pueda llamarlo al fallar el drag out.
func flash_slot_fail(slot_key: String) -> void:
	if slot_key == "" or not SLOT_POSITIONS.has(slot_key):
		return
	_flash_slot = slot_key
	_flash_time_left = FLASH_DURATION
	set_process(true)
	if _paper_doll:
		_paper_doll.queue_redraw()


func _on_doll_mouse_exited() -> void:
	_hovered_slot = ""
	_tooltip.visible = false
	if _paper_doll:
		_paper_doll.queue_redraw()


func _slot_at(local_pos: Vector2) -> String:
	for slot_key in SLOT_POSITIONS.keys():
		var center: Vector2 = SLOT_POSITIONS[slot_key]
		var rect := Rect2(center - SLOT_SIZE * 0.5, SLOT_SIZE)
		if rect.has_point(local_pos):
			return slot_key
	return ""


func _update_tooltip(slot_key: String, global_mouse: Vector2) -> void:
	if slot_key == "":
		_tooltip.visible = false
		return

	var item_id: String = equipped.get(slot_key, "")
	# Slot vacío → NO mostrar tooltip (nada útil que mostrar)
	if item_id == "":
		_tooltip.visible = false
		return

	var slot_label: String = SLOT_NAMES.get(slot_key, slot_key)
	var item_data: Dictionary = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		_tooltip.visible = false
		return

	var rarity: String = item_data.get("rarity", "common")
	var rarity_hex: String = _rarity_color_hex(rarity)
	var item_name: String = item_data.get("name", item_id)
	var desc: String = item_data.get("description", "")

	var text: String = "[color=#888888]%s[/color]\n[color=#%s][b]%s[/b][/color]\n%s" % [
		slot_label, rarity_hex, item_name, desc
	]
	var stats: Dictionary = item_data.get("stats", {})
	for stat_key in stats.keys():
		text += "\n+%s %s" % [stats[stat_key], stat_key]
	text += "\n[color=#%s]Rareza: %s[/color]" % [rarity_hex, rarity]

	_tooltip_label.text = text
	_tooltip.reset_size()
	_tooltip.visible = true

	var vp_size := get_viewport().get_visible_rect().size
	var tip_size := _tooltip.get_combined_minimum_size()
	var tip_pos  := global_mouse + Vector2(14, 14)
	if tip_pos.x + tip_size.x > vp_size.x:
		tip_pos.x = global_mouse.x - tip_size.x - 8
	if tip_pos.y + tip_size.y > vp_size.y:
		tip_pos.y = global_mouse.y - tip_size.y - 8
	_tooltip.global_position = tip_pos


func _rarity_color_hex(rarity: String) -> String:
	var c: Color = ItemDatabase.RARITY_COLORS.get(rarity, Color.WHITE)
	return c.to_html(false)


# ---------------------------------------------------------------------------
# API pública
# ---------------------------------------------------------------------------

## Conecta el panel al jugador. Llamar después de instanciar el panel.
func setup(player: Node) -> void:
	_player = player
	if player.has_signal("equipment_changed"):
		player.equipment_changed.connect(refresh)
	refresh()


func equip_item(slot_key: String, item_id: String) -> void:
	if not SLOT_NAMES.has(slot_key):
		return
	equipped[slot_key] = item_id
	if _paper_doll:
		_paper_doll.queue_redraw()


func unequip_slot(slot_key: String) -> void:
	equipped.erase(slot_key)
	if _paper_doll:
		_paper_doll.queue_redraw()


func refresh() -> void:
	# Sincronizar equipped desde el equipamiento real del jugador
	if _player != null and _player.get("equipment") != null:
		var eq = _player.equipment
		equipped.clear()
		for slot_key in eq.slots:
			var entry: Dictionary = eq.slots[slot_key]
			if not entry.is_empty():
				equipped[slot_key] = entry.get("item_id", "")
	if _paper_doll:
		_paper_doll.queue_redraw()


# ---------------------------------------------------------------------------
# Drag & Drop — paper doll ↔ inventario
# ---------------------------------------------------------------------------
func _doll_get_drag_data(at_position: Vector2) -> Variant:
	var slot_key := _slot_at(at_position)
	if slot_key == "":
		return null
	var item_id: String = equipped.get(slot_key, "")
	if item_id == "":
		return null

	var item_data: Dictionary = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return null

	# Preview visual del item arrastrado
	var preview := Panel.new()
	preview.custom_minimum_size = Vector2(120, 40)
	var rarity: String = item_data.get("rarity", "common")
	var style := StyleBoxFlat.new()
	var fill: Color = ItemDatabase.get_rarity_color(rarity)
	fill.a = 0.75
	style.bg_color = fill
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = ItemDatabase.get_rarity_color(rarity)
	preview.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = item_data.get("name", item_id)
	label.add_theme_font_size_override("font_size", 10)
	label.position = Vector2(4, 2)
	label.size = Vector2(preview.custom_minimum_size.x - 8, 16)
	label.clip_text = true
	preview.add_child(label)

	_paper_doll.set_drag_preview(preview)
	_tooltip.visible = false

	return {
		"source": "equipment_panel",
		"slot_key": slot_key,
		"item_id": item_id,
	}


func _doll_can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if data.get("source", "") != "inventory_grid":
		return false
	var item_id: String = data.get("item_id", "")
	if item_id == "":
		return false
	var item_data: Dictionary = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return false
	# Solo items equipables (con slot definido en la database)
	if item_data.get("slot", "") == "":
		return false
	# Chequeo adicional: el slot bajo el mouse debe existir
	var target_slot := _slot_at(at_position)
	return target_slot != ""


func _doll_drop_data(at_position: Vector2, data: Variant) -> void:
	if _player == null or not _player.has_method("equip_item"):
		return
	var item_id: String = data.get("item_id", "")
	var from_pos: Vector2i = data.get("from_pos", Vector2i.ZERO)
	if item_id == "":
		return
	_player.equip_item(item_id, from_pos)
	if _paper_doll:
		_paper_doll.queue_redraw()
