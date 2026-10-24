class_name RunState
extends RefCounted
## The player's persistent state for one run (HP and deck survive from battle to battle).
## Pure logic, no Node access. Implements: story-004-recompenses-vol-attaque, criterion 4.
## Story 007 (story-007-champion-evolution-fin-de-partie): evolve_starter() after the Champion, run stats for the
## victory / defeat summary (get_summary), is_defeated().
## Story 012 (story-012-structure-8-arenes): the run is `zones` (drawn at the start, zone_index = the current one);
## each zone has its own act map; beating a gym awards a badge (permanent bonuses, data: zones.json badge_rewards).
## Story 013 (story-013-conseil-4-ethernatos): after the last badge, the league (4 members, Maître, final boss), see set_league.

var player_id: String = ""
var display_name: String = ""
var type_ids: Array[String] = []
var sprite_path: String = ""
var max_hp: int = 1
var hp: int = 1
var energy_per_turn: int = 0
var hand_size: int = 0
## The run's own copy of the deck (never the shared starter definition).
var deck: Array[CardData] = []
var battles_won: int = 0
## Enemy Pokémon beaten in won battles (story 007, victory / defeat summary).
var enemies_defeated: int = 0
## The starter picked at the start of the run; never changes, even after the evolution (story 007).
var base_pokemon_id: String = ""
## True once evolve_starter() has run (evolution OR the "il se renforce" bonus): it applies once per run.
var evolution_applied: bool = false
## True if evolve_starter() changed the form at least once (false for a Pokémon without an evolution entry).
var evolved: bool = false
## Story 014: how many times the starter's form changed (0 = still the chosen form, 1 = stage 2, 2 = stage 3).
var evolution_stage: int = 0
## Story 014: the summary (evolve_starter format) of each starter evolution step applied, in order.
var evolution_history: Array[Dictionary] = []
## Story 014: team Pokémon (carriers of deck cards, not the starter) progress: carrier id ->
## {"battles": won battles since it entered the deck, "stage": evolutions already done}. See record_battle_result.
var team_progress: Dictionary = {}
## Story 014: badge numbers for which evolve_starter(data, badge) already ran (0 = the badge-less call).
var _evolved_badges: Array[int] = []
## Pokédollars (story 006).
var money: int = 0
## Held items owned, in pickup order (permanent, no duplicates).
var items: Array[ItemData] = []
## Potions carried (single use, at most max_potions()).
var potions: Array[PotionData] = []
## Story 017: Poké Balls carried: ball id -> count (> 0), total at most max_balls(); separate from potions.
var balls: Dictionary = {}
## Story 017: ids of the Pokémon captured so far this run (unique, first capture order); feeds the Pokédex (story 025).
var captured: Array[String] = []
## Cards removed at the Poké Mart so far this run (drives the rising removal price).
var card_removals: int = 0
var _data: GameData
## Pokémon on the field at the start of every battle (GameData.get_starter_pokemon_id, story 009).
var starter_pokemon_id: String = ""
var _pokemon_infos: Dictionary = {}  # pokemon id -> info dict (GameData.get_pokemon_info)
## Progress on the act map of the CURRENT zone (null until start_act is called).
var act: ActProgress = null
## Story 012: index (0-based) of the current zone in `zones`.
var zone_index: int = 0
## Story 012: the zones of this run (GameData.draw_zones): type, leader, modifiers... Empty = a single legacy act.
var zones: Array[Dictionary] = []
## Story 012: badges earned so far, in order: see award_badge().
var badges: Array[Dictionary] = []
## Permanent badge bonuses on top of hand_size / energy_per_turn (story 012).
var bonus_hand_size: int = 0
var bonus_energy: int = 0
## Seed of the first zone's map; the next zones derive theirs from it (deterministic).
var _base_map_seed: int = 0
## Rooms entered in the zones already left (summary: floors climbed across zones).
var _floors_done: int = 0
## Story 013: the league fights of this run (GameData.draw_league: members, Maître, final boss), drawn at the start.
var league: Array[Dictionary] = []
## Story 013: index of the current league fight (0..league.size()-1); -1 = not in the league yet.
var league_stage: int = -1
## Story 013: league fights won so far (members + Maître + final boss).
var league_fights_won: int = 0
## Story 013: true once the final boss (Éthernatos) is beaten: the real end of the run.
var final_boss_defeated: bool = false
## Added to the base map seed per zone index to derive a zone's map seed.
const ZONE_SEED_STEP: int = 1000003


## Starts a run from the player's data: full HP, starter deck copy. Null if the id is unknown.
static func create(data: GameData, new_player_id: String) -> RunState:
	var def: Dictionary = data.get_player_definition(new_player_id)
	if def.is_empty():
		return null
	var r := RunState.new()
	r.player_id = new_player_id
	r.display_name = String(def.get("name", ""))
	var raw_types: Variant = def.get("types", [])
	if raw_types is Array:
		for t: Variant in (raw_types as Array):
			r.type_ids.append(String(t))
	r.sprite_path = String(def.get("sprite", ""))
	r.max_hp = int(def.get("max_hp", 1))
	r.hp = r.max_hp
	r.energy_per_turn = int(def.get("energy_per_turn", 0))
	r.hand_size = int(def.get("hand_size", 0))
	r.deck = data.get_starter_deck(new_player_id)  # fresh array each call
	r.starter_pokemon_id = data.get_starter_pokemon_id()
	r.base_pokemon_id = r.starter_pokemon_id
	for pid: String in data.get_pokemon_ids():
		r._pokemon_infos[pid] = data.get_pokemon_info(pid)
	r._init_services(data)
	return r


## Starts a run with the chosen starter (story 010): deck = GameData.build_starter_deck(starter), identity
## (name, types, sprite) from the starter's entry, max HP / energy / hand size from the shared player config
## (GameData.get_default_player_id). Null if the starter or the shared config is unknown.
static func create_with_starter(data: GameData, starter_id: String) -> RunState:
	var info: Dictionary = data.get_pokemon_info(starter_id)
	var shared: Dictionary = data.get_player_definition(data.get_default_player_id())
	if info.is_empty() or shared.is_empty():
		push_error("RunState: unknown starter '%s' or missing shared player config" % starter_id)
		return null
	var deck: Array[CardData] = data.build_starter_deck(starter_id)
	if deck.is_empty():
		return null
	var r := RunState.new()
	r.player_id = data.get_default_player_id()
	r.display_name = String(info["name"])
	r.type_ids.assign(info["types"])
	r.sprite_path = String(info["sprite_path"])
	r.max_hp = int(shared.get("max_hp", 1))
	r.hp = r.max_hp
	r.energy_per_turn = int(shared.get("energy_per_turn", 0))
	r.hand_size = int(shared.get("hand_size", 0))
	r.deck = deck
	r.starter_pokemon_id = starter_id
	r.base_pokemon_id = starter_id
	for pid: String in data.get_pokemon_ids():
		r._pokemon_infos[pid] = data.get_pokemon_info(pid)
	r._init_services(data)
	return r


func _init_services(data: GameData) -> void:
	_data = data
	money = data.get_starting_money()


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
	c.type_ids = type_ids.duplicate()
	c.max_hp = max_hp
	c.hp = clampi(hp, 0, max_hp)
	c.active_pokemon_id = starter_pokemon_id
	var info: Dictionary = get_pokemon_info(starter_pokemon_id)
	if not info.is_empty():
		c.set_active_pokemon(starter_pokemon_id, String(info["name"]), String(info["sprite_path"]), info["types"])
	return c


## Pokémon info {id, name, sprite_path, types} for any player/enemy id (empty if unknown); Battle's lookup.
func get_pokemon_info(pokemon_id: String) -> Dictionary:
	return (_pokemon_infos.get(pokemon_id, {}) as Dictionary).duplicate()


## Builds a battle from the persisted state; the battle gets a COPY of the deck.
## Held items and potions are handed to the battle; passive items raise the energy / hand size it is built with.
## Drinking a potion in the battle also removes it from `potions` (kept in sync through potion_used).
## Story 017: `capture_allowed` (Main: _data.capture_allowed_in(room type), wild fights only) lets the player throw the balls;
## each thrown ball leaves `balls` at once (kept in sync through ball_thrown); apply the captures after the win with apply_captures.
func create_battle(enemies: Array[Combatant], type_chart: TypeChart, rng: RandomNumberGenerator,
		capture_allowed: bool = false) -> Battle:
	var battle := Battle.new(build_player_combatant(), enemies, deck.duplicate(), effective_energy_per_turn(),
			effective_hand_size(), rng, type_chart, get_pokemon_info, starter_pokemon_id, items, potions,
			_data.get_status_book() if _data != null else null)
	battle.potion_used.connect(_on_battle_potion_used)
	return battle


## Energy per turn including the (single) energy_up_per_turn item.
func effective_energy_per_turn() -> int:
	return energy_per_turn + bonus_energy + ItemEffects.passive_total(items, "energy_up_per_turn")


## Cards drawn per turn including draw_up items.
func effective_hand_size() -> int:
	return hand_size + bonus_hand_size + ItemEffects.passive_total(items, "draw_up")


func _on_battle_potion_used(potion: PotionData) -> void:
	for i: int in potions.size():
		if potions[i].id == potion.id:
			potions.remove_at(i)
			return


func _on_battle_ball_thrown(_target: Combatant, ball: BallData, _chance: float) -> void:
	remove_ball(ball.id)


## Copies the player's HP back after a battle (clamped 0..max_hp). A surviving player = a battle won, and
## `defeated_ids` (the enemies of that battle) are added to enemies_defeated. HP 0 = the run is lost (is_defeated).
func record_battle_result(player: Combatant, defeated_ids: Array[String] = []) -> void:
	hp = clampi(player.hp, 0, max_hp)
	if hp > 0:
		battles_won += 1
		enemies_defeated += defeated_ids.size()
		track_team_win()


## True when the run is lost: HP reached 0 (story 007 defeat screen).
func is_defeated() -> bool:
	return hp <= 0


## Rooms entered across the whole run (zones already left + the current map), 0 without an act.
func floors_climbed() -> int:
	return _floors_done + (act.visited.size() if act != null else 0)


## Floors of the whole run (sum of the zones' maps; the single act's floors without zones), 0 without an act.
func total_floors() -> int:
	if not zones.is_empty() and _data != null:
		var total: int = 0
		for z: Dictionary in zones:
			total += _data.get_zone_floors(int(z["number"]))
		return total
	return act.graph.floors if act != null and act.graph != null else 0


## Floors of the CURRENT zone's map (what the map header shows), 0 without an act.
func zone_floors() -> int:
	return act.graph.floors if act != null and act.graph != null else 0


# --- Zones and badges (story 012) -------------------------------------------------------------------

## Sets the run's zones (GameData.draw_zones) and goes back to the first one.
func set_zones(new_zones: Array[Dictionary]) -> void:
	zones = new_zones
	zone_index = 0
	badges = []
	_floors_done = 0
	_base_map_seed = 0


## The current zone's dict ({} without zones): see GameData.draw_zones.
func current_zone() -> Dictionary:
	return zones[zone_index] if zone_index >= 0 and zone_index < zones.size() else {}


## True on the last zone (its gym ends the run). True without zones (a single act).
func is_final_zone() -> bool:
	return zones.is_empty() or zone_index >= zones.size() - 1


## Moves to the next zone; its map is NOT built yet (call start_act). False (no change) on the last zone.
## HP, deck, money, items, potions and badges are kept; the floors of the zone just left are added to the stats.
func advance_zone() -> bool:
	if is_final_zone():
		return false
	_floors_done += act.visited.size() if act != null else 0
	zone_index += 1
	act = null
	return true


## QA-ONLY: jumps to zone `index` (0-based, clamped) without playing the zones before: no badge, no bonus.
## The map is NOT built (call start_act).
func jump_to_zone(index: int) -> void:
	zone_index = clampi(index, 0, maxi(zones.size() - 1, 0))
	act = null
	_floors_done = 0
	if _data != null:
		for i: int in zone_index:
			_floors_done += _data.get_zone_floors(i + 1)


## The current zone's gym is beaten: awards its badge (once per zone; a second call returns the same badge) and applies
## the badge's data bonus (zones.json badge_rewards[n]): max HP (+HP), +cards per turn, +energy, then the heal of
## heal_percent % of max HP. Returns {id, name, index (1-based badge number), zone_index, type_id, type_name, color,
## leader, bonus: the reward dict, bonus_text (FR), healed: HP restored, max_hp_gain, unlocks: {wild, elite} pool ids}.
## {} without zones.
func award_badge(data: GameData) -> Dictionary:
	var zone: Dictionary = current_zone()
	if zone.is_empty():
		return {}
	if badges.size() > zone_index:
		return badges[zone_index]
	var number: int = badges.size() + 1
	var reward: Dictionary = data.get_badge_reward(number)
	var parts: Array[String] = []
	var hp_gain: int = int(reward.get("max_hp", 0))
	if hp_gain > 0:
		gain_max_hp(hp_gain)
		parts.append("+%d PV max" % hp_gain)
	var cards: int = int(reward.get("hand_size", 0))
	if cards > 0:
		bonus_hand_size += cards
		parts.append("+%d carte piochée par tour" % cards)
	var energy: int = int(reward.get("energy_per_turn", 0))
	if energy > 0:
		bonus_energy += energy
		parts.append("+%d énergie par tour" % energy)
	var healed: int = heal_percent(float(reward.get("heal_percent", 0)))
	if healed > 0:
		parts.append("%d PV rendus" % healed)
	var badge: Dictionary = {"id": String(zone["badge_id"]), "name": String(zone["badge_name"]), "index": number,
			"zone_index": zone_index, "type_id": String(zone["type_id"]), "type_name": String(zone["type_name"]),
			"color": data.get_type_color(String(zone["type_id"])), "leader": String(zone["leader"]), "bonus": reward,
			"bonus_text": ", ".join(parts), "healed": healed, "max_hp_gain": hp_gain,
			"unlocks": (reward.get("unlock_pools", {}) as Dictionary).duplicate(true)}
	badges.append(badge)
	return badge


# --- Conseil 4, Maître, boss final (story 013) -------------------------------------------------------

## Sets the run's league fights (GameData.draw_league, drawn at the start of the run); the league is not started.
func set_league(stages: Array[Dictionary]) -> void:
	league = stages
	league_stage = -1
	league_fights_won = 0
	final_boss_defeated = false


## Enters the league (after the last badge): stage 0 = the first member. False (no change) without league data.
func start_league() -> bool:
	if league.is_empty():
		return false
	league_stage = 0
	return true


## True between start_league() and the end of the run.
func is_in_league() -> bool:
	return league_stage >= 0 and league_stage < league.size()


## The league fight of the current stage (copy; {} outside the league): see GameData.draw_league.
func current_league_fight() -> Dictionary:
	return (league[league_stage] as Dictionary).duplicate(true) if is_in_league() else {}


## True when the current stage is the final boss.
func is_league_final_stage() -> bool:
	return is_in_league() and league_stage == league.size() - 1


## The current league fight is won: counts it (once per stage); on the final boss sets final_boss_defeated.
func win_league_fight() -> void:
	if not is_in_league() or league_fights_won > league_stage:
		return
	league_fights_won = league_stage + 1
	if is_league_final_stage():
		final_boss_defeated = true


## Moves to the next league fight and heals `heal_pct` % of max HP (GameData.get_league_heal_percent).
## Returns the HP restored; -1 (no change) if the current fight is not won yet or this was the last stage.
func advance_league(heal_pct: float) -> int:
	if not is_in_league() or league_fights_won <= league_stage or is_league_final_stage():
		return -1
	league_stage += 1
	return heal_percent(heal_pct)


## Story 007 / 014: one evolution step of the chosen starter (Main calls it after the badges of zones.json
## evolution_after_badges: `badge_number` identifies the step, a second call for the same number changes nothing and
## returns {}). The rule is the same for every Pokémon: GameData.get_evolution(<current form>) (pokemon.json
## evolutions / roster evolves_to; stage-2 forms have their own entry): new name / types / sprite, max HP AND current
## HP + max_hp_bonus, the field Pokémon becomes the new form, and the deck cards carried by the old form are now
## carried by the new one. Without a next form the form stays: GameData.get_evolution_hp_bonus_default() max HP AND one
## of the Pokémon's cards is upgraded "+" (the most expensive upgradable one; upgrade_card logic) -- "n'évolue pas — il
## se renforce".
## Returns {from_id, from_name, from_sprite, from_types, to_id, to_name, to_sprite, to_types, hp_bonus: int,
## evolved: bool, stage: int (evolution_stage after the step), badge: int, upgraded_card: String (display name, "" if none)}.
func evolve_starter(data: GameData, badge_number: int = 0) -> Dictionary:
	if data == null or _evolved_badges.has(badge_number):
		return {}
	_evolved_badges.append(badge_number)
	var summary: Dictionary = {"from_id": starter_pokemon_id, "from_name": display_name, "from_sprite": sprite_path,
			"from_types": type_ids.duplicate(), "badge": badge_number, "upgraded_card": ""}
	var evo: Dictionary = data.get_evolution(starter_pokemon_id)
	var bonus: int = data.get_evolution_hp_bonus_default()
	var step_evolved: bool = false
	if not evo.is_empty():
		bonus = int(evo["max_hp_bonus"])
		var new_id: String = String(evo["id"])
		display_name = String(evo["name"])
		type_ids.assign(evo["types"])
		sprite_path = String(evo["sprite"])
		_pokemon_infos[new_id] = data.get_pokemon_info(new_id)
		_recarry(starter_pokemon_id, new_id)
		starter_pokemon_id = new_id
		evolved = true
		evolution_stage += 1
		step_evolved = true
	else:
		var idx: int = _best_upgradable_index(starter_pokemon_id)
		if idx >= 0:
			upgrade_card(idx)
			summary["upgraded_card"] = deck[idx].display_name
	gain_max_hp(bonus)
	evolution_applied = true
	summary["to_id"] = starter_pokemon_id
	summary["to_name"] = display_name
	summary["to_sprite"] = sprite_path
	summary["to_types"] = type_ids.duplicate()
	summary["hp_bonus"] = bonus
	summary["evolved"] = step_evolved
	summary["stage"] = evolution_stage
	evolution_history.append(summary.duplicate(true))
	return summary


## Story 014: true if evolve_starter(data, badge_number) already ran for that number.
func starter_evolved_at(badge_number: int) -> bool:
	return _evolved_badges.has(badge_number)


## Story 014: the deck cards carried by `from_id` become carried by `to_id` (one rule for any Pokémon id).
func _recarry(from_id: String, to_id: String) -> void:
	for i: int in deck.size():
		if deck[i].pokemon_id == from_id:
			deck[i] = deck[i].with_pokemon(to_id)


## Story 014: deck index of the most expensive card of `pokemon_id` that can still be upgraded (first on ties), -1 if none.
func _best_upgradable_index(pokemon_id: String) -> int:
	var best: int = -1
	for i: int in deck.size():
		if deck[i].pokemon_id == pokemon_id and can_upgrade_card(i) and (best < 0 or deck[i].cost > deck[best].cost):
			best = i
	return best


## Story 014: ids of the team Pokémon = carriers of deck cards other than the field starter, in deck order.
func team_carriers() -> Array[String]:
	var result: Array[String] = []
	for c: CardData in deck:
		if not c.pokemon_id.is_empty() and c.pokemon_id != starter_pokemon_id and not result.has(c.pokemon_id):
			result.append(c.pokemon_id)
	return result


## Story 014: a battle was won (record_battle_result calls this; public for QA) -- every team Pokémon in the deck gets +1 battle (one that just entered the deck
## starts counting now; one that left the deck forgets its progress).
func track_team_win() -> void:
	var carriers: Array[String] = team_carriers()
	for key: String in team_progress.keys():
		if not carriers.has(key):
			team_progress.erase(key)
	for c: String in carriers:
		if not team_progress.has(c):
			team_progress[c] = {"battles": 0, "stage": 0}
		team_progress[c]["battles"] = int(team_progress[c]["battles"]) + 1


## Story 014: team Pokémon that can evolve now (battles >= team_evolution.battles_per_stage[stage] and a next form
## exists), in deck order. Pure observation.
func pending_team_evolutions(data: GameData) -> Array[String]:
	var result: Array[String] = []
	if data == null:
		return result
	var steps: Array[int] = data.get_team_evolution_battles()
	for c: String in team_carriers():
		var prog: Dictionary = team_progress.get(c, {})
		var stage: int = int(prog.get("stage", 0))
		if stage < steps.size() and int(prog.get("battles", 0)) >= steps[stage] and not data.get_evolution(c).is_empty():
			result.append(c)
	return result


## Story 014: evolves every team Pokémon that is due (see pending_team_evolutions; several steps in a row if the
## thresholds are all passed). Same rule for any id: max HP + team_evolution.bonus_hp per step, the deck cards of the old
## form are carried by the new one, no card choice. Returns one row per Pokémon (evolve_starter format: from_*, to_*,
## hp_bonus = total gained, evolved = true, stage = its stage after), empty if nothing is due.
func evolve_team(data: GameData) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for start_id: String in pending_team_evolutions(data):
		var cur: String = start_id
		var from_info: Dictionary = data.get_pokemon_info(start_id)
		var row: Dictionary = {"from_id": start_id, "from_name": String(from_info.get("name", "")),
				"from_sprite": String(from_info.get("sprite_path", "")), "from_types": from_info.get("types", []), "hp_bonus": 0,
				"evolved": true, "badge": 0, "upgraded_card": ""}
		var prog: Dictionary = (team_progress[start_id] as Dictionary).duplicate()
		var steps: Array[int] = data.get_team_evolution_battles()
		while int(prog["stage"]) < steps.size() and int(prog["battles"]) >= steps[int(prog["stage"])]:
			var evo: Dictionary = data.get_evolution(cur)
			if evo.is_empty():
				break
			var new_id: String = String(evo["id"])
			_pokemon_infos[new_id] = data.get_pokemon_info(new_id)
			_recarry(cur, new_id)
			cur = new_id
			prog["stage"] = int(prog["stage"]) + 1
			row["hp_bonus"] = int(row["hp_bonus"]) + data.get_team_evolution_bonus_hp()
		team_progress.erase(start_id)
		var to_info: Dictionary = data.get_pokemon_info(cur)
		if cur != starter_pokemon_id:
			if team_progress.has(cur):  # two lines merging into one form keep the best progress
				prog["battles"] = maxi(int(prog["battles"]), int(team_progress[cur]["battles"]))
				prog["stage"] = maxi(int(prog["stage"]), int(team_progress[cur]["stage"]))
			team_progress[cur] = prog
		row["to_id"] = cur
		row["to_name"] = String(to_info.get("name", ""))
		row["to_sprite"] = String(to_info.get("sprite_path", ""))
		row["to_types"] = to_info.get("types", [])
		row["stage"] = int(prog["stage"])
		gain_max_hp(int(row["hp_bonus"]))
		rows.append(row)
	return rows


## Story 007: everything the victory / defeat screen shows, read from the run:
## {pokemon_id, name, sprite, types, hp, max_hp, floors (across all zones), total_floors (all zones), enemies_defeated,
##  battles_won, money, item_names: Array[String], deck_size, evolved, zone (1-based current zone), zone_count,
##  badges (count), badge_names: Array[String],
##  story 013: league_started (bool), league_stage (-1..), league_fights_won, league_total (fights incl. Maître + boss),
##  league_members_total, league_beaten_names: Array[String] (names of the league fights won, in order),
##  champion_defeated (Maître beaten), eternatus_defeated (final boss beaten = "Éthernatos vaincu"), final_boss_name}.
func get_summary() -> Dictionary:
	var item_names: Array[String] = []
	for it: ItemData in items:
		item_names.append(it.display_name)
	var badge_names: Array[String] = []
	for b: Dictionary in badges:
		badge_names.append(String(b["name"]))
	var league_names: Array[String] = []
	for i: int in mini(league_fights_won, league.size()):
		league_names.append(String((league[i] as Dictionary)["name"]))
	return {"zone": zone_index + 1, "zone_count": maxi(zones.size(), 1), "badges": badges.size(), "badge_names": badge_names,
			"pokemon_id": starter_pokemon_id, "name": display_name, "sprite": sprite_path, "types": type_ids.duplicate(),
			"hp": hp, "max_hp": max_hp, "floors": floors_climbed(), "total_floors": total_floors(),
			"enemies_defeated": enemies_defeated, "battles_won": battles_won, "money": money,
			"item_names": item_names, "deck_size": deck.size(), "evolved": evolved,
			"league_started": league_stage >= 0, "league_stage": league_stage, "league_fights_won": league_fights_won,
			"league_total": league.size(), "league_members_total": maxi(league.size() - 2, 0),
			"league_beaten_names": league_names, "champion_defeated": league.size() >= 2 and league_fights_won >= league.size() - 1,
			"eternatus_defeated": final_boss_defeated,
			"final_boss_name": String((league[league.size() - 1] as Dictionary)["name"]) if not league.is_empty() else ""}


## CardData.deck_key() ("card@pokemon") -> copies in the deck.
func deck_counts() -> Dictionary:
	var counts: Dictionary = {}
	for c: CardData in deck:
		counts[c.deck_key()] = int(counts.get(c.deck_key(), 0)) + 1
	return counts


## Deck grouped for display: [{"card": CardData, "count": int}], sorted by card name.
func get_deck_entries() -> Array[Dictionary]:
	var by_id: Dictionary = {}
	var entries: Array[Dictionary] = []
	for c: CardData in deck:
		if by_id.has(c.deck_key()):
			by_id[c.deck_key()]["count"] = int(by_id[c.deck_key()]["count"]) + 1
		else:
			var e: Dictionary = {"card": c, "count": 1}
			by_id[c.deck_key()] = e
			entries.append(e)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["card"] as CardData).display_name.naturalnocasecmp_to((b["card"] as CardData).display_name) < 0)
	return entries


## Generates the map of the CURRENT zone (the single act without zones) and starts progress on it (seed 0 = random for
## the first zone, derived from the first zone's seed for the next ones; graph.seed holds the used seed).
## Returns false if `data` has no valid act config.
func start_act(data: GameData, act_seed: int = 0) -> bool:
	var config: Dictionary = data.get_zone_act_config(zone_index + 1) if not zones.is_empty() else data.get_act_config()
	if config.is_empty():
		push_error("RunState: no act config loaded")
		return false
	var used_seed: int = act_seed
	if used_seed == 0 and zone_index > 0 and _base_map_seed != 0:
		used_seed = _base_map_seed + zone_index * ZONE_SEED_STEP
	act = ActProgress.create(MapGenerator.generate(config, used_seed))
	if zone_index == 0:
		_base_map_seed = act.graph.seed
	return true


## Heals `percent` % of max HP (rounded up), never above max HP. Returns the HP actually restored.
func heal_percent(percent: float) -> int:
	var before: int = hp
	hp = mini(max_hp, hp + ceili(max_hp * percent / 100.0))
	return hp - before


## Loses up to `amount` HP but never goes below `min_hp` (events never kill: default 1).
## Returns the HP actually lost.
func lose_hp(amount: int, min_hp: int = 1) -> int:
	var before: int = hp
	hp = maxi(mini(hp, min_hp), hp - maxi(amount, 0))
	return before - hp


## Raises max HP by `amount` and current HP by the same amount.
func gain_max_hp(amount: int) -> void:
	var a: int = maxi(amount, 0)
	max_hp += a
	hp += a


## Removes ONE copy of the card from the deck. False (no change) if the deck has none.
func remove_card(card_id: String) -> bool:
	for i: int in deck.size():
		if deck[i].id == card_id:
			deck.remove_at(i)
			return true
	return false


# --- Money, items, potions (story 006) -------------------------------------------------------------

## Adds Pokédollars (negative amounts are ignored).
func add_money(amount: int) -> void:
	money += maxi(amount, 0)


## Pays `amount` Pokédollars. False (nothing changes) if the run cannot afford it.
func spend_money(amount: int) -> bool:
	if amount < 0 or amount > money:
		return false
	money -= amount
	return true


## True if the item is already owned.
func has_item(item_id: String) -> bool:
	for it: ItemData in items:
		if it.id == item_id:
			return true
	return false


## Gives a held item and applies its on_pickup effects (max_hp_up raises max AND current HP; heal_*).
## False (nothing changes) for null or an item already owned.
func add_item(item: ItemData) -> bool:
	if item == null or has_item(item.id):
		return false
	items.append(item)
	if item.trigger == ItemData.TRIGGER_ON_PICKUP:
		for e: Dictionary in item.effects:
			match String(e["type"]):
				"max_hp_up":
					gain_max_hp(int(e["value"]))
				"heal_flat":
					hp = mini(max_hp, hp + int(e["value"]))
				"heal_percent_max":
					heal_percent(float(e["percent"]))
	return true


## Max number of potions carried (potions.json).
func max_potions() -> int:
	return _data.get_max_potions() if _data != null else 0


## Stores a potion. False (nothing changes) if null or the belt is full.
func add_potion(potion: PotionData) -> bool:
	if potion == null or potions.size() >= max_potions():
		return false
	potions.append(potion)
	return true


## Applies Main's loot dict (LootGenerator.generate) and reports what the player actually got:
## {"money": int, "item": ItemData or null, "potion": PotionData or null, "ball": BallData or null} (null = none, or no room).
func apply_loot(loot: Dictionary) -> Dictionary:
	var result: Dictionary = {"money": int(loot.get("money", 0)), "item": null, "potion": null, "ball": null}
	add_money(result["money"])
	var item_id: String = String(loot.get("item_id", ""))
	if not item_id.is_empty():
		var item: ItemData = _data.get_item(item_id)
		if add_item(item):
			result["item"] = item
	var potion_id: String = String(loot.get("potion_id", ""))
	if not potion_id.is_empty():
		var potion: PotionData = _data.get_potion(potion_id)
		if add_potion(potion):
			result["potion"] = potion
	var ball_id: String = String(loot.get("ball_id", ""))
	if not ball_id.is_empty() and add_ball(ball_id):
		result["ball"] = _data.get_ball(ball_id)
	return result


# --- Poké Balls and captures (story 017) -----------------------------------------------------------

## Max total number of balls carried (balls.json max_carried).
func max_balls() -> int:
	return _data.get_max_balls() if _data != null else 0


## Balls carried, all kinds together.
func ball_total() -> int:
	var total: int = 0
	for bid: String in balls.keys():
		total += int(balls[bid])
	return total


## Balls of one kind carried.
func ball_count(ball_id: String) -> int:
	return int(balls.get(ball_id, 0))


## Stores one ball. False (nothing changes) for an unknown ball or a full bag.
func add_ball(ball_id: String) -> bool:
	if _data == null or not _data.has_ball(ball_id) or ball_total() >= max_balls():
		return false
	balls[ball_id] = ball_count(ball_id) + 1
	return true


## Removes one ball of that kind (the key disappears at 0). False if there is none.
func remove_ball(ball_id: String) -> bool:
	if ball_count(ball_id) <= 0:
		return false
	if ball_count(ball_id) == 1:
		balls.erase(ball_id)
	else:
		balls[ball_id] = ball_count(ball_id) - 1
	return true


## After a won battle: the captured Pokémon (Battle.captured_ids) join the team. Each one adds ALL the cards it teaches
## (pokemon.json / roster.json `teaches`, 1-2) to the deck, carried by it (card.pokemon_id = its id), so team_carriers /
## team_progress / evolve_team treat it like any other team Pokémon (its battles count from the NEXT won battle: call this
## after record_battle_result). Capturing a Pokémon already in the team stacks the cards. captured gets the id (unique).
## Returns one row per capture: {id, name, sprite, types, cards: Array[CardData], first_time: bool}.
func apply_captures(captured_ids: Array[String]) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if _data == null:
		return rows
	for pid: String in captured_ids:
		var info: Dictionary = _data.get_pokemon_info(pid)
		if info.is_empty():
			continue
		var cards: Array[CardData] = []
		for card: CardData in _data.get_enemy_teaches(pid):
			var carried: CardData = card.with_pokemon(pid)
			add_card(carried)
			cards.append(carried)
		_pokemon_infos[pid] = info
		var first: bool = not captured.has(pid)
		if first:
			captured.append(pid)
		rows.append({"id": pid, "name": String(info["name"]), "sprite": String(info["sprite_path"]), "types": info["types"],
				"cards": cards, "first_time": first})
	return rows


# --- Centre Pokémon / Poké Mart services (story 006) ------------------------------------------------

## Centre Pokémon "se soigner": heals act1.json room_types.center.heal_percent % of max HP (rounded up).
## Returns the HP actually restored.
func rest_heal() -> int:
	return heal_percent(float(_data.get_room_type("center").get("heal_percent", 0)))


## HP that rest_heal() would restore now (display only, nothing changes).
func rest_heal_preview() -> int:
	return mini(max_hp - hp, ceili(max_hp * rest_heal_percent() / 100.0))


## The Centre's heal rule: % of max HP (act1.json room_types.center.heal_percent).
func rest_heal_percent() -> float:
	return float(_data.get_room_type("center").get("heal_percent", 0))


## True if deck[deck_index] exists and can still be improved (not already upgraded, rule changes something).
func can_upgrade_card(deck_index: int) -> bool:
	return deck_index >= 0 and deck_index < deck.size() and deck[deck_index].can_upgrade(_data.get_upgrade_rules())


## Centre Pokémon "améliorer": replaces deck[deck_index] by its upgraded copy (once per card). False if impossible.
func upgrade_card(deck_index: int) -> bool:
	if not can_upgrade_card(deck_index):
		return false
	deck[deck_index] = deck[deck_index].upgraded_copy(_data.get_upgrade_rules())
	return true


## Preview of the upgrade of deck[deck_index] (the CardData it would become), null if impossible. Does not change the deck.
func preview_upgrade(deck_index: int) -> CardData:
	if deck_index < 0 or deck_index >= deck.size():
		return null
	return deck[deck_index].upgraded_copy(_data.get_upgrade_rules())


## Price of the next Poké Mart card removal: base_price + price_step per removal already made this run.
func removal_price() -> int:
	var cfg: Dictionary = _data.get_removal_config()
	return int(cfg["base_price"]) + int(cfg["price_step"]) * card_removals
