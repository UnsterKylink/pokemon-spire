extends SceneTree
## Story 017 scratch: capture with Poké Balls (formula, determinism, team join, removal/win, room rules, bag limit, energy,
## shop/loot/event balls, save round trip incl. old save, data validation).
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
	var names := ["cards", "pokemon", "types", "rewards", "act1", "events", "items", "potions", "shop", "zones", "league", "roster", "statuses", "balls"]
	var paths: Array = []
	for n in names:
		paths.append(over.get(n, D + n + ".json"))
	return GameData.new().callv("load_all", paths)

func rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r

func new_run() -> RunState:
	return RunState.create_with_starter(gd, "salameche")

## A non-boss wild enemy id that teaches exactly `n` cards.
func enemy_with_teaches(n: int) -> String:
	for id: String in gd.get_enemy_ids():
		if not gd.is_boss_pokemon(id) and gd.get_enemy_teaches(id).size() == n:
			return id
	return ""

func battle_with(run: RunState, ids: Array, capture: bool, s: int = 1) -> Battle:
	var enemies: Array[Combatant] = []
	for id: String in ids:
		enemies.append(gd.create_enemy(id))
	var b: Battle = run.create_battle(enemies, gd.get_type_chart(), rng(s), capture)
	b.start()
	return b

func force(lo: float, hi: float) -> void:
	gd.get_capture_rules().min_chance = lo
	gd.get_capture_rules().max_chance = hi

func _initialize() -> void:
	gd = GameData.new()
	ok(gd.load_all(), "real data loads")
	var rules: CaptureRules = gd.get_capture_rules()
	ok(rules != null and rules.energy_cost == 1 and gd.get_max_balls() == 5, "capture rules / max 5 / cost 1")
	ok(gd.get_ball_ids() == (["poke_ball", "super_ball", "hyper_ball"] as Array[String]), "3 balls in order")
	var pb: BallData = gd.get_ball("poke_ball")
	var sb: BallData = gd.get_ball("super_ball")
	var hb: BallData = gd.get_ball("hyper_ball")
	ok(pb.price < sb.price and sb.price < hb.price and pb.base_chance < sb.base_chance and sb.base_chance < hb.base_chance, "increasing price/base")
	# --- formula
	var none: Array[String] = []
	var full: float = rules.chance(pb, 40, 40, none)
	ok(absf(full - 0.1) < 0.001, "Poké Ball full HP ~10%% (%f)" % full)
	var low: float = rules.chance(pb, 4, 40, none)
	ok(low >= 0.7, "Poké Ball 10%% HP >= 70%% (%f)" % low)
	ok(rules.chance(pb, 20, 40, none) > full and rules.chance(pb, 20, 40, none) < low, "lower HP raises the chance")
	ok(rules.chance(sb, 40, 40, none) > full and rules.chance(hb, 40, 40, none) > rules.chance(sb, 40, 40, none), "better balls better chance")
	ok(absf(rules.chance(pb, 40, 40, ["sleep"] as Array[String]) - 0.2) < 0.001, "sleep x2")
	ok(absf(rules.chance(pb, 40, 40, ["freeze"] as Array[String]) - 0.2) < 0.001, "freeze x2")
	for s: String in ["paralysis", "burn", "poison"]:
		ok(absf(rules.chance(pb, 40, 40, [s] as Array[String]) - 0.15) < 0.001, "%s x1.5" % s)
	ok(absf(rules.chance(pb, 40, 40, ["poison", "sleep"] as Array[String]) - 0.2) < 0.001, "best status counts (not product)")
	ok(rules.chance(hb, 1, 40, ["sleep"] as Array[String]) == rules.max_chance, "clamped to max")
	ok(rules.chance(pb, 0, 40, none) <= rules.max_chance and rules.chance(pb, 40, 40, none) >= rules.min_chance, "clamped range")
	# --- room rules
	ok(gd.capture_allowed_in("wild") and not gd.capture_allowed_in("elite") and not gd.capture_allowed_in("boss")
			and not gd.capture_allowed_in("league") and not gd.capture_allowed_in(""), "wild only")
	var eid2: String = enemy_with_teaches(2)
	var eid1: String = enemy_with_teaches(1)
	ok(not eid2.is_empty() and not eid1.is_empty(), "enemies with 1 and 2 teaches exist (%s, %s)" % [eid1, eid2])
	# --- bag
	var run: RunState = new_run()
	ok(run.balls.is_empty() and run.captured.is_empty() and run.ball_total() == 0, "new run: no balls")
	for i: int in 5:
		ok(run.add_ball("poke_ball" if i < 3 else "super_ball"), "add ball %d" % i)
	ok(not run.add_ball("hyper_ball") and run.ball_total() == 5, "max 5 total")
	ok(not run.add_ball("nope"), "unknown ball refused")
	ok(run.remove_ball("super_ball") and run.ball_count("super_ball") == 1 and run.remove_ball("super_ball") and not run.balls.has("super_ball"), "remove_ball")
	ok(not run.remove_ball("super_ball"), "remove missing ball")
	# --- no capture outside wild / boss / not allowed
	var b0: Battle = battle_with(run, [eid2], false)
	ok(not b0.can_use_ball("poke_ball", 0) and not b0.use_ball("poke_ball", 0)["used"], "capture_allowed false -> refused")
	var bb: Battle = battle_with(run, ["eternatus"], true)
	ok(not bb.enemies[0].capturable and not bb.can_use_ball("poke_ball", 0) and bb.capture_chance("poke_ball", 0) == 0.0, "boss never capturable")
	# --- energy / invalid
	var b1: Battle = battle_with(run, [eid2, eid1], true, 7)
	ok(b1.ball_ids() == (["poke_ball"] as Array[String]) and b1.ball_count("poke_ball") == 3, "battle gets the bag")
	ok(b1.can_use_ball(0, 0) and b1.can_use_ball("poke_ball", 1), "index and id forms")
	ok(not b1.can_use_ball("super_ball", 0) and not b1.can_use_ball(5, 0) and not b1.can_use_ball("poke_ball", 9), "invalid ball / target")
	b1.energy = 0
	ok(not b1.can_use_ball("poke_ball", 0) and not b1.use_ball("poke_ball", 0)["used"] and b1.ball_count("poke_ball") == 3, "no energy -> refused, ball kept")
	b1.energy = 3
	# failure: enemy stays, ball + energy spent, run synced
	force(0.0, 0.0)
	var sig: Array = []
	b1.ball_thrown.connect(func(t: Combatant, ball: BallData, c: float) -> void: sig.append(["thrown", t.id, ball.id, c]))
	b1.capture_failed.connect(func(t: Combatant) -> void: sig.append(["failed", t.id]))
	b1.capture_succeeded.connect(func(t: Combatant) -> void: sig.append(["ok", t.id]))
	var r1: Dictionary = b1.use_ball("poke_ball", 0)
	ok(r1["used"] and not r1["success"] and r1["chance"] == 0.0 and r1.has("roll"), "failed throw result")
	ok(b1.energy == 2 and b1.ball_count("poke_ball") == 2 and run.ball_count("poke_ball") == 2, "failure costs energy + ball (run synced)")
	ok(b1.enemies.size() == 2 and b1.state == Battle.State.PLAYER_TURN, "enemy stays")
	ok(sig == [["thrown", eid2, "poke_ball", 0.0], ["failed", eid2]], "signals on failure %s" % str(sig))
	ok(b1.end_turn() and b1.state != Battle.State.WON, "enemy keeps acting")
	# success on the first of two: removed, battle goes on
	force(1.0, 1.0)
	sig.clear()
	var target: Combatant = b1.enemies[0]
	var r2: Dictionary = b1.use_ball("poke_ball", 0)
	ok(r2["success"] and r2["target"] == target, "success")
	ok(b1.enemies.size() == 1 and b1.enemies[0].id == eid1 and b1.captured == ([target] as Array[Combatant]) and b1.captured_ids == ([eid2] as Array[String]), "captured enemy removed")
	ok(b1.state == Battle.State.PLAYER_TURN and sig[1] == ["ok", eid2], "battle continues")
	ok(run.ball_count("poke_ball") == 1, "run synced after success")
	# kill the last one by cards? capture it instead -> battle won
	var won: Array = [false]
	b1.battle_won.connect(func() -> void: won[0] = true)
	var r3: Dictionary = b1.use_ball("poke_ball", 0)
	ok(r3["success"] and b1.state == Battle.State.WON and won[0] and b1.enemies.is_empty(), "capturing the last enemy wins")
	ok(run.balls.is_empty() and not b1.can_use_ball(0, 0), "no ball left")
	# apply captures after the win
	var deck_before: int = run.deck.size()
	run.record_battle_result(b1.player, [] as Array[String])
	var rows: Array[Dictionary] = run.apply_captures(b1.captured_ids)
	ok(rows.size() == 2 and run.deck.size() == deck_before + 3, "all teaches cards added (2 + 1)")
	var carried2: int = 0
	for c: CardData in run.deck:
		if c.pokemon_id == eid2:
			carried2 += 1
	ok(carried2 == 2 and (rows[0]["cards"] as Array).size() == 2 and rows[0]["first_time"], "cards carried by the captured Pokémon")
	ok(run.captured == ([eid2, eid1] as Array[String]), "captured recorded")
	ok(run.team_carriers().has(eid2) and run.team_carriers().has(eid1), "captured Pokémon are team carriers")
	run.track_team_win()
	ok(int(run.team_progress[eid2]["battles"]) == 1, "team progress counts the captured Pokémon")
	var again: Array[Dictionary] = run.apply_captures([eid2] as Array[String])
	ok(not again[0]["first_time"] and run.captured.size() == 2 and run.deck.size() == deck_before + 5, "recapture stacks cards, captured unique")
	# --- determinism: same seed, same rolls
	force(0.05, 0.95)
	var rolls: Array = []
	for rep: int in 2:
		var rr: RunState = new_run()
		for i: int in 5:
			rr.add_ball("poke_ball")
		var bd: Battle = battle_with(rr, [eid2, eid1], true, 4242)
		var seq: Array = []
		while bd.state == Battle.State.PLAYER_TURN and not bd.ball_ids().is_empty():
			if bd.energy < 1:
				bd.end_turn()
				continue
			var res: Dictionary = bd.use_ball(0, bd.first_living_enemy())
			seq.append([res["success"], snappedf(res["roll"], 0.000001), snappedf(res["chance"], 0.000001)])
		rolls.append(seq)
	ok(rolls[0] == rolls[1] and not rolls[0].is_empty(), "deterministic rolls %s" % str(rolls[0]))
	# status raises chance in battle
	var rs: RunState = new_run()
	rs.add_ball("poke_ball")
	var bs: Battle = battle_with(rs, [eid2], true)
	var c0: float = bs.capture_chance("poke_ball", 0)
	bs.apply_status(bs.enemies[0], "paralysis", 1)
	ok(bs.capture_chance("poke_ball", 0) > c0 or "electric" in bs.enemies[0].type_ids, "status raises battle chance")
	# --- loot
	var lr: RunState = new_run()
	var got: Dictionary = {}
	var r := rng(99)
	for i: int in 400:
		var loot: Dictionary = LootGenerator.generate(gd, lr, "wild", r)
		if not String(loot["ball_id"]).is_empty():
			got[loot["ball_id"]] = int(got.get(loot["ball_id"], 0)) + 1
	ok(got.has("poke_ball") and not got.has("super_ball") and not got.has("hyper_ball"), "zone 1 wild loot: Poké Balls only %s" % str(got))
	ok(int(got["poke_ball"]) > 80 and int(got["poke_ball"]) < 160, "~30%% chance (%d/400)" % int(got["poke_ball"]))
	lr.zone_index = 5
	got.clear()
	for i: int in 600:
		var loot2: Dictionary = LootGenerator.generate(gd, lr, "wild", r)
		if not String(loot2["ball_id"]).is_empty():
			got[loot2["ball_id"]] = int(got.get(loot2["ball_id"], 0)) + 1
	ok(got.has("super_ball") and got.has("hyper_ball") and int(got["hyper_ball"]) < int(got["poke_ball"]), "deep zone: rarer Super/Hyper %s" % str(got))
	for room: String in ["elite", "boss"]:
		var none_seen: bool = true
		for i: int in 100:
			if not String(LootGenerator.generate(gd, lr, room, r)["ball_id"]).is_empty():
				none_seen = false
		ok(none_seen, "no ball loot in %s" % room)
	for i: int in 5:
		lr.add_ball("poke_ball")
	var full_none: bool = true
	for i: int in 100:
		if not String(LootGenerator.generate(gd, lr, "wild", r)["ball_id"]).is_empty():
			full_none = false
	ok(full_none, "no ball loot when the bag is full")
	var ar: RunState = new_run()
	var applied: Dictionary = ar.apply_loot({"money": 0, "ball_id": "poke_ball"})
	ok(applied["ball"] == pb and ar.ball_count("poke_ball") == 1, "apply_loot gives the ball")
	ok(ar.apply_loot({"money": 0})["ball"] == null, "old loot dict without ball_id")
	# --- shop
	var sr: RunState = new_run()
	sr.money = 1000
	var counts: Dictionary = {}
	var shr := rng(5)
	for i: int in 50:
		var inv: ShopInventory = ShopInventory.generate(gd, sr, shr)
		ok(inv.balls.size() >= 1 and inv.balls.size() <= 2, "1-2 ball offers")
		var seen: Dictionary = {}
		for e: ShopEntry in inv.balls:
			ok(e.kind == ShopEntry.KIND_BALL and e.price == e.ball.price and not seen.has(e.ball.id) and e.get_name() == e.ball.display_name, "ball entry")
			seen[e.ball.id] = true
			counts[e.ball.id] = true
	ok(counts.keys() == ["poke_ball"], "zone 1 shop: Poké Ball only")
	var inv2: ShopInventory = ShopInventory.generate(gd, sr, shr)
	var m0: int = sr.money
	ok(inv2.buy_ball(0) and sr.money == m0 - inv2.balls[0].price and sr.ball_total() == 1 and inv2.balls[0].sold, "buy ball")
	ok(not inv2.buy_ball(0), "sold slot")
	for i: int in 4:
		sr.add_ball("poke_ball")
	var inv3: ShopInventory = ShopInventory.generate(gd, sr, shr)
	ok(not inv3.can_buy_ball(0) and not inv3.buy_ball(0) and sr.ball_total() == 5, "full bag: cannot buy")
	sr.zone_index = 6
	counts.clear()
	for i: int in 80:
		for e: ShopEntry in ShopInventory.generate(gd, sr, shr).balls:
			counts[e.ball.id] = true
	ok(counts.size() == 3, "deep shop offers all balls")
	# --- events
	var er: RunState = new_run()
	var ev: Dictionary = gd.get_event("sac_abandonne")
	ok(not ev.is_empty() and not gd.get_event("chercheur_pokemon").is_empty(), "2 ball events")
	ok(gd.get_event_pool().has("sac_abandonne") and gd.get_event_pool().has("chercheur_pokemon"), "in the event pool")
	var txt: String = EventResolver.apply_effects(ev["options"][0]["effects"], er, gd, rng(1))
	ok(er.ball_count("poke_ball") == 2 and txt.contains("2 Balls obtenues"), "event gives 2 Poké Balls: %s" % txt)
	txt = EventResolver.apply_effects(gd.get_event("chercheur_pokemon")["options"][0]["effects"], er, gd, rng(1))
	ok(er.ball_count("super_ball") == 1 and txt.contains("Ball obtenue : Super Ball"), "event gives a Super Ball: %s" % txt)
	for i: int in 2:
		er.add_ball("poke_ball")
	txt = EventResolver.apply_effects(ev["options"][0]["effects"], er, gd, rng(1))
	ok(er.ball_total() == 5 and not txt.contains("Ball"), "event respects the bag limit: %s" % txt)
	# --- save
	var vr: RunState = new_run()
	vr.set_zones(gd.draw_zones(rng(3)))
	vr.start_act(gd, 12345)
	vr.add_ball("poke_ball"); vr.add_ball("poke_ball"); vr.add_ball("hyper_ball")
	vr.apply_captures([eid2] as Array[String])
	var d1: Dictionary = SaveGame.to_dict(vr, {})
	var json: Variant = JSON.parse_string(JSON.stringify(d1))
	var res2: Dictionary = SaveGame.from_dict(json, gd)
	ok(res2["ok"], "save loads: %s" % res2["error"])
	if res2["ok"]:
		var lr2: RunState = res2["run"]
		ok(lr2.balls == {"poke_ball": 2, "hyper_ball": 1} and lr2.captured == ([eid2] as Array[String]), "balls + captured round trip %s" % str(lr2.balls))
		ok(typeof(lr2.balls["poke_ball"]) == TYPE_INT, "ball counts are ints")
		ok(lr2.team_carriers().has(eid2), "captured carrier survives the save")
	var old: Dictionary = (json as Dictionary).duplicate(true)
	old["run"].erase("balls"); old["run"].erase("captured")
	var res3: Dictionary = SaveGame.from_dict(old, gd)
	ok(res3["ok"] and (res3["run"] as RunState).balls.is_empty() and (res3["run"] as RunState).captured.is_empty(), "old save without keys loads empty")
	var bad: Dictionary = (json as Dictionary).duplicate(true)
	bad["run"]["balls"] = {"master_ball": 1}
	ok(not SaveGame.from_dict(bad, gd)["ok"], "unknown ball refused")
	bad["run"]["balls"] = []
	ok(not SaveGame.from_dict(bad, gd)["ok"], "balls not a dict refused")
	bad["run"]["balls"] = {"poke_ball": 0}
	ok(not SaveGame.from_dict(bad, gd)["ok"], "zero count refused")
	bad["run"]["balls"] = {}
	bad["run"]["captured"] = ["missingno"]
	ok(not SaveGame.from_dict(bad, gd)["ok"], "unknown captured refused")
	bad["run"]["captured"] = "x"
	ok(not SaveGame.from_dict(bad, gd)["ok"], "captured not an array refused")
	# --- data validation
	var base: Dictionary = rd(D + "balls.json")
	ok(load_with({}), "real data loads through load_with")
	var cases: Array = []
	var c1: Dictionary = base.duplicate(true); c1["max_carried"] = 0; cases.append(["max 0", c1])
	var c2: Dictionary = base.duplicate(true); c2["balls"]["poke_ball"].erase("base_chance"); cases.append(["no base", c2])
	var c3: Dictionary = base.duplicate(true); c3["balls"]["poke_ball"]["price"] = -1; cases.append(["price < 0", c3])
	var c4: Dictionary = base.duplicate(true); c4["capture"]["status_bonus"]["toxic"] = 2; cases.append(["unknown status", c4])
	var c5: Dictionary = base.duplicate(true); c5["capture"]["status_bonus"]["sleep"] = 0.5; cases.append(["bonus < 1", c5])
	var c6: Dictionary = base.duplicate(true); c6["capture"]["allowed_room_types"] = ["league"]; cases.append(["league room", c6])
	var c7: Dictionary = base.duplicate(true); c7["capture"]["min_chance"] = 0.99; cases.append(["min > max", c7])
	var c8: Dictionary = base.duplicate(true); c8["capture"]["hp_factor"] = 1.5; cases.append(["k > 1", c8])
	var c9: Dictionary = base.duplicate(true); c9["loot"]["wild"]["chance"] = 2; cases.append(["loot chance > 1", c9])
	var c10: Dictionary = base.duplicate(true); c10["loot"]["wild"]["weights"] = {"master_ball": 1}; cases.append(["loot unknown ball", c10])
	var c11: Dictionary = base.duplicate(true); c11["shop"]["count_max"] = 0; cases.append(["shop max < min", c11])
	var c12: Dictionary = base.duplicate(true); c12["capture"]["energy_cost"] = -1; cases.append(["cost < 0", c12])
	var c13: Dictionary = base.duplicate(true); c13["balls"]["poke_ball"]["min_zone"] = 0; cases.append(["min_zone 0", c13])
	var c14: Dictionary = base.duplicate(true); c14.erase("capture"); cases.append(["no capture", c14])
	var c15: Dictionary = base.duplicate(true); c15["loot"]["center"] = c15["loot"]["wild"]; cases.append(["loot non-fight room", c15])
	for i: int in cases.size():
		ok(not load_with({"balls": wr("t23_b%d.json" % i, cases[i][1])}), "rejects: %s" % cases[i][0])
	var evs: Dictionary = rd(D + "events.json")
	var e1: Dictionary = evs.duplicate(true); e1["events"][4]["options"][0]["effects"][0]["ball"] = "master_ball"
	ok(not load_with({"events": wr("t23_e1.json", e1)}), "rejects add_ball unknown ball")
	var e2: Dictionary = evs.duplicate(true); e2["events"][4]["options"][0]["effects"][0]["count"] = 0
	ok(not load_with({"events": wr("t23_e2.json", e2)}), "rejects add_ball count 0")
	print("t23 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
