class_name PauseMenu
extends CanvasLayer
## In-battle pause menu (Esc): Resume, Settings, Level Select, Main Menu.

var battle: Battle

var _main: PanelContainer
var _settings: PanelContainer


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main = UiStyle.panel(self)
	_center(_main)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_main.add_child(v)
	var title: Label = UiStyle.label("Paused", 48, UiStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var resume: Button = UiStyle.button("Resume", Vector2(320, 58), 26)
	resume.pressed.connect(close)
	v.add_child(resume)
	var settings: Button = UiStyle.button("Settings", Vector2(320, 54), 24)
	settings.pressed.connect(func() -> void:
		_main.visible = false
		_settings.visible = true)
	v.add_child(settings)
	var map: Button = UiStyle.button("Level Select", Vector2(320, 54), 24)
	map.pressed.connect(func() -> void: _leave("res://scenes/level_select.tscn"))
	v.add_child(map)
	var menu: Button = UiStyle.button("Main Menu", Vector2(320, 54), 24)
	menu.pressed.connect(func() -> void: _leave("res://scenes/main_menu.tscn"))
	v.add_child(menu)
	_settings = UiStyle.panel(self)
	_center(_settings)
	_settings.visible = false
	var sp: SettingsPanel = SettingsPanel.new()
	sp.closed.connect(func() -> void:
		_settings.visible = false
		_main.visible = true)
	_settings.add_child(sp)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not battle.ended:
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	_main.visible = true
	_settings.visible = false
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _leave(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


func _center(c: Control) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.5
	c.anchor_bottom = 0.5
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	c.grow_vertical = Control.GROW_DIRECTION_BOTH
