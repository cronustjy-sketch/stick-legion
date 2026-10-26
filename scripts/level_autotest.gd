class_name LevelAutotest
extends Node
## Scripted level-flow check for step 6 (debug only):  godot --path . -- --level-test
## Runs over several scene reloads (stage kept in a static), prints LEVEL-TEST results.

static var stage: int = 0

var battle: Battle


func _ready() -> void:
	_run()


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step6_" + shot_name)


func _run() -> void:
	battle.hero.mouse_gate = false
	await _wait(0.5)
	match stage:
		0:
			print("LEVEL-TEST stage 0: level=", battle.level, " enemy multiplier=", battle.enemy_level, " pool=", LevelData.pool(battle.level))
			# Let the real enemy spawner work for a while (speed it up).
			battle.spawner.enabled = true
			Engine.time_scale = 4.0
			await get_tree().create_timer(40.0).timeout
			Engine.time_scale = 1.0
			var n: int = get_tree().get_nodes_in_group("units_team1").size()
			print("LEVEL-TEST enemy units after 40 game-seconds: ", n, " spawner gold left: ", int(battle.spawner.gold))
			await _shot("enemy_army")
			battle.spawner.enabled = false
			stage = 1
			battle.enemy_fortress.take_damage(99999.0)  # win
			await _wait(2.4)
			await _shot("victory")
			print("LEVEL-TEST ended=", battle.ended, " highest_unlocked=", GameState.highest_unlocked)
			var next: Button = battle.get_node("EndScreen").find_child("NextLevel", true, false) as Button
			next.pressed.emit()
		1:
			print("LEVEL-TEST stage 1: level=", battle.level, " multiplier=", snappedf(UnitData.level_multiplier(battle.level), 0.01), " pool=", LevelData.pool(battle.level))
			var u: Unit = battle.spawn_unit("swordsman", 1)
			print("LEVEL-TEST enemy swordsman hp at level 2: ", u.max_hp, " (base 60 x 1.11 = 66.6)")
			stage = 2
			battle.player_fortress.take_damage(99999.0)  # lose
			await _wait(2.4)
			await _shot("defeat")
			var retry: Button = battle.get_node("EndScreen").find_child("Retry", true, false) as Button
			retry.pressed.emit()
		2:
			print("LEVEL-TEST stage 2 (after Retry): level=", battle.level, " player fortress hp=", battle.player_fortress.hp, " ended=", battle.ended)
			get_tree().quit()
