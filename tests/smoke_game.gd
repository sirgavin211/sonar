extends SceneTree
# Run: Godot --headless --path . --script tests/smoke_game.gd
# Drives main.gd through shards, boss, feeding the sun, and the win.


func _initialize() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.ability = main.ABILITIES[0]
	main.playtime = main.PLAYTIMES[4]
	main.start()

	# Sonar wave: open-air Listener gets hit, one behind a wall doesn't.
	# Just below the facility: outside its walls, inside the rock-free zone.
	var origin: Vector2 = main.camp.position + Vector2(0, 250)
	main.player.position = origin
	var open_target = spawn_listener(main, origin + Vector2(200, 0))
	var hidden_target = spawn_listener(main, origin + Vector2(-200, 0))
	Placeholder.wall(main, origin + Vector2(-100, 0), Vector2(20, 120), Color.GRAY)
	await physics_frame
	var waves := []
	for aim in [Vector2.RIGHT, Vector2.LEFT]:
		var wave := SonarWave.new()
		wave.setup(main.player, aim)
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

	for i in main.SCATTERED_SHARDS:
		assert(main.player.pick_up("shard"))
	await process_frame
	assert(main.stage == 3)
	assert(main.boss_timer > 0.0)
	var spawned: int = get_nodes_in_group("listeners").size()
	assert(spawned == main.START_LISTENERS + 3 + 6 + 6 + 20 + 20, "spawned %d" % spawned)

	var shards_on_ground := func(): return main.get_children().filter(func(n): return n is Pickup and n.kind == "shard").size()
	var before: int = shards_on_ground.call()
	main.boss_timer = 0.01
	await create_timer(0.1).timeout
	var boss = get_nodes_in_group("listeners").filter(func(l): return l.max_health == 40)[0]
	boss.take_hit(100)
	await process_frame
	await process_frame
	assert(shards_on_ground.call() == before + 1, "boss dropped the final shard")

	assert(main.player.pick_up("shard"))
	assert(main.player.backpack.add("fuel", 10))
	main.feed_sun()
	assert(main.shards_deposited == 6)
	assert(main.game_over, "won")
	print("smoke test passed")
	quit()


func spawn_listener(main, pos: Vector2) -> Listener:
	var listener := Listener.new()
	listener.target = main.player
	listener.max_health = 99
	listener.speed = 0.0
	listener.position = pos
	main.add_child(listener)
	return listener
