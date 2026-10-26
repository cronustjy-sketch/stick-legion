class_name LevelData
extends RefCounted
## Campaign level rules. Enemy strength = 1 + 0.11 x (level - 1) (see UnitData.level_multiplier).
## Every 5th level is a boss level (see data/bosses.gd): the enemy fortress is shielded until the boss falls.

const LEVEL_COUNT: int = 20

const NAMES: Array[String] = [
	"Green Valley", "Mossy Crossing", "Archer's Ridge", "Ironwood Pass", "Gorath's Gate",
	"Stonebridge", "Giant's Meadow", "Ashen Fields", "Catapult Hill", "Vexra's Bastion",
	"Frostwatch", "Ember Road", "Raven Hollow", "Siege Plains", "Mordrek's Citadel",
	"Black Marsh", "Thunder Pass", "Crimson Steppe", "Broken Throne", "The Iron Emperor",
]

## [unit, first level it appears in the enemy army]
const POOL_UNLOCK: Array = [
	["swordsman", 1], ["spearman", 2], ["archer", 3], ["shield_knight", 4],
	["cavalry", 5], ["mage", 6], ["giant", 7], ["assassin", 8], ["catapult", 9], ["priest", 10],
]


static func pool(level: int) -> Array[String]:
	var out: Array[String] = []
	for e: Array in POOL_UNLOCK:
		if level >= int(e[1]):
			out.append(String(e[0]))
	return out


static func is_boss_level(level: int) -> bool:
	return not BossData.for_level(level).is_empty()


static func level_name(level: int) -> String:
	return NAMES[clampi(level - 1, 0, NAMES.size() - 1)]


static func settings(level: int) -> Dictionary:
	return {
		"level": level,
		"name": level_name(level),
		"multiplier": UnitData.level_multiplier(level),
		"start_gold": 40.0,
		"income": 6.0 + 0.8 * float(level - 1),
		"pop_cap": mini(40, 24 + 2 * level),
		"interval": maxf(1.2, 3.0 - 0.1 * float(level)),
		"fortress_hp": 3000.0 * (1.0 + 0.08 * float(level - 1)),
		"pool": pool(level),
		"boss": BossData.for_level(level),
	}
