class_name TalentBook
extends RefCounted
## Story 027: talents (assets/data/talents.json) and the Élan rules. Injected into Battle; a null book = no talents, no Élan.
## A talent fires when its Pokémon ENTERS the field (a card brings it in, or it is the starter at battle start).

var _talents: Dictionary = {}  # id -> {"name": String, "description": String, "effect": Dictionary (EffectSpec)}
var _order: Array[String] = []
## Primary type id -> talent id (the default talent of every Pokémon of that type).
var default_by_type: Dictionary = {}
## Pokémon id -> talent id (overrides kept in talents.json for Pokémon whose own file is generated).
var by_pokemon: Dictionary = {}
## True: a Pokémon's talent fires at most once per player turn (no switch ping-pong).
var once_per_turn: bool = true
## Élan: stacks gained per attack card of the already-active Pokémon, the cap, and the flat damage per stack on each hit.
var elan_gain_per_attack: int = 0
var elan_cap: int = 0
var elan_damage_per_stack: int = 0
## Player-facing keyword texts: keyword id -> {"name", "description"} (tooltips of the UI).
var keywords: Dictionary = {}


static func _is_int_ge(v: Variant, lo: int) -> bool:
	return (v is int or v is float) and float(v) >= float(lo) and float(v) == floorf(float(v))


## Builds the book from the parsed talents.json. `known_types` (when not empty) must all have a default talent;
## `status_book` (when not null) validates the statuses the talents apply. Returns null after push_error if invalid.
static func from_dict(root: Dictionary, known_types: Array[String] = [], status_book: StatusBook = null) -> TalentBook:
	var raw: Variant = root.get("talents", null)
	if not (raw is Dictionary) or (raw as Dictionary).is_empty():
		push_error("TalentBook: talents file needs a non-empty 'talents' object")
		return null
	var book := TalentBook.new()
	var ok: bool = true
	for tid: String in (raw as Dictionary).keys():
		var d: Variant = (raw as Dictionary)[tid]
		if not (d is Dictionary) or not ((d as Dictionary).get("name", null) is String) or String((d as Dictionary)["name"]).is_empty() \
				or not ((d as Dictionary).get("description", null) is String) or String((d as Dictionary)["description"]).is_empty():
			push_error("TalentBook: talent '%s' needs a non-empty 'name' and 'description'" % tid)
			ok = false
			continue
		var fx: Variant = EffectSpec.parse("talent '%s'" % tid, (d as Dictionary).get("effect", null))
		if fx == null or (fx as Dictionary).is_empty():
			push_error("TalentBook: talent '%s' needs a non-empty 'effect'" % tid)
			ok = false
			continue
		var bad: bool = false
		for a: Dictionary in (fx as Dictionary).get(EffectSpec.FIELD_APPLY, []):
			if String(a["to"]) == EffectSpec.TO_TARGET:
				push_error("TalentBook: talent '%s': a talent has no target (use all_enemies / random_enemy / self)" % tid)
				bad = true
			elif status_book != null and not status_book.has(String(a["status"])):
				push_error("TalentBook: talent '%s' applies unknown status '%s'" % [tid, String(a["status"])])
				bad = true
		if bad:
			ok = false
			continue
		book._talents[tid] = {"name": String((d as Dictionary)["name"]), "description": String((d as Dictionary)["description"]), "effect": fx}
		book._order.append(tid)
	var defaults: Variant = root.get("default_by_type", null)
	if not (defaults is Dictionary):
		push_error("TalentBook: talents file needs a 'default_by_type' object (type id -> talent id)")
		return null
	for t: String in (defaults as Dictionary).keys():
		if not ((defaults as Dictionary)[t] is String) or not book._talents.has(String((defaults as Dictionary)[t])):
			push_error("TalentBook: default_by_type '%s' names unknown talent '%s'" % [t, str((defaults as Dictionary)[t])])
			ok = false
		elif not known_types.is_empty() and t not in known_types:
			push_error("TalentBook: default_by_type has unknown type '%s'" % t)
			ok = false
		else:
			book.default_by_type[t] = String((defaults as Dictionary)[t])
	for t: String in known_types:
		if not book.default_by_type.has(t):
			push_error("TalentBook: default_by_type has no talent for type '%s'" % t)
			ok = false
	var overrides: Variant = root.get("by_pokemon", {})
	if not (overrides is Dictionary):
		push_error("TalentBook: 'by_pokemon' must be an object (pokemon id -> talent id)")
		return null
	for pid: String in (overrides as Dictionary).keys():
		if not ((overrides as Dictionary)[pid] is String) or not book._talents.has(String((overrides as Dictionary)[pid])):
			push_error("TalentBook: by_pokemon '%s' names unknown talent '%s'" % [pid, str((overrides as Dictionary)[pid])])
			ok = false
		else:
			book.by_pokemon[pid] = String((overrides as Dictionary)[pid])
	if root.has("talent_once_per_turn") and not (root["talent_once_per_turn"] is bool):
		push_error("TalentBook: 'talent_once_per_turn' must be a boolean")
		ok = false
	else:
		book.once_per_turn = bool(root.get("talent_once_per_turn", true))
	var elan: Variant = root.get("elan", {})
	if not (elan is Dictionary):
		push_error("TalentBook: 'elan' must be an object {gain_per_attack, cap, damage_per_stack}")
		return null
	for key: String in ["gain_per_attack", "cap", "damage_per_stack"]:
		if not _is_int_ge((elan as Dictionary).get(key, 0), 0):
			push_error("TalentBook: 'elan.%s' must be an integer >= 0" % key)
			ok = false
	if ok:
		book.elan_gain_per_attack = int((elan as Dictionary).get("gain_per_attack", 0))
		book.elan_cap = int((elan as Dictionary).get("cap", 0))
		book.elan_damage_per_stack = int((elan as Dictionary).get("damage_per_stack", 0))
	var kw: Variant = root.get("keywords", {})
	if not (kw is Dictionary):
		push_error("TalentBook: 'keywords' must be an object (keyword id -> {name, description})")
		return null
	for kid: String in (kw as Dictionary).keys():
		var k: Variant = (kw as Dictionary)[kid]
		if not (k is Dictionary) or not ((k as Dictionary).get("name", null) is String) or not ((k as Dictionary).get("description", null) is String):
			push_error("TalentBook: keyword '%s' needs 'name' and 'description'" % kid)
			ok = false
		else:
			book.keywords[kid] = {"name": String((k as Dictionary)["name"]), "description": String((k as Dictionary)["description"])}
	return book if ok else null


## True if the talent id is defined.
func has(talent_id: String) -> bool:
	return _talents.has(talent_id)


## Every talent id in file order.
func ids() -> Array[String]:
	return _order.duplicate()


## Display name ("" if unknown).
func name_of(talent_id: String) -> String:
	return String((_talents[talent_id] as Dictionary)["name"]) if _talents.has(talent_id) else ""


## Player-facing description ("" if unknown).
func description_of(talent_id: String) -> String:
	return String((_talents[talent_id] as Dictionary)["description"]) if _talents.has(talent_id) else ""


## The talent's effect (EffectSpec dictionary; {} if unknown).
func effect_of(talent_id: String) -> Dictionary:
	return (_talents[talent_id] as Dictionary)["effect"] if _talents.has(talent_id) else {}


## Talent id of a Pokémon: `explicit` (its own `talent` field) if known, else by_pokemon, else the default of its
## primary type; "" if none.
func talent_for(pokemon_id: String, explicit: String, types: Array[String]) -> String:
	if not explicit.is_empty() and _talents.has(explicit):
		return explicit
	if by_pokemon.has(pokemon_id):
		return String(by_pokemon[pokemon_id])
	if not types.is_empty() and default_by_type.has(types[0]):
		return String(default_by_type[types[0]])
	return ""
