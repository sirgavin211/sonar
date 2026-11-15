class_name SunCore
extends StaticBody2D
# The unfinished artificial sun. Glows with fuel (fed through the hopper), grows with shards.

@export var prompt := "E: put shards in the sun"
@export var cold := Color(0.3, 0.15, 0.05)
@export var hot := Color(1.0, 0.9, 0.4)

@onready var core: FlatShape = $Core
@onready var glow: PointLight2D = $Glow


func refresh(fuel_ratio: float, shards: int, total_shards: int) -> void:
	core.color = cold.lerp(hot, fuel_ratio)
	core.scale = Vector2.ONE * (0.6 + 0.4 * shards / float(total_shards))
	glow.energy = fuel_ratio
