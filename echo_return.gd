class_name EchoReturn
extends Node2D
# The "bounce back": an arc as wide as the object it came off of,
# shrinking back toward the player like a reflected sound wave.

@export var speed := 600.0
@export var min_span := 0.05  # radians, so tiny objects still show

var listener: Player
var direction := 0.0  # angle from player to the object
var span := 0.0
var radius := 0.0
var color := Color.WHITE


func setup(player: Player, from: Vector2, object_size: float, echo_color: Color) -> void:
	listener = player
	position = player.global_position
	var offset := from - player.global_position
	direction = offset.angle()
	radius = offset.length()
	# Arc length = object size, so a big rock sends back a wide echo.
	span = clampf(object_size / maxf(radius, 1.0), min_span, PI)
	color = echo_color


func _physics_process(delta: float) -> void:
	radius -= speed * delta
	if radius <= listener.size.x / 2:
		queue_free()
		return
	global_position = listener.global_position
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, direction - span / 2, direction + span / 2, 16, color, 2.0)
