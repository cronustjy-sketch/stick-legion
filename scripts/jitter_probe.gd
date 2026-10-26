class_name JitterProbe
extends Node
## Debug helper: added last in the tree, so its _process runs after the hero and the camera. Records their speed per frame.

var hero: Node3D
var cam: Node3D
var cam_speeds: Array[float] = []
var hero_speeds: Array[float] = []
var _lc: Vector3 = Vector3.INF
var _lh: Vector3 = Vector3.INF


func _process(delta: float) -> void:
	if _lc != Vector3.INF and delta > 0.0:
		cam_speeds.append(cam.global_position.distance_to(_lc) / delta)
		hero_speeds.append(hero.global_position.distance_to(_lh) / delta)
	_lc = cam.global_position
	_lh = hero.global_position
