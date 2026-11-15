class_name SonarWave
extends Node2D
# Expanding arc of sound fired from the gun. As the front sweeps outward, anything
# it reaches (with no wall in between) echoes, sends an EchoReturn back to the
# player, and Listeners take a hit once.

const SPEED := 600.0
const ARC := PI / 4  # cone width; set to TAU for a full 360 ring
const RINGS := 3  # trailing ripples behind the front
const RING_GAP := 14.0
const COLOR := Color(0.5, 0.9, 1.0)

var shooter: Player
var direction := 0.0
var max_range := 700.0
var damage := 1
var radius := 0.0
var echoed := {}  # nodes this wave already reached


func setup(player: Player, aim: Vector2) -> void:
	shooter = player
	position = player.global_position
	direction = aim.angle()
	max_range = player.wave_range
	damage = player.wave_damage


func _ready() -> void:
	# Draw at full brightness; the darkness shouldn't hide the wave itself.
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unshaded


func _physics_process(delta: float) -> void:
	radius += SPEED * delta
	if radius > max_range:
		queue_free()
		return
	echo_reached()
	queue_redraw()


func echo_reached() -> void:
	for node in get_tree().get_nodes_in_group("echoable"):
		if echoed.has(node):
			continue
		var offset: Vector2 = node.global_position - global_position
		if offset.length() > radius or absf(angle_difference(direction, offset.angle())) > ARC / 2:
			continue
		echoed[node] = true
		if not can_hear(node):
			continue
		EchoGlow.flash_on(node)
		send_echo(node)
		if node is Listener:
			node.take_hit(damage)


func send_echo(node: Node2D) -> void:
	var echo := EchoReturn.new()
	var glow: PointLight2D = node.get_node("EchoGlow")
	echo.setup(shooter, node.global_position, object_size(node), glow.color)
	get_parent().add_child(echo)


# Placeholder rect size; switch to the sprite's size once art lands.
func object_size(node: Node2D) -> float:
	for child in node.get_children():
		if child is ColorRect:
			return maxf(child.size.x, child.size.y)
	return 20.0


# Walls block sound: a ray to the node must hit nothing, or the node itself.
func can_hear(node: Node2D) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, node.global_position, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == node


func _draw() -> void:
	var fade := 1.0 - radius / max_range
	for i in RINGS:
		var ring_radius := radius - i * RING_GAP
		if ring_radius <= 0.0:
			break
		var color := COLOR
		color.a = fade / (i + 1)
		draw_arc(Vector2.ZERO, ring_radius, direction - ARC / 2, direction + ARC / 2, 32, color, 3.0)
