class_name PotionData
extends RefCounted
## Immutable definition of a single-use potion (assets/data/potions.json). Used during the player's turn
## via Battle.use_potion. Implements: story-006-objets-et-services, criterion 2.

const EFFECT_TYPES: Array = ["heal_flat", "heal_percent_max", "block_flat", "energy_gain", "draw_cards", "damage_bonus_turn"]

var id: String = ""
var display_name: String = ""
var description: String = ""
## Pokédollars at the Poké Mart.
var price: int = 0
var effects: Array[Dictionary] = []


## Builds a PotionData from JSON; null (after push_error) if invalid.
static func from_dict(potion_id: String, d: Dictionary) -> PotionData:
	for key: String in ["name", "description", "price", "effects"]:
		if not d.has(key):
			push_error("PotionData: potion '%s' is missing field '%s'" % [potion_id, key])
			return null
	var p := PotionData.new()
	p.id = potion_id
	p.display_name = String(d["name"])
	p.description = String(d["description"])
	var price_v: Variant = d["price"]
	if not ((price_v is int or price_v is float) and price_v >= 0):
		push_error("PotionData: potion '%s' needs a price >= 0" % potion_id)
		return null
	p.price = int(price_v)
	var raw: Variant = d["effects"]
	if not (raw is Array) or (raw as Array).is_empty():
		push_error("PotionData: potion '%s' needs a non-empty 'effects' array" % potion_id)
		return null
	for e: Variant in (raw as Array):
		if not (e is Dictionary) or not ItemData.validate_effect(potion_id, e, EFFECT_TYPES):
			return null
		p.effects.append((e as Dictionary).duplicate())
	return p
