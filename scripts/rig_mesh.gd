class_name RigMesh
extends RefCounted
## Collects low-poly primitives into ONE skinned ArrayMesh (rigid weights, vertex colours, flat normals).
## Set `frame` to place pieces in another coordinate frame (e.g. a weapon held in a hand).

var frame: Transform3D = Transform3D.IDENTITY

var _st: SurfaceTool = SurfaceTool.new()
var _bone_index: Dictionary


func _init(bone_index: Dictionary) -> void:
	_bone_index = bone_index
	_st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)


func commit() -> ArrayMesh:
	_st.generate_normals()
	return _st.commit()


## Cylinder (or cone when r_b = 0) from local point a to local point b.
func cyl(bone: String, a: Vector3, b: Vector3, r_a: float, r_b: float, color: Color, sides: int = 6) -> void:
	var m: CylinderMesh = CylinderMesh.new()
	m.bottom_radius = r_a
	m.top_radius = r_b
	m.height = a.distance_to(b)
	m.radial_segments = sides
	m.rings = 1
	var basis: Basis = _basis_y((b - a).normalized())
	_add(m, Transform3D(basis, (a + b) * 0.5), bone, color)


## Vertical tapered cylinder, squashed in Z (torso, robes).
func tcyl(bone: String, y0: float, y1: float, r0: float, r1: float, z_scale: float, color: Color, sides: int = 7, x: float = 0.0) -> void:
	var m: CylinderMesh = CylinderMesh.new()
	m.bottom_radius = r0
	m.top_radius = r1
	m.height = y1 - y0
	m.radial_segments = sides
	m.rings = 1
	_add(m, Transform3D(Basis.from_scale(Vector3(1.0, 1.0, z_scale)), Vector3(x, (y0 + y1) * 0.5, 0.0)), bone, color)


func sphere(bone: String, c: Vector3, r: float, color: Color, scl: Vector3 = Vector3.ONE, segments: int = 8) -> void:
	var m: SphereMesh = SphereMesh.new()
	m.radius = 1.0
	m.height = 2.0
	m.radial_segments = segments
	m.rings = maxi(segments / 2, 3)
	_add(m, Transform3D(Basis.from_scale(scl * r), c), bone, color)


func box(bone: String, c: Vector3, size: Vector3, color: Color, rot: Basis = Basis.IDENTITY) -> void:
	var m: BoxMesh = BoxMesh.new()
	m.size = size
	_add(m, Transform3D(rot, c), bone, color)


func _add(mesh: Mesh, xf: Transform3D, bone: String, color: Color) -> void:
	var arrays: Array = mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var bones: PackedInt32Array = PackedInt32Array([int(_bone_index[bone]), 0, 0, 0])
	var weights: PackedFloat32Array = PackedFloat32Array([1.0, 0.0, 0.0, 0.0])
	var full: Transform3D = frame * xf
	for i: int in idx:
		_st.set_smooth_group(-1)  # flat shading
		_st.set_color(color)
		_st.set_bones(bones)
		_st.set_weights(weights)
		_st.add_vertex(full * verts[i])


static func _basis_y(dir: Vector3) -> Basis:
	if absf(dir.dot(Vector3.UP)) > 0.999:
		return Basis.IDENTITY if dir.y > 0.0 else Basis(Vector3.RIGHT, PI)
	return Basis(Quaternion(Vector3.UP, dir))
