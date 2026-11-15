extends CharacterBody2D

signal cracks_changed(player_id: int, cracks_left: int)
signal shattered(player_id: int)

@export var player_id := 1

const SPEED := 300.0
const JUMP_VELOCITY := -350.0
const MAX_CRACKS := 4
const AIM_TURN_SPEED := 3.0
const AIM_LENGTH := 40.0
const CRACKED_COLOR := Color(1, 0.35, 0.35)
const WaveScene := preload("res://sound_wave.tscn")

# Bass is slow and heavy, treble is fast and bouncy.
const WEAPONS := [
	{"name": "Bass", "speed": 500.0, "cooldown": 0.6, "damage": 2, "bounces": 2, "pitch": 0.6, "size": 1.5},
	{"name": "Mid", "speed": 800.0, "cooldown": 0.3, "damage": 1, "bounces": 3, "pitch": 1.0, "size": 1.0},
	{"name": "Treble", "speed": 1200.0, "cooldown": 0.15, "damage": 1, "bounces": 5, "pitch": 1.6, "size": 0.7},
]

var cooldown_left := 0.0
var weapon_index := 1
var aim_angle := 0.0
var cracks_left := MAX_CRACKS
var is_shattered := false


func _ready() -> void:
	# P2 spawns on the right, so start aiming left.
	if player_id == 2:
		aim_angle = PI


func _physics_process(delta: float) -> void:
	if is_shattered:
		return
	apply_gravity(delta)
	handle_movement()
	move_and_slide()
	handle_weapon_switch()
	handle_aim(delta)
	handle_shooting(delta)


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func handle_movement() -> void:
	if Input.is_action_just_pressed(action("jump")) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis(action("left"), action("right"))
	velocity.x = direction * SPEED


func handle_weapon_switch() -> void:
	for i in WEAPONS.size():
		if Input.is_action_just_pressed(action("weapon_%d" % (i + 1))):
			weapon_index = i


# P1 aims with the mouse; P2 has no mouse, so rotates aim with keys.
func handle_aim(delta: float) -> void:
	if player_id != 1:
		aim_angle += Input.get_axis(action("aim_left"), action("aim_right")) * AIM_TURN_SPEED * delta


# Hold shoot to aim, release to fire.
func handle_shooting(delta: float) -> void:
	cooldown_left -= delta
	var aiming := Input.is_action_pressed(action("shoot"))
	$AimLine.visible = aiming
	if aiming:
		$AimLine.set_point_position(1, aim_line_end())
	if Input.is_action_just_released(action("shoot")) and cooldown_left <= 0.0:
		shoot()


func shoot() -> void:
	var weapon: Dictionary = WEAPONS[weapon_index]
	var wave := WaveScene.instantiate()
	get_tree().current_scene.add_child(wave)
	wave.setup(self, weapon, aim_direction())
	cooldown_left = weapon.cooldown
	$ShootSound.pitch_scale = weapon.pitch
	$ShootSound.play()


func aim_direction() -> Vector2:
	if player_id == 1:
		return (get_global_mouse_position() - global_position).normalized()
	return Vector2.from_angle(aim_angle)


func aim_line_end() -> Vector2:
	if player_id == 1:
		return $AimLine.to_local(get_global_mouse_position())
	return aim_direction() * AIM_LENGTH


func take_hit(damage: int) -> void:
	if is_shattered:
		return
	cracks_left = maxi(cracks_left - damage, 0)
	# Placeholder for crack sprites: tint redder with each hit.
	$Sprite2D.modulate = Color.WHITE.lerp(CRACKED_COLOR, 1.0 - float(cracks_left) / MAX_CRACKS)
	cracks_changed.emit(player_id, cracks_left)
	if cracks_left == 0:
		shatter()


func shatter() -> void:
	is_shattered = true
	$Sprite2D.hide()
	$AimLine.hide()
	# Deferred: can't change collision shapes mid physics step.
	$CollisionShape2D.set_deferred("disabled", true)
	$ShatterParticles.emitting = true
	shattered.emit(player_id)


func action(action_name: String) -> String:
	return "p%d_%s" % [player_id, action_name]
