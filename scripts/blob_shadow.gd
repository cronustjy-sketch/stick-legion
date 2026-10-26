class_name BlobShadow
extends MeshInstance3D
## Cheap fake shadow: a dark radial-gradient quad lying on the ground.

static var _tex: GradientTexture2D
static var _mat: StandardMaterial3D


## Creates a blob shadow of the given world-space size (diameter in metres).
static func make(diameter: Vector2) -> BlobShadow:
	var s: BlobShadow = BlobShadow.new()
	var q: QuadMesh = QuadMesh.new()
	q.size = diameter
	q.orientation = PlaneMesh.FACE_Y
	s.mesh = q
	s.material_override = get_material()
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.position.y = 0.06
	return s


static func get_material() -> StandardMaterial3D:
	if _mat == null:
		var grad: Gradient = Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
		grad.colors = PackedColorArray([Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.3), Color(0, 0, 0, 0.0)])
		_tex = GradientTexture2D.new()
		_tex.gradient = grad
		_tex.fill = GradientTexture2D.FILL_RADIAL
		_tex.fill_from = Vector2(0.5, 0.5)
		_tex.fill_to = Vector2(1.0, 0.5)
		_tex.width = 64
		_tex.height = 64
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.albedo_texture = _tex
		_mat.no_depth_test = false
		_mat.render_priority = -1
	return _mat
