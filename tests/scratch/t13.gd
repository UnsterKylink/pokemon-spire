extends SceneTree
## Story 007 scratch test: evolution, victory summary, defeat at 0 HP from battle, full reset on new run.

var passes: int = 0
var fails: int = 0
var main: Main


func ok(c: bool, msg: String) -> void:
	if c:
		passes += 1
	else:
		fails += 1
		print("FAIL: ", msg)


func win() -> void:
	var guard: int = 0
	while main.get_current_screen_name() == "battle" and guard < 300:
		guard += 1
		var bs: BattleScreen = main.get_battle_screen()
		var b: Battle = bs.get_battle()
		main.qa_set_hp(b.player.max_hp)
		main.qa_set_enemy_hp(1)
		var played: bool = false
		for i: int in b.hand.size():
			if b.hand[i].kind == CardData.KIND_ATTACK and b.can_play(i):
				bs.select_card(i)
				bs.click_enemy(b.first_living_enemy())
				played = true
				break
		if not played:
			bs.press_end_turn()


func _initialize() -> void:
	main = (load("res://src/main.tscn") as PackedScene).instantiate() as Main
	root.add_child(main)
	_go.call_deferred()


func _go() -> void:
	var gd := GameData.new()
	ok(gd.load_all(), "data")
	# --- Pure RunState evolution ---
	var r: RunState = RunState.create_with_starter(gd, "salameche")
	var evo: Dictionary = gd.get_evolution("salameche")
	var hp0: int = r.max_hp
	r.hp = hp0 - 10
	var sm: Dictionary = r.evolve_starter(gd)
	ok(sm["evolved"] == true and sm["from_name"] == "Salamèche" and sm["to_name"] == "Reptincel", "salameche -> Reptincel %s" % sm)
	ok(sm["hp_bonus"] == int(evo["max_hp_bonus"]) and r.max_hp == hp0 + int(evo["max_hp_bonus"]), "max hp bonus")
	ok(r.hp == hp0 - 10 + int(evo["max_hp_bonus"]), "current hp also +bonus")
	ok(r.starter_pokemon_id == "charmeleon" and r.display_name == "Reptincel" and r.sprite_path == String(evo["sprite"]), "identity")
	ok(r.base_pokemon_id == "salameche" and r.type_ids.size() == 1 and r.type_ids[0] == "fire", "base kept, types")
	var c: Combatant = r.build_player_combatant()
	ok(c.active_pokemon_id == "charmeleon" and c.display_name == "Reptincel", "combatant fields evolved form")
	var carried_old: int = 0
	for card: CardData in r.deck:
		if card.pokemon_id == "salameche":
			carried_old += 1
	ok(carried_old == 0, "no deck card still carried by the old form")
	ok(r.evolve_starter(gd).is_empty() and r.max_hp == hp0 + int(evo["max_hp_bonus"]), "evolves once")
	var offers: Array[CardData] = EvolutionOffer.generate(gd, r)
	ok(offers.size() == 3, "3 offers (%d)" % offers.size())
	for o: CardData in offers:
		ok(o.pokemon_id == "charmeleon", "offer carried by evolved %s" % o.id)
	ok(offers[0].id == "danse_flamme" and offers[1].id == "lance_flammes" and offers[2].upgraded, "offer contents")
	# no-evolution path: strip the entry via a fresh run whose base has none
	var r2: RunState = RunState.create_with_starter(gd, "salameche")
	# story 014: the rule follows the CURRENT form; Dracaufeu (stage 3) has no next form
	r2.evolve_starter(gd, 1); r2.evolve_starter(gd, 4)
	var mh: int = r2.max_hp
	var sm2: Dictionary = r2.evolve_starter(gd, 5)
	ok(sm2["evolved"] == false and r2.max_hp == mh + gd.get_evolution_hp_bonus_default() and r2.display_name == "Dracaufeu", "no evo -> default bonus")
	# --- Main: boss -> evolution -> victory ---
	main.start_new_run(4242, "salameche")
	var run: RunState = main.get_run_state()
	main.qa_set_money(123)
	main.qa_give_item("restes")
	main.qa_give_potion("potion")
	main.start_encounter("solo_bidoof", "wild")
	win()
	ok(main.get_current_screen_name() == "reward", "wild -> reward")
	main.reward_skip()
	main.qa_start_boss()
	ok(main.get_current_screen_name() == "battle" and main.get_battle_screen().get_battle().enemies.size() == 3, "champion 3 pokemon")
	var money_before: int = run.money
	win()
	ok(main.get_current_screen_name() == "reward", "gym -> reward (story 012)")
	ok(run.money > money_before, "gym pays loot (story 012)")
	main.reward_skip()
	main.badge_continue()
	ok(main.get_current_screen_name() == "evolution", "badge 1 -> evolution")
	ok(run.display_name == "Reptincel" and main.get_evolution_summary()["evolved"], "evolved in main")
	var es: EvolutionScreen = main.get_evolution_screen()
	ok(es.get_step() == EvolutionScreen.Step.REVEAL and es.get_bonus_text().contains("+15 PV max"), "reveal %s" % es.get_bonus_text())
	main.evolution_pick(0)
	ok(es.get_step() == EvolutionScreen.Step.REVEAL, "pick ignored on reveal")
	main.evolution_continue()
	ok(es.get_step() == EvolutionScreen.Step.CHOOSE, "choose step")
	var deck_n: int = run.deck.size()
	main.evolution_pick(1)
	main.evolution_pick(0)
	ok(run.deck.size() == deck_n + 1 and run.deck[-1].id == "lance_flammes" and run.deck[-1].pokemon_id == "charmeleon", "one card added")
	main.evolution_continue()
	ok(main.get_current_screen_name() == "map" and main.get_zone_index() == 1, "evolution -> zone 2 (story 012)")
	main.qa_set_zone(7)
	main.qa_win_gym()
	main.reward_skip()
	main.badge_continue()
	for _k: int in 12:  # story 013: badge 8 -> league (5 fights + Éthernatos) -> victory
		if main.get_current_screen_name() == "battle": main.qa_win_current_fight()  # story 018: pre-league rival
		if main.get_current_screen_name() == "league": main.qa_win_league_fight()
		if main.get_current_screen_name() == "reward": main.reward_skip()
	ok(main.get_current_screen_name() == "victory", "victory")
	var vs: RunEndScreen = main.get_victory_screen()
	var st: Dictionary = vs.get_stats()
	ok(vs.is_victory() and vs.get_title_text() == "Victoire ! Tu as vaincu Éthernatos", "victory title (story 013: final victory)")
	ok(st["Ennemis battus"] == str(1 + 3 + 3 + 3 + 15 + 1) and run.enemies_defeated == 26, "enemies 4 (%s)" % st)
	ok(st["Combats gagnés"] == "10" and st["Pokédollars"] == RunHud.format_money(run.money), "battles/money %s" % st)
	ok(st["Étages franchis"] == "%d/%d" % [run.floors_climbed(), run.total_floors()], "floors (debug fights do not move) %s" % st)
	ok(String(st["Objets"]).contains("Restes"), "items")
	ok(vs.get_deck_lines().size() == run.get_deck_entries().size(), "deck lines")
	ok(not main.get_hud().visible, "no HUD on victory")
	# --- New run resets everything ---
	main.victory_new_run()
	ok(main.get_current_screen_name() == "starter" and main.get_run_state() == null, "starter, old run dropped")
	# story 013b: a roster Ghost starter is immune to Bidoof's Normal attacks (defeat part below) -> pick a non-Ghost one
	var pick_i: int = 0
	for ci: int in main.get_starter_choices().size():
		if gd.get_primary_type(main.get_starter_choices()[ci]) != "ghost":
			pick_i = ci
			break
	main.starter_choose("salameche") if main.get_starter_choices().has("salameche") else main.starter_choose(pick_i)
	var nr: RunState = main.get_run_state()
	ok(nr != run and not nr.evolution_applied and nr.items.is_empty() and nr.potions.is_empty(), "fresh run")
	ok(nr.money == gd.get_starting_money() and nr.battles_won == 0 and nr.enemies_defeated == 0 and nr.hp == nr.max_hp, "fresh stats")
	ok(nr.deck.size() == gd.build_starter_deck(nr.starter_pokemon_id).size(), "fresh deck")
	ok(main.get_hud().get_money_text().contains(str(gd.get_starting_money())) and main.get_hud().get_item_names().is_empty(), "HUD reset")
	ok(main.get_last_loot().is_empty() and main.get_evolution_summary().is_empty(), "no loot/evolution leak")
	# --- Defeat at 0 HP ---
	main.start_encounter("solo_bidoof")
	ok(main.qa_lose_battle(), "lost")
	ok(nr.hp == 0 and nr.is_defeated(), "run hp 0")
	ok(main.get_current_screen_name() == "battle", "overlay first")
	main.battle_defeat_continue()
	ok(main.get_current_screen_name() == "defeat", "defeat screen")
	var ds: RunEndScreen = main.get_defeat_screen()
	ok(not ds.is_victory() and ds.get_title_text() == "Défaite…" and ds.get_stats()["PV"] == "0/%d" % nr.max_hp, "defeat summary")
	main.defeat_new_run()
	ok(main.get_current_screen_name() == "starter", "defeat -> starter")
	# determinism: same seed -> same choices
	main.start_new_run(777)
	var a: Array[String] = main.get_starter_choices().duplicate()
	main.start_new_run(777)
	ok(a == main.get_starter_choices(), "deterministic")
	print("t13 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
