class_name HeroAutotest
extends Node
## Scripted playthrough of the hero controls for step 3 (debug only):
##   godot --path . -- --hero-test
## Presses real input actions, saves screenshots to screenshots/ and prints HERO-TEST results.

var battle: Battle


func _ready() -> void:
	_run()


func _press(action: String, pressed: bool = true) -> void:
	var e: InputEventAction = InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)


## A real click: press, then release shortly after.
func _click() -> void:
	_press("attack")
	get_tree().create_timer(0.05).timeout.connect(func() -> void: _press("attack", false))


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step3_" + shot_name)


func _run() -> void:
	var hero: Hero = battle.hero
	hero.mouse_gate = false
	var cam: HeroCamera = battle.hero_camera
	var dummies: Array[Node] = get_tree().get_nodes_in_group("hittable_enemy").filter(func(n: Node) -> bool: return n is TrainingDummy)
	hero.struck.connect(func(h: int, c: int) -> void: print("HERO-TEST strike combo=", c, " hits=", h, " hero_z=", snappedf(hero.global_position.z, 0.01)))
	await _wait(1.0)
	await _shot("idle")
	# Sprint forward toward the dummies.
	_press("sprint")
	_press("move_forward")
	await _wait(0.9)
	await _shot("sprint")
	_press("move_forward", false)
	_press("sprint", false)
	await _wait(0.5)
	print("HERO-TEST hero z after sprint: ", snappedf(hero.global_position.z, 0.1))
	# 3-hit combo, camera swung to the side so the swings are visible.
	cam.yaw = 0.9
	cam.distance = 4.2
	await _wait(0.4)
	var hp_before: float = 0.0
	for d: Node in dummies:
		hp_before += (d as TrainingDummy).hp
	_click()
	await _wait(0.2)
	_click()
	await _wait(0.1)
	await _shot("attack1")
	await _wait(0.4)
	_click()
	await _wait(0.2)
	await _shot("attack2")
	await _wait(0.6)
	await _shot("attack3")
	await _wait(1.0)
	var hp_after: float = 0.0
	for d: Node in dummies:
		hp_after += (d as TrainingDummy).hp
	print("HERO-TEST dummy damage dealt by combo: ", hp_before - hp_after, " (expected 14+16+32 = 62 on one dummy)")
	# Dodge roll.
	_press("move_right")
	_press("dodge")
	await _wait(0.2)
	await _shot("roll")
	print("HERO-TEST invincible during roll: ", hero.invincible)
	_press("move_right", false)
	await _wait(0.9)
	# Block.
	_press("block")
	await _wait(0.5)
	await _shot("block")
	print("HERO-TEST state while blocking (BLOCK=3): ", hero.state)
	_press("block", false)
	await _wait(0.4)
	# Fortress: teleport to the enemy gate and hit it.
	hero.global_position = Vector3(0.0, 0.0, -63.0)
	hero.rotation.y = 0.0
	cam._focus = hero.global_position
	cam.yaw = 0.5
	var fort_hp: float = battle.enemy_fortress.hp
	await _wait(0.3)
	_click()
	await _wait(0.2)
	_click()
	await _wait(0.5)
	_click()
	await _wait(0.9)
	await _shot("fortress")
	print("HERO-TEST enemy fortress hp: ", fort_hp, " -> ", battle.enemy_fortress.hp)
	get_tree().quit()
