extends SceneTree
var fails: int = 0
var passes: int = 0
const SCR := "/tmp/claude-0/-home-user-pokemon-spire/a2b72075-2d8b-51e2-a914-9e4b612c161d/scratchpad/"
func ok(c: bool, msg: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		if fails < 40: print("FAIL ", msg)
func rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r
func rj(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))
func wj(name: String, d: Dictionary) -> String:
	var f := FileAccess.open(SCR + name, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	return SCR + name
func sig(g: MapGraph) -> String:
	var s := str(g.seed)
	var ids: Array = g.nodes.keys()
	ids.sort()
	for id: String in ids:
		var n: MapNode = g.nodes[id]
		s += "|%s:%s>%s" % [id, n.room_type, ",".join(n.next)]
	return s

func _init() -> void:
	var data := GameData.new()
	ok(data.load_all(), "load_all")
	var cfg: Dictionary = data.get_act_config()
	var counts: Dictionary = {}
	var no_consec: Array = cfg["placement"]["no_consecutive"]
	var total_nodes := 0
	for s: int in range(1, 401):
		var g: MapGenerator = null
		var graph: MapGraph = MapGenerator.generate(cfg, s)
		ok(graph.seed == s, "seed recorded")
		ok(graph.floors == 15, "floors")
		ok(graph.get_floor_nodes(15).size() == 1 and graph.get_floor_nodes(15)[0].room_type == "boss", "boss")
		ok(graph.get_floor_nodes(1).size() >= 3, "starts >=3 seed %d" % s)
		for n: MapNode in graph.get_floor_nodes(1): ok(n.room_type == "wild", "f1 wild")
		for n: MapNode in graph.get_floor_nodes(14): ok(n.room_type == "center", "f14 center")
		# reachability
		var reach: Dictionary = {}
		var stack: Array[String] = graph.start_node_ids()
		while not stack.is_empty():
			var id: String = stack.pop_back()
			if reach.has(id): continue
			reach[id] = true
			stack.append_array(graph.get_node(id).next)
		ok(reach.size() == graph.nodes.size(), "all reachable seed %d" % s)
		ok(reach.has(graph.boss_id()), "boss reachable")
		for id: String in graph.nodes.keys():
			var n: MapNode = graph.nodes[id]
			total_nodes += 1
			counts[n.room_type] = int(counts.get(n.room_type, 0)) + 1
			ok(n.room_type != "", "typed")
			if n.floor < 15: ok(not n.next.is_empty(), "outgoing %s" % id)
			if n.room_type == "elite": ok(n.floor >= 5, "elite floor")
			if n.room_type == "center": ok(n.floor >= 4, "center floor")
			for nid: String in n.next:
				var m: MapNode = graph.get_node(nid)
				ok(m != null and m.floor == n.floor + 1, "adjacent floors")
				if m.floor < 15: ok(absi(m.col - n.col) <= 1, "dcol")
				if n.room_type in no_consec: ok(m.room_type != n.room_type, "no_consecutive %s %s" % [n.id, m.id])
		# crossings
		for f: int in range(1, 14):
			var edges: Array = []
			for n: MapNode in graph.get_floor_nodes(f):
				for nid: String in n.next: edges.append([n.col, graph.get_node(nid).col])
			for a: Array in edges:
				for b: Array in edges:
					ok(not ((a[0] < b[0] and a[1] > b[1])), "crossing seed %d f%d" % [s, f])
		if s <= 30:
			ok(sig(MapGenerator.generate(cfg, s)) == sig(graph), "determinism")
		# progress
		var prog := ActProgress.create(graph)
		ok(prog.current_floor() == 0 and prog.reachable_ids() == graph.start_node_ids(), "progress start")
		var r := rng(s)
		var non_start: String = graph.get_floor_nodes(2)[0].id
		ok(not prog.enter(non_start), "cannot skip floor")
		var steps := 0
		while not prog.is_boss_current():
			var opts: Array[String] = prog.reachable_ids()
			ok(not opts.is_empty(), "opts")
			var pick: String = opts[r.randi_range(0, opts.size() - 1)]
			ok(prog.enter(pick) and prog.is_visited(pick), "enter")
			steps += 1
			ok(prog.current_floor() == steps, "floor == steps")
			var bad: String = graph.get_floor_nodes(mini(steps + 2, 15))[0].id
			if steps + 2 <= 15: ok(not prog.can_enter(bad), "skip")
			if steps > 20: break
		ok(steps == 15, "15 steps")
	print("room type counts: ", counts, " total ", total_nodes)
	ok(counts.size() == 6, "all 6 types occur")
	ok(counts["wild"] > counts["event"] and counts["event"] > counts["elite"] and counts["elite"] > 0, "frequency order")
	var r0 := MapGenerator.generate(cfg, 0)
	ok(r0.seed != 0, "random seed recorded")
	ok(sig(MapGenerator.generate(cfg, r0.seed)) == sig(r0), "random seed replay")
	# pick_encounter
	var rr := rng(7)
	var pools: Dictionary = cfg["encounter_pools"]
	for i: int in 500:
		var fl: int = rr.randi_range(1, 14)
		var e: String = data.pick_encounter("wild", fl, rr)
		var pool: String = "wild_early" if fl <= 3 else "wild"
		var found := false
		for en: Dictionary in pools[pool]: if en["encounter"] == e: found = true
		ok(found, "wild pick %s at %d" % [e, fl])
		ok(not data.create_enemies(e).is_empty(), "wild create")
		var el: String = data.pick_encounter("elite", 8, rr)
		ok(el.begins_with("elite_") and not data.create_enemies(el).is_empty(), "elite pick")
	ok(data.pick_encounter("boss", 15, rr) == "boss_champion", "boss pick")
	# elite modifiers
	var mods: Dictionary = data.get_room_modifiers("elite")
	ok(mods["hp_multiplier"] == 1.4 and mods["strength_bonus"] == 1, "mods")
	var base: Array[Combatant] = data.create_enemies("elite_2")
	var boosted: Array[Combatant] = data.create_enemies("elite_2", mods["hp_multiplier"], mods["strength_bonus"])
	ok(base[0].max_hp == 30 and boosted[0].max_hp == 42 and boosted[0].hp == 42, "hp x1.4 (%d)" % boosted[0].max_hp)
	ok(boosted[1].max_hp == ceili(28 * 1.4) and boosted[0].strength == 1, "hp ceil / strength")
	var run := RunState.create(data, "salameche")
	for sd: int in 30:
		var enemies: Array[Combatant] = data.create_enemies("elite_2", 1.4, 1)
		var b := run.create_battle(enemies, data.get_type_chart(), rng(sd))
		for en: Combatant in enemies:
			if en.intent != null and en.intent.type == EnemyIntent.TYPE_ATTACK:
				var plain: Array[Combatant] = data.create_enemies("elite_2")
				var pb := run.create_battle(plain, data.get_type_chart(), rng(sd))
				var idx: int = enemies.find(en)
				ok(en.intent.value >= plain[idx].intent.value + 1 or plain[idx].intent.type != EnemyIntent.TYPE_ATTACK, "boosted intent")
		var shown: Array = []
		for en: Combatant in enemies: shown.append(en.intent.value if en.intent != null else -1)
		var hp0: int = b.player.hp
		var expected := 0
		for en: Combatant in enemies:
			if en.intent != null and en.intent.type == EnemyIntent.TYPE_ATTACK: expected += en.intent.value
		b.end_turn()
		ok(hp0 - b.player.hp == expected or b.state == Battle.State.LOST, "executed == displayed (%d vs %d)" % [hp0 - b.player.hp, expected])
	# reward weights
	var ew: Dictionary = data.get_room_rarity_weights("elite")
	ok(not ew.is_empty() and data.get_room_rarity_weights("wild").is_empty(), "elite weights")
	var rare_n := [0, 0]
	var rrn := rng(3)
	for i: int in 3000:
		var no: Array[String] = []
		for o: RewardOffer in RewardGenerator.generate(data, "salameche", no, rrn): if o.card.rarity == "rare": rare_n[0] += 1
		for o: RewardOffer in RewardGenerator.generate(data, "salameche", no, rrn, ew): if o.card.rarity == "rare": rare_n[1] += 1
	print("rare picks normal/elite: ", rare_n)
	ok(rare_n[1] > rare_n[0] * 1.5, "elite more rares")
	# events
	for id: String in data.get_event_pool():
		ok((data.get_event(id)["options"] as Array).size() == 2, "2 options")
	var re := rng(5)
	for i: int in 20: ok(not EventResolver.pick_event(data, re).is_empty(), "pick event")
	var run2 := RunState.create(data, "salameche")
	run2.hp = 10
	var summ: String = EventResolver.apply_effects([{"type": "heal", "percent": 30}], run2, data, re)
	ok(run2.hp == 10 + ceili(75 * 0.3) and summ.begins_with("+"), "heal " + summ)
	EventResolver.apply_effects([{"type": "heal", "percent": 100}], run2, data, re)
	ok(run2.hp == run2.max_hp, "heal clamp")
	run2.hp = 3
	summ = EventResolver.apply_effects([{"type": "lose_hp", "value": 50}], run2, data, re)
	ok(run2.hp == 1, "never kills " + summ)
	run2.hp = 20
	summ = EventResolver.apply_effects([{"type": "gain_max_hp", "value": 5}, {"type": "lose_hp", "value": 5}], run2, data, re)
	ok(run2.max_hp == 80 and run2.hp == 20 and summ == "+5 PV max, -5 PV", "gain max: " + summ)
	var n0: int = run2.deck.size()
	EventResolver.apply_effects([{"type": "add_card", "card": "rugissement"}], run2, data, re)
	ok(run2.deck.size() == n0 + 1, "add card")
	EventResolver.apply_effects([{"type": "remove_card", "card": "abri"}, {"type": "add_random_card", "rarity": "common"}], run2, data, re)
	ok(run2.deck.size() == n0 + 1 and run2.deck_counts()["abri"] == 3, "trade")
	summ = EventResolver.apply_effects([{"type": "remove_card", "card": "tonnerre"}, {"type": "nothing"}], run2, data, re)
	ok(run2.deck.size() == n0 + 1 and summ == "", "remove absent noop")
	ok(run2.start_act(data, 42) and run2.act.graph.seed == 42, "start_act")
	# validation
	var paths := [GameData.DEFAULT_CARDS_PATH, GameData.DEFAULT_POKEMON_PATH, GameData.DEFAULT_TYPES_PATH, GameData.DEFAULT_REWARDS_PATH]
	var act: Dictionary = rj(GameData.DEFAULT_ACT_PATH)
	var evs: Dictionary = rj(GameData.DEFAULT_EVENTS_PATH)
	var pk: Dictionary = rj(GameData.DEFAULT_POKEMON_PATH)
	var cases := {}
	var a1: Dictionary = act.duplicate(true); a1["encounter_pools"]["elite"] = [{"encounter": "nope", "weight": 1}]; cases["unknown encounter"] = [a1, evs, pk]
	var a2: Dictionary = act.duplicate(true); a2["room_types"]["badroom"] = {"name": "x", "weight": 1, "min_floor": 1}; cases["unknown room type"] = [a2, evs, pk]
	var a3: Dictionary = act.duplicate(true); a3["map"]["boss_floor_nodes"] = 2; cases["boss floor 2 nodes"] = [a3, evs, pk]
	var a4: Dictionary = act.duplicate(true); a4["placement"]["forced_floors"]["15"] = "wild"; cases["last floor not boss"] = [a4, evs, pk]
	var a5: Dictionary = act.duplicate(true); a5["room_types"]["wild"]["encounter_pool"] = "ghost"; cases["unknown pool"] = [a5, evs, pk]
	var a6: Dictionary = act.duplicate(true); for k: String in a6["room_types"]: a6["room_types"][k]["weight"] = 0; cases["all weights 0"] = [a6, evs, pk]
	var a7: Dictionary = act.duplicate(true); a7["event_pool"] = ["ghost"]; cases["unknown event in pool"] = [a7, evs, pk]
	var e1: Dictionary = evs.duplicate(true); e1["events"][0]["options"].append({"label": "x", "result_text": "y", "effects": [{"type": "nothing"}]}); cases["event 3 options"] = [act, e1, pk]
	var e2: Dictionary = evs.duplicate(true); e2["events"][0]["options"][0]["effects"] = [{"type": "explode"}]; cases["unknown effect"] = [act, e2, pk]
	var e3: Dictionary = evs.duplicate(true); e3["events"][0]["options"][0]["effects"] = [{"type": "add_card", "card": "zzz"}]; cases["unknown card"] = [act, e3, pk]
	var n := 0
	for name: String in cases.keys():
		n += 1
		var c: Array = cases[name]
		var bad := GameData.new()
		var res: bool = bad.load_all(paths[0], wj("bp%d.json" % n, c[2]), paths[2], paths[3], wj("ba%d.json" % n, c[0]), wj("be%d.json" % n, c[1]))
		ok(not res, "rejects " + name)
	ok(GameData.new().load_all(), "real still loads")
	print("PASS ", passes, " FAIL ", fails)
	quit(1 if fails > 0 else 0)
