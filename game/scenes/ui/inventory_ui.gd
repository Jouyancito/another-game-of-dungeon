extends CanvasLayer

# Inventario Diablo 2 estilo — toggle con TAB, click para mover, right-click para contexto

@export var cell_size := 50
@export var grid_cols := 10
@export var grid_rows := 6

# Referencia al inventario lógico del jugador
var inventory: Inventory = null

# Estado de selección
var _selected_entry: Dictionary = {}   # entry activo para mover
var _hovered_pos := Vector2i(-1, -1)   # celda bajo el mouse

# Sub-nodos (asignados en _ready desde la escena)
@onready var _bg: ColorRect = $Background
@onready var _grid_panel: Control = $Background/VBoxContainer/GridPanel
@onready var _coin_label: Label = $Background/VBoxContainer/FooterRow/CoinLabel
@onready var _close_btn: Button = $Background/VBoxContainer/TitleRow/CloseBtn
@onready var _tooltip: PanelContainer = $Tooltip
@onready var _tooltip_label: Label = $Tooltip/MarginContainer/TooltipLabel
@onready var _context_menu: PopupMenu = $ContextMenu


func _ready() -> void:
	layer = 10
	visible = false

	_tooltip.visible = false
	_context_menu.visible = false

	_close_btn.pressed.connect(_close)
	_context_menu.id_pressed.connect(_on_context_menu_item)

	_grid_panel.custom_minimum_size = Vector2(grid_cols * cell_size, grid_rows * cell_size)
	_grid_panel.draw.connect(_draw_grid)
	_grid_panel.gui_input.connect(_on_grid_input)
	_grid_panel.mouse_exited.connect(_on_grid_mouse_exited)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			toggle()
			get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		_close()
	else:
		_open()


func _open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()


func _close() -> void:
	visible = false
	_selected_entry = {}
	_tooltip.visible = false
	# Si el pause menu también está cerrado, volver a capturar el mouse
	var pause_menu = _find_pause_menu()
	if pause_menu == null or not pause_menu.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _find_pause_menu() -> Control:
	for child in get_tree().current_scene.get_children():
		if child.get_script() != null:
			var path: String = child.get_script().resource_path
			if "pause_menu" in path:
				return child as Control
	return null


func _refresh() -> void:
	if inventory == null:
		return
	_coin_label.text = "Monedas: %d" % inventory.coins
	_grid_panel.queue_redraw()


# Dibuja el grid y los items como rectángulos coloreados
func _draw_grid() -> void:
	if inventory == null:
		return

	# Celdas de fondo
	for row in range(grid_rows):
		for col in range(grid_cols):
			var rect := Rect2(col * cell_size, row * cell_size, cell_size, cell_size)
			_grid_panel.draw_rect(rect, Color(0.15, 0.15, 0.15, 1.0))
			_grid_panel.draw_rect(rect, Color(0.35, 0.35, 0.35, 1.0), false)

	# Hover highlight
	if _hovered_pos.x >= 0:
		var rect := Rect2(_hovered_pos.x * cell_size, _hovered_pos.y * cell_size, cell_size, cell_size)
		_grid_panel.draw_rect(rect, Color(1.0, 1.0, 1.0, 0.08))

	# Items colocados
	var drawn_ids: Array = []
	for entry in inventory.items:
		if drawn_ids.has(entry):
			continue
		drawn_ids.append(entry)

		var item_data := ItemDatabase.get_item(entry["item_id"])
		if item_data.is_empty():
			continue

		var size: Vector2i = item_data["grid_size"]
		var anchor: Vector2i = entry["grid_pos"]
		var rarity: String = item_data.get("rarity", "common")
		var fill_color := ItemDatabase.get_rarity_color(rarity)
		fill_color.a = 0.55

		var is_selected: bool = (_selected_entry == entry)

		var rect := Rect2(
			anchor.x * cell_size + 2,
			anchor.y * cell_size + 2,
			size.x * cell_size - 4,
			size.y * cell_size - 4
		)

		_grid_panel.draw_rect(rect, fill_color)

		# Borde de rareza (más grueso si está seleccionado)
		var border_color := ItemDatabase.get_rarity_color(rarity)
		var border_width := 3 if is_selected else 1
		_grid_panel.draw_rect(rect, border_color, false, border_width)

		# Nombre del item (abreviado si no cabe)
		var name_text: String = item_data.get("name", entry["item_id"])
		if entry["quantity"] > 1:
			name_text += " x%d" % entry["quantity"]
		var font := ThemeDB.fallback_font
		var font_size := 10
		_grid_panel.draw_string(
			font,
			Vector2(rect.position.x + 3, rect.position.y + font_size + 2),
			name_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 6,
			font_size,
			Color(1, 1, 1, 1)
		)


func _on_grid_input(event: InputEvent) -> void:
	if inventory == null:
		return

	if event is InputEventMouseMotion:
		var pos := _pixel_to_grid(event.position)
		if pos != _hovered_pos:
			_hovered_pos = pos
			_grid_panel.queue_redraw()
			_update_tooltip(pos, event.global_position)

	elif event is InputEventMouseButton and event.pressed:
		var pos := _pixel_to_grid(event.position)

		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_left_click(pos, event)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_on_right_click(pos, event)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			_on_double_click(pos)


func _on_grid_mouse_exited() -> void:
	_hovered_pos = Vector2i(-1, -1)
	_tooltip.visible = false
	_grid_panel.queue_redraw()


func _on_left_click(pos: Vector2i, event: InputEventMouseButton) -> void:
	if event.double_click:
		_on_double_click(pos)
		return

	if _selected_entry.is_empty():
		# Seleccionar item en esa celda
		var entry := inventory.get_item_at(pos)
		if not entry.is_empty():
			_selected_entry = entry
			_grid_panel.queue_redraw()
	else:
		# Intentar mover el item seleccionado a la nueva posición
		var item_id: String = _selected_entry["item_id"]
		var old_pos: Vector2i = _selected_entry["grid_pos"]
		var qty: int = _selected_entry["quantity"]

		if pos == old_pos:
			_selected_entry = {}
			_grid_panel.queue_redraw()
			return

		# Quitar temporalmente para ver si cabe
		inventory.remove_item_at(old_pos)
		if inventory.can_place_item(item_id, pos):
			inventory.place_item(item_id, pos, qty)
			_selected_entry = {}
		else:
			# No cabe — devolver al lugar original
			inventory.place_item(item_id, old_pos, qty)

		_grid_panel.queue_redraw()


func _on_right_click(pos: Vector2i, _event: InputEventMouseButton) -> void:
	var entry := inventory.get_item_at(pos)
	if entry.is_empty():
		return

	var item_data := ItemDatabase.get_item(entry["item_id"])

	_context_menu.clear()
	_context_menu.set_meta("entry_pos", pos)
	_context_menu.add_item("Soltar", 0)

	var is_consumable: bool = item_data.get("type", "") == "consumable"
	if is_consumable:
		_context_menu.add_item("Usar", 1)

	_context_menu.popup(Rect2i(
		int(get_viewport().get_mouse_position().x),
		int(get_viewport().get_mouse_position().y),
		0, 0
	))


func _on_double_click(pos: Vector2i) -> void:
	var entry := inventory.get_item_at(pos)
	if entry.is_empty():
		return
	var item_data := ItemDatabase.get_item(entry["item_id"])
	print("Equipar (placeholder): ", item_data.get("name", entry["item_id"]))


func _on_context_menu_item(id: int) -> void:
	var pos: Vector2i = _context_menu.get_meta("entry_pos", Vector2i(-1, -1))
	if pos.x < 0:
		return

	match id:
		0: # Soltar
			var entry := inventory.remove_item_at(pos)
			if not entry.is_empty():
				print("Drop: ", entry["item_id"])
			_grid_panel.queue_redraw()
		1: # Usar
			var entry := inventory.get_item_at(pos)
			if not entry.is_empty():
				_use_item(entry, pos)


func _use_item(entry: Dictionary, pos: Vector2i) -> void:
	var item_data := ItemDatabase.get_item(entry["item_id"])
	if item_data.is_empty():
		return

	var heal: int = item_data.get("stats", {}).get("heal", 0)
	if heal > 0:
		var player := _find_player()
		if player != null and player.has_method("heal"):
			player.heal(float(heal))
			print("Usaste: ", item_data.get("name", ""), " — cura %d HP" % heal)
		else:
			print("Usaste: ", item_data.get("name", ""), " — sin jugador para curar")

	# Reducir cantidad o eliminar
	if entry["quantity"] > 1:
		entry["quantity"] -= 1
	else:
		inventory.remove_item_at(pos)

	_grid_panel.queue_redraw()
	_refresh()


func _find_player() -> Node:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null


func _update_tooltip(pos: Vector2i, global_mouse: Vector2) -> void:
	if pos.x < 0:
		_tooltip.visible = false
		return

	var entry := inventory.get_item_at(pos)
	if entry.is_empty():
		_tooltip.visible = false
		return

	var item_data := ItemDatabase.get_item(entry["item_id"])
	if item_data.is_empty():
		_tooltip.visible = false
		return

	var text := "[%s]\n%s\n" % [item_data.get("name", ""), item_data.get("description", "")]
	var stats: Dictionary = item_data.get("stats", {})
	for stat_key in stats.keys():
		text += "+%s %s\n" % [stats[stat_key], stat_key]
	var rarity: String = item_data.get("rarity", "common")
	text += "Rareza: %s" % rarity

	_tooltip_label.text = text
	_tooltip.visible = true

	var vp_size := get_viewport().get_visible_rect().size
	var tip_size := _tooltip.get_combined_minimum_size()
	var tip_pos := global_mouse + Vector2(14, 14)
	if tip_pos.x + tip_size.x > vp_size.x:
		tip_pos.x = global_mouse.x - tip_size.x - 8
	if tip_pos.y + tip_size.y > vp_size.y:
		tip_pos.y = global_mouse.y - tip_size.y - 8
	_tooltip.global_position = tip_pos


func _pixel_to_grid(pixel: Vector2) -> Vector2i:
	var col := int(pixel.x / cell_size)
	var row := int(pixel.y / cell_size)
	if col < 0 or col >= grid_cols or row < 0 or row >= grid_rows:
		return Vector2i(-1, -1)
	return Vector2i(col, row)
