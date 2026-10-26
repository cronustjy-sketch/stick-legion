class_name LevelSelect
extends Control
## The campaign map: 20 levels along a winding road. Click a level (or use the arrow keys) and press Start.
## Boss levels (every 5th) are bigger and red. English only.

const GOLD: Color = Color("e8b44a")
const RED: Color = Color("de4b3f")
const GREEN: Color = Color("5fc46a")
const TEXT: Color = Color("f1ede2")
const DIM: Color = Color("9a978d")

var selected: int = 1

var _points: Array[Vector2] = []
var _buttons: Array[Button] = []
var _map: Control
var _info_title: Label
var _info_body: Label
var _start: Button
var _cleared_label: Label
var _chapter_label: Label


func _ready() -> void:
	Settings.init()
	for a: String in OS.get_cmdline_user_args():
		if a.ends_with("-test"):
			GameState.persist = false
	GameState.load_progress()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	selected = clampi(GameState.highest_unlocked, 1, LevelData.LEVEL_COUNT)
	if OS.get_cmdline_user_args().has("--select-test"):
		GameState.mark_all_seen_for_test()
		GameState.highest_unlocked = 1
		selected = 1
	_build()
	_refresh()
	if OS.get_cmdline_user_args().has("--select-test"):
		_run_test()
	elif OS.get_cmdline_user_args().has("--flow-test"):
		get_tree().create_timer(0.8).timeout.connect(_play)
	elif OS.get_cmdline_user_args().has("--menu-test"):
		get_tree().create_timer(0.6).timeout.connect(func() -> void:
			print("MENU-TEST reached the level select after Play: ok")
			get_tree().quit())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not (event as InputEventKey).echo:
		var k: InputEventKey = event
		if k.keycode == KEY_RIGHT or k.keycode == KEY_D:
			_select(mini(selected + 1, mini(GameState.highest_unlocked, LevelData.LEVEL_COUNT)))
		elif k.keycode == KEY_LEFT or k.keycode == KEY_A:
			_select(maxi(selected - 1, 1))
		elif k.keycode == KEY_ENTER or k.keycode == KEY_SPACE or k.keycode == KEY_KP_ENTER:
			_play()


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map = Control.new()
	_map.name = "Map"
	add_child(_map)
	_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map.draw.connect(_draw_map)
	for i: int in LevelData.LEVEL_COUNT:
		var t: float = float(i) / float(LevelData.LEVEL_COUNT - 1)
		_points.append(Vector2(110.0 + t * 1060.0, 335.0 + sin(float(i) * 0.7) * 125.0))
	for i: int in LevelData.LEVEL_COUNT:
		var lvl: int = i + 1
		var b: Button = Button.new()
		b.name = "Level%d" % lvl
		b.text = str(lvl)
		b.focus_mode = Control.FOCUS_NONE
		var size: float = 76.0 if LevelData.is_boss_level(lvl) else 54.0
		b.custom_minimum_size = Vector2(size, size)
		b.size = Vector2(size, size)
		b.position = _points[i] - Vector2(size, size) * 0.5
		b.add_theme_font_size_override("font_size", 24 if size < 60.0 else 30)
		b.pressed.connect(_on_node_pressed.bind(lvl))
		add_child(b)
		_buttons.append(b)
	var back: Button = UiStyle.button("Main Menu", Vector2(150, 40), 18)
	add_child(back)
	back.position = Vector2(24.0, 64.0)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	var title: Label = _label("STICK LEGION", 54, GOLD)
	add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 18)
	var sub: Label = _label("Campaign map", 20, TEXT)
	add_child(sub)
	sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 82)
	_cleared_label = _label("", 20, GREEN)
	add_child(_cleared_label)
	_cleared_label.position = Vector2(24.0, 24.0)
	var tip: Label = _label("Mira: \"%s\"" % StoryData.MIRA_TIPS[randi() % StoryData.MIRA_TIPS.size()], 18, Color("f6d98a"))
	add_child(tip)
	tip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 108)
	if GameState.endless_unlocked():
		var endless: Button = UiStyle.button("Endless Mode", Vector2(220, 48), 22)
		add_child(endless)
		endless.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 18)
		endless.pressed.connect(func() -> void: StoryFlow.start_level(get_tree(), maxi(GameState.highest_unlocked, LevelData.LEVEL_COUNT + 1)))
	var panel: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.1, 0.9)
	sb.border_color = GOLD.darkened(0.45)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_top = -18.0
	panel.offset_bottom = -18.0
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	panel.add_child(row)
	var col: VBoxContainer = VBoxContainer.new()
	col.custom_minimum_size = Vector2(760.0, 0.0)
	row.add_child(col)
	_chapter_label = _label("", 16, DIM)
	col.add_child(_chapter_label)
	_info_title = _label("", 28, GOLD)
	_info_body = _label("", 17, TEXT)
	col.add_child(_info_title)
	col.add_child(_info_body)
	_start = Button.new()
	_start.text = "Start Level"
	_start.custom_minimum_size = Vector2(200.0, 64.0)
	_start.add_theme_font_size_override("font_size", 26)
	_start.focus_mode = Control.FOCUS_NONE
	_start.pressed.connect(_play)
	for st: String in ["normal", "hover", "pressed", "disabled"]:
		var sbx: StyleBoxFlat = StyleBoxFlat.new()
		sbx.bg_color = {"normal": Color("a67c2e"), "hover": Color("c99a3c"), "pressed": Color("8a6522"), "disabled": Color(0.25, 0.25, 0.28)}[st]
		sbx.set_corner_radius_all(10)
		sbx.border_color = GOLD
		sbx.set_border_width_all(2)
		_start.add_theme_stylebox_override(st, sbx)
	row.add_child(_start)


func _on_node_pressed(lvl: int) -> void:
	_select(lvl)


func _select(lvl: int) -> void:
	selected = clampi(lvl, 1, LevelData.LEVEL_COUNT)
	_refresh()


func _play() -> void:
	if selected > GameState.highest_unlocked:
		return
	StoryFlow.start_level(get_tree(), selected)


func _refresh() -> void:
	var unlocked: int = mini(GameState.highest_unlocked, LevelData.LEVEL_COUNT)
	var cleared: int = clampi(GameState.highest_unlocked - 1, 0, LevelData.LEVEL_COUNT)
	_cleared_label.text = "Levels cleared: %d / %d" % [cleared, LevelData.LEVEL_COUNT]
	for i: int in _buttons.size():
		var lvl: int = i + 1
		var boss: bool = LevelData.is_boss_level(lvl)
		var locked: bool = lvl > unlocked
		var done: bool = lvl <= cleared
		var base: Color = Color(0.3, 0.3, 0.33) if locked else (GREEN.darkened(0.25) if done else GOLD.darkened(0.15))
		var border: Color = RED if boss else (Color(0.5, 0.5, 0.5) if locked else (GREEN if done else GOLD.lightened(0.3)))
		if lvl == selected:
			border = Color.WHITE
		var radius: int = int(_buttons[i].size.x * 0.5)
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			var s: StyleBoxFlat = StyleBoxFlat.new()
			s.bg_color = base.lightened(0.12) if state == "hover" and not locked else base
			s.border_color = border
			s.set_border_width_all(5 if lvl == selected else 3)
			s.set_corner_radius_all(radius)
			_buttons[i].add_theme_stylebox_override(state, s)
		_buttons[i].add_theme_color_override("font_color", Color(0.75, 0.75, 0.75) if locked else Color("1b1b1f"))
		_buttons[i].text = str(lvl)
		_buttons[i].disabled = false
	var st: Dictionary = LevelData.settings(selected)
	var locked_sel: bool = selected > unlocked
	var title: String = "Level %d  -  %s" % [selected, String(st.name)]
	_chapter_label.text = "Chapter %d: %s" % [LevelData.chapter_of(selected), LevelData.chapter_name(selected)]
	_info_title.text = title + ("   (locked)" if locked_sel else "")
	var names: PackedStringArray = PackedStringArray()
	for k: String in st.pool:
		names.append(String(UnitData.STATS[k].name))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Enemy strength x%.2f     Enemy fortress %d HP" % [float(st.multiplier), int(float(st.fortress_hp))])
	lines.append("Enemy army: " + ", ".join(names))
	if not (st.boss as Dictionary).is_empty():
		lines.append("BOSS: %s  (the fortress is shielded until the boss falls)" % String((st.boss as Dictionary).name).replace("The ", "The "))
	else:
		lines.append("No boss on this level.")
	_info_body.text = "\n".join(lines)
	_info_title.add_theme_color_override("font_color", RED if not (st.boss as Dictionary).is_empty() else GOLD)
	_start.disabled = locked_sel
	_map.queue_redraw()


func _draw_map() -> void:
	var w: float = size.x
	var h: float = size.y
	# Sky and ground.
	var sky: PackedColorArray = PackedColorArray([Color("2c6cc4"), Color("2c6cc4"), Color("9fd2f2"), Color("9fd2f2")])
	_map.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.55), Vector2(0, h * 0.55)]), sky)
	var ground: PackedColorArray = PackedColorArray([Color("86a94f"), Color("86a94f"), Color("5f8a3a"), Color("5f8a3a")])
	_map.draw_polygon(PackedVector2Array([Vector2(0, h * 0.28), Vector2(w, h * 0.28), Vector2(w, h), Vector2(0, h)]), ground)
	# Hills and mountains.
	for i: int in 9:
		var cx: float = float(i) * w / 8.0
		var peak: float = 0.14 + 0.07 * sin(float(i) * 1.7)
		_map.draw_colored_polygon(PackedVector2Array([Vector2(cx - 150, h * 0.3), Vector2(cx, h * (0.2 - peak * 0.4)), Vector2(cx + 150, h * 0.3)]), Color("7d8fa8").darkened(0.05 * float(i % 3)))
	# The road.
	if _points.size() > 1:
		_map.draw_polyline(PackedVector2Array(_points), Color(0.35, 0.26, 0.15, 0.55), 22.0, true)
		_map.draw_polyline(PackedVector2Array(_points), Color("c9a86a"), 14.0, true)
		var cleared: int = clampi(GameState.highest_unlocked - 1, 0, LevelData.LEVEL_COUNT)
		if cleared >= 2:
			_map.draw_polyline(PackedVector2Array(_points.slice(0, cleared)), GREEN, 6.0, true)
	# Enemy fortress at the end of the road.
	var end: Vector2 = _points[_points.size() - 1] + Vector2(70.0, -10.0)
	_map.draw_rect(Rect2(end + Vector2(-26, -34), Vector2(52, 44)), Color("8d8a84"))
	_map.draw_rect(Rect2(end + Vector2(-32, -48), Vector2(14, 58)), Color("8d8a84"))
	_map.draw_rect(Rect2(end + Vector2(18, -48), Vector2(14, 58)), Color("8d8a84"))
	_map.draw_colored_polygon(PackedVector2Array([end + Vector2(-36, -48), end + Vector2(-25, -66), end + Vector2(-14, -48)]), RED)
	_map.draw_colored_polygon(PackedVector2Array([end + Vector2(14, -48), end + Vector2(25, -66), end + Vector2(36, -48)]), RED)
	# Your fortress at the start.
	var start: Vector2 = _points[0] + Vector2(-70.0, 8.0)
	_map.draw_rect(Rect2(start + Vector2(-22, -30), Vector2(44, 40)), Color("b6c0cc"))
	_map.draw_colored_polygon(PackedVector2Array([start + Vector2(-26, -30), start + Vector2(0, -56), start + Vector2(26, -30)]), GOLD)


func _label(text: String, font_size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	return l


# --- Scripted check (godot --path . -- --select-test) -----------------------------------------------------

func _run_test() -> void:
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step10_levelselect_new")
	GameState.highest_unlocked = 8
	_select(5)
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step10_levelselect_boss")
	print("SELECT-TEST selected=", selected, " unlocked=", GameState.highest_unlocked, " info: ", _info_title.text)
	_on_node_pressed(7)
	_start.pressed.emit()
