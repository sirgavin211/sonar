@tool
class_name TitleWaves
extends Node2D
# Pulsing sonar arcs for the title screen, like a wave being fired again and again.

@export var color := Color(0.5, 0.9, 1.0)
@export var direction_degrees := 0.0  # 0 = right, 180 = left
@export var arc_degrees := 40.0
@export var reach := 110.0  # how far each arc travels before fading out
@export var rings := 3
@export var period := 1.6  # seconds for one arc to travel its full reach

var time := 0.0


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var half_arc := deg_to_rad(arc_degrees) / 2
	var facing := deg_to_rad(direction_degrees)
	for i in rings:
		var progress := fmod(time / period + float(i) / rings, 1.0)
		var ring_color := color
		ring_color.a = 1.0 - progress
		draw_arc(Vector2.ZERO, progress * reach, facing - half_arc, facing + half_arc, 24, ring_color, 2.0)
