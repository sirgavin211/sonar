class_name Hopper
extends StaticBody2D
# Feeds the sun one piece of fuel at a time: each piece crumbles into the mouth
# over crumble_time, then `crumbled` fires and main adds its fuel to the sun.
# Main stops it when you run out of fuel, switch items, walk off, or the sun is full.

signal crumbled

@export var prompt := "E: crumble fuel into the hopper"
@export var crumble_time := 1.0

var feeding := false
var time_left := 0.0
var shrink: Tween
var piece_scale := Vector2.ONE  # Piece's scale in hopper.tscn, restored for each new piece

@onready var piece: Sprite2D = $Piece
@onready var crumbs: CPUParticles2D = $Crumbs


func _ready() -> void:
	piece_scale = piece.scale


func start() -> void:
	if feeding:
		return
	feeding = true
	$CrunchSound.play()
	next_piece()


func stop() -> void:
	feeding = false
	$CrunchSound.stop()
	piece.hide()
	crumbs.emitting = false
	if shrink:
		shrink.kill()


func next_piece() -> void:
	time_left = crumble_time
	piece.show()
	piece.scale = piece_scale
	crumbs.emitting = true
	if shrink:
		shrink.kill()
	shrink = create_tween()
	shrink.tween_property(piece, "scale", Vector2.ZERO, crumble_time)


func _process(delta: float) -> void:
	if not feeding:
		return
	time_left -= delta
	if time_left <= 0.0:
		crumbled.emit()
		if feeding:
			next_piece()
