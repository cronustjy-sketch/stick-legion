class_name ThemeProps
extends RefCounted
## Extra scenery per chapter (ThemeData "extras"): wheat tufts, broken walls and red banners.
## Everything is a few MultiMeshes, so a whole chapter adds only a handful of draw calls.


static func build(battle: Battle, look: Dictionary) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = BattlefieldData.SCENE_SEED + 7
	for extra: String in look.extras:
		match extra:
			"wheat":
				_wheat(battle, rng)
			"ruins":
				_ruins(battle, rng)
			"banners":
				_banners(battle, rng)


## A random spot in the side bands of the valley (outside the open grass field) or, with `anywhere`, across the whole valley.
static func _spot(rng: RandomNumberGenerator, anywhere: bool, z_limit: float) -> Vector2:
	var side: float = -1.0 if rng.randf() < 0.5 else 1.0
	var x: float = side * rng.randf_range(2.0 if anywhere else BattlefieldData.FIELD_HALF_WIDTH + 1.5, 38.0)
	return Vector2(x, rng.randf_range(-z_limit, z_limit))


static func _wheat(battle: Battle, rng: RandomNumberGenerator) -> void:
	var tuft: CylinderMesh = CylinderMesh.new()
	tuft.top_radius = 0.0
	tuft.bottom_radius = 0.05
	tuft.height = 0.5
	tuft.radial_segments = 4
	tuft.rings = 1
	var xfs: Array[Transform3D] = []
	var count: int = int(2600.0 * Settings.prop_density())
	for i: int in count:
		var p: Vector2 = _spot(rng, true, BattlefieldData.FORTRESS_Z - 9.0)
		var s: float = rng.randf_range(0.8, 1.5)
		var lean: Basis = Basis.from_euler(Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.3, 0.3)))
		xfs.append(Transform3D(lean * Basis.from_scale(Vector3(s, s, s)), Vector3(p.x, battle.terrain.height_at(p.x, p.y) + 0.25 * s, p.y)))
	battle.add_multimesh("WheatTufts", tuft, battle.toon(Color("dcc060")), xfs)


static func _ruins(battle: Battle, rng: RandomNumberGenerator) -> void:
	var stone: Color = Color("7f7570")
	var walls: Array[Transform3D] = []
	var pillars: Array[Transform3D] = []
	var shadows: Array[Transform3D] = []
	for i: int in int(20.0 * Settings.prop_density()):
		var p: Vector2 = _spot(rng, false, BattlefieldData.FORTRESS_Z - 14.0)
		var length: float = rng.randf_range(5.0, 11.0)
		var h: float = rng.randf_range(1.2, 4.2)
		var yaw: float = rng.randf_range(-0.35, 0.35) + (PI * 0.5 if rng.randf() < 0.25 else 0.0)
		var y: float = battle.terrain.height_at(p.x, p.y)
		walls.append(Transform3D(Basis.from_euler(Vector3(0.0, yaw, 0.0)) * Basis.from_scale(Vector3(length, h, 1.2)), Vector3(p.x, y + h * 0.5 - 0.1, p.y)))
		shadows.append(Transform3D(Basis.from_euler(Vector3(0.0, yaw, 0.0)) * Basis.from_scale(Vector3(length * 1.15, 1.0, 3.0)), Vector3(p.x, y + 0.08, p.y)))
	for i: int in int(16.0 * Settings.prop_density()):
		var p: Vector2 = _spot(rng, false, BattlefieldData.FORTRESS_Z - 12.0)
		var h: float = rng.randf_range(2.0, 5.5)
		var y: float = battle.terrain.height_at(p.x, p.y)
		if rng.randf() < 0.3:  # a toppled column
			pillars.append(Transform3D(Basis.from_euler(Vector3(0.0, rng.randf() * TAU, PI * 0.5)) * Basis.from_scale(Vector3(1, h, 1)), Vector3(p.x, y + 0.6, p.y)))
		else:
			pillars.append(Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.08, 0.08), 0.0, rng.randf_range(-0.08, 0.08))) * Basis.from_scale(Vector3(1, h, 1)), Vector3(p.x, y + h * 0.5 - 0.1, p.y)))
		shadows.append(Transform3D(Basis.from_scale(Vector3(2.6, 1.0, 2.6)), Vector3(p.x, y + 0.08, p.y)))
	var wall_mesh: BoxMesh = BoxMesh.new()
	battle.add_multimesh("RuinWalls", wall_mesh, battle.toon(stone), walls)
	var pillar_mesh: CylinderMesh = CylinderMesh.new()
	pillar_mesh.top_radius = 0.6
	pillar_mesh.bottom_radius = 0.75
	pillar_mesh.height = 1.0
	pillar_mesh.radial_segments = 6
	pillar_mesh.rings = 1
	battle.add_multimesh("RuinPillars", pillar_mesh, battle.toon(stone.lightened(0.08)), pillars)
	var sh_mesh: QuadMesh = QuadMesh.new()
	sh_mesh.size = Vector2.ONE
	sh_mesh.orientation = PlaneMesh.FACE_Y
	battle.add_multimesh("RuinShadows", sh_mesh, BlobShadow.get_material(), shadows)


static func _banners(battle: Battle, rng: RandomNumberGenerator) -> void:
	var pole: CylinderMesh = CylinderMesh.new()
	pole.top_radius = 0.08
	pole.bottom_radius = 0.12
	pole.height = 7.0
	pole.radial_segments = 4
	pole.rings = 1
	var cloth: QuadMesh = QuadMesh.new()
	cloth.size = Vector2(1.7, 3.4)
	var cloth_mat: StandardMaterial3D = StandardMaterial3D.new()
	cloth_mat.albedo_color = Color("b8322c")
	cloth_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	cloth_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	cloth_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cloth_mat.emission_enabled = true
	cloth_mat.emission = Color("7a1814")
	cloth_mat.emission_energy_multiplier = 0.5
	var poles: Array[Transform3D] = []
	var cloths: Array[Transform3D] = []
	for i: int in 16:
		var p: Vector2 = _spot(rng, false, BattlefieldData.FORTRESS_Z - 10.0)
		var yaw: float = rng.randf_range(-0.5, 0.5)
		var y: float = battle.terrain.height_at(p.x, p.y)
		var pole_t: Transform3D = Transform3D(Basis.from_euler(Vector3(0.0, yaw, rng.randf_range(-0.05, 0.05))), Vector3(p.x, y + 3.4, p.y))
		poles.append(pole_t)
		cloths.append(pole_t * Transform3D(Basis.IDENTITY, Vector3(0.95, 1.7, 0.0)))
	battle.add_multimesh("BannerPoles", pole, battle.toon(Color("2a2222")), poles)
	battle.add_multimesh("BannerCloth", cloth, cloth_mat, cloths)
