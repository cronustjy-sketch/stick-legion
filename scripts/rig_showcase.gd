class_name RigShowcase
extends Node3D
## Debug scene that checks the stickman rig. Saves screenshots to res://screenshots/ and quits:
##   lineup_1/2  - every humanoid unit type, gold and red side by side
##   far         - both teams from a distance (team colours must read at a glance)
##   attack_<unit> - each unit type frozen mid-attack, gold vs red duelling pair
## Run: godot --path . res://scenes/rig_showcase.tscn

const PAIR_SPACING: float = 3.0
const DUEL_SPACING: float = 9.0
const DUEL_GAP: float = 1.15
# Time into the "attack" animation that shows the strike pose, per attack style.
const STRIKE_TIME: Dictionary = {"swing": 0.34, "thrust": 0.45, "shoot": 0.8, "cast": 0.6}

var _gold: Array[Stickman] = []
var _red: Array[Stickman] = []
var _cam: Camera3D
var _tag: String = "step2b"


func _ready() -> void:
	SkySetup.build(self)
	_build_floor()
	var n: int = UnitData.HUMANOID_ORDER.size()
	for i: int in n:
		var key: String = UnitData.HUMANOID_ORDER[i]
		_gold.append(_spawn(key, 0))
		_red.append(_spawn(key, 1))
	_cam = Camera3D.new()
	_cam.fov = 32.0
	add_child(_cam)
	_cam.current = true
	_run()


func _spawn(key: String, team: int) -> Stickman:
	var s: Stickman = Stickman.new()
	s.name = "%s_%d" % [key, team]
	s.setup(key, team)
	add_child(s)
	return s


func _build_floor() -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(200.0, 200.0)
	mi.mesh = plane
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = BattlefieldData.COLOR_GRASS_A
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mi.material_override = mat
	add_child(mi)


func _run() -> void:
	await _wait(0.5)
	# Lineups: each unit type is a gold + red pair, facing the camera.
	_place_pairs(false)
	await _wait(0.6)
	_aim(Vector3(-4.5, 1.2, 0.0), Vector3(-4.5, 6.0, 12.0))
	await _wait(0.2)
	await _shot("lineup_1")
	_aim(Vector3(7.5, 1.2, 0.0), Vector3(7.5, 6.0, 12.0))
	await _wait(0.2)
	await _shot("lineup_2")
	_aim(Vector3(0.0, 2.0, 0.0), Vector3(0.0, 8.0, 30.0))
	_cam.fov = 28.0
	await _wait(0.2)
	await _shot("far")
	# Mid-attack duels, one shot per unit type.
	_cam.fov = 32.0
	_place_pairs(true)
	for i: int in UnitData.HUMANOID_ORDER.size():
		var key: String = UnitData.HUMANOID_ORDER[i]
		var t: float = float(STRIKE_TIME[String(UnitData.LOOKS[key].style)])
		for s: Stickman in [_gold[i], _red[i]]:
			s.player.playback_default_blend_time = 0.0  # no crossfade, so the frozen pose is the real strike pose
			s.play("attack", 1.0, true)
			s.player.seek(t, true)
			s.player.pause()
		var cx: float = (float(i) - 3.0) * DUEL_SPACING
		_aim(Vector3(cx, 1.15, 0.0), Vector3(cx, 2.4, 6.2))
		await _wait(0.25)
		await _shot("attack_" + key)
	get_tree().quit()


func _place_pairs(duel: bool) -> void:
	for i: int in _gold.size():
		var g: Stickman = _gold[i]
		var r: Stickman = _red[i]
		if duel:
			var cx: float = (float(i) - 3.0) * DUEL_SPACING
			g.position = Vector3(cx - DUEL_GAP, 0.0, 0.0)
			r.position = Vector3(cx + DUEL_GAP, 0.0, 0.0)
			g.rotation.y = -deg_to_rad(105.0)  # face +X and a little toward the camera
			r.rotation.y = deg_to_rad(105.0)
		else:
			var cx2: float = (float(i) - 3.0) * PAIR_SPACING
			g.position = Vector3(cx2 - 0.75, 0.0, 0.0)
			r.position = Vector3(cx2 + 0.75, 0.0, 0.0)
			g.rotation.y = PI
			r.rotation.y = PI
			g.play("idle")
			r.play("idle")


func _aim(target: Vector3, from: Vector3) -> void:
	_cam.position = from
	_cam.look_at(target)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var dir: String = ProjectSettings.globalize_path("res://screenshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var path: String = dir.path_join("%s_%s.png" % [_tag, shot_name])
	img.save_png(path)
	print("Screenshot saved: ", path)
