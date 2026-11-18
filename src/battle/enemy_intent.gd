class_name EnemyIntent
extends RefCounted
## An enemy action: either a data definition (from pokemon.json "actions") or the
## concrete intent an enemy has rolled for its next turn (value includes strength).
## Implements: design/game-brief.md MVP feature 2, story-002-intentions-et-multi-ennemis,
## story-030-ennemis-et-boss (status / heal / heal_ally / block_ally / charge / strip_block / drain_energy / add_junk,
## multi-hit attacks; documented in pokemon.json _enemies_doc).

const TYPE_ATTACK: String = "attack"
const TYPE_BLOCK: String = "block"
const TYPE_BUFF: String = "buff"
## Story 030. Inflicts `status` {id, value} on the player (value = the status value; `value` field optional).
const TYPE_STATUS: String = "status"
## Heals `value` HP to the enemy itself.
const TYPE_HEAL: String = "heal"
## Heals `value` HP / gives `value` block to the living enemy with the lowest HP ratio (itself included; leftmost on ties).
const TYPE_HEAL_ALLY: String = "heal_ally"
const TYPE_BLOCK_ALLY: String = "block_ally"
## Does nothing this turn, then the NEXT intent is an attack of `value` (optional attack_type) shown as « Attaque chargée ».
const TYPE_CHARGE: String = "charge"
## Removes up to `value` block from the player.
const TYPE_STRIP_BLOCK: String = "strip_block"
## The player starts its next turn with `value` less energy (never below the drain floor, see Battle.configure_enemy_mechanics).
const TYPE_DRAIN_ENERGY: String = "drain_energy"
## Shuffles `value` junk cards (« Débris », cards.json junk_cards) into the player's draw pile.
const TYPE_ADD_JUNK: String = "add_junk"
## Every valid action type.
const TYPES: Array[String] = ["attack", "block", "buff", "status", "heal", "heal_ally", "block_ally", "charge",
		"strip_block", "drain_energy", "add_junk"]

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
## Story 019: type id of an attack action (data key "attack_type"; "" = the enemy's primary type, resolved by Battle when
## the intent is rolled, so a rolled attack intent always carries its real type). Validated against types.json by GameData.
var attack_type: String = ""
## Story 019: display name of the attack type, set by Battle only for dual-typed enemies ("" = not shown).
var attack_type_label: String = ""
## Story 030: number of separate hits of an attack (each goes through the player's block); data key "hits" (default 1).
var hits: int = 1
## Story 030: true for the big attack released after a "charge" action (display « Attaque chargée »).
var charged: bool = false
## Non-empty while the enemy will lose its turn (set by Battle, e.g. "Dort"): display_text() shows it instead of the action.
var skip_label: String = ""


## True if the given string is a known action type.
static func is_valid_type(action_type: String) -> bool:
	return action_type in TYPES


## Builds an action from a JSON dictionary. Returns null (after push_error) if invalid.
static func from_dict(d: Dictionary) -> EnemyIntent:
	var type_value: Variant = d.get("type", null)
	if not (type_value is String) or not is_valid_type(type_value):
		push_error("EnemyIntent: unknown or missing action type '%s'" % str(type_value))
		return null
	var raw_value: Variant = d.get("value", null)
	var value_optional: bool = type_value == TYPE_STATUS
	if not (value_optional and raw_value == null) and (not (raw_value is int or raw_value is float) or float(raw_value) <= 0.0 \
			or float(raw_value) != floorf(float(raw_value))):
		push_error("EnemyIntent: action '%s' needs a positive integer 'value'" % type_value)
		return null
	var raw_weight: Variant = d.get("weight", 1)
	if not (raw_weight is int or raw_weight is float) or float(raw_weight) <= 0.0:
		push_error("EnemyIntent: action '%s' has an invalid 'weight' (must be > 0)" % type_value)
		return null
	var status_v: Variant = d.get("status", null)
	var intent := EnemyIntent.new()
	if type_value == TYPE_STATUS and status_v == null:
		push_error("EnemyIntent: a 'status' action needs 'status' {id, value}")
		return null
	if status_v != null:
		if (type_value != TYPE_ATTACK and type_value != TYPE_STATUS) or not (status_v is Dictionary) \
				or not ((status_v as Dictionary).get("id", null) is String) or String((status_v as Dictionary)["id"]).is_empty():
			push_error("EnemyIntent: 'status' must be {id, value} and only applies to attack / status actions")
			return null
		var sv: Variant = (status_v as Dictionary).get("value", null)
		if not (sv is int or sv is float) or float(sv) <= 0.0 or float(sv) != floorf(float(sv)):
			push_error("EnemyIntent: action status needs a positive integer 'value'")
			return null
		intent.status_id = String((status_v as Dictionary)["id"])
		intent.status_value = int(sv)
	var at_v: Variant = d.get("attack_type", null)
	if at_v != null:
		if (type_value != TYPE_ATTACK and type_value != TYPE_CHARGE) or not (at_v is String) or String(at_v).is_empty():
			push_error("EnemyIntent: 'attack_type' must be a type id and only applies to attack / charge actions")
			return null
		intent.attack_type = String(at_v)
	var hits_v: Variant = d.get("hits", null)
	if hits_v != null:
		if type_value != TYPE_ATTACK or not (hits_v is int or hits_v is float) or float(hits_v) < 1.0 \
				or float(hits_v) != floorf(float(hits_v)):
			push_error("EnemyIntent: 'hits' must be an integer >= 1 and only applies to attack actions")
			return null
		intent.hits = int(hits_v)
	intent.type = type_value
	intent.value = intent.status_value if raw_value == null else int(raw_value)
	intent.weight = float(raw_weight)
	return intent


## True for the actions whose `value` is damage dealt to the player (strength, burn, types and statuses apply).
func is_attack() -> bool:
	return type == TYPE_ATTACK


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
	copy.attack_type = attack_type
	copy.attack_type_label = attack_type_label
	copy.hits = hits
	copy.charged = charged
	return copy


## French display text, short: "Attaque 7", "Attaque 4×3", "Attaque 9 + Poison 3", "Attaque 9 (Eau)", "Protection 6",
## "Renforcement +2"; story 030: "Inflige Brûlure 3", "Soin 8", "Soigne allié 8", "Protège allié 6", "Charge…",
## "Attaque chargée 30", "Brise-garde 6", "Vol d'énergie 1", "Débris ×2"; the skip label ("Dort") while the enemy loses its turn.
func display_text() -> String:
	if not skip_label.is_empty():
		return skip_label
	var st: String = status_label if not status_label.is_empty() else status_id
	match type:
		TYPE_ATTACK:
			var suffix: String = " (%s)" % attack_type_label if not attack_type_label.is_empty() else ""
			var head: String = "Attaque chargée" if charged else "Attaque"
			var amount: String = "%d×%d" % [value, hits] if hits > 1 else str(value)
			if not status_id.is_empty():
				return "%s %s%s + %s %d" % [head, amount, suffix, st, status_value]
			return "%s %s%s" % [head, amount, suffix]
		TYPE_BLOCK:
			return "Protection %d" % value
		TYPE_BUFF:
			return "Renforcement +%d" % value
		TYPE_STATUS:
			return "Inflige %s %d" % [st, status_value]
		TYPE_HEAL:
			return "Soin %d" % value
		TYPE_HEAL_ALLY:
			return "Soigne allié %d" % value
		TYPE_BLOCK_ALLY:
			return "Protège allié %d" % value
		TYPE_CHARGE:
			return "Charge…"
		TYPE_STRIP_BLOCK:
			return "Brise-garde %d" % value
		TYPE_DRAIN_ENERGY:
			return "Vol d'énergie %d" % value
		TYPE_ADD_JUNK:
			return "Débris ×%d" % value
	return ""
