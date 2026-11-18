class_name ItemData
extends RefCounted
## Immutable definition of a held item (assets/data/items.json). Effects are GENERIC (trigger + effect list),
## there is no per-item code. Implements: story-006-objets-et-services, criterion 1.

const TRIGGER_BATTLE_START: String = "battle_start"
const TRIGGER_BATTLE_END: String = "battle_end"
const TRIGGER_TURN_START: String = "turn_start"
const TRIGGER_TURN_END: String = "turn_end"
const TRIGGER_CARD_PLAYED: String = "card_played"
const TRIGGER_ON_PICKUP: String = "on_pickup"
## Story 029: fires when an enemy dies (not captured) / when one of the player's cards is exhausted.
const TRIGGER_ON_KILL: String = "on_kill"
const TRIGGER_ON_EXHAUST: String = "on_exhaust"
## Permanent stat modifiers (extra draw / energy): applied when the battle is created, no event.
const TRIGGER_PASSIVE: String = "passive"

## Effect types each trigger accepts (engine vocabulary, not gameplay values).
const EFFECTS_BY_TRIGGER: Dictionary = {
	"battle_start": ["heal_flat", "heal_percent_max", "block_flat", "strength_start", "draw_first_turn", "energy_first_turn", "apply_all_enemies"],
	"battle_end": ["heal_flat", "heal_percent_max", "money_bonus_on_win"],
	"turn_start": ["heal_flat", "heal_percent_max", "block_flat"],
	"turn_end": ["heal_flat", "heal_percent_max", "block_flat"],
	"card_played": ["damage_bonus", "damage_bonus_type"],
	"on_pickup": ["max_hp_up", "heal_flat", "heal_percent_max", "add_ball"],
	"on_kill": ["heal_flat", "block_flat"],
	"on_exhaust": ["heal_flat", "block_flat"],
	"passive": ["draw_up", "energy_up_per_turn", "status_immunity", "first_type_card_free", "elan_cap_up", "elan_keep_percent",
			"talent_retrigger", "status_bonus", "exhaust_recycle", "block_keep", "capture_bonus", "max_potions_up"],
}
## Story 029: effects that need a status id ({status}); those that need a card type id ({card_type}); a ball id ({ball});
## flags without any number; effects whose number is a `percent` (0 < percent <= 100) instead of a `value`.
const STATUS_EFFECTS: Array[String] = ["status_immunity", "cure_status", "apply_all_enemies", "status_bonus"]
const TYPE_EFFECTS: Array[String] = ["damage_bonus_type", "first_type_card_free"]
const FLAG_EFFECTS: Array[String] = ["status_immunity", "cure_status", "talent_retrigger", "exhaust_recycle", "first_type_card_free"]
const PERCENT_EFFECTS: Array[String] = ["heal_percent_max", "elan_keep_percent", "block_keep"]

var id: String = ""
var display_name: String = ""
var description: String = ""
## One of CardData.RARITIES except "starter".
var rarity: String = ""
var trigger: String = ""
## Only for card_played: applies to the first attack card of each battle only.
var first_attack_each_battle: bool = false
## [{"type": String, "value": int} or {"type": "heal_percent_max", "percent": float}].
var effects: Array[Dictionary] = []
## Story 029: relative draw weight inside its rarity (items.json `weight`, default 1; e.g. berries are drawn less often).
var weight: float = 1.0


## Story 032: the card types this item is tied to (the `card_type` of its effects; empty for a generic item).
func card_types() -> Array[String]:
	var out: Array[String] = []
	for e: Dictionary in effects:
		var t: String = String(e.get("card_type", ""))
		if not t.is_empty() and not out.has(t):
			out.append(t)
	return out


## Builds an ItemData from a JSON dictionary; null (after push_error) if invalid.
static func from_dict(item_id: String, d: Dictionary) -> ItemData:
	for key: String in ["name", "description", "rarity", "trigger", "effects"]:
		if not d.has(key):
			push_error("ItemData: item '%s' is missing field '%s'" % [item_id, key])
			return null
	var item := ItemData.new()
	item.id = item_id
	item.display_name = String(d["name"])
	item.description = String(d["description"])
	item.rarity = String(d["rarity"])
	item.trigger = String(d["trigger"])
	item.first_attack_each_battle = bool(d.get("first_attack_each_battle", false))
	var wv: Variant = d.get("weight", 1.0)
	if not ((wv is int or wv is float) and wv > 0):
		push_error("ItemData: item '%s' has an invalid 'weight' (must be > 0)" % item_id)
		return null
	item.weight = float(wv)
	if item.rarity not in CardData.RARITIES or item.rarity == CardData.RARITY_STARTER:
		push_error("ItemData: item '%s' has invalid rarity '%s'" % [item_id, item.rarity])
		return null
	if not EFFECTS_BY_TRIGGER.has(item.trigger):
		push_error("ItemData: item '%s' has unknown trigger '%s'" % [item_id, item.trigger])
		return null
	if item.first_attack_each_battle and item.trigger != TRIGGER_CARD_PLAYED:
		push_error("ItemData: item '%s': first_attack_each_battle only applies to card_played" % item_id)
		return null
	var raw: Variant = d["effects"]
	if not (raw is Array) or (raw as Array).is_empty():
		push_error("ItemData: item '%s' needs a non-empty 'effects' array" % item_id)
		return null
	for e: Variant in (raw as Array):
		if not (e is Dictionary) or not validate_effect(item_id, e, EFFECTS_BY_TRIGGER[item.trigger]):
			return null
		item.effects.append((e as Dictionary).duplicate())
	return item


## Shared effect check (items and potions): known type among `allowed`, positive 'value' (or 0 < percent <= 100).
static func validate_effect(owner_id: String, e: Dictionary, allowed: Array) -> bool:
	var t: String = String(e.get("type", "")) if e.get("type", null) is String else ""
	if t not in allowed:
		push_error("'%s': effect type '%s' is not allowed here (allowed: %s)" % [owner_id, t, str(allowed)])
		return false
	if t in STATUS_EFFECTS:  # {type, status: statuses.json id (cure_status also accepts "all"), value for apply_all_enemies / status_bonus}
		var sid: Variant = e.get("status", null)
		if not (sid is String) or String(sid).is_empty() or (String(sid) == "all" and t != "cure_status"):
			push_error("'%s': effect '%s' needs a 'status' id" % [owner_id, t])
			return false
	if t in TYPE_EFFECTS:  # {type, card_type: types.json id, value for damage_bonus_type}
		var cid: Variant = e.get("card_type", null)
		if not (cid is String) or String(cid).is_empty():
			push_error("'%s': effect '%s' needs a 'card_type' id" % [owner_id, t])
			return false
	if t == "add_ball":  # {type, ball: balls.json id, value = number of balls}
		var bid: Variant = e.get("ball", null)
		if not (bid is String) or String(bid).is_empty():
			push_error("'%s': effect 'add_ball' needs a 'ball' id" % owner_id)
			return false
	if t in FLAG_EFFECTS:
		return true
	if t in PERCENT_EFFECTS:
		var p: Variant = e.get("percent", null)
		if not ((p is int or p is float) and p > 0 and p <= 100):
			push_error("'%s': effect '%s' needs 0 < percent <= 100" % [owner_id, t])
			return false
		return true
	var v: Variant = e.get("value", null)
	if not ((v is int or v is float) and v > 0 and v == floorf(v)):
		push_error("'%s': effect '%s' needs a positive integer 'value'" % [owner_id, t])
		return false
	return true


## Sum of 'value' over this item's effects of `effect_type` (0 if none).
func total(effect_type: String) -> int:
	var sum: int = 0
	for e: Dictionary in effects:
		if e["type"] == effect_type:
			sum += int(e["value"])
	return sum
