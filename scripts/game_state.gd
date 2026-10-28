class_name GameState
extends RefCounted
## Progress that survives scene reloads: the level being played and the highest level unlocked (saved to disk).

const SAVE_PATH: String = "user://stick_legion.cfg"

static var current_level: int = 1
static var seen_cards: Dictionary = {}  # story card id -> true
static var endings: Dictionary = {}  # "brothers" / "crown" -> true
static var story_queue: Array[String] = []  # cards the story player will show next
static var story_next: String = "res://scenes/main_menu.tscn"  # where to go afterwards
static var persist: bool = true  # false in scripted tests: nothing is written to the save file
static var story_replay: bool = false  # replaying from the Story menu: no choices, nothing is saved
static var highest_unlocked: int = 1
static var stars: Dictionary = {}  # level -> best stars (1..3)
static var upgrades: Dictionary = {}  # upgrade key -> tier bought (0..5)
static var _loaded: bool = false


static func load_progress() -> void:
	if _loaded:
		return
	_loaded = true
	for a: String in OS.get_cmdline_user_args():
		if (a.ends_with("-test") and a != "--start-test") or a.begins_with("--boss-level=") or a.begins_with("--story-ending="):
			persist = false  # scripted tests never touch the real save file
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		highest_unlocked = int(cfg.get_value("progress", "highest_unlocked", 1))
		for lvl: String in cfg.get_section_keys("stars") if cfg.has_section("stars") else PackedStringArray():
			stars[int(lvl)] = clampi(int(cfg.get_value("stars", lvl, 0)), 0, 3)
		for key: String in cfg.get_section_keys("upgrades") if cfg.has_section("upgrades") else PackedStringArray():
			if UpgradeData.DEFS.has(key):
				upgrades[key] = clampi(int(cfg.get_value("upgrades", key, 0)), 0, UpgradeData.MAX_TIER)
		for id: String in PackedStringArray(cfg.get_value("story", "seen", PackedStringArray())):
			seen_cards[id] = true
		for e: String in PackedStringArray(cfg.get_value("story", "endings", PackedStringArray())):
			endings[e] = true


## Records a win. `star_count` (1..3) is kept only if it beats the best so far; returns the stars newly earned.
static func level_won(level: int, star_count: int = 1) -> int:
	highest_unlocked = maxi(highest_unlocked, level + 1)
	var gained: int = 0
	if level >= 1 and level <= LevelData.LEVEL_COUNT:  # endless battles give no stars
		var best: int = int(stars.get(level, 0))
		if star_count > best:
			gained = star_count - best
			stars[level] = star_count
	save()
	return gained


static func stars_of(level: int) -> int:
	return int(stars.get(level, 0))


static func stars_earned() -> int:
	var n: int = 0
	for v: Variant in stars.values():
		n += int(v)
	return n


static func stars_spent() -> int:
	var n: int = 0
	for key: String in upgrades:
		for t: int in int(upgrades[key]):
			n += int(UpgradeData.TIER_COST[t])
	return n


static func stars_available() -> int:
	return stars_earned() - stars_spent()


static func upgrade_tier(key: String) -> int:
	return int(upgrades.get(key, 0))


## Buys the next tier of an upgrade if there are enough stars. Returns true if bought.
static func buy_upgrade(key: String) -> bool:
	var tier: int = upgrade_tier(key)
	if tier >= UpgradeData.MAX_TIER or stars_available() < UpgradeData.cost_of_next(key):
		return false
	upgrades[key] = tier + 1
	save()
	return true


static func save() -> void:
	if not persist:
		return
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("progress", "highest_unlocked", highest_unlocked)
	for lvl: int in stars:
		cfg.set_value("stars", str(lvl), int(stars[lvl]))
	for key: String in upgrades:
		cfg.set_value("upgrades", key, int(upgrades[key]))
	cfg.set_value("story", "seen", PackedStringArray(seen_cards.keys()))
	cfg.set_value("story", "endings", PackedStringArray(endings.keys()))
	cfg.save(SAVE_PATH)


static func mark_seen(id: String) -> void:
	if not story_replay:
		seen_cards[id] = true
		save()


static func has_seen(id: String) -> bool:
	return seen_cards.has(id)


static func endless_unlocked() -> bool:
	return not endings.is_empty()


## Tests only: pretend every card was already seen so scripted runs are not interrupted by story scenes (nothing is saved).
static func mark_all_seen_for_test() -> void:
	for id: String in StoryData.CARDS:
		seen_cards[id] = true
