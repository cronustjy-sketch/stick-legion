class_name Boss
extends Unit
## A boss unit with telegraphed special attacks (red ground markers that fill before the blow lands) and phases.
## Everything about a boss - name, lines, phases, abilities - comes from BossData; see STORY.md for the characters.
## Abilities: slam, sweep, meteors, summon, charge, spin, dash, flurry, combo, guards.

signal phase_changed(phase: int)

var boss_name: String = "Boss"
var phase: int = 1

var def: Dictionary = {}
var _level: int = 1
var _special_cd: float = 4.0
var _last_ability: String = ""
var _base_speed: float = 1.0
var _base_cooldown: float = 1.0
var _guards: Array[Unit] = []


func configure(level: int, boss_def: Dictionary) -> void:
	_level = level
	def = boss_def
	boss_name = String(UnitData.STATS[key].name)
	_base_speed = speed
	_base_cooldown = cooldown
	_special_cd = 3.5
	_apply_phase_stats()


func _apply_phase_stats() -> void:
	var mults: Array = def.speed_mult
	speed = _base_speed * float(mults[mini(phase - 1, mults.size() - 1)])
	cooldown = _base_cooldown * pow(0.88, float(phase - 1))
	_anim_speed = maxf(_anim_speed, 1.0)


func _extra_process(delta: float) -> void:
	if state == State.DEAD:
		return
	var thresholds: Array = def.thresholds
	if phase <= thresholds.size() and hp <= max_hp * float(thresholds[phase - 1]):
		enter_phase(phase + 1)
	if busy:
		return
	_special_cd -= delta
	if _special_cd <= 0.0 and target != null and _target_alive() and not (target is Fortress):
		_cast_special()


## Moves the boss into phase `n` (also used when a linked partner falls: the twins enrage).
func enter_phase(n: int) -> void:
	if n <= phase or state == State.DEAD:
		return
	phase = n
	_apply_phase_stats()
	_special_cd = 1.2
	phase_changed.emit(phase)
	battle.fx.shake(0.4, 0.6)
	battle.fx.ring(global_position, 9.0, Color("ff3a2a"), 0.7)
	var tw: Tween = model.create_tween()
	var s: Vector3 = model.scale
	tw.tween_property(model, "scale", s * 1.1, 0.3)
	tw.tween_property(model, "scale", s * 1.05, 0.4)
	var lines: Dictionary = def.get("phase_lines", {})
	if lines.has(phase):
		battle.banner(boss_name, String(lines[phase]))
	else:
		battle.army.message.emit("%s is enraged!" % boss_name)
	if String(def.id) == "corvin":
		if phase == 2:
			_do_guards()
		elif phase == 3:
			_dismiss_guards()
	if int(def.get("red_sky_phase", 0)) == phase:
		SkySetup.set_red_sky(battle, true)


func _abilities() -> Array:
	var all: Array = def.abilities
	return all[mini(phase - 1, all.size() - 1)]


func _cast_special() -> void:
	var list: Array = _abilities()
	var ability: String = String(list[randi() % list.size()])
	if ability == _last_ability and list.size() > 1:
		ability = String(list[(list.find(ability) + 1) % list.size()])
	_last_ability = ability
	var cds: Array = def.cooldowns
	_special_cd = float(cds[mini(phase - 1, cds.size() - 1)])
	match ability:
		"slam":
			_do_slam()
		"sweep":
			_do_sweep()
		"spin":
			_do_spin()
		"meteors":
			_do_meteors()
		"summon":
			_do_summon()
		"charge":
			_do_charge(float(def.get("charge_width", 4.0)), float(def.get("charge_length", 22.0)), 1.2, 1.5)
		"dash":
			_do_charge(float(def.get("dash_width", 2.6)), float(def.get("dash_length", 12.0)), 0.7, 1.0)
		"flurry":
			_do_flurry()
		"combo":
			_do_combo()
		"guards":
			_do_guards()


# --- Helpers ------------------------------------------------------------------------------------------

func _after(seconds: float, action: Callable) -> void:
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if state != State.DEAD:
			action.call())


func _hold(seconds: float) -> void:
	busy = true
	get_tree().create_timer(seconds).timeout.connect(func() -> void: busy = false)


## Plays the swing animation so that its hit lands exactly when the red marker completes.
func _swing_at(delay: float, anim: StringName = &"") -> void:
	var a: StringName = _attack_anim if anim == &"" else anim
	var lead: float = 0.52 if a == &"attack3" else 0.34
	_after(maxf(delay - lead, 0.0), func() -> void: model.play(a, 1.0, true))


func _face(p: Vector3) -> void:
	var to: Vector3 = p - global_position
	to.y = 0.0
	if to.length() > 0.1:
		rotation.y = atan2(-to.x, -to.z)


func _focus_point() -> Vector3:
	var at: Vector3 = global_position
	if battle.hero.is_alive() and battle.hero.global_position.distance_to(global_position) < 34.0:
		at = battle.hero.global_position
	elif target != null and _target_alive():
		at = (target as Node3D).global_position
	at.y = 0.0
	return at


## The blow: hurts the hero and every player unit inside the circle.
func _blast(at: Vector3, radius: float, dmg: float, push: float) -> void:
	if state == State.DEAD:
		return
	battle.fx.ring(at, radius, Color("ff4a2a"), 0.4)
	battle.fx.sparks(at + Vector3(0.0, 0.5, 0.0), Color("ff7a3a"), 16)
	battle.fx.shake(0.2, 0.35)
	for n: Node in get_tree().get_nodes_in_group("units_team0"):
		var u: Unit = n as Unit
		if Vector3(u.global_position.x, 0.0, u.global_position.z).distance_to(at) <= radius + u.hit_radius:
			u.take_damage(dmg, global_position)
			u.knock_away(at, push)
	var h: Hero = battle.hero
	if h.is_alive() and Vector3(h.global_position.x, 0.0, h.global_position.z).distance_to(at) <= radius + 0.45:
		h.take_damage(dmg, global_position)


func _blast_line(a: Vector3, b: Vector3, width: float, dmg: float) -> void:
	if state == State.DEAD:
		return
	battle.fx.shake(0.25, 0.35)
	for n: Node in get_tree().get_nodes_in_group("units_team0"):
		var u: Unit = n as Unit
		if _seg_dist(u.global_position, a, b) <= width * 0.5 + u.hit_radius:
			u.take_damage(dmg, global_position)
			u.knock_away(a.lerp(b, 0.5), 3.0)
			battle.fx.sparks(u.global_position + Vector3(0.0, 1.0, 0.0), Color("ff7a3a"), 8)
	var h: Hero = battle.hero
	if h.is_alive() and _seg_dist(h.global_position, a, b) <= width * 0.5 + 0.45:
		h.take_damage(dmg, global_position)


func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var pa: Vector2 = Vector2(p.x, p.z)
	var aa: Vector2 = Vector2(a.x, a.z)
	var ba: Vector2 = Vector2(b.x, b.z) - aa
	var t: float = clampf((pa - aa).dot(ba) / maxf(ba.length_squared(), 0.0001), 0.0, 1.0)
	return pa.distance_to(aa + ba * t)


func _ground(p: Vector3) -> Vector3:
	p.x = clampf(p.x, -(BattlefieldData.VALLEY_HALF_WIDTH + 3.0), BattlefieldData.VALLEY_HALF_WIDTH + 3.0)
	p.z = clampf(p.z, -(BattlefieldData.FORTRESS_Z + 8.0), BattlefieldData.FORTRESS_Z + 8.0)
	p.y = battle.terrain.height_at(p.x, p.z)
	return p


# --- Abilities ----------------------------------------------------------------------------------------

func _do_slam() -> void:
	var at: Vector3 = _focus_point()
	var radius: float = float(def.get("slam_radius", 4.5))
	var delay: float = 1.3
	battle.fx.telegraph(at, radius, delay)
	_face(at)
	_swing_at(delay)
	_hold(delay + 0.7)
	_after(delay, func() -> void: _blast(at, radius, damage * 1.5, 4.0))


func _do_sweep() -> void:
	var radius: float = float(def.get("sweep_radius", 7.5))
	var delay: float = 1.4
	var at: Vector3 = global_position
	battle.fx.telegraph(at, radius, delay)
	_swing_at(delay)
	_hold(delay + 0.7)
	_after(delay, func() -> void: _blast(at, radius, damage * 1.1, 5.5))


## Grask's whirling cleavers: a ring around him, and he spins while it fills.
func _do_spin() -> void:
	var radius: float = float(def.get("spin_radius", 6.5))
	var delay: float = 1.3
	var at: Vector3 = global_position
	battle.fx.telegraph(at, radius, delay)
	_after(delay - 0.35, func() -> void: model.play("spin", 1.0, true))
	_hold(delay + 0.8)
	_after(delay, func() -> void: _blast(at, radius, damage * 1.2, 5.0))
	_after(delay + 0.45, func() -> void: _blast(at, radius, damage * 0.8, 3.0))


## A straight-line rush (Grask's charge, the twins' dash): a red corridor, then he crosses it in a blink.
func _do_charge(width: float, length: float, delay: float, dmg_mult: float) -> void:
	var at: Vector3 = _focus_point()
	var from: Vector3 = global_position
	var dir: Vector3 = at - from
	dir.y = 0.0
	if dir.length() < 1.0:
		dir = Vector3(0.0, 0.0, 1.0 if team == 1 else -1.0)
	dir = dir.normalized()
	var reach: float = minf(maxf((at - from).length() + 3.0, 8.0), length)
	var to: Vector3 = _ground(from + dir * reach)
	_face(to)
	battle.fx.telegraph_line(from, to, width, delay)
	_hold(delay + 0.9)
	_after(delay, func() -> void:
		model.play("dash", 1.0, true)
		var tw: Tween = create_tween()
		tw.tween_property(self, "global_position", to, 0.35).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			if state != State.DEAD:
				_blast_line(from, to, width, damage * dmg_mult)
				battle.fx.ring(to, width * 1.2, Color("ff4a2a"), 0.35)))


## Three quick strikes on the hero (the twins' flurry): they hop in close, then red circles snap shut one by one.
func _do_flurry() -> void:
	var at: Vector3 = _focus_point()
	var to_target: Vector3 = at - global_position
	to_target.y = 0.0
	if to_target.length() > 4.0:
		var near: Vector3 = _ground(at - to_target.normalized() * 3.2)
		var hop: Tween = create_tween()
		hop.tween_property(self, "global_position", near, 0.35).set_ease(Tween.EASE_OUT)
	_face(at)
	_hold(2.2)
	for i: int in 3:
		var spot: Vector3 = at + Vector3(randf_range(-1.8, 1.8), 0.0, randf_range(-1.8, 1.8)) * float(i > 0)
		var delay: float = 0.8 + 0.4 * float(i)
		_after(0.35, func() -> void: battle.fx.telegraph(spot, 2.3, delay - 0.35))
		_swing_at(delay, &"attack")
		_after(delay, func() -> void: _blast(spot, 2.3, damage * 1.3, 2.0))


## Corvin's greatsword combo: three strikes marching out in front of him.
func _do_combo() -> void:
	var at: Vector3 = _focus_point()
	_face(at)
	var dir: Vector3 = Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	_hold(2.4)
	for i: int in 3:
		var spot: Vector3 = _ground(global_position + dir * (3.6 + 2.6 * float(i)))
		var delay: float = 0.9 + 0.4 * float(i)
		battle.fx.telegraph(spot, 3.2, delay)
		_swing_at(delay)
		_after(delay, func() -> void: _blast(spot, 3.2, damage * 1.2, 3.5))


func _do_meteors() -> void:
	var count: int = int(def.get("meteors", 6))
	var delay: float = 1.8
	var spots: Array[Vector3] = []
	var anchor: Vector3 = battle.hero.global_position if battle.hero.is_alive() else global_position
	spots.append(anchor)
	var friends: Array = get_tree().get_nodes_in_group("units_team0")
	for i: int in count - 1:
		if not friends.is_empty() and randf() < 0.7:
			spots.append((friends[randi() % friends.size()] as Node3D).global_position)
		else:
			spots.append(anchor + Vector3(randf_range(-9.0, 9.0), 0.0, randf_range(-9.0, 9.0)))
	for s: Vector3 in spots:
		var spot: Vector3 = Vector3(s.x, 0.0, s.z)
		battle.fx.telegraph(spot, 3.0, delay)
		_after(delay, func() -> void: _blast(spot, 3.0, damage * 0.8, 3.0))
	model.play("cry", 1.0, true)
	_hold(delay + 0.6)


func _do_summon() -> void:
	model.play("cry", 1.0, true)
	battle.fx.ring(global_position, 6.0, Color("b86bd6"), 0.9)
	_hold(1.3)
	var info: Dictionary = def.get("summon", {})
	var count: int = int(info.get("count", 3))
	var pool: Array[String] = LevelData.pool(_level)
	_after(1.0, func() -> void:
		for i: int in count:
			var unit_key: String = String(info.get("key", pool[randi() % mini(pool.size(), 4)]))
			var u: Unit = battle.spawn_unit(unit_key, 1, 0.0)
			var a: float = float(i) / float(count) * TAU
			u.global_position = _ground(global_position + Vector3(sin(a) * 6.0, 0.0, cos(a) * 6.0))
			battle.fx.sparks(u.global_position + Vector3(0.0, 1.0, 0.0), Color("b86bd6"), 10))


## Corvin's ring of red elite guards (shield knights, stronger than normal).
func _do_guards() -> void:
	model.play("cry", 1.0, true)
	battle.fx.ring(global_position, 8.0, Color("ff3a2a"), 1.0)
	_hold(1.3)
	var info: Dictionary = def.get("guards", {"count": 6, "strength": 1.6})
	_after(1.0, func() -> void:
		for i: int in int(info.count):
			var u: Unit = battle.spawn_unit("shield_knight", 1, 0.0)
			var s: float = float(info.strength)
			u.max_hp *= s
			u.hp = u.max_hp
			u.damage *= s
			var a: float = float(i) / float(info.count) * TAU
			u.global_position = _ground(global_position + Vector3(sin(a) * 6.5, 0.0, cos(a) * 6.5))
			battle.fx.sparks(u.global_position + Vector3(0.0, 1.0, 0.0), Color("ff3a2a"), 10)
			_guards.append(u))


## Phase 3: Corvin fights alone - the guards fall away.
func _dismiss_guards() -> void:
	for u: Unit in _guards:
		if is_instance_valid(u) and u.is_alive():
			battle.fx.sparks(u.global_position + Vector3(0.0, 1.0, 0.0), Color("ff3a2a"), 12)
			u.take_damage(99999.0)
	_guards.clear()
