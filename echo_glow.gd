class_name EchoGlow
extends PointLight2D
# Dark until a sonar wave touches its parent, then flashes and fades: the "echo".

const FLASH_ENERGY := 1.5
const FADE_TIME := 3.0

var tween: Tween


static func attach(parent: Node, radius: float, glow_color := Color(0.6, 0.9, 1.0)) -> EchoGlow:
	var glow := EchoGlow.new()
	glow.name = "EchoGlow"
	glow.texture = Placeholder.radial_texture()
	glow.texture_scale = radius / 128.0
	glow.color = glow_color
	glow.energy = 0.0
	# Disabled lights cost nothing; the map has hundreds of these.
	glow.enabled = false
	parent.add_child(glow)
	return glow


static func flash_on(node: Node) -> void:
	var glow := node.get_node_or_null("EchoGlow")
	if glow:
		glow.flash()


func flash() -> void:
	if tween:
		tween.kill()
	enabled = true
	energy = FLASH_ENERGY
	tween = create_tween()
	tween.tween_property(self, "energy", 0.0, FADE_TIME)
	tween.tween_callback(func(): enabled = false)
