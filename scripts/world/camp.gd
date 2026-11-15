class_name Camp
extends Node2D
# Metal facility (Subnautica-habitat vibe). Layout lives in camp.tscn:
# walls with a door gap, lit inside, Sun Core in the middle, fuel hopper to its right.

@onready var sun_core: SunCore = $SunCore
@onready var hopper: Hopper = $Hopper


# How far a point is from the factory floor (the Plates rectangle); 0 when on it.
func distance_from_floor(point: Vector2) -> float:
	var plates: Ground = $Plates
	var floor_rect := Rect2(plates.position, plates.size)
	var local := to_local(point)
	return local.distance_to(local.clamp(floor_rect.position, floor_rect.end))
