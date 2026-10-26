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
static var _loaded: bool = false


static func load_progress() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		highest_unlocked = int(cfg.get_value("progress", "highest_unlocked", 1))
		for id: String in PackedStringArray(cfg.get_value("story", "seen", PackedStringArray())):
			seen_cards[id] = true
		for e: String in PackedStringArray(cfg.get_value("story", "endings", PackedStringArray())):
			endings[e] = true


static func level_won(level: int) -> void:
	highest_unlocked = maxi(highest_unlocked, level + 1)
	save()


static func save() -> void:
	if not persist:
		return
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("progress", "highest_unlocked", highest_unlocked)
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
