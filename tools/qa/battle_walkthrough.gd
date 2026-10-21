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
	_main.qa_win_gym()
	_main.reward_skip()
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


func _run() -> void:
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
