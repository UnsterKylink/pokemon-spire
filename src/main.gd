class_name Main
extends Control
## Run owner: holds GameData, RunState and RNGs, and switches between the screens
## (MapScreen -> Battle/Event/placeholder room -> Reward -> MapScreen ... -> boss -> act end).
## Screens only display and emit signals; all persistent state lives here / in RunState.
## Implements: story-005-carte-acte-1 (act map flow), story-004-recompenses-vol-attaque (rewards).
## CLI (user args, after `--`): `--seed=<int>` forces the first map seed (and seeds the run RNGs, for QA);
## `--encounter=<id>` starts that encounter directly (debug).

const PLAYER_ID: String = "salameche"
const ENCOUNTER_ARG_PREFIX: String = "--encounter="
const SEED_ARG_PREFIX: String = "--seed="
const BATTLE_SCENE: PackedScene = preload("res://src/ui/battle_screen.tscn")
const REWARD_SCENE: PackedScene = preload("res://src/ui/reward_screen.tscn")
const MAP_SCENE: PackedScene = preload("res://src/ui/map_screen.tscn")
const EVENT_SCENE: PackedScene = preload("res://src/ui/event_screen.tscn")
const ROOM_SCENE: PackedScene = preload("res://src/ui/placeholder_room_screen.tscn")
const SCREEN_NONE: String = "none"
const SCREEN_MAP: String = "map"
const SCREEN_BATTLE: String = "battle"
const SCREEN_REWARD: String = "reward"
const SCREEN_EVENT: String = "event"
const SCREEN_ROOM: String = "room"
const SCREEN_ACT_END: String = "act_end"
const COLOR_ACT_END: Color = Color(1.0, 0.8, 0.28)

var _data: GameData
var _run: RunState
var _battle_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _encounter_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _reward_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _event_rng: RandomNumberGenerator = RandomNumberGenerator.new()
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
var _offers: Array[RewardOffer] = []


func _ready() -> void:
	_data = GameData.new()
	if not _data.load_all():
		push_error("Main: could not load game data")
		return
	_encounter_order = _data.get_encounter_order()
	var forced_seed: int = 0
	var debug_encounter: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(SEED_ARG_PREFIX):
			var value: String = arg.substr(SEED_ARG_PREFIX.length())
			if value.is_valid_int() and int(value) != 0:
				forced_seed = int(value)
			else:
				push_error("Main: invalid --seed '%s' (non-zero integer expected), using a random seed" % value)
		elif arg.begins_with(ENCOUNTER_ARG_PREFIX):
			debug_encounter = arg.substr(ENCOUNTER_ARG_PREFIX.length())
	start_new_run(forced_seed)
	if not debug_encounter.is_empty():
		start_encounter(debug_encounter)


## Starts a brand new run (full HP, starter deck) on a new act map and shows the map.
## `act_seed` 0 = random map and RNGs; any other value makes the map AND the run RNGs reproducible (QA).
func start_new_run(act_seed: int = 0) -> void:
	var run: RunState = RunState.create(_data, PLAYER_ID)
	if run == null:
		return
	var rngs: Array[RandomNumberGenerator] = [_battle_rng, _encounter_rng, _reward_rng, _event_rng]
	for i: int in rngs.size():
		if act_seed != 0:
			rngs[i].seed = act_seed + i + 1
		else:
			rngs[i].randomize()
	if not run.start_act(_data, act_seed):
		push_error("Main: could not start the act")
		return
	_run = run
	_show_map()


## Debug/QA entry point: starts a battle on `encounter_id` (x1 modifiers, normal reward) with the CURRENT
## run state; the win leads back to the map.
func start_encounter(encounter_id: String) -> void:
	if _run == null or not _encounter_order.has(encounter_id):
		push_error("Main: cannot start encounter '%s'" % encounter_id)
		return
	_launch_battle(encounter_id, _data.create_enemies(encounter_id), "")


# --- QA accessors -------------------------------------------------------------------------------

## QA: the run state (HP, deck, act progress).
func get_run_state() -> RunState:
	return _run


## QA: "map", "battle", "reward", "event", "room", "act_end" (or "none").
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


## QA: the live placeholder / act-end screen (null otherwise).
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
		_map_screen.open_deck()


## QA: closes the map's deck overlay.
func map_close_deck() -> void:
	if _map_screen != null:
		_map_screen.close_deck()


## QA: clicks event option `index`.
func event_choose(index: int) -> void:
	if _event_screen != null:
		_event_screen.choose(index)


## QA: presses "Continuer" on the event result.
func event_continue() -> void:
	if _event_screen != null:
		_event_screen.press_continue()


## QA: presses the button of the placeholder room or act-end screen.
func room_continue() -> void:
	if _room_screen != null:
		_room_screen.press_continue()


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
	if _reward_screen != null:
		_reward_screen.close_deck()


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


# --- Flow ----------------------------------------------------------------------------------------

func _show_map() -> void:
	_clear_screens()
	_map_screen = MAP_SCENE.instantiate() as MapScreen
	_map_screen.node_chosen.connect(_on_node_chosen)
	_set_screen(_map_screen, SCREEN_MAP)
	_map_screen.setup(_data, _run)


func _on_node_chosen(node_id: String) -> void:
	if not _run.act.enter(node_id):
		push_error("Main: room '%s' is not reachable" % node_id)
		return
	var node: MapNode = _run.act.current_node()
	if _data.get_room_type(node.room_type).has("encounter_pool"):
		_start_room_fight(node)
	elif node.room_type == "event":
		_show_event()
	else:
		_show_placeholder_room(node.room_type)


func _start_room_fight(node: MapNode) -> void:
	var encounter_id: String = _data.pick_encounter(node.room_type, node.floor, _encounter_rng)
	var mods: Dictionary = _data.get_room_modifiers(node.room_type)
	var enemies: Array[Combatant] = _data.create_enemies(encounter_id, float(mods["hp_multiplier"]), int(mods["strength_bonus"]))
	if enemies.is_empty():
		push_error("Main: no enemies for room '%s' (encounter '%s')" % [node.id, encounter_id])
		_show_map()
		return
	_launch_battle(encounter_id, enemies, node.room_type)


func _launch_battle(encounter_id: String, enemies: Array[Combatant], room_type: String) -> void:
	if enemies.is_empty():
		return
	_clear_screens()
	_encounter_id = encounter_id
	_fight_room_type = room_type
	var battle: Battle = _run.create_battle(enemies, _data.get_type_chart(), _battle_rng)
	_battle_screen = BATTLE_SCENE.instantiate() as BattleScreen
	_battle_screen.battle_won.connect(_on_battle_won)
	_battle_screen.restart_requested.connect(_on_restart_requested)
	_set_screen(_battle_screen, SCREEN_BATTLE)
	_battle_screen.setup(battle, _data, _run, encounter_id)


func _on_battle_won(defeated_ids: Array[String]) -> void:
	_run.record_battle_result(_battle_screen.get_battle().player)
	var weights: Dictionary = _data.get_room_rarity_weights(_fight_room_type) if not _fight_room_type.is_empty() else {}
	var offers: Array[RewardOffer] = RewardGenerator.generate(_data, _run.player_id, defeated_ids, _reward_rng, weights)
	_clear_screens()
	_offers = offers
	_reward_screen = REWARD_SCENE.instantiate() as RewardScreen
	_reward_screen.card_chosen.connect(_on_card_chosen)
	_reward_screen.skipped.connect(_after_reward)
	_set_screen(_reward_screen, SCREEN_REWARD)
	_reward_screen.setup(_data, _run, _offers)


func _on_card_chosen(card: CardData) -> void:
	_run.add_card(card)
	_after_reward()


## Back to the map, or the act-end message after the boss fight.
func _after_reward() -> void:
	if _fight_room_type == "boss" and _run.act.is_boss_current():
		_show_act_end()
	else:
		_show_map()


func _on_restart_requested() -> void:
	start_new_run()


func _show_event() -> void:
	var event: Dictionary = EventResolver.pick_event(_data, _event_rng)
	if event.is_empty():
		push_error("Main: empty event pool")
		_show_map()
		return
	_clear_screens()
	_current_event = event
	_event_screen = EVENT_SCENE.instantiate() as EventScreen
	_event_screen.option_chosen.connect(_on_event_option_chosen)
	_event_screen.finished.connect(_show_map)
	_set_screen(_event_screen, SCREEN_EVENT)
	_event_screen.setup(event, _run)


func _on_event_option_chosen(index: int) -> void:
	var option: Dictionary = (_current_event.get("options", []) as Array)[index]
	var summary: String = EventResolver.apply_effects(option.get("effects", []), _run, _data, _event_rng)
	_event_screen.show_result(String(option.get("result_text", "")), summary, _run)


## Centre / Mart placeholder (contents = story 006). The centre's provisional heal comes from
## act1.json room_types.center.heal_percent.
func _show_placeholder_room(room_type: String) -> void:
	var room: Dictionary = _data.get_room_type(room_type)
	var body: String = ""
	var heal: float = float(room.get("heal_percent", 0))
	if heal > 0.0:
		var healed: int = _run.heal_percent(heal)
		body = "Tu te reposes : +%d PV (PV %d/%d).\n\n" % [healed, _run.hp, _run.max_hp]
	body += "Bientôt disponible — tâche 006"
	_clear_screens()
	_room_screen = ROOM_SCENE.instantiate() as PlaceholderRoomScreen
	_room_screen.finished.connect(_show_map)
	_set_screen(_room_screen, SCREEN_ROOM)
	_room_screen.setup(String(room.get("name", room_type)), body, "Continuer",
			MapCanvas.ROOM_COLORS.get(room_type, MapCanvas.COLOR_UNKNOWN_ROOM))


## Minimal end-of-act message (the real victory / evolution screen is story 007).
func _show_act_end() -> void:
	_clear_screens()
	_room_screen = ROOM_SCENE.instantiate() as PlaceholderRoomScreen
	_room_screen.finished.connect(_on_restart_requested)
	_set_screen(_room_screen, SCREEN_ACT_END)
	_room_screen.setup("Acte 1 terminé !",
			"Tu as vaincu le %s ! PV %d/%d   |   Deck : %d cartes" % [_data.get_room_name("boss"), _run.hp, _run.max_hp, _run.deck.size()],
			"Nouvelle partie", COLOR_ACT_END)


func _set_screen(screen: Control, screen_name: String) -> void:
	_screen = screen
	_screen_name = screen_name
	add_child(screen)


func _clear_screens() -> void:
	if _screen != null:
		remove_child(_screen)
		_screen.queue_free()
	_screen = null
	_screen_name = SCREEN_NONE
	_battle_screen = null
	_reward_screen = null
	_map_screen = null
	_event_screen = null
	_room_screen = null
	_offers = []
	_current_event = {}
