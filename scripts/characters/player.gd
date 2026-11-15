class_name Player
extends CharacterBody2D

signal died
signal shot_fired(at: Vector2)
signal item_picked(kind: String)

const WaveScene := preload("res://scenes/effects/sonar_wave.tscn")

@export var max_health := 100.0
@export var food_heal := 30.0
@export var eat_time := 1.0  # seconds to finish one food
@export var sprint_step_pitch := 1.35  # footsteps speed up while sprinting
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
var has_sprinted := false  # for the "Hold Shift to sprint" quest step
var backpack := Inventory.new(15)  # 3 rows x 5
var frozen := true  # main unfreezes after the start rolls
var is_dead := false
var cooldown_left := 0.0
var selected := 0  # hotbar slot 0-4, picked with number keys
var eat_left := 0.0  # > 0 while eating
var eat_tween: Tween

@onready var gun: Node2D = $Gun
@onready var muzzle: Marker2D = $Gun/Muzzle  # center of the orb in the sprite
@onready var held: Node2D = $Gun/Muzzle/Held
@onready var crumbs: CPUParticles2D = $Gun/Muzzle/Crumbs
@onready var health_bar: WorldBar = $HealthBar
@onready var footsteps: AudioStreamPlayer = $Footsteps
@onready var size: Vector2 = $CollisionShape2D.shape.size


func _ready() -> void:
	health = max_health
	stamina = max_stamina
	backpack.add("sonar")  # always starts in slot 1


func _physics_process(delta: float) -> void:
	if frozen or is_dead:
		footsteps.stream_paused = true
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var boost := sprint_multiplier(direction, delta)
	velocity = direction * speed * boost
	move_and_slide()
	play_footsteps(boost > 1.0)
	gun.rotation = aim_direction().angle()
	cooldown_left -= delta
	for i in 5:
		if Input.is_action_just_pressed("slot_%d" % (i + 1)):
			select(i)
	show_held()
	use_held(delta)


# Left click uses whatever is in the selected slot.
func use_held(delta: float) -> void:
	if eat_left > 0.0:
		eat_left -= delta
		if eat_left <= 0.0:
			finish_eating()
		return
	# A click on a hotbar slot is for the slot, not a sonar shot or a bite.
	if get_viewport().gui_get_hovered_control() is Button:
		return
	var kind := held_kind()
	if kind == "sonar" and Input.is_action_pressed("shoot") and cooldown_left <= 0.0:
		shoot()
	elif kind == "food" and Input.is_action_just_pressed("shoot") and health < max_health:
		start_eating()


func held_kind() -> String:
	var item = backpack.slots[selected]
	return item.kind if item else ""


func select(slot: int) -> void:
	selected = slot
	stop_eating()


# The sonar orb is part of the character art; other items show their icon in the hand.
func show_held() -> void:
	var kind := held_kind()
	held.visible = kind != "" and kind != "sonar"
	if held.visible:
		$Gun/Muzzle/Held/Icon.texture = Pickup.world_icon_for(kind)


# One long looping track: paused when standing still so it picks up where it left off.
func play_footsteps(sprinting: bool) -> void:
	var moving := get_real_velocity().length() > 1.0
	if moving and not footsteps.playing:
		footsteps.play()
	footsteps.stream_paused = not moving
	footsteps.pitch_scale = sprint_step_pitch if sprinting else 1.0


# Drains stamina while sprinting and moving, regens otherwise.
func sprint_multiplier(direction: Vector2, delta: float) -> float:
	var sprinting := Input.is_action_pressed("sprint") and direction != Vector2.ZERO and not exhausted
	if sprinting:
		has_sprinted = true
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
	var origin := muzzle.global_position
	wave.setup(self, origin, (get_global_mouse_position() - origin).normalized())
	get_parent().add_child(wave)
	$SonarSound.play()
	cooldown_left = fire_cooldown
	shot_fired.emit(global_position)


func pick_up(kind: String) -> bool:
	if not backpack.add(kind):
		return false
	# Shards get their own big sound; everything else the normal pickup blip.
	if kind == "shard":
		$ShardSound.play()
	else:
		$CollectSound.play()
	item_picked.emit(kind)
	return true


# Food shrinks in the hand while crumbs fall, then heals.
func start_eating() -> void:
	eat_left = eat_time
	crumbs.emitting = true
	$EatSound.play()
	held.scale = Vector2.ONE
	eat_tween = create_tween()
	eat_tween.tween_property(held, "scale", Vector2.ZERO, eat_time)


func finish_eating() -> void:
	stop_eating(false)
	if backpack.remove("food"):
		health = minf(health + food_heal, max_health)
		health_bar.ratio = health / max_health


# cut_sound: switching away mid-bite cuts the crunch; finishing lets it ring out.
func stop_eating(cut_sound := true) -> void:
	if eat_tween:
		eat_tween.kill()
	eat_left = 0.0
	crumbs.emitting = false
	held.scale = Vector2.ONE
	if cut_sound:
		$EatSound.stop()


func take_damage(amount: float) -> void:
	if is_dead:
		return
	health -= amount
	health_bar.ratio = maxf(health, 0.0) / max_health
	# Contact damage lands every frame; letting the clip finish first makes it ~once a second.
	if amount > 0.0 and not $HurtSound.playing:
		$HurtSound.play()
	if health <= 0.0:
		health = 0.0
		is_dead = true
		died.emit()
