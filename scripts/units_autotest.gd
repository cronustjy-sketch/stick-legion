class_name UnitsAutotest
extends Node
## Scripted check of all 10 unit types and their specials for step 8 (debug only):
##   godot --path . -- --units-test
## Runs one small scenario after another (passive dummies as targets), prints UNITS-TEST results,
## saves screenshots/step8_*.png.

var battle: Battle
var _cam: Camera3D
var _made: Array[Unit] = []


func _ready() -> void:
	_run()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step8_" + shot_name)


## Spawns a unit at (x, z) facing `yaw` (0 = toward -Z). Passive units only stand and take damage.
func _mk(key: String, team: int, x: float, z: float, passive: bool = false, yaw: float = 0.0) -> Unit:
	var u: Unit = battle.spawn_unit(key, team, 0.0)
	u.global_position = Vector3(x, battle.terrain.height_at(x, z), z)
	u.rotation.y = yaw
	u.passive = passive
	_made.append(u)
	return u


func _clear() -> void:
	for u: Unit in _made:
		if is_instance_valid(u):
			u.queue_free()
	_made.clear()
	for p: Node in get_tree().get_nodes_in_group("projectiles"):
		p.queue_free()
	await _wait(0.2)


func _aim(from: Vector3, at: Vector3) -> void:
	_cam.position = from
	_cam.look_at(at)


func _dummy_hp(key: String = "swordsman", hp: float = -1.0, x: float = 0.0, z: float = 0.0, yaw: float = PI) -> Unit:
	var d: Unit = _mk(key, 1, x, z, true, yaw)
	if hp > 0.0:
		d.max_hp = hp
		d.hp = hp
	return d


## Waits until `u` is in the strike part of its attack animation (for the screenshot), up to `limit` seconds.
func _wait_mid_attack(u: Unit, limit: float) -> bool:
	var waited: float = 0.0
	while waited < limit:
		if is_instance_valid(u) and u.state == Unit.State.ATTACK and u._attack_t >= u._strike_time * 0.85:
			return true
		await get_tree().create_timer(0.03).timeout
		waited += 0.03
	return false


func _run() -> void:
	battle.hero.mouse_gate = false
	battle.hero.global_position = Vector3(0.0, 0.0, 66.0)
	battle.army.gold = 99999.0
	_cam = Camera3D.new()
	_cam.fov = 45.0
	add_child(_cam)
	_cam.current = true
	await _wait(0.5)

	# 1. Lineup of every unit type, both teams, facing the camera.
	var order: Array[String] = UnitData.ALL_ORDER
	for i: int in order.size():
		var cx: float = (float(i) - 4.5) * 5.0
		_mk(order[i], 0, cx - 1.3, 0.0, true, PI)
		_mk(order[i], 1, cx + 1.3, 0.0, true, PI)
	await _wait(1.2)
	_aim(Vector3(-12.0, 3.2, 12.0), Vector3(-12.0, 1.4, 0.0))
	await _wait(0.2)
	await _shot("lineup_1")
	_aim(Vector3(11.0, 3.4, 12.5), Vector3(11.0, 1.5, 0.0))
	await _wait(0.2)
	await _shot("lineup_2")
	await _clear()

	Engine.time_scale = 3.0

	# 2. Archer arrows: hurt a swordsman; a shield knight facing the archer blocks them, facing away he does not.
	var archer: Unit = _mk("archer", 0, 0.0, 12.0)
	var sword: Unit = _dummy_hp("swordsman", 600.0, 0.0, -2.0)
	var shield_front: Unit = _dummy_hp("shield_knight", 600.0, 6.0, -2.0, 0.0)  # faces -Z, i.e. away from the archer's side? see below
	shield_front.rotation.y = PI  # faces +Z toward the archer: blocks
	var shield_back: Unit = _dummy_hp("shield_knight", 600.0, -6.0, -2.0, 0.0)  # faces -Z, back to the archer: takes damage
	_aim(Vector3(8.0, 3.0, 17.0), Vector3(0.0, 1.2, 5.0))
	await _wait(0.2)
	await _wait_mid_attack(archer, 6.0)
	await _shot("attack_archer")
	await _wait(14.0)
	print("UNITS-TEST archer vs swordsman hp lost: ", int(600.0 - sword.hp), " (arrows hit)")
	await _clear()
	# Make the archer pick each knight in turn.
	var a2: Unit = _mk("archer", 0, 6.0, 12.0)
	var k1: Unit = _dummy_hp("shield_knight", 600.0, 6.0, -2.0, PI)
	await _wait(14.0)
	print("UNITS-TEST archer vs shield knight facing it, hp lost: ", int(600.0 - k1.hp), " (expect 0: blocked)")
	a2.queue_free()
	k1.queue_free()
	var a3: Unit = _mk("archer", 0, 6.0, 12.0)
	var k2: Unit = _dummy_hp("shield_knight", 600.0, 6.0, -2.0, 0.0)
	await _wait(14.0)
	print("UNITS-TEST archer vs shield knight with his back turned, hp lost: ", int(600.0 - k2.hp), " (expect >0, armour 35% applies)")
	await _clear()

	# 3. Mage fireball splash.
	var mage: Unit = _mk("mage", 0, 0.0, 10.0)
	var cluster: Array[Unit] = [_dummy_hp("swordsman", 300.0, 0.0, -2.0), _dummy_hp("swordsman", 300.0, 1.2, -2.8), _dummy_hp("swordsman", 300.0, -1.2, -1.4)]
	_aim(Vector3(7.0, 3.5, 13.0), Vector3(0.0, 1.0, 3.0))
	await _wait(0.2)
	await _wait_mid_attack(mage, 8.0)
	await _wait(0.6)
	await _shot("attack_mage")
	await _wait(8.0)
	var damaged: int = 0
	for c: Unit in cluster:
		if c.hp < c.max_hp:
			damaged += 1
	print("UNITS-TEST mage splash: ", damaged, " of 3 clustered enemies hurt (expect 3)")
	await _clear()

	# 4. Priest heals a wounded friend.
	var priest: Unit = _mk("priest", 0, 0.0, 6.0)
	var wounded: Unit = _mk("swordsman", 0, 3.0, 4.0, true)
	wounded.hp = 20.0
	_aim(Vector3(6.0, 3.0, 10.0), Vector3(1.5, 1.0, 5.0))
	await _wait(0.2)
	await _wait_mid_attack(priest, 6.0)
	await _shot("attack_priest")
	await _wait(8.0)
	print("UNITS-TEST priest healed a swordsman: 20 -> ", int(wounded.hp), " / ", int(wounded.max_hp))
	await _clear()

	# 5. Giant smash: area damage + knockback.
	var giant: Unit = _mk("giant", 0, 0.0, 6.0)
	var group: Array[Unit] = [_dummy_hp("swordsman", 300.0, 0.0, 2.5), _dummy_hp("swordsman", 300.0, 1.5, 3.0), _dummy_hp("swordsman", 300.0, -1.5, 3.2)]
	var starts: Array[Vector3] = []
	for g: Unit in group:
		starts.append(g.global_position)
	_aim(Vector3(8.0, 4.0, 11.0), Vector3(0.0, 1.5, 4.0))
	await _wait(0.2)
	await _wait_mid_attack(giant, 12.0)
	await _wait(0.12)
	await _shot("attack_giant")
	await _wait(2.5)
	var hurt: int = 0
	var shoved: float = 0.0
	for i: int in group.size():
		if group[i].hp < group[i].max_hp:
			hurt += 1
		shoved = maxf(shoved, group[i].global_position.distance_to(starts[i]))
	print("UNITS-TEST giant smash: ", hurt, " of 3 hurt, max knockback ", snappedf(shoved, 0.1), " m (expect 3 hurt, ~3.5 m)")
	await _clear()

	# 6. Cavalry charge: the first hit after a run-up deals double damage.
	var horse: Unit = _mk("cavalry", 0, 0.0, 30.0)
	var target: Unit = _dummy_hp("swordsman", 600.0, 0.0, -2.0)
	_aim(Vector3(7.0, 3.0, 8.0), Vector3(0.0, 1.2, 0.0))
	await _wait(0.2)
	var first_hit: float = 0.0
	var watched: float = target.hp
	var waited: float = 0.0
	while waited < 20.0 and first_hit == 0.0:
		await get_tree().create_timer(0.02).timeout
		waited += 0.02
		if target.hp < watched:
			first_hit = watched - target.hp
		watched = target.hp
	await _wait_mid_attack(horse, 3.0)
	await _shot("attack_cavalry")
	await _wait(2.5)
	print("UNITS-TEST cavalry first hit after a run-up: ", int(first_hit), " (expect 40 = 20 x2), next hits normal 20")
	await _clear()

	# 7. Catapult vs fortress (x2 damage) and splash on units.
	var cat: Unit = _mk("catapult", 0, 0.0, -38.0, false, 0.0)
	_aim(Vector3(9.0, 4.0, -31.0), Vector3(0.0, 1.5, -40.0))
	var fort_before: float = battle.enemy_fortress.hp
	await _wait(0.2)
	await _wait_mid_attack(cat, 10.0)
	await _shot("attack_catapult")
	await _wait(12.0)
	print("UNITS-TEST catapult vs enemy fortress: ", int(fort_before), " -> ", int(battle.enemy_fortress.hp), " (50 x2 = 100 per boulder)")
	await _clear()

	# 8. Spearman double damage vs big units; assassin crits.
	var spear: Unit = _mk("spearman", 0, 0.0, 0.0, true)
	var big: Unit = _dummy_hp("giant", 5000.0, 0.0, -5.0)
	var small: Unit = _dummy_hp("swordsman", 5000.0, 4.0, -5.0)
	print("UNITS-TEST spearman damage vs giant: ", spear.damage_against(big), "  vs swordsman: ", spear.damage_against(small), " (expect 24 vs 12)")
	await _clear()
	var assassin: Unit = _mk("assassin", 0, 0.0, 6.0)
	var post: Unit = _dummy_hp("swordsman", 1000000.0, 0.0, 4.6)
	Engine.time_scale = 5.0
	var hits: int = 0
	var crits: int = 0
	var last: float = post.hp
	var t: float = 0.0
	while t < 90.0:
		await get_tree().process_frame
		t += get_process_delta_time() * Engine.time_scale
		if post.hp < last:
			hits += 1
			if last - post.hp > 25.0:
				crits += 1
			last = post.hp
	print("UNITS-TEST assassin: ", crits, " crits in ", hits, " hits = ", snappedf(100.0 * float(crits) / maxf(hits, 1), 1.0), " % (expect ~30 %)")
	Engine.time_scale = 1.0
	assassin.queue_free()
	await _clear()
	get_tree().quit()
