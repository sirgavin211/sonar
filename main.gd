extends Node2D
# Game manager: start rolls, map, stages, spawns, boss timer, win/lose.
# Every balance number below shows up in the Inspector when you select Main in main.tscn.

const PlayerScene := preload("res://player.tscn")
const CampScene := preload("res://camp.tscn")
const HudScene := preload("res://hud.tscn")
const WallScene := preload("res://wall.tscn")
const PickupScene := preload("res://pickup.tscn")
const ListenerScene := preload("res://listener.tscn")
const BossScene := preload("res://boss.tscn")

@export_group("Map")
@export var map_size := Vector2(4000, 4000)
@export var tile := 100.0  # mountain block size
@export var tree_count := 45
@export var stone_count := 30
@export var bush_count := 90
@export var pebble_count := 70
@export var food_count := 25
@export var fuel_count := 40
@export var scattered_shards := 5  # the last one comes from the boss
@export var camp_clear_radius := 500.0
@export var ground_tiles: Array[Texture2D] = [
	preload("res://graphics/01-bare-rock.png"),
	preload("res://graphics/02-sparse-moss.png"),
	preload("res://graphics/03-patchy-moss.png"),
	preload("res://graphics/04-dense-moss.png"),
]
@export var ground_tile_size := 32.0  # 16px art drawn 2x = 1 art pixel per screen pixel
@export var moss_patch_size := 14.0  # tiles across one moss patch
@export var moss_levels: Array[float] = [-0.12, 0.0, 0.12]  # Perlin cutoffs: stone | sparse | patchy | dense
@export var camp_stone_radius := 450.0  # the camp always sits in stone this far out
@export_subgroup("Nature art")
# Solid (block you, bounce sonar): trees and stones. Walk-over clutter: bushes and pebbles.
@export var tree_textures: Array[Texture2D] = [
	preload("res://graphics/nature/32x32/tree-1.png"),
	preload("res://graphics/nature/32x32/tree-2.png"),
	preload("res://graphics/nature/32x32/tree-3.png"),
	preload("res://graphics/nature/32x32/tree-4.png"),
	preload("res://graphics/nature/48x48/tree-1-48x48.png"),
	preload("res://graphics/nature/48x48/tree-2-48x48.png"),
]
@export var stone_textures: Array[Texture2D] = [
	preload("res://graphics/nature/32x32/stone-2.png"),
	preload("res://graphics/nature/32x32/stone-3.png"),
	preload("res://graphics/nature/32x32/stone-4.png"),
]
@export var bush_textures: Array[Texture2D] = [
	preload("res://graphics/nature/16x16/bush-empty-16.png"),
	preload("res://graphics/nature/16x16/bush-berries-16.png"),
]
@export var pebble_textures: Array[Texture2D] = [
	preload("res://graphics/nature/16x16/rock-small-16.png"),
]
@export var nature_scale := 2.0  # art pixels -> world; 2x everywhere keeps one pixel grid
@export var tree_color := Color(0.2, 0.4, 0.3)  # minimap color
@export var stone_color := Color(0.45, 0.45, 0.5)
@export_subgroup("")
@export var mountain_color := Color(0.35, 0.3, 0.3)
@export var darkness_color := Color(0.03, 0.03, 0.05)

@export_group("Sun")
@export var shards_to_win := 6
@export var fuel_max := 100.0
@export var start_fuel := 60.0
@export var fuel_per_item := 10.0
@export var fuel_drain := 0.4  # per second
@export var interact_range := 80.0

@export_group("Enemies")
@export var start_listeners := 8
@export var boss_delay := 60.0
# Index = stage - 1. Stage 3 is meant to be a near-guaranteed loss.
@export var spawn_per_shard: Array[int] = [3, 6, 20]
@export var stage_stats: Array[Dictionary] = [
	{"speed": 110.0, "max_health": 2, "contact_damage": 12.0},
	{"speed": 150.0, "max_health": 3, "contact_damage": 18.0},
	{"speed": 215.0, "max_health": 5, "contact_damage": 35.0},
]

@export_group("Start rolls")
# Mods are added to player stats. Weights don't need to sum to 100.
@export var abilities: Array[Dictionary] = [
	{"name": "Nothing. Unlucky.", "weight": 60, "tier": "none", "mods": {}},
	{"name": "Heavy Boots (slower)", "weight": 9, "tier": "bad", "mods": {"speed": -60.0}},
	{"name": "Loud Mouth (Listeners hear you from far)", "weight": 8, "tier": "bad", "mods": {"aggro_radius": 700.0}},
	{"name": "Butterfingers (slow sonar)", "weight": 8, "tier": "bad", "mods": {"fire_cooldown": 0.5}},
	{"name": "Quick Feet", "weight": 4, "tier": "good", "mods": {"speed": 90.0}},
	{"name": "Echo Chamber (bigger waves)", "weight": 4, "tier": "good", "mods": {"wave_range": 500.0}},
	{"name": "Rapid Pulse (fast sonar)", "weight": 4, "tier": "good", "mods": {"fire_cooldown": -0.3}},
	{"name": "SUPERNOVA", "weight": 3, "tier": "jackpot",
		"mods": {"speed": 120.0, "wave_range": 800.0, "fire_cooldown": -0.4, "wave_damage": 2}},
]
# seconds 0 = unlimited.
@export var playtimes: Array[Dictionary] = [
	{"name": "3 minutes", "weight": 40, "tier": "bad", "seconds": 180},
	{"name": "5 minutes", "weight": 30, "tier": "none", "seconds": 300},
	{"name": "8 minutes", "weight": 18, "tier": "good", "seconds": 480},
	{"name": "15 minutes", "weight": 9, "tier": "good", "seconds": 900},
	{"name": "UNLIMITED", "weight": 3, "tier": "jackpot", "seconds": 0},
]
@export var tier_flavor := {"none": "meh.", "bad": "oof.", "good": "LET'S GO", "jackpot": "!!! JACKPOT !!!"}

var player: Player
var camp: Camp
var hud: Hud
var darkness: CanvasModulate
var rock_rects: Array[Rect2] = []

var started := false
var game_over := false
var ability: Dictionary
var playtime: Dictionary
var time_left := 0.0
var sun_fuel := 0.0
var shards_found := 0
var shards_deposited := 0
var stage := 1
var boss_timer := -1.0  # < 0 means not counting


func _ready() -> void:
	sun_fuel = start_fuel
	darkness = CanvasModulate.new()
	darkness.color = darkness_color
	add_child(darkness)
	build_map()

	camp = CampScene.instantiate()
	camp.position = map_size / 2
	add_child(camp)

	player = PlayerScene.instantiate()
	player.position = camp.position + Vector2(0, 90)
	add_child(player)
	player.died.connect(func(): lose("The Listeners got you."))
	player.shot_fired.connect(_on_shot_fired)
	player.item_picked.connect(_on_item_picked)

	camp.hopper.crumbled.connect(_on_hopper_crumbled)

	hud = HudScene.instantiate()
	hud.game = self
	add_child(hud)

	spawn_listeners(start_listeners)
	await run_start_rolls()
	start()


# --- Map ---

func build_map() -> void:
	var ground := Ground.new()
	ground.size = map_size
	ground.tiles = ground_tiles
	ground.cell = ground_tile_size
	ground.patch_size = moss_patch_size
	ground.levels = moss_levels
	ground.stone_center = map_size / 2  # where the camp goes
	ground.stone_radius = camp_stone_radius
	ground.noise_seed = randi()
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ground.z_index = -2
	add_child(ground)
	build_mountains()
	# Trees block at the trunk (canopy hangs over you); stones at most of their body.
	scatter_solid(tree_textures, tree_count, 0.45, tree_color, 1)
	scatter_solid(stone_textures, stone_count, 0.75, stone_color, 0)
	scatter_clutter(bush_textures, bush_count)
	scatter_clutter(pebble_textures, pebble_count)
	for i in food_count:
		spawn_pickup("food", random_open_point())
	for i in fuel_count:
		spawn_pickup("fuel", random_open_point())
	for i in scattered_shards:
		spawn_pickup("shard", random_open_point())


# Ring of blocks on every edge keeps the player in.
func build_mountains() -> void:
	var tiles := int(map_size.x / tile)
	for i in tiles:
		var along := (i + 0.5) * tile
		for pos in [Vector2(along, tile / 2), Vector2(along, map_size.y - tile / 2),
				Vector2(tile / 2, along), Vector2(map_size.x - tile / 2, along)]:
			spawn_wall(pos, Vector2(tile, tile), mountain_color)


func spawn_wall(pos: Vector2, size: Vector2, color: Color, texture: Texture2D = null) -> Wall:
	var wall: Wall = WallScene.instantiate()
	wall.position = pos
	wall.size = size
	wall.color = color
	wall.texture = texture
	wall.texture_scale = nature_scale
	add_child(wall)
	return wall


# collider_ratio: how much of the art blocks movement. layer 1 draws over the player.
func scatter_solid(textures: Array[Texture2D], count: int, collider_ratio: float, color: Color, layer: int) -> void:
	for i in count:
		var texture: Texture2D = textures.pick_random()
		var art := texture.get_size() * nature_scale
		var pos := random_open_point()
		var wall := spawn_wall(pos, art * collider_ratio, color, texture)
		wall.z_index = layer
		wall.get_node("Sprite").flip_h = randf() < 0.5
		rock_rects.append(Rect2(pos - art / 2, art))


# Walk-over ground clutter: just art, no collision or sonar echo.
func scatter_clutter(textures: Array[Texture2D], count: int) -> void:
	for i in count:
		var sprite := Sprite2D.new()
		sprite.texture = textures.pick_random()
		sprite.scale = Vector2.ONE * nature_scale
		sprite.flip_h = randf() < 0.5
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = -1
		sprite.position = random_open_point()
		add_child(sprite)


func spawn_pickup(kind: String, pos: Vector2) -> void:
	var pickup: Pickup = PickupScene.instantiate()
	pickup.kind = kind
	pickup.position = pos
	add_child(pickup)


# Inside the mountains, outside the camp, not inside a rock.
func random_open_point() -> Vector2:
	while true:
		var point := Vector2(randf_range(tile * 1.5, map_size.x - tile * 1.5),
				randf_range(tile * 1.5, map_size.y - tile * 1.5))
		if point.distance_to(map_size / 2) < camp_clear_radius:
			continue
		if rock_rects.any(func(rect: Rect2): return rect.grow(30).has_point(point)):
			continue
		return point
	return Vector2.ZERO


# --- Start rolls ---

func run_start_rolls() -> void:
	ability = weighted_pick(abilities)
	await spin("ABILITY ROLL", abilities, ability)
	playtime = weighted_pick(playtimes)
	await spin("HOW LONG YOU GET TO PLAY", playtimes, playtime)
	hud.show_message("Ability: %s\nPlaytime: %s\n\nPress SPACE to start" % [ability.name, playtime.name])
	while not Input.is_action_just_pressed("confirm"):
		await get_tree().process_frame


# Slot-machine flicker that slows down, then lands on the result.
func spin(title: String, options: Array, result: Dictionary) -> void:
	for i in 25:
		hud.show_message("%s\n\n%s" % [title, options.pick_random().name])
		await get_tree().create_timer(0.03 + i * 0.008).timeout
	hud.show_message("%s\n\n%s\n%s" % [title, result.name, tier_flavor[result.tier]])
	await get_tree().create_timer(1.5).timeout


func weighted_pick(options: Array) -> Dictionary:
	var total := 0
	for option in options:
		total += option.weight
	var roll := randi_range(1, total)
	for option in options:
		roll -= option.weight
		if roll <= 0:
			return option
	return options[0]


func start() -> void:
	for stat in ability.mods:
		player.set(stat, player.get(stat) + ability.mods[stat])
	time_left = playtime.seconds
	hud.hide_message()
	player.frozen = false
	started = true


# --- Loop ---

func _process(delta: float) -> void:
	if not started or game_over:
		return
	sun_fuel -= fuel_drain * delta
	if camp.hopper.feeding and not can_use_hopper():
		camp.hopper.stop()
	camp.sun_core.refresh(sun_fuel / fuel_max, shards_deposited, shards_to_win)
	if sun_fuel <= 0.0:
		lose("The sun went cold.")
	if playtime.seconds > 0:
		time_left -= delta
		if time_left <= 0.0:
			lose("Time's up. The jackpot ran dry.")
	if boss_timer > 0.0:
		boss_timer -= delta
		if boss_timer <= 0.0:
			spawn_boss()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if not started or game_over:
		return
	if event.is_action_pressed("backpack"):
		if hud.is_inventory_open():
			close_inventory()
		else:
			open_inventory()
	elif event.is_action_pressed("interact"):
		if hud.is_inventory_open():
			close_inventory()
		else:
			interact()


func open_inventory() -> void:
	hud.open_inventory()
	player.frozen = true


func close_inventory() -> void:
	hud.close_inventory()
	player.frozen = false


# Fuel goes in through the hopper, shards straight into the sun; both from your hand.
func interact() -> void:
	var target := nearest_interactable()
	if target is Hopper and can_use_hopper():
		target.start()
	elif target is SunCore and player.held_kind() == "shard":
		deposit_shards()


# Holding fuel, standing at the hopper, and the sun still has room.
func can_use_hopper() -> bool:
	return player.held_kind() == "fuel" and nearest_interactable() is Hopper and sun_fuel < fuel_max


func nearest_interactable() -> Node2D:
	var best: Node2D = null
	var best_distance := interact_range
	for node in get_tree().get_nodes_in_group("interactable"):
		var distance := player.global_position.distance_to(node.global_position)
		if distance < best_distance:
			best = node
			best_distance = distance
	return best


# Only takes the fuel the sun needs; extra stays in the backpack.
func _on_hopper_crumbled() -> void:
	if player.backpack.remove("fuel"):
		sun_fuel = minf(sun_fuel + fuel_per_item, fuel_max)
		check_win()


func deposit_shards() -> void:
	var shards := player.backpack.count("shard")
	player.backpack.remove("shard", shards)
	shards_deposited += shards
	hud.toast("SHARDS IN THE SUN: %d/%d" % [shards_deposited, shards_to_win])
	check_win()


func check_win() -> void:
	if shards_deposited >= shards_to_win and sun_fuel >= fuel_max:
		win()


func _on_shot_fired(at: Vector2) -> void:
	for listener in get_tree().get_nodes_in_group("listeners"):
		listener.hear(at, player.aggro_radius)


func _on_item_picked(kind: String) -> void:
	if kind != "shard":
		return
	shards_found += 1
	var old_stage := stage
	stage = mini(1 + int(shards_found / 2.0), 3)
	if stage > old_stage:
		$StageUpSound.play()
	hud.toast("SHARD %d/%d  -  STAGE %d\nThey heard that." % [shards_found, shards_to_win, stage])
	# Deferred: can't add physics bodies inside a pickup's collision callback.
	spawn_listeners.call_deferred(spawn_per_shard[stage - 1])
	if shards_found == scattered_shards:
		boss_timer = boss_delay


# --- Enemies ---

func spawn_listeners(count: int) -> void:
	for i in count:
		var listener: Listener = ListenerScene.instantiate()
		for stat in stage_stats[stage - 1]:
			listener.set(stat, stage_stats[stage - 1][stat])
		listener.target = player
		listener.position = far_from_player_point()
		add_child(listener)


func spawn_boss() -> void:
	var boss: Listener = BossScene.instantiate()
	boss.target = player
	boss.position = far_from_player_point()
	boss.died.connect(func(dead: Listener): drop_shard.call_deferred(dead.global_position))
	add_child(boss)
	hud.toast("THE BOSS HAS COME.")


func drop_shard(pos: Vector2) -> void:
	spawn_pickup("shard", pos)
	hud.toast("THE FINAL SHARD DROPPED")


func far_from_player_point() -> Vector2:
	var point := random_open_point()
	while point.distance_to(player.global_position) < 700.0:
		point = random_open_point()
	return point


# --- End ---

func lose(reason: String) -> void:
	if game_over:
		return
	game_over = true
	player.frozen = true
	get_tree().call_group("listeners", "set_physics_process", false)
	hud.show_message("YOU FROZE\n%s\n\nR to retry" % reason)


func win() -> void:
	game_over = true
	player.frozen = true
	get_tree().call_group("listeners", "queue_free")
	var tween := create_tween().set_parallel()
	tween.tween_property(camp.sun_core, "position:y", -1500.0, 5.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(camp.sun_core.glow, "energy", 3.0, 5.0)
	tween.tween_property(darkness, "color", Color.WHITE, 5.0)
	hud.show_message("THE SUN RISES\nYou relit the world.\n\nR to play again", false)


# --- HUD text ---

func sun_fuel_percent() -> float:
	return sun_fuel / fuel_max * 100.0


func goal_text() -> String:
	if not started:
		return ""
	if boss_timer > 0.0:
		return "THE BOSS ARRIVES IN %d.\nKill it for the final shard." % ceili(boss_timer)
	if shards_found >= scattered_shards and shards_found < shards_to_win:
		return "The boss is out there. Kill it for the final shard."
	return "Find sun shards and fuel in the dark. Fuel goes in the hopper, shards in the Sun Core.\n" \
		+ "WASD move  -  1-5 pick item  -  Left Click use (sonar / eat)  -  Shift sprint  -  Tab backpack  -  E interact"


func run_text() -> String:
	if not started:
		return ""
	var time := "UNLIMITED" if playtime.seconds == 0 else "%d:%02d" % [int(time_left / 60), int(time_left) % 60]
	return "Stage %d\nAbility: %s\nTime left: %s" % [stage, ability.name, time]


func prompt_text() -> String:
	if not started or game_over or hud.is_inventory_open():
		return ""
	var target := nearest_interactable()
	if target is Hopper:
		if camp.hopper.feeding:
			return "Crumbling fuel..."
		if player.held_kind() != "fuel":
			return "Hold fuel (1-5) to use the hopper"
		if sun_fuel >= fuel_max:
			return "The sun is full"
	if target is SunCore and player.held_kind() != "shard":
		return "Hold a shard (1-5) to put it in the sun"
	return target.prompt if target else ""
