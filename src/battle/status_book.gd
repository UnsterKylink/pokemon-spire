class_name StatusBook
extends RefCounted
## All status definitions (statuses.json). Injected into Battle; null/empty book = statuses disabled.

var _defs: Dictionary = {}  # id -> StatusData
var _order: Array[String] = []


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
	return book if ok else null


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
