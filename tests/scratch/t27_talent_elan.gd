extends SceneTree
## Story 027 scratch: talents (fire when a Pokémon enters, once per battle, the starter enters at battle start) and Élan
## (built by attacks of the already-active Pokémon, capped, reset by a switch). Uses the real talents.json.
const P := "res://assets/data/"
const HP: int = 200
const DMG: int = 6
var passes: int = 0
var fails: int = 0
var gd: GameData
var tb: TalentBook


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


func atk(id: String, pokemon: String, cost: int = 0) -> CardData:
	return CardData.from_dict(id, {"name": id, "cost": cost, "kind": "attack", "damage": DMG, "block": 0, "description": "",
			"type": "normal", "pokemon": pokemon, "rarity": "common"})


func enemy() -> Combatant:
	return Combatant.from_dict("e", {"name": "E", "max_hp": HP, "sprite": "", "types": ["normal"], "pattern": "sequence",
			"actions": [{"type": "attack", "value": 8}]})


## Unstarted battle (connect the signals, then start()).
func mk(cards: Array, starter: String, book: TalentBook, enemy_count: int = 1, seed_value: int = 1) -> Battle:
	var p := Combatant.new()
	p.id = "p"
	p.max_hp = HP
	p.hp = HP - 20
	var deck: Array[CardData] = []
	deck.assign(cards)
	var es: Array[Combatant] = []
	for i: int in enemy_count:
		es.append(enemy())
	return Battle.new(p, es, deck, 3, 5, rng(seed_value), gd.get_type_chart(), gd.get_pokemon_info, starter, [] as Array[ItemData],
			[] as Array[PotionData], gd.get_status_book(), null, {}, {}, false, book)


func play(b: Battle, id: String) -> int:
	for i: int in b.hand.size():
		if b.hand[i].id == id:
			var before: int = b.enemies[0].hp
			if not b.play_card(i, 0):
				return -1
			return before - b.enemies[0].hp
	return -1


func _initialize() -> void:
	gd = GameData.new()
	ok(gd.load_all(), "real data loads")
	tb = gd.get_talent_book()
	ok(tb != null and tb.trigger == TalentBook.TRIGGER_ONCE_PER_BATTLE and tb.elan_cap == 3 and tb.elan_damage_per_stack == 1 and tb.elan_gain_per_attack == 1, "talents.json rules")
	_data()
	_starter_and_elan()
	_switch()
	_other_talents()
	_save()
	print("t27 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)


func _data() -> void:
	for t: String in gd.get_type_chart().get_type_ids():
		ok(tb.has(String(tb.default_by_type.get(t, ""))), "type '%s' has a default talent" % t)
	var missing: int = 0
	for pid: String in gd.get_pokemon_ids():
		if gd.get_talent_info(pid).is_empty():
			missing += 1
	ok(missing == 0, "every Pokémon has a talent (%d without)" % missing)
	ok(String(gd.get_talent_info("salameche").get("id", "")) == "brasier", "default by primary type (fire)")
	ok(String(gd.get_talent_info("shinx").get("id", "")) == "intimidation", "pokemon.json override")
	ok(String(gd.get_talent_info("gyarados").get("id", "")) == "intimidation", "talents.json by_pokemon override")
	ok(not String(gd.get_talent_info("salameche")["name"]).is_empty() and not String(gd.get_talent_info("salameche")["description"]).is_empty(), "talent texts for the UI")
	ok(tb.ids().size() >= 20 and tb.keywords.has("elan") and tb.keywords.has("exhaust"), "about 20 talents + keyword texts")
	print("--- errors expected below (invalid talents rejected) ---")
	var root: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(P + "talents.json"))
	var r1: Dictionary = root.duplicate(true)
	(r1["default_by_type"] as Dictionary).erase("fire")
	ok(TalentBook.from_dict(r1, gd.get_type_chart().get_type_ids(), gd.get_status_book()) == null, "missing default type rejected")
	var r2: Dictionary = root.duplicate(true)
	r2["talents"]["brasier"]["effect"] = {"fly": 2}
	ok(TalentBook.from_dict(r2, gd.get_type_chart().get_type_ids(), gd.get_status_book()) == null, "unknown effect field rejected")
	var r3: Dictionary = root.duplicate(true)
	r3["by_pokemon"]["nobody"] = "brasier"
	var f := FileAccess.open("user://t27_talents.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(r3))
	f.close()
	var paths: Array = [P + "cards.json", P + "pokemon.json", P + "types.json", P + "rewards.json", P + "act1.json", P + "events.json",
			P + "items.json", P + "potions.json", P + "shop.json", P + "zones.json", P + "league.json", P + "roster.json",
			P + "statuses.json", P + "balls.json", P + "rival.json", "user://t27_talents.json"]
	ok(not GameData.new().callv("load_all", paths), "by_pokemon with an unknown Pokémon: load refused")
	print("--- end of expected errors ---")
	paths[paths.size() - 1] = ""
	var g2 := GameData.new()
	ok(g2.callv("load_all", paths) and g2.get_talent_book() == null and g2.get_talent_info("salameche").is_empty(), "no talents file: game still loads, no talents")


func _starter_and_elan() -> void:
	var cards: Array = []
	for i: int in 7:
		cards.append(atk("a%d" % i, "salameche"))
	var b := mk(cards, "salameche", tb)
	var fired: Array = []
	var elans: Array = []
	b.talent_triggered.connect(func(pid: String, tid: String) -> void: fired.append([pid, tid]))
	b.elan_changed.connect(func(v: int) -> void: elans.append(v))
	b.start()
	ok(fired == [["salameche", "brasier"]], "the starter's talent fires at battle start: %s" % str(fired))
	ok(b.get_next_attack_bonus() == 1 and b.get_elan() == 0 and b.get_elan_cap() == 3, "Brasier waits for the next attack")
	ok(int(b.preview_card_damage(0, 0)["amount"]) == DMG + 1, "preview shows the talent bonus")
	var lost: Array = []
	for i: int in 5:
		lost.append(play(b, b.hand[0].id))
	ok(lost == [DMG + 1, DMG + 1, DMG + 2, DMG + 3, DMG + 3], "Brasier once, then +1 per Élan: %s" % str(lost))
	ok(b.get_elan() == 3 and elans == [1, 2, 3] and b.get_next_attack_bonus() == 0, "Élan built by the active Pokémon: %s" % str(elans))
	ok(b.get_elan_damage_bonus() == 3, "Élan damage bonus getter")
	b.end_turn()
	ok(b.get_elan() == 3 and fired.size() == 1, "Élan is kept between turns; the talent does not re-fire by staying")
	ok(play(b, b.hand[0].id) == DMG + 3 and play(b, b.hand[0].id) == DMG + 3, "capped at 3")
	ok(b.get_elan() == 3 and elans.size() == 3, "no change signal at the cap")
	# No talent book: nothing fires, no Élan (old behaviour).
	b = mk(cards, "salameche", null)
	b.start()
	ok(play(b, b.hand[0].id) == DMG and play(b, b.hand[0].id) == DMG and b.get_elan() == 0 and b.get_elan_cap() == 0, "without a talent book: plain damage")


func _switch() -> void:
	var cards: Array = [atk("s1", "salameche"), atk("s2", "salameche"), atk("q1", "squirtle"), atk("q2", "squirtle"), atk("s3", "salameche")]
	var b := mk(cards, "salameche", tb)
	var fired: Array = []
	var elans: Array = []
	b.talent_triggered.connect(func(pid: String, tid: String) -> void: fired.append(tid))
	b.elan_changed.connect(func(v: int) -> void: elans.append(v))
	b.start()
	ok(play(b, "s1") == DMG + 1 and play(b, "s2") == DMG + 1 and b.get_elan() == 2, "build 2 Élan on the starter")
	ok(b.would_trigger_talent(b.hand[0]) == (b.hand[0].pokemon_id == "squirtle"), "would_trigger_talent only for a newcomer")
	ok(play(b, "q1") == DMG and b.active_pokemon_id == "squirtle", "switching card: no Élan bonus")
	ok(b.get_elan() == 0 and elans == [1, 2, 0] and fired == ["brasier", "torrent"] and b.player.block == 3, "switch: Élan 0, Torrent gives 3 block")
	ok(play(b, "s3") == DMG and fired.size() == 2, "back to the starter the same turn: Brasier does not re-fire, no Élan")
	ok(play(b, "q2") == DMG and fired.size() == 2 and b.player.block == 3 and b.get_elan() == 0, "ping-pong: Torrent does not re-fire either")
	ok(b.is_talent_used("salameche") and b.is_talent_used("squirtle") and not b.is_talent_used("bulbasaur"), "is_talent_used after both entries")
	b.end_turn()
	var hand_id: String = b.hand[0].id
	ok(not b.would_trigger_talent(b.hand[0]), "next turn: no talent preview, both are used for this battle")
	play(b, hand_id)
	ok(fired.size() == 2, "once per battle: next turn a returning Pokémon's talent does NOT fire again (%s)" % str(fired))
	b.end_turn()
	for c: CardData in b.hand.duplicate():
		play(b, c.id)
	ok(fired.size() == 2, "still once per battle two turns later")
	# talent_trigger once_per_turn: a newcomer fires again next turn.
	var root: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(P + "talents.json"))
	root["talent_trigger"] = "once_per_turn"
	var per_turn: TalentBook = TalentBook.from_dict(root, gd.get_type_chart().get_type_ids(), gd.get_status_book())
	ok(per_turn != null and per_turn.trigger == TalentBook.TRIGGER_ONCE_PER_TURN, "talent_trigger once_per_turn parsed")
	b = mk(cards, "salameche", per_turn)
	fired = []
	b.talent_triggered.connect(func(pid: String, tid: String) -> void: fired.append(tid))
	b.start()
	play(b, "q1")
	play(b, "s1")
	ok(fired == ["brasier", "torrent"], "once_per_turn: no re-fire within the turn (%s)" % str(fired))
	b.end_turn()
	hand_id = b.hand[0].id
	var is_sq: bool = b.hand[0].pokemon_id == "squirtle"
	play(b, hand_id)
	ok(fired.size() == (3 if is_sq else 2), "once_per_turn: next turn a newcomer's talent fires again")
	# talent_trigger every_entry (and the legacy talent_once_per_turn false): every entry fires.
	root["talent_trigger"] = "every_entry"
	var loose: TalentBook = TalentBook.from_dict(root, gd.get_type_chart().get_type_ids(), gd.get_status_book())
	b = mk(cards, "salameche", loose)
	b.start()
	play(b, "q1")
	play(b, "s1")
	play(b, "q2")
	ok(b.player.block == 6, "every_entry: Torrent fired twice (block %d)" % b.player.block)
	var legacy: Dictionary = root.duplicate(true)
	legacy.erase("talent_trigger")
	legacy["talent_once_per_turn"] = false
	var lb: TalentBook = TalentBook.from_dict(legacy, gd.get_type_chart().get_type_ids(), gd.get_status_book())
	ok(lb != null and lb.trigger == TalentBook.TRIGGER_EVERY_ENTRY, "legacy talent_once_per_turn false = every_entry")
	legacy.erase("talent_once_per_turn")
	ok(TalentBook.from_dict(legacy, gd.get_type_chart().get_type_ids(), gd.get_status_book()).trigger == TalentBook.TRIGGER_ONCE_PER_BATTLE, "default rule: once_per_battle")
	print("--- error expected below (bad talent_trigger) ---")
	legacy["talent_trigger"] = "sometimes"
	ok(TalentBook.from_dict(legacy, gd.get_type_chart().get_type_ids(), gd.get_status_book()) == null, "unknown talent_trigger rejected")
	print("--- end of expected error ---")
	# Élan disabled in data.
	root["elan"] = {"gain_per_attack": 0, "cap": 0, "damage_per_stack": 0}
	var flat: TalentBook = TalentBook.from_dict(root, gd.get_type_chart().get_type_ids(), gd.get_status_book())
	b = mk([atk("s1", "salameche"), atk("s2", "salameche"), atk("s3", "salameche")], "salameche", flat)
	b.start()
	play(b, "s1")
	ok(play(b, "s2") == DMG and play(b, "s3") == DMG and b.get_elan() == 0, "Élan values come from data (0 = off)")


func _other_talents() -> void:
	var cards: Array = [atk("x1", "shinx"), atk("p1", "pidgey"), atk("m1", "taillow"), atk("f1", "fletchling"), atk("z1", "zubat"), atk("x2", "shinx")]
	# Intimidation (starter shinx): Faiblesse 1 on every enemy, shown intents already reduced.
	var b := mk(cards, "shinx", tb, 2)
	b.start()
	ok(b.enemies[0].has_status("weak") and b.enemies[1].has_status("weak") and b.enemies[0].intent.value == 6, "Intimidation at battle start")
	var hand0: int = b.hand.size()
	play(b, "p1")
	ok(b.hand.size() == hand0 - 1 + 1 and b.active_pokemon_id == "pidgey", "Regard Vif draws 1 on entry")
	ok(play(b, "m1") == DMG + 1 and b.get_turn_strength() == 1, "Cran: +1 Force this turn, on the entering attack too")
	b.end_turn()
	ok(b.get_turn_strength() == 0 and b.player.hp == HP - 20 - 6 - 6, "Force of the turn is gone; weak enemies hit for 6")
	# random_enemy uses the injected RNG: same seed, same target; heal talent.
	var picks: Array = []
	for round_i: int in 2:
		var b2 := mk([atk("z1", "zubat")], "salameche", tb, 3, 42)
		b2.start()
		play(b2, "z1")
		for i: int in b2.enemies.size():
			if b2.enemies[i].has_status("poison"):
				picks.append(i)
	ok(picks.size() == 2 and picks[0] == picks[1], "Point Poison target is deterministic for a seed: %s" % str(picks))
	var b3 := mk([atk("g1", "bulbasaur")], "salameche", tb)
	b3.start()
	play(b3, "g1")
	ok(b3.player.hp == HP - 20 + 2, "Engrais heals 2 on entry")
	# Through RunState (the real game path): the book is injected.
	var run := RunState.create_with_starter(gd, "salameche")
	var rb: Battle = run.create_battle(gd.create_enemies("solo"), gd.get_type_chart(), rng(5))
	rb.start()
	ok(rb.get_elan_cap() == 3 and rb.get_talent_id("salameche") == "brasier" and rb.get_next_attack_bonus() == 1, "RunState.create_battle wires talents + Élan")


## Save compatibility: story 027 adds no run-state field (all new state lives inside a Battle, never saved mid-battle), so the
## version stays and a run holding story-027 cards round-trips; an unknown future version is refused cleanly, not crashed on.
func _save() -> void:
	var run := RunState.create_with_starter(gd, "salameche")
	run.set_zones(gd.draw_zones(rng(3)))
	run.add_card(gd.get_card("combo_griffe"))
	run.add_card(gd.get_card("danse_lames"))
	var loaded: Dictionary = SaveGame.from_dict(JSON.parse_string(JSON.stringify(SaveGame.to_dict(run))), gd)
	ok(SaveGame.VERSION == 1, "save version unchanged (no new run-state field)")
	ok(bool(loaded.get("ok", false)), "a run with story-027 cards saves and loads: %s" % str(loaded.get("error", "")))
	if bool(loaded.get("ok", false)):
		var ids: Array = []
		for c: CardData in (loaded["run"] as RunState).deck:
			ids.append(c.id)
		ok("combo_griffe" in ids and "danse_lames" in ids and (loaded["run"] as RunState).deck[ids.find("combo_griffe")].hits == 3, "new cards survive a save / load")
	var future: Dictionary = SaveGame.to_dict(run)
	future["version"] = SaveGame.VERSION + 1
	var fut: Dictionary = SaveGame.from_dict(future, gd)
	ok(not bool(fut.get("ok", true)) and not String(fut.get("error", "")).is_empty(), "unknown save version refused with a message")
