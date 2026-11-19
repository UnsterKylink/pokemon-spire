extends SceneTree
## Story 025 scratch: Pokedex persistence (save / load, broken file, bad rows), the catalog (Total = 893 species,
## generations 1-9, dex numbers), the milestones (unlock, starter choice count, rewards applied to a NEW RunState only),
## Main's hooks through a scripted mini-run (starter seen + caught, enemies seen at battle start, capture, evolution,
## milestone banner, rewards on the next run, Pokédex off by default) and the Pokédex screen from the title screen
## (counters, filters, detail, milestones, Échap). Scratch files only.
const DEX_PATH: String = "user://t25b_pokedex.json"
const SAVE_PATH: String = "user://t25b_save.json"
const STATS_PATH: String = "user://t25b_stats.json"
## Size of the species list with the current data (pokemon.json + roster.json merged by sprite slug).
const EXPECTED_TOTAL: int = 893
var passes: int = 0
var fails: int = 0


func ok(c: bool, msg: String) -> void:
	if c:
		passes += 1
	else:
		fails += 1
		print("FAIL ", msg)


func _initialize() -> void:
	_clean()
	_check_persistence()
	var data := GameData.new()
	ok(data.load_all(), "data loads")
	var catalog: PokedexCatalog = PokedexCatalog.build(data)
	_check_catalog(data, catalog)
	_check_rewards(data, catalog)
	await _check_main(catalog)
	_clean()
	print("t25b_pokedex: %d pass, %d fail" % [passes, fails])
	quit(1 if fails > 0 else 0)


func _clean() -> void:
	for p: String in [DEX_PATH, DEX_PATH + ".tmp", SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp", STATS_PATH,
			STATS_PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _check_persistence() -> void:
	var p: Pokedex = Pokedex.load_from(DEX_PATH)
	ok(p.seen.is_empty() and p.caught.is_empty() and p.milestones_claimed.is_empty(), "missing file = empty Pokédex")
	p.mark_seen("rattata")
	p.mark_seen("rattata")
	p.mark_caught("pidgey")
	p.mark_seen("")
	ok(p.seen_count("rattata") == 2 and p.is_seen("pidgey") and p.is_caught("pidgey") and not p.is_caught("rattata"),
			"seen / caught counts: %s" % [p.to_dict()])
	ok(p.seen_total() == 2 and p.caught_total() == 1, "totals 2 / 1")
	ok(p.seen_total(PackedStringArray(["rattata"])) == 1, "totals restricted to a catalog")
	p.milestones_claimed.append("dex_10")
	ok(p.save() and not FileAccess.file_exists(DEX_PATH + ".tmp"), "atomic save (no temp file left)")
	var r: Pokedex = Pokedex.load_from(DEX_PATH)
	ok(r.seen_count("rattata") == 2 and r.caught_count("pidgey") == 1 and r.milestones_claimed.size() == 1 and r.milestones_claimed[0] == "dex_10",
			"reload: %s" % [r.to_dict()])
	var f: FileAccess = FileAccess.open(DEX_PATH, FileAccess.WRITE)
	f.store_string("{broken")
	f.close()
	ok(Pokedex.load_from(DEX_PATH).seen.is_empty(), "broken file = empty Pokédex")
	f = FileAccess.open(DEX_PATH, FileAccess.WRITE)
	f.store_string('{"seen": {"a": 2, "b": -1, "c": "x"}, "caught": [1], "milestones_claimed": ["m", 3, "m"]}')
	f.close()
	var bad: Pokedex = Pokedex.load_from(DEX_PATH)
	ok(bad.seen == {"a": 2} and bad.caught.is_empty() and bad.milestones_claimed.size() == 1 and bad.milestones_claimed[0] == "m", "bad rows skipped: %s" % [bad.to_dict()])
	DirAccess.remove_absolute(DEX_PATH)


func _check_catalog(data: GameData, catalog: PokedexCatalog) -> void:
	ok(catalog.size() == EXPECTED_TOTAL, "Total = %d species (got %d)" % [EXPECTED_TOTAL, catalog.size()])
	var gens: Dictionary = {}
	var prev: int = 0
	var ordered: bool = true
	var no_card: int = 0
	for e: Dictionary in catalog.entries:
		gens[int(e["generation"])] = int(gens.get(int(e["generation"]), 0)) + 1
		ordered = ordered and int(e["dex"]) >= prev
		prev = int(e["dex"])
		no_card += 1 if (e["teaches"] as Array).is_empty() else 0
	ok(gens.size() == 9 and gens.has(1) and gens.has(9), "generations 1-9 all present: %s" % [gens])
	ok(ordered, "entries in dex order")
	ok(no_card == 0, "every species teaches at least one card (%d without)" % no_card)
	var ch: Dictionary = catalog.get_entry("charmander")
	ok(int(ch.get("dex", 0)) == 4 and int(ch.get("generation", 0)) == 1 and (ch.get("ids", []) as Array).has("salameche"),
			"charmander = N° 4 gen 1, carried by player id salameche: %s" % [ch])
	ok(int(catalog.get_entry("charizard").get("dex", 0)) == 6, "roster dex used (charizard N° 6)")
	ok(int(catalog.get_entry("eternatus").get("generation", 0)) == 8, "final boss is in the Pokédex (gen 8)")
	var fire1: Array[Dictionary] = catalog.filtered(1, "fire", "all", null)
	var all_fire: bool = not fire1.is_empty()
	for e: Dictionary in fire1:
		all_fire = all_fire and (e["types"] as Array).has("fire") and int(e["generation"]) == 1
	ok(all_fire, "type + generation filter (%d gen-1 fire)" % fire1.size())
	var dex := Pokedex.new()
	dex.mark_seen("charmander")
	dex.mark_caught("bulbasaur")
	ok(catalog.filtered(1, "", "caught", dex).size() == 1 and catalog.filtered(1, "", "seen", dex).size() == 2,
			"status filters (caught 1, seen 2)")
	ok(data.get_evolved_form_ids().has("charmeleon"), "evolved forms listed")


func _check_rewards(data: GameData, catalog: PokedexCatalog) -> void:
	var rw: PokedexRewards = PokedexRewards.load_from()
	ok(rw.milestones.size() >= 4, "milestones loaded (%d)" % rw.milestones.size())
	ok(rw.unlocked(0).is_empty() and rw.unlocked(10).size() == 1 and rw.unlocked(9999).size() == rw.milestones.size(), "unlock thresholds")
	ok(rw.starter_choice_count(3, 0) == 3 and rw.starter_choice_count(3, 25) == 4, "extra starter choice at 25")
	ok(rw.newly_unlocked(25, ["dex_10"] as Array[String]).size() == 1, "newly unlocked skips claimed ones")
	var base: RunState = RunState.create_with_starter(data, "salameche")
	var boosted: RunState = RunState.create_with_starter(data, "salameche")
	ok(rw.apply_to_run(base, 0).is_empty(), "no milestone: nothing applied")
	var names: Array[String] = rw.apply_to_run(boosted, 9999)
	var upgraded: int = 0
	for c: CardData in boosted.deck:
		upgraded += 1 if c.upgraded else 0
	ok(names.size() == rw.milestones.size() - 1, "every run-start milestone applied (the starter-choice one is read before the run): %s" % [names])
	ok(boosted.ball_count("poke_ball") == base.ball_count("poke_ball") + 1, "+1 Poké Ball")
	ok(boosted.money == base.money + 25, "+25 money (%d vs %d)" % [boosted.money, base.money])
	ok(boosted.max_hp == base.max_hp + 5 and boosted.hp == boosted.max_hp, "+5 max HP")
	ok(upgraded == 1, "one starter card upgraded (%d)" % upgraded)
	ok(catalog.size() > 150, "the last milestone is reachable (catalog %d)" % catalog.size())


func _check_main(catalog: PokedexCatalog) -> void:
	var m: Main = (load("res://src/main.tscn") as PackedScene).instantiate() as Main
	root.add_child(m)
	await process_frame
	ok(not m.pokedex_enabled() and m.starter_choice_count() == 3, "QA Main: Pokédex off by default")
	m.start_new_run(4242, "salameche")
	ok(m.get_pokedex().seen.is_empty() and not FileAccess.file_exists(DEX_PATH), "Pokédex off: nothing recorded")
	# Opt in with a scratch file, seeded with 9 caught species (one below the first milestone).
	var seed := Pokedex.new()
	seed.path = DEX_PATH
	var slugs: PackedStringArray = catalog.slugs()
	for i: int in 9:
		seed.mark_caught(slugs[100 + i])
	seed.save()
	m.qa_set_save_path(SAVE_PATH)
	m.qa_set_stats_path(STATS_PATH)
	m.qa_set_pokedex_path(DEX_PATH)
	ok(m.pokedex_enabled() and m.get_pokedex().caught_total() == 9, "opt-in loads the scratch Pokédex")
	m.start_new_run(4242, "salameche")
	await process_frame
	var dex: Pokedex = Pokedex.load_from(DEX_PATH)
	ok(dex.is_caught("charmander") and dex.caught_total() == 10, "starter counted caught (and saved): %d" % dex.caught_total())
	ok(m.get_pokedex().milestones_claimed.has("dex_10"), "10 caught -> milestone dex_10 claimed")
	ok(m.get_pokedex_banner().get_texts().size() == 2 and m.get_pokedex_banner().get_texts()[0].contains("Palier du Pokédex débloqué"),
			"banner shown: %s" % [m.get_pokedex_banner().get_texts()])
	ok(m.get_run_state().ball_count("poke_ball") == 0, "milestone reached during a run does not change that run")
	m.start_encounter("solo")
	await process_frame
	var battle: Battle = m.get_battle_screen().get_battle()
	var enemy_slug: String = Pokedex.slug_of(battle.enemies[0].sprite_path)
	ok(m.get_pokedex().seen_count(enemy_slug) >= 1 and Pokedex.load_from(DEX_PATH).is_seen(enemy_slug), "enemy seen at battle start (%s)" % enemy_slug)
	var before: int = m.get_pokedex().caught_count("rattata")
	m.get_run_state().apply_captures(["rattata"] as Array[String])
	ok(m.get_pokedex().caught_count("rattata") == before + 1, "capture recorded")
	m.qa_set_evolution_stage(1)
	ok(m.get_pokedex().is_seen("charmeleon"), "evolved form seen")
	# Next run: the dex_10 reward (+1 Poké Ball) applies.
	m.start_new_run(4243, "salameche")
	await process_frame
	ok(m.get_run_state().ball_count("poke_ball") == 1, "new run gets the milestone ball (%d)" % m.get_run_state().ball_count("poke_ball"))
	# 25 caught -> 4 starters proposed.
	var d2: Pokedex = Pokedex.load_from(DEX_PATH)
	for i: int in 30:
		d2.mark_caught(slugs[300 + i])
	d2.save()
	m.qa_set_pokedex_path(DEX_PATH)
	ok(m.starter_choice_count() == 4, "25+ caught -> 4 starter choices")
	m.start_new_run(4244)
	await process_frame
	ok(m.get_starter_choices().size() == 4, "starter screen proposes 4 (%d)" % m.get_starter_choices().size())
	# Title -> Pokédex screen.
	m.qa_enable_title_screen(true)
	m.qa_quit_to_title()
	await process_frame
	m.get_title_screen().press_pokedex()
	await process_frame
	var ps: PokedexScreen = m.get_pokedex_screen()
	ok(m.get_current_screen_name() == "pokedex" and ps != null, "title « Pokédex » opens the screen")
	if ps != null:
		var cur: Pokedex = m.get_pokedex()
		ok(ps.get_counter_text() == "Vus : %d   /   Capturés : %d   /   Total : %d" % [cur.seen_total(slugs), cur.caught_total(slugs), EXPECTED_TOTAL],
				"counters: %s" % ps.get_counter_text())
		ok(ps.get_listed_slugs().size() == catalog.filtered(1, "", "all", null).size(), "gen 1 tab lists gen 1")
		ps.set_type_filter("fire")
		ok(ps.get_listed_slugs().size() == catalog.filtered(1, "fire", "all", null).size(), "type filter applied")
		ps.set_type_filter("")
		ps.set_status_filter("caught")
		ok(ps.get_listed_slugs().has("charmander") and not ps.get_listed_slugs().has("charmeleon"), "caught filter")
		ps.set_status_filter("all")
		ok(ps.open_detail("charmander") and ps.get_detail_slug() == "charmander", "detail opens")
		ps.show_milestones()
		ok(ps.is_milestones_shown(), "milestone list")
		ps.select_generation(9)
		ok(ps.get_listed_slugs().size() == catalog.filtered(9, "", "all", null).size(), "gen 9 tab")
		ok(m.handle_escape(), "Échap handled")
		await process_frame
		await process_frame
		ok(m.get_current_screen_name() == "title", "Échap back to the title (%s)" % m.get_current_screen_name())
	m.queue_free()
	await process_frame
