@tool
class_name FlatShape
extends Node2D
# zombs.io-style stand-in art: flat fill with a thick dark outline.
# Corner radius of half the size makes a circle. Swap for a Sprite2D once art lands.

@export var size := Vector2(28, 28):
	set(value):
		size = value
		queue_redraw()
@export var color := Color(0.85, 0.65, 0.5):
	set(value):
		color = value
		queue_redraw()
@export var outline_color := Color(0.17, 0.16, 0.2):
	set(value):
		outline_color = value
		queue_redraw()
@export var outline_width := 3.0:
	set(value):
		outline_width = value
		queue_redraw()
@export var corner_radius := 14.0:
	set(value):
		corner_radius = value
		queue_redraw()


func _draw() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = outline_color
	box.set_border_width_all(int(outline_width))
	box.set_corner_radius_all(int(corner_radius))
	box.corner_detail = 16
	draw_style_box(box, Rect2(-size / 2, size))
