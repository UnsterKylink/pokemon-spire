extends SceneTree
## Story 015 scratch test: SaveGame round trips, RNG determinism across a quit/resume, error handling, deletion, atomic write.

const D := "user://t19_files/"
var passes: int = 0
var fails: int = 0
var gd: GameData
var main: Main


func ok(c: bool, msg: String) -> void:
	if c:
		passes += 1
	else:
		fails += 1
		print("FAIL: ", msg)


func clean(path: String) -> void:
	for p: String in [path, path + ".tmp", path + ".bak"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func canon(d: Dictionary) -> String:
	return JSON.stringify(d["run"], "", true)


func settle(m: Main) -> void:
	for i: int in 14:
		match m.get_current_screen_name():
			"map", "battle", "event", "center", "mart", "league", "victory", "defeat", "starter":
				return
			"reward":
				m.reward_skip()
			"badge":
				m.badge_continue()
			"evolution":
				m.evolution_continue()
				m.evolution_pick(0)
				m.evolution_continue()
			_:
				return


func win_battle(m: Main) -> String:
	var ids: Array[String] = []
	for e: Combatant in m.get_battle_screen().get_battle().enemies:
		ids.append(e.id)
	m._on_battle_won(ids)
	var offers: PackedStringArray = PackedStringArray()
	for o: RewardOffer in m.get_reward_offers():
		offers.append(o.card.deck_key())
	var loot: Dictionary = m.get_last_loot()
	var s: String = "offers=%s loot=%s" % [offers, str(loot.get("money", 0))]
	m.reward_skip()
	settle(m)
	return s


## One deterministic action from the map: enter the first reachable room and resolve it. Returns an observation string.
func step(m: Main) -> String:
	var ids: Array[String] = m.map_reachable_ids()
	if ids.is_empty() or m.get_current_screen_name() != "map":
		return "stuck:" + m.get_current_screen_name()
	m.map_choose(ids[0])
	var out: String = ids[0] + ":" + m.get_current_screen_name() + ":"
	match m.get_current_screen_name():
		"battle":
			out += m.get_encounter_id() + ":" + win_battle(m)
		"event":
			out += String(m.get_current_event().get("id", ""))
			m.event_choose(0)
			m.event_continue()
		"center":
			m.center_heal()
			m.center_continue()
		"mart":
			var inv: ShopInventory = m.get_shop_inventory()
			out += str(inv.cards.size()) + "/" + str(inv.items.size()) + "/" + str(inv.potions.size())
			for c in inv.cards:
				out += "," + c.get_name()
			m.shop_leave()
		_:
			out += "other"
	settle(m)
	var r: RunState = m.get_run_state()
	return out + " hp=%d money=%d deck=%d" % [r.hp, r.money, r.deck.size()]


func steps(m: Main, n: int) -> Array[String]:
	var log: Array[String] = []
	for i: int in n:
		log.append(step(m))
	return log


func new_main() -> Main:
	var m: Main = (load("res://src/main.tscn") as PackedScene).instantiate() as Main
	root.add_child(m)
	return m


func rich_run() -> Main:
	var m: Main = new_main()
	m.start_new_run(42, "salameche")
	for z: int in 3:  # win gyms of zone 1..3 through the real flow: badges, evolution at badge 1
		if z > 0:
			pass
		m.qa_win_gym()
		m.reward_skip()
		settle(m)
	var r: RunState = m.get_run_state()
	m.qa_give_item("peau_metal")
	m.qa_give_item("bandeau")
	m.qa_give_potion("potion")
	m.qa_give_potion("attaque_plus")
	m.qa_give_cards(8)
	var pidgey: CardData = gd.get_card("jet_de_pierres").with_pokemon("pidgey")
	r.add_card(pidgey)
	m.qa_win_battles(4)
	r.upgrade_card(0)
	r.money = 321
	r.hp = 77
	r.card_removals = 2
	r.act.enter(r.act.reachable_ids()[0])
	return m


func _initialize() -> void:
	_go.call_deferred()


func _go() -> void:
	gd = GameData.new()
	ok(gd.load_all(), "data loads")
	DirAccess.make_dir_recursive_absolute(D)
	var real_before: bool = FileAccess.file_exists(SaveGame.DEFAULT_PATH)
	# --- default QA Main never writes the real save
	main = new_main()
	main.start_new_run(5, "salameche")
	ok(not main.qa_save_now(), "autosave off by default in QA")
	ok(FileAccess.file_exists(SaveGame.DEFAULT_PATH) == real_before, "real save untouched")
	# --- rich run round trips
	var m: Main = rich_run()
	var r: RunState = m.get_run_state()
	ok(r.badges.size() == 3 and r.zone_index == 3, "zone 4 with 3 badges (%d, %d)" % [r.badges.size(), r.zone_index])
	ok(r.evolution_stage >= 1 and r.starter_pokemon_id != "salameche" and r.base_pokemon_id == "salameche", "evolved starter %s" % r.starter_pokemon_id)
	var any_up: bool = false
	for c: CardData in r.deck:
		any_up = any_up or c.upgraded
	ok(any_up and r.items.size() >= 2 and r.potions.size() >= 2 and not r.team_progress.is_empty(), "rich content up=%s items=%d pot=%d team=%s" % [any_up, r.items.size(), r.potions.size(), r.team_progress])
	var extras: Dictionary = {"screen": "map", "x": "1"}
	var d1: Dictionary = SaveGame.to_dict(r, extras)
	var res: Dictionary = SaveGame.from_dict(d1, gd)
	ok(res["ok"], "from_dict ok: %s" % res["error"])
	if res["ok"]:
		var c1: String = canon(d1)
		var c2: String = canon(SaveGame.to_dict(res["run"], extras))
		var at: int = 0
		while at < mini(c1.length(), c2.length()) and c1[at] == c2[at]:
			at += 1
		ok(c1 == c2, "to_dict/from_dict equality: diff at %d: %s ||| %s" % [at, c1.substr(maxi(at - 120, 0), 240), c2.substr(maxi(at - 120, 0), 240)])
		var r2: RunState = res["run"]
		ok(r2.badges[0]["color"] is Color and r2.get_summary() == r.get_summary(), "summary + badge colour equal")
		ok(r2.deck_counts() == r.deck_counts() and r2.act.current_node_id == r.act.current_node_id and r2.act.visited == r.act.visited, "deck + progress")
		ok(r2.act.graph.seed == r.act.graph.seed and r2.act.graph.nodes.size() == r.act.graph.nodes.size(), "graph size/seed")
		var same_graph: bool = true
		for id: String in r.act.graph.nodes.keys():
			var a: MapNode = r.act.graph.nodes[id]
			var b: MapNode = r2.act.graph.get_node(id)
			same_graph = same_graph and b != null and a.room_type == b.room_type and a.next == b.next and a.floor == b.floor and a.col == b.col
		ok(same_graph and r2.act.reachable_ids() == r.act.reachable_ids(), "graph nodes/edges/types identical")
		ok(r2.zones == r.zones and r2.league == r.league and r2.evolution_history == r.evolution_history and r2.team_progress == r.team_progress, "zones/league/history/team equal")
		ok(r2.effective_hand_size() == r.effective_hand_size() and r2.effective_energy_per_turn() == r.effective_energy_per_turn() and r2.removal_price() == r.removal_price(), "derived values")
		ok(r2._evolved_badges == r._evolved_badges and r2._base_map_seed == r._base_map_seed and r2._floors_done == r._floors_done, "private counters")
		r2.start_act(gd, 0) if false else null
	# via file
	var path: String = D + "a.json"
	clean(path)
	ok(SaveGame.write(path, d1) and SaveGame.exists(path) and not FileAccess.file_exists(path + ".tmp"), "write atomic: no tmp left")
	var fres: Dictionary = SaveGame.load_run(path, gd)
	ok(fres["ok"] and canon(SaveGame.to_dict(fres["run"], extras)) == canon(d1), "file round trip equality: %s" % fres["error"])
	ok(fres["extras"] == extras, "extras round trip")
	# league case (act may be null after the cheat)
	m.qa_skip_to_league()
	m.qa_set_league_stage(2)
	var rl: RunState = m.get_run_state()
	var dl: Dictionary = SaveGame.to_dict(rl, {"screen": "league"})
	SaveGame.write(path, dl)
	var lres: Dictionary = SaveGame.load_run(path, gd)
	ok(lres["ok"] and lres["run"].league_stage == 2 and lres["run"].league_fights_won == 2 and lres["run"].league == rl.league
			and canon(SaveGame.to_dict(lres["run"], {"screen": "league"})) == canon(dl), "league state round trip: %s" % lres["error"])
	# --- RNG helper survives JSON (64-bit)
	var g := RandomNumberGenerator.new()
	g.seed = 987654321987
	for i: int in 7:
		g.randi()
	var jd: Variant = JSON.parse_string(JSON.stringify(SaveGame.rng_to_dict(g)))
	var g2 := RandomNumberGenerator.new()
	ok(SaveGame.rng_apply(g2, jd) and g2.seed == g.seed and g2.state == g.state, "rng seed/state exact through JSON")
	ok(g2.randi() == g.randi() and g2.randf() == g.randf(), "rng next rolls identical")
	ok(not SaveGame.rng_apply(g2, {"seed": "x"}), "bad rng dict refused")
	# --- error handling
	var good: String = JSON.stringify(d1)
	var cases: Dictionary = {}
	cases["json invalide"] = "{not json"
	cases["vide"] = ""
	cases["racine tableau"] = "[1,2]"
	var bad_ver: Dictionary = JSON.parse_string(good); bad_ver["version"] = 99
	cases["version"] = JSON.stringify(bad_ver)
	var no_ver: Dictionary = JSON.parse_string(good); no_ver.erase("version")
	cases["sans version"] = JSON.stringify(no_ver)
	var bad_card: Dictionary = JSON.parse_string(good); bad_card["run"]["deck"][0]["id"] = "carte_inexistante"
	cases["carte inconnue"] = JSON.stringify(bad_card)
	var bad_poke: Dictionary = JSON.parse_string(good); bad_poke["run"]["starter_pokemon_id"] = "pokemon_inexistant"
	cases["pokemon inconnu"] = JSON.stringify(bad_poke)
	var bad_item: Dictionary = JSON.parse_string(good); bad_item["run"]["items"] = ["objet_inexistant"]
	cases["objet inconnu"] = JSON.stringify(bad_item)
	var bad_pot: Dictionary = JSON.parse_string(good); bad_pot["run"]["potions"] = ["potion_inexistante"]
	cases["potion inconnue"] = JSON.stringify(bad_pot)
	var no_money: Dictionary = JSON.parse_string(good); no_money["run"].erase("money")
	cases["champ manquant"] = JSON.stringify(no_money)
	var no_run: Dictionary = JSON.parse_string(good); no_run.erase("run")
	cases["sans run"] = JSON.stringify(no_run)
	var bad_hp: Dictionary = JSON.parse_string(good); bad_hp["run"]["hp"] = 99999
	cases["pv"] = JSON.stringify(bad_hp)
	var bad_type: Dictionary = JSON.parse_string(good); bad_type["run"]["hp"] = "beaucoup"
	cases["type"] = JSON.stringify(bad_type)
	var bad_edge: Dictionary = JSON.parse_string(good); bad_edge["run"]["act"]["graph"]["nodes"][0]["next"] = ["f99_c9"]
	cases["arete"] = JSON.stringify(bad_edge)
	var bad_room: Dictionary = JSON.parse_string(good); bad_room["run"]["act"]["graph"]["nodes"][0]["room_type"] = "casino"
	cases["salle"] = JSON.stringify(bad_room)
	var bad_zone: Dictionary = JSON.parse_string(good); bad_zone["run"]["zones"].pop_back()
	cases["zones"] = JSON.stringify(bad_zone)
	var bad_cur: Dictionary = JSON.parse_string(good); bad_cur["run"]["act"]["current_node_id"] = "nulle_part"
	cases["salle courante"] = JSON.stringify(bad_cur)
	for k: String in cases.keys():
		var p: String = D + "bad.json"
		var f := FileAccess.open(p, FileAccess.WRITE)
		f.store_string(String(cases[k]))
		f.close()
		var br: Dictionary = SaveGame.load_run(p, gd)
		ok(not br["ok"] and not String(br["error"]).is_empty() and not br["missing"], "error case '%s' -> %s" % [k, br["error"]])
	ok(SaveGame.load_run(D + "nope.json", gd)["missing"], "missing file flagged")
	ok(not SaveGame.from_dict(null, gd)["ok"] and not SaveGame.from_dict(5, gd)["ok"], "non-dict refused")
	# --- atomic write: stale half tmp, invalid dir, overwrite
	var ap: String = D + "atomic.json"
	clean(ap)
	var tf := FileAccess.open(ap + ".tmp", FileAccess.WRITE)
	tf.store_string("{\"version\": 1, \"ru")
	tf.close()
	ok(SaveGame.write(ap, d1) and not FileAccess.file_exists(ap + ".tmp") and SaveGame.load_run(ap, gd)["ok"], "stale half tmp replaced, final file valid")
	var before_text: String = FileAccess.get_file_as_string(ap)
	ok(not SaveGame.write(D + "no_such_dir/x.json", d1), "write to missing dir fails cleanly")
	SaveGame.write(ap, dl)
	ok(SaveGame.load_run(ap, gd)["ok"] and FileAccess.get_file_as_string(ap) != before_text, "overwrite keeps a valid file")
	ok(SaveGame.delete(ap) and not FileAccess.file_exists(ap), "delete")
	# --- Main: autosave, deterministic resume
	var sp: String = D + "main.json"
	clean(sp)
	var ma: Main = new_main()
	ma.qa_set_save_path(sp)
	ma.start_new_run(77, "salameche")
	ok(ma.qa_has_save(), "autosave at the first map")
	var head: Array[String] = steps(ma, 2)
	var tail1: Array[String] = steps(ma, 5)
	ok(ma.get_current_screen_name() != "starter", "played on")
	# relaunch from the safe point saved after `head`: re-create by replaying head from a fresh run with the same seed
	var mb: Main = new_main()
	mb.qa_set_save_path(D + "main_b.json")
	clean(D + "main_b.json")
	mb.start_new_run(77, "salameche")
	var headb: Array[String] = steps(mb, 2)
	ok(headb == head, "same seed same head (control)")
	var graph_before: String = JSON.stringify(SaveGame.to_dict(mb.get_run_state())["run"]["act"])
	var hud_items: int = mb.get_run_state().items.size()
	ok(mb.qa_has_save() and mb.get_current_screen_name() == "map", "saved at the map")
	mb.qa_quit_to_title()
	ok(mb.get_current_screen_name() == "resume" and mb.get_resume_screen() != null and mb.get_run_state() == null, "relaunch shows the resume screen")
	ok(mb.get_resume_screen().has_continue_button() and mb.get_resume_screen().get_summary_lines().size() == 6, "summary shown: %s" % [mb.get_resume_screen().get_summary_lines()])
	mb.resume_continue()
	ok(mb.get_current_screen_name() == "map" and JSON.stringify(SaveGame.to_dict(mb.get_run_state())["run"]["act"]) == graph_before and mb.get_run_state().items.size() == hud_items, "map identical after resume")
	var tail2: Array[String] = steps(mb, 5)
	ok(tail1 == tail2, "deterministic after resume:\n  %s\n  %s" % [tail1, tail2])
	# quit in the middle of a room: resumes at the map before it, same results
	var mc: Main = new_main()
	mc.qa_set_save_path(D + "main_c.json")
	clean(D + "main_c.json")
	mc.start_new_run(77, "salameche")
	steps(mc, 2)
	var ids: Array[String] = mc.map_reachable_ids()
	mc.map_choose(ids[0])  # now inside a room, never saved
	mc.qa_quit_to_title()
	mc.resume_continue()
	ok(mc.get_current_screen_name() == "map" and mc.map_reachable_ids() == ids, "mid-room quit resumes before the room")
	ok(steps(mc, 5) == tail1, "deterministic after a mid-room quit")
	# resume screen "Nouvelle partie" deletes the save
	mc.qa_quit_to_title()
	ok(mc.get_current_screen_name() == "resume", "resume again")
	mc.resume_new_game()
	ok(mc.get_current_screen_name() == "starter" and not mc.qa_has_save(), "Nouvelle partie: save deleted, starter screen")
	mc.qa_quit_to_title()
	ok(mc.get_current_screen_name() == "starter", "no save -> starter screen")
	# unreadable save on the resume screen
	var up: String = D + "main_bad.json"
	clean(up)
	var bf := FileAccess.open(up, FileAccess.WRITE)
	bf.store_string(JSON.stringify(bad_card))
	bf.close()
	mc.qa_set_save_path(up)
	mc.qa_quit_to_title()
	var rs: ResumeScreen = mc.get_resume_screen()
	ok(mc.get_current_screen_name() == "resume" and rs != null and not rs.has_continue_button() and rs.get_message().begins_with("Sauvegarde illisible : "), "unreadable message: %s" % (rs.get_message() if rs != null else "-"))
	ok(FileAccess.file_exists(up + ".bak") and not mc.qa_has_save(), "bad file kept as .bak")
	rs.press_continue()
	ok(mc.get_current_screen_name() == "resume", "no continue in error mode")
	mc.resume_new_game()
	ok(mc.get_current_screen_name() == "starter", "error -> Nouvelle partie -> starter")
	# defeat deletes the save
	var dp: String = D + "main_d.json"
	clean(dp)
	var md: Main = new_main()
	md.qa_set_save_path(dp)
	md.start_new_run(5, "salameche")
	ok(md.qa_has_save(), "save before defeat")
	md.map_choose(md.map_reachable_ids()[0])
	ok(md.qa_lose_battle(), "battle lost")
	ok(not md.qa_has_save(), "save deleted on the lost battle")
	md.battle_defeat_continue()
	ok(md.get_current_screen_name() == "defeat" and not md.qa_has_save(), "defeat screen, no save")
	md.defeat_new_run()
	ok(md.get_current_screen_name() == "starter" and not md.qa_has_save(), "new run after defeat: starter, no stale save")
	md.qa_quit_to_title()
	ok(md.get_current_screen_name() == "starter", "relaunch after defeat: starter")
	# victory deletes the save
	md.start_new_run(5, "salameche")
	md.qa_skip_to_league()
	ok(md.qa_has_save() and md.get_current_screen_name() == "league", "league screen saved")
	md.qa_set_league_stage(md.get_run_state().league.size() - 1)
	md.qa_win_league_fight()
	ok(md.get_current_screen_name() == "victory" and not md.qa_has_save(), "victory deletes the save")
	# league resume
	md.start_new_run(5, "salameche")
	md.qa_skip_to_league()
	md.qa_set_league_stage(2)
	md.qa_quit_to_title()
	md.resume_continue()
	ok(md.get_current_screen_name() == "league" and md.get_run_state().league_stage == 2, "league intermission resumes")
	ok(FileAccess.file_exists(SaveGame.DEFAULT_PATH) == real_before, "real save never touched")
	print("t19 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
