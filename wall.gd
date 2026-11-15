@tool
class_name Wall
extends StaticBody2D
# Solid block that sonar bounces off and lights up: mountains, trees, stones, facility walls.
# With a texture it draws that art (size is then just the collider, e.g. a tree's trunk);
# without, a flat outlined box. Color is also its minimap color.
# @tool so changing these in the Inspector shows up in the editor right away.

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
@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			apply()
@export var texture_scale := 3.0:  # 3x matches the ground tiles' pixel size
	set(value):
		texture_scale = value
		if is_node_ready():
			apply()


func _ready() -> void:
	apply()


func apply() -> void:
	$Body.size = size
	$Body.color = color
	$Body.visible = texture == null
	$Sprite.texture = texture
	$Sprite.scale = Vector2.ONE * texture_scale
	$CollisionShape2D.shape.size = size
	# Glow covers the whole art, not just the collider.
	var art := texture.get_size() * texture_scale if texture else Vector2.ZERO
	$EchoGlow.texture_scale = maxf(size.length(), art.length()) / 128.0
