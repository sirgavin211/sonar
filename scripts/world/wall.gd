@tool
class_name Wall
extends StaticBody2D
# Solid block that sonar bounces off and lights up: mountains, trees, stones, facility walls.
# With a texture it draws that art (size is then just the collider, e.g. a tree's trunk).
# With a surface it's a block of that tile repeated, with a pixel outline (stone walls).
# Neither: a flat outlined box. Color is also its minimap color.
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
@export var surface: Texture2D:  # tile repeated across the whole block
	set(value):
		surface = value
		if is_node_ready():
			apply()
@export var surface_tint := Color.WHITE:  # above 1 brightens, so stone walls stand out from stone ground
	set(value):
		surface_tint = value
		if is_node_ready():
			apply()
@export var texture_scale := 2.0:  # 2x everywhere keeps one pixel grid
	set(value):
		texture_scale = value
		if is_node_ready():
			apply()


func _ready() -> void:
	apply()


func apply() -> void:
	var tiled := texture == null and surface != null
	$Body.size = size
	$Body.visible = texture == null
	# Over a tiled surface the Body only draws its outline (clear fill), on top of the tiles.
	$Body.color = Color(color, 0.0) if tiled else color
	$Sprite.texture = surface if tiled else texture
	$Sprite.scale = Vector2.ONE * texture_scale
	$Sprite.z_index = -1 if tiled else 0
	$Sprite.region_enabled = tiled
	$Sprite.region_rect = Rect2(Vector2.ZERO, size / texture_scale)
	$Sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if tiled else CanvasItem.TEXTURE_REPEAT_PARENT_NODE
	$Sprite.self_modulate = surface_tint if tiled else Color.WHITE
	$CollisionShape2D.shape.size = size
	# Glow covers the whole art, not just the collider.
	var art := texture.get_size() * texture_scale if texture else Vector2.ZERO
	$EchoGlow.texture_scale = maxf(size.length(), art.length()) / 128.0
