class_name SonarWave
extends Node2D
# Cone of sound fired from the gun, built from a fan of rays. Each ray travels and
# bounces off walls on its own; the visible wave joins neighbouring rays, so when
# part of the front hits a corner it splits into smaller pieces. Anything a ray
# reaches echoes, sends an EchoReturn back to where it was fired, and Listeners take a hit once.

const EchoScene := preload("res://echo_return.tscn")

@export var speed := 600.0
@export_range(1, 360, 1, "radians_as_degrees") var arc := PI / 9  # cone width; 360 for a full ring
@export var ray_count := 40
@export var bounce_dim := 0.6  # each bounce makes that piece of the wave dimmer
@export var rings := 3  # trailing ripples behind the front
@export var ring_gap := 14.0
@export var color := Color(0.5, 0.9, 1.0)

var shooter: Player
var direction := 0.0
var max_range := 700.0
var damage := 1
var traveled := 0.0  # path length so far, bounces included
var rays: Array[Dictionary] = []  # {pos, dir, bounces}, in order across the cone
var echoed := {}  # nodes this wave already reached


func setup(player: Player, origin: Vector2, aim: Vector2) -> void:
	shooter = player
	position = origin
	direction = aim.angle()
	max_range = player.wave_range
	damage = player.wave_damage
	for i in ray_count:
		var angle := direction - arc / 2 + arc * i / (ray_count - 1)
		rays.append({"pos": position, "dir": Vector2.from_angle(angle), "bounces": 0})


func _physics_process(delta: float) -> void:
	var step := speed * delta
	traveled += step
	if traveled > max_range:
		queue_free()
		return
	for ray in rays:
		move_ray(ray, step)
	echo_reached(step)
	queue_redraw()


# Walls and the Sun Core (layer 1) reflect the ray and echo.
func move_ray(ray: Dictionary, step: float) -> void:
	var target: Vector2 = ray.pos + ray.dir * step
	var query := PhysicsRayQueryParameters2D.create(ray.pos, target, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		ray.pos = target
		return
	# Nudge off the surface so the next cast doesn't start inside the wall.
	ray.pos = hit.position + hit.normal * 0.5
	ray.dir = ray.dir.bounce(hit.normal)
	ray.bounces += 1
	reach(hit.collider)


# Listeners and pickups aren't solid, so a ray only has to pass near them.
func echo_reached(step: float) -> void:
	for node in get_tree().get_nodes_in_group("echoable"):
		if echoed.has(node) or node is StaticBody2D:
			continue
		var catch := object_size(node) / 2 + step
		if rays.any(func(ray): return ray.pos.distance_to(node.global_position) < catch):
			reach(node)


func reach(node: Node) -> void:
	if echoed.has(node) or not node.is_in_group("echoable"):
		return
	echoed[node] = true
	EchoGlow.flash_on(node)
	# Items just light up; only walls and Listeners send a wave back.
	if not node is Pickup:
		send_echo(node)
	if node is Listener:
		node.take_hit(damage)


# shortcut: echo returns in a straight line, not along the bounced path; trace back the ray's path if it looks wrong in play
func send_echo(node: Node2D) -> void:
	var echo: EchoReturn = EchoScene.instantiate()
	var glow: PointLight2D = node.get_node("EchoGlow")
	echo.setup(position, node.global_position, object_size(node), glow.color)
	get_parent().add_child(echo)


# Size of the node's collision shape, so it stays right when art replaces the shapes.
func object_size(node: Node2D) -> float:
	var collision: CollisionShape2D = node.get_node_or_null("CollisionShape2D")
	if collision == null:
		return 20.0
	var rect := collision.shape.get_rect()
	return maxf(rect.size.x, rect.size.y)


func _draw() -> void:
	var fade := 1.0 - traveled / max_range
	# Neighbours further apart than this have split (one hit a corner, one didn't).
	var max_gap := traveled * arc / (ray_count - 1) * 2.5 + 4.0
	for i in ray_count - 1:
		var a: Dictionary = rays[i]
		var b: Dictionary = rays[i + 1]
		if a.bounces != b.bounces or a.pos.distance_to(b.pos) > max_gap:
			continue
		for ring in rings:
			var back := ring * ring_gap
			if back >= traveled:
				break
			var ring_color := color
			ring_color.a = fade * pow(bounce_dim, a.bounces) / (ring + 1)
			draw_line(to_local(a.pos - a.dir * back), to_local(b.pos - b.dir * back), ring_color, 2.0)
