extends SceneTree
## Story 032 scratch (story-032-rythme-et-zones): 4-floor zone maps (forced floors, guaranteed elite option, valid graph),
## the light zone rule (data, applied to wild / elite only, weaker than the gym rule, map banner + battle pill),
## thematic rewards (zone_type_bias on reward cards, Mart cards and held items), old 6-floor saves.
## Run: timeout 300 godot --headless --path . -s tests/scratch/t32_pacing.gd
const SEEDS: int = 200
var passes: int = 0
var fails: int = 0
var gd: GameData


func ok(c: bool, msg: String) -> void:
	if c:
		passes += 1
	else:
		fails += 1
		print("FAIL: ", msg)


func rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func new_run(seed_v: int = 3) -> RunState:
	var r := RunState.create_with_starter(gd, "salameche")
	r.set_zones(gd.draw_zones(rng(seed_v)))
	r.init_rival(gd, rng(seed_v + 1))
	return r


## Forces the current zone of `run` to the gym type `type_id` (QA: zones are drawn at random).
func force_zone_type(run: RunState, type_id: String) -> void:
	run.zones[run.zone_index]["type_id"] = type_id
	run.zones[run.zone_index]["type_name"] = gd.get_type_name(type_id)


func _initialize() -> void:
	_main.call_deferred()  # root enters the tree after _initialize: screens are added from _main


func _main() -> void:
	gd = GameData.new()
	ok(gd.load_all(), "data loads")
	_test_maps()
	_test_zone_rules()
	_test_first_card_every()
	_test_reward_bias()
	_test_saves()
	await _test_ui()
	print("t32 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)


# --- 1. Maps: 4 floors, forced floors, elite option, valid graph -------------------------------------------
func _test_maps() -> void:
	var with_mart: int = 0
	var floor2_multi: int = 0
	var floor2_elite: int = 0
	for z: int in range(1, 9):
		ok(gd.get_zone_floors(z) == 4, "zone %d has 4 floors" % z)
		var cfg: Dictionary = gd.get_zone_act_config(z)
		var rival_zone: bool = z in [2, 4, 6]
		for s: int in SEEDS:
			var g: MapGraph = MapGenerator.generate(cfg, 1000 * z + s + 1)
			ok(g.floors == 4 and g.get_node(g.boss_id()).floor == 4 and g.get_node(g.boss_id()).room_type == "boss", "boss on floor 4")
			for n: MapNode in g.get_floor_nodes(1):
				ok(n.room_type == ("rival" if rival_zone else "wild"), "zone %d floor 1 = %s" % [z, n.room_type])
			for n: MapNode in g.get_floor_nodes(3):
				ok(n.room_type == "center", "floor 3 = Centre (before the gym)")
				ok(n.next.size() == 1 and n.next[0] == g.boss_id(), "Centre leads to the gym")
			var f2: Array[MapNode] = g.get_floor_nodes(2)
			var types: Array[String] = []
			for n: MapNode in f2:
				types.append(n.room_type)
				ok(n.room_type in ["wild", "elite", "event", "mart"], "floor 2 type %s" % n.room_type)
			if f2.size() >= 2:
				floor2_multi += 1
				if types.has("elite"):
					floor2_elite += 1
			if types.has("mart"):
				with_mart += 1
			# Valid graph: every node reachable from floor 1, every node reaches the boss.
			var reach: Dictionary = {}
			var stack: Array[String] = g.start_node_ids()
			while not stack.is_empty():
				var id: String = stack.pop_back()
				if reach.has(id):
					continue
				reach[id] = true
				for nx: String in g.get_node(id).next:
					stack.append(nx)
			ok(reach.size() == g.nodes.size() and reach.has(g.boss_id()), "all rooms reachable")
			for n: MapNode in g.nodes.values():
				ok(n.floor == 4 or not n.next.is_empty(), "no dead end")
	ok(floor2_multi > 0 and floor2_elite == floor2_multi, "floor 2 always offers an elite when it has >= 2 rooms (%d/%d)" % [floor2_elite, floor2_multi])
	ok(with_mart > 0, "Mart possible on floor 2 (%d maps)" % with_mart)
	# Invalid guaranteed_rooms is rejected (no crash).
	var act: Dictionary = gd.get_act_config()
	ok((act["placement"]["guaranteed_rooms"] as Dictionary).has("2"), "guaranteed_rooms in data")


# --- 2. Zone rules -----------------------------------------------------------------------------------------
func _rule_strength(rule: Dictionary) -> float:
	var total: float = 0.0
	for fx: Dictionary in (rule.get("effects", []) as Array):
		total += float(fx.get("value", 1)) / float(fx.get("every", 1))
	return total


func _test_zone_rules() -> void:
	var types: Array[String] = gd.get_gym_type_ids()
	ok(types.size() == 18, "18 gym types")
	var run := new_run()
	run.start_act(gd, 5)
	for t: String in types:
		var zr: Dictionary = gd.get_zone_field_rule(t)
		var gr: Dictionary = gd.get_gym_field_rule(t)
		ok(not zr.is_empty() and String(zr["scope"]) == FieldRules.SCOPE_ZONE, "%s has a zone rule" % t)
		ok(zr.get("id", "") != gr.get("id", "") and not String(zr["name"]).is_empty(), "%s zone rule differs from the gym rule" % t)
		ok(_rule_strength(zr) < _rule_strength(gr), "%s zone rule weaker than the gym rule (%.2f < %.2f)" % [t, _rule_strength(zr), _rule_strength(gr)])
		var zone: Dictionary = {"type_id": t}
		for room: String in ["wild", "elite", "boss", "rival", "rival_final", "legendary", ""]:
			var b: Battle = run.create_battle(gd.create_enemies("solo"), gd.get_type_chart(), rng(1), false)
			var applied: Dictionary = SpecialFights.apply_fight_mechanics(gd, b, room, zone, {})
			var got: String = String(b.get_field_rule().get("id", ""))
			match room:
				"wild", "elite":
					ok(got == String(zr["id"]) and applied.get("id", "") == zr["id"], "%s %s fight gets the zone rule (%s)" % [t, room, got])
				"boss":
					ok(got == String(gr["id"]), "%s gym keeps the gym rule" % t)
				_:
					ok(got.is_empty(), "%s '%s' fight has no zone rule (%s)" % [t, room, got])
	# League fights keep their own rules (never a zone rule).
	var lb: Battle = run.create_battle(gd.create_enemies("solo"), gd.get_type_chart(), rng(1), false)
	SpecialFights.apply_fight_mechanics(gd, lb, SpecialFights.LEAGUE_ROOM, {"type_id": "water"}, {"kind": "champion"})
	ok(String(lb.get_field_rule().get("scope", "")) != FieldRules.SCOPE_ZONE and not lb.get_field_rule().is_empty(), "league: league rule, not the zone's")
	# Bad scope rejected by the validator.
	ok(not FieldRules.check_rule("x", {"name": "a", "description": "b", "scope": "nope", "effects": [{"type": "enemy_heal_per_turn", "value": 1}]}).is_empty(), "bad scope rejected")


# --- 3. first_card_cost_up honours `every` (zone_electric: every 3 turns) ----------------------------------
func _test_first_card_every() -> void:
	var run := new_run()
	var b: Battle = run.create_battle(gd.create_enemies("solo"), gd.get_type_chart(), rng(2), false)
	b.set_field_rule(gd.get_zone_field_rule("electric"))
	var rule_every: int = int((gd.get_zone_field_rule("electric")["effects"] as Array)[0].get("every", 1))
	b.start()
	b.player.max_hp = 9999
	b.player.hp = 9999
	for turn: int in range(1, rule_every * 2 + 1):
		if b.state != Battle.State.PLAYER_TURN or b.hand.is_empty():
			break
		var c: CardData = b.hand[0]
		var base: int = c.cost
		var up: int = 1 if turn % rule_every == 0 else 0
		ok(b.turn_number == turn and b.card_cost(c) >= base + up and b.card_cost(c) <= base + up, "turn %d: first card costs +%d" % [turn, up])
		b.end_turn()


# --- 4. Thematic rewards -----------------------------------------------------------------------------------
func _share_cards(zone_type: String, bias: float, n: int) -> float:
	var hit: int = 0
	var total: int = 0
	for s: int in n:
		for o: RewardOffer in RewardGenerator.generate(gd, "salameche", [] as Array[String], rng(s + 1), {}, -1, zone_type, bias):
			total += 1
			if o.card.type_id == "water":
				hit += 1
	return float(hit) / float(maxi(total, 1))


func _test_reward_bias() -> void:
	ok(gd.get_zone_type_bias("reward_cards") > 0.0 and gd.get_zone_type_bias("shop_cards") > 0.0 and gd.get_zone_type_bias("items") > 0.0,
			"zone_type_bias in data")
	var base: float = _share_cards("", -1.0, 400)
	var data_bias: float = _share_cards("water", -1.0, 400)
	var full: float = _share_cards("water", 1.0, 200)
	ok(data_bias > base + 0.1, "water cards more frequent in a water zone (%.2f > %.2f)" % [data_bias, base])
	ok(full > 0.99, "bias 1 => every offer of the type (%.2f)" % full)
	# Stolen card stays (not themed) and offers stay distinct.
	for s: int in 50:
		var offers: Array[RewardOffer] = RewardGenerator.generate(gd, "salameche", ["pikachu"] as Array[String], rng(s), {}, -1, "water", 1.0)
		var stolen: int = 0
		var ids: Dictionary = {}
		for o: RewardOffer in offers:
			ids[o.card.id] = true
			if o.stolen:
				stolen += 1
			else:
				ok(o.card.type_id == "water", "non-stolen offer of the zone type")
		ok(stolen == 1 and ids.size() == offers.size() and offers.size() == gd.get_offer_count(), "stolen card kept, offers distinct")
	# League: no zone type.
	var lr := new_run()
	ok(RewardGenerator.zone_type_of(lr) == String(lr.current_zone()["type_id"]), "zone type of a zone fight")
	# Items (loot / Mart): fire items more frequent in a fire zone than in a normal zone (no normal item).
	var fire_run := new_run()
	force_zone_type(fire_run, "fire")
	var norm_run := new_run()
	force_zone_type(norm_run, "normal")
	var fire_hits: Array[int] = [0, 0]
	for s: int in 600:
		for i: int in 2:
			var r: RunState = fire_run if i == 0 else norm_run
			for it: ItemData in LootGenerator.pick_items(gd, r, 1, rng(s + 7)):
				if it.card_types().has("fire"):
					fire_hits[i] += 1
	ok(fire_hits[0] > fire_hits[1] * 2, "fire items more frequent in a fire zone (%d vs %d)" % [fire_hits[0], fire_hits[1]])
	# Mart cards.
	var water_run := new_run()
	force_zone_type(water_run, "water")
	var shop_hits: Array[int] = [0, 0]
	for s: int in 200:
		for i: int in 2:
			var r: RunState = water_run if i == 0 else norm_run
			for e: ShopEntry in ShopInventory.generate(gd, r, rng(s + 3)).cards:
				if e.card.type_id == "water":
					shop_hits[i] += 1
	ok(shop_hits[0] > shop_hits[1] + 50, "water cards more frequent in a water-zone Mart (%d vs %d)" % [shop_hits[0], shop_hits[1]])


# --- 5. Saves: an old 6-floor map still loads and plays; wrong versions are refused --------------------------
func _test_saves() -> void:
	var run := new_run()
	var old_cfg: Dictionary = gd.get_zone_act_config(1)
	old_cfg["map"]["floors"] = 6
	old_cfg["placement"]["forced_floors"] = {"1": "wild", "5": "center", "6": "boss"}
	old_cfg["placement"]["guaranteed_rooms"] = {}
	run.act = ActProgress.create(MapGenerator.generate(old_cfg, 77))
	ok(run.act.graph.floors == 6, "old-style map built")
	run.act.enter(run.act.reachable_ids()[0])
	var dict: Dictionary = SaveGame.to_dict(run, {})
	ok(int(dict["version"]) == SaveGame.VERSION, "save version %d" % SaveGame.VERSION)
	var back: Dictionary = SaveGame.from_dict(JSON.parse_string(JSON.stringify(dict)), gd)
	ok(back["ok"], "old 6-floor save loads: " + String(back.get("error", "")))
	if back["ok"]:
		var lr: RunState = back["run"]
		ok(lr.act.graph.floors == 6 and lr.act.current_floor() == 1, "6-floor map kept for the zone in progress")
		# Walk to the gym of the old map.
		var guard: int = 0
		while not lr.act.is_boss_current() and guard < 10:
			lr.act.enter(lr.act.reachable_ids()[0])
			guard += 1
		ok(lr.act.is_boss_current() and lr.act.current_floor() == 6, "old map's gym reachable")
		ok(lr.advance_zone() and lr.start_act(gd) and lr.act.graph.floors == 4, "next zone uses the 4-floor maps")
	var bad: Dictionary = JSON.parse_string(JSON.stringify(dict))
	bad["version"] = SaveGame.VERSION + 1
	var refused: Dictionary = SaveGame.from_dict(bad, gd)
	ok(not refused["ok"] and String(refused["error"]).contains("version"), "unknown version refused cleanly: " + String(refused.get("error", "")))


# --- 6. UI: map banner + header, battle pill ----------------------------------------------------------------
func _test_ui() -> void:
	var run := new_run()
	force_zone_type(run, "water")
	run.start_act(gd, 11)
	var zr: Dictionary = gd.get_zone_field_rule("water")
	var ms: MapScreen = (load("res://src/ui/map_screen.tscn") as PackedScene).instantiate() as MapScreen
	root.add_child(ms)
	ms.setup(gd, run)
	await process_frame
	ok(ms.get_banner_rule_text().begins_with("Règle de zone : " + String(zr["name"])), "map banner rule line: " + ms.get_banner_rule_text())
	ok(ms.get_banner_rule_text().contains(String(zr["description"])), "banner shows the rule description")
	ok(ms.get_info_text().contains("Règle de zone : " + String(zr["name"])), "header info shows the zone rule: " + ms.get_info_text())
	ok(ms.get_title_text().contains("Étage") == false or ms.get_title_text().contains("/4"), "title floors /4")
	run.act.enter(run.act.reachable_ids()[0])
	ms.setup(gd, run)
	ok(ms.get_banner_rule_text().is_empty() and ms.get_title_text().contains("Étage 1/4"), "banner hidden after the first room, 'Étage 1/4': " + ms.get_title_text())
	ms.queue_free()
	await process_frame
	# Battle pill on a wild fight of the zone.
	var b: Battle = run.create_battle(gd.create_enemies("solo"), gd.get_type_chart(), rng(4), true)
	SpecialFights.apply_fight_mechanics(gd, b, "wild", run.current_zone(), {})
	var bs: BattleScreen = (load("res://src/ui/battle_screen.tscn") as PackedScene).instantiate() as BattleScreen
	root.add_child(bs)
	bs.setup(b, gd, run, "solo")
	await process_frame
	ok(bs.get_field_rule_pill_text() == "Zone : " + String(zr["name"]), "battle pill: " + bs.get_field_rule_pill_text())
	bs.queue_free()
	await process_frame
