class_name Boss
extends Unit
## A boss warlord: a huge unit with telegraphed special attacks (red ground circles) and a second phase at 50% HP.
## Abilities come from BossData: slam (circle on the hero or army), sweep (ring around the boss),
## meteors (several circles), summon (reinforcements).

signal phase_changed(phase: int)

var boss_name: String = "Boss"
var phase: int = 1

var _def: Dictionary = {}
var _level: int = 1
var _special_cd: float = 4.0
var _last_ability: String = ""


func configure(level: int) -> void:
	_level = level
	_def = BossData.for_level(level)
	boss_name = String(UnitData.STATS[key].name)
	_special_cd = 4.0


func _extra_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if phase == 1 and hp <= max_hp * 0.5:
		_enter_phase_two()
	if busy:
		return
	_special_cd -= delta
	if _special_cd <= 0.0 and target != null and _target_alive() and not (target is Fortress):
		_cast_special()


func _enter_phase_two() -> void:
	phase = 2
	speed *= 1.35
	cooldown *= 0.8
	_special_cd = 1.5
	phase_changed.emit(phase)
	battle.army.message.emit("%s is enraged!" % boss_name)
	battle.fx.shake(0.4, 0.6)
	battle.fx.ring(global_position, 9.0, Color("ff3a2a"), 0.7)
	var tw: Tween = model.create_tween()
	var s: Vector3 = model.scale
	tw.tween_property(model, "scale", s * 1.12, 0.3)
	tw.tween_property(model, "scale", s * 1.06, 0.4)  # stays a little bigger


func _cast_special() -> void:
	var list: Array = _def.phase1 if phase == 1 else _def.phase2
	var ability: String = String(list[randi() % list.size()])
	if ability == _last_ability and list.size() > 1:
		ability = String(list[(list.find(ability) + 1) % list.size()])
	_last_ability = ability
	_special_cd = float(_def.cooldown if phase == 1 else _def.cooldown2)
	match ability:
		"slam":
			_do_slam()
		"sweep":
			_do_sweep()
		"meteors":
			_do_meteors()
		"summon":
			_do_summon()


func _hold(seconds: float) -> void:
	busy = true
	get_tree().create_timer(seconds).timeout.connect(func() -> void: busy = false)


## Plays the swing animation so that its hit lands exactly when the red circle completes.
func _swing_at(delay: float) -> void:
	var lead: float = 0.52  # the attack3 animation strikes 0.52 s after it starts
	get_tree().create_timer(maxf(delay - lead, 0.0)).timeout.connect(func() -> void:
		if state != State.DEAD:
			model.play(_attack_anim, 1.0, true))


func _do_slam() -> void:
	var at: Vector3 = global_position
	if battle.hero.is_alive() and battle.hero.global_position.distance_to(global_position) < 32.0:
		at = battle.hero.global_position
	elif target != null and _target_alive():
		at = (target as Node3D).global_position
	at.y = 0.0
	var radius: float = float(_def.slam_radius)
	var delay: float = 1.3
	battle.fx.telegraph(at, radius, delay)
	_face(at)
	_swing_at(delay)
	_hold(delay + 0.7)
	get_tree().create_timer(delay).timeout.connect(func() -> void: _blast(at, radius, damage * 1.5, 4.0))


func _do_sweep() -> void:
	var radius: float = float(_def.sweep_radius)
	var delay: float = 1.4
	var at: Vector3 = global_position
	battle.fx.telegraph(at, radius, delay)
	_swing_at(delay)
	_hold(delay + 0.7)
	get_tree().create_timer(delay).timeout.connect(func() -> void: _blast(at, radius, damage * 1.1, 5.5))


func _do_meteors() -> void:
	var count: int = int(_def.meteors)
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
		s.y = 0.0
		battle.fx.telegraph(s, 3.0, delay)
		get_tree().create_timer(delay).timeout.connect(func() -> void: _blast(s, 3.0, damage * 0.9, 3.0))
	model.play("cry", 1.0, true)
	_hold(delay + 0.6)


func _do_summon() -> void:
	model.play("cry", 1.0, true)
	battle.fx.ring(global_position, 6.0, Color("b86bd6"), 0.9)
	_hold(1.3)
	var pool: Array[String] = LevelData.pool(_level)
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		if state == State.DEAD:
			return
		for i: int in int(_def.summons):
			var unit_key: String = pool[randi() % mini(pool.size(), 4)]
			var u: Unit = battle.spawn_unit(unit_key, 1, 0.0)
			var a: float = float(i) / float(_def.summons) * TAU
			u.global_position = global_position + Vector3(sin(a) * 5.5, 0.0, cos(a) * 5.5)
			u.global_position.y = battle.terrain.height_at(u.global_position.x, u.global_position.z)
			battle.fx.sparks(u.global_position + Vector3(0.0, 1.0, 0.0), Color("b86bd6"), 10))


## The blow itself: hurts the hero and every player unit inside the circle.
func _blast(at: Vector3, radius: float, dmg: float, push: float) -> void:
	if state == State.DEAD:
		return
	battle.fx.ring(at, radius, Color("ff4a2a"), 0.4)
	battle.fx.sparks(at + Vector3(0.0, 0.5, 0.0), Color("ff7a3a"), 16)
	battle.fx.shake(0.22, 0.4)
	for n: Node in get_tree().get_nodes_in_group("units_team0"):
		var u: Unit = n as Unit
		if Vector3(u.global_position.x, 0.0, u.global_position.z).distance_to(at) <= radius + u.hit_radius:
			u.take_damage(dmg, global_position)
			u.knock_away(at, push)
	var h: Hero = battle.hero
	if h.is_alive() and Vector3(h.global_position.x, 0.0, h.global_position.z).distance_to(at) <= radius + 0.45:
		h.take_damage(dmg, global_position)


func _face(p: Vector3) -> void:
	var to: Vector3 = p - global_position
	to.y = 0.0
	if to.length() > 0.1:
		rotation.y = atan2(-to.x, -to.z)
