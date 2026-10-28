class_name UpgradeData
extends RefCounted
## Armory upgrades bought with stars. Each has 5 tiers; VALUES[0] is the base value, VALUES[1..5] the value after each tier.
## "fmt" says how a value is shown: mult_up (+N%), mult_down (-N%), hp, per_second, gold, pop.
## Balance changes happen here, never in gameplay code.

## Stars needed for tier 1..5 (the same for every upgrade). 12 stars per upgrade, 108 for all nine; the campaign holds 60.
const TIER_COST: Array[int] = [1, 2, 2, 3, 4]
const MAX_TIER: int = 5

const ORDER: Array[String] = [
	"hero_hp", "hero_damage", "skill_cooldown", "rage_gain",
	"unit_hp", "unit_damage", "income", "start_gold", "army_cap",
]

const DEFS: Dictionary = {
	"hero_hp": {"group": "hero", "name": "Hero max HP", "fmt": "hp", "values": [150.0, 165.0, 180.0, 195.0, 210.0, 225.0]},
	"hero_damage": {"group": "hero", "name": "Hero damage", "fmt": "mult_up", "values": [1.0, 1.08, 1.16, 1.24, 1.32, 1.4]},
	"skill_cooldown": {"group": "hero", "name": "Skill cooldown", "fmt": "mult_down", "values": [1.0, 0.92, 0.84, 0.76, 0.68, 0.6]},
	"rage_gain": {"group": "hero", "name": "Rage gain", "fmt": "mult_up", "values": [1.0, 1.15, 1.3, 1.45, 1.6, 1.8]},
	"unit_hp": {"group": "army", "name": "Unit HP", "fmt": "mult_up", "values": [1.0, 1.08, 1.16, 1.24, 1.32, 1.4]},
	"unit_damage": {"group": "army", "name": "Unit damage", "fmt": "mult_up", "values": [1.0, 1.07, 1.14, 1.21, 1.28, 1.35]},
	"income": {"group": "army", "name": "Gold per second", "fmt": "per_second", "values": [10.0, 11.5, 13.0, 14.5, 16.0, 17.5]},
	"start_gold": {"group": "army", "name": "Starting gold", "fmt": "gold", "values": [100.0, 140.0, 180.0, 220.0, 260.0, 300.0]},
	"army_cap": {"group": "army", "name": "Army cap", "fmt": "pop", "values": [40.0, 43.0, 46.0, 49.0, 52.0, 55.0]},
}

## Short explanation under each upgrade name.
const BLURBS: Dictionary = {
	"hero_hp": "Aldric can take more punishment.",
	"hero_damage": "Sword swings and skills hit harder.",
	"skill_cooldown": "Q E R F recharge faster.",
	"rage_gain": "The ultimate meter fills faster.",
	"unit_hp": "Your soldiers survive longer.",
	"unit_damage": "Your soldiers hit harder.",
	"income": "More gold every second.",
	"start_gold": "Begin each battle richer.",
	"army_cap": "Field a bigger army.",
}


## The value of an upgrade at a tier (0..MAX_TIER).
static func value_at(key: String, tier: int) -> float:
	var vals: Array = DEFS[key].values
	return float(vals[clampi(tier, 0, vals.size() - 1)])


## The value currently bought (what gameplay code reads).
static func value(key: String) -> float:
	return value_at(key, GameState.upgrade_tier(key))


static func cost_of_next(key: String) -> int:
	var t: int = GameState.upgrade_tier(key)
	return int(TIER_COST[t]) if t < MAX_TIER else 0


## A value as shown to the player ("+16%", "180 HP", "13.0/s"...).
static func show(key: String, v: float) -> String:
	match String(DEFS[key].fmt):
		"mult_up":
			var up: int = roundi((v - 1.0) * 100.0)
			return "+%d%%" % up if up > 0 else "0%"
		"mult_down":
			var down: int = roundi((1.0 - v) * 100.0)
			return "-%d%%" % down if down > 0 else "0%"
		"hp":
			return "%d HP" % roundi(v)
		"per_second":
			return "%.1f/s" % v
	return "%d" % roundi(v)
