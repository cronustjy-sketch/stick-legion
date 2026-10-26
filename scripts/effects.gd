class_name Effects
extends Node3D
## Hit feedback: spark bursts, floating damage numbers, expanding rings, and camera shake requests.
## Everything is created on demand and cleans itself up; counts are capped so big fights stay smooth.

var max_sparks: int = 22
const MAX_NUMBERS: int = 40

var battle: Battle

var _live_sparks: int = 0
var _live_numbers: int = 0
var _spark_mesh: BoxMesh
var _spark_mats: Dictionary = {}
var _ring_mesh: CylinderMesh


func _ready() -> void:
	max_sparks = Settings.max_sparks()
	_spark_mesh = BoxMesh.new()
	_spark_mesh.size = Vector3(0.07, 0.07, 0.07)
	_ring_mesh = CylinderMesh.new()
	_ring_mesh.top_radius = 1.0
	_ring_mesh.bottom_radius = 1.0
	_ring_mesh.height = 0.08
	_ring_mesh.radial_segments = 24
	_ring_mesh.rings = 1


## A short burst of sparks at a hit.
func sparks(pos: Vector3, color: Color = Color("ffd24a"), amount: int = 8) -> void:
	if _live_sparks >= max_sparks:
		return
	_live_sparks += 1
	var p: CPUParticles3D = CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.4
	p.mesh = _spark_mesh
	p.material_override = _spark_material(color)
	p.direction = Vector3.UP
	p.spread = 150.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 6.0
	p.gravity = Vector3(0.0, -12.0, 0.0)
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.5
	p.emitting = true
	add_child(p)
	p.global_position = pos
	get_tree().create_timer(0.8).timeout.connect(func() -> void:
		_live_sparks -= 1
		p.queue_free())


## A floating number that rises and fades. `kind`: "hit", "heavy", "hurt" (hero took damage), "heal".
func number(pos: Vector3, amount: float, kind: String = "hit") -> void:
	if _live_numbers >= MAX_NUMBERS:
		return
	_live_numbers += 1
	var l: Label3D = Label3D.new()
	l.text = ("+%d" if kind == "heal" else "%d") % int(round(amount))
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.fixed_size = true
	l.no_depth_test = true
	l.font_size = 40 if kind == "heavy" else 32
	l.pixel_size = 0.0011
	l.outline_size = 12
	match kind:
		"heavy":
			l.modulate = Color("ffc531")
		"hurt":
			l.modulate = Color("ff5a4a")
		"heal":
			l.modulate = Color("6fe08a")
		_:
			l.modulate = Color("ffffff")
	add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.3, 0.3), 0.0, randf_range(-0.3, 0.3))
	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y + 1.6, 0.8).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	t.chain().tween_callback(func() -> void:
		_live_numbers -= 1
		l.queue_free())


## An expanding ground ring (area skills, smashes).
func ring(pos: Vector3, radius: float, color: Color = Color("ffd24a"), time: float = 0.5) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = _ring_mesh
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(color.r, color.g, color.b, 0.55)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = pos + Vector3(0.0, 0.15, 0.0)
	mi.scale = Vector3(0.3, 1.0, 0.3)
	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(mi, "scale", Vector3(radius, 1.0, radius), time).set_ease(Tween.EASE_OUT)
	t.tween_property(m, "albedo_color:a", 0.0, time)
	t.chain().tween_callback(mi.queue_free)


func shake(amount: float, time: float = 0.25) -> void:
	if battle != null and battle.hero_camera != null:
		battle.hero_camera.shake(amount, time)


func _spark_material(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html()
	if not _spark_mats.has(key):
		var m: StandardMaterial3D = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = color
		_spark_mats[key] = m
	return _spark_mats[key]


## Boss attack warning: a red circle on the ground that fills up until the blow lands after `time` seconds.
func telegraph(pos: Vector3, radius: float, time: float) -> void:
	Sfx.play("warning", -5.0, pos)
	var outer: MeshInstance3D = _disc(Color(0.85, 0.05, 0.05, 0.34))
	outer.global_position = pos + Vector3(0.0, 0.12, 0.0)
	outer.scale = Vector3(radius, 1.0, radius)
	var inner: MeshInstance3D = _disc(Color(1.0, 0.1, 0.05, 0.55))
	inner.global_position = pos + Vector3(0.0, 0.16, 0.0)
	inner.scale = Vector3(0.2, 1.0, 0.2)
	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(inner, "scale", Vector3(radius, 1.0, radius), time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func() -> void:
		outer.queue_free()
		inner.queue_free())


func _disc(color: Color) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = _ring_mesh
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


## A red corridor on the ground that fills from `a` to `b` (charges and dashes).
func telegraph_line(a: Vector3, b: Vector3, width: float, time: float) -> void:
	Sfx.play("warning", -5.0, a)
	var dir: Vector3 = b - a
	dir.y = 0.0
	var length: float = dir.length()
	if length < 0.1:
		return
	dir /= length
	var yaw: float = atan2(dir.x, dir.z)
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(1.0, 0.06, 1.0)
	var outer: MeshInstance3D = _box_disc(box, Color(0.85, 0.05, 0.05, 0.3))
	outer.global_position = a + dir * length * 0.5 + Vector3(0.0, 0.12, 0.0)
	outer.rotation.y = yaw
	outer.scale = Vector3(width, 1.0, length)
	var inner: MeshInstance3D = _box_disc(box, Color(1.0, 0.1, 0.05, 0.55))
	inner.rotation.y = yaw
	inner.scale = Vector3(width, 1.0, 0.1)
	inner.global_position = a + Vector3(0.0, 0.16, 0.0)
	var t: Tween = create_tween()
	t.tween_method(func(s: float) -> void:
		inner.scale.z = maxf(length * s, 0.1)
		inner.global_position = a + dir * length * s * 0.5 + Vector3(0.0, 0.16, 0.0), 0.0, 1.0, time)
	t.tween_callback(func() -> void:
		outer.queue_free()
		inner.queue_free())


func _box_disc(mesh: Mesh, color: Color) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi
