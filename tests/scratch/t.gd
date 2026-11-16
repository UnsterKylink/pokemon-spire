extends SceneTree
var fails := 0
func ok(c: bool, m: String) -> void:
	print(("PASS " if c else "FAIL ") + m)
	if not c: fails += 1
func mk(seed_v: int, enemy_id := "rattata") -> Battle:
	var d := GameData.new()
	ok(d.load_all(), "data loads") if false else d.load_all()
	var r := RandomNumberGenerator.new(); r.seed = seed_v
	var b := Battle.new(d.create_player("salameche"), d.create_enemy(enemy_id), d.get_starter_deck("salameche"), d.get_energy_per_turn("salameche"), d.get_hand_size("salameche"), r)
	b.start()
	return b
func _init() -> void:
	var b := mk(42)
	ok(b.energy == 3, "3 energy at start")
	ok(b.hand.size() == 5, "hand 5")
	ok(b.draw_pile.size() + b.hand.size() == 10, "deck 10")
	ok(b.player.max_hp == 75, "hp 75")
	# block absorbs then HP
	var c := Combatant.new(); c.hp = 20; c.max_hp = 20
	c.add_block(5); c.take_damage(8)
	ok(c.block == 0 and c.hp == 17, "block absorbs then hp")
	# block reset next turn
	b.player.add_block(9)
	b.end_turn()
	ok(b.player.block == 0, "block reset next turn")
	ok(b.player.hp == 75, "9 block absorbed enemy 7 (test fix)")
	ok(b.energy == 3 and b.hand.size() == 5, "new turn energy/hand")
	# reshuffle after 3 turns
	b.end_turn(); b.end_turn()
	ok(b.hand.size() == 5, "hand 5 after reshuffle")
	ok(b.draw_pile.size() + b.hand.size() + b.discard_pile.size() == 10, "no card lost")
	# unaffordable
	b.energy = 0
	var idx := -1
	for i in b.hand.size():
		if b.hand[i].cost > 0: idx = i
	ok(not b.play_card(idx, b.enemy) and b.hand.size() == 5, "unaffordable rejected")
	b.energy = 3
	# attack with invalid target
	var ai := -1
	for i in b.hand.size():
		if b.hand[i].kind == "attack": ai = i
	if ai >= 0: ok(not b.play_card(ai, null), "null target rejected")
	# win
	var w := mk(1)
	w.enemy.hp = 5
	var won := [false]
	w.battle_won.connect(func(): won[0] = true)
	var gi := -1
	for i in w.hand.size():
		if w.hand[i].kind == "attack": gi = i
	if gi < 0: w.hand.append(w.draw_pile[0]); gi = 5; w.hand[gi] = w.draw_pile.filter(func(x): return x.kind=="attack")[0]
	ok(w.play_card(gi, w.enemy) and won[0] and w.state == Battle.State.WON, "win path")
	ok(not w.end_turn(), "no end_turn after win")
	# lose
	var l := mk(2)
	l.player.hp = 7
	var lost := [false]
	l.battle_lost.connect(func(): lost[0] = true)
	l.end_turn()
	ok(lost[0] and l.state == Battle.State.LOST and l.player.hp == 0, "lose path")
	# damage card: enemy hp decreases
	var e := mk(3)
	var ei := -1
	for i in e.hand.size():
		if e.hand[i].id == "griffe": ei = i
	if ei >= 0:
		e.play_card(ei, e.enemy)
		ok(e.enemy.hp == 24 and e.energy == 2, "griffe 6 dmg cost 1")
	print("FAILS=", fails)
	quit(1 if fails > 0 else 0)
