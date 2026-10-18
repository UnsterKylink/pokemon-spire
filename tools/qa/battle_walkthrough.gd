extends SceneTree
## QA harness: drives BattleScreen through the 3 encounters (solo, duo, trio) and saves screenshots.
## Run (needs a display, not --headless):
##   godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <out_dir>
## Story: pokemon-spire 001, 002

var _screen: BattleScreen
var _out_dir: String = "user://qa"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_screen = (load("res://src/ui/battle_screen.tscn") as PackedScene).instantiate() as BattleScreen
	root.add_child(_screen)
	_run.call_deferred()


func _shot(shot_name: String) -> void:
	for i: int in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(_out_dir.path_join(shot_name + ".png"))
	var b: Battle = _screen.get_battle()
	var hps: PackedStringArray = PackedStringArray()
	var intents: PackedStringArray = PackedStringArray()
	for e: Combatant in b.enemies:
		hps.append(str(e.hp))
		intents.append(e.intent.display_text() if e.intent != null else "-")
	print("shot ", shot_name, " | enc=", _screen.get_encounter_id(), " hp=", b.player.hp,
		" enemies=", hps, " intents=", intents, " energy=", b.energy,
		" block=", b.player.block, " state=", b.state)


func _index_of(kind: String) -> int:
	var b: Battle = _screen.get_battle()
	for i: int in b.hand.size():
		if b.hand[i].kind == kind and b.can_play(i):
			return i
	return -1


## Attacks the given enemy (selection + click) until it faints or the turn runs out of attacks.
func _kill_enemy(enemy_index: int) -> void:
	var b: Battle = _screen.get_battle()
	var guard: int = 0
	while b.state == Battle.State.PLAYER_TURN and b.enemies[enemy_index].is_alive() and guard < 60:
		guard += 1
		var i: int = _index_of(CardData.KIND_ATTACK)
		if i < 0:
			_screen.press_end_turn()
			continue
		_screen.select_card(i)
		_screen.click_enemy(enemy_index)


## Kills every enemy, left to right.
func _win_battle() -> void:
	var b: Battle = _screen.get_battle()
	for k: int in b.enemies.size():
		_kill_enemy(k)


func _run() -> void:
	var order: Array[String] = ["solo", "duo", "trio"]
	# Solo: intents visible, then a win.
	_screen.start_encounter(order[0])
	await _shot("01-solo-debut")
	_win_battle()
	await _shot("02-solo-victoire")
	# Duo.
	_screen.start_encounter(order[1])
	await _shot("03-duo-debut")
	_win_battle()
	await _shot("04-duo-victoire")
	# Trio: selection, one KO, then a win.
	_screen.start_encounter(order[2])
	await _shot("05-trio-debut")
	var a: int = _index_of(CardData.KIND_ATTACK)
	_screen.select_card(a)
	await _shot("06-trio-carte-selectionnee")
	_screen.click_background()
	_kill_enemy(1)
	await _shot("07-trio-un-ko")
	_win_battle()
	await _shot("08-trio-victoire")
	# Rejouer after a victory goes to the next encounter (wraps to solo).
	_screen.restart()
	await _shot("09-rejouer-apres-victoire")
	# Defeat: only end turns, then Rejouer repeats the same encounter.
	var guard: int = 0
	while _screen.get_battle().state == Battle.State.PLAYER_TURN and guard < 60:
		guard += 1
		_screen.press_end_turn()
	await _shot("10-defaite")
	_screen.restart()
	await _shot("11-rejouer-apres-defaite")
	quit(0)
