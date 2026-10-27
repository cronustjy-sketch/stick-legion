class_name HeroData
extends RefCounted
## Hero tuning. Balance changes happen here, never in gameplay code.

const STATS: Dictionary = {
	"max_hp": 150.0,
	"lives": 3,
	"respawn_time": 10.0,
	"walk_speed": 4.5,
	"sprint_speed": 8.0,
	"block_speed": 2.0,
	"turn_speed": 14.0,
	"roll_speed": 11.0,
	"roll_time": 0.6,
	"roll_iframes": 0.42,  # invincible for this long from the start of the roll
	"roll_cooldown": 0.45,
	"attack_range": 2.7,
	"attack_arc_deg": 120.0,
	"attack_speed": 1.6,  # animation speed multiplier (higher = faster swings)
	"combo_reset": 0.55,  # seconds after a swing before the combo starts over
	"block_reduction": 0.75,
	"block_arc_deg": 140.0,
	"hurt_stun": 0.25,
}

## Per swing of the 3-hit combo: animation, damage, strike time (s into the animation), animation length,
## and forward lunge speed.
const COMBO: Array[Dictionary] = [
	{"anim": "attack", "damage": 14.0, "strike": 0.34, "length": 0.8, "lunge": 2.5},
	{"anim": "attack2", "damage": 16.0, "strike": 0.36, "length": 0.7, "lunge": 2.5},
	{"anim": "attack3", "damage": 32.0, "strike": 0.52, "length": 1.0, "lunge": 4.0},
]

const CAMERA: Dictionary = {
	"distance": 6.6,
	"min_distance": 2.4,
	"max_distance": 10.0,
	"shoulder": 0.75,  # sideways offset (over-the-shoulder)
	"height": 1.75,
	"start_pitch": 0.28,
	"mouse_sensitivity": 0.0028,
	"zoom_step": 0.6,
}

## Rage fills when the hero deals or takes damage; the ultimate (G) needs a full meter.
const RAGE: Dictionary = {"max": 100.0, "per_damage_dealt": 0.22, "per_damage_taken": 0.3}

## Hero skills. "hits" are times (s) into the animation when the effect lands.
## damage / radius / knockback: area around the hero (shifted `forward` metres ahead).
## dash: hero charges forward at that speed until `dash_time` (invincible until `invincible`).
## heal_self / heal_allies / heal_radius, buff (army damage multiplier) + buff_time.
const SKILLS: Dictionary = {
	"q": {"name": "Whirlwind", "action": "skill_q", "cooldown": 6.0, "anim": "spin", "length": 0.8, "hits": [0.2, 0.4, 0.6],
		"damage": 16.0, "radius": 3.6, "knockback": 1.2, "shake": 0.05},
	"e": {"name": "Shield Dash", "action": "skill_e", "cooldown": 8.0, "anim": "dash", "length": 0.55, "hits": [0.3],
		"damage": 28.0, "radius": 2.6, "knockback": 4.5, "forward": 1.2, "dash": 16.0, "dash_time": 0.3, "invincible": 0.4, "shake": 0.12},
	"r": {"name": "War Cry", "action": "skill_r", "cooldown": 20.0, "anim": "cry", "length": 1.0, "hits": [0.35],
		"heal_self": 30.0, "heal_allies": 35.0, "heal_radius": 16.0, "buff": 1.35, "buff_time": 8.0, "shake": 0.06, "ring": 16.0},
	"f": {"name": "Ground Slam", "action": "skill_f", "cooldown": 12.0, "anim": "slam", "length": 0.95, "hits": [0.5],
		"damage": 50.0, "radius": 5.0, "knockback": 4.5, "forward": 1.6, "shake": 0.3},
	"g": {"name": "Legion Wrath", "action": "skill_g", "cooldown": 0.0, "anim": "ultimate", "length": 1.5, "hits": [0.85],
		"damage": 140.0, "radius": 10.0, "knockback": 7.0, "heal_allies": 40.0, "heal_radius": 18.0, "buff": 1.4, "buff_time": 10.0,
		"shake": 0.55, "ring": 10.0, "ultimate": true},
}
