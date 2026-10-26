class_name CatapultModel
extends UnitVisual
## A wooden catapult: frame, four wheels, a throwing arm and a team banner. Faces -Z.

const ARM_LOADED: float = 62.0  # degrees, arm pulled back
const ARM_FIRED: float = -58.0  # degrees, arm thrown forward

var _arm: Node3D
var _wheels: Array[Node3D] = []
var _moving: bool = false
var _dead: bool = false
var _tween: Tween
var _speed: float = 1.0


func setup(team: int) -> void:
	var wood: Color = Color("8a6a46")
	var dark_wood: Color = Color("5e4630")
	var cloth: Color = Stickman.C_GOLD if team == 0 else Stickman.C_RED
	var metal: Color = Stickman.C_STEEL if team == 0 else Stickman.C_IRON
	_part(Vector3(0.0, 0.7, 0.0), Vector3(1.5, 0.28, 2.5), wood, self)
	_part(Vector3(-0.62, 1.1, 0.35), Vector3(0.18, 0.9, 0.18), dark_wood, self)
	_part(Vector3(0.62, 1.1, 0.35), Vector3(0.18, 0.9, 0.18), dark_wood, self)
	_part(Vector3(0.0, 1.5, 0.35), Vector3(1.4, 0.16, 0.22), dark_wood, self)
	_part(Vector3(0.0, 0.95, 1.05), Vector3(1.0, 0.1, 0.1), dark_wood, self)
	_part(Vector3(0.0, 1.0, -0.9), Vector3(0.8, 0.55, 0.12), cloth, self)  # banner plate in the team colour
	_part(Vector3(0.0, 0.82, 0.0), Vector3(1.56, 0.1, 1.0), metal, self)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var w: Node3D = Node3D.new()
			w.position = Vector3(sx * 0.86, 0.5, sz * 0.85)
			add_child(w)
			var mi: MeshInstance3D = MeshInstance3D.new()
			var cyl: CylinderMesh = CylinderMesh.new()
			cyl.top_radius = 0.5
			cyl.bottom_radius = 0.5
			cyl.height = 0.16
			cyl.radial_segments = 8
			cyl.rings = 1
			mi.mesh = cyl
			mi.rotation_degrees = Vector3(0.0, 0.0, 90.0)
			mi.material_override = _mat(dark_wood)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			w.add_child(mi)
			_part(Vector3(0.0, 0.0, 0.0), Vector3(0.2, 0.9, 0.12), wood, w)  # spoke so the spin is visible
			_wheels.append(w)
	_arm = Node3D.new()
	_arm.position = Vector3(0.0, 1.5, 0.35)
	add_child(_arm)
	_part(Vector3(0.0, 0.0, -1.1), Vector3(0.2, 0.22, 3.0), wood, _arm)  # long arm (front end holds the bucket)
	_part(Vector3(0.0, 0.1, -2.5), Vector3(0.6, 0.12, 0.6), dark_wood, _arm)  # bucket
	_part(Vector3(0.0, 0.3, -2.5), Vector3(0.12, 0.3, 0.6), dark_wood, _arm)
	_part(Vector3(0.0, 0.15, 0.55), Vector3(0.4, 0.3, 0.4), metal, _arm)  # counterweight
	_arm.rotation_degrees.x = ARM_LOADED
	var shadow: BlobShadow = BlobShadow.make(Vector2(3.2, 3.8))
	shadow.name = "BlobShadow"
	add_child(shadow)


func play(anim: StringName, speed: float = 1.0, _restart: bool = false) -> void:
	if _dead:
		return
	_speed = speed
	match anim:
		&"walk", &"run":
			_moving = true
		&"idle", &"hit":
			_moving = false
		&"attack":
			_moving = false
			if _tween != null:
				_tween.kill()
			_tween = create_tween()
			_tween.tween_interval(0.25)
			_tween.tween_property(_arm, "rotation_degrees:x", ARM_FIRED, 0.25).set_ease(Tween.EASE_IN)  # whip forward: the strike
			_tween.tween_interval(0.35)
			_tween.tween_property(_arm, "rotation_degrees:x", ARM_LOADED, 2.0).set_ease(Tween.EASE_IN_OUT)  # winch back
		&"die":
			_dead = true
			_moving = false
			if _tween != null:
				_tween.kill()
			var t: Tween = create_tween().set_parallel(true)
			t.tween_property(self, "rotation:z", deg_to_rad(28.0), 0.6)
			t.tween_property(self, "position:y", position.y - 0.25, 0.6)
			t.tween_property(_arm, "rotation_degrees:x", 20.0, 0.6)


func _process(delta: float) -> void:
	if _moving:
		for w: Node3D in _wheels:
			w.rotation.x -= delta * 2.4 * _speed


func _mat(color: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return mat


func _part(pos: Vector3, size: Vector3, color: Color, parent: Node3D) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var m: BoxMesh = BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.material_override = _mat(color)
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
