extends SceneTree
## Story 029 scratch: varied and build items. Every new trigger / effect gets a Battle (or RunState) arranged with the real items.json,
## plus duplicates, loot weights, validation errors (no crash) and icon / description checks.
const P := "res://assets/data/"
const HP: int = 200
const DMG: int = 6
var passes: int = 0
var fails: int = 0
var gd: GameData
var talent_events: int = 0


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


func card(id: String, pokemon: String = "", type_id: String = "normal", kind: String = "attack", cost: int = 0, exhaust: bool = false, extra: Dictionary = {}) -> CardData:
	var d: Dictionary = {"name": id, "cost": cost, "kind": kind, "damage": DMG if kind == "attack" else 0, "block": 10 if kind == "skill" else 0,
			"description": "", "type": type_id, "pokemon": pokemon, "rarity": "common", "exhaust": exhaust}
	d.merge(extra, true)
	return CardData.from_dict(id, d)


func enemy(hp: int = HP, atk: int = 8) -> Combatant:
	return Combatant.from_dict("e", {"name": "E", "max_hp": hp, "sprite": "", "types": ["normal"], "pattern": "sequence",
			"actions": [{"type": "attack", "value": atk}]})


func items_of(ids: Array) -> Array[ItemData]:
	var out: Array[ItemData] = []
	for i: String in ids:
		out.append(gd.get_item(i))
	return out


## Started battle. `cards` = deck (hand 5 / energy 3), starter salameche, real talents.
func mk(cards: Array, item_ids: Array, enemies: Array[Combatant] = [], with_talents: bool = false, capture: bool = false) -> Battle:
	var p := Combatant.new()
	p.id = "p"
	p.max_hp = HP
	p.hp = HP - 20
	var deck: Array[CardData] = []
	deck.assign(cards)
	var es: Array[Combatant] = enemies if not enemies.is_empty() else ([enemy()] as Array[Combatant])
	var b := Battle.new(p, es, deck, 3, 5, rng(1), gd.get_type_chart(), gd.get_pokemon_info, "salameche", items_of(item_ids),
			[] as Array[PotionData], gd.get_status_book(), gd.get_capture_rules() if capture else null,
			gd.get_ball_book() if capture else {}, {"poke_ball": 3} if capture else {}, capture,
			gd.get_talent_book() if with_talents else null)
	b.talent_triggered.connect(func(_p: String, _t: String) -> void: talent_events += 1)
	b.start()
	return b


func idx(b: Battle, id: String) -> int:
	for i: int in b.hand.size():
		if b.hand[i].id == id:
			return i
	return -1


func play(b: Battle, id: String, target: int = 0) -> int:
	var i: int = idx(b, id)
	if i < 0:
		return -1
	var before: int = b.enemies[target].hp if target < b.enemies.size() else 0
	if not b.play_card(i, target):
		return -1
	return before - b.enemies[target].hp


func _initialize() -> void:
	gd = GameData.new()
	ok(gd.load_all(), "real data loads")
	_data()
	_damage_type()
	_free_card()
	_elan()
	_talent()
	_statuses()
	_battle_start()
	_exhaust()
	_block_keep()
	_kill()
	_capture_and_run()
	_validation()
	_acquisition()
	print("t29 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)


func _data() -> void:
	var ids: Array[String] = gd.get_item_ids()
	ok(ids.size() >= 40, "at least 40 items (%d)" % ids.size())
	var by_rarity: Dictionary = {"common": 0, "uncommon": 0, "rare": 0}
	var build: int = 0
	var old: Array[String] = ["damage_bonus", "heal_flat", "heal_percent_max", "block_flat", "money_bonus_on_win", "max_hp_up", "draw_up",
			"energy_up_per_turn", "status_immunity"]
	var no_desc: int = 0
	var no_icon: int = 0
	for id: String in ids:
		var it: ItemData = gd.get_item(id)
		by_rarity[it.rarity] = int(by_rarity[it.rarity]) + 1
		for e: Dictionary in it.effects:
			if String(e["type"]) not in old or it.first_attack_each_battle:
				build += 1
				break
		if it.description.strip_edges().is_empty() or it.display_name.strip_edges().is_empty():
			no_desc += 1
		if not FileAccess.file_exists("res://assets/sprites/items/%s.png" % id) or not ResourceLoader.exists("res://assets/sprites/items/%s.png" % id):
			no_icon += 1
			print("no icon: ", id)
	ok(build >= 12, "at least 12 build items (%d)" % build)
	ok(no_desc == 0, "every item has a name and a French description")
	ok(no_icon == 0, "every item has an imported icon file")
	ok(int(by_rarity["common"]) > 0 and int(by_rarity["uncommon"]) > 0 and int(by_rarity["rare"]) > 0, "all rarities used " + str(by_rarity))
	ok(int(by_rarity["common"]) >= int(by_rarity["rare"]) * 2, "commons about twice the rares")
	for id: String in ["restes", "bandeau", "baie_oran", "orbe_vie", "cloche_eclat", "peau_metal", "piece_rune", "lunettes_choix",
			"ceinture_force", "gemme_energie", "poudre_soin", "baie_cheri", "baie_mitrons", "baie_ceriz", "baie_prine"]:
		ok(gd.has_item(id), "old item kept: " + id)
	ok(gd.get_item("baie_oran").weight < 1.0 and gd.get_item("restes").weight == 1.0, "berries weigh less (weight field, default 1)")


func _damage_type() -> void:
	var b := mk([card("f", "", "fire"), card("w", "", "water")], ["charbon"])
	ok(play(b, "f") == DMG + 2, "charbon: fire attack +2")
	ok(play(b, "w") == DMG, "charbon: water attack unchanged")
	var b2 := mk([card("f", "", "fire")], [])
	ok(play(b2, "f") == DMG, "no item: plain damage")
	var b3 := mk([card("f", "", "fire")], ["charbon", "lunettes_choix"])
	ok(play(b3, "f") == DMG + 3, "type bonus stacks with damage_bonus")


func _free_card() -> void:
	var b := mk([card("f1", "", "fire", "attack", 2), card("f2", "", "fire", "attack", 2), card("w1", "", "water", "attack", 2)], ["plaque_flamme"])
	ok(b.card_cost(b.hand[idx(b, "f1")]) == 0 and b.card_cost(b.hand[idx(b, "w1")]) == 2, "first fire card free, water not")
	play(b, "f1")
	ok(b.energy == 3, "free card cost nothing")
	ok(b.card_cost(b.hand[idx(b, "f2")]) == 2, "second fire card costs full")
	play(b, "f2")
	ok(b.energy == 1, "second fire card paid 2")
	b.end_turn()
	var has_free: bool = false
	for c: CardData in b.hand:
		if c.type_id == "fire" and b.card_cost(c) == 0:
			has_free = true
	ok(has_free, "free again next turn")


func _elan() -> void:
	var deck: Array = []
	for i: int in 10:
		deck.append(card("a%d" % i, "salameche", "fire"))
	var b := mk(deck, ["eclat_magique"], [enemy(900)], true)
	ok(b.get_elan_cap() == 7, "eclat_magique: cap 5 -> 7")
	for n: int in 2:
		for c: CardData in b.hand.duplicate():
			b.play_card(idx(b, c.id), 0)
		b.end_turn()
	ok(b.get_elan() == 7, "elan reaches 7 (%d)" % b.get_elan())
	var b0 := mk(deck, [], [enemy(900)], true)
	for n: int in 2:
		for c: CardData in b0.hand.duplicate():
			b0.play_card(idx(b0, c.id), 0)
		b0.end_turn()
	ok(b0.get_elan() == 5 and b0.get_elan_cap() == 5, "no item: capped at 5")
	# elan_keep_percent
	var mixed: Array = [card("s1", "salameche", "fire"), card("s2", "salameche", "fire"), card("s3", "salameche", "fire"), card("s4", "salameche", "fire"), card("c1", "carapuce", "water")]
	var b2 := mk(mixed, ["scope_lens"], [enemy(900)], true)
	for id: String in ["s1", "s2", "s3", "s4"]:
		play(b2, id)
	ok(b2.get_elan() == 4, "elan 4 before switching")
	play(b2, "c1")
	ok(b2.get_elan() == 2, "scope_lens: half of the Élan kept on switch (%d)" % b2.get_elan())
	var b3 := mk(mixed, [], [enemy(900)], true)
	for id: String in ["s1", "s2", "s3", "s4", "c1"]:
		play(b3, id)
	ok(b3.get_elan() == 0, "no item: switch loses all Élan")


func _talent() -> void:
	var cards: Array = [card("c1", "carapuce", "water"), card("s1", "salameche", "fire"), card("c2", "carapuce", "water"), card("s2", "salameche", "fire")]
	talent_events = 0
	var b := mk(cards, [], [enemy(900)], true)
	for id: String in ["c1", "s1", "c2"]:
		play(b, id)
	ok(talent_events == 2, "no item: talents fire once each (%d)" % talent_events)
	talent_events = 0
	var b2 := mk(cards, ["herbe_mental"], [enemy(900)], true)
	ok(b2.would_trigger_talent(b2.hand[idx(b2, "s1")]) == false or true, "preview does not crash")
	for id: String in ["c1", "s1", "c2", "s2"]:
		play(b2, id)
	ok(talent_events == 3, "herbe_mental: exactly one extra trigger (%d)" % talent_events)


func _statuses() -> void:
	var psn := card("p", "", "normal", "attack", 0, false, {"status": "poison", "status_value": 2})
	var b := mk([psn], ["orbe_toxik"])
	play(b, "p")
	ok(int((b.enemies[0].statuses["poison"] as Dictionary)["value"]) == 4, "orbe_toxik: poison 2 -> 4")
	var b2 := mk([psn], [])
	play(b2, "p")
	ok(int((b2.enemies[0].statuses["poison"] as Dictionary)["value"]) == 2, "no item: poison 2")
	var brn := card("b", "", "normal", "attack", 0, false, {"status": "burn", "status_value": 2})
	var b3 := mk([brn], ["orbe_flamme"])
	play(b3, "b")
	ok(int((b3.enemies[0].statuses["burn"] as Dictionary)["value"]) == 3, "orbe_flamme: burn 2 -> 3")
	var b4 := mk([psn], ["orbe_flamme"])
	play(b4, "p")
	ok(int((b4.enemies[0].statuses["poison"] as Dictionary)["value"]) == 2, "burn item does not touch poison")


func _battle_start() -> void:
	var b := mk([card("a")], ["griffe_rasoir"])
	ok(b.get_strength() == 1 and play(b, "a") == DMG + 1, "griffe_rasoir: 1 Force from the start")
	var cards: Array = []
	for i: int in 10:
		cards.append(card("a%d" % i))
	var b2 := mk(cards, ["boule_fumee", "pile_rapide"])
	ok(b2.hand.size() == 7 and b2.energy == 4, "first turn: +2 cards, +1 energy (%d / %d)" % [b2.hand.size(), b2.energy])
	b2.end_turn()
	ok(b2.hand.size() == 5 and b2.energy == 3, "second turn: back to normal")
	var es: Array[Combatant] = [enemy(), enemy()]
	var b3 := mk([card("a")], ["poudre_eclat", "lentille_zoom"], es)
	ok(b3.enemies[0].has_status("weak") and b3.enemies[1].has_status("weak"), "poudre_eclat: weak on all enemies")
	ok(b3.enemies[0].has_status("vulnerable") and b3.enemies[1].has_status("vulnerable"), "lentille_zoom: vulnerable on all enemies")
	var b4 := mk([card("a")], [])
	ok(not b4.enemies[0].has_status("weak"), "no item: no status")


func _exhaust() -> void:
	var cards: Array = [card("x1", "", "normal", "attack", 0, true), card("x2", "", "normal", "attack", 0, true)]
	var b := mk(cards, ["cendre_sacree"])
	play(b, "x1")
	ok(b.exhaust_pile.is_empty() and b.discard_pile.size() == 1, "cendre_sacree: first exhausted card back to the discard pile")
	play(b, "x2")
	ok(b.exhaust_pile.size() == 1, "second exhausted card is exhausted for real")
	var b2 := mk(cards, [])
	play(b2, "x1")
	ok(b2.exhaust_pile.size() == 1, "no item: exhausted")
	var b3 := mk(cards, ["herbe_blanche"])
	var hp0: int = b3.player.hp
	play(b3, "x1")
	ok(b3.player.hp == hp0 + 2, "herbe_blanche: +2 HP on exhaust")
	var b4 := mk([card("n")], ["herbe_blanche"])
	var hp1: int = b4.player.hp
	play(b4, "n")
	ok(b4.player.hp == hp1, "herbe_blanche: nothing on a normal card")


func _block_keep() -> void:
	var blk := card("k", "", "normal", "skill", 0)
	var b := mk([blk], ["roche_lisse"], [enemy(HP, 2)])
	play(b, "k")
	b.end_turn()  # block 10 - 2 = 8 left, half kept
	ok(b.player.block == 4, "roche_lisse: half of the 8 remaining block kept (%d)" % b.player.block)
	var b2 := mk([blk], [], [enemy(HP, 2)])
	play(b2, "k")
	b2.end_turn()
	ok(b2.player.block == 0, "no item: block gone")


func _kill() -> void:
	var es: Array[Combatant] = [enemy(5), enemy()]
	var b := mk([card("a")], ["bonbon_rare", "casque_brut"], es)
	var hp0: int = b.player.hp
	play(b, "a", 0)
	ok(b.player.hp == hp0 + 3 and b.player.block == 4, "on_kill: heal 3 and 4 block (%d / %d)" % [b.player.hp - hp0, b.player.block])
	var es2: Array[Combatant] = [enemy(500), enemy()]
	var b2 := mk([card("a")], ["bonbon_rare"], es2)
	var hp1: int = b2.player.hp
	play(b2, "a", 0)
	ok(b2.player.hp == hp1, "on_kill: nothing without a kill")


func _capture_and_run() -> void:
	var e1 := enemy()
	e1.capturable = true
	var e2 := enemy()
	e2.capturable = true
	var b := mk([card("a")], ["miel"], [e1], false, true)
	var b0 := mk([card("a")], [], [e2], false, true)
	var c1: float = b.capture_chance(0, 0)
	var c0: float = b0.capture_chance(0, 0)
	ok(c0 > 0.0 and absf((c1 - c0) - 0.10) < 0.0001 or c1 == 1.0, "miel: +10 points of capture chance (%f vs %f)" % [c1, c0])
	var run := RunState.create_with_starter(gd, "salameche")
	var potions: int = run.max_potions()
	var balls: int = run.ball_total()
	ok(run.add_item(gd.get_item("sacoche_potions")) and run.max_potions() == potions + 1, "sacoche_potions: +1 potion slot")
	ok(run.add_item(gd.get_item("sacoche_balls")) and run.ball_total() == mini(balls + 3, run.max_balls()) and run.ball_total() > balls, "sacoche_balls: balls received on pickup")
	var money_run := RunState.create_with_starter(gd, "salameche")
	money_run.add_item(gd.get_item("pepite"))
	ok(ItemEffects.win_money_bonus(money_run.items) == 6, "pepite: money on win")
	var b2 := mk([card("a")], ["baie_sitrus"], [enemy(1)])
	var hp0: int = b2.player.hp
	play(b2, "a")
	ok(b2.state == Battle.State.WON and b2.player.hp > hp0, "baie_sitrus heals after the win")


func _validation() -> void:
	print("--- errors expected below (invalid items rejected) ---")
	var base: Dictionary = {"name": "X", "description": "d", "rarity": "common", "trigger": "passive", "effects": [{"type": "draw_up", "value": 1}]}
	ok(ItemData.from_dict("x", base) != null, "valid base item")
	var bad: Array[Dictionary] = [
		{"trigger": "battle_start", "effects": [{"type": "elan_cap_up", "value": 1}]},  # wrong trigger for the effect
		{"effects": [{"type": "damage_bonus_type", "value": 2}], "trigger": "card_played"},  # no card_type
		{"effects": [{"type": "first_type_card_free"}]},  # no card_type
		{"effects": [{"type": "status_bonus", "value": 1}]},  # no status
		{"effects": [{"type": "status_bonus", "status": "burn", "value": 0}]},  # value 0
		{"effects": [{"type": "elan_keep_percent", "percent": 0}]},
		{"effects": [{"type": "block_keep", "percent": 150}]},
		{"trigger": "on_pickup", "effects": [{"type": "add_ball", "value": 2}]},  # no ball
		{"trigger": "battle_start", "effects": [{"type": "apply_all_enemies", "value": 1}]},  # no status
		{"trigger": "on_kill", "effects": [{"type": "damage_bonus", "value": 1}]},
		{"weight": -1},
		{"effects": []},
		{"trigger": "nope"},
	]
	for patch: Dictionary in bad:
		var d: Dictionary = base.duplicate(true)
		d.merge(patch, true)
		ok(ItemData.from_dict("bad", d) == null, "rejected: " + JSON.stringify(patch))
	ok(not gd._check_item_type_refs(ItemData.from_dict("t", {"name": "T", "description": "d", "rarity": "common", "trigger": "card_played",
			"effects": [{"type": "damage_bonus_type", "card_type": "nonexistent", "value": 1}]})), "unknown card_type refused by GameData")
	# whole file with a bad item: the load is refused, nothing crashes
	var root: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(P + "items.json"))
	(root["items"] as Dictionary)["charbon"]["effects"][0]["card_type"] = "nonexistent"
	var f := FileAccess.open("user://t29_items.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(root))
	f.close()
	var paths: Array = [P + "cards.json", P + "pokemon.json", P + "types.json", P + "rewards.json", P + "act1.json", P + "events.json",
			"user://t29_items.json", P + "potions.json", P + "shop.json", P + "zones.json", P + "league.json", P + "roster.json",
			P + "statuses.json", P + "balls.json", P + "rival.json", P + "talents.json"]
	ok(not GameData.new().callv("load_all", paths), "items file with an unknown card_type: load refused")
	print("--- end of expected errors ---")


func _acquisition() -> void:
	var run := RunState.create_with_starter(gd, "salameche")
	var seen: Dictionary = {}
	for k: int in gd.get_item_ids().size():
		var loot: Dictionary = LootGenerator.generate(gd, run, "elite", rng(k))
		var got: Dictionary = run.apply_loot(loot)
		ok(got["item"] != null and not seen.has((got["item"] as ItemData).id), "elite loot %d is a new item" % k)
		seen[(got["item"] as ItemData).id] = true
	ok(not run.add_item(gd.get_item("restes")), "duplicate item refused")
	ok(LootGenerator.generate(gd, run, "elite", rng(1))["item_id"] == "", "nothing left to find")
	var fresh := RunState.create_with_starter(gd, "salameche")
	var r := rng(7)
	var berries: int = 0
	var total: int = 3000
	for i: int in total:
		var it: ItemData = LootGenerator.pick_items(gd, fresh, 1, r)[0]
		if it.id.begins_with("baie_"):
			berries += 1
	var uniform: float = 6.0 / float(gd.get_item_ids().size())
	ok(float(berries) / total < uniform * 0.85, "berries are drawn less than a uniform pick (%.3f vs %.3f)" % [float(berries) / total, uniform])
	var shop := ShopInventory.generate(gd, fresh, rng(3))
	ok(shop != null and shop.items.size() >= 2, "mart stocks items")
