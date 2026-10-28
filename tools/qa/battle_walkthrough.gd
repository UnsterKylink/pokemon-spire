extends SceneTree
## QA harness: drives Main through a whole act (story 005) with a fixed map seed and saves screenshots:
## map at start -> floor-1 fight -> reward -> map after the fight -> event (before / after choice) ->
## elite fight + reward -> centre -> boss -> act end. Picks a path through an event and an elite;
## tries the seeds of SEEDS in order until one has such a path (prints which one was used).
## Wins use the real select/click path; HP is topped up through Main.qa_set_hp (QA-only cheat).
## Run (needs a display, not --headless for screenshots):
##   godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <out_dir>
## Story: pokemon-spire 005, 008 (type shots 01-types-doubles / 02-super-efficace-double / 03-immunite),
## 009 (switch shots 01-actif-salameche .. 07-deck, run FIRST, see _switch_shots),
## 006 (items / services shots 01-hud-carte .. 07b-mart-apres-retrait, see _items_shots),
## 007 (Champion / evolution / victory / defeat / new run shots, see _champion_shots).
## 011 (deck access shots: deck panel on map / battle tabs / 45 cards / Mart, see _deck_shots; filter `story-011`).
## 012 (8 zones / gyms / badges shots: zone maps + HUD badges, gyms of zones 1 and 8, badge screen, victory with 8
## badges, defeat summary; see _zones_shots; filter `story-012`).
## 013 (league shots: Route Victoire list, Conseil 4 fight with trainer header + HUD progress, intermission heal, Maître,
## Éthernatos intro / fight, final victory, league defeat; see _league_shots; filter `story-013`).
## 013b (roster diversity shots: roster starter in the choice, roster wild fights in zones 1 and 6, reward carriers, a
## newly possible gym type, a roster starter's deck; see _diversity_shots; filter `story-013b`).
## Story 014 (in-run evolutions: starter stage 1->2 at badge 1 with its card choice, 2->3 at badge 4, a Pokémon
## without a next form, the team evolution summary, the deck afterwards; see _evolution_shots; filter `story-014`).
## Story 015 (save / resume: resume screen of a zone-3 run, map after the resume, unreadable save, starter without a save,
## starter after a defeat deleted the save; see _save_shots; filter `story-015`). Story 016 (status chips, feedback,
## immunity, team status / lost turn, cure potion, "Dort"/"Gelé" intents, status cards; see _status_shots; filter `story-016`).
## Story 019 (dual-type intent "(Type)", zone-1 gym after balancing; see _balance_shots; filter `story-019`). Uses a scratch save file (SAVE_QA_PATH,
## Story 017 (capture: HUD balls, capture mode with chances, success / failure feedback, reward with the capture, Mart
## balls, team tab with a captured Pokémon, trainer fight without capture; see _capture_shots; filter `story-017`).
## Story 018 (rival room on the zone-2 map, rival intro / fight / reward, event with a greyed option, card removal picker,
## legendary event / solo fight / legendary card, pre-league rival; see _rival_shots; filter `story-018`).
## deleted at the end) through Main.qa_set_save_path: the real user://savegame.json is never touched.
## Optional 2nd user arg = story filter: `-- <out_dir> story-007` runs ONLY that story's shots (no stray shots).

const ORIGINAL_ENEMIES: Array[String] = ["rattata", "pidgey", "caterpie", "weedle", "zubat", "geodude", "poliwag", "oddish", "pikachu"]
const ROSTER_SEED: int = 12345
const ROSTER_TRIO_PREFIX: String = "trio_r"
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
## Story 021: seconds to wait after starting an animation before the shot (the shot adds ~10 frames).
const FX_SHOT_DELAY: float = 0.05
## Story 006: run seed, items / potions / money given through the QA cheats, encounter of the potion shot.
const ITEMS_SEED: int = 2026
const ITEMS_GIVEN: Array[String] = ["peau_metal", "bandeau", "restes"]
const POTIONS_GIVEN: Array[String] = ["potion", "attaque_plus", "defense_plus"]
const ITEMS_ENCOUNTER: String = "solo_bidoof"
const ITEMS_ATTACK: String = "flammeche"
const MART_MONEY: int = 260

## Story 007: run seed and the money / item / potion given so the summary shows them.
const CHAMPION_SEED: int = 4242
const CHAMPION_ITEM: String = "restes"
const CHAMPION_MONEY: int = 187
const CHAMPION_WARMUP: Array[String] = ["solo_bidoof", "trio_vol"]  # defeat part: one win, then the lost fight
const CHAMPION_PICK: int = 1

## Story 011: run seed, fight used for the pile shots and the deck size of the long-deck shot.
const DECK_SEED: int = 2026
const DECK_ENCOUNTER: String = "trio_vol"
const DECK_BIG: int = 45

## Story 012: run seed, the items / potion given so the HUD is crowded, and how far the defeat run goes.
const ZONES_SEED: int = 2026
const ZONES_ITEMS: Array[String] = ["peau_metal", "bandeau", "restes"]
const ZONES_POTIONS: Array[String] = ["potion", "attaque_plus"]
const ZONES_DEFEAT_ZONE: int = 3  # 1-based zone where the defeat run loses

## Story 013: run seed, HP set during a league fight so the heal after it shows, and the stage of the defeat run.
const LEAGUE_SEED: int = 2026
const LEAGUE_HURT_HP: int = 60
const LEAGUE_DEFEAT_STAGE: int = 1  # 0-based: the defeat run loses its 2nd league fight

## Story 015: scratch save slot of the save shots (deleted with its .bak at the end).
const SAVE_QA_PATH: String = "user://qa_story015_savegame.json"
const SAVE_SEED: int = 2026

## Story 016: run seed, the 3-enemy fight of the chip shots, its forced hand, the fight of the intent shot.
const STATUS_SEED: int = 2026
const STATUS_TRIO: String = "trio_r2"  # Lépidonille / Ponchiot / Arcko: no immunity to poison / burn / paralysis
const STATUS_HAND: Array[String] = ["toxik", "feu_follet", "cage_eclair", "hypnose", "dard_venin"]
const STATUS_INTENTS: String = "trio_vol"  # Roucool / Nosferapti / Aspicot (Aspicot opens with "Attaque 4 + Poison 2")
## Strength given to Aspicot in the intent shot so its status attack reads "Attaque 13 + Poison 2" (long intent).
const STATUS_LONG_STRENGTH: int = 22  # (4 + 22) x0.5 (Insecte vs Feu) = 13

## Story 017 shots: run seed and the wild trio staged for the capture shots.
const CAPTURE_SEED: int = 1701
const CAPTURE_TRIO: String = "trio_r2"
## Story 019 shots: run seed (any seed works; fixed for reproducible shots).
const STORY_019_SEED: int = 1907
## Story 018 shots: run seed.
const RIVAL_SEED: int = 1801
## Story 020 shots: run seed, the forced 5-card hand (attack, skill, legendary, long description, status attack)
## and the 10-card hand (narrowest cards).
const STYLE_SEED: int = 2020
const STYLE_HAND: Array[String] = ["flammette", "abri", "voile_temporel", "hypnose", "dard_venin"]
const STYLE_HAND_10: Array[String] = ["flammette", "abri", "feu_sacre", "hypnose", "dard_venin", "griffe", "toxik",
		"aeroblast", "trou_noir", "ecrasement"]
var _main: Main
var _out_dir: String = "user://qa"
var _filter: String = ""


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out_dir = args[0]
	if args.size() > 1:
		_filter = args[1]
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
	var line: String = "shot %s | screen=%s" % [shot_name, _main.get_current_screen_name()]
	if _main.get_current_screen_name() == "starter":
		line += " choices=%s" % [_main.get_starter_choices()]
	elif run != null and run.act != null:
		line += " starter=%s run_hp=%d/%d deck=%d won=%d floor=%d visited=%d reachable=%s" % [
				run.starter_pokemon_id, run.hp, run.max_hp, run.deck.size(), run.battles_won,
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
		# Story 016 fit-in-720p fix: every hand card must be fully inside the window.
		var rects: Array[Rect2] = bs.get_hand_card_rects()
		var bottom: float = 0.0
		for r: Rect2 in rects:
			bottom = maxf(bottom, r.end.y)
		var win_h: float = root.get_visible_rect().size.y
		line += " cards=%d card_h=%d hand_bottom=%d/%d fits=%s" % [rects.size(), int(rects[0].size.y) if not rects.is_empty() else 0,
				int(bottom), int(win_h), bottom <= win_h]
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
func _win_battle(quick: bool = false) -> void:
	var guard: int = 0
	while _main.get_current_screen_name() == "battle" and guard < MAX_BATTLE_STEPS:
		guard += 1
		var bs: BattleScreen = _main.get_battle_screen()
		var b: Battle = bs.get_battle()
		_main.qa_set_hp(b.player.max_hp)
		if quick:
			_main.qa_set_enemy_hp(1)
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


## Story 010 shots (run FIRST, seed ROSTER_SEED, no forced starter): starter choice, chosen starter in its first
## fight, type-coherent reward carriers, varied roster enemies, starter deck overlay.
func _roster_shots() -> void:
	_main.forced_starter_id = ""
	_main.start_new_run(ROSTER_SEED)
	var choices: Array[String] = _main.get_starter_choices()
	var data := GameData.new()
	data.load_all()
	var prim: PackedStringArray = PackedStringArray()
	for c: String in choices:
		prim.append("%s:%s" % [c, data.get_primary_type(c)])
	print("roster: choices = %s" % [prim])
	await _shot("01-choix-depart")
	_main.starter_choose(1)
	var node_id: String = _main.map_reachable_ids()[0]
	_main.map_choose(node_id)
	await _shot("02-depart-choisi")
	_win_battle()
	await _shot("03-carte-aleatoire-type-coherent")
	for o: RewardOffer in _main.get_reward_offers():
		print("roster offer: %s type=%s carrier=%s carrier_types=%s stolen=%s" % [o.card.id, o.card.type_id,
				o.card.pokemon_id, data.get_pokemon_info(o.card.pokemon_id).get("types", []), o.stolen])
	_main.reward_pick(0)
	var trio: String = ""
	for id: String in data.get_encounter_order():
		if not id.begins_with(ROSTER_TRIO_PREFIX):
			continue
		var fresh: bool = true
		for e: Combatant in data.create_enemies(id):
			if ORIGINAL_ENEMIES.has(e.id):
				fresh = false
		if fresh:
			trio = id
			break
	_main.start_encounter(trio)
	await _shot("04-ennemis-varies")
	_main.start_new_run(ROSTER_SEED)
	_main.starter_choose(1)
	_main.map_open_deck()
	await _shot("05-deck-du-depart")
	_main.map_close_deck()


## Story 006 shots: permanent HUD on the map, potions + item feedback in battle, reward loot (an elite-loot
## debug fight), Centre (choice, upgrade picker, before/after preview, result) and Mart (stock, purchases,
## removal picker, after removal). Leaves the run to the caller (it starts a new one).
func _items_shots() -> void:
	_main.start_new_run(ITEMS_SEED)
	for id: String in ITEMS_GIVEN:
		_main.qa_give_item(id)
	for id: String in POTIONS_GIVEN:
		_main.qa_give_potion(id)
	await _shot("01-hud-carte")
	print("hud: money=%s items=%s potions=%s" % [_main.get_hud().get_money_text(), _main.get_hud().get_item_names(),
			_main.get_hud().get_potion_texts()])
	_main.start_encounter(ITEMS_ENCOUNTER, "elite")
	var bs: BattleScreen = _main.get_battle_screen()
	var b: Battle = bs.get_battle()
	print("battle start: block=%d (Peau Métal) float=\"%s\"" % [b.player.block, bs.get_item_float_text()])
	await create_timer(FLOAT_WAIT).timeout
	bs.qa_force_hand([ITEMS_ATTACK, ITEMS_ATTACK, "abri"] as Array[String])
	var drunk: bool = _main.battle_use_potion(1)  # Attaque +
	var foe: Combatant = b.enemies[0]
	var hp_before: int = foe.hp
	bs.select_card(0)
	bs.click_enemy(0)  # Bandeau (first attack) + Attaque + bonus
	print("potion drunk=%s bonus=%d foe hp %d -> %d item_float=\"%s\" potion_float=\"%s\" hud_potions=%s run_potions=%d" % [
			drunk, b.turn_damage_bonus, hp_before, foe.hp, bs.get_item_float_text(), bs.get_potion_float_text(),
			_main.get_hud().get_potion_texts(), _main.get_run_state().potions.size()])
	await _shot("02-combat-potions")
	_win_battle()
	var rs: RewardScreen = _main.get_reward_screen()
	print("loot: %s texts=%s money=%d" % [_main.get_last_loot(), rs.get_loot_texts() if rs != null else [], _main.get_run_state().money])
	await _shot("03-recompense-butin")
	_main.reward_skip()
	var run: RunState = _main.get_run_state()
	_main.qa_open_room("center")
	_main.qa_set_hp(run.max_hp / 2)
	print("centre options: %s" % [_main.get_center_screen().get_option_texts()])
	await _shot("04-centre")
	_main.center_open_upgrade()
	print("centre picker offers: %s" % [_main.get_center_screen().get_picker().get_offered_indices()])
	await _shot("05a-centre-choix-carte")
	var up_index: int = -1
	for i: int in run.deck.size():
		if run.deck[i].kind == CardData.KIND_ATTACK and run.can_upgrade_card(i):
			up_index = i
			break
	_main.center_pick(up_index)
	await _shot("05b-centre-amelioration")
	var hp_c: int = run.hp
	_main.center_confirm()
	print("centre upgrade: %s | hp %d -> %d (no heal) | result=\"%s\"" % [run.deck[up_index].deck_key(), hp_c, run.hp,
			_main.get_center_screen().get_result_text()])
	await _shot("05c-centre-resultat")
	_main.center_continue()
	_main.qa_set_money(MART_MONEY)
	_main.qa_open_room("mart")
	var shop: ShopInventory = _main.get_shop_inventory()
	await _shot("06-mart")
	_main.shop_buy_card(0)
	_main.shop_buy_potion(0)
	_main.shop_buy_potion(1)  # belt full after the first one -> refused
	print("mart after buys: money=%d deck=%d potions=%d card0 sold=%s potion0 sold=%s potion1 sold=%s status=\"%s\"" % [
			run.money, run.deck.size(), run.potions.size(), shop.cards[0].sold, shop.potions[0].sold, shop.potions[1].sold,
			_main.get_shop_screen().get_status_text()])
	await _shot("06b-mart-achats")
	_main.shop_open_remove()
	await _shot("07-mart-retrait")
	var deck_before: int = run.deck.size()
	var money_before: int = run.money
	var remove_index: int = _main.get_shop_screen().get_picker().get_offered_indices()[0]
	for i: int in _main.get_shop_screen().get_picker().get_offered_indices():
		if run.deck[i].id == SKILL_CARD:
			remove_index = i  # remove an Abri, not the card just upgraded at the Centre
	_main.shop_remove(remove_index)
	print("mart removal: deck %d -> %d money %d -> %d next price=%d" % [deck_before, run.deck.size(), money_before,
			run.money, shop.removal_price()])
	await _shot("07b-mart-apres-retrait")
	_main.shop_leave()
	print("after mart: screen=%s" % _main.get_current_screen_name())


## Story 007 shots: Champion fight reached through the real map (3 Pokémon, boss modifiers), evolution before -> after, the card
## choice, the victory summary, then a lost battle -> defeat summary, then "Nouvelle partie" (starter screen,
## then the new run's map with a reset HUD). Wins use the real click path with Main.qa_set_enemy_hp (QA cheat).
func _champion_shots() -> void:
	_main.forced_starter_id = ""
	_main.start_new_run(CHAMPION_SEED, "salameche")
	_main.qa_set_money(CHAMPION_MONEY)
	_main.qa_give_item(CHAMPION_ITEM)
	# Walk the real act map up to the Champion (quick wins), so floors / enemies / battles are real numbers.
	var graph: MapGraph = _main.get_run_state().act.graph
	for id: String in _plan(graph):
		var rt: String = graph.get_node(id).room_type
		if not _main.map_choose(id):
			print("ERROR: could not enter ", id)
			quit(1)
			return
		match rt:
			"boss":
				await create_timer(FLOAT_WAIT).timeout
				await _shot("01-champion")
			"wild", "elite":
				_win_battle(true)
				_main.reward_pick(0)
			"event":
				_main.event_choose(0)
				_main.event_continue()
			"center":
				_main.center_heal()
				_main.room_continue()
			_:
				_main.room_continue()
	if _main.get_current_screen_name() != "battle":
		print("ERROR: not on the Champion fight: ", _main.get_current_screen_name())
	_win_battle(true)
	_main.reward_skip()  # story 012: the gym pays loot + a card reward, then the badge, then the evolution (badge 1)
	await _shot("01b-badge")
	_main.badge_continue()
	print("evolution summary: ", _main.get_evolution_summary())
	await _shot("02-evolution")
	_main.evolution_continue()
	await _shot("03-evolution-cartes")
	_main.evolution_pick(CHAMPION_PICK)
	print("evolution result: ", _main.get_evolution_screen().get_result_text())
	_main.evolution_continue()
	# story 012: the evolution leads to zone 2; jump to the last zone and win its gym for the (temporary) victory.
	_main.qa_set_zone(7)
	_main.qa_win_gym()
	_main.reward_skip()
	_main.badge_continue()
	_win_league()  # story 013: badge 8 -> Conseil 4 -> Maître -> Éthernatos -> victory
	await _shot("04-victoire")
	print("victory stats: ", _main.get_victory_screen().get_stats())
	_main.victory_new_run()
	_main.starter_choose(0)
	_main.qa_set_money(CHAMPION_MONEY)
	# Defeat on the map: win the floor-1 fight, then lose the first fight reachable on floor 2 (debug fight if none).
	_main.map_choose(_main.map_reachable_ids()[0])
	_win_battle(true)
	_main.reward_skip()
	var g2: MapGraph = _main.get_run_state().act.graph
	var fight_id: String = ""
	for id: String in _main.map_reachable_ids():
		if g2.get_node(id).room_type == "wild":
			fight_id = id
			break
	if fight_id.is_empty():
		_main.start_encounter(CHAMPION_WARMUP[1])
	else:
		_main.map_choose(fight_id)
	print("lost: ", _main.qa_lose_battle())
	await _shot("05a-defaite-combat")
	_main.battle_defeat_continue()
	await _shot("05-defaite")
	print("defeat stats: ", _main.get_defeat_screen().get_stats())
	_main.defeat_new_run()
	await _shot("06-nouvelle-partie")
	_main.starter_choose(0)
	var r: RunState = _main.get_run_state()
	print("new run: money=%d items=%d potions=%d deck=%d hp=%d/%d evolved=%s hud=%s %s" % [r.money, r.items.size(),
			r.potions.size(), r.deck.size(), r.hp, r.max_hp, r.evolution_applied, _main.get_hud().get_money_text(),
			_main.get_hud().get_item_names()])
	await _shot("06b-nouvelle-partie-carte")


## Battle state that opening / closing the deck panel must not change.
func _battle_fingerprint(b: Battle) -> String:
	var keys: PackedStringArray = PackedStringArray()
	for pile: Array in [b.draw_pile, b.hand, b.discard_pile]:
		var ks: PackedStringArray = PackedStringArray()
		for c: CardData in pile:
			ks.append(c.deck_key())
		keys.append(",".join(ks))
	return "state=%d energy=%d hp=%d block=%d | %s" % [b.state, b.energy, b.player.hp, b.player.block, " | ".join(keys)]


## Story 011 shots: deck panel on the map, in a battle (Deck complet / Pioche / Défausse after two cards),
## with a 45-card deck (scrolling) and at the Mart. Also checks that opening / closing changes nothing.
func _deck_shots() -> void:
	_main.forced_starter_id = "salameche"
	_main.start_new_run(DECK_SEED)
	var run: RunState = _main.get_run_state()
	var deck_before: String = str(run.deck.map(func(c: CardData) -> String: return c.deck_key()))
	_main.map_open_deck()
	var panel: DeckOverlay = _main.get_deck_panel()
	print("map: panel open=%s tabs=%s lines=%s" % [panel.is_open(), panel.has_tabs(), panel.get_lines()])
	await _shot("01-deck-carte")
	_main.close_deck()
	print("map: closed=%s deck unchanged=%s" % [not panel.is_open(), str(run.deck.map(func(c: CardData) -> String: return c.deck_key())) == deck_before])
	# Battle: panel on the 3 tabs, state compared before / after.
	_main.start_encounter(DECK_ENCOUNTER)
	var bs: BattleScreen = _main.get_battle_screen()
	var b: Battle = bs.get_battle()
	var fp_before: String = _battle_fingerprint(b)
	_main.open_deck("deck")
	print("battle deck tab: titles=%s tabs=%s" % [panel.get_tab_titles(), panel.has_tabs()])
	await _shot("02-deck-combat")
	_main.open_deck("draw")
	print("battle draw tab: lines=%s" % [panel.get_lines()])
	await _shot("03-pioche-combat")
	_main.close_deck()
	print("battle: state unchanged after open/close = %s" % (_battle_fingerprint(b) == fp_before))
	var played: int = 0
	for i: int in b.hand.size():
		if played >= 2:
			break
		var idx: int = 0
		while idx < b.hand.size() and not (b.hand[idx].kind == CardData.KIND_ATTACK and b.can_play(idx)):
			idx += 1
		if idx < b.hand.size():
			bs.select_card(idx)
			bs.click_enemy(b.first_living_enemy())
			played += 1
	print("battle: played %d cards, discard=%d draw=%d hand=%d" % [played, b.discard_pile.size(), b.draw_pile.size(), b.hand.size()])
	fp_before = _battle_fingerprint(b)
	_main.open_deck("discard")
	print("battle discard tab: titles=%s lines=%s" % [panel.get_tab_titles(), panel.get_lines()])
	await _shot("04-defausse-combat")
	_main.close_deck()
	print("battle: state unchanged after open/close = %s" % (_battle_fingerprint(b) == fp_before))
	# Long deck on the map.
	_main.start_new_run(DECK_SEED)
	run = _main.get_run_state()
	_main.qa_give_cards(DECK_BIG - run.deck.size())
	_main.open_deck()
	print("long deck: %d cards, %d groups, scroll max=%s" % [run.deck.size(), panel.get_group_count(), panel.get_scroll().get_v_scroll_bar().max_value])
	await _shot("05-deck-45-cartes")
	panel.get_scroll().scroll_vertical = 100000
	await process_frame
	await _shot("05b-deck-45-cartes-bas")
	_main.close_deck()
	# Mart: panel open, then the removal picker disables the Deck button.
	_main.qa_set_money(MART_MONEY)
	_main.qa_open_room("mart")
	_main.open_deck()
	await _shot("06-deck-mart")
	_main.close_deck()
	_main.shop_open_remove()
	await process_frame
	await process_frame
	var enabled: bool = _main.get_hud().is_deck_enabled()
	var refused: bool = not _main.open_deck()
	print("mart picker open (%s): deck button enabled=%s open_deck refused=%s" % [_main.get_shop_screen().get_picker().is_open(), enabled, refused])
	_main.get_shop_screen().get_picker().cancel()
	await process_frame
	await process_frame
	print("mart picker closed: deck button enabled=%s" % _main.get_hud().is_deck_enabled())


## Story 013: from the league screen, wins every league fight (QA cheat, reward skipped) up to the final victory.
func _win_league() -> void:
	for i: int in 10:
		if _main.get_current_screen_name() != "league":
			return
		print("league fight: ", _main.get_league_member().get("name", ""))
		_main.qa_win_league_fight()
		if _main.get_current_screen_name() == "reward":
			_main.reward_skip()


func _zone_line(tag: String) -> void:
	var run: RunState = _main.get_run_state()
	var z: Dictionary = _main.get_zone()
	var line: String = "%s: zone=%d/%d type=%s leader=%s badges=%d hud_badges=%s" % [tag, _main.get_zone_index() + 1,
			run.zones.size(), z.get("type_id", ""), z.get("leader", ""), run.badges.size(),
			_main.get_hud().get_badge_slots().map(func(d: Dictionary) -> String: return "1" if d["earned"] else "0")]
	if _main.get_map_screen() != null:
		var ms: MapScreen = _main.get_map_screen()
		var gym: Button = ms.get_map_canvas().get_button(run.act.graph.boss_id())
		line += " title=\"%s\" banner=\"%s\" gym_button=\"%s\"" % [ms.get_title_text(), ms.get_banner_text(), gym.text]
	print(line)


func _gym_line(tag: String) -> void:
	var b: Battle = _main.get_battle_screen().get_battle()
	var parts: PackedStringArray = PackedStringArray()
	for e: Combatant in b.enemies:
		parts.append("%s %s hp=%d str=%d" % [e.id, e.type_ids, e.max_hp, e.strength])
	print("%s: enc=%s zone_type=%s enemies=%s" % [tag, _main.get_encounter_id(), _main.get_zone().get("type_id", ""), parts])


## Wins the current zone's gym through the real flow: gym fight -> reward (skipped) -> badge screen (left with
## badge_continue) -> evolution after badge 1 (skipped) -> next map.
func _clear_gym(shoot_badge: bool = false) -> void:
	if _main.get_current_screen_name() != "battle":
		_main.qa_skip_to_gym()  # enters the gym room (counted in the floors), then the cheat win
	_main.qa_win_gym()
	_main.reward_skip()
	_drain_team_evolution()
	if shoot_badge:
		var bs: BadgeScreen = _main.get_badge_screen()
		print("badge screen: title=\"%s\" leader=\"%s\" bonus=\"%s\" unlock=\"%s\" progress=\"%s\" button=%s" % [
				bs.get_title_text(), bs.get_leader_text(), bs.get_bonus_text(), bs.get_unlock_text().replace("\n", " / "),
				bs.get_progress_text(), bs.get_button_text()])
		await _shot("03-badge")
	_main.badge_continue()
	if _main.get_current_screen_name() == "evolution":
		_main.evolution_continue()
		_main.evolution_skip()
		_main.evolution_continue()


func _zones_shots() -> void:
	_main.forced_starter_id = "salameche"
	_main.start_new_run(ZONES_SEED)
	for id: String in ZONES_ITEMS:
		_main.qa_give_item(id)
	for id: String in ZONES_POTIONS:
		_main.qa_give_potion(id)
	_zone_line("zone 1 map")
	await _shot("01-carte-zone-1")
	_main.qa_skip_to_gym()
	await create_timer(FLOAT_WAIT).timeout
	_gym_line("zone 1 gym")
	await _shot("02-champion-zone-1")
	await _clear_gym(true)
	_zone_line("zone 2 map")
	await _shot("04-carte-zone-2")
	for i: int in range(1, 7):  # badges 2..7 through the real gym flow
		await _clear_gym()
	print("before zone 8: badges=%d zone=%d" % [_main.get_badges().size(), _main.get_zone_index() + 1])
	_zone_line("zone 8 map")
	_main.qa_skip_to_gym()
	await create_timer(FLOAT_WAIT).timeout
	_gym_line("zone 8 gym")
	await _shot("05-champion-zone-8")
	await _clear_gym()
	_win_league()  # story 013: the league screen follows badge 8
	var vs: RunEndScreen = _main.get_victory_screen()
	print("victory: title=\"%s\" stats=%s badges=%s" % [vs.get_title_text(), vs.get_stats(),
			vs.get_badge_slots().map(func(d: Dictionary) -> String: return "1" if d["earned"] else "0")])
	await _shot("06-victoire-8-badges")
	# Defeat: a new run, gyms 1..2 won, then a fight of zone 3 lost.
	_main.start_new_run(ZONES_SEED + 1)
	for i: int in ZONES_DEFEAT_ZONE - 1:
		await _clear_gym()
	_main.map_choose(_main.map_reachable_ids()[0])
	if _main.get_current_screen_name() != "battle":
		print("defeat: first room is not a fight (%s), debug fight instead" % _main.get_current_screen_name())
		_main.start_encounter(CHAMPION_WARMUP[1])
	print("lost: ", _main.qa_lose_battle())
	_main.battle_defeat_continue()
	var ds: RunEndScreen = _main.get_defeat_screen()
	print("defeat: stats=%s badges=%s" % [ds.get_stats(), ds.get_badge_slots().map(func(d: Dictionary) -> String: return "1" if d["earned"] else "0")])
	await _shot("07-defaite-zone")


func _league_line(tag: String) -> void:
	var run: RunState = _main.get_run_state()
	var line: String = "%s: screen=%s stage=%d won=%d hp=%d/%d heal=%d hud=\"%s\"" % [tag, _main.get_current_screen_name(),
			_main.get_league_stage(), run.league_fights_won, run.hp, run.max_hp, _main.get_last_league_heal(),
			_main.get_hud().get_league_text()]
	var ls: LeagueScreen = _main.get_league_screen() as LeagueScreen
	if ls != null and _main.get_current_screen_name() == "league":
		line += " title=\"%s\" sub=\"%s\" heal_text=\"%s\" button=\"%s\" boss=%s rows=%s" % [ls.get_title_text(),
				ls.get_subtitle_text(), ls.get_heal_text(), ls.get_button_text(), ls.is_boss_intro(),
				ls.get_rows().map(func(r: Dictionary) -> String: return "%s:%s" % [r["name"], r["status"]])]
	var bs: BattleScreen = _main.get_battle_screen()
	if bs != null and _main.get_current_screen_name() == "battle":
		var parts: PackedStringArray = PackedStringArray()
		for e: Combatant in bs.get_battle().enemies:
			parts.append("%s %s hp=%d str=%d" % [e.id, e.type_ids, e.max_hp, e.strength])
		line += " header=\"%s\" enc=%s enemies=%s" % [bs.get_trainer_header_text(), bs.get_encounter_id(), parts]
	print(line)


## Wins the current league fight from the league screen: fight (HP lowered so the heal shows) -> reward skipped.
func _league_fight() -> void:
	_main.league_continue()
	_main.qa_set_hp(LEAGUE_HURT_HP)
	_main.qa_win_league_fight()
	if _main.get_current_screen_name() == "reward":
		_main.reward_skip()
	_drain_team_evolution()


## Story 014: leaves a team evolution summary if one popped up after a reward.
func _drain_team_evolution() -> void:
	var es: EvolutionScreen = _main.get_evolution_screen()
	if es != null and es.is_team_mode():
		_main.evolution_continue()


## Story 014: the evolution screens. Salamèche run: badge 1 (stage 1->2 + card choice), badges 2..4 through the real gym
## flow (stage 2->3 at badge 4). Pikachu run: Raichu has no next form at badge 4; then 3 team carriers evolve after 4
## won battles; the deck afterwards.
func _evolution_shots() -> void:
	var dir: String = _out_dir
	_main.start_new_run(LEAGUE_SEED, "salameche")
	_main.qa_win_gym()
	_main.reward_skip()
	_drain_team_evolution()
	_main.badge_continue()
	print("014 evo1: ", _main.get_evolution_summary())
	await _shot("01-evolution-1")
	_main.evolution_continue()
	print("014 offers: ", _main.get_evolution_screen().get_offers().map(func(c: CardData) -> String: return c.deck_key()))
	await _shot("02-evolution-cartes")
	_main.evolution_pick(0)
	_main.evolution_continue()
	for i: int in 3:  # badges 2, 3, 4 through the real gym flow
		_main.qa_skip_to_gym()
		_main.qa_win_gym()
		_main.reward_skip()
		_drain_team_evolution()
		_main.badge_continue()
		if _main.get_current_screen_name() == "evolution" and i < 2:
			push_error("unexpected evolution at badge %d" % (i + 2))
	print("014 evo2: ", _main.get_evolution_summary())
	await _shot("03-evolution-2")
	_main.evolution_continue()
	_main.evolution_pick(0)
	_main.evolution_continue()
	_main.start_new_run(LEAGUE_SEED, "pikachu")
	_main.qa_set_evolution_stage(1)
	_main.qa_show_starter_evolution(4)
	print("014 no evo: ", _main.get_evolution_summary(), " bonus=", _main.get_evolution_screen().get_bonus_text())
	await _shot("04-sans-evolution")
	_main.evolution_continue()
	print("014 no evo result: ", _main.get_evolution_screen().get_result_text())
	_main.evolution_continue()
	var run: RunState = _main.get_run_state()
	var base: CardData = run.deck[0]
	for pid: String in ["pidgey", "nidoran-m", "machop"]:
		run.add_card(base.with_pokemon(pid))
		run.add_card(base.with_pokemon(pid))
	_main.qa_win_battles(4)
	_main.qa_check_team_evolution()
	print("014 team rows: ", _main.get_team_evolution_rows().map(func(r: Dictionary) -> String: return "%s->%s" % [r["from_id"], r["to_id"]]))
	await _shot("05-evolutions-equipe")
	_main.evolution_continue()
	_main.map_open_deck()
	print("014 deck: ", run.deck.map(func(c: CardData) -> String: return c.deck_key()))
	await _shot("06-deck-apres")
	_main.map_close_deck()
	_out_dir = dir


func _league_shots() -> void:
	_main.forced_starter_id = "salameche"
	_main.start_new_run(LEAGUE_SEED)
	for id: String in ZONES_ITEMS:
		_main.qa_give_item(id)
	for id: String in ZONES_POTIONS:
		_main.qa_give_potion(id)
	for i: int in 8:  # the 8 badges through the real gym flow; badge 8 -> league intro
		await _clear_gym()
	_league_line("intro")
	await _shot("01-route-victoire")
	_main.league_continue()
	await create_timer(FLOAT_WAIT).timeout
	_league_line("member 1 fight")
	await _shot("02-conseil-combat")
	_main.qa_set_hp(LEAGUE_HURT_HP)
	_main.qa_win_league_fight()
	_main.reward_skip()
	_league_line("intermission 1")
	await _shot("03-intermission")
	for i: int in 3:  # members 2..4
		await _league_fight()
	_league_line("before Maître")
	_main.league_continue()
	await create_timer(FLOAT_WAIT).timeout
	_league_line("Maître fight")
	await _shot("04-maitre")
	_main.qa_set_hp(LEAGUE_HURT_HP)
	_main.qa_win_league_fight()
	_main.reward_skip()
	_league_line("boss intro")
	await _shot("05-ethernatos-intro")
	_main.league_continue()
	await create_timer(FLOAT_WAIT).timeout
	_league_line("boss fight")
	await _shot("06-ethernatos-combat")
	_main.qa_win_league_fight()
	var vs: RunEndScreen = _main.get_victory_screen()
	print("victory: screen=%s title=\"%s\" sub=\"%s\" league=%s stats=%s" % [_main.get_current_screen_name(),
			vs.get_title_text(), vs.get_subtitle_text(), vs.get_league_row(), vs.get_stats()])
	await _shot("07-victoire-finale")
	# Defeat: a new run straight into the league (QA cheat, no badge), first fight counted as won, the 2nd one lost.
	_main.start_new_run(LEAGUE_SEED + 1)
	_main.qa_skip_to_league()
	_main.qa_set_league_stage(LEAGUE_DEFEAT_STAGE)
	_main.league_continue()
	_league_line("defeat fight")
	print("lost: ", _main.qa_lose_battle())
	_main.battle_defeat_continue()
	var ds: RunEndScreen = _main.get_defeat_screen()
	print("defeat: screen=%s title=\"%s\" sub=\"%s\" league=%s" % [_main.get_current_screen_name(), ds.get_title_text(),
			ds.get_subtitle_text(), ds.get_league_row()])
	await _shot("08-defaite-conseil")


## Story 013b: first seed (from `from`) whose starter choice holds a roster candidate.
const DIVERSITY_SEED: int = 2026
const DIVERSITY_NEW_GYMS: Array[String] = ["dark", "fairy", "ghost", "dragon", "ice", "steel", "psychic", "fighting", "ground"]


func _roster_line(tag: String) -> void:
	var data: GameData = GameData.new()
	data.load_all()
	var bs: BattleScreen = _main.get_battle_screen()
	var parts: PackedStringArray = PackedStringArray()
	if bs != null:
		for e: Combatant in bs.get_battle().enemies:
			var r: Dictionary = data.get_roster_entry(e.id)
			parts.append("%s(%s gen%s tier%s %s)" % [e.id, e.display_name, str(r.get("generation", "-")), str(r.get("tier", "-")), str(e.type_ids)])
	print("013b %s: zone=%s enc=%s enemies=%s" % [tag, str(_main.get_zone().get("type_id", "")), _main.get_encounter_id(), parts])


## Enters the first reachable room of type `room_type`; restarts the zone map (qa_set_zone) until the fight is a
## roster encounter. True on success.
func _enter_roster_fight(zone_index: int, data: GameData) -> bool:
	for attempt: int in 40:
		_main.qa_set_zone(zone_index)
		for node_id: String in _main.map_reachable_ids():
			if _main.get_run_state().act.graph.get_node(node_id).room_type == "wild":
				_main.map_choose(node_id)
				break
		if _main.get_current_screen_name() == "battle" and data.is_roster_encounter(_main.get_encounter_id()) \
				and (zone_index == 0 or data.get_encounter_enemy_ids(_main.get_encounter_id()).size() >= 2):
			return true
	return false


func _diversity_shots() -> void:
	var data: GameData = GameData.new()
	data.load_all()
	var roster_cands: Array[String] = data.get_roster_starter_candidates()
	_main.forced_starter_id = ""
	var seed_used: int = DIVERSITY_SEED
	var roster_pick: String = ""
	for s: int in range(DIVERSITY_SEED, DIVERSITY_SEED + 200):
		_main.start_new_run(s)
		for id: String in _main.get_starter_choices():
			if roster_cands.has(id) and not data.get_evolution(id).is_empty():
				roster_pick = id
		if not roster_pick.is_empty():
			seed_used = s
			break
	print("013b starter seed=%d choices=%s roster pick=%s" % [seed_used, _main.get_starter_choices(), roster_pick])
	await _shot("01-choix-depart")
	_main.starter_choose(roster_pick)
	print("013b run starter=%s deck=%s" % [_main.get_run_state().starter_pokemon_id, _main.get_run_state().deck.map(func(c: CardData) -> String: return c.deck_key())])
	if _enter_roster_fight(0, data):
		await create_timer(FLOAT_WAIT).timeout
		_roster_line("zone 1 wild")
		await _shot("02-sauvage-zone1")
	else:
		print("013b: no roster fight found in zone 1")
	_main.qa_set_hp(_main.get_run_state().max_hp)
	if _enter_roster_fight(5, data):
		await create_timer(FLOAT_WAIT).timeout
		_roster_line("zone 6 wild")
		await _shot("03-sauvage-zone6")
		await _win_battle(true)
		var carriers: PackedStringArray = PackedStringArray()
		for o: RewardOffer in _main.get_reward_offers():
			carriers.append("%s<-%s" % [o.card.id, o.card.pokemon_id])
		print("013b reward carriers=%s" % [carriers])
		await _shot("04-recompense")
		_main.reward_skip()
	else:
		print("013b: no roster fight found in zone 6")
	# A newly possible gym type (dark first): first seed whose zones hold one, then that zone's gym.
	var gym_zone: int = -1
	for s: int in range(DIVERSITY_SEED, DIVERSITY_SEED + 200):
		_main.start_new_run(s, roster_pick)
		for wanted: String in DIVERSITY_NEW_GYMS:
			for z: Dictionary in _main.get_run_state().zones:
				if String(z["type_id"]) == wanted and gym_zone < 0:
					gym_zone = int(z["index"])
			if gym_zone >= 0:
				break
		if gym_zone >= 0:
			print("013b gym seed=%d zone=%s" % [s, str(_main.get_run_state().zones[gym_zone])])
			break
	_main.qa_set_zone(gym_zone)
	_main.qa_skip_to_gym()
	await create_timer(FLOAT_WAIT).timeout
	_roster_line("gym")
	await _shot("05-arene-nouveau-type")
	_main.qa_set_zone(gym_zone)
	_main.map_open_deck()
	print("013b deck of %s: %d cards" % [_main.get_run_state().starter_pokemon_id, _main.get_run_state().deck.size()])
	await _shot("06-deck")
	_main.map_close_deck()


func _act_text(run: RunState) -> String:
	return JSON.stringify(SaveGame.to_dict(run)["run"]["act"])


func _save_shots() -> void:
	for p: String in [SAVE_QA_PATH, SAVE_QA_PATH + ".bak"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	_main.qa_set_save_path(SAVE_QA_PATH)
	_main.start_new_run(SAVE_SEED, "salameche")
	for i: int in 2:  # badges 1 and 2 through the real gym flow (evolution after badge 1)
		_main.qa_skip_to_gym()
		_main.qa_win_gym()
		_main.reward_skip()
		_drain_team_evolution()
		_main.badge_continue()
		if _main.get_current_screen_name() == "evolution":
			_main.evolution_continue()
			_main.evolution_pick(0)
			_main.evolution_continue()
	for id: String in ZONES_ITEMS:
		_main.qa_give_item(id)
	for id: String in ZONES_POTIONS:
		_main.qa_give_potion(id)
	_main.qa_give_cards(6)
	_main.qa_set_money(312)
	var run: RunState = _main.get_run_state()
	run.act.enter(run.act.reachable_ids()[0])  # one room done on the zone-3 map
	_main.qa_save_now()
	var before_act: String = _act_text(run)
	var before_sum: Dictionary = run.get_summary()
	print("015 saved: zone=%d badges=%d form=%s deck=%d items=%d potions=%d money=%d visited=%s has_save=%s" % [
			run.zone_index + 1, run.badges.size(), run.starter_pokemon_id, run.deck.size(), run.items.size(),
			run.potions.size(), run.money, run.act.visited, _main.qa_has_save()])
	_main.qa_quit_to_title()
	print("015 resume lines: ", _main.get_resume_screen().get_summary_lines())
	await _shot("01-reprendre")
	_main.resume_continue()
	var after: RunState = _main.get_run_state()
	print("015 after resume: screen=%s same_map=%s same_summary=%s reachable=%s" % [_main.get_current_screen_name(),
			_act_text(after) == before_act, after.get_summary() == before_sum, _main.map_reachable_ids()])
	await _shot("02-apres-reprise")
	var f := FileAccess.open(SAVE_QA_PATH, FileAccess.WRITE)
	f.store_string("{\"version\": 1, \"run\": {\"player_id\": ")  # truncated file
	f.close()
	_main.qa_quit_to_title()
	print("015 unreadable: ", _main.get_resume_screen().get_message().replace("\n", " | "), " bak=",
			FileAccess.file_exists(SAVE_QA_PATH + ".bak"))
	await _shot("03-sauvegarde-illisible")
	_main.resume_new_game()
	_main.qa_quit_to_title()  # relaunch without any save
	print("015 no save: screen=%s has_save=%s" % [_main.get_current_screen_name(), _main.qa_has_save()])
	await _shot("04-pas-de-sauvegarde-depart")
	_main.starter_choose(0)
	print("015 new run saved at the map: ", _main.qa_has_save())
	_main.map_choose(_main.map_reachable_ids()[0])
	_main.qa_lose_battle()
	print("015 lost battle: has_save=%s" % _main.qa_has_save())
	_main.battle_defeat_continue()
	_main.defeat_new_run()
	_main.qa_quit_to_title()
	print("015 after defeat relaunch: screen=%s has_save=%s" % [_main.get_current_screen_name(), _main.qa_has_save()])
	await _shot("05-apres-defaite")
	for p: String in [SAVE_QA_PATH, SAVE_QA_PATH + ".bak"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


## Story 016: chips / status feedback / intents / lost turn / cure / status card shots (filter `story-016`).
func _status_line(tag: String) -> void:
	var bs: BattleScreen = _main.get_battle_screen()
	var b: Battle = bs.get_battle()
	var chips: PackedStringArray = PackedStringArray()
	var floats: PackedStringArray = PackedStringArray()
	for i: int in b.enemies.size():
		chips.append("%s=%s" % [b.enemies[i].id, bs.get_enemy_status_chips(i)])
		floats.append("%s=\"%s\"" % [b.enemies[i].id, bs.get_enemy_status_float_text(i).replace("\n", " | ")])
	print("016 %s: chips=%s player_chips=%s floats=%s player_float=\"%s\" hp=%s player_hp=%d energy=%d hint=\"%s\" intents=%s" % [
			tag, chips, bs.get_player_status_chips(), floats, bs.get_player_status_float_text().replace("\n", " | "),
			_enemy_summary(b), b.player.hp, b.energy, bs.get_hint_text(), _intent_summary(b)])


func _status_shots() -> void:
	_main.start_new_run(STATUS_SEED, "salameche")
	_main.qa_give_potion("total_soin")
	_main.qa_give_potion("antidote")
	# 07 + 01: three enemies, status cards in hand, then poison / burn / paralysis on them.
	_main.start_encounter(STATUS_TRIO)
	var bs: BattleScreen = _main.get_battle_screen()
	bs.qa_force_hand(STATUS_HAND)
	await _shot("07-carte-statut")
	bs.play_card_direct(0, 0)  # Toxik -> enemy 0
	bs.play_card_direct(0, 0)  # Feu Follet -> enemy 0
	bs.play_card_direct(0, 0)  # Cage-Éclair -> enemy 0
	bs.qa_apply_status(1, "poison", 3)
	bs.qa_apply_status(1, "burn", 2)
	bs.qa_apply_status(2, "paralysis", 1)
	_status_line("01")
	await _shot("01-statuts-ennemis")
	await create_timer(FLOAT_WAIT).timeout
	bs.press_end_turn()
	_status_line("02")
	await _shot("02-tick-poison")
	# 03: a Fire enemy is immune to burn.
	_main.start_encounter("solo_cyndaquil")
	bs = _main.get_battle_screen()
	bs.qa_force_hand(["feu_follet", "toxik"])
	bs.play_card_direct(1, 0)  # Toxik (sticks)
	bs.play_card_direct(0, 0)  # Feu Follet: immune
	_status_line("03")
	await _shot("03-immunite")
	# 04: Aspicot's first attack poisons the team.
	_main.start_encounter("solo_aspicot")
	bs = _main.get_battle_screen()
	bs.qa_force_hand(["abri"])
	bs.press_end_turn()
	_status_line("04")
	await _shot("04-statut-joueur")
	# 04b: the team is asleep: it loses 2 energy this turn (info row message), then gets the RÉPIT chip.
	await create_timer(FLOAT_WAIT).timeout
	bs.qa_apply_status(-1, "sleep", 1)
	await create_timer(FLOAT_WAIT).timeout
	bs.press_end_turn()
	_status_line("04b")
	await _shot("04b-joueur-endormi")
	# 06: Total Soin cures the team (chips gone).
	await create_timer(FLOAT_WAIT).timeout
	var b: Battle = bs.get_battle()
	var idx: int = -1
	for i: int in b.potions.size():
		if b.potions[i].id == "total_soin":
			idx = i
	print("016 before potion: player_chips=%s potions=%d idx=%d" % [bs.get_player_status_chips(), b.potions.size(), idx])
	_main.battle_use_potion(idx)
	_status_line("06")
	await _shot("06-soin-statut")
	# 08: aftermath immunity: after the sleep, the team cannot be put to sleep / frozen ("Immunisé !", RÉPIT chip).
	await create_timer(FLOAT_WAIT).timeout
	var blocked: bool = not bs.qa_apply_status(-1, "freeze", 1)
	print("016 08 freeze refused by aftermath: %s aftermath_turns=%d" % [blocked, b.player.aftermath_turns])
	_status_line("08")
	await _shot("08-repit")
	# 05: sleeping / frozen enemies show "Dort" / "Gelé"; Aspicot's long status attack must fit.
	_main.start_encounter(STATUS_INTENTS)
	bs = _main.get_battle_screen()
	b = bs.get_battle()
	b.enemies[2].sequence_index = 0
	b.enemies[2].strength = STATUS_LONG_STRENGTH
	b._roll_intent(b.enemies[2])
	bs.qa_apply_status(0, "sleep", 1)
	bs.qa_apply_status(1, "freeze", 1)
	await create_timer(FLOAT_WAIT).timeout
	_status_line("05")
	await _shot("05-sommeil-gel")
	# 09: worst-case layout: 3 enemies with 3 chips each, chips on the team, 7-card hand (all fully visible).
	_main.start_encounter(STATUS_TRIO)
	bs = _main.get_battle_screen()
	for i: int in 3:
		bs.qa_apply_status(i, "poison", 3)
		bs.qa_apply_status(i, "burn", 2)
		bs.qa_apply_status(i, "paralysis", 1)
	bs.qa_apply_status(-1, "poison", 2)
	bs.qa_apply_status(-1, "paralysis", 1)
	var seven: Array[String] = STATUS_HAND.duplicate()
	seven.append_array(["toxik", "feu_follet"])
	bs.qa_force_hand(seven)
	await create_timer(FLOAT_WAIT).timeout
	_status_line("09")
	await _shot("09-main-7-cartes-statuts")


## Story 019: a dual-type enemy's intent showing the attack's type "(Type)" (Étourmi Normal/Vol, 2nd action = its Vol
## attack) and the new zone-1 gym fight (roster team of 3 tier-1 Pokémon of the zone type, x0.7 HP) (filter `story-019`).
func _balance_shots() -> void:
	_main.start_new_run(STORY_019_SEED, "salameche")
	_main.start_encounter("solo_starly")
	var bs: BattleScreen = _main.get_battle_screen()
	for i: int in 1:
		bs.press_end_turn()
		await create_timer(FLOAT_WAIT).timeout
		_main.qa_set_hp(90)
	print("019 01 intents=%s" % [_intent_summary(bs.get_battle())])
	await _shot("01-intent-type")
	_main.start_new_run(STORY_019_SEED, "salameche")
	_main.qa_start_gym()
	var gb: Battle = _main.get_battle_screen().get_battle()
	print("019 02 zone=%s enc=%s enemies=%s intents=%s" % [String(_main.get_zone().get("type_id", "")), _main.get_battle_screen().get_encounter_id(),
			_enemy_summary(gb), _intent_summary(gb)])
	await _shot("02-arene-zone1")


## Story 017: one line of capture state for the shot log.
func _capture_line(tag: String) -> void:
	var run: RunState = _main.get_run_state()
	var line: String = "017 %s: hud=\"%s\" tip=\"%s\" run_balls=%s captured=%s" % [tag, _main.get_hud().get_balls_text(),
			_main.get_hud().get_balls_tooltip().replace("\n", " | "), run.balls, run.captured]
	var bs: BattleScreen = _main.get_battle_screen()
	if bs != null and _main.get_current_screen_name() == "battle":
		var b: Battle = bs.get_battle()
		var texts := PackedStringArray()
		for i: int in b.enemies.size():
			texts.append("%s=%s" % [b.enemies[i].id, bs.get_enemy_capture_texts(i)])
		line += " allowed=%s mode=%s button=%s enemies=%s capture=%s float=\"%s\" energy=%d hint=\"%s\"" % [b.capture_allowed,
				bs.is_capture_mode(), bs.get_capture_button_state(), _enemy_summary(b), texts, bs.get_capture_float_text(), b.energy,
				bs.get_hint_text()]
	print(line)


## Story 017: capture shots (filter `story-017`).
func _capture_shots() -> void:
	_main.start_new_run(CAPTURE_SEED, "salameche")
	for bid: String in ["poke_ball", "poke_ball", "poke_ball", "super_ball", "hyper_ball"]:
		_main.qa_give_ball(bid)
	for iid: String in ["restes", "bandeau", "baie_oran", "orbe_vie"]:
		_main.qa_give_item(iid)
	_main.qa_give_potion("total_soin")
	_capture_line("01")
	await _shot("01-hud-balls")
	# 02: wild trio; enemy 1 weakened and asleep, capture mode on (chances per ball on each enemy).
	_main.start_encounter(CAPTURE_TRIO, "wild")
	var bs: BattleScreen = _main.get_battle_screen()
	var b: Battle = bs.get_battle()
	var weak: Combatant = b.enemies[1]
	weak.hp = maxi(1, weak.max_hp / 5)
	weak.changed.emit()
	bs.qa_apply_status(1, "sleep", 1)
	await create_timer(FLOAT_WAIT).timeout
	bs.toggle_capture_mode()
	_capture_line("02")
	await _shot("02-mode-capture")
	# 04: a Poké Ball on a full-HP enemy (low chance): retried until a failure is on screen.
	var failed: bool = false
	for attempt: int in 3:
		if failed or b.ball_count("poke_ball") <= 0:
			break
		var target: int = 0 if b.enemies[0] != weak else 2
		var r: Dictionary = _main.battle_use_ball("poke_ball", target)
		print("017 throw full-hp: ", {"used": r.get("used"), "success": r.get("success"), "chance": r.get("chance"), "roll": r.get("roll")})
		failed = bool(r.get("used", false)) and not bool(r.get("success", true))
		if not failed:
			bs.qa_force_hand(["griffe", "griffe", "griffe", "griffe", "griffe"])
	_capture_line("04")
	await _shot("04-capture-ratee")
	# 03: the weakened, sleeping enemy with the best ball left, until it is captured (enemy slots rebuilt).
	await create_timer(FLOAT_WAIT).timeout
	for attempt: int in 4:
		var idx: int = b.enemies.find(weak)
		if idx < 0 or b.ball_ids().is_empty():
			break
		if b.energy < b.ball_energy_cost():
			bs.qa_force_hand(["griffe", "griffe", "griffe", "griffe", "griffe"])
		var ids: Array[String] = b.ball_ids()
		var r: Dictionary = _main.battle_use_ball(ids[ids.size() - 1], idx)
		print("017 throw weak: ", {"used": r.get("used"), "success": r.get("success"), "chance": r.get("chance"), "roll": r.get("roll")})
	_capture_line("03")
	await _shot("03-capture-reussie")
	# 05: win the rest of the fight: the reward shows the capture (and a ball loot chip, staged if the loot roll gave none).
	_win_battle(true)
	var rs: RewardScreen = _main.get_reward_screen()
	var loot: Dictionary = _main.get_last_loot().duplicate()
	if loot.get("ball", null) == null:
		loot["ball"] = _main.get_hud().ball_book.get("poke_ball", null)  # display staging only (the run is unchanged)
		print("017 05: ball loot chip staged (the loot roll gave no ball)")
	rs.set_loot(loot)
	print("017 05 captures=%s loot=%s" % [rs.get_capture_texts(), rs.get_loot_texts()])
	await _shot("05-recompense-capture")
	_main.reward_skip()
	# 06: Mart with its balls row: one bought ("Vendu"), then the bag filled up ("Sac plein").
	_main.qa_set_money(400)
	_main.qa_open_room("mart")
	var shop: ShopInventory = _main.get_shop_inventory()
	if not shop.balls.is_empty():
		_main.shop_buy_ball(0)
	var guard: int = 0
	while _main.get_run_state().ball_total() < _main.get_run_state().max_balls() and guard < 6:
		guard += 1
		_main.qa_give_ball("poke_ball")
	_main.get_shop_screen().refresh()
	_main.qa_set_money(40)
	_main.get_shop_screen().refresh()
	var shop_lines := PackedStringArray()
	for e: ShopEntry in shop.balls:
		shop_lines.append("%s %d sold=%s" % [e.get_name(), e.price, e.sold])
	print("017 06 shop balls=%s" % [shop_lines])
	_capture_line("06")
	await _shot("06-mart-balls")
	_main.shop_leave()
	# 07: the team tab of the deck panel (starter + the captured Pokémon).
	_main.open_deck("team")
	print("017 07 team=%s" % [_main.get_deck_panel().get_lines()])
	await _shot("07-equipe")
	_main.close_deck()
	# 08: a gym (trainer) fight: the capture button is disabled with the reason.
	_main.qa_start_gym()
	_capture_line("08")
	await _shot("08-dresseur-sans-capture")


## Story 018: one line of rival / event state for the shot log.
func _rival_line(tag: String) -> void:
	var line: String = "018 %s: screen=%s rival=%s fight=%s special=%s pending=%d" % [tag, _main.get_current_screen_name(),
			_main.get_rival_info(), {"room": _main.get_current_fight().get("room", ""), "title": _main.get_current_fight().get("title", "")},
			_main.get_last_special_reward(), _main.get_pending_card_removals()]
	var bs: BattleScreen = _main.get_battle_screen()
	if bs != null and _main.get_current_screen_name() == "battle":
		var b: Battle = bs.get_battle()
		var caps := PackedStringArray()
		for i: int in b.enemies.size():
			caps.append("%s" % [bs.get_enemy_capture_texts(i)])
		var intro: RivalIntroBanner = bs.get_rival_intro()
		line += " header=\"%s\" enemies=%s capture=%s intro=\"%s\" taunt=\"%s\"" % [bs.get_trainer_header_text(), _enemy_summary(b), caps,
				intro.get_title_text() if intro != null else "", intro.get_taunt_text() if intro != null else ""]
	var es: EventScreen = _main.get_event_screen()
	if es != null:
		var opts := PackedStringArray()
		for i: int in (es.get_event().get("options", []) as Array).size():
			opts.append("%s[%s]" % [es.get_option_text(i), "ok" if es.is_option_available(i) else "grisée"])
		line += " event=%s options=%s picker_open=%s" % [es.get_event().get("id", ""), opts, es.get_picker().is_open()]
	var rs: RewardScreen = _main.get_reward_screen()
	if rs != null:
		line += " reward_title=\"%s\" loot=%s captures=%s" % [rs.get_title_text(), rs.get_loot_texts(), rs.get_capture_texts()]
	print(line)


## Story 018: resolves the non-rival rooms of the current map until a rival fight is on screen (false if none).
func _walk_to_rival() -> bool:
	for step: int in 40:
		var scr: String = _main.get_current_screen_name()
		if scr == "map":
			var reach: Array[String] = _main.map_reachable_ids()
			if reach.is_empty():
				return false
			var pick: String = reach[0]
			for id: String in reach:
				if _main.get_run_state().act.graph.get_node(id).room_type == "rival":
					pick = id
			_main.map_choose(pick)
		elif scr == "battle":
			if String(_main.get_current_fight().get("room", "")) == "rival":
				return true
			_main.qa_win_current_fight()
		elif scr == "reward":
			_main.reward_skip()
		elif scr == "event":
			_main.event_choose(1 if _main.event_option_available(1) else 0)
			_main.event_continue()
			while _main.get_pending_card_removals() > 0:
				_main.event_remove_card(0)
		elif scr == "evolution":
			if _main.get_evolution_screen().get_step() == EvolutionScreen.Step.CHOOSE:
				_main.evolution_skip()
			else:
				_main.evolution_continue()
		elif scr == "center":
			_main.center_continue()
		elif scr == "mart":
			_main.shop_leave()
		else:
			_main.room_continue()
	return false


## Story 018: rival / events / legendary shots (filter `story-018`).
func _rival_shots() -> void:
	_main.start_new_run(RIVAL_SEED, "salameche")
	_main.qa_set_zone(1)
	_rival_line("01")
	await _shot("01-carte-salle-rival")
	if not _walk_to_rival():
		print("018 ERROR: no rival room reached")
	_rival_line("02")
	await _shot("02-rival-intro")
	var bs: BattleScreen = _main.get_battle_screen()
	if bs != null and bs.get_rival_intro() != null:
		bs.get_rival_intro().dismiss()
	await create_timer(FLOAT_WAIT).timeout
	_rival_line("03")
	await _shot("03-combat-rival")
	_main.qa_win_current_fight()
	_rival_line("04")
	await _shot("04-recompense-rival")
	_main.reward_skip()
	# 05: the travelling merchant with too little money: the 110 P$ option is greyed with its reason.
	_main.qa_set_money(30)
	_main.qa_show_event("marchand_ambulant")
	_rival_line("05")
	await _shot("05-evenement-choix")
	# 06: the trading trainer: accept, "Continuer" -> the deck picker to forget a card.
	_main.qa_show_event("dresseur_echange")
	_main.event_choose(0)
	_main.event_continue()
	_rival_line("06")
	await _shot("06-oubli-carte")
	var picker: DeckPicker = _main.get_event_screen().get_picker()
	if picker.is_open() and not picker.get_offered_indices().is_empty():
		picker.pick(picker.get_offered_indices()[0])
	_rival_line("06b")
	# 07: Darkrai's legendary event (zone 3+).
	_main.qa_set_zone(2)
	_main.qa_show_event("legendaire_darkrai")
	_rival_line("07")
	await _shot("07-legendaire-evenement")
	for bid: String in ["poke_ball", "super_ball", "hyper_ball"]:
		_main.qa_give_ball(bid)  # before the fight: a battle takes the run's balls at its start
	_main.event_choose(1)
	_main.event_continue()
	bs = _main.get_battle_screen()
	if bs != null:
		await create_timer(FLOAT_WAIT).timeout
		bs.get_battle().energy = maxi(bs.get_battle().energy, bs.get_battle().ball_energy_cost())  # staging: the sleep cost energy
		bs.get_battle().state_changed.emit()
		bs.toggle_capture_mode()
	_rival_line("08")
	await _shot("08-combat-legendaire")
	if bs != null and bs.is_capture_mode():
		bs.toggle_capture_mode()
	_main.qa_win_current_fight()
	_rival_line("09")
	await _shot("09-carte-legendaire")
	_main.reward_skip()
	# 10: the pre-league rival after badge 8.
	_main.qa_set_zone(7)
	_main.qa_win_gym()
	_main.reward_skip()
	_main.badge_continue()
	for _e: int in 6:
		if _main.get_current_screen_name() == "evolution":
			if _main.get_evolution_screen().get_step() == EvolutionScreen.Step.CHOOSE:
				_main.evolution_skip()
			else:
				_main.evolution_continue()
	_rival_line("10")
	await _shot("10-rival-final")


## Story 020: redesigned cards in the battle hand (5 and 10 cards), the reward screen and the deck overlay (filter `story-020`).
func _style_shots() -> void:
	_main.start_new_run(STYLE_SEED, "salameche")
	_main.start_encounter("trio_vol")
	var bs: BattleScreen = _main.get_battle_screen()
	bs.qa_force_hand(STYLE_HAND)
	await create_timer(FLOAT_WAIT).timeout
	await _shot("01-main-5-cartes")
	bs.select_card(0)
	await _shot("02-carte-selectionnee")
	bs.qa_force_hand(STYLE_HAND_10)
	await _shot("03-main-10-cartes")
	_main.open_deck("deck")
	await _shot("04-deck-combat")
	_main.close_deck()
	await _win_battle(true)
	await _shot("05-recompense")
	_main.open_deck()
	await _shot("06-deck-carte")
	_main.close_deck()


## Story 020 part 3 (screens pass): maps (zone 1 start, mid-zone with a travelled path, another gym type), starter
## choice, reward, Mart, Centre, event, badge, league, run end and deck overlay, files 2x-<screen>.png (filter `story-020`).
func _screens_style_shots() -> void:
	_main.qa_set_autosave(false)  # never touch the real save
	_main.qa_quit_to_title()
	await _shot("2x-choix-starter")
	_main.start_new_run(STYLE_SEED, "salameche")
	_zone_line("2x zone 1 start")
	await _shot("2x-carte-zone-1-debut")
	var reward_done: bool = false
	for step: int in 3:  # walk three rooms so the travelled path shows
		var ids: Array[String] = _main.map_reachable_ids()
		if ids.is_empty():
			break
		_main.map_choose(ids[0])
		match _main.get_current_screen_name():
			"battle":
				await _win_battle(true)
				if not reward_done:
					reward_done = true
					await _shot("2x-recompense")
				_main.reward_skip()
			"event":
				_main.event_choose(0)
				_main.event_continue()
			"center":
				_main.center_continue()
			"mart":
				_main.shop_leave()
			_:
				_main.room_continue()
		print("2x walk step %d -> screen=%s" % [step, _main.get_current_screen_name()])
	await _shot("2x-carte-chemin-parcouru")
	_main.open_deck()
	await _shot("2x-deck")
	_main.close_deck()
	_main.qa_set_money(MART_MONEY)
	_main.qa_open_room("mart")
	await _shot("2x-mart")
	_main.shop_leave()
	_main.qa_set_hp(_main.get_run_state().max_hp / 2)
	_main.qa_open_room("center")
	await _shot("2x-centre")
	_main.center_continue()
	_main.qa_show_event("marchand_ambulant")
	await _shot("2x-evenement")
	_main.event_choose(0)
	_main.event_continue()
	await _clear_gym()
	if _main.get_current_screen_name() != "map":
		print("2x: after gym 1 screen=", _main.get_current_screen_name())
	_main.qa_skip_to_gym()
	_main.qa_win_gym()
	_main.reward_skip()
	_drain_team_evolution()
	await _shot("2x-badge")
	_main.badge_continue()
	if _main.get_current_screen_name() == "evolution":
		_main.evolution_continue()
		_main.evolution_skip()
		_main.evolution_continue()
	_main.qa_set_zone(4)
	_zone_line("2x zone 5 map")
	await _shot("2x-carte-autre-type")
	_main.qa_set_zone(6)
	_zone_line("2x zone 7 map")
	await _shot("2x-carte-autre-type-b")
	_main.qa_skip_to_league()
	await _shot("2x-ligue")
	_main.start_new_run(STYLE_SEED + 1, "salameche")
	_main.map_choose(_main.map_reachable_ids()[0])
	if _main.get_current_screen_name() != "battle":
		_main.start_encounter("trio_vol")
	_main.qa_lose_battle()
	_main.battle_defeat_continue()
	await _shot("2x-fin-de-partie")


## Story 020: battle backdrops (filter `story-020`): the zone's real Champion fight (backdrop chosen by Main from the
## gym type), then the same 3-enemy fight on forced backdrops, plus a selected card; files 1x-combat-<backdrop>.png.
func _backdrop_shots() -> void:
	_main.start_new_run(STYLE_SEED, "salameche")
	_main.qa_start_gym()
	var bs: BattleScreen = _main.get_battle_screen()
	bs.qa_force_hand(STYLE_HAND)
	print("backdrop gym zone_type=%s backdrop=%s" % [_main.get_zone().get("type_id", ""), bs.get_backdrop_id()])
	await _shot("1x-combat-champion-" + bs.get_backdrop_id())
	_main.start_encounter("trio_vol")
	bs = _main.get_battle_screen()
	bs.qa_force_hand(STYLE_HAND)
	for id: String in ["route", "fire", "water", "ghost", "electric", "ice", "grass", "psychic", "league", "ethernatos", "legendary"]:
		bs.set_backdrop(id)
		print("backdrop forced=%s shown=%s" % [id, bs.get_backdrop_id()])
		await _shot("1x-combat-" + id)
	bs.set_backdrop("route")
	bs.select_card(0)
	await _shot("1x-combat-carte-selectionnee")


## Story 020b: animated Pokémon (front sheets for enemies, back sheet for the player) on the shader backdrops, a big
## player (Dracaufeu) against Éthernatos and a solo fight; files 1x-*.png (filter `story-020b`). The anim frame is printed.
func _premium_battle_shots() -> void:
	_main.start_new_run(STYLE_SEED, "salameche")
	_main.start_encounter("trio_vol")
	var bs: BattleScreen = _main.get_battle_screen()
	bs.qa_force_hand(STYLE_HAND)
	for id: String in ["route", "fire", "water", "ghost", "league", "ethernatos", "grass", "psychic", "dark"]:
		bs.set_backdrop(id)
		await _shot("1x-combat-" + id)
		var sp: AnimatedPokemon = bs.find_child("PlayerSprite", true, false) as AnimatedPokemon
		print("premium backdrop=%s player_animated=%s frame=%d" % [bs.get_backdrop_id(), sp.is_animated() if sp != null else false,
				sp.get_frame() if sp != null else -1])
	print("premium evolution stage=%d" % _main.qa_set_evolution_stage(3))
	_main.qa_start_boss()  # zone Champion (big sprites) against Dracaufeu (big back sheet)
	bs = _main.get_battle_screen()
	bs.qa_force_hand(STYLE_HAND)
	bs.set_backdrop("ethernatos")
	await _shot("1x-grand-ethernatos-dracaufeu")
	for zone: int in 8:  # the gym whose trio has the tallest sprite (Roucarnage, Onix...)
		if _main.qa_set_zone(zone) and String(_main.get_zone().get("type_id", "")) in ["flying", "rock"]:
			_main.qa_start_gym()
			bs = _main.get_battle_screen()
			bs.qa_force_hand(STYLE_HAND)
			await _shot("1x-grand-champion-" + bs.get_backdrop_id())
			break
	_main.start_encounter("solo_pikachu")
	bs = _main.get_battle_screen()
	bs.qa_force_hand(STYLE_HAND)
	bs.set_backdrop("electric")
	await _shot("1x-solo-electric")
	bs.set_backdrop("dragon")
	await _shot("1x-solo-dragon")


## Story 020b: parchment map (zone start, travelled path, other zone types), a reward and an event with item art,
## the top bar with held items + potions + balls, and the Poké Mart with item / potion / ball art; files 2x-*.png
## (filter `story-020b`).
func _premium_map_shots() -> void:
	_main.qa_set_autosave(false)  # never touch the real save
	_main.start_new_run(STYLE_SEED, "salameche")
	var icons: Array[String] = []
	for room: String in ["wild", "elite", "rival", "center", "mart", "event", "boss", "player"]:
		if MapCanvas.icon_texture(room) != null:
			icons.append(room)
	var zone_type: String = String(_main.get_zone().get("type_id", ""))
	print("2x premium map art zone1 type=%s region_image=%s icons=%s" % [zone_type,
			MapCanvas.region_texture(zone_type) != null, icons])
	await _shot("2x-carte-zone-1-debut")
	var reward_done: bool = false
	for step: int in 3:  # walk three rooms so the ink trail shows
		var ids: Array[String] = _main.map_reachable_ids()
		if ids.is_empty():
			break
		_main.map_choose(ids[0])
		match _main.get_current_screen_name():
			"battle":
				await _win_battle(true)
				if not reward_done:
					reward_done = true
					var data: GameData = _main.get("_data") as GameData
					_main.get_reward_screen().set_loot({"money": 25, "item": data.get_item("restes"),
							"potion": data.get_potion("super_potion"), "ball": data.get_ball("super_ball")})
					await _shot("2x-recompense-objet")
				_main.reward_skip()
			"event":
				_main.event_choose(0)
				_main.event_continue()
			"center":
				_main.center_continue()
			"mart":
				_main.shop_leave()
			_:
				_main.room_continue()
		print("2x premium walk step %d -> screen=%s" % [step, _main.get_current_screen_name()])
	for id: String in ["restes", "bandeau", "orbe_vie", "lunettes_choix", "cloche_eclat"]:
		_main.qa_give_item(id)
	_main.qa_give_potion("potion")
	_main.qa_give_potion("anti_brule")
	_main.qa_give_ball("poke_ball")
	_main.qa_give_ball("poke_ball")
	_main.qa_give_ball("super_ball")
	print("2x premium hud items=%s potions=%s balls=%s" % [_main.get_hud().get_item_names(),
			_main.get_hud().get_potion_texts(), _main.get_hud().get_balls_tooltip().replace("\n", " / ")])
	await _shot("2x-carte-chemin-parcouru")
	_main.qa_set_money(MART_MONEY)
	_main.qa_open_room("mart")
	await _shot("2x-mart")
	_main.shop_leave()
	_main.qa_show_event("sac_abandonne")
	_main.event_choose(0)
	await _shot("2x-evenement-objet")
	_main.event_continue()
	for zone: int in [4, 6]:
		if _main.qa_set_zone(zone):
			print("2x premium zone %d type=%s" % [zone + 1, _main.get_zone().get("type_id", "")])
			await _shot("2x-carte-zone-%d" % (zone + 1))


## Story 020b: premium cards and finish (filter `story-020b`): a hand with a starter / common / uncommon / rare /
## legendary card, the rare and the legendary card hovered (lift, tilt, foil), deck overlay, reward screen and the
## starter (title) screen; files 3x-*.png.
func _premium_card_shots() -> void:
	_main.qa_set_autosave(false)  # never touch the real save
	_main.start_new_run(STYLE_SEED, "salameche")
	_main.start_encounter("trio_vol")
	var bs: BattleScreen = _main.get_battle_screen()
	var premium_hand: Array[String] = ["flammette", "vive_attaque", "danse_flamme", "lance_flammes", "feu_sacre"]
	bs.qa_force_hand(premium_hand)
	await create_timer(FLOAT_WAIT).timeout
	await _shot("3x-main-raretes")
	var faces: Array[CardFace] = []
	for n: Node in _main.find_children("Content", "", true, false):
		if n is CardFace and (n as CardFace).is_visible_in_tree():
			faces.append(n as CardFace)
	print("3x hand faces=%d" % faces.size())
	for idx: int in [3, 4]:
		if idx >= faces.size():
			continue
		var f: CardFace = faces[idx]
		var rect: Rect2 = f.get_global_rect()
		Input.warp_mouse(rect.position + rect.size * Vector2(0.7, 0.35))
		f.hover(true, true)
		await create_timer(0.5).timeout
		print("3x hover card=%s scale=%s rot=%.3f z=%d" % [f.card.id, f.scale, f.rotation, f.z_index])
		await _shot("3x-carte-survolee-" + f.card.id)
		f.hover(false, false)
		await create_timer(0.3).timeout
	# Story 020b follow-up: skill cards (no carrier Pokémon) show their main effect (EffectArt), not a Poké Ball.
	bs.qa_force_hand(["abri", "hypnose", "toxik", "feu_follet", "cage_eclair", "mur_de_fumee"])
	await create_timer(FLOAT_WAIT).timeout
	await _shot("3x-main-competences")
	# Gallery of every effect illustration, including kinds no card uses yet (heal, draw, energy, buff, freeze).
	var gallery := ColorRect.new()
	gallery.color = UiStyle.BG_DEEP
	gallery.position = Vector2(20, 200)
	gallery.size = Vector2(1240, 140)
	var kinds: Array[String] = [EffectArt.KIND_BLOCK, EffectArt.KIND_HEAL, EffectArt.KIND_DRAW, EffectArt.KIND_ENERGY,
			EffectArt.KIND_BUFF, EffectArt.KIND_ATTACK, "sleep", "paralysis", "poison", "burn", "freeze"]
	for i: int in kinds.size():
		var cell := ColorRect.new()
		cell.color = UiStyle.SKILL.lightened(0.6)
		cell.position = Vector2(8 + i * 112, 8)
		cell.size = Vector2(104, 100)
		gallery.add_child(cell)
		var art := EffectArt.new()
		art.kind = kinds[i]
		art.position = Vector2(8 + i * 112, 12)
		art.size = Vector2(104, 80)
		gallery.add_child(art)
		var lbl := Label.new()
		lbl.text = EffectArt.label_of(kinds[i])
		lbl.add_theme_font_override("font", UiStyle.font_bold())
		lbl.add_theme_color_override("font_color", UiStyle.TEXT_DARK)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector2(8 + i * 112, 88)
		lbl.size = Vector2(104, 20)
		lbl.add_theme_font_size_override("font_size", 13)
		gallery.add_child(lbl)
	root.add_child(gallery)
	await _shot("3x-effets-competences")
	gallery.queue_free()
	_main.open_deck("deck")
	await _shot("3x-deck")
	_main.close_deck()
	await _win_battle(true)
	await _shot("3x-recompense")
	_main.reward_skip()
	_main.qa_quit_to_title()
	await _shot("3x-titre")


## Story 021: attack / combat animation shots, mid-animation frames (filter `story-021`): player charge + projectile,
## impact + super effective number, block pulse, status, enemy charge, K.O. fade, switch slide, capture ball arc.
func _fx_battle_shots() -> void:
	_main.start_new_run(2021, "salameche")
	_main.start_encounter("trio_vol")
	var bs: BattleScreen = _main.get_battle_screen()
	bs.set_fx_speed("normal")
	var b: Battle = bs.get_battle()
	var foe: int = 0
	for i: int in b.enemies.size():
		if b.enemies[i].display_name == "Aspicot":
			foe = i
	var hand: Array[String] = ["flammette", "abri", "hypnose", "dard_venin", "flammette"]
	await create_timer(0.5).timeout  # layout settled: the effects read the sprite positions
	bs.qa_force_hand(hand)
	bs.play_card_direct(0, foe)
	await create_timer(FX_SHOT_DELAY + 0.1).timeout
	await _shot("1x-01-charge-projectile")
	bs.skip_animations()
	bs.qa_force_hand(hand)
	bs.play_card_direct(0, foe)
	await create_timer(FX_SHOT_DELAY + 0.45).timeout
	await _shot("1x-02-impact-super-efficace")
	bs.skip_animations()
	bs.qa_force_hand(hand)
	bs.play_card_direct(1)
	await create_timer(FX_SHOT_DELAY).timeout
	await _shot("1x-03-protection")
	bs.skip_animations()
	bs.qa_force_hand(hand)
	bs.play_card_direct(2, foe)
	await create_timer(FX_SHOT_DELAY + 0.4).timeout
	await _shot("1x-04-statut")
	bs.skip_animations()
	bs.press_end_turn()
	await create_timer(FX_SHOT_DELAY + 0.3).timeout
	await _shot("1x-05-ennemi-charge")
	bs.skip_animations()
	if b.enemies[foe].is_alive():
		b.enemies[foe].hp = 1
		b.enemies[foe].changed.emit()
		bs.qa_force_hand(hand)
		bs.play_card_direct(0, foe)
		await create_timer(FX_SHOT_DELAY + 1.0).timeout
		await _shot("1x-06-ko-fondu")
	bs.skip_animations()
	_main.start_encounter(SWITCH_ENCOUNTER)
	await create_timer(0.5).timeout
	bs = _main.get_battle_screen()
	bs.set_fx_speed("normal")
	var sw: Array[String] = [SWITCH_CARD, SWITCH_CARD, "abri"]
	bs.qa_force_hand(sw)
	bs.play_card_direct(0, 0)
	await create_timer(0.1).timeout
	await _shot("1x-07-switch-slide")
	bs.skip_animations()
	_main.start_new_run(2022, "salameche")
	_main.qa_give_ball("poke_ball")
	_main.qa_give_ball("poke_ball")
	_main.start_encounter(CAPTURE_TRIO, "wild")
	await create_timer(0.5).timeout
	bs = _main.get_battle_screen()
	bs.set_fx_speed("normal")
	_main.battle_use_ball("poke_ball", 0)
	await create_timer(FX_SHOT_DELAY + 0.1).timeout
	await _shot("1x-08-capture-arc")
	bs.skip_animations()


func _run() -> void:
	if _filter == "story-021":
		await _fx_battle_shots()
		quit(0)
		return
	if _filter == "story-020b":
		await _premium_battle_shots()
		await _premium_map_shots()
		await _premium_card_shots()
		quit(0)
		return
	if _filter == "story-020":
		await _style_shots()
		await _backdrop_shots()
		await _screens_style_shots()
		quit(0)
		return
	if _filter == "story-018":
		await _rival_shots()
		quit(0)
		return
	if _filter == "story-017":
		await _capture_shots()
		quit(0)
		return
	if _filter == "story-019":
		await _balance_shots()
		quit(0)
		return
	if _filter == "story-016":
		await _status_shots()
		quit(0)
		return
	if _filter == "story-015":
		await _save_shots()
		quit(0)
		return
	if _filter == "story-014":
		await _evolution_shots()
		quit(0)
		return
	if _filter == "story-013b":
		await _diversity_shots()
		quit(0)
		return
	if _filter == "story-013":
		await _league_shots()
		quit(0)
		return
	if _filter == "story-012":
		await _zones_shots()
		quit(0)
		return
	if _filter == "story-011":
		await _deck_shots()
		quit(0)
		return
	if _filter == "story-007":
		await _champion_shots()
		quit(0)
		return
	await _roster_shots()
	_main.forced_starter_id = "salameche"  # the older shots assume Salamèche's deck and identity
	await _items_shots()
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
				if rt == "center":
					_main.center_heal()  # story 006: the centre no longer heals on entry
				_main.room_continue()
	_main.badge_continue()  # story 012: gym reward -> badge -> evolution (badge 1) -> zone 2 map
	_main.evolution_continue()
	_main.evolution_skip()
	_main.evolution_continue()
	await _shot("10-acte-termine")
	print("missing room types on the path: ", WANTED_TYPES.filter(func(t: String) -> bool: return not shot_done.has(t)))
	quit(0)
