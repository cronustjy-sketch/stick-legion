class_name Projectile
extends Node3D
## Arrows, fireballs and boulders. They fly on an arc to where the target is, then apply their effect:
## arrows hit one target (a frontal shield blocks them), fireballs and boulders splash everything near the impact.

static var _meshes: Dictionary = {}
static var _mats: Dictionary = {}

var kind: String = "arrow"
var team: int = 0
var damage: float = 10.0
var splash: float = 0.0
var fortress_mult: float = 1.0
var target: Node
var start: Vector3
var end: Vector3
var duration: float = 1.0
var arc: float = 2.0
var shooter_pos: Vector3

var _t: float = 0.0
var _last: Vector3


## Fires a projectile from `from` at `at` (a Unit, Hero or Fortress).
static func fire(parent: Node, kind_name: String, team_id: int, from: Vector3, at: Node, dmg: float, splash_radius: float,
		speed: float, f_mult: float = 1.0) -> Projectile:
	var p: Projectile = Projectile.new()
	p.kind = kind_name
	p.team = team_id
	p.damage = dmg
	p.splash = splash_radius
	p.fortress_mult = f_mult
	p.target = at
	p.start = from
	p.shooter_pos = from
	p.end = aim_point(at, from)
	var dist: float = from.distance_to(p.end)
	p.duration = maxf(dist / speed, 0.15)
	p.arc = clampf(dist * (0.22 if kind_name == "arrow" else 0.3), 0.6, 9.0)
	parent.add_child(p)
	p.add_to_group("projectiles")
	p.global_position = from
	p._last = from
	p._make_visual()
	return p


static func aim_point(n: Node, from: Vector3) -> Vector3:
	if n is Fortress:
		return (n.call("nearest_point", from) as Vector3) + Vector3(0.0, 2.2, 0.0)
	return (n as Node3D).global_position + Vector3(0.0, 1.1, 0.0)


func _physics_process(delta: float) -> void:
	_t += delta / duration
	if is_instance_valid(target) and bool(target.call("is_alive")):
		end = aim_point(target, shooter_pos)
	var k: float = minf(_t, 1.0)
	var pos: Vector3 = start.lerp(end, k) + Vector3.UP * arc * 4.0 * k * (1.0 - k)
	global_position = pos
	if pos.distance_squared_to(_last) > 0.0004:
		look_at(pos + (pos - _last), Vector3.UP)
	_last = pos
	if _t >= 1.0:
		_impact()


func _impact() -> void:
	set_physics_process(false)
	if splash > 0.0:
		Sfx.play("explosion" if kind == "fireball" else "boulder", -3.0, end)
		_splash_damage()
	elif is_instance_valid(target) and bool(target.call("is_alive")):
		if not _blocked_by_shield():  # a shield knight facing the shooter takes no damage
			target.call("take_damage", damage, shooter_pos)
	queue_free()


func _blocked_by_shield() -> bool:
	if not (target is Unit):
		return false
	var u: Unit = target
	if not u.blocks_arrows:
		return false
	var to: Vector3 = shooter_pos - u.global_position
	to.y = 0.0
	if to.length() < 0.1:
		return true
	var forward: Vector3 = Vector3(-sin(u.rotation.y), 0.0, -cos(u.rotation.y))
	return forward.dot(to.normalized()) > cos(deg_to_rad(65.0))


func _splash_damage() -> void:
	var centre: Vector3 = Vector3(end.x, 0.0, end.z)
	for n: Node in get_tree().get_nodes_in_group("units_team%d" % (1 - team)):
		var u: Node3D = n as Node3D
		if Vector3(u.global_position.x, 0.0, u.global_position.z).distance_to(centre) <= splash + float(n.get("hit_radius")):
			n.call("take_damage", damage, shooter_pos)
	var battle: Battle = get_tree().current_scene as Battle
	if battle == null:
		return
	if team == 1 and battle.hero.is_alive():
		if Vector3(battle.hero.global_position.x, 0.0, battle.hero.global_position.z).distance_to(centre) <= splash + 0.45:
			battle.hero.take_damage(damage, shooter_pos)
	var fort: Fortress = battle.enemy_fortress if team == 0 else battle.player_fortress
	if fort.is_alive():
		var np: Vector3 = fort.nearest_point(centre)
		if Vector3(np.x, 0.0, np.z).distance_to(centre) <= splash:
			fort.take_damage(damage * fortress_mult)


func _make_visual() -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not _meshes.has(kind):
		match kind:
			"arrow":
				var c: CylinderMesh = CylinderMesh.new()
				c.top_radius = 0.025
				c.bottom_radius = 0.025
				c.height = 1.0
				c.radial_segments = 4
				c.rings = 1
				_meshes[kind] = c
			"fireball":
				var s: SphereMesh = SphereMesh.new()
				s.radius = 0.3
				s.height = 0.6
				s.radial_segments = 8
				s.rings = 4
				_meshes[kind] = s
			_:
				var b: SphereMesh = SphereMesh.new()
				b.radius = 0.55
				b.height = 1.0
				b.radial_segments = 6
				b.rings = 3
				_meshes[kind] = b
	var key: String = "%s%d" % [kind, team]
	if not _mats.has(key):
		var m: StandardMaterial3D = StandardMaterial3D.new()
		match kind:
			"arrow":
				m.albedo_color = Color("d9c9a0")
			"fireball":
				m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				m.albedo_color = Color("ffd24a") if team == 0 else Color("ff5a3a")
			_:
				m.albedo_color = Color("7a7a7e")
				m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		_mats[key] = m
	mi.mesh = _meshes[kind]
	mi.material_override = _mats[key]
	if kind == "arrow":
		mi.rotation_degrees.x = 90.0  # cylinder axis Y -> flight direction -Z
	add_child(mi)
