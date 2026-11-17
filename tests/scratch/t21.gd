extends SceneTree
## Story 019 scratch: simulator determinism + legality, dual-type attack data, per-type card coverage.
const SCR: String = "user://"
const SimRun: GDScript = preload("res://tools/balance/sim_run.gd")
const Simulate: GDScript = preload("res://tools/balance/simulate.gd")
var fails: int = 0
var passes: int = 0

func ok(c: bool, msg: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		print("FAIL ", msg)

func _initialize() -> void:
	var data := GameData.new()
	ok(data.load_all(), "data loads")
	# 1. determinism + legality (20 games, twice)
	var a: Array = []
	var b: Array = []
	for i: int in 20:
		a.append(SimRun.play_game(data, Simulate.game_seed(42, i), {}))
	for i: int in 20:
		b.append(SimRun.play_game(data, Simulate.game_seed(42, i), {}))
	ok(JSON.stringify(a) == JSON.stringify(b), "same seed -> same 20 results")
	var c: Array = [SimRun.play_game(data, Simulate.game_seed(43, 0), {})]
	var illegal: int = 0
	var fights: int = 0
	for r: Dictionary in a:
		illegal += int(r["illegal"])
		fights += int(r["fights"])
		ok(not bool(r["stalled"]), "no stalled fight (game %s)" % str(r["stage"]))
		ok(String(r["stage"]) != "" and String(r["stage"]) != "map_error", "a run ends at a known stage")
	ok(illegal == 0, "policy never made an illegal move (%d)" % illegal)
	ok(fights >= 20, "fights were played (%d)" % fights)
	ok(JSON.stringify(c) != JSON.stringify([a[0]]), "another seed gives another run")
	var forced: Dictionary = SimRun.play_game(data, Simulate.game_seed(42, 0), {"starter_pick": "first", "block_first_fraction": 0.9})
	ok(int(forced["illegal"]) == 0, "policy overrides still legal")
	# 2. dual-type attack data
	var chart: TypeChart = data.get_type_chart()
	var def: Dictionary = {"name": "Test", "max_hp": 50, "sprite": "", "types": ["normal", "water"], "pattern": "sequence",
			"actions": [{"type": "attack", "value": 10, "attack_type": "water"}, {"type": "attack", "value": 10}]}
	var enemy: Combatant = Combatant.from_dict("t", def)
	ok(enemy != null and enemy.actions[0].attack_type == "water" and enemy.actions[1].attack_type == "", "attack_type parsed")
	var player: Combatant = Combatant.from_dict("p", {"name": "P", "max_hp": 100, "sprite": "", "types": ["fire"]})
	var deck: Array[CardData] = [data.get_card("abri")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var bt := Battle.new(player, [enemy] as Array[Combatant], deck, 3, 1, rng, chart)
	bt.start()
	ok(enemy.intent.attack_type == "water" and enemy.intent.value == chart.final_damage(10, "water", ["fire"]) and enemy.intent.value > 10,
			"water attack is super effective on fire (%d)" % enemy.intent.value)
	ok(enemy.intent.display_text().contains("(%s)" % data.get_type_name("water")), "intent shows the type: " + enemy.intent.display_text())
	bt.end_turn()
	ok(player.hp == 100 - chart.final_damage(10, "water", ["fire"]), "the water hit was executed with its type")
	ok(enemy.intent.attack_type == "normal" and enemy.intent.value == 10, "no attack_type = primary type")
	player.set_active_pokemon("p", "P", "", ["ghost"] as Array[String])
	bt.refresh_intents()
	ok(enemy.intent.value == 0, "refresh_intents uses the action type (normal vs ghost = 0)")
	var single: Combatant = Combatant.from_dict("s", {"name": "S", "max_hp": 10, "sprite": "", "types": ["water"], "pattern": "sequence",
			"actions": [{"type": "attack", "value": 5}]})
	var bt2 := Battle.new(Combatant.from_dict("p2", {"name": "P", "max_hp": 50, "sprite": "", "types": ["fire"]}), [single] as Array[Combatant], deck, 3, 1, rng, chart)
	bt2.start()
	ok(single.intent.display_text() == "Attaque %d" % single.intent.value, "single type: no type label")
	ok(EnemyIntent.from_dict({"type": "block", "value": 3, "attack_type": "water"}) == null, "attack_type refused on a block")
	# validation: unknown attack type rejected by GameData
	var pj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/pokemon.json"))
	((pj["enemies"]["bidoof"] as Dictionary)["actions"] as Array)[0]["attack_type"] = "plasma"
	var f := FileAccess.open(SCR + "t21_p.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(pj))
	f.close()
	var P: String = "res://assets/data/"
	ok(not GameData.new().load_all(P + "cards.json", SCR + "t21_p.json"), "unknown attack_type rejected")
	# generator rule applied: every dual-typed roster / pokemon.json enemy with >= 2 attacks has exactly one secondary-typed attack
	var rule_ok: int = 0
	var rule_bad: Array[String] = []
	for pid: String in data.get_enemy_ids():
		var e: Combatant = data.create_enemy(pid)
		var attacks: Array[EnemyIntent] = []
		for act: EnemyIntent in e.actions:
			if act.type == EnemyIntent.TYPE_ATTACK:
				attacks.append(act)
		var typed: Array[EnemyIntent] = []
		for act: EnemyIntent in attacks:
			if not act.attack_type.is_empty():
				typed.append(act)
		if e.type_ids.size() == 2 and attacks.size() >= 2:
			if typed.size() == 1 and typed[0].attack_type == e.type_ids[1]:
				rule_ok += 1
			else:
				rule_bad.append(pid)
		elif not typed.is_empty():
			rule_bad.append(pid)
	ok(rule_bad.is_empty() and rule_ok > 300, "dual-type rule in data (%d ok, bad: %s)" % [rule_ok, str(rule_bad.slice(0, 5))])
	# 3. per-type card coverage (cards.json attacks not carried by the final boss) and in the reward pool
	var cj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/cards.json"))
	var pool_ids: Dictionary = {}
	for card: CardData in data.get_reward_pool(data.get_default_player_id()):
		pool_ids[card.id] = true
	var counts: Dictionary = {}
	for id: String in (cj["cards"] as Dictionary).keys():
		var d: Dictionary = cj["cards"][id]
		if String(d["kind"]) != "attack" or data.is_boss_pokemon(String(d["pokemon"])):
			continue
		var key: String = String(d["type"]) + "/" + String(d["rarity"])
		counts[key] = int(counts.get(key, 0)) + 1
		if pool_ids.has(id):
			counts["pool/" + key] = int(counts.get("pool/" + key, 0)) + 1
	ok(chart.get_type_ids().size() == 18, "18 types")
	for t: String in chart.get_type_ids():
		ok(int(counts.get(t + "/uncommon", 0)) >= 2, "%s has >= 2 uncommon in cards.json (%d)" % [t, int(counts.get(t + "/uncommon", 0))])
		ok(int(counts.get(t + "/rare", 0)) >= 1, "%s has >= 1 rare in cards.json (%d)" % [t, int(counts.get(t + "/rare", 0))])
		ok(not data.get_carriers_for_type(t).is_empty(), "%s has carriers" % t)
		ok(int(counts.get("pool/" + t + "/uncommon", 0)) >= 1 and int(counts.get("pool/" + t + "/rare", 0)) >= 1, "%s: uncommon + rare in the reward pool" % t)
	print("t21 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
