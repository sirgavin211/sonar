extends Node2D

var round_over := false


func _ready() -> void:
	for player in [$Player, $Player2]:
		player.cracks_changed.connect(_on_cracks_changed)
		player.shattered.connect(_on_shattered)
		_on_cracks_changed(player.player_id, player.cracks_left)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _on_cracks_changed(player_id: int, cracks_left: int) -> void:
	var label: Label = $HUD/P1Label if player_id == 1 else $HUD/P2Label
	label.text = "P%d glass: %d/4" % [player_id, cracks_left]


func _on_shattered(player_id: int) -> void:
	if round_over:
		return
	round_over = true
	var winner := 2 if player_id == 1 else 1
	$HUD/WinnerLabel.text = "Player %d wins!\nPress R to restart" % winner
	$HUD/WinnerLabel.show()
