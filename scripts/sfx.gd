class_name Sfx
extends RefCounted
## Sound helper used by the game scripts:  Sfx.play("hit", -4.0, unit.global_position)   Sfx.music("music_battle")
## Talks to the AudioHub autoload (scripts/audio_hub.gd). Does nothing when the hub is missing (tools, headless scripts).

static func _hub() -> Node:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	if loop == null:
		return null
	return loop.root.get_node_or_null("AudioHub")


static func play(stream_name: String, volume_db: float = 0.0, at: Vector3 = Vector3.INF, pitch: float = 1.0) -> void:
	var h: Node = _hub()
	if h != null:
		h.call("play", stream_name, volume_db, at, pitch)


static func music(track: String, fade: float = 1.2) -> void:
	var h: Node = _hub()
	if h != null:
		h.call("music", track, fade)


static func set_listener(pos: Vector3) -> void:
	var h: Node = _hub()
	if h != null:
		h.set("listener", pos)
