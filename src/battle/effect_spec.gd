class_name EffectSpec
extends RefCounted
## Story 027: the small data grammar shared by cards (cards.json) and talents (talents.json).
## An EFFECT is a dictionary of optional fields (absent = no effect):
##   block, heal, draw, energy            integers >= 1
##   strength (Force for the battle), strength_turn (Force until the end of the turn)
##   next_attack_bonus (flat damage added to every hit of the next attack card)
##   self_damage (HP the player loses, ignores block, never K.O.)
##   block_per_enemy (block gained per living enemy)
##   apply: [{status: id of statuses.json, value: int >= 1, to: target|all_enemies|random_enemy|self}]
##   damage, hits (ONLY inside a card conditional `then`): extra damage per hit / extra hits
## A CONDITION is a string or a one-key object:
##   "carrier_was_active" | "carrier_entered" | "super_effective" | "first_card_of_turn"
##   {"target_has_status": "any" | status id} | {"target_hp_below": fraction 0..1} | {"elan_at_least": int >= 1}
## All parsing is static and pure: invalid data is reported with push_error and rejected (never a crash).

const INT_FIELDS: Array[String] = ["block", "heal", "draw", "energy", "strength", "strength_turn", "next_attack_bonus",
		"self_damage", "block_per_enemy"]
const DAMAGE_FIELDS: Array[String] = ["damage", "hits"]
const FIELD_APPLY: String = "apply"
const TO_TARGET: String = "target"
const TO_ALL: String = "all_enemies"
const TO_RANDOM: String = "random_enemy"
const TO_SELF: String = "self"
const APPLY_TARGETS: Array[String] = ["target", "all_enemies", "random_enemy", "self"]
const COND_WAS_ACTIVE: String = "carrier_was_active"
const COND_ENTERED: String = "carrier_entered"
const COND_SUPER_EFFECTIVE: String = "super_effective"
const COND_FIRST_CARD: String = "first_card_of_turn"
const COND_TARGET_STATUS: String = "target_has_status"
const COND_TARGET_HP_BELOW: String = "target_hp_below"
const COND_ELAN: String = "elan_at_least"
const SIMPLE_CONDITIONS: Array[String] = ["carrier_was_active", "carrier_entered", "super_effective", "first_card_of_turn"]
const ARG_CONDITIONS: Array[String] = ["target_has_status", "target_hp_below", "elan_at_least"]
## Conditions that only make sense on a card with a carrier Pokémon (attack cards).
const CARRIER_CONDITIONS: Array[String] = ["carrier_was_active", "carrier_entered"]
## Conditions that look at the targeted enemy.
const TARGET_CONDITIONS: Array[String] = ["super_effective", "target_has_status", "target_hp_below"]
const ANY_STATUS: String = "any"


static func _is_pos_int(v: Variant) -> bool:
	return (v is int or v is float) and float(v) >= 1.0 and float(v) == floorf(float(v))


## Parses an effect object. `only` (when not empty) restricts which keys of `raw` are read (the others are ignored: used
## to pick the effect fields out of a whole card definition); otherwise an unknown key is an error.
## Returns the normalised effect, or null after push_error.
static func parse(label: String, raw: Variant, allow_damage: bool = false, only: Array[String] = []) -> Variant:
	if not (raw is Dictionary):
		push_error("EffectSpec: %s: an effect must be an object" % label)
		return null
	var out: Dictionary = {}
	for key_v: Variant in (raw as Dictionary).keys():
		var key: String = String(key_v)
		if not only.is_empty() and key not in only:
			continue
		var v: Variant = (raw as Dictionary)[key_v]
		if key in INT_FIELDS or (allow_damage and key in DAMAGE_FIELDS):
			if not _is_pos_int(v):
				push_error("EffectSpec: %s: '%s' must be an integer >= 1" % [label, key])
				return null
			out[key] = int(v)
		elif key == FIELD_APPLY:
			var list: Variant = _parse_apply(label, v)
			if list == null:
				return null
			out[key] = list
		else:
			push_error("EffectSpec: %s: unknown effect field '%s'" % [label, key])
			return null
	return out


static func _parse_apply(label: String, raw: Variant) -> Variant:
	var items: Array = raw if raw is Array else [raw]
	var out: Array[Dictionary] = []
	for it: Variant in items:
		if not (it is Dictionary) or not ((it as Dictionary).get("status", null) is String) \
				or String((it as Dictionary)["status"]).is_empty() or not _is_pos_int((it as Dictionary).get("value", null)):
			push_error("EffectSpec: %s: 'apply' entries must be {status, value >= 1, to}" % label)
			return null
		var to: String = String((it as Dictionary).get("to", TO_TARGET))
		if to not in APPLY_TARGETS:
			push_error("EffectSpec: %s: 'apply.to' must be one of %s (has '%s')" % [label, str(APPLY_TARGETS), to])
			return null
		out.append({"status": String((it as Dictionary)["status"]), "value": int((it as Dictionary)["value"]), "to": to})
	return out


## Parses a condition into {"type": String, "arg": Variant}; {} after push_error if invalid.
static func parse_condition(label: String, raw: Variant) -> Dictionary:
	if raw is String:
		if String(raw) in SIMPLE_CONDITIONS:
			return {"type": String(raw), "arg": null}
		if String(raw) == COND_TARGET_STATUS:
			return {"type": COND_TARGET_STATUS, "arg": ANY_STATUS}
		push_error("EffectSpec: %s: unknown condition '%s'" % [label, String(raw)])
		return {}
	if raw is Dictionary and (raw as Dictionary).size() == 1:
		var key: String = String((raw as Dictionary).keys()[0])
		var arg: Variant = (raw as Dictionary).values()[0]
		if key in SIMPLE_CONDITIONS:
			return {"type": key, "arg": null}
		match key:
			COND_TARGET_STATUS:
				if arg is String and not String(arg).is_empty():
					return {"type": key, "arg": String(arg)}
			COND_TARGET_HP_BELOW:
				if (arg is int or arg is float) and float(arg) > 0.0 and float(arg) <= 1.0:
					return {"type": key, "arg": float(arg)}
			COND_ELAN:
				if _is_pos_int(arg):
					return {"type": key, "arg": int(arg)}
		push_error("EffectSpec: %s: invalid condition %s" % [label, str(raw)])
		return {}
	push_error("EffectSpec: %s: a condition is a string or a one-key object" % label)
	return {}


## Parses `conditional` (one {"if", "then"} object or an array of them). Returns Array[Dictionary] of
## {"if": {type, arg}, "then": effect}, or null after push_error.
static func parse_conditionals(label: String, raw: Variant, is_attack: bool) -> Variant:
	var items: Array = raw if raw is Array else [raw]
	var out: Array[Dictionary] = []
	for it: Variant in items:
		if not (it is Dictionary) or not (it as Dictionary).has("if") or not (it as Dictionary).has("then"):
			push_error("EffectSpec: %s: a conditional must be {\"if\": condition, \"then\": effect}" % label)
			return null
		var cond: Dictionary = parse_condition(label, (it as Dictionary)["if"])
		if cond.is_empty():
			return null
		if not is_attack and String(cond["type"]) in CARRIER_CONDITIONS:
			push_error("EffectSpec: %s: condition '%s' needs a carrier Pokémon (attack cards only)" % [label, String(cond["type"])])
			return null
		var then: Variant = parse(label + " (then)", (it as Dictionary)["then"], is_attack)
		if then == null or (then as Dictionary).is_empty():
			push_error("EffectSpec: %s: 'then' must be a non-empty effect" % label)
			return null
		out.append({"if": cond, "then": then})
	return out


## Status ids an effect applies (for validation against statuses.json).
static func status_ids(fx: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for a: Dictionary in fx.get(FIELD_APPLY, []):
		out.append(String(a["status"]))
	return out


## True if the effect applies a status to the card's target (the card then needs a target).
static func needs_target(fx: Dictionary) -> bool:
	for a: Dictionary in fx.get(FIELD_APPLY, []):
		if String(a["to"]) == TO_TARGET:
			return true
	return false
