class_name ArmyManager
extends Node
## The player's economy: gold income, kill rewards, population cap and spawning units at the fortress.

signal gold_changed(gold: int)
signal pop_changed(used: int, cap: int)
signal message(text: String)
signal order_changed(order: int)

enum Order { CHARGE, HOLD, FOLLOW, RETREAT }
const ORDER_NAMES: Array[String] = ["Charge", "Hold", "Follow", "Retreat"]

var battle: Battle
var gold: float = EconomyData.START_GOLD
var pop_used: int = 0
var pop_cap: int = EconomyData.POP_CAP
var order: Order = Order.CHARGE

var _slot_counter: int = 0

var _last_gold: int = -1


func _ready() -> void:
	_emit_gold()
	pop_changed.emit(pop_used, pop_cap)


func _process(delta: float) -> void:
	_buff_left = maxf(_buff_left - delta, 0.0)
	gold += EconomyData.INCOME_PER_SECOND * delta
	_emit_gold()


func cost_of(key: String) -> int:
	return int(UnitData.STATS[key].cost)


func pop_of(key: String) -> int:
	return int(UnitData.STATS[key].pop)


## Empty string when the unit can be bought, otherwise the reason it cannot.
func why_not(key: String) -> String:
	if battle.level < LevelData.unit_unlock(key) and not battle.unlock_all:
		return Loc.t("%s unlocks at level %d") % [Loc.t(UnitData.STATS[key].name), LevelData.unit_unlock(key)]
	if gold < cost_of(key):
		return Loc.t("Not enough gold")
	if pop_used + pop_of(key) > pop_cap:
		return Loc.t("Population full")
	if not battle.player_fortress.is_alive():
		return Loc.t("Fortress destroyed")
	return ""


func try_spawn(key: String) -> bool:
	var reason: String = why_not(key)
	if reason != "":
		message.emit(reason)
		return false
	gold -= cost_of(key)
	Sfx.play("coin", -4.0)
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


func set_order(o: Order) -> void:
	if o == order:
		return
	order = o
	Sfx.play("order", -4.0)
	order_changed.emit(o)
	message.emit(Loc.f("Order: %s", [Loc.t(ORDER_NAMES[o])]))
	get_tree().call_group("units_team0", "refresh_orders")


## Each player unit gets a stable slot number; formations (hold line, follow, retreat) are built from it.
func next_slot() -> int:
	_slot_counter += 1
	return _slot_counter


## Temporary damage boost for the whole army (hero skills War Cry and Legion Wrath).
var _buff_mult: float = 1.0
var _buff_left: float = 0.0


func apply_buff(mult: float, seconds: float) -> void:
	_buff_mult = maxf(mult, 1.0)
	_buff_left = seconds


func damage_buff() -> float:
	return _buff_mult if _buff_left > 0.0 else 1.0
