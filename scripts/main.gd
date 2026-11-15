extends Node2D
# Game manager: start rolls, map, stages, spawns, boss timer, win/lose.
# Every balance number below shows up in the Inspector when you select Main in main.tscn.

const PlayerScene := preload("res://scenes/characters/player.tscn")
const CampScene := preload("res://scenes/world/camp.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")
const WallScene := preload("res://scenes/world/wall.tscn")
const PickupScene := preload("res://scenes/world/pickup.tscn")
const ListenerScene := preload("res://scenes/characters/listener.tscn")
const BossScene := preload("res://scenes/characters/boss.tscn")

@export_group("Map")
@export var map_size := Vector2(4000, 4000)
@export var tile := 100.0  # mountain block size
@export var rock_count := 50  # pixel stone blocks
@export var rock_min_size := 40
@export var rock_max_size := 120
@export var tree_count := 90
@export var stone_count := 60
@export var bush_count := 180
@export var pebble_count := 140
@export var prop_gap := 12.0  # minimum space between any two props
@export var food_count := 38  # 1.5x the old 25
@export var fuel_count := 40
@export var scattered_shards := 5  # spread over the map; only the first two you find count
@export var shard_spacing := 900.0  # shards are at least this far apart
@export var camp_clear_radius := 500.0
@export var ground_tiles: Array[Texture2D] = [
	preload("res://assets/textures/terrain/01-bare-rock.png"),
	preload("res://assets/textures/terrain/02-sparse-moss.png"),
	preload("res://assets/textures/terrain/03-patchy-moss.png"),
	preload("res://assets/textures/terrain/04-dense-moss.png"),
]
@export var ground_tile_size := 32.0  # 16px art drawn 2x = 1 art pixel per screen pixel
@export var moss_patch_size := 14.0  # tiles across one moss patch
@export var moss_levels: Array[float] = [-0.12, 0.0, 0.12]  # Perlin cutoffs: stone | sparse | patchy | dense
@export var camp_stone_radius := 450.0  # the camp always sits in stone this far out
@export_subgroup("Nature art")
# Solid (block you, bounce sonar): trees and stones. Walk-over clutter: bushes and pebbles.
@export var tree_textures: Array[Texture2D] = [
	preload("res://assets/textures/nature/32x32/tree-1.png"),
	preload("res://assets/textures/nature/32x32/tree-2.png"),
	preload("res://assets/textures/nature/32x32/tree-3.png"),
	preload("res://assets/textures/nature/32x32/tree-4.png"),
	preload("res://assets/textures/nature/48x48/tree-1-48x48.png"),
	preload("res://assets/textures/nature/48x48/tree-2-48x48.png"),
]
@export var stone_textures: Array[Texture2D] = [
	preload("res://assets/textures/nature/32x32/stone-2.png"),
	preload("res://assets/textures/nature/32x32/stone-3.png"),
	preload("res://assets/textures/nature/32x32/stone-4.png"),
]
@export var bush_textures: Array[Texture2D] = [
	preload("res://assets/textures/nature/16x16/bush-empty-16.png"),
	preload("res://assets/textures/nature/16x16/bush-berries-16.png"),
]
@export var pebble_textures: Array[Texture2D] = [
	preload("res://assets/textures/nature/16x16/rock-small-16.png"),
]
@export var nature_scale := 2.0  # art pixels -> world; 2x everywhere keeps one pixel grid
@export var stone_surface: Texture2D = preload("res://assets/textures/terrain/01-bare-rock.png")  # tiled over stone blocks + mountains
@export var rock_tint := Color(1.7, 1.6, 1.5)  # lighter than the stone ground so blocks read as walls
@export var mountain_tint := Color(1.3, 1.25, 1.2)
@export var rock_color := Color(0.4, 0.38, 0.35)  # minimap color
@export var tree_color := Color(0.2, 0.4, 0.3)  # minimap color
@export var stone_color := Color(0.45, 0.45, 0.5)
@export_subgroup("")
@export var mountain_color := Color(0.35, 0.3, 0.3)
@export var darkness_color := Color(0.03, 0.03, 0.05)

@export_group("Sun")
@export var shards_to_win := 3  # the two you find, plus the one the boss drops
@export var fuel_max := 100.0
@export var start_fuel := 60.0
@export var fuel_per_item := 10.0
@export var fuel_drain := 0.4  # per second
@export var interact_range := 80.0
@export var ambience_db := -6.0  # loudness of the inside/outside ambience
@export var ambience_fade_distance := 250.0  # factory hum fades out over this far past the camp walls
@export var ambience_smoothing := 0.4  # seconds; smooths jumps (like respawning in camp)

@export_group("Enemies")
@export var start_listeners := 8
@export var boss_delay := 10.0  # seconds after Stage 3: Boss Fight starts
# Stage 1 at the start, +1 per shard found; Stage 3 is the boss fight.
# Both tables are indexed by stage - 1.
@export var spawn_per_stage: Array[int] = [0, 6, 12]  # Listeners added on reaching each stage
@export var stage_stats: Array[Dictionary] = [
	{"speed": 110.0, "max_health": 2, "contact_damage": 12.0},
	{"speed": 150.0, "max_health": 3, "contact_damage": 18.0},
	{"speed": 215.0, "max_health": 5, "contact_damage": 35.0},
]

@export_group("Quests")
# Shown one at a time in the bar at the top. "done" is what finishes a step:
# sonar = fire it, fuel/food = pick one up, hopper = crumble fuel into it,
# time = info only, moves on after tip_seconds.
# After the last step the bar shows the stage instead.
@export var quests: Array[Dictionary] = [
	{"text": "Use Left Click to shoot sonic waves to search for objects", "done": "sonar"},
	{"text": "Find fuel to feed the Sun.", "done": "fuel"},
	{"text": "Feed the fuel into the hopper (hold it, press E)", "done": "hopper"},
	{"text": "If the Sun Fuel bar runs out, your only heat source is gone and you will freeze to death", "done": "time"},
	{"text": "Find food to help you heal.", "done": "food"},
	{"text": "Beware the Listeners who hear the waves made by your sonar", "done": "time"},
	{"text": "Find the shards that raise the sun back to the atmosphere", "done": "time"},
]
@export var tip_seconds := 6.0

@export_group("Start rolls")
# When each click happens in assets/audio/sfx/SpinClick.mp3 (seconds). Every click flips to a
# new name; the last click lands on the result. Found with ffmpeg silencedetect.
@export var spin_clicks: Array[float] = [
	0.047, 0.128, 0.207, 0.297, 0.389, 0.474, 0.561, 0.642, 0.72, 0.81, 0.904,
	0.988, 1.074, 1.154, 1.232, 1.323, 1.439, 1.594, 1.766, 1.932, 2.123, 2.329,
]
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
@export var tier_flavor := {"none": "meh.", "bad": "oof.", "good": "LET'S GO", "jackpot": "!!! JACKPOT !!!"}

var player: Player
var camp: Camp
var hud: Hud
var darkness: CanvasModulate
var rock_rects: Array[Rect2] = []  # footprint of every placed prop (trees, stones, bushes, pebbles)

var started := false
var game_over := false
var ability: Dictionary
var sun_fuel := 0.0
var shards_found := 0
var shards_deposited := 0
var stage := 1  # 1 + shards found; 3 = boss fight
var quest_step := 0  # index into quests; past the end = showing the stage
var quest_done := {}  # "sonar", "fuel", "food", "shard" once you've done them
var tip_time := 0.0  # how long the current info-only step has been up
var boss_timer := -1.0  # < 0 means not counting
var boss_beaten := false
var boss: Listener  # the live boss, for the HUD's health bar
var inside_mix := 1.0  # 1 = full factory ambience, 0 = full outside ambience; you start in camp


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
	# Frozen until the run starts, so nothing can wander in and kill you on the SPACE screen.
	get_tree().call_group("listeners", "set_physics_process", false)
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
	scatter_rocks()
	scatter_solid(tree_textures, tree_count, 0.45, tree_color, 1)
	scatter_solid(stone_textures, stone_count, 0.75, stone_color, 0)
	scatter_clutter(bush_textures, bush_count)
	scatter_clutter(pebble_textures, pebble_count)
	for i in food_count:
		spawn_pickup("food", random_open_point())
	for i in fuel_count:
		spawn_pickup("fuel", random_open_point())
	scatter_shards()


# Ring of blocks on every edge keeps the player in.
func build_mountains() -> void:
	var tiles := int(map_size.x / tile)
	for i in tiles:
		var along := (i + 0.5) * tile
		for pos in [Vector2(along, tile / 2), Vector2(along, map_size.y - tile / 2),
				Vector2(tile / 2, along), Vector2(map_size.x - tile / 2, along)]:
			spawn_stone(pos, Vector2(tile, tile), mountain_color, mountain_tint)


func spawn_wall(pos: Vector2, size: Vector2, color: Color, texture: Texture2D = null) -> Wall:
	var wall: Wall = WallScene.instantiate()
	wall.position = pos
	wall.size = size
	wall.color = color
	wall.texture = texture
	wall.texture_scale = nature_scale
	add_child(wall)
	return wall


# Stone blocks of random size; even sizes keep their edges on the pixel grid.
func scatter_rocks() -> void:
	for i in rock_count:
		var size := Vector2(randi_range(rock_min_size / 2, rock_max_size / 2), randi_range(rock_min_size / 2, rock_max_size / 2)) * 2
		var spot = claim_free_spot(size)
		if spot != null:
			spawn_stone(spot, size, rock_color, rock_tint)


func spawn_stone(pos: Vector2, size: Vector2, color: Color, tint: Color) -> Wall:
	var wall := spawn_wall(pos, size, color)
	wall.surface = stone_surface
	wall.surface_tint = tint
	return wall


# collider_ratio: how much of the art blocks movement. layer 1 draws over the player.
func scatter_solid(textures: Array[Texture2D], count: int, collider_ratio: float, color: Color, layer: int) -> void:
	for i in count:
		var texture: Texture2D = textures.pick_random()
		var art := texture.get_size() * nature_scale
		var spot = claim_free_spot(art)
		if spot == null:
			continue
		var wall := spawn_wall(spot, art * collider_ratio, color, texture)
		wall.z_index = layer
		wall.get_node("Sprite").flip_h = randf() < 0.5


# Walk-over ground clutter: just art, no collision or sonar echo.
func scatter_clutter(textures: Array[Texture2D], count: int) -> void:
	for i in count:
		var texture: Texture2D = textures.pick_random()
		var spot = claim_free_spot(texture.get_size() * nature_scale)
		if spot == null:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2.ONE * nature_scale
		sprite.flip_h = randf() < 0.5
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = -1
		sprite.position = spot
		add_child(sprite)


# A spot where a prop this size (plus prop_gap) overlaps no other prop; reserves it.
# Returns null if the map is too crowded to fit it, so that prop is just skipped.
func claim_free_spot(size: Vector2):
	for attempt in 40:
		var point := random_open_point()
		var footprint := Rect2(point - size / 2, size)
		if rock_rects.any(func(rect: Rect2): return rect.intersects(footprint.grow(prop_gap))):
			continue
		rock_rects.append(footprint)
		return point
	return null


# Shards keep shard_spacing apart so they're spread across the map, not clumped.
func scatter_shards() -> void:
	var placed: Array[Vector2] = []
	for i in scattered_shards:
		var point := random_open_point()
		for attempt in 60:
			if placed.all(func(other: Vector2): return other.distance_to(point) >= shard_spacing):
				break
			point = random_open_point()
		placed.append(point)
		spawn_pickup("shard", point)


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
	hud.show_message("Ability: %s\n\nPress SPACE to start" % ability.name)
	while not Input.is_action_just_pressed("confirm"):
		await get_tree().process_frame


# Slot machine synced to the wheel-click sound: a new name on every click, fast at
# first then slowing with the wheel, landing on the result at the last click.
func spin(title: String, options: Array, result: Dictionary) -> void:
	$SpinClick.play()
	var started_at := Time.get_ticks_msec()
	var shown := ""
	for i in spin_clicks.size():
		# Wait until this click's moment in the sound (measured from the start, so no drift).
		var wait := spin_clicks[i] - (Time.get_ticks_msec() - started_at) / 1000.0
		if wait > 0.0:
			await get_tree().create_timer(wait).timeout
		var last := spin_clicks.size() - 1
		# The name before the last click can't be the result, or the final click wouldn't visibly land.
		var avoid: Array = [shown, result.name] if i == last - 1 else [shown]
		var name: String = result.name if i == last else different_name(options, avoid)
		hud.show_message("%s\n\n%s" % [title, name])
		shown = name
	hud.show_message("%s\n\n%s\n%s" % [title, result.name, tier_flavor[result.tier]])
	await get_tree().create_timer(1.5).timeout


# Any option except the given names, so every click visibly changes.
func different_name(options: Array, avoid: Array) -> String:
	var others := options.filter(func(option): return not option.name in avoid)
	return others.pick_random().name


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
	hud.hide_message()
	player.frozen = false
	get_tree().call_group("listeners", "set_physics_process", true)
	started = true


# --- Loop ---

func _process(delta: float) -> void:
	update_ambience(delta)
	if not started or game_over:
		return
	sun_fuel -= fuel_drain * delta
	advance_quests(delta)
	if camp.hopper.feeding and not can_use_hopper():
		camp.hopper.stop()
	camp.sun_core.refresh(sun_fuel / fuel_max, shards_deposited, shards_to_win)
	if sun_fuel <= 0.0:
		lose("The sun went cold.")
	if boss_timer > 0.0:
		boss_timer -= delta
		if boss_timer <= 0.0:
			spawn_boss()


# Both loops always run. The factory hum fades out as you walk away from the camp
# and back in as you return; the outdoor ambience does the opposite.
func update_ambience(delta: float) -> void:
	var away := camp.distance_from_floor(player.global_position)
	var target := 1.0 - clampf(away / ambience_fade_distance, 0.0, 1.0)
	inside_mix = move_toward(inside_mix, target, delta / ambience_smoothing)
	# Equal-power crossfade (sqrt), so it doesn't dip in loudness halfway.
	$InsideAmbience.volume_db = ambience_db + linear_to_db(sqrt(inside_mix))
	$OutsideAmbience.volume_db = ambience_db + linear_to_db(sqrt(1.0 - inside_mix))


func _unhandled_input(event: InputEvent) -> void:
	# Only once the run has begun: mid-roll the old scene's spin is still waiting and errors when freed.
	if event.is_action_pressed("restart") and started:
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
	return player.held_kind() == "fuel" and nearest_interactable() is Hopper and not sun_is_full()


# Full = can't fit another whole piece of fuel. Not exactly fuel_max: the sun drains every
# frame, so it would only ever be "full" for one frame (you couldn't win by filling it first).
func sun_is_full() -> bool:
	return sun_fuel > fuel_max - fuel_per_item


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
	quest_done["hopper"] = true
	if player.backpack.remove("fuel"):
		sun_fuel = minf(sun_fuel + fuel_per_item, fuel_max)
		check_win()


func deposit_shards() -> void:
	var shards := player.backpack.count("shard")
	player.backpack.remove("shard", shards)
	shards_deposited += shards
	camp.sun_core.get_node("ShardInSound").play()
	hud.toast("SHARDS IN THE SUN: %d/%d" % [shards_deposited, shards_to_win])
	check_win()


func check_win() -> void:
	if shards_deposited >= shards_to_win and sun_is_full():
		win()


# Moves past every finished step. Out of order is fine: find food first and that
# step is already done when it comes up.
func advance_quests(delta: float) -> void:
	while quest_step < quests.size():
		var needs: String = quests[quest_step].done
		if needs == "time":
			tip_time += delta
			if tip_time < tip_seconds:
				return
			tip_time = 0.0
			delta = 0.0  # the next info step starts its own clock fresh
		elif not quest_done.has(needs):
			return
		quest_step += 1


func _on_shot_fired(at: Vector2) -> void:
	quest_done["sonar"] = true
	for listener in get_tree().get_nodes_in_group("listeners"):
		listener.hear(at, player.aggro_radius)


func _on_item_picked(kind: String) -> void:
	quest_done[kind] = true
	if kind != "shard":
		return
	if stage >= boss_stage():
		return
	shards_found += 1
	stage += 1
	$StageUpSound.play()
	hud.toast("SHARD %d/%d  -  %s\nThey heard that." % [shards_found, shards_to_win, stage_name()])
	# Deferred: can't add physics bodies inside a pickup's collision callback.
	spawn_listeners.call_deferred(spawn_per_stage[stage - 1])
	if stage == boss_stage():
		start_boss_fight()


func boss_stage() -> int:
	return stage_stats.size()


func stage_name() -> String:
	return "Stage %d: Boss Fight" % stage if stage == boss_stage() else "Stage %d" % stage


# The shards nobody found vanish, and the boss comes after boss_delay.
func start_boss_fight() -> void:
	for node in get_children():
		if node is Pickup and node.kind == "shard":
			node.queue_free()
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
	boss = BossScene.instantiate()
	boss.target = player
	boss.position = far_from_player_point()
	boss.died.connect(func(dead: Listener): drop_final_shard.call_deferred(dead.global_position))
	add_child(boss)
	hud.toast("THE BOSS HAS COME.")


# Deferred from the boss's death: can't add the pickup's physics body mid-callback.
func drop_final_shard(pos: Vector2) -> void:
	boss_beaten = true
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


# The quest bar at the top: the current intro step, then the stage.
func goal_text() -> String:
	if not started:
		return ""
	if quest_step < quests.size():
		return quests[quest_step].text
	var text := stage_name()
	if boss_timer > 0.0:
		text += "\nThe boss arrives in %d" % ceili(boss_timer)
	elif boss_beaten and not game_over:
		text += "\nBring all %d shards to the Sun." % shards_to_win
	return text


func run_text() -> String:
	if not started:
		return ""
	return "Ability: %s\nShards in sun: %d/%d" % [ability.name, shards_deposited, shards_to_win]


func prompt_text() -> String:
	if not started or game_over or hud.is_inventory_open():
		return ""
	var target := nearest_interactable()
	if target is Hopper:
		if camp.hopper.feeding:
			return "Crumbling fuel..."
		if player.held_kind() != "fuel":
			return "Hold fuel (1-5) to use the hopper"
		if sun_is_full():
			return "The sun is full"
	if target is SunCore and player.held_kind() != "shard":
		return "Hold a shard (1-5) to put it in the sun"
	return target.prompt if target else ""
