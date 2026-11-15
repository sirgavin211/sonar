class_name Camp
extends Node2D
# Metal facility (Subnautica-habitat vibe): walls with a door gap, lit inside,
# Sun Core in the middle, chests along the left wall.

const SIZE := Vector2(480, 320)
const WALL := 16.0
const DOOR := 110.0
const METAL := Color(0.45, 0.5, 0.55)
const CHEST_COUNT := 3

var sun_core: SunCore


func _ready() -> void:
	var floor_rect := Placeholder.box(self, SIZE, Color(0.2, 0.24, 0.28))
	floor_rect.z_index = -1
	build_walls()
	Placeholder.light(self, 320, Color(1.0, 0.95, 0.85), 0.9)

	sun_core = SunCore.new()
	sun_core.position = Vector2(0, -20)
	add_child(sun_core)

	for i in CHEST_COUNT:
		var chest := Chest.new()
		chest.position = Vector2(-SIZE.x / 2 + 40, -80 + i * 80)
		add_child(chest)


func build_walls() -> void:
	var half := SIZE / 2
	Placeholder.wall(self, Vector2(0, -half.y), Vector2(SIZE.x, WALL), METAL)
	Placeholder.wall(self, Vector2(-half.x, 0), Vector2(WALL, SIZE.y), METAL)
	Placeholder.wall(self, Vector2(half.x, 0), Vector2(WALL, SIZE.y), METAL)
	# Bottom wall is two pieces with the door between them.
	var piece := (SIZE.x - DOOR) / 2
	for side in [-1, 1]:
		Placeholder.wall(self, Vector2(side * (DOOR + piece) / 2, half.y), Vector2(piece, WALL), METAL)
