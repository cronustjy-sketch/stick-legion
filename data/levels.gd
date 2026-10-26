class_name LevelData
extends RefCounted
## Campaign level rules. Enemy strength = 1 + 0.11 x (level - 1) (see UnitData.level_multiplier).
## Bosses (every 5th level) and the level-select map come in step 10.

## [unit, first level it appears in the enemy army]
const POOL_UNLOCK: Array = [
	["swordsman", 1], ["spearman", 2], ["archer", 3], ["shield_knight", 4],
	["mage", 6], ["assassin", 8], ["priest", 10],
]


static func pool(level: int) -> Array[String]:
	var out: Array[String] = []
	for e: Array in POOL_UNLOCK:
		if level >= int(e[1]):
			out.append(String(e[0]))
	return out


static func settings(level: int) -> Dictionary:
	return {
		"level": level,
		"multiplier": UnitData.level_multiplier(level),
		"start_gold": 40.0,
		"income": 6.0 + 0.8 * float(level - 1),
		"pop_cap": mini(40, 24 + 2 * level),
		"interval": maxf(1.2, 3.0 - 0.1 * float(level)),
		"pool": pool(level),
	}
