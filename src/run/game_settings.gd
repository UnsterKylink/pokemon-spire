class_name GameSettings
extends RefCounted
## Player options saved in user://settings.json (shared with the animation speed of BattleFxDirector).
## Read / write are static and never fail loudly: a missing or broken file gives the defaults.

const PATH: String = "user://settings.json"
## Show a light green / red tint on targets when the selected attack is super / not very effective.
const KEY_TYPE_HINTS: String = "type_hints"
## Story 026: show the prestige card trim once unlocked (difficulty.json cosmetics.card_frames).
const KEY_PRESTIGE_FRAME: String = "prestige_frame"
const DEFAULTS: Dictionary = {KEY_TYPE_HINTS: true, KEY_PRESTIGE_FRAME: true}


## All saved settings (empty when there is no valid file).
static func load_all() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var f: FileAccess = FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}


## A boolean setting, or its default.
static func get_bool(key: String) -> bool:
	var value: Variant = load_all().get(key, DEFAULTS.get(key, false))
	return bool(value)


## Saves one setting (atomic: temp file then rename; failures are ignored).
static func set_value(key: String, value: Variant) -> void:
	var data: Dictionary = load_all()
	data[key] = value
	var tmp: String = PATH + ".tmp"
	var w: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if w == null:
		return
	w.store_string(JSON.stringify(data, "  "))
	w.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(PATH))


## True when the type-effectiveness hint is on.
static func type_hints_enabled() -> bool:
	return get_bool(KEY_TYPE_HINTS)


## Story 022: music volume 0..1 (read / written by AudioManager; default from assets/data/audio.json).
const KEY_MUSIC_VOLUME: String = "music_volume"
## Story 022: sound-effect volume 0..1 (also scales the Pokemon cries).
const KEY_SFX_VOLUME: String = "sfx_volume"


## A numeric setting, or `fallback` when absent or not a number.
static func get_float(key: String, fallback: float) -> float:
	var value: Variant = load_all().get(key, null)
	if value is float or value is int:
		return float(value)
	return fallback


## Story 023: fullscreen window (Options « Plein écran »); applied at launch by Main (real game only).
const KEY_FULLSCREEN: String = "fullscreen"


## True when the player chose the fullscreen window (default: windowed).
static func fullscreen_enabled() -> bool:
	return get_bool(KEY_FULLSCREEN)


## Saves the fullscreen choice and applies it to the window (see apply_window_mode).
static func set_fullscreen(on: bool) -> void:
	set_value(KEY_FULLSCREEN, on)
	apply_window_mode(on)


## Puts the main window in fullscreen (`on`) or windowed mode. No-op headless (no real window).
static func apply_window_mode(on: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var current: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	var is_full: bool = current == DisplayServer.WINDOW_MODE_FULLSCREEN or current == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if on and not is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not on and is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


## Story 026: true when the unlocked prestige card trim should be drawn (Options « Liseré de prestige », default on).
static func prestige_frame_enabled() -> bool:
	return get_bool(KEY_PRESTIGE_FRAME)
