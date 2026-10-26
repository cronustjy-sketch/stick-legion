class_name Unit
extends Node3D
## One soldier. Stats come from UnitData; the AI is deliberately simple and readable:
## pick the nearest enemy in aggro range (else march on the enemy fortress), walk until in range, hit on cooldown.
## Player units also obey the army order (Charge / Hold / Follow / Retreat).
## Unit specials (arrows, splash, healing, armour, smash, charge, ...) are driven by optional keys in UnitData.STATS.
## Implements the "hittable" interface (is_alive / nearest_point / hit_radius / take_damage) like Hero and Fortress.

signal died(unit: Unit)

enum State { MOVE, ATTACK, DEAD }

const THINK_INTERVAL: float = 0.25
const AGGRO_RANGE: float = 16.0
const SEPARATION_RADIUS: float = 1.1
const BODY_FADE_TIME: float = 6.0
const KITE_DISTANCE: float = 5.0

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
var model: UnitVisual
var passive: bool = false  # tests: stands still, never thinks or attacks, but can be hurt
var busy: bool = false  # bosses stand still while casting a special attack

# Specials (read from UnitData.STATS in setup)
var ranged: String = ""
var splash: float = 0.0
var armor: float = 0.0
var blocks_arrows: bool = false
var is_big: bool = false
var heal_amount: float = 0.0
var crit_chance: float = 0.0
var crit_mult: float = 2.0
var bonus_vs_big: float = 1.0
var charge_mult: float = 1.0
var aoe_radius: float = 0.0
var knockback: float = 0.0
var fortress_mult: float = 1.0
var projectile_speed: float = 20.0
var kites: bool = false
var aggro: float = AGGRO_RANGE

var slot: int = 0  # formation slot (player units)

var _think_t: float = 0.0
var _cd: float = 0.0
var _attack_t: float = 0.0
var _struck: bool = false
var _strike_time: float = 0.34
var _anim_speed: float = 1.0
var _attack_anim: StringName = &"attack"
var _neighbors: Array[Unit] = []
var _goal: Vector3 = Vector3.ZERO
var _has_goal: bool = false
var _run_dist: float = 99.0  # distance travelled since the last attack (cavalry charge)
var _hp_bar: HpBar3D
var _bar_height: float = 2.5
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
	hit_radius = float(s.get("radius", 0.4))
	ranged = String(s.get("ranged", ""))
	splash = float(s.get("splash", 0.0))
	armor = float(s.get("armor", 0.0))
	blocks_arrows = bool(s.get("blocks_arrows", false))
	is_big = bool(s.get("big", false))
	heal_amount = float(s.get("heal", 0.0)) * strength
	crit_chance = float(s.get("crit", 0.0))
	crit_mult = float(s.get("crit_mult", 2.0))
	bonus_vs_big = float(s.get("bonus_vs_big", 1.0))
	charge_mult = float(s.get("charge_mult", 1.0))
	aoe_radius = float(s.get("aoe", 0.0))
	knockback = float(s.get("knockback", 0.0))
	fortress_mult = float(s.get("fortress_mult", 1.0))
	projectile_speed = float(s.get("projectile_speed", 20.0))
	kites = bool(s.get("kite", false))
	if ranged != "":
		aggro = maxf(AGGRO_RANGE, attack_range * 0.9)
	var look: Dictionary = UnitData.LOOKS[unit_key]
	var timing: Dictionary = UnitData.ATTACK_TIMING[String(look.get("timing", look.style))]
	_attack_anim = StringName(look.get("attack_anim", "attack"))
	_anim_speed = maxf(1.0, float(timing.length) / cooldown)
	_strike_time = float(timing.strike) / _anim_speed
	model = VisualFactory.create(unit_key, team_id)
	model.name = "Model"
	add_child(model)
	_think_t = randf() * THINK_INTERVAL
	add_to_group("units_team%d" % team)
	add_to_group("all_units")
	if team == 1:
		add_to_group("hittable_enemy")  # the hero can hit enemy units
	else:
		slot = battle.army.next_slot()
	_make_hp_bar(float(look.get("bar_height", 2.55 * float(look.scale))))
	_make_marker()


func is_alive() -> bool:
	return state != State.DEAD


func nearest_point(_from: Vector3) -> Vector3:
	return global_position


func take_damage(amount: float, from_pos: Vector3 = Vector3.ZERO) -> void:
	if state == State.DEAD:
		return
	var dealt: float = amount * (1.0 - armor)
	hp -= dealt
	_update_hp_bar()
	_hit_fx(dealt)
	if hp <= 0.0:
		_die()
		return
	if state != State.ATTACK:
		model.play("hit", 1.0, true)
	# Being hit pulls attention to the attacker if it is close.
	if from_pos != Vector3.ZERO and target == null:
		_think_t = 0.0


func heal(amount: float) -> void:
	if state == State.DEAD:
		return
	var before: float = hp
	hp = minf(hp + amount, max_hp)
	_update_hp_bar()
	if hp > before:
		battle.fx.number(global_position + Vector3(0.0, _bar_height + 0.4, 0.0), hp - before, "heal")


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
	if state == State.DEAD or passive:
		return
	_extra_process(delta)
	if busy:
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
	if kites and dist < KITE_DISTANCE and target is Unit:
		_move(-to.normalized(), delta, 0.9)  # archers and mages back away from enemies that get too close
		return
	if dist <= attack_range:
		if _cd <= 0.0:
			_start_attack()
		else:
			model.play("idle")
	else:
		_move(to.normalized(), delta)


## Hook for subclasses (Boss): runs every physics frame before the normal AI.
func _extra_process(_delta: float) -> void:
	pass


func _start_attack() -> void:
	state = State.ATTACK
	_attack_t = 0.0
	_struck = false
	model.play(_attack_anim, _anim_speed, true)


func _update_attack(delta: float) -> void:
	_attack_t += delta
	if not _struck and _attack_t >= _strike_time:
		_struck = true
		_deal_damage()
	if _attack_t >= cooldown:
		_cd = 0.0
		state = State.MOVE


# --- Attacks and specials -----------------------------------------------------------------------------

## Damage this unit would deal to `t` right now (spear vs big, charge, ...). Crits are rolled separately.
func damage_against(t: Node) -> float:
	var d: float = damage
	if t is Unit and (t as Unit).is_big:
		d *= bonus_vs_big
	if t is Fortress:
		d *= fortress_mult
	if charge_mult > 1.0 and _run_dist >= 6.0:
		d *= charge_mult
	if team == 0:
		d *= battle.army.damage_buff()
	return d


func _deal_damage() -> void:
	if target == null or not _target_alive():
		return
	var to: Vector3 = _target_point() - global_position
	to.y = 0.0
	if to.length() - _target_radius() > attack_range * 1.6 + 0.4:
		return  # target slipped away
	if heal_amount > 0.0:
		target.call("heal", heal_amount)
		return
	if ranged != "":
		Projectile.fire(battle, ranged, team, global_position + Vector3(0.0, 1.5, 0.0), target, damage, splash, projectile_speed, fortress_mult)
		return
	var d: float = damage_against(target)
	if crit_chance > 0.0 and randf() < crit_chance:
		d *= crit_mult
	_run_dist = 0.0
	if aoe_radius > 0.0:
		_smash(d)
		return
	target.call("take_damage", d, global_position)


## The giant's ground smash: hits everything near the target and shoves enemy units back.
func _smash(d: float) -> void:
	var centre: Vector3 = _target_point()
	for n: Node in get_tree().get_nodes_in_group("units_team%d" % (1 - team)):
		var u: Unit = n as Unit
		if u.global_position.distance_to(centre) <= aoe_radius + u.hit_radius:
			u.take_damage(d, global_position)
			if u.is_alive() and not u.is_big:
				var away: Vector3 = u.global_position - global_position
				away.y = 0.0
				if away.length() < 0.01:
					away = Vector3.FORWARD
				var p: Vector3 = u.global_position + away.normalized() * knockback
				p.y = battle.terrain.height_at(p.x, p.z)
				var tw: Tween = u.create_tween()
				tw.tween_property(u, "global_position", p, 0.25).set_ease(Tween.EASE_OUT)
	if team == 1 and battle.hero.is_alive() and battle.hero.global_position.distance_to(centre) <= aoe_radius + 0.6:
		battle.hero.take_damage(d, global_position)
	if target is Fortress:
		pass  # the fortress already took its hit through damage_against below
	var fort: Fortress = battle.enemy_fortress if team == 0 else battle.player_fortress
	if target == fort:
		fort.take_damage(d, global_position)


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
	_run_dist += global_position.distance_to(p)
	global_position = p
	var eff: float = speed * speed_mult
	model.play("run" if eff > 4.5 else "walk", clampf(eff / 3.2, 0.7, 1.4))


# --- AI -----------------------------------------------------------------------------------------------

func _think() -> void:
	if heal_amount > 0.0:
		_think_support()
		_collect_neighbors()
		return
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
	if best != null and best_d <= aggro:
		target = best
	else:
		var fort: Fortress = battle.player_fortress
		target = fort if fort.is_alive() else null
	_collect_neighbors()


## Priests look for the most wounded friend (hero included); otherwise they stay with the army.
func _think_support() -> void:
	var best: Node = null
	var best_missing: float = 0.0
	for n: Node in get_tree().get_nodes_in_group("units_team%d" % team):
		var u: Unit = n as Unit
		var missing: float = u.max_hp - u.hp
		if u != self and missing > best_missing and missing > u.max_hp * 0.08 and _edge_dist(u) <= 18.0:
			best_missing = missing
			best = u
	if team == 0 and battle.hero.is_alive():
		var hm: float = battle.hero.max_hp - battle.hero.hp
		if hm > best_missing and hm > battle.hero.max_hp * 0.08 and _edge_dist(battle.hero) <= 18.0:
			best = battle.hero
	_has_goal = false
	if best != null:
		target = best
		return
	target = null
	if team == 0:
		var o: ArmyManager.Order = battle.army.order
		if o == ArmyManager.Order.HOLD:
			_goal = _hold_point()
		elif o == ArmyManager.Order.FOLLOW:
			_goal = _follow_point()
		elif o == ArmyManager.Order.RETREAT:
			_goal = _retreat_point()
		else:
			_goal = _front_friend_point()
		_has_goal = true
	else:
		_goal = _front_friend_point()
		_has_goal = true


## A point just behind the friendly unit that is furthest toward the enemy (priests trail the army).
func _front_friend_point() -> Vector3:
	var best: Node3D = null
	var best_progress: float = -INF
	for n: Node in get_tree().get_nodes_in_group("units_team%d" % team):
		var u: Unit = n as Unit
		if u == self or u.heal_amount > 0.0:
			continue
		var progress: float = -u.global_position.z if team == 0 else u.global_position.z
		if progress > best_progress:
			best_progress = progress
			best = u
	if best == null:
		return global_position
	var back: Vector3 = Vector3(0.0, 0.0, 2.5 if team == 0 else -2.5)
	return best.global_position + back


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
		if best != null and best_d <= aggro:
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
			engage = best != null and best_d <= maxf(9.0, aggro * 0.6) and (best as Node3D).global_position.distance_to(anchor) <= 16.0 + aggro * 0.4
		ArmyManager.Order.FOLLOW:
			anchor = _follow_point()
			engage = best != null and best_d <= maxf(7.0, aggro * 0.5) and (best as Node3D).global_position.distance_to(battle.hero.global_position) <= 14.0 + aggro * 0.4
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

func _make_hp_bar(height: float) -> void:
	_bar_height = height
	_hp_bar = HpBar3D.new()
	_hp_bar.name = "HpBar"
	_hp_bar.setup(Vector2(1.15, 0.15) * maxf(1.0, height / 2.8), BattlefieldData.COLOR_RED if team == 1 else BattlefieldData.COLOR_GOLD)
	_hp_bar.position = Vector3(0.0, height, 0.0)
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


# --- Hit feedback -------------------------------------------------------------------------------------------

## Sparks on every hit; damage numbers for hits on enemies (friends would be too noisy).
func _hit_fx(dealt: float) -> void:
	var col: Color = Color("ffd24a") if team == 1 else Color("ff8a6a")
	battle.fx.sparks(global_position + Vector3(0.0, 1.1 * float(UnitData.LOOKS[key].scale), 0.0), col, 6)
	if team == 1:
		battle.fx.number(global_position + Vector3(0.0, _bar_height + 0.3, 0.0), dealt, "heavy" if dealt >= 30.0 else "hit")


## Shoves the unit away from `from` (hero skills, giant smash). Big units are too heavy to move.
func knock_away(from: Vector3, distance: float) -> void:
	if state == State.DEAD or is_big or distance <= 0.0:
		return
	var away: Vector3 = global_position - from
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3.FORWARD
	var p: Vector3 = global_position + away.normalized() * distance
	p.y = battle.terrain.height_at(p.x, p.z)
	var tw: Tween = create_tween()
	tw.tween_property(self, "global_position", p, 0.25).set_ease(Tween.EASE_OUT)
