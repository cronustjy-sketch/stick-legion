class_name HeroCamera
extends Node3D
## Over-the-shoulder third-person camera. Mouse looks, scroll zooms, Esc frees the mouse.
## `yaw` is the heading the camera looks along (0 = toward -Z); the hero moves relative to it.

var target: Node3D
var terrain: Terrain
var yaw: float = 0.0
var pitch: float = HeroData.CAMERA.start_pitch  # radians above the hero looking down
var distance: float = HeroData.CAMERA.distance
var swallow_click: bool = false  # the click that grabs the mouse must not also swing the sword

var camera: Camera3D
var tactical: bool = false  # Tab held: high view of the whole fight
var _tac_t: float = 0.0
var _shake_amp: float = 0.0
var _shake_time: float = 0.0
var _shake_total: float = 0.01
var _focus: Vector3 = Vector3.ZERO


func _ready() -> void:
	top_level = true
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 70.0
	camera.far = 600.0
	add_child(camera)
	camera.current = true
	if target != null:
		_focus = target.global_position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var m: InputEventMouseMotion = event
		yaw -= m.relative.x * float(HeroData.CAMERA.mouse_sensitivity)
		pitch = clampf(pitch + m.relative.y * float(HeroData.CAMERA.mouse_sensitivity), -0.25, 1.25)
	elif event is InputEventMouseButton:
		var b: InputEventMouseButton = event
		if b.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			swallow_click = true
		elif b.pressed and b.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(distance - float(HeroData.CAMERA.zoom_step), float(HeroData.CAMERA.min_distance))
		elif b.pressed and b.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(distance + float(HeroData.CAMERA.zoom_step), float(HeroData.CAMERA.max_distance))
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Screen shake: `amount` is roughly metres of camera offset at the start, fading out over `time` seconds.
func shake(amount: float, time: float = 0.25) -> void:
	if amount >= _shake_amp * (_shake_time / _shake_total):
		_shake_amp = amount
		_shake_time = time
		_shake_total = maxf(time, 0.01)


func _process(delta: float) -> void:
	if target == null:
		return
	_focus = _focus.lerp(target.global_position, clampf(14.0 * delta, 0.0, 1.0))
	var pivot: Vector3 = _focus + Vector3(0.0, float(HeroData.CAMERA.height), 0.0)
	var basis: Basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -pitch)
	var forward: Vector3 = basis * Vector3.FORWARD
	var right: Vector3 = basis * Vector3.RIGHT
	var pos: Vector3 = pivot - forward * distance + right * float(HeroData.CAMERA.shoulder)
	if terrain != null:
		pos.y = maxf(pos.y, terrain.height_at(pos.x, pos.z) + 0.6)
	global_position = pos
	# Aim at a point ahead of the hero so the hero sits left of centre (over-the-shoulder).
	var normal: Transform3D = Transform3D(basis, pos).looking_at(pivot + forward * 6.0 + right * float(HeroData.CAMERA.shoulder), Vector3.UP)
	var want_tactical: bool = Input.is_action_pressed("tactical")
	if want_tactical != tactical:
		tactical = want_tactical
		get_tree().call_group("all_units", "set_tactical", tactical)
	_tac_t = move_toward(_tac_t, 1.0 if tactical else 0.0, delta * 2.2)
	if _tac_t <= 0.0:
		camera.global_transform = normal
		camera.fov = 70.0
	else:
		var fz: float = clampf(target.global_position.z, -30.0, 38.0)
		var high: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0.0, 82.0, fz + 30.0)).looking_at(Vector3(0.0, 0.0, fz), Vector3.UP)
		var k: float = smoothstep(0.0, 1.0, _tac_t)
		camera.global_transform = normal.interpolate_with(high, k)
		camera.fov = lerpf(70.0, 62.0, k)
	if _shake_time > 0.0:
		_shake_time -= delta
		var f: float = clampf(_shake_time / _shake_total, 0.0, 1.0)
		camera.h_offset = randf_range(-1.0, 1.0) * _shake_amp * f
		camera.v_offset = randf_range(-1.0, 1.0) * _shake_amp * f
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
