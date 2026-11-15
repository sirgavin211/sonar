class_name Listener
extends CharacterBody2D
# Hunts by sound: chases when close, or when the player fires sonar within earshot.
# Main overrides the stats per stage; boss.tscn is this scene with bigger numbers.

signal died(listener: Listener)

@export var max_health := 2
@export var speed := 110.0
@export var contact_damage := 12.0  # per second while touching
@export var sight_radius := 250.0
@export var turn_speed := 10.0  # how fast the sprite swings round to face where it's going
@export var death_sound: AudioStream = preload("res://sound/Keith Ave.ogg")
@export var death_volume_db := 12.0  # the clip is quiet (peaks at -12.7 dB); +12 is about as loud as it goes without clipping

var health := 2
var target: Player
# Growls (positional, so you hear where from) the moment it starts hunting you.
var chasing := false:
	set(value):
		if value and not chasing:
			$Growl.play()
		chasing = value
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
	face_movement(delta)
	if to_player.length() < (size.x + target.size.x) / 2 + 6:
		target.take_damage(contact_damage * delta)


# The art faces down (+y), hence the -90 degrees. Like the player, the rotated
# sprite snaps to the screen's pixel grid, so its pixels shift as it turns.
func face_movement(delta: float) -> void:
	if velocity.length() > 1.0:
		$Body.rotation = lerp_angle($Body.rotation, velocity.angle() - PI / 2, turn_speed * delta)


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
	if is_queued_for_deletion():
		return  # already dead this frame; don't die (or scream) twice
	health -= damage
	health_bar.ratio = float(health) / max_health
	chasing = true
	if health <= 0:
		died.emit(self)
		play_death_sound()
		queue_free()


# The Listener is freed right away, so the sound gets its own node at the death
# spot that removes itself when done.
func play_death_sound() -> void:
	var sound := AudioStreamPlayer2D.new()
	sound.stream = death_sound
	sound.global_position = global_position
	sound.volume_db = death_volume_db
	sound.max_distance = 900.0
	sound.attenuation = 0.5  # gentle falloff: sonar kills are usually far away
	sound.finished.connect(sound.queue_free)
	get_parent().add_child(sound)
	sound.play()
