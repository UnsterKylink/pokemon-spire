extends SceneTree
## Story 012 scratch: zones, gyms, badges.
const SCR: String = "/tmp/claude-0/-home-user-pokemon-spire/a2b72075-2d8b-51e2-a914-9e4b612c161d/scratchpad/"
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

func zones_load(mut: Callable) -> bool:
	var z: Dictionary = rj("res://assets/data/zones.json")
	mut.call(z)
	var f := FileAccess.open(SCR + "t14_z.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(z))
	f.close()
	var P := "res://assets/data/"
	return GameData.new().load_all(P + "cards.json", P + "pokemon.json", P + "types.json", P + "rewards.json", P + "act1.json",
			P + "events.json", P + "items.json", P + "potions.json", P + "shop.json", SCR + "t14_z.json")

func rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r

func types_of(zs: Array[Dictionary]) -> Array:
	return zs.map(func(z: Dictionary) -> String: return z["type_id"])

func _initialize() -> void:
	main = (load("res://src/main.tscn") as PackedScene).instantiate() as Main
	root.add_child(main)
	_go.call_deferred()

func _go() -> void:
	var gd := GameData.new()
	ok(gd.load_all(), "data loads")
	# 1. 8 distinct types per seed + determinism
	var distinct_orders: Dictionary = {}
	for s: int in range(1, 41):
		var zs: Array[Dictionary] = gd.draw_zones(rng(s))
		var t: Array = types_of(zs)
		var uniq: Dictionary = {}
		for x: String in t: uniq[x] = true
		ok(zs.size() == 8 and uniq.size() == 8, "8 distinct types seed %d" % s)
		ok(t == types_of(gd.draw_zones(rng(s))), "deterministic seed %d" % s)
		distinct_orders[str(t)] = true
		for z: Dictionary in zs:
			ok(gd.create_enemies(z["gym_encounter"]).size() == 3, "gym team of 3 " + z["type_id"])
			var carriers := 0
			for e: Combatant in gd.create_enemies(z["gym_encounter"]):
				if e.type_ids.has(z["type_id"]): carriers += 1
			ok(carriers == 3, "team of zone type %s (%d)" % [z["type_id"], carriers])
	ok(distinct_orders.size() > 30, "draws vary across seeds (%d)" % distinct_orders.size())
	# 2. per-zone map 6 floors, gym on top
	for n: int in range(1, 9):
		var g: MapGraph = MapGenerator.generate(gd.get_zone_act_config(n), 100 + n)
		ok(g.floors == 6 and g.get_node(g.boss_id()).room_type == "boss" and g.get_node(g.boss_id()).floor == 6, "zone %d map 6 floors" % n)
		for f: int in range(1, 6):
			for node: MapNode in g.get_floor_nodes(f):
				ok(node.room_type != "boss" and node.room_type != "", "normal room floor %d" % f)
	# 3. modifiers rise monotonically
	var zs: Array[Dictionary] = gd.draw_zones(rng(7))
	for i: int in range(1, 8):
		var a: Dictionary = gd.get_fight_modifiers("boss", zs[i - 1]); var b: Dictionary = gd.get_fight_modifiers("boss", zs[i])
		ok(b["hp_multiplier"] >= a["hp_multiplier"] and b["strength_bonus"] >= a["strength_bonus"], "gym mods rise %d" % i)
		var wa: Dictionary = gd.get_fight_modifiers("wild", zs[i - 1]); var wb: Dictionary = gd.get_fight_modifiers("wild", zs[i])
		ok(wb["hp_multiplier"] >= wa["hp_multiplier"] and wb["strength_bonus"] >= wa["strength_bonus"], "wild mods rise %d" % i)
	ok(is_equal_approx(gd.get_fight_modifiers("boss", zs[0])["hp_multiplier"], 0.7) and is_equal_approx(gd.get_fight_modifiers("boss", zs[7])["hp_multiplier"], 1.25), "gym x0.7 .. x1.25")
	ok(is_equal_approx(gd.get_fight_modifiers("elite", zs[7])["hp_multiplier"], 1.2 * 1.2), "elite stacks room x zone")
	ok(gd.get_fight_modifiers("center", zs[7])["hp_multiplier"] == 1.0, "center neutral")
	# wild bias toward the zone type
	var r := rng(3)
	var typed := 0
	for k: int in 400:
		var enc: String = gd.pick_encounter("wild", 4, r, zs[2])
		for e: Combatant in gd.create_enemies(enc):
			if e.type_ids.has(zs[2]["type_id"]):
				typed += 1
				break
	ok(typed > 200, "wild biased to zone type %d/400" % typed)
	ok(gd.pick_encounter("boss", 6, r, zs[4]) == zs[4]["gym_encounter"], "gym encounter from zone")
	ok((zs[1]["unlocked_wild_pools"] as Array).has("wild_duos") and (zs[0]["unlocked_wild_pools"] as Array).is_empty(), "badge 1 unlocks zone 2 pool")
	# 4. Main: full flow
	main.start_new_run(4242, "salameche")
	var run: RunState = main.get_run_state()
	ok(run.zones.size() == 8 and main.get_zone_index() == 0 and run.act.graph.floors == 6, "run starts zone 1")
	var t1: Array = types_of(run.zones)
	main.start_new_run(4242, "salameche")
	ok(types_of(main.get_run_state().zones) == t1, "--seed deterministic zones")
	run = main.get_run_state()
	main.qa_set_money(321)
	main.qa_give_item("restes")
	main.qa_give_potion("potion")
	var seed1: int = run.act.graph.seed
	var deck_n: int = run.deck.size()
	var max0: int = run.max_hp
	var hand0: int = run.effective_hand_size()
	var en0: int = run.effective_energy_per_turn()
	main.qa_skip_to_gym()
	ok(main.get_current_screen_name() == "battle" and main.get_encounter_id() == run.zones[0]["gym_encounter"], "gym fight")
	main.qa_win_gym()
	ok(main.get_current_screen_name() == "reward" and main.get_last_loot()["money"] >= 60, "gym -> reward + loot")
	main.qa_set_hp(10)
	main.reward_pick(0)
	ok(main.get_current_screen_name() == "badge", "reward -> badge")
	var b1: Dictionary = main.get_last_badge()
	ok(b1["index"] == 1 and b1["name"] == run.zones[0]["badge_name"] and b1["color"] is Color, "badge 1 dict")
	ok(run.max_hp == max0 + 6 and run.hp > 10 and b1["healed"] > 0, "badge 1 +6 max hp and heal (%d/%d)" % [run.hp, run.max_hp])
	ok(main.get_badges().size() == 1, "1 badge")
	var money: int = run.money
	main.badge_continue()
	ok(main.get_current_screen_name() == "evolution", "evolution after badge 1")
	main.evolution_continue(); main.evolution_skip(); main.evolution_continue()
	ok(main.get_current_screen_name() == "map" and main.get_zone_index() == 1, "zone 2 map")
	ok(run.deck.size() == deck_n + 1 and run.money == money and run.has_item("restes") and run.potions.size() >= 1, "deck/money/items kept")
	ok(run.act.visited.is_empty() and run.act.graph.seed != seed1 and run.floors_climbed() == 1, "fresh zone map, floors carried (%d)" % run.floors_climbed())
	var hp_keep: int = run.hp
	ok(run.hp == hp_keep, "hp kept")
	# badges 2..8 via the real gym flow
	for i: int in range(1, 8):
		ok(main.get_zone_index() == i, "zone %d" % (i + 1))
		main.qa_win_gym()
		main.reward_skip()
		for _e: int in 6:  # story 014: drain evolution screens (starter steps / team summary)
			if main.get_current_screen_name() == "evolution":
				if main.get_evolution_screen().get_step() == EvolutionScreen.Step.CHOOSE: main.evolution_skip()
				else: main.evolution_continue()
		ok(main.get_current_screen_name() == "badge" and main.get_last_badge()["index"] == i + 1, "badge %d" % (i + 1))
		main.badge_continue()
		for _e: int in 6:  # story 014: drain evolution screens (starter steps / team summary)
			if main.get_current_screen_name() == "evolution":
				if main.get_evolution_screen().get_step() == EvolutionScreen.Step.CHOOSE: main.evolution_skip()
				else: main.evolution_continue()
		if i < 7:
			ok(main.get_current_screen_name() == "map", "-> next map after badge %d" % (i + 1))
	for _k: int in 12:  # story 013: badge 8 -> league (5 fights + Éthernatos) -> victory
		if main.get_current_screen_name() == "battle": main.qa_win_current_fight()  # story 018: pre-league rival
		if main.get_current_screen_name() == "league": main.qa_win_league_fight()
		if main.get_current_screen_name() == "reward": main.reward_skip()
		for _e: int in 6:  # story 014: drain evolution screens (starter steps / team summary)
			if main.get_current_screen_name() == "evolution":
				if main.get_evolution_screen().get_step() == EvolutionScreen.Step.CHOOSE: main.evolution_skip()
				else: main.evolution_continue()
	ok(main.get_current_screen_name() == "victory", "victory after badge 8")
	# gym loot also gives held items (draw_up / energy / max_hp items), so check the badge part on its own
	ok(run.bonus_hand_size == 1 and run.bonus_energy == 1 and run.effective_hand_size() == run.hand_size + 1 + ItemEffects.passive_total(run.items, "draw_up") and run.effective_energy_per_turn() == run.energy_per_turn + 1 + ItemEffects.passive_total(run.items, "energy_up_per_turn"), "badge hand +1, energy +1 in effective values")
	var gains := 0
	for b: Dictionary in main.get_badges(): gains += int(b["max_hp_gain"])
	ok(gains == 6 + 6 + 8 + 8 + 8 + 10, "badge max hp gains %d" % gains)
	var sm: Dictionary = run.get_summary()
	ok(sm["badges"] == 8 and sm["total_floors"] == 48 and sm["zone"] == 8, "summary %s" % sm)
	var bnames: Dictionary = {}
	for b: Dictionary in main.get_badges(): bnames[b["id"]] = true
	ok(bnames.size() == 8, "8 different badges")
	# 5. new run full reset
	main.victory_new_run()
	main.starter_choose(0)
	var nr: RunState = main.get_run_state()
	ok(nr.zone_index == 0 and nr.badges.is_empty() and nr.bonus_energy == 0 and nr.bonus_hand_size == 0 and nr.floors_climbed() == 0 and main.get_last_badge().is_empty(), "reset after victory")
	# defeat in zone 4 then reset
	main.qa_set_zone(3)
	main.start_encounter("solo_bidoof")
	ok(main.qa_lose_battle(), "lost in zone 4")
	main.battle_defeat_continue()
	ok(main.get_current_screen_name() == "defeat", "defeat zone 4")
	main.defeat_new_run()
	main.starter_choose(0)
	nr = main.get_run_state()
	ok(nr.zone_index == 0 and nr.badges.is_empty() and nr.act.graph.floors == 6, "reset after defeat")
	# 6. validation rejections
	ok(zones_load(func(_z): pass), "unmodified copy loads")
	ok(not zones_load(func(z): z["zone_count"] = 10), "pool smaller than zone_count")
	ok(not zones_load(func(z): z["gym_types"]["dark"] = z["gym_types"]["rock"].duplicate()), "type without enough carriers / dup badge")
	ok(not zones_load(func(z): z["gym_types"]["rock"]["encounter"] = "solo"), "team not of size 3")
	ok(not zones_load(func(z): z["gym_types"]["rock"]["wild_pool"] = "nope"), "unknown pool")
	ok(not zones_load(func(z): z["tiers"].pop_back()), "tiers count")
	ok(not zones_load(func(z): z["tiers"][3]["gym_modifiers"]["hp_multiplier"] = 0.5), "decreasing gym")
	ok(not zones_load(func(z): z["badge_rewards"]["7"]["energy_per_turn"] = 1), "energy limit")
	ok(not zones_load(func(z): z["badge_rewards"].erase("3")), "missing badge reward")
	ok(not zones_load(func(z): z["evolution_after_badges"] = [9]), "bad evolution badge")
	ok(not zones_load(func(z): z["zone_overrides"] = {"2": {"map": {"floors": 2}}}), "bad override map")
	ok(zones_load(func(z): z["zone_overrides"]["8"] = {"map": {"floors": 7}, "forced_floors": {"1": "wild", "7": "boss"}}), "valid override loads")
	print("t14 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
