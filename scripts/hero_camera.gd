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
	camera.global_transform = Transform3D(basis, pos).looking_at(pivot + forward * 6.0 + right * float(HeroData.CAMERA.shoulder), Vector3.UP)
