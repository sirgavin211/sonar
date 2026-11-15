class_name Camp
extends Node2D
# Metal facility (Subnautica-habitat vibe). Layout lives in camp.tscn:
# walls with a door gap, lit inside, Sun Core in the middle, fuel hopper to its right.

@onready var sun_core: SunCore = $SunCore
@onready var hopper: Hopper = $Hopper


# Inside the factory floor (the Plates rectangle).
func contains(point: Vector2) -> bool:
	var plates: Ground = $Plates
	return Rect2(plates.position, plates.size).has_point(to_local(point))
