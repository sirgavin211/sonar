extends SceneTree

func _initialize() -> void:
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var buttons = menu.get_node("Center/Panel/Contents/Buttons")
	var settings = menu.get_node("Center/Panel/Contents/Settings")
	assert(buttons.visible and not settings.visible)
	buttons.get_node("Settings").pressed.emit()
	assert(not buttons.visible and settings.visible)
	settings.get_node("Volume").value = 0.5
	assert(is_equal_approx(AudioServer.get_bus_volume_linear(0), 0.5))
	settings.get_node("Back").pressed.emit()
	assert(buttons.visible and not settings.visible)
	buttons.get_node("Play").pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == "res://scenes/main.tscn")
	print("menu test passed")
	quit()
