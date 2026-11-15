class_name Minimap
extends Panel
# Bottom-left map: you and the camp. Enemies stay off it; it's a sonar game.

@export var player_color := Color(0.6, 0.6, 1.0)
@export var camp_color := Color(1.0, 0.85, 0.4)

var game: Node  # main.gd


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var scale_to_map: Vector2 = size / game.map_size
	draw_rect(Rect2(game.camp.position * scale_to_map - Vector2(4, 4), Vector2(8, 8)), camp_color)
	draw_circle(game.player.position * scale_to_map, 3.0, player_color)
