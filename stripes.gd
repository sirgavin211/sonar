@tool
class_name Stripes
extends Node2D
# Repeating stripes in a box: hazard tape (slanted) or conveyor rollers (straight,
# with scroll_speed so the belt moves). Rotate the node for a vertical belt.

@export var size := Vector2(110, 12):
	set(value):
		size = value
		queue_redraw()
@export var color := Color(0.95, 0.75, 0.1):
	set(value):
		color = value
		queue_redraw()
@export var back_color := Color(0.1, 0.1, 0.1):
	set(value):
		back_color = value
		queue_redraw()
@export var stripe_width := 8.0:
	set(value):
		stripe_width = maxf(value, 1.0)
		queue_redraw()
@export var slant := 8.0:  # how far each stripe leans; 0 = straight
	set(value):
		slant = value
		queue_redraw()
@export var scroll_speed := 0.0  # pixels per second along the box

var offset := 0.0


func _process(delta: float) -> void:
	if scroll_speed == 0.0:
		return
	offset = fmod(offset + scroll_speed * delta, stripe_width * 2)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(-size / 2, size)
	draw_rect(rect, back_color)
	var box := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var x := rect.position.x - absf(slant) - stripe_width * 2 + offset
	while x < rect.end.x + absf(slant):
		var stripe := PackedVector2Array([
			Vector2(x, rect.end.y), Vector2(x + slant, rect.position.y),
			Vector2(x + slant + stripe_width, rect.position.y), Vector2(x + stripe_width, rect.end.y),
		])
		# Clip each stripe to the box so the ends stay square.
		for piece in Geometry2D.intersect_polygons(box, stripe):
			draw_colored_polygon(piece, color)
		x += stripe_width * 2
