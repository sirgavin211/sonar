extends CharacterBody2D

const LIFETIME := 4.0
# Time before a wave can hit its own shooter, so it doesn't hit them on spawn.
const SELF_HIT_GRACE := 0.15

var damage := 1
var max_bounces := 3
var bounces_left := 3
var age := 0.0
var shooter: Node2D


func setup(from: Node2D, weapon: Dictionary, direction: Vector2) -> void:
	shooter = from
	global_position = from.global_position
	velocity = direction * weapon.speed
	damage = weapon.damage
	max_bounces = weapon.bounces
	bounces_left = max_bounces
	scale = Vector2.ONE * weapon.size
	rotation = velocity.angle()
	add_collision_exception_with(from)


func _physics_process(delta: float) -> void:
	age += delta
	if age > LIFETIME:
		queue_free()
		return

	# Grace over: the wave can now bounce back and hit its shooter.
	if is_instance_valid(shooter) and age > SELF_HIT_GRACE:
		remove_collision_exception_with(shooter)
		shooter = null

	var collision := move_and_collide(velocity * delta)
	if collision:
		handle_collision(collision)
	# Sprite art points right (angle 0), so face the travel direction.
	rotation = velocity.angle()


func handle_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider()
	if collider.has_method("take_hit"):
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
	modulate.a = 0.4 + 0.6 * float(bounces_left) / max_bounces
