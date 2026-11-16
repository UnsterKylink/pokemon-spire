extends SceneTree
var passes := 0
var fails := 0
var hits: Array = []
const SCR := "/tmp/claude-0/-home-user-pokemon-spire/a2b72075-2d8b-51e2-a914-9e4b612c161d/scratchpad/"
const IDS := ["normal","fire","water","electric","grass","ice","fighting","poison","ground","flying","psychic","bug","rock","ghost","dragon","dark","steel","fairy"]
const NAMES := {"normal":"Normal","fire":"Feu","water":"Eau","electric":"Électrik","grass":"Plante","ice":"Glace","fighting":"Combat","poison":"Poison","ground":"Sol","flying":"Vol","psychic":"Psy","bug":"Insecte","rock":"Roche","ghost":"Spectre","dragon":"Dragon","dark":"Ténèbres","steel":"Acier","fairy":"Fée"}
# attacker: [SE, NVE, IM]
const TABLE := {
"normal":[[],["rock","steel"],["ghost"]],
"fire":[["grass","ice","bug","steel"],["fire","water","rock","dragon"],[]],
"water":[["fire","ground","rock"],["water","grass","dragon"],[]],
"electric":[["water","flying"],["electric","grass","dragon"],["ground"]],
"grass":[["water","ground","rock"],["fire","grass","poison","flying","bug","dragon","steel"],[]],
"ice":[["grass","ground","flying","dragon"],["fire","water","ice","steel"],[]],
"fighting":[["normal","ice","rock","dark","steel"],["poison","flying","psychic","bug","fairy"],["ghost"]],
"poison":[["grass","fairy"],["poison","ground","rock","ghost"],["steel"]],
"ground":[["fire","electric","poison","rock","steel"],["grass","bug"],["flying"]],
"flying":[["grass","fighting","bug"],["electric","rock","steel"],[]],
"psychic":[["fighting","poison"],["psychic","steel"],["dark"]],
"bug":[["grass","psychic","dark"],["fire","fighting","poison","flying","ghost","steel","fairy"],[]],
"rock":[["fire","ice","flying","bug"],["fighting","ground","steel"],[]],
"ghost":[["psychic","ghost"],["dark"],["normal"]],
"dragon":[["dragon"],["steel"],["fairy"]],
"dark":[["psychic","ghost"],["fighting","dark","fairy"],[]],
"steel":[["ice","rock","fairy"],["fire","water","electric","steel"],[]],
"fairy":[["fighting","dragon","dark"],["fire","poison","steel"],[]]}

func ok(c: bool, msg: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		print("FAIL ", msg)

func sa(a: Array) -> Array[String]:
	var r: Array[String] = []
	for x in a: r.append(String(x))
	return r

func mk(types: Array, actions: Array, hp: int = 50) -> Combatant:
	return Combatant.from_dict("x", {"name": "X", "types": types, "max_hp": hp, "sprite": "s", "pattern": "sequence", "actions": actions})

func pl(types: Array, hp: int = 500) -> Combatant:
	return Combatant.from_dict("p", {"name": "P", "types": types, "max_hp": hp, "sprite": "s"})

func battle(gd: GameData, p: Combatant, es: Array[Combatant], card_ids: Array) -> Battle:
	var d: Array[CardData] = []
	for c: String in card_ids: d.append(gd.get_card(c))
	var r := RandomNumberGenerator.new(); r.seed = 1
	var b := Battle.new(p, es, d, 3, 5, r, gd.get_type_chart())
	b.hit_resolved.connect(func(t: Combatant, a: int, m: float) -> void: hits.append([t, a, m]))
	b.start()
	return b

func write_json(path: String, d: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE); f.store_string(JSON.stringify(d)); f.close()

func rd(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p)) as Dictionary

func loads(mod: Callable) -> bool:
	var c := rd("res://assets/data/cards.json"); var p := rd("res://assets/data/pokemon.json"); var t := rd("res://assets/data/types.json")
	mod.call(c, p, t)
	write_json(SCR + "t8_c.json", c); write_json(SCR + "t8_p.json", p); write_json(SCR + "t8_t.json", t)
	var g := GameData.new()
	return g.load_all(SCR + "t8_c.json", SCR + "t8_p.json", SCR + "t8_t.json")

func _initialize() -> void:
	var gd := GameData.new()
	ok(gd.load_all(), "real data loads")
	var chart := gd.get_type_chart()
	ok(chart.get_type_ids().size() == 18, "18 types")
	for id: String in IDS:
		ok(gd.get_type_name(id) == NAMES[id], "name " + id)
		ok(gd.get_type_color(id) != Color.WHITE, "colour " + id)
	var cols := {}
	for id: String in IDS: cols[gd.get_type_color(id).to_html()] = true
	ok(cols.size() == 18, "18 distinct colours")
	var pairs := 0
	for a: String in IDS:
		for d: String in IDS:
			var want := 1.0
			if (TABLE[a][0] as Array).has(d): want = 1.5
			elif (TABLE[a][1] as Array).has(d): want = 0.5
			elif (TABLE[a][2] as Array).has(d): want = 0.0
			ok(is_equal_approx(chart.damage_multiplier(a, sa([d])), want), "pair %s>%s" % [a, d])
			ok(is_equal_approx(chart.damage_multiplier_vs(a, d), want), "pair_vs %s>%s" % [a, d])
			pairs += 1
	ok(pairs == 324, "324 pairs")
	ok(chart.damage_multiplier("", sa(["fire"])) == 1.0 and chart.damage_multiplier("zzz", sa(["fire"])) == 1.0, "empty/unknown attack neutral")
	ok(chart.damage_multiplier("fire", sa(["zzz"])) == 1.0, "unknown defender neutral")
	ok(chart.damage_multiplier("fire", sa([])) == 1.0, "no defender type neutral")
	var m := func(a: String, d: Array) -> float: return chart.damage_multiplier(a, sa(d))
	ok(is_equal_approx(m.call("fire", ["grass","poison"]), 1.5), "fire>grass/poison 1.5")
	ok(is_equal_approx(m.call("fire", ["grass","bug"]), 2.25), "fire>grass/bug 2.25")
	ok(is_equal_approx(m.call("fire", ["water","rock"]), 0.25), "fire>water/rock .25")
	ok(m.call("ground", ["flying","rock"]) == 0.0, "ground>flying/rock 0")
	ok(m.call("electric", ["rock","ground"]) == 0.0, "electric>rock/ground 0")
	ok(is_equal_approx(m.call("normal", ["rock","steel"]), 0.25), "normal>rock/steel .25")
	ok(m.call("ground", ["fire","flying"]) == 0.0, "ground>fire/flying 0")
	ok(m.call("ground", ["flying","fire"]) == 0.0, "order independent")
	var f := func(b: int, a: String, d: Array) -> int: return chart.final_damage(b, a, sa(d))
	ok(f.call(7, "fire", ["grass"]) == 10, "7*1.5=10")
	ok(f.call(3, "fire", ["water"]) == 1, "3*.5=1")
	ok(f.call(1, "fire", ["water"]) == 0, "1*.5=0")
	ok(f.call(6, "fire", ["grass","bug"]) == 13, "6*2.25=13")
	ok(f.call(5, "fire", ["water","rock"]) == 1, "5*.25=1")
	ok(f.call(50, "ground", ["flying","rock"]) == 0, "immune 0")
	# roster types
	var want_types := {"rattata":["normal"],"pidgey":["normal","flying"],"caterpie":["bug"],"weedle":["bug","poison"],"zubat":["poison","flying"],"geodude":["rock","ground"],"poliwag":["water"],"oddish":["grass","poison"],"pikachu":["electric"]}
	for k: String in want_types:
		ok(gd.create_enemy(k).type_ids == sa(want_types[k]), "types " + k)
	ok(gd.create_player("salameche").type_ids == sa(["fire"]), "salameche fire")
	ok(gd.create_enemy("geodude").get_primary_type() == "rock", "primary type")
	# immune hit: deals 0, block untouched, hit_resolved 0
	var geo := mk(["rock","ground"], [{"type": "block", "value": 5}])
	geo.block = 5
	var b := battle(gd, pl(["fire"]), [geo] as Array[Combatant], ["eclair"])
	hits.clear()
	ok(b.play_card(0, 0), "play eclair")
	ok(geo.hp == 50 and geo.block == 5, "immune: hp %d block %d" % [geo.hp, geo.block])
	ok(hits.size() == 1 and hits[0][1] == 0 and hits[0][2] == 0.0, "hit_resolved 0")
	ok(geo.take_damage(0) == 0 and geo.block == 5, "take_damage(0) keeps block")
	# x2.25 hit: water card (7) vs rock/ground
	var geo2 := mk(["rock","ground"], [{"type": "block", "value": 5}])
	var b2 := battle(gd, pl(["fire"]), [geo2] as Array[Combatant], ["pistolet_a_o"])
	hits.clear(); b2.play_card(0, 0)
	ok(hits.size() == 1 and hits[0][1] == 15 and is_equal_approx(hits[0][2], 2.25) and geo2.hp == 35, "water vs rock/ground 15 x2.25")
	# enemy intent vs dual-type player: fire 6 vs grass/poison -> floori(13.5)=13
	var fe := mk(["fire"], [{"type": "attack", "value": 6}])
	hits.clear()
	var b3 := battle(gd, pl(["grass","bug"]), [fe] as Array[Combatant], ["abri"])
	ok(fe.intent.value == 13, "intent 6*2.25=13: %d" % fe.intent.value)
	var p3 := b3.player
	b3.end_turn()
	ok(p3.hp == 500 - 13, "executed = displayed: hp %d" % p3.hp)
	ok(hits.size() == 1 and hits[0][0] == p3 and hits[0][1] == 13 and is_equal_approx(hits[0][2], 2.25), "enemy hit_resolved 2.25")
	# immune intent: ground attacker vs flying player -> Attaque 0, hit 0 multiplier, block kept
	var ge := mk(["ground"], [{"type": "attack", "value": 9}])
	hits.clear()
	var b4 := battle(gd, pl(["fire","flying"]), [ge] as Array[Combatant], ["abri"])
	ok(ge.intent.value == 0, "immune intent 0")
	b4.player.block = 4
	b4.end_turn()
	ok(b4.player.hp == 500 and hits.size() == 1 and hits[0][2] == 0.0, "immune enemy hit")
	# all encounters build
	ok(gd.get_enemy_ids().size() == 824, "824 enemies (story 013b: 98 + 720 roster, 018: +6 legendary)")
	ok(gd.get_encounter_order().size() == 98, "98 encounters in order")
	for enc: String in gd.get_encounter_order():
		var es := gd.create_enemies(enc)
		var bb := Battle.new(gd.create_player("salameche"), es, gd.get_starter_deck("salameche"), 3, 5, RandomNumberGenerator.new(), chart)
		bb.start()
		ok(es.size() >= 1 and es.size() <= 3, "encounter " + enc)
		for en: Combatant in bb.enemies:
			ok(en.intent != null and not en.type_ids.is_empty(), "intent " + enc)
	# rejections
	ok(loads(func(_c, _p, _t): pass), "unmodified copy loads")
	ok(not loads(func(_c, p, _t): p["enemies"]["zubat"]["types"] = ["poison","flying","bug"]), "reject 3 types")
	ok(not loads(func(_c, p, _t): p["enemies"]["zubat"]["types"] = ["poison","poison"]), "reject duplicate types")
	ok(not loads(func(_c, p, _t): p["enemies"]["zubat"]["types"] = ["nope"]), "reject unknown type")
	ok(not loads(func(_c, p, _t): p["enemies"]["zubat"]["types"] = []), "reject empty types")
	ok(not loads(func(_c, p, _t): p["enemies"]["zubat"].erase("types")), "reject missing types")
	ok(not loads(func(_c, p, _t): p["player"]["salameche"]["types"] = ["fire","fire"]), "reject player dup")
	ok(not loads(func(_c, _p, t): t["chart"]["fire"]["immune"] = ["nope"]), "reject immune unknown")
	ok(not loads(func(_c, _p, t): t["chart"]["fire"]["super_effective"].append("nope")), "reject SE unknown")
	ok(not loads(func(_c, _p, t): t["chart"]["ground"]["super_effective"].append("flying")), "reject pair in SE and IM")
	ok(not loads(func(_c, _p, t): t["chart"]["normal"]["not_very_effective"].append("ghost")), "reject pair in NVE and IM")
	ok(not loads(func(_c, _p, t): t["multipliers"]["immune"] = 0.1), "reject immune != 0")
	ok(not loads(func(_c, _p, t): t["multipliers"].erase("immune")), "reject missing immune mult")
	ok(not loads(func(_c, _p, t): t["multipliers"]["not_very_effective"] = 0), "reject NVE 0")
	ok(not loads(func(_c, _p, t): t["types"].erase("fairy")), "reject <18 types")
	print("RESULT pass=%d fail=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
