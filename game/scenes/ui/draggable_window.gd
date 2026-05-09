extends PanelContainer
class_name DraggableWindow
## Ventana arrastreable — agarrás del header y la movés por la pantalla.
## Usar como nodo base o agregarle esta funcionalidad a cualquier PanelContainer.
## Compatible con anchors centrados: al empezar a arrastrar, desancla el panel.

@export var drag_handle_height := 36.0

var _dragging := false
var _drag_offset := Vector2.ZERO
var _unanchored := false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _is_in_drag_zone(event.position):
			_dragging = true
			_drag_offset = event.position
			_unanchor()
		else:
			_dragging = false

	if event is InputEventMouseMotion and _dragging:
		position += event.relative
		_clamp_to_screen()


func _is_in_drag_zone(local_pos: Vector2) -> bool:
	return local_pos.y <= drag_handle_height


func _unanchor() -> void:
	if _unanchored:
		return
	_unanchored = true
	# Guardar posición actual en pantalla antes de quitar anchors
	var current_pos = global_position
	anchor_left = 0
	anchor_top = 0
	anchor_right = 0
	anchor_bottom = 0
	global_position = current_pos
	size = size  # forzar re-layout con el tamaño actual


func center_on_screen() -> void:
	_unanchored = false
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -size.x / 2
	offset_top = -size.y / 2
	offset_right = size.x / 2
	offset_bottom = size.y / 2


func _clamp_to_screen() -> void:
	var screen_size = get_viewport_rect().size
	position.x = clampf(position.x, -size.x + 60, screen_size.x - 60)
	# Reservar 80px del bottom para hotbar (52px alto + 28 margen).
	# Si la ventana es más alta que el viewport disponible, max_y queda en 0.
	var max_y: float = maxf(0.0, screen_size.y - size.y - 80.0)
	position.y = clampf(position.y, 0, max_y)
