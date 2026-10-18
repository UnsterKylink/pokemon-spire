extends SceneTree
## QA harness: drives BattleScreen through the type scenarios (trio_mix, fire vs grass/rock, water vs fire player,
## victory) and saves screenshots.
## Run (needs a display, not --headless):
##   godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <out_dir>
## Story: pokemon-spire 001, 002, 003

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
		" block=", b.player.block, " state=", b.state,
		" float_player='", _screen.get_player_float_text(), "'")


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


## Index of the first playable hand card with this id, or -1.
func _index_of_id(card_id: String) -> int:
	var b: Battle = _screen.get_battle()
	for i: int in b.hand.size():
		if b.hand[i].id == card_id and b.can_play(i):
			return i
	return -1


## Restarts the encounter (fresh shuffle) until the card is playable in hand. Bounded.
func _start_with_card(encounter_id: String, card_id: String) -> bool:
	for attempt: int in 60:
		_screen.start_encounter(encounter_id)
		if _index_of_id(card_id) >= 0:
			# Let the freshly built enemy slots get laid out so the floating label is positioned right.
			await process_frame
			await process_frame
			return true
	push_error("walkthrough: card '%s' never drawn on '%s'" % [card_id, encounter_id])
	return false


## Selects the card then clicks the enemy (the real UI path).
func _play_on(card_id: String, enemy_index: int) -> void:
	_screen.select_card(_index_of_id(card_id))
	_screen.click_enemy(enemy_index)


func _run() -> void:
	# 1. trio_mix: types visible on the cards and on the 3 enemies + the player.
	_screen.start_encounter("trio_mix")
	await _shot("01-trio-mix-debut-types")
	# 2. Fire attack on the grass enemy (Mystherbe, slot 0): "Super efficace !".
	if await _start_with_card("trio_mix", "flammeche"):
		_play_on("flammeche", 0)
		print("float text enemy0 = '", _screen.get_enemy_float_text(0), "'")
		await _shot("02-feu-sur-plante-super-efficace")
	# 3. Fire attack on the rock enemy (Racaillou, slot 2): "Ce n'est pas très efficace…".
	if await _start_with_card("trio_mix", "flammeche"):
		_play_on("flammeche", 2)
		print("float text enemy2 = '", _screen.get_enemy_float_text(2), "'")
		await _shot("03-feu-sur-roche-pas-tres-efficace")
	# 4. Enemy super-effective hit: Ptitard (water) attacks the fire player.
	_screen.start_encounter("solo_ptitard")
	var guard: int = 0
	while guard < 40 and _screen.get_battle().state == Battle.State.PLAYER_TURN:
		guard += 1
		var intent: EnemyIntent = _screen.get_battle().enemies[0].intent
		if intent != null and intent.type == EnemyIntent.TYPE_ATTACK:
			await _shot("04a-ptitard-intention-attaque-9")
			_screen.press_end_turn()
			break
		_screen.press_end_turn()
	print("float text player = '", _screen.get_player_float_text(), "'")
	await _shot("04b-ptitard-touche-le-joueur-super-efficace")
	# 5. Victory.
	_screen.start_encounter("solo_racaillou")
	_win_battle()
	await _shot("05-victoire")
	quit(0)
