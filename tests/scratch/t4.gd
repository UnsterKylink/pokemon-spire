extends SceneTree
var fails: int = 0
var passes: int = 0
const SCR := "user://"

func ok(c: bool, msg: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		print("FAIL ", msg)

func rj(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))

func wj(name: String, d: Dictionary) -> String:
	var f := FileAccess.open(SCR + name, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	return SCR + name

func rng(seed_v: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	return r

func ids(offers: Array[RewardOffer]) -> Array:
	var a: Array = []
	for o: RewardOffer in offers: a.append(o.card.id)
	return a

func _initialize() -> void:
	var d := GameData.new()
	ok(d.load_all(), "real data loads")
	var run := RunState.create(d, "salameche")
	ok(run.deck.size() == 10 and run.max_hp == 90 and run.hp == 90, "run init")
	var starter_before: int = d.get_starter_deck("salameche").size()
	run.hp = 40
	var pc: Combatant = run.build_player_combatant()
	ok(pc.hp == 40 and pc.max_hp == 90 and pc.block == 0 and pc.get_primary_type() == "fire" and pc.display_name == "Salamèche", "combatant from run")
	pc.hp = 12
	run.record_battle_result(pc)
	ok(run.hp == 12, "hp persisted")
	pc.hp = -5
	run.record_battle_result(pc)
	ok(run.hp == 0, "clamp low")
	pc.hp = 999
	run.record_battle_result(pc)
	ok(run.hp == 90, "clamp high")
	run.hp = 33
	run.add_card(d.get_card("eclair"))
	ok(run.deck.size() == 11 and d.get_starter_deck("salameche").size() == starter_before, "add_card doesn't touch starter")
	ok(RunState.create(d, "salameche").deck.size() == 10, "new run fresh deck")
	ok(run.deck_counts()["griffe@salameche"] == 5 and run.deck_counts()["eclair@pikachu"] == 1, "counts")
	var ent: Array[Dictionary] = run.get_deck_entries()
	ok(ent.size() == 4, "entries grouped")
	# battle from run
	var enemies: Array[Combatant] = d.create_enemies("solo")
	var b: Battle = run.create_battle(enemies, d.get_type_chart(), rng(1))
	ok(b.player.hp == 33 and b.player.max_hp == 90, "battle uses persisted hp")
	ok(b.draw_pile.size() + b.hand.size() + b.discard_pile.size() == 11, "full deck in battle")
	b.start()
	b.end_turn(); b.end_turn(); b.end_turn()
	ok(run.deck.size() == 11, "run deck untouched by battle")
	var from_counts: int = 0
	for c: CardData in run.deck: from_counts += 1
	ok(from_counts == 11 and run.hp == 33, "run hp untouched mid-battle")
	# data
	var pool: Array[CardData] = d.get_reward_pool("salameche")
	var seen: Dictionary = {}
	var has_atk: bool = false
	for c: CardData in pool:
		seen[c.id] = true
		if c.rarity == "starter": ok(false, "starter in pool")
	ok(seen.size() >= 25 and seen.size() == pool.size(), "pool >=25 distinct: %d" % pool.size())
	var types: Dictionary = {}
	var costs: Dictionary = {}
	var rc: Dictionary = {}
	for c: CardData in pool:
		types[c.type_id] = true; costs[c.cost] = true; rc[c.rarity] = int(rc.get(c.rarity, 0)) + 1
	ok(types.size() == 19 and types.has("") and costs.has(0) and costs.has(3) and rc["rare"] >= 5, "pool variety " + str(rc) + str(types.keys()))
	ok(d.get_offer_count() == 3, "offer_count")
	for e: String in d.get_enemy_ids():
		ok(d.create_enemy(e) != null, "enemy " + e)
	for enc: String in d.get_encounter_order():
		ok(not d.create_enemies(enc).is_empty(), "enc " + enc)
	# generator
	var rd: Array[String] = ["rattata"]
	for s: int in 200:
		var offers: Array[RewardOffer] = RewardGenerator.generate(d, "salameche", rd, rng(s))
		var u: Dictionary = {}
		var stolen: int = 0
		for o: RewardOffer in offers:
			u[o.card.id] = true
			if o.stolen:
				stolen += 1
				ok(o.card.id in ["vive_attaque", "croc_fatal"] and o.source_pokemon_name == "Rattata" and o.card.kind == "attack", "stolen valid")
			ok(o.card.rarity != "starter", "no starter")
		ok(offers.size() == 3 and u.size() == 3 and stolen == 1, "3 distinct 1 stolen seed %d" % s)
	var multi: Array[String] = ["pidgey", "geodude", "zubat"]
	for s: int in 100:
		var offers: Array[RewardOffer] = RewardGenerator.generate(d, "salameche", multi, rng(s))
		var u: Dictionary = {}
		var st: int = 0
		for o: RewardOffer in offers:
			u[o.card.id] = true
			if o.stolen: st += 1
		ok(u.size() == 3 and st == 1, "multi")
	var none: Array[String] = []
	for s: int in 50:
		var offers: Array[RewardOffer] = RewardGenerator.generate(d, "salameche", none, rng(s))
		var st: int = 0
		for o: RewardOffer in offers:
			if o.stolen: st += 1
		ok(offers.size() == 3 and st == 0, "no teach none stolen")
	ok(ids(RewardGenerator.generate(d, "salameche", rd, rng(42))) == ids(RewardGenerator.generate(d, "salameche", rd, rng(42))), "deterministic")
	var distinct_orders: Dictionary = {}
	for s: int in 50:
		distinct_orders[str(ids(RewardGenerator.generate(d, "salameche", rd, rng(s))))] = true
	ok(distinct_orders.size() > 10, "varied")
	# rarity frequencies: first card of each offer (no stolen)
	var r := rng(7)
	var cnt: Dictionary = {"common": 0, "uncommon": 0, "rare": 0}
	var n: int = 3000
	for i: int in n:
		var offers: Array[RewardOffer] = RewardGenerator.generate(d, "salameche", none, r)
		for o: RewardOffer in offers:
			cnt[o.card.rarity] += 1
	var total: float = n * 3.0
	print("freq ", cnt, " ", cnt["common"] / total, " ", cnt["uncommon"] / total, " ", cnt["rare"] / total)
	ok(absf(cnt["common"] / total - 0.6) < 0.05 and absf(cnt["uncommon"] / total - 0.3) < 0.05 and absf(cnt["rare"] / total - 0.1) < 0.05, "rarity freq (all 3 slots)")
	var cnt1: Dictionary = {"common": 0, "uncommon": 0, "rare": 0}
	for i: int in n:
		var o1: Array[RewardOffer] = RewardGenerator.generate(d, "salameche", none, r)
		cnt1[o1[0].card.rarity] += 1
	print("freq first ", cnt1)
	# bad data copies
	var P := "res://assets/data/"
	var cards := rj(P + "cards.json"); var pk := rj(P + "pokemon.json"); var rw := rj(P + "rewards.json")
	var cp: String = wj("c.json", cards); var pp: String = wj("p.json", pk); var rp: String = wj("r.json", rw)
	var tp: String = P + "types.json"
	ok(GameData.new().load_all(cp, pp, tp, rp), "temp copies good")
	var bad: Dictionary = rw.duplicate(true); bad["player_pool"]["salameche"].append("nope")
	ok(not GameData.new().load_all(cp, pp, tp, wj("r1.json", bad)), "unknown reward id rejected")
	bad = rw.duplicate(true); bad["player_pool"]["salameche"] = ["eclair", "tranch_herbe"]
	ok(not GameData.new().load_all(cp, pp, tp, wj("r2.json", bad)), "pool too small rejected")
	bad = rw.duplicate(true); bad["player_pool"]["salameche"] = ["abri", "rugissement", "mimi_queue", "mur_de_fumee"]
	bad["rarity_weights"]["starter"] = 1
	ok(not GameData.new().load_all(cp, pp, tp, wj("r2b.json", bad)), "no attack in pool rejected")
	bad = rw.duplicate(true); bad["rarity_weights"]["rare"] = 0
	ok(not GameData.new().load_all(cp, pp, tp, wj("r3.json", bad)), "weight 0 rejected")
	bad = rw.duplicate(true); bad["rarity_weights"]["mythic"] = 5
	ok(not GameData.new().load_all(cp, pp, tp, wj("r4.json", bad)), "unknown rarity weight rejected")
	bad = rw.duplicate(true); bad["offer_count"] = 0
	ok(not GameData.new().load_all(cp, pp, tp, wj("r4b.json", bad)), "offer_count 0 rejected")
	var bc: Dictionary = cards.duplicate(true); bc["cards"]["eclair"]["rarity"] = "mythic"
	ok(not GameData.new().load_all(wj("c1.json", bc), pp, tp, rp), "unknown card rarity rejected")
	bc = cards.duplicate(true); bc["cards"]["eclair"].erase("rarity")
	ok(not GameData.new().load_all(wj("c2.json", bc), pp, tp, rp), "missing rarity rejected")
	var bp: Dictionary = pk.duplicate(true); bp["enemies"]["rattata"]["teaches"] = ["nope"]
	ok(not GameData.new().load_all(cp, wj("p1.json", bp), tp, rp), "teaches unknown rejected")
	bp = pk.duplicate(true); bp["enemies"]["rattata"]["teaches"] = ["abri"]
	ok(not GameData.new().load_all(cp, wj("p2.json", bp), tp, rp), "teaches skill rejected")
	bp = pk.duplicate(true); bp["enemies"]["rattata"].erase("teaches")
	var d2 := GameData.new()
	ok(d2.load_all(cp, wj("p3.json", bp), tp, rp) and d2.get_enemy_teaches("rattata").is_empty(), "no teaches ok")
	var o2: Array[RewardOffer] = RewardGenerator.generate(d2, "salameche", rd, rng(3))
	ok(o2.size() == 3 and not o2[0].stolen and not o2[1].stolen and not o2[2].stolen, "defeated w/o teaches -> none stolen")
	print("RESULT pass=", passes, " fail=", fails)
	quit(0)
