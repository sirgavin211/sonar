class_name SonarWave
extends CharacterBody2D
# Ported from the old sound_wave.gd: bounces off walls, fades per bounce.
# Lights its path and makes anything it touches echo (flash).

const LIFETIME := 3.0
const SIZE := Vector2(18, 6)
const COLOR := Color(0.5, 0.9, 1.0)

var damage := 1
var max_bounces := 3
var bounces_left := 3
var age := 0.0
var light: PointLight2D


func setup(shooter: Player, direction: Vector2) -> void:
	position = shooter.global_position
	velocity = direction * shooter.wave_speed
	damage = shooter.wave_damage
	max_bounces = shooter.wave_bounces
	bounces_left = max_bounces
	rotation = velocity.angle()


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 | 4  # walls, enemies
	Placeholder.box(self, SIZE, COLOR)
	Placeholder.collider(self, SIZE)
	light = Placeholder.light(self, 140, COLOR, 1.0)
	add_sensor()


# Wider than the wave so it echoes things it passes, not only what it hits.
func add_sensor() -> void:
	var sensor := Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 1 | 4 | 16  # walls, enemies, pickups
	var shape := CircleShape2D.new()
	shape.radius = 50
	var collision := CollisionShape2D.new()
	collision.shape = shape
	sensor.add_child(collision)
	add_child(sensor)
	sensor.body_entered.connect(EchoGlow.flash_on)
	sensor.area_entered.connect(EchoGlow.flash_on)


func _physics_process(delta: float) -> void:
	age += delta
	if age > LIFETIME:
		queue_free()
		return
	var collision := move_and_collide(velocity * delta)
	if collision:
		handle_collision(collision)
	rotation = velocity.angle()


func handle_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider()
	EchoGlow.flash_on(collider)
	if collider is Listener:
		collider.take_hit(damage)
		queue_free()
	elif bounces_left > 0:
		bounce(collision.get_normal())
	else:
		queue_free()


func bounce(normal: Vector2) -> void:
	velocity = velocity.bounce(normal)
	bounces_left -= 1
	# Fade as the wave loses energy.
	var strength := 0.4 + 0.6 * float(bounces_left) / max_bounces
	modulate.a = strength
	light.energy = strength
