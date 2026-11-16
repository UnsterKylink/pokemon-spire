extends SceneTree
var fails: int = 0
var passes: int = 0
const SCR := "/tmp/claude-0/-home-user-pokemon-spire/a2b72075-2d8b-51e2-a914-9e4b612c161d/scratchpad/"

func ok(c: bool, msg: String) -> void:
	if c: passes += 1; print("PASS ", msg)
	else: fails += 1; print("FAIL ", msg)

func mk(actions: Array, pattern: String, hp: int = 50) -> Combatant:
	return Combatant.from_dict("x", {"name": "X", "max_hp": hp, "sprite": "s", "pattern": pattern, "actions": actions})

func player(hp: int = 500) -> Combatant:
	return Combatant.from_dict("p", {"name": "P", "max_hp": hp, "sprite": "s"})

func deck(gd: GameData) -> Array[CardData]:
	return gd.get_starter_deck("salameche")

func battle(gd: GameData, p: Combatant, es: Array[Combatant], seed_v: int = 1) -> Battle:
	var r := RandomNumberGenerator.new(); r.seed = seed_v
	var b := Battle.new(p, es, deck(gd), 3, 5, r)
	b.start()
	return b

func _initialize() -> void:
	var gd := GameData.new()
	ok(gd.load_all(), "real data loads")
	ok(gd.get_enemy_ids().size() >= 5, "5+ enemies: %d" % gd.get_enemy_ids().size())
	ok(str(gd.get_encounter_order()) == str(["solo", "duo", "trio"]), "encounter order")
	var sizes: Array[int] = []
	for id: String in gd.get_encounter_order():
		sizes.append(gd.create_enemies(id).size())
	ok(str(sizes) == str([1, 2, 3]), "encounters build 1/2/3: %s" % str(sizes))
	for id: String in gd.get_enemy_ids():
		var e: Combatant = gd.create_enemy(id)
		ok(e != null and not e.actions.is_empty(), "enemy builds " + id)

	# Sequence cycles in order.
	var seq := mk([{"type":"attack","value":3},{"type":"block","value":4},{"type":"buff","value":2}], "sequence")
	var b := battle(gd, player(), [seq] as Array[Combatant])
	var seen: Array[String] = []
	for t: int in 7:
		seen.append(seq.intent.type)
		b.end_turn()
	ok(str(seen) == str(["attack","block","buff","attack","block","buff","attack"]), "sequence cycles: " + str(seen))

	# Executed == displayed, incl. strength.
	var p := player()
	var w := mk([{"type":"attack","value":5},{"type":"buff","value":2},{"type":"block","value":3}], "sequence")
	b = battle(gd, p, [w] as Array[Combatant])
	var all_match := true
	var log_: Array[String] = []
	var acted: Array = []
	b.enemy_acted.connect(func(en: Combatant, it: EnemyIntent) -> void: acted.append(it))
	for t: int in 6:
		var shown: EnemyIntent = w.intent
		var shown_txt := shown.display_text()
		var hp_before := p.hp; var str_before := w.strength
		b.end_turn()
		var it: EnemyIntent = acted[acted.size() - 1]
		if it != shown: all_match = false
		match shown.type:
			"attack":
				if hp_before - p.hp != shown.value: all_match = false
			"buff":
				if w.strength - str_before != shown.value: all_match = false
			"block":
				if w.block != shown.value: all_match = false
		log_.append(shown_txt)
	ok(all_match, "executed == displayed: " + str(log_))
	ok(str(log_) == str(["Attaque 5","Renforcement +2","Protection 3","Attaque 7","Renforcement +2","Protection 3"]), "strength raises displayed attack")

	# Weighted determinism + proportions.
	var acts := [{"type":"attack","value":5,"weight":3},{"type":"block","value":2,"weight":1}]
	var run1: Array[String] = []; var run2: Array[String] = []
	for k: int in 2:
		var we := mk(acts, "weighted")
		var bb := battle(gd, player(100000), [we] as Array[Combatant], 42)
		for t: int in 20:
			(run1 if k == 0 else run2).append(we.intent.type)
			bb.end_turn()
	ok(run1 == run2, "weighted deterministic for fixed seed")
	var we2 := mk(acts, "weighted")
	var bb2 := battle(gd, player(1000000), [we2] as Array[Combatant], 7)
	var atk := 0
	for t: int in 2000:
		if we2.intent.type == "attack": atk += 1
		bb2.end_turn()
	ok(absf(atk / 2000.0 - 0.75) < 0.04, "weighted ratio ~0.75: %f" % (atk / 2000.0))

	# 3 enemies.
	var es: Array[Combatant] = [mk([{"type":"attack","value":3}], "sequence", 6), mk([{"type":"attack","value":3}], "sequence", 6), mk([{"type":"attack","value":3}], "sequence", 6)]
	p = player()
	b = battle(gd, p, es)
	b.energy = 100
	var ai := -1
	for i: int in b.hand.size():
		if b.hand[i].damage > 0: ai = i; break
	ok(ai >= 0, "have attack in hand")
	var hpb := es[0].hp
	ok(not b.play_card(ai, -1) and not b.play_card(ai, 3) and not b.play_card(ai, -5), "invalid target rejected")
	ok(b.hand.size() == 5 and b.energy == 100 and es[0].hp == hpb, "rejection changes nothing")
	# skill ignores target
	var si := -1
	for i: int in b.hand.size():
		if b.hand[i].damage == 0: si = i; break
	if si >= 0:
		ok(b.play_card(si, 99) and p.block > 0, "skill ignores target")
	# kill enemy 1 with repeated attacks
	var guard := 0
	while es[1].is_alive() and guard < 50:
		guard += 1
		b.energy = 100
		var idx := -1
		for i: int in b.hand.size():
			if b.hand[i].damage > 0: idx = i; break
		if idx < 0: b.end_turn(); continue
		b.play_card(idx, 1)
	ok(not es[1].is_alive() and es[1].intent == null, "enemy 1 dead, no intent")
	b.energy = 100
	var ai2 := -1
	for i: int in b.hand.size():
		if b.hand[i].damage > 0: ai2 = i; break
	if ai2 >= 0:
		ok(not b.play_card(ai2, 1), "dead target rejected")
	ok(b.state == Battle.State.PLAYER_TURN, "not won with 2 alive")
	var who: Array[Combatant] = []
	b.enemy_acted.connect(func(en: Combatant, it: EnemyIntent) -> void: who.append(en))
	b.end_turn()
	ok(who.size() == 2 and who[0] == es[0] and who[1] == es[2], "dead enemy does not act; left-to-right order")
	for target: int in [0, 2]:
		guard = 0
		while es[target].is_alive() and guard < 80:
			guard += 1
			b.energy = 100
			var idx := -1
			for i: int in b.hand.size():
				if b.hand[i].damage > 0: idx = i; break
			if idx < 0: b.end_turn(); continue
			b.play_card(idx, target)
			if target == 0: ok(b.state == Battle.State.PLAYER_TURN, "still not won") if not es[0].is_alive() else null
	ok(b.state == Battle.State.WON, "won when all dead")

	# Enemy block absorbs player damage first.
	var bl := mk([{"type":"block","value":10}], "sequence", 30)
	b = battle(gd, player(), [bl] as Array[Combatant])
	b.end_turn()
	ok(bl.block == 10, "enemy block gained")
	b.energy = 100
	var di := -1
	for i: int in b.hand.size():
		if b.hand[i].damage > 0: di = i; break
	if di >= 0:
		var dmg := b.hand[di].damage
		b.play_card(di, 0)
		ok(bl.hp == 30 and bl.block == 10 - dmg or bl.hp == 30 - (dmg - 10), "enemy block absorbed first (dmg %d, block %d, hp %d)" % [dmg, bl.block, bl.hp])
	# Enemy block reset at start of its next action.
	b.end_turn()
	ok(bl.block == 10, "block reset then regained (not stacked)")

	# Player block absorbs enemy attack.
	p = player(50)
	var at := mk([{"type":"attack","value":8}], "sequence")
	b = battle(gd, p, [at] as Array[Combatant])
	p.add_block(5)
	b.end_turn()
	ok(p.hp == 50 - 3 or p.hp == 47, "player block absorbs: hp %d" % p.hp)

	# Loss.
	p = player(8)
	b = battle(gd, p, [mk([{"type":"attack","value":8}], "sequence")] as Array[Combatant])
	b.end_turn()
	ok(b.state == Battle.State.LOST, "lost at 0 hp")

	# Constructor validation.
	var none: Array[Combatant] = []
	var r := RandomNumberGenerator.new()
	var bn := Battle.new(player(), none, deck(gd), 3, 5, r)
	bn.start()
	ok(bn.enemies.is_empty() and bn.hand.is_empty(), "0 enemies does not crash")
	var four: Array[Combatant] = [mk([{"type":"attack","value":1}], "sequence"), mk([{"type":"attack","value":1}], "sequence"), mk([{"type":"attack","value":1}], "sequence"), mk([{"type":"attack","value":1}], "sequence")]
	ok(Battle.new(player(), four, deck(gd), 3, 5, r).enemies.size() == 3, "4 enemies clamped to 3")

	# CardData: skill with damage rejected.
	ok(CardData.from_dict("bad", {"name":"b","cost":1,"kind":"skill","damage":3,"block":2,"description":"d"}) == null, "skill with damage rejected")
	ok(CardData.from_dict("g", {"name":"b","cost":1,"kind":"attack","damage":3,"block":0,"description":"d"}).needs_target(), "attack needs target")

	# GameData rejects bad encounters (temp copies in scratchpad).
	var txt := FileAccess.get_file_as_string("res://assets/data/pokemon.json")
	var variants := {
		"unknown_enemy": txt.replace('"duo": ["pidgey", "weedle"]', '"duo": ["pidgey", "mewtwo"]'),
		"four_enemies": txt.replace('"duo": ["pidgey", "weedle"]', '"duo": ["pidgey", "weedle", "zubat", "rattata"]'),
		"empty_encounter": txt.replace('"duo": ["pidgey", "weedle"]', '"duo": []'),
		"bad_order": txt.replace('"encounter_order": ["solo", "duo", "trio"]', '"encounter_order": ["solo", "nope"]'),
		"bad_action_type": txt.replace('"type": "buff", "value": 2', '"type": "heal", "value": 2'),
		"zero_weight": txt.replace('"value": 7, "weight": 4', '"value": 7, "weight": 0'),
		"negative_value": txt.replace('"value": 7, "weight": 4', '"value": -7, "weight": 4'),
		"bad_pattern": txt.replace('"pattern": "sequence"', '"pattern": "random"'),
		"encounters_not_dict": txt.replace('"encounters": {', '"encounters": [], "x": {'),
	}
	for k: String in variants.keys():
		var path: String = SCR + "bad_%s.json" % k
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(variants[k]); f.close()
		var g := GameData.new()
		ok(variants[k] != txt and not g.load_all("res://assets/data/cards.json", path), "rejects " + k)
		DirAccess.remove_absolute(path)
	print("RESULT pass=%d fail=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
