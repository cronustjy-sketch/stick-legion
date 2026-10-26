class_name Settings
extends RefCounted
## Player settings (volume, graphics quality, fullscreen, mouse sensitivity), saved to user://settings.cfg.
## Call Settings.init() once per scene start; it loads the file and applies everything.

const PATH: String = "user://settings.cfg"
const QUALITY_NAMES: Array[String] = ["Low", "Medium", "High"]

static var master: float = 0.8
static var music: float = 0.7
static var sfx: float = 0.8
static var quality: int = 2  # 0 low, 1 medium, 2 high
static var fullscreen: bool = false
static var mouse_sens: float = 1.0

static var revision: int = 0
static var _loaded: bool = false


static func init() -> void:
	if not _loaded:
		_loaded = true
		var cfg: ConfigFile = ConfigFile.new()
		if cfg.load(PATH) == OK:
			master = float(cfg.get_value("audio", "master", master))
			music = float(cfg.get_value("audio", "music", music))
			sfx = float(cfg.get_value("audio", "sfx", sfx))
			quality = clampi(int(cfg.get_value("graphics", "quality", quality)), 0, 2)
			fullscreen = bool(cfg.get_value("graphics", "fullscreen", fullscreen))
			mouse_sens = clampf(float(cfg.get_value("controls", "mouse_sens", mouse_sens)), 0.3, 3.0)
	apply()


static func save() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("audio", "master", master)
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("graphics", "quality", quality)
	cfg.set_value("graphics", "fullscreen", fullscreen)
	cfg.set_value("controls", "mouse_sens", mouse_sens)
	cfg.save(PATH)


## Pushes the current values to the engine (audio buses, window mode, cached materials).
static func apply() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_set_bus("Master", master)
	_set_bus("Music", music)
	_set_bus("SFX", sfx)
	if not OS.has_feature("web") and DisplayServer.get_name() != "headless":
		var wanted: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != wanted:
			DisplayServer.window_set_mode(wanted)
	revision += 1  # lets cached visuals (unit outlines) notice that the quality level changed


# Quality-dependent knobs used by the game.

static func prop_density() -> float:
	return [0.35, 0.7, 1.0][quality]


static func max_sparks() -> int:
	return [0, 12, 22][quality]


static func outlines() -> bool:
	return quality >= 1


static func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")


static func _set_bus(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
