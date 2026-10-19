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
	return card


## True if the card needs an enemy target to be played (derived from its damage).
func needs_target() -> bool:
	return damage > 0


## A copy of this card carried by another Pokémon (stolen cards, story 009).
func with_pokemon(pid: String) -> CardData:
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
	copy.pokemon_id = pid
	return copy


## Key grouping identical cards: card id + carrying Pokémon ("griffe@salameche"; just the id for skills).
func deck_key() -> String:
	return id if pokemon_id.is_empty() else "%s@%s" % [id, pokemon_id]


## "Griffe — Salamèche" when `pokemon_name` is given and the card has a Pokémon, else the plain name.
func display_label(pokemon_name: String = "") -> String:
	if pokemon_id.is_empty() or pokemon_name.is_empty():
		return display_name
	return "%s — %s" % [display_name, pokemon_name]
