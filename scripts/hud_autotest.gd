class_name HudAutotest
extends Node
## Scripted HUD check for step 5 (debug only):  godot --path . -- --hud-test
## Buys units with the hotkey and the API, hits the gold / population limits, watches kills pay gold.

var battle: Battle


func _ready() -> void:
	_run()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step5_" + shot_name)


func _key(code: Key) -> void:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)


func _run() -> void:
	var army: ArmyManager = battle.army
	battle.hero.mouse_gate = false
	await _wait(1.5)
	await _shot("start")
	print("HUD-TEST gold at start: ", int(army.gold), " pop: ", army.pop_used, "/", army.pop_cap)
	var g0: float = army.gold
	_key(KEY_Z)  # swordsman via the real hotkey path
	await _wait(0.3)
	print("HUD-TEST after Z: swordsmen=", get_tree().get_nodes_in_group("units_team0").size(), " gold spent~", snappedf(g0 - army.gold, 1.0), " pop=", army.pop_used)
	army.gold = 500.0
	for k: String in ["swordsman", "archer", "spearman", "shield_knight", "mage"]:
		army.try_spawn(k)
	await _wait(1.0)
	await _shot("bought")
	print("HUD-TEST pop after buying 5 more: ", army.pop_used, "/", army.pop_cap)
	army.gold = 5.0
	var ok: bool = army.try_spawn("mage")
	print("HUD-TEST buy with 5 gold succeeded (expect false): ", ok)
	await _wait(0.2)
	await _shot("toast_gold")
	army.gold = 5000.0
	var bought: int = 0
	for i: int in 60:
		if army.try_spawn("swordsman"):
			bought += 1
	print("HUD-TEST bought until cap: ", bought, " pop=", army.pop_used, "/", army.pop_cap, " (expect cap 40)")
	await _wait(0.2)
	await _shot("pop_full")
	Engine.time_scale = 3.0
	army.gold = 0.0
	await get_tree().create_timer(60.0).timeout
	await _shot("fight")
	print("HUD-TEST gold after 60 game-seconds (income 600 + kill rewards): ", int(army.gold))
	Engine.time_scale = 1.0
	get_tree().quit()
