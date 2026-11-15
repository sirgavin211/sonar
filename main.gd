extends Node2D
# Game manager: start rolls, map, stages, spawns, boss timer, win/lose.

# --- Balance (tweak here) ---
const MAP_SIZE := Vector2(4000, 4000)
const TILE := 100.0  # mountain block size
const ROCK_COUNT := 70
const FOOD_COUNT := 25
const FUEL_COUNT := 40
const SCATTERED_SHARDS := 5  # the 6th comes from the boss
const SHARDS_TO_WIN := 6
const CAMP_CLEAR_RADIUS := 500.0
const FUEL_MAX := 100.0
const START_FUEL := 60.0
const FUEL_PER_ITEM := 10.0
const FUEL_DRAIN := 0.4  # per second
const BOSS_DELAY := 60.0
const START_LISTENERS := 8
const INTERACT_RANGE := 80.0
const DARKNESS := Color(0.03, 0.03, 0.05)

# Index = stage - 1. Stage 3 is meant to be a near-guaranteed loss.
const SPAWN_PER_SHARD := [3, 6, 20]
const STAGE_STATS := [
	{"speed": 110.0, "max_health": 2, "contact_damage": 12.0},
	{"speed": 150.0, "max_health": 3, "contact_damage": 18.0},
	{"speed": 215.0, "max_health": 5, "contact_damage": 35.0},
]
const BOSS_STATS := {
	"size": Vector2(80, 80), "color": Color(0.9, 0.1, 0.1), "max_health": 40,
	"speed": 160.0, "contact_damage": 40.0, "sight_radius": 100000.0,
}

# Changes are added to player stats. Weights don't need to sum to 100.
const ABILITIES := [
	{"name": "Nothing. Unlucky.", "weight": 60, "tier": "none", "mods": {}},
	{"name": "Heavy Boots (slower)", "weight": 9, "tier": "bad", "mods": {"speed": -60.0}},
	{"name": "Loud Mouth (Listeners hear you from far)", "weight": 8, "tier": "bad", "mods": {"aggro_radius": 700.0}},
	{"name": "Butterfingers (slow sonar)", "weight": 8, "tier": "bad", "mods": {"fire_cooldown": 0.3}},
	{"name": "Quick Feet", "weight": 4, "tier": "good", "mods": {"speed": 90.0}},
	{"name": "Echo Chamber (more bounces)", "weight": 4, "tier": "good", "mods": {"wave_bounces": 4}},
	{"name": "Rapid Pulse (fast sonar)", "weight": 4, "tier": "good", "mods": {"fire_cooldown": -0.2}},
	{"name": "SUPERNOVA", "weight": 3, "tier": "jackpot",
		"mods": {"speed": 120.0, "wave_bounces": 6, "fire_cooldown": -0.27, "wave_damage": 2}},
]
# seconds 0 = unlimited.
const PLAYTIMES := [
	{"name": "3 minutes", "weight": 40, "tier": "bad", "seconds": 180},
	{"name": "5 minutes", "weight": 30, "tier": "none", "seconds": 300},
	{"name": "8 minutes", "weight": 18, "tier": "good", "seconds": 480},
	{"name": "15 minutes", "weight": 9, "tier": "good", "seconds": 900},
	{"name": "UNLIMITED", "weight": 3, "tier": "jackpot", "seconds": 0},
]
const TIER_FLAVOR := {"none": "meh.", "bad": "oof.", "good": "LET'S GO", "jackpot": "!!! JACKPOT !!!"}

const KEY_ACTIONS := {
	"move_up": KEY_W, "move_down": KEY_S, "move_left": KEY_A, "move_right": KEY_D,
	"backpack": KEY_TAB, "interact": KEY_E, "eat": KEY_F, "confirm": KEY_SPACE, "restart": KEY_R,
}

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
var sun_fuel := START_FUEL
var shards_found := 0
var shards_deposited := 0
var stage := 1
var boss_timer := -1.0  # < 0 means not counting


func _ready() -> void:
	setup_input()
	darkness = CanvasModulate.new()
	darkness.color = DARKNESS
	add_child(darkness)
	build_map()

	camp = Camp.new()
	camp.position = MAP_SIZE / 2
	add_child(camp)

	player = Player.new()
	player.position = camp.position + Vector2(0, 90)
	add_child(player)
	player.died.connect(func(): lose("The Listeners got you."))
	player.shot_fired.connect(_on_shot_fired)
	player.item_picked.connect(_on_item_picked)

	hud = Hud.new()
	hud.game = self
	add_child(hud)

	spawn_listeners(START_LISTENERS)
	await run_start_rolls()
	start()


func setup_input() -> void:
	for action in KEY_ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_ACTIONS[action]
		InputMap.action_add_event(action, key)
	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("shoot", click)


# --- Map ---

func build_map() -> void:
	var ground := Placeholder.box(self, MAP_SIZE, Color(0.25, 0.22, 0.2))
	ground.position = Vector2.ZERO
	ground.z_index = -2
	build_mountains()
	for i in ROCK_COUNT:
		var size := Vector2(randf_range(40, 120), randf_range(40, 120))
		var pos := random_open_point()
		Placeholder.wall(self, pos, size, Color(0.4, 0.38, 0.35))
		rock_rects.append(Rect2(pos - size / 2, size))
	for i in FOOD_COUNT:
		Pickup.spawn(self, "food", random_open_point())
	for i in FUEL_COUNT:
		Pickup.spawn(self, "fuel", random_open_point())
	for i in SCATTERED_SHARDS:
		Pickup.spawn(self, "shard", random_open_point())


# Ring of blocks on every edge keeps the player in.
func build_mountains() -> void:
	var tiles := int(MAP_SIZE.x / TILE)
	var mountain := Color(0.35, 0.3, 0.3)
	for i in tiles:
		var along := (i + 0.5) * TILE
		for pos in [Vector2(along, TILE / 2), Vector2(along, MAP_SIZE.y - TILE / 2),
				Vector2(TILE / 2, along), Vector2(MAP_SIZE.x - TILE / 2, along)]:
			Placeholder.wall(self, pos, Vector2(TILE, TILE), mountain)


# Inside the mountains, outside the camp, not inside a rock.
func random_open_point() -> Vector2:
	while true:
		var point := Vector2(randf_range(TILE * 1.5, MAP_SIZE.x - TILE * 1.5),
				randf_range(TILE * 1.5, MAP_SIZE.y - TILE * 1.5))
		if point.distance_to(MAP_SIZE / 2) < CAMP_CLEAR_RADIUS:
			continue
		if rock_rects.any(func(rect: Rect2): return rect.grow(30).has_point(point)):
			continue
		return point
	return Vector2.ZERO


# --- Start rolls ---

func run_start_rolls() -> void:
	ability = weighted_pick(ABILITIES)
	await spin("ABILITY ROLL", ABILITIES, ability)
	playtime = weighted_pick(PLAYTIMES)
	await spin("HOW LONG YOU GET TO PLAY", PLAYTIMES, playtime)
	hud.show_message("Ability: %s\nPlaytime: %s\n\nPress SPACE to start" % [ability.name, playtime.name])
	while not Input.is_action_just_pressed("confirm"):
		await get_tree().process_frame


# Slot-machine flicker that slows down, then lands on the result.
func spin(title: String, options: Array, result: Dictionary) -> void:
	for i in 25:
		hud.show_message("%s\n\n%s" % [title, options.pick_random().name])
		await get_tree().create_timer(0.03 + i * 0.008).timeout
	hud.show_message("%s\n\n%s\n%s" % [title, result.name, TIER_FLAVOR[result.tier]])
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
	sun_fuel -= FUEL_DRAIN * delta
	camp.sun_core.refresh(sun_fuel / FUEL_MAX, shards_deposited, SHARDS_TO_WIN)
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


func open_inventory(chest: Inventory = null) -> void:
	hud.open_inventory(chest)
	player.frozen = true


func close_inventory() -> void:
	hud.close_inventory()
	player.frozen = false


func interact() -> void:
	var target := nearest_interactable()
	if target is Chest:
		open_inventory(target.inventory)
	elif target is SunCore:
		feed_sun()


func nearest_interactable() -> Node2D:
	var best: Node2D = null
	var best_distance := INTERACT_RANGE
	for node in get_tree().get_nodes_in_group("interactable"):
		var distance := player.global_position.distance_to(node.global_position)
		if distance < best_distance:
			best = node
			best_distance = distance
	return best


# Only takes the fuel the sun needs; extra stays in the backpack.
func feed_sun() -> void:
	var needed := ceili((FUEL_MAX - sun_fuel) / FUEL_PER_ITEM)
	var fuel := mini(player.backpack.count("fuel"), needed)
	player.backpack.remove("fuel", fuel)
	sun_fuel = minf(sun_fuel + fuel * FUEL_PER_ITEM, FUEL_MAX)
	var shards := player.backpack.count("shard")
	player.backpack.remove("shard", shards)
	shards_deposited += shards
	if shards > 0:
		hud.toast("SHARDS IN THE SUN: %d/%d" % [shards_deposited, SHARDS_TO_WIN])
	if shards_deposited >= SHARDS_TO_WIN and sun_fuel >= FUEL_MAX:
		win()


func _on_shot_fired(at: Vector2) -> void:
	for listener in get_tree().get_nodes_in_group("listeners"):
		listener.hear(at, player.aggro_radius)


func _on_item_picked(kind: String) -> void:
	if kind != "shard":
		return
	shards_found += 1
	stage = mini(1 + int(shards_found / 2.0), 3)
	hud.toast("SHARD %d/%d  -  STAGE %d\nThey heard that." % [shards_found, SHARDS_TO_WIN, stage])
	# Deferred: can't add physics bodies inside a pickup's collision callback.
	spawn_listeners.call_deferred(SPAWN_PER_SHARD[stage - 1])
	if shards_found == SCATTERED_SHARDS:
		boss_timer = BOSS_DELAY


# --- Enemies ---

func spawn_listeners(count: int) -> void:
	for i in count:
		var listener := Listener.new()
		for stat in STAGE_STATS[stage - 1]:
			listener.set(stat, STAGE_STATS[stage - 1][stat])
		listener.target = player
		listener.position = far_from_player_point()
		add_child(listener)


func spawn_boss() -> void:
	var boss := Listener.new()
	for stat in BOSS_STATS:
		boss.set(stat, BOSS_STATS[stat])
	boss.target = player
	boss.position = far_from_player_point()
	boss.died.connect(func(dead: Listener): drop_shard.call_deferred(dead.global_position))
	add_child(boss)
	hud.toast("THE BOSS HAS COME.")


func drop_shard(pos: Vector2) -> void:
	Pickup.spawn(self, "shard", pos)
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
	return sun_fuel / FUEL_MAX * 100.0


func status_text() -> String:
	if not started:
		return ""
	var lines := PackedStringArray([
		"Shards in sun: %d/%d   carrying: %d" % [shards_deposited, SHARDS_TO_WIN, player.backpack.count("shard")],
		"Stage %d" % stage,
		"Ability: %s" % ability.name,
		"Time left: %s" % ("UNLIMITED" if playtime.seconds == 0 else "%d:%02d" % [int(time_left / 60), int(time_left) % 60]),
		"Tab backpack | E interact | F eat",
	])
	if boss_timer > 0.0:
		lines.append("THE BOSS ARRIVES IN %d" % ceili(boss_timer))
	return "\n".join(lines)


func prompt_text() -> String:
	if not started or game_over or hud.is_inventory_open():
		return ""
	var target := nearest_interactable()
	return target.prompt if target else ""
