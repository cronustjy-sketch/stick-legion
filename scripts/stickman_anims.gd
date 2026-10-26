class_name StickmanAnims
extends RefCounted
## Builds the shared animation library for the stickman rig in code.
## Poses are Dictionaries {bone name: Vector3 euler degrees}; "Hips_pos" is an offset from the rest position.
## Sign cheat-sheet (model faces -Z): +X rotation swings a hanging limb forward; knees bend with -X;
## the arm/weapon pitch is shoulder + elbow + hand (85 = weapon upright, 0 = weapon pointing forward).

const REST_HIPS: Vector3 = Vector3(0.0, 0.95, 0.0)

const IDLE: Dictionary = {
	"ShoulderR": Vector3(30, 0, 6), "ElbowR": Vector3(55, 0, 0), "HandR": Vector3.ZERO,
	"ShoulderL": Vector3(30, 0, -6), "ElbowL": Vector3(55, 0, 0), "HandL": Vector3.ZERO,
	"Spine": Vector3.ZERO, "Head": Vector3.ZERO, "Hips": Vector3.ZERO,
	"ThighL": Vector3(0, 0, -2), "ThighR": Vector3(0, 0, 2),
	"KneeL": Vector3.ZERO, "KneeR": Vector3.ZERO, "FootL": Vector3.ZERO, "FootR": Vector3.ZERO,
	"Hips_pos": Vector3.ZERO,
}

static var _cache: Dictionary = {}


static func library(style: String) -> AnimationLibrary:
	if _cache.has(style):
		return _cache[style]
	var lib: AnimationLibrary = AnimationLibrary.new()
	lib.add_animation("idle", _idle())
	lib.add_animation("walk", _locomotion(1.0, 12, 26.0, 45.0, 30.0, 16.0, 55.0, 3.0, 0.03, 4.0))
	lib.add_animation("run", _locomotion(0.6, 12, 48.0, 85.0, 40.0, 40.0, 95.0, 14.0, 0.07, 6.0))
	lib.add_animation("attack", _attack(style))
	lib.add_animation("block", _block())
	lib.add_animation("hit", _hit())
	lib.add_animation("die", _die())
	_cache[style] = lib
	return lib


static func _pose(over: Dictionary) -> Dictionary:
	var p: Dictionary = IDLE.duplicate()
	p.merge(over, true)
	return p


static func _make(length: float, loop: bool, keys: Array) -> Animation:
	var anim: Animation = Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var bones: Array = []
	for k: Array in keys:
		for b: String in (k[1] as Dictionary):
			if b != "Hips_pos" and not bones.has(b):
				bones.append(b)
	for b: String in bones:
		var tr: int = anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(tr, NodePath("Skeleton3D:" + b))
		for k: Array in keys:
			var e: Vector3 = (k[1] as Dictionary).get(b, Vector3.ZERO)
			anim.rotation_track_insert_key(tr, k[0], Quaternion.from_euler(Vector3(deg_to_rad(e.x), deg_to_rad(e.y), deg_to_rad(e.z))))
	var pt: int = anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pt, NodePath("Skeleton3D:Hips"))
	for k: Array in keys:
		anim.position_track_insert_key(pt, k[0], REST_HIPS + ((k[1] as Dictionary).get("Hips_pos", Vector3.ZERO) as Vector3))
	return anim


static func _idle() -> Animation:
	var a: Dictionary = _pose({"Spine": Vector3(-1.0, 0, 0), "Hips_pos": Vector3(0, 0.0, 0), "ShoulderR": Vector3(32, 0, 7), "ShoulderL": Vector3(32, 0, -7)})
	var b: Dictionary = _pose({"Spine": Vector3(1.5, 0, 0), "Hips_pos": Vector3(0, -0.012, 0), "ShoulderR": Vector3(28, 0, 5), "ShoulderL": Vector3(28, 0, -5), "Head": Vector3(-1.5, 0, 0)})
	return _make(2.0, true, [[0.0, a], [1.0, b], [2.0, a]])


static func _locomotion(length: float, steps: int, amp: float, knee_amp: float, arm_base: float, arm_amp: float,
		elbow: float, lean: float, bob: float, twist: float) -> Animation:
	var keys: Array = []
	for i: int in steps + 1:
		var p: float = float(i) / float(steps)
		var s: float = sin(TAU * p)
		var c: float = cos(TAU * p)
		var tl: float = amp * s
		var tr: float = -amp * s
		var kl: float = -knee_amp * maxf(0.0, c)
		var kr: float = -knee_amp * maxf(0.0, -c)
		keys.append([length * p, _pose({
			"ThighL": Vector3(tl, 0, -2), "ThighR": Vector3(tr, 0, 2),
			"KneeL": Vector3(kl, 0, 0), "KneeR": Vector3(kr, 0, 0),
			"FootL": Vector3(-(tl + kl), 0, 0), "FootR": Vector3(-(tr + kr), 0, 0),
			"ShoulderL": Vector3(arm_base - arm_amp * s, 0, -6), "ShoulderR": Vector3(arm_base + arm_amp * s, 0, 6),
			"ElbowL": Vector3(elbow, 0, 0), "ElbowR": Vector3(elbow, 0, 0),
			"Spine": Vector3(-lean, twist * s, 0), "Head": Vector3(lean * 0.6, -twist * s, 0),
			"Hips": Vector3(0, -twist * 0.5 * s, 0),
			"Hips_pos": Vector3(0, bob * (cos(2.0 * TAU * p) - 1.0) * 0.5, 0),
		})])
	return _make(length, true, keys)


static func _attack(style: String) -> Animation:
	match style:
		"thrust":
			return _make(0.9, false, [
				[0.0, _pose({})],
				[0.3, _pose({"ShoulderR": Vector3(15, 0, 6), "ElbowR": Vector3(60, 0, 0), "HandR": Vector3(-55, 0, 0),
					"ShoulderL": Vector3(60, 0, -10), "ElbowL": Vector3(40, 0, 0), "Spine": Vector3(-4, -22, 0),
					"ThighL": Vector3(18, 0, -2), "KneeL": Vector3(-10, 0, 0), "ThighR": Vector3(-14, 0, 2), "KneeR": Vector3(-10, 0, 0),
					"Hips_pos": Vector3(0, -0.04, 0)})],
				[0.45, _pose({"ShoulderR": Vector3(80, 0, 4), "ElbowR": Vector3(5, 0, 0), "HandR": Vector3(-65, 0, 0),
					"ShoulderL": Vector3(40, 0, -12), "ElbowL": Vector3(50, 0, 0), "Spine": Vector3(-10, 24, 0),
					"ThighL": Vector3(30, 0, -2), "KneeL": Vector3(-25, 0, 0), "ThighR": Vector3(-20, 0, 2), "KneeR": Vector3(-12, 0, 0),
					"Hips_pos": Vector3(0, -0.07, -0.08)})],
				[0.6, _pose({"ShoulderR": Vector3(80, 0, 4), "ElbowR": Vector3(5, 0, 0), "HandR": Vector3(-65, 0, 0),
					"Spine": Vector3(-8, 20, 0), "ThighL": Vector3(30, 0, -2), "KneeL": Vector3(-25, 0, 0),
					"Hips_pos": Vector3(0, -0.07, -0.08)})],
				[0.9, _pose({})],
			])
		"shoot":
			return _make(1.4, false, [
				[0.0, _pose({})],
				[0.3, _pose({"ShoulderL": Vector3(88, 0, -4), "ElbowL": Vector3(0, 0, 0), "HandL": Vector3(-3, 0, 0),
					"ShoulderR": Vector3(88, 0, 6), "ElbowR": Vector3(0, 0, 0), "Spine": Vector3(0, 18, 0), "Head": Vector3(0, -18, 0)})],
				[0.8, _pose({"ShoulderL": Vector3(88, 0, -4), "ElbowL": Vector3(0, 0, 0), "HandL": Vector3(-3, 0, 0),
					"ShoulderR": Vector3(70, 0, 28), "ElbowR": Vector3(105, 0, 0), "Spine": Vector3(0, 22, 0), "Head": Vector3(0, -22, 0),
					"ThighL": Vector3(8, 0, -6), "ThighR": Vector3(-6, 0, 6)})],
				[0.9, _pose({"ShoulderL": Vector3(90, 0, -4), "ElbowL": Vector3(0, 0, 0), "HandL": Vector3(-5, 0, 0),
					"ShoulderR": Vector3(60, 0, 24), "ElbowR": Vector3(60, 0, 0), "Spine": Vector3(-2, 14, 0), "Head": Vector3(0, -16, 0)})],
				[1.4, _pose({})],
			])
		"cast":
			return _make(1.2, false, [
				[0.0, _pose({})],
				[0.4, _pose({"ShoulderR": Vector3(100, 0, 12), "ElbowR": Vector3(40, 0, 0), "HandR": Vector3(-75, 0, 0),
					"ShoulderL": Vector3(120, 0, -20), "ElbowL": Vector3(20, 0, 0), "Spine": Vector3(6, 0, 0), "Head": Vector3(-8, 0, 0)})],
				[0.6, _pose({"ShoulderR": Vector3(105, 0, 8), "ElbowR": Vector3(10, 0, 0), "HandR": Vector3(-55, 0, 0),
					"ShoulderL": Vector3(95, 0, -14), "ElbowL": Vector3(5, 0, 0), "Spine": Vector3(-12, 0, 0), "Head": Vector3(6, 0, 0),
					"Hips_pos": Vector3(0, -0.03, -0.05)})],
				[0.8, _pose({"ShoulderR": Vector3(105, 0, 8), "ElbowR": Vector3(10, 0, 0), "HandR": Vector3(-55, 0, 0),
					"ShoulderL": Vector3(95, 0, -14), "ElbowL": Vector3(5, 0, 0), "Spine": Vector3(-12, 0, 0)})],
				[1.2, _pose({})],
			])
		_:  # swing: overhead chop
			return _make(0.8, false, [
				[0.0, _pose({})],
				[0.22, _pose({"ShoulderR": Vector3(125, 0, 10), "ElbowR": Vector3(35, 0, 0), "HandR": Vector3(0, 0, 0),
					"ShoulderL": Vector3(45, 0, -15), "ElbowL": Vector3(40, 0, 0), "Spine": Vector3(5, -22, 0),
					"ThighL": Vector3(12, 0, -2), "ThighR": Vector3(-12, 0, 2), "Hips_pos": Vector3(0, -0.02, 0.02)})],
				[0.34, _pose({"ShoulderR": Vector3(75, 0, 4), "ElbowR": Vector3(-5, 0, 0), "HandR": Vector3(-45, 0, 0),
					"ShoulderL": Vector3(25, 0, -22), "ElbowL": Vector3(30, 0, 0), "Spine": Vector3(-14, 26, 0),
					"ThighL": Vector3(26, 0, -2), "KneeL": Vector3(-22, 0, 0), "ThighR": Vector3(-18, 0, 2), "KneeR": Vector3(-10, 0, 0),
					"Hips_pos": Vector3(0, -0.07, -0.07)})],
				[0.5, _pose({"ShoulderR": Vector3(70, 0, 4), "ElbowR": Vector3(-5, 0, 0), "HandR": Vector3(-40, 0, 0),
					"Spine": Vector3(-12, 22, 0), "ThighL": Vector3(26, 0, -2), "KneeL": Vector3(-22, 0, 0), "ThighR": Vector3(-18, 0, 2),
					"Hips_pos": Vector3(0, -0.07, -0.07)})],
				[0.8, _pose({})],
			])


static func _block() -> Animation:
	var guard: Dictionary = _pose({
		"ShoulderL": Vector3(88, 0, -12), "ElbowL": Vector3(15, 0, 0), "HandL": Vector3(-18, 0, 0),
		"ShoulderR": Vector3(50, 0, 14), "ElbowR": Vector3(80, 0, 0), "HandR": Vector3(-45, 0, 0),
		"Spine": Vector3(-8, 0, 0), "Head": Vector3(6, 0, 0),
		"ThighL": Vector3(34, 0, -8), "KneeL": Vector3(-62, 0, 0), "FootL": Vector3(28, 0, 0),
		"ThighR": Vector3(-8, 0, 8), "KneeR": Vector3(-40, 0, 0), "FootR": Vector3(48, 0, 0),
		"Hips_pos": Vector3(0, -0.2, -0.04),
	})
	return _make(0.3, false, [[0.0, _pose({})], [0.2, guard], [0.3, guard]])


static func _hit() -> Animation:
	var flinch: Dictionary = _pose({
		"Spine": Vector3(20, 0, 9), "Head": Vector3(-18, 0, -6),
		"ShoulderL": Vector3(55, 0, -25), "ShoulderR": Vector3(55, 0, 25),
		"ThighL": Vector3(8, 0, -2), "KneeL": Vector3(-14, 0, 0), "ThighR": Vector3(-8, 0, 2),
		"Hips_pos": Vector3(0, -0.04, 0.07),
	})
	return _make(0.45, false, [[0.0, _pose({})], [0.09, flinch], [0.45, _pose({})]])


static func _die() -> Animation:
	var stagger: Dictionary = _pose({
		"Spine": Vector3(14, 0, 6), "Head": Vector3(-14, 0, 0),
		"ShoulderL": Vector3(60, 0, -30), "ShoulderR": Vector3(60, 0, 30), "ElbowL": Vector3(20, 0, 0), "ElbowR": Vector3(20, 0, 0),
		"ThighL": Vector3(14, 0, -2), "KneeL": Vector3(-40, 0, 0), "ThighR": Vector3(-6, 0, 2), "KneeR": Vector3(-30, 0, 0),
		"Hips_pos": Vector3(0, -0.2, 0.08),
	})
	var fall: Dictionary = _pose({
		"Hips": Vector3(55, 0, 0), "Spine": Vector3(8, 0, 4), "Head": Vector3(-10, 0, 0),
		"ShoulderL": Vector3(110, 0, -50), "ShoulderR": Vector3(95, 0, 55), "ElbowL": Vector3(10, 0, 0), "ElbowR": Vector3(10, 0, 0),
		"ThighL": Vector3(20, 0, -8), "KneeL": Vector3(-50, 0, 0), "ThighR": Vector3(-10, 0, 8), "KneeR": Vector3(-30, 0, 0),
		"Hips_pos": Vector3(0, -0.5, 0.25),
	})
	var lying: Dictionary = _pose({
		"Hips": Vector3(88, 0, 0), "Spine": Vector3(0, 0, 3), "Head": Vector3(-8, 0, 6),
		"ShoulderL": Vector3(20, 0, -55), "ShoulderR": Vector3(35, 0, 60), "ElbowL": Vector3(8, 0, 0), "ElbowR": Vector3(15, 0, 0),
		"ThighL": Vector3(8, 0, -10), "KneeL": Vector3(-12, 0, 0), "ThighR": Vector3(-5, 0, 12), "KneeR": Vector3(-8, 0, 0),
		"Hips_pos": Vector3(0, -0.83, 0.3),
	})
	return _make(1.1, false, [[0.0, _pose({})], [0.22, stagger], [0.6, fall], [1.0, lying], [1.1, lying]])
