class_name SunCore
extends StaticBody2D
# The unfinished artificial sun. Glows with fuel, grows with shards.

const SIZE := Vector2(60, 60)
const COLD := Color(0.3, 0.15, 0.05)
const HOT := Color(1.0, 0.9, 0.4)

var prompt := "E: feed the sun"
var core: ColorRect
var glow: PointLight2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("interactable")
	core = Placeholder.box(self, SIZE, COLD)
	Placeholder.collider(self, SIZE)
	glow = Placeholder.light(self, 200, HOT, 0.0)


func refresh(fuel_ratio: float, shards: int, total_shards: int) -> void:
	core.color = COLD.lerp(HOT, fuel_ratio)
	core.scale = Vector2.ONE * (0.6 + 0.4 * shards / float(total_shards))
	glow.energy = fuel_ratio
