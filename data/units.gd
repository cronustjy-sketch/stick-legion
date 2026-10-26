class_name UnitData
extends RefCounted
## Unit stats and visual loadouts. Balance changes happen here, never in gameplay code.

const STATS: Dictionary = {
	"swordsman": {"name": "Swordsman", "hp": 60.0, "dmg": 10.0, "range": 1.2, "speed": 3.0, "cooldown": 0.9, "cost": 20, "pop": 1},
	"archer": {"name": "Archer", "hp": 36.0, "dmg": 9.0, "range": 18.0, "speed": 2.6, "cooldown": 1.35, "cost": 30, "pop": 1},
	"spearman": {"name": "Spearman", "hp": 75.0, "dmg": 12.0, "range": 2.2, "speed": 2.8, "cooldown": 1.1, "cost": 35, "pop": 1},
	"shield_knight": {"name": "Shield Knight", "hp": 240.0, "dmg": 15.0, "range": 1.3, "speed": 2.2, "cooldown": 1.0, "cost": 45, "pop": 1},
	"mage": {"name": "Mage", "hp": 42.0, "dmg": 15.0, "range": 14.0, "speed": 2.2, "cooldown": 2.0, "cost": 60, "pop": 1},
	"assassin": {"name": "Assassin", "hp": 48.0, "dmg": 20.0, "range": 1.0, "speed": 5.5, "cooldown": 0.6, "cost": 50, "pop": 1},
	"priest": {"name": "Priest", "hp": 55.0, "dmg": 0.0, "range": 10.0, "speed": 2.5, "cooldown": 1.4, "cost": 55, "pop": 1},
	"giant": {"name": "Giant", "hp": 620.0, "dmg": 38.0, "range": 2.8, "speed": 1.4, "cooldown": 2.2, "cost": 150, "pop": 3},
	"cavalry": {"name": "Cavalry", "hp": 170.0, "dmg": 20.0, "range": 1.6, "speed": 7.0, "cooldown": 1.0, "cost": 90, "pop": 2},
	"catapult": {"name": "Catapult", "hp": 220.0, "dmg": 50.0, "range": 35.0, "speed": 1.2, "cooldown": 4.2, "cost": 140, "pop": 3},
}

## Order used by the showcase and the spawn bar.
const HUMANOID_ORDER: Array[String] = [
	"swordsman", "archer", "spearman", "shield_knight", "mage", "assassin", "priest",
]

## Gear per humanoid unit. Pieces are low-poly meshes baked into one skinned mesh.
##   helmet:  cap | kettle | plume | greathelm | wizard | hood | circlet
##   chest:   plate | leather | robe
##   main/off: sword | dagger | spear | staff | axe | hammer | shield | tower_shield | bow
##   style:   swing | thrust | shoot | cast  (which attack animation to use)
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
	"priest": {"helmet": "circlet", "shoulders": false, "chest": "robe", "cape": true, "belt": true,
		"main": "staff", "off": "", "style": "cast", "scale": 1.0, "white_robe": true},
}
