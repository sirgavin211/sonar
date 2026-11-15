class_name Chest
extends StaticBody2D

const SIZE := Vector2(44, 30)

var inventory := Inventory.new(15)
var prompt := "E: open chest"


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("interactable")
	Placeholder.box(self, SIZE, Color(0.55, 0.35, 0.15))
	Placeholder.collider(self, SIZE)
	EchoGlow.attach(self, 60)
