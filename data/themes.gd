class_name ThemeData
extends RefCounted
## Look of each chapter (see STORY.md). Same battlefield layout, different colours, props, sky and particles.
## Keys:
##   ground_a / ground_b (grass or snow or wheat), patch + patch_amount (burnt or dirty patches), rock_side (steep slopes)
##   sky_top / sky_horizon / ground_horizon / ground_bottom, fog colour + density, ambient colour + energy,
##   sun colour + energy + pitch/yaw (degrees), cloud colour + emission, mountain colour, snow_caps
##   tree_style: pine | snow_pine | dead | none, tree_trunk / tree_low / tree_high colours, tree_count (multiplier), rock_color, rock_count (multiplier)
##   extras: "wheat" | "ruins" | "banners" (see scripts/theme_props.gd)
##   weather: "snow" | "embers" | "ash" | ""  (see scripts/weather.gd)

const CHAPTER_COUNT: int = 4

const THEMES: Array[Dictionary] = [
	{ # 1 - The Green Valleys
		"name": "Green Valleys",
		"ground_a": Color("6f9a45"), "ground_b": Color("86a94f"), "patch": Color("6f9a45"), "patch_amount": 0.0, "rock_side": Color("7c8a63"),
		"sky_top": Color("2c6cc4"), "sky_horizon": Color("9fd2f2"), "ground_horizon": Color("a8c4a4"), "ground_bottom": Color("6f8f70"),
		"fog": Color("b4d6ee"), "fog_density": 0.0006, "ambient": Color("c4d2e8"), "ambient_energy": 0.55,
		"sun": Color("fff3da"), "sun_energy": 1.0, "sun_pitch": -48.0, "sun_yaw": 35.0,
		"cloud": Color("ffffff"), "cloud_emission": Color("9fb4d0"), "cloud_count": 16,
		"mountain": Color("7d8fa8"), "snow_caps": false,
		"tree_style": "pine", "tree_trunk": Color("5e4630"), "tree_low": Color("3f7a3a"), "tree_high": Color("4b8b43"), "tree_count": 1.0,
		"rock_color": Color("8b8d8f"), "rock_count": 1.0,
		"extras": [], "weather": "",
	},
	{ # 2 - The Iron Pass: snowy mountains, pines, grey sky, falling snow
		"name": "Iron Pass",
		"ground_a": Color("e6eef4"), "ground_b": Color("cfdce8"), "patch": Color("aab6c2"), "patch_amount": 0.18, "rock_side": Color("7f8b98"),
		"sky_top": Color("5d6b7c"), "sky_horizon": Color("b9c3cd"), "ground_horizon": Color("c4ccd4"), "ground_bottom": Color("8e99a5"),
		"fog": Color("b4bec8"), "fog_density": 0.0045, "ambient": Color("b8c4d2"), "ambient_energy": 0.62,
		"sun": Color("dfe8f2"), "sun_energy": 0.8, "sun_pitch": -52.0, "sun_yaw": 35.0,
		"cloud": Color("c9d0d8"), "cloud_emission": Color("8e9aa8"), "cloud_count": 22,
		"mountain": Color("8c98a8"), "snow_caps": true,
		"tree_style": "snow_pine", "tree_trunk": Color("4a3a2e"), "tree_low": Color("2f5a3c"), "tree_high": Color("f2f6fa"), "tree_count": 1.15,
		"rock_color": Color("7b8590"), "rock_count": 1.0,
		"extras": [], "weather": "snow",
	},
	{ # 3 - The Burning Fields: golden wheat, orange sky, smoke and embers, burnt trees
		"name": "Burning Fields",
		"ground_a": Color("8c7743"), "ground_b": Color("9e8a4e"), "patch": Color("4a3826"), "patch_amount": 0.2, "rock_side": Color("7a5c3c"),
		"sky_top": Color("7a3a2a"), "sky_horizon": Color("f2a24e"), "ground_horizon": Color("c8803c"), "ground_bottom": Color("6a4a2c"),
		"fog": Color("d08a50"), "fog_density": 0.0018, "ambient": Color("d8c0a8"), "ambient_energy": 0.55,
		"sun": Color("ffc888"), "sun_energy": 0.9, "sun_pitch": -24.0, "sun_yaw": 35.0,
		"cloud": Color("6a5448"), "cloud_emission": Color("b06a3c"), "cloud_count": 20,
		"mountain": Color("8a5a48"), "snow_caps": false,
		"tree_style": "dead", "tree_trunk": Color("2a2320"), "tree_low": Color("2a2320"), "tree_high": Color("2a2320"), "tree_count": 0.8,
		"rock_color": Color("6e5e54"), "rock_count": 0.8,
		"extras": ["wheat"], "weather": "embers",
	},
	{ # 4 - The Ruined Capital: broken stone walls, red banners, dark red sky
		"name": "Ruined Capital",
		"ground_a": Color("5a504c"), "ground_b": Color("685c56"), "patch": Color("362d2b"), "patch_amount": 0.22, "rock_side": Color("4c3e3c"),
		"sky_top": Color("2a080e"), "sky_horizon": Color("a03428"), "ground_horizon": Color("7a2c24"), "ground_bottom": Color("3a1a18"),
		"fog": Color("7a3430"), "fog_density": 0.0026, "ambient": Color("a08c90"), "ambient_energy": 0.55,
		"sun": Color("ffc0a8"), "sun_energy": 0.8, "sun_pitch": -30.0, "sun_yaw": 35.0,
		"cloud": Color("4a1c1c"), "cloud_emission": Color("8a2a24"), "cloud_count": 20,
		"mountain": Color("5a2a2e"), "snow_caps": false,
		"tree_style": "dead", "tree_trunk": Color("2c2422"), "tree_low": Color("2c2422"), "tree_high": Color("2c2422"), "tree_count": 0.4,
		"rock_color": Color("6a5f5c"), "rock_count": 0.9,
		"extras": ["ruins", "banners"], "weather": "ash",
	},
]


## Chapter number (1..4) of a level. Endless battles cycle through the four looks.
static func chapter_for_level(level: int) -> int:
	if level > LevelData.LEVEL_COUNT:
		return (level - LevelData.LEVEL_COUNT - 1) % CHAPTER_COUNT + 1
	return LevelData.chapter_of(level)


static func for_level(level: int) -> Dictionary:
	return THEMES[chapter_for_level(level) - 1]
