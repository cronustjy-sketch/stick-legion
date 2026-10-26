extends Node
## Autoload "AudioHub": a pool of sound-effect players and a crossfading music player. Everything goes through the static
## helper `Sfx` (scripts/sfx.gd), so game scripts never reference this node directly.

const POOL_SIZE: int = 20
const MIN_GAP: float = 0.045  # the same effect cannot restart faster than this (keeps big fights from becoming noise)

var listener: Vector3 = Vector3.INF

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _last_played: Dictionary = {}
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_name: String = ""
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # sounds and music keep going while the game is paused
	Settings.init()
	for i: int in POOL_SIZE:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music_a = _make_music_player()
	_music_b = _make_music_player()


func _make_music_player() -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.bus = "Music"
	p.volume_db = -80.0
	add_child(p)
	return p


func _stream(stream_name: String) -> AudioStream:
	if not _streams.has(stream_name):
		var path: String = "res://audio/%s.wav" % stream_name
		var s: AudioStreamWAV = load(path) as AudioStreamWAV
		if s != null and stream_name.begins_with("music_"):
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = s.data.size() / 2
		_streams[stream_name] = s
	return _streams[stream_name]


## Plays an effect. `at` is a world position (volume fades with distance from the listener); Vector3.INF = not positional.
func play(stream_name: String, volume_db: float = 0.0, at: Vector3 = Vector3.INF, pitch: float = 1.0) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(stream_name, -10.0)) < MIN_GAP:
		return
	var db: float = volume_db
	if at != Vector3.INF and listener != Vector3.INF:
		var d: float = at.distance_to(listener)
		if d > 70.0:
			return
		db -= clampf((d - 7.0) * 0.55, 0.0, 28.0)
	var s: AudioStream = _stream(stream_name)
	if s == null:
		return
	for p: AudioStreamPlayer in _players:
		if not p.playing:
			_last_played[stream_name] = now
			p.stream = s
			p.volume_db = db
			p.pitch_scale = pitch * randf_range(0.94, 1.06)
			p.play()
			return


## Starts a music loop with a crossfade. Asking for the track that already plays does nothing.
func music(track: String, fade: float = 1.2) -> void:
	if track == _music_name:
		return
	_music_name = track
	var incoming: AudioStreamPlayer = _music_b if _music_a.playing and _music_a.volume_db > -60.0 else _music_a
	var outgoing: AudioStreamPlayer = _music_a if incoming == _music_b else _music_b
	if _music_tween != null:
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true)
	if track != "":
		incoming.stream = _stream(track)
		incoming.volume_db = -60.0
		incoming.play()
		_music_tween.tween_property(incoming, "volume_db", -6.0, fade)
	_music_tween.tween_property(outgoing, "volume_db", -60.0, fade)
	_music_tween.chain().tween_callback(outgoing.stop)


func current_music() -> String:
	return _music_name


func _exit_tree() -> void:
	for p: AudioStreamPlayer in _players:
		p.stop()
		p.stream = null
	for p: AudioStreamPlayer in [_music_a, _music_b]:
		p.stop()
		p.stream = null
	_streams.clear()
