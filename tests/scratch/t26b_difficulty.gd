extends SceneTree
## Story 026 scratch: difficulty levels. The data table (10 levels, cumulative folding, level 0 neutral), the run effects
## (start HP / junk, money, Centre / League heal, Mart prices, enemy HP / Force by fight category, final boss phases),
## save / load of the level (old save = level 0, junk card in the deck), PlayerStats unlock + persistence, and Main's
## flow (starter screen selector, HUD badge, victory screen + unlock, title line, Pokédex header). Scratch files only.
const SAVE_PATH: String = "user://t26b_save.json"
const STATS_PATH: String = "user://t26b_stats.json"
const STARTER: String = "salameche"
var passes: int = 0
var fails: int = 0


func ok(c: bool, msg: String) -> void:
	if c:
		passes += 1
	else:
		fails += 1
		print("FAIL ", msg)


func _initialize() -> void:
	_clean()
	var data := GameData.new()
	ok(data.load_all(), "data loads (difficulty.json valid)")
	_check_table(data)
	_check_run_effects(data)
	_check_enemies(data)
	_check_save(data)
	_check_stats()
	await _check_main(data)
	_clean()
	print("t26b_difficulty: %d pass, %d fail" % [passes, fails])
	quit(1 if fails > 0 else 0)


func _clean() -> void:
	for p: String in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp", STATS_PATH, STATS_PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _check_table(data: GameData) -> void:
	var d: Difficulty = data.get_difficulty()
	ok(d.max_level == 10 and d.levels.size() == 10, "10 levels")
	ok(d.effects_for(0) == Difficulty.neutral_effects(), "level 0 = neutral effects")
	ok(d.modifiers_for(0).is_empty() and d.modifiers_for(3).size() == 3 and d.modifiers_for(99).size() == 10, "cumulative modifier lists")
	ok(d.clamp_level(-4) == 0 and d.clamp_level(42) == 10, "clamp")
	for lvl: int in range(1, 11):
		ok(not String(d.levels[lvl - 1]["name"]).is_empty() and not String(d.levels[lvl - 1]["description"]).is_empty(),
				"level %d has a French name + description" % lvl)
	# Cumulative folding: compare every level with the previous one: something changed, nothing went back.
	for lvl: int in range(1, 11):
		var a: Dictionary = d.effects_for(lvl - 1)
		var b: Dictionary = d.effects_for(lvl)
		ok(a != b, "level %d adds an effect" % lvl)
		for room: String in (a[Difficulty.EFFECT_ENEMY_HP] as Dictionary).keys():
			ok(float(b[Difficulty.EFFECT_ENEMY_HP].get(room, 1.0)) >= float(a[Difficulty.EFFECT_ENEMY_HP][room]),
					"level %d keeps enemy_hp of %s" % [lvl, room])
		for k: String in [Difficulty.EFFECT_MONEY_GAIN, Difficulty.EFFECT_CENTER_HEAL, Difficulty.EFFECT_LEAGUE_HEAL]:
			ok(float(b[k]) <= float(a[k]), "level %d never raises %s" % [lvl, k])
		ok(float(b[Difficulty.EFFECT_SHOP_PRICES]) >= float(a[Difficulty.EFFECT_SHOP_PRICES]), "level %d never lowers prices" % lvl)
	# Folding rule on a hand-made table (product for multipliers, sum for additive effects).
	var t: Difficulty = Difficulty.from_dict({"max_level": 2, "levels": [
		{"level": 1, "name": "A", "description": "a", "effects": [{"type": "enemy_hp", "rooms": ["elite"], "value": 1.5},
				{"type": "money_gain", "value": 0.5}, {"type": "start_junk", "value": 1}]},
		{"level": 2, "name": "B", "description": "b", "effects": [{"type": "enemy_hp", "rooms": ["elite", "wild"], "value": 2.0},
				{"type": "money_gain", "value": 0.5}, {"type": "start_junk", "value": 2}]}]})
	ok(t != null, "hand-made table loads")
	var e2: Dictionary = t.effects_for(2)
	ok(is_equal_approx(float(e2["enemy_hp"]["elite"]), 3.0) and is_equal_approx(float(e2["enemy_hp"]["wild"]), 2.0)
			and is_equal_approx(float(e2["money_gain"]), 0.25) and int(e2["start_junk"]) == 3, "folding: %s" % [e2])
	ok(Difficulty.from_dict({"max_level": 1, "levels": [{"level": 1, "name": "A", "description": "a",
			"effects": [{"type": "explode", "value": 1}]}]}) == null, "unknown effect refused")
	ok(Difficulty.from_dict({"max_level": 1, "levels": [{"level": 1, "name": "A", "description": "a",
			"effects": [{"type": "enemy_hp", "rooms": ["nowhere"], "value": 1.2}]}]}) == null, "unknown room refused")
	ok(Difficulty.room_key("league", {"kind": "final_boss"}) == "league_final_boss" and Difficulty.room_key("boss") == "boss"
			and Difficulty.room_key("") == "", "room keys")
	ok(d.card_frame_for(-1).is_empty() and d.card_frame_for(4).is_empty() and String(d.card_frame_for(5)["id"]) == "gold"
			and String(d.card_frame_for(10)["id"]) == "platinum", "prestige frames at 5 and 10")


func _run_at(data: GameData, level: int) -> RunState:
	var r: RunState = RunState.create_with_starter(data, STARTER)
	r.apply_difficulty(data, level)
	return r


func _count_junk(r: RunState) -> int:
	var n: int = 0
	for c: CardData in r.deck:
		if c.is_junk():
			n += 1
	return n


func _check_run_effects(data: GameData) -> void:
	var base: RunState = RunState.create_with_starter(data, STARTER)
	var r0: RunState = _run_at(data, 0)
	ok(r0.difficulty_level == 0 and r0.max_hp == base.max_hp and r0.hp == base.hp and r0.deck.size() == base.deck.size()
			and r0.money == base.money, "level 0: run unchanged")
	ok(r0.rest_heal_percent() == base.rest_heal_percent() and r0.removal_price() == base.removal_price(), "level 0: services unchanged")
	r0.add_money(100)
	ok(r0.money == base.money + 100, "level 0: money unchanged")
	ok(r0.shop_price(50) == 50, "level 0: prices unchanged")
	for lvl: int in range(0, 11):
		var r: RunState = _run_at(data, lvl)
		var fx: Dictionary = data.get_difficulty().effects_for(lvl)
		ok(r.max_hp == maxi(1, base.max_hp + int(fx["start_max_hp"])) and r.hp == r.max_hp, "level %d start HP %d" % [lvl, r.max_hp])
		ok(_count_junk(r) == int(fx["start_junk"]) and r.deck.size() == base.deck.size() + int(fx["start_junk"]),
				"level %d junk cards %d" % [lvl, _count_junk(r)])
		var before: int = r.money
		r.add_money(100)
		ok(r.money - before == floori(100 * float(fx["money_gain"]) + 0.0001), "level %d money gain %d" % [lvl, r.money - before])
		ok(is_equal_approx(r.rest_heal_percent(), base.rest_heal_percent() * float(fx["center_heal"])), "level %d centre heal" % lvl)
		ok(r.shop_price(100) == ceili(100 * float(fx["shop_prices"]) - 0.0001), "level %d prices %d" % [lvl, r.shop_price(100)])
		ok(r.removal_price() == r.shop_price(base.removal_price()), "level %d removal price" % lvl)
	# League heal between fights.
	for lvl: int in [0, 10]:
		var r: RunState = _run_at(data, lvl)
		r.set_league([{"kind": "member"}, {"kind": "member"}] as Array[Dictionary])
		r.start_league()
		r.win_league_fight()
		r.hp = 1
		var healed: int = r.advance_league(50.0)
		var expect: int = ceili(r.max_hp * 50.0 * float(data.get_difficulty().effects_for(lvl)["league_heal"]) / 100.0)
		ok(healed == mini(expect, r.max_hp - 1), "level %d league heal %d (expected %d)" % [lvl, healed, expect])
	# Mart prices of a generated shop.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var r8: RunState = _run_at(data, 8)
	r8.set_zones(data.draw_zones(rng))
	rng.seed = 9
	var shop8: ShopInventory = ShopInventory.generate(data, r8, rng)
	var r0b: RunState = _run_at(data, 0)
	r0b.set_zones(r8.zones)
	rng.seed = 9
	var shop0: ShopInventory = ShopInventory.generate(data, r0b, rng)
	var all_scaled: bool = shop8.cards.size() == shop0.cards.size() and shop8.cards.size() > 0
	for i: int in mini(shop8.cards.size(), shop0.cards.size()):
		all_scaled = all_scaled and shop8.cards[i].price == r8.shop_price(shop0.cards[i].price) and shop8.cards[i].price > shop0.cards[i].price
	for i: int in mini(shop8.potions.size(), shop0.potions.size()):
		all_scaled = all_scaled and shop8.potions[i].price == r8.shop_price(shop0.potions[i].price)
	ok(all_scaled, "level 8: Mart card / potion prices scaled")


func _battle(data: GameData, run: RunState, encounter: String) -> Battle:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	return run.create_battle(data.create_enemies(encounter), data.get_type_chart(), rng)


func _check_enemies(data: GameData) -> void:
	var encounter: String = data.get_encounter_order()[0]
	var plain: Battle = _battle(data, _run_at(data, 0), encounter)
	var hp0: int = plain.enemies[0].max_hp
	var str0: int = plain.enemies[0].strength
	SpecialFights.apply_fight_mechanics(data, plain, "elite", {}, {}, _run_at(data, 0))
	ok(plain.enemies[0].max_hp == hp0 and plain.enemies[0].strength == str0, "level 0: elite unchanged")
	for lvl: int in [1, 5, 10]:
		var fx: Dictionary = data.get_difficulty().effects_for(lvl)
		for room: String in ["wild", "elite", "boss"]:
			var b: Battle = _battle(data, _run_at(data, lvl), encounter)
			SpecialFights.apply_fight_mechanics(data, b, room, {}, {}, _run_at(data, lvl))
			var mult: float = float(fx["enemy_hp"].get(room, 1.0))
			var bonus: int = int(fx["enemy_strength"].get(room, 0))
			ok(b.enemies[0].max_hp == maxi(1, ceili(snappedf(hp0 * mult, 0.0001))) and b.enemies[0].hp == b.enemies[0].max_hp
					and b.enemies[0].strength == str0 + bonus,
					"level %d %s: hp %d str %d (x%.3f +%d)" % [lvl, room, b.enemies[0].max_hp, b.enemies[0].strength, mult, bonus])
	# QA fights (room "") are never scaled.
	var qa: Battle = _battle(data, _run_at(data, 10), encounter)
	SpecialFights.apply_fight_mechanics(data, qa, "", {}, {}, _run_at(data, 10))
	ok(qa.enemies[0].max_hp == hp0, "room '' unscaled")
	# Final boss phases heal more at level 10.
	var fight: Dictionary = {"kind": "final_boss"}
	var b0: Battle = _battle(data, _run_at(data, 0), encounter)
	SpecialFights.apply_fight_mechanics(data, b0, "league", {}, fight, _run_at(data, 0))
	var b10: Battle = _battle(data, _run_at(data, 10), encounter)
	SpecialFights.apply_fight_mechanics(data, b10, "league", {}, fight, _run_at(data, 10))
	var extra: float = float(data.get_difficulty().effects_for(10)["boss_phase_heal"])
	ok(not b0.enemies[0].phases.is_empty() and b10.enemies[0].phases.size() == b0.enemies[0].phases.size(), "boss phases set")
	for i: int in b0.enemies[0].phases.size():
		ok(is_equal_approx(float(b10.enemies[0].phases[i]["heal_percent"]),
				minf(100.0, float(b0.enemies[0].phases[i]["heal_percent"]) + extra)), "phase %d heal +%.0f %%" % [i, extra])


func _check_save(data: GameData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var r: RunState = _run_at(data, 7)
	r.set_zones(data.draw_zones(rng))
	r.start_act(data, 77)
	var junk: int = _count_junk(r)
	ok(junk > 0, "level 7 run holds junk")
	var d: Dictionary = SaveGame.to_dict(r)
	ok(int(d["run"]["difficulty_level"]) == 7, "level saved")
	var parsed: Variant = JSON.parse_string(JSON.stringify(d))
	var res: Dictionary = SaveGame.from_dict(parsed, data)
	ok(bool(res["ok"]), "save with junk loads: %s" % res.get("error", ""))
	if bool(res["ok"]):
		var back: RunState = res["run"]
		ok(back.difficulty_level == 7 and _count_junk(back) == junk and back.max_hp == r.max_hp, "level + junk + HP restored")
		ok(back.shop_price(100) == r.shop_price(100), "loaded run keeps the level effects")
	ok(SaveGame.write(SAVE_PATH, d) and int((SaveGame.load_run(SAVE_PATH, data)["run"] as RunState).difficulty_level) == 7, "file round trip")
	# A save written before story 026 (no difficulty_level key) is a level-0 run.
	var r0: RunState = _run_at(data, 0)
	r0.set_zones(r.zones)
	r0.start_act(data, 77)
	var old: Dictionary = JSON.parse_string(JSON.stringify(SaveGame.to_dict(r0)))
	(old["run"] as Dictionary).erase("difficulty_level")
	var res_old: Dictionary = SaveGame.from_dict(old, data)
	ok(bool(res_old["ok"]) and (res_old["run"] as RunState).difficulty_level == 0, "old save -> level 0")
	(old["run"] as Dictionary)["difficulty_level"] = "abc"
	var res_bad: Dictionary = SaveGame.from_dict(old, data)
	ok(bool(res_bad["ok"]) and (res_bad["run"] as RunState).difficulty_level == 0, "invalid level -> 0, no crash")
	(old["run"] as Dictionary)["difficulty_level"] = 99
	var res_big: Dictionary = SaveGame.from_dict(old, data)
	ok(bool(res_big["ok"]) and (res_big["run"] as RunState).difficulty_level == 10, "level clamped to max")


func _check_stats() -> void:
	var s: PlayerStats = PlayerStats.load_from(STATS_PATH)
	ok(s.level_unlocked == 0 and s.best_level_won == PlayerStats.NO_LEVEL and s.highest_selectable_level(10) == 0, "fresh stats: level 0 only")
	ok(s.record_level_victory(0, 10) and s.level_unlocked == 1 and s.best_level_won == 0, "win at 0 unlocks 1")
	ok(not s.record_level_victory(0, 10) and s.level_unlocked == 1, "win at 0 again: nothing new")
	ok(s.record_level_victory(1, 10) and s.level_unlocked == 2 and s.best_level_won == 1, "win at 1 unlocks 2")
	ok(s.save(), "stats saved")
	var r: PlayerStats = PlayerStats.load_from(STATS_PATH)
	ok(r.level_unlocked == 2 and r.best_level_won == 1, "unlock persisted")
	ok(r.record_level_victory(10, 10) == true and r.level_unlocked == 10 and r.best_level_won == 10, "win at 10: stays capped at 10")
	ok(not r.record_level_victory(10, 10) and r.level_unlocked == 10, "never above max")
	r.record_level_victory(3, 10)
	ok(r.level_unlocked == 10 and r.best_level_won == 10, "a lower win never lowers the unlock / best")
	# Old stats file (no difficulty keys).
	var f := FileAccess.open(STATS_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"runs_played": 3, "runs_won": 1}))
	f.close()
	var o: PlayerStats = PlayerStats.load_from(STATS_PATH)
	ok(o.runs_played == 3 and o.level_unlocked == 0 and o.best_level_won == PlayerStats.NO_LEVEL, "old stats file -> level 0")
	DirAccess.remove_absolute(STATS_PATH)


func _win_run(m: Main) -> void:
	m.qa_skip_to_league()
	m.qa_set_league_stage(m.get_league().size() - 1)
	m.qa_win_league_fight()


func _check_main(data: GameData) -> void:
	var st := PlayerStats.new()
	st.path = STATS_PATH
	st.level_unlocked = 3
	st.save()
	var m: Main = (load("res://src/main.tscn") as PackedScene).instantiate() as Main
	root.add_child(m)
	await process_frame
	m.qa_set_stats_path(STATS_PATH)
	m.start_new_run(4242)
	await process_frame
	var ss: StarterScreen = m.get_starter_screen()
	ok(ss != null and ss.get_level() == 3, "starter screen: default = highest unlocked (3), got %d" % (ss.get_level() if ss else -1))
	if ss == null:
		m.queue_free()
		return
	ss.set_level(9)
	ok(ss.get_level() == 3, "cannot pick a locked level")
	ss.set_level(2)
	ok(ss.get_level() == 2, "level 2 picked")
	m.starter_choose(0)
	await process_frame
	ok(m.get_difficulty_level() == 2 and m.get_run_state().difficulty_level == 2, "run created at level 2")
	ok(m.get_hud().get_level_text() == "Niv. 2" and m.get_hud().get_level_tooltip().contains("Champions"), "HUD badge: %s" % m.get_hud().get_level_text())
	_win_run(m)
	await process_frame
	ok(m.get_current_screen_name() == "victory", "victory screen (%s)" % m.get_current_screen_name())
	var v: RunEndScreen = m.get_victory_screen()
	ok(v != null and v.get_level_text() == "Niveau 2", "victory: %s" % (v.get_level_text() if v else ""))
	ok(m.get_player_stats().level_unlocked == 3 and m.get_player_stats().best_level_won == 2, "win at 2 with 3 unlocked: no new unlock")
	m.start_new_run(4243)
	await process_frame
	m.get_starter_screen().set_level(3)
	m.starter_choose(1)
	await process_frame
	_win_run(m)
	await process_frame
	v = m.get_victory_screen()
	ok(v != null and v.get_level_text() == "Niveau 3 — Niveau 4 débloqué !", "unlock line: %s" % (v.get_level_text() if v else ""))
	var reloaded: PlayerStats = PlayerStats.load_from(STATS_PATH)
	ok(reloaded.level_unlocked == 4 and reloaded.best_level_won == 3, "unlock 4 persisted (global)")
	# Defeat at a level: no unlock, level shown.
	m.start_new_run(4244)
	await process_frame
	ok(m.get_starter_screen().get_level() == 4, "next run defaults to 4")
	m.starter_choose(0)
	await process_frame
	m.qa_start_boss()
	await process_frame
	m.qa_lose_battle()
	await process_frame
	m.battle_defeat_continue()
	await process_frame
	var dft: RunEndScreen = m.get_defeat_screen()
	ok(dft != null and dft.get_level_text() == "Niveau 4", "defeat: %s" % (dft.get_level_text() if dft else ""))
	ok(PlayerStats.load_from(STATS_PATH).level_unlocked == 4, "defeat never unlocks")
	# Level 0 run (QA forced start, no screen): unchanged game, no HUD badge.
	m.qa_set_difficulty_level(0)
	m.start_new_run(4245, STARTER)
	await process_frame
	ok(m.get_difficulty_level() == 0 and m.get_hud().get_level_text() == "", "level 0: no HUD badge")
	m.qa_set_difficulty_level(-1)
	# Title line + prestige badge; Pokédex header.
	var t := TitleScreen.new()
	root.add_child(t)
	t.setup(reloaded, "", "", "", data)
	ok(t.get_stats_line().ends_with("Niveau max : 4") and t.get_prestige_text() == "★ Niveau 3 vaincu",
			"title: %s / %s" % [t.get_stats_line(), t.get_prestige_text()])
	t.setup(PlayerStats.new(), "", "", "", data)
	ok(t.get_prestige_text() == "" and t.get_stats_line().ends_with("Niveau max : 0"), "title without wins: no badge")
	t.queue_free()
	var ps := PokedexScreen.new()
	root.add_child(ps)
	ps.setup(data, PokedexCatalog.build(data), Pokedex.new(), PokedexRewards.new(), reloaded)
	ok(ps.get_level_text() == "Niveau max : 4  ·  ★ 3 vaincu", "Pokédex header: %s" % ps.get_level_text())
	ps.queue_free()
	# Prestige trim: none below 5, gold at 5 (Options can switch it off).
	ok(CardFace.prestige_trim.a == 0.0, "no trim before a level-5 win")
	m.queue_free()
	await process_frame
