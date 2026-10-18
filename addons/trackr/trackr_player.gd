# component from https://jam-trackr.vercel.app for playing jam.trackr generated zips

class_name TrackrPlayer
extends Node
## Row-based sample sequencer with an internal BPM clock or one row per external tick.

signal row_changed(order_index: int, pattern_id: String, row: int)
signal finished
signal load_failed(message: String)

const SequenceLoader = preload("sequence_loader.gd")

enum PlaybackMode { INTERNAL, EXTERNAL }

## Trackr export ZIP to load automatically when this node becomes ready.
@export_file("*.zip") var sequence_file: String = ""
## Clock used by play(). External mode waits for tick() before playing each row.
@export var playback_mode: PlaybackMode = PlaybackMode.INTERNAL
## Internal clock tempo. Loading a sequence preserves this setting.
@export_range(1, 960, 1, "or_greater") var bpm: float = 120.0:
	set(value):
		if is_finite(value) and value > 0.0 and value <= 10000.0:
			_sync_time()
			bpm = value
@export var loop: bool = true
@export var output_bus: StringName = &"Master":
	set(value):
		output_bus = value
		_apply_output()
@export_range(-80, 12, 0.1) var volume_db: float = 0.0:
	set(value):
		volume_db = value
		_apply_output()
## Zero disables automatic fading. This timeout only applies to external playback.
@export_range(0, 60, 0.01, "or_greater") var idle_timeout: float = 0.0
@export_range(0, 10, 0.01, "or_greater") var idle_fade_duration: float = 0.25
@export_range(0, 10, 0.01, "or_greater") var idle_recovery_duration: float = 0.03

var playing: bool:
	get:
		return _running
var paused: bool:
	get:
		return _paused
var current_row: int = -1
var current_order: int = 0

class Voice:
	var player: AudioStreamPlayer
	var track: int
	var age: float = 0.0
	var attack: float
	var release: float
	var release_age: float = -1.0
	var release_start: float = 0.0
	var level: float = 0.0
	var gain: float
	var looping: bool

var _data: Dictionary = {}
var _streams: Dictionary = {}
var _patterns: Dictionary = {}
var _sample_info: Dictionary = {}
var _voices: Array[Voice] = []
var _active: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _buses: Array[StringName] = []
var _track_buses: Array[StringName] = []
var _fade_bus: StringName
var _running := false
var _external := false
var _paused := false
var _row := 0
var _order := 0
var _phase := 0.0
var _last_process_usec: int = 0
var _has_tick := false
var _idle_elapsed := 0.0
var _idle_gain := 1.0
var _fade_from := 1.0
var _fade_target := 1.0
var _fade_elapsed := 0.0
var _fade_duration := 0.0

func _ready() -> void:
	if not sequence_file.is_empty():
		load_sequence(sequence_file)

## Accepts a ZIP, an extracted directory, or a path to sequence.json. Returns a Godot Error.
## Call after add_child(). Failed loads preserve the previous sequence.
func load_sequence(path: String) -> Error:
	if not is_inside_tree():
		load_failed.emit("Add TrackrPlayer to the scene tree before loading a sequence.")
		return ERR_UNCONFIGURED
	var result: Dictionary = SequenceLoader.read(path)
	if result.has("error"):
		load_failed.emit(result.error)
		return ERR_INVALID_DATA
	stop()
	_dispose_buses()
	_data = result.data
	_streams = result.streams
	_patterns = result.rows
	_sample_info.clear()
	for sample: Dictionary in _data.samples:
		_sample_info[sample.id] = sample
	loop = bool(_data.loop)
	_build_mixer()
	return OK

## Starts in playback_mode: internal plays row zero immediately; external waits for tick().
## Negative/default BPM keeps the current BPM.
func play(bpm_override: float = -1.0) -> void:
	if not _begin(playback_mode == PlaybackMode.EXTERNAL):
		return
	if bpm_override > 0.0:
		bpm = bpm_override
	if not _external:
		_step_row()

## Arms external playback regardless of playback_mode, waiting for the first tick().
func start_external() -> void:
	_begin(true)

func set_bpm(value: float) -> void:
	bpm = value

func tick() -> void:
	if not _running or not _external or _paused:
		return
	_sync_time()
	_has_tick = true
	_idle_elapsed = 0.0
	_fade_to(1.0, idle_recovery_duration)
	_step_row()

## Freezes row phase, sample positions, envelopes, and idle-fade progress.
## Ticks arriving while paused are ignored, not queued.
func pause() -> void:
	if _paused:
		return
	_sync_time()
	_paused = true
	for voice in _voices:
		voice.player.stream_paused = true

func resume() -> void:
	if not _paused:
		return
	_paused = false
	_last_process_usec = Time.get_ticks_usec()
	for voice in _voices:
		voice.player.stream_paused = false

func stop() -> void:
	_running = false
	_paused = false
	for voice in _voices:
		voice.player.stop()
		voice.player.stream = null
		voice.player.stream_paused = false
		_pool.append(voice.player)
	_voices.clear()
	_active.clear()
	_row = 0
	_order = 0
	_phase = 0.0
	current_row = -1
	current_order = 0
	_has_tick = false
	_idle_elapsed = 0.0
	_idle_gain = 1.0
	_fade_target = 1.0
	_fade_elapsed = 0.0
	_fade_duration = 0.0
	_last_process_usec = Time.get_ticks_usec()
	_apply_output()

func _begin(external: bool) -> bool:
	if _data.is_empty() or not is_inside_tree():
		load_failed.emit("Load a sequence before starting TrackrPlayer.")
		return false
	stop()
	if _buses.is_empty():
		_build_mixer()
	_external = external
	_running = true
	return true

func _process(_delta: float) -> void:
	_sync_time()

func _sync_time() -> void:
	var now := Time.get_ticks_usec()
	var elapsed := float(now - _last_process_usec) / 1000000.0 if _last_process_usec > 0 else 0.0
	_last_process_usec = now
	if not _paused:
		_advance(elapsed)

## Kept independent of wall-clock reads so clock/fade behavior can be tested deterministically.
func _advance(delta: float) -> void:
	if _paused or delta <= 0.0:
		return
	if _external or not _running:
		_advance_audio(delta)
		if _external and _has_tick:
			_advance_idle(delta)
		return
	# Preserve fractional row phase through BPM changes. Split stalled frames at row
	# boundaries so obsolete voices finish instead of accumulating release tails.
	var remaining := delta
	while _running and not _paused:
		var row_seconds: float = 60.0 / bpm / float(_data.rows_per_beat)
		var until_row := (1.0 - _phase) * row_seconds
		if remaining + 0.000000001 < until_row:
			_phase += remaining / row_seconds
			_advance_audio(remaining)
			return
		_advance_audio(until_row)
		remaining = maxf(0.0, remaining - until_row)
		_phase = 0.0
		_step_row()
		if remaining <= 0.0:
			return
	if not _paused:
		_advance_audio(remaining)

func _step_row() -> void:
	var pattern_id: String = _data.order[_order]
	var rows: Array = _patterns[pattern_id]
	if _row >= rows.size():
		_row = 0
		_order += 1
		if _order >= _data.order.size():
			if not loop:
				_running = false
				# One-shots decay naturally; sustain loops receive a release at the end.
				for voice in _voices:
					if voice.looping:
						_release(voice)
				_active.clear()
				finished.emit()
				return
			_order = 0
		pattern_id = _data.order[_order]
		rows = _patterns[pattern_id]
	current_row = _row
	current_order = _order
	for event: Dictionary in rows[_row]:
		var track := int(event.track)
		if _active.has(track):
			_release(_active[track])
			_active.erase(track)
		if event.op == "note_on":
			_start_voice(event, track)
	_row += 1
	row_changed.emit(current_order, pattern_id, current_row)

func _start_voice(event: Dictionary, track: int) -> void:
	var info: Dictionary = _sample_info[event.sample]
	var player: AudioStreamPlayer
	if _pool.is_empty():
		player = AudioStreamPlayer.new()
		# Web's default Sample playback bypasses the panner/compressor audio effects.
		player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		add_child(player)
	else:
		player = _pool.pop_back()
	player.stream = _streams[event.sample]
	player.bus = _track_buses[track]
	player.pitch_scale = pow(2.0, (float(event.note) - float(info.root_note)) / 12.0)
	player.volume_db = -100.0
	player.stream_paused = false
	var voice := Voice.new()
	voice.player = player
	voice.track = track
	voice.attack = float(info.attack)
	voice.release = float(info.release)
	voice.gain = float(info.gain) * float(event.volume) / 100.0
	voice.looping = info.has("loop")
	# Prime the first mix block: a sub-frame one-shot must be audible even if it
	# finishes before the next scene frame can update its attack envelope.
	voice.level = minf(1.0, 128.0 / AudioServer.get_mix_rate() / voice.attack)
	player.volume_db = _gain_db(voice.level * voice.gain)
	_voices.append(voice)
	_active[track] = voice
	player.play()

func _release(voice: Voice) -> void:
	if voice.release_age < 0.0:
		voice.release_age = 0.0
		voice.release_start = voice.level

func _advance_audio(delta: float) -> void:
	for index in range(_voices.size() - 1, -1, -1):
		var voice := _voices[index]
		voice.age += delta
		if voice.release_age >= 0.0:
			voice.release_age += delta
			voice.level = voice.release_start * maxf(0.0, 1.0 - voice.release_age / voice.release)
		else:
			voice.level = maxf(voice.level, minf(1.0, voice.age / voice.attack))
		if not voice.player.playing or (voice.release_age >= voice.release):
			voice.player.stop()
			voice.player.stream = null
			_pool.append(voice.player)
			_voices.remove_at(index)
			if _active.get(voice.track) == voice:
				_active.erase(voice.track)
		else:
			voice.player.volume_db = _gain_db(voice.level * voice.gain)

func _advance_idle(delta: float) -> void:
	var previous := _idle_elapsed
	_idle_elapsed += delta
	var fade_delta := delta
	if idle_timeout <= 0.0:
		_fade_to(1.0, idle_recovery_duration)
	elif _idle_elapsed >= idle_timeout:
		_fade_to(0.0, idle_fade_duration)
		if previous < idle_timeout:
			fade_delta = _idle_elapsed - idle_timeout
	_fade_elapsed += fade_delta
	if _fade_duration > 0.0:
		_idle_gain = lerpf(_fade_from, _fade_target, minf(1.0, _fade_elapsed / _fade_duration))
	else:
		_idle_gain = _fade_target
	_apply_output()

func _fade_to(target: float, duration: float) -> void:
	if _fade_target == target:
		return
	_fade_from = _idle_gain
	_fade_target = target
	_fade_elapsed = 0.0
	_fade_duration = maxf(0.0, duration)
	if _fade_duration == 0.0:
		_idle_gain = target
		_apply_output()

func _build_mixer() -> void:
	var prefix := "Trackr_%d_" % get_instance_id()
	_fade_bus = StringName(prefix + "Output")
	_add_bus(_fade_bus, output_bus)
	var mix_bus := StringName(prefix + "Mix")
	var mix_index := _add_bus(mix_bus, _fade_bus)
	AudioServer.set_bus_volume_db(mix_index, _gain_db(float(_data.master_gain)))
	AudioServer.set_bus_mute(mix_index, float(_data.master_gain) == 0.0)
	var compressor := AudioEffectCompressor.new()
	compressor.threshold = -6.0
	compressor.ratio = 8.0
	compressor.attack_us = 3000.0
	compressor.release_ms = 120.0
	AudioServer.add_bus_effect(mix_index, compressor)
	for index in _data.tracks.size():
		var track: Dictionary = _data.tracks[index]
		var bus := StringName(prefix + "Track_%d" % index)
		var bus_index := _add_bus(bus, mix_bus)
		AudioServer.set_bus_volume_db(bus_index, _gain_db(float(track.volume)))
		AudioServer.set_bus_mute(bus_index, float(track.volume) == 0.0)
		var panner := AudioEffectPanner.new()
		panner.pan = float(track.pan)
		AudioServer.add_bus_effect(bus_index, panner)
		_track_buses.append(bus)
	_apply_output()

func _add_bus(bus: StringName, send: StringName) -> int:
	var index := AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(index, bus)
	AudioServer.set_bus_send(index, send if AudioServer.get_bus_index(send) >= 0 else &"Master")
	_buses.append(bus)
	return index

func _apply_output() -> void:
	if _buses.is_empty():
		return
	var index := AudioServer.get_bus_index(_fade_bus)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, volume_db + _gain_db(_idle_gain))
		AudioServer.set_bus_mute(index, _idle_gain <= 0.0)
		AudioServer.set_bus_send(index, output_bus if AudioServer.get_bus_index(output_bus) >= 0 else &"Master")

static func _gain_db(gain: float) -> float:
	return linear_to_db(gain) if gain > 0.0 else -100.0

func _dispose_buses() -> void:
	for offset in range(_buses.size() - 1, -1, -1):
		var bus := _buses[offset]
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			AudioServer.remove_bus(index)
	_buses.clear()
	_track_buses.clear()

func _exit_tree() -> void:
	stop()
	_dispose_buses()
