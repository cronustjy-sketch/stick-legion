class_name BossData
extends RefCounted
## Boss fights (every 5th level). The boss is a huge warlord unit; its stats and gear live in data/units.gd
## (keys boss_*), the special attacks below are cast by scripts/boss.gd with red ground markers.
##
## abilities: "slam" (circle on the hero or army), "sweep" (ring around the boss), "meteors" (several circles),
## "summon" (calls reinforcements). Phase 2 starts at 50% HP: faster, shorter cooldowns, more abilities.

const BOSSES: Dictionary = {
	5: {"key": "boss_gorath", "name": "Gorath the Warlord", "phase1": ["slam", "sweep"], "phase2": ["slam", "sweep", "summon"],
		"cooldown": 6.5, "cooldown2": 4.0, "slam_radius": 4.5, "sweep_radius": 7.5, "meteors": 5, "summons": 3},
	10: {"key": "boss_vexra", "name": "Vexra the Axe Queen", "phase1": ["slam", "sweep", "meteors"], "phase2": ["slam", "meteors", "summon", "sweep"],
		"cooldown": 6.0, "cooldown2": 3.6, "slam_radius": 5.0, "sweep_radius": 8.0, "meteors": 6, "summons": 4},
	15: {"key": "boss_mordrek", "name": "Mordrek the Siege Lord", "phase1": ["slam", "meteors", "sweep"], "phase2": ["meteors", "slam", "summon", "sweep"],
		"cooldown": 5.5, "cooldown2": 3.3, "slam_radius": 5.5, "sweep_radius": 8.5, "meteors": 8, "summons": 5},
	20: {"key": "boss_emperor", "name": "The Iron Emperor", "phase1": ["slam", "meteors", "sweep", "summon"], "phase2": ["meteors", "slam", "summon", "sweep"],
		"cooldown": 5.0, "cooldown2": 2.9, "slam_radius": 6.0, "sweep_radius": 9.0, "meteors": 10, "summons": 6},
}


static func for_level(level: int) -> Dictionary:
	return BOSSES.get(level, {})
