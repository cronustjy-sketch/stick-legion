class_name HeroSkills
extends Node
## The hero's four skills (Q E R F) and the rage-powered ultimate (G). Data lives in HeroData.SKILLS.
## While a skill plays the hero is in State.SKILL and this node drives movement, hits and effects.

signal rage_changed(rage: float, maximum: float)
signal skill_cast(id: String)

var hero: Hero
var rage: float = 0.0
var active: String = ""

var _cd: Dictionary = {}  # id -> seconds left
var _t: float = 0.0
var _hit_index: int = 0
var _dir: Vector3 = Vector3.FORWARD


func _process(delta: float) -> void:
	for id: String in _cd:
		_cd[id] = maxf(float(_cd[id]) - delta, 0.0)


func rage_max() -> float:
	return float(HeroData.RAGE.max)


func add_rage(amount: float) -> void:
	rage = clampf(rage + amount, 0.0, rage_max())
	rage_changed.emit(rage, rage_max())


func is_ready(id: String) -> bool:
	if bool(HeroData.SKILLS[id].get("ultimate", false)):
		return rage >= rage_max()
	return float(_cd.get(id, 0.0)) <= 0.0


## 0 = ready, 1 = just used (for the HUD cooldown overlay).
func cooldown_fraction(id: String) -> float:
	var cd: float = float(HeroData.SKILLS[id].cooldown)
	if cd <= 0.0:
		return 0.0
	return clampf(float(_cd.get(id, 0.0)) / cd, 0.0, 1.0)


func cooldown_left(id: String) -> float:
	return float(_cd.get(id, 0.0))


## Looks for a skill key press and casts it. Returns true if a skill started.
func poll(move_dir: Vector3) -> bool:
	for id: String in HeroData.SKILLS:
		var def: Dictionary = HeroData.SKILLS[id]
		if Input.is_action_just_pressed(String(def.action)) and is_ready(id):
			cast(id, move_dir)
			return true
	return false


func cast(id: String, move_dir: Vector3) -> void:
	var def: Dictionary = HeroData.SKILLS[id]
	hero.state = Hero.State.SKILL
	active = id
	_t = 0.0
	_hit_index = 0
	if bool(def.get("ultimate", false)):
		rage = 0.0
		rage_changed.emit(rage, rage_max())
	else:
		_cd[id] = float(def.cooldown)
	if def.has("dash"):
		_dir = move_dir.normalized() if move_dir.length() > 0.1 else hero.forward_vector()
		hero.rotation.y = atan2(-_dir.x, -_dir.z)
	else:
		hero.assist_aim()
		_dir = hero.forward_vector()
	hero.model.play(StringName(def.anim), 1.0, true)
	Sfx.play({"q": "swing_big", "e": "whoosh_big", "r": "horn", "f": "whoosh_big", "g": "horn"}[id], -3.0)
	skill_cast.emit(id)


## Called every physics frame while the hero is in State.SKILL.
func update(delta: float) -> void:
	var def: Dictionary = HeroData.SKILLS[active]
	_t += delta
	hero.invincible = _t < float(def.get("invincible", 0.0))
	if def.has("dash") and _t < float(def.dash_time):
		hero.velocity = _dir * float(def.dash)
	else:
		hero.velocity = hero.velocity.move_toward(Vector3.ZERO, 30.0 * delta)
	var hits: Array = def.hits
	while _hit_index < hits.size() and _t >= float(hits[_hit_index]):
		_hit_index += 1
		_apply(def)
	if _t >= float(def.length):
		hero.state = Hero.State.FREE
		active = ""


func _apply(def: Dictionary) -> void:
	var battle: Battle = hero.battle
	var centre: Vector3 = hero.global_position + hero.forward_vector() * float(def.get("forward", 0.0))
	var gold: Color = Color("ffd24a")
	if float(def.get("damage", 0.0)) > 0.0:
		var radius: float = float(def.radius)
		var dmg: float = float(def.damage)
		for n: Node in hero.get_tree().get_nodes_in_group("hittable_enemy"):
			if not n.call("is_alive"):
				continue
			var p: Vector3 = n.call("nearest_point", centre)
			var flat: Vector3 = p - centre
			flat.y = 0.0
			if flat.length() - float(n.get("hit_radius")) > radius:
				continue
			n.call("take_damage", dmg, hero.global_position)
			add_rage(dmg * float(HeroData.RAGE.per_damage_dealt))
			if n is Unit:
				(n as Unit).knock_away(hero.global_position, float(def.get("knockback", 0.0)))
		Sfx.play("boom" if radius >= 5.0 else "hit", -3.0)
		if battle != null:
			battle.fx.ring(centre, radius, gold, 0.45)
			battle.fx.sparks(centre + Vector3(0.0, 0.6, 0.0), gold, 14)
	if float(def.get("heal_self", 0.0)) > 0.0:
		hero.heal(float(def.heal_self))
	if float(def.get("heal_allies", 0.0)) > 0.0 and battle != null:
		var hr: float = float(def.heal_radius)
		for n: Node in hero.get_tree().get_nodes_in_group("units_team0"):
			if (n as Node3D).global_position.distance_to(hero.global_position) <= hr:
				(n as Unit).heal(float(def.heal_allies))
		battle.fx.ring(hero.global_position, float(def.get("ring", hr)), Color("6fe08a"), 0.7)
	if float(def.get("buff", 0.0)) > 0.0 and battle != null:
		battle.army.apply_buff(float(def.buff), float(def.buff_time))
		battle.army.message.emit(Loc.t("%s! Army damage +%d%% for %ds") % [Loc.t(def.name), roundi((float(def.buff) - 1.0) * 100.0), int(def.buff_time)])
	if battle != null:
		battle.fx.shake(float(def.get("shake", 0.1)), 0.35)


## Casts a skill from a button press (HUD slot tapped / clicked) if the hero is able to.
func try_cast(id: String) -> bool:
	var h: Hero = hero
	var ok_state: bool = h.state == Hero.State.FREE or h.state == Hero.State.BLOCK or (h.state == Hero.State.ATTACK and h._struck)
	if not ok_state or not is_ready(id) or (h.camera != null and h.camera.tactical):
		return false
	cast(id, Vector3.ZERO)
	return true
