class_name GameData
extends RefCounted
## Loads and validates the JSON data files (cards, Pokémon). No gameplay value lives in code.

const DEFAULT_CARDS_PATH: String = "res://assets/data/cards.json"
const DEFAULT_POKEMON_PATH: String = "res://assets/data/pokemon.json"

var _cards: Dictionary = {}    # String -> CardData
var _players: Dictionary = {}  # String -> Dictionary (raw definition)
var _enemies: Dictionary = {}  # String -> Dictionary (raw definition)


## Loads both files. Returns false (after push_error) if anything is missing or invalid.
func load_all(cards_path: String = DEFAULT_CARDS_PATH, pokemon_path: String = DEFAULT_POKEMON_PATH) -> bool:
	_cards.clear()
	_players.clear()
	_enemies.clear()
	var cards_root: Dictionary = _read_json(cards_path)
	var pokemon_root: Dictionary = _read_json(pokemon_path)
	if cards_root.is_empty() or pokemon_root.is_empty():
		return false
	var ok: bool = true
	var cards_dict: Dictionary = cards_root.get("cards", {})
	for card_id: String in cards_dict.keys():
		var card: CardData = CardData.from_dict(card_id, cards_dict[card_id])
		if card == null:
			ok = false
		else:
			_cards[card_id] = card
	_players = pokemon_root.get("player", {})
	_enemies = pokemon_root.get("enemies", {})
	for pid: String in _players.keys():
		var def: Dictionary = _players[pid]
		for key: String in ["energy_per_turn", "hand_size", "starter_deck"]:
			if not def.has(key):
				push_error("GameData: player '%s' is missing field '%s'" % [pid, key])
				ok = false
		for card_id: String in Dictionary(def.get("starter_deck", {})).keys():
			if not _cards.has(card_id):
				push_error("GameData: player '%s' deck references unknown card '%s'" % [pid, card_id])
				ok = false
	for eid: String in _enemies.keys():
		if not _enemies[eid].has("attack_damage"):
			push_error("GameData: enemy '%s' is missing field 'attack_damage'" % eid)
			ok = false
	return ok


## Returns the card or null (with push_error) if the id is unknown.
func get_card(card_id: String) -> CardData:
	if not _cards.has(card_id):
		push_error("GameData: unknown card id '%s'" % card_id)
		return null
	return _cards[card_id]


## Builds a fresh player Combatant, or null if the id is unknown.
func create_player(player_id: String) -> Combatant:
	if not _players.has(player_id):
		push_error("GameData: unknown player id '%s'" % player_id)
		return null
	return Combatant.from_dict(player_id, _players[player_id])


## Builds a fresh enemy Combatant, or null if the id is unknown.
func create_enemy(enemy_id: String) -> Combatant:
	if not _enemies.has(enemy_id):
		push_error("GameData: unknown enemy id '%s'" % enemy_id)
		return null
	return Combatant.from_dict(enemy_id, _enemies[enemy_id])


## Expanded starter deck (one CardData per copy) for the given player.
func get_starter_deck(player_id: String) -> Array[CardData]:
	var deck: Array[CardData] = []
	if not _players.has(player_id):
		push_error("GameData: unknown player id '%s'" % player_id)
		return deck
	var counts: Dictionary = _players[player_id]["starter_deck"]
	for card_id: String in counts.keys():
		var card: CardData = get_card(card_id)
		if card == null:
			continue
		for i: int in int(counts[card_id]):
			deck.append(card)
	return deck


## Energy refilled at the start of each player turn.
func get_energy_per_turn(player_id: String) -> int:
	return int(_players.get(player_id, {}).get("energy_per_turn", 0))


## Number of cards drawn at the start of each player turn.
func get_hand_size(player_id: String) -> int:
	return int(_players.get(player_id, {}).get("hand_size", 0))


## Ids of all enemies defined in data.
func get_enemy_ids() -> Array[String]:
	var ids: Array[String] = []
	for k: String in _enemies.keys():
		ids.append(k)
	return ids


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("GameData: file not found: %s" % path)
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_error("GameData: invalid JSON in %s" % path)
		return {}
	return parsed
