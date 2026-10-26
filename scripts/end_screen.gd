class_name EndScreen
extends CanvasLayer
## Victory / defeat overlay. Pauses the game; buttons reload the battle (retry / next level).

var battle: Battle


func show_result(victory: bool, level: int) -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.1, 0.96)
	sb.border_color = Color("e8b44a") if victory else Color("de4b3f")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	var finished: bool = victory and level >= LevelData.LEVEL_COUNT
	var title: Label = _label(("CAMPAIGN COMPLETE" if finished else "VICTORY") if victory else "DEFEAT", 64 if not finished else 48, Color("e8b44a") if victory else Color("de4b3f"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub: Label = _label(("Level %d cleared. The enemy fortress has fallen." if victory else "Level %d lost. Your fortress fell or your hero is out of lives.") % level, 20, Color("f1ede2"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	if victory and not finished:
		row.add_child(_button("Next Level", func() -> void: _go(level + 1)))
	row.add_child(_button("Retry", func() -> void: _go(level)))
	row.add_child(_button("Level Select", _to_map))


func _to_map() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _go(level: int) -> void:
	GameState.current_level = level
	get_tree().paused = false
	get_tree().reload_current_scene()


func _button(text: String, on_press: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.name = text.replace(" ", "")
	b.custom_minimum_size = Vector2(190, 56)
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(on_press)
	return b


func _label(text: String, size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	return l
