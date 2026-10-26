class_name CavalryModel
extends UnitVisual
## A low-poly horse (legs swing in code) carrying a stickman rider (the "ride" animation set).
## Faces -Z like every other unit.

var rider: Stickman
var _root: Node3D
var _legs: Array[Node3D] = []
var _mode: StringName = &"idle"
var _phase: float = 0.0
var _speed: float = 1.0
var _dead: bool = false


func setup(team: int) -> void:
	_root = Node3D.new()
	_root.name = "Root"
	add_child(_root)
	var coat: Color = Color("d8cfbf") if team == 0 else Color("3b2c27")
	var dark: Color = Color("2a2220")
	var cloth: Color = Stickman.C_GOLD if team == 0 else Stickman.C_RED
	var metal: Color = Stickman.C_STEEL if team == 0 else Stickman.C_IRON
	_part(Vector3(0.0, 1.15, 0.0), Vector3(0.72, 0.72, 1.7), coat)
	_part(Vector3(0.0, 1.62, -0.98), Vector3(0.34, 0.85, 0.42), coat, Vector3(-32.0, 0, 0))
	_part(Vector3(0.0, 1.98, -1.3), Vector3(0.3, 0.34, 0.62), coat, Vector3(-18.0, 0, 0))
	_part(Vector3(0.0, 1.78, -0.82), Vector3(0.1, 0.7, 0.3), dark, Vector3(-32.0, 0, 0))  # mane
	_part(Vector3(0.0, 1.2, 0.98), Vector3(0.13, 0.75, 0.13), dark, Vector3(20.0, 0, 0))  # tail
	_part(Vector3(0.0, 1.53, 0.0), Vector3(0.8, 0.08, 1.0), cloth)  # blanket in the team colour
	_part(Vector3(0.0, 1.5, -1.0), Vector3(0.5, 0.5, 0.1), metal, Vector3(-30.0, 0, 0))  # chest armour
	_part(Vector3(0.0, 2.1, -1.5), Vector3(0.12, 0.2, 0.14), cloth, Vector3(-18.0, 0, 0))  # forehead plume
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var pivot: Node3D = Node3D.new()
			pivot.position = Vector3(sx * 0.22, 0.86, sz * 0.62)
			_root.add_child(pivot)
			_part(Vector3(0.0, -0.42, 0.0), Vector3(0.16, 0.86, 0.16), coat, Vector3.ZERO, pivot)
			_part(Vector3(0.0, -0.86, 0.02), Vector3(0.19, 0.1, 0.22), dark, Vector3.ZERO, pivot)
			_legs.append(pivot)
	rider = Stickman.new()
	rider.setup("cavalry", team)
	rider.position = Vector3(0.0, 0.8, 0.08)
	_root.add_child(rider)
	var rs: Node = rider.get_node_or_null("BlobShadow")
	if rs != null:
		rs.queue_free()
	var shadow: BlobShadow = BlobShadow.make(Vector2(1.9, 2.8))
	shadow.name = "BlobShadow"
	add_child(shadow)


func play(anim: StringName, speed: float = 1.0, restart: bool = false) -> void:
	if _dead:
		return
	if anim == &"die":
		_dead = true
		rider.play("die", 1.0, true)
		var t: Tween = create_tween().set_parallel(true)
		t.tween_property(_root, "rotation:z", deg_to_rad(82.0), 0.7).set_ease(Tween.EASE_IN)
		t.tween_property(_root, "position:y", -0.15, 0.7)
		return
	_mode = anim
	_speed = speed
	rider.play(anim, speed, restart)


func _process(delta: float) -> void:
	if _dead:
		return
	var moving: bool = _mode == &"walk" or _mode == &"run"
	var amp: float = 0.0
	if moving:
		amp = deg_to_rad(42.0 if _mode == &"run" else 26.0)
		_phase += delta * (13.0 if _mode == &"run" else 7.0) * _speed
	for i: int in _legs.size():
		# Front/back pairs swing opposite, left/right offset: a readable gallop.
		var side: float = -1.0 if (i / 2) == 0 else 1.0
		var front: float = -1.0 if i % 2 == 0 else 1.0
		var target: float = sin(_phase + (0.0 if front * side > 0.0 else PI)) * amp
		_legs[i].rotation.x = lerpf(_legs[i].rotation.x, target, clampf(18.0 * delta, 0.0, 1.0))
	_root.position.y = absf(sin(_phase * 2.0)) * 0.06 if moving else 0.0


func _part(pos: Vector3, size: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO, parent: Node3D = null) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var m: BoxMesh = BoxMesh.new()
	m.size = size
	mi.mesh = m
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent != null else _root).add_child(mi)
