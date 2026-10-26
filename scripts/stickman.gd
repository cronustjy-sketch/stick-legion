class_name Stickman
extends Node3D
## The one reusable stickman rig: a 16-bone Skeleton3D, ONE skinned mesh (one draw call + outline),
## and an AnimationPlayer with idle / walk / run / attack / block / hit / die.
## Every unit type is the same rig with different gear (see UnitData.LOOKS).
## The model faces -Z (Godot forward). Player team = gold + steel, enemy = red + dark iron.

signal animation_done(anim: StringName)

const BONES: Array = [  # [name, parent, rest position relative to parent]
	["Root", "", Vector3(0.0, 0.0, 0.0)],
	["Hips", "Root", Vector3(0.0, 0.95, 0.0)],
	["Spine", "Hips", Vector3(0.0, 0.05, 0.0)],
	["Head", "Spine", Vector3(0.0, 0.62, 0.0)],
	["ShoulderL", "Spine", Vector3(-0.21, 0.5, 0.0)],
	["ElbowL", "ShoulderL", Vector3(0.0, -0.3, 0.0)],
	["HandL", "ElbowL", Vector3(0.0, -0.28, 0.0)],
	["ShoulderR", "Spine", Vector3(0.21, 0.5, 0.0)],
	["ElbowR", "ShoulderR", Vector3(0.0, -0.3, 0.0)],
	["HandR", "ElbowR", Vector3(0.0, -0.28, 0.0)],
	["ThighL", "Hips", Vector3(-0.1, 0.0, 0.0)],
	["KneeL", "ThighL", Vector3(0.0, -0.47, 0.0)],
	["FootL", "KneeL", Vector3(0.0, -0.45, 0.0)],
	["ThighR", "Hips", Vector3(0.1, 0.0, 0.0)],
	["KneeR", "ThighR", Vector3(0.0, -0.47, 0.0)],
	["FootR", "KneeR", Vector3(0.0, -0.45, 0.0)],
]

const HAND_L: Vector3 = Vector3(-0.21, 0.92, 0.0)
const HAND_R: Vector3 = Vector3(0.21, 0.92, 0.0)
const HELD_PITCH: float = 85.0  # idle arm pitch (shoulder + elbow); items are authored upright in this pose

const C_BODY: Color = Color("26262b")
const C_LEATHER: Color = Color("5a4030")
const C_WOOD: Color = Color("7a5a3a")
const C_WHITE: Color = Color("e6e0d0")
const C_STEEL: Color = Color("b6c0cc")
const C_IRON: Color = Color("4c474a")

static var _mesh_cache: Dictionary = {}  # "look|team" -> {mesh, skin}
static var _material: StandardMaterial3D

var unit_key: String = ""
var team: int = 0
var look: Dictionary = {}

var skeleton: Skeleton3D
var player: AnimationPlayer
var _bone_index: Dictionary = {}
var _rest_global: Dictionary = {}


## Builds the rig for a unit type ("swordsman", ...) and team (0 = player, 1 = enemy).
func setup(key: String, team_id: int) -> void:
	unit_key = key
	team = team_id
	look = UnitData.LOOKS[key]
	scale = Vector3.ONE * float(look.scale)
	_build_skeleton()
	var cached: Dictionary = _get_mesh(key, team_id)
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = cached.mesh
	mi.skin = cached.skin
	mi.material_override = _get_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 2.0  # skinned pose can leave the rest-pose bounds (die animation)
	skeleton.add_child(mi)
	mi.skeleton = NodePath("..")
	var shadow: BlobShadow = BlobShadow.make(Vector2(1.1, 1.1))
	shadow.name = "BlobShadow"
	add_child(shadow)
	player = AnimationPlayer.new()
	player.name = "Anim"
	add_child(player)
	player.add_animation_library("", StickmanAnims.library(String(look.style)))
	player.playback_default_blend_time = 0.12
	player.animation_finished.connect(func(a: StringName) -> void: animation_done.emit(a))
	player.play("idle")


## Plays an animation by name; does nothing if it is already the current one.
func play(anim: StringName, speed: float = 1.0) -> void:
	player.speed_scale = speed
	if player.current_animation != String(anim) or not player.is_playing():
		player.play(anim)


func _build_skeleton() -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	add_child(skeleton)
	var origin: Dictionary = {}
	for i: int in BONES.size():
		var b: Array = BONES[i]
		var bone_name: String = b[0]
		skeleton.add_bone(bone_name)
		_bone_index[bone_name] = i
		var parent_name: String = b[1]
		var parent_global: Vector3 = Vector3.ZERO
		if parent_name != "":
			skeleton.set_bone_parent(i, int(_bone_index[parent_name]))
			parent_global = origin[parent_name]
		skeleton.set_bone_rest(i, Transform3D(Basis.IDENTITY, b[2]))
		origin[bone_name] = parent_global + (b[2] as Vector3)
	_rest_global = origin
	skeleton.reset_bone_poses()


func _get_mesh(key: String, team_id: int) -> Dictionary:
	var ck: String = "%s|%d" % [key, team_id]
	if _mesh_cache.has(ck):
		return _mesh_cache[ck]
	var m: RigMesh = RigMesh.new(_bone_index)
	_build_body(m)
	_build_gear(m)
	var mesh: ArrayMesh = m.commit()
	var entry: Dictionary = {"mesh": mesh, "skin": skeleton.create_skin_from_rest_transforms()}
	_mesh_cache[ck] = entry
	return entry


static func _get_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		var outline: StandardMaterial3D = StandardMaterial3D.new()  # thin dark outline (inverted hull)
		outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		outline.albedo_color = Color(0.03, 0.03, 0.04)
		outline.cull_mode = BaseMaterial3D.CULL_FRONT
		outline.grow = true
		outline.grow_amount = 0.012
		_material.next_pass = outline
	return _material


# --- Body ---------------------------------------------------------------------------------------------

func _build_body(m: RigMesh) -> void:
	m.frame = Transform3D.IDENTITY
	m.cyl("Spine", Vector3(0, 1.0, 0), Vector3(0, 1.55, 0), 0.05, 0.05, C_BODY)
	m.cyl("Head", Vector3(0, 1.55, 0), Vector3(0, 1.66, 0), 0.035, 0.035, C_BODY)
	m.sphere("Head", Vector3(0, 1.74, 0), 0.105, C_BODY)
	m.cyl("Hips", Vector3(-0.11, 0.95, 0), Vector3(0.11, 0.95, 0), 0.04, 0.04, C_BODY)
	m.cyl("Spine", Vector3(-0.21, 1.5, 0), Vector3(0.21, 1.5, 0), 0.04, 0.04, C_BODY)
	for s: float in [-1.0, 1.0]:
		var side: String = "L" if s < 0.0 else "R"
		var sh: Vector3 = Vector3(s * 0.21, 1.5, 0)
		var el: Vector3 = Vector3(s * 0.21, 1.2, 0)
		var hd: Vector3 = Vector3(s * 0.21, 0.92, 0)
		m.cyl("Shoulder" + side, sh, el, 0.033, 0.03, C_BODY)
		m.sphere("Elbow" + side, el, 0.045, C_BODY, Vector3.ONE, 6)
		m.cyl("Elbow" + side, el, hd, 0.03, 0.028, C_BODY)
		m.sphere("Hand" + side, hd, 0.05, C_BODY, Vector3.ONE, 6)
		var hip: Vector3 = Vector3(s * 0.1, 0.95, 0)
		var kn: Vector3 = Vector3(s * 0.1, 0.48, 0)
		var ft: Vector3 = Vector3(s * 0.1, 0.03, 0)
		m.cyl("Thigh" + side, hip, kn, 0.042, 0.036, C_BODY)
		m.sphere("Knee" + side, kn, 0.048, C_BODY, Vector3.ONE, 6)
		m.cyl("Knee" + side, kn, ft, 0.035, 0.03, C_BODY)
		m.box("Foot" + side, Vector3(s * 0.1, 0.03, -0.05), Vector3(0.09, 0.05, 0.22), C_BODY)


# --- Gear ---------------------------------------------------------------------------------------------

func _metal() -> Color:
	return C_STEEL if team == 0 else C_IRON


func _cloth() -> Color:
	return BattlefieldData.COLOR_GOLD if team == 0 else BattlefieldData.COLOR_RED


func _cloth_dark() -> Color:
	return _cloth().darkened(0.3)


func _build_gear(m: RigMesh) -> void:
	m.frame = Transform3D.IDENTITY
	_helmet(m, String(look.helmet))
	if bool(look.shoulders):
		for s: float in [-1.0, 1.0]:
			var side: String = "L" if s < 0.0 else "R"
			m.sphere("Shoulder" + side, Vector3(s * 0.22, 1.54, 0), 0.1, _metal(), Vector3(1.0, 0.55, 1.0))
			m.sphere("Shoulder" + side, Vector3(s * 0.24, 1.5, 0), 0.085, _metal().darkened(0.12), Vector3(0.7, 0.5, 0.9), 6)
	_chest(m, String(look.chest))
	if bool(look.belt):
		m.tcyl("Spine", 0.97, 1.06, 0.095, 0.09, 0.7, C_LEATHER, 7)
		m.box("Spine", Vector3(0, 1.015, -0.075), Vector3(0.06, 0.06, 0.02), _cloth())
	if bool(look.cape):
		m.box("Spine", Vector3(0, 1.17, 0.085), Vector3(0.34, 0.74, 0.025), _cloth())
		m.box("Spine", Vector3(0, 1.5, 0.07), Vector3(0.4, 0.06, 0.06), _cloth_dark())
	_weapon(m, String(look.main), "HandR", HAND_R, 1.0)
	_weapon(m, String(look.off), "HandL", HAND_L, -1.0)


func _helmet(m: RigMesh, kind: String) -> void:
	var metal: Color = _metal()
	match kind:
		"cap":
			m.sphere("Head", Vector3(0, 1.78, 0), 0.125, metal, Vector3(1.0, 0.75, 1.0))
		"kettle":
			m.sphere("Head", Vector3(0, 1.78, 0), 0.125, metal, Vector3(1.0, 0.75, 1.0))
			m.cyl("Head", Vector3(0, 1.75, 0), Vector3(0, 1.77, 0), 0.19, 0.19, metal, 8)
		"plume":
			m.sphere("Head", Vector3(0, 1.78, 0), 0.125, metal, Vector3(1.0, 0.75, 1.0))
			m.cyl("Head", Vector3(0, 1.75, 0), Vector3(0, 1.77, 0), 0.15, 0.15, metal, 8)
			m.box("Head", Vector3(0, 1.9, 0.0), Vector3(0.03, 0.09, 0.24), _cloth())
		"greathelm":
			m.cyl("Head", Vector3(0, 1.62, 0), Vector3(0, 1.87, 0), 0.125, 0.115, metal, 8)
			m.box("Head", Vector3(0, 1.75, -0.115), Vector3(0.17, 0.03, 0.03), C_BODY)
			m.box("Head", Vector3(0, 1.69, -0.12), Vector3(0.03, 0.1, 0.03), C_BODY)
			m.box("Head", Vector3(0, 1.93, 0.0), Vector3(0.035, 0.1, 0.24), _cloth())
		"wizard":
			m.cyl("Head", Vector3(0, 1.8, 0), Vector3(0, 1.82, 0), 0.21, 0.21, _cloth_dark(), 8)
			m.cyl("Head", Vector3(0, 1.8, 0), Vector3(0.0, 2.22, 0.05), 0.12, 0.0, _cloth(), 7)
		"hood":
			m.sphere("Head", Vector3(0, 1.75, 0.012), 0.13, _cloth_dark(), Vector3(1.0, 1.05, 1.06))
			m.cyl("Head", Vector3(0, 1.78, 0.09), Vector3(0, 1.74, 0.27), 0.09, 0.0, _cloth_dark(), 5)
		"circlet":
			m.cyl("Head", Vector3(0, 1.79, 0), Vector3(0, 1.82, 0), 0.115, 0.115, _cloth(), 8)
			m.sphere("Head", Vector3(0, 1.82, -0.115), 0.025, C_WHITE, Vector3.ONE, 5)


func _chest(m: RigMesh, kind: String) -> void:
	var metal: Color = _metal()
	match kind:
		"plate":
			m.tcyl("Spine", 1.1, 1.52, 0.105, 0.135, 0.68, metal, 8)
			m.box("Spine", Vector3(0, 1.3, -0.085), Vector3(0.07, 0.36, 0.02), _cloth())
		"leather":
			m.tcyl("Spine", 1.1, 1.5, 0.095, 0.115, 0.66, C_LEATHER, 7)
			m.box("Spine", Vector3(0, 1.3, -0.08), Vector3(0.06, 0.34, 0.02), _cloth())
		"robe":
			var robe: Color = C_WHITE if bool(look.get("white_robe", false)) else _cloth_dark()
			m.tcyl("Spine", 0.5, 1.52, 0.23, 0.115, 0.82, robe, 8)
			m.tcyl("Spine", 0.5, 0.56, 0.235, 0.23, 0.82, _cloth_dark() if robe != C_WHITE else _cloth(), 8)
			m.box("Spine", Vector3(0, 1.0, -0.095), Vector3(0.07, 0.5, 0.02), _cloth_dark() if robe != C_WHITE else _cloth())


## Authors an item in the "held frame" (origin = hand, +Y up, -Z forward) and bakes it into the rest pose.
func _weapon(m: RigMesh, kind: String, bone: String, hand: Vector3, side: float) -> void:
	if kind == "":
		return
	m.frame = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-HELD_PITCH)), hand)
	var metal: Color = _metal()
	match kind:
		"sword":
			m.cyl(bone, Vector3(0, -0.08, 0), Vector3(0, 0.08, 0), 0.02, 0.02, C_LEATHER, 5)
			m.box(bone, Vector3(0, 0.09, 0), Vector3(0.17, 0.025, 0.04), metal.darkened(0.15))
			m.box(bone, Vector3(0, 0.52, 0), Vector3(0.055, 0.84, 0.014), metal.lightened(0.2))
			m.cyl(bone, Vector3(0, 0.94, 0), Vector3(0, 1.04, 0), 0.03, 0.0, metal.lightened(0.2), 4)
			m.sphere(bone, Vector3(0, -0.09, 0), 0.03, _cloth(), Vector3.ONE, 5)
		"dagger":
			m.cyl(bone, Vector3(0, -0.06, 0), Vector3(0, 0.06, 0), 0.02, 0.02, C_LEATHER, 5)
			m.box(bone, Vector3(0, 0.07, 0), Vector3(0.1, 0.02, 0.035), metal.darkened(0.15))
			m.box(bone, Vector3(0, 0.27, 0), Vector3(0.04, 0.38, 0.012), metal.lightened(0.2))
			m.cyl(bone, Vector3(0, 0.46, 0), Vector3(0, 0.54, 0), 0.022, 0.0, metal.lightened(0.2), 4)
		"spear":
			m.cyl(bone, Vector3(0, -0.6, 0), Vector3(0, 1.4, 0), 0.02, 0.02, C_WOOD, 5)
			m.cyl(bone, Vector3(0, 1.4, 0), Vector3(0, 1.72, 0), 0.05, 0.0, metal.lightened(0.2), 5)
			m.cyl(bone, Vector3(0, 1.36, 0), Vector3(0, 1.42, 0), 0.04, 0.04, metal, 5)
			m.box(bone, Vector3(0, 1.28, 0.06), Vector3(0.012, 0.14, 0.12), _cloth())
		"staff":
			m.cyl(bone, Vector3(0, -0.6, 0), Vector3(0, 1.15, 0), 0.025, 0.025, C_WOOD, 5)
			m.cyl(bone, Vector3(0, 1.1, 0), Vector3(0, 1.16, 0), 0.06, 0.06, metal, 6)
			m.sphere(bone, Vector3(0, 1.26, 0), 0.075, _cloth().lightened(0.25), Vector3.ONE, 6)
		"axe":
			m.cyl(bone, Vector3(0, -0.2, 0), Vector3(0, 0.95, 0), 0.025, 0.025, C_WOOD, 5)
			m.box(bone, Vector3(0, 0.82, -0.1), Vector3(0.03, 0.26, 0.22), metal.lightened(0.15))
		"hammer":
			m.cyl(bone, Vector3(0, -0.2, 0), Vector3(0, 1.0, 0), 0.025, 0.025, C_WOOD, 5)
			m.box(bone, Vector3(0, 1.0, 0), Vector3(0.22, 0.15, 0.15), metal)
		"shield":
			m.box(bone, Vector3(side * 0.05, 0.12, -0.1), Vector3(0.05, 0.05, 0.05), C_LEATHER)
			m.cyl(bone, Vector3(side * 0.04, 0.12, -0.1), Vector3(side * 0.04, 0.12, -0.14), 0.31, 0.31, metal, 8)
			m.cyl(bone, Vector3(side * 0.04, 0.12, -0.14), Vector3(side * 0.04, 0.12, -0.17), 0.25, 0.25, _cloth(), 8)
			m.sphere(bone, Vector3(side * 0.04, 0.12, -0.18), 0.07, metal.lightened(0.15), Vector3(1, 1, 0.6), 6)
		"tower_shield":
			m.box(bone, Vector3(side * 0.05, 0.2, -0.12), Vector3(0.52, 0.86, 0.05), metal)
			m.box(bone, Vector3(side * 0.05, 0.2, -0.15), Vector3(0.42, 0.76, 0.04), _cloth())
			m.box(bone, Vector3(side * 0.05, 0.2, -0.17), Vector3(0.1, 0.64, 0.03), metal.lightened(0.1))
			m.sphere(bone, Vector3(side * 0.05, 0.2, -0.19), 0.07, metal.lightened(0.2), Vector3(1, 1, 0.6), 6)
		"bow":
			var prev: Vector3 = Vector3.ZERO
			for i: int in 9:
				var t: float = -1.0 + float(i) * 0.25
				var p: Vector3 = Vector3(0.0, t * 0.62, -0.17 * (1.0 - t * t))
				if i > 0:
					m.cyl(bone, prev, p, 0.02, 0.02, C_WOOD, 5)
				prev = p
			m.cyl(bone, Vector3(0, -0.62, 0), Vector3(0, 0.62, 0), 0.006, 0.006, C_WHITE, 3)
	m.frame = Transform3D.IDENTITY
