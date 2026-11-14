extends CharacterBody2D

@export var player_id := 1

const SPEED := 300.0
const JUMP_VELOCITY := -300.0


func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_horizontal()
	move_and_slide()


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func handle_jump() -> void:
	if Input.is_action_just_pressed(action("jump")) and is_on_floor():
		velocity.y = JUMP_VELOCITY


func handle_horizontal() -> void:
	var direction := Input.get_axis(action("left"), action("right"))
	velocity.x = direction * SPEED


func action(action_name: String) -> String:
	return "p%d_%s" % [player_id, action_name]
