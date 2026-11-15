class_name Pickup
extends Area2D

# Item colors, also used by the HUD slots and the held item. Sonar isn't a pickup, it's the starting tool.
const COLORS := {
	"sonar": Color(0.4, 0.9, 1.0),
	"food": Color(0.8, 0.5, 0.25),  # roasted-meat brown, matches the drumstick
	"fuel": Color(1.0, 0.5, 0.1),
	"shard": Color(1.0, 0.95, 0.4),
}

# Art for items that have it; the rest stay colored circles. Also used by the HUD and held item.
const ICONS := {
	"food": preload("res://resources/textures/food_icon.tres"),  # food.png cropped to the drumstick
	"fuel": preload("res://assets/textures/items/Fuel.png"),
	"shard": preload("res://assets/textures/items/shard.png"),
}

static var dot_icons := {}  # generated stand-ins, one per kind

@export_enum("food", "fuel", "shard") var kind := "food"


# The item's art, or a small outlined pixel dot in its color until art lands.
# Shrinks an icon in the hotbar/backpack slots (1.0 = its real size).
const HUD_ICON_SCALE := {
	"food": 0.9,
}

# Smaller art for the world (ground + hand) where the HUD size would dwarf the character.
const WORLD_ICONS := {
	"food": preload("res://assets/textures/items/food_small.png"),  # food.png at half size
}


# What the item looks like in the world: the smaller art if there is one, else the HUD icon.
static func world_icon_for(item_kind: String) -> Texture2D:
	return WORLD_ICONS.get(item_kind, icon_for(item_kind))


static func icon_for(item_kind: String) -> Texture2D:
	if ICONS.has(item_kind):
		return ICONS[item_kind]
	if not dot_icons.has(item_kind):
		var image := Image.create(12, 12, false, Image.FORMAT_RGBA8)
		for x in 12:
			for y in 12:
				var distance := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(6, 6))
				if distance <= 4.5:
					image.set_pixel(x, y, COLORS[item_kind])
				elif distance <= 5.8:
					image.set_pixel(x, y, Color(0.17, 0.16, 0.2))
		dot_icons[item_kind] = ImageTexture.create_from_image(image)
	return dot_icons[item_kind]


func _ready() -> void:
	$Body.color = COLORS[kind]
	$EchoGlow.color = COLORS[kind]
	if ICONS.has(kind):
		$Icon.texture = world_icon_for(kind)
		$Icon.show()
		$Body.hide()


# shortcut: full backpack means walk off and back on to retry, fine until it annoys playtesters.
func _on_body_entered(body: Node) -> void:
	if body is Player and body.pick_up(kind):
		queue_free()
