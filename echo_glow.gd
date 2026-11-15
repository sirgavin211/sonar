class_name EchoGlow
extends PointLight2D
# Dark until a sonar wave touches its parent, then flashes and fades: the "echo".
# Add an EchoGlow node to anything that should show up on sonar.

@export var flash_energy := 1.5
@export var fade_time := 3.0

var tween: Tween


func _ready() -> void:
	# Lit in the editor so you can see the radius; dark in game until a wave hits.
	# Disabled lights cost nothing; the map has hundreds of these.
	enabled = false
	energy = 0.0
	get_parent().add_to_group("echoable")


static func flash_on(node: Node) -> void:
	var glow := node.get_node_or_null("EchoGlow")
	if glow:
		glow.flash()


func flash() -> void:
	if tween:
		tween.kill()
	enabled = true
	energy = flash_energy
	tween = create_tween()
	tween.tween_property(self, "energy", 0.0, fade_time)
	tween.tween_callback(func(): enabled = false)
