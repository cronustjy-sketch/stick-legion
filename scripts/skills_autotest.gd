class_name SkillsAutotest
extends Node
## Scripted check of hero skills, rage and hit effects for step 9 (debug only):
##   godot --path . -- --skills-test

var battle: Battle
var _made: Array[Unit] = []


func _ready() -> void:
	_run()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step9_" + shot_name)


func _press(action: String) -> void:
	var e: InputEventAction = InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	get_tree().create_timer(0.06).timeout.connect(func() -> void:
		var r: InputEventAction = InputEventAction.new()
		r.action = action
		r.pressed = false
		Input.parse_input_event(r))


func _enemies(count: int, radius: float, centre: Vector3) -> Array[Unit]:
	for u: Unit in _made:
		if is_instance_valid(u):
			u.queue_free()
	_made.clear()
	var out: Array[Unit] = []
	for i: int in count:
		var a: float = float(i) / float(count) * TAU
		var u: Unit = battle.spawn_unit("swordsman", 1, 0.0)
		u.passive = true
		u.max_hp = 600.0
		u.hp = 600.0
		u.global_position = centre + Vector3(sin(a) * radius, 0.0, cos(a) * radius)
		u.rotation.y = a + PI
		_made.append(u)
		out.append(u)
	return out


func _lost(list: Array[Unit]) -> int:
	var t: float = 0.0
	for u: Unit in list:
		t += u.max_hp - u.hp
	return int(t)


func _run() -> void:
	var hero: Hero = battle.hero
	var cam: HeroCamera = battle.hero_camera
	hero.mouse_gate = false
	hero.global_position = Vector3(0.0, 0.0, 20.0)
	hero.rotation.y = 0.0
	cam._focus = hero.global_position
	cam.yaw = 0.7
	cam.distance = 7.0
	cam.pitch = 0.45
	await _wait(0.6)
	var centre: Vector3 = hero.global_position

	# Q: Whirlwind hits everything around the hero.
	var ring: Array[Unit] = _enemies(6, 2.4, centre)
	await _wait(0.4)
	_press("skill_q")
	await _wait(0.45)
	await _shot("whirlwind")
	await _wait(0.8)
	print("UNITS-TEST-HEADER skills")
	print("SKILLS-TEST Q whirlwind: damage dealt to 6 surrounding enemies = ", _lost(ring), " (3 hits x 16 x 6 = 288 if all hit)")
	print("SKILLS-TEST rage after Q: ", snappedf(hero.skills.rage, 0.1))
	_press("skill_q")
	await _wait(0.3)
	print("SKILLS-TEST Q again immediately -> cast? ", hero.state == Hero.State.SKILL, " (expect false: on cooldown, cd left ", snappedf(hero.skills.cooldown_left("q"), 0.1), "s)")
	await _wait(0.4)

	# E: Shield Dash.
	hero.global_position = centre
	var line: Array[Unit] = _enemies(3, 0.0, centre)
	for i: int in 3:
		line[i].global_position = centre + Vector3(float(i - 1) * 0.8, 0.0, -6.5 - float(i))
	hero.rotation.y = 0.0
	await _wait(0.4)
	_press("skill_e")
	await _wait(0.32)
	await _shot("dash")
	var was_invincible: bool = hero.invincible
	await _wait(0.8)
	print("SKILLS-TEST E dash: invincible while dashing=", was_invincible, ", damage dealt = ", _lost(line), " (expect 3 x 28 = 84)")

	# R: War Cry heals the army and buffs damage.
	hero.global_position = centre
	var hurt: Array[Unit] = []
	for i: int in 3:
		var f: Unit = battle.spawn_unit("swordsman", 0, 0.0)
		f.passive = true
		f.global_position = centre + Vector3(-2.5 + float(i) * 2.5, 0.0, 3.0)
		f.rotation.y = PI
		f.hp = 15.0
		_made.append(f)
		hurt.append(f)
	await _wait(0.3)
	_press("skill_r")
	await _wait(0.6)
	await _shot("warcry")
	print("SKILLS-TEST R war cry: friend hp 15 -> ", int(hurt[0].hp), "; army damage buff = ", battle.army.damage_buff(), " (expect 1.35)")
	await _wait(0.8)

	# F: Ground Slam.
	hero.global_position = centre
	hero.rotation.y = 0.0
	var slam_targets: Array[Unit] = _enemies(5, 2.8, centre + Vector3(0.0, 0.0, -1.6))
	await _wait(0.4)
	_press("skill_f")
	await _wait(0.62)
	await _shot("slam")
	await _wait(0.8)
	print("SKILLS-TEST F slam: damage dealt = ", _lost(slam_targets), " (5 x 50 = 250 if all in radius 5)")

	# G: needs a full rage meter.
	hero.skills.rage = 40.0
	hero.global_position = centre
	var big_ring: Array[Unit] = _enemies(8, 6.0, centre)
	await _wait(0.4)
	_press("skill_g")
	await _wait(0.3)
	print("SKILLS-TEST G at 40% rage -> cast? ", hero.state == Hero.State.SKILL, " (expect false)")
	hero.skills.add_rage(60.0)
	await _wait(0.3)
	_press("skill_g")
	await _wait(1.0)
	await _shot("ultimate")
	await _wait(1.0)
	print("SKILLS-TEST G ultimate: damage dealt to 8 enemies = ", _lost(big_ring), " (8 x 140 = 1120), rage after = ", snappedf(hero.skills.rage, 0.1), ", buff = ", battle.army.damage_buff())

	# Plain combo with sword trail + damage numbers.
	var dummies: Array[Unit] = _enemies(2, 1.8, centre + Vector3(0.0, 0.0, -1.5))
	hero.global_position = centre
	hero.rotation.y = 0.0
	await _wait(0.5)
	_press("attack")
	await _wait(0.12)
	await _wait(0.22)
	await _shot("trail")
	await _wait(0.2)
	print("SKILLS-TEST sword hit: damage = ", _lost(dummies))
	get_tree().quit()
