extends CanvasLayer

# Inventario Diablo 2 estilo — toggle con TAB, click para mover, right-click para contexto

@export var cell_size := 45
@export var grid_cols := 12
@export var grid_rows := 7
@export var tooltip_max_width: float = 280.0  # cap ancho tooltip (wrap kicks in at this width)

# Referencia al inventario lógico del jugador
var inventory: Inventory = null

var _hovered_pos := Vector2i(-1, -1)   # celda bajo el mouse

# Drag state — para detectar drop fuera de UI (soltar al mundo)
var _last_drag_data: Dictionary = {}
var _was_dragging := false
var _drag_cancelled := false   # set por _unhandled_key_input si se presiona Escape mid-drag

# Click-to-toggle — click agarra el item, click en otra celda lo suelta
var _held_entry: Dictionary = {}

# Preview de destino al arrastrar — muestra borde donde caería el item
var _drag_preview_item_id: String = ""  # id del item siendo arrastrado (para saber su grid_size)

# Referencia al jugador conectado a equipment_changed — para poder desconectar
var _connected_player: Node = null

# Panel de equipamiento (paper doll) — se abre/cierra junto al inventario
var _equipment_panel: EquipmentPanel = null

# Sub-nodos (asignados en _ready desde la escena)
@onready var _background: PanelContainer = $Background
@onready var _title_row: HBoxContainer = $Background/VBoxContainer/TitleRow
@onready var _grid_panel: Control = $Background/VBoxContainer/GridPanel
@onready var _coin_label: Label = $Background/VBoxContainer/FooterRow/CoinLabel
@onready var _close_btn: Button = $Background/VBoxContainer/TitleRow/CloseBtn
@onready var _tooltip: PanelContainer = $Tooltip
@onready var _tooltip_label: RichTextLabel = $Tooltip/MarginContainer/TooltipLabel
@onready var _context_menu: PopupMenu = $ContextMenu

# Drag state para mover la ventana entera (canon UX: inventory no debe tapar
# el HUD, el user arrastra del título).
var _window_dragging: bool = false
var _window_drag_offset: Vector2 = Vector2.ZERO
var _window_unanchored: bool = false


func _ready() -> void:
	layer = 10
	visible = false

	_tooltip.visible = false
	_tooltip.custom_minimum_size = Vector2(tooltip_max_width, 0)
	_tooltip_label.custom_minimum_size = Vector2(tooltip_max_width - 16.0, 0)  # 16 = 2*8 margin
	_context_menu.visible = false

	_close_btn.pressed.connect(_close)
	_context_menu.id_pressed.connect(_on_context_menu_item)

	_grid_panel.custom_minimum_size = Vector2(grid_cols * cell_size, grid_rows * cell_size)
	_grid_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_grid_panel.draw.connect(_draw_grid)
	_grid_panel.gui_input.connect(_on_grid_input)
	_grid_panel.mouse_exited.connect(_on_grid_mouse_exited)
	_grid_panel.set_drag_forwarding(
		_grid_get_drag_data,
		_grid_can_drop_data,
		_grid_drop_data,
	)

	# Instanciar el panel de equipamiento como hijo de este CanvasLayer
	var eq_scene := load("res://scenes/ui/equipment_panel.tscn") as PackedScene
	if eq_scene:
		_equipment_panel = eq_scene.instantiate() as EquipmentPanel
		add_child(_equipment_panel)

	# Wire drag en el TitleRow — el user agarra del título y arrastra.
	_title_row.mouse_filter = Control.MOUSE_FILTER_STOP
	_title_row.gui_input.connect(_on_title_drag_input)


func _on_title_drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_window_dragging = true
			_window_drag_offset = _background.get_global_mouse_position() - _background.global_position
			_unanchor_window()
		else:
			_window_dragging = false
	if event is InputEventMouseMotion and _window_dragging:
		var new_pos: Vector2 = _background.get_global_mouse_position() - _window_drag_offset
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		# Clampear al viewport para que no se pierda la ventana fuera de pantalla.
		new_pos.x = clampf(new_pos.x, -_background.size.x + 80.0, viewport_size.x - 80.0)
		new_pos.y = clampf(new_pos.y, 0.0, viewport_size.y - 40.0)
		_background.global_position = new_pos


func _unanchor_window() -> void:
	if _window_unanchored:
		return
	_window_unanchored = true
	var cur_pos: Vector2 = _background.global_position
	_background.anchor_left = 0.0
	_background.anchor_top = 0.0
	_background.anchor_right = 0.0
	_background.anchor_bottom = 0.0
	_background.global_position = cur_pos


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and get_viewport().gui_is_dragging():
			# Escape mid-drag = cancelar — flag para que _handle_drag_end no suelte al mundo
			_drag_cancelled = true


func _process(_delta: float) -> void:
	# Detectar drag end — si el drag vino de este inventario y no fue "drop exitoso"
	# y el mouse está fuera de la UI, soltamos el item al mundo.
	if not visible:
		return
	var is_dragging := get_viewport().gui_is_dragging()
	if _was_dragging and not is_dragging:
		_handle_drag_end()
		_drag_preview_item_id = ""
		_grid_panel.queue_redraw()
	_was_dragging = is_dragging


func _handle_drag_end() -> void:
	if _last_drag_data.is_empty():
		_drag_cancelled = false
		return
	# Guard: no inventory → no-op (puede pasar si la sesión aún no cableó inventory)
	if inventory == null:
		_last_drag_data = {}
		_drag_cancelled = false
		return
	# Guard: Escape fue presionado durante el drag → cancelar sin soltar al mundo
	if _drag_cancelled:
		_last_drag_data = {}
		_drag_cancelled = false
		return
	# Guard extra: si el mouse LMB sigue presionado (drag abortado internamente), no soltar
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_last_drag_data = {}
		return

	var source: String = _last_drag_data.get("source", "")
	if source != "inventory_grid":
		_last_drag_data = {}
		return

	var item_id: String = _last_drag_data.get("item_id", "")
	var from_pos: Vector2i = _last_drag_data.get("from_pos", Vector2i.ZERO)
	var qty: int = _last_drag_data.get("quantity", 1)
	_last_drag_data = {}

	# ¿El item sigue en su posición original? Si NO, el drop ya fue consumido
	# (movimiento dentro del grid / equipado / etc) y no hay que hacer nada.
	var still_there: Dictionary = inventory.get_item_at(from_pos)
	if still_there.is_empty() or still_there.get("item_id", "") != item_id:
		return

	# El item sigue en su lugar → el drop no fue absorbido por ningún handler.
	# Chequear si el mouse está fuera de la UI → soltar al mundo.
	var mouse_pos := get_viewport().get_mouse_position()
	if _is_mouse_over_ui(mouse_pos):
		return

	var removed: Dictionary = inventory.remove_item_at(from_pos)
	if removed.is_empty():
		return

	_drop_item_to_world(item_id, qty)
	_grid_panel.queue_redraw()

	var player := _find_player()
	if player != null and player.has_method("_save_inventory"):
		player._save_inventory()


func _is_mouse_over_ui(mouse_pos: Vector2) -> bool:
	# Inventario (background del grid)
	var bg: Control = get_node_or_null("Background")
	if bg != null and bg.get_global_rect().has_point(mouse_pos):
		return true
	# Equipment panel — chequear el Panel raíz (el contenedor draggable), no solo el paper doll
	if _equipment_panel != null:
		var eq_panel: Control = _equipment_panel.get_node_or_null("Panel")
		if eq_panel != null and eq_panel.get_global_rect().has_point(mouse_pos):
			return true
	# Tooltip del inventario (si está visible)
	if _tooltip != null and _tooltip.visible and _tooltip.get_global_rect().has_point(mouse_pos):
		return true
	# Context menu (si está visible)
	if _context_menu != null and _context_menu.visible:
		var cm_rect := Rect2(Vector2(_context_menu.position), Vector2(_context_menu.size))
		if cm_rect.has_point(mouse_pos):
			return true
	return false


func toggle() -> void:
	if visible:
		_close()
	else:
		_open()


func _open() -> void:
	visible = true
	var player := _find_player()

	# Si la referencia cacheada es inválida (ej: jugador freed tras respawn/reload), limpiarla
	if _connected_player != null and not is_instance_valid(_connected_player):
		_connected_player = null
	if _equipment_panel and _equipment_panel._player != null and not is_instance_valid(_equipment_panel._player):
		_equipment_panel._player = null

	if _equipment_panel:
		_equipment_panel.visible = true
		# Conectar al jugador si no está cableado (o si cambió)
		if _equipment_panel._player == null and player != null:
			_equipment_panel.setup(player)

	# Conectar equipment_changed + item_picked_up al jugador actual
	# Estas señales refrescan el grid en vivo (equipar, recoger del mundo, etc)
	if player != null and player != _connected_player:
		if player.has_signal("equipment_changed") and not player.equipment_changed.is_connected(_on_equipment_changed):
			player.equipment_changed.connect(_on_equipment_changed)
		if player.has_signal("item_picked_up") and not player.item_picked_up.is_connected(_on_item_picked_up):
			player.item_picked_up.connect(_on_item_picked_up)
		_connected_player = player

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()


func _close() -> void:
	visible = false
	if _equipment_panel:
		_equipment_panel.visible = false
	_tooltip.visible = false
	# Limpiar estado de drag y click-to-toggle para que no quede stale
	_last_drag_data = {}
	_was_dragging = false
	_drag_cancelled = false
	_held_entry = {}
	# Desconectar equipment_changed + item_picked_up para evitar leak / crash si el jugador es freed
	if _connected_player != null and is_instance_valid(_connected_player):
		if _connected_player.has_signal("equipment_changed") and _connected_player.equipment_changed.is_connected(_on_equipment_changed):
			_connected_player.equipment_changed.disconnect(_on_equipment_changed)
		if _connected_player.has_signal("item_picked_up") and _connected_player.item_picked_up.is_connected(_on_item_picked_up):
			_connected_player.item_picked_up.disconnect(_on_item_picked_up)
	_connected_player = null
	# Si el pause menu también está cerrado, volver a capturar el mouse
	var pause_menu = _find_pause_menu()
	if pause_menu == null or not pause_menu.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_equipment_changed() -> void:
	# El jugador equipó / desequipó algo — refrescar el grid para reflejar cambios
	# (_refresh ya llama a queue_redraw, no duplicar)
	_refresh()


func _on_item_picked_up(_item_id: String, _quantity: int) -> void:
	# El jugador recogió un item del mundo — refrescar el grid en vivo
	_refresh()


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

	# Preview de destino al arrastrar — borde verde (cabe) / rojo (no cabe)
	if _drag_preview_item_id != "" and _hovered_pos.x >= 0:
		var preview_data: Dictionary = ItemDatabase.get_item(_drag_preview_item_id)
		if not preview_data.is_empty():
			var psize: Vector2i = preview_data["grid_size"]
			var preview_rect := Rect2(
				_hovered_pos.x * cell_size,
				_hovered_pos.y * cell_size,
				psize.x * cell_size,
				psize.y * cell_size
			)
			var fits := (_hovered_pos.x + psize.x <= grid_cols and _hovered_pos.y + psize.y <= grid_rows)
			var border_col: Color = Color(0.2, 0.9, 0.3, 0.7) if fits else Color(0.9, 0.2, 0.2, 0.7)
			_grid_panel.draw_rect(preview_rect, border_col, false, 2)
			if fits:
				var fill := Color(0.2, 0.9, 0.3, 0.08)
				_grid_panel.draw_rect(preview_rect, fill)

	# Items colocados
	var drawn_ids: Array = []
	for entry in inventory.items:
		if drawn_ids.has(entry):
			continue
		drawn_ids.append(entry)

		var item_data: Dictionary = ItemDatabase.get_item(entry["item_id"])
		if item_data.is_empty():
			continue

		var size: Vector2i = item_data["grid_size"]
		var anchor: Vector2i = entry["grid_pos"]
		var rarity: String = item_data.get("rarity", "common")
		var fill_color: Color = ItemDatabase.get_rarity_color(rarity)
		fill_color.a = 0.55

		var rect := Rect2(
			anchor.x * cell_size + 2,
			anchor.y * cell_size + 2,
			size.x * cell_size - 4,
			size.y * cell_size - 4
		)

		_grid_panel.draw_rect(rect, fill_color)

		# Borde: amarillo grueso si está "agarrado" por click, rareza si no
		var is_held: bool = (not _held_entry.is_empty() and entry == _held_entry)
		if is_held:
			_grid_panel.draw_rect(rect, Color(1, 0.95, 0.2, 1), false, 3)
		else:
			var border_color: Color = ItemDatabase.get_rarity_color(rarity)
			_grid_panel.draw_rect(rect, border_color, false, 1)

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
		# Note: double-click LEFT is already handled by _on_left_click → _on_double_click


func _on_grid_mouse_exited() -> void:
	_hovered_pos = Vector2i(-1, -1)
	_tooltip.visible = false
	_grid_panel.queue_redraw()


func _on_left_click(pos: Vector2i, event: InputEventMouseButton) -> void:
	if event.double_click:
		_on_double_click(pos)
		return

	# Click-to-toggle: primer click agarra el item, segundo click lo suelta
	# (funciona en paralelo al drag & drop — elegí el que prefieras)
	if _held_entry.is_empty():
		# Agarrar item en esta celda (si hay)
		var entry: Dictionary = inventory.get_item_at(pos)
		if not entry.is_empty():
			_held_entry = entry
			_grid_panel.queue_redraw()
	else:
		# Soltar el item agarrado en esta celda
		var item_id: String = _held_entry["item_id"]
		var from_pos: Vector2i = _held_entry["grid_pos"]
		var qty: int = _held_entry["quantity"]
		_held_entry = {}

		if pos == from_pos:
			_grid_panel.queue_redraw()
			return

		inventory.remove_item_at(from_pos)
		if inventory.can_place_item(item_id, pos):
			inventory.place_item(item_id, pos, qty)
		else:
			# No entra — devolver al lugar original
			inventory.place_item(item_id, from_pos, qty)

		_grid_panel.queue_redraw()
		var player := _find_player()
		if player != null and player.has_method("_save_inventory"):
			player._save_inventory()


# ---------------------------------------------------------------------------
# Drag & Drop — reemplaza el click-to-select viejo
# ---------------------------------------------------------------------------
func _grid_get_drag_data(at_position: Vector2) -> Variant:
	if inventory == null:
		return null
	var pos := _pixel_to_grid(at_position)
	if pos.x < 0:
		return null
	var entry: Dictionary = inventory.get_item_at(pos)
	if entry.is_empty():
		return null

	var item_data: Dictionary = ItemDatabase.get_item(entry["item_id"])
	if item_data.is_empty():
		return null

	# Preview visual — rectángulo coloreado del tamaño del item
	var size_cells: Vector2i = item_data["grid_size"]
	var preview := Panel.new()
	preview.custom_minimum_size = Vector2(
		size_cells.x * cell_size - 4,
		size_cells.y * cell_size - 4
	)
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
	label.text = item_data.get("name", entry["item_id"])
	label.add_theme_font_size_override("font_size", 10)
	label.position = Vector2(4, 2)
	label.size = Vector2(preview.custom_minimum_size.x - 8, 16)
	label.clip_text = true
	preview.add_child(label)

	_grid_panel.set_drag_preview(preview)
	_tooltip.visible = false
	# Si había un item "agarrado" por click, el drag lo anula
	_held_entry = {}
	# Guardar id para dibujar preview de destino en el grid
	_drag_preview_item_id = entry["item_id"]

	var drag_data := {
		"source": "inventory_grid",
		"item_id": entry["item_id"],
		"from_pos": entry["grid_pos"],
		"quantity": entry["quantity"],
	}
	_last_drag_data = drag_data.duplicate()
	return drag_data


func _grid_can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("item_id"):
		return false
	var pos := _pixel_to_grid(at_position)
	if pos.x < 0:
		return false
	var source: String = data.get("source", "")
	if source == "inventory_grid":
		return data.has("from_pos")
	elif source == "equipment_panel":
		return data.has("slot_key")
	return false


func _grid_drop_data(at_position: Vector2, data: Variant) -> void:
	if inventory == null:
		return
	var pos := _pixel_to_grid(at_position)
	if pos.x < 0:
		return

	var source: String = data.get("source", "")

	if source == "equipment_panel":
		# Drag desde equipment → unequip al inventario
		var slot_key: String = data.get("slot_key", "")
		if slot_key == "":
			return
		var player := _find_player()
		if player != null and player.has_method("unequip_slot"):
			var ok: bool = player.unequip_slot(slot_key)
			if not ok and _equipment_panel != null:
				_equipment_panel.flash_slot_fail(slot_key)
		_grid_panel.queue_redraw()
		return

	# source == "inventory_grid" — mover dentro del grid
	var item_id: String = data["item_id"]
	var from_pos: Vector2i = data["from_pos"]
	var quantity: int = data.get("quantity", 1)

	if pos == from_pos:
		return

	# Sacar temporalmente y probar si entra en la nueva posición
	inventory.remove_item_at(from_pos)
	if inventory.can_place_item(item_id, pos):
		inventory.place_item(item_id, pos, quantity)
	else:
		# No entra — devolver al lugar original
		inventory.place_item(item_id, from_pos, quantity)

	_grid_panel.queue_redraw()

	# Persistir el cambio
	var player := _find_player()
	if player != null and player.has_method("_save_inventory"):
		player._save_inventory()


func _on_right_click(pos: Vector2i, _event: InputEventMouseButton) -> void:
	var entry: Dictionary = inventory.get_item_at(pos)
	if entry.is_empty():
		return

	var item_data: Dictionary = ItemDatabase.get_item(entry["item_id"])

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
	var entry: Dictionary = inventory.get_item_at(pos)
	if entry.is_empty():
		return
	var item_data: Dictionary = ItemDatabase.get_item(entry["item_id"])
	# Solo equipar items que tienen slot (no consumibles ni materiales)
	if item_data.get("slot", "") == "":
		return
	var player := _find_player()
	if player != null and player.has_method("equip_item"):
		player.equip_item(entry["item_id"], pos)
		_grid_panel.queue_redraw()


func _on_context_menu_item(id: int) -> void:
	var pos: Vector2i = _context_menu.get_meta("entry_pos", Vector2i(-1, -1))
	if pos.x < 0:
		return

	match id:
		0: # Soltar — dropear al mundo frente al jugador
			var entry: Dictionary = inventory.remove_item_at(pos)
			if not entry.is_empty():
				_drop_item_to_world(entry["item_id"], entry["quantity"])
			_grid_panel.queue_redraw()
		1: # Usar
			var entry: Dictionary = inventory.get_item_at(pos)
			if not entry.is_empty():
				_use_item(entry, pos)


func _use_item(entry: Dictionary, pos: Vector2i) -> void:
	var item_data: Dictionary = ItemDatabase.get_item(entry["item_id"])
	if item_data.is_empty():
		return

	var stats: Dictionary = item_data.get("stats", {})
	var player := _find_player()

	var heal: int = stats.get("heal", 0)
	if heal > 0:
		if player != null and player.has_method("heal"):
			player.heal(float(heal))

	var restore_mana: int = stats.get("restore_mana", 0)
	if restore_mana > 0:
		if player != null and player.has_method("restore_mana"):
			player.restore_mana(float(restore_mana))

	# Reducir cantidad o eliminar
	if entry["quantity"] > 1:
		entry["quantity"] -= 1
	else:
		inventory.remove_item_at(pos)

	# Guardar inventario tras usar el item
	if player != null and player.has_method("_save_inventory"):
		player._save_inventory()

	_grid_panel.queue_redraw()
	_refresh()


func _find_player() -> Node:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null


func _drop_item_to_world(item_id: String, quantity: int) -> void:
	var player := _find_player()
	if player == null:
		return

	var item_scene := preload("res://scenes/loot/item_drop.tscn")
	var drop := item_scene.instantiate() as ItemDrop

	# Nombre del jugador para mostrar en party
	var player_name: String = ""
	if player.has_method("get_character_name"):
		player_name = player.get_character_name()

	drop.setup(item_id, quantity, player_name)

	# Dropear 2m frente al jugador (con raycast para evitar paredes)
	# Fallback al forward del player si no hay cámara activa
	var cam: Camera3D = player.get_viewport().get_camera_3d()
	var forward: Vector3
	if cam != null:
		forward = -cam.global_transform.basis.z.normalized()
	else:
		forward = -player.global_transform.basis.z.normalized()
	forward.y = 0
	if forward.length() < 0.01:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var drop_pos: Vector3 = player.global_position + forward * 2.0

	# Chequeo de pared entre jugador y drop_pos — si hay, drop en la posición del player
	var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var wall_from: Vector3 = player.global_position + Vector3(0, 1.0, 0)
	var wall_to: Vector3 = drop_pos + Vector3(0, 1.0, 0)
	var wall_q: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(wall_from, wall_to)
	wall_q.exclude = [player.get_rid()]
	wall_q.collision_mask = 1
	var wall_hit: Dictionary = space.intersect_ray(wall_q)
	if not wall_hit.is_empty():
		drop_pos = player.global_position

	# Raycast hacia abajo para apoyarlo en el suelo — evita que flote
	var down_from: Vector3 = drop_pos + Vector3(0, 2.0, 0)
	var down_to: Vector3 = drop_pos + Vector3(0, -5.0, 0)
	var ground_q: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(down_from, down_to)
	ground_q.exclude = [player.get_rid()]
	ground_q.collision_mask = 1
	var ground_hit: Dictionary = space.intersect_ray(ground_q)
	if not ground_hit.is_empty():
		drop_pos.y = ground_hit.position.y + 0.05
	else:
		drop_pos.y = player.global_position.y - 0.8  # fallback aprox feet level

	drop.global_position = drop_pos

	get_tree().current_scene.call_deferred("add_child", drop)


func _update_tooltip(pos: Vector2i, global_mouse: Vector2) -> void:
	if pos.x < 0:
		_tooltip.visible = false
		return

	var entry: Dictionary = inventory.get_item_at(pos)
	if entry.is_empty():
		_tooltip.visible = false
		return

	var item_data: Dictionary = ItemDatabase.get_item(entry["item_id"])
	if item_data.is_empty():
		_tooltip.visible = false
		return

	var rarity: String = item_data.get("rarity", "common")
	var rarity_hex: String = _rarity_color_hex(rarity)
	var item_name: String = item_data.get("name", "")
	var desc: String = item_data.get("description", "")

	var text := "[color=#%s][b]%s[/b][/color]\n%s" % [rarity_hex, item_name, desc]
	var stats: Dictionary = item_data.get("stats", {})
	for stat_key in stats.keys():
		text += "\n+%s %s" % [stats[stat_key], stat_key]
	text += "\n[color=#%s]Rareza: %s[/color]" % [rarity_hex, rarity]

	_tooltip_label.text = text
	_tooltip.reset_size()
	_tooltip.visible = true

	var vp_size := get_viewport().get_visible_rect().size
	var tip_size := _tooltip.get_combined_minimum_size()
	var tip_pos := global_mouse + Vector2(14, 14)
	if tip_pos.x + tip_size.x > vp_size.x:
		tip_pos.x = global_mouse.x - tip_size.x - 8
	if tip_pos.y + tip_size.y > vp_size.y:
		tip_pos.y = global_mouse.y - tip_size.y - 8
	_tooltip.global_position = tip_pos


func _rarity_color_hex(rarity: String) -> String:
	var c: Color = ItemDatabase.RARITY_COLORS.get(rarity, Color.WHITE)
	return c.to_html(false)


func _pixel_to_grid(pixel: Vector2) -> Vector2i:
	var col := int(pixel.x / cell_size)
	var row := int(pixel.y / cell_size)
	if col < 0 or col >= grid_cols or row < 0 or row >= grid_rows:
		return Vector2i(-1, -1)
	return Vector2i(col, row)
