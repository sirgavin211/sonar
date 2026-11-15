@tool
class_name WorldTag
extends Node2D
# Floating pixel label with a pointer arrow, like "FUEL" over the hopper.
# The node's position is the arrow's tip: put it just above the thing it labels.
# World space is 2x, so every size here is in steps of 2 (= 1 screen pixel).

const ARROW_HEIGHT := 8.0

@export var text := "LABEL":
	set(value):
		text = value
		if is_node_ready():
			refresh()


func _ready() -> void:
	$Panel.resized.connect(place)
	refresh()


func refresh() -> void:
	$Panel/Label.text = text.to_upper()
	$Panel.reset_size()
	place()


# Centre the panel over the arrow, snapped to whole screen pixels so it stays crisp.
func place() -> void:
	var panel_size: Vector2 = $Panel.size
	$Panel.position = (Vector2(-panel_size.x / 2, -ARROW_HEIGHT - panel_size.y) / 2).round() * 2
