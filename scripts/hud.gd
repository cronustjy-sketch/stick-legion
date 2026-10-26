class_name Hud
extends CanvasLayer
## In-battle HUD (English only): gold, population, fortress HP bars, hero HP + lives,
## unit spawn buttons with portrait icons (hotkeys Z X C V B N M) and skill buttons (Q E R F, ultimate G).
## Mouse is captured while playing: press Esc to free it and click the buttons, or just use the hotkeys.

const PANEL_BG: Color = Color(0.07, 0.08, 0.1, 0.78)
const GOLD: Color = Color("e8b44a")
const RED: Color = Color("de4b3f")
const TEXT: Color = Color("f1ede2")
const DIM: Color = Color("9a978d")

var battle: Battle

var _gold_label: Label
var _pop_label: Label
var _player_bar: ProgressBar
var _player_label: Label
var _enemy_bar: ProgressBar
var _enemy_label: Label
var _hero_bar: ProgressBar
var _hero_label: Label
var _lives_label: Label
var _toast: Label
var _toast_tween: Tween
var _buttons: Dictionary = {}  # unit key -> {"button": Button, "cost": Label}


func _ready() -> void:
	layer = 10
	var root: Control = Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_top_left(root)
	_build_top_center(root)
	_build_top_right(root)
	_build_bottom_left(root)
	_build_spawn_bar(root)
	_build_skills(root)
	_toast = _label("", 22, GOLD)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast)
	_anchor(_toast, 0.5, 1.0, 190.0)
	_connect_signals()


func _connect_signals() -> void:
	battle.army.gold_changed.connect(_on_gold)
	battle.army.pop_changed.connect(_on_pop)
	battle.army.message.connect(show_toast)
	battle.player_fortress.hp_changed.connect(func(c: float, m: float) -> void: _set_fort(_player_bar, _player_label, "Your Fortress", c, m))
	battle.enemy_fortress.hp_changed.connect(func(c: float, m: float) -> void: _set_fort(_enemy_bar, _enemy_label, "Enemy Fortress", c, m))
	battle.hero.hp_changed.connect(_on_hero_hp)
	battle.hero.lives_changed.connect(_on_lives)
	_set_fort(_player_bar, _player_label, "Your Fortress", battle.player_fortress.hp, battle.player_fortress.max_hp)
	_set_fort(_enemy_bar, _enemy_label, "Enemy Fortress", battle.enemy_fortress.hp, battle.enemy_fortress.max_hp)
	_on_hero_hp(battle.hero.hp, battle.hero.max_hp)
	_on_lives(battle.hero.lives)
	_on_gold(int(battle.army.gold))
	_on_pop(battle.army.pop_used, battle.army.pop_cap)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or (event as InputEventKey).echo:
		return
	var k: InputEventKey = event
	for i: int in UnitData.HUMANOID_ORDER.size():
		if k.physical_keycode == EconomyData.SPAWN_KEYS[i]:
			battle.army.try_spawn(UnitData.HUMANOID_ORDER[i])


func _process(_delta: float) -> void:
	for key: String in _buttons:
		var affordable: bool = battle.army.why_not(key) == ""
		var b: Button = _buttons[key].button
		b.modulate = Color.WHITE if affordable else Color(0.55, 0.55, 0.55, 0.9)


func show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(0.9)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


# --- Updates ------------------------------------------------------------------------------------------

func _on_gold(g: int) -> void:
	_gold_label.text = "Gold  %d" % g


func _on_pop(used: int, cap: int) -> void:
	_pop_label.text = "Army  %d / %d" % [used, cap]
	_pop_label.add_theme_color_override("font_color", RED if used >= cap else TEXT)


func _set_fort(bar: ProgressBar, label: Label, title: String, cur: float, maximum: float) -> void:
	bar.max_value = maximum
	bar.value = cur
	label.text = "%s   %d / %d" % [title, ceili(cur), int(maximum)]


func _on_hero_hp(cur: float, maximum: float) -> void:
	_hero_bar.max_value = maximum
	_hero_bar.value = cur
	_hero_label.text = "Hero   %d / %d" % [ceili(cur), int(maximum)]


func _on_lives(lives: int) -> void:
	_lives_label.text = "Lives  %d" % lives


# --- Layout -------------------------------------------------------------------------------------------

func _build_top_left(root: Control) -> void:
	var p: PanelContainer = _panel(root)
	_anchor(p, 0.0, 0.0, 14.0)
	var v: VBoxContainer = VBoxContainer.new()
	p.add_child(v)
	_gold_label = _label("Gold  0", 26, GOLD)
	_pop_label = _label("Army  0 / 40", 20, TEXT)
	v.add_child(_gold_label)
	v.add_child(_pop_label)


func _build_top_center(root: Control) -> void:
	var p: PanelContainer = _panel(root)
	_anchor(p, 0.5, 0.0, 14.0)
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	p.add_child(h)
	var left: VBoxContainer = VBoxContainer.new()
	_player_label = _label("Your Fortress", 16, GOLD)
	_player_bar = _bar(GOLD, Vector2(280, 16))
	left.add_child(_player_label)
	left.add_child(_player_bar)
	var right: VBoxContainer = VBoxContainer.new()
	_enemy_label = _label("Enemy Fortress", 16, RED)
	_enemy_bar = _bar(RED, Vector2(280, 16))
	right.add_child(_enemy_label)
	right.add_child(_enemy_bar)
	h.add_child(left)
	h.add_child(right)


func _build_top_right(root: Control) -> void:
	var p: PanelContainer = _panel(root)
	_anchor(p, 1.0, 0.0, 14.0)
	var l: Label = _label("WASD move   Shift sprint   Space roll\nLeft click attack   Right click block\nZ X C V B N M  spawn units\nEsc  free the mouse", 14, DIM)
	p.add_child(l)


func _build_bottom_left(root: Control) -> void:
	var p: PanelContainer = _panel(root)
	_anchor(p, 0.0, 1.0, 14.0)
	var v: VBoxContainer = VBoxContainer.new()
	p.add_child(v)
	_hero_label = _label("Hero", 18, TEXT)
	_hero_bar = _bar(Color("5fc46a"), Vector2(200, 18))
	_lives_label = _label("Lives  3", 16, GOLD)
	v.add_child(_hero_label)
	v.add_child(_hero_bar)
	v.add_child(_lives_label)


func _build_spawn_bar(root: Control) -> void:
	var p: PanelContainer = _panel(root)
	_anchor(p, 0.5, 1.0, 14.0)
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	for i: int in UnitData.HUMANOID_ORDER.size():
		var key: String = UnitData.HUMANOID_ORDER[i]
		h.add_child(_spawn_button(key, OS.get_keycode_string(EconomyData.SPAWN_KEYS[i])))


func _spawn_button(key: String, hotkey: String) -> Button:
	var s: Dictionary = UnitData.STATS[key]
	var b: Button = Button.new()
	b.custom_minimum_size = Vector2(82, 132)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", _box(Color(0.14, 0.15, 0.18, 0.95), GOLD.darkened(0.4)))
	b.add_theme_stylebox_override("hover", _box(Color(0.2, 0.21, 0.26, 0.98), GOLD))
	b.add_theme_stylebox_override("pressed", _box(Color(0.3, 0.26, 0.14, 1.0), GOLD))
	var v: VBoxContainer = VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
	var icon: TextureRect = TextureRect.new()
	icon.texture = UnitIcons.make(self, key)
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)
	var name_l: Label = _label(String(s.name), 12, TEXT)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name_l)
	var cost: String = "%dg" % int(s.cost) + ("  pop %d" % int(s.pop) if int(s.pop) > 1 else "")
	var cost_l: Label = _label(cost, 15, GOLD)
	cost_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(cost_l)
	var hot: Label = _label(hotkey, 14, DIM)
	hot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(hot)
	hot.position = Vector2(7, 3)
	b.pressed.connect(func() -> void: battle.army.try_spawn(key))
	_buttons[key] = {"button": b, "cost": cost_l}
	return b


func _build_skills(root: Control) -> void:
	var p: PanelContainer = _panel(root)
	_anchor(p, 1.0, 1.0, 14.0)
	var v: VBoxContainer = VBoxContainer.new()
	p.add_child(v)
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	for k: String in ["Q", "E", "R", "F"]:
		h.add_child(_skill_slot(k, Vector2(52, 52)))
	var rage: HBoxContainer = HBoxContainer.new()
	v.add_child(rage)
	rage.add_child(_skill_slot("G", Vector2(52, 28)))
	var rage_bar: ProgressBar = _bar(Color("b86bd6"), Vector2(150, 16))
	rage_bar.value = 0.0
	rage_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rage.add_child(rage_bar)
	var note: Label = _label("Skills unlock later", 12, DIM)
	v.add_child(note)


func _skill_slot(key: String, size: Vector2) -> Control:
	var c: PanelContainer = PanelContainer.new()
	c.custom_minimum_size = size
	c.add_theme_stylebox_override("panel", _box(Color(0.12, 0.12, 0.15, 0.9), DIM.darkened(0.3)))
	var l: Label = _label(key, 24, DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	c.add_child(l)
	return c


# --- Widgets ------------------------------------------------------------------------------------------

func _panel(parent: Control) -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _box(PANEL_BG, GOLD.darkened(0.5), 10, 10))
	parent.add_child(p)
	return p


func _box(bg: Color, border: Color, margin: int = 6, radius: int = 8) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


func _label(text: String, size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 3)
	return l


func _bar(fill: Color, min_size: Vector2) -> ProgressBar:
	var b: ProgressBar = ProgressBar.new()
	b.custom_minimum_size = min_size
	b.show_percentage = false
	b.add_theme_stylebox_override("background", _box(Color(0.05, 0.05, 0.06, 0.95), Color(0, 0, 0, 1), 0, 4))
	b.add_theme_stylebox_override("fill", _box(fill, fill.darkened(0.4), 0, 4))
	return b


## Pins a control to a screen corner/edge (ax: 0 left, 0.5 centre, 1 right; ay: 0 top, 1 bottom).
## It grows away from that edge, so it always stays fully on screen whatever its size.
func _anchor(c: Control, ax: float, ay: float, margin: float) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.grow_horizontal = Control.GROW_DIRECTION_END if ax == 0.0 else (Control.GROW_DIRECTION_BEGIN if ax == 1.0 else Control.GROW_DIRECTION_BOTH)
	c.grow_vertical = Control.GROW_DIRECTION_END if ay == 0.0 else Control.GROW_DIRECTION_BEGIN
	var sx: float = margin if ax == 0.0 else (-margin if ax == 1.0 else 0.0)
	var sy: float = margin if ay == 0.0 else -margin
	c.offset_left = sx
	c.offset_right = sx
	c.offset_top = sy
	c.offset_bottom = sy
