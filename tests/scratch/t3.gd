extends SceneTree
var fails: int = 0
var passes: int = 0
const SCR := "/tmp/claude-0/-home-user-pokemon-spire/a2b72075-2d8b-51e2-a914-9e4b612c161d/scratchpad/"
const IDS := ["normal", "fire", "water", "electric", "grass", "poison", "ground", "flying", "bug", "rock"]
# independent copy: attacker -> [SE list, NVE list]
const TABLE := {
	"normal": [[], ["rock"]],
	"fire": [["grass", "bug"], ["fire", "water", "rock"]],
	"water": [["fire", "ground", "rock"], ["water", "grass"]],
	"electric": [["water", "flying"], ["electric", "grass", "ground"]],
	"grass": [["water", "ground", "rock"], ["fire", "grass", "poison", "flying", "bug"]],
	"poison": [["grass"], ["poison", "ground", "rock"]],
	"ground": [["fire", "electric", "poison", "rock"], ["grass", "bug", "flying"]],
	"flying": [["grass", "bug"], ["electric", "rock"]],
	"bug": [["grass"], ["fire", "poison", "flying"]],
	"rock": [["fire", "flying", "bug"], ["ground"]],
}
var hits: Array = []

func ok(c: bool, msg: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		print("FAIL ", msg)

func mk(t: String, actions: Array, hp: int = 50) -> Combatant:
	return Combatant.from_dict("x", {"name": "X", "types": [t], "max_hp": hp, "sprite": "s", "pattern": "sequence", "actions": actions})

func pl(t: String = "fire", hp: int = 500) -> Combatant:
	return Combatant.from_dict("p", {"name": "P", "types": [t], "max_hp": hp, "sprite": "s"})

func battle(gd: GameData, p: Combatant, es: Array[Combatant], card_ids: Array) -> Battle:
	var d: Array[CardData] = []
	for c: String in card_ids:
		d.append(gd.get_card(c))
	var r := RandomNumberGenerator.new(); r.seed = 1
	var b := Battle.new(p, es, d, 3, 5, r, gd.get_type_chart())
	b.hit_resolved.connect(func(t: Combatant, a: int, m: float) -> void: hits.append([t, a, m]))
	b.start()
	return b

func tweak(src_cards: bool, mod: Callable, name: String) -> bool:
	# writes temp copies with a modification, returns GameData.load_all result
	var cards := JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/cards.json")) as Dictionary
	var pk := JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/pokemon.json")) as Dictionary
	var ty := JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/types.json")) as Dictionary
	mod.call(cards, pk, ty)
	for pair: Array in [[cards, "c"], [pk, "p"], [ty, "t"]]:
		var f := FileAccess.open(SCR + name + "_" + pair[1] + ".json", FileAccess.WRITE)
		f.store_string(JSON.stringify(pair[0]))
		f.close()
	var gd := GameData.new()
	return gd.load_all(SCR + name + "_c.json", SCR + name + "_p.json", SCR + name + "_t.json")

func _initialize() -> void:
	var gd := GameData.new()
	ok(gd.load_all(), "real data loads")
	var chart := gd.get_type_chart()
	ok(chart.get_type_ids().size() == 18, "18 types")
	# 18x18 pair table now covered by t8.gd
	ok(chart.damage_multiplier_vs("", "fire") == 1.0, "empty attack neutral")
	ok(chart.damage_multiplier_vs("zzz", "fire") == 1.0, "unknown attack neutral")
	ok(chart.damage_multiplier_vs("fire", "zzz") == 1.0, "unknown defender neutral")
	ok(chart.final_damage(7, "fire", ["grass"] as Array[String]) == 10, "7*1.5=10")
	ok(chart.final_damage(3, "fire", ["water"] as Array[String]) == 1, "3*.5=1")
	ok(chart.final_damage(1, "fire", ["water"] as Array[String]) == 0, "1*.5=0")
	ok(chart.final_damage(6, "", ["fire"] as Array[String]) == 6, "typeless neutral")
	ok(gd.get_type_name("electric") == "Électrik" and gd.get_type_name("bug") == "Insecte", "names")
	ok(gd.get_type_color("fire") != Color.WHITE, "color")
	# every attack card and pokemon typed
	for cid: String in ["griffe", "flammeche", "danse_flamme", "vive_attaque", "crocs_feu", "draco_griffe", "pistolet_a_o", "tranch_herbe", "eclair", "jet_de_pierres"]:
		ok(chart.is_known_type(gd.get_card(cid).type_id), "card typed " + cid)
	ok(gd.get_card("abri").type_id == "", "skill untyped")
	ok(gd.create_player("salameche").get_primary_type() == "fire", "player fire")
	# card vs bug with 5 block
	var bug := mk("bug", [{"type": "block", "value": 5}])
	bug.add_block(5)
	var b := battle(gd, pl(), [bug] as Array[Combatant], ["flammeche"])
	hits.clear()
	bug.block = 5
	ok(b.play_card(0, 0), "play fire card")
	ok(bug.hp == 50 - 7 and bug.block == 0, "12 final: 5 absorbed, 7 lost (hp %d block %d)" % [bug.hp, bug.block])
	ok(hits.size() == 1 and hits[0][0] == bug and hits[0][1] == 12 and is_equal_approx(hits[0][2], 1.5), "hit_resolved card 12 x1.5")
	# NVE card: flammeche (8) on rock -> 4
	var rock := mk("rock", [{"type": "attack", "value": 5}])
	var b2 := battle(gd, pl(), [rock] as Array[Combatant], ["flammeche"])
	hits.clear()
	b2.play_card(0, 0)
	ok(rock.hp == 46 and hits[0][1] == 4 and is_equal_approx(hits[0][2], 0.5), "fire vs rock 4")
	# neutral card emits multiplier 1
	var nb := mk("normal", [{"type": "attack", "value": 5}])
	var b3 := battle(gd, pl(), [nb] as Array[Combatant], ["griffe"])
	hits.clear()
	b3.play_card(0, 0)
	ok(nb.hp == 44 and hits.size() == 1 and hits[0][2] == 1.0, "neutral hit emitted x1")
	# skill: no hit
	var b4 := battle(gd, pl(), [mk("normal", [{"type": "attack", "value": 5}])] as Array[Combatant], ["abri"])
	hits.clear()
	b4.play_card(0)
	ok(hits.is_empty(), "skill emits no hit")
	# enemy water 6 vs fire player = 9; intent == dealt
	var water := mk("water", [{"type": "attack", "value": 6}])
	var p := pl()
	var b5 := battle(gd, p, [water] as Array[Combatant], ["abri"])
	ok(water.intent.value == 9 and water.intent.display_text() == "Attaque 9", "intent shows 9: " + water.intent.display_text())
	hits.clear()
	var shown := water.intent.value
	var before := p.hp
	b5.end_turn()
	ok(before - p.hp == shown and shown == 9, "dealt == displayed")
	ok(hits.size() == 1 and hits[0][0] == p and hits[0][1] == 9 and is_equal_approx(hits[0][2], 1.5), "hit_resolved enemy 9 x1.5")
	# enemy NVE: grass 5 vs fire -> 2
	var gr := mk("grass", [{"type": "attack", "value": 5}])
	var p2 := pl()
	var b6 := battle(gd, p2, [gr] as Array[Combatant], ["abri"])
	hits.clear()
	var show2 := gr.intent.value
	b6.end_turn()
	ok(show2 == 2 and p2.hp == 498 and is_equal_approx(hits[0][2], 0.5), "grass 5 vs fire = 2")
	# player block absorbs after multiplier: player block 4, water 6 -> 9: 4 absorbed, 5 lost
	var w2 := mk("water", [{"type": "attack", "value": 6}])
	var p3 := pl()
	var b7 := battle(gd, p3, [w2] as Array[Combatant], ["abri"])
	b7.play_card(0)  # block 5 -> hand empty
	b7.end_turn()
	ok(p3.hp == 500 - 4, "block after multiplier: hp %d" % p3.hp)
	# strength before multiplier
	var st := mk("water", [{"type": "buff", "value": 1}, {"type": "attack", "value": 5}])
	var p4 := pl()
	var b8 := battle(gd, p4, [st] as Array[Combatant], ["abri"])
	b8.end_turn()  # buff
	ok(st.strength == 1 and st.intent.type == "attack" and st.intent.value == 9, "(5+1)*1.5=9 (not 8): %d" % st.intent.value)
	b8.end_turn()
	ok(p4.hp == 491, "strength plus multiplier dealt 9")
	# no chart injected -> neutral
	var r := RandomNumberGenerator.new()
	var bn := Battle.new(pl(), [mk("water", [{"type": "attack", "value": 6}])] as Array[Combatant], [] as Array[CardData], 3, 5, r)
	bn.start()
	ok(bn.enemies[0].intent.value == 6, "null chart neutral")
	# all enemies + encounters build
	ok(gd.get_enemy_ids().size() == 824, "824 enemies (story 013 +22 league, 013b +720 roster, 018 +6 legendary): %d" % gd.get_enemy_ids().size())
	for eid: String in gd.get_enemy_ids():
		var e := gd.create_enemy(eid)
		ok(e != null and chart.is_known_type(e.get_primary_type()), "enemy builds typed " + eid)
	ok(gd.get_encounter_order().size() == 98, "98 encounters in order")
	for enc: String in gd.get_encounter_order():
		var es := gd.create_enemies(enc)
		ok(es.size() >= 1 and es.size() <= 3, "encounter builds " + enc)
		var bb := Battle.new(gd.create_player("salameche"), es, gd.get_starter_deck("salameche"), 3, 5, RandomNumberGenerator.new(), chart)
		bb.start()
		for en: Combatant in bb.enemies:
			ok(en.intent != null, "intent rolled " + enc)
	# rejections
	ok(not tweak(true, func(c, _p, _t): c["cards"]["griffe"]["type"] = "zzz", "r1"), "reject unknown card type")
	ok(not tweak(true, func(_c, p, _t): p["player"]["salameche"]["types"] = ["zzz"], "r2"), "reject unknown player type")
	ok(not tweak(true, func(_c, p, _t): p["enemies"]["zubat"]["types"] = ["zzz"], "r3"), "reject unknown enemy type")
	ok(not tweak(true, func(c, _p, _t): c["cards"]["griffe"].erase("type"), "r4"), "reject untyped attack")
	ok(not tweak(true, func(_c, _p, t): t["chart"]["fire"]["super_effective"].append("zzz"), "r5"), "reject chart unknown defender")
	ok(not tweak(true, func(_c, _p, t): t["chart"]["zzz"] = {"super_effective": [], "not_very_effective": [], "immune": []}, "r6"), "reject chart unknown attacker")
	ok(not tweak(true, func(_c, _p, t): t["multipliers"]["super_effective"] = 0, "r7"), "reject multiplier 0")
	ok(not tweak(true, func(_c, _p, t): t["chart"]["fire"]["not_very_effective"].append("grass"), "r8"), "reject SE+NVE same pair")
	ok(not tweak(true, func(_c, _p, t): t["chart"]["fire"]["super_effective"].append("grass"), "r9"), "reject duplicate in list")
	ok(not tweak(true, func(_c, _p, t): t["types"].erase("rock"), "r10"), "reject <10 types / dangling refs")
	ok(tweak(true, func(_c, _p, _t): pass, "ok0"), "unmodified copy loads")
	print("RESULT pass=%d fail=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
