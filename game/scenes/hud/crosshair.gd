extends Control

@export var color := Color(1, 1, 1, 0.8)
@export var line_length := 12.0
@export var thickness := 2.0
@export var gap := 4.0

func _draw() -> void:
	var center = get_size() / 2
	# Linea horizontal izquierda
	draw_line(Vector2(center.x - line_length, center.y), Vector2(center.x - gap, center.y), color, thickness)
	# Linea horizontal derecha
	draw_line(Vector2(center.x + gap, center.y), Vector2(center.x + line_length, center.y), color, thickness)
	# Linea vertical arriba
	draw_line(Vector2(center.x, center.y - line_length), Vector2(center.x, center.y - gap), color, thickness)
	# Linea vertical abajo
	draw_line(Vector2(center.x, center.y + gap), Vector2(center.x, center.y + line_length), color, thickness)
	# Punto central
	draw_circle(center, 1.5, color)
