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
## Permanent stat modifiers (extra draw / energy): applied when the battle is created, no event.
const TRIGGER_PASSIVE: String = "passive"

## Effect types each trigger accepts (engine vocabulary, not gameplay values).
const EFFECTS_BY_TRIGGER: Dictionary = {
	"battle_start": ["heal_flat", "heal_percent_max", "block_flat"],
	"battle_end": ["heal_flat", "heal_percent_max", "money_bonus_on_win"],
	"turn_start": ["heal_flat", "heal_percent_max", "block_flat"],
	"turn_end": ["heal_flat", "heal_percent_max", "block_flat"],
	"card_played": ["damage_bonus"],
	"on_pickup": ["max_hp_up", "heal_flat", "heal_percent_max"],
	"passive": ["draw_up", "energy_up_per_turn", "status_immunity"],
}

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
	if t == "status_immunity" or t == "cure_status":  # {type, status: statuses.json id (cure_status also accepts "all")}
		var sid: Variant = e.get("status", null)
		if not (sid is String) or String(sid).is_empty() or (String(sid) == "all" and t == "status_immunity"):
			push_error("'%s': effect '%s' needs a 'status' id" % [owner_id, t])
			return false
		return true
	if t == "heal_percent_max":
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
