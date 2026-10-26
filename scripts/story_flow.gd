class_name StoryFlow
extends RefCounted
## Decides which story cards play when, and switches to the story scene. Cards already seen are not shown again
## (they can be replayed from the Story menu).

const STORY_SCENE: String = "res://scenes/story.tscn"
const BATTLE_SCENE: String = "res://scenes/battle.tscn"
const MAP_SCENE: String = "res://scenes/level_select.tscn"
const MENU_SCENE: String = "res://scenes/main_menu.tscn"


static func unseen(ids: Array) -> Array[String]:
	var out: Array[String] = []
	for id: String in ids:
		if not GameState.has_seen(id):
			out.append(id)
	return out


## Plays `ids` and then loads `next_scene` (no cards left to show: loads it straight away).
static func play(tree: SceneTree, ids: Array[String], next_scene: String, replay: bool = false) -> void:
	if ids.is_empty():
		tree.change_scene_to_file(next_scene)
		return
	GameState.story_queue = ids.duplicate()
	GameState.story_next = next_scene
	GameState.story_replay = replay
	tree.change_scene_to_file(STORY_SCENE)


## Main menu "Play": the prologue the first time, then the campaign map.
static func on_play(tree: SceneTree) -> void:
	play(tree, unseen(StoryData.PROLOGUE), MAP_SCENE)


## Starts a battle, with the chapter intro (or Mira's pre-level line) first if it has not been seen.
static func start_level(tree: SceneTree, level: int) -> void:
	GameState.current_level = level
	var cards: Array = StoryData.BEFORE_LEVEL.get(level, [])
	play(tree, unseen(cards), BATTLE_SCENE)


## After a boss: the cards that follow it. Returns true if a story scene was started.
static func after_boss(tree: SceneTree, level: int) -> bool:
	var cards: Array[String] = unseen(StoryData.AFTER_BOSS.get(level, []))
	if cards.is_empty():
		return false
	play(tree, cards, MAP_SCENE if level < LevelData.LEVEL_COUNT else MENU_SCENE)
	return true


static func has_after_boss(level: int) -> bool:
	return not unseen(StoryData.AFTER_BOSS.get(level, [])).is_empty()
