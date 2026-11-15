class_name Ground
extends Node2D
# Flat ground with a grid, zombs.io style. Main sets size/colors from its exports.

var size := Vector2(4000, 4000)
var color := Color(0.33, 0.4, 0.28)
var line_color := Color(0.29, 0.35, 0.24)
var cell := 48.0


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
