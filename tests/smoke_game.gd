extends SceneTree
# Run: Godot --headless --path . --script tests/smoke_game.gd
# Drives main.gd through shards, boss, feeding the sun, and the win.


func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.ability = main.abilities[0]
	main.start()

	# Sonar wave: open-air Listener gets hit, one behind a wall doesn't.
	# Just below the facility: outside its walls, inside the rock-free zone.
	var origin: Vector2 = main.camp.position + Vector2(0, 250)
	main.player.position = origin
	var open_target = spawn_listener(main, origin + Vector2(200, 0))
	var hidden_target = spawn_listener(main, origin + Vector2(-200, 0))
	main.spawn_wall(origin + Vector2(-100, 0), Vector2(20, 120), Color.GRAY)
	await physics_frame
	var waves := []
	for aim in [Vector2.RIGHT, Vector2.LEFT]:
		var wave: SonarWave = load("res://scenes/effects/sonar_wave.tscn").instantiate()
		wave.setup(main.player, main.player.global_position, aim)
		main.add_child(wave)
		waves.append(wave)
	await create_timer(0.45).timeout
	assert(main.get_children().any(func(n): return n is EchoReturn), "echo bounces back")
	assert(waves[1].rays.any(func(ray): return ray.bounces > 0), "wave reflects off the wall")
	await create_timer(0.55).timeout
	assert(open_target.health < open_target.max_health, "wave hits Listener in the open")
	assert(hidden_target.health == hidden_target.max_health, "walls block the wave")
	open_target.queue_free()
	hidden_target.queue_free()

	# Hotbar: sonar starts in slot 1; food in hand takes eat_time, then heals and is used up.
	assert(main.player.held_kind() == "sonar", "sonar starts selected in slot 1")
	assert(main.player.pick_up("food"))
	main.player.select(1)
	assert(main.player.held_kind() == "food")
	main.player.take_damage(50)
	var hurt: float = main.player.health
	main.player.start_eating()
	await create_timer(main.player.eat_time / 2).timeout
	assert(main.player.health == hurt, "not healed mid-bite")
	await create_timer(main.player.eat_time / 2 + 0.2).timeout
	assert(main.player.health > hurt and main.player.backpack.count("food") == 0, "ate the food")
	main.player.select(0)

	var shards_on_map := func(): return main.get_children().filter(func(n): return n is Pickup and n.kind == "shard" and not n.is_queued_for_deletion()).size()
	assert(shards_on_map.call() == main.scattered_shards, "all shards scattered")
	for i in main.boss_stage() - 1:  # the shards you find before the boss fight
		assert(main.player.pick_up("shard"))
	await process_frame
	assert(main.stage == 3, "one stage per shard, Stage 3 is the boss fight")
	assert(main.stage_name() == "Stage 3: Boss Fight")
	assert(shards_on_map.call() == 0, "unfound shards vanish when the boss fight starts")
	assert(main.boss_timer > 0.0 and main.boss_timer <= main.boss_delay, "boss countdown starts")
	var spawned: int = get_nodes_in_group("listeners").size()
	var expected: int = main.start_listeners
	for n in main.spawn_per_stage:
		expected += n
	assert(spawned == expected, "spawned %d, expected %d" % [spawned, expected])

	main.boss_timer = 0.01
	await create_timer(0.1).timeout
	var boss = get_nodes_in_group("listeners").filter(func(l): return l.max_health == 40)[0]

	# Boss red waves: hurt the player, and cancel out with player waves.
	get_nodes_in_group("listeners").filter(func(l): return l != boss).map(func(l): l.free())
	boss.speed = 0.0
	boss.position = main.player.position + Vector2(300, 0)
	var hp: float = main.player.health
	var red = load("res://scenes/effects/sonar_wave.tscn").instantiate()
	red.setup_hostile(main.player, boss.position, Vector2.LEFT, 650.0, 20.0, 380.0)
	main.add_child(red)
	await create_timer(1.0).timeout
	assert(main.player.health <= hp - 20.0, "red wave hurts the player")
	var red2 = load("res://scenes/effects/sonar_wave.tscn").instantiate()
	red2.setup_hostile(main.player, boss.position, Vector2.LEFT, 650.0, 20.0, 380.0)
	main.add_child(red2)
	var blue = load("res://scenes/effects/sonar_wave.tscn").instantiate()
	blue.setup(main.player, main.player.global_position, Vector2.RIGHT)
	main.add_child(blue)
	await create_timer(0.5).timeout
	assert(not is_instance_valid(red2) and not is_instance_valid(blue), "player and boss waves cancel out")
	main.player.health = main.player.max_health
	# Score tracking: a Listener kill counts, the boss doesn't.
	var kills_before: int = main.kills
	main.spawn_listeners(1)
	var victim = get_nodes_in_group("listeners").filter(func(l): return l != boss)[-1]
	victim.take_hit(999)
	await process_frame
	assert(main.kills == kills_before + 1, "Listener kill counted")

	var shards_before: int = shards_on_map.call()
	boss.take_hit(100)
	await process_frame
	await process_frame
	assert(not is_instance_valid(boss), "boss dies")
	assert(shards_on_map.call() == shards_before + 1, "boss drops the final shard")
	main.quest_step = main.quests.size()  # past the intro steps, so the bar shows the stage
	assert(main.goal_text().contains("Bring all"), "quest bar sends you to the Sun")
	assert(main.player.pick_up("shard"))

	# Hopper: holding fuel at the hopper crumbles one piece per crumble_time into the sun.
	assert(main.player.backpack.add("fuel", 2))
	main.player.select(main.player.backpack.slots.find_custom(func(s): return s != null and s.kind == "fuel"))
	main.player.position = main.camp.position + main.camp.hopper.position + Vector2(0, 40)
	main.sun_fuel = 50.0
	main.interact()
	assert(main.camp.hopper.feeding, "hopper started")
	await create_timer(main.camp.hopper.crumble_time + 0.15).timeout
	assert(main.player.backpack.count("fuel") == 1, "one piece crumbled")
	assert(main.sun_fuel > 59.0, "its fuel reached the sun")

	main.sun_fuel = main.fuel_max
	main.deposit_shards()
	assert(main.shards_deposited == main.shards_to_win)
	assert(main.game_over, "won")
	assert(main.kills == kills_before + 1, "boss isn't counted as a kill")
	assert(main.boss_time > 0.0, "boss time measured")
	var won_score: int = main.score(true)
	assert(won_score > 0 and won_score % 10 == 0, "score rounds up to 10s")
	assert(won_score > main.score(false), "a win always beats a loss")
	assert(main.hud.message.text.contains("SCORE  %d" % won_score), "score on the win screen")
	print("smoke test passed")
	quit()


func spawn_listener(main, pos: Vector2) -> Listener:
	var listener: Listener = load("res://scenes/characters/listener.tscn").instantiate()
	listener.target = main.player
	listener.max_health = 99
	listener.speed = 0.0
	listener.position = pos
	main.add_child(listener)
	return listener
