extends SceneTree
## Story 027 scratch: the card effect grammar (draw, energy, multi-hit, exhaust, retain, Force, Faiblesse / Vulnérable,
## self-damage, block scaling, conditionals, on_draw / end_of_turn_in_hand hooks) and its load-time validation.
## Battles are built WITHOUT a talent book (no talents, no Élan) so every number below is the card's own.
const P := "res://assets/data/"
const HP: int = 100
const ATK: int = 8
var passes: int = 0
var fails: int = 0
var gd: GameData
var chart: TypeChart


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


func card(id: String, extra: Dictionary) -> CardData:
	var d: Dictionary = {"name": id, "cost": 0, "kind": "attack", "damage": 0, "block": 0, "description": "", "type": "normal",
			"pokemon": "salameche", "rarity": "common"}
	for k: String in extra.keys():
		d[k] = extra[k]
	if String(d["kind"]) == "skill":
		d.erase("pokemon")
		d.erase("type")
	return CardData.from_dict(id, d)


func enemy(types: Array, attack: int = ATK) -> Combatant:
	return Combatant.from_dict("e", {"name": "E", "max_hp": HP, "sprite": "", "types": types, "pattern": "sequence",
			"actions": [{"type": "attack", "value": attack}]})


func mk(cards: Array, enemies: Array, book: TalentBook = null) -> Battle:
	var p := Combatant.new()
	p.id = "p"
	p.max_hp = HP
	p.hp = HP
	var deck: Array[CardData] = []
	deck.assign(cards)
	var es: Array[Combatant] = []
	es.assign(enemies)
	var b := Battle.new(p, es, deck, 3, 5, rng(1), chart, gd.get_pokemon_info, "salameche", [] as Array[ItemData],
			[] as Array[PotionData], gd.get_status_book(), null, {}, {}, false, book)
	b.start()
	return b


func idx(b: Battle, id: String) -> int:
	for i: int in b.hand.size():
		if b.hand[i].id == id:
			return i
	return -1


func play(b: Battle, id: String, target: int = 0) -> bool:
	return b.play_card(idx(b, id), target)


func _initialize() -> void:
	gd = GameData.new()
	ok(gd.load_all(), "real data loads (new cards, statuses, talents)")
	chart = gd.get_type_chart()
	_basic_effects()
	_hits()
	_piles()
	_strength()
	_weak_vulnerable()
	_scaling()
	_conditionals()
	_validation()
	print("t26 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)


func _basic_effects() -> void:
	var filler: Array = []
	for i: int in 7:
		filler.append(card("f%d" % i, {"damage": 1}))
	var b := mk(filler + [card("d", {"kind": "skill", "draw": 2})], [enemy(["normal"])])
	while idx(b, "d") < 0:  # the draw card may sit in the draw pile: next turn
		b.end_turn()
	var before: int = b.hand.size()
	var drawn: Array = []
	b.cards_drawn.connect(func(n: int) -> void: drawn.append(n))
	ok(play(b, "d", -1), "draw card played without target")
	ok(b.hand.size() == before - 1 + 2 and drawn == [2], "draw 2: hand %d -> %d" % [before, b.hand.size()])
	b = mk([card("en", {"kind": "skill", "energy": 2})], [enemy(["normal"])])
	ok(play(b, "en", -1) and b.energy == 5, "energy +2: %d" % b.energy)
	b = mk([card("sd", {"damage": 4, "self_damage": 3})], [enemy(["normal"])])
	b.player.block = 10
	ok(play(b, "sd") and b.player.hp == HP - 3 and b.player.block == 10, "self damage ignores block: hp %d" % b.player.hp)
	b = mk([card("sd", {"damage": 4, "self_damage": 3})], [enemy(["normal"])])
	b.player.hp = 2
	ok(play(b, "sd") and b.player.hp == 1 and b.state == Battle.State.PLAYER_TURN, "self damage never K.O.s: hp %d" % b.player.hp)
	b = mk([card("od", {"damage": 1, "on_draw": {"energy": 1}})], [enemy(["normal"])])
	ok(b.energy == 4, "on_draw energy: %d" % b.energy)
	b = mk([card("eot", {"damage": 1, "cost": 9, "end_of_turn_in_hand": {"block": 2}})], [enemy(["normal"])])
	b.end_turn()
	ok(b.player.hp == HP - (ATK - 2), "end_of_turn_in_hand block 2 absorbed: hp %d" % b.player.hp)


func _hits() -> void:
	var b := mk([card("m", {"damage": 2, "hits": 3})], [enemy(["normal"])])
	b.enemies[0].block = 4
	var seen: Array = []
	b.hit_resolved.connect(func(_t: Combatant, amount: int, _m: float) -> void: seen.append(amount))
	ok(play(b, "m"), "multi-hit played")
	ok(seen == [2, 2, 2], "3 separate hits resolved: %s" % str(seen))
	ok(b.enemies[0].block == 0 and b.enemies[0].hp == HP - 2, "block eaten hit by hit: hp %d" % b.enemies[0].hp)
	# Type multiplier applies to every hit, before block.
	var one: int = chart.final_damage(3, "fire", ["grass"] as Array[String])
	b = mk([card("m", {"damage": 3, "hits": 2, "type": "fire"})], [enemy(["grass"])])
	b.enemies[0].block = 5
	play(b, "m")
	ok(one > 3 and b.enemies[0].hp == HP - (2 * one - 5), "super-effective multi-hit vs block: hp %d (hit %d)" % [b.enemies[0].hp, one])
	ok(int(b.preview_card_damage(0, 0)["hits"]) == 0, "preview of an empty hand is neutral")
	# A dead target takes no further hit; the battle is won.
	b = mk([card("m", {"damage": 60, "hits": 3})], [enemy(["normal"])])
	seen = []
	b.hit_resolved.connect(func(_t: Combatant, amount: int, _m: float) -> void: seen.append(amount))
	play(b, "m")
	ok(seen.size() == 2 and b.state == Battle.State.WON, "hits stop on a K.O. target: %s" % str(seen))
	# target_all + hits: every living enemy takes every hit.
	b = mk([card("m", {"damage": 2, "hits": 2, "target_all": true})], [enemy(["normal"]), enemy(["normal"])])
	var pv: Dictionary = b.preview_card_damage(0, 1)
	play(b, "m")
	ok(b.enemies[0].hp == HP - 4 and b.enemies[1].hp == HP - 4, "target_all multi-hit")
	ok(int(pv["amount"]) == 2 and int(pv["hits"]) == 2, "preview matches: %s" % str(pv))
	# An immune (x0) multi-hit inflicts no status.
	b = mk([card("m", {"damage": 2, "hits": 2, "status": {"id": "poison", "value": 2}})], [enemy(["ghost"])])
	play(b, "m")
	ok(b.enemies[0].hp == HP and not b.enemies[0].has_status("poison"), "x0 multi-hit: no damage, no status")


func _piles() -> void:
	var b := mk([card("x", {"kind": "skill", "block": 1, "exhaust": true}), card("a", {"damage": 1})], [enemy(["normal"])])
	var ex: Array = []
	b.card_exhausted.connect(func(c: CardData) -> void: ex.append(c.id))
	play(b, "x", -1)
	ok(b.exhaust_pile.size() == 1 and b.discard_pile.is_empty() and ex == ["x"], "exhausted card leaves the deck")
	for t: int in 4:
		b.end_turn()
		ok(idx(b, "x") < 0 and b.hand.size() == 1, "exhausted card never comes back (turn %d)" % t)
	b = mk([card("r", {"kind": "skill", "block": 1, "cost": 1, "retain": true}), card("a", {"damage": 1}), card("b", {"damage": 1})],
			[enemy(["normal"])])
	b.end_turn()
	ok(idx(b, "r") >= 0 and b.hand.size() == 3 and b.discard_pile.is_empty(), "retained card stays, the others cycle: hand %d" % b.hand.size())
	play(b, "r", -1)
	b.end_turn()
	ok(b.hand.size() == 3 and b.exhaust_pile.is_empty(), "a played retain card is discarded normally")


func _strength() -> void:
	var b := mk([card("s", {"kind": "skill", "strength": 2}), card("a", {"damage": 6}), card("m", {"damage": 2, "hits": 2})],
			[enemy(["normal"])])
	var ev: Array = []
	b.strength_changed.connect(func(battle_v: int, turn_v: int) -> void: ev.append([battle_v, turn_v]))
	play(b, "s", -1)
	ok(b.get_strength() == 2 and ev == [[2, 0]], "Force for the battle: %s" % str(ev))
	ok(int(b.preview_card_damage(idx(b, "a"), 0)["amount"]) == 8, "preview includes Force")
	play(b, "a")
	ok(b.enemies[0].hp == HP - 8, "Force adds to the hit")
	play(b, "m")
	ok(b.enemies[0].hp == HP - 8 - 8, "Force adds to EVERY hit of a multi-hit")
	b.end_turn()
	play(b, "a")
	ok(b.get_strength() == 2 and b.enemies[0].hp == HP - 24, "Force lasts the battle")
	b = mk([card("s", {"kind": "skill", "strength_turn": 3}), card("a", {"damage": 6})], [enemy(["normal"])])
	play(b, "s", -1)
	ok(b.get_turn_strength() == 3 and b.get_strength() == 0, "Force for the turn")
	play(b, "a")
	ok(b.enemies[0].hp == HP - 9, "turn Force adds to the hit")
	b.end_turn()
	play(b, "a")
	ok(b.get_turn_strength() == 0 and b.enemies[0].hp == HP - 15, "turn Force is gone next turn")


func _weak_vulnerable() -> void:
	var book: StatusBook = gd.get_status_book()
	var weak_m: float = book.get_def("weak").damage_dealt_multiplier
	var vuln_m: float = book.get_def("vulnerable").damage_taken_multiplier
	ok(weak_m == 0.75 and vuln_m == 1.5, "data: Faiblesse -25 %, Vulnérable +50 %")
	# Weak enemy: its shown intent IS the reduced value; ticks down at the end of ITS turn.
	var b := mk([card("w", {"kind": "skill", "status": {"id": "weak", "value": 2}})], [enemy(["normal"])])
	ok(b.enemies[0].intent.value == ATK, "intent before")
	play(b, "w")
	ok(b.enemies[0].intent.value == floori(ATK * weak_m) and b.enemies[0].get_status_value("weak") == 2, "weak intent: %d" % b.enemies[0].intent.value)
	b.end_turn()
	ok(b.player.hp == HP - 6 and b.enemies[0].get_status_value("weak") == 1, "weak hit 6, 1 turn left")
	ok(b.enemies[0].intent.value == 6, "still weak next intent")
	b.end_turn()
	ok(b.player.hp == HP - 12 and not b.enemies[0].has_status("weak"), "weak expired after 2 enemy turns")
	ok(b.enemies[0].intent.value == ATK, "intent back to normal")
	# Re-applying adds turns.
	b = mk([card("w", {"kind": "skill", "status": {"id": "weak", "value": 2}}), card("w2", {"kind": "skill", "status": {"id": "weak", "value": 1}})],
			[enemy(["normal"])])
	play(b, "w")
	play(b, "w2")
	ok(b.enemies[0].get_status_value("weak") == 3 and b.enemies[0].get_status_turns("weak") == 3, "weak stacks its duration")
	# Vulnerable enemy takes +50 % (rounded down), before the type multiplier; gone after its turn.
	b = mk([card("v", {"kind": "skill", "status": {"id": "vulnerable", "value": 1}}), card("a", {"damage": 7}), card("m", {"damage": 3, "hits": 2})],
			[enemy(["normal"])])
	play(b, "v")
	ok(int(b.preview_card_damage(idx(b, "a"), 0)["amount"]) == 10, "preview vulnerable")
	play(b, "a")
	ok(b.enemies[0].hp == HP - 10, "7 -> 10 on a vulnerable target: hp %d" % b.enemies[0].hp)
	play(b, "m")
	ok(b.enemies[0].hp == HP - 10 - 8, "each hit 3 -> 4: hp %d" % b.enemies[0].hp)
	b.end_turn()
	ok(not b.enemies[0].has_status("vulnerable"), "vulnerable 1 ends after the enemy's turn")
	play(b, "a")
	ok(b.enemies[0].hp == HP - 18 - 7, "normal damage again")
	var se: int = chart.final_damage(floori(7 * vuln_m), "fire", ["grass"] as Array[String])
	b = mk([card("v", {"kind": "skill", "status": {"id": "vulnerable", "value": 1}}), card("a", {"damage": 7, "type": "fire"})], [enemy(["grass"])])
	play(b, "v")
	play(b, "a")
	ok(b.enemies[0].hp == HP - se and se > floori(7 * vuln_m), "vulnerable (rounded down) then the type multiplier: %d" % se)
	# The player can be weak / vulnerable too (same statuses, both directions).
	b = mk([card("a", {"damage": 8})], [enemy(["normal"])])
	b.apply_status(b.player, "weak", 1)
	play(b, "a")
	ok(b.enemies[0].hp == HP - 6, "weak player deals 6")
	b.apply_status(b.player, "vulnerable", 2)
	ok(b.enemies[0].intent.value == 12, "intent vs a vulnerable player: %d" % b.enemies[0].intent.value)
	b.end_turn()
	ok(b.player.hp == HP - 12 and not b.player.has_status("weak") and b.player.get_status_value("vulnerable") == 1, "player statuses tick at the end of its turn")
	# apply grammar: all enemies / self.
	b = mk([card("all", {"kind": "skill", "apply": [{"status": "weak", "value": 1, "to": "all_enemies"}, {"status": "vulnerable", "value": 1, "to": "self"}]})],
			[enemy(["normal"]), enemy(["normal"])])
	ok(not b.hand[0].needs_target() and play(b, "all", -1), "apply to all needs no target")
	ok(b.enemies[0].has_status("weak") and b.enemies[1].has_status("weak") and b.player.has_status("vulnerable"), "apply all_enemies + self")


func _scaling() -> void:
	var b := mk([card("bpe", {"kind": "skill", "block_per_enemy": 4})], [enemy(["normal"]), enemy(["normal"])])
	play(b, "bpe", -1)
	ok(b.player.block == 8, "block per enemy: %d" % b.player.block)
	b = mk([card("blk", {"kind": "skill", "block": 5}), card("dfb", {"damage_from_block": 1})], [enemy(["normal"])])
	ok(b.hand[idx(b, "dfb")].needs_target(), "damage_from_block needs a target")
	play(b, "blk", -1)
	play(b, "dfb")
	ok(b.enemies[0].hp == HP - 5 and b.player.block == 5, "damage equal to block (block kept): hp %d" % b.enemies[0].hp)


func _conditionals() -> void:
	var bonus: Dictionary = {"damage": 3}
	# carrier_was_active / carrier_entered (the starter is salameche).
	var b := mk([card("wa", {"damage": 5, "conditional": {"if": "carrier_was_active", "then": bonus}}),
			card("en", {"damage": 5, "pokemon": "squirtle", "conditional": [{"if": "carrier_entered", "then": {"draw": 1}}, {"if": "carrier_was_active", "then": bonus}]}),
			card("f1", {"damage": 1}), card("f2", {"damage": 1}), card("f3", {"damage": 1}), card("f4", {"damage": 1})], [enemy(["normal"])])
	while idx(b, "wa") < 0 or idx(b, "en") < 0:
		b.end_turn()
	var hp0: int = b.enemies[0].hp
	play(b, "wa")
	ok(b.enemies[0].hp == hp0 - 8, "carrier_was_active: +3")
	var hand0: int = b.hand.size()
	play(b, "en")
	ok(b.enemies[0].hp == hp0 - 8 - 5 and b.hand.size() == hand0 - 1 + 1 and b.active_pokemon_id == "squirtle", "carrier_entered: draw 1, no was_active bonus")
	b = mk([card("wa", {"damage": 5, "pokemon": "squirtle", "conditional": {"if": "carrier_was_active", "then": bonus}})], [enemy(["normal"])])
	play(b, "wa")
	ok(b.enemies[0].hp == HP - 5, "a card that switches in was not active")
	# target_has_status any / id; evaluated BEFORE the card's own status.
	b = mk([card("st", {"damage": 5, "status": {"id": "poison", "value": 2}, "conditional": {"if": {"target_has_status": "any"}, "then": bonus}}),
			card("sb", {"damage": 5, "conditional": {"if": {"target_has_status": "burn"}, "then": bonus}}),
			card("sp", {"damage": 5, "conditional": {"if": {"target_has_status": "poison"}, "then": bonus}})], [enemy(["normal"])])
	play(b, "st")
	ok(b.enemies[0].hp == HP - 5 and b.enemies[0].has_status("poison"), "no status yet: no bonus")
	play(b, "sb")
	ok(b.enemies[0].hp == HP - 10, "wrong status: no bonus")
	play(b, "sp")
	ok(b.enemies[0].hp == HP - 18, "right status: +3")
	# super_effective, target_hp_below, first_card_of_turn.
	b = mk([card("se", {"damage": 4, "type": "fire", "conditional": {"if": "super_effective", "then": {"strength_turn": 2}}})], [enemy(["grass"])])
	play(b, "se")
	ok(b.get_turn_strength() == 2, "super_effective met")
	b = mk([card("se", {"damage": 4, "type": "fire", "conditional": {"if": "super_effective", "then": {"strength_turn": 2}}})], [enemy(["normal"])])
	play(b, "se")
	ok(b.get_turn_strength() == 0, "super_effective not met")
	b = mk([card("hp", {"damage": 5, "conditional": {"if": {"target_hp_below": 0.5}, "then": bonus}}), card("hp2", {"damage": 5, "conditional": {"if": {"target_hp_below": 0.5}, "then": bonus}})],
			[enemy(["normal"])])
	b.enemies[0].hp = HP / 2
	play(b, "hp")
	ok(b.enemies[0].hp == HP / 2 - 5, "exactly half is not below")
	play(b, "hp2")
	ok(b.enemies[0].hp == HP / 2 - 5 - 8, "below half: +3")
	b = mk([card("fc", {"damage": 4, "conditional": {"if": "first_card_of_turn", "then": {"apply": [{"status": "weak", "value": 1, "to": "target"}]}}}),
			card("fc2", {"damage": 4, "conditional": {"if": "first_card_of_turn", "then": {"apply": [{"status": "vulnerable", "value": 1, "to": "target"}]}}})], [enemy(["normal"])])
	play(b, "fc")
	play(b, "fc2")
	ok(b.enemies[0].has_status("weak") and not b.enemies[0].has_status("vulnerable"), "first_card_of_turn only for the first card")
	b.end_turn()
	play(b, "fc2")
	ok(b.enemies[0].has_status("vulnerable"), "first card of the next turn")
	# then.hits adds hits.
	b = mk([card("h", {"damage": 2, "conditional": {"if": "carrier_was_active", "then": {"hits": 2}}})], [enemy(["normal"])])
	ok(int(b.preview_card_damage(0, 0)["hits"]) == 3, "preview counts conditional hits")
	play(b, "h")
	ok(b.enemies[0].hp == HP - 6, "conditional extra hits")
	# elan_at_least needs the Élan rules (real talents.json: +1 per attack of the active Pokémon).
	var tb: TalentBook = gd.get_talent_book()
	b = mk([card("e1", {"damage": 1}), card("e2", {"damage": 1}), card("el", {"damage": 4, "conditional": {"if": {"elan_at_least": 2}, "then": {"damage": 4}}}),
			card("el2", {"damage": 4, "pokemon": "squirtle", "conditional": {"if": {"elan_at_least": 1}, "then": {"damage": 4}}})], [enemy(["normal"])], tb)
	ok(int(b.preview_card_damage(idx(b, "el"), 0)["amount"]) == 4 + b.get_next_attack_bonus(), "elan 0: no bonus")
	play(b, "e1")
	play(b, "e2")
	var hp1: int = b.enemies[0].hp
	ok(b.get_elan() == 2, "elan built: %d" % b.get_elan())
	play(b, "el")
	ok(b.enemies[0].hp == hp1 - (4 + 4 + b.get_elan_damage_bonus() - tb.elan_damage_per_stack), "elan_at_least 2 met: lost %d" % (hp1 - b.enemies[0].hp))
	hp1 = b.enemies[0].hp
	play(b, "el2")
	ok(b.get_elan() == 0 and b.enemies[0].hp == hp1 - 4, "a switching card is played with 0 Élan")


func _validation() -> void:
	print("--- errors expected below (invalid data rejected) ---")
	ok(card("bad", {"damage": 2, "hits": 0}) == null, "hits 0 rejected")
	ok(card("bad", {"damage": 2, "draw": -1}) == null, "negative draw rejected")
	ok(card("bad", {"damage": 2, "exhaust": "yes"}) == null, "non-bool exhaust rejected")
	ok(card("bad", {"damage": 2, "conditional": {"if": "full_moon", "then": {"draw": 1}}}) == null, "unknown condition rejected")
	ok(card("bad", {"damage": 2, "conditional": {"if": "super_effective", "then": {}}}) == null, "empty then rejected")
	ok(card("bad", {"damage": 2, "conditional": {"if": {"target_hp_below": 3}, "then": {"draw": 1}}}) == null, "fraction > 1 rejected")
	ok(card("bad", {"kind": "skill", "conditional": {"if": "carrier_entered", "then": {"draw": 1}}}) == null, "carrier condition on a skill rejected")
	ok(card("bad", {"kind": "skill", "conditional": {"if": "first_card_of_turn", "then": {"damage": 2}}}) == null, "then.damage on a skill rejected")
	ok(card("bad", {"kind": "skill", "hits": 2}) == null, "hits on a skill rejected")
	ok(card("bad", {"damage": 2, "apply": [{"status": "weak", "value": 1, "to": "moon"}]}) == null, "unknown apply.to rejected")
	ok(card("bad", {"damage": 2, "on_draw": {"apply": [{"status": "weak", "value": 1, "to": "target"}]}}) == null, "targeted on_draw rejected")
	ok(card("fine", {"damage": 2, "hits": 2, "exhaust": true, "retain": true, "draw": 1}) != null, "valid card accepted")
	var up: CardData = card("fine", {"damage": 2, "hits": 2, "exhaust": true, "draw": 1, "description": "Inflige 2 dégâts 2 fois."}).upgraded_copy(gd.get_upgrade_rules())
	ok(up != null and up.hits == 2 and up.exhaust and int(up.effect.get("draw", 0)) == 1, "upgraded copy keeps the new fields")
	# GameData: an effect naming an unknown status makes the load fail (no crash).
	var root: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(P + "cards.json"))
	(root["cards"] as Dictionary)["bluff"]["conditional"] = {"if": "first_card_of_turn", "then": {"apply": [{"status": "nope", "value": 1, "to": "target"}]}}
	var f := FileAccess.open("user://t26_cards.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(root))
	f.close()
	ok(not GameData.new().load_all("user://t26_cards.json"), "unknown status in an effect: load refused")
	print("--- end of expected errors ---")
	# Real example cards.
	for id: String in ["combo_griffe", "double_pied", "taillade", "demi_tour", "chatiment", "saumure", "roulade", "bluff", "damocles",
			"big_splash", "aiguisage", "danse_lames", "groz_yeux", "charme", "hate", "chargeur", "garde_large", "stockage"]:
		ok(gd.has_card(id), "example card '%s' exists" % id)
	ok(gd.get_card("combo_griffe").hits == 3 and gd.get_card("danse_lames").exhaust and gd.get_card("stockage").retain, "example cards carry their fields")
	var pool_ids: Array = []
	for c: CardData in gd.get_reward_pool("salameche"):
		pool_ids.append(c.id)
	ok("combo_griffe" in pool_ids and "stockage" in pool_ids, "example cards can be offered as rewards")
