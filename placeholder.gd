class_name Placeholder
extends Object
# Rectangle stand-ins until Andrew's art lands. Swap box() calls for Sprite2Ds later.

static var light_texture: GradientTexture2D


static func box(parent: Node, size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.size = size
	rect.position = -size / 2
	rect.pivot_offset = size / 2
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect


static func collider(parent: Node, size: Vector2) -> CollisionShape2D:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	parent.add_child(collision)
	return collision


# Solid block that sonar bounces off and lights up: mountains, rocks, facility walls.
static func wall(parent: Node, pos: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	box(body, size, color)
	collider(body, size)
	EchoGlow.attach(body, size.length())
	parent.add_child(body)
	return body


static func light(parent: Node, radius: float, color: Color, energy: float) -> PointLight2D:
	var lamp := PointLight2D.new()
	lamp.texture = radial_texture()
	lamp.texture_scale = radius / 128.0
	lamp.color = color
	lamp.energy = energy
	parent.add_child(lamp)
	return lamp


# One shared soft circle texture for every light.
static func radial_texture() -> GradientTexture2D:
	if light_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color.WHITE)
		gradient.set_color(1, Color(0, 0, 0, 0))
		light_texture = GradientTexture2D.new()
		light_texture.gradient = gradient
		light_texture.fill = GradientTexture2D.FILL_RADIAL
		light_texture.fill_from = Vector2(0.5, 0.5)
		light_texture.fill_to = Vector2(1.0, 0.5)
		light_texture.width = 256
		light_texture.height = 256
	return light_texture
