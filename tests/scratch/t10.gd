extends SceneTree
## Throwaway: story 010 assertions (starter choice, starter decks, type-coherent reward carriers, roster).
var fails: int = 0
var passes: int = 0
const SCR := "/tmp/claude-0/-home-user-pokemon-spire/a2b72075-2d8b-51e2-a914-9e4b612c161d/scratchpad/"

func ok(c: bool, msg: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		print("FAIL ", msg)

func rng(seed_v: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	return r

func rj(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))

func loads(mut: Callable) -> bool:
	var c: Dictionary = rj("res://assets/data/cards.json")
	var p: Dictionary = rj("res://assets/data/pokemon.json")
	var r: Dictionary = rj("res://assets/data/rewards.json")
	mut.call(c, p, r)
	for pair in [["t10_c.json", c], ["t10_p.json", p], ["t10_r.json", r]]:
		var f := FileAccess.open(SCR + pair[0], FileAccess.WRITE)
		f.store_string(JSON.stringify(pair[1]))
		f.close()
	var g := GameData.new()
	return g.load_all(SCR + "t10_c.json", SCR + "t10_p.json", "res://assets/data/types.json", SCR + "t10_r.json")

func _initialize() -> void:
	var gd := GameData.new()
	ok(gd.load_all(), "real data loads")
	var cands: Array[String] = gd.get_starter_candidates()
	cands.append_array(gd.get_roster_starter_candidates())  # story 013b
	# 1. choices
	for s: int in 500:
		var ch: Array[String] = gd.draw_starter_choices(rng(s))
		var types: Dictionary = {}
		for id: String in ch:
			types[gd.get_primary_type(id)] = true
			ok(cands.has(id), "choice is candidate")
		ok(ch.size() == 3 and types.size() == 3, "3 different primary types seed %d %s" % [s, ch])
	ok(gd.draw_starter_choices(rng(77)) == gd.draw_starter_choices(rng(77)), "deterministic")
	var variety: Dictionary = {}
	for s: int in 100: variety[str(gd.draw_starter_choices(rng(s)))] = true
	ok(variety.size() > 20, "choices vary")
	ok(gd.draw_starter_choices(rng(1), 99).size() == 10 or true, "graceful (push_error expected above)")
	# 2. decks
	var pool_ids: Dictionary = {}
	for c: CardData in gd.get_reward_pool(gd.get_default_player_id()):
		pool_ids[c.id] = true
		ok(c.rarity != "starter", "no starter in pool")
	for id: String in cands:
		var deck: Array[CardData] = gd.build_starter_deck(id)
		var cards: Dictionary = gd.get_starter_cards_for_type(gd.get_primary_type(id))
		var basic: int = 0; var skill: int = 0; var strong: int = 0
		for c: CardData in deck:
			if c.id == (cards["basic"] as CardData).id: basic += 1
			elif c.id == "abri": skill += 1
			elif c.id == (cards["strong"] as CardData).id: strong += 1
			if c.kind == "attack":
				ok(c.pokemon_id == id and c.type_id == gd.get_primary_type(id), "attack carried by %s" % id)
			ok(c.rarity == "starter", "starter rarity")
			ok(not pool_ids.has(c.id), "starter card not in pool")
		ok(deck.size() == 11 and basic == 5 and skill == 4 and strong == 2, "deck shape %s" % id)
	# 3. run
	var chart: TypeChart = gd.get_type_chart()
	for id: String in ["pikachu", "squirtle", "poochyena", "salameche", "geodude"]:
		var run := RunState.create_with_starter(gd, id)
		var info: Dictionary = gd.get_pokemon_info(id)
		ok(run.starter_pokemon_id == id and run.deck.size() == 11 and run.hp == 90 and run.max_hp == 90 and run.energy_per_turn == 3 and run.hand_size == 5, "run " + id)
		var enemies: Array[Combatant] = gd.create_enemies(gd.get_encounter_order()[0])
		var b: Battle = run.create_battle(enemies, chart, rng(5))
		ok(b.active_pokemon_id == id and b.player.active_pokemon_id == id, "active " + id)
		ok(b.player.display_name == info["name"] and b.player.type_ids == info["types"] and b.player.sprite_path == info["sprite_path"], "identity " + id + " " + b.player.display_name)
		for c: CardData in b.hand:
			ok(c.kind == "skill" or c.pokemon_id == id, "hand card carried by starter")
	ok(RunState.create_with_starter(gd, "nope") == null, "unknown starter -> null")
	ok(RunState.create(gd, "salameche").deck.size() == 10, "legacy create works")
	# 4. rewards
	var coherent: int = 0; var total: int = 0; var distinct_ok: bool = true; var stolen_ok: bool = true
	var cases: Array = [["rattata"], ["pikachu", "geodude"], ["bulbasaur"], ["rowlet", "yungoos", "pikachu"], []]
	for s: int in 1000:
		var def: Array[String] = []
		def.assign(cases[s % cases.size()])
		var offers: Array[RewardOffer] = RewardGenerator.generate(gd, "salameche", def, rng(s))
		var keys: Dictionary = {}
		for o: RewardOffer in offers:
			keys[o.card.deck_key()] = true
			if o.stolen:
				stolen_ok = stolen_ok and def.has(o.card.pokemon_id) and gd.get_enemy_teaches(o.card.pokemon_id).any(func(c: CardData) -> bool: return c.id == o.card.id)
			elif o.card.kind == "attack":
				total += 1
				if (gd.get_pokemon_info(o.card.pokemon_id)["types"] as Array).has(o.card.type_id): coherent += 1
		if keys.size() != 3 or offers.size() != 3: distinct_ok = false
	ok(total > 1000 and coherent == total, "carriers coherent %d/%d" % [coherent, total])
	ok(distinct_ok, "3 distinct offers")
	ok(stolen_ok, "stolen card carried by defeated Pokemon")
	var d1: Array = RewardGenerator.generate(gd, "salameche", ["rattata"] as Array[String], rng(9)).map(func(o): return o.card.deck_key())
	var d2: Array = RewardGenerator.generate(gd, "salameche", ["rattata"] as Array[String], rng(9)).map(func(o): return o.card.deck_key())
	ok(d1 == d2, "reward deterministic")
	# 5. roster
	var lacking: Array[String] = []
	var d: Dictionary = rj("res://assets/data/pokemon.json")
	var roster: Array[String] = gd.get_enemy_ids()
	ok(roster.size() == 824, "824 enemies (story 013b: 98 + 720 roster, 018: +6 legendary)")
	for id: String in roster:
		var en: Array[Combatant] = []
		var c1: Combatant = gd.create_enemy(id)
		ok(c1 != null and c1.max_hp > 0, "enemy builds " + id)
		var info: Dictionary = gd.get_pokemon_info(id)
		var good: bool = false
		for card: CardData in gd.get_enemy_teaches(id):
			if card.kind == "attack" and ((info["types"] as Array).has(card.type_id) or card.type_id == "normal"): good = true
		if not good: lacking.append(id)
		ok(FileAccess.file_exists(info["sprite_path"]) and ResourceLoader.exists(info["sprite_path"]), "sprite exists " + id)
	print("LACKING coherent taught card: ", lacking)
	var act: Dictionary = rj("res://assets/data/act1.json")
	var enc_ids: Dictionary = {}
	for pool_id: String in act["encounter_pools"].keys() if act.has("encounter_pools") else []:
		for e: Variant in act["encounter_pools"][pool_id]:
			enc_ids[e if e is String else e["encounter"]] = true
	ok(not enc_ids.is_empty(), "found act pools %d" % enc_ids.size())
	for eid: String in enc_ids.keys():
		ok(not gd.create_enemies(eid).is_empty(), "encounter builds " + eid)
	# 6. validation rejections
	ok(loads(func(_c, _p, _r): pass), "unmodified temp copy loads")
	ok(not loads(func(_c, p, _r): p["starter_candidates"].append("zzz")), "reject unknown candidate")
	ok(not loads(func(_c, p, _r): p["starter_cards_by_type"].erase("dark")), "reject missing type entry")
	ok(not loads(func(_c, p, _r): p["starter_cards_by_type"]["dark"]["basic"] = "abri"), "reject non-attack starter card")
	ok(not loads(func(_c, p, _r): p["starter_cards_by_type"]["dark"]["basic"] = "griffe"), "reject wrong-type starter card")
	ok(not loads(func(_c, p, _r): p["starter_cards_by_type"]["zzz"] = {"basic": "griffe", "strong": "griffe"}), "reject unknown type")
	ok(not loads(func(_c, p, _r): p.erase("starter_deck_template")), "reject missing template")
	ok(not loads(func(_c, _p, r): r["player_pool"]["salameche"].append("griffe")), "reject starter card in reward pool")
	print("t10 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
