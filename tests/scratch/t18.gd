extends SceneTree
## Story 014 scratch test: in-run evolutions up to stage 3 (starter at badges 1 / 4, team carriers by battles won).

const SCR := "user://"
const P := "res://assets/data/"
var passes: int = 0
var fails: int = 0


func ok(c: bool, msg: String) -> void:
	if c:
		passes += 1
	else:
		fails += 1
		print("FAIL: ", msg)


func rj(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func load_with(file: String, mut: Callable) -> bool:
	var d: Dictionary = rj(P + file + ".json")
	mut.call(d)
	var f := FileAccess.open(SCR + "t18_" + file + ".json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	var pk: String = SCR + "t18_pokemon.json" if file == "pokemon" else P + "pokemon.json"
	var zn: String = SCR + "t18_zones.json" if file == "zones" else P + "zones.json"
	return GameData.new().load_all(P + "cards.json", pk, P + "types.json", P + "rewards.json", P + "act1.json",
			P + "events.json", P + "items.json", P + "potions.json", P + "shop.json", zn)


func carried(r: RunState, pid: String) -> int:
	var n: int = 0
	for c: CardData in r.deck:
		if c.pokemon_id == pid:
			n += 1
	return n


func _initialize() -> void:
	var gd := GameData.new()
	ok(gd.load_all(), "data loads")
	ok(gd.get_evolution_after_badges() == ([1, 4] as Array[int]), "evolution_after_badges [1, 4]")
	ok(gd.get_team_evolution_battles() == ([4, 9] as Array[int]), "team battles_per_stage")
	# --- data coverage: every starter candidate's line resolves stage 1 -> 2 (-> 3 when the real line has one)
	var pj: Dictionary = rj(P + "pokemon.json")
	var three: int = 0
	for sid: String in pj["starter_candidates"]:
		var e1: Dictionary = gd.get_evolution(sid)
		ok(not e1.is_empty() and not gd.get_pokemon_info(String(e1["id"])).is_empty(), "stage 2 of %s" % sid)
		var e2: Dictionary = gd.get_evolution(String(e1.get("id", "")))
		if not e2.is_empty():
			three += 1
			ok(ResourceLoader.exists(String(e2["sprite"])) and not gd.get_pokemon_info(String(e2["id"])).is_empty(), "stage 3 info of %s" % sid)
			ok(not gd.get_evolution_cards(String(e1["id"])).is_empty(), "stage 3 teaches of %s" % sid)
	ok(three >= 40, "most classic lines reach stage 3 (%d)" % three)
	ok(String(gd.get_evolution("charmeleon").get("id", "")) == "charizard", "Reptincel -> Dracaufeu")
	# --- starter: stage 1->2 at badge 1, 2->3 at badge 4, several lines (classic + roster)
	var lines: Dictionary = {"salameche": ["charmeleon", "charizard"], "bulbasaur": ["ivysaur", "venusaur"],
			"squirtle": ["wartortle", "blastoise"], "nidoran-f": ["nidorina", "nidoqueen"], "machop": ["machoke", "machamp"]}
	for sid: String in lines.keys():
		var r: RunState = RunState.create_with_starter(gd, sid)
		ok(r != null, "run %s" % sid)
		if r == null:
			continue
		var n0: int = r.deck.size()
		var hp0: int = r.max_hp
		var s1: Dictionary = r.evolve_starter(gd, 1)
		ok(s1["evolved"] and r.starter_pokemon_id == lines[sid][0] and r.evolution_stage == 1 and s1["stage"] == 1, "%s stage 2 at badge 1" % sid)
		ok(carried(r, sid) == 0 and carried(r, lines[sid][0]) > 0 and r.deck.size() == n0, "%s deck re-carried" % sid)
		ok(r.max_hp == hp0 + int(s1["hp_bonus"]) and int(s1["hp_bonus"]) > 0, "%s hp bonus 1" % sid)
		ok(r.evolve_starter(gd, 1).is_empty(), "%s same badge twice = nothing" % sid)
		var offers: Array[CardData] = EvolutionOffer.generate(gd, r, s1)
		ok(offers.size() >= 3, "%s 3 offers at stage 2 (%d)" % [sid, offers.size()])
		var s2: Dictionary = r.evolve_starter(gd, 4)
		ok(s2["evolved"] and r.starter_pokemon_id == lines[sid][1] and r.evolution_stage == 2, "%s stage 3 at badge 4 (%s)" % [sid, r.starter_pokemon_id])
		ok(carried(r, lines[sid][0]) == 0 and carried(r, lines[sid][1]) > 0, "%s deck re-carried to stage 3" % sid)
		var offers2: Array[CardData] = EvolutionOffer.generate(gd, r, s2)
		ok(offers2.size() >= 2 and offers2[0].pokemon_id == lines[sid][1], "%s offers at stage 3" % sid)
		ok(r.get_summary()["pokemon_id"] == lines[sid][1] and r.evolution_history.size() == 2, "%s summary final form" % sid)
		# --- a third step: no next form -> +HP default AND one card upgraded
		var mh: int = r.max_hp
		var ups: int = 0
		for c: CardData in r.deck: ups += 1 if c.upgraded else 0
		var s3: Dictionary = r.evolve_starter(gd, 7)
		var ups2: int = 0
		for c: CardData in r.deck: ups2 += 1 if c.upgraded else 0
		ok(not s3["evolved"] and r.max_hp == mh + gd.get_evolution_hp_bonus_default() and ups2 == ups + 1 and not String(s3["upgraded_card"]).is_empty(), "%s no next form -> HP + 1 card upgraded" % sid)
		ok(EvolutionOffer.generate(gd, r, s3).is_empty(), "%s no card choice without evolution" % sid)
	# a 2-stage line: Pikachu -> Raichu at badge 1, then badge 4 = il se renforce
	var rp: RunState = RunState.create_with_starter(gd, "pikachu")
	rp.evolve_starter(gd, 1)
	var sp: Dictionary = rp.evolve_starter(gd, 4)
	ok(rp.starter_pokemon_id == "raichu" and not sp["evolved"] and sp["upgraded_card"] != "", "Raichu se renforce at badge 4")
	# --- team carriers: same rule for any id, by battles won since entering the deck
	var r: RunState = RunState.create_with_starter(gd, "salameche")
	var card: CardData = gd.get_card("vive_attaque")
	r.add_card(card.with_pokemon("nidoran-m"))
	r.add_card(card.with_pokemon("pidgey"))
	r.add_card(card.with_pokemon("ditto"))
	ok(r.team_carriers() == (["nidoran-m", "pidgey", "ditto"] as Array[String]), "team carriers")
	for i: int in 3: r.track_team_win()
	ok(r.pending_team_evolutions(gd).is_empty() and r.evolve_team(gd).is_empty(), "nothing before 4 wins")
	r.add_card(card.with_pokemon("caterpie"))  # enters late: counts from now
	r.track_team_win()
	var hp1: int = r.max_hp
	var rows: Array[Dictionary] = r.evolve_team(gd)
	var ids: Array = rows.map(func(x: Dictionary) -> String: return String(x["to_id"]))
	ok(ids == ["nidorino", "pidgeotto"], "4 wins: stage 2 rows (%s)" % str(ids))
	ok(carried(r, "nidorino") == 1 and carried(r, "nidoran-m") == 0 and carried(r, "pidgeotto") == 1 and carried(r, "ditto") == 1 and carried(r, "caterpie") == 1, "team deck re-carried")
	ok(r.max_hp == hp1 + 2 * gd.get_team_evolution_bonus_hp(), "team hp bonus")
	ok(r.evolve_team(gd).is_empty(), "no double evolution")
	for i: int in 4: r.track_team_win()
	ok(r.evolve_team(gd).map(func(x: Dictionary) -> String: return String(x["to_id"])) == ["metapod"], "caterpie after its own 4 wins")
	for i: int in 1: r.track_team_win()
	rows = r.evolve_team(gd)
	ok(rows.map(func(x: Dictionary) -> String: return String(x["to_id"])) == ["nidoking", "pidgeot"], "9 wins: stage 3 (%s)" % str(rows.map(func(x: Dictionary) -> String: return String(x["to_id"]))))
	ok(rows[0]["stage"] == 2 and carried(r, "nidoking") == 1, "stage 3 carried")
	for i: int in 20: r.track_team_win()
	var after: Array = r.evolve_team(gd).map(func(x: Dictionary) -> String: return String(x["to_id"]))
	ok(after == ["butterfree"], "only metapod left to evolve (%s)" % str(after))
	ok(r.starter_pokemon_id == "salameche", "team evolutions never touch the starter")
	# determinism: same inputs -> same rows
	var a1: RunState = RunState.create_with_starter(gd, "squirtle")
	var a2: RunState = RunState.create_with_starter(gd, "squirtle")
	for rr: RunState in [a1, a2]:
		rr.add_card(card.with_pokemon("machop"))
		for i: int in 9: rr.track_team_win()
	ok(str(a1.evolve_team(gd)) == str(a2.evolve_team(gd)) and a1.deck.map(func(c: CardData) -> String: return c.deck_key()) == a2.deck.map(func(c: CardData) -> String: return c.deck_key()), "deterministic")
	ok(a1.team_progress.has("machamp"), "jump of 2 stages at once when both thresholds passed")
	# --- validation rejections
	ok(not load_with("pokemon", func(d: Dictionary) -> void: d.erase("team_evolution")), "missing team_evolution rejected")
	ok(not load_with("pokemon", func(d: Dictionary) -> void: d["team_evolution"]["battles_per_stage"] = [9, 4]), "decreasing battles rejected")
	ok(not load_with("pokemon", func(d: Dictionary) -> void: d["team_evolution"]["bonus_hp"] = -1), "negative bonus rejected")
	ok(not load_with("pokemon", func(d: Dictionary) -> void: d["evolutions"]["zzz_form"] = d["evolutions"]["salameche"].duplicate()), "unknown base rejected")
	ok(not load_with("pokemon", func(d: Dictionary) -> void: d["evolutions"]["charmeleon"]["id"] = "ivysaur"), "duplicate evolved id rejected")
	ok(load_with("pokemon", func(d: Dictionary) -> void: pass), "unchanged pokemon loads")
	ok(not load_with("zones", func(d: Dictionary) -> void: d["evolution_after_badges"] = [1, 1]), "duplicate badge rejected")
	# --- Main flow + new-run reset
	var main: Main = (load("res://src/main.tscn") as PackedScene).instantiate() as Main
	root.add_child(main)
	_flow.call_deferred(main, card)


func _flow(main: Main, card: CardData) -> void:
	main.start_new_run(42, "salameche")
	main.qa_win_gym(); main.reward_skip()
	if main.get_current_screen_name() == "evolution": main.evolution_continue()
	main.badge_continue()
	ok(main.get_current_screen_name() == "evolution" and main.get_run_state().starter_pokemon_id == "charmeleon", "badge 1 -> Reptincel")
	main.evolution_continue(); main.evolution_pick(0); main.evolution_continue()
	ok(main.get_current_screen_name() == "map", "-> map")
	main.qa_show_starter_evolution(4)
	ok(main.get_run_state().starter_pokemon_id == "charizard" and main.get_evolution_screen().get_offers().size() >= 2, "badge 4 -> Dracaufeu with offers")
	main.get_run_state().add_card(card.with_pokemon("pidgey"))
	main.qa_win_battles(4)
	ok(main.qa_check_team_evolution() and main.get_team_evolution_rows().size() == 1 and main.get_evolution_screen().is_team_mode(), "team summary screen")
	main.evolution_continue()
	ok(main.get_current_screen_name() == "map", "team summary -> map")
	main.start_new_run(42, "salameche")
	var nr: RunState = main.get_run_state()
	ok(nr.evolution_stage == 0 and nr.evolution_history.is_empty() and nr.team_progress.is_empty() and nr.starter_pokemon_id == "salameche" and main.get_team_evolution_rows().is_empty(), "new run reset")
	print("t18 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
