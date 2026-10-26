class_name Main
extends Control
## Run owner: holds GameData, RunState and RNGs, and switches between the screens
## (MapScreen -> Battle/Event/room -> Reward -> MapScreen ... -> boss -> Evolution -> Victory; HP 0 -> Defeat).
## Screens only display and emit signals; all persistent state lives here / in RunState.
## Implements: story-005-carte-acte-1 (act map flow), story-004-recompenses-vol-attaque (rewards),
## story-006-objets-et-services (permanent RunHud, potions in battle, loot on the reward screen, Centre Pokémon
## and Poké Mart screens: Main applies every service / purchase through RunState / ShopInventory),
## story-007-champion-evolution-fin-de-partie (boss win -> evolution of the starter + 1-of-N card choice ->
## victory summary; HP 0 -> defeat summary; "Nouvelle partie" resets the whole run back to the starter choice).
## story-011-acces-au-deck (RunHud "Deck" button + the single DeckOverlay panel owned here: open_deck / close_deck).
## story-012-structure-8-arenes (8 zones, each with its own map and gym; gym win -> loot + card reward -> BADGE screen
## -> [evolution after the badges listed in zones.json] -> next zone map, or the victory after the last badge;
## zone types are drawn with the run's seeded RNG). Badge flow API: get_last_badge() / get_badges() / badge_continue().
## story-013-conseil-4-ethernatos (after badge 8: league screen -> 4 Conseil 4 fights -> Maître -> Éthernatos -> victory;
## heal + card reward between fights, data: league.json). API: get_league_stage() / get_league_member() / league_continue().
## story-015-sauvegarde (autosave / resume): at every SAFE point (the act map or a league intermission is shown) the run is
## written to ONE slot (SaveGame, `user://savegame.json`, atomic); at launch a valid save shows the ResumeScreen ("Reprendre
## la partie") before the starter choice. A quit mid-battle / mid-room resumes at the map before that room. Victory / defeat
## delete the save. Autosave is ON only for the real game (this scene is the project's current scene) and OFF when a CLI flag
## forces a fresh run (--seed / --starter / --encounter) or when Main is instantiated by a QA script: such scripts opt in
## with qa_set_save_path(<scratch path>), so they never touch the real save.
## story-018-rival-et-evenements: the rival (drawn at the start: RunState.init_rival with the zone rng) is fought in the
## 'rival' map rooms (zones of rival.json) and automatically after the last badge, before the league screen; events are
## filtered by zone, may be legendary (rare), may queue a fight (started after the event's "Continuer") or a card removal.
## API: get_rival_info(), get_current_fight(), get_last_special_reward(), event_option_available(), event_remove_card().
## CLI (user args, after `--`): `--seed=<int>` forces the first map seed (and seeds the run RNGs, for QA);
## `--starter=<id>` skips the starter choice (QA / repro); `--encounter=<id>` starts that encounter directly (debug).

const STARTER_ARG_PREFIX: String = "--starter="
const STARTER_CHOICE_COUNT: int = 3
const ENCOUNTER_ARG_PREFIX: String = "--encounter="
const SEED_ARG_PREFIX: String = "--seed="
const BATTLE_SCENE: PackedScene = preload("res://src/ui/battle_screen.tscn")
const REWARD_SCENE: PackedScene = preload("res://src/ui/reward_screen.tscn")
const STARTER_SCENE: PackedScene = preload("res://src/ui/starter_screen.tscn")
const MAP_SCENE: PackedScene = preload("res://src/ui/map_screen.tscn")
const EVENT_SCENE: PackedScene = preload("res://src/ui/event_screen.tscn")
const ROOM_SCENE: PackedScene = preload("res://src/ui/placeholder_room_screen.tscn")
const SCREEN_NONE: String = "none"
const SCREEN_STARTER: String = "starter"
const SCREEN_MAP: String = "map"
const SCREEN_BATTLE: String = "battle"
const SCREEN_REWARD: String = "reward"
const SCREEN_EVENT: String = "event"
const SCREEN_ROOM: String = "room"
const SCREEN_CENTER: String = "center"
const SCREEN_MART: String = "mart"
const SCREEN_EVOLUTION: String = "evolution"
## Story 012: the badge screen (BadgeScreen; leave it with badge_continue()).
const SCREEN_BADGE: String = "badge"
const SCREEN_VICTORY: String = "victory"
## Story 013: league intro ("Route Victoire") / intermission between two league fights; league_continue() leaves it.
const SCREEN_LEAGUE: String = "league"
## Story 013: _fight_room_type of a league fight (no loot, league reward weights).
const ROOM_LEAGUE: String = "league"
const SCREEN_DEFEAT: String = "defeat"
## Story 015: the "Reprendre la partie" screen (ResumeScreen) shown at launch when a save exists (or is unreadable).
const SCREEN_RESUME: String = "resume"
## Story 015: names of Main's RandomNumberGenerators in the save (order = the seeding order of start_new_run).
const RNG_NAMES: Array[String] = ["battle", "encounter", "reward", "event", "starter", "loot", "shop", "zone", "league"]
## Room type of the zone's gym fight (story 012: its win pays loot + a card reward, then the badge; the last zone ends the run).
const ROOM_BOSS: String = "boss"
## Story 020: special battle backdrop ids (assets/data/backdrops.json).
const BACKDROP_LEAGUE: String = "league"
const BACKDROP_LEGENDARY: String = "legendary"
const BACKDROP_FINAL_BOSS: String = "ethernatos"
## QA: player turns qa_lose_battle() ends at most before giving up.
const QA_LOSE_MAX_TURNS: int = 60

var _data: GameData
var _run: RunState
## Story 015: the save slot file, whether the run is autosaved (see the header), the live resume screen and the
## loaded-save result it shows (SaveGame.load_run format + extras checked).
var _save_path: String = SaveGame.DEFAULT_PATH
var _autosave: bool = false
var _resume_screen: ResumeScreen
var _resume_result: Dictionary = {}
var _battle_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _encounter_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _reward_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _event_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _starter_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Story 006: win loot (money / item / potion) and Poké Mart stock; appended to the rng list so older seeds are unchanged.
var _loot_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _shop_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Story 012: draws the zone (gym) types at the start of a run; appended last so older seeds are unchanged.
var _zone_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Story 013: draws the Conseil 4 member types (seeded with the other run RNGs; last in the list so older seeds are unchanged).
var _league_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Story 013: HP healed between the last two league fights (-1 = intro, no heal yet).
var _last_league_heal: int = -1
## Story 013: league intro / intermission / final-boss intro screen (LeagueScreen).
var _league_screen: Control
## The badge just awarded ({} before the first gym win): see RunState.award_badge.
var _last_badge: Dictionary = {}
## What the last won fight paid: {"money": int, "item": ItemData|null, "potion": PotionData|null} ({} before any win).
var _last_loot: Dictionary = {}
## Story 017: RunState.apply_captures rows of the last won battle (empty if nothing was captured).
var _last_captures: Array[Dictionary] = []
## Story 018: the special fight being played (SpecialFights dict: rival / rival_final / event fight; {} for map fights).
var _current_fight: Dictionary = {}
## Story 018: what the last special win gave: {} or {kind: "rival" | "rival_final", encounter_id, money, item} /
## {kind: "legendary", pokemon_id, name, captured, cards: Array[CardData]}.
var _last_special_reward: Dictionary = {}
## Non-empty = every new run starts with this Pokémon without showing the choice (QA / `--starter=`).
var forced_starter_id: String = ""
## `--seed=` value (0 = none): every "Nouvelle partie" reuses it so a QA run stays reproducible; else random.
var _cli_seed: int = 0
var _pending_act_seed: int = 0
var _starter_choices: Array[String] = []
var _starter_screen: StarterScreen
var _encounter_order: Array[String] = []
var _encounter_id: String = ""
## Room type of the current fight ("" for a debug start_encounter): drives the reward rarity override.
var _fight_room_type: String = ""
var _current_event: Dictionary = {}
var _screen_name: String = SCREEN_NONE
var _screen: Control
var _battle_screen: BattleScreen
var _reward_screen: RewardScreen
var _map_screen: MapScreen
var _event_screen: EventScreen
var _room_screen: PlaceholderRoomScreen
var _center_screen: CenterScreen
var _mart_screen: MartScreen
## Story 007 screens and the evolution's card offers / summary (cleared with the screens / on a new run).
var _evolution_screen: EvolutionScreen
var _end_screen: RunEndScreen
## Story 012: the badge screen (null outside it).
var _badge_screen: BadgeScreen
var _evolution_offers: Array[CardData] = []
var _evolution_summary: Dictionary = {}
## Story 014: the rows (RunState.evolve_team) of the team evolution summary on screen, [] otherwise.
var _team_evolution_rows: Array[Dictionary] = []
## The current Poké Mart visit's stock (null outside the Mart): one per visit.
var _shop: ShopInventory
## Permanent money / items / potions bar (story 006), above every run screen except the starter choice.
var _hud: RunHud
## Story 011: THE deck panel (deck / pioche / défausse), under the HUD, above every screen. Read only.
var _deck_panel: DeckOverlay
var _offers: Array[RewardOffer] = []


func _ready() -> void:
	_data = GameData.new()
	if not _data.load_all():
		push_error("Main: could not load game data")
		return
	_encounter_order = _data.get_encounter_order()
	_hud = RunHud.new()
	_hud.visible = false
	_hud.ball_book = _data.get_ball_book()
	_hud.potion_pressed.connect(battle_use_potion)
	_hud.deck_pressed.connect(toggle_deck)
	add_child(_hud)
	_deck_panel = DeckOverlay.new()
	add_child(_deck_panel)
	move_child(_hud, get_child_count() - 1)  # the panel sits under the HUD, so the Deck button stays usable
	var forced_seed: int = 0
	var debug_encounter: String = ""
	var cli_forced: bool = false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(STARTER_ARG_PREFIX) or arg.begins_with(SEED_ARG_PREFIX) or arg.begins_with(ENCOUNTER_ARG_PREFIX):
			cli_forced = true
		if arg.begins_with(STARTER_ARG_PREFIX):
			forced_starter_id = arg.substr(STARTER_ARG_PREFIX.length())
			if _data.get_pokemon_info(forced_starter_id).is_empty():
				push_error("Main: unknown --starter '%s', the choice screen will be shown" % forced_starter_id)
				forced_starter_id = ""
			continue
		if arg.begins_with(SEED_ARG_PREFIX):
			var value: String = arg.substr(SEED_ARG_PREFIX.length())
			if value.is_valid_int() and int(value) != 0:
				forced_seed = int(value)
			else:
				push_error("Main: invalid --seed '%s' (non-zero integer expected), using a random seed" % value)
		elif arg.begins_with(ENCOUNTER_ARG_PREFIX):
			debug_encounter = arg.substr(ENCOUNTER_ARG_PREFIX.length())
	if not debug_encounter.is_empty() and forced_starter_id.is_empty():
		forced_starter_id = _data.get_default_player_id()  # a debug fight needs a run, so no choice screen
	_cli_seed = forced_seed
	_autosave = not cli_forced and get_tree().current_scene == self  # the real game only (see the header)
	if _autosave:
		_show_title()
		return
	start_new_run(forced_seed)
	if not debug_encounter.is_empty():
		start_encounter(debug_encounter)


## Starts a brand new run: shows the starter choice screen (3 proposals drawn with the run RNG), unless
## `starter_id` (or `forced_starter_id`) is given. `act_seed` 0 = random map and RNGs; any other value makes
## the map, the starter draw AND the run RNGs reproducible (QA).
## Story 007: the previous run is dropped entirely (RunState, loot, evolution, encounter, screens), so nothing
## leaks into the new one; the HUD is redrawn from the new run once the starter is chosen.
func start_new_run(act_seed: int = 0, starter_id: String = "") -> void:
	_clear_screens()
	_run = null
	_last_loot = {}
	_last_captures = []
	_last_badge = {}
	_last_league_heal = -1
	_current_fight = {}
	_last_special_reward = {}
	_encounter_id = ""
	_fight_room_type = ""
	_evolution_summary = {}
	_team_evolution_rows = []
	_hud.visible = false
	_resume_result = {}
	var rngs: Array[RandomNumberGenerator] = _rng_list()
	for i: int in rngs.size():
		if act_seed != 0:
			rngs[i].seed = act_seed + i + 1
		else:
			rngs[i].randomize()
	var chosen: String = starter_id if not starter_id.is_empty() else forced_starter_id
	if not chosen.is_empty():
		_begin_run(chosen, act_seed)
		return
	_pending_act_seed = act_seed
	_starter_choices = _data.draw_starter_choices(_starter_rng, STARTER_CHOICE_COUNT)
	_show_starter_screen()


## The run's generators in RNG_NAMES order.
func _rng_list() -> Array[RandomNumberGenerator]:
	return [_battle_rng, _encounter_rng, _reward_rng, _event_rng, _starter_rng, _loot_rng, _shop_rng, _zone_rng, _league_rng]


func _begin_run(starter_id: String, act_seed: int) -> void:
	var run: RunState = RunState.create_with_starter(_data, starter_id)
	if run == null:
		return
	run.set_zones(_data.draw_zones(_zone_rng))  # story 012: the 8 gym types, in zone order
	var gym_types: Array[String] = []
	for z: Dictionary in run.zones:
		gym_types.append(String(z["type_id"]))
	run.set_league(_data.draw_league(_league_rng, gym_types))  # story 013: 4 member types not used by the gyms
	run.init_rival(_data, _zone_rng)  # story 018: rival name + starter countering the player's primary type
	if not run.start_act(_data, act_seed):
		push_error("Main: could not start the act")
		return
	_run = run
	_show_map()


func _show_starter_screen() -> void:
	_clear_screens()
	_starter_screen = STARTER_SCENE.instantiate() as StarterScreen
	_starter_screen.starter_chosen.connect(_on_starter_chosen)
	_set_screen(_starter_screen, SCREEN_STARTER)
	_starter_screen.setup(_data, _starter_choices)


func _on_starter_chosen(pokemon_id: String) -> void:
	_begin_run(pokemon_id, _pending_act_seed)


## Debug/QA entry point: starts a battle on `encounter_id` (x1 modifiers, normal reward) with the CURRENT
## run state; the win leads back to the map. `loot_room_type` ("wild", "elite"; "" = none) only chooses the
## loot and reward rarity of the win (QA shots of the loot, story 006).
func start_encounter(encounter_id: String, loot_room_type: String = "") -> void:
	if _run == null or not _encounter_order.has(encounter_id):
		push_error("Main: cannot start encounter '%s'" % encounter_id)
		return
	_launch_battle(encounter_id, _data.create_enemies(encounter_id), loot_room_type)


# --- QA accessors -------------------------------------------------------------------------------

## QA: the proposals of the last starter screen.
func get_starter_choices() -> Array[String]:
	return _starter_choices


## QA: picks a starter proposal by index (int) or by Pokémon id (String), as a click would.
func starter_choose(index_or_id: Variant) -> void:
	if _starter_screen == null:
		return
	if index_or_id is int:
		_starter_screen.choose(index_or_id)
	else:
		_starter_screen.choose(_starter_choices.find(String(index_or_id)))


# --- Zones and badges (story 012) --------------------------------------------------------------

## Index (0-based) of the current zone; 0 without a run.
func get_zone_index() -> int:
	return _run.zone_index if _run != null else 0


## The current zone's dict ({} without a run): type_id, type_name, leader, badge_name, modifiers... (GameData.draw_zones).
func get_zone() -> Dictionary:
	return _run.current_zone() if _run != null else {}


## The badges earned so far, in order (see RunState.award_badge for the dict).
func get_badges() -> Array[Dictionary]:
	return _run.badges if _run != null else ([] as Array[Dictionary])


## The badge awarded by the last gym win ({} before the first). While the badge screen is up it is the badge shown:
## {id, name, index, zone_index, type_id, type_name, color: Color, leader, bonus, bonus_text, healed, max_hp_gain, unlocks}.
func get_last_badge() -> Dictionary:
	return _last_badge


## Leaves the badge screen (the UI badge screen's button calls this too): evolution if zones.json
## evolution_after_badges lists this badge, then the next zone's map, or the victory after the last badge. Ignored
## outside the badge screen.
func badge_continue() -> void:
	if _screen_name != SCREEN_BADGE:
		return
	if _data.get_evolution_after_badges().has(_run.badges.size()) and not _run.starter_evolved_at(_run.badges.size()):
		_show_evolution(_run.badges.size())
	else:
		_next_zone_or_victory()


## QA: the live StarterScreen (null outside the choice).
func get_starter_screen() -> StarterScreen:
	return _starter_screen


## What the last won fight paid and gave, already applied to the run: {"money": int, "item": ItemData|null,
## "potion": PotionData|null}; {} before any win / for debug fights without a room type. For the reward screen.
func get_last_loot() -> Dictionary:
	return _last_loot


## Story 017: the Pokémon captured in the last won battle (RunState.apply_captures rows: id, name, sprite, types, cards,
## first_time). Empty if none.
func get_last_captures() -> Array[Dictionary]:
	return _last_captures


## A fresh Poké Mart stock for the current run (seeded shop RNG: deterministic with --seed). Call once per visit.
func create_shop_inventory() -> ShopInventory:
	return ShopInventory.generate(_data, _run, _shop_rng)


## QA: the badge screen (null outside it).
func get_badge_screen() -> BadgeScreen:
	return _badge_screen


## QA: the run state (HP, deck, act progress).
func get_run_state() -> RunState:
	return _run


## QA: "starter", "map", "battle", "reward", "event", "center", "mart", "room", "evolution", "victory",
## "defeat" (or "none").
func get_current_screen_name() -> String:
	return _screen_name


## QA: the live BattleScreen (null outside a battle).
func get_battle_screen() -> BattleScreen:
	return _battle_screen


## QA: the live RewardScreen (null outside the reward phase).
func get_reward_screen() -> RewardScreen:
	return _reward_screen


## QA: the live MapScreen (null outside the map).
func get_map_screen() -> MapScreen:
	return _map_screen


## QA: the live EventScreen (null outside an event).
func get_event_screen() -> EventScreen:
	return _event_screen


## QA: the live placeholder room screen (null otherwise).
func get_room_screen() -> PlaceholderRoomScreen:
	return _room_screen


## QA: current (or last) encounter id.
func get_encounter_id() -> String:
	return _encounter_id


## QA: the event being shown ({} outside an event).
func get_current_event() -> Dictionary:
	return _current_event


## QA: the offers of the current reward screen (empty outside it).
func get_reward_offers() -> Array[RewardOffer]:
	return _offers


## QA: rooms that can be entered now (empty outside the map screen).
func map_reachable_ids() -> Array[String]:
	if _map_screen == null or _run == null or _run.act == null:
		return []
	return _run.act.reachable_ids()


## QA: clicks room `node_id` on the map. True if the room was entered (unreachable ids are refused).
func map_choose(node_id: String) -> bool:
	if _map_screen == null:
		return false
	var before: String = _run.act.current_node_id
	_map_screen.choose(node_id)
	return _run.act.current_node_id != before


## QA: presses "Voir le deck" on the map.
func map_open_deck() -> void:
	if _map_screen != null:
		_map_screen.open_deck()  # same path as the button: routes to the single deck panel


## QA: closes the map's deck overlay.
func map_close_deck() -> void:
	close_deck()


## QA: clicks event option `index`.
func event_choose(index: int) -> void:
	if _event_screen != null:
		_event_screen.choose(index)


## QA: presses "Continuer" on the event result.
func event_continue() -> void:
	if _event_screen != null:
		_event_screen.press_continue()


## QA: presses the button of the placeholder room or act-end screen; on the Centre it is "Continuer" (only
## after a service), on the Mart "Quitter".
func room_continue() -> void:
	if _room_screen != null:
		_room_screen.press_continue()
	elif _center_screen != null:
		_center_screen.press_continue()
	elif _mart_screen != null:
		_mart_screen.leave()
	elif _badge_screen != null:
		_badge_screen.press_continue()


# --- QA: story 006 (HUD, potions, Centre, Mart) ----------------------------------------------------

## QA: the permanent run bar.
func get_hud() -> RunHud:
	return _hud


## QA: the live CenterScreen (null outside the Centre Pokémon).
func get_center_screen() -> CenterScreen:
	return _center_screen


## QA: the live MartScreen (null outside the Poké Mart).
func get_shop_screen() -> MartScreen:
	return _mart_screen


## QA: the current Mart visit's stock (null outside the Mart).
func get_shop_inventory() -> ShopInventory:
	return _shop


## QA: clicks potion slot `index` of the HUD during a battle (same path as the click). False if not drunk.
func battle_use_potion(index: int) -> bool:
	if _battle_screen == null:
		return false
	return _battle_screen.use_potion(index)


## QA (story 017): throws ball `ball` (id or index into Battle.ball_ids()) at enemy `enemy_index` of the current battle,
## through BattleScreen.throw_ball (the same path as a click on a ball button in capture mode). {} outside a battle.
func battle_use_ball(ball: Variant, enemy_index: int) -> Dictionary:
	if _battle_screen == null or _battle_screen.get_battle() == null:
		return {}
	return _battle_screen.throw_ball(ball, enemy_index)


## QA-ONLY CHEAT (story 017): gives one ball `ball_id` (if the bag has room).
func qa_give_ball(ball_id: String) -> void:
	if _run != null and _run.add_ball(ball_id):
		_refresh_hud()


## QA: Centre "Se soigner".
func center_heal() -> void:
	if _center_screen != null:
		_center_screen.choose_heal()


## QA: Centre "Améliorer une carte" (opens the picker).
func center_open_upgrade() -> void:
	if _center_screen != null:
		_center_screen.open_upgrade()


## QA: picks deck[deck_index] in the Centre picker (opens the before/after preview).
func center_pick(deck_index: int) -> void:
	if _center_screen != null:
		_center_screen.pick_card(deck_index)


## QA: confirms the previewed upgrade.
func center_confirm() -> void:
	if _center_screen != null:
		_center_screen.confirm_upgrade()


## QA: full upgrade path on deck[deck_index]: open picker, pick, confirm.
func center_upgrade(deck_index: int) -> void:
	center_open_upgrade()
	center_pick(deck_index)
	center_confirm()


## QA: "Continuer" on the Centre (after a service).
func center_continue() -> void:
	if _center_screen != null:
		_center_screen.press_continue()


## QA: clicks card article `index` at the Mart.
func shop_buy_card(index: int) -> void:
	if _mart_screen != null:
		_mart_screen.buy_card(index)


## QA: clicks held-item article `index` at the Mart.
func shop_buy_item(index: int) -> void:
	if _mart_screen != null:
		_mart_screen.buy_item(index)


## QA: clicks potion article `index` at the Mart.
func shop_buy_potion(index: int) -> void:
	if _mart_screen != null:
		_mart_screen.buy_potion(index)


## QA (story 017): buys ball article `index` at the Mart (same path as a MartScreen buy_requested("ball", index)).
func shop_buy_ball(index: int) -> void:
	if _mart_screen != null and _shop != null:
		_on_shop_buy(ShopEntry.KIND_BALL, index)


## QA: "Retirer une carte" (opens the removal picker).
func shop_open_remove() -> void:
	if _mart_screen != null:
		_mart_screen.open_remove()


## QA: removes deck[deck_index] (opens the picker if needed, then picks the card).
func shop_remove(deck_index: int) -> void:
	if _mart_screen == null:
		return
	if not _mart_screen.get_picker().is_open():
		_mart_screen.open_remove()
	_mart_screen.remove(deck_index)


## QA: "Quitter" the Mart.
func shop_leave() -> void:
	if _mart_screen != null:
		_mart_screen.leave()


## QA-ONLY: opens the Centre ("center") or the Mart ("mart") screen directly, without moving on the map.
func qa_open_room(room_type: String) -> void:
	if _run == null:
		return
	if room_type == "center":
		_show_center()
	elif room_type == "mart":
		_show_mart()


## QA-ONLY CHEAT: gives held item `item_id` (on_pickup effects apply).
func qa_give_item(item_id: String) -> void:
	if _run != null and _run.add_item(_data.get_item(item_id)):
		_refresh_hud()


## QA-ONLY CHEAT: gives potion `potion_id` (if the belt has room).
func qa_give_potion(potion_id: String) -> void:
	if _run != null and _run.add_potion(_data.get_potion(potion_id)):
		_refresh_hud()


## QA-ONLY CHEAT: sets the run's Pokédollars.
func qa_set_money(amount: int) -> void:
	if _run != null:
		_run.money = maxi(amount, 0)
		_refresh_hud()


# --- Deck panel (story 011) ---------------------------------------------------------------------

## Opens the deck panel on `tab` = "deck" | "team" (story 017, always) | "draw" | "discard" (in a battle only).
## Refused (false) when there is no run, or while a modal card picker (Centre upgrade / Mart removal) is open.
## Never changes the run or the battle.
func open_deck(tab: String = "deck") -> bool:
	if _run == null or _deck_panel == null or not _hud.visible or _picker_open():
		return false
	var which: DeckOverlay.Tab = DeckOverlay.Tab.DECK
	if tab == "draw":
		which = DeckOverlay.Tab.DRAW
	elif tab == "discard":
		which = DeckOverlay.Tab.DISCARD
	elif tab == "team":
		which = DeckOverlay.Tab.TEAM
	_deck_panel.open(_run, _data, _battle_screen.get_battle() if _battle_screen != null else null, which)
	return true


## Closes the deck panel.
func close_deck() -> void:
	if _deck_panel != null:
		_deck_panel.close()


## The Deck button: opens the panel, or closes it if already open.
func toggle_deck() -> void:
	if _deck_panel != null and _deck_panel.is_open():
		close_deck()
	else:
		open_deck()


## QA: the deck panel (always exists; check is_open()).
func get_deck_panel() -> DeckOverlay:
	return _deck_panel


## QA-ONLY CHEAT: pads the deck with `n` extra cards cycling through the player's reward pool (every 4th one
## upgraded "+") to test long decks.
func qa_give_cards(n: int) -> void:
	if _run == null:
		return
	var pool: Array[CardData] = _data.get_reward_pool(_run.player_id)
	if pool.is_empty():
		return
	for i: int in n:
		var card: CardData = pool[i % pool.size()]
		if i % 4 == 3:
			var up: CardData = card.upgraded_copy(_data.get_upgrade_rules())
			card = up if up != null else card
		_run.add_card(card)
	_refresh_hud()


## True while a modal card picker (Centre upgrade, Mart removal) is shown.
func _picker_open() -> bool:
	return (_center_screen != null and _center_screen.get_picker().is_open()) \
			or (_mart_screen != null and _mart_screen.get_picker().is_open())


## The Deck button is disabled while a modal picker is open (the picker and the panel must not stack).
func _process(_delta: float) -> void:
	if _hud != null and _hud.visible:
		_hud.set_deck_enabled(not _picker_open())


# --- QA: story 007 (Champion, evolution, victory / defeat, new run) ----------------------------------

## QA: the live EvolutionScreen (null outside the evolution).
func get_evolution_screen() -> EvolutionScreen:
	return _evolution_screen


## QA: the live victory summary (null otherwise).
func get_victory_screen() -> RunEndScreen:
	return _end_screen if _screen_name == SCREEN_VICTORY else null


## QA: the live defeat summary (null otherwise).
func get_defeat_screen() -> RunEndScreen:
	return _end_screen if _screen_name == SCREEN_DEFEAT else null


## QA: what the evolution did (RunState.evolve_starter summary; {} before the Champion is beaten).
func get_evolution_summary() -> Dictionary:
	return _evolution_summary


## QA (story 014): the rows of the team evolution summary on screen ([] otherwise); see RunState.evolve_team.
func get_team_evolution_rows() -> Array[Dictionary]:
	return _team_evolution_rows


## QA-ONLY CHEAT (story 014): the starter's form goes to `stage` (0..) through the real evolution rule, silently
## (no screen, one RunState.evolve_starter step per stage, bonuses applied). Returns the stage reached.
func qa_set_evolution_stage(stage: int) -> int:
	if _run == null:
		return 0
	while _run.evolution_stage < stage:
		var before: String = _run.starter_pokemon_id
		if _run.evolve_starter(_data, -(_run.evolution_history.size() + 1)).is_empty() or _run.starter_pokemon_id == before:
			break
	_refresh_hud()
	return _run.evolution_stage


## QA-ONLY CHEAT (story 014): counts `n` won battles (battles_won + team progress) without fighting.
func qa_win_battles(n: int) -> void:
	if _run == null:
		return
	for i: int in n:
		_run.battles_won += 1
		_run.track_team_win()


## QA-ONLY (story 014): checks the team evolutions as after a won battle; shows the summary screen (then the map) and
## returns true if some Pokémon was due.
func qa_check_team_evolution() -> bool:
	return _run != null and _show_team_evolution(_show_map)


## QA-ONLY (story 014): runs the starter evolution of badge number `badge_number` (screen flow, as after the badge).
func qa_show_starter_evolution(badge_number: int) -> void:
	if _run != null:
		_show_evolution(badge_number)


## QA: "Continuer" on the evolution screen (reveal -> card choice; result -> victory).
func evolution_continue() -> void:
	if _evolution_screen != null:
		_evolution_screen.press_continue()


## QA: picks evolution card `index` (from the card-choice step) as a click would.
func evolution_pick(index: int) -> void:
	if _evolution_screen != null:
		_evolution_screen.pick(index)


## QA: "Passer" on the evolution card choice.
func evolution_skip() -> void:
	if _evolution_screen != null:
		_evolution_screen.skip()


## QA: "Nouvelle partie" on the victory screen.
func victory_new_run() -> void:
	if get_victory_screen() != null:
		_end_screen.press_new_run()


## QA: "Nouvelle partie" on the defeat screen.
func defeat_new_run() -> void:
	if get_defeat_screen() != null:
		_end_screen.press_new_run()


## QA: "Continuer" on the battle's defeat overlay (-> defeat summary). Ignored unless the battle is lost.
func battle_defeat_continue() -> void:
	if _battle_screen != null:
		_battle_screen.press_defeat_continue()


## QA-ONLY: starts the current zone's Champion fight ("boss" room: the zone's gym encounter and gym modifiers, as on the
## map) with the CURRENT run, without walking the map. The win goes through the real gym flow (reward -> badge...).
func qa_start_boss() -> void:
	if _run == null:
		return
	var encounter_id: String = _data.pick_encounter(ROOM_BOSS, _run.zone_floors(), _encounter_rng, _run.current_zone())
	var mods: Dictionary = _data.get_fight_modifiers(ROOM_BOSS, _run.current_zone())
	_launch_battle(encounter_id, _data.create_enemies(encounter_id, float(mods["hp_multiplier"]), int(mods["strength_bonus"])), ROOM_BOSS)


## QA-ONLY alias of qa_start_boss (story 012 wording).
func qa_start_gym() -> void:
	qa_start_boss()


## QA-ONLY CHEAT: wins the current zone's gym through the real win path (starts the gym fight if none is running, then
## the battle-won handler): loot + card reward screen next, then badge_continue-able badge screen after the reward.
func qa_win_gym() -> void:
	if _run == null:
		return
	if _battle_screen == null or _fight_room_type != ROOM_BOSS:
		qa_start_boss()
	if _battle_screen == null:
		return
	var ids: Array[String] = []
	for e: Combatant in _battle_screen.get_battle().enemies:
		ids.append(e.id)
	_on_battle_won(ids)


## QA-ONLY CHEAT: jumps to zone `index` (0-based) with a fresh map, keeping HP / deck / money / items; no badge or bonus is
## granted for the zones skipped. False if the index is out of range.
func qa_set_zone(index: int) -> bool:
	if _run == null or index < 0 or index >= _run.zones.size():
		return false
	_run.jump_to_zone(index)
	if not _run.start_act(_data, 0):
		return false
	_show_map()
	return true


## QA-ONLY CHEAT: enters the current zone's gym room directly (marks it visited) and starts the Champion fight.
func qa_skip_to_gym() -> void:
	if _run == null or _run.act == null:
		return
	var gym_id: String = _run.act.graph.boss_id()
	_run.act.current_node_id = gym_id
	if not _run.act.visited.has(gym_id):
		_run.act.visited.append(gym_id)
	_start_room_fight(_run.act.current_node())


## QA-ONLY CHEAT: sets every living enemy of the live battle to `value` HP (clamped 1..max), to win quickly.
func qa_set_enemy_hp(value: int) -> void:
	if _battle_screen == null:
		return
	for e: Combatant in _battle_screen.get_battle().enemies:
		if e.is_alive():
			e.hp = clampi(value, 1, e.max_hp)
			e.changed.emit()
	_battle_screen.get_battle().state_changed.emit()


## QA-ONLY CHEAT: loses the live battle through the real enemy turns (player at 1 HP, no block, ends turns).
## True if the battle is lost (the defeat overlay is then shown; battle_defeat_continue() goes on).
func qa_lose_battle() -> bool:
	if _battle_screen == null:
		return false
	var b: Battle = _battle_screen.get_battle()
	for i: int in QA_LOSE_MAX_TURNS:
		if b.state != Battle.State.PLAYER_TURN:
			break
		b.player.hp = 1
		b.player.block = 0
		b.player.changed.emit()
		_battle_screen.press_end_turn()
	return b.state == Battle.State.LOST


## QA: picks reward card `index` as a click would.
func reward_pick(index: int) -> void:
	if _reward_screen != null:
		_reward_screen.pick(index)


## QA: presses "Passer".
func reward_skip() -> void:
	if _reward_screen != null:
		_reward_screen.skip()


## QA: presses "Voir le deck".
func reward_open_deck() -> void:
	if _reward_screen != null:
		_reward_screen.open_deck()


## QA: presses "Fermer" on the deck overlay.
func reward_close_deck() -> void:
	close_deck()


## QA-ONLY CHEAT (walkthroughs): sets the run HP (and the live battle's player HP) to `value`,
## clamped to 1..max HP. Never called by the game itself.
func qa_set_hp(value: int) -> void:
	if _run == null:
		return
	_run.hp = clampi(value, 1, _run.max_hp)
	if _battle_screen != null:
		var player: Combatant = _battle_screen.get_battle().player
		player.hp = clampi(value, 1, player.max_hp)
		player.changed.emit()
	elif _center_screen != null and _center_screen.get_step() == CenterScreen.Step.CHOOSE:
		_center_screen.setup(_data, _run, _run.rest_heal_preview(), _run.rest_heal_percent())


# --- Conseil 4, Maître, Éthernatos (story 013) -------------------------------------------------

## Current league stage: 0..member_count-1 = Conseil 4 members, member_count = the Maître, member_count+1 = the final
## boss (Éthernatos); -1 outside the league (or without a run). With the shipped data: 0..5.
func get_league_stage() -> int:
	return _run.league_stage if _run != null and _run.is_in_league() else -1


## The league fight of the current stage ({} outside the league): {name, type_id, type_name, title, index (1-based),
## total (fights incl. Maître + boss), stage, kind ("member" | "champion" | "final_boss"), type_ids, encounter, modifiers,
## color (Color of type_id)}.
func get_league_member() -> Dictionary:
	if _run == null or not _run.is_in_league():
		return {}
	var m: Dictionary = _run.current_league_fight()
	m["color"] = _data.get_type_color(String(m["type_id"]))
	return m


## All league fights of this run in order (members drawn at the start of the run, Maître, final boss); see
## GameData.draw_league. Readable before the league starts (e.g. a "Route Victoire" preview).
func get_league() -> Array[Dictionary]:
	return _run.league if _run != null else ([] as Array[Dictionary])


## HP restored by the heal between the last two league fights; -1 on the intro (before the first league fight).
func get_last_league_heal() -> int:
	return _last_league_heal


## True on the league screen before the first league fight (the "Route Victoire" intro), false on an intermission.
func is_league_intro() -> bool:
	return _screen_name == SCREEN_LEAGUE and _run != null and _run.league_fights_won == 0


## Leaves the league screen (intro / intermission between two fights) and starts the current stage's fight with the
## data modifiers. The UI's league screen button calls this. Ignored outside SCREEN_LEAGUE.
func league_continue() -> void:
	if _screen_name != SCREEN_LEAGUE or _run == null or not _run.is_in_league():
		return
	var fight: Dictionary = _run.current_league_fight()
	var mods: Dictionary = fight["modifiers"]
	var enemies: Array[Combatant] = _data.create_enemies(String(fight["encounter"]), float(mods["hp_multiplier"]),
			int(mods["strength_bonus"]))
	_launch_battle(String(fight["encounter"]), enemies, ROOM_LEAGUE)
	if _battle_screen != null:
		_battle_screen.set_trainer_header("%s — %s" % [String(fight["name"]), String(fight["title"])],
				_data.get_type_color(String(fight["type_id"])), String(fight["kind"]) == "final_boss")
		if String(fight["kind"]) == "final_boss":
			_battle_screen.set_backdrop(BACKDROP_FINAL_BOSS)  # story 020


## QA: the live league screen (LeagueScreen; null elsewhere).
func get_league_screen() -> Control:
	return _league_screen


## QA-ONLY CHEAT: jumps to the last zone and enters the league at stage 0 (league intro screen) without playing the
## zones: no badge or bonus is granted.
func qa_skip_to_league() -> void:
	if _run == null or _run.league.is_empty():
		return
	_run.jump_to_zone(_run.zones.size() - 1)
	_run.start_league()
	_last_league_heal = -1
	_show_league_screen()


## QA-ONLY CHEAT: jumps to league stage `stage` (clamped) and shows the league screen; earlier fights count as won.
func qa_set_league_stage(stage: int) -> void:
	if _run == null or _run.league.is_empty():
		return
	if not _run.is_in_league():
		_run.start_league()
	_run.league_stage = clampi(stage, 0, _run.league.size() - 1)
	_run.league_fights_won = _run.league_stage
	_show_league_screen()


## QA-ONLY CHEAT: wins the current league fight through the real win path (starts it from the league screen if needed,
## then the battle-won handler): card reward next (members / Maître), or the final victory (final boss).
func qa_win_league_fight() -> void:
	if _run == null:
		return
	if _screen_name == SCREEN_LEAGUE:
		league_continue()
	if _battle_screen == null or _fight_room_type != ROOM_LEAGUE:
		return
	var ids: Array[String] = []
	for e: Combatant in _battle_screen.get_battle().enemies:
		ids.append(e.id)
	_on_battle_won(ids)


# --- Rival, legendary, event queues (story 018) ----------------------------------------------------

## The rival of this run: {name, starter_id (stage 1), current_id (form after the badges earned), current_name, sprite, types,
## encounters_done: Array[String], encounters_total}. {} without a run / rival.
func get_rival_info() -> Dictionary:
	if _run == null or _run.rival_starter_id.is_empty():
		return {}
	var cur: String = _run.rival_current_form(_data)
	var info: Dictionary = _data.get_pokemon_info(cur)
	return {"name": _run.rival_name, "starter_id": _run.rival_starter_id, "current_id": cur, "current_name": String(info.get("name", "")),
			"sprite": String(info.get("sprite_path", "")), "types": info.get("types", []),
			"encounters_done": _run.rival_encounters_done.duplicate(), "encounters_total": _data.get_rival_encounters().size()}


## The special fight being played (SpecialFights dict, see special_fights.gd): kind, room, title, rival_def, legendary_id,
## capture... {} during a normal fight / outside battles.
func get_current_fight() -> Dictionary:
	return _current_fight


## What the last special win gave (rival: {kind, encounter_id, money, item, healed}; legendary: {kind, pokemon_id, name, captured,
## cards}); {} after any other fight. Read it on the reward screen.
func get_last_special_reward() -> Dictionary:
	return _last_special_reward


## True if option `index` of the current event can be chosen (requires_money). The event screen greys out the others.
func event_option_available(index: int) -> bool:
	var opts: Array = _current_event.get("options", [])
	return index >= 0 and index < opts.size() and EventResolver.option_available(opts[index], _run)


## Cards the player must still pick to forget (event remove_card_choice); the UI shows a deck picker while > 0.
func get_pending_card_removals() -> int:
	return _run.pending_card_removals if _run != null else 0


## Forgets deck[deck_index] for a pending event removal; when none is left the event flow continues (fight / map). False if refused.
func event_remove_card(deck_index: int) -> bool:
	if _run == null or not _run.remove_card_at(deck_index):
		return false
	_refresh_hud()
	if _screen_name == SCREEN_EVENT:
		_after_event()  # story 018 UI: re-opens the picker while removals remain, else continues the flow
	return true


## QA-ONLY CHEAT (story 018): wins the battle on screen (any kind: rival, pre-league rival, event / legendary fight...)
## through the real win path (_on_battle_won with every enemy as defeated). Ignored outside a battle.
func qa_win_current_fight() -> void:
	if _battle_screen == null:
		return
	var ids: Array[String] = []
	for e: Combatant in _battle_screen.get_battle().enemies:
		ids.append(e.id)
	_on_battle_won(ids)


# --- Save / resume (story 015) ---------------------------------------------------------------------

## QA: the live ResumeScreen (null elsewhere).
func get_resume_screen() -> ResumeScreen:
	return _resume_screen


## QA-ONLY: points the save slot at `path` (a scratch file) AND turns autosave on, so QA runs never touch the real save.
func qa_set_save_path(path: String) -> void:
	_save_path = path
	_autosave = true


## QA-ONLY: turns autosave on / off without changing the path.
func qa_set_autosave(enabled: bool) -> void:
	_autosave = enabled


## QA: true if a file exists in the save slot.
func qa_has_save() -> bool:
	return SaveGame.exists(_save_path)


## QA-ONLY: writes the save now (as on the map, or on the league screen). False if autosave is off or there is no run.
func qa_save_now() -> bool:
	return _autosave_now()


## QA-ONLY: simulates quitting and relaunching: drops the run and shows the resume screen (valid / unreadable save) or the
## starter choice (no save), exactly like the launch of the real game. Without autosave it just starts a fresh run.
func qa_quit_to_title() -> void:
	_clear_screens()
	_run = null
	_hud.visible = false
	if _autosave:
		_show_title()
	else:
		start_new_run(_cli_seed)


## "Reprendre" on the resume screen: rebuilds the saved run (state, map, RNG states) and shows its map / league screen.
func resume_continue() -> void:
	if _screen_name != SCREEN_RESUME or not bool(_resume_result.get("ok", false)):
		return
	var result: Dictionary = _resume_result
	_clear_screens()
	_last_loot = {}
	_last_badge = {}
	_encounter_id = ""
	_fight_room_type = ""
	_evolution_summary = {}
	_team_evolution_rows = []
	_resume_result = {}
	var extras: Dictionary = result["extras"]
	var rngs: Array[RandomNumberGenerator] = _rng_list()
	for i: int in RNG_NAMES.size():
		SaveGame.rng_apply(rngs[i], (extras["rngs"] as Dictionary)[RNG_NAMES[i]])
	_cli_seed = int(String(extras.get("cli_seed", "0")))
	_last_league_heal = int(extras.get("last_league_heal", -1))
	_run = result["run"]
	if String(extras["screen"]) == SCREEN_LEAGUE:
		_show_league_screen()
	else:
		_show_map()


## "Nouvelle partie" on the resume screen: the save (or its unreadable remains) is deleted, then the starter choice.
func resume_new_game() -> void:
	if _screen_name != SCREEN_RESUME:
		return
	SaveGame.delete(_save_path)
	start_new_run(_cli_seed)


## Launch / relaunch: a valid save -> resume screen; an unreadable one -> the same screen with the reason (the file is kept
## as .bak); none -> the starter choice.
func _show_title() -> void:
	var result: Dictionary = SaveGame.load_run(_save_path, _data)
	if bool(result.get("missing", false)):
		start_new_run(_cli_seed)
		return
	if bool(result["ok"]):
		var reason: String = _check_extras(result["run"], result["extras"])
		if not reason.is_empty():
			result = SaveGame._fail(reason)
	_clear_screens()
	_resume_result = result
	_resume_screen = ResumeScreen.new()
	_resume_screen.continue_requested.connect(resume_continue)
	_resume_screen.new_game_requested.connect(resume_new_game)
	_set_screen(_resume_screen, SCREEN_RESUME)
	if bool(result["ok"]):
		_resume_screen.setup_valid(_data, result["run"], String(result["saved_at"]))
	else:
		SaveGame.quarantine(_save_path)
		_resume_screen.setup_error(String(result["error"]))


## Main's part of the save must be complete and consistent with the run: "" = fine, else the French reason.
func _check_extras(run: RunState, extras: Dictionary) -> String:
	var screen: String = String(extras.get("screen", ""))
	if screen != SCREEN_MAP and screen != SCREEN_LEAGUE:
		return "écran de reprise inconnu"
	if screen == SCREEN_MAP and run.act == null:
		return "carte de zone absente"
	if screen == SCREEN_LEAGUE and not run.is_in_league():
		return "étape de ligue absente"
	var rngs: Variant = extras.get("rngs")
	if not (rngs is Dictionary):
		return "états aléatoires absents"
	var probe := RandomNumberGenerator.new()
	for n: String in RNG_NAMES:
		if not SaveGame.rng_apply(probe, (rngs as Dictionary).get(n)):
			return "état aléatoire invalide : %s" % n
	return ""


## Writes the autosave if enabled (SAFE points only: called when the map / league screen is shown). True if written.
func _autosave_now() -> bool:
	if not _autosave or _run == null or _run.is_defeated():
		return false
	var rngs: Dictionary = {}
	var list: Array[RandomNumberGenerator] = _rng_list()
	for i: int in RNG_NAMES.size():
		rngs[RNG_NAMES[i]] = SaveGame.rng_to_dict(list[i])
	var extras: Dictionary = {"screen": SCREEN_LEAGUE if _screen_name == SCREEN_LEAGUE else SCREEN_MAP,
			"last_league_heal": _last_league_heal, "cli_seed": str(_cli_seed), "rngs": rngs}
	return SaveGame.write(_save_path, SaveGame.to_dict(_run, extras))


func _delete_save() -> void:
	if _autosave:
		SaveGame.delete(_save_path)


# --- Flow ----------------------------------------------------------------------------------------

func _show_map() -> void:
	_clear_screens()
	_map_screen = MAP_SCENE.instantiate() as MapScreen
	_map_screen.node_chosen.connect(_on_node_chosen)
	_map_screen.deck_requested.connect(open_deck)
	_set_screen(_map_screen, SCREEN_MAP)
	_map_screen.setup(_data, _run)
	_autosave_now()


func _on_node_chosen(node_id: String) -> void:
	if not _run.act.enter(node_id):
		push_error("Main: room '%s' is not reachable" % node_id)
		return
	var node: MapNode = _run.act.current_node()
	if node.room_type == GameData.ROOM_RIVAL:  # story 018
		_start_special_fight(SpecialFights.rival_room_fight(_data, _run, _encounter_rng))
	elif _data.get_room_type(node.room_type).has("encounter_pool"):
		_start_room_fight(node)
	elif node.room_type == "event":
		_show_event()
	elif node.room_type == "center":
		_show_center()
	elif node.room_type == "mart":
		_show_mart()
	else:
		_show_placeholder_room(node.room_type)


func _start_room_fight(node: MapNode) -> void:
	var encounter_id: String = _data.pick_encounter(node.room_type, node.floor, _encounter_rng, _run.current_zone(),
			_data.deck_attack_types(_run.deck))
	var mods: Dictionary = _data.get_fight_modifiers(node.room_type, _run.current_zone())
	var enemies: Array[Combatant] = _data.create_enemies(encounter_id, float(mods["hp_multiplier"]), int(mods["strength_bonus"]))
	if enemies.is_empty():
		push_error("Main: no enemies for room '%s' (encounter '%s')" % [node.id, encounter_id])
		_show_map()
		return
	_launch_battle(encounter_id, enemies, node.room_type)


## Story 018: starts a SpecialFights fight dict (rival / event fight) with its header; an empty dict (nothing to fight,
## e.g. a rival room whose encounter is already won) goes back to the map.
func _start_special_fight(fight: Dictionary) -> void:
	if fight.is_empty() or (fight["enemies"] as Array).is_empty():
		_current_fight = {}
		_show_map()
		return
	var enemies: Array[Combatant] = []
	enemies.assign(fight["enemies"])
	_launch_battle(String(fight["encounter"]), enemies, String(fight["room"]))
	_current_fight = fight
	if _battle_screen != null and not String(fight["title"]).is_empty():
		var lead_types: Array[String] = enemies[0].type_ids
		_battle_screen.set_trainer_header(String(fight["title"]), _data.get_type_color(lead_types[0] if not lead_types.is_empty() else "normal"),
				String(fight["room"]) in [GameData.ROOM_RIVAL_FINAL, GameData.ROOM_LEGENDARY])
	if _battle_screen != null and String(fight["room"]) in [GameData.ROOM_RIVAL, GameData.ROOM_RIVAL_FINAL]:
		_battle_screen.show_rival_intro(_rival_intro_info(fight, enemies))  # story 018 UI: "{name} te défie !"


## Story 018 UI: what the rival intro banner shows (RivalIntroBanner.setup).
func _rival_intro_info(fight: Dictionary, enemies: Array[Combatant]) -> Dictionary:
	var rival: Dictionary = get_rival_info()
	var def_id: String = String((fight.get("rival_def", {}) as Dictionary).get("id", ""))
	var number: int = 1
	var all_defs: Array[Dictionary] = _data.get_rival_encounters()
	for i: int in all_defs.size():
		if String(all_defs[i].get("id", "")) == def_id:
			number = i + 1
	var team: Array[String] = []
	for e: Combatant in enemies:
		team.append(String(_data.get_pokemon_info(e.id).get("sprite_path", "")))
	return {"name": String(rival.get("name", "")), "sprite": String(rival.get("sprite", "")), "current_name": String(rival.get("current_name", "")),
			"number": number, "total": all_defs.size(), "final": String(fight["room"]) == GameData.ROOM_RIVAL_FINAL, "team": team}


func _launch_battle(encounter_id: String, enemies: Array[Combatant], room_type: String) -> void:
	if enemies.is_empty():
		return
	_clear_screens()
	_current_fight = {}
	_encounter_id = encounter_id
	_fight_room_type = room_type
	# Story 017: balls only in the room types of balls.json capture.allowed_room_types (wild); never gyms / league / QA "".
	var battle: Battle = _run.create_battle(enemies, _data.get_type_chart(), _battle_rng, _data.capture_allowed_in(room_type))
	battle.state_changed.connect(_refresh_hud)
	battle.item_triggered.connect(_on_item_triggered)
	_battle_screen = BATTLE_SCENE.instantiate() as BattleScreen
	_battle_screen.battle_won.connect(_on_battle_won)
	_battle_screen.defeat_acknowledged.connect(_show_defeat)
	battle.battle_lost.connect(_on_battle_lost)
	_set_screen(_battle_screen, SCREEN_BATTLE)
	_battle_screen.setup(battle, _data, _run, encounter_id)
	_battle_screen.set_backdrop(_backdrop_for(room_type))
	_refresh_hud()


## Story 020: battle backdrop id (assets/data/backdrops.json) for a fight in `room_type`: the league hall for league
## fights (league_continue switches the final boss to "ethernatos"), the legendary backdrop for the legendary event,
## otherwise the current zone's gym type (BattleBackdrop falls back to "route" for an unknown / empty type).
func _backdrop_for(room_type: String) -> String:
	if room_type == ROOM_LEAGUE:
		return BACKDROP_LEAGUE
	if room_type == GameData.ROOM_LEGENDARY:
		return BACKDROP_LEGENDARY
	return String(get_zone().get("type_id", ""))


func _on_battle_won(defeated_ids: Array[String]) -> void:
	var won_battle: Battle = _battle_screen.get_battle()
	_run.record_battle_result(won_battle.player, defeated_ids)
	# Story 017: captured Pokémon left the battle (not in defeated_ids: no xp / stolen card); they join the team now.
	_last_captures = _run.apply_captures(won_battle.captured_ids)
	var weights: Dictionary = {}
	_last_special_reward = {}
	var room: String = _fight_room_type
	if room in [GameData.ROOM_RIVAL, GameData.ROOM_RIVAL_FINAL] and not _current_fight.is_empty():  # story 018
		var def: Dictionary = _current_fight["rival_def"]
		_last_loot = SpecialFights.apply_rival_win(_data, _run, def, _loot_rng)
		_last_special_reward = {"kind": room, "encounter_id": String(def["id"]), "money": int(_last_loot["money"]),
				"item": _last_loot["item"], "healed": int(_last_loot["healed"])}
		_show_reward_screen(SpecialFights.rival_reward_offers(_data, _run, def, defeated_ids, _reward_rng), _last_loot)
		return
	if room == GameData.ROOM_LEGENDARY and not _current_fight.is_empty():  # story 018
		_last_special_reward = SpecialFights.apply_legendary_win(_data, _run, String(_current_fight["legendary_id"]),
				won_battle.captured_ids)
		_last_special_reward["kind"] = room
		_last_loot = {}
		_show_reward_screen(RewardGenerator.generate(_data, _run.player_id, [] as Array[String], _reward_rng,
				_data.get_room_rarity_weights("elite")), {})
		return
	if _fight_room_type == ROOM_LEAGUE:  # story 013: no loot; the final boss ends the run with the victory
		_run.win_league_fight()
		if _run.final_boss_defeated:
			_show_victory()
			return
		_last_loot = {}
		weights = _data.get_league_reward_weights()
	else:
		_last_loot = _run.apply_loot(LootGenerator.generate(_data, _run, _fight_room_type, _loot_rng))
		weights = _data.get_room_rarity_weights(_fight_room_type) if not _fight_room_type.is_empty() else {}
	var offers: Array[RewardOffer] = RewardGenerator.generate(_data, _run.player_id, defeated_ids, _reward_rng, weights)
	_show_reward_screen(offers, _last_loot if not _fight_room_type.is_empty() and _fight_room_type != ROOM_LEAGUE else {})


## The reward screen with `offers` and `loot` (apply_loot format; {} = none) plus the captures of the last win.
func _show_reward_screen(offers: Array[RewardOffer], loot: Dictionary) -> void:
	var keep_fight: Dictionary = _current_fight
	_clear_screens()
	_current_fight = keep_fight
	_offers = offers
	_reward_screen = REWARD_SCENE.instantiate() as RewardScreen
	_reward_screen.card_chosen.connect(_on_card_chosen)
	_reward_screen.skipped.connect(_after_reward)
	_reward_screen.deck_requested.connect(open_deck)
	_set_screen(_reward_screen, SCREEN_REWARD)
	_reward_screen.setup(_data, _run, _offers)
	_reward_screen.set_loot(loot)
	_reward_screen.set_captures(_last_captures)
	_reward_screen.set_special(_last_special_reward, _run.rival_name)  # story 018 UI: rival / legendary titles


func _on_card_chosen(card: CardData) -> void:
	_run.add_card(card)
	_after_reward()


## Back to the map; after a gym win (story 012) the badge comes first; after a league fight (story 013) the heal of
## league.json heal_percent_between_fights then the league intermission screen (next fight).
func _after_reward() -> void:
	if not _show_team_evolution(_after_team_evolution):
		_after_team_evolution()


func _after_team_evolution() -> void:
	if _fight_room_type == ROOM_LEAGUE:
		_last_league_heal = _run.advance_league(_data.get_league_heal_percent())
		_show_league_screen()
	elif _fight_room_type == ROOM_BOSS:
		_show_badge()
	elif _fight_room_type == GameData.ROOM_RIVAL_FINAL:  # story 018: the pre-league rival is beaten -> the league
		_enter_league()
	else:
		_show_map()


## Story 012: awards the zone's badge (RunState.award_badge: bonuses + heal, data) and shows the badge screen
## (BadgeScreen, get_badge_screen()); its button calls badge_continue().
func _show_badge() -> void:
	_last_badge = _run.award_badge(_data)
	_clear_screens()
	if _last_badge.is_empty():  # no zones configured: nothing to award
		_next_zone_or_victory()
		return
	_badge_screen = BadgeScreen.new()
	_badge_screen.finished.connect(badge_continue)
	_set_screen(_badge_screen, SCREEN_BADGE)
	_badge_screen.setup(_data, _run, _last_badge)


## After the badge (and the evolution): the next zone's map, or the league (story 013: Conseil 4 -> Maître -> final boss)
## once the last zone's gym is beaten (the victory directly only without league data).
func _next_zone_or_victory() -> void:
	if _run.is_final_zone() or not _run.advance_zone():
		# Story 018: the rival waits right before the Route Victoire (automatic fight, once).
		var rival: Dictionary = SpecialFights.rival_final_fight(_data, _run, _encounter_rng)
		if not rival.is_empty():
			_start_special_fight(rival)
			return
		_enter_league()
		return
	if not _run.start_act(_data, 0):
		push_error("Main: could not start zone %d" % (_run.zone_index + 1))
		_show_victory()
		return
	_show_map()


## Story 013: league intro after the last badge (story 018: after the pre-league rival); the victory without league data.
func _enter_league() -> void:
	if _run.start_league():
		_last_league_heal = -1
		_show_league_screen()
	else:
		_show_victory()


## The battle is lost: HP 0 is written to the run now (the HUD / summary read it); the overlay's "Continuer"
## then shows the defeat summary (_show_defeat).
func _on_battle_lost() -> void:
	_delete_save()  # the run is lost: no way back to a safe point by quitting
	_run.record_battle_result(_battle_screen.get_battle().player)
	_refresh_hud()


## "Nouvelle partie" (victory / defeat): a brand new run, back to the starter choice (same seed only with --seed).
func _on_new_run_requested() -> void:
	start_new_run(_cli_seed)


## Story 007 (story 012: after the badges of zones.json evolution_after_badges): the chosen starter evolves (RunState.evolve_starter, data-driven), then
## the evolved form offers its cards (EvolutionOffer). The run's HP / deck change here; the screen only displays.
func _show_evolution(badge_number: int) -> void:
	_clear_screens()  # before the offers: it resets _evolution_offers
	_evolution_summary = _run.evolve_starter(_data, badge_number)
	if _evolution_summary.is_empty():
		_next_zone_or_victory()
		return
	_evolution_offers = EvolutionOffer.generate(_data, _run, _evolution_summary)
	_evolution_screen = EvolutionScreen.new()
	_evolution_screen.card_chosen.connect(_on_evolution_card_chosen)
	_evolution_screen.finished.connect(_next_zone_or_victory)
	_set_screen(_evolution_screen, SCREEN_EVOLUTION)
	_evolution_screen.setup(_data, _run, _evolution_summary, _evolution_offers)


## Story 014: team Pokémon due to evolve (RunState.evolve_team, after a won battle's reward): the compact "Évolutions"
## summary (EvolutionScreen.setup_team), then `then` runs. Returns false (nothing shown, `then` NOT called) if none is due.
func _show_team_evolution(then: Callable) -> bool:
	var rows: Array[Dictionary] = _run.evolve_team(_data)
	if rows.is_empty():
		return false
	_clear_screens()
	_team_evolution_rows = rows
	_evolution_screen = EvolutionScreen.new()
	_evolution_screen.finished.connect(then)
	_set_screen(_evolution_screen, SCREEN_EVOLUTION)
	_evolution_screen.setup_team(_data, _run, rows)
	return true


func _on_evolution_card_chosen(index: int) -> void:
	var card: CardData = _evolution_offers[index]
	_run.add_card(card)
	_evolution_screen.show_result("%s rejoint ton deck !" % card.display_name)


## Story 013: league intro (before the first fight) / intermission (after a heal) / final-boss intro: LeagueScreen
## (get_league_screen()); its "Affronter <Nom>" button calls league_continue().
func _show_league_screen() -> void:
	_clear_screens()
	var screen := LeagueScreen.new()
	_league_screen = screen
	screen.finished.connect(league_continue)
	_set_screen(screen, SCREEN_LEAGUE)
	screen.setup(_data, _run, _last_league_heal)
	_autosave_now()


func _show_victory() -> void:
	_show_run_end(true)


## Defeat summary; only once HP is 0 (a stray call with HP left is refused).
func _show_defeat() -> void:
	if _run == null or not _run.is_defeated():
		return
	_show_run_end(false)


func _show_run_end(victory: bool) -> void:
	_delete_save()  # victory or defeat ends the run for good
	_clear_screens()
	_end_screen = RunEndScreen.new()
	_end_screen.new_run_requested.connect(_on_new_run_requested)
	_set_screen(_end_screen, SCREEN_VICTORY if victory else SCREEN_DEFEAT)
	_end_screen.setup(_data, _run, victory)


## Any HP loss outside a battle (events, services) that reaches 0 also ends the run. Events never go below
## 1 HP today (RunState.lose_hp), so this is a safety net for future effects.
func _check_defeat_outside_battle() -> bool:
	if _run != null and _run.is_defeated():
		_show_defeat()
		return true
	return false


func _show_event() -> void:
	var event: Dictionary = EventResolver.pick_event(_data, _event_rng, _run)  # story 018: zone filter, legendary, {rival}
	if event.is_empty():
		push_error("Main: empty event pool")
		_show_map()
		return
	_show_event_def(event)


## QA-ONLY (story 018 UI shots): shows event `event_id` of events.json ({rival} substituted), no draw. Ignored if unknown.
func qa_show_event(event_id: String) -> void:
	var event: Dictionary = _data.get_event(event_id)
	if _run == null or event.is_empty():
		return
	_show_event_def(EventResolver._personalise(event, _run))


func _show_event_def(event: Dictionary) -> void:
	_clear_screens()
	_current_event = event
	_event_screen = EVENT_SCENE.instantiate() as EventScreen
	_event_screen.option_chosen.connect(_on_event_option_chosen)
	_event_screen.finished.connect(_after_event)
	_event_screen.removal_picked.connect(event_remove_card)
	_set_screen(_event_screen, SCREEN_EVENT)
	_event_screen.setup(event, _run, _data, event_option_available)


func _on_event_option_chosen(index: int) -> void:
	var option: Dictionary = (_current_event.get("options", []) as Array)[index]
	if not EventResolver.option_available(option, _run):  # story 018: requires_money
		return
	var summary: String = EventResolver.apply_effects(option.get("effects", []), _run, _data, _event_rng)
	if _check_defeat_outside_battle():
		return
	_event_screen.show_result(String(option.get("result_text", "")), summary, _run)


## Story 018: after the event's "Continuer": a queued card removal must be resolved first (event_remove_card; the UI shows
## the deck picker while get_pending_card_removals() > 0), then a queued fight starts, else the map.
func _after_event() -> void:
	if _run.pending_card_removals > 0 and _run.deck.size() > 1:
		if _event_screen != null:  # story 018 UI: the deck picker resolves it (event_remove_card), never a dead end
			_event_screen.open_removal(_run, _data, _run.pending_card_removals)
		return
	_run.pending_card_removals = 0
	if not _run.pending_fight.is_empty():
		_start_special_fight(SpecialFights.event_fight(_data, _run, _encounter_rng))
		return
	_show_map()


func _on_item_triggered(item: ItemData) -> void:
	_hud.flash_item(item)


## Centre Pokémon (story 006): heal OR upgrade one card, applied here through RunState. Never auto-heals.
func _show_center() -> void:
	_clear_screens()
	_center_screen = CenterScreen.new()
	_center_screen.heal_chosen.connect(_on_center_heal)
	_center_screen.upgrade_chosen.connect(_on_center_upgrade)
	_center_screen.finished.connect(_show_map)
	_set_screen(_center_screen, SCREEN_CENTER)
	_center_screen.setup(_data, _run, _run.rest_heal_preview(), _run.rest_heal_percent())


func _on_center_heal() -> void:
	var healed: int = _run.rest_heal()
	_refresh_hud()
	_center_screen.show_result("Tu te reposes : +%d PV (PV %d/%d)." % [healed, _run.hp, _run.max_hp])


func _on_center_upgrade(deck_index: int) -> void:
	var before: String = _run.deck[deck_index].display_name if deck_index >= 0 and deck_index < _run.deck.size() else ""
	if _run.upgrade_card(deck_index):
		_center_screen.show_result("%s devient %s !" % [before, _run.deck[deck_index].display_name])
	else:
		push_error("Main: cannot upgrade deck card %d" % deck_index)
		_center_screen.show_result("Impossible d'améliorer cette carte.")


## Poké Mart (story 006): one ShopInventory per visit; purchases / removals applied here.
func _show_mart() -> void:
	_clear_screens()
	_shop = create_shop_inventory()
	_mart_screen = MartScreen.new()
	_mart_screen.buy_requested.connect(_on_shop_buy)
	_mart_screen.remove_requested.connect(_on_shop_remove)
	_mart_screen.finished.connect(_show_map)
	_set_screen(_mart_screen, SCREEN_MART)
	_mart_screen.setup(_data, _run, _shop)


func _on_shop_buy(kind: String, index: int) -> void:
	var ok: bool = false
	var label: String = ""
	match kind:
		ShopEntry.KIND_CARD:
			label = _shop.cards[index].get_name()
			ok = _shop.buy_card(index)
		ShopEntry.KIND_ITEM:
			label = _shop.items[index].get_name()
			ok = _shop.buy_item(index)
		ShopEntry.KIND_POTION:
			label = _shop.potions[index].get_name()
			ok = _shop.buy_potion(index)
		ShopEntry.KIND_BALL:
			label = _shop.balls[index].get_name()
			ok = _shop.buy_ball(index)
	_refresh_hud()
	_mart_screen.refresh("Acheté : %s." % label if ok else "Achat impossible.")


func _on_shop_remove(deck_index: int) -> void:
	var label: String = _run.deck[deck_index].display_name if deck_index >= 0 and deck_index < _run.deck.size() else ""
	var ok: bool = _shop.remove_card(deck_index)
	_refresh_hud()
	_mart_screen.refresh("Carte retirée : %s." % label if ok else "Retrait impossible.")


## Fallback for a room type without a screen (none in act 1 since story 006).
func _show_placeholder_room(room_type: String) -> void:
	var room: Dictionary = _data.get_room_type(room_type)
	var body: String = "Bientôt disponible."
	_clear_screens()
	_room_screen = ROOM_SCENE.instantiate() as PlaceholderRoomScreen
	_room_screen.finished.connect(_show_map)
	_set_screen(_room_screen, SCREEN_ROOM)
	_room_screen.setup(String(room.get("name", room_type)), body, "Continuer",
			MapCanvas.ROOM_COLORS.get(room_type, MapCanvas.COLOR_UNKNOWN_ROOM))


func _set_screen(screen: Control, screen_name: String) -> void:
	_screen = screen
	_screen_name = screen_name
	add_child(screen)
	# No HUD on the starter choice nor on the end summaries (they show money / items themselves).
	var show_hud: bool = _run != null and screen_name not in [SCREEN_STARTER, SCREEN_VICTORY, SCREEN_DEFEAT]
	_hud.visible = show_hud
	screen.offset_top = RunHud.HEIGHT if show_hud else 0.0
	if _deck_panel != null:
		_deck_panel.close()  # a new screen always starts with the panel closed
		move_child(_deck_panel, get_child_count() - 1)
	move_child(_hud, get_child_count() - 1)
	_refresh_hud()


## Redraws the HUD from the run (and the live battle's potions).
func _refresh_hud() -> void:
	if _hud != null and _run != null:
		_hud.refresh(_run, _battle_screen.get_battle() if _battle_screen != null else null)


func _clear_screens() -> void:
	if _screen != null:
		remove_child(_screen)
		_screen.queue_free()
	_screen = null
	_screen_name = SCREEN_NONE
	_battle_screen = null
	_starter_screen = null
	_reward_screen = null
	_map_screen = null
	_event_screen = null
	_room_screen = null
	_center_screen = null
	_mart_screen = null
	_evolution_screen = null
	_end_screen = null
	_resume_screen = null
	_badge_screen = null
	_league_screen = null
	_evolution_offers = []
	_team_evolution_rows = []
	_shop = null
	_offers = []
	_current_event = {}
	_current_fight = {}
