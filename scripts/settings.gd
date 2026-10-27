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
static var language: String = "en"  # "en" or "zh"
static var sound_on: bool = true
static var touch: int = 0  # touch controls: 0 automatic (phones), 1 always on, 2 off

static var revision: int = 0
static var _loaded: bool = false
static var _lang_forced: bool = false


static func init() -> void:
	if not _loaded:
		_loaded = true
		for a: String in OS.get_cmdline_user_args():  # tests: "--lang=zh" starts in Chinese without touching the saved settings
			if a.begins_with("--lang="):
				language = a.get_slice("=", 1)
				_lang_forced = true
		if OS.has_feature("web"):  # "?lang=zh" in the address opens the game in Chinese
			var q: String = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('lang') || ''", true))
			if q == "zh" or q == "en":
				language = q
				_lang_forced = true
		var cfg: ConfigFile = ConfigFile.new()
		if cfg.load(PATH) == OK:
			master = float(cfg.get_value("audio", "master", master))
			music = float(cfg.get_value("audio", "music", music))
			sfx = float(cfg.get_value("audio", "sfx", sfx))
			quality = clampi(int(cfg.get_value("graphics", "quality", quality)), 0, 2)
			fullscreen = bool(cfg.get_value("graphics", "fullscreen", fullscreen))
			mouse_sens = clampf(float(cfg.get_value("controls", "mouse_sens", mouse_sens)), 0.3, 3.0)
			touch = clampi(int(cfg.get_value("controls", "touch", touch)), 0, 2)
			if not _lang_forced:
				language = String(cfg.get_value("general", "language", language))
			sound_on = bool(cfg.get_value("audio", "sound_on", sound_on))
	apply()


static func save() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("audio", "master", master)
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("graphics", "quality", quality)
	cfg.set_value("graphics", "fullscreen", fullscreen)
	cfg.set_value("controls", "mouse_sens", mouse_sens)
	cfg.set_value("controls", "touch", touch)
	if not _lang_forced:  # a test run that forces a language must not overwrite the saved choice
		cfg.set_value("general", "language", language)
	cfg.set_value("audio", "sound_on", sound_on)
	cfg.save(PATH)


## Pushes the current values to the engine (audio buses, window mode, cached materials).
static func apply() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_set_bus("Master", master if sound_on else 0.0)
	_install_cjk_font()
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


static var _cjk_added: bool = false


## Adds the bundled Chinese font as a fallback to the default font, so Chinese text shows on every platform (browsers have no system fonts).
static func _install_cjk_font() -> void:
	if _cjk_added:
		return
	var f: FontFile = load("res://ui/fonts/cjk_subset.ttf") as FontFile
	if f == null:
		return
	_cjk_added = true
	var base: Font = ThemeDB.fallback_font
	var fb: Array[Font] = base.fallbacks.duplicate()
	fb.append(f)
	base.fallbacks = fb
