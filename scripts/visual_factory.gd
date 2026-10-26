class_name VisualFactory
extends RefCounted
## Creates the right visual for a unit key (stickman rig, cavalry, catapult).


static func create(key: String, team: int) -> UnitVisual:
	match key:
		"cavalry":
			var c: CavalryModel = CavalryModel.new()
			c.setup(team)
			return c
		"catapult":
			var k: CatapultModel = CatapultModel.new()
			k.setup(team)
			return k
		_:
			var s: Stickman = Stickman.new()
			s.setup(key, team)
			return s
