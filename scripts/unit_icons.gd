class_name UnitIcons
extends RefCounted
## Renders a small portrait of a unit (the real rig, front 3/4 view) into a texture for the HUD.

const SIZE: int = 112


## Creates the portrait viewport under `parent` and returns its texture. Rendering stops after a moment.
static func make(parent: Node, key: String, team: int = 0) -> ViewportTexture:
	var vp: SubViewport = SubViewport.new()
	vp.name = "Icon_" + key
	vp.size = Vector2i(SIZE, SIZE)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	parent.add_child(vp)
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c4d2e8")
	env.ambient_light_energy = 0.7
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30.0, -25.0, 0.0)
	sun.light_energy = 1.1
	vp.add_child(sun)
	var s: Stickman = Stickman.new()
	s.setup(key, team)
	s.rotation.y = deg_to_rad(-22.0)
	vp.add_child(s)
	s.get_node("BlobShadow").visible = false
	var cam: Camera3D = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.7
	vp.add_child(cam)
	cam.position = Vector3(0.0, 1.22, 4.0)
	# Let the idle pose apply, then freeze the picture to save GPU time.
	var timer: SceneTreeTimer = parent.get_tree().create_timer(0.5)
	timer.timeout.connect(func() -> void: vp.render_target_update_mode = SubViewport.UPDATE_DISABLED)
	return vp.get_texture()
