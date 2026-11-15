@tool
class_name Ground
extends Node2D
# Flat floor with a grid: the zombs.io-style map ground (main sets it from its exports)
# and the factory's metal plates in camp.tscn. Draws from (0, 0) to size.

@export var size := Vector2(4000, 4000):
	set(value):
		size = value
		queue_redraw()
@export var color := Color(0.33, 0.4, 0.28):
	set(value):
		color = value
		queue_redraw()
@export var line_color := Color(0.29, 0.35, 0.24):
	set(value):
		line_color = value
		queue_redraw()
@export var cell := 48.0:
	set(value):
		cell = maxf(value, 4.0)
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), line_color, 2.0)
		x += cell
	var y := 0.0
	while y <= size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), line_color, 2.0)
		y += cell
