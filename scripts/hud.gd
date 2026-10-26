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
const ORDER_ACTIONS: Array[String] = ["order_charge", "order_hold", "order_follow", "order_retreat"]

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
var _hint_panel: PanelContainer
var _boss_panel: PanelContainer
var _boss_bars: Array[ProgressBar] = []
var _boss_labels: Array[Label] = []
var _banner: PanelContainer
var _banner_speaker: Label
var _banner_text: Label
var _banner_tween: Tween
var _shield_toast_cd: float = 0.0
var _skill_slots: Dictionary = {}
var _rage_bar: ProgressBar
var _rage_label: Label
var _level_label: Label
var _respawn_label: Label
var _toast_tween: Tween
var _order_buttons: Array[Button] = []
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
	_build_orders(root)
	_build_boss_bar(root)
	_build_bottom_left(root)
	_build_spawn_bar(root)
	_build_skills(root)
	_toast = _label("", 22, GOLD)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast)
	_anchor(_toast, 0.5, 1.0, 190.0)
	_level_label = _label("Level %d" % battle.level, 22, TEXT)
	root.add_child(_level_label)
	_anchor(_level_label, 0.5, 0.0, 92.0)
	_respawn_label = _label("", 34, RED)
	_respawn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_respawn_label)
	_anchor(_respawn_label, 0.5, 0.5, 0.0)
	_connect_signals()
	if TouchControls.wanted():
		_hint_panel.visible = false


func _connect_signals() -> void:
	battle.army.gold_changed.connect(_on_gold)
	battle.army.pop_changed.connect(_on_pop)
	battle.army.message.connect(show_toast)
	battle.army.order_changed.connect(_on_order)
	battle.enemy_fortress.shield_blocked.connect(_on_shield_blocked)
	_on_order(battle.army.order)
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
	for i: int in ORDER_ACTIONS.size():
		if event.is_action_pressed(ORDER_ACTIONS[i]):
			battle.army.set_order(i as ArmyManager.Order)
			return
	if not (event is InputEventKey) or not event.is_pressed() or (event as InputEventKey).echo:
		return
	var k: InputEventKey = event
	for i: int in UnitData.ALL_ORDER.size():
		if k.physical_keycode == EconomyData.SPAWN_KEYS[i]:
			battle.army.try_spawn(UnitData.ALL_ORDER[i])


func _process(_delta: float) -> void:
	_update_boss_bar()
	_update_skills()
	var wait: float = battle.hero.respawn_remaining()
	_respawn_label.text = "Respawning in %d" % ceili(wait) if wait > 0.0 else ""
	for key: String in _buttons:
		var affordable: bool = battle.army.why_not(key) == ""
		var b: Button = _buttons[key].button
		var locked: bool = battle.level < LevelData.unit_unlock(key) and not battle.unlock_all
		b.modulate = Color.WHITE if affordable else (Color(0.4, 0.4, 0.45, 0.85) if locked else Color(0.55, 0.55, 0.55, 0.9))
		var cl: Label = _buttons[key].cost
		var s: Dictionary = UnitData.STATS[key]
		cl.text = ("Level %d" % LevelData.unit_unlock(key)) if locked else ("%dg" % int(s.cost) + ("
%d pop" % int(s.pop) if int(s.pop) > 1 else ""))


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
	_hero_label.text = "Aldric   %d / %d" % [ceili(cur), int(maximum)]


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
	_hint_panel = p
	_anchor(p, 1.0, 0.0, 14.0)
	var l: Label = _label("WASD move   Shift sprint   Space roll\nLeft click attack   Right click block\nZ X C V B N M , . /  spawn units\nEsc  pause   Hold Alt  use the mouse", 14, DIM)
	p.add_child(l)


func _build_bottom_left(root: Control) -> void:
	var p: PanelContainer = _panel(root)
	_anchor(p, 0.0, 1.0, 14.0)
	var v: VBoxContainer = VBoxContainer.new()
	p.add_child(v)
	_hero_label = _label("Aldric", 18, TEXT)
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
	for i: int in UnitData.ALL_ORDER.size():
		var key: String = UnitData.ALL_ORDER[i]
		h.add_child(_spawn_button(key, EconomyData.SPAWN_KEY_LABELS[i]))


func _spawn_button(key: String, hotkey: String) -> Button:
	var s: Dictionary = UnitData.STATS[key]
	var b: Button = Button.new()
	b.custom_minimum_size = Vector2(62, 132)
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
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)
	var name_l: Label = _label(String(s.name), 10, TEXT)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.custom_minimum_size = Vector2(58, 28)
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name_l)
	var cost: String = "%dg" % int(s.cost) + ("
%d pop" % int(s.pop) if int(s.pop) > 1 else "")
	var cost_l: Label = _label(cost, 14, GOLD)
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
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	for id: String in ["q", "e", "r", "f"]:
		h.add_child(_skill_slot(id, Vector2(56, 66)))
	var rage: HBoxContainer = HBoxContainer.new()
	rage.add_theme_constant_override("separation", 8)
	v.add_child(rage)
	rage.add_child(_skill_slot("g", Vector2(56, 66)))
	var col: VBoxContainer = VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	rage.add_child(col)
	_rage_label = _label("Rage 0%", 14, Color("c996e8"))
	col.add_child(_rage_label)
	_rage_bar = _bar(Color("b86bd6"), Vector2(150, 16))
	_rage_bar.max_value = 100.0
	col.add_child(_rage_bar)


## One skill button: key letter, skill name, and a dark cooldown cover that shrinks as it recharges.
func _skill_slot(id: String, size: Vector2) -> Control:
	var def: Dictionary = HeroData.SKILLS[id]
	var c: Control = Control.new()
	c.custom_minimum_size = size
	var bg: Panel = Panel.new()
	bg.add_theme_stylebox_override("panel", _box(Color(0.12, 0.12, 0.15, 0.92), DIM.darkened(0.3), 0, 8))
	c.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var key_l: Label = _label(id.to_upper(), 26, TEXT)
	key_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(key_l)
	key_l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	key_l.offset_top = 4.0
	var name_l: Label = _label(String(def.name), 10, DIM)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(name_l)
	name_l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_l.offset_top = -18.0
	var cover: ColorRect = ColorRect.new()
	cover.color = Color(0, 0, 0, 0.62)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(cover)
	var cd_l: Label = _label("", 20, TEXT)
	cd_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(cd_l)
	cd_l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			battle.hero.skills.try_cast(id))
	_skill_slots[id] = {"root": c, "bg": bg, "key": key_l, "cover": cover, "cd": cd_l, "size": size}
	return c


func _update_skills() -> void:
	var sk: HeroSkills = battle.hero.skills
	for id: String in _skill_slots:
		var s: Dictionary = _skill_slots[id]
		var size: Vector2 = s.size
		var ready: bool = sk.is_ready(id)
		var frac: float = sk.cooldown_fraction(id)
		var cover: ColorRect = s.cover
		var cd_l: Label = s.cd
		var bg: Panel = s.bg
		var key_l: Label = s.key
		if id == "g":
			cover.size = Vector2.ZERO if ready else size
			cd_l.text = "" if ready else "%d%%" % int(100.0 * sk.rage / sk.rage_max())
		else:
			cover.size = Vector2(size.x, size.y * frac)
			cd_l.text = "" if ready else "%.1f" % sk.cooldown_left(id)
		bg.add_theme_stylebox_override("panel", _box(Color(0.3, 0.25, 0.1, 0.95) if ready else Color(0.12, 0.12, 0.15, 0.92), GOLD if ready else DIM.darkened(0.3), 0, 8))
		key_l.add_theme_color_override("font_color", Color("ffe9a8") if ready else DIM)
	_rage_bar.value = sk.rage
	_rage_label.text = "Rage %d%%  %s" % [int(100.0 * sk.rage / sk.rage_max()), "READY (G)" if sk.rage >= sk.rage_max() else ""]


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


# --- Army orders --------------------------------------------------------------------------------------

func _build_orders(root: Control) -> void:
	var p: PanelContainer = _panel(root)
	_anchor(p, 0.0, 0.0, 14.0)
	p.offset_top += 100.0  # sits under the gold / army panel
	p.offset_bottom += 100.0
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	p.add_child(v)
	v.add_child(_label("Army orders", 14, DIM))
	for i: int in ArmyManager.ORDER_NAMES.size():
		var b: Button = Button.new()
		b.text = "%d  %s" % [i + 1, ArmyManager.ORDER_NAMES[i]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(150, 34)
		b.add_theme_font_size_override("font_size", 17)
		b.pressed.connect(func() -> void: battle.army.set_order(i as ArmyManager.Order))
		v.add_child(b)
		_order_buttons.append(b)


func _on_order(o: int) -> void:
	for i: int in _order_buttons.size():
		var active: bool = i == o
		var b: Button = _order_buttons[i]
		b.add_theme_stylebox_override("normal", _box(Color(0.35, 0.28, 0.1, 1.0) if active else Color(0.14, 0.15, 0.18, 0.95), GOLD if active else GOLD.darkened(0.55), 4, 6))
		b.add_theme_stylebox_override("hover", _box(Color(0.3, 0.3, 0.36, 1.0), GOLD, 4, 6))
		b.add_theme_stylebox_override("pressed", _box(Color(0.4, 0.32, 0.12, 1.0), GOLD, 4, 6))
		b.add_theme_color_override("font_color", Color("ffe9a8") if active else TEXT)


# --- Boss bar + taunt banner -----------------------------------------------------------------------------

func _build_boss_bar(root: Control) -> void:
	_boss_panel = _panel(root)
	_anchor(_boss_panel, 0.5, 0.0, 124.0)
	var v: VBoxContainer = VBoxContainer.new()
	_boss_panel.add_child(v)
	for i: int in 2:
		var l: Label = _label("", 20, RED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		var b: ProgressBar = _bar(Color("b32a22"), Vector2(520, 20))
		v.add_child(b)
		_boss_labels.append(l)
		_boss_bars.append(b)
	_boss_panel.visible = false
	_banner = _panel(root)
	_anchor(_banner, 0.5, 0.0, 250.0)
	var bv: VBoxContainer = VBoxContainer.new()
	_banner.add_child(bv)
	_banner_speaker = _label("", 22, RED)
	_banner_speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(_banner_speaker)
	_banner_text = _label("", 26, TEXT)
	_banner_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_text.custom_minimum_size = Vector2(640, 0)
	bv.add_child(_banner_text)
	_banner.visible = false
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE


## A short line of dialogue (boss taunts). Fades after a few seconds.
func show_banner(speaker: String, text: String) -> void:
	_banner_speaker.text = speaker
	_banner_text.text = "\"%s\"" % text
	_banner.visible = true
	_banner.modulate.a = 1.0
	if _banner_tween != null:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_interval(4.0)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.8)
	_banner_tween.tween_callback(func() -> void: _banner.visible = false)


func _update_boss_bar() -> void:
	_shield_toast_cd -= get_process_delta_time()
	var shown: int = 0
	for b: Boss in battle.bosses:
		if shown >= 2 or not is_instance_valid(b) or not b.is_alive():
			continue
		_boss_labels[shown].visible = true
		_boss_bars[shown].visible = true
		_boss_bars[shown].max_value = b.max_hp
		_boss_bars[shown].value = b.hp
		_boss_labels[shown].text = "%s%s" % [b.boss_name, "   (enraged)" if b.phase >= 2 and b.def.thresholds.size() < 2 else ("   (phase %d)" % b.phase if b.def.thresholds.size() >= 2 else "")]
		shown += 1
	for i: int in range(shown, 2):
		_boss_labels[i].visible = false
		_boss_bars[i].visible = false
	_boss_panel.visible = shown > 0


func _on_shield_blocked() -> void:
	if _shield_toast_cd <= 0.0:
		_shield_toast_cd = 3.0
		show_toast("The fortress is shielded! Defeat the boss first.")
