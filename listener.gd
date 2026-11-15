class_name Listener
extends CharacterBody2D
# Hunts by sound: chases when close, or when the player fires sonar within earshot.
# Main overrides the stats per stage; boss.tscn is this scene with bigger numbers.

signal died(listener: Listener)

@export var max_health := 2
@export var speed := 110.0
@export var contact_damage := 12.0  # per second while touching
@export var sight_radius := 250.0

var health := 2
var target: Player
var chasing := false
var wander_dir := Vector2.ZERO
var wander_time := 0.0

@onready var size: Vector2 = $CollisionShape2D.shape.size
@onready var health_bar: WorldBar = $HealthBar


func _ready() -> void:
	health = max_health
	health_bar.ratio = 1.0


func _physics_process(delta: float) -> void:
	var to_player := target.global_position - global_position
	if to_player.length() < sight_radius:
		chasing = true
	if chasing and not target.is_dead:
		velocity = to_player.normalized() * speed
	else:
		wander(delta)
	move_and_slide()
	if to_player.length() < (size.x + target.size.x) / 2 + 6:
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
	health_bar.ratio = float(health) / max_health
	chasing = true
	if health <= 0:
		died.emit(self)
		queue_free()
