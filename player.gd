class_name Player
extends CharacterBody2D

signal died
signal shot_fired(at: Vector2)
signal item_picked(kind: String)

const WaveScene := preload("res://sonar_wave.tscn")

@export var max_health := 100.0
@export var food_heal := 30.0
@export_group("Stamina")
@export var max_stamina := 100.0
@export var sprint_boost := 1.7  # speed multiplier while sprinting
@export var stamina_drain := 35.0  # per second while sprinting
@export var stamina_regen := 20.0
@export var stamina_recover_at := 30.0  # running dry locks sprint until this much is back

# Stats the start-of-game ability roll can change.
@export_group("Rollable stats")
@export var speed := 220.0
@export var fire_cooldown := 0.6
@export var wave_range := 700.0
@export var wave_damage := 1
@export var aggro_radius := 600.0  # how far Listeners hear the sonar gun

var health := 0.0
var stamina := 0.0
var exhausted := false
var backpack := Inventory.new(15)  # 3 rows x 5
var frozen := true  # main unfreezes after the start rolls
var is_dead := false
var cooldown_left := 0.0

@onready var gun: Node2D = $Gun
@onready var health_bar: WorldBar = $HealthBar
@onready var size: Vector2 = $CollisionShape2D.shape.size


func _ready() -> void:
	health = max_health
	stamina = max_stamina


func _physics_process(delta: float) -> void:
	if frozen or is_dead:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed * sprint_multiplier(direction, delta)
	move_and_slide()
	gun.rotation = aim_direction().angle()
	cooldown_left -= delta
	if Input.is_action_pressed("shoot") and cooldown_left <= 0.0:
		shoot()


# Drains stamina while sprinting and moving, regens otherwise.
func sprint_multiplier(direction: Vector2, delta: float) -> float:
	var sprinting := Input.is_action_pressed("sprint") and direction != Vector2.ZERO and not exhausted
	if sprinting:
		stamina = maxf(stamina - stamina_drain * delta, 0.0)
		exhausted = stamina == 0.0
		return sprint_boost
	stamina = minf(stamina + stamina_regen * delta, max_stamina)
	if exhausted and stamina >= stamina_recover_at:
		exhausted = false
	return 1.0


func aim_direction() -> Vector2:
	return (get_global_mouse_position() - global_position).normalized()


func shoot() -> void:
	var wave: SonarWave = WaveScene.instantiate()
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
	if health < max_health and backpack.remove("food"):
		health = minf(health + food_heal, max_health)
		health_bar.ratio = health / max_health


func take_damage(amount: float) -> void:
	if is_dead:
		return
	health -= amount
	health_bar.ratio = maxf(health, 0.0) / max_health
	if health <= 0.0:
		health = 0.0
		is_dead = true
		died.emit()
