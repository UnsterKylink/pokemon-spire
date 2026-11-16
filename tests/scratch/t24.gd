extends SceneTree
## Story 018 scratch: rival (placement, counter-type starter, team growth + evolution, modifiers, rewards), new events (count,
## zone filter, effects), legendary events (once per run, from zone 3, fight, unique card, capture chance, exclusions),
## AoE / heal cards, save round trip, determinism, validation rejections, Main flow (rival room + pre-league rival).
const SCR := "/tmp/claude-0/-home-user-pokemon-spire/a2b72075-2d8b-51e2-a914-9e4b612c161d/scratchpad/"
const D := "res://assets/data/"
var fails: int = 0
var passes: int = 0
var gd: GameData

func ok(c: bool, msg: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		print("FAIL ", msg)

func wr(name: String, d: Dictionary) -> String:
	var f := FileAccess.open(SCR + name, FileAccess.WRITE)
	f.store_string(JSON.stringify(d)); f.close()
	return SCR + name

func rd(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary

func load_with(over: Dictionary) -> bool:
	var names := ["cards", "pokemon", "types", "rewards", "act1", "events", "items", "potions", "shop", "zones", "league", "roster", "statuses", "balls", "rival"]
	var paths: Array = []
	for n in names:
		paths.append(over.get(n, D + n + ".json"))
	return GameData.new().callv("load_all", paths)

func rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r

func new_run(starter: String = "salameche", seed_v: int = 3) -> RunState:
	var r := RunState.create_with_starter(gd, starter)
	r.set_zones(gd.draw_zones(rng(seed_v)))
	r.init_rival(gd, rng(seed_v + 1))
	return r

func _initialize() -> void:
	gd = GameData.new()
	ok(gd.load_all(), "data loads")
	var chart: TypeChart = gd.get_type_chart()
	# --- 1. placement
	for z: int in range(1, 9):
		var cfg: Dictionary = gd.get_zone_act_config(z)
		var has_rival: bool = (cfg["placement"]["forced_floors"] as Dictionary).values().has("rival")
		ok(has_rival == (z in [2, 4, 6]), "zone %d rival floor = %s" % [z, has_rival])
		var g: MapGraph = MapGenerator.generate(cfg, 100 + z)
		var n_rival: int = 0
		for n: MapNode in g.nodes.values():
			if n.room_type == "rival":
				n_rival += 1
				ok(n.floor == 3, "rival on floor 3")
		ok((n_rival > 0) == (z in [2, 4, 6]), "zone %d map rival rooms %d" % [z, n_rival])
	var encs: Array[Dictionary] = gd.get_rival_encounters()
	ok(encs.size() == 4, "4 rival encounters")
	ok(String(gd.get_rival_encounter_for_zone(8, "pre_league").get("id", "")) == "rival_final", "pre-league rival in zone 8")
	ok(gd.get_rival_default_name() == "Régis", "default name")
	# --- 2. counter-type starter for each type
	for t: String in chart.get_type_ids():
		var cands: Array[String] = gd.rival_starter_candidates(t)
		ok(not cands.is_empty(), "candidates vs " + t)
		for c: String in cands:
			var types: Array = gd.get_pokemon_info(c)["types"]
			var best: float = 0.0
			for ct: String in types:
				best = maxf(best, chart.damage_multiplier(ct, [t] as Array[String]))
			ok(best > 1.0 and not gd.is_legendary_pokemon(c) and gd.get_roster_entry(c)["stage"] == 1, "%s counters %s" % [c, t])
		var a: String = gd.draw_rival_starter(t, rng(7))
		ok(a == gd.draw_rival_starter(t, rng(7)) and cands.has(a), "deterministic draw " + t)
		# lead attack super effective vs t
		ok(chart.damage_multiplier(String(gd.get_pokemon_info(a)["types"][0]), [t] as Array[String]) > 1.0, "lead primary SE vs " + t)
	var run := new_run()
	ok(run.rival_name == "Régis" and not run.rival_starter_id.is_empty(), "init_rival")
	var water_like: float = chart.damage_multiplier(String(gd.get_pokemon_info(run.rival_starter_id)["types"][0]), ["fire"] as Array[String])
	ok(water_like > 1.0, "rival vs Salamèche has advantage")
	# --- 3. team growth + evolution
	var base: String = run.rival_starter_id
	ok(gd.rival_form_at(base, 0) == base, "stage 1 before badge 1")
	var f1: String = gd.rival_form_at(base, 1)
	var f4: String = gd.rival_form_at(base, 4)
	ok(gd.get_evolution(base).is_empty() or f1 == String(gd.get_evolution(base)["id"]), "evolves at badge 1")
	ok(gd.get_evolution(f1).is_empty() or f4 == String(gd.get_evolution(f1)["id"]), "evolves again at badge 4")
	ok(gd.rival_form_at(base, 3) == f1, "badge 3 = stage 2")
	var sizes: Dictionary = {}
	for s: int in 40:
		for e: Dictionary in encs:
			var badges: int = int(e["zone"]) - 1
			var id: String = gd.build_rival_team(e, base, badges, rng(s), [] as Array[String])
			var ids: Array[String] = gd.get_encounter_enemy_ids(id)
			ok(not ids.is_empty() and ids[0] == gd.rival_form_at(base, badges), "lead form %s" % e["id"])
			var k: String = String(e["id"])
			if not sizes.has(k): sizes[k] = {}
			sizes[k][ids.size()] = true
			var uniq: Dictionary = {}
			for x: String in ids:
				uniq[x] = true
				ok(not gd.is_legendary_pokemon(x), "no legendary in rival team")
			ok(uniq.size() == ids.size(), "no duplicate species")
			if k == "rival_final":
				for i: int in range(1, ids.size()):
					ok(int(gd.get_roster_entry(ids[i])["tier"]) == 3, "final mates tier 3")
	ok(sizes["rival_1"].keys().all(func(x): return x in [1, 2]) and sizes["rival_1"].size() == 2, "rival_1 1-2 Pokémon")
	ok(sizes["rival_2"].keys() == [2], "rival_2 = 2")
	ok(sizes["rival_3"].keys() == [3] and sizes["rival_final"].keys() == [3], "rival_3/final = 3")
	ok(gd.build_rival_team(encs[2], base, 5, rng(11)) == gd.build_rival_team(encs[2], base, 5, rng(11)), "team deterministic")
	for e: Dictionary in encs:
		var zone: Dictionary = run.zones[int(e["zone"]) - 1]
		var rm: Dictionary = gd.get_rival_fight_modifiers(e, zone)
		var em: Dictionary = gd.get_fight_modifiers("elite", zone)
		ok(float(rm["hp_multiplier"]) > float(em["hp_multiplier"]) - 0.0001 and int(rm["strength_bonus"]) >= int(em["strength_bonus"])
, "never weaker than elite " + String(e["id"]))
	# --- 4. rival fights + rewards
	run.zone_index = 1
	run.badges.append({"id": "b", "name": "B", "index": 1, "zone_index": 0, "type_id": "rock", "leader": "x"})
	var fight: Dictionary = SpecialFights.rival_room_fight(gd, run, rng(5))
	ok(not fight.is_empty() and fight["room"] == "rival" and String(fight["rival_def"]["id"]) == "rival_1", "rival room fight zone 2")
	ok((fight["enemies"] as Array).size() >= 1 and (fight["enemies"][0] as Combatant).id == gd.rival_form_at(base, 1), "lead evolved form in zone 2")
	var money0: int = run.money
	var loot: Dictionary = SpecialFights.apply_rival_win(gd, run, fight["rival_def"], rng(6))
	ok(run.money == money0 + int(fight["rival_def"]["reward"]["money"]) and loot["item"] != null and String((loot["item"] as ItemData).rarity) in fight["rival_def"]["reward"]["item_rarities"], "rival reward money + item")
	ok(run.rival_done("rival_1") and SpecialFights.rival_room_fight(gd, run, rng(5)).is_empty(), "rival 1 done once")
	run.zone_index = 2
	ok(SpecialFights.rival_room_fight(gd, run, rng(5)).is_empty(), "no rival room in zone 3")
	run.zone_index = 7
	var fin: Dictionary = SpecialFights.rival_final_fight(gd, run, rng(8))
	ok(not fin.is_empty() and fin["room"] == "rival_final" and (fin["enemies"] as Array).size() == 3, "pre-league rival 3 Pokémon")
	var offers: Array[RewardOffer] = SpecialFights.rival_reward_offers(gd, run, fin["rival_def"], ["rattata"] as Array[String], rng(9))
	ok(offers.size() == 3, "final: 3 card offers")
	for o: RewardOffer in offers:
		ok(o.card.rarity == "rare" and not o.stolen, "final offer rare, not stolen")
	SpecialFights.apply_rival_win(gd, run, fin["rival_def"], rng(10))
	ok(SpecialFights.rival_final_fight(gd, run, rng(8)).is_empty(), "final rival once")
	# --- 5. events
	var evroot: Dictionary = rd(D + "events.json")
	var new_ids: Array[String] = []
	for e: Dictionary in evroot["events"]:
		if not bool(e.get("legendary", false)) and String(e["id"]) not in ["rattata_affame", "source_chaude", "dresseur_curieux", "herbes_hautes", "sac_abandonne", "chercheur_pokemon"]:
			new_ids.append(String(e["id"]))
	ok(new_ids.size() >= 10, ">= 10 new events (%d)" % new_ids.size())
	var types_used: Dictionary = {}
	for e: Dictionary in evroot["events"]:
		ok((e["options"] as Array).size() == 2, "2 options " + String(e["id"]))
		for o: Dictionary in e["options"]:
			for f: Dictionary in o["effects"]:
				types_used[f["type"]] = true
	for t: String in ["apply_status_next_fight", "cure_all", "gamble_money", "upgrade_random_card", "add_card_of_type", "remove_card_choice", "add_item_random", "lose_money", "gain_money", "start_fight", "add_pokemon", "evolve_team_member"]:
		ok(types_used.has(t), "effect used: " + t)
	ok(not gd.get_event_pool_for_zone(1).has("dresseur_echange") and gd.get_event_pool_for_zone(2).has("dresseur_echange"), "min_zone filter")
	ok(gd.get_event_pool_for_zone(6).has("oeuf_mystere") and not gd.get_event_pool_for_zone(7).has("oeuf_mystere"), "max_zone filter")
	ok(gd.get_event_pool_for_zone(1).has("rattata_affame") and gd.get_event_pool_for_zone(8).has("rattata_affame"), "old events everywhere")
	for z: int in range(1, 9):
		ok(gd.get_event_pool_for_zone(z).size() >= 10, "zone %d has >= 10 events" % z)
		for id: String in gd.get_event_pool_for_zone(z):
			ok(not gd.get_legendary_event_ids().has(id), "no legendary in pool")
	var r2 := new_run()
	r2.money = 100
	var s1: String = EventResolver.apply_effects([{"type": "gain_money", "value": 30}, {"type": "lose_money", "value": 500}], r2, gd, rng(1))
	ok(r2.money == 0 and s1.find("-130") >= 0, "gain/lose money floor 0: " + s1)
	r2.money = 100
	EventResolver.apply_effects([{"type": "gamble_money", "stake": 50, "chance": 1.0, "win": 120}], r2, gd, rng(1))
	ok(r2.money == 170, "gamble win")
	EventResolver.apply_effects([{"type": "gamble_money", "stake": 50, "chance": 0.0, "win": 120}], r2, gd, rng(1))
	ok(r2.money == 120, "gamble lose")
	r2.money = 10
	EventResolver.apply_effects([{"type": "gamble_money", "stake": 50, "chance": 1.0, "win": 120}], r2, gd, rng(1))
	ok(r2.money == 10, "gamble unaffordable = nothing")
	ok(not EventResolver.option_available({"requires_money": 50}, r2) and EventResolver.option_available({}, r2), "requires_money")
	EventResolver.apply_effects([{"type": "apply_status_next_fight", "status": "poison", "value": 3}, {"type": "apply_status_next_fight", "status": "poison", "value": 1}], r2, gd, rng(1))
	ok(r2.pending_statuses.size() == 1 and int(r2.pending_statuses[0]["value"]) == 4, "pending status stacks")
	var b: Battle = r2.create_battle(gd.create_enemies("solo"), chart, rng(2))
	ok(b.player.statuses.has("poison") and r2.pending_statuses.is_empty(), "pending status applied to next battle")
	EventResolver.apply_effects([{"type": "apply_status_next_fight", "status": "burn", "value": 2}, {"type": "cure_all"}], r2, gd, rng(1))
	ok(r2.pending_statuses.is_empty(), "cure_all")
	var ups_before: int = r2.deck.filter(func(c): return c.upgraded).size()
	EventResolver.apply_effects([{"type": "upgrade_random_card", "count": 2}], r2, gd, rng(1))
	ok(r2.deck.filter(func(c): return c.upgraded).size() == ups_before + 2, "upgrade 2 cards")
	var n0: int = r2.deck.size()
	EventResolver.apply_effects([{"type": "add_card_of_type", "of_type": "player", "rarity": "rare"}], r2, gd, rng(1))
	ok(r2.deck.size() == n0 + 1 and r2.deck[n0].rarity == "rare" and r2.deck[n0].type_id == "fire", "add_card_of_type player")
	EventResolver.apply_effects([{"type": "remove_card_choice"}], r2, gd, rng(1))
	ok(r2.pending_card_removals == 1 and r2.remove_card_at(0) and r2.deck.size() == n0 and r2.pending_card_removals == 0 and not r2.remove_card_at(0), "remove_card_choice")
	var it0: int = r2.items.size()
	EventResolver.apply_effects([{"type": "add_item_random", "rarities": ["rare"]}], r2, gd, rng(1))
	ok(r2.items.size() == it0 + 1 and r2.items[it0].rarity == "rare", "add_item_random rare")
	EventResolver.apply_effects([{"type": "add_pokemon", "tier": 1}], r2, gd, rng(4))
	ok(r2.captured.size() == 1 and gd.get_roster_entry(r2.captured[0])["stage"] == 1 and r2.team_carriers().has(r2.captured[0]), "add_pokemon joins team")
	var egg: String = r2.captured[0]
	var ev_s: String = EventResolver.apply_effects([{"type": "evolve_team_member"}], r2, gd, rng(1))
	ok(gd.get_evolution(egg).is_empty() or (not r2.team_carriers().has(egg) and r2.team_carriers().has(String(gd.get_evolution(egg)["id"]))), "evolve_team_member: " + ev_s)
	EventResolver.apply_effects([{"type": "start_fight", "source": "rival_starter", "room": "elite", "modifiers": {"hp_multiplier": 1.0, "strength_bonus": 0}}], r2, gd, rng(1))
	ok(not r2.pending_fight.is_empty(), "start_fight queued")
	var duel: Dictionary = SpecialFights.event_fight(gd, r2, rng(1))
	ok(r2.pending_fight.is_empty() and (duel["enemies"] as Array).size() == 1 and (duel["enemies"][0] as Combatant).id == r2.rival_current_form(gd) and duel["room"] == "elite", "rival duel")
	var pe: Dictionary = EventResolver.pick_event(gd, rng(1), r2)
	ok(String(pe["text"]).find("{rival}") < 0, "placeholder replaced")
	var prov: Dictionary = EventResolver._personalise(gd.get_event("rival_provocation"), r2)
	ok(String(prov["text"]).begins_with("Régis"), "rival name in text")
	# --- 6. legendary
	var leg_ids: Array[String] = gd.get_legendary_event_ids()
	ok(leg_ids.size() >= 4 and leg_ids.size() <= 6, "4-6 legendary events")
	var hits: int = 0
	var trials: int = 2000
	for s: int in trials:
		var lr := new_run("salameche", 3)
		lr.zone_index = 0 if s % 2 == 0 else 1
		var r := rng(1000 + s)
		for k: int in 8:
			if EventResolver.is_legendary(EventResolver.pick_event(gd, r, lr)):
				hits += 1
	ok(hits == 0, "no legendary in zones 1-2 (%d)" % hits)
	var first: int = 0
	var multi: int = 0
	for s: int in trials:
		var lr := new_run("salameche", 3)
		lr.zone_index = 2 + s % 6
		var r := rng(5000 + s)
		var seen: int = 0
		for k: int in 30:
			var e: Dictionary = EventResolver.pick_event(gd, r, lr)
			if EventResolver.is_legendary(e):
				seen += 1
				if k == 0: first += 1
		if seen > 1: multi += 1
		ok(lr.legendary_seen.size() <= 1, "legendary_seen <= 1")
	ok(multi == 0, "at most 1 legendary per run")
	var rate: float = float(first) / trials
	ok(rate > 0.11 and rate < 0.19, "first-event legendary rate ~15%% (%.3f)" % rate)
	ok(EventResolver.pick_event(gd, rng(77), new_run()) == EventResolver.pick_event(gd, rng(77), new_run()), "pick deterministic")
	for id: String in leg_ids:
		var ev: Dictionary = gd.get_event(id)
		var walk: Dictionary = ev["options"][0]
		ok(walk["effects"].all(func(f): return f["type"] != "start_fight"), "option 0 walks away " + id)
		var lr := new_run()
		lr.zone_index = 4
		EventResolver.apply_effects(ev["options"][1]["effects"], lr, gd, rng(1))
		var lf: Dictionary = SpecialFights.event_fight(gd, lr, rng(1))
		var en: Array = lf["enemies"]
		ok(en.size() == 1 and (en[0] as Combatant).legendary and lf["room"] == "legendary" and lf["capture"] and gd.capture_allowed_in("legendary"), "legendary solo fight " + id)
		var gm: Dictionary = lr.current_zone()["gym_modifiers"]
		ok(float(lf["modifiers"]["hp_multiplier"]) > float(gm["hp_multiplier"]), "legendary scaled above gym " + id)
		var lid: String = String(lf["legendary_id"])
		var n1: int = lr.deck.size()
		var res: Dictionary = SpecialFights.apply_legendary_win(gd, lr, lid, [] as Array[String])
		ok(lr.deck.size() == n1 + 1 and (lr.deck[n1] as CardData).legendary and lr.deck[n1].pokemon_id == lid and not res["captured"], "unique legendary card " + id)
		var n2: int = lr.deck.size()
		SpecialFights.apply_legendary_win(gd, lr, lid, [lid] as Array[String])
		ok(lr.deck.size() == n2, "captured: no duplicate card " + id)
	var dk := new_run()
	EventResolver.apply_effects(gd.get_event("legendaire_darkrai")["options"][1]["effects"], dk, gd, rng(1))
	var dkf: Dictionary = SpecialFights.event_fight(gd, dk, rng(1))
	var dkb: Battle = dk.create_battle(dkf["enemies"], chart, rng(1), true)
	ok(dkb.player.statuses.has("sleep"), "Darkrai: team starts asleep")
	ok(dkb.is_capturable(0), "legendary capturable in its fight")
	# capture chance
	var cr: CaptureRules = gd.get_capture_rules()
	var hyper: BallData = gd.get_ball("hyper_ball")
	var poke: BallData = gd.get_ball("poke_ball")
	ok(cr.chance(hyper, 1, 200, ["sleep"] as Array[String], true) <= 0.15 and cr.chance(hyper, 1, 200, ["sleep"] as Array[String], false) >= 0.9, "legendary best chance <= 15%")
	ok(cr.chance(poke, 200, 200, [] as Array[String], true) < 0.02, "poke ball at full HP < 2%")
	# exclusions
	var leg_pokemon: Array[String] = []
	for pid: String in gd.get_enemy_ids():
		if gd.is_legendary_pokemon(pid): leg_pokemon.append(pid)
	ok(leg_pokemon.size() == 6, "6 legendary Pokémon")
	for t: String in chart.get_type_ids():
		for pid: String in gd.get_carriers_for_type(t):
			ok(not gd.is_legendary_pokemon(pid), "carrier not legendary")
	for pid: String in gd.get_starter_candidates() + gd.get_roster_starter_candidates():
		ok(not gd.is_legendary_pokemon(pid), "starter candidate not legendary")
	for pid: String in leg_pokemon:
		ok(gd.get_roster_entry(pid).is_empty(), "not in roster (wild) " + pid)
	var act: Dictionary = gd.get_act_config()
	for pool: String in act["encounter_pools"].keys():
		for entry: Dictionary in act["encounter_pools"][pool]:
			for eid: String in gd.get_encounter_enemy_ids(String(entry["encounter"])):
				ok(not gd.is_legendary_pokemon(eid), "pool %s no legendary" % pool)
	for s: int in 200:
		for pid: String in gd.draw_starter_choices(rng(s), 3):
			ok(not gd.is_legendary_pokemon(pid), "starter draw not legendary")
		var zs: Array[Dictionary] = gd.draw_zones(rng(s))
		for z: Dictionary in zs:
			for k: int in 3:
				var eid: String = gd.pick_encounter("wild", 4, rng(s * 7 + k), z)
				for x: String in gd.get_encounter_enemy_ids(eid):
					ok(not gd.is_legendary_pokemon(x), "wild draw not legendary")
	for pid: String in ["rattata", "salameche"]:
		pass
	var pool_cards: Array[CardData] = gd.get_reward_pool(gd.get_default_player_id())
	ok(pool_cards.all(func(c): return not c.legendary), "no legendary card in reward pool")
	# --- 7. AoE / heal cards
	var aoe: CardData = gd.get_card("trou_noir")
	var hb_run := new_run()
	hb_run.deck.clear()
	for i: int in 6: hb_run.deck.append(aoe.with_pokemon("darkrai"))
	var hb: Battle = hb_run.create_battle(gd.create_enemies("trio"), chart, rng(3))
	hb.start()
	var hp_before: Array[int] = []
	for e: Combatant in hb.enemies: hp_before.append(e.hp)
	ok(hb.play_card(0, 0), "play Trou Noir")
	var all_hit: bool = true
	for i: int in hb.enemies.size():
		var e: Combatant = hb.enemies[i]
		if e.is_alive() and not (e.hp < hp_before[i] or e.block > 0) : all_hit = false
		if e.is_alive() and not e.statuses.has("sleep"): all_hit = false
	ok(all_hit, "Trou Noir hits + sleeps every enemy")
	var fs: CardData = gd.get_card("feu_sacre")
	ok(fs.heal == 8 and gd.get_card("voile_temporel").heal == 6, "heal fields")
	hb_run.deck.clear()
	for i: int in 6: hb_run.deck.append(fs)
	hb_run.hp = 20
	var hb2: Battle = hb_run.create_battle(gd.create_enemies("solo"), chart, rng(3))
	hb2.start()
	hb2.play_card(0, 0)
	ok(hb2.player.hp == 28, "Feu Sacré heals 8 (%d)" % hb2.player.hp)
	ok(fs.upgraded_copy(gd.get_upgrade_rules()).heal == 8, "upgrade keeps heal")
	# --- 8. save round trip
	var sr := new_run()
	sr.start_act(gd, 42)
	sr.rival_encounters_done.append("rival_1")
	sr.legendary_seen.append("legendaire_lugia")
	sr.add_pending_status("burn", 2)
	sr.rival_name = "Blue"
	var dict: Dictionary = SaveGame.to_dict(sr, {})
	var back: Dictionary = SaveGame.from_dict(JSON.parse_string(JSON.stringify(dict)), gd)
	ok(back["ok"], "save loads: " + String(back.get("error", "")))
	if back["ok"]:
		var lr2: RunState = back["run"]
		ok(lr2.rival_name == "Blue" and lr2.rival_starter_id == sr.rival_starter_id and lr2.rival_encounters_done == sr.rival_encounters_done, "rival saved")
		ok(lr2.legendary_seen == ["legendaire_lugia"] and lr2.pending_statuses.size() == 1 and int(lr2.pending_statuses[0]["value"]) == 2, "legendary/pending saved")
	var old: Dictionary = JSON.parse_string(JSON.stringify(dict))
	for k: String in ["rival_name", "rival_starter_id", "rival_encounters_done", "legendary_seen", "pending_statuses"]:
		old["run"].erase(k)
	var ob: Dictionary = SaveGame.from_dict(old, gd)
	ok(ob["ok"] and (ob["run"] as RunState).rival_starter_id == "" and (ob["run"] as RunState).legendary_seen.is_empty(), "old save loads with defaults")
	var bad: Dictionary = JSON.parse_string(JSON.stringify(dict)); bad["run"]["rival_starter_id"] = "missingno"
	ok(not SaveGame.from_dict(bad, gd)["ok"], "unknown rival rejected")
	var bad2: Dictionary = JSON.parse_string(JSON.stringify(dict)); bad2["run"]["legendary_seen"] = ["nope"]
	ok(not SaveGame.from_dict(bad2, gd)["ok"], "unknown legendary event rejected")
	var bad3: Dictionary = JSON.parse_string(JSON.stringify(dict)); bad3["run"]["pending_statuses"] = [{"id": "x", "value": 1}]
	ok(not SaveGame.from_dict(bad3, gd)["ok"], "unknown pending status rejected")
	# --- 9. validation rejections
	var riv: Dictionary = rd(D + "rival.json")
	var rc: Array = []
	var v1: Dictionary = riv.duplicate(true); v1["counter_types"]["fire"] = ["grass"]; rc.append(["counter not SE", v1])
	var v2: Dictionary = riv.duplicate(true); v2["encounters"][0]["zone"] = 3; rc.append(["room zone without rival floor", v2])
	var v3: Dictionary = riv.duplicate(true); v3["encounters"][0]["modifiers"]["hp_multiplier"] = 0.9; rc.append(["hp < 1", v3])
	var v4: Dictionary = riv.duplicate(true); v4["encounters"][3]["zone"] = 6; rc.append(["pre_league not last zone", v4])
	var v5: Dictionary = riv.duplicate(true); v5["default_name"] = ""; rc.append(["empty name", v5])
	var v6: Dictionary = riv.duplicate(true); v6["encounters"][1]["team_size_weights"] = {"4": 1}; rc.append(["team size 4", v6])
	var v7: Dictionary = riv.duplicate(true); v7["encounters"][2]["teammate_tiers"] = [2]; rc.append(["too few tiers", v7])
	var v8: Dictionary = riv.duplicate(true); v8["encounters"][0]["reward"]["card_rarity_weights"] = {"mythic": 1}; rc.append(["bad rarity", v8])
	var v9: Dictionary = riv.duplicate(true); v9["counter_types"].erase("dragon"); rc.append(["missing type", v9])
	for i: int in rc.size():
		ok(not load_with({"rival": wr("t24_r%d.json" % i, rc[i][1])}), "rival rejects: " + rc[i][0])
	ok(load_with({"rival": wr("t24_rok.json", riv)}), "rival baseline loads")
	var ec: Array = []
	var leg_index: int = -1
	var prov_index: int = -1
	for i: int in evroot["events"].size():
		if evroot["events"][i]["id"] == "legendaire_darkrai": leg_index = i
		if evroot["events"][i]["id"] == "baie_mystere": prov_index = i
	var e1: Dictionary = evroot.duplicate(true); e1["events"][leg_index]["options"][1]["effects"][0]["encounter"] = "solo"; ec.append(["legendary non-legendary encounter", e1])
	var e2: Dictionary = evroot.duplicate(true); e2["events"][prov_index]["options"][0]["effects"][1]["status"] = "confusion"; ec.append(["unknown status", e2])
	var e3: Dictionary = evroot.duplicate(true); e3["events"][prov_index]["options"][0]["effects"] = [{"type": "add_card_of_type", "of_type": "plasma", "rarity": "rare"}]; ec.append(["bad of_type", e3])
	var e4: Dictionary = evroot.duplicate(true); e4["events"][prov_index]["options"][0]["effects"] = [{"type": "start_fight", "source": "encounter", "encounter": "nope", "room": "wild", "modifiers": {"hp_multiplier": 1, "strength_bonus": 0}}]; ec.append(["unknown fight encounter", e4])
	var e5: Dictionary = evroot.duplicate(true); e5["events"][prov_index]["min_zone"] = 5; e5["events"][prov_index]["max_zone"] = 2; ec.append(["min > max zone", e5])
	var e6: Dictionary = evroot.duplicate(true); e6["events"][prov_index]["options"][0]["requires_money"] = 0; ec.append(["requires_money 0", e6])
	var e7: Dictionary = evroot.duplicate(true); e7["legendary"]["chance"] = 1.5; ec.append(["chance > 1", e7])
	var e8: Dictionary = evroot.duplicate(true); e8["events"][prov_index]["options"][0]["effects"] = [{"type": "gamble_money", "stake": 0, "chance": 0.5, "win": 1}]; ec.append(["stake 0", e8])
	var e9: Dictionary = evroot.duplicate(true); e9["events"][leg_index]["options"][0]["effects"] = e9["events"][leg_index]["options"][1]["effects"]; ec.append(["legendary walk-away fights", e9])
	var e10: Dictionary = evroot.duplicate(true); e10["events"][prov_index]["options"][0]["effects"] = [{"type": "add_item_random", "rarities": []}]; ec.append(["empty rarities", e10])
	for i: int in ec.size():
		ok(not load_with({"events": wr("t24_e%d.json" % i, ec[i][1])}), "events rejects: " + ec[i][0])
	var actj: Dictionary = rd(D + "act1.json")
	var a1: Dictionary = actj.duplicate(true); a1["event_pool"].append("legendaire_lugia")
	ok(not load_with({"act1": wr("t24_a1.json", a1)}), "rejects legendary in event_pool")
	var a2: Dictionary = actj.duplicate(true); a2["room_types"]["rival"]["weight"] = 5
	ok(not load_with({"act1": wr("t24_a2.json", a2)}), "rejects rival weight > 0")
	var balls: Dictionary = rd(D + "balls.json")
	var bl: Dictionary = balls.duplicate(true); bl["capture"]["legendary_multiplier"] = 0
	ok(not load_with({"balls": wr("t24_b1.json", bl)}), "rejects legendary_multiplier 0")
	var pk: Dictionary = rd(D + "pokemon.json")
	var p1: Dictionary = pk.duplicate(true); p1["starter_candidates"].append("darkrai")
	ok(not load_with({"pokemon": wr("t24_p1.json", p1)}), "rejects legendary starter candidate")
	var rw: Dictionary = rd(D + "rewards.json")
	var w1: Dictionary = rw.duplicate(true)
	for k: String in w1["player_pool"].keys(): w1["player_pool"][k].append("trou_noir")
	ok(not load_with({"rewards": wr("t24_w1.json", w1)}), "rejects legendary card in reward pool")
	var cj: Dictionary = rd(D + "cards.json")
	var c1: Dictionary = cj.duplicate(true); c1["cards"]["feu_sacre"]["heal"] = -2
	ok(not load_with({"cards": wr("t24_c1.json", c1)}), "rejects negative heal")
	main = (load("res://src/main.tscn") as PackedScene).instantiate() as Main
	root.add_child(main)
	_go.call_deferred()


var main: Main


func _go() -> void:
	# --- 10. Main flow: rival room in zone 2, pre-league rival before the league screen
	main.start_new_run(12345, "salameche")
	ok(not main.get_rival_info().is_empty() and main.get_rival_info()["name"] == "Régis", "Main rival info")
	ok(main.qa_set_zone(1), "zone 2")
	var met: bool = false
	for step: int in 30:
		var scr: String = main.get_current_screen_name()
		if scr == "map":
			var reach: Array[String] = main.map_reachable_ids()
			if reach.is_empty(): break
			main.map_choose(reach[0])
		elif scr == "battle":
			var cf: Dictionary = main.get_current_fight()
			if not cf.is_empty() and cf["room"] == "rival":
				met = true
				ok(main.get_run_state().act.current_node().floor == 3, "rival room on floor 3")
				main.qa_win_current_fight()
				ok(main.get_current_screen_name() == "reward" and main.get_last_special_reward().get("kind", "") == "rival", "rival reward screen")
				break
			main.qa_win_current_fight()
		elif scr == "reward": main.reward_skip()
		elif scr == "event":
			if main.event_option_available(1): main.event_choose(1)
			else: main.event_choose(0)
			main.event_continue()
			while main.get_pending_card_removals() > 0: main.event_remove_card(0)
		elif scr == "evolution":
			if main.get_evolution_screen().get_step() == EvolutionScreen.Step.CHOOSE: main.evolution_skip()
			else: main.evolution_continue()
		else: main.room_continue()
	ok(met, "met the rival in zone 2")
	ok(main.qa_set_zone(7), "zone 8")
	main.qa_win_gym()
	main.reward_skip()
	main.badge_continue()
	for _e: int in 6:
		if main.get_current_screen_name() == "evolution":
			if main.get_evolution_screen().get_step() == EvolutionScreen.Step.CHOOSE: main.evolution_skip()
			else: main.evolution_continue()
	ok(main.get_current_screen_name() == "battle" and main.get_current_fight().get("room", "") == "rival_final", "pre-league rival fight (%s)" % main.get_current_screen_name())
	main.qa_win_current_fight()
	ok(main.get_current_screen_name() == "reward" and main.get_reward_offers().size() == 3, "final rival: 3 rare offers")
	main.reward_skip()
	for _e: int in 6:
		if main.get_current_screen_name() == "evolution": main.evolution_continue()
	ok(main.get_current_screen_name() == "league", "then the league screen (%s)" % main.get_current_screen_name())
	main.queue_free()
	print("t24 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
