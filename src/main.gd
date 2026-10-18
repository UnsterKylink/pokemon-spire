class_name Main
extends Control
## Run owner: holds GameData, RunState and RNGs, and switches BattleScreen <-> RewardScreen.
## Screens only display and emit signals; all persistent state lives here / in RunState.
## Implements: story-004-recompenses-vol-attaque (flow: battle -> reward -> next battle).

const PLAYER_ID: String = "salameche"
const ENCOUNTER_ARG_PREFIX: String = "--encounter="
const BATTLE_SCENE: PackedScene = preload("res://src/ui/battle_screen.tscn")
const REWARD_SCENE: PackedScene = preload("res://src/ui/reward_screen.tscn")

var _data: GameData
var _run: RunState
var _battle_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _encounter_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _reward_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _encounter_order: Array[String] = []
var _encounter_id: String = ""
var _battle_screen: BattleScreen
var _reward_screen: RewardScreen
var _offers: Array[RewardOffer] = []


func _ready() -> void:
	_data = GameData.new()
	if not _data.load_all():
		push_error("Main: could not load game data")
		return
	_encounter_order = _data.get_encounter_order()
	if _encounter_order.is_empty():
		push_error("Main: no encounter defined")
		return
	_battle_rng.randomize()
	_encounter_rng.randomize()
	_reward_rng.randomize()
	_run = RunState.create(_data, PLAYER_ID)
	if _run == null:
		return
	var first_id: String = _pick_random_encounter("")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(ENCOUNTER_ARG_PREFIX):
			var requested: String = arg.substr(ENCOUNTER_ARG_PREFIX.length())
			if _encounter_order.has(requested):
				first_id = requested
			else:
				push_error("Main: unknown encounter '%s' in --encounter, using '%s'" % [requested, first_id])
	start_encounter(first_id)


## Starts a battle on `encounter_id` with the CURRENT run state (HP and deck persist).
func start_encounter(encounter_id: String) -> void:
	if _run == null or not _encounter_order.has(encounter_id):
		push_error("Main: cannot start encounter '%s'" % encounter_id)
		return
	var enemies: Array[Combatant] = _data.create_enemies(encounter_id)
	if enemies.is_empty():
		return
	_clear_screens()
	_encounter_id = encounter_id
	var battle: Battle = _run.create_battle(enemies, _data.get_type_chart(), _battle_rng)
	_battle_screen = BATTLE_SCENE.instantiate() as BattleScreen
	_battle_screen.battle_won.connect(_on_battle_won)
	_battle_screen.restart_requested.connect(_on_restart_requested)
	add_child(_battle_screen)
	_battle_screen.setup(battle, _data, _run, encounter_id)


## Starts a brand new run (full HP, starter deck) and a random battle.
func start_new_run() -> void:
	_run = RunState.create(_data, PLAYER_ID)
	start_encounter(_pick_random_encounter(_encounter_id))


## QA: the run state (HP, deck).
func get_run_state() -> RunState:
	return _run


## QA: "battle", "reward" or "none".
func get_current_screen_name() -> String:
	if _battle_screen != null:
		return "battle"
	if _reward_screen != null:
		return "reward"
	return "none"


## QA: the live BattleScreen (null outside a battle).
func get_battle_screen() -> BattleScreen:
	return _battle_screen


## QA: the live RewardScreen (null outside the reward phase).
func get_reward_screen() -> RewardScreen:
	return _reward_screen


## QA: current encounter id.
func get_encounter_id() -> String:
	return _encounter_id


## QA: the offers of the current reward screen (empty outside it).
func get_reward_offers() -> Array[RewardOffer]:
	return _offers


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


func _on_battle_won(defeated_ids: Array[String]) -> void:
	_run.record_battle_result(_battle_screen.get_battle().player)
	_clear_screens()
	_offers = RewardGenerator.generate(_data, _run.player_id, defeated_ids, _reward_rng)
	_reward_screen = REWARD_SCENE.instantiate() as RewardScreen
	_reward_screen.card_chosen.connect(_on_card_chosen)
	_reward_screen.skipped.connect(_start_next_battle)
	add_child(_reward_screen)
	_reward_screen.setup(_data, _run, _offers)


func _on_card_chosen(card: CardData) -> void:
	_run.add_card(card)
	_start_next_battle()


func _on_restart_requested() -> void:
	start_new_run()


## Next battle: random encounter, never the same twice in a row.
func _start_next_battle() -> void:
	start_encounter(_pick_random_encounter(_encounter_id))


func _clear_screens() -> void:
	for screen: Control in [_battle_screen, _reward_screen]:
		if screen != null:
			remove_child(screen)
			screen.queue_free()
	_battle_screen = null
	_reward_screen = null
	_offers = []


func _pick_random_encounter(exclude: String) -> String:
	var pool: Array[String] = []
	for id: String in _encounter_order:
		if id != exclude:
			pool.append(id)
	if pool.is_empty():
		return _encounter_order[0]
	return pool[_encounter_rng.randi_range(0, pool.size() - 1)]
