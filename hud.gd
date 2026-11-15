class_name Hud
extends CanvasLayer
# zombs.io-style HUD: goal box, run info, minimap, hotbar, resource table, bars,
# backpack/chest grids, big messages. Layout lives in hud.tscn; reads state from main each frame.

const SLOT_SIZE := Vector2(58, 58)

var game: Node  # main.gd
var open_chest: Inventory

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
@onready var chest_grid: GridContainer = $Root/InventoryPanel/Row/Chest/Grid
@onready var overlay: ColorRect = $Root/Overlay
@onready var message: Label = $Root/Overlay/Message


func _ready() -> void:
	minimap.game = game
	add_slots(backpack_grid, 15, _on_backpack_slot)
	add_slots(chest_grid, 15, _on_chest_slot)
	# Hotbar mirrors the backpack's first row; display only.
	add_slots(hotbar, 5, Callable())


# Identical buttons, so they're made here instead of copy-pasted in hud.tscn.
func add_slots(container: Container, count: int, on_click: Callable) -> void:
	for i in count:
		var slot := Button.new()
		slot.custom_minimum_size = SLOT_SIZE
		# No focus, or Tab/Space would get eaten by the buttons.
		slot.focus_mode = Control.FOCUS_NONE
		if on_click.is_valid():
			slot.pressed.connect(on_click.bind(i))
		else:
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(slot)


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
	if inventory_panel.visible:
		fill_grid(backpack_grid, player.backpack)
		if open_chest:
			fill_grid(chest_grid, open_chest)


func fill_grid(grid: Container, inventory: Inventory) -> void:
	for i in grid.get_child_count():
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
