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
	var intent := EnemyIntent.new()
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
	return copy


## French display text: "Attaque 7", "Protection 6", "Renforcement +2".
func display_text() -> String:
	match type:
		TYPE_ATTACK:
			return "Attaque %d" % value
		TYPE_BLOCK:
			return "Protection %d" % value
		TYPE_BUFF:
			return "Renforcement +%d" % value
	return ""
