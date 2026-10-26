class_name UnitData
extends RefCounted
## Unit stats and visual loadouts. Balance changes happen here, never in gameplay code.
##
## Optional special keys in STATS (all read by scripts/unit.gd and scripts/projectile.gd):
##   ranged: "arrow" | "fireball" | "boulder"   projectile_speed, splash (radius, m), kite (back away from close enemies)
##   bonus_vs_big (damage multiplier vs big units), armor (damage reduction), blocks_arrows (frontal shield),
##   crit / crit_mult, heal (HP restored per cast), aoe + knockback (ground smash), charge_mult (first hit after a run-up),
##   fortress_mult (damage multiplier against fortresses), big (counts as a big unit), radius (body size, m)

const STATS: Dictionary = {
	"swordsman": {"name": "Swordsman", "hp": 60.0, "dmg": 10.0, "range": 1.2, "speed": 3.0, "cooldown": 0.9, "cost": 20, "pop": 1},
	"archer": {"name": "Archer", "hp": 36.0, "dmg": 9.0, "range": 18.0, "speed": 2.6, "cooldown": 1.35, "cost": 30, "pop": 1,
		"ranged": "arrow", "projectile_speed": 26.0, "kite": true},
	"spearman": {"name": "Spearman", "hp": 75.0, "dmg": 12.0, "range": 2.2, "speed": 2.8, "cooldown": 1.1, "cost": 35, "pop": 1,
		"bonus_vs_big": 2.0},
	"shield_knight": {"name": "Shield Knight", "hp": 240.0, "dmg": 15.0, "range": 1.3, "speed": 2.2, "cooldown": 1.0, "cost": 45, "pop": 1,
		"armor": 0.35, "blocks_arrows": true},
	"mage": {"name": "Mage", "hp": 42.0, "dmg": 15.0, "range": 14.0, "speed": 2.2, "cooldown": 2.0, "cost": 60, "pop": 1,
		"ranged": "fireball", "projectile_speed": 15.0, "splash": 2.5, "kite": true},
	"assassin": {"name": "Assassin", "hp": 48.0, "dmg": 20.0, "range": 1.0, "speed": 5.5, "cooldown": 0.6, "cost": 50, "pop": 1,
		"crit": 0.3, "crit_mult": 2.0},
	"priest": {"name": "Priest", "hp": 55.0, "dmg": 0.0, "range": 10.0, "speed": 2.5, "cooldown": 1.4, "cost": 55, "pop": 1,
		"heal": 16.0},
	"giant": {"name": "Giant", "hp": 620.0, "dmg": 38.0, "range": 2.8, "speed": 1.4, "cooldown": 2.2, "cost": 150, "pop": 3,
		"big": true, "aoe": 3.2, "knockback": 3.5, "radius": 1.1},
	"cavalry": {"name": "Cavalry", "hp": 170.0, "dmg": 20.0, "range": 1.6, "speed": 7.0, "cooldown": 1.0, "cost": 90, "pop": 2,
		"big": true, "charge_mult": 2.0, "radius": 0.8},
	"catapult": {"name": "Catapult", "hp": 220.0, "dmg": 50.0, "range": 35.0, "speed": 1.2, "cooldown": 4.2, "cost": 140, "pop": 3,
		"big": true, "ranged": "boulder", "projectile_speed": 17.0, "splash": 3.0, "fortress_mult": 2.0, "radius": 1.2},
	"boss_gorath": {"name": "Gorath the Warlord", "hp": 2400.0, "dmg": 36.0, "range": 4.6, "speed": 1.7, "cooldown": 2.6, "cost": 0, "pop": 0,
		"big": true, "aoe": 4.2, "knockback": 4.0, "radius": 2.0},
	"boss_vexra": {"name": "Vexra the Axe Queen", "hp": 3600.0, "dmg": 46.0, "range": 4.4, "speed": 1.9, "cooldown": 2.4, "cost": 0, "pop": 0,
		"big": true, "aoe": 4.4, "knockback": 4.5, "radius": 1.9},
	"boss_mordrek": {"name": "Mordrek the Siege Lord", "hp": 5200.0, "dmg": 58.0, "range": 5.0, "speed": 1.8, "cooldown": 2.4, "cost": 0, "pop": 0,
		"big": true, "aoe": 4.8, "knockback": 5.0, "radius": 2.3},
	"boss_emperor": {"name": "The Iron Emperor", "hp": 7600.0, "dmg": 70.0, "range": 5.4, "speed": 2.0, "cooldown": 2.2, "cost": 0, "pop": 0,
		"big": true, "aoe": 5.2, "knockback": 5.5, "radius": 2.5},
}

## Rigged stickman units (the showcase and the old tests use this list).
const HUMANOID_ORDER: Array[String] = [
	"swordsman", "archer", "spearman", "shield_knight", "mage", "assassin", "priest",
]

## Every unit, in spawn-button order.
const ALL_ORDER: Array[String] = [
	"swordsman", "archer", "spearman", "shield_knight", "mage", "assassin", "priest", "giant", "cavalry", "catapult",
]

## Gear per unit. Pieces are low-poly meshes baked into one skinned mesh (see scripts/stickman.gd).
##   helmet:  cap | kettle | plume | greathelm | wizard | hood | circlet
##   chest:   plate | leather | robe
##   main/off: sword | dagger | spear | staff | axe | hammer | shield | tower_shield | bow
##   style:   swing | thrust | shoot | cast | ride   (which animation set to use)
##   attack_anim / timing / bar_height: optional overrides (see scripts/unit.gd)
## "catapult" has no stickman gear: it is a machine (scripts/catapult_model.gd).
const LOOKS: Dictionary = {
	"swordsman": {"helmet": "kettle", "shoulders": true, "chest": "plate", "cape": false, "belt": true,
		"main": "sword", "off": "", "style": "swing", "scale": 1.0},
	"archer": {"helmet": "hood", "shoulders": false, "chest": "leather", "cape": true, "belt": true,
		"main": "", "off": "bow", "style": "shoot", "scale": 1.0},
	"spearman": {"helmet": "plume", "shoulders": true, "chest": "leather", "cape": false, "belt": true,
		"main": "spear", "off": "", "style": "thrust", "scale": 1.0},
	"shield_knight": {"helmet": "greathelm", "shoulders": true, "chest": "plate", "cape": true, "belt": true,
		"main": "sword", "off": "tower_shield", "style": "swing", "scale": 1.1},
	"mage": {"helmet": "wizard", "shoulders": false, "chest": "robe", "cape": false, "belt": true,
		"main": "staff", "off": "", "style": "cast", "scale": 1.0},
	"assassin": {"helmet": "hood", "shoulders": false, "chest": "leather", "cape": true, "belt": true,
		"main": "dagger", "off": "dagger", "style": "swing", "scale": 0.97},
	"hero": {"helmet": "plume", "shoulders": true, "chest": "plate", "cape": true, "belt": true,
		"main": "sword", "off": "shield", "style": "swing", "scale": 1.12},
	"priest": {"helmet": "circlet", "shoulders": false, "chest": "robe", "cape": true, "belt": true,
		"main": "staff", "off": "", "style": "cast", "scale": 1.0, "white_robe": true},
	"giant": {"helmet": "greathelm", "shoulders": true, "chest": "plate", "cape": true, "belt": true,
		"main": "hammer", "off": "", "style": "swing", "scale": 2.1, "attack_anim": "attack3", "timing": "attack3", "bar_height": 5.7},
	"cavalry": {"helmet": "plume", "shoulders": true, "chest": "plate", "cape": true, "belt": true,
		"main": "spear", "off": "", "style": "ride", "scale": 1.0, "bar_height": 3.5},
	"catapult": {"style": "shoot", "scale": 1.0, "timing": "catapult", "bar_height": 3.3},
	"boss_gorath": {"helmet": "greathelm", "shoulders": true, "chest": "plate", "cape": true, "belt": true, "main": "hammer", "off": "",
		"style": "swing", "scale": 3.2, "attack_anim": "attack3", "timing": "attack3", "bar_height": 8.6},
	"boss_vexra": {"helmet": "plume", "shoulders": true, "chest": "plate", "cape": true, "belt": true, "main": "axe", "off": "",
		"style": "swing", "scale": 3.1, "attack_anim": "attack3", "timing": "attack3", "bar_height": 8.3},
	"boss_mordrek": {"helmet": "greathelm", "shoulders": true, "chest": "plate", "cape": true, "belt": true, "main": "sword", "off": "tower_shield",
		"style": "swing", "scale": 3.4, "attack_anim": "attack3", "timing": "attack3", "bar_height": 9.0},
	"boss_emperor": {"helmet": "wizard", "shoulders": true, "chest": "plate", "cape": true, "belt": true, "main": "hammer", "off": "",
		"style": "swing", "scale": 3.7, "attack_anim": "attack3", "timing": "attack3", "bar_height": 10.0},
}

## Animation timing used by the unit AI: when in the attack animation the hit lands, and how long it is.
const ATTACK_TIMING: Dictionary = {
	"swing": {"strike": 0.34, "length": 0.8},
	"thrust": {"strike": 0.45, "length": 0.9},
	"shoot": {"strike": 0.85, "length": 1.4},
	"cast": {"strike": 0.6, "length": 1.2},
	"ride": {"strike": 0.42, "length": 0.9},
	"attack3": {"strike": 0.52, "length": 1.0},
	"catapult": {"strike": 0.5, "length": 1.1},
}

## Enemy strength at a campaign level (level 1 = 1.0).
static func level_multiplier(level: int) -> float:
	return 1.0 + 0.11 * float(level - 1)

