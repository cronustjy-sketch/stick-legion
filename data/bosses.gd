class_name BossData
extends RefCounted
## Boss fights (levels 5, 10, 15, 20) - see STORY.md for who they are and what they say.
## The boss units' stats and gear live in data/units.gd (keys boss_*); the attacks below are cast by scripts/boss.gd
## with red ground markers.
##
## keys:        the boss unit(s) spawned (the twins are two units)
## thresholds:  fractions of HP at which the next phase starts (twins: the survivor enrages when its partner falls)
## abilities:   list per phase. "slam" "sweep" "meteors" "summon" "charge" "spin" "dash" "flurry" "combo" "guards"
## cooldowns / speed_mult: per phase

const BOSSES: Dictionary = {
	5: {"id": "grask", "name": "Grask the Butcher", "keys": ["boss_grask"],
		"appear": "Little gold soldier. I've butchered better.",
		"defeated": "The King... will finish... what I started.",
		"thresholds": [0.5], "link": false,
		"abilities": [["charge", "spin"], ["charge", "spin", "slam", "summon"]],
		"cooldowns": [6.0, 3.8], "speed_mult": [1.0, 1.35],
		"slam_radius": 4.5, "spin_radius": 6.5, "charge_width": 4.0, "charge_length": 24.0,
		"summon": {"count": 3}},
	10: {"id": "volk", "name": "Siege Master Volk", "keys": ["boss_volk"],
		"appear": "Walls, armies, kings. I've crushed all three.",
		"defeated": "You fight like him. Like the King. Same eyes.",
		"thresholds": [0.5], "link": false,
		"abilities": [["meteors", "summon"], ["meteors", "summon", "slam"]],
		"cooldowns": [6.5, 4.0], "speed_mult": [1.0, 1.3],
		"slam_radius": 5.0, "meteors": 6, "summon": {"key": "catapult", "count": 2}},
	15: {"id": "twins", "name": "The Twin Blades", "keys": ["boss_sera", "boss_kade"],
		"appear": "The Crimson King sends his regards, little brother of his.",
		"defeated": "Ask your old king... what he did to Corvin.",
		"speaker": "Sera and Kade",
		"thresholds": [], "link": true,
		"abilities": [["dash", "flurry"], ["dash", "flurry", "flurry"]],
		"cooldowns": [3.2, 1.8], "speed_mult": [1.0, 1.4],
		"dash_width": 2.6, "dash_length": 13.0},
	20: {"id": "corvin", "name": "Corvin, the Crimson King", "keys": ["boss_corvin"],
		"appear": "Little brother. You picked up the banner I dropped.",
		"defeated": "",
		"thresholds": [0.66, 0.33], "link": false,
		"abilities": [["combo", "slam"], ["combo", "slam", "guards", "sweep"], ["combo", "slam", "sweep", "meteors"]],
		"cooldowns": [5.0, 4.0, 2.4], "speed_mult": [1.0, 1.1, 1.6],
		"phase_lines": {3: "Aurum threw me away! Why do you still bleed for it?"},
		"slam_radius": 5.5, "sweep_radius": 8.5, "meteors": 9, "guards": {"count": 6, "strength": 1.6},
		"red_sky_phase": 3},
}


static func for_level(level: int) -> Dictionary:
	return BOSSES.get(level, {})
