class_name Armory
extends Control
## The Armory: spend stars on upgrades (5 tiers each). Opened from the campaign map. Numbers live in data/upgrades.gd.

signal closed

var _stars_label: Label
var _hero_col: VBoxContainer
var _army_col: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = UiStyle.panel(self)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var head: HBoxContainer = HBoxContainer.new()
	head.add_theme_constant_override("separation", 24)
	v.add_child(head)
	head.add_child(UiStyle.label("Armory", 40, UiStyle.GOLD))
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	_stars_label = UiStyle.label("", 24, StarRow.GOLD)
	head.add_child(_stars_label)
	var cols: HBoxContainer = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 30)
	v.add_child(cols)
	_hero_col = VBoxContainer.new()
	_hero_col.add_theme_constant_override("separation", 8)
	cols.add_child(_hero_col)
	_army_col = VBoxContainer.new()
	_army_col.add_theme_constant_override("separation", 8)
	cols.add_child(_army_col)
	var back: Button = UiStyle.button("Back", Vector2(200, 46), 22)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	v.add_child(back)
	_refresh()


func _refresh() -> void:
	_stars_label.text = Loc.f("Stars to spend: %d", [GameState.stars_available()])
	for col: VBoxContainer in [_hero_col, _army_col]:
		for c: Node in col.get_children():
			c.queue_free()
	_hero_col.add_child(UiStyle.label("Hero", 26, UiStyle.GOLD))
	_army_col.add_child(UiStyle.label("Army", 26, UiStyle.GOLD))
	for key: String in UpgradeData.ORDER:
		var col: VBoxContainer = _hero_col if String(UpgradeData.DEFS[key].group) == "hero" else _army_col
		col.add_child(_row(key))


func _row(key: String) -> Control:
	var tier: int = GameState.upgrade_tier(key)
	var maxed: bool = tier >= UpgradeData.MAX_TIER
	var box: PanelContainer = PanelContainer.new()
	box.name = "Row_" + key
	box.add_theme_stylebox_override("panel", UiStyle.box(Color(0.11, 0.11, 0.13, 0.95), UiStyle.GOLD.darkened(0.55), 8, 8, 1))
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	box.add_child(h)
	var info: VBoxContainer = VBoxContainer.new()
	info.custom_minimum_size = Vector2(300, 0)
	info.add_theme_constant_override("separation", 0)
	h.add_child(info)
	info.add_child(UiStyle.label(String(UpgradeData.DEFS[key].name), 20))
	info.add_child(UiStyle.label(String(UpgradeData.BLURBS[key]), 13, UiStyle.DIM))
	var now: String = UpgradeData.show(key, UpgradeData.value_at(key, tier))
	var line: String
	if maxed:
		line = Loc.f("Now: %s   (maxed)", [now])
	else:
		line = Loc.f("Now: %s   Next: %s", [now, UpgradeData.show(key, UpgradeData.value_at(key, tier + 1))])
	info.add_child(UiStyle.label(line, 15, StarRow.GOLD))
	var pips: Control = Control.new()
	pips.custom_minimum_size = Vector2(88, 20)
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pips.draw.connect(func() -> void:
		for i: int in UpgradeData.MAX_TIER:
			var r: Rect2 = Rect2(Vector2(float(i) * 17.0, 2.0), Vector2(14.0, 16.0))
			pips.draw_rect(r, StarRow.GOLD if i < tier else Color(0.22, 0.22, 0.26))
			pips.draw_rect(r, StarRow.EDGE if i < tier else Color(0.45, 0.45, 0.5), false, 1.5))
	h.add_child(pips)
	var cost: int = UpgradeData.cost_of_next(key)
	var buy: Button = UiStyle.button(Loc.t("MAX") if maxed else Loc.f("Buy  %d stars", [cost]) if cost > 1 else Loc.t("Buy  1 star"), Vector2(150, 44), 16)
	buy.name = "Buy_" + key
	buy.disabled = maxed or GameState.stars_available() < cost
	buy.pressed.connect(func() -> void:
		if GameState.buy_upgrade(key):
			_refresh())
	h.add_child(buy)
	return box
