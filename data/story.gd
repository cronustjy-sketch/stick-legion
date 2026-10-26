class_name StoryData
extends RefCounted
## Every story card, in the words of STORY.md. A card is a short posed 3D scene with a slow camera pan and 1-3 lines of text.
##
## id / group / name   - for the Story menu
## set                 - backdrop preset (scripts/story_sets.gd)
## actors              - [unit look key, team (0 gold / 1 red), x, z, facing in degrees (0 = away from the camera, 180 = toward it), animation]
## props               - extra scenery [type, x, z, rotation, scale, variant]
## cam                 - [camera start, camera end, look-at point]
## lines               - [speaker, text]  (speaker "" = narrator)
## choice              - true: the final choice card (Spare him / End it)
## title / subtitle    - a title card instead of a scene

const GROUPS: Array[String] = ["Prologue", "Chapter 1: The Green Valleys", "Chapter 2: The Iron Pass", "Chapter 3: The Burning Fields", "Chapter 4: The Crimson Throne", "Endings"]

const CARDS: Dictionary = {
	"prologue_1": {"group": 0, "name": "Aurum has fallen", "set": "burning_city",
		"actors": [["swordsman", 1, -3.0, -7.0, 150, "idle"], ["swordsman", 1, 1.0, -9.0, 160, "idle"], ["spearman", 1, 4.0, -7.5, 170, "idle"]],
		"props": [["banner", -1.5, -2.5, 25, 1.0, "gold_torn"], ["banner", 2.5, -3.5, -40, 1.0, "gold_torn"]],
		"cam": [[-7.0, 2.2, 9.0], [5.0, 2.8, 8.0], [0.0, 2.6, -5.0]],
		"lines": [["", "Aurum has fallen. The Crimson Host came from the east, and no wall could stop them."]]},
	"prologue_2": {"group": 0, "name": "One banner still stands", "set": "ashes",
		"actors": [["hero", 0, 0.0, 0.0, 180, "idle"]],
		"props": [["banner", 0.9, 0.2, 8, 1.1, "gold_torn"]],
		"cam": [[0.0, 1.5, 6.5], [0.6, 1.6, 4.4], [0.0, 1.35, 0.0]],
		"lines": [["", "One captain survived. One banner still stands."]]},
	"prologue_3": {"group": 0, "name": "Mira and the survivors", "set": "ashes",
		"actors": [["hero", 0, 0.0, 0.0, 200, "idle"], ["mira", 0, -1.6, 0.6, 150, "idle"], ["swordsman", 0, -3.0, -0.4, 140, "idle"],
			["spearman", 0, 2.6, 0.3, 215, "idle"], ["archer", 0, 1.4, 1.5, 200, "idle"]],
		"props": [],
		"cam": [[-3.5, 1.7, 7.0], [2.0, 1.6, 6.0], [0.0, 1.2, 0.0]],
		"lines": [["Mira", "Captain, we're all that's left. Tell us where to march."]]},
	"prologue_4": {"group": 0, "name": "We take it back", "set": "dawn",
		"actors": [["hero", 0, 0.0, 0.0, 180, "cry"], ["mira", 0, -1.8, 0.6, 165, "idle"], ["swordsman", 0, -3.2, -0.3, 160, "idle"],
			["spearman", 0, 2.4, 0.4, 200, "idle"], ["archer", 0, 3.8, -0.5, 205, "idle"]],
		"props": [["banner", 0.0, -0.9, 0, 1.5, "gold"]],
		"cam": [[0.0, 0.6, 7.5], [0.0, 1.7, 5.2], [0.0, 1.9, 0.0]],
		"lines": [["Aldric", "We take it back. One valley at a time."]]},

	"ch1_intro": {"group": 1, "name": "A border village", "set": "village",
		"actors": [["swordsman", 1, -2.0, -3.0, 170, "idle"], ["spearman", 1, 2.5, -4.0, 190, "idle"]],
		"props": [],
		"cam": [[-6.0, 2.4, 9.0], [5.0, 2.6, 8.0], [0.0, 1.8, -4.0]],
		"lines": [["", "Every village we free joins the legion."]]},
	"ch1_after_boss": {"group": 1, "name": "Grask's banner burns", "set": "camp",
		"actors": [["hero", 0, 0.8, 0.0, 215, "idle"], ["mira", 0, -1.0, 0.4, 150, "idle"]],
		"props": [["banner", -0.2, -2.6, 10, 1.3, "red_burning"], ["fire", -0.2, -2.6, 0, 1.0, ""]],
		"cam": [[2.0, 1.7, 6.5], [-0.8, 1.8, 5.0], [0.0, 1.3, -1.0]],
		"lines": [["Mira", "He said 'the King'. The Host has a king?"]]},

	"ch2_intro": {"group": 2, "name": "The Iron Pass", "set": "pass",
		"actors": [["swordsman", 1, -3.0, -6.0, 180, "idle"], ["shield_knight", 1, 0.5, -6.5, 180, "idle"], ["swordsman", 1, 3.5, -6.0, 180, "idle"]],
		"props": [],
		"cam": [[-5.0, 3.0, 11.0], [4.0, 3.6, 9.0], [0.0, 3.5, -6.0]],
		"lines": [["", "To reach the heart of Aurum, we must break the Iron Pass."]]},
	"ch2_after_boss": {"group": 2, "name": "The general's medal", "set": "wreck",
		"actors": [["hero", 0, 0.0, 0.0, 200, "offer"]],
		"props": [["wreck", 0.0, -3.0, 0, 1.0, ""]],
		"cam": [[1.5, 1.6, 4.6], [0.4, 1.7, 3.0], [0.0, 1.35, 0.0]],
		"lines": [["Aldric", "This belonged to an Aurum general... Only one general ever wore this."]]},

	"ch3_intro": {"group": 3, "name": "The wheat is burning", "set": "fields_fire",
		"actors": [["swordsman", 1, -2.5, -5.0, 170, "idle"], ["swordsman", 1, 1.5, -6.0, 190, "idle"]],
		"props": [],
		"cam": [[-5.0, 2.0, 9.0], [5.0, 2.4, 8.0], [0.0, 1.5, -3.0]],
		"lines": [["", "The Host burns everything it cannot hold."]]},
	"ch3_reveal_1": {"group": 3, "name": "Two brothers", "set": "flashback",
		"actors": [["young_aldric", 0, -1.2, 0.0, 90, "attack"], ["young_corvin", 0, 1.2, 0.0, 270, "block"]],
		"props": [],
		"cam": [[0.0, 1.5, 6.5], [1.2, 1.5, 5.2], [0.0, 1.1, 0.0]],
		"lines": [["Aldric", "Corvin. My brother. Aurum's greatest general."]]},
	"ch3_reveal_2": {"group": 3, "name": "The king's fear", "set": "throne_hall_warm",
		"actors": [["edmar", 0, 0.0, -2.3, 180, "sit", 0.55], ["young_corvin", 0, 0.3, 1.4, 0, "kneel"]],
		"props": [["throne", 0.0, -2.4, 180, 1.0, ""]],
		"cam": [[-3.0, 1.8, 6.5], [2.5, 1.9, 6.0], [0.0, 1.0, -0.5]],
		"lines": [["", "When the eastern war was won, the King feared him. He called him a traitor and sent him to die in the mountains."]]},
	"ch3_reveal_3": {"group": 3, "name": "Left in the snow", "set": "snow",
		"actors": [["young_corvin", 0, 0.0, 0.0, 180, "kneel"]],
		"props": [["banner", 1.4, -0.4, 70, 0.8, "red_torn"]],
		"cam": [[0.0, 1.3, 6.0], [0.0, 1.4, 4.0], [0.0, 0.8, 0.0]],
		"lines": [["", "He didn't die. He came back with an army."]]},
	"ch3_reveal_4": {"group": 3, "name": "The Crimson King is Corvin", "set": "ashes_dusk",
		"actors": [["hero", 0, 0.0, 0.0, 190, "offer"]],
		"props": [],
		"cam": [[0.0, 1.6, 5.5], [0.4, 1.7, 3.6], [0.0, 1.4, 0.0]],
		"lines": [["Aldric", "The Crimson King... is Corvin."]]},

	"ch4_intro": {"group": 4, "name": "Home", "set": "ruined_capital",
		"actors": [["swordsman", 1, -3.0, -4.0, 180, "idle"], ["shield_knight", 1, 2.0, -5.0, 180, "idle"]],
		"props": [["throne", 0.0, -11.0, 180, 1.6, ""]],
		"cam": [[-4.0, 2.2, 10.0], [4.0, 3.0, 8.0], [0.0, 2.4, -6.0]],
		"lines": [["", "The road ends where it began. At home."]]},
	"mira_18": {"group": 4, "name": "The legion follows you", "set": "camp_night",
		"actors": [["mira", 0, -0.9, 0.0, 200, "idle"], ["hero", 0, 1.0, 0.2, 160, "idle"]],
		"props": [["fire", 0.0, -1.2, 0, 0.8, ""]],
		"cam": [[-2.0, 1.5, 5.5], [1.0, 1.6, 4.4], [0.0, 1.3, 0.0]],
		"lines": [["Mira", "Whatever he was to you, Captain, the legion follows you. Not him."]]},
	"final_choice": {"group": 4, "name": "The final choice", "set": "throne_hall",
		"actors": [["corvin", 1, -0.4, 0.0, 180, "kneel"], ["hero", 0, 1.9, 0.6, 130, "idle"]],
		"props": [["throne", 0.0, -3.0, 180, 1.2, ""]],
		"cam": [[0.0, 1.9, 7.0], [0.0, 1.7, 5.0], [0.3, 1.2, 0.0]],
		"lines": [], "choice": true},

	"spare_1": {"group": 5, "name": "Spare him: a hand offered", "set": "throne_hall",
		"actors": [["corvin", 1, -0.4, 0.0, 180, "kneel"], ["hero", 0, 1.6, 0.6, 150, "offer"]],
		"props": [["throne", 0.0, -3.0, 180, 1.2, ""]],
		"cam": [[2.0, 1.6, 6.0], [0.6, 1.7, 4.2], [0.6, 1.3, 0.0]],
		"lines": [["Aldric", "Aurum wronged you. Help me build a better one."]]},
	"spare_2": {"group": 5, "name": "Spare him: one legion", "set": "rebuilt",
		"actors": [["hero", 0, -1.4, 0.0, 190, "idle"], ["corvin", 1, 1.4, 0.0, 170, "idle"]],
		"props": [["banner", -3.5, -1.5, 0, 1.6, "gold"], ["banner", 3.5, -1.5, 0, 1.6, "red"]],
		"cam": [[0.0, 1.8, 8.5], [0.0, 2.4, 6.5], [0.0, 2.3, 0.0]],
		"lines": [["", "The two armies became one legion. The brothers rebuilt Aurum together."]]},
	"spare_3": {"group": 5, "name": "Ending: Brothers", "set": "rebuilt", "title": "THE END", "subtitle": "Ending: Brothers",
		"actors": [], "props": [], "cam": [[0.0, 3.0, 10.0], [0.0, 3.4, 9.0], [0.0, 3.0, 0.0]], "lines": [], "ending": "brothers"},
	"end_1": {"group": 5, "name": "End it: the red banner falls", "set": "throne_hall",
		"actors": [["corvin", 1, -0.4, 0.0, 180, "kneel"], ["hero", 0, 1.7, 0.6, 130, "attack3"]],
		"props": [["banner", -2.8, -1.8, 10, 1.4, "red"], ["throne", 0.0, -3.0, 180, 1.2, ""]],
		"cam": [[0.0, 1.8, 6.5], [1.0, 1.9, 5.0], [0.4, 1.3, 0.0]],
		"lines": [["Corvin", "...You were always the loyal one."]]},
	"end_2": {"group": 5, "name": "End it: the captain alone", "set": "sunset_steps",
		"actors": [["hero", 0, 0.0, 0.0, 180, "idle"]],
		"props": [["banner", 1.0, -0.3, 0, 1.5, "gold"]],
		"cam": [[0.0, 0.7, 8.0], [0.0, 1.5, 6.0], [0.0, 1.8, 0.0]],
		"lines": [["", "Aurum was free. But its captain never smiled again."]]},
	"end_3": {"group": 5, "name": "Ending: The Crown", "set": "sunset_steps", "title": "THE END", "subtitle": "Ending: The Crown",
		"actors": [], "props": [], "cam": [[0.0, 3.0, 10.0], [0.0, 3.4, 9.0], [0.0, 3.0, 0.0]], "lines": [], "ending": "crown"},
	"credits": {"group": 5, "name": "Credits", "set": "dawn", "title": "A game by Junyuan", "subtitle": "Endless Mode unlocked on the campaign map",
		"actors": [], "props": [], "cam": [[0.0, 3.0, 10.0], [0.0, 3.4, 9.0], [0.0, 3.0, 0.0]], "lines": [], "credits": true, "hidden": true},
}

const PROLOGUE: Array[String] = ["prologue_1", "prologue_2", "prologue_3", "prologue_4"]
const SPARE_ENDING: Array[String] = ["spare_1", "spare_2", "spare_3", "credits"]
const END_ENDING: Array[String] = ["end_1", "end_2", "end_3", "credits"]

## Cards shown right after beating a boss level.
const AFTER_BOSS: Dictionary = {
	5: ["ch1_after_boss"],
	10: ["ch2_after_boss"],
	15: ["ch3_reveal_1", "ch3_reveal_2", "ch3_reveal_3", "ch3_reveal_4"],
	20: ["final_choice"],
}

## Cards shown before a level starts.
const BEFORE_LEVEL: Dictionary = {
	1: ["ch1_intro"], 6: ["ch2_intro"], 11: ["ch3_intro"], 16: ["ch4_intro"], 18: ["mira_18"],
}

## Short tips from Mira, shown at random on the campaign map.
const MIRA_TIPS: Array[String] = [
	"Spearmen eat giants for breakfast.",
	"Shield knights block arrows. Put them in front.",
	"Hold Tab to see the whole battle.",
	"Priests behind the front line keep everyone alive longer.",
	"Catapults are slow, but fortresses hate them.",
	"Use Follow and lead the charge yourself.",
]
