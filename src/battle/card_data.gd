class_name CardData
extends RefCounted
## Immutable definition of a card, loaded from assets/data/cards.json.
## Implements: design/game-brief.md (MVP: combat à cartes), story-001, story-003 (type_id).

const KIND_ATTACK: String = "attack"
const KIND_SKILL: String = "skill"
const RARITY_STARTER: String = "starter"
const RARITY_COMMON: String = "common"
const RARITY_UNCOMMON: String = "uncommon"
const RARITY_RARE: String = "rare"
## Every rarity value a card may declare in cards.json (story 004).
const RARITIES: Array[String] = ["starter", "common", "uncommon", "rare"]

var id: String = ""
var display_name: String = ""
var cost: int = 0
var kind: String = KIND_ATTACK
var damage: int = 0
var block: int = 0
var description: String = ""
## Type id from types.json; empty for skill cards (they deal no damage).
var type_id: String = ""
## One of RARITIES (story 004); validated by GameData ("" if the file omits it).
var rarity: String = ""
## Pokémon carrying this card (id from pokemon.json); required for attacks, empty for skills (story 009).
var pokemon_id: String = ""
## True once improved at a Centre Pokémon (story 006): name gets a "+" suffix, stats are boosted. Once only.
var upgraded: bool = false
## Optional per-card improvement from cards.json ("upgrade": {damage, block, cost} deltas); {} = use the global rules.
var upgrade_override: Dictionary = {}
## Optional status inflicted on the target (statuses.json id + stack value); "" = none (story 016). Mentioned in `description`.
var status_id: String = ""
var status_value: int = 0


## Builds a CardData from a JSON dictionary. Returns null (and pushes an error) if invalid.
static func from_dict(card_id: String, d: Dictionary) -> CardData:
	for key: String in ["name", "cost", "kind", "damage", "block", "description"]:
		if not d.has(key):
			push_error("CardData: card '%s' is missing field '%s'" % [card_id, key])
			return null
	var kind_value: String = String(d["kind"])
	if kind_value != KIND_ATTACK and kind_value != KIND_SKILL:
		push_error("CardData: card '%s' has unknown kind '%s'" % [card_id, kind_value])
		return null
	if kind_value == KIND_SKILL and int(d["damage"]) > 0:
		push_error("CardData: skill card '%s' must not deal damage" % card_id)
		return null
	var card := CardData.new()
	card.id = card_id
	card.display_name = String(d["name"])
	card.cost = int(d["cost"])
	card.kind = kind_value
	card.damage = int(d["damage"])
	card.block = int(d["block"])
	card.description = String(d["description"])
	card.type_id = String(d.get("type", ""))
	card.rarity = String(d.get("rarity", ""))
	card.pokemon_id = String(d.get("pokemon", ""))
	var status_v: Variant = d.get("status", null)
	if status_v != null:
		var sv: Variant = (status_v as Dictionary).get("value", null) if status_v is Dictionary else null
		if not (status_v is Dictionary) or not ((status_v as Dictionary).get("id", null) is String) \
				or String((status_v as Dictionary)["id"]).is_empty() \
				or not (sv is int or sv is float) or float(sv) <= 0.0 or float(sv) != floorf(float(sv)):
			push_error("CardData: card '%s' has an invalid 'status' (expected {id, value>0})" % card_id)
			return null
		card.status_id = String((status_v as Dictionary)["id"])
		card.status_value = int(sv)
	var up: Variant = d.get("upgrade", {})
	if not (up is Dictionary) or not valid_upgrade_rule(up):
		push_error("CardData: card '%s' has an invalid 'upgrade' (expected {damage, block, cost} integers)" % card_id)
		return null
	card.upgrade_override = (up as Dictionary).duplicate()
	return card


## True if the card needs an enemy target to be played (derived from its damage, or a status to inflict).
func needs_target() -> bool:
	return damage > 0 or not status_id.is_empty()


## A copy of this card carried by another Pokémon (stolen cards, story 009).
func with_pokemon(pid: String) -> CardData:
	var copy: CardData = _copy()
	copy.pokemon_id = pid
	return copy


func _copy() -> CardData:
	var copy := CardData.new()
	copy.id = id
	copy.display_name = display_name
	copy.cost = cost
	copy.kind = kind
	copy.damage = damage
	copy.block = block
	copy.description = description
	copy.type_id = type_id
	copy.rarity = rarity
	copy.pokemon_id = pokemon_id
	copy.upgraded = upgraded
	copy.upgrade_override = upgrade_override
	copy.status_id = status_id
	copy.status_value = status_value
	return copy


## True if `rule` is a dictionary of integer deltas among damage / block / cost (cost <= 0 = cheaper).
static func valid_upgrade_rule(rule: Dictionary) -> bool:
	for k: Variant in rule.keys():
		if k not in ["damage", "block", "cost"]:
			return false
		var v: Variant = rule[k]
		if not ((v is int) or (v is float and v == floorf(v))):
			return false
	return true


## The improvement that applies to this card: its own "upgrade" if any, else rules[kind] (rules = GameData.get_upgrade_rules()).
func _rule(rules: Dictionary) -> Dictionary:
	return upgrade_override if not upgrade_override.is_empty() else (rules.get(kind, {}) as Dictionary)


## The upgraded copy of this card (name + "+", boosted damage/block, lower cost, description numbers updated),
## or null if already upgraded or the rule would change nothing.
func upgraded_copy(rules: Dictionary) -> CardData:
	if upgraded:
		return null
	var rule: Dictionary = _rule(rules)
	var new_damage: int = damage + (int(rule.get("damage", 0)) if damage > 0 else 0)
	var new_block: int = block + (int(rule.get("block", 0)) if block > 0 else 0)
	var new_cost: int = maxi(0, cost + int(rule.get("cost", 0)))
	if new_damage == damage and new_block == block and new_cost == cost:
		return null
	var copy: CardData = _copy()
	copy.upgraded = true
	copy.display_name = display_name + "+"
	copy.damage = new_damage
	copy.block = new_block
	copy.cost = new_cost
	# Prefer the "N dégâts" / "N points de protection" wording so a status value equal to the damage is not rewritten.
	if new_damage != damage:
		copy.description = _replace_number(copy.description, damage, new_damage, " dégâts")
	if new_block != block:
		copy.description = _replace_number(copy.description, block, new_block, " points de protection")
	return copy


static func _replace_number(text: String, old_n: int, new_n: int, suffix: String) -> String:
	if text.find(str(old_n) + suffix) >= 0:
		return text.replace(str(old_n) + suffix, str(new_n) + suffix)
	return text.replace(str(old_n), str(new_n))


## True if upgraded_copy(rules) would succeed.
func can_upgrade(rules: Dictionary) -> bool:
	return upgraded_copy(rules) != null


## Key grouping identical cards: card id + carrying Pokémon + upgrade ("griffe@salameche", "griffe@salameche+";
## just the id for plain skills). Upgraded and plain copies never merge.
func deck_key() -> String:
	var key: String = id if pokemon_id.is_empty() else "%s@%s" % [id, pokemon_id]
	return key + "+" if upgraded else key


## "Griffe — Salamèche" when `pokemon_name` is given and the card has a Pokémon, else the plain name.
func display_label(pokemon_name: String = "") -> String:
	if pokemon_id.is_empty() or pokemon_name.is_empty():
		return display_name
	return "%s — %s" % [display_name, pokemon_name]
