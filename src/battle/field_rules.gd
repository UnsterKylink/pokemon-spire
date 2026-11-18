class_name FieldRules
extends RefCounted
## Story 030 (story-030-ennemis-et-boss): vocabulary of the field rules ("règles de terrain") of gym Champions, Conseil 4
## members, the Maître and Éthernatos's phases. A rule (assets/data/field_rules.json `rules`) is
## {id, name (FR), description (FR), effects: [{type, ...}]}; Battle.set_field_rule applies it. Every number is data.
## Per-turn effects take an optional `every` (>= 1, default 1): they fire on the player turns whose number is a multiple of it.

## Each living enemy gains `value` block at the start of every player turn.
const ENEMY_BLOCK_PER_TURN: String = "enemy_block_per_turn"
## Each living enemy gains `value` strength before its intents of the coming turn are rolled (every `every` turns).
const ENEMY_STRENGTH_PER_TURN: String = "enemy_strength_per_turn"
## Each living enemy heals `value` HP at the start of every player turn.
const ENEMY_HEAL_PER_TURN: String = "enemy_heal_per_turn"
## Each enemy starts the battle with `value` block.
const ENEMY_START_BLOCK: String = "enemy_start_block"
## The player receives `status` x `value` at the start of the player turn (every `every` turns; immunities apply).
const PLAYER_STATUS_EACH_TURN: String = "player_status_each_turn"
## The player receives `status` x `value` when the battle starts (immunities apply).
const PLAYER_STATUS_START: String = "player_status_start"
## The player loses `value` HP (ignores block, never K.O.: leaves at least 1 HP) at the start of every player turn.
const PLAYER_HP_LOSS_PER_TURN: String = "player_hp_loss_per_turn"
## The first card played each turn costs `value` more energy.
const FIRST_CARD_COST_UP: String = "first_card_cost_up"
## After the draw (every `every` turns), the costliest card of the hand (leftmost on ties) burns: it goes to the exhaust pile.
const BURN_COSTLIEST_CARD: String = "burn_costliest_card"
## The player draws `value` fewer cards each turn (always at least 1).
const PLAYER_DRAW_DOWN: String = "player_draw_down"
## Every attack (player card or enemy) of type `type` gets +`value` damage per hit before the multipliers.
const TYPE_DAMAGE_UP: String = "type_damage_up"
## `value` junk cards (« Débris ») are shuffled into the player's draw pile before the draw (every `every` turns).
const JUNK_EACH_TURN: String = "junk_each_turn"

## Every effect type, and the ones that need `value` (> 0 int).
const TYPES: Array[String] = [ENEMY_BLOCK_PER_TURN, ENEMY_STRENGTH_PER_TURN, ENEMY_HEAL_PER_TURN, ENEMY_START_BLOCK,
		PLAYER_STATUS_EACH_TURN, PLAYER_STATUS_START, PLAYER_HP_LOSS_PER_TURN, FIRST_CARD_COST_UP, BURN_COSTLIEST_CARD,
		PLAYER_DRAW_DOWN, TYPE_DAMAGE_UP, JUNK_EACH_TURN]
const NO_VALUE: Array[String] = [BURN_COSTLIEST_CARD]
const WITH_STATUS: Array[String] = [PLAYER_STATUS_EACH_TURN, PLAYER_STATUS_START]


## Error message for a rule definition ("" if valid). `status_ids` / `type_ids` = known ids (empty = not checked).
static func check_rule(rule_id: String, d: Variant, status_ids: Array[String] = [], type_ids: Array[String] = []) -> String:
	if not (d is Dictionary):
		return "field rule '%s' must be an object" % rule_id
	var r: Dictionary = d
	if not (r.get("name", null) is String) or not (r.get("description", null) is String) or String(r["name"]).is_empty():
		return "field rule '%s' needs a 'name' and a 'description' (strings)" % rule_id
	if r.has("scope") and String(r["scope"]) not in ["", SCOPE_ZONE]:
		return "field rule '%s': 'scope' must be \"zone\" or absent" % rule_id
	var fx_v: Variant = r.get("effects", null)
	if not (fx_v is Array) or (fx_v as Array).is_empty():
		return "field rule '%s' needs a non-empty 'effects' array" % rule_id
	for fx: Variant in (fx_v as Array):
		var err: String = check_effect(fx, status_ids, type_ids)
		if not err.is_empty():
			return "field rule '%s': %s" % [rule_id, err]
	return ""


## Error message for one effect ("" if valid).
static func check_effect(fx_v: Variant, status_ids: Array[String] = [], type_ids: Array[String] = []) -> String:
	if not (fx_v is Dictionary):
		return "an effect must be an object"
	var fx: Dictionary = fx_v
	var t: String = String(fx.get("type", ""))
	if t not in TYPES:
		return "unknown effect type '%s'" % t
	if t not in NO_VALUE and not _pos_int(fx.get("value", null)):
		return "effect '%s' needs a positive integer 'value'" % t
	if fx.has("every") and not _pos_int(fx["every"]):
		return "effect '%s': 'every' must be an integer >= 1" % t
	if t in WITH_STATUS:
		var sid: Variant = fx.get("status", null)
		if not (sid is String) or (not status_ids.is_empty() and sid not in status_ids):
			return "effect '%s' needs a known 'status' id" % t
	if t == TYPE_DAMAGE_UP:
		var tid: Variant = fx.get("of_type", null)
		if not (tid is String) or (not type_ids.is_empty() and tid not in type_ids):
			return "effect '%s' needs a known 'of_type' type id" % t
	return ""


## Story 032: rule `scope` of the light zone rules (UI: « Zone : <nom> » / « Règle de zone ») ; "" = gym / league / boss
## rule (« Règle de terrain »).
const SCOPE_ZONE: String = "zone"


## Public summary of a rule for the UI: {id, name, description, scope} ({} for no rule).
static func summary(rule: Dictionary) -> Dictionary:
	if rule.is_empty():
		return {}
	return {"id": String(rule.get("id", "")), "name": String(rule.get("name", "")), "description": String(rule.get("description", "")),
			"scope": String(rule.get("scope", ""))}


static func _pos_int(v: Variant) -> bool:
	return (v is int or v is float) and float(v) >= 1.0 and float(v) == floorf(float(v))
