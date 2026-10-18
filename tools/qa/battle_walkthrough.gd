extends SceneTree
## QA harness: drives Main through the story-004 flow (battle -> reward screen -> deck overlay -> pick ->
## next battle with persisted HP/deck -> pass path -> defeat -> Rejouer = fresh run) and saves screenshots.
## Run (needs a display, not --headless for screenshots):
##   godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <out_dir>
## Story: pokemon-spire 001-004

var _main: Main
var _out_dir: String = "user://qa"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_main = (load("res://src/main.tscn") as PackedScene).instantiate() as Main
	root.add_child(_main)
	_run.call_deferred()


func _shot(shot_name: String) -> void:
	for i: int in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(_out_dir.path_join(shot_name + ".png"))
	var run: RunState = _main.get_run_state()
	var line: String = "shot %s | screen=%s run_hp=%d/%d deck=%d won=%d" % [shot_name,
			_main.get_current_screen_name(), run.hp, run.max_hp, run.deck.size(), run.battles_won]
	var bs: BattleScreen = _main.get_battle_screen()
	if bs != null:
		var b: Battle = bs.get_battle()
		line += " enc=%s hp=%d energy=%d state=%d hand=%s" % [bs.get_encounter_id(), b.player.hp, b.energy, b.state, _hand_ids(b)]
	for o: RewardOffer in _main.get_reward_offers():
		line += " [%s%s]" % [o.card.id, "*" + o.source_pokemon_name if o.stolen else ""]
	print(line)


func _hand_ids(b: Battle) -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for c: CardData in b.hand:
		ids.append(c.id)
	return ids


## Plays attacks (select + click, the real UI path) until every enemy is dead or the guard runs out.
func _win_battle() -> void:
	var bs: BattleScreen = _main.get_battle_screen()
	var b: Battle = bs.get_battle()
	var guard: int = 0
	while bs != null and b.state == Battle.State.PLAYER_TURN and guard < 120:
		guard += 1
		var played: bool = false
		for i: int in b.hand.size():
			if b.hand[i].kind == CardData.KIND_ATTACK and b.can_play(i):
				bs.select_card(i)
				bs.click_enemy(b.first_living_enemy())
				played = true
				break
		if not played:
			bs.press_end_turn()


## Ends turns without playing until the player is dead (bounded).
func _lose_battle() -> void:
	var bs: BattleScreen = _main.get_battle_screen()
	var b: Battle = bs.get_battle()
	var guard: int = 0
	while b.state == Battle.State.PLAYER_TURN and guard < 200:
		guard += 1
		bs.press_end_turn()


func _run() -> void:
	# 1. Solo fight: take some damage first, then win -> reward screen.
	_main.start_encounter("solo")
	var bs: BattleScreen = _main.get_battle_screen()
	bs.press_end_turn()
	bs.press_end_turn()
	_win_battle()
	await _shot("01-reward-screen")
	# 2. Deck overlay.
	_main.reward_open_deck()
	await _shot("02-deck-overlay")
	print("deck lines = ", _main.get_reward_screen().get_deck_lines())
	_main.reward_close_deck()
	# 3. Pick the stolen card (or card 0) -> next battle, HP and deck persisted.
	var pick_index: int = 0
	var offers: Array[RewardOffer] = _main.get_reward_offers()
	for i: int in offers.size():
		if offers[i].stolen:
			pick_index = i
	var picked_id: String = offers[pick_index].card.id
	_main.reward_pick(pick_index)
	await _shot("03-next-battle")
	# 3b. A few turns later the new card shows up in hand (bounded: 11 cards cycle within 3 turns).
	bs = _main.get_battle_screen()
	var b: Battle = bs.get_battle()
	var turns: int = 0
	while turns < 4 and b.state == Battle.State.PLAYER_TURN:
		var in_hand: bool = false
		for c: CardData in b.hand:
			if c.id == picked_id:
				in_hand = true
		if in_hand:
			break
		turns += 1
		bs.press_end_turn()
	print("picked '", picked_id, "' seen in hand after ", turns, " end-turns")
	await _shot("03b-nouvelle-carte-en-main")
	# 4. Another win, then "Passer": the deck stays at 11.
	_win_battle()
	await _shot("04-passer-avant")
	_main.reward_skip()
	await _shot("04-passer-apres")
	# 5. Defeat, then Rejouer: fresh run (75/75, 10 cards).
	_lose_battle()
	await _shot("05a-defaite")
	_main.get_battle_screen().press_restart()
	await _shot("05-defaite-nouvelle-partie")
	quit(0)
