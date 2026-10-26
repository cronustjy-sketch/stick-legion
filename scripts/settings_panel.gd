class_name SettingsPanel
extends VBoxContainer
## The settings form: volume sliders, graphics quality, fullscreen, mouse sensitivity.
## Used by the main menu and the in-game pause menu. Changes apply and save immediately.

signal closed

var _master: HSlider
var _music: HSlider
var _sfx: HSlider
var _sens: HSlider
var _quality: OptionButton
var _fullscreen: CheckBox


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	custom_minimum_size = Vector2(520, 0)
	add_child(UiStyle.label("Settings", 40, UiStyle.GOLD))
	_master = _slider_row("Master volume", Settings.master, 0.0, 1.0)
	_music = _slider_row("Music volume", Settings.music, 0.0, 1.0)
	_sfx = _slider_row("Effects volume", Settings.sfx, 0.0, 1.0)
	_sens = _slider_row("Mouse sensitivity", Settings.mouse_sens / 3.0, 0.1, 1.0)
	var qrow: HBoxContainer = HBoxContainer.new()
	add_child(qrow)
	var ql: Label = UiStyle.label("Graphics quality", 20)
	ql.custom_minimum_size = Vector2(200, 0)
	qrow.add_child(ql)
	_quality = OptionButton.new()
	_quality.focus_mode = Control.FOCUS_NONE
	for q: String in Settings.QUALITY_NAMES:
		_quality.add_item(q)
	_quality.select(Settings.quality)
	_quality.custom_minimum_size = Vector2(160, 36)
	_quality.item_selected.connect(_on_quality)
	qrow.add_child(_quality)
	var trow: HBoxContainer = HBoxContainer.new()
	add_child(trow)
	var tl: Label = UiStyle.label("Touch controls", 20)
	tl.custom_minimum_size = Vector2(200, 0)
	trow.add_child(tl)
	var touch_opt: OptionButton = OptionButton.new()
	touch_opt.focus_mode = Control.FOCUS_NONE
	for t: String in ["Automatic", "Always on", "Off"]:
		touch_opt.add_item(t)
	touch_opt.select(Settings.touch)
	touch_opt.custom_minimum_size = Vector2(160, 36)
	touch_opt.item_selected.connect(func(i: int) -> void:
		Settings.touch = i
		Settings.save())
	trow.add_child(touch_opt)
	_fullscreen = CheckBox.new()
	_fullscreen.text = "Fullscreen"
	_fullscreen.focus_mode = Control.FOCUS_NONE
	_fullscreen.button_pressed = Settings.fullscreen
	_fullscreen.add_theme_font_size_override("font_size", 20)
	_fullscreen.toggled.connect(_on_fullscreen)
	if not OS.has_feature("web"):
		add_child(_fullscreen)
	var note: Label = UiStyle.label("Low quality: fewer trees and rocks, fewer sparks, no unit outlines.", 14, UiStyle.DIM)
	add_child(note)
	var back: Button = UiStyle.button("Back", Vector2(200, 50), 22)
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)


func _slider_row(title: String, value: float, lo: float, hi: float) -> HSlider:
	var row: HBoxContainer = HBoxContainer.new()
	add_child(row)
	var l: Label = UiStyle.label(title, 20)
	l.custom_minimum_size = Vector2(200, 0)
	row.add_child(l)
	var s: HSlider = HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.01
	s.value = value
	s.custom_minimum_size = Vector2(220, 28)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.focus_mode = Control.FOCUS_NONE
	row.add_child(s)
	var pct: Label = UiStyle.label("%d%%" % int(round(s.value * 100.0)), 18, UiStyle.GOLD)
	pct.custom_minimum_size = Vector2(60, 0)
	row.add_child(pct)
	s.value_changed.connect(func(v: float) -> void:
		pct.text = "%d%%" % int(round(v * 100.0))
		_on_changed())
	return s


func _on_changed() -> void:
	Settings.master = _master.value
	Settings.music = _music.value
	Settings.sfx = _sfx.value
	Settings.mouse_sens = _sens.value * 3.0
	Settings.apply()
	Settings.save()


func _on_quality(index: int) -> void:
	Settings.quality = index
	Settings.apply()
	Settings.save()


func _on_fullscreen(on: bool) -> void:
	Settings.fullscreen = on
	Settings.apply()
	Settings.save()
