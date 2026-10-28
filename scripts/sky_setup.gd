class_name SkySetup
extends RefCounted
## Shared sky, light and low-poly clouds for the battle and the rig showcase.

static var sky_mat: ProceduralSkyMaterial
static var env: Environment
static var look: Dictionary = ThemeData.THEMES[0]  # the chapter look in use (the red-sky phase fades back to it)


## Corvin phase 3: the sky turns red (and back to blue when `on` is false).
static func set_red_sky(owner: Node, on: bool) -> void:
	if sky_mat == null:
		return
	var t: Tween = owner.create_tween().set_parallel(true)
	t.tween_property(sky_mat, "sky_top_color", Color("6e1612") if on else look.sky_top as Color, 2.5)
	t.tween_property(sky_mat, "sky_horizon_color", Color("e8602e") if on else look.sky_horizon as Color, 2.5)
	t.tween_property(sky_mat, "ground_horizon_color", Color("c0502a") if on else look.ground_horizon as Color, 2.5)
	if env != null:
		t.tween_property(env, "fog_light_color", Color("d8683a") if on else look.fog as Color, 2.5)
		t.tween_property(env, "ambient_light_color", Color("e0a090") if on else look.ambient as Color, 2.5)


static func build(parent: Node3D, theme: Dictionary = {}) -> Node3D:
	if not theme.is_empty():
		look = theme
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = look.sky_top as Color
	sky_mat.sky_horizon_color = look.sky_horizon as Color
	sky_mat.sky_curve = 0.25
	sky_mat.ground_horizon_color = look.ground_horizon as Color
	sky_mat.ground_bottom_color = look.ground_bottom as Color
	sky_mat.sun_angle_max = 12.0
	var sky: Sky = Sky.new()
	sky.sky_material = sky_mat
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = look.ambient as Color
	env.ambient_light_energy = float(look.ambient_energy)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = look.fog as Color
	env.fog_density = float(look.fog_density)
	env.fog_sky_affect = 0.15
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = look.sun as Color
	sun.light_energy = float(look.sun_energy)
	sun.shadow_enabled = false  # blob shadows only
	sun.rotation_degrees = Vector3(float(look.sun_pitch), float(look.sun_yaw), 0.0)
	parent.add_child(sun)
	return _build_clouds(parent)


static func _build_clouds(parent: Node3D) -> Node3D:
	# One cloud mesh = a few squashed low-poly spheres merged; scattered with one MultiMesh.
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 7
	sphere.rings = 4
	var st: SurfaceTool = SurfaceTool.new()
	var puffs: Array[Vector4] = [
		Vector4(0.0, 0.0, 0.0, 1.0), Vector4(1.2, -0.1, 0.2, 0.8), Vector4(-1.2, -0.15, -0.1, 0.75),
		Vector4(0.5, 0.35, -0.3, 0.7), Vector4(-0.5, 0.2, 0.4, 0.65),
	]
	for p: Vector4 in puffs:
		var b: Basis = Basis.from_scale(Vector3(p.w, p.w * 0.55, p.w * 0.9))
		st.append_from(sphere, 0, Transform3D(b, Vector3(p.x, p.y, p.z)))
	var merged: ArrayMesh = st.commit()
	st = SurfaceTool.new()
	st.create_from(merged, 0)
	st.deindex()
	st.generate_normals()
	var cloud_mesh: ArrayMesh = st.commit()
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = look.cloud as Color
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.emission_enabled = true
	mat.emission = look.cloud_emission as Color
	mat.emission_energy_multiplier = 0.55
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cloud_mesh
	mm.instance_count = int(look.cloud_count)
	for i: int in mm.instance_count:
		var ang: float = rng.randf() * TAU
		var r: float = rng.randf_range(60.0, 190.0)
		var s: float = rng.randf_range(9.0, 20.0)
		var b2: Basis = Basis.from_scale(Vector3(s, s, s)).rotated(Vector3.UP, rng.randf() * TAU)
		mm.set_instance_transform(i, Transform3D(b2, Vector3(cos(ang) * r, rng.randf_range(55.0, 90.0), sin(ang) * r)))
	var holder: Node3D = Node3D.new()
	holder.name = "Clouds"
	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(mmi)
	parent.add_child(holder)
	return holder
