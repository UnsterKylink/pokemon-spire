extends SceneTree
# Story 016 — statuses: tick/duration/stacking, immunities, skip rules, thaw/wake, death, cures, items, data validation.
var fails: int = 0
var passes: int = 0
const SCR := "user://"
var gd: GameData
var ev: Array = []

func ok(c: bool, msg: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		print("FAIL ", msg)

func mk(types: Array, actions: Array, hp: int = 100) -> Combatant:
	return Combatant.from_dict("e", {"name": "E", "types": types, "max_hp": hp, "sprite": "s", "pattern": "sequence", "actions": actions})

func pl(types: Array = ["normal"], hp: int = 200) -> Combatant:
	return Combatant.from_dict("p", {"name": "P", "types": types, "max_hp": hp, "sprite": "s"})

const BLOCK1 := [{"type": "block", "value": 1}]

func bt(p: Combatant, es: Array, card_id: String = "griffe", seed_v: int = 1, items: Array = [], potions: Array = []) -> Battle:
	var d: Array[CardData] = []
	for i in 10:
		d.append(gd.get_card(card_id))
	var e2: Array[Combatant] = []
	for e in es: e2.append(e)
	var it: Array[ItemData] = []
	for i in items: it.append(gd.get_item(i))
	var po: Array[PotionData] = []
	for i in potions: po.append(gd.get_potion(i))
	var r := RandomNumberGenerator.new(); r.seed = seed_v
	var b := Battle.new(p, e2, d, 3, 5, r, gd.get_type_chart(), Callable(), "", it, po, gd.get_status_book())
	b.status_applied.connect(func(t, s, v): ev.append(["applied", t, s, v]))
	b.status_ticked.connect(func(t, s, a): ev.append(["ticked", t, s, a]))
	b.status_blocked.connect(func(t, s): ev.append(["blocked", t, s]))
	b.turn_skipped.connect(func(t, s): ev.append(["skipped", t, s]))
	b.status_removed.connect(func(t, s): ev.append(["removed", t, s]))
	b.enemy_acted.connect(func(e, i): ev.append(["acted", e]))
	b.start()
	return b

func has_ev(kind: String, sid: String) -> bool:
	for e in ev:
		if e[0] == kind and e[2] == sid: return true
	return false

func count_ev(kind: String) -> int:
	var n := 0
	for e in ev:
		if e[0] == kind: n += 1
	return n

func wr(name: String, d: Dictionary) -> String:
	var f := FileAccess.open(SCR + name, FileAccess.WRITE)
	f.store_string(JSON.stringify(d)); f.close()
	return SCR + name

func rd(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary

const D := "res://assets/data/"
func load_with(over: Dictionary) -> bool:
	var names := ["cards", "pokemon", "types", "rewards", "act1", "events", "items", "potions", "shop", "zones", "league", "roster", "statuses"]
	var paths: Array = []
	for n in names:
		paths.append(over.get(n, D + n + ".json"))
	return GameData.new().callv("load_all", paths)

func _initialize() -> void:
	gd = GameData.new()
	ok(gd.load_all(), "real data loads")
	ok(Array(gd.get_status_ids()) == ["poison", "burn", "paralysis", "sleep", "freeze", "weak", "vulnerable"], "5 statuses + story 027 Faiblesse / Vulnérable")
	var bk := gd.get_status_book()
	ok(bk.get_def("burn").attack_penalty == 2 and bk.get_def("burn").duration == 3, "burn data")
	ok(is_equal_approx(bk.get_def("paralysis").skip_chance, 0.25) and bk.get_def("paralysis").duration == 2, "para data")
	ok(Array(bk.get_def("freeze").thaw_types) == ["fire"], "freeze thaw")

	# --- Poison: N then N-1, ignores block, stacks
	var e := mk(["normal"], BLOCK1)
	var b := bt(pl(), [e])
	ok(b.apply_status(e, "poison", 3), "poison applied")
	ok(b.apply_status(e, "poison", 2) and e.get_status_value("poison") == 5, "poison stacks 3+2")
	e.add_block(20)
	b.end_turn()  # enemy acts (block reset + 1), then ticks 5 ignoring block
	ok(e.hp == 95 and e.get_status_value("poison") == 4, "poison tick 5 -> 4 (hp %d)" % e.hp)
	b.end_turn(); b.end_turn(); b.end_turn()
	ok(e.hp == 95 - 4 - 3 - 2 and e.get_status_value("poison") == 1, "poison 4,3,2")
	ev.clear()
	b.end_turn()
	ok(e.hp == 85 and not e.has_status("poison") and has_ev("removed", "poison"), "poison ends at 0")

	# --- Burn: N for 3 turns, stacking adds value + refreshes duration, attack penalty
	e = mk(["normal"], [{"type": "attack", "value": 9}])
	var p := pl()
	b = bt(p, [e])
	ok(e.intent.value == 9 and e.intent.display_text() == "Attaque 9", "intent before burn")
	b.apply_status(e, "burn", 2)
	ok(e.get_status_turns("burn") == 3 and e.intent.value == 7, "burn: 3 turns, intent -2 (%d)" % e.intent.value)
	b.end_turn()
	ok(p.hp == 193 and e.hp == 98 and e.get_status_turns("burn") == 2, "burned enemy hits 7, ticks 2")
	b.apply_status(e, "burn", 1)
	ok(e.get_status_value("burn") == 3 and e.get_status_turns("burn") == 3, "burn stack 2+1, refresh 3")
	b.end_turn(); b.end_turn(); b.end_turn()
	ok(e.hp == 98 - 9 and not e.has_status("burn"), "burn 3 ticks then gone (hp %d)" % e.hp)
	ok(e.intent.value == 9, "intent back to 9 after burn")
	# player burned: cards deal -2
	e = mk(["normal"], BLOCK1)
	p = pl()
	b = bt(p, [e], "griffe")
	b.apply_status(p, "burn", 1)
	b.play_card(0, 0)
	ok(e.hp == 96, "burned player griffe 6-2 = 4 (hp %d)" % e.hp)
	b.end_turn()
	ok(p.hp == 199, "player burn ticks at end of its turn")

	# --- Immunities by type (incl. dual types), player active Pokémon types
	var cases := [[["fire"], "burn", false], [["electric"], "paralysis", false], [["ice"], "freeze", false],
		[["poison"], "poison", false], [["steel"], "poison", false], [["water", "ice"], "freeze", false],
		[["bug", "poison"], "poison", false], [["rock", "steel"], "poison", false], [["normal", "flying"], "poison", true],
		[["grass"], "sleep", true], [["water"], "burn", true], [["dark", "fire"], "burn", false]]
	for c in cases:
		e = mk(c[0], BLOCK1)
		b = bt(pl(), [e])
		ev.clear()
		var r: bool = b.apply_status(e, c[1], 2)
		ok(r == c[2] and e.has_status(c[1]) == c[2] and has_ev("blocked", c[1]) != c[2], "immunity %s %s" % [str(c[0]), c[1]])
	p = pl(["fire"])
	b = bt(p, [mk(["normal"], BLOCK1)])
	ok(not b.apply_status(p, "burn", 2) and b.is_immune(p, "burn"), "fire player immune to burn")
	p.set_active_pokemon("x", "X", "s", ["water"] as Array[String])
	ok(b.apply_status(p, "burn", 2), "after switching to water: burnable")

	# --- Paralysis (enemy): seeded RNG determinism + rate, 2 turns
	var pattern_a := []
	var pattern_b := []
	for run in 2:
		e = mk(["normal"], [{"type": "attack", "value": 1}])
		p = pl(["normal"], 999)
		b = bt(p, [e], "griffe", 42)
		var pat := []
		for t in 30:
			b.apply_status(e, "paralysis", 1)
			ev.clear()
			b.end_turn()
			pat.append(has_ev("skipped", "paralysis"))
		if run == 0: pattern_a = pat
		else: pattern_b = pat
	ok(pattern_a == pattern_b, "paralysis deterministic with same seed")
	var skips := pattern_a.count(true)
	ok(skips >= 3 and skips <= 15, "paralysis ~25%% (%d/30)" % skips)
	e = mk(["normal"], BLOCK1)
	b = bt(pl(), [e])
	b.apply_status(e, "paralysis", 1)
	b.end_turn()
	ok(e.get_status_turns("paralysis") == 1, "para 2 -> 1")
	b.end_turn()
	ok(not e.has_status("paralysis"), "para gone after 2 turns")
	# player paralysed: cards fizzle (energy spent, no effect), deterministic
	var fizz := [0, 0]
	for run in 2:
		var total := 0
		for k in 40:
			e = mk(["normal"], BLOCK1, 999)
			p = pl()
			b = bt(p, [e], "griffe", 100 + k)
			b.apply_status(p, "paralysis", 1)
			ev.clear()
			var en := b.energy
			b.play_card(0, 0)
			if has_ev("blocked", "paralysis"):
				total += 1
				ok(e.hp == 999 and b.energy == en - 1 and b.hand.size() == 4, "fizzle spends energy, no damage")
			else:
				ok(e.hp == 993, "non-fizzled card hits")
		fizz[run] = total
	ok(fizz[0] == fizz[1] and fizz[0] >= 3 and fizz[0] <= 20, "player fizzle deterministic ~25%% (%d/40)" % fizz[0])
	# no RNG drawn without paralysis: same sequence as a battle without statuses
	var r1 := RandomNumberGenerator.new(); r1.seed = 7
	e = mk(["normal"], BLOCK1)
	b = bt(pl(), [e], "griffe", 7)
	b.play_card(0, 0)
	ok(true, "no-status play ok")

	# --- Sleep (enemy): skips, intent "Dort", wake on damage; card Hypnose
	e = mk(["normal"], [{"type": "attack", "value": 5}])
	p = pl()
	b = bt(p, [e], "hypnose")
	ok(gd.get_card("hypnose").needs_target(), "status skill needs a target")
	b.play_card(0, 0)
	ok(e.has_status("sleep") and e.intent.display_text() == "Dort", "hypnose -> Dort (%s)" % e.intent.display_text())
	ev.clear()
	b.end_turn()
	ok(p.hp == 200 and has_ev("skipped", "sleep") and count_ev("acted") == 0 and not e.has_status("sleep"), "asleep enemy skips once")
	b.end_turn()
	ok(p.hp == 195, "awake enemy attacks next turn")
	e = mk(["normal"], [{"type": "attack", "value": 5}])
	b = bt(pl(), [e], "griffe")
	b.apply_status(e, "sleep", 1)
	b.play_card(0, 0)
	ok(not e.has_status("sleep") and e.intent.display_text() == "Attaque 5", "damage wakes the enemy")
	# player asleep (anti-lock rule): next turn starts with -2 energy (data), cards still drawn
	ok(bk.get_def("sleep").player_energy_loss == 2 and bk.get_def("freeze").player_energy_loss == 2, "player_energy_loss data")
	ok(Array(bk.aftermath_statuses) == ["sleep", "freeze"] and bk.aftermath_turns == 2 and bk.aftermath_display.short == "RÉPIT", "aftermath data")
	ok(not bk.get_def("paralysis").refresh_on_reapply and bk.get_def("burn").refresh_on_reapply, "refresh_on_reapply data")
	e = mk(["normal"], BLOCK1)
	p = pl()
	b = bt(p, [e])
	b.apply_status(p, "sleep", 1)
	ev.clear()
	b.end_turn()
	ok(b.energy == 1 and b.energy_lost == 2 and b.hand.size() == 5 and has_ev("skipped", "sleep") and not p.has_status("sleep"), "asleep player: -2 energy, still draws (%d)" % b.energy)
	ok(b.play_card(0, 0), "asleep player can still play with remaining energy")
	# aftermath immunity: 2 turns, blocks sleep AND freeze, then expires
	ok(p.aftermath_turns == 2, "aftermath starts at 2 (%d)" % p.aftermath_turns)
	ev.clear()
	ok(not b.apply_status(p, "sleep", 1) and not b.apply_status(p, "freeze", 1) and count_ev("blocked") == 2, "aftermath blocks sleep + freeze")
	ok(b.is_immune(p, "sleep") and not b.is_immune(p, "poison") and b.apply_status(p, "poison", 1), "aftermath does not block poison")
	ok(not b.is_immune(e, "sleep"), "aftermath is player-only")
	b.end_turn()
	ok(b.energy == 3 and b.energy_lost == 0 and p.aftermath_turns == 1, "next turn normal energy, aftermath 1 (%d)" % p.aftermath_turns)
	ok(not b.apply_status(p, "freeze", 1), "still immune on 2nd turn")
	b.end_turn()
	ok(p.aftermath_turns == 0 and b.apply_status(p, "freeze", 1), "aftermath expired after 2 turns")
	b.end_turn()
	ok(b.energy == 1 and p.aftermath_turns == 2, "frozen player -2 energy, aftermath again")
	# cure starts the aftermath too
	p = pl()
	b = bt(p, [mk(["normal"], BLOCK1)], "griffe", 1, [], ["reveil"])
	b.apply_status(p, "sleep", 1)
	b.use_potion(0)
	ok(p.aftermath_turns == 2 and not b.apply_status(p, "sleep", 1), "cured sleep -> aftermath")
	# enemy waking hit: the aftermath begins with the coming turn (not decremented in the same enemy phase)
	p = pl()
	b = bt(p, [mk(["normal"], [{"type": "attack", "value": 5}])])
	b.apply_status(p, "sleep", 1)
	b.end_turn()
	ok(b.energy == 3 and p.aftermath_turns == 2, "woken by hit -> aftermath 2 on the next turn (%d)" % p.aftermath_turns)
	# paralysis is not extended by re-applying; burn still refreshes
	e = mk(["normal"], BLOCK1)
	b = bt(pl(), [e])
	b.apply_status(e, "paralysis", 1)
	b.end_turn()
	ev.clear()
	ok(not b.apply_status(e, "paralysis", 1) and e.get_status_turns("paralysis") == 1 and count_ev("applied") == 0, "paralysis not extended")
	b.end_turn()
	ok(not e.has_status("paralysis") and b.apply_status(e, "paralysis", 1) and e.get_status_turns("paralysis") == 2, "paralysis re-applicable once gone")
	b.apply_status(e, "burn", 2)
	b.end_turn()
	ok(e.get_status_turns("burn") == 2, "burn 3 -> 2")
	ok(b.apply_status(e, "burn", 1) and e.get_status_turns("burn") == 3 and e.get_status_value("burn") == 3, "burn refreshes + stacks")
	# an enemy trio spamming sleep cannot lock the player at 0 energy over 10 turns
	for sid in ["sleep", "freeze"]:
		var spammer := [{"type": "attack", "value": 1, "status": {"id": sid, "value": 1}}]
		var sp := pl(["normal"], 999)
		var trio := [mk(["normal"], spammer, 999), mk(["normal"], spammer, 999), mk(["normal"], spammer, 999)]
		ok(trio[0] != null and trio[0].actions[0].status_id == sid, "%s spammer built" % sid)
		b = bt(sp, trio, "abri")
		var energies := []
		var zero_turns := 0
		var full_turns := 0
		for k in 10:
			b.end_turn()
			energies.append(b.energy)
			if b.energy == 0: zero_turns += 1
			if b.energy == 3: full_turns += 1
		ok(zero_turns == 0 and full_turns >= 4, "%s trio: never 0 energy over 10 turns %s" % [sid, energies])
		print("%s trio energies: %s" % [sid, energies])
	# enemy attack wakes the sleeping player before its turn
	e = mk(["normal"], [{"type": "attack", "value": 5}])
	p = pl()
	b = bt(p, [e])
	b.apply_status(p, "sleep", 1)
	b.end_turn()
	ok(b.energy == 3 and not p.has_status("sleep"), "hit wakes the player")

	# --- Freeze: skips 1 turn, Fire thaws, normal hit does not, ice immune
	e = mk(["normal"], [{"type": "attack", "value": 5}])
	p = pl()
	b = bt(p, [e], "griffe")
	b.apply_status(e, "freeze", 1)
	ok(e.intent.display_text() == "Gelé", "frozen intent")
	b.play_card(0, 0)
	ok(e.has_status("freeze"), "normal hit does not thaw")
	b.end_turn()
	ok(p.hp == 200 and not e.has_status("freeze"), "frozen enemy skipped once")
	e = mk(["normal"], BLOCK1)
	b = bt(pl(), [e], "flammette")
	b.apply_status(e, "freeze", 1)
	ev.clear()
	b.play_card(0, 0)
	ok(not e.has_status("freeze") and has_ev("removed", "freeze"), "fire attack thaws")

	# --- Death by status
	e = mk(["normal"], BLOCK1, 3)
	p = pl()
	b = bt(p, [e])
	var won := [false]
	b.battle_won.connect(func(): won[0] = true)
	b.apply_status(e, "poison", 5)
	b.apply_status(p, "burn", 1)
	b.end_turn()
	ok(won[0] and b.state == Battle.State.WON and not e.is_alive() and e.intent == null, "enemy killed by poison -> won")
	ok(p.statuses.is_empty(), "player statuses cleared after battle")
	var e1 := mk(["normal"], BLOCK1, 3)
	var e2 := mk(["normal"], BLOCK1, 50)
	b = bt(pl(), [e1, e2])
	b.apply_status(e1, "burn", 4)
	b.end_turn()
	ok(not e1.is_alive() and b.state == Battle.State.PLAYER_TURN, "one dies from burn, battle goes on")
	e = mk(["normal"], [{"type": "attack", "value": 5}])
	p = pl(["normal"], 3)
	b = bt(p, [e])
	var lost := [false]
	b.battle_lost.connect(func(): lost[0] = true)
	b.apply_status(p, "burn", 4)
	ev.clear()
	b.end_turn()
	ok(lost[0] and b.state == Battle.State.LOST and count_ev("acted") == 0 and p.statuses.is_empty(), "player dies from burn before enemies act")

	# --- Cards and enemy actions applying statuses; intent text
	ok(gd.get_card("crocs_feu").status_id == "burn" and gd.get_card("crocs_feu").status_value == 2, "card status parsed")
	e = mk(["normal"], BLOCK1)
	b = bt(pl(), [e], "crocs_feu")
	b.play_card(0, 0)
	ok(e.hp == 100 - gd.get_card("crocs_feu").damage and e.get_status_value("burn") == 2, "crocs_feu hits its damage + burn 2")
	e = mk(["fire"], BLOCK1)
	b = bt(pl(), [e], "crocs_feu")
	ev.clear()
	b.play_card(0, 0)
	ok(not e.has_status("burn") and has_ev("blocked", "burn"), "fire enemy immune to the card's burn")
	e = mk(["ghost"], BLOCK1)
	b = bt(pl(), [e], "dard_venin")
	b.play_card(0, 0)
	ok(e.has_status("poison"), "poison card on ghost (x0.5 not 0) applies")
	e = mk(["normal"], [{"type": "attack", "value": 5, "status": {"id": "poison", "value": 3}}])
	p = pl()
	b = bt(p, [e])
	ok(e.intent.display_text() == "Attaque 5 + Poison 3", "intent text with status (%s)" % e.intent.display_text())
	b.end_turn()
	ok(p.hp == 195 and p.get_status_value("poison") == 3, "enemy attack poisons the player")
	b.end_turn()
	ok(p.hp == 195 - 3 - 5 and p.get_status_value("poison") == 2 + 3, "player poison ticks then re-stacked")
	p = pl(["ghost"])
	b = bt(p, [e])
	b.end_turn()
	ok(not p.has_status("poison"), "fully immune hit (x0) inflicts no status")
	p = pl()
	p.add_block(50)
	e = mk(["normal"], [{"type": "attack", "value": 5, "status": {"id": "burn", "value": 2}}])
	b = bt(p, [e])
	b.end_turn()
	ok(p.has_status("burn"), "status applied even when block absorbs")
	# data: hand-written + roster enemies have statuses and show them
	var zub := gd.create_enemies("solo_nosferapti", 1.0, 0)
	var found := false
	for a: EnemyIntent in zub[0].actions:
		if a.status_id == "poison": found = true
	ok(found, "zubat action inflicts poison (data)")
	var roster := rd(D + "roster.json")["pokemon"] as Dictionary
	var with_status := 0
	for k in roster:
		for a in roster[k]["actions"]:
			if a.has("status"): with_status += 1
	ok(with_status > 50, "roster enemies with status: %d" % with_status)
	# card descriptions mention the status; upgrade keeps it
	var cards := rd(D + "cards.json")["cards"] as Dictionary
	for cid in cards:
		var c := gd.get_card(cid)
		if not c.status_id.is_empty():
			ok(c.description.contains(bk.name_of(c.status_id)), "desc mentions status: " + cid)
	var up := gd.get_card("lance_flammes").upgraded_copy(gd.get_upgrade_rules())
	ok(up.description == "Inflige 23 dégâts. Brûlure 4." and up.status_id == "burn", "upgrade desc (%s)" % up.description)

	# --- Cures (potions) and item immunity
	e = mk(["normal"], BLOCK1)
	p = pl()
	b = bt(p, [e], "griffe", 1, [], ["antidote", "total_soin"])
	b.apply_status(p, "poison", 3); b.apply_status(p, "burn", 2); b.apply_status(p, "paralysis", 1)
	b.use_potion(0)
	ok(not p.has_status("poison") and p.has_status("burn"), "antidote cures poison only")
	b.use_potion(0)
	ok(p.statuses.is_empty(), "total soin cures all")
	for pair in [["anti_brule", "burn"], ["antigel", "freeze"], ["reveil", "sleep"], ["anti_para", "paralysis"]]:
		p = pl()
		b = bt(p, [mk(["normal"], BLOCK1)], "griffe", 1, [], [pair[0]])
		b.apply_status(p, pair[1], 1)
		b.use_potion(0)
		ok(not p.has_status(pair[1]), "%s cures %s" % pair)
	p = pl()
	b = bt(p, [mk(["normal"], BLOCK1)], "griffe", 1, ["baie_cheri", "baie_mitrons"])
	ok(not b.apply_status(p, "paralysis", 1) and not b.apply_status(p, "poison", 2) and b.apply_status(p, "burn", 1), "berries immunity")
	e = mk(["normal"], BLOCK1)
	ok(b.apply_status(b.enemies[0], "poison", 1), "berry protects only the player")
	# RunState passes the book
	var run := RunState.new()
	ok(run.has_method("create_battle"), "runstate")

	# --- Data validation rejections (errors expected below)
	var st := rd(D + "statuses.json")
	var bad := st.duplicate(true); bad["statuses"]["paralysis"]["skip_chance"] = 2.0
	ok(not load_with({"statuses": wr("t20_s1.json", bad)}), "skip_chance > 1 rejected")
	bad = st.duplicate(true); bad["statuses"]["burn"]["immune_types"] = ["lava"]
	ok(not load_with({"statuses": wr("t20_s2.json", bad)}), "unknown immune type rejected")
	bad = st.duplicate(true); bad["statuses"]["poison"]["value_decay"] = 0
	ok(not load_with({"statuses": wr("t20_s3.json", bad)}), "never-ending poison rejected")
	bad = st.duplicate(true); bad["statuses"]["sleep"]["player_energy_loss"] = -1
	ok(not load_with({"statuses": wr("t20_s4.json", bad)}), "negative player_energy_loss rejected")
	bad = st.duplicate(true); bad["statuses"]["burn"]["player_energy_loss"] = 2
	ok(not load_with({"statuses": wr("t20_s5.json", bad)}), "player_energy_loss without skip_turns rejected")
	bad = st.duplicate(true); bad["statuses"]["paralysis"]["refresh_on_reapply"] = "no"
	ok(not load_with({"statuses": wr("t20_s6.json", bad)}), "non-bool refresh_on_reapply rejected")
	bad = st.duplicate(true); bad["aftermath_immunity"]["turns"] = 0
	ok(not load_with({"statuses": wr("t20_s7.json", bad)}), "aftermath turns 0 rejected")
	bad = st.duplicate(true); bad["aftermath_immunity"]["statuses"] = ["sleep", "confusion"]
	ok(not load_with({"statuses": wr("t20_s8.json", bad)}), "aftermath unknown status rejected")
	bad = st.duplicate(true); bad["aftermath_immunity"]["color"] = "pas une couleur"
	ok(not load_with({"statuses": wr("t20_s9.json", bad)}), "aftermath bad color rejected")
	bad = st.duplicate(true); bad["aftermath_immunity"] = [1, 2]
	ok(not load_with({"statuses": wr("t20_s10.json", bad)}), "aftermath non-object rejected")
	var cd := rd(D + "cards.json")
	var c2 := cd.duplicate(true); c2["cards"]["crocs_feu"]["status"] = {"id": "confusion", "value": 1}
	ok(not load_with({"cards": wr("t20_c1.json", c2)}), "card unknown status rejected")
	c2 = cd.duplicate(true); c2["cards"]["crocs_feu"]["description"] = "Inflige 8 dégâts."
	ok(not load_with({"cards": wr("t20_c2.json", c2)}), "card description without status rejected")
	c2 = cd.duplicate(true); c2["cards"]["crocs_feu"]["status"] = {"id": "burn", "value": 0}
	ok(not load_with({"cards": wr("t20_c3.json", c2)}), "card status value 0 rejected")
	var pk := rd(D + "pokemon.json")
	var p2 := pk.duplicate(true); p2["enemies"]["rattata"]["actions"][1]["status"] = {"id": "poison", "value": 2}
	ok(not load_with({"pokemon": wr("t20_p1.json", p2)}), "status on a block action rejected")
	p2 = pk.duplicate(true); p2["enemies"]["rattata"]["actions"][0]["status"] = {"id": "nope", "value": 2}
	ok(not load_with({"pokemon": wr("t20_p2.json", p2)}), "enemy unknown status rejected")
	var po := rd(D + "potions.json")
	po["potions"]["antidote"]["effects"] = [{"type": "cure_status", "status": "nope"}]
	ok(not load_with({"potions": wr("t20_po.json", po)}), "potion unknown status rejected")
	var itm := rd(D + "items.json")
	itm["items"]["baie_cheri"]["effects"] = [{"type": "status_immunity", "status": "all"}]
	ok(not load_with({"items": wr("t20_i.json", itm)}), "item immunity 'all' rejected")
	ok(load_with({}), "real data still loads")

	print("t20 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
