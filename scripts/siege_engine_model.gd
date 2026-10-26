class_name SiegeEngineModel
extends UnitVisual
## Siege Master Volk's war machine: a giant catapult with Volk standing on the platform.

var engine: CatapultModel
var rider: Stickman


func setup(team: int) -> void:
	engine = CatapultModel.new()
	engine.setup(team)
	engine.scale = Vector3.ONE * 2.1
	add_child(engine)
	rider = Stickman.new()
	rider.setup("volk_rider", team)
	rider.position = Vector3(0.0, 1.85, 0.9)
	add_child(rider)
	var rs: Node = rider.get_node_or_null("BlobShadow")
	if rs != null:
		rs.queue_free()


func play(anim: StringName, speed: float = 1.0, restart: bool = false) -> void:
	engine.play(anim, speed, restart)
	match anim:
		&"walk", &"run":
			rider.play("idle")
		&"die":
			rider.play("die", 1.0, true)
			var t: Tween = create_tween()
			t.tween_property(rider, "position:y", rider.position.y - 0.6, 0.6)
		_:
			rider.play(anim, speed, restart)
