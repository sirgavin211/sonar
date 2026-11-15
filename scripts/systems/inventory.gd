class_name Inventory
extends RefCounted
# Slots hold null or {"kind", "count"}. Same kinds stack up to STACK_SIZE.

const STACK_SIZE := 10

var slots := []


func _init(slot_count := 15) -> void:
	slots.resize(slot_count)


# All or nothing: returns false and changes nothing if it doesn't fit.
func add(kind: String, amount := 1) -> bool:
	if space_for(kind) < amount:
		return false
	for slot in slots:
		if amount == 0:
			break
		if slot and slot.kind == kind:
			var moved := mini(amount, STACK_SIZE - slot.count)
			slot.count += moved
			amount -= moved
	for i in slots.size():
		if amount == 0:
			break
		if slots[i] == null:
			var moved := mini(amount, STACK_SIZE)
			slots[i] = {"kind": kind, "count": moved}
			amount -= moved
	return true


func remove(kind: String, amount := 1) -> bool:
	if count(kind) < amount:
		return false
	for i in range(slots.size() - 1, -1, -1):
		var slot = slots[i]
		if amount == 0:
			break
		if slot and slot.kind == kind:
			var taken := mini(amount, slot.count)
			slot.count -= taken
			amount -= taken
			if slot.count == 0:
				slots[i] = null
	return true


func count(kind: String) -> int:
	var total := 0
	for slot in slots:
		if slot and slot.kind == kind:
			total += slot.count
	return total


func space_for(kind: String) -> int:
	var space := 0
	for slot in slots:
		if slot == null:
			space += STACK_SIZE
		elif slot.kind == kind:
			space += STACK_SIZE - slot.count
	return space
