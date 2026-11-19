extends SceneTree
## Story 023 scratch: PlayerStats (save / load / update, best-result ordering, broken file), the title screen (with and
## without a save, stats lines), the pause menu (tree paused, Échap routing, abandon -> stats + save deleted + title),
## the first-run tutorial flag and the tutorial replay sandbox (fixed hand, no save), the fullscreen setting persisted,
## and the new battle tooltips (intent, type pill, energy). Uses scratch files only; restores the player's settings.
const STATS_PATH: String = "user://t23_stats.json"
const SAVE_PATH: String = "user://t23_save.json"
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
	_check_stats()
	var settings_backup: String = FileAccess.get_file_as_string(GameSettings.PATH) if FileAccess.file_exists(GameSettings.PATH) else ""
	_check_fullscreen()
	await _check_main()
	if settings_backup.is_empty():
		DirAccess.remove_absolute(GameSettings.PATH)
	else:
		var f: FileAccess = FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
		f.store_string(settings_backup)
		f.close()
	_clean()
	print("t23_menus: %d pass, %d fail" % [passes, fails])
	quit(1 if fails > 0 else 0)


func _clean() -> void:
	for p: String in [STATS_PATH, STATS_PATH + ".tmp", SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _check_stats() -> void:
	var s: PlayerStats = PlayerStats.load_from(STATS_PATH)
	ok(s.runs_played == 0 and s.runs_won == 0 and s.best_result_text() == "—" and not s.tutorial_done, "missing file = empty stats")
	s.record_run_end({"score": 5, "text": "5 badges"}, false)
	s.record_run_end({"score": 3, "text": "3 badges"}, false)
	ok(s.best_text == "5 badges", "a worse run keeps the best (%s)" % s.best_text)
	s.record_run_end({"score": PlayerStats.LEAGUE_BASE + 2, "text": "Conseil 4 — 2/4"}, false)
	ok(s.best_text == "Conseil 4 — 2/4", "league beats badges")
	s.record_run_end({"score": PlayerStats.VICTORY_SCORE, "text": "Éthernatos vaincu"}, true)
	ok(s.best_text == "Éthernatos vaincu" and s.runs_played == 4 and s.runs_won == 1, "victory: best + counts (%d/%d)" % [s.runs_played, s.runs_won])
	s.tutorial_done = true
	s.last_title_pokemon = "salameche"
	ok(s.save(), "stats saved")
	var r: PlayerStats = PlayerStats.load_from(STATS_PATH)
	ok(r.runs_played == 4 and r.runs_won == 1 and r.best_score == PlayerStats.VICTORY_SCORE and r.tutorial_done
			and r.last_title_pokemon == "salameche", "stats reload: %s" % [r.to_dict()])
	var f: FileAccess = FileAccess.open(STATS_PATH, FileAccess.WRITE)
	f.store_string("{broken")
	f.close()
	ok(PlayerStats.load_from(STATS_PATH).runs_played == 0, "broken file = empty stats")
	DirAccess.remove_absolute(STATS_PATH)
	# result_of on real runs
	var data := GameData.new()
	ok(data.load_all(), "data loads")
	var run: RunState = RunState.create_with_starter(data, "salameche")
	ok(String(PlayerStats.result_of(run)["text"]) == "0 badge", "fresh run = 0 badge")
	for i: int in 5:
		run.badges.append({"index": i})
	var r5: Dictionary = PlayerStats.result_of(run)
	ok(String(r5["text"]) == "5 badges" and int(r5["score"]) == 5, "5 badges: %s" % [r5])
	var stages: Array[Dictionary] = [{"kind": "member"}, {"kind": "member"}, {"kind": "member"}, {"kind": "member"},
			{"kind": "champion"}, {"kind": "final_boss"}]
	run.set_league(stages)
	run.start_league()
	run.league_fights_won = 2
	var rl: Dictionary = PlayerStats.result_of(run)
	ok(String(rl["text"]) == "Conseil 4 — 2/4" and int(rl["score"]) > int(r5["score"]), "league 2/4: %s" % [rl])
	run.final_boss_defeated = true
	ok(String(PlayerStats.result_of(run)["text"]) == "Éthernatos vaincu", "victory text")


func _check_fullscreen() -> void:
	GameSettings.set_fullscreen(true)
	ok(GameSettings.fullscreen_enabled(), "fullscreen saved on")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GameSettings.PATH))
	ok(parsed is Dictionary and bool((parsed as Dictionary).get(GameSettings.KEY_FULLSCREEN, false)), "fullscreen in settings.json")
	GameSettings.set_fullscreen(false)
	ok(not GameSettings.fullscreen_enabled(), "fullscreen saved off")


func _new_main() -> Main:
	var m: Main = (load("res://src/main.tscn") as PackedScene).instantiate() as Main
	root.add_child(m)
	return m


func _free_main(m: Main) -> void:
	paused = false
	m.queue_free()
	await process_frame


func _check_main() -> void:
	var m: Main = _new_main()
	await process_frame
	ok(m.get_current_screen_name() == "starter", "QA launch keeps the starter flow (no title): %s" % m.get_current_screen_name())
	ok(m.get_tutorial_overlay() == null, "no tutorial without opt-in")
	# Options panel: the fullscreen checkbox persists.
	m.open_options()
	m.get_options_panel().set_fullscreen(true)
	ok(GameSettings.fullscreen_enabled() and m.get_options_panel().is_fullscreen_checked(), "options checkbox saves fullscreen")
	m.get_options_panel().set_fullscreen(false)
	ok(m.handle_escape() and not m.get_options_panel().is_open(), "Échap closes the options first")
	# Title screen without / with a save.
	m.qa_set_save_path(SAVE_PATH)
	m.qa_set_stats_path(STATS_PATH)
	m.qa_enable_title_screen(true)
	m.qa_quit_to_title()
	await process_frame
	var t: TitleScreen = m.get_title_screen()
	ok(m.get_current_screen_name() == "title" and t != null and not t.has_continue(), "title without save: no Continuer")
	ok(t != null and t.get_button_texts() == PackedStringArray(["Nouvelle partie", "Tutoriel", "Pokédex", "Options", "Quitter"]), "title buttons: %s" % [t.get_button_texts() if t != null else []])
	ok(t != null and t.get_stats_lines()[0] == "Parties jouées : 0", "stats lines: %s" % [t.get_stats_lines() if t != null else []])
	var first_pokemon: String = t.get_pokemon_sprite() if t != null else ""
	ok(not first_pokemon.is_empty(), "a title Pokémon is shown (%s)" % first_pokemon)
	ok(m.get_audio().current_track() == "titre" or m.get_audio().current_track() == "", "title music context")
	t.press_new_game()
	await process_frame
	ok(m.get_current_screen_name() == "starter", "Nouvelle partie without save -> starter choice")
	m.starter_choose(0)
	await process_frame
	ok(m.get_current_screen_name() == "map" and m.qa_has_save(), "run started and autosaved")
	m.qa_quit_to_title()
	await process_frame
	t = m.get_title_screen()
	ok(t != null and t.has_continue() and t.get_button_texts()[0] == "Continuer", "title with save: Continuer first")
	ok(t != null and t.get_pokemon_sprite() != first_pokemon, "another Pokémon on the next launch")
	t.press_new_game()
	ok(t.is_confirm_open() and m.get_current_screen_name() == "title", "Nouvelle partie with a save asks first")
	ok(m.handle_escape() and not t.is_confirm_open(), "Échap closes the confirmation")
	t.press_continue()
	await process_frame
	ok(m.get_current_screen_name() == "map" and m.get_run_state() != null, "Continuer resumes the saved run")
	# Pause: tree paused, Échap routing, abandon.
	ok(m.handle_escape() and m.is_paused() and paused, "Échap opens the pause and pauses the tree")
	ok(m.handle_escape() and not m.is_paused() and not paused, "Échap again resumes")
	ok(m.open_pause(), "pause from the run bar")
	m.get_pause_menu().press_abandon()
	ok(m.get_pause_menu().get_confirm_kind() == "abandon", "abandon asks for confirmation")
	ok(m.handle_escape() and m.get_pause_menu().get_confirm_kind() == "" and m.is_paused(), "Échap backs out of the confirmation")
	m.get_pause_menu().press_abandon()
	m.get_pause_menu().confirm_abandon()
	await process_frame
	var st: PlayerStats = PlayerStats.load_from(STATS_PATH)
	ok(st.runs_played == 1 and st.runs_won == 0 and st.best_text == "0 badge", "abandon counted as lost: %s" % [st.to_dict()])
	ok(not m.qa_has_save() and not paused and m.get_current_screen_name() == "title", "abandon: save deleted, unpaused, title")
	ok(m.get_title_screen().get_stats_lines()[0] == "Parties jouées : 1", "title shows the new count")
	# Quit to title keeps the save.
	m.get_title_screen().press_new_game()
	m.starter_choose(0)
	await process_frame
	m.open_pause()
	m.get_pause_menu().press_quit()
	m.get_pause_menu().confirm_quit(true)
	await process_frame
	ok(m.qa_has_save() and m.get_current_screen_name() == "title" and m.get_title_screen().has_continue(), "quit to title keeps the save")
	ok(PlayerStats.load_from(STATS_PATH).runs_played == 1, "quitting does not count a run")
	# First-run tutorial flag.
	m.qa_enable_first_run_tutorial(true)
	m.start_new_run(2323, "salameche")
	m.start_encounter("solo_bidoof")
	await process_frame
	var tut: TutorialOverlay = m.get_tutorial_overlay()
	ok(tut != null and tut.get_step_count() == 9 and tut.get_step_id() == "energy", "first battle shows the tutorial")
	if tut != null:
		tut.next()
		ok(tut.get_step_id() == "attack_card" and tut.has_target(), "step 2 points at an attack card")
		tut.next()
		var bs: BattleScreen = m.get_battle_screen()
		var idx: int = -1
		for i: int in bs.get_battle().hand.size():
			if bs.get_battle().hand[i].deals_damage() and bs.get_battle().can_play(i):
				idx = i
				break
		bs.play_card_direct(idx, 0)
		ok(tut.get_step_id() == "intent", "playing a card ends step 3 (%s)" % tut.get_step_id())
		tut.skip()
	ok(PlayerStats.load_from(STATS_PATH).tutorial_done, "skipping saves the tutorial flag")
	m.start_encounter("solo_bidoof")
	await process_frame
	ok(m.get_tutorial_overlay() == null, "no tutorial once seen")
	# Battle tooltips.
	var b2: BattleScreen = m.get_battle_screen()
	ok(not b2.qa_show_tip("intent", 0).is_empty(), "intent tooltip: %s" % [b2.qa_show_tip("intent", 0)])
	var type_tip: String = " ".join(b2.qa_show_tip("enemy_type", 0))
	ok(type_tip.contains("Peu efficace contre : Roche") and type_tip.contains("Type Normal"), "type pill tooltip: %s" % type_tip)
	ok(" ".join(b2.qa_show_tip("energy")).contains("Énergie"), "energy tooltip")
	ok(not b2.qa_show_tip("player_type", 0).is_empty(), "player type tooltip")
	# Tutorial replay sandbox.
	m.qa_quit_to_title()
	await process_frame
	ok(m.qa_has_save(), "save still there before the tutorial")
	var save_before: String = FileAccess.get_file_as_string(SAVE_PATH)
	m.get_title_screen().press_tutorial()
	await process_frame
	var bs3: BattleScreen = m.get_battle_screen()
	ok(m.is_tutorial_sandbox() and bs3 != null and bs3.get_encounter_id() == "solo_chenipan", "tutorial replay starts the fixed fight")
	var ids: PackedStringArray = PackedStringArray()
	for c: CardData in bs3.get_battle().hand:
		ids.append(c.id)
	ok(ids == PackedStringArray(["flammette", "flammeche", "eclair", "abri", "flammette"]), "fixed first hand: %s" % [ids])
	ok(m.get_tutorial_overlay() != null and bs3.get_tutorial_target("switch_card") != null, "replay overlay + switch card target")
	ok(m.open_pause() and m.get_pause_menu().sandbox, "pause in the sandbox")
	m.get_pause_menu().press_abandon()
	m.get_pause_menu().confirm_abandon()
	await process_frame
	ok(m.get_current_screen_name() == "title" and FileAccess.get_file_as_string(SAVE_PATH) == save_before, "sandbox abandon: title, save untouched")
	ok(PlayerStats.load_from(STATS_PATH).runs_played == 1, "sandbox never counts")
	m.get_title_screen().press_tutorial()
	await process_frame
	m.get_tutorial_overlay().skip()
	await process_frame
	await process_frame
	ok(m.get_current_screen_name() == "title", "« Passer le tutoriel » in the replay -> title")
	await _free_main(m)
