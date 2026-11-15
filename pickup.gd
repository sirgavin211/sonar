class_name Pickup
extends Area2D

const SIZE := Vector2(20, 20)
const COLORS := {
	"food": Color(0.3, 0.9, 0.3),
	"fuel": Color(1.0, 0.5, 0.1),
	"shard": Color(1.0, 0.95, 0.4),
}

var kind := "food"


static func spawn(parent: Node, item_kind: String, pos: Vector2) -> Pickup:
	var pickup := Pickup.new()
	pickup.kind = item_kind
	pickup.position = pos
	parent.add_child(pickup)
	return pickup


func _ready() -> void:
	collision_layer = 16
	collision_mask = 2  # player
	Placeholder.box(self, SIZE, COLORS[kind])
	Placeholder.collider(self, SIZE)
	EchoGlow.attach(self, 70, COLORS[kind])
	body_entered.connect(_on_body_entered)


# shortcut: full backpack means walk off and back on to retry, fine until it annoys playtesters.
func _on_body_entered(body: Node) -> void:
	if body is Player and body.pick_up(kind):
		queue_free()
