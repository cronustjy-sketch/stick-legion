class_name MainMenu
extends Node3D
## Title screen: a small 3D scene (the hero and a skirmish) behind Play / Settings / Credits / Quit.
## "Created by Junyuan" is shown on the title and in the credits. English only.

var _ui: CanvasLayer
var _menu: VBoxContainer
var _settings_panel: PanelContainer
var _credits_panel: PanelContainer
var _cam: Camera3D
var _t: float = 0.0
var _fighters: Array[Stickman] = []
var _fight_clock: float = 0.0


func _ready() -> void:
	Settings.init()
	GameState.load_progress()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	SkySetup.build(self)
	_build_world()
	_build_ui()
	if OS.get_cmdline_user_args().has("--menu-test"):
		_run_test()


func _process(delta: float) -> void:
	_t += delta
	_cam.position = Vector3(0.9 + sin(_t * 0.25) * 0.8, 2.0, 9.6 + cos(_t * 0.2) * 0.3)
	_cam.look_at(Vector3(-0.9, 1.2, 0.0))
	_fight_clock += delta
	if _fight_clock >= 1.1:
		_fight_clock = 0.0
		for s: Stickman in _fighters:
			if randf() < 0.55:
				s.play("attack", 1.0, true)


# --- 3D backdrop --------------------------------------------------------------------------------------

func _build_world() -> void:
	var floor_mi: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(300.0, 300.0)
	floor_mi.mesh = plane
	floor_mi.material_override = _toon(BattlefieldData.COLOR_GRASS_A)
	add_child(floor_mi)
	var cone: CylinderMesh = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.0
	cone.height = 1.0
	cone.radial_segments = 6
	cone.rings = 1
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in 16:
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = cone
		mi.material_override = _toon(BattlefieldData.COLOR_MOUNTAIN)
		var ang: float = float(i) / 16.0 * TAU
		var h: float = rng.randf_range(30.0, 70.0)
		mi.scale = Vector3(h * 0.9, h, h * 0.9)
		mi.position = Vector3(cos(ang) * 120.0, h * 0.5 - 4.0, sin(ang) * 120.0)
		add_child(mi)
	# Trees at the sides.
	var trunk: CylinderMesh = CylinderMesh.new()
	trunk.top_radius = 0.2
	trunk.bottom_radius = 0.28
	trunk.height = 1.8
	trunk.radial_segments = 5
	trunk.rings = 1
	for i: int in 14:
		var x: float = rng.randf_range(-22.0, 22.0)
		var z: float = rng.randf_range(-30.0, -6.0)
		if absf(x) < 8.0:
			continue
		var s: float = rng.randf_range(1.2, 2.0)
		var tr: MeshInstance3D = MeshInstance3D.new()
		tr.mesh = trunk
		tr.material_override = _toon(Color("5e4630"))
		tr.scale = Vector3.ONE * s
		tr.position = Vector3(x, 0.9 * s, z)
		add_child(tr)
		for lvl: int in 2:
			var leaf: MeshInstance3D = MeshInstance3D.new()
			leaf.mesh = cone
			leaf.material_override = _toon(Color("3f7a3a").lightened(0.1 * float(lvl)))
			leaf.scale = Vector3(1.7, 2.6 - 0.4 * float(lvl), 1.7) * s
			leaf.position = Vector3(x, (2.5 + 1.6 * float(lvl)) * s, z)
			add_child(leaf)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.current = true
	# The hero in front, a gold squad behind him, a red squad facing them.
	_unit("hero", 0, Vector3(1.4, 0.0, 1.2), 0.35)
	_unit("swordsman", 0, Vector3(-0.8, 0.0, 0.0), -0.25)
	_unit("spearman", 0, Vector3(-2.2, 0.0, -1.0), -0.2)
	_unit("archer", 0, Vector3(-3.6, 0.0, -0.4), -0.2)
	_unit("swordsman", 1, Vector3(4.1, 0.0, -0.2), PI + 0.25)
	_unit("shield_knight", 1, Vector3(5.6, 0.0, 0.8), PI + 0.2)
	_unit("mage", 1, Vector3(7.0, 0.0, -0.9), PI + 0.25)


func _unit(key: String, team: int, pos: Vector3, yaw: float) -> void:
	var s: Stickman = Stickman.new()
	s.setup(key, team)
	s.position = pos
	s.rotation.y = yaw
	add_child(s)
	if key != "hero":
		_fighters.append(s)


func _toon(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


# --- UI -----------------------------------------------------------------------------------------------

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	var root: Control = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 14)
	root.add_child(_menu)
	_menu.position = Vector2(70.0, 70.0)
	var title: Label = UiStyle.label("STICK LEGION", 84, UiStyle.GOLD)
	title.add_theme_constant_override("outline_size", 10)
	_menu.add_child(title)
	var tag: Label = UiStyle.label("Lead your stickman army to victory", 24)
	_menu.add_child(tag)
	_menu.add_child(Control.new())
	var play: Button = UiStyle.button("Play", Vector2(300, 64), 30)
	play.pressed.connect(_on_play)
	_menu.add_child(play)
	var settings: Button = UiStyle.button("Settings", Vector2(300, 56), 24)
	settings.pressed.connect(_show_settings)
	_menu.add_child(settings)
	var credits: Button = UiStyle.button("Credits", Vector2(300, 56), 24)
	credits.pressed.connect(_show_credits)
	_menu.add_child(credits)
	if not OS.has_feature("web"):
		var quit: Button = UiStyle.button("Quit", Vector2(300, 56), 24)
		quit.pressed.connect(func() -> void: get_tree().quit())
		_menu.add_child(quit)
	var by: Label = UiStyle.label("Created by Junyuan", 22, UiStyle.TEXT)
	root.add_child(by)
	by.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 24)
	_settings_panel = UiStyle.panel(root)
	_settings_panel.visible = false
	var sp: SettingsPanel = SettingsPanel.new()
	sp.closed.connect(_show_menu)
	_settings_panel.add_child(sp)
	_center(_settings_panel)
	_credits_panel = UiStyle.panel(root)
	_credits_panel.visible = false
	var cv: VBoxContainer = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 14)
	cv.custom_minimum_size = Vector2(520, 0)
	_credits_panel.add_child(cv)
	cv.add_child(UiStyle.label("Credits", 40, UiStyle.GOLD))
	cv.add_child(UiStyle.label("A game by Junyuan", 30))
	cv.add_child(UiStyle.label("Game design, art and code: Junyuan", 20, UiStyle.DIM))
	cv.add_child(UiStyle.label("Built with Godot Engine 4.7.2", 20, UiStyle.DIM))
	cv.add_child(UiStyle.label("Thank you for playing!", 24, UiStyle.GOLD))
	var back: Button = UiStyle.button("Back", Vector2(200, 50), 22)
	back.pressed.connect(_show_menu)
	cv.add_child(back)
	_center(_credits_panel)


func _center(c: Control) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.5
	c.anchor_bottom = 0.5
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	c.grow_vertical = Control.GROW_DIRECTION_BOTH


func _show_menu() -> void:
	_menu.visible = true
	_settings_panel.visible = false
	_credits_panel.visible = false


func _show_settings() -> void:
	_menu.visible = false
	_settings_panel.visible = true


func _show_credits() -> void:
	_menu.visible = false
	_credits_panel.visible = true


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


# --- Scripted check (godot --path . -- --menu-test) ---------------------------------------------------------

func _run_test() -> void:
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step11_menu")
	_show_settings()
	var sliders: Array[Node] = _settings_panel.find_children("*", "HSlider", true, false)
	(sliders[0] as HSlider).value = 0.4
	(sliders[1] as HSlider).value = 0.25
	var opt: OptionButton = _settings_panel.find_children("*", "OptionButton", true, false)[0] as OptionButton
	opt.select(0)
	opt.item_selected.emit(0)
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step11_settings")
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(Settings.PATH)
	print("MENU-TEST settings saved: master=", cfg.get_value("audio", "master"), " music=", cfg.get_value("audio", "music"), " quality=", cfg.get_value("graphics", "quality"),
		" | master bus dB=", snappedf(AudioServer.get_bus_volume_db(0), 0.1), " (expect -7.9 for 0.4)",
		" | buses: ", AudioServer.get_bus_index("Music") != -1, "/", AudioServer.get_bus_index("SFX") != -1)
	_show_credits()
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step11_credits")
	# Put the settings back to normal before the real game.
	Settings.master = 0.8
	Settings.music = 0.7
	Settings.quality = 2
	Settings.apply()
	Settings.save()
	_show_menu()
	_on_play()
