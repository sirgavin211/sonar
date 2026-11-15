extends SceneTree
# Run: Godot --headless --path . --script tests/test_inventory.gd

const InventoryScript := preload("res://scripts/systems/inventory.gd")


func _init() -> void:
	var bag = InventoryScript.new(2)
	assert(bag.add("food", 10))
	assert(bag.add("food", 5))
	assert(bag.count("food") == 15)
	assert(not bag.add("food", 6), "only 5 food space left")
	assert(not bag.add("fuel"), "no free slot for a new kind")
	assert(bag.count("food") == 15, "failed add changes nothing")

	assert(bag.remove("food", 12))
	assert(bag.count("food") == 3)
	assert(not bag.remove("food", 4))
	assert(bag.add("fuel", 10))

	print("inventory tests passed")
	quit()
