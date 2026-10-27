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
var bosses: Array[Boss] = []
var ended: bool = false
var unlock_all: bool = false  # tests only: ignore the unit unlock levels

var _clouds: Node3D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	Settings.init()
	InputSetup.ensure()
	for a: String in OS.get_cmdline_user_args():
		if (a.ends_with("-test") and a != "--start-test") or a.begins_with("--boss-level="):
			GameState.persist = false  # scripted tests never touch the real save file
			unlock_all = true  # ...and may buy any unit
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
	Sfx.music("music_boss" if LevelData.is_boss_level(level) else "music_battle")
	if not unlock_all:  # every battle starts with four swordsmen already at the gate (scripted tests start empty)
		for i: int in 4:
			spawn_unit("swordsman", 0, 3.0)
		army.recount_pop()
	hud = Hud.new()
	hud.name = "Hud"
	hud.battle = self
	add_child(hud)
	if TouchControls.wanted():
		var tc: TouchControls = TouchControls.new()
		tc.name = "TouchControls"
		tc.battle = self
		add_child(tc)
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
	if args.has("--flow-test"):
		_run_flow_test()
	if args.has("--start-test"):
		spawner.enabled = false
		_run_start_test()
	if args.has("--aim-test"):
		spawner.enabled = false
		_run_aim_test()
	if args.has("--joy-test"):
		spawner.enabled = false
		_run_joy_test()
	if args.has("--jitter-test"):
		spawner.enabled = false
		_run_jitter_test()
	if args.has("--look-test"):
		spawner.enabled = false
		_run_look_test()
	if args.has("--touch-test"):
		spawner.enabled = false
		_run_touch_test()
	if args.has("--audio-test"):
		spawner.enabled = false
		_run_audio_test()
	if args.has("--pause-test"):
		spawner.enabled = false
		_run_pause_test()
	if args.has("--select-test"):
		spawner.enabled = false
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			print("SELECT-TEST battle loaded: level=", level, " boss=", boss != null, " shielded=", enemy_fortress.shielded)
			get_tree().quit())
	if args.has("--boss-test") or _has_arg_prefix("--boss-level="):
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
		var z: float = _rng.randf_range(-(BattlefieldData.FORTRESS_Z + 8.0), BattlefieldData.FORTRESS_Z + 8.0)
		if absf(z) > BattlefieldData.FORTRESS_Z - 8.0 and absf(x) < 30.0:
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
		var z: float = _rng.randf_range(-(BattlefieldData.FORTRESS_Z - 4.0), BattlefieldData.FORTRESS_Z - 4.0)
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
	var z: float = BattlefieldData.FORTRESS_Z - 16.0  # well outside the gate, so the camera never ends up inside the walls
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
	for p: Vector2 in [Vector2(0.8, BattlefieldData.FORTRESS_Z - 18.5), Vector2(-3.5, BattlefieldData.FORTRESS_Z - 22.0), Vector2(3.5, BattlefieldData.FORTRESS_Z - 25.0)]:
		var d: TrainingDummy = TrainingDummy.new()
		d.position = Vector3(p.x, terrain.height_at(p.x, p.y), p.y)
		d.rotation.y = PI  # face the hero
		add_child(d)


## Spawns a soldier at its team's fortress gate. Enemy strength follows the level multiplier.
func spawn_unit(key: String, team: int, spread: float = 4.0) -> Unit:
	var u: Unit = Unit.new()
	u.name = "%s_t%d" % [key, team]
	u.battle = self
	var z: float = (BattlefieldData.FORTRESS_Z - 12.0) * (1.0 if team == 0 else -1.0)
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
	for a: String in OS.get_cmdline_user_args():
		if a == "--boss-test":
			GameState.current_level = 5
		elif a.begins_with("--boss-level="):
			GameState.current_level = int(a.get_slice("=", 1))
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
	Sfx.music("", 0.6)
	if victory:
		GameState.level_won(level)
		_collapse(enemy_fortress)
		Sfx.play("fanfare", 0.0)
	else:
		_collapse(player_fortress)
		Sfx.play("defeat", 0.0)
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
	bosses.clear()
	var keys: Array = def.keys
	for i: int in keys.size():
		var b: Boss = Boss.new()
		b.name = "Boss_%d" % i
		b.battle = self
		add_child(b)
		b.setup(String(keys[i]), 1, 1.0 + 0.06 * float(lvl - 1))  # bosses scale a bit slower than normal enemies
		b.configure(lvl, def)
		var z: float = -(BattlefieldData.FORTRESS_Z - 12.0)
		var x: float = (float(i) - float(keys.size() - 1) * 0.5) * 6.0
		b.global_position = Vector3(x, terrain.height_at(x, z), z)
		b.rotation.y = PI
		b.died.connect(_on_boss_died)
		bosses.append(b)
	boss = bosses[0]
	enemy_fortress.set_shield(true)
	# The boss introduces itself a moment after the battle starts.
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		Sfx.play("roar", 0.0)
		banner(String(def.get("speaker", def.name)), String(def.appear)))


func _on_boss_died(dead: Unit) -> void:
	var def: Dictionary = BossData.for_level(level)
	var alive: Array[Boss] = []
	for b: Boss in bosses:
		if b.is_alive():
			alive.append(b)
	if bool(def.get("link", false)):
		for b: Boss in alive:
			b.enter_phase(b.phase + 1)  # the twins: when one falls, the other enrages
	if alive.is_empty():
		enemy_fortress.set_shield(false)
		army.message.emit(Loc.t("Boss defeated! The fortress shield is down!"))
		fx.shake(0.5, 0.8)
		fx.ring(dead.global_position, 12.0, Color("ffd24a"), 0.8)
		if String(def.get("defeated", "")) != "":
			banner(String(def.get("speaker", def.name)), String(def.defeated))
		if int(def.get("red_sky_phase", 0)) > 0:
			SkySetup.set_red_sky(self, false)


## A big line of dialogue over the battle (boss taunts). The HUD draws it.
func banner(speaker: String, text: String) -> void:
	if hud != null:
		hud.show_banner(speaker, text)


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


## Full-path check (godot --path . -- --flow-test): main menu -> Play -> level select -> Start -> this battle.
func _run_flow_test() -> void:
	await get_tree().create_timer(3.0).timeout
	var bought: bool = army.try_spawn("swordsman")
	await get_tree().create_timer(2.0).timeout
	print("FLOW-TEST battle reached from the main menu: level=", level, " bought swordsman=", bought,
		" player units=", get_tree().get_nodes_in_group("units_team0").size(), " enemy units=", get_tree().get_nodes_in_group("units_team1").size())
	get_tree().quit()


func _has_arg_prefix(prefix: String) -> bool:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return true
	return false


## Scripted check of sound (godot --path . res://scenes/battle.tscn -- --audio-test): a fight must trigger effects, the right music must play.
func _run_audio_test() -> void:
	var hub: Node = get_tree().root.get_node_or_null("AudioHub")
	print("AUDIO-TEST hub present: ", hub != null, "  music: ", hub.call("current_music"), "  buses: Master/Music/SFX = ",
		AudioServer.get_bus_index("Master"), "/", AudioServer.get_bus_index("Music"), "/", AudioServer.get_bus_index("SFX"))
	for i: int in 8:
		spawn_unit("swordsman", 0, 6.0).global_position = Vector3(float(i) - 4.0, 0.0, 6.0)
		spawn_unit("archer" if i % 2 == 0 else "swordsman", 1, 6.0).global_position = Vector3(float(i) - 4.0, 0.0, 2.0)
	Engine.time_scale = 3.0
	var peak: int = 0
	var seen: Dictionary = {}
	for k: int in 120:
		await get_tree().create_timer(0.1).timeout
		var playing: int = 0
		for p: Node in hub.get_children():
			var ap: AudioStreamPlayer = p as AudioStreamPlayer
			if ap != null and ap.bus == "SFX" and ap.playing:
				playing += 1
				seen[ap.stream.resource_path.get_file()] = true
		peak = maxi(peak, playing)
	Engine.time_scale = 1.0
	print("AUDIO-TEST during a fight: up to ", peak, " effects at once; sounds heard: ", seen.keys())
	hero.skills.rage = 100.0
	var e: InputEventAction = InputEventAction.new()
	e.action = "skill_g"
	e.pressed = true
	hero.mouse_gate = false
	Input.parse_input_event(e)
	await get_tree().create_timer(0.3).timeout
	var any: bool = false
	for p: Node in hub.get_children():
		var ap2: AudioStreamPlayer = p as AudioStreamPlayer
		if ap2 != null and ap2.playing and ap2.stream != null and ap2.stream.resource_path.get_file() == "horn.wav":
			any = true
	print("AUDIO-TEST ultimate horn playing: ", any)
	get_tree().quit()


## Scripted check of the phone controls (godot --path . res://scenes/battle.tscn -- --touch --touch-test): fake finger touches.
func _run_touch_test() -> void:
	await get_tree().create_timer(1.0).timeout
	var tc: TouchControls = get_node_or_null("TouchControls") as TouchControls
	print("TOUCH-TEST controls shown: ", tc != null, "  hero touch_active: ", hero.touch_active)
	var start: Vector3 = hero.global_position
	var down: InputEventScreenTouch = InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = Vector2(165.0, 455.0)
	Input.parse_input_event(down)
	var drag: InputEventScreenDrag = InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(165.0, 455.0 - 90.0)  # push the stick fully up = forward + sprint
	Input.parse_input_event(drag)
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step13_touch_controls")
	print("TOUCH-TEST joystick forward: hero moved ", snappedf(start.distance_to(hero.global_position), 0.1), " m (sprinting: ", hero.touch_sprint, ")")
	var up: InputEventScreenTouch = InputEventScreenTouch.new()
	up.index = 0
	up.pressed = false
	up.position = Vector2(165.0, 365.0)
	Input.parse_input_event(up)
	await get_tree().create_timer(0.3).timeout
	var yaw0: float = hero_camera.yaw
	var d2: InputEventScreenTouch = InputEventScreenTouch.new()
	d2.index = 2
	d2.pressed = true
	d2.position = Vector2(700.0, 300.0)
	Input.parse_input_event(d2)
	await get_tree().process_frame
	var m2: InputEventScreenDrag = InputEventScreenDrag.new()
	m2.index = 2
	m2.position = Vector2(760.0, 300.0)
	m2.relative = Vector2(60.0, 0.0)
	Input.parse_input_event(m2)
	await get_tree().process_frame
	var d3: InputEventScreenTouch = InputEventScreenTouch.new()
	d3.index = 2
	d3.pressed = false
	d3.position = Vector2(760.0, 300.0)
	Input.parse_input_event(d3)
	await get_tree().create_timer(0.2).timeout
	print("TOUCH-TEST camera drag turned the view by ", snappedf(rad_to_deg(hero_camera.yaw - yaw0), 0.1), " degrees")
	var atk: InputEventScreenTouch = InputEventScreenTouch.new()
	atk.index = 1
	atk.pressed = true
	atk.position = Vector2(1140.0, 455.0)
	Input.parse_input_event(atk)
	await get_tree().create_timer(0.25).timeout
	print("TOUCH-TEST attack button -> hero state ATTACK(1): ", hero.state)
	atk.pressed = false
	Input.parse_input_event(atk)
	await get_tree().create_timer(1.2).timeout
	var blk: InputEventScreenTouch = InputEventScreenTouch.new()
	blk.index = 3
	blk.pressed = true
	blk.position = Vector2(1040.0, 385.0)
	Input.parse_input_event(blk)
	await get_tree().create_timer(0.3).timeout
	print("TOUCH-TEST block held -> hero state BLOCK(3): ", hero.state)
	blk.pressed = false
	Input.parse_input_event(blk)
	await get_tree().create_timer(0.2).timeout
	print("TOUCH-TEST skill tap (HUD slot) cast Q: ", hero.skills.try_cast("q"))
	get_tree().quit()


## Looks at the hero from behind, the side and the front, standing and running (godot ... battle.tscn -- --look-test).
func _run_look_test() -> void:
	unlock_all = true
	hero.mouse_gate = false
	await get_tree().create_timer(0.8).timeout
	var cam: HeroCamera = hero_camera
	cam.distance = 3.2
	cam.pitch = 0.18
	var shots: Array = [["back_idle", 0.0, false], ["side_idle", PI * 0.5, false], ["front_idle", PI, false], ["back_run", 0.0, true], ["side_run", PI * 0.5, true]]
	for s: Array in shots:
		cam.yaw = float(s[1])
		var fwd: bool = bool(s[2])
		var e: InputEventAction = InputEventAction.new()
		e.action = "move_forward"
		e.pressed = fwd
		Input.parse_input_event(e)
		var sp: InputEventAction = InputEventAction.new()
		sp.action = "sprint"
		sp.pressed = fwd
		Input.parse_input_event(sp)
		cam.yaw = 0.0 if fwd else float(s[1])  # run straight ahead, then swing the camera round for the picture
		await get_tree().create_timer(1.2 if fwd else 0.6).timeout
		if fwd:
			cam.yaw = float(s[1])
			await get_tree().create_timer(0.25).timeout
		await RenderingServer.frame_post_draw
		var sk: Skeleton3D = hero.model.skeleton
		print("LOOK-TEST ", s[0], " scarf bone tilt (deg) 1..4: ", snappedf(rad_to_deg(sk.get_bone_pose_rotation(sk.find_bone("Scarf1")).get_euler().x), 1.0), " ", snappedf(rad_to_deg(sk.get_bone_pose_rotation(sk.find_bone("Scarf2")).get_euler().x), 1.0), " ", snappedf(rad_to_deg(sk.get_bone_pose_rotation(sk.find_bone("Scarf4")).get_euler().x), 1.0))
		DebugShot.save(get_viewport(), "look_aldric_" + String(s[0]))
		if fwd:
			hero.global_position = Vector3(0.0, 0.0, BattlefieldData.FORTRESS_Z - 16.0)
	get_tree().quit()


## Checks how a battle starts (godot ... battle.tscn -- --start-test): four swordsmen, short field, controls panel for 10 s.
func _run_start_test() -> void:
	hero.mouse_gate = false
	await get_tree().create_timer(1.0).timeout
	print("START-TEST gold units at start: ", get_tree().get_nodes_in_group("units_team0").size(), " (expect 4)  distance between fortresses: ",
		snappedf(absf(player_fortress.position.z - enemy_fortress.position.z), 0.1), " m (was 140)")
	print("START-TEST controls panel visible at 1 s: ", hud._hint_panel.visible, " (expect true)")
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "start_battle")
	await get_tree().create_timer(9.0).timeout
	print("START-TEST controls panel visible at 11.5 s: ", hud._hint_panel.visible, " (expect false)")
	hud._help_button.pressed.emit()
	print("START-TEST after pressing ?: ", hud._hint_panel.visible, " (expect true)")
	var victim: Unit = spawn_unit("swordsman", 1, 0.0)
	victim.passive = true
	victim.global_position = Vector3(10.0, terrain.height_at(10.0, 20.0), 20.0)
	var before: Vector3 = victim.global_position
	victim.take_damage(60.0, before + Vector3(0.0, 0.0, 3.0))  # killed by a blow from the +Z side
	await get_tree().create_timer(0.6).timeout
	var moved: Vector3 = victim.global_position - before
	print("START-TEST death knockback: moved ", snappedf(moved.length(), 0.1), " m, away from the attacker (z change ", snappedf(moved.z, 0.1), ", expect negative)")
	var cam_d: float = hero_camera.distance
	print("START-TEST default camera distance: ", cam_d, " (was 4.8)")
	get_tree().quit()


## Camera/hero smoothness at an uneven frame rate (godot ... battle.tscn -- --touch --jitter-test): sprints and measures per-frame speed.
func _run_jitter_test() -> void:
	unlock_all = true
	hero.mouse_gate = false
	Engine.max_fps = 45  # not a multiple of the 60 Hz physics rate: the classic phone stutter case
	await get_tree().create_timer(0.8).timeout
	hero.touch_move = Vector2(0.0, -1.0)
	hero.touch_sprint = true
	await get_tree().create_timer(0.6).timeout
	var cam: Camera3D = hero_camera.camera
	var last_c: Vector3 = cam.global_position
	var last_h: Vector3 = hero.global_position
	var probe: JitterProbe = JitterProbe.new()
	probe.hero = hero
	probe.cam = cam
	add_child(probe)
	await get_tree().create_timer(2.0).timeout
	hero.touch_move = Vector2.ZERO
	var cs: Array[float] = probe.cam_speeds
	var hs: Array[float] = probe.hero_speeds
	print("JITTER-TEST camera speed per frame: mean ", snappedf(_mean(cs), 0.01), " m/s, spread (std dev) ", snappedf(_std(cs), 0.01), "  |  hero: mean ", snappedf(_mean(hs), 0.01), " std ", snappedf(_std(hs), 0.01), "  (smooth = std near 0)")
	Engine.max_fps = 0
	get_tree().quit()


func _mean(a: Array[float]) -> float:
	var s: float = 0.0
	for v: float in a:
		s += v
	return s / float(a.size())


func _std(a: Array[float]) -> float:
	var m: float = _mean(a)
	var s: float = 0.0
	for v: float in a:
		s += (v - m) * (v - m)
	return sqrt(s / float(a.size()))


## Moving the joystick must never turn the camera (godot ... battle.tscn -- --touch --joy-test): sends the emulated mouse motion a phone browser adds to finger drags.
func _run_joy_test() -> void:
	hero.mouse_gate = false
	await get_tree().create_timer(0.8).timeout
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # worst case: the pointer got captured (e.g. after closing the pause menu)
	var yaw0: float = hero_camera.yaw
	var pitch0: float = hero_camera.pitch
	var down: InputEventScreenTouch = InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = Vector2(165.0, 455.0)
	Input.parse_input_event(down)
	for i: int in 20:
		var drag: InputEventScreenDrag = InputEventScreenDrag.new()
		drag.index = 0
		drag.position = Vector2(165.0 + 40.0 * sin(float(i)), 455.0 - 80.0)
		drag.relative = Vector2(25.0 * sin(float(i)), -4.0)
		Input.parse_input_event(drag)
		var mm: InputEventMouseMotion = InputEventMouseMotion.new()  # the emulated twin of that drag
		mm.position = drag.position
		mm.relative = drag.relative
		Input.parse_input_event(mm)
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	print("JOY-TEST camera yaw changed by ", snappedf(rad_to_deg(hero_camera.yaw - yaw0), 0.01), " deg, pitch by ", snappedf(rad_to_deg(hero_camera.pitch - pitch0), 0.01), " deg while the joystick moved (expect 0 / 0); hero moved: ", hero.touch_move != Vector2.ZERO)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().quit()


## Auto aim and attack speed (godot ... battle.tscn -- --aim-test): enemies beside and behind the hero must be hit by a single press; holding attack must keep swinging.
func _run_aim_test() -> void:
	hero.mouse_gate = false
	await get_tree().create_timer(0.8).timeout
	var c: Vector3 = hero.global_position
	for case: Array in [["beside (90 deg)", Vector3(3.0, 0.0, 0.0)], ["behind (180 deg)", Vector3(0.0, 0.0, 3.5)], ["far side (-100 deg)", Vector3(-2.6, 0.0, 0.8)]]:
		hero.rotation.y = 0.0  # facing -Z
		hero.state = Hero.State.FREE
		var e: Unit = spawn_unit("swordsman", 1, 0.0)
		e.passive = true
		e.max_hp = 500.0
		e.hp = 500.0
		e.global_position = c + (case[1] as Vector3)
		await get_tree().create_timer(0.2).timeout
		var t: InputEventAction = InputEventAction.new()
		t.action = "attack"
		t.pressed = true
		Input.parse_input_event(t)
		await get_tree().create_timer(0.1).timeout
		var to: Vector3 = e.global_position - hero.global_position
		var facing: float = rad_to_deg(hero.forward_vector().angle_to(Vector3(to.x, 0.0, to.z).normalized()))
		print("AIM-TEST enemy ", case[0], ": hero turned to face it instantly (error ", snappedf(facing, 0.1), " deg)")
		var t2: InputEventAction = InputEventAction.new()
		t2.action = "attack"
		t2.pressed = false
		Input.parse_input_event(t2)
		await get_tree().create_timer(0.9).timeout
		print("AIM-TEST   damage dealt by the first swing: ", int(500.0 - e.hp), " (expect 14)")
		e.queue_free()
		hero.state = Hero.State.FREE
		await get_tree().create_timer(0.8).timeout
	# Holding attack: count the swings in 3 seconds.
	var dummy: Unit = spawn_unit("swordsman", 1, 0.0)
	dummy.passive = true
	dummy.max_hp = 100000.0
	dummy.hp = 100000.0
	dummy.global_position = c + Vector3(0.0, 0.0, -1.8)
	hero.rotation.y = 0.0
	var swings: Array[int] = [0]
	hero.struck.connect(func(_h: int, _ci: int) -> void: swings[0] += 1)
	var hold: InputEventAction = InputEventAction.new()
	hold.action = "attack"
	hold.pressed = true
	Input.parse_input_event(hold)
	await get_tree().create_timer(3.0).timeout
	var rel: InputEventAction = InputEventAction.new()
	rel.action = "attack"
	rel.pressed = false
	Input.parse_input_event(rel)
	print("AIM-TEST holding attack for 3 s: ", swings[0], " swings landed (before the change: about 5)")
	get_tree().quit()
