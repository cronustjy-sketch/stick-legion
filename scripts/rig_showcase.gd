class_name RigShowcase
extends Node3D
## Debug scene: every humanoid unit type, both teams, playing different animations.
## Run with: godot --path . res://scenes/rig_showcase.tscn

const SHOT_TIMES: Array[float] = [1.0, 1.7, 2.6]
const SPACING: float = 1.9

# Animation per unit slot (same order as UnitData.HUMANOID_ORDER).
const GOLD_ANIMS: Array[String] = ["attack", "attack", "attack", "block", "attack", "run", "walk"]
const RED_ANIMS: Array[String] = ["block", "hit", "idle", "attack", "die", "attack", "attack"]

var _units: Array[Stickman] = []


func _ready() -> void:
	SkySetup.build(self)
	_build_floor()
	_spawn_row(0, 1.0, GOLD_ANIMS)
	_spawn_row(1, -4.2, RED_ANIMS)
	var cam: Camera3D = Camera3D.new()
	cam.fov = 34.0
	add_child(cam)
	cam.position = Vector3(0.0, 2.6, 15.0)
	cam.look_at(Vector3(0.0, 1.0, -1.0))
	cam.current = true
	if OS.get_cmdline_user_args().has("--closeup"):  # godot ... -- --closeup
		cam.position = Vector3(-2.9, 1.7, 6.5)
		cam.look_at(Vector3(-2.9, 1.0, 0.0))
	if OS.is_debug_build() and not OS.has_feature("web"):
		for t: float in SHOT_TIMES:
			get_tree().create_timer(t).timeout.connect(_save_screenshot)


func _build_floor() -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(60.0, 60.0)
	mi.mesh = plane
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = BattlefieldData.COLOR_GRASS_A
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mi.material_override = mat
	add_child(mi)


func _spawn_row(team: int, z: float, anims: Array[String]) -> void:
	var n: int = UnitData.HUMANOID_ORDER.size()
	for i: int in n:
		var s: Stickman = Stickman.new()
		s.name = "%s_%d" % [UnitData.HUMANOID_ORDER[i], team]
		s.setup(UnitData.HUMANOID_ORDER[i], team)
		var x_off: float = 0.0 if team == 0 else SPACING * 0.5  # stagger the rows so nobody hides behind a friend
		s.position = Vector3((float(i) - float(n - 1) * 0.5) * SPACING + x_off - SPACING * 0.25, 0.0, z)
		s.rotation.y = PI  # face the camera (+Z)
		add_child(s)
		_units.append(s)
		var anim: String = anims[i]
		s.play(anim)
		s.animation_done.connect(_replay.bind(s, anim))


func _replay(_finished: StringName, s: Stickman, anim: String) -> void:
	if anim == "attack" or anim == "hit" or anim == "die":
		await get_tree().create_timer(1.0 if anim == "die" else 0.5).timeout
		s.play(anim)


func _save_screenshot() -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var dir: String = ProjectSettings.globalize_path("res://screenshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var path: String = dir.path_join("rig_%d.png" % Time.get_ticks_msec())
	img.save_png(path)
	print("Screenshot saved: ", path)
