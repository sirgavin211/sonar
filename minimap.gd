class_name Minimap
extends Panel
# Bottom-left map: you, the camp, and whatever sonar just pinged (walls and items),
# fading out with their echo glow. Enemies stay off it; it's a sonar game.

@export var player_color := Color(0.6, 0.6, 1.0)
@export var camp_color := Color(1.0, 0.85, 0.4)
@export var item_dot_radius := 2.0

var game: Node  # main.gd


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var scale_to_map: Vector2 = size / game.map_size
	for node in get_tree().get_nodes_in_group("echoable"):
		draw_pinged(node, scale_to_map)
	draw_rect(Rect2(game.camp.position * scale_to_map - Vector2(4, 4), Vector2(8, 8)), camp_color)
	draw_circle(game.player.position * scale_to_map, 3.0, player_color)


# Walls draw at their real size, items as dots; both fade as the glow does.
func draw_pinged(node: Node2D, scale_to_map: Vector2) -> void:
	var glow: EchoGlow = node.get_node("EchoGlow")
	if not glow.enabled:
		return
	var at := node.global_position * scale_to_map
	if node is Wall:
		var color: Color = node.color
		color.a = glow.energy / glow.flash_energy
		var wall_size: Vector2 = (node.size * scale_to_map).max(Vector2(2, 2))
		draw_rect(Rect2(at - wall_size / 2, wall_size), color)
	elif node is Pickup:
		var color := glow.color
		color.a = glow.energy / glow.flash_energy
		draw_circle(at, item_dot_radius, color)
