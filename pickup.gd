class_name Pickup
extends Area2D

# Item colors, also used by the HUD slots and the held item. Sonar isn't a pickup, it's the starting tool.
const COLORS := {
	"sonar": Color(0.4, 0.9, 1.0),
	"food": Color(0.3, 0.9, 0.3),
	"fuel": Color(1.0, 0.5, 0.1),
	"shard": Color(1.0, 0.95, 0.4),
}

# Art for items that have it; the rest stay colored circles. Also used by the HUD and held item.
const ICONS := {
	"fuel": preload("res://graphics/Fuel.png"),
	"shard": preload("res://graphics/shard.png"),
}

@export_enum("food", "fuel", "shard") var kind := "food"


func _ready() -> void:
	$Body.color = COLORS[kind]
	$EchoGlow.color = COLORS[kind]
	if ICONS.has(kind):
		$Icon.texture = ICONS[kind]
		$Icon.show()
		$Body.hide()


# shortcut: full backpack means walk off and back on to retry, fine until it annoys playtesters.
func _on_body_entered(body: Node) -> void:
	if body is Player and body.pick_up(kind):
		queue_free()
