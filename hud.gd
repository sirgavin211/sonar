class_name Hud
extends CanvasLayer
# Bars, status text, backpack/chest grids, big messages. Reads state from main each frame.

const SLOT_SIZE := Vector2(64, 64)

var game: Node  # main.gd
var health_bar: ProgressBar
var fuel_bar: ProgressBar
var info: Label
var prompt: Label
var toast_label: Label
var overlay: ColorRect
var message: Label
var inventory_panel: PanelContainer
var backpack_grid: GridContainer
var chest_grid: GridContainer
var open_chest: Inventory


func _ready() -> void:
	var status := VBoxContainer.new()
	status.position = Vector2(16, 16)
	status.custom_minimum_size.x = 260
	add_child(status)
	health_bar = make_bar(status, "Health", Color(0.85, 0.2, 0.2))
	fuel_bar = make_bar(status, "Sun fuel", Color(1.0, 0.6, 0.1))
	info = Label.new()
	status.add_child(info)

	prompt = Label.new()
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.offset_top = -80
	add_child(prompt)

	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 36)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	toast_label.offset_top = 90
	add_child(toast_label)

	build_inventory_panel()
	build_overlay()


func make_bar(parent: Node, title: String, color: Color) -> ProgressBar:
	var label := Label.new()
	label.text = title
	parent.add_child(label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(260, 18)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar


func build_inventory_panel() -> void:
	inventory_panel = PanelContainer.new()
	inventory_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	inventory_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	inventory_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	inventory_panel.hide()
	add_child(inventory_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	inventory_panel.add_child(row)
	backpack_grid = make_grid(row, "Backpack (click to move)", _on_backpack_slot)
	chest_grid = make_grid(row, "Chest", _on_chest_slot)


func make_grid(parent: Node, title: String, on_click: Callable) -> GridContainer:
	var column := VBoxContainer.new()
	parent.add_child(column)
	var label := Label.new()
	label.text = title
	column.add_child(label)
	var grid := GridContainer.new()
	grid.columns = 5
	column.add_child(grid)
	for i in 15:
		var slot := Button.new()
		slot.custom_minimum_size = SLOT_SIZE
		# No focus, or Tab/Space would get eaten by the buttons.
		slot.focus_mode = Control.FOCUS_NONE
		slot.pressed.connect(on_click.bind(i))
		grid.add_child(slot)
	return grid


func build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.hide()
	add_child(overlay)
	message = Label.new()
	message.set_anchors_preset(Control.PRESET_FULL_RECT)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 40)
	overlay.add_child(message)


func _process(_delta: float) -> void:
	health_bar.value = game.player.health / Player.MAX_HEALTH * 100.0
	fuel_bar.value = game.sun_fuel_percent()
	info.text = game.status_text()
	prompt.text = game.prompt_text()
	if inventory_panel.visible:
		fill_grid(backpack_grid, game.player.backpack)
		if open_chest:
			fill_grid(chest_grid, open_chest)


func fill_grid(grid: GridContainer, inventory: Inventory) -> void:
	for i in 15:
		var slot: Button = grid.get_child(i)
		var item = inventory.slots[i]
		slot.text = "" if item == null else "%s\nx%d" % [item.kind, item.count]
		if item:
			slot.add_theme_color_override("font_color", Pickup.COLORS[item.kind])


func open_inventory(chest: Inventory = null) -> void:
	open_chest = chest
	chest_grid.get_parent().visible = chest != null
	inventory_panel.show()


func close_inventory() -> void:
	open_chest = null
	inventory_panel.hide()


func is_inventory_open() -> bool:
	return inventory_panel.visible


func _on_backpack_slot(index: int) -> void:
	if open_chest:
		game.player.backpack.move_slot(index, open_chest)


func _on_chest_slot(index: int) -> void:
	open_chest.move_slot(index, game.player.backpack)


func show_message(text: String, dim := true) -> void:
	message.text = text
	overlay.color = Color(0, 0, 0, 0.75 if dim else 0.0)
	overlay.show()


func hide_message() -> void:
	overlay.hide()


func toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	create_tween().tween_property(toast_label, "modulate:a", 0.0, 2.0).set_delay(0.8)
