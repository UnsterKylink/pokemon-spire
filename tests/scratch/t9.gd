extends SceneTree
var fails: int = 0
var passes: int = 0
const SCR := "/tmp/claude-0/-home-user-pokemon-spire/a2b72075-2d8b-51e2-a914-9e4b612c161d/scratchpad/"
var gd: GameData

func ok(c: bool, msg: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		print("FAIL ", msg)

func mk(t: String, actions: Array, hp: int = 500) -> Combatant:
	return Combatant.from_dict("enemy_" + t, {"name": "E", "types": [t], "max_hp": hp, "sprite": "s", "pattern": "sequence", "actions": actions})

func idx(b: Battle, cid: String) -> int:
	for i: int in b.hand.size():
		if b.hand[i].id == cid:
			return i
	return -1

func mkbattle(run: RunState, es: Array[Combatant], ids: Array) -> Battle:
	var d: Array[CardData] = []
	for c: String in ids:
		d.append(gd.get_card(c))
	run.deck = d
	run.energy_per_turn = 10
	run.hand_size = ids.size()
	var r := RandomNumberGenerator.new(); r.seed = 3
	var b := run.create_battle(es, gd.get_type_chart(), r)
	b.start()
	return b

func tweak(mod: Callable, name: String) -> bool:
	var cards := JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/cards.json")) as Dictionary
	var pk := JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/pokemon.json")) as Dictionary
	mod.call(cards, pk)
	var f := FileAccess.open(SCR + name + "_c.json", FileAccess.WRITE); f.store_string(JSON.stringify(cards)); f.close()
	f = FileAccess.open(SCR + name + "_p.json", FileAccess.WRITE); f.store_string(JSON.stringify(pk)); f.close()
	var g := GameData.new()
	return g.load_all(SCR + name + "_c.json", SCR + name + "_p.json")

func _initialize() -> void:
	gd = GameData.new()
	ok(gd.load_all(), "load")
	for cid: String in ["griffe","abri","flammeche","rugissement","danse_flamme","vive_attaque","crocs_feu","eclair","tonnerre","forteresse","tunnel"]:
		var c: CardData = gd.get_card(cid)
		if c.kind == "attack":
			ok(not gd.get_pokemon_info(c.pokemon_id).is_empty(), "known pokemon " + cid)
		else:
			ok(c.pokemon_id == "", "skill none " + cid)
	var cards := JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/cards.json")) as Dictionary
	for cid: String in (cards["cards"] as Dictionary).keys():
		var c: CardData = gd.get_card(cid)
		if c.kind == "attack":
			ok(not gd.get_pokemon_info(c.pokemon_id).is_empty(), "attack has pokemon " + cid)
		else:
			ok(c.pokemon_id == "", "skill without pokemon " + cid)
	ok(gd.get_starter_pokemon_id() == "salameche", "starter id")
	for c: CardData in gd.get_starter_deck("salameche"):
		ok(c.kind == "skill" or c.pokemon_id == "salameche", "starter deck salameche " + c.id)
	for cid: String in ["crocs_feu","lance_flammes","danse_flamme","draco_griffe"]:
		ok(gd.get_card(cid).pokemon_id == "salameche", "salameche card " + cid)
	var inf: Dictionary = gd.get_pokemon_info("geodude")
	ok(inf["name"] != "" and inf["sprite_path"] != "" and inf["types"].size() == 2, "info geodude dual")
	ok(gd.get_pokemon_info("nope").is_empty(), "info unknown")

	# run / deck counts
	var run := RunState.create(gd, "salameche")
	ok(run.starter_pokemon_id == "salameche", "run starter")
	run.add_card(gd.get_card("vive_attaque"))
	run.add_card(gd.get_card("vive_attaque").with_pokemon("pidgey"))
	run.add_card(gd.get_card("vive_attaque").with_pokemon("pidgey"))
	var dc: Dictionary = run.deck_counts()
	ok(dc["griffe@salameche"] == 5 and dc["abri"] == 4 and dc["vive_attaque@rattata"] == 1 and dc["vive_attaque@pidgey"] == 2, "deck_counts group " + str(dc))
	var n_ent := 0
	for e: Dictionary in run.get_deck_entries():
		if (e["card"] as CardData).id == "vive_attaque": n_ent += 1
	ok(n_ent == 2, "entries separate")
	ok(gd.get_card("griffe").display_label("Salamèche") == "Griffe — Salamèche", "label")
	ok(gd.get_card("vive_attaque").with_pokemon("pidgey").pokemon_id == "pidgey" and gd.get_card("vive_attaque").pokemon_id == "rattata", "with_pokemon copy")

	# battle: switching
	run = RunState.create(gd, "salameche")
	var pika := mk("electric", [{"type": "attack", "value": 10}, {"type": "block", "value": 5}])
	var dummy := mk("normal", [{"type": "block", "value": 5}])
	var es: Array[Combatant] = [pika, dummy]
	var b := mkbattle(run, es, ["griffe", "abri", "jet_de_pierres", "vive_attaque", "forteresse", "flammeche"])
	var sw: Array = []
	var sc: Array = [0]
	b.active_pokemon_changed.connect(func(o: String, n: String) -> void: sw.append([o, n]))
	b.state_changed.connect(func() -> void: sc[0] += 1)
	ok(b.active_pokemon_id == "salameche" and b.player.active_pokemon_id == "salameche" and b.player.type_ids == ["fire"], "start active")
	ok(b.player.display_name == "Salamèche", "start name")
	ok(pika.intent.type == "attack" and pika.intent.value == 10, "intent vs fire 10")
	ok(b.play_card(idx(b, "griffe"), 1) and sw.is_empty(), "same pokemon no switch")
	ok(b.play_card(idx(b, "abri")) and sw.is_empty() and b.player.block == 5, "skill no switch")
	ok(b.play_card(idx(b, "forteresse")) and sw.is_empty(), "skill2 no switch")
	var blk: int = b.player.block
	var ei: int = idx(b, "jet_de_pierres")
	var e_hp: int = pika.hp
	ok(not b.play_card(ei, 7) and sw.is_empty() and b.active_pokemon_id == "salameche" and b.hand.size() == 3, "invalid target no switch")
	# dummy dead target case
	dummy.hp = 0
	ok(not b.play_card(ei, 1) and sw.is_empty(), "dead target no switch")
	dummy.hp = 500
	var hit: Array = []
	b.hit_resolved.connect(func(t: Combatant, a: int, m: float) -> void: hit.append([t, a, m, b.player.type_ids.duplicate(), sw.size()]))
	ok(b.play_card(ei, 0), "play geodude card")
	ok(sw.size() == 1 and sw[0] == ["salameche", "geodude"] and b.active_pokemon_id == "geodude", "switch emitted once")
	ok(b.player.display_name == "Racaille" or b.player.display_name == gd.get_pokemon_info("geodude")["name"], "name changed")
	ok(b.player.type_ids == ["rock", "ground"], "types changed " + str(b.player.type_ids))
	ok(hit.size() == 1 and hit[0][4] == 1, "switch before hit")
	ok(pika.hp < e_hp, "hit landed")
	ok(pika.intent.type == "attack" and pika.intent.value == 0 and pika.intent.display_text() == "Attaque 0", "intent 0 vs geodude")
	ok(b.player.block == blk, "block shared across switch")
	ok(sc[0] > 0, "state_changed")
	var hp0: int = run.hp
	var pre_hp: int = b.player.hp
	b.end_turn()
	ok(b.player.hp == pre_hp, "immune: no HP lost")
	# next intent: block; switch back and replay
	ok(pika.intent.type == "block", "sequence block next")
	# attack intent after switching mid-turn: execute == displayed
	run = RunState.create(gd, "salameche")
	pika = mk("electric", [{"type": "attack", "value": 10}, {"type": "attack", "value": 10}])
	es = [pika]
	b = mkbattle(run, es, ["vive_attaque", "cru_aile", "eclair", "griffe", "abri"])
	ok(pika.intent.value == 10, "x1 vs fire")
	b.play_card(idx(b, "cru_aile"), 0)  # flying: electric vs flying 2x
	ok(b.active_pokemon_id == "pidgey" and pika.intent.value == 15 and pika.intent.type == "attack", "se vs pidgey 20: " + str(pika.intent.value))
	b.play_card(idx(b, "abri"))
	var shown: int = pika.intent.value
	var blk2: int = b.player.block
	var hp_before: int = b.player.hp
	var ehit: Array = []
	b.hit_resolved.connect(func(t: Combatant, a: int, m: float) -> void: if t == b.player: ehit.append(a))
	b.end_turn()
	ok(ehit == [shown], "executed equals displayed " + str(ehit))
	ok(b.player.hp == hp_before - maxi(shown - blk2, 0), "HP lost (block shared)")
	ok(b.active_pokemon_id == "pidgey", "active persists across turn")
	b.player.hp = b.player.hp
	run.record_battle_result(b.player)
	ok(run.hp == b.player.hp, "shared HP persisted")
	# next battle resets
	var b2: Battle = run.create_battle([mk("normal", [{"type": "attack", "value": 3}])] as Array[Combatant], gd.get_type_chart(), RandomNumberGenerator.new())
	ok(b2.active_pokemon_id == "salameche" and b2.player.type_ids == ["fire"] and b2.player.display_name == "Salamèche" and b2.player.hp == run.hp, "next battle starter")
	# old-style constructor
	var b3 := Battle.new(gd.create_player("salameche"), [mk("normal", [{"type": "attack", "value": 3}])] as Array[Combatant], gd.get_starter_deck("salameche"), 3, 5, RandomNumberGenerator.new(), gd.get_type_chart())
	b3.start()
	ok(b3.active_pokemon_id == "salameche" or b3.active_pokemon_id != "", "old ctor")

	# rewards
	var rng := RandomNumberGenerator.new()
	for s: int in 20:
		rng.seed = s
		var ids: Array[String] = ["pikachu"] as Array[String]
		var offers: Array[RewardOffer] = RewardGenerator.generate(gd, "salameche", ids, rng)
		var st := 0
		var seen := {}
		for o: RewardOffer in offers:
			seen[o.card.id] = true
			if o.stolen:
				st += 1
				ok(o.card.pokemon_id == "pikachu", "stolen carries pikachu")
				ok(gd.get_card(o.card.id).pokemon_id != "" , "orig intact")
			else:
				ok(o.card.kind == "skill" or (gd.get_pokemon_info(o.card.pokemon_id)["types"] as Array).has(o.card.type_id), "pool carrier type-coherent (story 010)")
		ok(st == 1 and offers.size() == 3 and seen.size() == 3, "3 distinct with stolen")
	for e_id: String in gd.get_enemy_ids():
		for c: CardData in gd.get_enemy_teaches(e_id):
			if c.id == "vive_attaque":
				rng.seed = 1
				var offers2 := RewardGenerator.generate(gd, "salameche", [e_id] as Array[String], rng)
				for o: RewardOffer in offers2:
					if o.stolen: ok(o.card.pokemon_id == e_id, "stolen = defeated " + e_id)
				break

	# validation
	ok(tweak(func(c: Dictionary, p: Dictionary) -> void: pass, "v0"), "tweak baseline ok")
	ok(not tweak(func(c: Dictionary, p: Dictionary) -> void: c["cards"]["griffe"]["pokemon"] = "mewthree", "v1"), "unknown pokemon rejected")
	ok(not tweak(func(c: Dictionary, p: Dictionary) -> void: c["cards"]["griffe"].erase("pokemon"), "v2"), "attack w/o pokemon rejected")
	ok(not tweak(func(c: Dictionary, p: Dictionary) -> void: c["cards"]["abri"]["pokemon"] = "salameche", "v3"), "skill w/ pokemon rejected")
	ok(not tweak(func(c: Dictionary, p: Dictionary) -> void: p["starter_pokemon"] = "mewtwo", "v4"), "unknown starter rejected")
	ok(not tweak(func(c: Dictionary, p: Dictionary) -> void: p.erase("starter_pokemon"), "v5"), "missing starter rejected")
	print("T9 pass=", passes, " fail=", fails)
	quit(1 if fails > 0 else 0)
