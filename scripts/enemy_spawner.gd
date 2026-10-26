class_name EnemySpawner
extends Node
## The enemy "player": earns gold, then buys units from the level's pool at its fortress, up to its population cap.

var battle: Battle
var settings: Dictionary
var gold: float = 0.0
var enabled: bool = true

var _clock: float = 0.0


func setup(b: Battle, level: int) -> void:
	battle = b
	settings = LevelData.settings(level)
	gold = float(settings.start_gold)


func _process(delta: float) -> void:
	if not enabled or not battle.enemy_fortress.is_alive():
		return
	gold += float(settings.income) * delta
	_clock += delta
	if _clock < float(settings.interval):
		return
	_clock = 0.0
	var pop: int = 0
	for n: Node in get_tree().get_nodes_in_group("units_team1"):
		pop += int(UnitData.STATS[(n as Unit).key].pop)
	# Cheap units are picked more often than expensive ones.
	var options: Array[String] = []
	var weights: Array[float] = []
	var total: float = 0.0
	for key: String in settings.pool:
		var s: Dictionary = UnitData.STATS[key]
		if float(s.cost) <= gold and pop + int(s.pop) <= int(settings.pop_cap):
			options.append(key)
			var w: float = 100.0 / float(s.cost)
			weights.append(w)
			total += w
	if options.is_empty():
		return
	var roll: float = randf() * total
	for i: int in options.size():
		roll -= weights[i]
		if roll <= 0.0 or i == options.size() - 1:
			gold -= float(UnitData.STATS[options[i]].cost)
			battle.spawn_unit(options[i], 1)
			return
