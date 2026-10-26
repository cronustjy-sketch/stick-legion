class_name GameState
extends RefCounted
## Progress that survives scene reloads: the level being played and the highest level unlocked (saved to disk).

const SAVE_PATH: String = "user://stick_legion.cfg"

static var current_level: int = 1
static var highest_unlocked: int = 1
static var _loaded: bool = false


static func load_progress() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		highest_unlocked = int(cfg.get_value("progress", "highest_unlocked", 1))


static func level_won(level: int) -> void:
	highest_unlocked = maxi(highest_unlocked, level + 1)
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("progress", "highest_unlocked", highest_unlocked)
	cfg.save(SAVE_PATH)
