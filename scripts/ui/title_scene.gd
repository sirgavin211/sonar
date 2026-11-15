extends Node2D
# The title screen's cast: the player and the Sun on the left, Listeners and the boss
# closing in from the right. Stays centred on the screen; the Listeners drift a little.

@export var drift := 3.0  # pixels the Listeners bob up and down

var time := 0.0
var rest_y := {}  # each Listener's starting height


func _ready() -> void:
	get_viewport().size_changed.connect(center)
	center()
	for listener in $Listeners.get_children():
		rest_y[listener] = listener.position.y


func center() -> void:
	position = get_viewport_rect().size / 2


func _process(delta: float) -> void:
	time += delta
	var i := 0
	for listener in $Listeners.get_children():
		# Rounded so they move in whole pixels, like everything else.
		listener.position.y = rest_y[listener] + roundf(sin(time * 1.5 + i) * drift)
		i += 1
