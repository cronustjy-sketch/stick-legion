class_name WeaponTrail
extends MeshInstance3D
## A fading ribbon behind the hero's sword while he swings. Samples the blade's base and tip every frame.

const LIFETIME: float = 0.22
const MAX_SAMPLES: int = 14

var active: bool = false

var _model: Stickman
var _samples: Array[Dictionary] = []  # {tip, base, age}
var _mesh: ImmediateMesh


func setup(model: Stickman) -> void:
	_model = model
	top_level = true
	_mesh = ImmediateMesh.new()
	mesh = _mesh
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	global_transform = Transform3D.IDENTITY


func _process(delta: float) -> void:
	for s: Dictionary in _samples:
		s.age = float(s.age) + delta
	while not _samples.is_empty() and float(_samples[0].age) > LIFETIME:
		_samples.pop_front()
	if active and _model != null:
		var pts: Array[Vector3] = _model.weapon_world_points()
		_samples.append({"tip": pts[0], "base": pts[1], "age": 0.0})
		if _samples.size() > MAX_SAMPLES:
			_samples.pop_front()
	_mesh.clear_surfaces()
	if _samples.size() < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for s: Dictionary in _samples:
		var a: float = clampf(1.0 - float(s.age) / LIFETIME, 0.0, 1.0)
		_mesh.surface_set_color(Color(1.0, 0.92, 0.6, 0.0))
		_mesh.surface_add_vertex(s.base as Vector3)
		_mesh.surface_set_color(Color(1.0, 0.95, 0.75, a * 0.75))
		_mesh.surface_add_vertex(s.tip as Vector3)
	_mesh.surface_end()
