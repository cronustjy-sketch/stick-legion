class_name UnitVisual
extends Node3D
## Base class of everything a Unit shows on screen (stickman, horse + rider, catapult).
## Units only ever call play(); each visual maps the common names (idle, walk, run, attack, hit, die) to its own animation.


func play(_anim: StringName, _speed: float = 1.0, _restart: bool = false) -> void:
	pass
