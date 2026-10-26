class_name BossAutotest
extends Node
## Scripted boss fight check (debug only):
##   godot --path . res://scenes/battle.tscn -- --boss-level=5      (5, 10, 15 or 20)

var battle: Battle


func _ready() -> void:
	_run()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var def: Dictionary = BossData.for_level(battle.level)
	DebugShot.save(get_viewport(), "story_boss_%s_%s" % [def.id, shot_name])


func _run() -> void:
	var hero: Hero = battle.hero
	var def: Dictionary = BossData.for_level(battle.level)
	hero.mouse_gate = false
	hero.max_hp = 999999.0
	hero.hp = 999999.0
	hero.global_position = Vector3(0.0, 0.0, -24.0)
	battle.hero_camera._focus = hero.global_position
	battle.hero_camera.distance = 10.0
	battle.hero_camera.pitch = 0.55
	var bosses: Array[Boss] = battle.bosses
	print("BOSS-TEST level ", battle.level, ": ", def.name, " x", bosses.size(), " hp=", int(bosses[0].max_hp), " shielded=", battle.enemy_fortress.shielded)
	var before: float = battle.enemy_fortress.hp
	battle.enemy_fortress.take_damage(500.0)
	print("BOSS-TEST shielded fortress takes damage? ", battle.enemy_fortress.hp < before, " (expect false)")
	await _wait(2.5)
	await _shot("appear")
	Engine.time_scale = 2.0
	var seen: Dictionary = {}
	var busy_prev: Dictionary = {}
	var t: float = 0.0
	var shots: int = 0
	var wanted: int = 4 if bosses.size() == 1 else 6
	while seen.size() < wanted and t < 150.0:
		await get_tree().process_frame
		t += get_process_delta_time() * Engine.time_scale
		for b: Boss in bosses:
			var was: bool = bool(busy_prev.get(b, false))
			if b.busy and not was:
				var key: String = "%s:%s:p%d" % [b.boss_name, b._last_ability, b.phase]
				if not seen.has(key):
					print("BOSS-TEST ", snappedf(t, 0.1), "s  ", key)
				seen[key] = true
				if shots < 2:
					shots += 1
					await _wait(0.5)
					await _shot("telegraph_%d" % shots)
			busy_prev[b] = b.busy
	Engine.time_scale = 1.0
	# Phases.
	var thresholds: Array = def.thresholds
	var guard_list: Array[Unit] = []
	for i: int in thresholds.size():
		var b: Boss = bosses[0]
		b.hp = b.max_hp * (float(thresholds[i]) - 0.02)
		b.take_damage(1.0, hero.global_position)
		await _wait(1.0)
		print("BOSS-TEST dropped below ", int(float(thresholds[i]) * 100.0), "% -> phase ", b.phase)
		if String(def.id) == "corvin" and b.phase == 2:
			await _wait(1.5)
			guard_list = b._guards.duplicate()
			print("BOSS-TEST phase 2 summoned ", guard_list.size(), " red elite guards (expect 6)")
		await _shot("phase%d" % b.phase)
	if bool(def.get("link", false)):
		bosses[0].take_damage(999999.0, hero.global_position)
		await _wait(1.0)
		print("BOSS-TEST twin ", bosses[0].boss_name, " fell -> ", bosses[1].boss_name, " phase=", bosses[1].phase, " (expect 2)")
		await _shot("enraged")
	if String(def.id) == "corvin":
		print("BOSS-TEST red sky active (sky top red channel): ", snappedf(SkySetup.sky_mat.sky_top_color.r, 0.01), " (blue sky = 0.17)")
		var alive_guards: int = 0
		for g: Unit in guard_list:
			if is_instance_valid(g) and g.is_alive():
				alive_guards += 1
		print("BOSS-TEST elite guards still alive after phase 3 (expect 0): ", alive_guards)
	for b: Boss in bosses:
		if b.is_alive():
			b.take_damage(999999.0, hero.global_position)
	await _wait(1.0)
	print("BOSS-TEST all bosses dead, shield down: ", not battle.enemy_fortress.shielded)
	await _shot("defeated")
	battle.enemy_fortress.take_damage(99999.0)
	await _wait(2.4)
	await _shot("victory")
	get_tree().quit()
