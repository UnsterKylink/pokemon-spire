extends SceneTree
## Story 013 scratch: Conseil 4, Maître, Éthernatos.
const SCR: String = "user://"
var fails: int = 0
var passes: int = 0
var main: Main

func ok(c: bool, msg: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		print("FAIL ", msg)

func rj(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))

func league_load(mut: Callable, pmut: Callable = Callable()) -> bool:
	var l: Dictionary = rj("res://assets/data/league.json")
	mut.call(l)
	var f := FileAccess.open(SCR + "t16_l.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(l)); f.close()
	var P := "res://assets/data/"
	var ppath: String = P + "pokemon.json"
	if pmut.is_valid():
		var p: Dictionary = rj(ppath)
		pmut.call(p)
		var g := FileAccess.open(SCR + "t16_p.json", FileAccess.WRITE)
		g.store_string(JSON.stringify(p)); g.close()
		ppath = SCR + "t16_p.json"
	return GameData.new().load_all(P + "cards.json", ppath, P + "types.json", P + "rewards.json", P + "act1.json",
			P + "events.json", P + "items.json", P + "potions.json", P + "shop.json", P + "zones.json", SCR + "t16_l.json")

func rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r

func _initialize() -> void:
	main = (load("res://src/main.tscn") as PackedScene).instantiate() as Main
	root.add_child(main)
	_go.call_deferred()

func _go() -> void:
	var gd := GameData.new()
	ok(gd.load_all(), "data loads")
	ok(gd.has_league() and gd.get_league_member_count() == 4 and gd.get_league_fight_count() == 6, "league counts")
	ok(gd.get_league_heal_percent() == 40.0, "heal 40%")
	var pool: Array[String] = gd.get_league_type_pool()
	# 1. member draw: 4 distinct, not among gym types, deterministic
	for s: int in range(1, 201):
		var zs: Array[Dictionary] = gd.draw_zones(rng(s))
		var gyms: Array[String] = []
		for z: Dictionary in zs: gyms.append(String(z["type_id"]))
		var lg: Array[Dictionary] = gd.draw_league(rng(s * 7), gyms)
		var lg2: Array[Dictionary] = gd.draw_league(rng(s * 7), gyms)
		ok(lg.size() == 6 and str(lg) == str(lg2), "6 fights + deterministic seed %d" % s)
		var seen: Dictionary = {}
		for i: int in 4:
			var m: Dictionary = lg[i]
			seen[m["type_id"]] = true
			ok(m["kind"] == "member" and pool.has(m["type_id"]) and not gyms.has(m["type_id"]), "member type ok %s" % m["type_id"])
			for eid: String in gd.get_encounter_enemy_ids(m["encounter"]):
				ok((gd.get_pokemon_info(eid)["types"] as Array).has(m["type_id"]), "team typed %s %s" % [eid, m["type_id"]])
			ok(gd.get_encounter_enemy_ids(m["encounter"]).size() >= 3, "team of 3+")
		ok(seen.size() == 4, "4 distinct member types")
		ok(lg[4]["kind"] == "champion" and lg[4]["type_id"] == "dragon" and lg[5]["kind"] == "final_boss" and lg[5]["name"] == "Éthernatos", "maitre + boss")
	var seen_types: Dictionary = {}
	for s: int in range(1, 60):
		for m: Dictionary in gd.draw_league(rng(s), [] as Array[String]).slice(0, 4): seen_types[m["type_id"]] = true
	ok(seen_types.size() == 6, "all 6 pool types appear over seeds")
	# fallback: gym types cover 4 of the 6 pool types -> 2 free + 2 reused, free ones first
	var fb: Array[Dictionary] = gd.draw_league(rng(3), ["ghost", "ice", "fighting", "psychic"] as Array[String])
	var fbt: Array = fb.slice(0, 4).map(func(m: Dictionary) -> String: return m["type_id"])
	ok(fbt.has("dark") and fbt.has("steel") and fbt.slice(0, 2).has("dark") and fbt.slice(0, 2).has("steel"), "fallback reuses gym types after free ones %s" % str(fbt))
	# 2. Maître Dragon team, Éthernatos stronger, boss flag
	for eid: String in gd.get_encounter_enemy_ids("league_champion"):
		ok((gd.get_pokemon_info(eid)["types"] as Array).has("dragon"), "maitre dragon " + eid)
	var lg0: Array[Dictionary] = gd.draw_league(rng(1), [] as Array[String])
	var cp: Dictionary = gd.get_encounter_power("league_champion", lg0[4]["modifiers"])
	var bp: Dictionary = gd.get_encounter_power("final_eternatus", lg0[5]["modifiers"])
	ok(bp["hp"] > cp["hp"] and bp["max_attack"] > cp["max_attack"], "eternatus > maitre %s %s" % [bp, cp])
	ok(gd.is_boss_pokemon("eternatus") and not gd.is_boss_pokemon("dragonite") and not gd.get_starter_candidates().has("eternatus"), "boss flag")
	ok(str(gd.get_pokemon_info("eternatus")["types"]) == str(["poison", "dragon"]), "eternatus types")
	var tiers_last: Dictionary = (rj("res://assets/data/zones.json")["tiers"] as Array).back()["gym_modifiers"]
	ok(float(lg0[0]["modifiers"]["hp_multiplier"]) > float(tiers_last["hp_multiplier"]), "member 1 > zone 8 gym")
	ok(float(lg0[4]["modifiers"]["hp_multiplier"]) > float(lg0[3]["modifiers"]["hp_multiplier"]), "maitre > members")
	for t: String in ["ghost", "ice", "fighting", "psychic", "steel", "dragon", "dark"]:
		var n: int = 0
		for e: String in gd.get_enemy_ids():
			for c: CardData in gd.get_enemy_teaches(e):
				if c.type_id == t: n += 1
		ok(n >= 2, "type %s has taught attack cards" % t)
	# 3. Main flow: badge 8 -> league -> 5 fights w/ heal -> Éthernatos -> victory
	main.start_new_run(4242, "salameche")
	var run: RunState = main.get_run_state()
	ok(run.league.size() == 6 and run.league_stage == -1 and main.get_league_stage() == -1, "league drawn, not started")
	var gyms_run: Array = run.zones.map(func(z: Dictionary) -> String: return z["type_id"])
	for i: int in 4: ok(not gyms_run.has(run.league[i]["type_id"]), "run member not a gym type")
	main.start_new_run(4242, "salameche")
	ok(str(main.get_run_state().league) == str(run.league), "same --seed same league")
	run = main.get_run_state()
	main.qa_set_zone(7)
	main.qa_win_gym()
	main.reward_skip()
	ok(main.get_current_screen_name() == "badge", "badge 8")
	main.badge_continue()
	if main.get_current_screen_name() == "evolution":  # qa_set_zone grants no badge: badge 8 counts as #1 -> evolution
		main.evolution_continue(); main.evolution_skip(); main.evolution_continue()
	if main.get_current_screen_name() == "battle":  # story 018: the pre-league rival first
		main.qa_win_current_fight(); main.reward_skip()
		for _e: int in 4:
			if main.get_current_screen_name() == "evolution": main.evolution_continue()
	ok(main.get_current_screen_name() == "league" and main.get_league_stage() == 0 and main.is_league_intro() and main.get_last_league_heal() == -1, "badge 8 -> league intro")
	var m0: Dictionary = main.get_league_member()
	ok(m0["index"] == 1 and m0["total"] == 6 and m0["name"] == run.league[0]["name"] and m0["color"] is Color and m0.has("type_name") and m0.has("title"), "member dict %s" % m0)
	for stage: int in 5:
		main.league_continue()
		ok(main.get_current_screen_name() == "battle" and main.get_encounter_id() == run.league[stage]["encounter"], "league fight %d starts" % stage)
		var b: Battle = main.get_battle_screen().get_battle()
		ok(b.enemies.size() == 3 and b.enemies[0].strength >= int(run.league[stage]["modifiers"]["strength_bonus"]), "modifiers applied %d" % stage)
		main.qa_win_league_fight()
		ok(main.get_current_screen_name() == "reward" and main.get_reward_offers().size() == 3, "reward after fight %d" % stage)
		ok(main.get_last_loot().is_empty(), "no loot in league")
		main.qa_set_hp(10)
		main.reward_skip()
		ok(main.get_current_screen_name() == "league" and main.get_league_stage() == stage + 1 and not main.is_league_intro(), "intermission %d" % stage)
		ok(main.get_last_league_heal() == ceili(run.max_hp * 0.4) and run.hp == 10 + main.get_last_league_heal(), "heal 40%% (%d)" % main.get_last_league_heal())
	ok(main.get_league_member()["kind"] == "final_boss" and main.get_league_stage() == 5, "stage 5 = Éthernatos")
	main.league_continue()
	var bb: Battle = main.get_battle_screen().get_battle()
	ok(bb.enemies.size() == 1 and bb.enemies[0].id == "eternatus" and bb.enemies[0].max_hp == 460, "solo Éthernatos")
	main.qa_win_league_fight()
	ok(main.get_current_screen_name() == "victory", "Éthernatos -> victory")
	var sm: Dictionary = run.get_summary()
	ok(sm["eternatus_defeated"] and sm["champion_defeated"] and sm["league_fights_won"] == 6 and sm["league_beaten_names"].size() == 6 and sm["league_total"] == 6 and sm["final_boss_name"] == "Éthernatos", "summary %s" % sm)
	ok(main.get_league_stage() == -1 or main.get_league_stage() == 5, "stage after victory")
	main.victory_new_run()
	main.starter_choose(0)
	var nr: RunState = main.get_run_state()
	ok(nr.league_stage == -1 and nr.league_fights_won == 0 and not nr.final_boss_defeated and nr.league.size() == 6, "reset after victory")
	# 4. defeat mid-league -> defeat + reset
	main.qa_skip_to_league()
	ok(main.get_current_screen_name() == "league" and main.get_league_stage() == 0, "qa_skip_to_league")
	main.qa_win_league_fight(); main.reward_skip()
	main.league_continue()
	ok(main.qa_lose_battle(), "lost league fight 2")
	main.battle_defeat_continue()
	ok(main.get_current_screen_name() == "defeat", "defeat mid-league")
	var ds: Dictionary = main.get_run_state().get_summary()
	ok(ds["league_started"] and ds["league_fights_won"] == 1 and not ds["eternatus_defeated"], "defeat summary league progress")
	main.defeat_new_run()
	main.starter_choose(0)
	nr = main.get_run_state()
	ok(nr.league_stage == -1 and nr.league_fights_won == 0 and nr.zone_index == 0 and nr.badges.is_empty() and main.get_league_stage() == -1, "reset after defeat")
	# defeat vs Éthernatos
	main.qa_set_league_stage(5)
	main.league_continue()
	ok(main.get_encounter_id() == "final_eternatus" and main.qa_lose_battle(), "lose vs Éthernatos")
	main.battle_defeat_continue()
	ok(main.get_current_screen_name() == "defeat", "defeat vs Éthernatos")
	# 5. validation rejections
	ok(league_load(func(_l): pass), "unmodified copy loads")
	ok(not league_load(func(l): l["member_count"] = 7), "pool < member_count")
	ok(not league_load(func(l): l["member_type_pool"].append("zzz")), "unknown type")
	ok(not league_load(func(l): l["member_type_pool"].append("ghost")), "duplicate type")
	ok(not league_load(func(l): l["members_by_type"].erase("ice")), "missing member")
	ok(not league_load(func(l): l["members_by_type"]["ice"]["encounter"] = "league_ghost"), "team not of the type")
	ok(not league_load(func(l): l["members_by_type"]["ice"]["encounter"] = "nope"), "unknown encounter")
	ok(not league_load(func(l): l["members_by_type"]["ice"]["name"] = ""), "empty name")
	ok(not league_load(func(l): l["member_modifiers"].pop_back()), "modifiers count")
	ok(not league_load(func(l): l["member_modifiers"][0] = {"hp_multiplier": 2.0, "strength_bonus": 3}), "member 1 not above gym 8")
	ok(not league_load(func(l): l["member_modifiers"][2]["hp_multiplier"] = 1.0), "decreasing members")
	ok(not league_load(func(l): l["member_modifiers"][1]["strength_bonus"] = -1), "negative strength")
	ok(not league_load(func(l): l["champion"]["modifiers"] = {"hp_multiplier": 2.4, "strength_bonus": 4}), "maitre not above members")
	ok(not league_load(func(l): l["champion"]["type"] = "fire"), "maitre team not of its type")
	ok(not league_load(func(l): l["final_boss"]["encounter"] = "league_champion"), "boss not solo")
	ok(not league_load(func(l): l["final_boss"]["modifiers"]["hp_multiplier"] = 0.5), "boss weaker than maitre")
	ok(not league_load(func(_l): pass, func(p): p["enemies"]["eternatus"].erase("boss")), "boss flag required")
	ok(not league_load(func(_l): pass, func(p): p["starter_candidates"].append("eternatus")), "boss as starter rejected")
	ok(not league_load(func(l): l["heal_percent_between_fights"] = 120), "heal > 100")
	ok(not league_load(func(l): l.erase("heal_percent_between_fights")), "heal missing")
	ok(not league_load(func(l): l["reward_rarity_weights"] = {"mythic": 3}), "bad weights")
	ok(not league_load(func(l): l.erase("champion")), "champion missing")
	print("t16 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
