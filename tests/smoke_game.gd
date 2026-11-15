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
