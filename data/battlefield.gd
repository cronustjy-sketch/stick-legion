class_name BattlefieldData
extends RefCounted
## Tunable numbers for the battlefield and fortresses (no gameplay code here).

const VALLEY_LENGTH: float = 120.0
const VALLEY_HALF_WIDTH: float = 26.0
const TERRAIN_HALF_X: float = 70.0
const TERRAIN_HALF_Z: float = 80.0
const TERRAIN_CELL: float = 2.0

const FORTRESS_Z: float = 50.0  # distance of each fortress from the centre

const FORTRESS: Dictionary = {
	"max_hp": 3000.0,
	"width": 18.0,
	"depth": 9.0,
	"wall_height": 5.0,
	"tower_height": 9.0,
	"keep_height": 11.0,
}

const COLOR_GOLD: Color = Color("e8b44a")
const COLOR_RED: Color = Color("de4b3f")
const COLOR_STEEL: Color = Color("aab4c0")
const COLOR_IRON: Color = Color("3b3638")
const COLOR_STONE: Color = Color("8d8a84")
const COLOR_GRASS_A: Color = Color("6f9a45")
const COLOR_GRASS_B: Color = Color("86a94f")
const COLOR_DIRT: Color = Color("8a7650")
const COLOR_ROCK_SIDE: Color = Color("7c8a63")
const COLOR_MOUNTAIN: Color = Color("7d8fa8")

const TREE_COUNT: int = 46
const ROCK_COUNT: int = 26
const SCENE_SEED: int = 1337
