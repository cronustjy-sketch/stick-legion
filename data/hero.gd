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
	"attack_speed": 1.25,  # animation speed multiplier
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
	"distance": 4.8,
	"min_distance": 2.4,
	"max_distance": 10.0,
	"shoulder": 0.75,  # sideways offset (over-the-shoulder)
	"height": 1.75,
	"start_pitch": 0.28,
	"mouse_sensitivity": 0.0028,
	"zoom_step": 0.6,
}
