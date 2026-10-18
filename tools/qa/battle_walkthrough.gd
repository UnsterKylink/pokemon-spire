extends SceneTree
## QA harness: drives BattleScreen through a scripted fight and saves screenshots.
## Run (needs a display, not --headless):
##   godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <out_dir>
## Story: pokemon-spire 001

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


func _shot(name: String) -> void:
	for i: int in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(_out_dir.path_join(name + ".png"))
	print("shot ", name, " | hp=", _screen.battle.player.hp, " enemy=", _screen.battle.enemy.hp,
		" energy=", _screen.battle.energy, " block=", _screen.battle.player.block, " state=", _screen.battle.state)


func _index_of(kind: String) -> int:
	for i: int in _screen.battle.hand.size():
		if _screen.battle.hand[i].kind == kind and _screen.battle.can_play(i):
			return i
	return -1


func _run() -> void:
	await _shot("01-debut-combat")
	var a: int = _index_of(CardData.KIND_ATTACK)
	_screen.select_card(a)
	await _shot("02-carte-selectionnee")
	_screen.click_enemy()
	var s: int = _index_of(CardData.KIND_SKILL)
	if s >= 0:
		_screen.select_card(s)
	await _shot("03-attaque-et-protection")
	_screen.press_end_turn()
	await _shot("04-tour-suivant")
	# Win: keep attacking until the enemy faints.
	var guard: int = 0
	while _screen.battle.state == Battle.State.PLAYER_TURN and guard < 40:
		guard += 1
		var i: int = _index_of(CardData.KIND_ATTACK)
		if i < 0:
			_screen.press_end_turn()
			continue
		_screen.select_card(i)
		_screen.click_enemy()
	await _shot("05-victoire")
	# Lose: restart and only end turns.
	_screen.restart()
	guard = 0
	while _screen.battle.state == Battle.State.PLAYER_TURN and guard < 40:
		guard += 1
		_screen.press_end_turn()
	await _shot("06-defaite")
	_screen.restart()
	await _shot("07-rejouer")
	quit(0)
