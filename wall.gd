@tool
class_name Wall
extends StaticBody2D
# Solid block that sonar bounces off and lights up: mountains, rocks, facility walls.
# @tool so changing size/color in the Inspector shows up in the editor right away.

@export var size := Vector2(100, 100):
	set(value):
		size = value
		if is_node_ready():
			apply()
@export var color := Color(0.4, 0.38, 0.35):
	set(value):
		color = value
		if is_node_ready():
			apply()


func _ready() -> void:
	apply()


func apply() -> void:
	$Body.size = size
	$Body.color = color
	$CollisionShape2D.shape.size = size
	$EchoGlow.texture_scale = size.length() / 128.0
