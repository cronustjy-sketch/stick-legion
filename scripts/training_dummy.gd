class_name TrainingDummy
extends Node3D
## Debug target so the hero's combo can be tested before real units exist (step 4 replaces it).
## Implements the "hittable_enemy" interface the hero uses.

const MAX_HP: float = 120.0

var hp: float = MAX_HP
var hit_radius: float = 0.55
var hits_taken: int = 0

var _model: Stickman


func _ready() -> void:
	add_to_group("hittable_enemy")
	var body: StaticBody3D = StaticBody3D.new()  # solid, so the hero cannot lunge through it
	body.collision_layer = 2
	var cs: CollisionShape3D = CollisionShape3D.new()
	var cap: CapsuleShape3D = CapsuleShape3D.new()
	cap.radius = hit_radius
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	body.add_child(cs)
	add_child(body)
	_model = Stickman.new()
	_model.setup("swordsman", 1)
	add_child(_model)
	_model.player.animation_finished.connect(_on_anim_finished)


func is_alive() -> bool:
	return hp > 0.0


func nearest_point(_from: Vector3) -> Vector3:
	return global_position


func take_damage(amount: float, _from: Vector3) -> void:
	if hp <= 0.0:
		return
	hp -= amount
	hits_taken += 1
	if hp <= 0.0:
		_model.play("die", 1.0, true)
		get_tree().create_timer(3.0).timeout.connect(_revive)
	else:
		_model.play("hit", 1.0, true)


func _on_anim_finished(anim: StringName) -> void:
	if anim == &"hit" and hp > 0.0:
		_model.play("idle")


func _revive() -> void:
	hp = MAX_HP
	_model.play("idle", 1.0, true)
