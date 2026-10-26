class_name OrdersAutotest
extends Node
## Scripted check of army orders, health bars and tactical view for step 7 (debug only):
##   godot --path . -- --orders-test

var battle: Battle


func _ready() -> void:
	_run()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step7_" + shot_name)


func _stats(team: int) -> String:
	var zs: float = 0.0
	var hero_d: float = 0.0
	var c: int = 0
	for n: Node in get_tree().get_nodes_in_group("units_team%d" % team):
		zs += (n as Node3D).global_position.z
		hero_d += (n as Node3D).global_position.distance_to(battle.hero.global_position)
		c += 1
	return "n=%d avg_z=%.1f avg_dist_to_hero=%.1f" % [c, zs / maxf(c, 1), hero_d / maxf(c, 1)]


func _press(action: String, pressed: bool) -> void:
	var e: InputEventAction = InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)


func _run() -> void:
	Engine.time_scale = 3.0
	battle.hero.mouse_gate = false
	battle.army.gold = 2000.0
	for i: int in 12:
		battle.army.try_spawn("swordsman" if i % 3 != 0 else "spearman")
	await _wait(5.0)
	print("ORDERS-TEST charge (default, marching on the enemy fortress): ", _stats(0))
	battle.army.set_order(ArmyManager.Order.HOLD)
	await _wait(16.0)
	print("ORDERS-TEST hold (line at z~46-50): ", _stats(0))
	await _shot("hold")
	battle.army.set_order(ArmyManager.Order.FOLLOW)
	battle.hero.global_position = Vector3(10.0, 0.0, 20.0)
	await _wait(16.0)
	print("ORDERS-TEST follow (hero at 10,20): ", _stats(0))
	await _shot("follow")
	# Enemies appear: units on Follow engage them near the hero; their bars show health.
	for i: int in 6:
		var e: Unit = battle.spawn_unit("swordsman", 1)
		e.global_position = Vector3(12.0 + float(i) * 1.2, 0.0, 6.0)
	await _wait(6.0)
	await _shot("fight_bars")
	_press("tactical", true)
	await _wait(1.8)
	await _shot("tactical")
	_press("tactical", false)
	await _wait(1.0)
	await _wait(8.0)
	var hurt: Unit = null
	for n: Node in get_tree().get_nodes_in_group("units_team0"):
		hurt = n as Unit
		break
	hurt.hp = hurt.max_hp * 0.2
	var hp_before: float = hurt.hp
	battle.army.set_order(ArmyManager.Order.RETREAT)
	await _wait(25.0)
	print("ORDERS-TEST retreat (near gate z~60-64): ", _stats(0), "  hp of a hurt unit: ", int(hp_before), " -> ", int(hurt.hp), " / ", int(hurt.max_hp))
	await _shot("retreat")
	battle.army.set_order(ArmyManager.Order.CHARGE)
	await _wait(4.0)
	print("ORDERS-TEST charge again: ", _stats(0))
	Engine.time_scale = 1.0
	get_tree().quit()
