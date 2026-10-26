class_name Battle
extends Node3D
## Battle scene root. Step 1: builds the battlefield (terrain, sky, props, fortresses).

const SHOT_DELAY: float = 3.0

var terrain: Terrain
var player_fortress: Fortress
var enemy_fortress: Fortress
var hero: Hero
var hero_camera: HeroCamera
var army: ArmyManager
var fx: Effects
var hud: Hud
var level: int = 1
var enemy_level: int = 1
var spawner: EnemySpawner
var boss: Boss
var ended: bool = false

var _clouds: Node3D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	Settings.init()
	InputSetup.ensure()
	_rng.seed = BattlefieldData.SCENE_SEED
	_build_environment()
	terrain = Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.build()
	_build_mountains()
	_scatter_props()
	player_fortress = _make_fortress(Fortress.Team.PLAYER, BattlefieldData.FORTRESS_Z, 0.0)
	enemy_fortress = _make_fortress(Fortress.Team.ENEMY, -BattlefieldData.FORTRESS_Z, PI)
	fx = Effects.new()
	fx.name = "Effects"
	fx.battle = self
	add_child(fx)
	_spawn_hero()
	army = ArmyManager.new()
	army.name = "Army"
	army.battle = self
	add_child(army)
	var pause: PauseMenu = PauseMenu.new()
	pause.name = "PauseMenu"
	pause.battle = self
	add_child(pause)
	_setup_level()  # before the HUD, so it shows the right level, fortress HP and boss
	hud = Hud.new()
	hud.name = "Hud"
	hud.battle = self
	add_child(hud)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("--hud-test"):
		var ht: HudAutotest = HudAutotest.new()
		ht.battle = self
		add_child(ht)
	if args.has("--battle-test"):
		spawner.enabled = false
		var bt: BattleAutotest = BattleAutotest.new()
		bt.battle = self
		add_child(bt)
	if args.has("--hero-test"):
		spawner.enabled = false
		_spawn_dummies()  # only the scripted hero test uses punching bags
		var test: HeroAutotest = HeroAutotest.new()
		test.battle = self
		add_child(test)
	if args.has("--units-test"):
		spawner.enabled = false
		var ut: UnitsAutotest = UnitsAutotest.new()
		ut.battle = self
		add_child(ut)
	if args.has("--pause-test"):
		spawner.enabled = false
		_run_pause_test()
	if args.has("--select-test"):
		spawner.enabled = false
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			print("SELECT-TEST battle loaded: level=", level, " boss=", boss != null, " shielded=", enemy_fortress.shielded)
			get_tree().quit())
	if args.has("--boss-test"):
		var bt2: BossAutotest = BossAutotest.new()
		bt2.battle = self
		add_child(bt2)
	if args.has("--skills-test"):
		spawner.enabled = false
		var st: SkillsAutotest = SkillsAutotest.new()
		st.battle = self
		add_child(st)
	if args.has("--orders-test"):
		spawner.enabled = false
		var ot: OrdersAutotest = OrdersAutotest.new()
		ot.battle = self
		add_child(ot)
	if args.has("--level-test"):
		spawner.enabled = false
		var lt: LevelAutotest = LevelAutotest.new()
		lt.battle = self
		add_child(lt)
	if OS.is_debug_build() and not OS.has_feature("web"):
		get_tree().create_timer(SHOT_DELAY).timeout.connect(_save_screenshot)


func _make_fortress(team: Fortress.Team, z: float, yaw: float) -> Fortress:
	var f: Fortress = Fortress.new()
	f.team = team
	f.name = "PlayerFortress" if team == Fortress.Team.PLAYER else "EnemyFortress"
	f.position = Vector3(0, terrain.height_at(0, z), z)
	f.rotation.y = yaw
	add_child(f)
	return f


func _build_environment() -> void:
	_clouds = SkySetup.build(self)


func _process(delta: float) -> void:
	if _clouds != null:
		_clouds.rotation.y += deg_to_rad(0.35) * delta


func _toon(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


func _build_mountains() -> void:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 1.0
	mesh.height = 1.0
	mesh.radial_segments = 6
	mesh.rings = 1
	var xfs: Array[Transform3D] = []
	for i: int in 26:
		var t: float = float(i) / 26.0
		var ang: float = t * TAU
		var r: float = 215.0 + _rng.randf_range(-10.0, 30.0)
		var h: float = _rng.randf_range(55.0, 110.0)
		var rad: float = h * _rng.randf_range(0.7, 1.0)
		var b: Basis = Basis.from_scale(Vector3(rad, h, rad)).rotated(Vector3.UP, _rng.randf() * TAU)
		xfs.append(Transform3D(b, Vector3(cos(ang) * r, h * 0.5 - 6.0, sin(ang) * r)))
	_add_multimesh("Mountains", mesh, _toon(BattlefieldData.COLOR_MOUNTAIN), xfs)


func _scatter_props() -> void:
	# Trees: pine = trunk + two cones, three shared multimeshes.
	var trunk: CylinderMesh = CylinderMesh.new()
	trunk.top_radius = 0.18
	trunk.bottom_radius = 0.26
	trunk.height = 1.6
	trunk.radial_segments = 5
	trunk.rings = 1
	var cone_lo: CylinderMesh = CylinderMesh.new()
	cone_lo.top_radius = 0.0
	cone_lo.bottom_radius = 1.5
	cone_lo.height = 2.6
	cone_lo.radial_segments = 6
	cone_lo.rings = 1
	var cone_hi: CylinderMesh = cone_lo.duplicate()
	cone_hi.bottom_radius = 1.05
	cone_hi.height = 2.2
	var t_trunk: Array[Transform3D] = []
	var t_lo: Array[Transform3D] = []
	var t_hi: Array[Transform3D] = []
	var rocks: Array[Transform3D] = []
	var blobs: Array[Vector3] = []  # x, z, radius
	var placed: int = 0
	var guard: int = 0
	while placed < int(round(float(BattlefieldData.TREE_COUNT) * Settings.prop_density())) and guard < 2000:
		guard += 1
		var side: float = -1.0 if _rng.randf() < 0.5 else 1.0
		var x: float = side * _rng.randf_range(BattlefieldData.FIELD_HALF_WIDTH + 1.0, 46.0)
		var z: float = _rng.randf_range(-78.0, 78.0)
		if absf(z) > 62.0 and absf(x) < 30.0:
			continue
		var s: float = _rng.randf_range(0.9, 1.7)
		var y: float = terrain.height_at(x, z)
		t_trunk.append(Transform3D(Basis.from_scale(Vector3(s, s, s)), Vector3(x, y + 0.8 * s, z)))
		t_lo.append(Transform3D(Basis.from_scale(Vector3(s, s, s)), Vector3(x, y + 2.5 * s, z)))
		t_hi.append(Transform3D(Basis.from_scale(Vector3(s, s, s)), Vector3(x, y + 4.0 * s, z)))
		blobs.append(Vector3(x, z, 2.6 * s))
		placed += 1
	_add_multimesh("TreeTrunks", trunk, _toon(Color("5e4630")), t_trunk)
	_add_multimesh("TreeFoliageLow", cone_lo, _toon(Color("3f7a3a")), t_lo)
	_add_multimesh("TreeFoliageHigh", cone_hi, _toon(Color("4b8b43")), t_hi)

	# Rocks: flat-shaded faceted blobs; kept at the edges so the field stays open.
	var rock_mesh: ArrayMesh = _make_rock_mesh()
	for i: int in int(round(float(BattlefieldData.ROCK_COUNT) * Settings.prop_density())):
		var x: float
		x = (-1.0 if _rng.randf() < 0.5 else 1.0) * _rng.randf_range(BattlefieldData.FIELD_HALF_WIDTH + 0.5, 42.0)
		var z: float = _rng.randf_range(-70.0, 70.0)
		var sc: Vector3 = Vector3(_rng.randf_range(0.8, 2.4), _rng.randf_range(0.7, 1.8), _rng.randf_range(0.8, 2.4))
		var b: Basis = Basis.from_scale(sc).rotated(Vector3.UP, _rng.randf() * TAU)
		rocks.append(Transform3D(b, Vector3(x, terrain.height_at(x, z) + sc.y * 0.25, z)))
		blobs.append(Vector3(x, z, 1.4 * maxf(sc.x, sc.z)))
	_add_multimesh("Rocks", rock_mesh, _toon(Color("8b8d8f")), rocks)

	# One multimesh of blob shadows for every tree and rock.
	var sh_mesh: QuadMesh = QuadMesh.new()
	sh_mesh.size = Vector2.ONE
	sh_mesh.orientation = PlaneMesh.FACE_Y
	var sh: Array[Transform3D] = []
	for bl: Vector3 in blobs:
		var d: float = bl.z * 2.0
		sh.append(Transform3D(Basis.from_scale(Vector3(d, 1, d)), Vector3(bl.x, terrain.height_at(bl.x, bl.y) + 0.07, bl.y)))
	_add_multimesh("PropShadows", sh_mesh, BlobShadow.get_material(), sh)


func _make_rock_mesh() -> ArrayMesh:
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 1.4
	sphere.radial_segments = 6
	sphere.rings = 3
	var st: SurfaceTool = SurfaceTool.new()
	st.append_from(sphere, 0, Transform3D.IDENTITY)
	var m: ArrayMesh = st.commit()
	st = SurfaceTool.new()
	st.create_from(m, 0)
	st.deindex()
	st.generate_normals()
	return st.commit()


func _add_multimesh(node_name: String, mesh: Mesh, mat: Material, xfs: Array[Transform3D]) -> MultiMeshInstance3D:
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i: int in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mi.name = node_name
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi




func _save_screenshot() -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var dir: String = ProjectSettings.globalize_path("res://screenshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var path: String = dir.path_join("battle_%d.png" % Time.get_unix_time_from_system())
	img.save_png(path)
	print("Screenshot saved: ", path)


func _spawn_hero() -> void:
	hero = Hero.new()
	hero.name = "Hero"
	hero.terrain = terrain
	hero.battle = self
	var z: float = BattlefieldData.FORTRESS_Z - 10.0
	hero.position = Vector3(0.0, terrain.height_at(0.0, z), z)
	add_child(hero)
	hero.spawn_position = hero.global_position
	hero_camera = HeroCamera.new()
	hero_camera.name = "HeroCamera"
	hero_camera.target = hero
	hero_camera.terrain = terrain
	add_child(hero_camera)
	hero.camera = hero_camera


## Debug punching bags in front of the player fortress (removed once real units exist in step 4).
func _spawn_dummies() -> void:
	for p: Vector2 in [Vector2(0.8, 50.5), Vector2(-3.5, 47.0), Vector2(3.5, 44.0)]:
		var d: TrainingDummy = TrainingDummy.new()
		d.position = Vector3(p.x, terrain.height_at(p.x, p.y), p.y)
		d.rotation.y = PI  # face the hero
		add_child(d)


## Spawns a soldier at its team's fortress gate. Enemy strength follows the level multiplier.
func spawn_unit(key: String, team: int, spread: float = 4.0) -> Unit:
	var u: Unit = Unit.new()
	u.name = "%s_t%d" % [key, team]
	u.battle = self
	var z: float = (BattlefieldData.FORTRESS_Z - 8.0) * (1.0 if team == 0 else -1.0)
	var x: float = randf_range(-spread, spread)
	u.position = Vector3(x, terrain.height_at(x, z), z)
	u.rotation.y = 0.0 if team == 0 else PI
	add_child(u)
	u.setup(key, team, UnitData.level_multiplier(enemy_level) if team == 1 else 1.0)
	u.died.connect(army.on_unit_died)
	return u


## Spawns `count` of one unit type for a team (used by tests).
func spawn_wave(key: String, team: int, count: int) -> void:
	for i: int in count:
		spawn_unit(key, team, 6.0)


# --- Level flow ---------------------------------------------------------------------------------------

func _setup_level() -> void:
	GameState.load_progress()
	if OS.get_cmdline_user_args().has("--boss-test"):
		GameState.current_level = 5
	level = GameState.current_level
	enemy_level = level
	spawner = EnemySpawner.new()
	spawner.name = "EnemySpawner"
	spawner.setup(self, level)
	add_child(spawner)
	enemy_fortress.set_max_hp(float(LevelData.settings(level).fortress_hp))
	if LevelData.is_boss_level(level):
		_spawn_boss(level)
	enemy_fortress.destroyed.connect(func(_t: int) -> void: _finish(true))
	player_fortress.destroyed.connect(func(_t: int) -> void: _finish(false))
	hero.out_of_lives.connect(func() -> void: _finish(false))


func _finish(victory: bool) -> void:
	if ended:
		return
	ended = true
	if victory:
		GameState.level_won(level)
		_collapse(enemy_fortress)
	else:
		_collapse(player_fortress)
	# Let the fortress fall for a moment before the result screen appears.
	await get_tree().create_timer(1.6).timeout
	var screen: EndScreen = EndScreen.new()
	screen.name = "EndScreen"
	screen.battle = self
	add_child(screen)
	screen.show_result(victory, level)


func _collapse(f: Fortress) -> void:
	if f.hp > 0.0:
		return
	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(f, "position:y", f.position.y - 4.0, 1.5).set_ease(Tween.EASE_IN)
	t.tween_property(f, "rotation:z", 0.12, 1.5)


func _spawn_boss(lvl: int) -> void:
	var def: Dictionary = BossData.for_level(lvl)
	boss = Boss.new()
	boss.name = "Boss"
	boss.battle = self
	add_child(boss)
	boss.setup(String(def.key), 1, UnitData.level_multiplier(lvl))
	boss.configure(lvl)
	var z: float = -(BattlefieldData.FORTRESS_Z - 9.0)
	boss.global_position = Vector3(0.0, terrain.height_at(0.0, z), z)
	boss.rotation.y = PI
	enemy_fortress.set_shield(true)
	boss.died.connect(_on_boss_died)


func _on_boss_died(_u: Unit) -> void:
	enemy_fortress.set_shield(false)
	army.message.emit("Boss defeated! The fortress shield is down!")
	fx.shake(0.5, 0.8)
	fx.ring(boss.global_position, 12.0, Color("ffd24a"), 0.8)


## Scripted check of the pause menu (godot --path . res://scenes/battle.tscn -- --pause-test).
func _run_pause_test() -> void:
	await get_tree().create_timer(1.0).timeout
	var e: InputEventAction = InputEventAction.new()
	e.action = "ui_cancel"
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().create_timer(0.4).timeout
	var pm: PauseMenu = get_node("PauseMenu")
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step11_pause")
	print("PAUSE-TEST after Esc: menu visible=", pm.visible, " tree paused=", get_tree().paused)
	pm.close()
	await get_tree().create_timer(0.3).timeout
	print("PAUSE-TEST after Resume: menu visible=", pm.visible, " tree paused=", get_tree().paused)
	get_tree().quit()
