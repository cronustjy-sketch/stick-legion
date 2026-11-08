class_name Digger
extends Unit
## A worker: walks to the nearest free gold rock, mines for a few seconds, carries the gold home and hands it over.
## Ignores the army orders (Charge / Hold / Follow) and keeps mining; Retreat sends it home. It fights back with its pickaxe
## only at enemies that come very close (and enemy units may attack it). The enemy has Diggers too (scripts/enemy_spawner.gd).

enum Job { FIND, TO_ROCK, MINING, TO_HOME, WAIT_HOME }

var job: Job = Job.FIND
var rock: GoldRock
var carried: float = 0.0
var delivered: float = 0.0

var _mine_left: float = 0.0
var _swing_left: float = 0.0
var _spark_left: float = -1.0
var _find_left: float = 0.0
var _home_x: float = 0.0


func setup(unit_key: String, team_id: int, strength: float = 1.0) -> void:
	super.setup(unit_key, team_id, strength)
	add_to_group("diggers_team%d" % team)
	_home_x = randf_range(-3.0, 3.0)
	_find_left = randf() * 0.5


func carry_capacity() -> float:
	return UpgradeData.value("income") if team == 0 else EconomyData.DIGGER_CARRY


func _die() -> void:
	remove_from_group("diggers_team%d" % team)
	_drop_rock()
	super._die()


## Diggers only look for enemies that are right next to them.
func _think() -> void:
	var best: Node = null
	var best_d: float = INF
	for n: Node in get_tree().get_nodes_in_group("units_team%d" % (1 - team)):
		var d: float = _edge_dist(n)
		if d < best_d:
			best_d = d
			best = n
	target = best if best != null and best_d <= EconomyData.DIGGER_DEFEND_RANGE else null
	_collect_neighbors()


func _home_point() -> Vector3:
	var sign_z: float = 1.0 if team == 0 else -1.0
	var z: float = sign_z * (BattlefieldData.FORTRESS_Z - EconomyData.DELIVERY_Z_FROM_FORTRESS)
	return Vector3(_home_x, battle.terrain.height_at(_home_x, z), z)


func _drop_rock() -> void:
	if rock != null and is_instance_valid(rock):
		rock.release(self)
	rock = null


## The job loop. Runs whenever the Digger has no enemy to fight (see Unit._physics_process).
func _go_to_goal(delta: float) -> void:
	var retreating: bool = team == 0 and battle.army.order == ArmyManager.Order.RETREAT
	if retreating and job != Job.TO_HOME and job != Job.WAIT_HOME:
		_drop_rock()
		job = Job.TO_HOME
	elif not retreating and job == Job.WAIT_HOME:
		job = Job.FIND
	match job:
		Job.FIND:
			model.play("idle")
			_find_left -= delta
			if _find_left <= 0.0:
				_find_left = 0.7
				var r: GoldRock = GoldRock.nearest_free(get_tree(), global_position)
				if r != null:
					rock = r
					r.claim(self)
					job = Job.TO_ROCK
		Job.TO_ROCK:
			if not _rock_ok():
				return
			var to: Vector3 = rock.global_position - global_position
			to.y = 0.0
			if to.length() - rock.stand_distance() <= 0.15:
				job = Job.MINING
				_mine_left = EconomyData.DIGGER_MINE_TIME
				_swing_left = 0.2
				return
			_walk(to.normalized(), delta)
		Job.MINING:
			if not _rock_ok():
				return
			_face_point(rock.global_position, delta)
			_mine_left -= delta
			_swing_left -= delta
			if _swing_left <= 0.0:
				_swing_left = 0.85
				_spark_left = _strike_time
				model.play(_attack_anim, 1.0, true)
			if _spark_left >= 0.0:
				_spark_left -= delta
				if _spark_left < 0.0:
					_mine_spark()
			if _mine_left <= 0.0:
				carried = rock.mine(carry_capacity())
				_drop_rock()
				job = Job.TO_HOME if carried > 0.0 else Job.FIND
		Job.TO_HOME:
			var to_home: Vector3 = _home_point() - global_position
			to_home.y = 0.0
			if to_home.length() <= 1.2:
				_deliver()
				job = Job.WAIT_HOME if retreating else Job.FIND
				return
			_walk(to_home.normalized(), delta)
		Job.WAIT_HOME:
			model.play("idle")


func _rock_ok() -> bool:
	if rock == null or not is_instance_valid(rock) or rock.remaining <= 0.0:
		rock = null
		job = Job.FIND
		_find_left = 0.0
		return false
	return true


func _walk(dir: Vector3, delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(10.0 * delta, 0.0, 1.0))
	_move(dir, delta)


func _face_point(p: Vector3, delta: float) -> void:
	var to: Vector3 = p - global_position
	to.y = 0.0
	if to.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), clampf(10.0 * delta, 0.0, 1.0))


func _mine_spark() -> void:
	if rock == null or not is_instance_valid(rock):
		return
	var at: Vector3 = global_position.lerp(rock.global_position, 0.8) + Vector3(0.0, 0.9, 0.0)
	battle.fx.sparks(at, Color("ffd24a"), 6)
	Sfx.play("clang", -14.0, global_position, randf_range(1.3, 1.6))


## Hands the gold over at the fortress gate: it counts for the owner and a "+50" pops up.
func _deliver() -> void:
	if carried <= 0.0:
		return
	var amount: float = carried
	carried = 0.0
	delivered += amount
	if team == 0:
		battle.army.add_gold(amount)
	else:
		battle.spawner.add_gold(amount)
	if team == 0 or battle.hero.global_position.distance_to(global_position) < 45.0:
		battle.fx.number(global_position + Vector3(0.0, _bar_height + 0.5, 0.0), amount, "gold" if team == 0 else "enemy_gold")
	Sfx.play("coin", -9.0 if team == 0 else -18.0, global_position)
