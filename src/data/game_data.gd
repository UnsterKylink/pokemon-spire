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
const DEFAULT_ITEMS_PATH: String = "res://assets/data/items.json"
const DEFAULT_POTIONS_PATH: String = "res://assets/data/potions.json"
const DEFAULT_SHOP_PATH: String = "res://assets/data/shop.json"
## Story 012: zones, gym types, tiers, badge rewards.
const DEFAULT_ZONES_PATH: String = "res://assets/data/zones.json"
## Story 013: Conseil 4, Maître, final boss.
const DEFAULT_LEAGUE_PATH: String = "res://assets/data/league.json"
## Story 013b: large roster (720 Pokémon, all generations) merged into the enemies; "" = no roster.
const DEFAULT_ROSTER_PATH: String = "res://assets/data/roster.json"
## Prefix of an encounter id GENERATED from the roster: "roster:<id>,<id>,..." (wild / elite fights, auto gym teams).
## create_enemies / get_encounter_enemy_ids decode it; it is never stored in pokemon.json.
const ROSTER_ENCOUNTER_PREFIX: String = "roster:"
## Highest roster power tier (roster.json schema: tier 1..3).
const ROSTER_MAX_TIER: int = 3
## Room types whose fights are biased toward the zone type and scaled by the zone "modifiers" (the gym uses "gym_modifiers").
const ZONE_TYPED_ROOMS: Array[String] = ["wild", "elite"]
## The room type that holds the zone's gym fight.
const ROOM_GYM: String = "boss"
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
var _starter_candidates: Array[String] = []
var _starter_cards_by_type: Dictionary = {}  # type id -> {"basic": card id, "strong": card id}
var _deck_template: Dictionary = {}  # basic_count / skill / skill_count / strong_count (story 010)
var _carriers_by_type: Dictionary = {}  # type id -> Array[String] (roster Pokémon having that type)
var _items: Dictionary = {}    # String -> ItemData (story 006)
var _potions: Dictionary = {}  # String -> PotionData
var _max_potions: int = 0
var _shop_cfg: Dictionary = {}  # validated shop.json
var _evolutions: Dictionary = {}  # base pokemon id -> validated evolution entry (story 007)
var _evolved_forms: Dictionary = {}  # evolved form id -> its evolution entry (for get_pokemon_info)
var _evolution_hp_bonus_default: int = 0
var _team_evolution_battles: Array[int] = []  # story 014: battles won needed for stage 1->2, 2->3 (team Pokémon)
var _team_evolution_bonus_hp: int = 0
var _zones_cfg: Dictionary = {}  # validated zones.json (story 012)
var _league_cfg: Dictionary = {}  # validated league.json (story 013)
var _roster_ids: Dictionary = {}  # roster id -> its entry (story 013b; the entry is ALSO in _enemies)
var _roster_wild: Dictionary = {}  # type id ("" = any type) -> {tier int -> Array[String] wild_ok roster ids, file order}
var _roster_candidates: Array[String] = []  # roster ids with roles.candidate_start (story 013b starter draw)
var _starter_roster_share: float = 0.0  # pokemon.json starter_choice.roster_share


## Loads all twelve files (act and events story 005; items, potions, shop story 006; zones story 012; league story 013;
## roster story 013b, skipped when `roster_path` is ""). Returns false (after push_error) if anything is missing or invalid.
func load_all(cards_path: String = DEFAULT_CARDS_PATH, pokemon_path: String = DEFAULT_POKEMON_PATH,
		types_path: String = DEFAULT_TYPES_PATH, rewards_path: String = DEFAULT_REWARDS_PATH,
		act_path: String = DEFAULT_ACT_PATH, events_path: String = DEFAULT_EVENTS_PATH,
		items_path: String = DEFAULT_ITEMS_PATH, potions_path: String = DEFAULT_POTIONS_PATH,
		shop_path: String = DEFAULT_SHOP_PATH, zones_path: String = DEFAULT_ZONES_PATH,
		league_path: String = DEFAULT_LEAGUE_PATH, roster_path: String = DEFAULT_ROSTER_PATH) -> bool:
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
	_starter_candidates.clear()
	_starter_cards_by_type = {}
	_deck_template = {}
	_carriers_by_type = {}
	_items.clear()
	_potions.clear()
	_max_potions = 0
	_shop_cfg = {}
	_evolutions = {}
	_evolved_forms = {}
	_evolution_hp_bonus_default = 0
	_team_evolution_battles = []
	_team_evolution_bonus_hp = 0
	_zones_cfg = {}
	_league_cfg = {}
	_roster_ids = {}
	_roster_wild = {}
	_roster_candidates.clear()
	_starter_roster_share = 0.0
	var types_root: Dictionary = _read_json(types_path)
	var cards_root: Dictionary = _read_json(cards_path)
	var pokemon_root: Dictionary = _read_json(pokemon_path)
	var rewards_root: Dictionary = _read_json(rewards_path)
	var act_root: Dictionary = _read_json(act_path)
	var events_root: Dictionary = _read_json(events_path)
	var items_root: Dictionary = _read_json(items_path)
	var potions_root: Dictionary = _read_json(potions_path)
	var shop_root: Dictionary = _read_json(shop_path)
	var zones_root: Dictionary = _read_json(zones_path)
	var league_root: Dictionary = _read_json(league_path)
	var roster_root: Dictionary = {"pokemon": {}}
	if not roster_path.is_empty():
		roster_root = _read_json(roster_path)
		if roster_root.is_empty():
			return false
	if types_root.is_empty() or cards_root.is_empty() or pokemon_root.is_empty() or rewards_root.is_empty() \
			or act_root.is_empty() or events_root.is_empty() or items_root.is_empty() or potions_root.is_empty() \
			or shop_root.is_empty() or zones_root.is_empty() or league_root.is_empty():
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
	ok = _load_roster(roster_root) and ok  # before the card owners / starters / evolutions that may name roster ids
	ok = _load_encounters(pokemon_root) and ok
	ok = _check_pokemon_refs(pokemon_root) and ok
	ok = _load_rewards(rewards_root) and ok
	ok = _load_starters(pokemon_root) and ok
	ok = _load_evolutions(pokemon_root) and ok
	ok = _load_roster_evolutions(pokemon_root) and ok
	ok = _load_events(events_root) and ok
	ok = _load_act(act_root) and ok
	ok = _load_items(items_root) and ok
	ok = _load_potions(potions_root) and ok
	ok = _load_shop(shop_root) and ok
	ok = _load_zones(zones_root) and ok
	ok = _load_league(league_root) and ok
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


## Story 015 (save/resume): existence checks that do not push_error (get_card / get_item / get_potion do).
func has_card(card_id: String) -> bool:
	return _cards.has(card_id)


func has_item(item_id: String) -> bool:
	return _items.has(item_id)


func has_potion(potion_id: String) -> bool:
	return _potions.has(potion_id)


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
## Story 013b: a generated "roster:<id>,..." encounter (pick_encounter / draw_zones) builds its roster Pokémon exactly
## like pokemon.json enemies (same Combatant.from_dict, same modifiers).
func create_enemies(encounter_id: String, hp_multiplier: float = 1.0, strength_bonus: int = 0) -> Array[Combatant]:
	var result: Array[Combatant] = []
	var ids: Array[String] = get_encounter_enemy_ids(encounter_id)
	if ids.is_empty():
		push_error("GameData: unknown encounter id '%s'" % encounter_id)
		return result
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
## Story 012: with a `zone` (RunState.current_zone()), the gym room returns the zone's Champion encounter; wild / elite
## rooms draw from the zone's type pool with probability wild_type_share / elite_type_share (one extra rng roll),
## else from the room's pool (the early-floor override only if the zone's tier has early_pool) PLUS the pools
## unlocked by the badges already earned. Without a zone nothing changes (same rolls as before story 012).
func pick_encounter(room_type: String, floor_number: int, rng: RandomNumberGenerator, zone: Dictionary = {}) -> String:
	if not zone.is_empty() and room_type == ROOM_GYM:
		return String(zone["gym_encounter"])
	var room: Dictionary = get_room_type(room_type)
	var pool_id: String = _pool_id_for(room, floor_number, zone.is_empty() or bool(zone.get("early_pool", true)))
	var pools: Dictionary = _act.get("encounter_pools", {})
	if pool_id.is_empty() or not pools.has(pool_id):
		push_error("GameData: room type '%s' has no encounter pool" % room_type)
		return ""
	var entries: Array = pools[pool_id]
	if not zone.is_empty() and room_type in ZONE_TYPED_ROOMS:
		var typed: bool = rng.randf() < float(zone.get(room_type + "_type_share", 0.0))
		# Story 013b: generated from the roster with the zone's roster share (always when the typed pool is missing).
		var roster: Dictionary = zone.get("roster", {})
		var fixed_typed_pool: String = String(zone.get(room_type + "_pool", ""))
		var from_roster: bool = rng.randf() < float(roster.get(room_type + "_share", 0.0))
		if typed and fixed_typed_pool.is_empty():
			from_roster = true
		if from_roster and not _roster_ids.is_empty():
			var early: bool = pool_id != String(room.get("encounter_pool", ""))
			return _roster_encounter(room_type, zone, typed, early, rng)
		if typed and not fixed_typed_pool.is_empty():
			entries = pools[fixed_typed_pool]
		else:
			entries = entries.duplicate()
			for extra: String in zone.get("unlocked_" + room_type + "_pools", []):
				entries.append_array(pools[extra])
	var total: float = 0.0
	for entry: Dictionary in entries:
		total += float(entry["weight"])
	var roll: float = rng.randf() * total
	for entry: Dictionary in entries:
		if roll < float(entry["weight"]):
			return String(entry["encounter"])
		roll -= float(entry["weight"])
	return String((entries[entries.size() - 1] as Dictionary)["encounter"])


## Story 013b: generated wild / elite encounter "roster:<id>,..." for `zone`: size from the zone's
## wild_size_weights / elite_size_weights (roster_encounters.early_size_weights on the wild_early floors), each
## Pokémon's tier from tier_weights (+ elite_tier_bonus for elites, capped at ROSTER_MAX_TIER), all of the zone's type
## when `typed`, no duplicate species. Deterministic for a seeded rng.
func _roster_encounter(room_type: String, zone: Dictionary, typed: bool, early: bool, rng: RandomNumberGenerator) -> String:
	var roster: Dictionary = zone.get("roster", {})
	var cfg: Dictionary = _zones_cfg.get("roster_encounters", {})
	var size_w: Dictionary = roster.get(room_type + "_size_weights", {"1": 1})
	if early and room_type == "wild" and cfg.has("early_size_weights"):
		size_w = cfg["early_size_weights"]
	var size: int = int(_weighted_key(size_w, rng))
	var bonus: int = int(cfg.get("elite_tier_bonus", 0)) if room_type == "elite" else 0
	var tier_w: Dictionary = {}
	for k: String in (roster.get("tier_weights", {"1": 1}) as Dictionary).keys():
		var t: String = str(mini(ROSTER_MAX_TIER, int(k) + bonus))
		tier_w[t] = float(tier_w.get(t, 0.0)) + float(roster["tier_weights"][k])
	var type_id: String = String(zone.get("type_id", "")) if typed else ""
	var ids: Array[String] = []
	for i: int in size:
		var pid: String = _draw_roster_pokemon(type_id, int(_weighted_key(tier_w, rng)), ids, rng)
		if pid.is_empty():
			break
		ids.append(pid)
	return ROSTER_ENCOUNTER_PREFIX + ",".join(ids)


## One wild_ok roster Pokémon of `type_id` ("" = any) and `tier` (nearest tier with a free candidate if none), not in
## `exclude`; "" if there is none at all.
func _draw_roster_pokemon(type_id: String, tier: int, exclude: Array[String], rng: RandomNumberGenerator) -> String:
	var by_tier: Dictionary = _roster_wild.get(type_id, {})
	for dist: int in range(0, ROSTER_MAX_TIER):
		for t: int in [tier - dist, tier + dist]:
			var free: Array[String] = []
			for pid: String in by_tier.get(t, []):
				if not exclude.has(pid):
					free.append(pid)
			if not free.is_empty():
				return free[rng.randi_range(0, free.size() - 1)]
	return ""


## Weighted pick of a key of `weights` (key -> number), keys in sorted order (deterministic).
func _weighted_key(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var keys: Array = weights.keys()
	keys.sort()
	var total: float = 0.0
	for k: String in keys:
		total += float(weights[k])
	var roll: float = rng.randf() * total
	for k: String in keys:
		if roll < float(weights[k]):
			return k
		roll -= float(weights[k])
	return String(keys[keys.size() - 1])


## Number of wild_ok roster Pokémon having `type_id` ("" = any), all tiers.
func get_roster_wild_count(type_id: String = "") -> int:
	var n: int = 0
	for t: int in (_roster_wild.get(type_id, {}) as Dictionary).keys():
		n += (_roster_wild[type_id][t] as Array).size()
	return n


## Roster entry (copy) of a roster id ({} if not a roster Pokémon): tier, generation, stage, roles, evolves_to...
func get_roster_entry(pokemon_id: String) -> Dictionary:
	return (_roster_ids.get(pokemon_id, {}) as Dictionary).duplicate(true)


## Ids of every roster Pokémon (file order).
func get_roster_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_roster_ids.keys())
	return ids


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


# --- Zones, gyms, badges (story 012) ----------------------------------------------------------------

## Number of zones (= gyms = badges) in a run (zones.json zone_count).
func get_zone_count() -> int:
	return int(_zones_cfg.get("zone_count", 0))


## Gym type ids that may be drawn (pool of zones.json gym_types), sorted.
func get_gym_type_ids() -> Array[String]:
	var ids: Array[String] = []
	for k: String in (_zones_cfg.get("gym_types", {}) as Dictionary).keys():
		ids.append(k)
	ids.sort()
	return ids


## Draws the zones of a new run with the injected (seeded) rng: `zone_count` DIFFERENT gym types out of the pool,
## in draw order = zone order (difficulty comes from the zone index, not from the type). Each zone is a dict:
## {index (0-based), number (1-based), type_id, type_name, leader, gym_encounter, badge_id, badge_name, wild_pool,
## elite_pool, gym_modifiers {hp_multiplier, strength_bonus}, modifiers {hp_multiplier, strength_bonus},
## wild_type_share, elite_type_share, early_pool, unlocked_wild_pools, unlocked_elite_pools}.
## Empty (push_error) if the data is not loaded. Same rng state = same zones.
func draw_zones(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var zones: Array[Dictionary] = []
	var count: int = get_zone_count()
	var pool: Array[String] = get_gym_type_ids()
	if count <= 0 or pool.size() < count:
		push_error("GameData: zones are not loaded or the gym type pool is too small")
		return zones
	for i: int in range(pool.size() - 1, 0, -1):  # Fisher-Yates
		var j: int = rng.randi_range(0, i)
		var tmp: String = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	pool = _gym_types_leaving_league(pool, count)
	if pool.size() < count:
		push_error("GameData: the gym type pool cannot leave enough Conseil 4 types free")
		return zones
	var gyms: Dictionary = _zones_cfg["gym_types"]
	var tiers: Array = _zones_cfg["tiers"]
	for i: int in count:
		var type_id: String = pool[i]
		var g: Dictionary = gyms[type_id]
		var tier: Dictionary = tiers[i]
		var roster: Dictionary = (tier.get("roster", {}) as Dictionary).duplicate(true)
		var gym_encounter: String = String(g.get("encounter", ""))
		if gym_encounter.is_empty():  # story 013b: auto team of the type from the roster, drawn now (fixed for the run)
			var team: Array[String] = []
			for t_v: Variant in roster.get("gym_team_tiers", []):
				var pid: String = _draw_roster_pokemon(type_id, int(t_v), team, rng)
				if not pid.is_empty():
					team.append(pid)
			gym_encounter = ROSTER_ENCOUNTER_PREFIX + ",".join(team)
		var zone: Dictionary = {"index": i, "number": i + 1, "type_id": type_id, "type_name": get_type_name(type_id),
				"leader": String(g["leader"]), "gym_encounter": gym_encounter, "badge_id": String(g["badge_id"]),
				"badge_name": String(g["badge_name"]), "wild_pool": String(g.get("wild_pool", "")),
				"elite_pool": String(g.get("elite_pool", "")), "roster": roster,
				"gym_modifiers": _modifiers_of(tier["gym_modifiers"]), "modifiers": _modifiers_of(tier["modifiers"]),
				"wild_type_share": float(tier["wild_type_share"]), "elite_type_share": float(tier["elite_type_share"]),
				"early_pool": bool(tier["early_pool"]), "unlocked_wild_pools": [], "unlocked_elite_pools": []}
		for badge_number: int in range(1, i + 1):  # badges earned in the previous zones
			var unlock: Dictionary = (get_badge_reward(badge_number).get("unlock_pools", {}) as Dictionary)
			for pool_id: String in unlock.get("wild", []):
				if not (zone["unlocked_wild_pools"] as Array).has(pool_id):
					(zone["unlocked_wild_pools"] as Array).append(pool_id)
			for pool_id: String in unlock.get("elite", []):
				if not (zone["unlocked_elite_pools"] as Array).has(pool_id):
					(zone["unlocked_elite_pools"] as Array).append(pool_id)
		zones.append(zone)
	return zones


## Story 013b: the first `count` types of the shuffled `pool` such that at least member_count Conseil 4 types
## (league.json member_type_pool) stay free; a league type that would break that is skipped (gym-then-league draw).
## Without a league = the first `count` types. Fewer than `count` if impossible.
func _gym_types_leaving_league(pool: Array[String], count: int) -> Array[String]:
	var league: Array = _league_cfg.get("member_type_pool", [])
	var free_league: int = league.size()
	var needed: int = int(_league_cfg.get("member_count", 0))
	var result: Array[String] = []
	for t: String in pool:
		if result.size() >= count:
			break
		if league.has(t):
			if free_league - 1 < needed:
				continue
			free_league -= 1
		result.append(t)
	return result


func _modifiers_of(m: Dictionary) -> Dictionary:
	return {"hp_multiplier": float(m["hp_multiplier"]), "strength_bonus": int(m["strength_bonus"])}


## The act config (same shape as get_act_config) for zone number `zone_number` (1-based): act1.json with the
## zone_overrides of zones.json merged in (map fields, forced_floors). Feed it to MapGenerator.generate.
func get_zone_act_config(zone_number: int) -> Dictionary:
	var config: Dictionary = get_act_config()
	if config.is_empty():
		return config
	var ov: Dictionary = (_zones_cfg.get("zone_overrides", {}) as Dictionary).get(str(zone_number), {})
	for key: String in (ov.get("map", {}) as Dictionary).keys():
		config["map"][key] = ov["map"][key]
	if ov.has("forced_floors"):
		config["placement"]["forced_floors"] = (ov["forced_floors"] as Dictionary).duplicate()
	return config


## Floors of the map of zone `zone_number` (1-based).
func get_zone_floors(zone_number: int) -> int:
	return int((get_zone_act_config(zone_number).get("map", {}) as Dictionary).get("floors", 0))


## Fight modifiers for a fight in `room_type` inside `zone`: the room's (act1.json) combined with the zone's
## (hp_multiplier multiplied, strength_bonus added). The gym uses the tier's gym_modifiers, wild / elite its
## modifiers, other rooms nothing. Without a zone = get_room_modifiers.
func get_fight_modifiers(room_type: String, zone: Dictionary = {}) -> Dictionary:
	var m: Dictionary = get_room_modifiers(room_type)
	if zone.is_empty():
		return m
	var zm: Dictionary = {}
	if room_type == ROOM_GYM:
		zm = zone["gym_modifiers"]
	elif room_type in ZONE_TYPED_ROOMS:
		zm = zone["modifiers"]
	else:
		return m
	return {"hp_multiplier": float(m["hp_multiplier"]) * float(zm["hp_multiplier"]),
			"strength_bonus": int(m["strength_bonus"]) + int(zm["strength_bonus"])}


## Reward of badge number `badge_number` (1-based) {max_hp, hand_size, energy_per_turn, heal_percent (always set),
## unlock_pools {wild, elite}} (copy); {} if unknown.
func get_badge_reward(badge_number: int) -> Dictionary:
	var rewards: Dictionary = _zones_cfg.get("badge_rewards", {})
	if not rewards.has(str(badge_number)):
		return {}
	var r: Dictionary = (rewards[str(badge_number)] as Dictionary).duplicate(true)
	if not r.has("heal_percent"):
		r["heal_percent"] = float(_zones_cfg.get("badge_heal_percent", 0))
	return r


## Badge numbers after which the starter evolves (zones.json evolution_after_badges).
func get_evolution_after_badges() -> Array[int]:
	var result: Array[int] = []
	for n: Variant in _zones_cfg.get("evolution_after_badges", []):
		result.append(int(n))
	return result


## Validates zones.json against the loaded cards / pokemon / act data. Reports every problem, never crashes.
func _load_zones(root: Dictionary) -> bool:
	var ok: bool = true
	if not _is_positive_int(root.get("zone_count", null)):
		push_error("GameData: zones file needs a positive integer 'zone_count'")
		return false
	var count: int = int(root["zone_count"])
	if not _is_positive_int(root.get("gym_team_size", null)):
		push_error("GameData: zones file needs a positive integer 'gym_team_size'")
		return false
	var team_size: int = int(root["gym_team_size"])
	var pools: Dictionary = _act.get("encounter_pools", {})
	# Gym types.
	var gyms_v: Variant = root.get("gym_types", null)
	if not (gyms_v is Dictionary):
		push_error("GameData: zones file needs a 'gym_types' object")
		return false
	var gyms: Dictionary = gyms_v
	if gyms.size() < count:
		push_error("GameData: gym_types has %d types, zone_count is %d" % [gyms.size(), count])
		ok = false
	var badge_ids: Dictionary = {}
	for type_id: String in gyms.keys():
		var label: String = "gym type '%s'" % type_id
		var g_v: Variant = gyms[type_id]
		if not _type_chart.is_known_type(type_id) or not _starter_cards_by_type.has(type_id) or not (g_v is Dictionary):
			push_error("GameData: %s must be an object for a known type that has starter cards" % label)
			ok = false
			continue
		var g: Dictionary = g_v
		for key: String in ["leader", "badge_id", "badge_name"]:
			if not (g.get(key, null) is String) or String(g[key]).is_empty():
				push_error("GameData: %s needs a non-empty '%s'" % [label, key])
				ok = false
		if g.get("badge_id", null) is String:
			if badge_ids.has(g["badge_id"]):
				push_error("GameData: %s: badge_id '%s' is already used" % [label, g["badge_id"]])
				ok = false
			badge_ids[g["badge_id"]] = true
		for key: String in ["wild_pool", "elite_pool"]:  # story 013b: optional (missing = typed fights from the roster)
			if g.has(key) and (not (g[key] is String) or not pools.has(g[key])):
				push_error("GameData: %s: '%s' must name an encounter pool of the act file" % [label, key])
				ok = false
		if (not g.has("encounter") or not g.has("wild_pool") or not g.has("elite_pool")) \
				and get_roster_wild_count(type_id) < maxi(team_size, Battle.MAX_ENEMIES):
			push_error("GameData: %s has no fixed team / pools but fewer than %d roster Pokémon of that type" % [label, maxi(team_size, Battle.MAX_ENEMIES)])
			ok = false
		var team_v: Variant = _encounters.get(g.get("encounter", null), null) if g.get("encounter", null) is String else null
		if not g.has("encounter"):
			pass  # auto team drawn by draw_zones
		elif not (team_v is Array) or (team_v as Array).size() != team_size:
			push_error("GameData: %s: 'encounter' must name an encounter of exactly %d Pokémon" % [label, team_size])
			ok = false
		else:
			var carriers: int = 0
			for enemy_id: String in (team_v as Array):
				if (get_pokemon_info(enemy_id)["types"] as Array).has(type_id):
					carriers += 1
			if carriers < 1:
				push_error("GameData: %s: nobody in the team '%s' has that type" % [label, g["encounter"]])
				ok = false
		if get_carriers_for_type(type_id).size() < team_size:
			push_error("GameData: %s: fewer than %d roster Pokémon carry that type" % [label, team_size])
			ok = false
	# Tiers.
	var tiers_v: Variant = root.get("tiers", null)
	if not (tiers_v is Array) or (tiers_v as Array).size() != count:
		push_error("GameData: zones file needs a 'tiers' array with one entry per zone (%d)" % count)
		return false
	var prev_hp: float = 0.0
	var prev_str: int = 0
	for i: int in count:
		var tier_v: Variant = (tiers_v as Array)[i]
		var label: String = "tier #%d" % (i + 1)
		if not (tier_v is Dictionary):
			push_error("GameData: %s must be an object" % label)
			ok = false
			continue
		var tier: Dictionary = tier_v
		var tier_ok: bool = true
		for key: String in ["gym_modifiers", "modifiers"]:
			var m_v: Variant = tier.get(key, null)
			if not (m_v is Dictionary) or not _is_number((m_v as Dictionary).get("hp_multiplier", null)) \
					or (m_v as Dictionary)["hp_multiplier"] <= 0 or not _is_number((m_v as Dictionary).get("strength_bonus", null)) \
					or (m_v as Dictionary)["strength_bonus"] < 0 or (m_v as Dictionary)["strength_bonus"] != floorf((m_v as Dictionary)["strength_bonus"]):
				push_error("GameData: %s.%s needs {hp_multiplier > 0, strength_bonus integer >= 0}" % [label, key])
				tier_ok = false
		for key: String in ["wild_type_share", "elite_type_share"]:
			if not (_is_number(tier.get(key, null)) and tier[key] >= 0 and tier[key] <= 1):
				push_error("GameData: %s.%s must be between 0 and 1" % [label, key])
				tier_ok = false
		if not (tier.get("early_pool", null) is bool):
			push_error("GameData: %s.early_pool must be a boolean" % label)
			tier_ok = false
		if tier.has("roster") or root.has("roster_encounters"):
			tier_ok = _check_tier_roster(label, tier.get("roster", null), team_size) and tier_ok
		if tier_ok:
			var gm: Dictionary = tier["gym_modifiers"]
			if float(gm["hp_multiplier"]) < prev_hp or int(gm["strength_bonus"]) < prev_str:
				push_error("GameData: %s: gym difficulty must not decrease from one zone to the next" % label)
				tier_ok = false
			prev_hp = float(gm["hp_multiplier"])
			prev_str = int(gm["strength_bonus"])
		ok = ok and tier_ok
	var re_v: Variant = root.get("roster_encounters", {})
	if not (re_v is Dictionary) or not (_is_number((re_v as Dictionary).get("elite_tier_bonus", 0)) and (re_v as Dictionary).get("elite_tier_bonus", 0) >= 0) \
			or ((re_v as Dictionary).has("early_size_weights") and not _check_size_weights((re_v as Dictionary)["early_size_weights"])):
		push_error("GameData: zones 'roster_encounters' needs elite_tier_bonus >= 0 and valid early_size_weights")
		ok = false
	# Per-zone map overrides: the merged config must still describe a valid map.
	var overrides_v: Variant = root.get("zone_overrides", {})
	if not (overrides_v is Dictionary):
		push_error("GameData: zones 'zone_overrides' must be an object")
		return false
	for key: String in (overrides_v as Dictionary).keys():
		if not key.is_valid_int() or int(key) < 1 or int(key) > count or not ((overrides_v as Dictionary)[key] is Dictionary):
			push_error("GameData: zone_overrides['%s'] must be an object for a zone number 1..%d" % [key, count])
			ok = false
			continue
		var m: Dictionary = (_act.get("map", {}) as Dictionary).duplicate()
		var forced: Dictionary = ((_act.get("placement", {}) as Dictionary).get("forced_floors", {}) as Dictionary).duplicate()
		var ov: Dictionary = (overrides_v as Dictionary)[key]
		for k: String in (ov.get("map", {}) as Dictionary).keys():
			m[k] = ov["map"][k]
		if ov.has("forced_floors") and ov["forced_floors"] is Dictionary:
			forced = ov["forced_floors"]
		var map_ok: bool = true
		for k: String in ["floors", "width", "start_nodes", "paths", "boss_floor_nodes"]:
			map_ok = map_ok and _is_positive_int(m.get(k, null))
		if map_ok:
			map_ok = int(m["floors"]) >= 3 and int(m["start_nodes"]) <= int(m["width"]) and int(m["paths"]) >= int(m["start_nodes"]) \
					and int(m["boss_floor_nodes"]) == 1 and forced.get(str(int(m["floors"])), null) == "boss"
		if not map_ok:
			push_error("GameData: zone_overrides['%s'] gives an invalid map (floors >= 3, start_nodes <= width, paths >= start_nodes, last floor 'boss')" % key)
			ok = false
	# Badge rewards.
	var rewards_v: Variant = root.get("badge_rewards", null)
	if not (rewards_v is Dictionary):
		push_error("GameData: zones file needs a 'badge_rewards' object")
		return false
	var limits_v: Variant = root.get("bonus_limits", {})
	var limits: Dictionary = limits_v if limits_v is Dictionary else {}
	var totals: Dictionary = {"hand_size": 0, "energy_per_turn": 0}
	if not (_is_number(root.get("badge_heal_percent", null)) and root["badge_heal_percent"] >= 0 and root["badge_heal_percent"] <= 100):
		push_error("GameData: zones file needs 'badge_heal_percent' between 0 and 100")
		ok = false
	for n: int in range(1, count + 1):
		var r_v: Variant = (rewards_v as Dictionary).get(str(n), null)
		var label: String = "badge_rewards['%d']" % n
		if not (r_v is Dictionary):
			push_error("GameData: %s is missing (one reward per badge)" % label)
			ok = false
			continue
		var r: Dictionary = r_v
		for key: String in ["max_hp", "hand_size", "energy_per_turn"]:
			if r.has(key):
				if not (_is_number(r[key]) and r[key] >= 0 and r[key] == floorf(r[key])):
					push_error("GameData: %s.%s must be an integer >= 0" % [label, key])
					ok = false
				elif totals.has(key):
					totals[key] += int(r[key])
		if r.has("heal_percent") and not (_is_number(r["heal_percent"]) and r["heal_percent"] >= 0 and r["heal_percent"] <= 100):
			push_error("GameData: %s.heal_percent must be between 0 and 100" % label)
			ok = false
		var unlock_v: Variant = r.get("unlock_pools", {})
		if not (unlock_v is Dictionary):
			push_error("GameData: %s.unlock_pools must be an object" % label)
			ok = false
			continue
		for key: String in (unlock_v as Dictionary).keys():
			var list_v: Variant = (unlock_v as Dictionary)[key]
			if key not in ZONE_TYPED_ROOMS or not (list_v is Array):
				push_error("GameData: %s.unlock_pools['%s'] must be an array under 'wild' or 'elite'" % [label, key])
				ok = false
				continue
			for pool_id: Variant in (list_v as Array):
				if not (pool_id is String) or not pools.has(pool_id):
					push_error("GameData: %s unlocks unknown encounter pool '%s'" % [label, str(pool_id)])
					ok = false
	for key: String in totals.keys():
		if totals[key] > int(limits.get(key, 0)):
			push_error("GameData: badge rewards give %d total '%s', the limit (bonus_limits) is %d" % [totals[key], key, int(limits.get(key, 0))])
			ok = false
	var evo_v: Variant = root.get("evolution_after_badges", null)
	if not (evo_v is Array):
		push_error("GameData: zones file needs an 'evolution_after_badges' array")
		ok = false
	else:
		for n_v: Variant in (evo_v as Array):
			if not _is_positive_int(n_v) or int(n_v) > count:
				push_error("GameData: evolution_after_badges has an invalid badge number '%s'" % str(n_v))
				ok = false
			elif (evo_v as Array).count(n_v) > 1:
				push_error("GameData: evolution_after_badges lists badge %d twice" % int(n_v))
				ok = false
	if ok:
		_zones_cfg = root
	return ok


## Story 013b: validates a tier's roster block (shares 0..1, tier / size weights, gym_team_tiers of gym_team_size tiers).
func _check_tier_roster(label: String, r_v: Variant, team_size: int) -> bool:
	if not (r_v is Dictionary):
		push_error("GameData: %s needs a 'roster' object" % label)
		return false
	var r: Dictionary = r_v
	var ok: bool = true
	for key: String in ["wild_share", "elite_share"]:
		if not (_is_number(r.get(key, null)) and r[key] >= 0 and r[key] <= 1):
			push_error("GameData: %s.roster.%s must be between 0 and 1" % [label, key])
			ok = false
	if not _check_weights_by_int_key(r.get("tier_weights", null), 1, ROSTER_MAX_TIER):
		push_error("GameData: %s.roster.tier_weights must map tiers '1'..'%d' to weights >= 0 (sum > 0)" % [label, ROSTER_MAX_TIER])
		ok = false
	for key: String in ["wild_size_weights", "elite_size_weights"]:
		if not _check_size_weights(r.get(key, null)):
			push_error("GameData: %s.roster.%s must map sizes %d..%d to weights >= 0 (sum > 0)" % [label, key, Battle.MIN_ENEMIES, Battle.MAX_ENEMIES])
			ok = false
	var gt: Variant = r.get("gym_team_tiers", null)
	if not (gt is Array) or (gt as Array).size() != team_size:
		push_error("GameData: %s.roster.gym_team_tiers must hold %d tiers" % [label, team_size])
		ok = false
	else:
		for t: Variant in (gt as Array):
			if not _is_positive_int(t) or int(t) > ROSTER_MAX_TIER:
				push_error("GameData: %s.roster.gym_team_tiers has an invalid tier '%s'" % [label, str(t)])
				ok = false
	return ok


func _check_size_weights(w: Variant) -> bool:
	return _check_weights_by_int_key(w, Battle.MIN_ENEMIES, Battle.MAX_ENEMIES)


func _check_weights_by_int_key(w_v: Variant, lo: int, hi: int) -> bool:
	if not (w_v is Dictionary) or (w_v as Dictionary).is_empty():
		return false
	var total: float = 0.0
	for k: Variant in (w_v as Dictionary).keys():
		var v: Variant = (w_v as Dictionary)[k]
		if not (k is String) or not String(k).is_valid_int() or int(k) < lo or int(k) > hi or not _is_number(v) or v < 0:
			return false
		total += float(v)
	return total > 0


# --- Conseil 4, Maître, boss final (story 013) -------------------------------------------------------

## True once league.json is loaded and valid (the run goes to the Conseil 4 after the last badge).
func has_league() -> bool:
	return not _league_cfg.is_empty()


## Number of Conseil 4 members per run (league.json member_count); 0 without a league.
func get_league_member_count() -> int:
	return int(_league_cfg.get("member_count", 0))


## Total league fights of a run: members + the Maître + the final boss (0 without a league).
func get_league_fight_count() -> int:
	return get_league_member_count() + 2 if has_league() else 0


## Member type pool (league.json member_type_pool), in file order.
func get_league_type_pool() -> Array[String]:
	var result: Array[String] = []
	for t: Variant in _league_cfg.get("member_type_pool", []):
		result.append(String(t))
	return result


## % of max HP healed after each won league fight (league.json heal_percent_between_fights).
func get_league_heal_percent() -> float:
	return float(_league_cfg.get("heal_percent_between_fights", 0))


## Rarity weights of the card reward after a league fight (league.json reward_rarity_weights, copy).
func get_league_reward_weights() -> Dictionary:
	return (_league_cfg.get("reward_rarity_weights", {}) as Dictionary).duplicate()


## True for an enemy flagged `boss: true` in pokemon.json (final boss: never capturable / proposable).
func is_boss_pokemon(pokemon_id: String) -> bool:
	return bool((_enemies.get(pokemon_id, {}) as Dictionary).get("boss", false))


## Enemy ids of an encounter (copy; empty if unknown). Story 013b: also decodes a generated "roster:<id>,..." id
## (empty if any id is unknown or the count is outside Battle.MIN_ENEMIES..MAX_ENEMIES).
func get_encounter_enemy_ids(encounter_id: String) -> Array[String]:
	var result: Array[String] = []
	if encounter_id.begins_with(ROSTER_ENCOUNTER_PREFIX):
		for eid: String in encounter_id.substr(ROSTER_ENCOUNTER_PREFIX.length()).split(",", false):
			if not _enemies.has(eid):
				return [] as Array[String]
			result.append(eid)
		if result.size() < Battle.MIN_ENEMIES or result.size() > Battle.MAX_ENEMIES:
			result.clear()
		return result
	result.assign(_encounters.get(encounter_id, []))
	return result


## True for a generated roster encounter id ("roster:<id>,...").
func is_roster_encounter(encounter_id: String) -> bool:
	return encounter_id.begins_with(ROSTER_ENCOUNTER_PREFIX)


## Draws the league fights of a run with the injected (seeded) rng. `gym_type_ids` = the run's 8 gym types (excluded
## from the member draw; if fewer than member_count pool types remain, the excluded pool types are reused as a fallback,
## drawn after the others). Returns member_count + 2 dicts in fight order:
## {stage (0-based), index (1-based), total, kind ("member" | "champion" | "final_boss"), name, title, type_id,
##  type_name, type_ids (all types shown, e.g. the boss's 2 types), encounter, modifiers {hp_multiplier, strength_bonus}}.
## Empty without a league. Same rng state + same gym types = same league.
func draw_league(rng: RandomNumberGenerator, gym_type_ids: Array[String] = []) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not has_league():
		return result
	var free: Array[String] = []
	var reused: Array[String] = []
	for t: String in get_league_type_pool():
		if gym_type_ids.has(t):
			reused.append(t)
		else:
			free.append(t)
	_shuffle(free, rng)
	_shuffle(reused, rng)
	var picked: Array[String] = free.duplicate()
	picked.append_array(reused)  # fallback: gym types only once the free ones run out
	var count: int = get_league_member_count()
	var total: int = count + 2
	var members: Dictionary = _league_cfg["members_by_type"]
	var mods: Array = _league_cfg["member_modifiers"]
	for i: int in count:
		var type_id: String = picked[i]
		var m: Dictionary = members[type_id]
		result.append({"stage": i, "index": i + 1, "total": total, "kind": "member", "name": String(m["name"]),
				"title": String(m["title"]), "type_id": type_id, "type_name": get_type_name(type_id), "type_ids": [type_id],
				"encounter": String(m["encounter"]), "modifiers": _modifiers_of(mods[i])})
	var c: Dictionary = _league_cfg["champion"]
	result.append({"stage": count, "index": count + 1, "total": total, "kind": "champion", "name": String(c["name"]),
			"title": String(c["title"]), "type_id": String(c["type"]), "type_name": get_type_name(String(c["type"])),
			"type_ids": [String(c["type"])], "encounter": String(c["encounter"]), "modifiers": _modifiers_of(c["modifiers"])})
	var b: Dictionary = _league_cfg["final_boss"]
	var boss_types: Array[String] = get_pokemon_info(get_encounter_enemy_ids(String(b["encounter"]))[0])["types"]
	result.append({"stage": count + 1, "index": count + 2, "total": total, "kind": "final_boss", "name": String(b["name"]),
			"title": String(b["title"]), "type_id": boss_types[0], "type_name": get_type_name(boss_types[0]),
			"type_ids": boss_types.duplicate(), "encounter": String(b["encounter"]), "modifiers": _modifiers_of(b["modifiers"])})
	return result


## Effective strength of an encounter under modifiers: {hp: sum of max_hp x hp_multiplier (rounded up as in battle),
## max_attack: strongest action value + strength_bonus}. Used by the league validation (boss > Maître).
func get_encounter_power(encounter_id: String, modifiers: Dictionary) -> Dictionary:
	var hp: int = 0
	var best: int = 0
	for eid: String in get_encounter_enemy_ids(encounter_id):
		var def: Dictionary = _enemies[eid]
		hp += maxi(1, ceili(snappedf(int(def["max_hp"]) * float(modifiers["hp_multiplier"]), 0.0001)))
		for a: Dictionary in def["actions"]:
			if String(a.get("type", "")) == EnemyIntent.TYPE_ATTACK:
				best = maxi(best, int(a["value"]) + int(modifiers["strength_bonus"]))
	return {"hp": hp, "max_attack": best}


func _shuffle(list: Array[String], rng: RandomNumberGenerator) -> void:
	for i: int in range(list.size() - 1, 0, -1):  # Fisher-Yates
		var j: int = rng.randi_range(0, i)
		var tmp: String = list[i]
		list[i] = list[j]
		list[j] = tmp


func _valid_modifiers(m_v: Variant) -> bool:
	if not (m_v is Dictionary):
		return false
	var m: Dictionary = m_v
	return _is_number(m.get("hp_multiplier", null)) and m["hp_multiplier"] > 0 and _is_number(m.get("strength_bonus", null)) \
			and m["strength_bonus"] >= 0 and m["strength_bonus"] == floorf(m["strength_bonus"])


## True if `a` is at least `b` on both fields and strictly above on one (`strict`) / or just at least (`not strict`).
func _mods_above(a: Dictionary, b: Dictionary, strict: bool) -> bool:
	var ge: bool = float(a["hp_multiplier"]) >= float(b["hp_multiplier"]) and int(a["strength_bonus"]) >= int(b["strength_bonus"])
	if not strict:
		return ge
	return ge and (float(a["hp_multiplier"]) > float(b["hp_multiplier"]) or int(a["strength_bonus"]) > int(b["strength_bonus"]))


## Checks that `encounter_id` exists and (when `type_id` is set) every Pokémon of it carries `type_id`.
func _check_league_team(label: String, encounter_id: Variant, type_id: String) -> bool:
	if not (encounter_id is String) or not _encounters.has(encounter_id):
		push_error("GameData: %s references unknown encounter '%s'" % [label, str(encounter_id)])
		return false
	var ok: bool = true
	if not type_id.is_empty():
		for eid: String in get_encounter_enemy_ids(encounter_id):
			if not (get_pokemon_info(eid)["types"] as Array).has(type_id):
				push_error("GameData: %s: '%s' does not have the type '%s'" % [label, eid, type_id])
				ok = false
	return ok


## Validates league.json against the loaded pokemon / zones data. Reports every problem, never crashes.
func _load_league(root: Dictionary) -> bool:
	var ok: bool = true
	if not _is_positive_int(root.get("member_count", null)):
		push_error("GameData: league file needs a positive integer 'member_count'")
		return false
	var count: int = int(root["member_count"])
	var pool_v: Variant = root.get("member_type_pool", null)
	var members_v: Variant = root.get("members_by_type", null)
	if not (pool_v is Array) or not (members_v is Dictionary):
		push_error("GameData: league file needs a 'member_type_pool' array and a 'members_by_type' object")
		return false
	var seen: Dictionary = {}
	for t_v: Variant in (pool_v as Array):
		if not (t_v is String) or not _type_chart.is_known_type(t_v) or seen.has(t_v):
			push_error("GameData: member_type_pool has an unknown or duplicate type '%s'" % str(t_v))
			ok = false
			continue
		seen[t_v] = true
		var m_v: Variant = (members_v as Dictionary).get(t_v, null)
		var label: String = "league member '%s'" % t_v
		if not (m_v is Dictionary):
			push_error("GameData: %s is missing from members_by_type" % label)
			ok = false
			continue
		var m: Dictionary = m_v
		if not (m.get("name", null) is String) or String(m["name"]).is_empty() or not (m.get("title", null) is String):
			push_error("GameData: %s needs a non-empty 'name' and a 'title'" % label)
			ok = false
		ok = _check_league_team(label, m.get("encounter", null), String(t_v)) and ok
	if seen.size() < count:
		push_error("GameData: member_type_pool has %d valid types, member_count is %d" % [seen.size(), count])
		ok = false
	var mods_v: Variant = root.get("member_modifiers", null)
	var last_mods: Dictionary = {}
	if not (mods_v is Array) or (mods_v as Array).size() != count:
		push_error("GameData: league 'member_modifiers' must be an array of %d modifiers" % count)
		ok = false
	else:
		var tiers: Array = _zones_cfg.get("tiers", [])
		var prev: Dictionary = (tiers[tiers.size() - 1] as Dictionary)["gym_modifiers"] if not tiers.is_empty() else {}
		for i: int in count:
			var m_v: Variant = (mods_v as Array)[i]
			if not _valid_modifiers(m_v):
				push_error("GameData: member_modifiers[%d] needs {hp_multiplier > 0, strength_bonus integer >= 0}" % i)
				ok = false
				prev = {}
				continue
			if not prev.is_empty() and not _mods_above(m_v, prev, i == 0):
				push_error("GameData: member_modifiers[%d] must be above the last gym (first member) and never decrease" % i)
				ok = false
			prev = m_v
			last_mods = m_v
	var champ_v: Variant = root.get("champion", null)
	var champ_power: Dictionary = {}
	if not (champ_v is Dictionary):
		push_error("GameData: league file needs a 'champion' object")
		ok = false
	else:
		var c: Dictionary = champ_v
		var ctype: String = String(c.get("type", "")) if c.get("type", null) is String else ""
		if not (c.get("name", null) is String) or String(c["name"]).is_empty() or not (c.get("title", null) is String) \
				or not _type_chart.is_known_type(ctype):
			push_error("GameData: league champion needs a 'name', a 'title' and a known 'type'")
			ok = false
		elif not _check_league_team("league champion", c.get("encounter", null), ctype):
			ok = false
		elif not _valid_modifiers(c.get("modifiers", null)):
			push_error("GameData: league champion needs valid 'modifiers'")
			ok = false
		else:
			if not last_mods.is_empty() and not _mods_above(c["modifiers"], last_mods, true):
				push_error("GameData: the league champion must be harder than the last member (modifiers)")
				ok = false
			champ_power = get_encounter_power(String(c["encounter"]), c["modifiers"])
	var boss_v: Variant = root.get("final_boss", null)
	if not (boss_v is Dictionary):
		push_error("GameData: league file needs a 'final_boss' object")
		ok = false
	else:
		var b: Dictionary = boss_v
		if not (b.get("name", null) is String) or String(b["name"]).is_empty() or not (b.get("title", null) is String):
			push_error("GameData: final_boss needs a 'name' and a 'title'")
			ok = false
		elif not _check_league_team("final_boss", b.get("encounter", null), ""):
			ok = false
		elif get_encounter_enemy_ids(String(b["encounter"])).size() != 1:
			push_error("GameData: final_boss encounter must hold exactly one Pokémon")
			ok = false
		elif not is_boss_pokemon(get_encounter_enemy_ids(String(b["encounter"]))[0]):
			push_error("GameData: the final_boss Pokémon must be flagged 'boss': true in pokemon.json")
			ok = false
		elif not _valid_modifiers(b.get("modifiers", null)):
			push_error("GameData: final_boss needs valid 'modifiers'")
			ok = false
		elif not champ_power.is_empty():
			var bp: Dictionary = get_encounter_power(String(b["encounter"]), b["modifiers"])
			if int(bp["hp"]) <= int(champ_power["hp"]) or int(bp["max_attack"]) <= int(champ_power["max_attack"]):
				push_error("GameData: final_boss (%s) must be stronger than the champion's team (%s): HP and strongest attack" % [str(bp), str(champ_power)])
				ok = false
	if seen.size() >= count and not _zones_cfg.is_empty():  # story 013b: 8 gyms + member_count free league types
		var non_league: int = 0
		var league_in_gyms: int = 0
		for gt: String in get_gym_type_ids():
			if seen.has(gt):
				league_in_gyms += 1
			else:
				non_league += 1
		if non_league + mini(league_in_gyms, seen.size() - count) < get_zone_count():
			push_error("GameData: the gym type pool cannot give %d gyms while leaving %d Conseil 4 types free" % [get_zone_count(), count])
			ok = false
	for pid: String in _starter_candidates:
		if is_boss_pokemon(pid):
			push_error("GameData: boss Pokémon '%s' cannot be a starter candidate" % pid)
			ok = false
	var heal: Variant = root.get("heal_percent_between_fights", null)
	if not (_is_number(heal) and heal >= 0 and heal <= 100):
		push_error("GameData: league 'heal_percent_between_fights' must be a number between 0 and 100")
		ok = false
	var w_v: Variant = root.get("reward_rarity_weights", null)
	if not (w_v is Dictionary) or not _check_rarity_weights("league reward", w_v):
		push_error("GameData: league file needs valid 'reward_rarity_weights'")
		ok = false
	if ok:
		_league_cfg = root
	return ok


# --- Items, potions, economy (story 006) ----------------------------------------------------------

## Held item by id, or null (with push_error) if unknown.
func get_item(item_id: String) -> ItemData:
	if not _items.has(item_id):
		push_error("GameData: unknown item id '%s'" % item_id)
		return null
	return _items[item_id]


## Every held item id, in file order.
func get_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for k: String in _items.keys():
		ids.append(k)
	return ids


## Potion by id, or null (with push_error) if unknown.
func get_potion(potion_id: String) -> PotionData:
	if not _potions.has(potion_id):
		push_error("GameData: unknown potion id '%s'" % potion_id)
		return null
	return _potions[potion_id]


## Every potion id, in file order.
func get_potion_ids() -> Array[String]:
	var ids: Array[String] = []
	for k: String in _potions.keys():
		ids.append(k)
	return ids


## Potions a run may carry at once (potions.json max_carried).
func get_max_potions() -> int:
	return _max_potions


## Pokédollars a new run starts with (shop.json).
func get_starting_money() -> int:
	return int(_shop_cfg.get("starting_money", 0))


## Loot rule of a fight room type {money_min, money_max, item_chance, potion_chance}; {} = no loot (e.g. boss).
func get_loot_config(room_type: String) -> Dictionary:
	return ((_shop_cfg.get("loot", {}) as Dictionary).get(room_type, {}) as Dictionary).duplicate()


## Rarity -> weight used to draw held items (shop.json item_rarity_weights).
func get_item_rarity_weights() -> Dictionary:
	return (_shop_cfg.get("item_rarity_weights", {}) as Dictionary).duplicate()


## Poké Mart config (copy): card_count, item_count_min/max, potion_count, card_prices, item_prices.
func get_shop_config() -> Dictionary:
	return (_shop_cfg.get("shop", {}) as Dictionary).duplicate(true)


## Card removal pricing (copy): base_price, price_step, min_deck_size.
func get_removal_config() -> Dictionary:
	return (_shop_cfg.get("card_removal", {}) as Dictionary).duplicate()


## Card upgrade rules by card kind (copy), e.g. {"attack": {"damage": 3}, "skill": {"block": 3}}.
func get_upgrade_rules() -> Dictionary:
	return (_shop_cfg.get("upgrade_rules", {}) as Dictionary).duplicate(true)


func _load_items(root: Dictionary) -> bool:
	var raw: Variant = root.get("items", null)
	if not (raw is Dictionary) or (raw as Dictionary).is_empty():
		push_error("GameData: items file needs a non-empty 'items' object")
		return false
	var ok: bool = true
	var energy_items: int = 0
	for item_id: String in (raw as Dictionary).keys():
		var def: Variant = (raw as Dictionary)[item_id]
		var item: ItemData = ItemData.from_dict(item_id, def) if def is Dictionary else null
		if item == null:
			push_error("GameData: item '%s' is invalid" % item_id)
			ok = false
			continue
		if item.total("energy_up_per_turn") > 0:
			energy_items += 1
		_items[item_id] = item
	if energy_items > 1:
		push_error("GameData: at most one item may grant energy_up_per_turn (found %d)" % energy_items)
		ok = false
	return ok


func _load_potions(root: Dictionary) -> bool:
	if not _is_positive_int(root.get("max_carried", null)):
		push_error("GameData: potions file needs a positive integer 'max_carried'")
		return false
	_max_potions = int(root["max_carried"])
	var raw: Variant = root.get("potions", null)
	if not (raw is Dictionary) or (raw as Dictionary).is_empty():
		push_error("GameData: potions file needs a non-empty 'potions' object")
		return false
	var ok: bool = true
	for potion_id: String in (raw as Dictionary).keys():
		var def: Variant = (raw as Dictionary)[potion_id]
		var potion: PotionData = PotionData.from_dict(potion_id, def) if def is Dictionary else null
		if potion == null:
			push_error("GameData: potion '%s' is invalid" % potion_id)
			ok = false
		else:
			_potions[potion_id] = potion
	return ok


## Validates a {rarity: number} object whose keys must be non-starter rarities; `positive` = values > 0 else >= 0.
func _check_rarity_numbers(label: String, v: Variant, positive: bool) -> bool:
	if not (v is Dictionary) or (v as Dictionary).is_empty():
		push_error("GameData: shop file needs a non-empty '%s' object" % label)
		return false
	var ok: bool = true
	for rarity: String in (v as Dictionary).keys():
		var n: Variant = (v as Dictionary)[rarity]
		if rarity not in CardData.RARITIES or rarity == CardData.RARITY_STARTER \
				or not (_is_number(n) and (n > 0 or (not positive and n == 0))):
			push_error("GameData: shop '%s' has an invalid entry for '%s'" % [label, rarity])
			ok = false
	return ok


func _load_shop(root: Dictionary) -> bool:
	var ok: bool = true
	var money: Variant = root.get("starting_money", null)
	if not (_is_number(money) and money >= 0):
		push_error("GameData: shop file needs 'starting_money' >= 0")
		ok = false
	# Loot per fight room type.
	var loot_v: Variant = root.get("loot", null)
	if not (loot_v is Dictionary):
		push_error("GameData: shop file needs a 'loot' object")
		return false
	for room: String in (loot_v as Dictionary).keys():
		var l_v: Variant = (loot_v as Dictionary)[room]
		if room not in FIGHT_ROOM_TYPES or not (l_v is Dictionary):
			push_error("GameData: shop loot['%s'] must be an object for a fight room type" % room)
			ok = false
			continue
		var l: Dictionary = l_v
		if not (_is_number(l.get("money_min", null)) and l["money_min"] >= 0 and _is_number(l.get("money_max", null))
				and l["money_max"] >= l["money_min"]):
			push_error("GameData: shop loot['%s'] needs 0 <= money_min <= money_max" % room)
			ok = false
		for key: String in ["item_chance", "potion_chance"]:
			if not (_is_number(l.get(key, null)) and l[key] >= 0 and l[key] <= 1):
				push_error("GameData: shop loot['%s'].%s must be between 0 and 1" % [room, key])
				ok = false
	ok = _check_rarity_numbers("item_rarity_weights", root.get("item_rarity_weights", null), true) and ok
	# Shop.
	var shop_v: Variant = root.get("shop", null)
	if not (shop_v is Dictionary):
		push_error("GameData: shop file needs a 'shop' object")
		return false
	var sh: Dictionary = shop_v
	var counts_ok: bool = true
	for key: String in ["card_count", "item_count_min", "item_count_max", "potion_count"]:
		if not (_is_number(sh.get(key, null)) and sh[key] >= 0 and sh[key] == floorf(sh[key])):
			push_error("GameData: shop.%s must be an integer >= 0" % key)
			counts_ok = false
	if counts_ok and sh["item_count_max"] < sh["item_count_min"]:
		push_error("GameData: shop.item_count_max must be >= item_count_min")
		counts_ok = false
	ok = ok and counts_ok
	ok = _check_rarity_numbers("shop.card_prices", sh.get("card_prices", null), false) and ok
	ok = _check_rarity_numbers("shop.item_prices", sh.get("item_prices", null), false) and ok
	# Every rarity that can be sold needs a price.
	var item_weights_v: Variant = root.get("item_rarity_weights", null)
	var item_prices_v: Variant = sh.get("item_prices", null)
	var card_prices_v: Variant = sh.get("card_prices", null)
	if item_weights_v is Dictionary and item_prices_v is Dictionary:
		for rarity: String in (item_weights_v as Dictionary).keys():
			if not (item_prices_v as Dictionary).has(rarity):
				push_error("GameData: shop.item_prices has no price for rarity '%s'" % rarity)
				ok = false
	if card_prices_v is Dictionary:
		for rarity: String in _rarity_weights.keys():
			if not (card_prices_v as Dictionary).has(rarity):
				push_error("GameData: shop.card_prices has no price for rarity '%s'" % rarity)
				ok = false
	# Card removal.
	var rm_v: Variant = root.get("card_removal", null)
	if not (rm_v is Dictionary) or not (_is_number((rm_v as Dictionary).get("base_price", null)) and rm_v["base_price"] >= 0) \
			or not (_is_number((rm_v as Dictionary).get("price_step", null)) and rm_v["price_step"] >= 0) \
			or not _is_positive_int((rm_v as Dictionary).get("min_deck_size", null)):
		push_error("GameData: shop file needs card_removal {base_price >= 0, price_step >= 0, min_deck_size >= 1}")
		ok = false
	# Upgrade rules.
	var up_v: Variant = root.get("upgrade_rules", null)
	if not (up_v is Dictionary):
		push_error("GameData: shop file needs an 'upgrade_rules' object")
		return false
	for kind: String in [CardData.KIND_ATTACK, CardData.KIND_SKILL]:
		var r: Variant = (up_v as Dictionary).get(kind, null)
		if not (r is Dictionary) or (r as Dictionary).is_empty() or not CardData.valid_upgrade_rule(r):
			push_error("GameData: upgrade_rules['%s'] must be a non-empty object of integer damage/block/cost deltas" % kind)
			ok = false
	if ok:
		_shop_cfg = root.duplicate(true)
	return ok


# --- Starter choice (story 010) ---------------------------------------------------------------------

## Id of the shared player-config entry (max HP, energy, hand size, reward pool) used by every starter.
## It is the pokemon.json "starter_pokemon" (the default starter), not a hardcoded id.
func get_default_player_id() -> String:
	return _starter_pokemon


## Pokémon that may be offered at the start of a run (pokemon.json "starter_candidates").
func get_starter_candidates() -> Array[String]:
	return _starter_candidates.duplicate()


## First type id of a Pokémon ("" if unknown).
func get_primary_type(pokemon_id: String) -> String:
	var types: Array = get_pokemon_info(pokemon_id).get("types", [])
	return String(types[0]) if not types.is_empty() else ""


## {"basic": CardData, "strong": CardData} of the starter deck for a type (empty if the type has none).
func get_starter_cards_for_type(type_id: String) -> Dictionary:
	if not _starter_cards_by_type.has(type_id):
		return {}
	var entry: Dictionary = _starter_cards_by_type[type_id]
	return {"basic": get_card(String(entry["basic"])), "strong": get_card(String(entry["strong"]))}


## Starter deck template {"basic_count", "skill", "skill_count", "strong_count"} (copy).
func get_starter_deck_template() -> Dictionary:
	return _deck_template.duplicate()


## Starter deck of a Pokémon: basic x N + skill x M + strong x K of its PRIMARY type, every attack carried
## by that Pokémon. Fresh array each call; empty (push_error) if the Pokémon or its type has no entry.
func build_starter_deck(pokemon_id: String) -> Array[CardData]:
	var deck: Array[CardData] = []
	var cards: Dictionary = get_starter_cards_for_type(get_primary_type(pokemon_id))
	if cards.is_empty():
		push_error("GameData: no starter cards for pokemon '%s'" % pokemon_id)
		return deck
	for i: int in int(_deck_template["basic_count"]):
		deck.append((cards["basic"] as CardData).with_pokemon(pokemon_id))
	for i: int in int(_deck_template["skill_count"]):
		deck.append(get_card(String(_deck_template["skill"])))
	for i: int in int(_deck_template["strong_count"]):
		deck.append((cards["strong"] as CardData).with_pokemon(pokemon_id))
	return deck


## `count` starter candidates with pairwise DIFFERENT primary types, drawn with the injected rng
## (deterministic for a seeded rng). Fewer (push_error) if there are not enough distinct types.
## Story 013b: each slot comes from the roster candidates (roles.candidate_start) with probability
## pokemon.json starter_choice.roster_share, else from starter_candidates; a pool with no free type left yields to the other.
func draw_starter_choices(rng: RandomNumberGenerator, count: int = 3) -> Array[String]:
	var classic: Array[String] = _starter_candidates.duplicate()
	var roster: Array[String] = _roster_candidates.duplicate()
	_shuffle(classic, rng)
	_shuffle(roster, rng)
	var result: Array[String] = []
	var used_types: Dictionary = {}
	while result.size() < count:
		var use_roster: bool = not roster.is_empty() and rng.randf() < _starter_roster_share
		var pid: String = _next_starter(roster if use_roster else classic, used_types)
		if pid.is_empty():
			pid = _next_starter(classic if use_roster else roster, used_types)
		if pid.is_empty():
			break
		used_types[get_primary_type(pid)] = true
		result.append(pid)
	if result.size() < count:
		push_error("GameData: only %d distinct starter types available, %d requested" % [result.size(), count])
	return result


## Pops (from the front of `pool`) the first candidate whose primary type is not in `used_types`; "" if none.
func _next_starter(pool: Array[String], used_types: Dictionary) -> String:
	while not pool.is_empty():
		var pid: String = pool.pop_front()
		if not used_types.has(get_primary_type(pid)):
			return pid
	return ""


## Roster candidates proposable at the start (roster.json roles.candidate_start, story 013b), file order.
func get_roster_starter_candidates() -> Array[String]:
	return _roster_candidates.duplicate()


## Pokémon (players + pokemon.json enemies + roster.json entries with roles.carrier_ok, story 013b) whose types include
## `type_id`, in file order. The final boss (boss: true) never carries a card.
func get_carriers_for_type(type_id: String) -> Array[String]:
	if _carriers_by_type.is_empty():
		for pid: String in get_pokemon_ids():
			if is_boss_pokemon(pid) or (_roster_ids.has(pid) and not bool(((_roster_ids[pid] as Dictionary).get("roles", {}) as Dictionary).get("carrier_ok", false))):
				continue
			for t: String in (get_pokemon_info(pid)["types"] as Array):
				if not _carriers_by_type.has(t):
					_carriers_by_type[t] = [] as Array[String]
				(_carriers_by_type[t] as Array[String]).append(pid)
	var result: Array[String] = []
	result.assign(_carriers_by_type.get(type_id, []))
	return result


func _load_starters(pokemon_root: Dictionary) -> bool:
	var ok: bool = true
	var tmpl_v: Variant = pokemon_root.get("starter_deck_template", null)
	if not (tmpl_v is Dictionary):
		push_error("GameData: pokemon file needs a 'starter_deck_template' object")
		return false
	var tmpl: Dictionary = tmpl_v
	for key: String in ["basic_count", "skill_count", "strong_count"]:
		if not _is_positive_int(tmpl.get(key, null)):
			push_error("GameData: starter_deck_template needs a positive integer '%s'" % key)
			ok = false
	var skill: Variant = tmpl.get("skill", null)
	if not (skill is String) or not _cards.has(skill) or (_cards[skill] as CardData).kind != CardData.KIND_SKILL:
		push_error("GameData: starter_deck_template 'skill' must name a skill card")
		ok = false
	var by_type_v: Variant = pokemon_root.get("starter_cards_by_type", null)
	if not (by_type_v is Dictionary):
		push_error("GameData: pokemon file needs a 'starter_cards_by_type' object")
		return false
	var by_type: Dictionary = by_type_v
	for type_id: String in by_type.keys():
		if not _type_chart.is_known_type(type_id):
			push_error("GameData: starter_cards_by_type has unknown type '%s'" % type_id)
			ok = false
		var entry_v: Variant = by_type[type_id]
		if not (entry_v is Dictionary):
			push_error("GameData: starter_cards_by_type['%s'] must be an object" % type_id)
			ok = false
			continue
		for slot: String in ["basic", "strong"]:
			var cid: Variant = (entry_v as Dictionary).get(slot, null)
			var card: CardData = _cards.get(cid, null) if cid is String else null
			if card == null or card.kind != CardData.KIND_ATTACK:
				push_error("GameData: starter_cards_by_type['%s'].%s must name an attack card" % [type_id, slot])
				ok = false
			elif card.type_id != type_id:
				push_error("GameData: starter_cards_by_type['%s'].%s: card '%s' has type '%s'" % [type_id, slot, cid, card.type_id])
				ok = false
	var cand_v: Variant = pokemon_root.get("starter_candidates", null)
	if not (cand_v is Array) or (cand_v as Array).is_empty():
		push_error("GameData: pokemon file needs a non-empty 'starter_candidates' array")
		return false
	for pid_v: Variant in (cand_v as Array):
		if not (pid_v is String) or not (_players.has(pid_v) or _enemies.has(pid_v)):
			push_error("GameData: starter_candidates references unknown pokemon '%s'" % str(pid_v))
			ok = false
			continue
		var pid: String = pid_v
		var primary: String = ""
		var types: Array = (_players.get(pid, _enemies.get(pid, {})) as Dictionary).get("types", [])
		if not types.is_empty():
			primary = String(types[0])
		if not by_type.has(primary):
			push_error("GameData: starter candidate '%s' has primary type '%s' without starter_cards_by_type entry" % [pid, primary])
			ok = false
		_starter_candidates.append(pid)
	var choice_v: Variant = pokemon_root.get("starter_choice", {})
	var share_v: Variant = (choice_v as Dictionary).get("roster_share", 0.0) if choice_v is Dictionary else null
	if not (_is_number(share_v) and share_v >= 0 and share_v <= 1):
		push_error("GameData: pokemon file 'starter_choice.roster_share' must be between 0 and 1")
		ok = false
	else:
		_starter_roster_share = float(share_v)
	for pid: String in _roster_ids.keys():  # story 013b: roster candidates whose primary type has starter cards
		var entry: Dictionary = _roster_ids[pid]
		if bool((entry.get("roles", {}) as Dictionary).get("candidate_start", false)) and not is_boss_pokemon(pid):
			if by_type.has(String((entry["types"] as Array)[0])):
				_roster_candidates.append(pid)
			else:
				push_error("GameData: roster candidate '%s' has a primary type without starter_cards_by_type entry" % pid)
				ok = false
	if ok:
		_starter_cards_by_type = by_type.duplicate(true)
		_deck_template = tmpl.duplicate(true)
	return ok


# --- Evolution (story 007) ---------------------------------------------------------------------------

## Official evolution of a Pokémon (copy), gained when the Champion is beaten:
## {"id": evolved form slug, "name": FR name, "types": Array, "max_hp_bonus": int, "sprite": res:// path,
## "teaches": Array of card ids (the player picks 1)}. EMPTY if the Pokémon has no evolution:
## the caller then applies get_evolution_hp_bonus_default() ("n'évolue pas, il se renforce").
func get_evolution(base_id: String) -> Dictionary:
	if not _evolutions.has(base_id):
		return {}
	return (_evolutions[base_id] as Dictionary).duplicate(true)


## Max HP gained by a Pokémon that has no evolution when the Champion is beaten (pokemon.json).
func get_evolution_hp_bonus_default() -> int:
	return _evolution_hp_bonus_default


## Cards (CardData) carried by the evolved form of `base_id`, among which the player picks one. Empty if no evolution.
func get_evolution_cards(base_id: String) -> Array[CardData]:
	var result: Array[CardData] = []
	for card_id: String in (_evolutions.get(base_id, {}) as Dictionary).get("teaches", []):
		var card: CardData = _cards.get(card_id, null)
		if card != null:
			result.append(card)
	return result


## Story 014: battles won (since it entered the deck) a team Pokémon needs to reach stage 2, then stage 3
## (pokemon.json team_evolution.battles_per_stage).
func get_team_evolution_battles() -> Array[int]:
	return _team_evolution_battles.duplicate()


## Story 014: max HP a team Pokémon gains at each evolution (pokemon.json team_evolution.bonus_hp, may be 0).
func get_team_evolution_bonus_hp() -> int:
	return _team_evolution_bonus_hp


## Story 014: validates `team_evolution` {battles_per_stage: non-empty strictly increasing positive ints, bonus_hp >= 0}.
## Reports the problems, never crashes (an invalid block leaves team evolution disabled).
func _load_team_evolution(pokemon_root: Dictionary) -> bool:
	var cfg_v: Variant = pokemon_root.get("team_evolution", null)
	if not (cfg_v is Dictionary):
		push_error("GameData: pokemon file needs a 'team_evolution' object {battles_per_stage, bonus_hp}")
		return false
	var cfg: Dictionary = cfg_v
	var ok: bool = true
	var battles: Array[int] = []
	var steps_v: Variant = cfg.get("battles_per_stage", null)
	if not (steps_v is Array) or (steps_v as Array).is_empty():
		push_error("GameData: team_evolution.battles_per_stage must be a non-empty array")
		ok = false
	else:
		for n_v: Variant in (steps_v as Array):
			if not _is_positive_int(n_v) or (not battles.is_empty() and int(n_v) <= battles[battles.size() - 1]):
				push_error("GameData: team_evolution.battles_per_stage must be strictly increasing positive integers (got '%s')" % str(n_v))
				ok = false
				break
			battles.append(int(n_v))
	var hp_v: Variant = cfg.get("bonus_hp", null)
	if not _is_number(hp_v) or hp_v < 0 or hp_v != floorf(hp_v):
		push_error("GameData: team_evolution.bonus_hp must be an integer >= 0")
		ok = false
	if ok:
		_team_evolution_battles = battles
		_team_evolution_bonus_hp = int(hp_v)
	return ok


## Validates `evolutions` + `evolution_hp_bonus_default`: base known, evolved id sane and unique, FR name, known types,
## positive max_hp_bonus, existing sprite, teaches = known non-starter attack cards. Reports every problem, never crashes.
func _load_evolutions(pokemon_root: Dictionary) -> bool:
	var ok: bool = true
	if not _is_positive_int(pokemon_root.get("evolution_hp_bonus_default", null)):
		push_error("GameData: pokemon file needs a positive integer 'evolution_hp_bonus_default'")
		ok = false
	else:
		_evolution_hp_bonus_default = int(pokemon_root["evolution_hp_bonus_default"])
	var raw: Variant = pokemon_root.get("evolutions", null)
	if not (raw is Dictionary):
		push_error("GameData: pokemon file needs an 'evolutions' object")
		return false
	ok = _load_team_evolution(pokemon_root) and ok
	# Story 014: a base may be an evolved form named by another entry (stage 2 -> 3): entries are accepted in
	# dependency order (several passes), whatever their order in the file. What never resolves is reported.
	var pending: Array = (raw as Dictionary).keys()
	var ordered: Array = []
	var known: Dictionary = {}
	var progress: bool = true
	while progress and not pending.is_empty():
		progress = false
		var rest: Array = []
		for bid: String in pending:
			if _players.has(bid) or _enemies.has(bid) or known.has(bid):
				ordered.append(bid)
				var d_v: Variant = (raw as Dictionary)[bid]
				if d_v is Dictionary and (d_v as Dictionary).get("id", null) is String:
					known[String((d_v as Dictionary)["id"])] = true
				progress = true
			else:
				rest.append(bid)
		pending = rest
	for bid4: String in pending:
		push_error("GameData: evolution of '%s': unknown base pokemon" % bid4)
		ok = false
	for base_id: String in ordered:
		var label: String = "evolution of '%s'" % base_id
		var def_v: Variant = (raw as Dictionary)[base_id]
		if not (def_v is Dictionary):
			push_error("GameData: %s must be an object" % label)
			ok = false
			continue
		var def: Dictionary = def_v
		var entry_ok: bool = true
		var evo_id: String = String(def["id"]) if def.get("id", null) is String else ""
		if evo_id.is_empty() or not evo_id.is_valid_ascii_identifier() or evo_id == base_id or _players.has(evo_id):
			push_error("GameData: %s needs an 'id' that is a valid identifier, differs from the base and is not a player id (got '%s')" % [label, evo_id])
			entry_ok = false
		elif _evolved_forms.has(evo_id):
			push_error("GameData: %s: evolved id '%s' is already used by another evolution" % [label, evo_id])
			entry_ok = false
		if not (def.get("name", null) is String) or String(def["name"]).is_empty():
			push_error("GameData: %s needs a non-empty 'name'" % label)
			entry_ok = false
		if not _check_types_ref(label, def.get("types", null)):
			entry_ok = false
		if not _is_positive_int(def.get("max_hp_bonus", null)):
			push_error("GameData: %s needs a positive integer 'max_hp_bonus'" % label)
			entry_ok = false
		var sprite: Variant = def.get("sprite", null)
		if not (sprite is String) or not ResourceLoader.exists(sprite):
			push_error("GameData: %s: sprite '%s' does not exist" % [label, str(sprite)])
			entry_ok = false
		var teaches_v: Variant = def.get("teaches", null)
		if not (teaches_v is Array) or (teaches_v as Array).is_empty():
			push_error("GameData: %s needs a non-empty 'teaches' array of card ids" % label)
			entry_ok = false
		else:
			for card_id: Variant in (teaches_v as Array):
				var card: CardData = _cards.get(card_id, null) if card_id is String else null
				if card == null or card.kind != CardData.KIND_ATTACK or card.rarity == CardData.RARITY_STARTER:
					push_error("GameData: %s teaches '%s' which is not a known non-starter attack card" % [label, str(card_id)])
					entry_ok = false
		if entry_ok:
			_evolutions[base_id] = def
			_evolved_forms[evo_id] = def
		else:
			ok = false
	return ok


# --- Loading / validation --------------------------------------------------

## Pokémon info for ANY player, enemy or evolved-form id: {id, name, sprite_path, types: Array[String]}. Empty if unknown.
func get_pokemon_info(pokemon_id: String) -> Dictionary:
	var def_v: Variant = _players.get(pokemon_id, _enemies.get(pokemon_id, _evolved_forms.get(pokemon_id, null)))
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
		ok = _check_enemy_def(eid, _enemies[eid]) and ok
	return ok


## Validates one enemy-format definition (pokemon.json enemies, roster.json entries). Reports every problem.
func _check_enemy_def(eid: String, def_v: Variant) -> bool:
	var ok: bool = true
	if true:
		if not (def_v is Dictionary):
			push_error("GameData: enemy '%s' must be an object" % eid)
			return false
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
			return false
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


## Story 013b: validates roster.json entries (enemy format + dex, generation, stage, tier 1..ROSTER_MAX_TIER, roles,
## existing sprite, evolves_to known) and merges the valid ones into the enemies. A roster id that collides with a
## pokemon.json id is rejected. Builds the wild pools by type / tier. Reports every problem, never crashes.
func _load_roster(root: Dictionary) -> bool:
	var raw: Variant = root.get("pokemon", null)
	if not (raw is Dictionary):
		push_error("GameData: roster file needs a 'pokemon' object")
		return false
	var ok: bool = true
	var entries: Dictionary = raw
	for rid: String in entries.keys():
		var def_v: Variant = entries[rid]
		var label: String = "roster '%s'" % rid
		if _enemies.has(rid) or _players.has(rid):
			push_error("GameData: %s collides with a pokemon.json id" % label)
			ok = false
			continue
		if not _check_enemy_def(rid, def_v):
			ok = false
			continue
		var def: Dictionary = def_v
		var entry_ok: bool = true
		for key: String in ["dex", "generation", "stage", "tier"]:
			if not _is_positive_int(def.get(key, null)):
				push_error("GameData: %s needs a positive integer '%s'" % [label, key])
				entry_ok = false
		if entry_ok and int(def["tier"]) > ROSTER_MAX_TIER:
			push_error("GameData: %s tier must be 1..%d" % [label, ROSTER_MAX_TIER])
			entry_ok = false
		var roles_v: Variant = def.get("roles", null)
		if not (roles_v is Dictionary):
			push_error("GameData: %s needs a 'roles' object" % label)
			entry_ok = false
		else:
			for key: String in ["wild_ok", "carrier_ok", "candidate_start"]:
				if not ((roles_v as Dictionary).get(key, null) is bool):
					push_error("GameData: %s roles.%s must be a boolean" % [label, key])
					entry_ok = false
		if not ResourceLoader.exists(String(def["sprite"])):
			push_error("GameData: %s: sprite '%s' does not exist" % [label, String(def["sprite"])])
			entry_ok = false
		var evo: Variant = def.get("evolves_to", null)
		if evo != null and not (evo is String and (entries.has(evo) or _enemies.has(evo) or _players.has(evo))):
			push_error("GameData: %s evolves_to unknown pokemon '%s'" % [label, str(evo)])
			entry_ok = false
		if not entry_ok:
			ok = false
			continue
		_enemies[rid] = def
		_roster_ids[rid] = def
		if bool(def["roles"]["wild_ok"]):
			var tier: int = int(def["tier"])
			for t: String in [""] + Array(def["types"]):
				if not _roster_wild.has(t):
					_roster_wild[t] = {}
				if not (_roster_wild[t] as Dictionary).has(tier):
					_roster_wild[t][tier] = [] as Array[String]
				(_roster_wild[t][tier] as Array[String]).append(rid)
	_carriers_by_type = {}  # rebuilt lazily with the roster
	return ok


## Story 013b: evolution entries (get_evolution format) for every roster Pokémon with an `evolves_to`, built from the
## evolved form: name, types, sprite, teaches; max_hp_bonus = roster_evolution.hp_bonus_per_tier x max(1, tier
## difference) + final_bonus when the evolved form does not evolve further. pokemon.json evolutions win on conflicts.
func _load_roster_evolutions(pokemon_root: Dictionary) -> bool:
	if _roster_ids.is_empty():
		return true
	var cfg_v: Variant = pokemon_root.get("roster_evolution", null)
	if not (cfg_v is Dictionary) or not _is_positive_int((cfg_v as Dictionary).get("hp_bonus_per_tier", null)) \
			or not (_is_number((cfg_v as Dictionary).get("final_bonus", null)) and (cfg_v as Dictionary)["final_bonus"] >= 0):
		push_error("GameData: pokemon file needs 'roster_evolution' {hp_bonus_per_tier > 0, final_bonus >= 0}")
		return false
	var per_tier: int = int(cfg_v["hp_bonus_per_tier"])
	var final_bonus: int = int(cfg_v["final_bonus"])
	var ok: bool = true
	for rid: String in _roster_ids.keys():
		var base: Dictionary = _roster_ids[rid]
		if base.get("evolves_to", null) == null or _evolutions.has(rid):
			continue
		var evo_id: String = String(base["evolves_to"])
		var evo: Dictionary = _enemies.get(evo_id, _players.get(evo_id, {}))
		var evo_tier: int = int(evo.get("tier", int(base["tier"]) + 1))
		var bonus: int = per_tier * maxi(1, evo_tier - int(base["tier"]))
		if evo.get("evolves_to", null) == null:
			bonus += final_bonus
		var teaches: Array = []
		for cid: Variant in evo.get("teaches", []):
			var card: CardData = _cards.get(cid, null)
			if card != null and card.kind == CardData.KIND_ATTACK and card.rarity != CardData.RARITY_STARTER:
				teaches.append(cid)
		if teaches.is_empty():
			push_error("GameData: roster evolution '%s' -> '%s' has no non-starter attack card to teach" % [rid, evo_id])
			ok = false
			continue
		var entry: Dictionary = {"id": evo_id, "name": String(evo.get("name", "")), "types": (evo.get("types", []) as Array).duplicate(),
				"max_hp_bonus": bonus, "sprite": String(evo.get("sprite", "")), "teaches": teaches}
		_evolutions[rid] = entry
		if not _evolved_forms.has(evo_id):
			_evolved_forms[evo_id] = entry
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
			elif card.rarity == CardData.RARITY_STARTER:
				push_error("GameData: reward pool '%s': starter-rarity card '%s' must not be a reward" % [pid, str(card_id)])
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


func _pool_id_for(room: Dictionary, floor_number: int, use_overrides: bool = true) -> String:
	var overrides: Array = room.get("encounter_pool_overrides", []) if use_overrides else []
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
