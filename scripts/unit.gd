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
var slot: int = 0  # formation slot (player units)
var _goal: Vector3 = Vector3.ZERO
var _has_goal: bool = false
var _hp_bar: HpBar3D
var _marker: MeshInstance3D


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
	add_to_group("all_units")
	if team == 1:
		add_to_group("hittable_enemy")  # the hero can hit enemy units
	else:
		slot = battle.army.next_slot()
	_make_hp_bar()
	_make_marker()


func is_alive() -> bool:
	return state != State.DEAD


func nearest_point(_from: Vector3) -> Vector3:
	return global_position


func take_damage(amount: float, from_pos: Vector3 = Vector3.ZERO) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	_update_hp_bar()
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
	remove_from_group("all_units")
	_hp_bar.visible = false
	_marker.visible = false
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
	if team == 0 and battle.army.order == ArmyManager.Order.RETREAT and _has_goal:
		_heal_while_retreating(delta)
	if target == null or not _target_alive():
		target = null
		if state == State.ATTACK:
			state = State.MOVE
		_go_to_goal(delta)
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


func _move(dir: Vector3, delta: float, speed_mult: float = 1.0) -> void:
	var step: Vector3 = dir * speed * speed_mult
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
	model.play("run" if speed * speed_mult > 4.5 else "walk", clampf(speed * speed_mult / 3.2, 0.7, 1.4))


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
	if team == 0:
		_think_player_order(best, best_d)
		_collect_neighbors()
		return
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
	_collect_neighbors()


## Friends close enough to need spacing.
func _collect_neighbors() -> void:
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


# --- Orders (player army) -------------------------------------------------------------------------------

## Called when the player gives a new order: think again right away.
func refresh_orders() -> void:
	_think_t = 0.0


func _slot_offset() -> Vector3:
	var i: int = slot % 24
	return Vector3((float(i % 8) - 3.5) * 1.6, 0.0, float(i / 8) * 1.7)


func _hold_point() -> Vector3:
	var o: Vector3 = _slot_offset()
	return Vector3(o.x, 0.0, BattlefieldData.FORTRESS_Z - 24.0 + o.z)


func _retreat_point() -> Vector3:
	var o: Vector3 = _slot_offset()
	return Vector3(o.x * 0.8, 0.0, BattlefieldData.FORTRESS_Z - 9.0 + o.z * 0.8)


func _follow_point() -> Vector3:
	var o: Vector3 = _slot_offset()
	var hero: Hero = battle.hero
	var local: Vector3 = Vector3(o.x, 0.0, 2.6 + o.z)  # behind the hero
	return hero.global_position + local.rotated(Vector3.UP, hero.rotation.y)


## Chooses target or goal for the player army from the current order.
func _think_player_order(best: Node, best_d: float) -> void:
	_has_goal = false
	var o: ArmyManager.Order = battle.army.order
	if o == ArmyManager.Order.CHARGE:
		if best != null and best_d <= AGGRO_RANGE:
			target = best
		else:
			var fort: Fortress = battle.enemy_fortress
			target = fort if fort.is_alive() else null
		return
	var anchor: Vector3
	var engage: bool = false
	match o:
		ArmyManager.Order.HOLD:
			anchor = _hold_point()
			engage = best != null and best_d <= 9.0 and (best as Node3D).global_position.distance_to(anchor) <= 16.0
		ArmyManager.Order.FOLLOW:
			anchor = _follow_point()
			engage = best != null and best_d <= 7.0 and (best as Node3D).global_position.distance_to(battle.hero.global_position) <= 14.0
		_:
			anchor = _retreat_point()
	if engage:
		target = best
	else:
		target = null
		_goal = anchor
		_has_goal = true


func _go_to_goal(delta: float) -> void:
	if not _has_goal:
		model.play("idle")
		return
	var to: Vector3 = _goal - global_position
	to.y = 0.0
	if to.length() <= 0.9:
		model.play("idle")
		return
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), clampf(10.0 * delta, 0.0, 1.0))
	_move(to.normalized(), delta, 1.5 if to.length() > 8.0 else 1.0)  # hurry when far behind


func _heal_while_retreating(delta: float) -> void:
	if hp >= max_hp or global_position.distance_to(_goal) > 3.0:
		return
	hp = minf(hp + max_hp * 0.08 * delta, max_hp)
	_update_hp_bar()


# --- Health bar above the head + tactical marker ---------------------------------------------------------

func _make_hp_bar() -> void:
	_hp_bar = HpBar3D.new()
	_hp_bar.name = "HpBar"
	_hp_bar.setup(Vector2(1.15, 0.15), BattlefieldData.COLOR_RED if team == 1 else BattlefieldData.COLOR_GOLD)
	_hp_bar.position = Vector3(0.0, 2.55 * float(UnitData.LOOKS[key].scale), 0.0)
	add_child(_hp_bar)
	_update_hp_bar()


func _update_hp_bar() -> void:
	_hp_bar.set_fill(hp / max_hp)
	_hp_bar.visible = team == 1 or hp < max_hp  # enemies always show it, friends only once hurt


func _make_marker() -> void:
	_marker = MeshInstance3D.new()
	_marker.name = "TacticalMarker"
	var m: CylinderMesh = CylinderMesh.new()
	m.top_radius = 1.5
	m.bottom_radius = 1.5
	m.height = 0.05
	m.radial_segments = 12
	m.rings = 1
	_marker.mesh = m
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = BattlefieldData.COLOR_GOLD if team == 0 else BattlefieldData.COLOR_RED
	_marker.material_override = mat
	_marker.position.y = 0.3
	_marker.visible = false
	add_child(_marker)


## Tactical view: big team-coloured discs so every unit can be seen from high above.
func set_tactical(on: bool) -> void:
	if state != State.DEAD:
		_marker.visible = on
