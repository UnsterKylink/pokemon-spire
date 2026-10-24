class_name EnemyIntent
extends RefCounted
## An enemy action: either a data definition (from pokemon.json "actions") or the
## concrete intent an enemy has rolled for its next turn (value includes strength).
## Implements: design/game-brief.md MVP feature 2, story-002-intentions-et-multi-ennemis.

const TYPE_ATTACK: String = "attack"
const TYPE_BLOCK: String = "block"
const TYPE_BUFF: String = "buff"

var type: String = TYPE_ATTACK
var value: int = 0
## Relative weight, only used by the "weighted" pattern (definitions only).
var weight: float = 1.0
## Attack value BEFORE the type multiplier (action value + strength); set when an intent is rolled so
## Battle.refresh_intents can recompute `value` when the active Pokémon changes (story 009).
var base_value: int = 0
## Optional status inflicted by an attack (statuses.json id + stack value); "" = none. Applied when the hit's type multiplier is > 0.
var status_id: String = ""
var status_value: int = 0
## Display name of status_id (set by Battle from the StatusBook; falls back to the id).
var status_label: String = ""
## Non-empty while the enemy will lose its turn (set by Battle, e.g. "Dort"): display_text() shows it instead of the action.
var skip_label: String = ""


## True if the given string is a known action type.
static func is_valid_type(action_type: String) -> bool:
	return action_type == TYPE_ATTACK or action_type == TYPE_BLOCK or action_type == TYPE_BUFF


## Builds an action from a JSON dictionary. Returns null (after push_error) if invalid.
static func from_dict(d: Dictionary) -> EnemyIntent:
	var type_value: Variant = d.get("type", null)
	if not (type_value is String) or not is_valid_type(type_value):
		push_error("EnemyIntent: unknown or missing action type '%s'" % str(type_value))
		return null
	var raw_value: Variant = d.get("value", null)
	if not (raw_value is int or raw_value is float) or float(raw_value) <= 0.0 \
			or float(raw_value) != floorf(float(raw_value)):
		push_error("EnemyIntent: action '%s' needs a positive integer 'value'" % type_value)
		return null
	var raw_weight: Variant = d.get("weight", 1)
	if not (raw_weight is int or raw_weight is float) or float(raw_weight) <= 0.0:
		push_error("EnemyIntent: action '%s' has an invalid 'weight' (must be > 0)" % type_value)
		return null
	var status_v: Variant = d.get("status", null)
	var intent := EnemyIntent.new()
	if status_v != null:
		if type_value != TYPE_ATTACK or not (status_v is Dictionary) or not ((status_v as Dictionary).get("id", null) is String) \
				or String((status_v as Dictionary)["id"]).is_empty():
			push_error("EnemyIntent: 'status' must be {id, value} and only applies to attack actions")
			return null
		var sv: Variant = (status_v as Dictionary).get("value", null)
		if not (sv is int or sv is float) or float(sv) <= 0.0 or float(sv) != floorf(float(sv)):
			push_error("EnemyIntent: action status needs a positive integer 'value'")
			return null
		intent.status_id = String((status_v as Dictionary)["id"])
		intent.status_value = int(sv)
	intent.type = type_value
	intent.value = int(raw_value)
	intent.weight = float(raw_weight)
	return intent


## Returns a copy of this action with value + bonus (used to add strength to attacks).
func with_bonus(bonus: int) -> EnemyIntent:
	var copy := EnemyIntent.new()
	copy.type = type
	copy.value = value + bonus
	copy.weight = weight
	copy.base_value = base_value
	copy.status_id = status_id
	copy.status_value = status_value
	copy.status_label = status_label
	return copy


## French display text: "Attaque 7", "Protection 6", "Renforcement +2".
## "Attaque 9 + Poison 3" when the attack inflicts a status; the skip label ("Dort") while the enemy loses its turn.
func display_text() -> String:
	if not skip_label.is_empty():
		return skip_label
	match type:
		TYPE_ATTACK:
			if not status_id.is_empty():
				return "Attaque %d + %s %d" % [value, status_label if not status_label.is_empty() else status_id, status_value]
			return "Attaque %d" % value
		TYPE_BLOCK:
			return "Protection %d" % value
		TYPE_BUFF:
			return "Renforcement +%d" % value
	return ""
