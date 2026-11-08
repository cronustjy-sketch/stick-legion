class_name GoldRock
extends Node3D
## A gold rock: shiny low-poly stone with gold veins. Diggers mine it (scripts/digger.gd); it shrinks as the gold goes
## and disappears when empty. Layout and amounts come from data/economy.gd.

static var _rock_mesh: ArrayMesh
static var _gold_mesh: ArrayMesh
static var _rock_mat: StandardMaterial3D
static var _gold_mat: StandardMaterial3D

var capacity: float = EconomyData.ROCK_GOLD
var remaining: float = EconomyData.ROCK_GOLD
var rich: bool = false
var workers: Array[Node] = []  # Diggers that have claimed this rock

var _base_scale: float = 1.0
var _body: Node3D
var _label: Label3D


## Builds every gold rock of the battle: a few beside each fortress and two rich ones in the middle.
static func build_all(battle: Battle) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = BattlefieldData.SCENE_SEED + 31
	var placed: Array[Vector2] = []
	for side: float in [1.0, -1.0]:  # +1 = the player's end of the valley
		var count: int = rng.randi_range(EconomyData.ROCKS_NEAR_FORTRESS_MIN, EconomyData.ROCKS_NEAR_FORTRESS_MAX)
		var guard: int = 0
		var made: int = 0
		while made < count and guard < 400:
			guard += 1
			var x: float = (-1.0 if rng.randf() < 0.5 else 1.0) * rng.randf_range(EconomyData.ROCK_NEAR_X.x, EconomyData.ROCK_NEAR_X.y)
			var z: float = side * (BattlefieldData.FORTRESS_Z - rng.randf_range(EconomyData.ROCK_NEAR_Z.x, EconomyData.ROCK_NEAR_Z.y))
			var p: Vector2 = Vector2(x, z)
			var clear: bool = true
			for q: Vector2 in placed:
				if p.distance_to(q) < EconomyData.ROCK_SPACING:
					clear = false
			if not clear:
				continue
			placed.append(p)
			_make(battle, p, false, rng)
			made += 1
	for sx: float in [-1.0, 1.0]:
		_make(battle, Vector2(sx * EconomyData.ROCK_MID_X, 0.0), true, rng)


static func _make(battle: Battle, p: Vector2, is_rich: bool, rng: RandomNumberGenerator) -> void:
	var r: GoldRock = GoldRock.new()
	r.name = "GoldRock"
	r.rich = is_rich
	r.capacity = EconomyData.ROCK_GOLD_RICH if is_rich else EconomyData.ROCK_GOLD
	r.remaining = r.capacity
	r._base_scale = 1.45 if is_rich else 1.0
	battle.add_child(r)
	r.position = Vector3(p.x, battle.terrain.height_at(p.x, p.y), p.y)
	r.rotation.y = rng.randf() * TAU
	r._build()


## The nearest rock that still has gold and a free working spot (null when there is none).
static func nearest_free(tree: SceneTree, from: Vector3) -> GoldRock:
	var best: GoldRock = null
	var best_d: float = INF
	for n: Node in tree.get_nodes_in_group("gold_rocks"):
		var r: GoldRock = n as GoldRock
		if r.remaining <= 0.0 or r.workers.size() >= EconomyData.DIGGERS_PER_ROCK:
			continue
		var d: float = r.global_position.distance_to(from)
		if d < best_d:
			best_d = d
			best = r
	return best


func claim(d: Node) -> void:
	if not workers.has(d):
		workers.append(d)


func release(d: Node) -> void:
	workers.erase(d)


## How far from the centre a Digger stands to swing at it (shrinks with the rock).
func stand_distance() -> float:
	return 1.25 * _base_scale * lerpf(EconomyData.ROCK_MIN_SCALE, 1.0, remaining / capacity) + 0.7


## Takes up to `amount` gold out of the rock and returns what was taken.
func mine(amount: float) -> float:
	var got: float = minf(amount, remaining)
	remaining -= got
	_refresh_label()
	if remaining <= 0.5:
		remaining = 0.0
		_deplete()
	else:
		var s: float = _base_scale * lerpf(EconomyData.ROCK_MIN_SCALE, 1.0, remaining / capacity)
		create_tween().tween_property(_body, "scale", Vector3.ONE * s, 0.25).set_ease(Tween.EASE_OUT)
	return got


func _deplete() -> void:
	remove_from_group("gold_rocks")
	_label.visible = false
	var t: Tween = create_tween()
	t.tween_property(_body, "scale", Vector3.ONE * 0.01, 0.5).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)


func _build() -> void:
	add_to_group("gold_rocks")
	_ensure_meshes()
	_body = Node3D.new()
	_body.name = "Body"
	_body.scale = Vector3.ONE * _base_scale
	add_child(_body)
	var rock: MeshInstance3D = MeshInstance3D.new()
	rock.mesh = _rock_mesh
	rock.material_override = _rock_mat
	rock.scale = Vector3(1.3, 1.0, 1.15)
	rock.position.y = 0.38
	rock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(rock)
	var gold: MeshInstance3D = MeshInstance3D.new()
	gold.mesh = _gold_mesh
	gold.material_override = _gold_mat
	gold.scale = rock.scale
	gold.position = rock.position
	gold.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(gold)
	var shadow: BlobShadow = BlobShadow.make(Vector2(3.6, 3.6) * _base_scale)
	add_child(shadow)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.fixed_size = true
	_label.no_depth_test = true
	_label.font_size = 28
	_label.pixel_size = 0.0009
	_label.outline_size = 10
	_label.modulate = Color("ffd24a")
	_label.position = Vector3(0.0, 2.1 * _base_scale, 0.0)
	_label.visible = false
	add_child(_label)
	_refresh_label()


## The remaining gold floats over a rock once somebody has started on it.
func _refresh_label() -> void:
	if _label != null:
		_label.text = "%d" % int(remaining)
		_label.visible = remaining < capacity and remaining > 0.0


static func _ensure_meshes() -> void:
	if _rock_mesh != null:
		return
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 1.3
	sphere.radial_segments = 6
	sphere.rings = 3
	var st: SurfaceTool = SurfaceTool.new()
	st.append_from(sphere, 0, Transform3D.IDENTITY)
	_rock_mesh = _flat(st.commit()).commit()
	# Gold: chunky nuggets and flat veins sitting on the upper half of the rock.
	var nugget: SphereMesh = SphereMesh.new()
	nugget.radius = 0.3
	nugget.height = 0.46
	nugget.radial_segments = 5
	nugget.rings = 2
	var vein: BoxMesh = BoxMesh.new()
	vein.size = Vector3(0.95, 0.07, 0.17)
	var gst: SurfaceTool = SurfaceTool.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 99
	var dirs: Array[Vector3] = [
		Vector3(0.55, 0.62, 0.5), Vector3(-0.6, 0.55, 0.45), Vector3(0.1, 0.9, -0.35), Vector3(-0.35, 0.5, -0.75),
		Vector3(0.75, 0.4, -0.45), Vector3(0.0, 0.35, 0.93), Vector3(-0.9, 0.3, -0.1),
	]
	for d: Vector3 in dirs:
		var n: Vector3 = d.normalized()
		var at: Vector3 = Vector3(n.x * 0.98, n.y * 0.62, n.z * 0.98)
		var b: Basis = Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)) * Basis.from_scale(Vector3.ONE * rng.randf_range(0.75, 1.15))
		gst.append_from(nugget, 0, Transform3D(b, at))
	for i: int in 4:
		var n2: Vector3 = Vector3(rng.randf_range(-0.8, 0.8), rng.randf_range(0.25, 0.95), rng.randf_range(-0.8, 0.8)).normalized()
		var at2: Vector3 = Vector3(n2.x * 0.93, n2.y * 0.6, n2.z * 0.93)
		var b2: Basis = Basis.looking_at(-n2, Vector3.UP) * Basis.from_euler(Vector3(0.0, 0.0, rng.randf() * TAU))
		gst.append_from(vein, 0, Transform3D(b2, at2))
	_gold_mesh = _flat(gst.commit()).commit()
	_rock_mat = StandardMaterial3D.new()
	_rock_mat.albedo_color = Color("6b6159")
	_rock_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	_rock_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_gold_mat = StandardMaterial3D.new()
	_gold_mat.albedo_color = Color("ffc531")
	_gold_mat.metallic = 0.75
	_gold_mat.roughness = 0.32
	_gold_mat.emission_enabled = true
	_gold_mat.emission = Color("ffae1a")
	_gold_mat.emission_energy_multiplier = 0.55


## Flat-shaded copy of a mesh (faceted look).
static func _flat(m: ArrayMesh) -> SurfaceTool:
	var st: SurfaceTool = SurfaceTool.new()
	st.create_from(m, 0)
	st.deindex()
	st.generate_normals()
	return st
