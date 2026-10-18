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
	return card


## True if the card needs an enemy target to be played (derived from its damage).
func needs_target() -> bool:
	return damage > 0
