extends RefCounted
## Plays ONE complete run headlessly (story 019 balance simulator): starter choice -> 8 zones (map walk, fights, rewards, loot,
## Centre, Mart, events, gym + badge, starter evolution, team evolution) -> Conseil 4 -> Maître -> Éthernatos.
## It mirrors src/main.gd's flow call for call (same classes: GameData, RunState, ActProgress/MapGenerator, RewardGenerator,
## LootGenerator, ShopInventory, EvolutionOffer, EventResolver, Battle) with the same RNG seeding (act_seed + index + 1 in
## Main.RNG_NAMES order) -- only the screens are replaced by SimPolicy decisions. Deterministic for (game_seed, policy cfg).

const SimPolicy: GDScript = preload("res://tools/balance/sim_policy.gd")
## Slot of the league in the per-zone arrays (zones are 0..7).
const LEAGUE_SLOT: int = 8

var _data: GameData
var _run: RunState
var _policy: RefCounted
var _battle_rng := RandomNumberGenerator.new()
var _encounter_rng := RandomNumberGenerator.new()
var _reward_rng := RandomNumberGenerator.new()
var _event_rng := RandomNumberGenerator.new()
var _starter_rng := RandomNumberGenerator.new()
var _loot_rng := RandomNumberGenerator.new()
var _shop_rng := RandomNumberGenerator.new()
var _zone_rng := RandomNumberGenerator.new()
var _league_rng := RandomNumberGenerator.new()

# stats of the run
var _fights: int = 0
var _fights_by_room: Dictionary = {}
var _hp_lost_by_zone: Array[int] = []
var _potions_used: int = 0
var _potions_bought: int = 0
var _stalled: bool = false
var _killers: Array[String] = []
var _stage: String = ""
var _death_room: String = ""
var _death_zone: int = 0
var _death_encounter: String = ""
var _last_defeated: Array[String] = []


## Plays one run; returns the per-run record (JSON-friendly dictionary).
static func play_game(data: GameData, game_seed: int, policy_cfg: Dictionary) -> Dictionary:
	var sim: RefCounted = (load("res://tools/balance/sim_run.gd") as GDScript).new()
	return sim._play(data, game_seed, policy_cfg)


func _play(data: GameData, game_seed: int, policy_cfg: Dictionary) -> Dictionary:
	_data = data
	_policy = SimPolicy.new(data, policy_cfg, game_seed + 7919)
	var rngs: Array[RandomNumberGenerator] = [_battle_rng, _encounter_rng, _reward_rng, _event_rng, _starter_rng, _loot_rng,
			_shop_rng, _zone_rng, _league_rng]
	for i: int in rngs.size():
		rngs[i].seed = game_seed + i + 1
	_hp_lost_by_zone.resize(LEAGUE_SLOT + 1)
	_hp_lost_by_zone.fill(0)
	var choices: Array[String] = data.draw_starter_choices(_starter_rng, 3)
	var starter: String = _policy.pick_starter(choices)
	_run = RunState.create_with_starter(data, starter)
	_run.set_zones(data.draw_zones(_zone_rng))
	var gym_types: Array[String] = []
	for z: Dictionary in _run.zones:
		gym_types.append(String(z["type_id"]))
	_run.set_league(data.draw_league(_league_rng, gym_types))
	_run.start_act(data, game_seed)
	var won: bool = _play_zones() and _play_league()
	if won:
		_stage = "victory"
	return _record(starter, won)


func _record(starter: String, won: bool) -> Dictionary:
	var info: Dictionary = _data.get_pokemon_info(starter)
	var types: Array = info.get("types", [])
	var zone_types: Array[String] = []
	for z: Dictionary in _run.zones:
		zone_types.append(String(z["type_id"]))
	return {"starter": starter, "starter_type": String(types[0]) if not types.is_empty() else "", "won": won, "stage": _stage,
			"zone": _death_zone, "room": _death_room, "encounter": _death_encounter, "killers": _killers,
			"deck_size": _run.deck.size(), "max_hp": _run.max_hp, "badges": _run.badges.size(), "fights": _fights,
			"fights_by_room": _fights_by_room, "hp_lost_by_zone": _hp_lost_by_zone, "potions_used": _potions_used,
			"potions_bought": _potions_bought, "items": _run.items.size(), "money": _run.money, "stalled": _stalled,
			"illegal": _policy.illegal_moves, "evolution_stage": _run.evolution_stage, "zones": zone_types}


## The 8 zones. Returns false when the run is lost on the way.
func _play_zones() -> bool:
	for _z: int in _run.zones.size():
		while true:
			var reach: Array[String] = _run.act.reachable_ids()
			if reach.is_empty():
				push_error("SimRun: dead end on the map")
				_stage = "map_error"
				return false
			var id: String = _policy.choose_room(_run, reach)
			if not _run.act.enter(id):
				_policy.illegal_moves += 1
				return false
			var node: MapNode = _run.act.current_node()
			if _data.get_room_type(node.room_type).has("encounter_pool"):
				if not _room_fight(node):
					return false
			elif node.room_type == "event":
				_room_event()
			elif node.room_type == "center":
				_policy.play_center(_run)
			elif node.room_type == "mart":
				var shop: ShopInventory = ShopInventory.generate(_data, _run, _shop_rng)
				var before: int = _run.potions.size()
				_policy.play_mart(_run, shop)
				_potions_bought += maxi(0, _run.potions.size() - before)
			if node.room_type == "boss":
				break
		# Gym won: badge -> [starter evolution] -> next zone or league (Main.badge_continue / _next_zone_or_victory).
		_run.award_badge(_data)
		if _data.get_evolution_after_badges().has(_run.badges.size()) and not _run.starter_evolved_at(_run.badges.size()):
			var summary: Dictionary = _run.evolve_starter(_data, _run.badges.size())
			if not summary.is_empty():
				var offers: Array[CardData] = EvolutionOffer.generate(_data, _run, summary)
				var pick: int = _policy.choose_reward(_run, offers, 0.0)
				if pick >= 0:
					_run.add_card(offers[pick])
		if _run.is_final_zone() or not _run.advance_zone():
			break
		_run.start_act(_data, 0)
	return true


func _play_league() -> bool:
	if not _run.start_league():
		return true
	while true:
		var fight: Dictionary = _run.current_league_fight()
		var mods: Dictionary = fight["modifiers"]
		var enemies: Array[Combatant] = _data.create_enemies(String(fight["encounter"]), float(mods["hp_multiplier"]),
				int(mods["strength_bonus"]))
		if not _fight(String(fight["encounter"]), enemies, "league", _league_stage_name(fight)):
			return false
		_run.win_league_fight()
		if _run.final_boss_defeated:
			return true
		_reward(_data.get_league_reward_weights(), _last_defeated)
		_run.advance_league(_data.get_league_heal_percent())
	return false


func _league_stage_name(fight: Dictionary) -> String:
	match String(fight["kind"]):
		"champion":
			return "league_champion"
		"final_boss":
			return "league_eternatus"
	return "league_member_%d" % int(fight["index"])


func _room_fight(node: MapNode) -> bool:
	var encounter_id: String = _data.pick_encounter(node.room_type, node.floor, _encounter_rng, _run.current_zone(),
			_data.deck_attack_types(_run.deck))
	var mods: Dictionary = _data.get_fight_modifiers(node.room_type, _run.current_zone())
	var enemies: Array[Combatant] = _data.create_enemies(encounter_id, float(mods["hp_multiplier"]), int(mods["strength_bonus"]))
	if enemies.is_empty():
		return true
	if not _fight(encounter_id, enemies, node.room_type, "zone%d_%s" % [_run.zone_index + 1, node.room_type]):
		return false
	_run.apply_loot(LootGenerator.generate(_data, _run, node.room_type, _loot_rng))
	_reward(_data.get_room_rarity_weights(node.room_type), _last_defeated)
	return true


## Fights one battle with the policy; updates the run like Main (record_battle_result). False = run lost.
func _fight(encounter_id: String, enemies: Array[Combatant], room_type: String, stage_name: String) -> bool:
	var battle: Battle = _run.create_battle(enemies, _data.get_type_chart(), _battle_rng)
	var potions_before: int = battle.potions.size()
	battle.start()
	var hp_before: int = _run.hp
	var stalled: bool = _policy.play_battle(battle, room_type)
	_fights += 1
	_fights_by_room[room_type] = int(_fights_by_room.get(room_type, 0)) + 1
	_potions_used += potions_before - battle.potions.size()
	var slot: int = LEAGUE_SLOT if room_type == "league" else _run.zone_index
	if battle.state == Battle.State.WON:
		var ids: Array[String] = []
		for e: Combatant in battle.enemies:
			ids.append(e.id)
		_last_defeated = ids
		_run.record_battle_result(battle.player, ids)
		_hp_lost_by_zone[slot] += maxi(0, hp_before - _run.hp)
		return true
	_stalled = stalled
	_run.hp = 0
	for e: Combatant in battle.enemies:
		if e.is_alive():
			_killers.append(e.id)
	_stage = stage_name
	_death_room = room_type
	_death_zone = LEAGUE_SLOT + 1 if room_type == "league" else _run.zone_index + 1
	_death_encounter = encounter_id
	_hp_lost_by_zone[slot] += hp_before
	return false


## Card reward (RewardGenerator -> take or skip), then the team evolution check (Main._after_reward).
func _reward(weights: Dictionary, defeated_ids: Array[String]) -> void:
	var offers: Array[RewardOffer] = RewardGenerator.generate(_data, _run.player_id, defeated_ids, _reward_rng, weights)
	var cards: Array[CardData] = []
	for o: RewardOffer in offers:
		cards.append(o.card)
	var pick: int = _policy.choose_reward(_run, cards)
	if pick >= 0:
		_run.add_card(cards[pick])
	_run.evolve_team(_data)


func _room_event() -> void:
	var event: Dictionary = EventResolver.pick_event(_data, _event_rng)
	if event.is_empty():
		return
	var option: Dictionary = (event.get("options", []) as Array)[_policy.choose_event_option(event)]
	EventResolver.apply_effects(option.get("effects", []), _run, _data, _event_rng)
