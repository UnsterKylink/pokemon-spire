class_name GameData
extends RefCounted
## Loads and validates the JSON data files (cards, Pokémon, encounters). No gameplay value lives in code.

const DEFAULT_CARDS_PATH: String = "res://assets/data/cards.json"
const DEFAULT_POKEMON_PATH: String = "res://assets/data/pokemon.json"

var _cards: Dictionary = {}    # String -> CardData
var _players: Dictionary = {}  # String -> Dictionary (raw definition)
var _enemies: Dictionary = {}  # String -> Dictionary (raw definition)
var _encounters: Dictionary = {}  # String -> Array (enemy ids)
var _encounter_order: Array[String] = []


## Loads both files. Returns false (after push_error) if anything is missing or invalid.
func load_all(cards_path: String = DEFAULT_CARDS_PATH, pokemon_path: String = DEFAULT_POKEMON_PATH) -> bool:
	_cards.clear()
	_players.clear()
	_enemies.clear()
	_encounters.clear()
	_encounter_order.clear()
	var cards_root: Dictionary = _read_json(cards_path)
	var pokemon_root: Dictionary = _read_json(pokemon_path)
	if cards_root.is_empty() or pokemon_root.is_empty():
		return false
	var ok: bool = true
	ok = _load_cards(cards_root) and ok
	ok = _load_players(pokemon_root) and ok
	ok = _load_enemies(pokemon_root) and ok
	ok = _load_encounters(pokemon_root) and ok
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


## Builds fresh enemy Combatants (left to right) for an encounter. Empty if the id is unknown.
func create_enemies(encounter_id: String) -> Array[Combatant]:
	var result: Array[Combatant] = []
	if not _encounters.has(encounter_id):
		push_error("GameData: unknown encounter id '%s'" % encounter_id)
		return result
	var ids: Array = _encounters[encounter_id]
	for enemy_id: String in ids:
		var enemy: Combatant = create_enemy(enemy_id)
		if enemy == null:
			result.clear()
			return result
		result.append(enemy)
	return result


## Encounter ids in the order they are played.
func get_encounter_order() -> Array[String]:
	return _encounter_order.duplicate()


## Expanded starter deck (one CardData per copy) for the given player.
func get_starter_deck(player_id: String) -> Array[CardData]:
	var deck: Array[CardData] = []
	if not _players.has(player_id):
		push_error("GameData: unknown player id '%s'" % player_id)
		return deck
	var player_def: Dictionary = _players[player_id]
	var counts: Dictionary = player_def["starter_deck"]
	for card_id: String in counts.keys():
		var card: CardData = get_card(card_id)
		if card == null:
			continue
		for i: int in int(counts[card_id]):
			deck.append(card)
	return deck


## Energy refilled at the start of each player turn.
func get_energy_per_turn(player_id: String) -> int:
	var def: Dictionary = _players.get(player_id, {})
	return int(def.get("energy_per_turn", 0))


## Number of cards drawn at the start of each player turn.
func get_hand_size(player_id: String) -> int:
	var def: Dictionary = _players.get(player_id, {})
	return int(def.get("hand_size", 0))


## Ids of all enemies defined in data.
func get_enemy_ids() -> Array[String]:
	var ids: Array[String] = []
	for k: String in _enemies.keys():
		ids.append(k)
	return ids


# --- Loading / validation --------------------------------------------------

func _load_cards(cards_root: Dictionary) -> bool:
	var raw: Variant = cards_root.get("cards", null)
	if not (raw is Dictionary):
		push_error("GameData: cards file needs a 'cards' object")
		return false
	var ok: bool = true
	var cards_dict: Dictionary = raw
	for card_id: String in cards_dict.keys():
		var def: Variant = cards_dict[card_id]
		var card: CardData = null
		if def is Dictionary:
			card = CardData.from_dict(card_id, def)
		else:
			push_error("GameData: card '%s' must be an object" % card_id)
		if card == null:
			ok = false
		else:
			_cards[card_id] = card
	return ok


func _load_players(pokemon_root: Dictionary) -> bool:
	var raw: Variant = pokemon_root.get("player", null)
	if not (raw is Dictionary):
		push_error("GameData: pokemon file needs a 'player' object")
		return false
	var ok: bool = true
	_players = raw
	for pid: String in _players.keys():
		var def_v: Variant = _players[pid]
		if not (def_v is Dictionary):
			push_error("GameData: player '%s' must be an object" % pid)
			ok = false
			continue
		var def: Dictionary = def_v
		for key: String in ["energy_per_turn", "hand_size"]:
			if not _is_positive_int(def.get(key, null)):
				push_error("GameData: player '%s' needs a positive integer '%s'" % [pid, key])
				ok = false
		var deck_v: Variant = def.get("starter_deck", null)
		if not (deck_v is Dictionary):
			push_error("GameData: player '%s' needs a 'starter_deck' object" % pid)
			ok = false
			continue
		var deck: Dictionary = deck_v
		for card_id: String in deck.keys():
			if not _cards.has(card_id):
				push_error("GameData: player '%s' deck references unknown card '%s'" % [pid, card_id])
				ok = false
			elif not _is_positive_int(deck[card_id]):
				push_error("GameData: player '%s' deck count for '%s' must be a positive integer" % [pid, card_id])
				ok = false
	return ok


func _load_enemies(pokemon_root: Dictionary) -> bool:
	var raw: Variant = pokemon_root.get("enemies", null)
	if not (raw is Dictionary):
		push_error("GameData: pokemon file needs an 'enemies' object")
		return false
	_enemies = raw
	var ok: bool = true
	for eid: String in _enemies.keys():
		var def_v: Variant = _enemies[eid]
		if not (def_v is Dictionary):
			push_error("GameData: enemy '%s' must be an object" % eid)
			ok = false
			continue
		var def: Dictionary = def_v
		if not _is_positive_int(def.get("max_hp", null)):
			push_error("GameData: enemy '%s' needs a positive integer 'max_hp'" % eid)
			ok = false
		for key: String in ["name", "sprite"]:
			if not (def.get(key, null) is String):
				push_error("GameData: enemy '%s' needs a string '%s'" % [eid, key])
				ok = false
		var pattern_v: Variant = def.get("pattern", null)
		if pattern_v != Combatant.PATTERN_SEQUENCE and pattern_v != Combatant.PATTERN_WEIGHTED:
			push_error("GameData: enemy '%s' needs 'pattern' = 'sequence' or 'weighted'" % eid)
			ok = false
		var actions_v: Variant = def.get("actions", null)
		if not (actions_v is Array) or (actions_v as Array).is_empty():
			push_error("GameData: enemy '%s' needs a non-empty 'actions' array" % eid)
			ok = false
			continue
		var actions: Array = actions_v
		for i: int in actions.size():
			var action_v: Variant = actions[i]
			if not (action_v is Dictionary):
				push_error("GameData: enemy '%s' action #%d must be an object" % [eid, i])
				ok = false
				continue
			var action: Dictionary = action_v
			if pattern_v == Combatant.PATTERN_WEIGHTED and not action.has("weight"):
				push_error("GameData: enemy '%s' action #%d needs a 'weight' (weighted pattern)" % [eid, i])
				ok = false
			if EnemyIntent.from_dict(action) == null:
				push_error("GameData: enemy '%s' action #%d is invalid" % [eid, i])
				ok = false
	return ok


func _load_encounters(pokemon_root: Dictionary) -> bool:
	var raw: Variant = pokemon_root.get("encounters", null)
	if not (raw is Dictionary):
		push_error("GameData: pokemon file needs an 'encounters' object")
		return false
	var ok: bool = true
	var encounters: Dictionary = raw
	for enc_id: String in encounters.keys():
		var list_v: Variant = encounters[enc_id]
		if not (list_v is Array):
			push_error("GameData: encounter '%s' must be an array of enemy ids" % enc_id)
			ok = false
			continue
		var list: Array = list_v
		if list.size() < Battle.MIN_ENEMIES or list.size() > Battle.MAX_ENEMIES:
			push_error("GameData: encounter '%s' must have %d to %d enemies (has %d)"
					% [enc_id, Battle.MIN_ENEMIES, Battle.MAX_ENEMIES, list.size()])
			ok = false
			continue
		var valid: bool = true
		for enemy_id: Variant in list:
			if not (enemy_id is String) or not _enemies.has(enemy_id):
				push_error("GameData: encounter '%s' references unknown enemy '%s'" % [enc_id, str(enemy_id)])
				valid = false
		if valid:
			_encounters[enc_id] = list
		else:
			ok = false
	var order_v: Variant = pokemon_root.get("encounter_order", null)
	if not (order_v is Array) or (order_v as Array).is_empty():
		push_error("GameData: pokemon file needs a non-empty 'encounter_order' array")
		return false
	for enc_id: Variant in (order_v as Array):
		if not (enc_id is String) or not _encounters.has(enc_id):
			push_error("GameData: encounter_order references unknown or invalid encounter '%s'" % str(enc_id))
			ok = false
		else:
			_encounter_order.append(enc_id)
	return ok


## True for an int, or a float with no fractional part (JSON numbers parse as float), > 0.
func _is_positive_int(v: Variant) -> bool:
	if v is int:
		return v > 0
	if v is float:
		return v > 0.0 and v == floorf(v)
	return false


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
