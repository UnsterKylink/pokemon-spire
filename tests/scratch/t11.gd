extends SceneTree
var fails: int = 0
var passes: int = 0
const SCR := "user://"
var gd: GameData

func ok(c: bool, msg: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		print("FAIL ", msg)

func rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new(); r.seed = s; return r

func mk(hp: int = 500, atk: int = 5) -> Combatant:
	return Combatant.from_dict("e", {"name": "E", "types": ["normal"], "max_hp": hp, "sprite": "s", "pattern": "sequence", "actions": [{"type": "attack", "value": atk}]})

func newrun() -> RunState:
	return RunState.create_with_starter(gd, "salameche")

func battle(run: RunState, deck_ids: Array, es: Array[Combatant], energy: int = 10) -> Battle:
	var d: Array[CardData] = []
	for c: String in deck_ids:
		d.append(gd.get_card(c))
	run.deck = d
	run.energy_per_turn = energy
	run.hand_size = deck_ids.size()
	var b := run.create_battle(es, gd.get_type_chart(), rng(3))
	b._talent_book = null  # story 027: these item tests measure plain damage; talents / Élan are covered by t27
	b.start()
	return b

func idx(b: Battle, cid: String) -> int:
	for i: int in b.hand.size():
		if b.hand[i].id == cid: return i
	return -1

func wr(name: String, d: Dictionary) -> String:
	var f := FileAccess.open(SCR + name, FileAccess.WRITE); f.store_string(JSON.stringify(d)); f.close(); return SCR + name

func _initialize() -> void:
	gd = GameData.new()
	ok(gd.load_all(), "real data loads")
	ok(gd.get_item_ids().size() >= 10, "10 items")
	ok(gd.get_potion_ids().size() >= 5 and gd.get_max_potions() == 3, "5 potions max 3")
	var run := newrun()
	ok(run.money == 50, "start money 50")
	ok(run.items.is_empty() and run.potions.is_empty(), "empty start")

	# --- money
	ok(run.spend_money(20) and run.money == 30, "spend")
	ok(not run.spend_money(31) and run.money == 30, "cannot overspend")
	run.add_money(-5); ok(run.money == 30, "neg add ignored")

	# --- items: pickup max hp
	var before_max := run.max_hp
	run.hp = 50
	ok(run.add_item(gd.get_item("baie_oran")), "add baie")
	ok(run.max_hp == before_max + 8 and run.hp == 58, "max hp up raises both")
	ok(not run.add_item(gd.get_item("baie_oran")), "no duplicate")
	ok(run.items.size() == 1, "one item")

	# --- battle triggers
	run = newrun(); run.hp = 40
	run.add_item(gd.get_item("restes")); run.add_item(gd.get_item("peau_metal")); run.add_item(gd.get_item("bandeau"))
	var e := mk(20)
	var es: Array[Combatant] = [e]
	var b := battle(run, ["griffe", "griffe", "abri"], es)
	ok(b.player.block == 4, "peau metal block at battle start kept through first turn: %d" % b.player.block)
	var i := idx(b, "griffe")
	ok(b.play_card(i, 0), "play griffe")
	ok(e.hp == 20 - (6 + 3), "bandeau first attack +3: hp %d" % e.hp)
	i = idx(b, "griffe")
	ok(b.play_card(i, 0) and e.hp == 20 - 9 - 6, "second attack no bonus: hp %d" % e.hp)
	ok(run.hp == 40, "hp unchanged before end")
	# win: heal 6 at battle end
	var e2 := mk(5); var es2: Array[Combatant] = [e2]
	run = newrun(); run.hp = 40; run.add_item(gd.get_item("restes"))
	b = battle(run, ["griffe"], es2)
	b.play_card(0, 0)
	ok(b.state == Battle.State.WON and b.player.hp == 46, "restes +6 on win: %d" % b.player.hp)
	run.record_battle_result(b.player)
	ok(run.hp == 46 and run.battles_won == 1, "persisted")
	# no heal on loss
	run = newrun(); run.hp = 3; run.add_item(gd.get_item("restes"))
	var es3: Array[Combatant] = [mk(500, 50)]
	b = battle(run, ["abri"], es3)
	b.end_turn()
	ok(b.state == Battle.State.LOST and b.player.hp == 0, "lost no restes")
	# turn_start / turn_end / lunettes / passive
	run = newrun(); run.hp = 40
	for id in ["ceinture_force", "poudre_soin", "lunettes_choix", "cloche_eclat", "gemme_energie"]:
		ok(run.add_item(gd.get_item(id)), "add " + id)
	ok(run.effective_energy_per_turn() == 4 and run.effective_hand_size() == 6, "passives %d %d" % [run.effective_energy_per_turn(), run.effective_hand_size()])
	var e3 := mk(500, 5); var es4: Array[Combatant] = [e3]
	b = battle(run, ["griffe", "griffe", "griffe", "griffe", "griffe", "griffe", "griffe"], es4, 3)
	ok(b.max_energy == 4 and b.hand.size() == 7 - 0 or b.hand.size() == 7, "hand with draw_up (deck 7, hand_size 7+1)")
	ok(b.player.block == 2, "ceinture turn start block 2: %d" % b.player.block)
	b.play_card(0, 0)
	ok(e3.hp == 500 - 7, "lunettes +1: %d" % e3.hp)
	var hp0 := b.player.hp
	b.end_turn()
	# poudre +1 at turn end, then enemy 5 attack vs block 2 -> 3 dmg
	ok(b.player.hp == hp0 + 1 - 3, "poudre then enemy: %d vs %d" % [b.player.hp, hp0])
	# --- potions
	run = newrun(); run.hp = 30
	ok(run.add_potion(gd.get_potion("potion")) and run.add_potion(gd.get_potion("attaque_plus")) and run.add_potion(gd.get_potion("energie_plus")), "3 potions")
	ok(not run.add_potion(gd.get_potion("pioche")) and run.potions.size() == 3, "full belt")
	var e4 := mk(500, 5); var es5: Array[Combatant] = [e4]
	b = battle(run, ["griffe", "griffe", "abri", "abri"], es5, 3)
	ok(b.potions.size() == 3, "battle has potions")
	ok(b.use_potion(0) and b.player.hp == 50, "heal 20: %d" % b.player.hp)
	ok(run.potions.size() == 2 and run.potions[0].id == "attaque_plus", "run synced")
	ok(b.use_potion(0) and b.turn_damage_bonus == 5, "attaque+")
	b.play_card(idx(b, "griffe"), 0)
	ok(e4.hp == 500 - 11, "attack bonus 5: %d" % e4.hp)
	var en := b.energy
	ok(b.use_potion(0) and b.energy == en + 2, "energy+2")
	ok(not b.use_potion(0) and not b.use_potion(-1), "no more potions")
	b.end_turn(); ok(b.turn_damage_bonus == 0, "bonus reset")
	b.potions.clear()
	# heal clamp
	run = newrun(); run.add_potion(gd.get_potion("super_potion")); run.hp = run.max_hp - 5
	var es6: Array[Combatant] = [mk()]
	b = battle(run, ["abri"], es6)
	b.use_potion(0); ok(b.player.hp == run.max_hp, "heal clamps")
	run = newrun(); run.add_potion(gd.get_potion("defense_plus")); run.add_potion(gd.get_potion("pioche"))
	var es7: Array[Combatant] = [mk()]
	b = battle(run, ["abri", "abri", "abri", "abri", "abri", "abri", "abri", "abri"], es7)
	run.hand_size = 2
	b = run.create_battle(es7, gd.get_type_chart(), rng(1)); b.start()
	var h := b.hand.size()
	b.use_potion(1); ok(b.hand.size() == h + 3, "pioche +3 (%d->%d)" % [h, b.hand.size()])
	b.use_potion(0); ok(b.player.block == 12, "defense+")

	# --- loot determinism + content
	run = newrun()
	var l1 := LootGenerator.generate(gd, run, "wild", rng(5))
	var l2 := LootGenerator.generate(gd, run, "wild", rng(5))
	ok(l1 == l2, "loot deterministic")
	var seen_potion := 0
	for s in 400:
		var l := LootGenerator.generate(gd, run, "wild", rng(s))
		ok(l["money"] >= 10 and l["money"] <= 20 and l["item_id"] == "", "wild money range")
		if l["potion_id"] != "": seen_potion += 1
		var le := LootGenerator.generate(gd, run, "elite", rng(s))
		ok(le["money"] >= 25 and le["money"] <= 35 and le["item_id"] != "" and le["potion_id"] == "", "elite loot")
	ok(seen_potion > 100 and seen_potion < 220, "potion ~40%%: %d/400" % seen_potion)
	ok(LootGenerator.generate(gd, run, "boss", rng(1))["money"] >= 60, "gym pays loot (story 012)")
	ok(LootGenerator.generate(gd, run, "", rng(1))["money"] == 0, "debug 0")
	run.add_item(gd.get_item("piece_rune"))
	var lb := LootGenerator.generate(gd, run, "wild", rng(5))
	ok(lb["money"] == l1["money"] + 10, "piece rune +10")
	# elite never duplicates; exhausts
	var r2 := newrun()
	var n_items: int = gd.get_item_ids().size()  # story 016: 11 -> 15 items (status berries)
	for k in n_items:
		var le := LootGenerator.generate(gd, r2, "elite", rng(k))
		var got := r2.apply_loot(le)
		ok(got["item"] != null, "elite gives item %d" % k)
	ok(r2.items.size() == n_items, "all owned, no dup")
	ok(LootGenerator.generate(gd, r2, "elite", rng(1))["item_id"] == "", "none left -> none")
	# apply with full belt
	var r3 := newrun()
	for k in 3: r3.add_potion(gd.get_potion("potion"))
	var ap := r3.apply_loot({"money": 12, "item_id": "", "potion_id": "pioche"})
	ok(ap["potion"] == null and r3.potions.size() == 3 and r3.money == 62, "full belt loot")
	ok(LootGenerator.generate(gd, r3, "wild", rng(0))["potion_id"] == "" , "no potion rolled when full")

	# --- centre
	run = newrun(); run.hp = 10
	var mx := run.max_hp
	ok(run.rest_heal() == ceili(mx * 0.5) and run.hp == 10 + ceili(mx * 0.5), "rest heal 50%")
	run.hp = mx - 1; ok(run.rest_heal() == 1, "heal clamps")
	var n := run.deck.size()
	var gi := -1; var ai := -1
	for k in run.deck.size():
		if run.deck[k].id == "flammette" and gi < 0: gi = k
		if run.deck[k].id == "abri" and ai < 0: ai = k
	var keys0 := run.deck_counts()
	ok(run.upgrade_card(gi), "upgrade griffe")
	ok(run.deck[gi].upgraded and run.deck[gi].damage == 9 and run.deck[gi].display_name == "Flammette+" and run.deck[gi].description == "Inflige 9 dégâts.", "griffe+ stats: %s %s" % [run.deck[gi].display_name, run.deck[gi].description])
	ok(run.deck[gi].pokemon_id == "salameche" and run.deck[gi].type_id == "fire" and run.deck[gi].cost == 1, "kept fields")
	ok(not run.upgrade_card(gi), "once only")
	var dc := run.deck_counts()
	ok(dc.get("flammette@salameche+", 0) == 1 and dc.get("flammette@salameche", 0) == int(keys0["flammette@salameche"]) - 1, "deck keys separate: %s" % str(dc))
	ok(run.deck.size() == n, "size same")
	ok(run.upgrade_card(ai) and run.deck[ai].block == 8 and run.deck[ai].description == "Gagne 8 points de protection.", "abri+")
	var ents := run.get_deck_entries()
	var tot := 0
	for en2 in ents: tot += int(en2["count"])
	ok(tot == n, "entries sum")
	ok(not run.upgrade_card(99) and not run.upgrade_card(-1) and run.preview_upgrade(99) == null, "bad index")
	# upgraded card works in battle
	var es8: Array[Combatant] = [mk()]
	var d: Array[CardData] = [run.deck[gi]]
	run.deck = d; run.hand_size = 1
	b = run.create_battle(es8, gd.get_type_chart(), rng(1)); b._talent_book = null; b.start()  # story 027: these item tests measure plain damage; talents / Élan are covered by t27
	b.play_card(0, 0); ok(es8[0].hp == 500 - 9, "upgraded dmg in battle")
	# per-card override + rewards path
	var rc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/cards.json"))
	var cdef: Dictionary = (rc["cards"] as Dictionary)["mimi_queue"]
	cdef["upgrade"] = {"cost": -1, "block": 2}
	var cp := wr("t11_c.json", rc)
	var g2 := GameData.new()
	ok(g2.load_all(cp), "override loads")
	var up := g2.get_card("mimi_queue").upgraded_copy(g2.get_upgrade_rules())
	ok(up != null and up.cost == 0 and up.block == 9, "override applied")
	ok(g2.get_card("mimi_queue").upgraded_copy({}) != null, "override independent of rules")
	cdef["upgrade"] = {"bogus": 1}
	ok(not GameData.new().load_all(wr("t11_c2.json", rc)), "bad override rejected (error expected above)")

	# --- shop
	run = newrun(); run.money = 1000
	var shop := ShopInventory.generate(gd, run, rng(9))
	ok(shop.cards.size() == 5 and shop.items.size() >= 2 and shop.items.size() <= 3 and shop.potions.size() == 2, "shop sizes %d %d %d" % [shop.cards.size(), shop.items.size(), shop.potions.size()])
	var shop_b := ShopInventory.generate(gd, run, rng(9))
	var same := true
	for k in shop.cards.size(): same = same and shop.cards[k].card.deck_key() == shop_b.cards[k].card.deck_key() and shop.cards[k].price == shop_b.cards[k].price
	for k in shop.items.size(): same = same and shop.items[k].item.id == shop_b.items[k].item.id
	for k in shop.potions.size(): same = same and shop.potions[k].potion.id == shop_b.potions[k].potion.id
	ok(same, "shop deterministic")
	var cids := {}
	for se in shop.cards:
		cids[se.card.id] = true
		ok(se.price > 0 and se.card.rarity != "starter", "card price")
		if se.card.kind == "attack":
			ok(gd.get_pokemon_info(se.card.pokemon_id)["types"].has(se.card.type_id), "carrier type-coherent")
	ok(cids.size() == 5, "distinct cards")
	var m0 := run.money; var dsz := run.deck.size()
	ok(shop.buy_card(0) and run.deck.size() == dsz + 1 and run.money == m0 - shop.cards[0].price and shop.cards[0].sold, "buy card")
	ok(not shop.buy_card(0), "sold out")
	ok(shop.buy_item(0) and run.has_item(shop.items[0].item.id), "buy item")
	ok(not shop.buy_item(0), "item sold")
	ok(shop.buy_potion(0) and run.potions.size() == 1, "buy potion")
	ok(shop.buy_potion(1) and run.potions.size() == 2, "buy potion 2")
	ok(not shop.buy_card(-1) and not shop.buy_card(99) and not shop.buy_item(99) and not shop.buy_potion(99), "bad index")
	# poor
	run.money = 0
	var shop_p := ShopInventory.generate(gd, run, rng(2))
	ok(not shop_p.buy_card(0) and not shop_p.buy_item(0) and not shop_p.buy_potion(0) and run.money == 0, "no money no buy")
	# full belt
	run.money = 1000
	for k in 3 - run.potions.size(): run.add_potion(gd.get_potion("potion"))
	ok(not shop_p.buy_potion(0) and run.money == 1000, "full belt no buy")
	# item already owned via other means
	var shop_o := ShopInventory.generate(gd, run, rng(3))
	run.add_item(shop_o.items[0].item)
	ok(not shop_o.buy_item(0) and run.money == 1000, "owned item cannot be bought")
	# owned items not stocked
	var shop_q := ShopInventory.generate(gd, run, rng(4))
	for se in shop_q.items: ok(not run.items.has(se.item), "owned not offered")
	# removal
	run.money = 1000
	ok(shop.removal_price() == 75, "removal 75")
	var dsz2 := run.deck.size()
	ok(shop.remove_card(0) and run.deck.size() == dsz2 - 1 and run.money == 925 and shop.removal_price() == 100, "remove 1")
	ok(shop.remove_card(0) and run.money == 825 and shop.removal_price() == 125, "remove 2 rising")
	ok(not shop.remove_card(999) and not shop.remove_card(-1), "bad deck idx")
	run.money = 10
	ok(not shop.remove_card(0) and run.deck.size() == dsz2 - 2, "poor cannot remove")
	run.money = 100000
	while run.deck.size() > 1: shop.remove_card(0)
	ok(run.deck.size() == 1 and not shop.remove_card(0) and run.deck.size() == 1, "keeps 1 card")

	# --- invalid data does not crash
	var it: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/items.json"))
	var items: Dictionary = it["items"]
	items["x1"] = {"name": "X", "description": "d", "rarity": "common", "trigger": "bogus", "effects": [{"type": "heal_flat", "value": 1}]}
	ok(not GameData.new().load_all("res://assets/data/cards.json", "res://assets/data/pokemon.json", "res://assets/data/types.json", "res://assets/data/rewards.json", "res://assets/data/act1.json", "res://assets/data/events.json", wr("t11_i1.json", it)), "bad trigger rejected")
	items["x1"] = {"name": "X", "description": "d", "rarity": "common", "trigger": "battle_end", "effects": [{"type": "draw_up", "value": 1}]}
	ok(not GameData.new().load_all("res://assets/data/cards.json", "res://assets/data/pokemon.json", "res://assets/data/types.json", "res://assets/data/rewards.json", "res://assets/data/act1.json", "res://assets/data/events.json", wr("t11_i2.json", it)), "effect not allowed for trigger")
	items["x1"] = {"name": "X", "description": "d", "rarity": "rare", "trigger": "passive", "effects": [{"type": "energy_up_per_turn", "value": 1}]}
	ok(not GameData.new().load_all("res://assets/data/cards.json", "res://assets/data/pokemon.json", "res://assets/data/types.json", "res://assets/data/rewards.json", "res://assets/data/act1.json", "res://assets/data/events.json", wr("t11_i3.json", it)), "2 energy items rejected")
	var sh: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/shop.json"))
	(sh["shop"] as Dictionary)["card_prices"].erase("rare")
	var base := ["res://assets/data/cards.json", "res://assets/data/pokemon.json", "res://assets/data/types.json", "res://assets/data/rewards.json", "res://assets/data/act1.json", "res://assets/data/events.json", "res://assets/data/items.json", "res://assets/data/potions.json"]
	ok(not GameData.new().load_all(base[0], base[1], base[2], base[3], base[4], base[5], base[6], base[7], wr("t11_s1.json", sh)), "missing price rejected")
	ok(not GameData.new().load_all(base[0], base[1], base[2], base[3], base[4], base[5], SCR + "nope.json"), "missing file -> false")
	print("T11 pass=%d fail=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
