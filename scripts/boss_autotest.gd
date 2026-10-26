class_name BossAutotest
extends Node
## Scripted boss fight check for step 10 (debug only):  godot --path . -- --boss-test   (forces level 5)

var battle: Battle


func _ready() -> void:
	_run()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step10_" + shot_name)


func _run() -> void:
	var hero: Hero = battle.hero
	var boss: Boss = battle.boss
	hero.mouse_gate = false
	hero.max_hp = 99999.0
	hero.hp = 99999.0
	hero.global_position = Vector3(0.0, 0.0, -14.0)
	battle.hero_camera._focus = hero.global_position
	battle.hero_camera.distance = 9.0
	battle.hero_camera.pitch = 0.5
	print("BOSS-TEST level=", battle.level, " boss=", boss.boss_name, " hp=", int(boss.max_hp), " fortress shielded=", battle.enemy_fortress.shielded,
		" fortress hp=", int(battle.enemy_fortress.max_hp))
	var before: float = battle.enemy_fortress.hp
	battle.enemy_fortress.take_damage(500.0)
	print("BOSS-TEST hitting the shielded fortress: hp ", int(before), " -> ", int(battle.enemy_fortress.hp), " (expect unchanged)")
	Engine.time_scale = 2.0
	var casts: int = 0
	var was_busy: bool = false
	var shots: int = 0
	var t: float = 0.0
	while casts < 4 and t < 90.0:
		await get_tree().process_frame
		t += get_process_delta_time() * Engine.time_scale
		if boss.busy and not was_busy:
			casts += 1
			print("BOSS-TEST special attack #", casts, " (phase ", boss.phase, ") at game time ", snappedf(t, 0.1), " s: ", boss._last_ability)
			if shots < 2:
				shots += 1
				await _wait(0.55)
				await _shot("telegraph_%d" % shots)
		was_busy = boss.busy
	Engine.time_scale = 1.0
	boss.hp = boss.max_hp * 0.49
	boss.take_damage(1.0, hero.global_position)
	await _wait(0.8)
	await _shot("phase2")
	print("BOSS-TEST phase after dropping below 50% HP: ", boss.phase, " (expect 2)")
	boss.take_damage(1000000.0, hero.global_position)
	await _wait(0.6)
	print("BOSS-TEST boss dead: ", not boss.is_alive(), " shield down: ", not battle.enemy_fortress.shielded)
	battle.enemy_fortress.take_damage(500.0)
	print("BOSS-TEST fortress hp after boss death + 500 damage: ", int(battle.enemy_fortress.hp), " of ", int(battle.enemy_fortress.max_hp))
	battle.enemy_fortress.take_damage(99999.0)
	await _wait(2.4)
	await _shot("victory")
	get_tree().quit()
