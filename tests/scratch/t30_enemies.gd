extends SceneTree
## Story 030 scratch: new enemy actions (each one), field rules (each effect type + data references), Éthernatos phases,
## validation errors without crash. Run: timeout 300 godot --headless --path . -s tests/scratch/t30_enemies.gd
const P := "res://assets/data/"
const HP: int = 100
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


func card(id: String, cost: int = 1, damage: int = 0, block: int = 0, type_id: String = "normal") -> CardData:
	var kind: String = "attack" if damage > 0 else "skill"
	var d: Dictionary = {"name": id, "cost": cost, "kind": kind, "damage": damage, "block": block, "description": "",
			"type": type_id, "rarity": "common"}
	if kind == "attack":
		d["pokemon"] = "x"
	return CardData.from_dict(id, d)


func foe(actions: Array, hp: int = HP, types: Array = ["normal"], cur: int = -1) -> Combatant:
	return Combatant.from_dict("e", {"name": "E", "max_hp": hp, "sprite": "", "types": types, "pattern": "sequence",
			"actions": actions}, cur)


func filler(n: int) -> Array[CardData]:
	var out: Array[CardData] = []
	for i: int in n:
		out.append(card("f%d" % i, 1, 0, 1))
	return out


## Battle (typeless player, energy 3, hand 5), enemy mechanics from the data, optional field rule; started.
func mk(enemies: Array[Combatant], deck: Array[CardData] = [], rule: Dictionary = {}, player_types: Array[String] = []) -> Battle:
	var p := Combatant.new()
	p.id = "p"
	p.max_hp = HP
	p.hp = HP
	p.type_ids = player_types
	var d: Array[CardData] = deck if not deck.is_empty() else filler(10)
	var b := Battle.new(p, enemies, d, 3, 5, rng(7), gd.get_type_chart(), Callable(), "", [] as Array[ItemData],
			[] as Array[PotionData], gd.get_status_book())
	b.configure_enemy_mechanics(gd.get_junk_card(), gd.get_min_energy_after_drain())
	b.set_field_rule(rule)
	b.start()
	return b


func rule(effects: Array) -> Dictionary:
	return {"id": "t", "name": "Test", "description": "Règle de test", "effects": effects}


func _init() -> void:
	gd = GameData.new()
	ok(gd.load_all(), "real data loads")
	test_intents()
	test_actions()
	test_field_rules()
	test_rule_data()
	test_phases()
	test_validation()
	print("t30 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)


func test_intents() -> void:
	var cases: Dictionary = {
		"Attaque 4×3": {"type": "attack", "value": 4, "hits": 3},
		"Inflige burn 3": {"type": "status", "status": {"id": "burn", "value": 3}},
		"Soin 8": {"type": "heal", "value": 8},
		"Soigne allié 8": {"type": "heal_ally", "value": 8},
		"Protège allié 6": {"type": "block_ally", "value": 6},
		"Charge…": {"type": "charge", "value": 30, "attack_type": "dragon"},
		"Brise-garde 6": {"type": "strip_block", "value": 6},
		"Vol d'énergie 1": {"type": "drain_energy", "value": 1},
		"Débris ×2": {"type": "add_junk", "value": 2},
	}
	for text: String in cases.keys():
		var it: EnemyIntent = EnemyIntent.from_dict(cases[text])
		ok(it != null and it.display_text() == text, "intent text %s (got %s)" % [text, it.display_text() if it != null else "null"])
	var st: EnemyIntent = EnemyIntent.from_dict(cases["Inflige burn 3"])
	ok(st.value == 3 and st.status_value == 3, "status action value = status value")


func test_actions() -> void:
	# Multi-hit: 3 hits of 5, each a hit_resolved, block absorbs per hit.
	var b: Battle = mk([foe([{"type": "attack", "value": 5, "hits": 3}])])
	var hits: Array[int] = [0]
	b.hit_resolved.connect(func(t: Combatant, _a: int, _m: float) -> void: hits[0] += 1 if t == b.player else 0)
	b.player.add_block(7)
	b.end_turn()
	ok(b.player.hp == HP - 8 and hits[0] == 3, "multi-hit 5x3 vs 7 block -> -8 HP, 3 hits (hp %d, hits %d)" % [b.player.hp, hits[0]])
	ok(b.enemies[0].intent.display_text() == "Attaque 5×3", "multi-hit intent " + b.enemies[0].intent.display_text())
	# Status action (and type immunity: a fire player is immune to burn).
	b = mk([foe([{"type": "status", "status": {"id": "burn", "value": 3}}])])
	ok(b.enemies[0].intent.display_text() == "Inflige Brûlure 3", "status intent label " + b.enemies[0].intent.display_text())
	b.end_turn()
	ok(b.player.get_status_value("burn") == 3, "status action applies burn 3")
	var fire: Array[String] = ["fire"]
	b = mk([foe([{"type": "status", "status": {"id": "burn", "value": 3}}])], [], {}, fire)
	b.end_turn()
	ok(not b.player.has_status("burn"), "status action respects type immunity")
	# Aftermath immunity (RÉPIT): sleep refused.
	b = mk([foe([{"type": "status", "status": {"id": "sleep", "value": 1}}])])
	b.player.aftermath_turns = 2
	b.end_turn()
	ok(not b.player.has_status("sleep"), "status action respects RÉPIT")
	# Heal self.
	b = mk([foe([{"type": "heal", "value": 10}], HP, ["normal"], 50)])
	b.end_turn()
	ok(b.enemies[0].hp == 60, "heal 10 -> 60 (%d)" % b.enemies[0].hp)
	# heal_ally / block_ally target the weakest living enemy (the block lasts through the player's turn).
	b = mk([foe([{"type": "heal_ally", "value": 10}]), foe([{"type": "attack", "value": 1}], HP, ["normal"], 30)])
	b.end_turn()
	ok(b.enemies[1].hp == 40 and b.enemies[0].hp == HP, "heal_ally heals the weakest ally")
	b = mk([foe([{"type": "block_ally", "value": 7}]), foe([{"type": "attack", "value": 1}], HP, ["normal"], 30)])
	b.end_turn()
	ok(b.enemies[1].block == 7, "block_ally protects the weakest ally until its next phase (%d)" % b.enemies[1].block)
	# Charge: « Charge… », then « Attaque chargée 20 », kept while asleep.
	b = mk([foe([{"type": "charge", "value": 20}, {"type": "attack", "value": 1}])])
	ok(b.enemies[0].intent.display_text() == "Charge…", "charge intent")
	b.end_turn()
	ok(b.player.hp == HP and b.enemies[0].intent.charged and b.enemies[0].intent.display_text() == "Attaque chargée 20",
			"charged attack announced: " + b.enemies[0].intent.display_text())
	b.apply_status(b.enemies[0], "sleep", 1)
	b.end_turn()
	ok(b.player.hp == HP and b.enemies[0].intent.charged, "charged attack kept while the enemy sleeps")
	b.end_turn()
	ok(b.player.hp == HP - 20 and not b.enemies[0].intent.charged and b.enemies[0].intent.value == 1, "charged attack lands, then the sequence goes on")
	# strip_block before an ally's attack.
	b = mk([foe([{"type": "strip_block", "value": 6}]), foe([{"type": "attack", "value": 10}])])
	b.player.add_block(10)
	b.end_turn()
	ok(b.player.hp == HP - 6, "strip_block 6 then attack 10 vs 10 block -> -6 (%d)" % (HP - b.player.hp))
	# drain_energy: -2 of 3, floor 1 (data); a 5 drain stops at the floor.
	b = mk([foe([{"type": "drain_energy", "value": 2}])])
	b.end_turn()
	ok(b.energy == 1 and b.energy_lost == 2, "drain 2 -> energy 1")
	b = mk([foe([{"type": "drain_energy", "value": 5}])])
	b.end_turn()
	ok(b.energy == gd.get_min_energy_after_drain(), "drain never below the floor")
	# add_junk: 2 Débris in the draw pile, never playable, exhausted at the end of the turn.
	b = mk([foe([{"type": "add_junk", "value": 2}, {"type": "block", "value": 1}])], filler(20))
	b.end_turn()
	var junk: int = 0
	for c: CardData in b.draw_pile + b.hand:
		junk += 1 if c.is_junk() else 0
	ok(junk == 2, "add_junk shuffles 2 Débris (%d)" % junk)
	var safety: int = 0
	while safety < 6 and not b.hand.any(func(c: CardData) -> bool: return c.is_junk()):
		b.end_turn()
		safety += 1
	var ji: int = -1
	for i: int in b.hand.size():
		if b.hand[i].is_junk():
			ji = i
	ok(ji >= 0 and not b.can_play(ji) and not b.play_card(ji), "a Débris in hand is never playable")
	var ex_before: int = b.exhaust_pile.size()
	b.end_turn()
	ok(b.exhaust_pile.size() > ex_before and b.exhaust_pile.any(func(c: CardData) -> bool: return c.is_junk()), "Débris exhausts at end of turn")


func test_field_rules() -> void:
	var atk: Array = [{"type": "attack", "value": 5}]
	var b: Battle = mk([foe(atk)], [], rule([{"type": "enemy_block_per_turn", "value": 3}]))
	ok(b.enemies[0].block == 3 and b.get_field_rule()["name"] == "Test", "enemy_block_per_turn + get_field_rule")
	b = mk([foe(atk)], [], rule([{"type": "enemy_strength_per_turn", "value": 1, "every": 2}]))
	ok(b.enemies[0].strength == 0, "strength every 2: none on turn 1")
	b.end_turn()
	ok(b.enemies[0].strength == 1 and b.enemies[0].intent.value == 6, "strength +1 on turn 2, intent includes it")
	b = mk([foe(atk, HP, ["normal"], 50)], [], rule([{"type": "enemy_heal_per_turn", "value": 3}]))
	ok(b.enemies[0].hp == 53, "enemy_heal_per_turn")
	b = mk([foe(atk)], [], rule([{"type": "enemy_start_block", "value": 15}]))
	ok(b.enemies[0].block == 15, "enemy_start_block")
	b = mk([foe(atk)], [], rule([{"type": "player_status_each_turn", "status": "poison", "value": 1, "every": 2}]))
	ok(not b.player.has_status("poison"), "status every 2: not on turn 1")
	b.end_turn()
	ok(b.player.has_status("poison"), "status every 2: on turn 2")
	b = mk([foe(atk)], [], rule([{"type": "player_status_start", "status": "weak", "value": 3}]))
	ok(b.player.get_status_turns("weak") == 3, "player_status_start weak 3")
	var fired: Array[int] = [0]
	b = mk([foe(atk)], [], rule([{"type": "player_hp_loss_per_turn", "value": 2}]))
	ok(b.player.hp == HP - 2, "player_hp_loss_per_turn")
	b.field_rule_triggered.connect(func(_r: String) -> void: fired[0] += 1)
	b.player.hp = 1
	b.end_turn()
	ok(b.state == Battle.State.LOST or b.player.hp >= 0, "hp loss rule never crashes")
	b = mk([foe([{"type": "block", "value": 1}])], [], rule([{"type": "player_hp_loss_per_turn", "value": 5}]))
	b.player.hp = 3
	b.end_turn()
	ok(b.player.hp == Battle.FIELD_HP_FLOOR, "hp loss rule leaves 1 HP (%d)" % b.player.hp)
	b = mk([foe(atk)], filler(10), rule([{"type": "first_card_cost_up", "value": 1}]))
	ok(b.card_cost(b.hand[0]) == 2, "first card costs +1")
	b.play_card(0)
	ok(b.energy == 1 and b.card_cost(b.hand[0]) == 1, "second card at its normal cost")
	var deck: Array[CardData] = filler(9)
	deck.append(card("cher", 3, 0, 1))
	b = mk([foe(atk)], deck, rule([{"type": "burn_costliest_card"}]))
	ok(b.exhaust_pile.size() == (1 if deck.size() > 0 else 0) and b.hand.size() == 4 and b.hand.all(func(c: CardData) -> bool: return c.cost <= 3),
			"burn_costliest_card burns one card")
	b = mk([foe(atk)], [], rule([{"type": "player_draw_down", "value": 1}]))
	ok(b.hand.size() == 4, "player_draw_down 1 -> 4 cards")
	var fdeck: Array[CardData] = [card("feu", 1, 6, 0, "fire")]
	b = mk([foe([{"type": "attack", "value": 5, "attack_type": "fire"}])], fdeck,
			rule([{"type": "type_damage_up", "of_type": "fire", "value": 3}]))
	ok(int(b.preview_card_damage(0, 0)["amount"]) == 9 and b.enemies[0].intent.value == 8, "type_damage_up both sides (card %d, enemy %d)"
			% [int(b.preview_card_damage(0, 0)["amount"]), b.enemies[0].intent.value])
	b = mk([foe(atk)], filler(20), rule([{"type": "junk_each_turn", "value": 1}]))
	var j: int = 0
	for c: CardData in b.draw_pile + b.hand:
		j += 1 if c.is_junk() else 0
	ok(j == 1, "junk_each_turn adds a Débris")
	b = mk([foe(atk)], [], rule([{"type": "bogus"}, {"type": "enemy_block_per_turn", "value": 2}]))
	ok(b.enemies[0].block == 2 and (b.field_rule["effects"] as Array).size() == 1, "invalid effect ignored, no crash")
	b = mk([foe(atk)])
	ok(b.get_field_rule().is_empty(), "no rule -> {}")


func test_rule_data() -> void:
	var types: Array[String] = gd.get_type_chart().get_type_ids()
	var gyms: int = 0
	for t: String in types:
		gyms += 0 if gd.get_gym_field_rule(t).is_empty() else 1
	ok(gyms == 18, "18 gym field rules (%d)" % gyms)
	for t: String in gd.get_league_type_pool():
		ok(not gd.get_league_field_rule({"kind": "member", "type_id": t}).is_empty(), "league member rule " + t)
	ok(not gd.get_league_field_rule({"kind": "champion"}).is_empty(), "Maître rule")
	ok(not gd.get_league_field_rule({"kind": "final_boss"}).is_empty(), "final boss rule")
	ok(gd.get_junk_card() != null and gd.get_junk_card().is_junk(), "junk card from data")
	ok(not gd.get_card_ids().has("debris") if gd.has_method("get_card_ids") else true, "Débris not in the card pool")
	# Gym fight via SpecialFights (same call as Main / sim).
	var enemies: Array[Combatant] = [foe([{"type": "attack", "value": 5}])]
	var p := Combatant.new()
	p.max_hp = HP
	p.hp = HP
	var b := Battle.new(p, enemies, filler(10), 3, 5, rng(1), gd.get_type_chart())
	var r: Dictionary = SpecialFights.apply_fight_mechanics(gd, b, GameData.ROOM_GYM, {"type_id": "water"}, {})
	b.start()
	ok(String(r["id"]) == "gym_water" and b.enemies[0].block == 3, "gym water rule via SpecialFights")
	ok(FieldRules.check_rule("x", {"name": "n", "description": "d", "effects": []}) != "", "empty effects rejected")
	ok(FieldRules.check_rule("x", {"name": "n", "description": "d", "effects": [{"type": "type_damage_up", "value": 2}]}) != "",
			"type_damage_up needs of_type")
	ok(FieldRules.check_effect({"type": "player_status_each_turn", "status": "nope", "value": 1}, gd.get_status_ids()) != "",
			"unknown status rejected")


func test_phases() -> void:
	var enemies: Array[Combatant] = gd.create_enemies("final_eternatus", 1.0, 4)
	var p := Combatant.new()
	p.max_hp = 999
	p.hp = 999
	var deck: Array[CardData] = []
	for i: int in 10:
		deck.append(card("big%d" % i, 0, 240))
	var b := Battle.new(p, enemies, deck, 3, 5, rng(3), gd.get_type_chart(), Callable(), "", [] as Array[ItemData],
			[] as Array[PotionData], gd.get_status_book())
	SpecialFights.apply_fight_mechanics(gd, b, SpecialFights.LEAGUE_ROOM, {}, {"kind": "final_boss"})
	b.start()
	var boss: Combatant = b.enemies[0]
	ok(boss.phases.size() == 2 and b.get_field_rule()["id"] == "eternatus_dynamax", "Éthernatos: 2 phases + base rule")
	var msgs: Array[String] = []
	b.enemy_phase_changed.connect(func(_e: Combatant, i: int, m: String) -> void: msgs.append("%d:%s" % [i, m]))
	b.apply_status(boss, "poison", 3)
	b.play_card(0, 0)  # 460 -> 220 (<= 50 %)
	ok(boss.phase_index == 1 and msgs.size() == 1 and msgs[0].contains("Infinitamax"), "phase 2 at <= 50 %: " + str(msgs))
	ok(b.get_field_rule()["id"] == "eternatus_infinitamax" and not boss.has_status("poison"), "phase 2: new rule, statuses cleared")
	ok(boss.intent != null and boss.intent.hits == 2, "phase 2 shows its first action at once: " + boss.intent.display_text())
	b.play_card(0, 0)  # 220 -> 0? 240 dmg kills: use a weaker path below
	ok(b.state == Battle.State.WON or boss.phase_index == 2, "second hit ends or reaches phase 3")
	# Both thresholds in one hit -> both phases in order.
	enemies = gd.create_enemies("final_eternatus", 1.0, 4)
	deck.clear()
	for i: int in 10:
		deck.append(card("mid%d" % i, 0, 380))
	b = Battle.new(p, enemies, deck, 3, 5, rng(3), gd.get_type_chart(), Callable(), "", [] as Array[ItemData],
			[] as Array[PotionData], gd.get_status_book())
	SpecialFights.apply_fight_mechanics(gd, b, SpecialFights.LEAGUE_ROOM, {}, {"kind": "final_boss"})
	b.start()
	msgs.clear()
	b.enemy_phase_changed.connect(func(_e: Combatant, i: int, m: String) -> void: msgs.append("%d:%s" % [i, m]))
	b.play_card(0, 0)  # 460 -> 80 (<= 20 %)
	ok(b.enemies[0].phase_index == 2 and msgs.size() == 2 and msgs[0].begins_with("1:") and msgs[1].begins_with("2:"),
			"both phases crossed in one hit: " + str(msgs))
	ok(b.enemies[0].intent.hits == 3, "phase 3 first action: " + b.enemies[0].intent.display_text())


func test_validation() -> void:
	print("--- expected errors below ---")
	ok(EnemyIntent.from_dict({"type": "status"}) == null, "status without status rejected")
	ok(EnemyIntent.from_dict({"type": "block", "value": 3, "hits": 2}) == null, "hits on block rejected")
	ok(EnemyIntent.from_dict({"type": "heal", "value": 3, "attack_type": "fire"}) == null, "attack_type on heal rejected")
	ok(EnemyIntent.from_dict({"type": "heal"}) == null, "heal without value rejected")
	ok(EnemyIntent.from_dict({"type": "explode", "value": 3}) == null, "unknown action rejected")
	ok(Combatant.parse_phase("p", {"hp_below": 1.5, "pattern": "sequence", "actions": [], "message": ""}).is_empty(), "bad phase rejected")
	# A data file with a broken field rule / unknown reference fails to load without crashing.
	var fr: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(P + "field_rules.json"))
	(fr["rules"] as Dictionary)["gym_water"] = {"name": "x", "description": "y", "effects": [{"type": "nope"}]}
	var path: String = "user://t30_field_rules.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(fr))
	f.close()
	var g := GameData.new()
	ok(not g.load_all(GameData.DEFAULT_CARDS_PATH, GameData.DEFAULT_POKEMON_PATH, GameData.DEFAULT_TYPES_PATH,
			GameData.DEFAULT_REWARDS_PATH, GameData.DEFAULT_ACT_PATH, GameData.DEFAULT_EVENTS_PATH, GameData.DEFAULT_ITEMS_PATH,
			GameData.DEFAULT_POTIONS_PATH, GameData.DEFAULT_SHOP_PATH, GameData.DEFAULT_ZONES_PATH, GameData.DEFAULT_LEAGUE_PATH,
			GameData.DEFAULT_ROSTER_PATH, GameData.DEFAULT_STATUSES_PATH, GameData.DEFAULT_BALLS_PATH, GameData.DEFAULT_RIVAL_PATH,
			GameData.DEFAULT_TALENTS_PATH, path), "broken field rule -> load_all false, no crash")
	print("--- end of expected errors ---")
