class_name Fortress
extends Node3D
## A team fortress: stone walls, corner towers, a keep, a banner and an HP bar.
## Front of the fortress faces local -Z; the enemy fortress is rotated by PI.

signal hp_changed(current: float, maximum: float)
signal destroyed(team: int)
signal shield_blocked

enum Team { PLAYER, ENEMY }

@export var team: Team = Team.PLAYER

var max_hp: float = BattlefieldData.FORTRESS.max_hp
var hp: float = max_hp
var shielded: bool = false  # enemy fortress is shielded while a boss lives
var hit_radius: float = 0.0  # part of the "hittable_enemy" interface the hero uses

var _hp_bar: HpBar3D
var _stone: StandardMaterial3D
var _trim: StandardMaterial3D
var _cloth: StandardMaterial3D
var _dark: StandardMaterial3D


func _ready() -> void:
	if team == Team.ENEMY:
		add_to_group("hittable_enemy")
	_make_materials()
	_build()
	_hp_bar.set_fill(1.0)


func take_damage(amount: float, _from: Vector3 = Vector3.ZERO) -> void:
	if hp <= 0.0:
		return
	if shielded:
		shield_blocked.emit()
		_sound("zap", -6.0, 0.5)
		return
	_sound("crack", -8.0, 0.35)
	hp = maxf(hp - amount, 0.0)
	_hp_bar.set_fill(hp / max_hp)
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		Sfx.play("explosion", 0.0)
		Sfx.play("boom", 0.0)
		destroyed.emit(team)


func _make_materials() -> void:
	var gold_team: bool = team == Team.PLAYER
	_stone = _toon(BattlefieldData.COLOR_STONE)
	_trim = _toon(BattlefieldData.COLOR_STEEL if gold_team else BattlefieldData.COLOR_IRON)
	_cloth = _toon(BattlefieldData.COLOR_GOLD if gold_team else BattlefieldData.COLOR_RED)
	_dark = _toon(BattlefieldData.COLOR_IRON)


func _toon(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


func _build() -> void:
	var f: Dictionary = BattlefieldData.FORTRESS
	var w: float = f.width
	var d: float = f.depth
	var wh: float = f.wall_height
	var th: float = f.tower_height
	var gate_w: float = 4.5

	# Front wall: two segments with a gate gap between them.
	var seg_w: float = (w - gate_w) * 0.5
	for sx: float in [-1.0, 1.0]:
		var cx: float = sx * (gate_w * 0.5 + seg_w * 0.5)
		_box(Vector3(seg_w, wh, 1.4), Vector3(cx, wh * 0.5, -d * 0.5), _stone)
		_crenels(seg_w, Vector3(cx, wh, -d * 0.5))
	# Gate lintel and dark gate interior.
	_box(Vector3(gate_w + 1.0, 1.4, 1.6), Vector3(0, wh - 0.7, -d * 0.5), _trim)
	_box(Vector3(gate_w, wh - 1.4, 0.4), Vector3(0, (wh - 1.4) * 0.5, -d * 0.5 + 0.5), _dark)
	# Side and back walls.
	for sx: float in [-1.0, 1.0]:
		_box(Vector3(1.4, wh, d), Vector3(sx * w * 0.5, wh * 0.5, 0), _stone)
	_box(Vector3(w, wh, 1.4), Vector3(0, wh * 0.5, d * 0.5), _stone)
	# Corner towers with conical roofs in the team colour.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_tower(Vector3(sx * w * 0.5, 0, sz * d * 0.5), th)
	# Central keep and banner.
	var kh: float = f.keep_height
	_box(Vector3(7.0, kh, 5.0), Vector3(0, kh * 0.5, d * 0.15), _stone)
	_crenels(7.0, Vector3(0, kh, d * 0.15 - 2.3))
	_box(Vector3(7.6, 0.6, 5.6), Vector3(0, kh, d * 0.15), _trim)
	var pole: MeshInstance3D = _cyl(0.12, 0.12, 6.0, Vector3(0, kh + 3.0, d * 0.15), _dark, 6)
	pole.name = "BannerPole"
	_box(Vector3(0.1, 2.4, 3.2), Vector3(0, kh + 4.6, d * 0.15 - 1.7), _cloth)
	# Cloth strip above the gate.
	_box(Vector3(gate_w + 1.0, 1.2, 0.2), Vector3(0, wh + 0.9, -d * 0.5 - 0.8), _cloth)

	# Collision footprint (for units and projectiles later).
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = 2
	var cs: CollisionShape3D = CollisionShape3D.new()
	var bs: BoxShape3D = BoxShape3D.new()
	bs.size = Vector3(w + 2.0, kh, d + 2.0)
	cs.shape = bs
	cs.position.y = kh * 0.5
	body.add_child(cs)
	add_child(body)

	var shadow: BlobShadow = BlobShadow.make(Vector2(w + 12.0, d + 12.0))
	add_child(shadow)

	# HP bar and name label.
	_hp_bar = HpBar3D.new()
	_hp_bar.name = "HpBar"
	_hp_bar.setup(Vector2(12.0, 1.1), BattlefieldData.COLOR_GOLD if team == Team.PLAYER else BattlefieldData.COLOR_RED)
	_hp_bar.position = Vector3(0, kh + 7.0, 0)
	add_child(_hp_bar)
	var label: Label3D = Label3D.new()
	label.text = "Player Fortress" if team == Team.PLAYER else "Enemy Fortress"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.fixed_size = true  # same on-screen size for both fortresses at any distance
	label.font_size = 40
	label.pixel_size = 0.0009
	label.outline_size = 12
	label.no_depth_test = true
	label.offset = Vector2(0, 34)  # pixels above the HP bar
	label.modulate = BattlefieldData.COLOR_GOLD if team == Team.PLAYER else BattlefieldData.COLOR_RED
	label.position = Vector3(0, kh + 8.3, 0)
	add_child(label)


func _tower(base: Vector3, h: float) -> void:
	_cyl(1.9, 2.1, h, base + Vector3(0, h * 0.5, 0), _stone, 8)
	_cyl(2.4, 2.4, 0.6, base + Vector3(0, h, 0), _trim, 8)
	var roof: MeshInstance3D = _cyl(0.0, 2.6, 3.2, base + Vector3(0, h + 2.2, 0), _cloth, 8)
	roof.name = "Roof"


func _crenels(width: float, at: Vector3) -> void:
	var n: int = int(width / 1.4)
	for i: int in n:
		var x: float = at.x - width * 0.5 + (i + 0.5) * (width / n)
		if i % 2 == 0:
			_box(Vector3(width / n * 0.8, 0.7, 1.0), Vector3(x, at.y + 0.35, at.z), _stone)


func _box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var m: BoxMesh = BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _cyl(top: float, bottom: float, h: float, pos: Vector3, mat: Material, sides: int) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var m: CylinderMesh = CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = sides
	m.rings = 1
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func is_alive() -> bool:
	return hp > 0.0


## Closest point of the fortress footprint to `from` (world space), so melee reach is measured to the walls.
func nearest_point(from: Vector3) -> Vector3:
	var f: Dictionary = BattlefieldData.FORTRESS
	var local: Vector3 = global_transform.affine_inverse() * from
	var hx: float = float(f.width) * 0.5 + 0.7
	var hz: float = float(f.depth) * 0.5 + 0.7
	var clamped: Vector3 = Vector3(clampf(local.x, -hx, hx), 0.0, clampf(local.z, -hz, hz))
	return global_transform * clamped


var _shield: MeshInstance3D


## Boss levels: the enemy fortress is protected by a glowing dome until the boss falls.
func set_shield(on: bool) -> void:
	shielded = on
	if on and _shield == null:
		_shield = MeshInstance3D.new()
		_shield.name = "Shield"
		var s: SphereMesh = SphereMesh.new()
		s.radius = 1.0
		s.height = 2.0
		s.radial_segments = 20
		s.rings = 10
		_shield.mesh = s
		var m: StandardMaterial3D = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.35, 0.6, 1.0, 0.22)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_shield.material_override = m
		_shield.scale = Vector3(15.0, 10.5, 12.0)
		_shield.position.y = 2.0
		_shield.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_shield)
		var t: Tween = create_tween().set_loops()
		t.tween_property(m, "albedo_color:a", 0.34, 0.9)
		t.tween_property(m, "albedo_color:a", 0.16, 0.9)
	if _shield != null:
		_shield.visible = on


## Sets the fortress hit points (campaign levels scale the enemy fortress).
func set_max_hp(value: float) -> void:
	max_hp = value
	hp = value
	if _hp_bar != null:
		_hp_bar.set_fill(1.0)


var _sound_clock: Dictionary = {}


## Plays a sound at the fortress, but not more often than every `gap` seconds.
func _sound(stream_name: String, volume_db: float, gap: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - float(_sound_clock.get(stream_name, -10.0)) >= gap:
		_sound_clock[stream_name] = now
		Sfx.play(stream_name, volume_db, global_position)
