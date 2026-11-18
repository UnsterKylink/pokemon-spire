class_name AudioManager
extends Node
## Story 022: music, sound effects and Pokemon cries, driven by assets/data/audio.json.
##
## Meant to be added once by Main (story 022 part 2) and called by the screens:
## play_music(context) with a crossfade, play_sfx(id) / play_event(event), play_cry(slug or sprite path).
## Two buses, "Music" and "SFX", are created at runtime when the project has none. Volumes are 0..1 and
## saved in GameSettings (music_volume, sfx_volume); 0 mutes the bus. Headless runs (tests, CI) keep every
## call working but mute both buses. A missing file never crashes: it gives one push_warning, then is ignored.

const CONFIG_PATH: String = "res://assets/data/audio.json"
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"
## Volume used for a fading-out player and the start of a fade-in.
const SILENT_DB: float = -60.0

var _config: Dictionary = {}
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _current_track: String = ""
var _fade_tween: Tween
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_next: int = 0
var _cry_player: AudioStreamPlayer
var _streams: Dictionary = {}  # path -> AudioStream (or null when missing)
var _warned: Dictionary = {}
var _music_volume: float = 0.6
var _sfx_volume: float = 0.8
var _headless: bool = false


## `config_path`: the audio.json to read (tests may pass another file); a missing / broken file gives an empty
## config (every call then only warns).
func _init(config_path: String = CONFIG_PATH) -> void:
	_config = _read_config(config_path)
	_headless = DisplayServer.get_name() == "headless"
	var defaults: Dictionary = _config.get("default_volumes", {}) if _config.get("default_volumes", {}) is Dictionary else {}
	_music_volume = clampf(GameSettings.get_float(GameSettings.KEY_MUSIC_VOLUME, float(defaults.get("music", 0.6))), 0.0, 1.0)
	_sfx_volume = clampf(GameSettings.get_float(GameSettings.KEY_SFX_VOLUME, float(defaults.get("sfx", 0.8))), 0.0, 1.0)
	_ensure_buses()
	_music_a = _make_player(MUSIC_BUS, "MusicA")
	_music_b = _make_player(MUSIC_BUS, "MusicB")
	_active = _music_a
	var poly: int = maxi(1, int(_config.get("sfx_polyphony", 8)))
	for i: int in poly:
		_sfx_pool.append(_make_player(SFX_BUS, "Sfx%d" % i))
	_cry_player = _make_player(SFX_BUS, "Cry")
	_cry_player.volume_db = linear_to_db(maxf(0.001, _cry_volume()))
	_apply_volumes()


# ------------------------------------------------------------------------------------------------ music

## Plays the music of a game context (a key of audio.json "music", e.g. "map", "wild", "boss", "final_boss_phase2")
## or directly a track id. Crossfades from the current track (`fade` < 0 = audio.json crossfade_seconds).
## Does nothing when that track is already playing; an unknown context or missing file only warns.
func play_music(context: String, fade: float = -1.0) -> void:
	var track: String = music_track_for(context)
	if track.is_empty():
		_warn_once("context:" + context, "AudioManager: no music for context '%s'" % context)
		return
	if track == _current_track and (_active.playing or _headless):
		return  # a finished jingle (victoire / defaite) is replayed when asked again
	var info: Dictionary = _tracks().get(track, {})
	var stream: AudioStream = _load_stream(String(info.get("file", "")))
	if stream == null:
		return
	_set_loop(stream, bool(info.get("loop", true)))
	var seconds: float = _crossfade_seconds() if fade < 0.0 else fade
	var old: AudioStreamPlayer = _active
	_active = _music_b if _active == _music_a else _music_a
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_active.stop()
	_active.stream = stream
	_current_track = track
	if seconds > 0.0 and is_inside_tree() and old.playing:
		_active.volume_db = SILENT_DB
		_active.play()
		_fade_tween = create_tween().set_parallel(true)
		_fade_tween.tween_property(_active, "volume_db", 0.0, seconds)
		_fade_tween.tween_property(old, "volume_db", SILENT_DB, seconds)
		_fade_tween.chain().tween_callback(old.stop)
	else:
		old.stop()
		_active.volume_db = 0.0
		_active.play()


## Stops the music, fading out over `fade` seconds (< 0 = audio.json crossfade_seconds, 0 = at once).
func stop_music(fade: float = -1.0) -> void:
	_current_track = ""
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	var seconds: float = _crossfade_seconds() if fade < 0.0 else fade
	for p: AudioStreamPlayer in [_music_a, _music_b]:
		if seconds > 0.0 and is_inside_tree() and p.playing:
			var t: Tween = create_tween()
			t.tween_property(p, "volume_db", SILENT_DB, seconds)
			t.tween_callback(p.stop)
		else:
			p.stop()


## Id of the track currently chosen ("" when none); set even while muted / headless.
func current_track() -> String:
	return _current_track


## The track id audio.json gives to `context` ("" when unknown); a track id is accepted as its own context.
func music_track_for(context: String) -> String:
	var music: Dictionary = _config.get("music", {}) if _config.get("music", {}) is Dictionary else {}
	if music.has(context):
		return String(music[context])
	return context if _tracks().has(context) else ""


# ------------------------------------------------------------------------------------------------ sfx / cries

## Plays one sound effect by id (a key of audio.json "sfx", else <sfx_dir>/<id>.wav). Returns false when it could
## not be played (unknown id or missing file, warned once).
func play_sfx(id: String) -> bool:
	var sfx: Dictionary = _config.get("sfx", {}) if _config.get("sfx", {}) is Dictionary else {}
	var path: String = String(sfx.get(id, ""))
	if path.is_empty():
		path = "%s/%s.wav" % [String(_config.get("sfx_dir", "res://assets/audio/sfx")), id]
	var stream: AudioStream = _load_stream(path)
	if stream == null:
		return false
	var p: AudioStreamPlayer = _free_sfx_player()
	p.stream = stream
	p.play()
	return true


## Plays the sound effect audio.json "events" gives to a game event (e.g. "hit_super_effective", "item_bought").
## Returns false for an unknown event or a missing file.
func play_event(event: String) -> bool:
	var events: Dictionary = _config.get("events", {}) if _config.get("events", {}) is Dictionary else {}
	if not events.has(event):
		_warn_once("event:" + event, "AudioManager: no sound for event '%s'" % event)
		return false
	return play_sfx(String(events[event]))


## True when audio.json cries.play_on lists `moment` ("battle_enter", "ko", "capture_success", "evolution").
func cry_plays_on(moment: String) -> bool:
	var cries: Dictionary = _config.get("cries", {}) if _config.get("cries", {}) is Dictionary else {}
	var on: Variant = cries.get("play_on", [])
	return on is Array and moment in (on as Array)


## Plays the official cry of a Pokemon. `slug_or_sprite`: the sprite slug ("pikachu") or its sprite path
## ("res://assets/sprites/pokemon/pikachu.png"); cries are named after the sprite file. A new cry cuts the previous one.
## Returns false when the cry file is missing (warned once).
func play_cry(slug_or_sprite: String) -> bool:
	var slug: String = cry_slug(slug_or_sprite)
	if slug.is_empty():
		return false
	var cries: Dictionary = _config.get("cries", {}) if _config.get("cries", {}) is Dictionary else {}
	var stream: AudioStream = _load_stream("%s/%s.ogg" % [String(cries.get("dir", "res://assets/audio/cries")), slug])
	if stream == null:
		return false
	_set_loop(stream, false)
	_cry_player.stream = stream
	_cry_player.play()
	return true


## The cry slug of a sprite path or slug: the file name without folder or extension.
static func cry_slug(slug_or_sprite: String) -> String:
	return slug_or_sprite.get_file().get_basename()


# ------------------------------------------------------------------------------------------------ volumes

## The saved volume 0..1 of `kind` ("music" or "sfx"), or audio.json default_volumes when never set. Static: the
## options panel reads it without an AudioManager.
static func saved_volume(kind: String, config_path: String = CONFIG_PATH) -> float:
	var fallback: float = 0.6 if kind == "music" else 0.8
	if FileAccess.file_exists(config_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(config_path))
		if parsed is Dictionary and (parsed as Dictionary).get("default_volumes", null) is Dictionary:
			fallback = float((parsed["default_volumes"] as Dictionary).get(kind, fallback))
	var key: String = GameSettings.KEY_MUSIC_VOLUME if kind == "music" else GameSettings.KEY_SFX_VOLUME
	return clampf(GameSettings.get_float(key, fallback), 0.0, 1.0)


## The music context of a screen (audio.json "screens": Main screen name -> context); "" = keep the current music.
func screen_context(screen_name: String) -> String:
	var screens: Dictionary = _config.get("screens", {}) if _config.get("screens", {}) is Dictionary else {}
	return String(screens.get(screen_name, ""))


## Music volume 0..1 (saved in GameSettings music_volume; 0 mutes the Music bus).
func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	GameSettings.set_value(GameSettings.KEY_MUSIC_VOLUME, _music_volume)
	_apply_volumes()


## Current music volume 0..1.
func get_music_volume() -> float:
	return _music_volume


## Sound-effect volume 0..1, cries included (saved in GameSettings sfx_volume; 0 mutes the SFX bus).
func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clampf(volume, 0.0, 1.0)
	GameSettings.set_value(GameSettings.KEY_SFX_VOLUME, _sfx_volume)
	_apply_volumes()


## Current sound-effect volume 0..1.
func get_sfx_volume() -> float:
	return _sfx_volume


## True when the bus is silent (volume 0 or headless run).
func is_bus_muted(bus: StringName) -> bool:
	var idx: int = AudioServer.get_bus_index(bus)
	return idx < 0 or AudioServer.is_bus_mute(idx)


# ------------------------------------------------------------------------------------------------ internals

func _read_config(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_warn_once("config", "AudioManager: missing %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		_warn_once("config", "AudioManager: invalid JSON in %s" % path)
		return {}
	return parsed


func _tracks() -> Dictionary:
	return _config.get("tracks", {}) if _config.get("tracks", {}) is Dictionary else {}


func _crossfade_seconds() -> float:
	return maxf(0.0, float(_config.get("crossfade_seconds", 0.8)))


func _cry_volume() -> float:
	var cries: Dictionary = _config.get("cries", {}) if _config.get("cries", {}) is Dictionary else {}
	return clampf(float(cries.get("volume", 1.0)), 0.0, 1.0)


func _ensure_buses() -> void:
	for bus: StringName in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus) >= 0:
			continue
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus)
		AudioServer.set_bus_send(idx, &"Master")


func _apply_volumes() -> void:
	for pair: Array in [[MUSIC_BUS, _music_volume], [SFX_BUS, _sfx_volume]]:
		var idx: int = AudioServer.get_bus_index(pair[0])
		if idx < 0:
			continue
		var v: float = float(pair[1])
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))
		AudioServer.set_bus_mute(idx, _headless or v <= 0.0)


func _make_player(bus: StringName, player_name: String) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.name = player_name
	p.bus = bus
	add_child(p)
	return p


func _free_sfx_player() -> AudioStreamPlayer:
	for i: int in _sfx_pool.size():
		var p: AudioStreamPlayer = _sfx_pool[(_sfx_next + i) % _sfx_pool.size()]
		if not p.playing:
			_sfx_next = (_sfx_next + i + 1) % _sfx_pool.size()
			return p
	var oldest: AudioStreamPlayer = _sfx_pool[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_pool.size()
	return oldest


func _load_stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	var stream: AudioStream = null
	if not path.is_empty() and ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	if stream == null:
		_warn_once(path, "AudioManager: missing sound '%s'" % path)
	_streams[path] = stream
	return stream


func _set_loop(stream: AudioStream, loop: bool) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop
	elif stream is AudioStreamWAV:
		var wav: AudioStreamWAV = stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop and wav.loop_end > 0 else AudioStreamWAV.LOOP_DISABLED


func _warn_once(key: String, message: String) -> void:
	if _warned.has(key):
		return
	_warned[key] = true
	push_warning(message)
