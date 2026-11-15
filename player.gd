class_name Player
extends CharacterBody2D

signal died
signal shot_fired(at: Vector2)
signal item_picked(kind: String)

const SIZE := Vector2(28, 28)
const MAX_HEALTH := 100.0
const FOOD_HEAL := 30.0

# Stats the start-of-game ability roll can change.
var speed := 220.0
var fire_cooldown := 0.35
var wave_speed := 700.0
var wave_bounces := 3
var wave_damage := 1
var aggro_radius := 600.0  # how far Listeners hear the sonar gun

var health := MAX_HEALTH
var backpack := Inventory.new(15)  # 3 rows x 5
var frozen := true  # main unfreezes after the start rolls
var is_dead := false
var cooldown_left := 0.0
var gun: Node2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	Placeholder.box(self, SIZE, Color(0.9, 0.9, 1.0))
	Placeholder.collider(self, SIZE)
	gun = Node2D.new()
	add_child(gun)
	var barrel := Placeholder.box(gun, Vector2(24, 8), Color(0.5, 0.6, 0.7))
	barrel.position.x += 18
	# Just enough light to see yourself in the dark.
	Placeholder.light(self, 80, Color.WHITE, 0.7)
	add_child(Camera2D.new())


func _physics_process(delta: float) -> void:
	if frozen or is_dead:
		return
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * speed
	move_and_slide()
	gun.rotation = aim_direction().angle()
	cooldown_left -= delta
	if Input.is_action_pressed("shoot") and cooldown_left <= 0.0:
		shoot()


func aim_direction() -> Vector2:
	return (get_global_mouse_position() - global_position).normalized()


func shoot() -> void:
	var wave := SonarWave.new()
	wave.setup(self, aim_direction())
	get_parent().add_child(wave)
	cooldown_left = fire_cooldown
	shot_fired.emit(global_position)


func pick_up(kind: String) -> bool:
	if not backpack.add(kind):
		return false
	item_picked.emit(kind)
	return true


func eat() -> void:
	if health < MAX_HEALTH and backpack.remove("food"):
		health = minf(health + FOOD_HEAL, MAX_HEALTH)


func take_damage(amount: float) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0.0:
		health = 0.0
		is_dead = true
		died.emit()
