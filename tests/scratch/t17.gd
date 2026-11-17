extends SceneTree
# Story 013b part B: roster integration.
const SCR := "user://"
var passes := 0
var fails := 0
func ok(c: bool, m: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		printerr("FAIL ", m)
func rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new(); r.seed = s; return r

func _init() -> void:
	var t0 := Time.get_ticks_usec()
	var gd := GameData.new()
	ok(gd.load_all(), "real data loads")
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	print("LOAD TIME ms=", ms)
	ok(ms < 3000.0, "load < 3 s")
	var roster := gd.get_roster_ids()
	ok(roster.size() >= 700, "roster >= 700: %d" % roster.size())
	ok(gd.get_enemy_ids().size() >= 98 + 700, "roster merged into enemies")
	for t: String in gd.get_type_chart().get_type_ids():
		ok(gd.get_roster_wild_count(t) >= 15, "type %s >= 15 roster" % t)
		ok(gd.get_carriers_for_type(t).size() >= 15, "type %s >= 15 carriers" % t)
		for pid: String in gd.get_carriers_for_type(t):
			ok((gd.get_pokemon_info(pid)["types"] as Array).has(t), "carrier %s has %s" % [pid, t])
	# info for roster ids
	var info := gd.get_pokemon_info("clefairy")
	ok(info.get("name") == "Mélofée" and (info["types"] as Array) == ["fairy"] and ResourceLoader.exists(info["sprite_path"]), "info roster id")
	for cid: String in ["vent_feerique", "eclat_magique", "calinerie", "pouvoir_lunaire"]:
		ok(gd.get_card(cid).pokemon_id == "clefairy", "fairy card re-pointed " + cid)
	# zones / encounters
	var species: Dictionary = {}
	var gens: Dictionary = {}
	var tiers: Array = []
	var zr := RandomNumberGenerator.new()
	var cfg := JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/zones.json")) as Dictionary
	var bonus: int = int(cfg["roster_encounters"]["elite_tier_bonus"])
	var zones := gd.draw_zones(rng(3))
	var roster_fights := 0
	var fixed_fights := 0
	for zi: int in 8:
		var zone: Dictionary = zones[zi].duplicate(true)
		var tw: Dictionary = cfg["tiers"][zi]["roster"]["tier_weights"]
		for room: String in ["wild", "elite"]:
			var allowed: Dictionary = {}
			for k: String in tw.keys():
				allowed[mini(3, int(k) + (bonus if room == "elite" else 0))] = true
			var sizes: Dictionary = {}
			var r := rng(1000 + zi)
			for f: int in 500:
				var enc := gd.pick_encounter(room, 5, r, zone)
				var ids := gd.get_encounter_enemy_ids(enc)
				ok(not ids.is_empty(), "encounter resolves " + enc)
				if gd.is_roster_encounter(enc):
					roster_fights += 1
					sizes[ids.size()] = true
					var uniq: Dictionary = {}
					for id: String in ids:
						uniq[id] = true
						species[id] = true
						var e := gd.get_roster_entry(id)
						gens[int(e["generation"])] = true
						if not allowed.has(int(e["tier"])):
							ok(false, "zone %d %s tier %d not in %s (%s)" % [zi + 1, room, int(e["tier"]), str(allowed.keys()), id])
						else:
							passes += 1
					ok(uniq.size() == ids.size(), "no duplicate species")
					var mods := gd.get_fight_modifiers(room, zone)
					var cs := gd.create_enemies(enc, float(mods["hp_multiplier"]), int(mods["strength_bonus"]))
					ok(cs.size() == ids.size(), "combatants built")
					if f == 0:
						var raw: int = int(gd.get_roster_entry(ids[0])["max_hp"])
						ok(cs[0].max_hp == maxi(1, ceili(snappedf(raw * float(mods["hp_multiplier"]), 0.0001))) and cs[0].strength == int(mods["strength_bonus"]), "modifiers apply to roster combatants")
				else:
					fixed_fights += 1
			if room == "wild" and zi >= 5:
				ok(sizes.has(3), "late zone has trios")
	print("distinct species=", species.size(), " generations=", gens.keys(), " roster fights=", roster_fights, " fixed=", fixed_fights)
	ok(species.size() >= 150, ">= 150 distinct species: %d" % species.size())
	ok(gens.size() == 9, "all 9 generations")
	ok(fixed_fights > 0 and roster_fights > fixed_fights, "mix of fixed and roster fights")
	# early floors: solo only (zone 1, early pool)
	var z1: Dictionary = zones[0].duplicate(true)
	var r1 := rng(5)
	for f: int in 200:
		var enc := gd.pick_encounter("wild", 1, r1, z1)
		if gd.is_roster_encounter(enc):
			ok(gd.get_encounter_enemy_ids(enc).size() == 1, "early floor roster fight is solo")
	# determinism
	ok(gd.pick_encounter("wild", 5, rng(9), zones[4]) == gd.pick_encounter("wild", 5, rng(9), zones[4]), "deterministic")
	# gyms: every pool type, 3-of-type teams; 8 gyms + 4 free league types over 1000 seeds
	var seen_types: Dictionary = {}
	for s: int in 1000:
		var zs := gd.draw_zones(rng(s))
		ok(zs.size() == 8, "8 zones")
		var gt: Array[String] = []
		for z: Dictionary in zs:
			gt.append(String(z["type_id"]))
			seen_types[z["type_id"]] = true
			var team := gd.get_encounter_enemy_ids(String(z["gym_encounter"]))
			ok(team.size() == 3, "gym team of 3: " + String(z["gym_encounter"]))
			if gd.is_roster_encounter(String(z["gym_encounter"])):
				for id: String in team:
					ok((gd.get_pokemon_info(id)["types"] as Array).has(z["type_id"]), "gym member %s has type %s" % [id, z["type_id"]])
		var u: Dictionary = {}
		for t in gt: u[t] = true
		ok(u.size() == 8, "8 distinct gym types")
		var lg := gd.draw_league(rng(s + 7), gt)
		var lt: Dictionary = {}
		for f: Dictionary in lg:
			if f["kind"] == "member":
				lt[f["type_id"]] = true
				ok(not gt.has(f["type_id"]), "league type not a gym type (seed %d)" % s)
		ok(lt.size() == 4, "4 distinct league types")
	ok(seen_types.size() == gd.get_gym_type_ids().size() and gd.get_gym_type_ids().size() == 18, "every gym pool type drawn (%d/%d)" % [seen_types.size(), gd.get_gym_type_ids().size()])
	ok(seen_types.has("dark"), "dark gym possible")
	# reward carriers varied
	var carriers: Dictionary = {}
	for s: int in 300:
		for o: RewardOffer in RewardGenerator.generate(gd, "salameche", [] as Array[String], rng(s)):
			if o.card.kind == CardData.KIND_ATTACK:
				carriers[o.card.pokemon_id] = true
				ok((gd.get_pokemon_info(o.card.pokemon_id)["types"] as Array).has(o.card.type_id), "carrier type-coherent")
	print("distinct reward carriers=", carriers.size())
	ok(carriers.size() >= 150, "carriers varied: %d" % carriers.size())
	var pool_ids: Array = gd.get_reward_pool("salameche").map(func(c): return c.id)
	for cid in ["calinerie", "blizzard", "close_combat", "ultralaser", "surf", "hantise"]:
		ok(pool_ids.has(cid), "new card in reward pool " + cid)
	# starters
	var rc := 0
	var classic := 0
	var with_evo := 0
	var cands := gd.get_roster_starter_candidates()
	ok(cands.size() >= 150, "roster candidates: %d" % cands.size())
	for s: int in 400:
		var ch := gd.draw_starter_choices(rng(s))
		ok(ch.size() == 3, "3 choices")
		var pt: Dictionary = {}
		for id: String in ch:
			pt[gd.get_primary_type(id)] = true
			if cands.has(id): rc += 1
			else: classic += 1
		ok(pt.size() == 3, "3 different primary types")
	print("starter picks roster=", rc, " classic=", classic)
	ok(rc > 300 and classic > 300, "both pools offered (~50%)")
	for id: String in cands:
		var deck := gd.build_starter_deck(id)
		ok(deck.size() == 11, "11-card deck " + id)
		var pt := gd.get_primary_type(id)
		for c: CardData in deck:
			if c.kind == CardData.KIND_ATTACK:
				ok(c.type_id == pt and c.pokemon_id == id, "deck attack typed & carried " + id)
		var e := gd.get_roster_entry(id)
		var evo := gd.get_evolution(id)
		if e["evolves_to"] != null:
			with_evo += 1
			ok(evo.get("id") == e["evolves_to"] and int(evo["max_hp_bonus"]) > 0 and not (evo["teaches"] as Array).is_empty() and ResourceLoader.exists(String(evo["sprite"])), "evolution " + id)
			ok(not gd.get_pokemon_info(String(evo["id"])).is_empty(), "evolved info " + id)
		else:
			ok(evo.is_empty(), "no evolution -> default bonus " + id)
	print("roster candidates=", cands.size(), " with evolution=", with_evo)
	var run := RunState.create_with_starter(gd, "clefairy")
	ok(run != null and run.deck.size() == 11, "run with roster starter")
	var sum := run.evolve_starter(gd)
	ok(sum.get("to_id") == "clefable" and int(sum["hp_bonus"]) == 20, "clefairy evolves to clefable +20: %s" % str(sum))
	# validation: collision rejected, no crash; empty roster path = no roster
	var rj := JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/roster.json")) as Dictionary
	rj["pokemon"]["rattata"] = rj["pokemon"]["clefairy"]
	var f := FileAccess.open(SCR + "t17_r.json", FileAccess.WRITE); f.store_string(JSON.stringify(rj)); f.close()
	var P := "res://assets/data/"
	ok(not GameData.new().load_all(P + "cards.json", P + "pokemon.json", P + "types.json", P + "rewards.json", P + "act1.json", P + "events.json", P + "items.json", P + "potions.json", P + "shop.json", P + "zones.json", P + "league.json", SCR + "t17_r.json"), "roster collision rejected (error expected)")
	print("t17 passes=", passes, " fails=", fails)
	quit(1 if fails > 0 else 0)
