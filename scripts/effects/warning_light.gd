class_name WarningLight
extends PointLight2D
# Factory lamp that slowly pulses. Each one starts at a random point so they don't blink in sync.

@export var pulse_speed := 2.5
@export var min_energy := 0.15
@export var max_energy := 0.9

var time := randf() * TAU


func _process(delta: float) -> void:
	time += delta * pulse_speed
	energy = lerpf(min_energy, max_energy, (sin(time) + 1.0) / 2.0)
