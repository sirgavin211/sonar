@tool
class_name WorldBar
extends Node2D
# Small health bar under a character, zombs.io style.

@export var width := 36.0
@export var height := 5.0
@export var color := Color(0.45, 0.75, 0.3)
@export var outline_color := Color(0.17, 0.16, 0.2)
@export var hide_when_full := false

var ratio := 1.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		visible = not (hide_when_full and ratio >= 1.0)
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(-width / 2, -height / 2, width, height)
	draw_rect(rect.grow(1.5), outline_color)
	draw_rect(Rect2(rect.position, Vector2(width * ratio, height)), color)
