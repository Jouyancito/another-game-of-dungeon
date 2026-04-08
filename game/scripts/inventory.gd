extends RefCounted
class_name Inventory

# Inventario por jugador. No es autoload — se instancia con Inventory.new()

const GRID_COLS := 10
const GRID_ROWS := 6

# grid[row][col] = item_id o "" si vacío
var grid: Array = []

# Lista de items colocados: {item_id, grid_pos: Vector2i, quantity: int}
var items: Array = []

var coins: int = 0


func _init() -> void:
	_reset_grid()


func _reset_grid() -> void:
	grid = []
	for row in range(GRID_ROWS):
		var cols: Array = []
		for col in range(GRID_COLS):
			cols.append("")
		grid.append(cols)


# Devuelve true si el item cabe completamente en pos sin superponerse con otro item
func can_place_item(item_id: String, pos: Vector2i) -> bool:
	var item_data := ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return false

	var size: Vector2i = item_data["grid_size"]

	if pos.x < 0 or pos.y < 0:
		return false
	if pos.x + size.x > GRID_COLS or pos.y + size.y > GRID_ROWS:
		return false

	for row in range(size.y):
		for col in range(size.x):
			var cell_id: String = grid[pos.y + row][pos.x + col]
			if cell_id != "":
				return false

	return true


# Coloca el item en pos. Devuelve true si tuvo éxito.
func place_item(item_id: String, pos: Vector2i, quantity: int = 1) -> bool:
	if not can_place_item(item_id, pos):
		return false

	var item_data := ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return false

	var size: Vector2i = item_data["grid_size"]

	# Si es stackeable y ya existe ese item en esa posición, sumar
	for entry in items:
		if entry["item_id"] == item_id and entry["grid_pos"] == pos:
			entry["quantity"] += quantity
			return true

	# Marcar las celdas
	for row in range(size.y):
		for col in range(size.x):
			grid[pos.y + row][pos.x + col] = item_id

	items.append({
		"item_id": item_id,
		"grid_pos": pos,
		"quantity": quantity,
	})
	return true


# Elimina el item cuya celda ancla (top-left) está en pos. Devuelve el entry removido o {}.
func remove_item_at(pos: Vector2i) -> Dictionary:
	var entry := _find_entry_by_anchor(pos)
	if entry.is_empty():
		return {}

	_clear_item_cells(entry)
	items.erase(entry)
	return entry


# Devuelve el entry del item que ocupa la celda en pos (puede no ser la celda ancla).
func get_item_at(pos: Vector2i) -> Dictionary:
	if pos.x < 0 or pos.x >= GRID_COLS or pos.y < 0 or pos.y >= GRID_ROWS:
		return {}

	var cell_id: String = grid[pos.y][pos.x]
	if cell_id == "":
		return {}

	# Buscar el entry que contiene esta celda
	for entry in items:
		var item_data := ItemDatabase.get_item(entry["item_id"])
		if item_data.is_empty():
			continue
		var size: Vector2i = item_data["grid_size"]
		var anchor: Vector2i = entry["grid_pos"]
		if pos.x >= anchor.x and pos.x < anchor.x + size.x and \
		   pos.y >= anchor.y and pos.y < anchor.y + size.y:
			return entry

	return {}


# Intenta colocar el item en el primer hueco disponible (top-left, fila a fila).
func auto_place_item(item_id: String, quantity: int = 1) -> bool:
	var item_data := ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return false

	# Si es stackeable, intentar apilar en un entry existente
	if item_data.get("stackable", false):
		for entry in items:
			if entry["item_id"] == item_id:
				var max_stack: int = item_data.get("max_stack", 1)
				if entry["quantity"] < max_stack:
					entry["quantity"] = mini(entry["quantity"] + quantity, max_stack)
					return true

	# Buscar primer posición libre
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			if can_place_item(item_id, Vector2i(col, row)):
				return place_item(item_id, Vector2i(col, row), quantity)

	return false


func has_space_for(item_id: String) -> bool:
	var item_data := ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return false

	if item_data.get("stackable", false):
		for entry in items:
			if entry["item_id"] == item_id:
				if entry["quantity"] < item_data.get("max_stack", 1):
					return true

	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			if can_place_item(item_id, Vector2i(col, row)):
				return true

	return false


func to_save_data() -> Dictionary:
	var serialized_items: Array = []
	for entry in items:
		serialized_items.append({
			"item_id": entry["item_id"],
			"grid_pos_x": entry["grid_pos"].x,
			"grid_pos_y": entry["grid_pos"].y,
			"quantity": entry["quantity"],
		})
	return {
		"items": serialized_items,
		"coins": coins,
	}


func from_save_data(data: Dictionary) -> void:
	_reset_grid()
	items = []
	coins = data.get("coins", 0)

	for entry in data.get("items", []):
		var pos := Vector2i(entry.get("grid_pos_x", 0), entry.get("grid_pos_y", 0))
		place_item(entry.get("item_id", ""), pos, entry.get("quantity", 1))


# --- Helpers ---

func _find_entry_by_anchor(pos: Vector2i) -> Dictionary:
	for entry in items:
		if entry["grid_pos"] == pos:
			return entry
	return {}


func _clear_item_cells(entry: Dictionary) -> void:
	var item_data := ItemDatabase.get_item(entry["item_id"])
	if item_data.is_empty():
		return
	var size: Vector2i = item_data["grid_size"]
	var anchor: Vector2i = entry["grid_pos"]
	for row in range(size.y):
		for col in range(size.x):
			grid[anchor.y + row][anchor.x + col] = ""
