class_name Listener
extends CharacterBody2D
# Hunts by sound: chases when close, or when the player fires sonar within earshot.
# Main sets the stats below before adding it (stage scaling, boss).

signal died(listener: Listener)

var size := Vector2(26, 26)
var color := Color(0.6, 0.1, 0.8)
var max_health := 2
var speed := 110.0
var contact_damage := 12.0  # per second while touching
var sight_radius := 250.0

var health := 2
var target: Player
var chasing := false
var wander_dir := Vector2.ZERO
var wander_time := 0.0


func _ready() -> void:
	health = max_health
	collision_layer = 4
	collision_mask = 1  # walls only, so they can swarm onto the player
	add_to_group("listeners")
	Placeholder.box(self, size, color)
	Placeholder.collider(self, size)
	EchoGlow.attach(self, size.x * 3, Color(1.0, 0.3, 0.6))


func _physics_process(delta: float) -> void:
	var to_player := target.global_position - global_position
	if to_player.length() < sight_radius:
		chasing = true
	if chasing and not target.is_dead:
		velocity = to_player.normalized() * speed
	else:
		wander(delta)
	move_and_slide()
	if to_player.length() < (size.x + Player.SIZE.x) / 2 + 6:
		target.take_damage(contact_damage * delta)


func wander(delta: float) -> void:
	wander_time -= delta
	if wander_time <= 0.0:
		wander_time = randf_range(1.0, 3.0)
		wander_dir = Vector2.from_angle(randf() * TAU) * randf()
	velocity = wander_dir * speed * 0.4


func hear(at: Vector2, radius: float) -> void:
	if global_position.distance_to(at) < radius:
		chasing = true


func take_hit(damage: int) -> void:
	health -= damage
	chasing = true
	if health <= 0:
		died.emit(self)
		queue_free()
