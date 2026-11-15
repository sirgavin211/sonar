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
@export var rock_count := 70
@export var rock_min_size := 40.0
@export var rock_max_size := 120.0
@export var food_count := 25
@export var fuel_count := 40
@export var scattered_shards := 5  # the last one comes from the boss
@export var camp_clear_radius := 500.0
@export var ground_color := Color(0.33, 0.4, 0.28)
@export var grid_color := Color(0.29, 0.35, 0.24)
@export var rock_color := Color(0.4, 0.38, 0.35)
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
	ground.color = ground_color
	ground.line_color = grid_color
	ground.z_index = -2
	add_child(ground)
	build_mountains()
	for i in rock_count:
		var size := Vector2(randf_range(rock_min_size, rock_max_size), randf_range(rock_min_size, rock_max_size))
		var pos := random_open_point()
		spawn_wall(pos, size, rock_color)
		rock_rects.append(Rect2(pos - size / 2, size))
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


func spawn_wall(pos: Vector2, size: Vector2, color: Color) -> void:
	var wall: Wall = WallScene.instantiate()
	wall.position = pos
	wall.size = size
	wall.color = color
	add_child(wall)


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
	elif event.is_action_pressed("eat"):
		player.eat()


func open_inventory() -> void:
	hud.open_inventory()
	player.frozen = true


func close_inventory() -> void:
	hud.close_inventory()
	player.frozen = false


func interact() -> void:
	if nearest_interactable() is SunCore:
		feed_sun()


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
func feed_sun() -> void:
	var needed := ceili((fuel_max - sun_fuel) / fuel_per_item)
	var fuel := mini(player.backpack.count("fuel"), needed)
	player.backpack.remove("fuel", fuel)
	sun_fuel = minf(sun_fuel + fuel * fuel_per_item, fuel_max)
	var shards := player.backpack.count("shard")
	player.backpack.remove("shard", shards)
	shards_deposited += shards
	if shards > 0:
		hud.toast("SHARDS IN THE SUN: %d/%d" % [shards_deposited, shards_to_win])
	if shards_deposited >= shards_to_win and sun_fuel >= fuel_max:
		win()


func _on_shot_fired(at: Vector2) -> void:
	for listener in get_tree().get_nodes_in_group("listeners"):
		listener.hear(at, player.aggro_radius)


func _on_item_picked(kind: String) -> void:
	if kind != "shard":
		return
	shards_found += 1
	stage = mini(1 + int(shards_found / 2.0), 3)
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
	return "Find sun shards and fuel in the dark, then bring them to the Sun Core in camp.\n" \
		+ "WASD move  -  Left Click sonar  -  Shift sprint  -  Tab backpack  -  E interact  -  F eat"


func run_text() -> String:
	if not started:
		return ""
	var time := "UNLIMITED" if playtime.seconds == 0 else "%d:%02d" % [int(time_left / 60), int(time_left) % 60]
	return "Stage %d\nAbility: %s\nTime left: %s" % [stage, ability.name, time]


func prompt_text() -> String:
	if not started or game_over or hud.is_inventory_open():
		return ""
	var target := nearest_interactable()
	return target.prompt if target else ""
