extends SceneTree
## QA harness: drives Main through a whole act (story 005) with a fixed map seed and saves screenshots:
## map at start -> floor-1 fight -> reward -> map after the fight -> event (before / after choice) ->
## elite fight + reward -> centre -> boss -> act end. Picks a path through an event and an elite;
## tries the seeds of SEEDS in order until one has such a path (prints which one was used).
## Wins use the real select/click path; HP is topped up through Main.qa_set_hp (QA-only cheat).
## Run (needs a display, not --headless for screenshots):
##   godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <out_dir>
## Story: pokemon-spire 005, 008 (type shots 01-types-doubles / 02-super-efficace-double / 03-immunite),
## 009 (switch shots 01-actif-salameche .. 07-deck, run FIRST, see _switch_shots).

const SEEDS: Array[int] = [12345, 777, 4242, 2026, 31337, 8080, 1111, 9001]
const WANTED_TYPES: Array[String] = ["event", "elite", "center"]
const MAX_PATHS: int = 200000
const MAX_BATTLE_STEPS: int = 600
## Story 009: encounter and cards used for the switch shots (Pikachu's Électrik attacks cannot touch Racaillou).
const SWITCH_ENCOUNTER: String = "solo_pikachu"
const SWITCH_CARD: String = "jet_de_pierres"
const SKILL_CARD: String = "abri"
const MAX_INTENT_TURNS: int = 8
## Seconds to wait so the "<Nom>, à toi !" float has faded (FLOAT_DURATION is 1.2 s).
const FLOAT_WAIT: float = 1.6

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
	var line: String = "shot %s | screen=%s run_hp=%d/%d deck=%d won=%d floor=%d visited=%d reachable=%s" % [
			shot_name, _main.get_current_screen_name(), run.hp, run.max_hp, run.deck.size(), run.battles_won,
			run.act.current_floor(), run.act.visited.size(), _main.map_reachable_ids()]
	var bs: BattleScreen = _main.get_battle_screen()
	if bs != null:
		var b: Battle = bs.get_battle()
		line += " enc=%s enemies=%s active=%s player_hp=%d/%d block=%d intents=%s float=\"%s\"" % [
				bs.get_encounter_id(), _enemy_summary(b), b.active_pokemon_id, b.player.hp, b.player.max_hp,
				b.player.block, _intent_summary(b), bs.get_switch_float_text()]
		var hand: PackedStringArray = PackedStringArray()
		for c: CardData in b.hand:
			hand.append(c.deck_key())
		line += " hand=%s" % [hand]
	for o: RewardOffer in _main.get_reward_offers():
		line += " [%s/%s%s]" % [o.card.id, o.card.rarity, "*" + o.source_pokemon_name if o.stolen else ""]
	var ev: Dictionary = _main.get_current_event()
	if not ev.is_empty():
		line += " event=%s" % ev.get("id", "")
	print(line)


func _intent_summary(b: Battle) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for e: Combatant in b.enemies:
		out.append("%s:%s" % [e.id, e.intent.display_text() if e.intent != null else "-"])
	return out


## Story 009 shots: active Pokémon, switch on an attack card of another Pokémon (intent recomputed:
## Pikachu's Électrik attack vs Racaillou = "Attaque 0"), skill without switch, immune end of turn,
## stolen card carried by Pikachu, deck by Pokémon. Leaves a fresh run on `used_seed`.
func _switch_shots(used_seed: int) -> void:
	_main.start_encounter(SWITCH_ENCOUNTER)
	await _shot("01-actif-salameche")
	var bs: BattleScreen = _main.get_battle_screen()
	var b: Battle = bs.get_battle()
	var pika: Combatant = b.enemies[0]
	# Weighted pattern: pass turns (HP topped up) until Pikachu announces an attack.
	var turns: int = 0
	while (pika.intent == null or pika.intent.type != EnemyIntent.TYPE_ATTACK) and turns < MAX_INTENT_TURNS:
		turns += 1
		_main.qa_set_hp(b.player.max_hp)
		bs.press_end_turn()
	print("switch: Pikachu intent before switch = %s (after %d passed turns), active=%s" % [
			pika.intent.display_text() if pika.intent != null else "-", turns, b.active_pokemon_id])
	bs.qa_force_hand([SWITCH_CARD] as Array[String])
	bs.select_card(0)
	bs.click_enemy(0)  # real UI path: Racaillou comes in before the hit
	print("switch: after %s active=%s intent=%s float=\"%s\"" % [SWITCH_CARD, b.active_pokemon_id,
			pika.intent.display_text() if pika.intent != null else "-", bs.get_switch_float_text()])
	await _shot("02-switch-vers-racaillou")
	await create_timer(FLOAT_WAIT).timeout
	await _shot("03-intention-recalculee")
	var block_before: int = b.player.block
	bs.qa_force_hand([SKILL_CARD] as Array[String])
	bs.select_card(0)  # skills play on click and never switch
	print("skill: %s active=%s block %d -> %d" % [SKILL_CARD, b.active_pokemon_id, block_before, b.player.block])
	await _shot("04-competence-sans-switch")
	var hp_before: int = b.player.hp
	var intent_before: String = pika.intent.display_text() if pika.intent != null else "-"
	bs.press_end_turn()
	print("end turn: Pikachu intent was %s, hp %d -> %d, active=%s" % [intent_before, hp_before, b.player.hp, b.active_pokemon_id])
	await _shot("05-fin-de-tour-immunite")
	var guard: int = 0
	while _main.get_current_screen_name() == "battle" and guard < MAX_BATTLE_STEPS:
		guard += 1
		bs = _main.get_battle_screen()
		b = bs.get_battle()
		_main.qa_set_hp(b.player.max_hp)
		bs.qa_force_hand([SWITCH_CARD, SWITCH_CARD, SWITCH_CARD] as Array[String])
		while _main.get_current_screen_name() == "battle" and b.can_play(0):
			bs.select_card(0)
			bs.click_enemy(b.first_living_enemy())
		if _main.get_current_screen_name() == "battle":
			bs.press_end_turn()
	await _shot("06-recompense-carte-volee")
	for o: RewardOffer in _main.get_reward_offers():
		print("offer: %s pokemon=%s stolen=%s from=%s" % [o.card.deck_key(), o.card.pokemon_id, o.stolen, o.source_pokemon_name])
	_main.reward_open_deck()
	await _shot("07-deck")
	var rs: RewardScreen = _main.get_reward_screen()
	if rs != null:
		for l: String in rs.get_deck_lines():
			print("deck: ", l)
	_main.reward_close_deck()
	_main.start_new_run(used_seed)


func _enemy_summary(b: Battle) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for e: Combatant in b.enemies:
		out.append("%s %d/%d str%d" % [e.id, e.hp, e.max_hp, e.strength])
	return out


## Best start->boss path: one containing as many WANTED_TYPES as possible (bounded DFS).
func _plan(g: MapGraph) -> Array[String]:
	var best: Array[String] = []
	var best_score: int = -1
	var stack: Array = []
	for s: String in g.start_node_ids():
		stack.append([s])
	var guard: int = 0
	while not stack.is_empty() and guard < MAX_PATHS:
		guard += 1
		var path: Array = stack.pop_back()
		var n: MapNode = g.get_node(path[-1])
		if n.next.is_empty():
			var score: int = 0
			for t: String in WANTED_TYPES:
				for id: String in path:
					if g.get_node(id).room_type == t:
						score += 1
						break
			if score > best_score:
				best_score = score
				best.assign(path)
			continue
		for nx: String in n.next:
			var p2: Array = path.duplicate()
			p2.append(nx)
			stack.append(p2)
	return best


func _path_score(g: MapGraph, path: Array[String]) -> int:
	var score: int = 0
	for t: String in WANTED_TYPES:
		for id: String in path:
			if g.get_node(id).room_type == t:
				score += 1
				break
	return score


## Plays attacks (select + click, the real UI path) until the fight ends; HP topped up each loop (bounded).
func _win_battle() -> void:
	var guard: int = 0
	while _main.get_current_screen_name() == "battle" and guard < MAX_BATTLE_STEPS:
		guard += 1
		var bs: BattleScreen = _main.get_battle_screen()
		var b: Battle = bs.get_battle()
		_main.qa_set_hp(b.player.max_hp)
		var played: bool = false
		for i: int in b.hand.size():
			if b.hand[i].kind == CardData.KIND_ATTACK and b.can_play(i):
				bs.select_card(i)
				bs.click_enemy(b.first_living_enemy())
				played = true
				break
		if not played:
			bs.press_end_turn()
	print("battle finished after %d steps -> %s" % [guard, _main.get_current_screen_name()])


## Story 008 shots: dual-type badges, a x2.25 hit, an immunity. 04-intention-attaque-0 is skipped:
## no attack in the roster is fully immune vs Salamèche (Feu); the unit test covers "Attaque 0".
func _type_shots(used_seed: int) -> void:
	_main.start_encounter("trio_vol")
	await _shot("01-types-doubles")
	_main.start_encounter("solo_racaillou")
	var bs: BattleScreen = _main.get_battle_screen()
	var foe: Combatant = bs.get_battle().enemies[0]
	var hp_before: int = foe.hp
	bs.qa_force_hand(["pistolet_a_o"] as Array[String])  # Eau vs Roche/Sol = x1.5 x1.5
	bs.play_card_direct(0, 0)
	print("pistolet_a_o vs %s %s: hp %d -> %d" % [foe.id, foe.type_ids, hp_before, foe.hp])
	await _shot("02-super-efficace-double")
	hp_before = foe.hp
	bs.qa_force_hand(["eclair"] as Array[String])  # Électrik vs Sol = immune
	bs.play_card_direct(0, 0)
	print("eclair vs %s %s: hp %d -> %d" % [foe.id, foe.type_ids, hp_before, foe.hp])
	await _shot("03-immunite")
	_main.start_new_run(used_seed)


func _run() -> void:
	# Pick the first seed whose map has a path through event + elite + centre.
	var used_seed: int = SEEDS[0]
	var path: Array[String] = []
	var best_score: int = -1
	for s: int in SEEDS:
		_main.start_new_run(s)
		var g: MapGraph = _main.get_run_state().act.graph
		var candidate: Array[String] = _plan(g)
		var score: int = _path_score(g, candidate)
		if score > best_score:
			best_score = score
			used_seed = s
			path = candidate
		if score == WANTED_TYPES.size():
			break
	_main.start_new_run(used_seed)
	var graph: MapGraph = _main.get_run_state().act.graph
	var types: PackedStringArray = PackedStringArray()
	for id: String in path:
		types.append(graph.get_node(id).room_type)
	print("walkthrough seed = %d, path = %s" % [used_seed, types])
	await _switch_shots(used_seed)
	await _type_shots(used_seed)
	await _shot("01-carte-debut")
	var shot_done: Dictionary = {}
	for step: int in path.size():
		var id: String = path[step]
		var rt: String = graph.get_node(id).room_type
		if rt == "center":
			_main.qa_set_hp(_main.get_run_state().max_hp / 2)  # so the centre's heal is visible
		if not _main.map_choose(id):
			print("ERROR: could not enter ", id)
			quit(1)
			return
		match rt:
			"wild", "elite", "boss":
				if step == 0:
					await _shot("02-combat-etage-1")
				elif rt == "elite" and not shot_done.has("elite"):
					await _shot("06-combat-elite")
				elif rt == "boss":
					await _shot("09-boss")
				_win_battle()
				if rt == "elite" and not shot_done.has("elite"):
					shot_done["elite"] = true
					await _shot("07-recompense-elite")
				_main.reward_pick(0)
				if step == 0:
					await _shot("03-carte-apres-combat")
			"event":
				if not shot_done.has("event"):
					_main.qa_set_hp(_main.get_run_state().max_hp / 2)
					await _shot("04-evenement")
				_main.event_choose(0)
				if not shot_done.has("event"):
					shot_done["event"] = true
					await _shot("05-evenement-resultat")
				_main.event_continue()
			_:
				if rt == "center" and not shot_done.has("center"):
					shot_done["center"] = true
					await _shot("08-centre")
				_main.room_continue()
	await _shot("10-acte-termine")
	print("missing room types on the path: ", WANTED_TYPES.filter(func(t: String) -> bool: return not shot_done.has(t)))
	quit(0)
