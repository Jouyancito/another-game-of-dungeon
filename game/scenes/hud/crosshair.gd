extends Control

@export var color := Color(1, 1, 1, 0.9)
@export var outline_color := Color(0, 0, 0, 0.65)
@export var line_length := 12.0
@export var thickness := 2.0
@export var outline_thickness := 4.0   # drawn first, under the white lines
@export var gap := 4.0
@export var dot_radius := 2.5
@export var ring_radius := 5.5
@export var ring_thickness := 1.5

func _draw() -> void:
	var center := get_size() / 2

	# ── Outline pass (drawn first, thicker, dark) ──────────────────────
	draw_line(Vector2(center.x - line_length, center.y), Vector2(center.x - gap, center.y), outline_color, outline_thickness)
	draw_line(Vector2(center.x + gap, center.y), Vector2(center.x + line_length, center.y), outline_color, outline_thickness)
	draw_line(Vector2(center.x, center.y - line_length), Vector2(center.x, center.y - gap), outline_color, outline_thickness)
	draw_line(Vector2(center.x, center.y + gap), Vector2(center.x, center.y + line_length), outline_color, outline_thickness)
	# Outer ring outline
	draw_arc(center, ring_radius, 0.0, TAU, 32, outline_color, ring_thickness + 2.0)
	# Center dot outline
	draw_circle(center, dot_radius + 1.5, outline_color)

	# ── Foreground pass (white) ────────────────────────────────────────
	draw_line(Vector2(center.x - line_length, center.y), Vector2(center.x - gap, center.y), color, thickness)
	draw_line(Vector2(center.x + gap, center.y), Vector2(center.x + line_length, center.y), color, thickness)
	draw_line(Vector2(center.x, center.y - line_length), Vector2(center.x, center.y - gap), color, thickness)
	draw_line(Vector2(center.x, center.y + gap), Vector2(center.x, center.y + line_length), color, thickness)
	# Outer ring — gives a dot+ring shape that reads on both light/dark backgrounds
	draw_arc(center, ring_radius, 0.0, TAU, 32, color, ring_thickness)
	# Center dot
	draw_circle(center, dot_radius, color)
