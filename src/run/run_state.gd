class_name RunState
extends RefCounted
## The player's persistent state for one run (HP and deck survive from battle to battle).
## Pure logic, no Node access. Implements: story-004-recompenses-vol-attaque, criterion 4.

var player_id: String = ""
var display_name: String = ""
var type_id: String = ""
var sprite_path: String = ""
var max_hp: int = 1
var hp: int = 1
var energy_per_turn: int = 0
var hand_size: int = 0
## The run's own copy of the deck (never the shared starter definition).
var deck: Array[CardData] = []
var battles_won: int = 0


## Starts a run from the player's data: full HP, starter deck copy. Null if the id is unknown.
static func create(data: GameData, new_player_id: String) -> RunState:
	var def: Dictionary = data.get_player_definition(new_player_id)
	if def.is_empty():
		return null
	var r := RunState.new()
	r.player_id = new_player_id
	r.display_name = String(def.get("name", ""))
	r.type_id = String(def.get("type", ""))
	r.sprite_path = String(def.get("sprite", ""))
	r.max_hp = int(def.get("max_hp", 1))
	r.hp = r.max_hp
	r.energy_per_turn = int(def.get("energy_per_turn", 0))
	r.hand_size = int(def.get("hand_size", 0))
	r.deck = data.get_starter_deck(new_player_id)  # fresh array each call
	return r


## Adds a reward card to the deck.
func add_card(card: CardData) -> void:
	if card != null:
		deck.append(card)


## A fresh player Combatant with the persisted HP (block 0).
func build_player_combatant() -> Combatant:
	var c := Combatant.new()
	c.id = player_id
	c.display_name = display_name
	c.sprite_path = sprite_path
	c.type_id = type_id
	c.max_hp = max_hp
	c.hp = clampi(hp, 0, max_hp)
	return c


## Builds a battle from the persisted state; the battle gets a COPY of the deck.
func create_battle(enemies: Array[Combatant], type_chart: TypeChart, rng: RandomNumberGenerator) -> Battle:
	return Battle.new(build_player_combatant(), enemies, deck.duplicate(), energy_per_turn, hand_size, rng, type_chart)


## Copies the player's HP back after a battle (clamped 0..max_hp). A surviving player = a battle won.
func record_battle_result(player: Combatant) -> void:
	hp = clampi(player.hp, 0, max_hp)
	if hp > 0:
		battles_won += 1


## card id -> copies in the deck.
func deck_counts() -> Dictionary:
	var counts: Dictionary = {}
	for c: CardData in deck:
		counts[c.id] = int(counts.get(c.id, 0)) + 1
	return counts


## Deck grouped for display: [{"card": CardData, "count": int}], sorted by card name.
func get_deck_entries() -> Array[Dictionary]:
	var by_id: Dictionary = {}
	var entries: Array[Dictionary] = []
	for c: CardData in deck:
		if by_id.has(c.id):
			by_id[c.id]["count"] = int(by_id[c.id]["count"]) + 1
		else:
			var e: Dictionary = {"card": c, "count": 1}
			by_id[c.id] = e
			entries.append(e)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["card"] as CardData).display_name.naturalnocasecmp_to((b["card"] as CardData).display_name) < 0)
	return entries
