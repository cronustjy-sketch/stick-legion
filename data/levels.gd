class_name LevelData
extends RefCounted
## Campaign: 4 chapters x 5 levels (see STORY.md). Enemy strength = 1 + 0.11 x (level - 1) (see UnitData.level_multiplier).
## Every 5th level is a boss level (see data/bosses.gd): the enemy fortress is shielded until the boss falls.

const LEVEL_COUNT: int = 20

const NAMES: Array[String] = [
	"Border Village", "Mossy Crossing", "Archer's Ridge", "Ironwood Road", "Grask's Camp",
	"Foothills", "Cliffwatch", "Ashen Pass", "Boulder Run", "Volk's Siege Fortress",
	"Wheat Fires", "Ember Road", "Raven Hollow", "Siege Plains", "The Twin Blades' Field",
	"Burned Streets", "Palace Square", "Ruined Gate", "Throne Stairs", "The Crimson Throne",
]

const CHAPTERS: Array[Dictionary] = [
	{"name": "The Green Valleys", "first": 1, "last": 5},
	{"name": "The Iron Pass", "first": 6, "last": 10},
	{"name": "The Burning Fields", "first": 11, "last": 15},
	{"name": "The Crimson Throne", "first": 16, "last": 20},
]

## The level at which each unit becomes available to the player (and starts appearing in the enemy army). From STORY.md.
const UNIT_UNLOCK: Dictionary = {
	"swordsman": 1, "archer": 2, "spearman": 3, "shield_knight": 4, "mage": 6, "assassin": 7,
	"priest": 8, "giant": 11, "cavalry": 12, "catapult": 13,
}


static func pool(level: int) -> Array[String]:
	var out: Array[String] = []
	for k: String in UnitData.ALL_ORDER:
		if level >= int(UNIT_UNLOCK[k]):
			out.append(k)
	return out


static func unit_unlock(key: String) -> int:
	return int(UNIT_UNLOCK.get(key, 1))


static func chapter_of(level: int) -> int:
	for i: int in CHAPTERS.size():
		if level <= int(CHAPTERS[i].last):
			return i + 1
	return CHAPTERS.size()


static func chapter_name(level: int) -> String:
	return String(CHAPTERS[chapter_of(level) - 1].name)


static func is_boss_level(level: int) -> bool:
	return not BossData.for_level(level).is_empty()


static func level_name(level: int) -> String:
	if level > LEVEL_COUNT:
		return "Endless Battle %d" % (level - LEVEL_COUNT)
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
