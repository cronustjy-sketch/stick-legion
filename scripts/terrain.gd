class_name Terrain
extends Node3D
## Low-poly flat-shaded valley terrain built from one ArrayMesh.

var look: Dictionary = ThemeData.THEMES[0]  # set before build()
var _noise: FastNoiseLite = FastNoiseLite.new()


func _init() -> void:
	_noise.seed = BattlefieldData.SCENE_SEED
	_noise.frequency = 0.045


## Ground height at world (x, z). Flat in the valley centre and at the fortresses.
func height_at(x: float, z: float) -> float:
	var edge: float = smoothstep(BattlefieldData.VALLEY_HALF_WIDTH, BattlefieldData.VALLEY_HALF_WIDTH + 24.0, absf(x))
	var end: float = smoothstep(BattlefieldData.FORTRESS_Z + 16.0, BattlefieldData.FORTRESS_Z + 40.0, absf(z))
	var rolling: float = _noise.get_noise_2d(x, z) * 1.0
	var near_fort: float = smoothstep(BattlefieldData.FORTRESS_Z - 4.0, BattlefieldData.FORTRESS_Z - 18.0, absf(z))
	var flatten: float = 1.0 - near_fort * 0.9
	return rolling * flatten + edge * 14.0 + end * 14.0


func build() -> void:
	var half_x: float = BattlefieldData.TERRAIN_HALF_X
	var half_z: float = BattlefieldData.TERRAIN_HALF_Z
	var cell: float = BattlefieldData.TERRAIN_CELL
	var nx: int = int(half_x * 2.0 / cell)
	var nz: int = int(half_z * 2.0 / cell)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz: int in nz:
		for ix: int in nx:
			var x0: float = -half_x + ix * cell
			var z0: float = -half_z + iz * cell
			var p00: Vector3 = Vector3(x0, height_at(x0, z0), z0)
			var p10: Vector3 = Vector3(x0 + cell, height_at(x0 + cell, z0), z0)
			var p01: Vector3 = Vector3(x0, height_at(x0, z0 + cell), z0 + cell)
			var p11: Vector3 = Vector3(x0 + cell, height_at(x0 + cell, z0 + cell), z0 + cell)
			_tri(st, p00, p10, p01)
			_tri(st, p10, p11, p01)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mesh.surface_set_material(0, mat)
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "TerrainMesh"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var centre: Vector3 = (a + b + c) / 3.0
	var col: Color = _ground_colour(centre)
	for p: Vector3 in [a, b, c]:
		st.set_color(col)
		st.add_vertex(p)


func _ground_colour(p: Vector3) -> Color:
	var n: float = _noise.get_noise_2d(p.x * 3.1 + 40.0, p.z * 3.1) * 0.5 + 0.5
	var col: Color = (look.ground_a as Color).lerp(look.ground_b as Color, n)
	var amount: float = float(look.patch_amount)
	if amount > 0.0:  # burnt / dirty patches
		var pn: float = _noise.get_noise_2d(p.x * 1.4 + 200.0, p.z * 1.4) * 0.5 + 0.5
		col = col.lerp(look.patch as Color, smoothstep(0.78 - amount * 0.5, 0.82 - amount * 0.5, pn))
	# Steep valley sides turn rocky.
	var rock: float = smoothstep(4.0, 12.0, p.y)
	return col.lerp(look.rock_side as Color, rock)
