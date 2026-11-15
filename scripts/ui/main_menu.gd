extends Control

@onready var buttons := $Center/Panel/Contents/Buttons
@onready var settings := $Center/Panel/Contents/Settings
@onready var volume := $Center/Panel/Contents/Settings/Volume


func _ready() -> void:
	volume.value = AudioServer.get_bus_volume_linear(0)
	for button in buttons.get_children():
		button.mouse_entered.connect(func(): button.modulate = Color(0.65, 1.0, 1.0))
		button.mouse_exited.connect(func(): button.modulate = Color.WHITE)
		button.focus_entered.connect(func(): button.modulate = Color(0.65, 1.0, 1.0))
		button.focus_exited.connect(func(): button.modulate = Color.WHITE)
	$Center/Panel/Contents/Buttons/Play.grab_focus()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_settings_pressed() -> void:
	buttons.hide()
	settings.show()
	volume.grab_focus()


func _on_back_pressed() -> void:
	settings.hide()
	buttons.show()
	$Center/Panel/Contents/Buttons/Settings.grab_focus()


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(0, value)
	AudioServer.set_bus_mute(0, value <= 0.0)


func _on_quit_pressed() -> void:
	get_tree().quit()
