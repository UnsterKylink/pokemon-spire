class_name TypeChart
extends RefCounted
## Type table (data from assets/data/types.json) and the ONE central damage formula.
## Pure logic, no Node access. Implements: story-003-types.
## final damage = floori(base * multiplier(attack type vs defender type)), applied before block.

const KEY_SUPER: String = "super_effective"
const KEY_NOT_VERY: String = "not_very_effective"
const KEY_NEUTRAL: String = "neutral"

var _super_mult: float = 1.0
var _not_very_mult: float = 1.0
var _neutral_mult: float = 1.0
var _names: Dictionary = {}   # String -> String (French display name)
var _colors: Dictionary = {}  # String -> Color
var _type_ids: Array[String] = []
var _super: Dictionary = {}   # attacker id -> Dictionary(defender id -> true)
var _not_very: Dictionary = {}


## A chart with no types: every pair is neutral (x1). Used when no data is injected.
static func neutral_chart() -> TypeChart:
	return TypeChart.new()


## Builds and validates a chart from the parsed types.json. Returns null (after push_error) if invalid.
static func from_dict(root: Dictionary) -> TypeChart:
	var chart := TypeChart.new()
	var mult_v: Variant = root.get("multipliers", null)
	if not (mult_v is Dictionary):
		push_error("TypeChart: needs a 'multipliers' object")
		return null
	var mult: Dictionary = mult_v
	var parsed: Dictionary = {}
	for key: String in [KEY_SUPER, KEY_NOT_VERY, KEY_NEUTRAL]:
		var v: Variant = mult.get(key, null)
		if not (v is int or v is float) or float(v) <= 0.0:
			push_error("TypeChart: multiplier '%s' must be a number > 0" % key)
			return null
		parsed[key] = float(v)
	chart._super_mult = parsed[KEY_SUPER]
	chart._not_very_mult = parsed[KEY_NOT_VERY]
	chart._neutral_mult = parsed[KEY_NEUTRAL]

	var types_v: Variant = root.get("types", null)
	if not (types_v is Dictionary) or (types_v as Dictionary).is_empty():
		push_error("TypeChart: needs a non-empty 'types' object")
		return null
	var ok: bool = true
	var types: Dictionary = types_v
	for type_id: String in types.keys():
		var def_v: Variant = types[type_id]
		if not (def_v is Dictionary):
			push_error("TypeChart: type '%s' must be an object" % type_id)
			ok = false
			continue
		var def: Dictionary = def_v
		var name_v: Variant = def.get("name", null)
		var color_v: Variant = def.get("color", null)
		if not (name_v is String) or (name_v as String).is_empty():
			push_error("TypeChart: type '%s' needs a non-empty string 'name'" % type_id)
			ok = false
			continue
		if not (color_v is String) or not Color.html_is_valid(color_v):
			push_error("TypeChart: type '%s' needs a valid '#RRGGBB' 'color'" % type_id)
			ok = false
			continue
		chart._type_ids.append(type_id)
		chart._names[type_id] = name_v
		chart._colors[type_id] = Color.html(color_v)

	var chart_v: Variant = root.get("chart", null)
	if not (chart_v is Dictionary):
		push_error("TypeChart: needs a 'chart' object")
		return null
	var rows: Dictionary = chart_v
	for attacker: String in rows.keys():
		if not chart._names.has(attacker):
			push_error("TypeChart: chart references unknown attacking type '%s'" % attacker)
			ok = false
			continue
		var row_v: Variant = rows[attacker]
		if not (row_v is Dictionary):
			push_error("TypeChart: chart row '%s' must be an object" % attacker)
			ok = false
			continue
		var row: Dictionary = row_v
		var seen: Dictionary = {}  # defender -> list key, to reject duplicates and SE+NVE overlaps
		for list_key: String in [KEY_SUPER, KEY_NOT_VERY]:
			var list_v: Variant = row.get(list_key, [])
			if not (list_v is Array):
				push_error("TypeChart: '%s'.'%s' must be an array" % [attacker, list_key])
				ok = false
				continue
			var target: Dictionary = {}
			for defender: Variant in (list_v as Array):
				if not (defender is String) or not chart._names.has(defender):
					push_error("TypeChart: '%s'.'%s' references unknown type '%s'"
							% [attacker, list_key, str(defender)])
					ok = false
				elif seen.has(defender):
					push_error("TypeChart: '%s' lists defender '%s' more than once (in '%s' and '%s')"
							% [attacker, defender, seen[defender], list_key])
					ok = false
				else:
					seen[defender] = list_key
					target[defender] = true
			if list_key == KEY_SUPER:
				chart._super[attacker] = target
			else:
				chart._not_very[attacker] = target
	return chart if ok else null


## All known type ids, in file order.
func get_type_ids() -> Array[String]:
	return _type_ids.duplicate()


## True if the id is a type of this chart.
func is_known_type(type_id: String) -> bool:
	return _names.has(type_id)


## French display name of the type ("" if unknown).
func get_type_name(type_id: String) -> String:
	return _names.get(type_id, "")


## Display colour of the type (white if unknown).
func get_type_color(type_id: String) -> Color:
	return _colors.get(type_id, Color.WHITE)


## Damage multiplier of an attack of attack_type against a defender of defender_type.
## Empty or unknown types are neutral.
func damage_multiplier(attack_type: String, defender_type: String) -> float:
	if _super.has(attack_type) and (_super[attack_type] as Dictionary).has(defender_type):
		return _super_mult
	if _not_very.has(attack_type) and (_not_very[attack_type] as Dictionary).has(defender_type):
		return _not_very_mult
	return _neutral_mult


## THE damage formula: floori(base * multiplier). Strength must already be in `base`;
## block is applied afterwards by Combatant.take_damage.
func final_damage(base: int, attack_type: String, defender_type: String) -> int:
	return floori(float(maxi(base, 0)) * damage_multiplier(attack_type, defender_type))
