extends Control

## World Select — modelo Valheim. Lista de mundos guardados + crear nuevo (nombre + seed).
## Al entrar: setea GameManager.world_seed/world_id/world_name y carga GameManager.target_scene.
## El nivel destino (floor1_prairie) lee GameManager.world_seed en su _ready() y genera el
## mapa procedural con esa semilla. Seed distinta = mapa distinto (terreno, POIs, vegetación,
## enemigos). Sin mundo elegido (world_seed = -1), el nivel usa su seed por defecto.
##
## Construye toda la UI por código (patrón de character_select.gd) para no acoplarse a
## node-paths del .tscn.

var _selected_index: int = -1
var _delete_pending: bool = false

var _world_list: VBoxContainer
var _name_input: LineEdit
var _seed_input: LineEdit
var _enter_btn: Button
var _delete_btn: Button
var _status: Label


func _ready() -> void:
	_build_ui()
	_refresh_worlds()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.055, 0.07, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 80
	root.offset_top = 48
	root.offset_right = -80
	root.offset_bottom = -48
	root.add_theme_constant_override("separation", 18)
	add_child(root)

	var title := Label.new()
	title.text = "Selecciona un Mundo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45, 1.0))
	root.add_child(title)

	# ── Lista de mundos (scroll vertical) ──
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_world_list = VBoxContainer.new()
	_world_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_world_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_world_list)

	# ── Crear mundo nuevo ──
	var create_row := HBoxContainer.new()
	create_row.add_theme_constant_override("separation", 10)
	root.add_child(create_row)

	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Nombre del mundo"
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_row.add_child(_name_input)

	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = "Seed (vacío = aleatoria)"
	_seed_input.custom_minimum_size = Vector2(240, 0)
	create_row.add_child(_seed_input)

	var create_btn := Button.new()
	create_btn.text = "Crear mundo"
	create_btn.custom_minimum_size = Vector2(160, 0)
	create_btn.pressed.connect(_on_create_pressed)
	create_row.add_child(create_btn)

	# ── Acciones ──
	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 16)
	root.add_child(action_row)

	var back_btn := Button.new()
	back_btn.text = "Volver"
	back_btn.custom_minimum_size = Vector2(160, 48)
	back_btn.pressed.connect(_on_back_pressed)
	action_row.add_child(back_btn)

	_delete_btn = Button.new()
	_delete_btn.text = "Eliminar"
	_delete_btn.custom_minimum_size = Vector2(160, 48)
	_delete_btn.disabled = true
	_delete_btn.pressed.connect(_on_delete_pressed)
	action_row.add_child(_delete_btn)

	_enter_btn = Button.new()
	_enter_btn.text = "Entrar"
	_enter_btn.custom_minimum_size = Vector2(240, 48)
	_enter_btn.disabled = true
	_enter_btn.pressed.connect(_on_enter_pressed)
	action_row.add_child(_enter_btn)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.modulate = Color(1.0, 1.0, 1.0, 0.6)
	root.add_child(_status)


func _refresh_worlds() -> void:
	_selected_index = -1
	_delete_pending = false
	_delete_btn.text = "Eliminar"
	_update_buttons()

	# remove_child es síncrono; queue_free es diferido. Sacamos del árbol PRIMERO
	# para que get_child_count() no cuente rows viejos mientras repoblamos (si no,
	# el highlight por índice caería en un row stale aún sin liberar).
	for child in _world_list.get_children():
		_world_list.remove_child(child)
		child.queue_free()

	if WorldManager.get_world_count() == 0:
		var hint := Label.new()
		hint.text = "No hay mundos todavía. Creá uno abajo para empezar a testear."
		hint.modulate = Color(1.0, 1.0, 1.0, 0.5)
		_world_list.add_child(hint)
		return

	for i in range(WorldManager.get_world_count()):
		var world: Dictionary = WorldManager.get_world(i)
		_world_list.add_child(_create_world_row(world, i))


func _create_world_row(world: Dictionary, index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 56)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)

	var name_label := Label.new()
	name_label.text = world.get("name", "???")
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(name_label)

	var seed_label := Label.new()
	seed_label.text = "seed: %d" % int(world.get("seed", 0))
	seed_label.add_theme_font_size_override("font_size", 14)
	seed_label.modulate = Color(0.7, 0.9, 1.0, 1.0)
	seed_label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(seed_label)

	var floor_label := Label.new()
	floor_label.text = "Piso %d" % int(world.get("highest_floor_cleared", 0))
	floor_label.add_theme_font_size_override("font_size", 14)
	floor_label.modulate = Color(1.0, 0.85, 0.3, 1.0)
	floor_label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(floor_label)

	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_select_world(index)
	)
	return panel


func _select_world(index: int) -> void:
	_selected_index = index
	_delete_pending = false
	_delete_btn.text = "Eliminar"
	_update_buttons()
	_highlight_selected()


func _highlight_selected() -> void:
	for i in range(_world_list.get_child_count()):
		var row = _world_list.get_child(i)
		if row is PanelContainer:
			row.modulate = Color(1.0, 0.85, 0.3, 1.0) if i == _selected_index else Color(1.0, 1.0, 1.0, 1.0)


func _update_buttons() -> void:
	var has_sel := _selected_index >= 0
	_enter_btn.disabled = not has_sel
	_delete_btn.disabled = not has_sel


func _on_create_pressed() -> void:
	if WorldManager.get_world_count() >= WorldManager.MAX_WORLDS:
		_status.text = "Máximo de mundos alcanzado (%d)." % WorldManager.MAX_WORLDS
		return

	var seed_text := _seed_input.text.strip_edges()
	var seed_value := -1
	if seed_text != "":
		if seed_text.is_valid_int():
			# abs(): un entero negativo se trata como "<0 = aleatoria" en create_world,
			# así que lo volvemos positivo para respetar la seed que el jugador escribió.
			seed_value = abs(int(seed_text))
		else:
			# Seed por texto: hash estable → permite usar un nombre como semilla.
			seed_value = abs(hash(seed_text))

	var idx := WorldManager.create_world(_name_input.text, seed_value)
	_name_input.text = ""
	_seed_input.text = ""
	_status.text = ""
	_refresh_worlds()
	_select_world(idx)


func _on_enter_pressed() -> void:
	if _selected_index < 0:
		return
	var world: Dictionary = WorldManager.get_world(_selected_index)
	if world.is_empty():
		return
	GameManager.world_seed = int(world.get("seed", 0))
	GameManager.world_id = world.get("world_id", "")
	GameManager.world_name = world.get("name", "")
	GameManager.world_index = _selected_index
	get_tree().change_scene_to_file(GameManager.target_scene)


func _on_delete_pressed() -> void:
	if _selected_index < 0:
		return
	if not _delete_pending:
		_delete_pending = true
		_delete_btn.text = "¿Confirmar?"
		return
	_delete_pending = false
	_delete_btn.text = "Eliminar"
	WorldManager.delete_world(_selected_index)
	_refresh_worlds()


func _on_back_pressed() -> void:
	# Salimos sin entrar a un mundo: limpiar el mundo activo para que no quede
	# una seed stale apuntando a un nivel futuro.
	GameManager.clear_active_world()
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
