class_name Unit
extends Node3D
## One soldier. Stats come from UnitData; the AI is deliberately simple and readable:
## pick the nearest enemy in aggro range (else march on the enemy fortress), walk until in range, hit on cooldown.
## Implements the "hittable" interface (is_alive / nearest_point / hit_radius / take_damage) like Hero and Fortress.

signal died(unit: Unit)

enum State { MOVE, ATTACK, DEAD }

const THINK_INTERVAL: float = 0.25
const AGGRO_RANGE: float = 16.0
const SEPARATION_RADIUS: float = 1.1
const BODY_FADE_TIME: float = 6.0

var battle: Battle
var key: String = "swordsman"
var team: int = 0
var max_hp: float = 60.0
var hp: float = 60.0
var damage: float = 10.0
var attack_range: float = 1.2
var speed: float = 3.0
var cooldown: float = 0.9
var hit_radius: float = 0.4
var state: State = State.MOVE
var target: Node
var model: Stickman

var _think_t: float = 0.0
var _cd: float = 0.0
var _attack_t: float = 0.0
var _struck: bool = false
var _strike_time: float = 0.34
var _anim_speed: float = 1.0
var _neighbors: Array[Unit] = []


## Creates the stats and the model. `strength` scales hp and damage (enemy level multiplier).
func setup(unit_key: String, team_id: int, strength: float = 1.0) -> void:
	key = unit_key
	team = team_id
	var s: Dictionary = UnitData.STATS[unit_key]
	max_hp = float(s.hp) * strength
	hp = max_hp
	damage = float(s.dmg) * strength
	attack_range = float(s.range)
	speed = float(s.speed)
	cooldown = float(s.cooldown)
	var style: String = String(UnitData.LOOKS[unit_key].style)
	var timing: Dictionary = UnitData.ATTACK_TIMING[style]
	_anim_speed = maxf(1.0, float(timing.length) / cooldown)
	_strike_time = float(timing.strike) / _anim_speed
	model = Stickman.new()
	model.name = "Model"
	model.setup(unit_key, team_id)
	add_child(model)
	_think_t = randf() * THINK_INTERVAL
	add_to_group("units_team%d" % team)
	if team == 1:
		add_to_group("hittable_enemy")  # the hero can hit enemy units


func is_alive() -> bool:
	return state != State.DEAD


func nearest_point(_from: Vector3) -> Vector3:
	return global_position


func take_damage(amount: float, from_pos: Vector3 = Vector3.ZERO) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	if hp <= 0.0:
		_die()
		return
	if state != State.ATTACK:
		model.play("hit", 1.0, true)
	# Being hit pulls attention to the attacker if it is close.
	if from_pos != Vector3.ZERO and target == null:
		_think_t = 0.0


func _die() -> void:
	state = State.DEAD
	remove_from_group("units_team%d" % team)
	remove_from_group("hittable_enemy")
	model.play("die", 1.0, true)
	var shadow: Node = model.get_node_or_null("BlobShadow")
	if shadow != null:
		(shadow as Node3D).visible = false
	died.emit(self)
	get_tree().create_timer(BODY_FADE_TIME).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_cd -= delta
	_think_t -= delta
	if _think_t <= 0.0:
		_think_t = THINK_INTERVAL
		_think()
	if target == null or not _target_alive():
		target = null
		if state == State.ATTACK:
			state = State.MOVE
		model.play("idle")
		return
	var to: Vector3 = _target_point() - global_position
	to.y = 0.0
	var dist: float = to.length() - _target_radius()
	if to.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), clampf(10.0 * delta, 0.0, 1.0))
	if state == State.ATTACK:
		_update_attack(delta)
		return
	if dist <= attack_range:
		if _cd <= 0.0:
			_start_attack()
		else:
			model.play("idle")
	else:
		_move(to.normalized(), delta)


func _start_attack() -> void:
	state = State.ATTACK
	_attack_t = 0.0
	_struck = false
	model.play("attack", _anim_speed, true)


func _update_attack(delta: float) -> void:
	_attack_t += delta
	if not _struck and _attack_t >= _strike_time:
		_struck = true
		_deal_damage()
	if _attack_t >= cooldown:
		_cd = 0.0
		state = State.MOVE


func _deal_damage() -> void:
	if target == null or not _target_alive():
		return
	var to: Vector3 = _target_point() - global_position
	to.y = 0.0
	if to.length() - _target_radius() > attack_range * 1.6 + 0.4:
		return  # target slipped away
	target.call("take_damage", damage, global_position)


func _move(dir: Vector3, delta: float) -> void:
	var step: Vector3 = dir * speed
	# Push away from crowded friends so the army spreads out instead of stacking.
	for n: Unit in _neighbors:
		if not is_instance_valid(n) or n.state == State.DEAD:
			continue
		var off: Vector3 = global_position - n.global_position
		off.y = 0.0
		var d: float = off.length()
		if d < SEPARATION_RADIUS and d > 0.001:
			step += off / d * (1.0 - d / SEPARATION_RADIUS) * speed * 1.5
	var p: Vector3 = global_position + step * delta
	p.x = clampf(p.x, -(BattlefieldData.VALLEY_HALF_WIDTH + 4.0), BattlefieldData.VALLEY_HALF_WIDTH + 4.0)
	p.z = clampf(p.z, -(BattlefieldData.FORTRESS_Z + 10.0), BattlefieldData.FORTRESS_Z + 10.0)
	p.y = battle.terrain.height_at(p.x, p.z)
	global_position = p
	model.play("run" if speed > 4.5 else "walk", clampf(speed / 3.2, 0.7, 1.4))


# --- AI -----------------------------------------------------------------------------------------------

func _think() -> void:
	var best: Node = null
	var best_d: float = INF
	for n: Node in get_tree().get_nodes_in_group("units_team%d" % (1 - team)):
		var d: float = _edge_dist(n)
		if d < best_d:
			best_d = d
			best = n
	if team == 1 and battle.hero != null and battle.hero.is_alive():
		var hd: float = _edge_dist(battle.hero)
		if hd < best_d:
			best_d = hd
			best = battle.hero
	# Keep the current target unless something is clearly closer.
	if target != null and _target_alive() and best != null and target != best:
		if _edge_dist(target) <= best_d + 2.0:
			best = target
			best_d = _edge_dist(target)
	if best != null and best_d <= AGGRO_RANGE:
		target = best
	else:
		var fort: Fortress = battle.enemy_fortress if team == 0 else battle.player_fortress
		target = fort if fort.is_alive() else null
	# Friends close enough to need spacing.
	_neighbors.clear()
	for n: Node in get_tree().get_nodes_in_group("units_team%d" % team):
		if n != self and (n as Node3D).global_position.distance_squared_to(global_position) < SEPARATION_RADIUS * SEPARATION_RADIUS * 1.5:
			_neighbors.append(n as Unit)


func _edge_dist(n: Node) -> float:
	var to: Vector3 = (n.call("nearest_point", global_position) as Vector3) - global_position
	to.y = 0.0
	return to.length() - float(n.get("hit_radius"))


func _target_alive() -> bool:
	return is_instance_valid(target) and bool(target.call("is_alive"))


func _target_point() -> Vector3:
	return target.call("nearest_point", global_position)


func _target_radius() -> float:
	return float(target.get("hit_radius"))
