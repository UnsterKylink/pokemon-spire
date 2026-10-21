class_name Main
extends Control
## Run owner: holds GameData, RunState and RNGs, and switches between the screens
## (MapScreen -> Battle/Event/placeholder room -> Reward -> MapScreen ... -> boss -> act end).
## Screens only display and emit signals; all persistent state lives here / in RunState.
## Implements: story-005-carte-acte-1 (act map flow), story-004-recompenses-vol-attaque (rewards),
## story-006-objets-et-services (permanent RunHud, potions in battle, loot on the reward screen, Centre Pokémon
## and Poké Mart screens: Main applies every service / purchase through RunState / ShopInventory).
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
const SCREEN_ACT_END: String = "act_end"
const COLOR_ACT_END: Color = Color(1.0, 0.8, 0.28)

var _data: GameData
var _run: RunState
var _battle_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _encounter_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _reward_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _event_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _starter_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Story 006: win loot (money / item / potion) and Poké Mart stock; appended to the rng list so older seeds are unchanged.
var _loot_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _shop_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## What the last won fight paid: {"money": int, "item": ItemData|null, "potion": PotionData|null} ({} before any win).
var _last_loot: Dictionary = {}
## Non-empty = every new run starts with this Pokémon without showing the choice (QA / `--starter=`).
var forced_starter_id: String = ""
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
## The current Poké Mart visit's stock (null outside the Mart): one per visit.
var _shop: ShopInventory
## Permanent money / items / potions bar (story 006), above every run screen except the starter choice.
var _hud: RunHud
var _offers: Array[RewardOffer] = []


func _ready() -> void:
	_data = GameData.new()
	if not _data.load_all():
		push_error("Main: could not load game data")
		return
	_encounter_order = _data.get_encounter_order()
	_hud = RunHud.new()
	_hud.visible = false
	_hud.potion_pressed.connect(battle_use_potion)
	add_child(_hud)
	var forced_seed: int = 0
	var debug_encounter: String = ""
	for arg: String in OS.get_cmdline_user_args():
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
	start_new_run(forced_seed)
	if not debug_encounter.is_empty():
		start_encounter(debug_encounter)


## Starts a brand new run: shows the starter choice screen (3 proposals drawn with the run RNG), unless
## `starter_id` (or `forced_starter_id`) is given. `act_seed` 0 = random map and RNGs; any other value makes
## the map, the starter draw AND the run RNGs reproducible (QA).
func start_new_run(act_seed: int = 0, starter_id: String = "") -> void:
	var rngs: Array[RandomNumberGenerator] = [_battle_rng, _encounter_rng, _reward_rng, _event_rng, _starter_rng, _loot_rng, _shop_rng]
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


func _begin_run(starter_id: String, act_seed: int) -> void:
	var run: RunState = RunState.create_with_starter(_data, starter_id)
	if run == null:
		return
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


## QA: the live StarterScreen (null outside the choice).
func get_starter_screen() -> StarterScreen:
	return _starter_screen


## What the last won fight paid and gave, already applied to the run: {"money": int, "item": ItemData|null,
## "potion": PotionData|null}; {} before any win / for debug fights without a room type. For the reward screen.
func get_last_loot() -> Dictionary:
	return _last_loot


## A fresh Poké Mart stock for the current run (seeded shop RNG: deterministic with --seed). Call once per visit.
func create_shop_inventory() -> ShopInventory:
	return ShopInventory.generate(_data, _run, _shop_rng)


## QA: the run state (HP, deck, act progress).
func get_run_state() -> RunState:
	return _run


## QA: "starter", "map", "battle", "reward", "event", "center", "mart", "room", "act_end" (or "none").
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


## QA: presses the button of the placeholder room or act-end screen; on the Centre it is "Continuer" (only
## after a service), on the Mart "Quitter".
func room_continue() -> void:
	if _room_screen != null:
		_room_screen.press_continue()
	elif _center_screen != null:
		_center_screen.press_continue()
	elif _mart_screen != null:
		_mart_screen.leave()


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
	elif _center_screen != null and _center_screen.get_step() == CenterScreen.Step.CHOOSE:
		_center_screen.setup(_data, _run, _run.rest_heal_preview(), _run.rest_heal_percent())


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
	elif node.room_type == "center":
		_show_center()
	elif node.room_type == "mart":
		_show_mart()
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
	battle.state_changed.connect(_refresh_hud)
	battle.item_triggered.connect(_on_item_triggered)
	_battle_screen = BATTLE_SCENE.instantiate() as BattleScreen
	_battle_screen.battle_won.connect(_on_battle_won)
	_battle_screen.restart_requested.connect(_on_restart_requested)
	_set_screen(_battle_screen, SCREEN_BATTLE)
	_battle_screen.setup(battle, _data, _run, encounter_id)
	_refresh_hud()


func _on_battle_won(defeated_ids: Array[String]) -> void:
	_run.record_battle_result(_battle_screen.get_battle().player)
	_last_loot = _run.apply_loot(LootGenerator.generate(_data, _run, _fight_room_type, _loot_rng))
	var weights: Dictionary = _data.get_room_rarity_weights(_fight_room_type) if not _fight_room_type.is_empty() else {}
	var offers: Array[RewardOffer] = RewardGenerator.generate(_data, _run.player_id, defeated_ids, _reward_rng, weights)
	_clear_screens()
	_offers = offers
	_reward_screen = REWARD_SCENE.instantiate() as RewardScreen
	_reward_screen.card_chosen.connect(_on_card_chosen)
	_reward_screen.skipped.connect(_after_reward)
	_set_screen(_reward_screen, SCREEN_REWARD)
	_reward_screen.setup(_data, _run, _offers)
	_reward_screen.set_loot(_last_loot if not _fight_room_type.is_empty() else {})


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
	var show_hud: bool = _run != null and screen_name != SCREEN_STARTER
	_hud.visible = show_hud
	screen.offset_top = RunHud.HEIGHT if show_hud else 0.0
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
	_shop = null
	_offers = []
	_current_event = {}
