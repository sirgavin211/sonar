class_name Pickup
extends Area2D

# Also used by the HUD to color backpack slots.
const COLORS := {
	"food": Color(0.3, 0.9, 0.3),
	"fuel": Color(1.0, 0.5, 0.1),
	"shard": Color(1.0, 0.95, 0.4),
}

@export_enum("food", "fuel", "shard") var kind := "food"


func _ready() -> void:
	$Body.color = COLORS[kind]
	$EchoGlow.color = COLORS[kind]


# shortcut: full backpack means walk off and back on to retry, fine until it annoys playtesters.
func _on_body_entered(body: Node) -> void:
	if body is Player and body.pick_up(kind):
		queue_free()
