class_name Weather
extends Node3D
## Falling snow, drifting embers and smoke, or ash: a few hundred cheap CPU particles in a box around the camera.
## Child of the camera, so the particles always surround what the player sees. Kinds come from ThemeData ("weather").

const BOX: Vector3 = Vector3(34.0, 9.0, 34.0)  # half extents of the spawn area


static func create(kind: String) -> Weather:
	var w: Weather = Weather.new()
	w.name = "Weather"
	match kind:
		"snow":
			w._add(w._flakes(Color(1, 1, 1, 0.95), 0.16, 420, 7.0, Vector3(0.7, -2.4, 0.3), 0.8, false, 0.0))
		"embers":
			w._add(w._flakes(Color(1.0, 0.55, 0.15, 1.0), 0.12, 160, 6.0, Vector3(0.5, 1.4, 0.3), 1.5, true, 0.0))
			w._add(w._flakes(Color(0.12, 0.1, 0.1, 0.2), 2.2, 24, 9.0, Vector3(0.8, 0.9, 0.3), 0.5, false, 0.3))
		"ash":
			w._add(w._flakes(Color(0.75, 0.72, 0.7, 0.8), 0.14, 220, 8.0, Vector3(0.6, -0.9, 0.4), 1.2, false, 0.0))
			w._add(w._flakes(Color(1.0, 0.42, 0.18, 1.0), 0.1, 70, 6.0, Vector3(0.4, 1.0, 0.3), 1.5, true, 0.0))
	# The box sits in front of the camera and above it, so the flakes fall through the view.
	w.position = Vector3(0.0, 3.0, -16.0)
	return w


func _add(p: CPUParticles3D) -> void:
	add_child(p)


## One particle system. `soft` fades the quads in and out (smoke); `glow` makes it unshaded and bright.
func _flakes(col: Color, size: float, count: int, life: float, vel: Vector3, jitter: float, glow: bool, grow: float) -> CPUParticles3D:
	var p: CPUParticles3D = CPUParticles3D.new()
	p.amount = maxi(int(float(count) * Settings.prop_density()), 8)
	p.lifetime = life
	p.preprocess = life  # the air is already full when the battle starts
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = BOX
	p.direction = vel.normalized()
	p.spread = 20.0 if vel.length() > 1.0 else 35.0
	p.initial_velocity_min = vel.length() * (1.0 - 0.3 * jitter)
	p.initial_velocity_max = vel.length() * (1.0 + 0.3 * jitter)
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	if grow > 0.0:
		p.scale_amount_curve = _ramp_curve(1.0, 0.4 + grow)
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color.WHITE
	mat.albedo_texture = _soft_dot()
	mat.disable_receive_shadows = true
	quad.material = mat
	p.mesh = quad
	var g: Gradient = Gradient.new()
	g.colors = PackedColorArray([Color(col.r, col.g, col.b, 0.0), col, col, Color(col.r, col.g, col.b, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.12, 0.8, 1.0])
	p.color_ramp = g
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


## A white dot that fades to transparent at the edge, so flakes and smoke puffs are round, not square.
static var _dot: GradientTexture2D


func _soft_dot() -> GradientTexture2D:
	if _dot == null:
		var g: Gradient = Gradient.new()
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)])
		g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		_dot = GradientTexture2D.new()
		_dot.gradient = g
		_dot.fill = GradientTexture2D.FILL_RADIAL
		_dot.fill_from = Vector2(0.5, 0.5)
		_dot.fill_to = Vector2(0.5, 0.0)
		_dot.width = 32
		_dot.height = 32
	return _dot


func _ramp_curve(a: float, b: float) -> Curve:
	var c: Curve = Curve.new()
	c.add_point(Vector2(0.0, a))
	c.add_point(Vector2(1.0, b))
	return c


## Hidden in the high tactical view, where flakes and puffs would just cover the battlefield.
func _process(_delta: float) -> void:
	var cam: Node = get_parent().get_parent() if get_parent() != null else null
	if cam is HeroCamera:
		visible = not (cam as HeroCamera).is_tactical()
