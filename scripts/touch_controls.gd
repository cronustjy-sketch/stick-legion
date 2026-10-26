class_name TouchControls
extends CanvasLayer
## On-screen controls for phones and tablets: a left joystick, Attack / Roll / Block buttons, a Map (tactical view) toggle,
## a Pause button, and dragging anywhere else on the right side turns the camera. Skills, orders and unit buttons are the
## normal HUD buttons (they react to taps). Shown automatically on mobile browsers; Settings can force it on or off.

const STICK_CENTER: Vector2 = Vector2(165.0, 455.0)
const STICK_RADIUS: float = 92.0
const STICK_GRAB: float = 165.0
const BUTTONS: Dictionary = {
	"attack": {"pos": Vector2(1140, 455), "r": 66.0, "label": "Attack"},
	"dodge": {"pos": Vector2(1012, 505), "r": 48.0, "label": "Roll"},
	"block": {"pos": Vector2(1040, 385), "r": 48.0, "label": "Block"},
	"map": {"pos": Vector2(1148, 52), "r": 30.0, "label": "Map"},
	"pause": {"pos": Vector2(1230, 52), "r": 30.0, "label": "II"},
}

var battle: Battle

var _canvas: Control
var _stick_id: int = -1
var _stick_vec: Vector2 = Vector2.ZERO
var _look_id: int = -1
var _held: Dictionary = {}  # touch index -> button name


## True when the on-screen controls should be shown (mobile browser / phone, or forced on in Settings).
static func wanted() -> bool:
	if Settings.touch == 1:
		return true
	if Settings.touch == 2:
		return false
	for a: String in OS.get_cmdline_user_args():
		if a == "--touch":
			return true
	if OS.has_feature("web"):
		# A phone or tablet: the main pointer is a finger. "?touch=1" in the address forces the controls on (for testing).
		var js: String = "(window.matchMedia('(pointer: coarse)').matches || new URLSearchParams(location.search).get('touch') === '1') ? 1 : 0"
		return int(JavaScriptBridge.eval(js, true)) == 1
	return OS.has_feature("android") or OS.has_feature("ios")


func _ready() -> void:
	layer = 15
	_canvas = Control.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_draw_controls)
	battle.hero.touch_active = true


func _exit_tree() -> void:
	if is_instance_valid(battle) and is_instance_valid(battle.hero):
		battle.hero.touch_active = false


func _process(_delta: float) -> void:
	_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event
		if t.pressed:
			_touch_down(t.index, t.position)
		else:
			_touch_up(t.index)
	elif event is InputEventScreenDrag:
		var d: InputEventScreenDrag = event
		if d.index == _stick_id:
			_set_stick(d.position)
		elif d.index == _look_id and battle.hero_camera != null:
			battle.hero_camera.look(d.relative)


func _touch_down(index: int, pos: Vector2) -> void:
	var name: String = _button_at(pos)
	if name != "":
		_held[index] = name
		_press(name, true)
		return
	if _stick_id == -1 and pos.distance_to(STICK_CENTER) <= STICK_GRAB:
		_stick_id = index
		_set_stick(pos)
		return
	if _look_id == -1 and pos.x > 360.0 and pos.y > 140.0 and pos.y < 545.0:
		_look_id = index


func _touch_up(index: int) -> void:
	if _held.has(index):
		_press(String(_held[index]), false)
		_held.erase(index)
	if index == _stick_id:
		_stick_id = -1
		_stick_vec = Vector2.ZERO
		battle.hero.touch_move = Vector2.ZERO
		battle.hero.touch_sprint = false
	if index == _look_id:
		_look_id = -1


func _set_stick(pos: Vector2) -> void:
	var v: Vector2 = (pos - STICK_CENTER) / STICK_RADIUS
	if v.length() > 1.0:
		v = v.normalized()
	_stick_vec = v
	battle.hero.touch_move = v if v.length() > 0.15 else Vector2.ZERO
	battle.hero.touch_sprint = v.length() > 0.92


func _button_at(pos: Vector2) -> String:
	for name: String in BUTTONS:
		if pos.distance_to(BUTTONS[name].pos) <= float(BUTTONS[name].r) + 8.0:
			return name
	return ""


func _press(name: String, down: bool) -> void:
	var hero: Hero = battle.hero
	match name:
		"attack":
			if down:
				hero.touch_attack = true
		"dodge":
			if down:
				hero.touch_dodge = true
		"block":
			hero.touch_block = down
		"map":
			if down and battle.hero_camera != null:
				battle.hero_camera.touch_tactical = not battle.hero_camera.touch_tactical
		"pause":
			if down:
				var pm: PauseMenu = battle.get_node_or_null("PauseMenu") as PauseMenu
				if pm != null and not battle.ended:
					pm.open()


func _draw_controls() -> void:
	# Joystick base and knob.
	_canvas.draw_circle(STICK_CENTER, STICK_RADIUS, Color(1, 1, 1, 0.1))
	_canvas.draw_arc(STICK_CENTER, STICK_RADIUS, 0.0, TAU, 40, Color(1, 1, 1, 0.35), 3.0)
	_canvas.draw_circle(STICK_CENTER + _stick_vec * STICK_RADIUS * 0.75, 38.0, Color(1, 0.85, 0.4, 0.55))
	var font: Font = ThemeDB.fallback_font
	for name: String in BUTTONS:
		var b: Dictionary = BUTTONS[name]
		var down: bool = _held.values().has(name)
		if name == "map" and battle.hero_camera != null and battle.hero_camera.touch_tactical:
			down = true
		var col: Color = Color(0.91, 0.71, 0.29, 0.55 if down else 0.28)
		_canvas.draw_circle(b.pos, float(b.r), col)
		_canvas.draw_arc(b.pos, float(b.r), 0.0, TAU, 32, Color(1, 1, 1, 0.5), 3.0)
		var size: int = 22 if float(b.r) > 40.0 else 15
		var text: String = String(b.label)
		var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		_canvas.draw_string(font, b.pos + Vector2(-w * 0.5, float(size) * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1, 1, 1, 0.9))
