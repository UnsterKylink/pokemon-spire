class_name StatusBook
extends RefCounted
## All status definitions (statuses.json). Injected into Battle; null/empty book = statuses disabled.

var _defs: Dictionary = {}  # id -> StatusData
var _order: Array[String] = []
## Anti-lock rule (statuses.json `aftermath_immunity`, optional; player only): when one of these statuses ends on the
## player's team, it becomes immune to ALL of them for `aftermath_turns` of its turns. Empty / 0 = no aftermath immunity.
var aftermath_statuses: Array[String] = []
var aftermath_turns: int = 0
## Display of the aftermath immunity chip (name / short / color / description; duration = aftermath_turns), or null.
var aftermath_display: StatusData = null


## Builds the book from the parsed statuses.json. Every invalid status is reported (push_error) and skipped;
## returns null if the file has no 'statuses' object or no valid status.
static func from_dict(root: Dictionary, known_types: Array[String] = []) -> StatusBook:
	var raw: Variant = root.get("statuses", null)
	if not (raw is Dictionary) or (raw as Dictionary).is_empty():
		push_error("StatusBook: statuses file needs a non-empty 'statuses' object")
		return null
	var book := StatusBook.new()
	var ok: bool = true
	for sid: String in (raw as Dictionary).keys():
		var def: Variant = (raw as Dictionary)[sid]
		var s: StatusData = StatusData.from_dict(sid, def, known_types) if def is Dictionary else null
		if s == null:
			push_error("StatusBook: status '%s' is invalid" % sid)
			ok = false
			continue
		book._defs[sid] = s
		book._order.append(sid)
	if ok and root.has("aftermath_immunity") and not book._parse_aftermath(root["aftermath_immunity"]):
		ok = false
	return book if ok else null


## Validates and stores `aftermath_immunity` {statuses: [ids of this book], turns: int >= 1, name, short, color, description}.
func _parse_aftermath(raw: Variant) -> bool:
	if not (raw is Dictionary):
		push_error("StatusBook: 'aftermath_immunity' must be an object")
		return false
	var d: Dictionary = raw
	var ids_raw: Variant = d.get("statuses", null)
	if not (ids_raw is Array) or (ids_raw as Array).is_empty():
		push_error("StatusBook: 'aftermath_immunity.statuses' must be a non-empty array of status ids")
		return false
	var ids_ok: Array[String] = []
	for sid: Variant in (ids_raw as Array):
		if not (sid is String) or not _defs.has(String(sid)):
			push_error("StatusBook: 'aftermath_immunity' references unknown status '%s'" % str(sid))
			return false
		ids_ok.append(String(sid))
	var turns: Variant = d.get("turns", null)
	if not ((turns is int or turns is float) and turns >= 1 and turns == floorf(turns)):
		push_error("StatusBook: 'aftermath_immunity.turns' must be an integer >= 1")
		return false
	for key: String in ["name", "short", "color", "description"]:
		if not (d.get(key, null) is String) or String(d[key]).is_empty():
			push_error("StatusBook: 'aftermath_immunity' needs a non-empty string '%s'" % key)
			return false
	if not String(d["color"]).is_valid_html_color():
		push_error("StatusBook: 'aftermath_immunity' has an invalid color")
		return false
	var disp := StatusData.new()
	disp.id = "aftermath_immunity"
	disp.display_name = String(d["name"])
	disp.short = String(d["short"])
	disp.color = Color.html(String(d["color"]))
	disp.description = String(d["description"])
	disp.duration = int(turns)
	aftermath_statuses = ids_ok
	aftermath_turns = int(turns)
	aftermath_display = disp
	return true


## True if the id is defined.
func has(status_id: String) -> bool:
	return _defs.has(status_id)


## The definition or null.
func get_def(status_id: String) -> StatusData:
	return _defs.get(status_id, null)


## Every status id in file order.
func ids() -> Array[String]:
	return _order.duplicate()


## Display name of a status ("" if unknown).
func name_of(status_id: String) -> String:
	return (_defs[status_id] as StatusData).display_name if _defs.has(status_id) else ""
