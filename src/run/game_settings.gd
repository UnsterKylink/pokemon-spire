class_name GameSettings
extends RefCounted
## Player options saved in user://settings.json (shared with the animation speed of BattleFxDirector).
## Read / write are static and never fail loudly: a missing or broken file gives the defaults.

const PATH: String = "user://settings.json"
## Show a light green / red tint on targets when the selected attack is super / not very effective.
const KEY_TYPE_HINTS: String = "type_hints"
const DEFAULTS: Dictionary = {KEY_TYPE_HINTS: true}


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
