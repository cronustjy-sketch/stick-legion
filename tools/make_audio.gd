extends SceneTree
## Synthesises every sound effect and music loop of the game into res://audio/*.wav (mono, 22.05 kHz, 16-bit).
## Run once (the WAV files are committed):  godot --headless --path . --script res://tools/make_audio.gd
## Nothing here is sampled from anywhere: everything is generated from sine / saw / square waves and filtered noise.

const SR: int = 22050
const OUT: String = "res://audio/"

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 20261026
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var sfx: Dictionary = {
		"click": _click(), "coin": _coin(), "swing": _swing(0.28, 0.35), "swing_big": _swing(0.5, 0.55), "hit": _hit(), "clang": _clang(),
		"arrow": _arrow(), "bow": _bow(), "fireball": _fireball(), "explosion": _explosion(), "boom": _boom(), "heal": _heal(), "death": _death(),
		"hurt": _hurt(), "horn": _horn(), "roar": _roar(), "zap": _zap(), "crack": _crack(), "fanfare": _fanfare(), "defeat": _defeat(),
		"warning": _warning(), "page": _page(), "step": _step(), "whoosh_big": _whoosh_big(), "boulder": _boulder(), "order": _order(),
	}
	for name: String in sfx:
		_save(name, sfx[name], 0.9)
	var music: Dictionary = {"music_menu": _music_menu(), "music_battle": _music_battle(), "music_boss": _music_boss(), "music_story": _music_story()}
	for name: String in music:
		_save(name, music[name], 0.7)
	print("AUDIO generated: ", sfx.size(), " effects, ", music.size(), " music loops")
	quit()


# --- Output -------------------------------------------------------------------------------------------

func _save(name: String, buf: PackedFloat32Array, peak: float) -> void:
	var m: float = 0.0001
	var sq: float = 0.0
	for v: float in buf:
		m = maxf(m, absf(v))
		sq += v * v
	var k: float = peak / m
	var is_music: bool = name.begins_with("music_")
	if is_music:  # music loops share one loudness (RMS) so the tracks feel equally loud
		k = minf(0.15 / sqrt(sq / float(buf.size())), 0.9 / m)
	var fade: int = int((0.03 if is_music else 0.008) * float(SR))
	for i: int in fade:
		buf[buf.size() - 1 - i] *= float(i) / float(fade)
		if is_music:
			buf[i] *= float(i) / float(fade)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i: int in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i] * k, -1.0, 1.0) * 32767.0))
	var w: AudioStreamWAV = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = bytes
	w.save_to_wav(ProjectSettings.globalize_path(OUT + name + ".wav"))


# --- Building blocks ----------------------------------------------------------------------------------

func _zeros(seconds: float) -> PackedFloat32Array:
	var b: PackedFloat32Array = PackedFloat32Array()
	b.resize(int(seconds * float(SR)))
	return b


func _noise() -> float:
	return _rng.randf() * 2.0 - 1.0


func _saw(phase: float) -> float:
	return 2.0 * (phase - floorf(phase)) - 1.0


func _square(phase: float) -> float:
	return 1.0 if (phase - floorf(phase)) < 0.5 else -1.0


func _mix(dst: PackedFloat32Array, src: PackedFloat32Array, at: float = 0.0, gain: float = 1.0) -> void:
	var o: int = int(at * float(SR))
	for i: int in src.size():
		if o + i < dst.size():
			dst[o + i] += src[i] * gain


func _midi(n: float) -> float:
	return 440.0 * pow(2.0, (n - 69.0) / 12.0)


# One shaped tone: kind 0 sine, 1 saw, 2 square, 3 triangle. Frequency glides f0 -> f1. Decay is an exponential rate (higher = shorter).
func _tone(seconds: float, f0: float, f1: float, kind: int, attack: float, decay: float, lowpass: float = 1.0) -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(seconds)
	var phase: float = 0.0
	var lp: float = 0.0
	for i: int in b.size():
		var t: float = float(i) / float(SR)
		var u: float = t / seconds
		phase += lerpf(f0, f1, u) / float(SR)
		var s: float
		match kind:
			0:
				s = sin(TAU * phase)
			1:
				s = _saw(phase)
			2:
				s = _square(phase)
			_:
				s = 2.0 * absf(2.0 * (phase - floorf(phase + 0.5))) - 1.0
		if lowpass < 1.0:
			lp += lowpass * (s - lp)
			s = lp
		var env: float = minf(t / maxf(attack, 0.0005), 1.0) * exp(-decay * t)
		b[i] = s * env
	return b


# Filtered noise: the filter cutoff sweeps from lp0 to lp1 (0..1), amplitude has a short attack and an exponential decay.
func _noise_burst(seconds: float, lp0: float, lp1: float, attack: float, decay: float) -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(seconds)
	var lp: float = 0.0
	for i: int in b.size():
		var t: float = float(i) / float(SR)
		var a: float = lerpf(lp0, lp1, t / seconds)
		lp += a * (_noise() - lp)
		b[i] = lp * minf(t / maxf(attack, 0.0005), 1.0) * exp(-decay * t)
	return b


func _fade_out(b: PackedFloat32Array, seconds: float) -> void:
	var n: int = int(seconds * float(SR))
	for i: int in n:
		var idx: int = b.size() - 1 - i
		if idx >= 0:
			b[idx] *= float(i) / float(n)


# --- Effects ------------------------------------------------------------------------------------------

func _click() -> PackedFloat32Array:
	return _tone(0.07, 1300.0, 900.0, 0, 0.002, 38.0)


func _coin() -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(0.4)
	_mix(b, _tone(0.3, 988.0, 988.0, 0, 0.002, 9.0))
	_mix(b, _tone(0.3, 1319.0, 1319.0, 0, 0.002, 8.0), 0.09)
	return b


func _swing(seconds: float, brightness: float) -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(seconds)
	var lp: float = 0.0
	for i: int in b.size():
		var u: float = float(i) / float(b.size())
		var a: float = brightness * sin(PI * u) + 0.03
		lp += a * (_noise() - lp)
		b[i] = lp * sin(PI * u) * 1.6
	return b


func _hit() -> PackedFloat32Array:
	var b: PackedFloat32Array = _noise_burst(0.18, 0.5, 0.15, 0.001, 22.0)
	_mix(b, _tone(0.18, 130.0, 70.0, 0, 0.001, 18.0), 0.0, 1.2)
	return b


func _clang() -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(0.6)
	var partials: Array = [[820.0, 7.0, 1.0], [1370.0, 9.0, 0.7], [1930.0, 12.0, 0.5], [2710.0, 16.0, 0.4]]
	for p: Array in partials:
		_mix(b, _tone(0.6, float(p[0]), float(p[0]), 0, 0.001, float(p[1])), 0.0, float(p[2]))
	_mix(b, _noise_burst(0.05, 0.9, 0.5, 0.001, 70.0), 0.0, 0.6)
	return b


func _arrow() -> PackedFloat32Array:
	var b: PackedFloat32Array = _noise_burst(0.2, 0.7, 0.25, 0.01, 11.0)
	_mix(b, _tone(0.2, 2200.0, 900.0, 0, 0.01, 12.0), 0.0, 0.25)
	return b


func _bow() -> PackedFloat32Array:
	var b: PackedFloat32Array = _tone(0.3, 240.0, 200.0, 3, 0.001, 14.0)
	_mix(b, _noise_burst(0.05, 0.8, 0.4, 0.001, 60.0), 0.0, 0.5)
	return b


func _fireball() -> PackedFloat32Array:
	var b: PackedFloat32Array = _tone(0.5, 180.0, 760.0, 1, 0.02, 3.5, 0.25)
	_mix(b, _noise_burst(0.5, 0.35, 0.6, 0.02, 4.0), 0.0, 0.5)
	return b


func _explosion() -> PackedFloat32Array:
	var b: PackedFloat32Array = _noise_burst(0.9, 0.22, 0.02, 0.002, 4.5)
	_mix(b, _tone(0.8, 90.0, 40.0, 0, 0.002, 5.0), 0.0, 1.4)
	return b


func _boom() -> PackedFloat32Array:
	var b: PackedFloat32Array = _tone(1.0, 75.0, 32.0, 0, 0.004, 3.2)
	_mix(b, _noise_burst(0.5, 0.12, 0.02, 0.002, 7.0), 0.0, 0.8)
	return b


func _boulder() -> PackedFloat32Array:
	var b: PackedFloat32Array = _noise_burst(0.7, 0.15, 0.02, 0.002, 6.0)
	_mix(b, _tone(0.7, 60.0, 35.0, 0, 0.002, 6.0), 0.0, 1.6)
	_mix(b, _noise_burst(0.12, 0.6, 0.3, 0.001, 30.0), 0.05, 0.6)
	return b


func _heal() -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(0.9)
	var notes: Array = [72.0, 76.0, 79.0, 84.0]
	for i: int in notes.size():
		_mix(b, _tone(0.5, _midi(float(notes[i])), _midi(float(notes[i])), 0, 0.004, 6.0), float(i) * 0.09)
		_mix(b, _tone(0.4, _midi(float(notes[i])) * 2.0, _midi(float(notes[i])) * 2.0, 0, 0.004, 9.0), float(i) * 0.09, 0.3)
	return b


func _death() -> PackedFloat32Array:
	var b: PackedFloat32Array = _tone(0.45, 320.0, 70.0, 1, 0.003, 6.0, 0.18)
	_mix(b, _noise_burst(0.2, 0.3, 0.05, 0.001, 18.0), 0.2, 0.8)
	_mix(b, _tone(0.25, 90.0, 50.0, 0, 0.001, 14.0), 0.25, 1.0)
	return b


func _hurt() -> PackedFloat32Array:
	return _tone(0.28, 170.0, 95.0, 1, 0.004, 8.0, 0.2)


func _horn() -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(1.1)
	for f: float in [196.0, 294.0, 392.0]:
		var t: PackedFloat32Array = _zeros(1.1)
		var phase: float = 0.0
		var lp: float = 0.0
		for i: int in t.size():
			var time: float = float(i) / float(SR)
			phase += (f * (1.0 + 0.004 * sin(TAU * 5.5 * time))) / float(SR)
			lp += 0.16 * (_saw(phase) - lp)
			t[i] = lp * minf(time / 0.12, 1.0) * exp(-1.6 * maxf(time - 0.55, 0.0))
		_mix(b, t, 0.0, 0.5)
	return b


func _roar() -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(1.3)
	var phase: float = 0.0
	var lp: float = 0.0
	for i: int in b.size():
		var t: float = float(i) / float(SR)
		phase += (78.0 - 22.0 * t) / float(SR)
		var growl: float = 0.55 + 0.45 * sin(TAU * 26.0 * t)
		lp += 0.07 * ((_saw(phase) * 0.8 + _noise() * 0.5) * growl - lp)
		b[i] = lp * minf(t / 0.1, 1.0) * exp(-1.4 * maxf(t - 0.5, 0.0))
	return b


func _zap() -> PackedFloat32Array:
	return _tone(0.28, 1000.0, 180.0, 2, 0.002, 10.0, 0.5)


func _crack() -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(0.45)
	for k: int in 3:
		_mix(b, _noise_burst(0.12, 0.45, 0.1, 0.001, 30.0), float(k) * 0.08, 1.0 - 0.25 * float(k))
	_mix(b, _tone(0.3, 110.0, 60.0, 0, 0.002, 12.0), 0.0, 0.8)
	return b


func _fanfare() -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(2.4)
	var seq: Array = [[60.0, 0.0, 0.2], [64.0, 0.2, 0.2], [67.0, 0.4, 0.2], [72.0, 0.6, 0.35]]
	for n: Array in seq:
		_mix(b, _tone(float(n[2]) + 0.15, _midi(float(n[0])), _midi(float(n[0])), 1, 0.01, 4.0, 0.2), float(n[1]), 0.7)
	for m: float in [60.0, 64.0, 67.0, 72.0]:
		_mix(b, _tone(1.5, _midi(m), _midi(m), 1, 0.03, 1.6, 0.2), 0.95, 0.4)
	_fade_out(b, 0.2)
	return b


func _defeat() -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(2.6)
	var seq: Array = [[57.0, 0.0], [53.0, 0.5], [52.0, 1.0], [45.0, 1.5]]
	for n: Array in seq:
		_mix(b, _tone(1.0, _midi(float(n[0])), _midi(float(n[0])) * 0.98, 1, 0.02, 2.4, 0.15), float(n[1]), 0.6)
	_fade_out(b, 0.3)
	return b


func _warning() -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(0.9)
	for k: int in 3:
		_mix(b, _tone(0.22, 150.0, 120.0, 2, 0.01, 6.0, 0.12), float(k) * 0.28)
	return b


func _page() -> PackedFloat32Array:
	return _noise_burst(0.07, 0.8, 0.5, 0.001, 45.0)


func _step() -> PackedFloat32Array:
	var b: PackedFloat32Array = _noise_burst(0.09, 0.25, 0.05, 0.001, 35.0)
	_mix(b, _tone(0.09, 100.0, 60.0, 0, 0.001, 30.0))
	return b


func _whoosh_big() -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(0.9)
	var lp: float = 0.0
	for i: int in b.size():
		var u: float = float(i) / float(b.size())
		lp += (0.04 + 0.4 * u * u) * (_noise() - lp)
		b[i] = lp * (u if u < 0.8 else (1.0 - u) * 5.0) * 1.8
	_mix(b, _tone(0.9, 80.0, 220.0, 1, 0.1, 1.5, 0.1), 0.0, 0.5)
	return b


func _order() -> PackedFloat32Array:
	var b: PackedFloat32Array = _tone(0.16, 520.0, 520.0, 3, 0.003, 14.0)
	_mix(b, _tone(0.16, 780.0, 780.0, 3, 0.003, 14.0), 0.07, 0.8)
	return b


# --- Music --------------------------------------------------------------------------------------------

# Adds a sustained note with a smooth fade in/out (so loops stay seamless).
func _pad_note(dst: PackedFloat32Array, midi: float, at: float, length: float, gain: float, kind: int, lowpass: float) -> void:
	var n: PackedFloat32Array = _zeros(length)
	var phase: float = 0.0
	var lp: float = 0.0
	var f: float = _midi(midi)
	for i: int in n.size():
		var t: float = float(i) / float(SR)
		phase += f / float(SR)
		var s: float = sin(TAU * phase) if kind == 0 else _saw(phase)
		lp += lowpass * (s - lp)
		var fade: float = minf(minf(t / 0.9, 1.0), minf((length - t) / 0.9, 1.0))
		n[i] = lp * maxf(fade, 0.0)
	_mix(dst, n, at, gain)


func _pluck(dst: PackedFloat32Array, midi: float, at: float, gain: float, decay: float) -> void:
	_mix(dst, _tone(1.2, _midi(midi), _midi(midi), 3, 0.004, decay), at, gain)


func _kick(dst: PackedFloat32Array, at: float, gain: float) -> void:
	_mix(dst, _tone(0.3, 140.0, 45.0, 0, 0.001, 11.0), at, gain)


func _snare(dst: PackedFloat32Array, at: float, gain: float) -> void:
	_mix(dst, _noise_burst(0.22, 0.6, 0.35, 0.001, 16.0), at, gain)
	_mix(dst, _tone(0.15, 200.0, 140.0, 0, 0.001, 22.0), at, gain * 0.6)


func _hat(dst: PackedFloat32Array, at: float, gain: float) -> void:
	_mix(dst, _noise_burst(0.05, 0.9, 0.8, 0.001, 70.0), at, gain)


func _tom(dst: PackedFloat32Array, at: float, f: float, gain: float) -> void:
	_mix(dst, _tone(0.35, f * 1.4, f, 0, 0.002, 9.0), at, gain)


func _music_menu() -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(16.0)
	# Am - F - C - G, four seconds each. Warm saw pads, a soft arpeggio on top.
	var chords: Array = [[57.0, 60.0, 64.0], [53.0, 57.0, 60.0], [48.0, 55.0, 64.0], [55.0, 59.0, 62.0]]
	for c: int in 4:
		var at: float = float(c) * 4.0
		for m: float in chords[c]:
			_pad_note(b, m, at, 4.4, 0.2, 1, 0.045)
		_pad_note(b, float(chords[c][0]) - 12.0, at, 4.4, 0.3, 0, 1.0)
		for k: int in 8:
			var note: float = float(chords[c][k % 3]) + 12.0 + (12.0 if k % 4 == 3 else 0.0)
			_pluck(b, note, at + float(k) * 0.5, 0.18, 4.5)
	return b


func _music_battle() -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(16.0)  # 8 bars of 4 beats at 120 bpm
	var roots: Array = [45.0, 45.0, 41.0, 43.0, 45.0, 45.0, 41.0, 43.0]
	for bar: int in 8:
		var at: float = float(bar) * 2.0
		_kick(b, at, 1.0)
		_kick(b, at + 1.0, 0.8)
		_kick(b, at + 1.5, 0.5)
		_snare(b, at + 0.5, 0.7)
		_snare(b, at + 1.5, 0.7)
		for h: int in 8:
			_hat(b, at + float(h) * 0.25, 0.22)
		if bar % 2 == 1:
			_tom(b, at + 1.75, 110.0, 0.6)
			_tom(b, at + 1.875, 90.0, 0.6)
		var root: float = float(roots[bar])
		for q: int in 8:
			_mix(b, _tone(0.3, _midi(root - 12.0), _midi(root - 12.0), 1, 0.003, 7.0, 0.1), at + float(q) * 0.25, 0.55)
		if bar % 2 == 0:
			for m: float in [root + 12.0, root + 15.0, root + 19.0]:
				_mix(b, _tone(1.6, _midi(m), _midi(m), 1, 0.03, 1.8, 0.12), at, 0.2)
	return b


func _music_boss() -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(12.8)  # 8 bars at 150 bpm (0.4 s per beat)
	var roots: Array = [38.0, 38.0, 34.0, 33.0, 38.0, 38.0, 39.0, 33.0]
	for bar: int in 8:
		var at: float = float(bar) * 1.6
		for k: int in 4:
			_kick(b, at + float(k) * 0.4, 1.0 if k % 2 == 0 else 0.7)
		_snare(b, at + 0.4, 0.8)
		_snare(b, at + 1.2, 0.8)
		for h: int in 8:
			_hat(b, at + float(h) * 0.2, 0.2)
		for k: int in 3:
			_tom(b, at + 1.2 + float(k) * 0.133, 130.0 - 15.0 * float(k), 0.5)
		var root: float = float(roots[bar])
		for q: int in 8:
			var s: PackedFloat32Array = _tone(0.22, _midi(root - 12.0), _midi(root - 12.0), 1, 0.002, 8.0, 0.18)
			for i: int in s.size():
				s[i] = clampf(s[i] * 2.5, -0.8, 0.8)  # drive it a little
			_mix(b, s, at + float(q) * 0.2, 0.5)
		for m: float in [root + 12.0, root + 18.0, root + 19.0]:
			_mix(b, _tone(0.7, _midi(m), _midi(m), 2, 0.01, 4.5, 0.14), at + (0.0 if bar % 2 == 0 else 0.8), 0.2)
	return b


func _music_story() -> PackedFloat32Array:
	var b: PackedFloat32Array = _zeros(20.0)
	# Dm - Bb - Gm - A, five seconds each: slow low strings and a few bell notes.
	var chords: Array = [[50.0, 57.0, 62.0, 65.0], [46.0, 53.0, 58.0, 62.0], [43.0, 50.0, 58.0, 62.0], [45.0, 52.0, 61.0, 64.0]]
	for c: int in 4:
		var at: float = float(c) * 5.0
		for m: float in chords[c]:
			_pad_note(b, m, at, 5.6, 0.2, 1, 0.03)
		_pad_note(b, float(chords[c][0]) - 12.0, at, 5.6, 0.35, 0, 1.0)
		_pluck(b, float(chords[c][2]) + 12.0, at + 1.0, 0.25, 2.2)
		_pluck(b, float(chords[c][3]) + 12.0, at + 2.6, 0.2, 2.2)
		_pluck(b, float(chords[c][1]) + 24.0, at + 3.8, 0.15, 2.5)
	return b
