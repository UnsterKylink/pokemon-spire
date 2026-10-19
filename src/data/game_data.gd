class_name GameData
extends RefCounted
## Loads and validates the JSON data files (types, cards, Pokémon, encounters). No gameplay value lives in code.

const DEFAULT_CARDS_PATH: String = "res://assets/data/cards.json"
const DEFAULT_POKEMON_PATH: String = "res://assets/data/pokemon.json"
const DEFAULT_TYPES_PATH: String = "res://assets/data/types.json"
const DEFAULT_REWARDS_PATH: String = "res://assets/data/rewards.json"
const DEFAULT_ACT_PATH: String = "res://assets/data/act1.json"
const DEFAULT_EVENTS_PATH: String = "res://assets/data/events.json"
## Room type ids the game logic knows (their CONTENT and proportions are data, act1.json).
const ROOM_TYPES: Array[String] = ["wild", "elite", "center", "mart", "event", "boss"]
## Room types that start a battle (need encounter_pool + modifiers).
const FIGHT_ROOM_TYPES: Array[String] = ["wild", "elite", "boss"]
const EFFECT_TYPES: Array[String] = ["heal", "lose_hp", "gain_max_hp", "add_card", "add_random_card", "remove_card", "nothing"]
const NO_FLOOR_LIMIT: int = 1000000
## Minimum number of types the type table must define (story 003).
const MIN_TYPES: int = 18
## A Pokémon has 1 to MAX_POKEMON_TYPES distinct types (story 008).
const MAX_POKEMON_TYPES: int = 2

var _type_chart: TypeChart = TypeChart.neutral_chart()
var _cards: Dictionary = {}    # String -> CardData
var _players: Dictionary = {}  # String -> Dictionary (raw definition)
var _enemies: Dictionary = {}  # String -> Dictionary (raw definition)
var _encounters: Dictionary = {}  # String -> Array (enemy ids)
var _encounter_order: Array[String] = []
var _offer_count: int = 0
var _rarity_weights: Dictionary = {}  # String -> float
var _reward_pools: Dictionary = {}    # String (player id) -> Array[CardData]
var _act: Dictionary = {}      # validated act1.json
var _events: Dictionary = {}   # String -> Dictionary (validated event)
var _starter_pokemon: String = ""


## Loads all six files (act and events last, story 005). Returns false (after push_error) if anything is missing or invalid.
func load_all(cards_path: String = DEFAULT_CARDS_PATH, pokemon_path: String = DEFAULT_POKEMON_PATH,
		types_path: String = DEFAULT_TYPES_PATH, rewards_path: String = DEFAULT_REWARDS_PATH,
		act_path: String = DEFAULT_ACT_PATH, events_path: String = DEFAULT_EVENTS_PATH) -> bool:
	_type_chart = TypeChart.neutral_chart()
	_cards.clear()
	_players.clear()
	_enemies.clear()
	_encounters.clear()
	_encounter_order.clear()
	_offer_count = 0
	_rarity_weights.clear()
	_reward_pools.clear()
	_act = {}
	_events.clear()
	_starter_pokemon = ""
	var types_root: Dictionary = _read_json(types_path)
	var cards_root: Dictionary = _read_json(cards_path)
	var pokemon_root: Dictionary = _read_json(pokemon_path)
	var rewards_root: Dictionary = _read_json(rewards_path)
	var act_root: Dictionary = _read_json(act_path)
	var events_root: Dictionary = _read_json(events_path)
	if types_root.is_empty() or cards_root.is_empty() or pokemon_root.is_empty() or rewards_root.is_empty() \
			or act_root.is_empty() or events_root.is_empty():
		return false
	var chart: TypeChart = TypeChart.from_dict(types_root)
	if chart == null:
		return false
	if chart.get_type_ids().size() < MIN_TYPES:
		push_error("GameData: types file defines %d types, at least %d are required"
				% [chart.get_type_ids().size(), MIN_TYPES])
		return false
	_type_chart = chart
	var ok: bool = true
	ok = _load_cards(cards_root) and ok
	ok = _load_players(pokemon_root) and ok
	ok = _load_enemies(pokemon_root) and ok
	ok = _load_encounters(pokemon_root) and ok
	ok = _check_pokemon_refs(pokemon_root) and ok
	ok = _load_rewards(rewards_root) and ok
	ok = _load_events(events_root) and ok
	ok = _load_act(act_root) and ok
	return ok


## The type table (multipliers + names/colours). Neutral/empty until load_all succeeds.
func get_type_chart() -> TypeChart:
	return _type_chart


## French display name of a type id ("" if unknown).
func get_type_name(type_id: String) -> String:
	return _type_chart.get_type_name(type_id)


## Display colour of a type id (white if unknown).
func get_type_color(type_id: String) -> Color:
	return _type_chart.get_type_color(type_id)


## Returns the card or null (with push_error) if the id is unknown.
func get_card(card_id: String) -> CardData:
	if not _cards.has(card_id):
		push_error("GameData: unknown card id '%s'" % card_id)
		return null
	return _cards[card_id]


## Builds a fresh player Combatant, or null if the id is unknown. current_hp < 0 = full HP.
func create_player(player_id: String, current_hp: int = -1) -> Combatant:
	if not _players.has(player_id):
		push_error("GameData: unknown player id '%s'" % player_id)
		return null
	return Combatant.from_dict(player_id, _players[player_id], current_hp)


## Raw definition (copy) of a player: name, type, max_hp, sprite, energy_per_turn, hand_size, ... Empty if unknown.
func get_player_definition(player_id: String) -> Dictionary:
	if not _players.has(player_id):
		push_error("GameData: unknown player id '%s'" % player_id)
		return {}
	return (_players[player_id] as Dictionary).duplicate(true)


## Number of cards offered after a victory (rewards.json).
func get_offer_count() -> int:
	return _offer_count


## Rarity id -> weight (> 0) used to draw reward cards.
func get_rarity_weights() -> Dictionary:
	return _rarity_weights.duplicate()


## The player's reward reserve (cards that may be offered). Empty if the player has none.
func get_reward_pool(player_id: String) -> Array[CardData]:
	var result: Array[CardData] = []
	var list: Array = _reward_pools.get(player_id, [])
	for c: CardData in list:
		result.append(c)
	return result


## Attack cards an enemy "teaches" when beaten (may be empty).
func get_enemy_teaches(enemy_id: String) -> Array[CardData]:
	var result: Array[CardData] = []
	var def: Dictionary = _enemies.get(enemy_id, {})
	var ids: Array = def.get("teaches", [])
	for card_id: String in ids:
		var card: CardData = _cards.get(card_id, null)
		if card != null:
			result.append(card)
	return result


## French display name of an enemy ("" if unknown).
func get_enemy_name(enemy_id: String) -> String:
	var def: Dictionary = _enemies.get(enemy_id, {})
	return String(def.get("name", ""))


## Builds a fresh enemy Combatant, or null if the id is unknown.
func create_enemy(enemy_id: String) -> Combatant:
	if not _enemies.has(enemy_id):
		push_error("GameData: unknown enemy id '%s'" % enemy_id)
		return null
	return Combatant.from_dict(enemy_id, _enemies[enemy_id])


## Builds fresh enemy Combatants (left to right) for an encounter. Empty if the id is unknown.
## Room modifiers (story 005): max HP x `hp_multiplier` (rounded up, HP full) and `strength_bonus`
## added to Combatant.strength, so battle intents already show the boosted attack values.
func create_enemies(encounter_id: String, hp_multiplier: float = 1.0, strength_bonus: int = 0) -> Array[Combatant]:
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
		if hp_multiplier != 1.0:
			enemy.max_hp = maxi(1, ceili(snappedf(enemy.max_hp * hp_multiplier, 0.0001)))
			enemy.hp = enemy.max_hp
		enemy.strength += strength_bonus
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


## Copy of the validated act config (act1.json): map, placement, room_types, encounter_pools, event_pool.
## Empty until load_all succeeds. Feed it to MapGenerator.generate.
func get_act_config() -> Dictionary:
	return _act.duplicate(true)


## Room type definition (copy): name, weight, min_floor, ... {} if unknown.
func get_room_type(room_type: String) -> Dictionary:
	var rooms: Dictionary = _act.get("room_types", {})
	if not rooms.has(room_type):
		return {}
	return (rooms[room_type] as Dictionary).duplicate(true)


## French display name of a room type ("" if unknown).
func get_room_name(room_type: String) -> String:
	return String(get_room_type(room_type).get("name", ""))


## Fight modifiers of a room type: {"hp_multiplier": float, "strength_bonus": int} (neutral if none).
func get_room_modifiers(room_type: String) -> Dictionary:
	var mods: Dictionary = get_room_type(room_type).get("modifiers", {})
	return {"hp_multiplier": float(mods.get("hp_multiplier", 1.0)), "strength_bonus": int(mods.get("strength_bonus", 0))}


## Rarity weights overriding rewards.json for this room's reward (elite); {} = use the default weights.
func get_room_rarity_weights(room_type: String) -> Dictionary:
	var reward: Dictionary = get_room_type(room_type).get("reward", {})
	var w: Variant = reward.get("rarity_weights", null)
	return (w as Dictionary).duplicate() if w is Dictionary else {}


## Picks an encounter id for a fight room at `floor_number` (weighted, from the room's pool for that floor).
## "" (after push_error) if the room has no pool.
func pick_encounter(room_type: String, floor_number: int, rng: RandomNumberGenerator) -> String:
	var room: Dictionary = get_room_type(room_type)
	var pool_id: String = _pool_id_for(room, floor_number)
	var pools: Dictionary = _act.get("encounter_pools", {})
	if pool_id.is_empty() or not pools.has(pool_id):
		push_error("GameData: room type '%s' has no encounter pool" % room_type)
		return ""
	var entries: Array = pools[pool_id]
	var total: float = 0.0
	for entry: Dictionary in entries:
		total += float(entry["weight"])
	var roll: float = rng.randf() * total
	for entry: Dictionary in entries:
		if roll < float(entry["weight"]):
			return String(entry["encounter"])
		roll -= float(entry["weight"])
	return String((entries[entries.size() - 1] as Dictionary)["encounter"])


## Ids of the events that may appear in event rooms.
func get_event_pool() -> Array[String]:
	var ids: Array[String] = []
	for id: String in _act.get("event_pool", []):
		ids.append(id)
	return ids


## Event definition (copy): {id, title, text, options:[{label, result_text, effects}]}. {} if unknown.
func get_event(event_id: String) -> Dictionary:
	if not _events.has(event_id):
		push_error("GameData: unknown event id '%s'" % event_id)
		return {}
	return (_events[event_id] as Dictionary).duplicate(true)


# --- Loading / validation --------------------------------------------------

## Pokémon info for ANY player or enemy id: {id, name, sprite_path, types: Array[String]}. Empty if unknown.
func get_pokemon_info(pokemon_id: String) -> Dictionary:
	var def_v: Variant = _players.get(pokemon_id, _enemies.get(pokemon_id, null))
	if not (def_v is Dictionary):
		return {}
	var def: Dictionary = def_v
	var types: Array[String] = []
	var raw_types: Variant = def.get("types", [])
	if raw_types is Array:
		for t: Variant in (raw_types as Array):
			types.append(String(t))
	return {"id": pokemon_id, "name": String(def.get("name", "")), "sprite_path": String(def.get("sprite", "")), "types": types}


## Every player + enemy Pokémon id.
func get_pokemon_ids() -> Array[String]:
	var ids: Array[String] = []
	for k: String in _players.keys():
		ids.append(k)
	for k: String in _enemies.keys():
		ids.append(k)
	return ids


## Id of the Pokémon on the field at the start of each battle (pokemon.json "starter_pokemon").
func get_starter_pokemon_id() -> String:
	return _starter_pokemon


## Story 009: attacks need a known Pokémon, skills none; "starter_pokemon" must exist.
func _check_pokemon_refs(pokemon_root: Dictionary) -> bool:
	var ok: bool = true
	for card_id: String in _cards.keys():
		var card: CardData = _cards[card_id]
		if card.kind == CardData.KIND_ATTACK:
			if card.pokemon_id.is_empty():
				push_error("GameData: attack card '%s' needs a 'pokemon'" % card_id)
				ok = false
			elif not _players.has(card.pokemon_id) and not _enemies.has(card.pokemon_id):
				push_error("GameData: card '%s' references unknown pokemon '%s'" % [card_id, card.pokemon_id])
				ok = false
		elif not card.pokemon_id.is_empty():
			push_error("GameData: skill card '%s' must not have a 'pokemon'" % card_id)
			ok = false
	var starter: Variant = pokemon_root.get("starter_pokemon", null)
	if not (starter is String) or (not _players.has(starter) and not _enemies.has(starter)):
		push_error("GameData: pokemon file needs a 'starter_pokemon' naming a known pokemon")
		ok = false
	else:
		_starter_pokemon = starter
	return ok


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
			# Attacks must have a type; a skill may omit it but, if given, it must be known.
			if card != null and not _check_type_ref("card '%s'" % card_id, card.type_id,
					card.kind == CardData.KIND_ATTACK):
				card = null
		else:
			push_error("GameData: card '%s' must be an object" % card_id)
		if card == null:
			ok = false
		elif card.rarity not in CardData.RARITIES:
			push_error("GameData: card '%s' needs a 'rarity' in %s (has '%s')" % [card_id, str(CardData.RARITIES), card.rarity])
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
		if not _check_types_ref("player '%s'" % pid, def.get("types", null)):
			ok = false
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
		if not _check_types_ref("enemy '%s'" % eid, def.get("types", null)):
			ok = false
		if not _is_positive_int(def.get("max_hp", null)):
			push_error("GameData: enemy '%s' needs a positive integer 'max_hp'" % eid)
			ok = false
		for key: String in ["name", "sprite"]:
			if not (def.get(key, null) is String):
				push_error("GameData: enemy '%s' needs a string '%s'" % [eid, key])
				ok = false
		var teaches_v: Variant = def.get("teaches", [])
		if not (teaches_v is Array):
			push_error("GameData: enemy '%s' 'teaches' must be an array of card ids" % eid)
			ok = false
		else:
			for card_id: Variant in (teaches_v as Array):
				var card: CardData = _cards.get(card_id, null) if card_id is String else null
				if card == null:
					push_error("GameData: enemy '%s' teaches unknown card '%s'" % [eid, str(card_id)])
					ok = false
				elif card.kind != CardData.KIND_ATTACK:
					push_error("GameData: enemy '%s' teaches '%s' which is not an attack" % [eid, str(card_id)])
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


func _load_rewards(root: Dictionary) -> bool:
	var ok: bool = true
	if not _is_positive_int(root.get("offer_count", null)):
		push_error("GameData: rewards file needs a positive integer 'offer_count'")
		return false
	_offer_count = int(root["offer_count"])
	var weights_v: Variant = root.get("rarity_weights", null)
	if not (weights_v is Dictionary) or (weights_v as Dictionary).is_empty():
		push_error("GameData: rewards file needs a non-empty 'rarity_weights' object")
		return false
	var weights: Dictionary = weights_v
	for rarity: String in weights.keys():
		var w: Variant = weights[rarity]
		if rarity not in CardData.RARITIES:
			push_error("GameData: rarity_weights has unknown rarity '%s'" % rarity)
			ok = false
		elif not ((w is int or w is float) and w > 0):
			push_error("GameData: rarity_weights['%s'] must be a number > 0" % rarity)
			ok = false
		else:
			_rarity_weights[rarity] = float(w)
	var pools_v: Variant = root.get("player_pool", null)
	if not (pools_v is Dictionary):
		push_error("GameData: rewards file needs a 'player_pool' object")
		return false
	var pools: Dictionary = pools_v
	for pid: String in _players.keys():
		if not pools.has(pid):
			push_error("GameData: rewards file has no pool for player '%s'" % pid)
			ok = false
	for pid: String in pools.keys():
		var list_v: Variant = pools[pid]
		if not _players.has(pid) or not (list_v is Array):
			push_error("GameData: reward pool '%s' must be an array and match a known player" % pid)
			ok = false
			continue
		var pool: Array[CardData] = []
		var seen: Dictionary = {}
		var attacks: int = 0
		for card_id: Variant in (list_v as Array):
			var card: CardData = _cards.get(card_id, null) if card_id is String else null
			if card == null:
				push_error("GameData: reward pool '%s' references unknown card '%s'" % [pid, str(card_id)])
				ok = false
			elif seen.has(card_id):
				push_error("GameData: reward pool '%s' lists '%s' twice" % [pid, str(card_id)])
				ok = false
			elif not _rarity_weights.has(card.rarity):
				push_error("GameData: reward pool '%s': card '%s' has rarity '%s' without a weight" % [pid, str(card_id), card.rarity])
				ok = false
			else:
				seen[card_id] = true
				pool.append(card)
				if card.kind == CardData.KIND_ATTACK:
					attacks += 1
		if attacks < 1:
			push_error("GameData: reward pool '%s' needs at least one attack card" % pid)
			ok = false
		if pool.size() < _offer_count:
			push_error("GameData: reward pool '%s' has %d usable cards, offer_count is %d" % [pid, pool.size(), _offer_count])
			ok = false
		_reward_pools[pid] = pool
	return ok


func _pool_id_for(room: Dictionary, floor_number: int) -> String:
	var overrides: Array = room.get("encounter_pool_overrides", [])
	for o: Dictionary in overrides:
		if floor_number >= int(o.get("min_floor", 1)) and floor_number <= int(o.get("max_floor", NO_FLOOR_LIMIT)):
			return String(o["pool"])
	return String(room.get("encounter_pool", ""))


func _is_number(v: Variant) -> bool:
	return v is int or v is float


## Validates a {rarity: weight > 0} object. `label` names the owner in errors.
func _check_rarity_weights(label: String, w: Dictionary) -> bool:
	var ok: bool = not w.is_empty()
	if not ok:
		push_error("GameData: %s rarity_weights is empty" % label)
	for rarity: String in w.keys():
		if rarity not in CardData.RARITIES or not (_is_number(w[rarity]) and w[rarity] > 0):
			push_error("GameData: %s rarity_weights['%s'] is invalid" % [label, rarity])
			ok = false
	return ok


func _load_events(root: Dictionary) -> bool:
	var list_v: Variant = root.get("events", null)
	if not (list_v is Array) or (list_v as Array).is_empty():
		push_error("GameData: events file needs a non-empty 'events' array")
		return false
	var ok: bool = true
	for ev_v: Variant in (list_v as Array):
		if not (ev_v is Dictionary):
			push_error("GameData: every event must be an object")
			ok = false
			continue
		var ev: Dictionary = ev_v
		var id: String = String(ev.get("id", "")) if ev.get("id", null) is String else ""
		if id.is_empty() or _events.has(id):
			push_error("GameData: event needs a unique non-empty 'id' (got '%s')" % id)
			ok = false
			continue
		var ev_ok: bool = true
		for key: String in ["title", "text"]:
			if not (ev.get(key, null) is String) or String(ev[key]).is_empty():
				push_error("GameData: event '%s' needs a text '%s'" % [id, key])
				ev_ok = false
		var opts_v: Variant = ev.get("options", null)
		if not (opts_v is Array) or (opts_v as Array).size() != 2:
			push_error("GameData: event '%s' needs exactly 2 options" % id)
			ok = false
			continue
		for o_v: Variant in (opts_v as Array):
			if not (o_v is Dictionary):
				push_error("GameData: event '%s' option must be an object" % id)
				ev_ok = false
				continue
			var o: Dictionary = o_v
			for key: String in ["label", "result_text"]:
				if not (o.get(key, null) is String) or String(o[key]).is_empty():
					push_error("GameData: event '%s' option needs a text '%s'" % [id, key])
					ev_ok = false
			var effects_v: Variant = o.get("effects", null)
			if not (effects_v is Array) or (effects_v as Array).is_empty():
				push_error("GameData: event '%s' option needs a non-empty 'effects' array" % id)
				ev_ok = false
				continue
			for eff_v: Variant in (effects_v as Array):
				if not _check_effect(id, eff_v):
					ev_ok = false
		if ev_ok:
			_events[id] = ev
		else:
			ok = false
	return ok


func _check_effect(event_id: String, eff_v: Variant) -> bool:
	if not (eff_v is Dictionary):
		push_error("GameData: event '%s' effect must be an object" % event_id)
		return false
	var eff: Dictionary = eff_v
	var t: String = String(eff.get("type", "")) if eff.get("type", null) is String else ""
	if t not in EFFECT_TYPES:
		push_error("GameData: event '%s' has unknown effect type '%s'" % [event_id, t])
		return false
	var good: bool = true
	match t:
		"heal":
			var pct: Variant = eff.get("percent", null)
			good = _is_number(pct) and pct > 0 and pct <= 100
		"lose_hp", "gain_max_hp":
			good = _is_positive_int(eff.get("value", null))
		"add_card", "remove_card":
			good = eff.get("card", null) is String and _cards.has(eff["card"])
		"add_random_card":
			good = eff.get("rarity", null) is String and _rarity_weights.has(eff["rarity"])
	if not good:
		push_error("GameData: event '%s' effect '%s' has invalid or unknown parameters" % [event_id, t])
	return good


func _load_act(root: Dictionary) -> bool:
	var map_v: Variant = root.get("map", null)
	if not (map_v is Dictionary):
		push_error("GameData: act file needs a 'map' object")
		return false
	var m: Dictionary = map_v
	for key: String in ["floors", "width", "start_nodes", "paths", "boss_floor_nodes"]:
		if not _is_positive_int(m.get(key, null)):
			push_error("GameData: act map needs a positive integer '%s'" % key)
			return false
	var floors: int = int(m["floors"])
	if floors < 3 or int(m["start_nodes"]) > int(m["width"]) or int(m["paths"]) < int(m["start_nodes"]):
		push_error("GameData: act map needs floors >= 3, start_nodes <= width and paths >= start_nodes")
		return false
	if int(m["boss_floor_nodes"]) != 1:
		push_error("GameData: the boss floor must have a single node (boss_floor_nodes = 1)")
		return false
	var ok: bool = true
	# Room types.
	var rooms_v: Variant = root.get("room_types", null)
	if not (rooms_v is Dictionary):
		push_error("GameData: act file needs a 'room_types' object")
		return false
	var rooms: Dictionary = rooms_v
	for tid: String in rooms.keys():
		if tid not in ROOM_TYPES:
			push_error("GameData: unknown room type '%s'" % tid)
			ok = false
	for tid: String in ROOM_TYPES:
		if not rooms.has(tid):
			push_error("GameData: room type '%s' is missing" % tid)
			ok = false
	if not ok:
		return false
	var pools_v: Variant = root.get("encounter_pools", null)
	if not (pools_v is Dictionary):
		push_error("GameData: act file needs an 'encounter_pools' object")
		return false
	var pools: Dictionary = pools_v
	var any_weight: bool = false
	for tid: String in rooms.keys():
		var r_v: Variant = rooms[tid]
		if not (r_v is Dictionary):
			push_error("GameData: room type '%s' must be an object" % tid)
			ok = false
			continue
		var r: Dictionary = r_v
		if not (r.get("name", null) is String) or not _is_number(r.get("weight", null)) or r["weight"] < 0 \
				or not _is_positive_int(r.get("min_floor", null)) \
				or (r.has("max_floor") and not _is_positive_int(r["max_floor"])) \
				or (r.has("max_floor") and _is_positive_int(r["max_floor"]) and r["max_floor"] < r["min_floor"]):
			push_error("GameData: room type '%s' needs name, weight >= 0, min_floor >= 1 and max_floor >= min_floor" % tid)
			ok = false
			continue
		if tid != "boss" and r["weight"] > 0:
			any_weight = true
		if tid == "boss" and r["weight"] != 0:
			push_error("GameData: the boss room must have weight 0 (it only exists on the boss floor)")
			ok = false
		if r.has("reward"):
			var reward_v: Variant = r["reward"]
			var rw: Variant = (reward_v as Dictionary).get("rarity_weights", null) if reward_v is Dictionary else 0
			if rw is Dictionary:
				ok = _check_rarity_weights("room '%s'" % tid, rw) and ok
			elif rw != null:
				push_error("GameData: room '%s' reward.rarity_weights must be null or an object" % tid)
				ok = false
		if tid in FIGHT_ROOM_TYPES:
			var mods_v: Variant = r.get("modifiers", null)
			if not (mods_v is Dictionary) or not _is_number((mods_v as Dictionary).get("hp_multiplier", null)) \
					or (mods_v as Dictionary)["hp_multiplier"] <= 0 \
					or not _is_number((mods_v as Dictionary).get("strength_bonus", null)) \
					or (mods_v as Dictionary)["strength_bonus"] < 0:
				push_error("GameData: fight room '%s' needs modifiers {hp_multiplier > 0, strength_bonus >= 0}" % tid)
				ok = false
			var used_pools: Array = [r.get("encounter_pool", null)]
			var overrides_v: Variant = r.get("encounter_pool_overrides", [])
			if not (overrides_v is Array):
				push_error("GameData: room '%s' encounter_pool_overrides must be an array" % tid)
				ok = false
			else:
				for o_v: Variant in (overrides_v as Array):
					if o_v is Dictionary:
						used_pools.append((o_v as Dictionary).get("pool", null))
					else:
						push_error("GameData: room '%s' has an invalid pool override" % tid)
						ok = false
			for pool_ref: Variant in used_pools:
				if not (pool_ref is String) or not pools.has(pool_ref):
					push_error("GameData: room '%s' references unknown encounter pool '%s'" % [tid, str(pool_ref)])
					ok = false
	if not any_weight:
		push_error("GameData: at least one non-boss room type needs a weight > 0")
		ok = false
	for pool_id: String in pools.keys():
		var list_v: Variant = pools[pool_id]
		if not (list_v is Array) or (list_v as Array).is_empty():
			push_error("GameData: encounter pool '%s' must be a non-empty array" % pool_id)
			ok = false
			continue
		for entry_v: Variant in (list_v as Array):
			if not (entry_v is Dictionary) or not ((entry_v as Dictionary).get("encounter", null) is String) \
					or not _encounters.has((entry_v as Dictionary)["encounter"]) \
					or not _is_number((entry_v as Dictionary).get("weight", null)) or (entry_v as Dictionary)["weight"] <= 0:
				push_error("GameData: encounter pool '%s' has an invalid entry (unknown encounter or weight <= 0)" % pool_id)
				ok = false
	# Placement.
	var place_v: Variant = root.get("placement", null)
	if not (place_v is Dictionary):
		push_error("GameData: act file needs a 'placement' object")
		return false
	var place: Dictionary = place_v
	var nc_v: Variant = place.get("no_consecutive", null)
	if not (nc_v is Array):
		push_error("GameData: placement needs a 'no_consecutive' array")
		return false
	for t: Variant in (nc_v as Array):
		if not (t is String) or t not in ROOM_TYPES:
			push_error("GameData: placement.no_consecutive has unknown room type '%s'" % str(t))
			ok = false
	var forced_v: Variant = place.get("forced_floors", null)
	if not (forced_v is Dictionary):
		push_error("GameData: placement needs a 'forced_floors' object")
		return false
	var forced: Dictionary = forced_v
	if forced.get(str(floors), null) != "boss":
		push_error("GameData: the last floor (%d) must be forced to 'boss'" % floors)
		ok = false
	var forced_by_floor: Dictionary = {}
	for key: String in forced.keys():
		var tv: Variant = forced[key]
		if not key.is_valid_int() or int(key) < 1 or int(key) > floors or not (tv is String) or tv not in ROOM_TYPES:
			push_error("GameData: invalid forced floor '%s'" % key)
			ok = false
			continue
		if tv == "boss" and int(key) != floors:
			push_error("GameData: only the last floor may be 'boss'")
			ok = false
		forced_by_floor[int(key)] = tv
		var fr: Dictionary = rooms[tv] if rooms[tv] is Dictionary else {}
		if not fr.is_empty() and (int(key) < int(fr.get("min_floor", 1)) or int(key) > int(fr.get("max_floor", NO_FLOOR_LIMIT))):
			push_error("GameData: forced floor %s uses '%s' outside its floor range" % [key, str(tv)])
			ok = false
	for f: int in forced_by_floor.keys():
		if forced_by_floor.has(f + 1) and forced_by_floor[f] == forced_by_floor[f + 1] and forced_by_floor[f] in (nc_v as Array):
			push_error("GameData: forced floors %d and %d break no_consecutive" % [f, f + 1])
			ok = false
	# Every free floor needs at least one placeable type (wild-like weight > 0 and floor range).
	for f: int in range(1, floors + 1):
		if forced_by_floor.has(f):
			continue
		var placeable: bool = false
		for tid: String in rooms.keys():
			var rr: Dictionary = rooms[tid] if rooms[tid] is Dictionary else {}
			if not rr.is_empty() and _is_number(rr.get("weight", null)) and rr["weight"] > 0 \
					and f >= int(rr.get("min_floor", 1)) and f <= int(rr.get("max_floor", NO_FLOOR_LIMIT)):
				placeable = true
		if not placeable:
			push_error("GameData: no room type can be placed on floor %d" % f)
			ok = false
	# Event pool.
	var ep_v: Variant = root.get("event_pool", null)
	if not (ep_v is Array) or (ep_v as Array).is_empty():
		push_error("GameData: act file needs a non-empty 'event_pool'")
		return false
	for eid: Variant in (ep_v as Array):
		if not (eid is String) or not _events.has(eid):
			push_error("GameData: event_pool references unknown event '%s'" % str(eid))
			ok = false
	if ok:
		_act = root
	return ok


## Checks a Pokémon's `types` array: 1-2 distinct ids known to the chart.
func _check_types_ref(owner_label: String, types_v: Variant) -> bool:
	if not (types_v is Array) or (types_v as Array).is_empty() or (types_v as Array).size() > MAX_POKEMON_TYPES:
		push_error("GameData: %s needs a 'types' array of 1 to %d types" % [owner_label, MAX_POKEMON_TYPES])
		return false
	var seen: Dictionary = {}
	var ok: bool = true
	for t: Variant in (types_v as Array):
		if not (t is String) or not _type_chart.is_known_type(t):
			push_error("GameData: %s has unknown type '%s'" % [owner_label, str(t)])
			ok = false
		elif seen.has(t):
			push_error("GameData: %s lists type '%s' twice" % [owner_label, t])
			ok = false
		else:
			seen[t] = true
	return ok


## Checks a `type` reference against the loaded chart. `required`: an empty type is an error.
func _check_type_ref(owner_label: String, type_id: String, required: bool) -> bool:
	if type_id.is_empty():
		if required:
			push_error("GameData: %s needs a 'type'" % owner_label)
			return false
		return true
	if not _type_chart.is_known_type(type_id):
		push_error("GameData: %s has unknown type '%s'" % [owner_label, type_id])
		return false
	return true


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
