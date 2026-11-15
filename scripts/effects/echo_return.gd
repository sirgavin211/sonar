class_name EchoReturn
extends Node2D
# The "bounce back": an arc as wide as the object it came off of,
# shrinking back to the spot the wave was fired from (it doesn't follow the player).

@export var speed := 600.0
@export var min_span := 0.05  # radians, so tiny objects still show
@export var end_radius := 14.0  # disappears this close to the firing spot

var direction := 0.0  # angle from the firing spot to the object
var span := 0.0
var radius := 0.0
var color := Color.WHITE


func setup(origin: Vector2, from: Vector2, object_size: float, echo_color: Color) -> void:
	position = origin
	var offset := from - origin
	direction = offset.angle()
	radius = offset.length()
	# Arc length = object size, so a big rock sends back a wide echo.
	span = clampf(object_size / maxf(radius, 1.0), min_span, PI)
	color = echo_color


func _physics_process(delta: float) -> void:
	radius -= speed * delta
	if radius <= end_radius:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, direction - span / 2, direction + span / 2, 16, color, 2.0)
