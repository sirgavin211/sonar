class_name Hud
extends CanvasLayer
# zombs.io-style HUD: goal box, run info, minimap, hotbar, resource table, bars,
# backpack grid, big messages. Layout lives in hud.tscn; reads state from main each frame.

const SLOT_SIZE := Vector2(58, 58)

var game: Node  # main.gd

@onready var goal: Label = $Root/Goal/Text
@onready var run_info: Label = $Root/RunInfo/Text
@onready var toast_label: Label = $Root/Toast
@onready var minimap: Minimap = $Root/Minimap
@onready var prompt: Label = $Root/Prompt
@onready var hotbar: HBoxContainer = $Root/Hotbar
@onready var food_count: Label = $Root/Stats/Resources/Grid/Food
@onready var fuel_count: Label = $Root/Stats/Resources/Grid/Fuel
@onready var shard_count: Label = $Root/Stats/Resources/Grid/Shards
@onready var in_sun_count: Label = $Root/Stats/Resources/Grid/InSun
@onready var health_bar: ProgressBar = $Root/Stats/HealthBar
@onready var stamina_bar: ProgressBar = $Root/Stats/StaminaBar
@onready var fuel_bar: ProgressBar = $Root/Stats/FuelBar
@onready var inventory_panel: PanelContainer = $Root/InventoryPanel
@onready var backpack_grid: GridContainer = $Root/InventoryPanel/Row/Backpack/Grid
@onready var overlay: ColorRect = $Root/Overlay
@onready var message: Label = $Root/Overlay/Message


func _ready() -> void:
	minimap.game = game
	add_slots(backpack_grid, 15)
	# Hotbar mirrors the backpack's first row.
	add_slots(hotbar, 5)
	number_slots(hotbar)


# Identical display-only slots, so they're made here instead of copy-pasted in hud.tscn.
func add_slots(container: Container, count: int) -> void:
	for i in count:
		var slot := Button.new()
		slot.custom_minimum_size = SLOT_SIZE
		# No focus, or Tab/Space would get eaten by the buttons.
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Pixel-art icons: scaled up crisp, filling the slot like Minecraft's hotbar.
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slot.expand_icon = true
		slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		# Stack size in the bottom-right corner, same style as the slot numbers.
		var stack := corner_label(slot, Control.PRESET_BOTTOM_RIGHT)
		stack.name = "Count"
		stack.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		container.add_child(slot)


# Small 1-5 in the top-left of each hotbar slot, matching the number keys.
func number_slots(container: Container) -> void:
	for i in container.get_child_count():
		corner_label(container.get_child(i), Control.PRESET_TOP_LEFT).text = str(i + 1)


# One shared look for the slot number and the stack count.
func corner_label(slot: Button, corner: Control.LayoutPreset) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	slot.add_child(label)
	label.set_anchors_and_offsets_preset(corner, Control.PRESET_MODE_MINSIZE, 4)
	return label


func _process(_delta: float) -> void:
	var player: Player = game.player
	health_bar.value = player.health / player.max_health * 100.0
	stamina_bar.value = player.stamina / player.max_stamina * 100.0
	# Dim while exhausted so you know sprint is locked.
	stamina_bar.modulate.a = 0.4 if player.exhausted else 1.0
	fuel_bar.value = game.sun_fuel_percent()
	food_count.text = str(player.backpack.count("food"))
	fuel_count.text = str(player.backpack.count("fuel"))
	shard_count.text = str(player.backpack.count("shard"))
	in_sun_count.text = "%d/%d" % [game.shards_deposited, game.shards_to_win]
	goal.text = game.goal_text()
	goal.get_parent().visible = goal.text != ""
	run_info.text = game.run_text()
	run_info.get_parent().visible = run_info.text != ""
	prompt.text = game.prompt_text()
	fill_grid(hotbar, player.backpack)
	for i in hotbar.get_child_count():
		hotbar.get_child(i).theme_type_variation = &"HotbarSelected" if i == player.selected else &""
	if inventory_panel.visible:
		fill_grid(backpack_grid, player.backpack)


func fill_grid(grid: Container, inventory: Inventory) -> void:
	for i in grid.get_child_count():
		var slot: Button = grid.get_child(i)
		var item = inventory.slots[i]
		slot.icon = Pickup.ICONS.get(item.kind) if item else null
		# Items without art yet show their name instead of an icon.
		slot.text = item.kind if item and not slot.icon else ""
		# Like Minecraft: no number for a single item.
		slot.get_node("Count").text = str(item.count) if item and item.count > 1 else ""
		if item:
			slot.add_theme_color_override("font_color", Pickup.COLORS[item.kind])


func open_inventory() -> void:
	inventory_panel.show()


func close_inventory() -> void:
	inventory_panel.hide()


func is_inventory_open() -> bool:
	return inventory_panel.visible


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
