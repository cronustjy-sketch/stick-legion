class_name InputSetup
extends RefCounted
## Registers the game's input actions in code (keyboard + mouse), so project.godot stays small.


static func ensure() -> void:
	_key("move_forward", KEY_W)
	_key("move_back", KEY_S)
	_key("move_left", KEY_A)
	_key("move_right", KEY_D)
	_key("sprint", KEY_SHIFT)
	_key("dodge", KEY_SPACE)
	_key("order_charge", KEY_1)
	_key("order_hold", KEY_2)
	_key("order_follow", KEY_3)
	_key("order_retreat", KEY_4)
	_key("tactical", KEY_TAB)
	_mouse("attack", MOUSE_BUTTON_LEFT)
	_mouse("block", MOUSE_BUTTON_RIGHT)


static func _add(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
	InputMap.action_add_event(action, event)


static func _key(action: String, keycode: Key) -> void:
	if InputMap.has_action(action):
		return
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = keycode
	_add(action, e)


static func _mouse(action: String, button: MouseButton) -> void:
	if InputMap.has_action(action):
		return
	var e: InputEventMouseButton = InputEventMouseButton.new()
	e.button_index = button
	_add(action, e)
