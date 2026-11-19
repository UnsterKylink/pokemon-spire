class_name KeywordBook
extends RefCounted
## Story 023: texts of the battle hover tooltips (assets/data/keywords.json): enemy intents, battle UI elements (energy,
## field / zone rule, talent, switch) and the type-pill effectiveness summary built from the TypeChart. Static, cached,
## read only. Every function returns KeywordTooltip entries: [{name, description}].

const PATH: String = "res://assets/data/keywords.json"

static var _root: Dictionary = {}
static var _loaded: bool = false


## The parsed file ({} when missing / invalid).
static func data() -> Dictionary:
	if not _loaded:
		_loaded = true
		var f: FileAccess = FileAccess.open(PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			f.close()
			if parsed is Dictionary:
				_root = parsed
			else:
				push_error("KeywordBook: %s is not a JSON object" % PATH)
	return _root


## One entry of section `section` ("intents" | "ui") by `id`; {} when absent.
static func entry(section: String, id: String) -> Dictionary:
	var sec: Variant = data().get(section, {})
	var e: Variant = (sec as Dictionary).get(id, {}) if sec is Dictionary else {}
	if not (e is Dictionary) or (e as Dictionary).is_empty():
		return {}
	return {"name": String((e as Dictionary).get("name", id)), "description": String((e as Dictionary).get("description", ""))}


## Tooltip entries of an enemy `intent` (skip / charged / multi-hit variants, + the inflicted status from `statuses`).
## `alive` false = the K.O. entry.
static func intent_entries(intent: EnemyIntent, statuses: StatusBook, alive: bool = true) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not alive:
		_append(out, entry("intents", "ko"))
		return out
	if intent == null:
		return out
	if not intent.skip_label.is_empty():
		_append(out, entry("intents", "skip"))
		return out
	if intent.type == EnemyIntent.TYPE_ATTACK:
		_append(out, entry("intents", "attack_charged" if intent.charged else "attack"))
		if intent.hits > 1:
			_append(out, entry("intents", "attack_multi"))
	else:
		_append(out, entry("intents", intent.type))
	if not intent.status_id.is_empty() and statuses != null:
		var def: StatusData = statuses.get_def(intent.status_id)
		if def != null:
			out.append({"name": def.display_name, "description": def.description})
	return out


## Tooltip entry of a status chip (`def` from statuses.json).
static func status_entries(def: StatusData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if def != null:
		out.append({"name": def.display_name, "description": def.description})
	return out


## Effectiveness summary of type `type_id`: « Super efficace contre : … », « Peu efficace contre : … », « Sans effet
## contre : … » (as an attack type) and « En défense, craint : … » (empty lines are left out).
static func type_entries(type_id: String, chart: TypeChart) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if chart == null or not chart.is_known_type(type_id):
		return out
	var t: Dictionary = data().get("type", {}) if data().get("type", {}) is Dictionary else {}
	var sep: String = String(t.get("separator", ", "))
	var strong: PackedStringArray = PackedStringArray()
	var weak: PackedStringArray = PackedStringArray()
	var immune: PackedStringArray = PackedStringArray()
	var fears: PackedStringArray = PackedStringArray()
	for other: String in chart.get_type_ids():
		var m: float = chart.damage_multiplier_vs(type_id, other)
		var other_name: String = chart.get_type_name(other)
		if m <= 0.0:
			immune.append(other_name)
		elif m > 1.0:
			strong.append(other_name)
		elif m < 1.0:
			weak.append(other_name)
		if chart.damage_multiplier_vs(other, type_id) > 1.0:
			fears.append(other_name)
	var lines: PackedStringArray = PackedStringArray()
	for pair: Array in [["super", strong], ["weak", weak], ["immune", immune], ["fears", fears]]:
		var names: PackedStringArray = pair[1]
		if not names.is_empty() and t.has(pair[0]):
			lines.append(String(t[pair[0]]) % sep.join(names))
	out.append({"name": String(t.get("name", "%s")) % chart.get_type_name(type_id), "description": "\n".join(lines)})
	return out


static func _append(out: Array[Dictionary], e: Dictionary) -> void:
	if not e.is_empty():
		out.append(e)
