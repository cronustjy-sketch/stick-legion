class_name BattleAutotest
extends Node
## Scripted army fight for step 4 (debug only):  godot --path . -- --battle-test
## Spawns two armies of swordsmen, watches them clash from above, saves screenshots, prints BATTLE-TEST results.

const WAVE: int = 10
const TIME_SCALE: float = 3.0

var battle: Battle
var _deaths: Array[int] = [0, 0]
var _cam: Camera3D


func _ready() -> void:
	_run()


func _game_wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "step4_" + shot_name)


func _alive(team: int) -> int:
	return get_tree().get_nodes_in_group("units_team%d" % team).size()


func _on_died(u: Unit) -> void:
	_deaths[u.team] += 1


func _spawn(team: int) -> void:
	for i: int in WAVE:
		var u: Unit = battle.spawn_unit("swordsman", team, 8.0)
		u.died.connect(_on_died)


func _run() -> void:
	Engine.time_scale = TIME_SCALE
	_cam = Camera3D.new()
	_cam.fov = 50.0
	add_child(_cam)
	_cam.current = true
	_cam.position = Vector3(13.0, 7.5, 10.0)
	_cam.look_at(Vector3(0.0, 0.8, 0.5))
	await _game_wait(0.5)
	_spawn(0)
	_spawn(1)
	await _game_wait(0.5)
	await _shot("spawned")
	print("BATTLE-TEST alive at start: player=", _alive(0), " enemy=", _alive(1))
	await _game_wait(13.0)
	await _shot("approach")
	await _game_wait(6.0)
	await _shot("clash")
	await _game_wait(5.0)
	await _shot("fighting")
	print("BATTLE-TEST after clash: alive player=", _alive(0), " enemy=", _alive(1), " deaths player=", _deaths[0], " enemy=", _deaths[1])
	await _game_wait(90.0)
	await _shot("aftermath")
	print("BATTLE-TEST end: alive player=", _alive(0), " enemy=", _alive(1), " deaths player=", _deaths[0], " enemy=", _deaths[1])
	print("BATTLE-TEST fortress hp: player=", battle.player_fortress.hp, " enemy=", battle.enemy_fortress.hp)
	print("BATTLE-TEST fps: ", Engine.get_frames_per_second())
	Engine.time_scale = 1.0
	get_tree().quit()
