class_name StorySets
extends RefCounted
## Backdrops and scenery for the story cards: each set is a sky + ground + light mood plus a few props.
## Props are built from simple low-poly boxes and cones, in the same toon style as the battlefield.

## sky = [top, horizon]; ground; sun = [colour, energy]; ambient; fog
const SETS: Dictionary = {
	"burning_city": {"sky": ["3a1a1a", "e8602e"], "ground": "4a3d38", "sun": ["ffb070", 0.8], "ambient": "9a7060", "fog": "b0603a",
		"props": [["wall", -6, -6, 15, 1.4, ""], ["wall", 5, -8, -20, 1.6, ""], ["wall", 0, -13, 0, 2.0, ""], ["fire", -4, -4, 0, 1.4, ""], ["fire", 3, -5, 0, 1.2, ""],
			["fire", 7, -7, 0, 1.8, ""], ["fire", -8, -9, 0, 2.0, ""], ["pillar", 2, -3, 8, 1.0, "broken"]]},
	"ashes": {"sky": ["5a5560", "b8a090"], "ground": "5a524a", "sun": ["e0d0c0", 0.7], "ambient": "a09890", "fog": "a09488",
		"props": [["wall", -7, -7, 10, 1.3, ""], ["wall", 6, -9, -15, 1.5, ""], ["fire", -9, -12, 0, 1.6, ""], ["pillar", 4, -4, 0, 1.0, "broken"], ["rock", -4, -3, 20, 1.0, ""]]},
	"dawn": {"sky": ["5a7ac8", "f6c890"], "ground": "7a8a50", "sun": ["ffd9a0", 1.1], "ambient": "c0c0d0", "fog": "e8c8a0",
		"props": [["wall", -8, -8, 10, 1.3, ""], ["tree", 7, -6, 0, 1.4, ""], ["tree", -6, -9, 0, 1.2, ""], ["rock", 4, -3, 30, 1.0, ""]]},
	"village": {"sky": ["3a80d0", "b0daf5"], "ground": "7a9a48", "sun": ["fff0d0", 1.0], "ambient": "c4d2e8", "fog": "b4d6ee",
		"props": [["house", -5, -7, 10, 1.2, "red"], ["house", 1, -9, -5, 1.4, "red"], ["house", 7, -6, 20, 1.2, "red"], ["tree", -9, -4, 0, 1.4, ""], ["tree", 10, -3, 0, 1.3, ""],
			["banner", -2.5, -3, 0, 1.2, "red"], ["banner", 4, -4, 0, 1.2, "red"]]},
	"camp": {"sky": ["3a70c0", "a8c8e0"], "ground": "6a8a48", "sun": ["fff0d0", 1.0], "ambient": "b8c4d8", "fog": "a8c8d8",
		"props": [["tent", -6, -5, 20, 1.2, ""], ["tent", 6, -6, -15, 1.3, ""], ["tree", -9, -9, 0, 1.4, ""], ["tree", 9, -8, 0, 1.3, ""], ["rock", 3, -2, 0, 1.0, ""]]},
	"camp_night": {"sky": ["0a1030", "2a3a68"], "ground": "2a3a2e", "sun": ["8aa0e0", 0.5], "ambient": "4a5a88", "fog": "202a48",
		"props": [["tent", -6, -5, 20, 1.2, ""], ["tent", 6, -6, -15, 1.3, ""], ["tree", -9, -9, 0, 1.4, ""], ["tree", 9, -8, 0, 1.3, ""]]},
	"pass": {"sky": ["4a70b0", "a8b8c8"], "ground": "7a766e", "sun": ["fff0e0", 1.0], "ambient": "a8b0c0", "fog": "9aa8b8",
		"props": [["wall", -4, -9, 0, 2.2, ""], ["wall", 4, -9, 0, 2.2, ""], ["pillar", -9, -8, 0, 2.0, ""], ["pillar", 9, -8, 0, 2.0, ""], ["banner", -2, -8, 0, 2.0, "red"],
			["banner", 2, -8, 0, 2.0, "red"], ["rock", -7, -4, 10, 2.0, ""], ["rock", 8, -4, -20, 2.2, ""]]},
	"wreck": {"sky": ["5a6a90", "c8b090"], "ground": "5a5a4a", "sun": ["ffe0b0", 0.9], "ambient": "a8a8b0", "fog": "b0a890",
		"props": [["rock", -5, -3, 10, 1.4, ""], ["rock", 5, -4, 40, 1.2, ""], ["fire", 3.5, -3.5, 0, 0.8, ""], ["tree", -8, -8, 0, 1.2, ""]]},
	"fields_fire": {"sky": ["5a2a1a", "f08a3a"], "ground": "8a7a3a", "sun": ["ffa060", 0.9], "ambient": "a08060", "fog": "c88040",
		"props": [["fire", -6, -4, 0, 1.6, ""], ["fire", -1, -6, 0, 2.0, ""], ["fire", 5, -5, 0, 1.8, ""], ["fire", 9, -8, 0, 2.4, ""], ["fire", -9, -9, 0, 2.2, ""],
			["house", 3, -12, 10, 1.3, "burnt"], ["tree", -4, -9, 0, 1.2, ""]]},
	"flashback": {"sky": ["7aa8e0", "ffe8b8"], "ground": "9ab060", "sun": ["fff0c0", 1.3], "ambient": "e8e0c8", "fog": "f6e8c0",
		"props": [["tree", -7, -6, 0, 1.4, ""], ["tree", 8, -7, 0, 1.3, ""], ["wall", 0, -11, 0, 1.6, ""], ["banner", -3.5, -4, 0, 1.2, "gold"], ["banner", 3.5, -4, 0, 1.2, "gold"]]},
	"throne_hall_warm": {"sky": ["302a20", "6a5030"], "ground": "8a7050", "sun": ["ffd890", 1.0], "ambient": "c0a070", "fog": "6a5030",
		"props": [["pillar", -6, -5, 0, 2.0, ""], ["pillar", 6, -5, 0, 2.0, ""], ["banner", -3, -6, 0, 2.0, "gold"], ["banner", 3, -6, 0, 2.0, "gold"], ["wall", 0, -9, 0, 3.0, ""]]},
	"snow": {"sky": ["8aa0c0", "e8eef6"], "ground": "e8eef4", "sun": ["f0f4ff", 1.0], "ambient": "d0d8e8", "fog": "dde4ee",
		"props": [["tree", -6, -6, 0, 1.4, "snow"], ["tree", 7, -7, 0, 1.6, "snow"], ["tree", 2, -10, 0, 1.3, "snow"], ["rock", -3, -3, 20, 1.2, "snow"]]},
	"ashes_dusk": {"sky": ["2a2a48", "c06a50"], "ground": "5a4e48", "sun": ["ff9a70", 0.7], "ambient": "8a7080", "fog": "9a6458",
		"props": [["wall", -7, -7, 10, 1.3, ""], ["pillar", 5, -5, 0, 1.2, "broken"], ["fire", -9, -11, 0, 1.4, ""]]},
	"ruined_capital": {"sky": ["3a2030", "d0583a"], "ground": "4a403c", "sun": ["ff9a60", 0.8], "ambient": "8a6a60", "fog": "a85a40",
		"props": [["wall", -7, -7, 10, 1.6, ""], ["wall", 7, -8, -10, 1.8, ""], ["pillar", -3, -9, 0, 1.6, "broken"], ["banner", -5, -3, 0, 1.8, "red"], ["banner", 5, -3, 0, 1.8, "red"],
			["fire", -10, -12, 0, 1.8, ""], ["fire", 10, -11, 0, 1.8, ""]]},
	"throne_hall": {"sky": ["1a1020", "5a2a30"], "ground": "5a4a4a", "sun": ["ff8a70", 0.9], "ambient": "8a6a70", "fog": "4a2a30",
		"props": [["pillar", -6, -5, 0, 2.0, ""], ["pillar", 6, -5, 0, 2.0, ""], ["banner", -3, -6, 0, 2.0, "red"], ["banner", 3, -6, 0, 2.0, "red"], ["wall", 0, -9, 0, 3.0, ""],
			["fire", -5, -2, 0, 0.7, ""], ["fire", 5, -2, 0, 0.7, ""]]},
	"rebuilt": {"sky": ["4a8ae0", "fff0c8"], "ground": "86a94f", "sun": ["fff0d0", 1.2], "ambient": "d0d8e8", "fog": "f0e8c8",
		"props": [["wall", -7, -8, 0, 1.4, ""], ["wall", 7, -8, 0, 1.4, ""], ["tree", -9, -4, 0, 1.4, ""], ["tree", 9, -5, 0, 1.3, ""], ["house", 0, -11, 0, 1.6, "gold"]]},
	"sunset_steps": {"sky": ["2a3a78", "ff9a50"], "ground": "6a5a4a", "sun": ["ffb070", 1.0], "ambient": "b09080", "fog": "e08850",
		"props": [["steps", 0, -4, 0, 1.4, ""], ["pillar", -6, -6, 0, 1.8, ""], ["pillar", 6, -6, 0, 1.8, ""], ["throne", 0, -8, 180, 1.4, ""]]},
}

static var _toon_cache: Dictionary = {}


## Builds the backdrop (ground + scenery) under `parent`. Returns the environment pieces so the player can recolour the sky.
static func build_props(parent: Node3D, set_name: String, extra: Array) -> void:
	var set_def: Dictionary = SETS.get(set_name, SETS.dawn)
	var lights: int = 0
	for p: Array in (set_def.props as Array) + extra:
		var n: Node3D = _prop(String(p[0]), String(p[5]), float(p[4]))
		if n == null:
			continue
		n.position = Vector3(float(p[1]), 0.0, float(p[2]))
		n.rotation_degrees.y = float(p[3])
		parent.add_child(n)
		if String(p[0]) == "fire" and lights < 3:
			lights += 1
			var l: OmniLight3D = OmniLight3D.new()
			l.light_color = Color("ff8a3a")
			l.light_energy = 1.6
			l.omni_range = 9.0
			l.position = Vector3(0.0, 1.6 * float(p[4]), 0.0)
			n.add_child(l)


static func _prop(kind: String, variant: String, scale: float) -> Node3D:
	var root: Node3D = Node3D.new()
	match kind:
		"fire":
			var outer: MeshInstance3D = _cone(Color("ff6a1a"), 0.42, 1.25, true)
			var inner: MeshInstance3D = _cone(Color("ffd24a"), 0.24, 0.8, true)
			root.add_child(outer)
			root.add_child(inner)
			_cyl_into(root, Vector3(0, 0.15, 0), 0.9, 0.3, Color("2a2420"))
			root.scale = Vector3.ONE * scale
			var tw: Tween = outer.create_tween().set_loops()
			tw.tween_property(outer, "scale", Vector3(1.0, 1.25, 1.0), 0.22)
			tw.tween_property(outer, "scale", Vector3(1.0, 0.85, 1.0), 0.3)
			var tw2: Tween = inner.create_tween().set_loops()
			tw2.tween_property(inner, "scale", Vector3(1.0, 0.8, 1.0), 0.17)
			tw2.tween_property(inner, "scale", Vector3(1.0, 1.2, 1.0), 0.25)
		"wall":
			_box_into(root, Vector3(0, 1.1, 0), Vector3(5.0, 2.2, 0.9), Color("8d8a84"))
			_box_into(root, Vector3(-1.4, 2.4, 0), Vector3(1.4, 0.7, 0.9), Color("7d7a74"), 12.0)
			_box_into(root, Vector3(1.6, 2.1, 0), Vector3(1.0, 0.4, 0.9), Color("9d9a94"), -8.0)
			root.scale = Vector3.ONE * scale
		"pillar":
			var h: float = 2.2 if variant == "broken" else 4.0
			_cyl_into(root, Vector3(0, h * 0.5, 0), 0.5, h, Color("a8a49c"))
			root.scale = Vector3.ONE * scale
		"banner":
			var cloth: Color = _banner_colour(variant)
			_cyl_into(root, Vector3(0, 1.8, 0), 0.06, 3.6, Color("5e4630"))
			_box_into(root, Vector3(0.0, 2.8, 0.35), Vector3(0.05, 1.3, 0.7), cloth)
			if variant.ends_with("torn"):
				_box_into(root, Vector3(0.0, 2.1, 0.3), Vector3(0.05, 0.4, 0.4), cloth.darkened(0.2), 20.0)
			root.scale = Vector3.ONE * scale
			if variant == "red_burning":
				root.rotation_degrees.z = 8.0
		"house":
			var wall: Color = Color("c8b898") if variant != "burnt" else Color("4a403a")
			_box_into(root, Vector3(0, 1.0, 0), Vector3(3.0, 2.0, 2.6), wall)
			var roof: MeshInstance3D = MeshInstance3D.new()
			var pm: PrismMesh = PrismMesh.new()
			pm.size = Vector3(3.5, 1.4, 3.0)
			roof.mesh = pm
			roof.material_override = _toon(Color("b02a22") if variant == "red" else (Color("c8a038") if variant == "gold" else Color("3a2a26")))
			roof.position = Vector3(0, 2.7, 0)
			root.add_child(roof)
			root.scale = Vector3.ONE * scale
		"tent":
			var tent: MeshInstance3D = MeshInstance3D.new()
			var pm2: PrismMesh = PrismMesh.new()
			pm2.size = Vector3(3.0, 2.2, 3.4)
			tent.mesh = pm2
			tent.material_override = _toon(Color("b8a888"))
			tent.position = Vector3(0, 1.1, 0)
			root.add_child(tent)
			root.scale = Vector3.ONE * scale
		"tree":
			var snow: bool = variant == "snow"
			_cyl_into(root, Vector3(0, 0.9, 0), 0.25, 1.8, Color("5e4630"))
			root.add_child(_cone_at(Vector3(0, 2.6, 0), 1.7, 2.8, Color("e8eef4") if snow else Color("3f7a3a")))
			root.add_child(_cone_at(Vector3(0, 4.0, 0), 1.2, 2.4, Color("f4f8fc") if snow else Color("4b8b43")))
			root.scale = Vector3.ONE * scale
		"rock":
			var rm: MeshInstance3D = MeshInstance3D.new()
			var sm: SphereMesh = SphereMesh.new()
			sm.radial_segments = 6
			sm.rings = 3
			rm.mesh = sm
			rm.material_override = _toon(Color("eef2f6") if variant == "snow" else Color("8b8d8f"))
			rm.scale = Vector3(1.4, 0.9, 1.1)
			rm.position.y = 0.4
			root.add_child(rm)
			root.scale = Vector3.ONE * scale
		"throne":
			_box_into(root, Vector3(0, 0.4, 0), Vector3(2.4, 0.8, 2.0), Color("3a3236"))
			_box_into(root, Vector3(0, 0.95, 0.0), Vector3(1.2, 0.3, 1.2), Color("5a2a2a"))
			_box_into(root, Vector3(0, 2.0, 0.75), Vector3(1.4, 2.4, 0.3), Color("2a2428"))
			_box_into(root, Vector3(0, 3.4, 0.75), Vector3(0.7, 0.8, 0.3), Color("c8a038"))
			root.scale = Vector3.ONE * scale
		"steps":
			for i: int in 4:
				_box_into(root, Vector3(0, 0.15 + 0.3 * float(i), -0.9 * float(i)), Vector3(6.0 - 0.6 * float(i), 0.3, 1.8), Color("8a8480"))
			root.scale = Vector3.ONE * scale
		"wreck":
			_box_into(root, Vector3(0, 0.6, 0), Vector3(3.0, 0.5, 4.0), Color("4a3a2a"), 10.0)
			_box_into(root, Vector3(0.8, 1.6, 0.4), Vector3(0.3, 2.2, 0.3), Color("3a2a1c"), 25.0)
			_box_into(root, Vector3(-1.0, 1.0, -0.6), Vector3(0.3, 1.6, 0.3), Color("3a2a1c"), -40.0)
			_cyl_into(root, Vector3(1.8, 0.7, 1.0), 0.7, 0.2, Color("3a2a1c"), 90.0)
			root.scale = Vector3.ONE * scale
		_:
			return null
	return root


static func _banner_colour(variant: String) -> Color:
	if variant.begins_with("red"):
		return Color("bd2a20")
	return Color("ffc531")


static func _toon(c: Color) -> StandardMaterial3D:
	var key: String = c.to_html()
	if not _toon_cache.has(key):
		var m: StandardMaterial3D = StandardMaterial3D.new()
		m.albedo_color = c
		m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		_toon_cache[key] = m
	return _toon_cache[key]


static func _box_into(parent: Node3D, pos: Vector3, size: Vector3, color: Color, roll_deg: float = 0.0) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var b: BoxMesh = BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = _toon(color)
	mi.position = pos
	mi.rotation_degrees.z = roll_deg
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


static func _cyl_into(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, roll_deg: float = 0.0) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var c: CylinderMesh = CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 8
	c.rings = 1
	mi.mesh = c
	mi.material_override = _toon(color)
	mi.position = pos
	mi.rotation_degrees.z = roll_deg
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


static func _cone_at(pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var c: CylinderMesh = CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 6
	c.rings = 1
	mi.mesh = c
	mi.material_override = _toon(color)
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _cone(color: Color, radius: float, height: float, glow: bool) -> MeshInstance3D:
	var mi: MeshInstance3D = _cone_at(Vector3(0, height * 0.5 + 0.2, 0), radius, height, color)
	if glow:
		var m: StandardMaterial3D = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = color
		mi.material_override = m
	return mi
