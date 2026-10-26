class_name ArmyManager
extends Node
## The player's economy: gold income, kill rewards, population cap and spawning units at the fortress.

signal gold_changed(gold: int)
signal pop_changed(used: int, cap: int)
signal message(text: String)

var battle: Battle
var gold: float = EconomyData.START_GOLD
var pop_used: int = 0
var pop_cap: int = EconomyData.POP_CAP

var _last_gold: int = -1


func _ready() -> void:
	_emit_gold()
	pop_changed.emit(pop_used, pop_cap)


func _process(delta: float) -> void:
	gold += EconomyData.INCOME_PER_SECOND * delta
	_emit_gold()


func cost_of(key: String) -> int:
	return int(UnitData.STATS[key].cost)


func pop_of(key: String) -> int:
	return int(UnitData.STATS[key].pop)


## Empty string when the unit can be bought, otherwise the reason it cannot.
func why_not(key: String) -> String:
	if gold < cost_of(key):
		return "Not enough gold"
	if pop_used + pop_of(key) > pop_cap:
		return "Population full"
	if not battle.player_fortress.is_alive():
		return "Fortress destroyed"
	return ""


func try_spawn(key: String) -> bool:
	var reason: String = why_not(key)
	if reason != "":
		message.emit(reason)
		return false
	gold -= cost_of(key)
	_emit_gold(true)
	battle.spawn_unit(key, 0)
	recount_pop()
	return true


func on_unit_died(u: Unit) -> void:
	if u.team == 1:
		gold += float(UnitData.STATS[u.key].cost) * EconomyData.KILL_REWARD_FACTOR
		_emit_gold(true)
	else:
		recount_pop()


func recount_pop() -> void:
	var used: int = 0
	for n: Node in get_tree().get_nodes_in_group("units_team0"):
		used += pop_of((n as Unit).key)
	pop_used = used
	pop_changed.emit(pop_used, pop_cap)


func _emit_gold(force: bool = false) -> void:
	var g: int = int(gold)
	if force or g != _last_gold:
		_last_gold = g
		gold_changed.emit(g)
