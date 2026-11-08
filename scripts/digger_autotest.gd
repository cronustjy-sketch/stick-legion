class_name DiggerAutotest
extends Node
## Scripted check of the gold economy (debug only):
##   godot --path . res://scenes/battle.tscn --rendering-driver opengl3 -- --digger-test
## Rocks, no passive income, Diggers mining / delivering, orders, retreat, depletion, enemy Diggers, the HUD counter.

var battle: Battle


func _ready() -> void:
	_run()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), shot_name)


func _run() -> void:
	var army: ArmyManager = battle.army
	battle.hero.mouse_gate = false
	var rocks: Array[Node] = get_tree().get_nodes_in_group("gold_rocks")
	var near_player: int = 0
	var near_enemy: int = 0
	var rich: int = 0
	var total: float = 0.0
	for n: Node in rocks:
		var r: GoldRock = n as GoldRock
		total += r.capacity
		if r.rich:
			rich += 1
		elif r.global_position.z > 0.0:
			near_player += 1
		else:
			near_enemy += 1
	print("DIGGER-TEST rocks: ", near_player, " near the player (4-6), ", near_enemy, " near the enemy (4-6), ", rich, " rich in the middle (2); gold in the ground: ", int(total))
	print("DIGGER-TEST start gold: ", int(army.gold), " (expect 1000)")
	await _wait(5.0)
	print("DIGGER-TEST gold after 5 s with no Diggers: ", int(army.gold), " (expect 1000: no passive income)")
	var cost: int = army.cost_of("digger")
	var d0: float = army.gold
	var ok: bool = army.try_spawn("digger")
	print("DIGGER-TEST bought a Digger: ", ok, " cost ", int(d0 - army.gold), " (expect 150)  pop ", army.pop_used, " (expect 1)")
	army.try_spawn("digger")
	army.try_spawn("digger")
	var diggers: Array[Digger] = []
	for n: Node in get_tree().get_nodes_in_group("diggers_team0"):
		diggers.append(n as Digger)
	print("DIGGER-TEST Diggers: ", diggers.size(), "  HUD counter: ", battle.hud._digger_label.text)
	await _shot("digger_hud")
	# Closeup of a Digger at work.
	var before: float = army.gold
	var seen_mining: bool = false
	var shot: bool = false
	var t: float = 0.0
	Engine.time_scale = 1.0
	while t < 40.0:
		await _wait(0.25)
		t += 0.25
		if not shot and diggers[0].job == Digger.Job.MINING:
			seen_mining = true
			var rock: GoldRock = diggers[0].rock
			var cam: Camera3D = Camera3D.new()
			add_child(cam)
			cam.current = true
			var dp: Vector3 = diggers[0].global_position
			cam.global_position = dp + Vector3(2.6, 1.9, -3.4)
			cam.look_at(dp.lerp(rock.global_position, 0.4) + Vector3(0.0, 0.9, 0.0))
			await _wait(1.2)
			await _shot("digger_mining")
			print("DIGGER-TEST mining: rock has ", int(rock.remaining), " / ", int(rock.capacity), " left, job=", diggers[0].job)
			shot = true
			if OS.get_cmdline_user_args().has("--digger-quick"):
				get_tree().quit()
				return
			cam.queue_free()
			battle.hero_camera.camera.current = true
	print("DIGGER-TEST a Digger was seen mining: ", seen_mining, "  gold gained in 40 s by 3 Diggers: ", int(army.gold - before), "  delivered per Digger: ", int(diggers[0].delivered), " ", int(diggers[1].delivered), " ", int(diggers[2].delivered))
	# Orders: Charge keeps them mining.
	army.set_order(ArmyManager.Order.CHARGE)
	await _wait(1.0)
	var working: int = 0
	for d: Digger in diggers:
		if d.job == Digger.Job.TO_ROCK or d.job == Digger.Job.MINING or d.job == Digger.Job.TO_HOME:
			working += 1
	print("DIGGER-TEST under Charge ", working, " of 3 are still working (expect 3)")
	army.set_order(ArmyManager.Order.HOLD)
	await _wait(1.0)
	army.set_order(ArmyManager.Order.FOLLOW)
	await _wait(1.0)
	working = 0
	for d: Digger in diggers:
		if d.job == Digger.Job.TO_ROCK or d.job == Digger.Job.MINING or d.job == Digger.Job.TO_HOME:
			working += 1
	print("DIGGER-TEST under Hold / Follow ", working, " of 3 are still working (expect 3)")
	# Retreat sends them home.
	army.set_order(ArmyManager.Order.RETREAT)
	await _wait(14.0)
	var home: int = 0
	for d: Digger in diggers:
		if d.job == Digger.Job.WAIT_HOME and absf(d.global_position.z) > BattlefieldData.FORTRESS_Z - 10.0:
			home += 1
	print("DIGGER-TEST after Retreat ", home, " of 3 are waiting at the fortress (expect 3)")
	await _shot("digger_retreat")
	army.set_order(ArmyManager.Order.CHARGE)
	await _wait(2.0)
	print("DIGGER-TEST after Charge again, job of the first Digger: ", diggers[0].job, " (expect FIND/TO_ROCK = 0 or 1)")
	# Digger limit.
	army.gold = 5000.0
	var bought: int = 0
	for i: int in 12:
		if army.try_spawn("digger"):
			bought += 1
	print("DIGGER-TEST bought until the limit: ", bought + 3, " (expect ", EconomyData.DIGGER_LIMIT, ")")
	# A rock runs dry and disappears.
	var rock2: GoldRock = GoldRock.nearest_free(get_tree(), Vector3(0.0, 0.0, 30.0))
	rock2.remaining = 70.0
	var got1: float = rock2.mine(50.0)
	var got2: float = rock2.mine(50.0)
	await _wait(0.8)
	print("DIGGER-TEST rock with 70 gold: took ", got1, " then ", got2, " (expect 50 then 20); rock still exists: ", is_instance_valid(rock2), " (expect false)")
	# Enemy side: Diggers are bought by the enemy spawner and can be killed.
	battle.spawner.enabled = true
	battle.spawner.gold = 1000.0
	await _wait(12.0)
	var enemy_diggers: Array[Node] = get_tree().get_nodes_in_group("diggers_team1")
	print("DIGGER-TEST enemy Diggers after 12 s: ", enemy_diggers.size(), " (target ", battle.spawner.settings.diggers, ")")
	if enemy_diggers.size() > 0:
		var victim: Digger = enemy_diggers[0] as Digger
		var g1: float = army.gold
		victim.take_damage(99999.0, victim.global_position + Vector3(0.0, 0.0, 2.0))
		await _wait(0.2)
		print("DIGGER-TEST killed an enemy Digger: reward ", int(army.gold - g1), " gold; enemy Diggers left ", get_tree().get_nodes_in_group("diggers_team1").size())
	await _wait(14.0)
	print("DIGGER-TEST enemy Diggers after the spawner re-buys: ", get_tree().get_nodes_in_group("diggers_team1").size(), "  enemy gold: ", int(battle.spawner.gold))
	battle.hero.global_position = Vector3(0.0, 0.0, 6.0)
	battle.hero_camera.touch_tactical = true
	await _wait(1.8)
	await _shot("digger_tactical")
	print("DIGGER-TEST draw calls: ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	get_tree().quit()
