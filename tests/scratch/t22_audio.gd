extends SceneTree
## Story 022 scratch: audio.json is complete (every track / sfx / event / context resolves to an existing imported file),
## every Pokemon of roster.json + pokemon.json has a cry, and AudioManager works headless (music contexts, crossfade,
## sfx / events / cries, volumes saved in GameSettings and reloaded, missing files / unknown ids tolerated).
## Restores the player's saved volumes at the end.
const CFG := "res://assets/data/audio.json"
var passes: int = 0
var fails: int = 0


func ok(c: bool, msg: String) -> void:
	if c:
		passes += 1
	else:
		fails += 1
		print("FAIL ", msg)


func _initialize() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CFG))
	ok(cfg is Dictionary and not cfg.is_empty(), "audio.json parses")
	_check_files(cfg)
	_check_cries(cfg)
	await _check_manager(cfg)
	await _check_main()
	print("t22_audio: %d pass, %d fail" % [passes, fails])
	quit(1 if fails > 0 else 0)


func _check_files(cfg: Dictionary) -> void:
	for id: String in cfg["tracks"]:
		var path: String = String(cfg["tracks"][id]["file"])
		ok(ResourceLoader.exists(path) and load(path) is AudioStream, "track %s loads (%s)" % [id, path])
	for ctx: String in cfg["music"]:
		ok(cfg["tracks"].has(String(cfg["music"][ctx])), "music context %s -> known track" % ctx)
	for need: String in ["map", "wild", "elite", "rival", "boss", "league_member", "league_champion", "final_boss",
			"final_boss_phase2", "victory", "defeat", "center", "mart", "event", "title"]:
		ok(cfg["music"].has(need), "music context %s defined" % need)
	for id: String in cfg["sfx"]:
		ok(ResourceLoader.exists(String(cfg["sfx"][id])) and load(String(cfg["sfx"][id])) is AudioStream, "sfx %s loads" % id)
	for ev: String in cfg["events"]:
		ok(cfg["sfx"].has(String(cfg["events"][ev])), "event %s -> known sfx" % ev)
	var v: Dictionary = cfg["default_volumes"]
	ok(float(v["music"]) >= 0.0 and float(v["music"]) <= 1.0 and float(v["sfx"]) >= 0.0 and float(v["sfx"]) <= 1.0, "default volumes in 0..1")
	var loops: int = 0
	for id: String in cfg["tracks"]:
		var s: AudioStream = load(String(cfg["tracks"][id]["file"]))
		if s is AudioStreamOggVorbis and (s as AudioStreamOggVorbis).loop == bool(cfg["tracks"][id]["loop"]):
			loops += 1
	ok(loops == cfg["tracks"].size(), "every track's imported loop flag matches audio.json (%d/%d)" % [loops, cfg["tracks"].size()])


func _check_cries(cfg: Dictionary) -> void:
	var dir: String = String(cfg["cries"]["dir"])
	var sprites: Array[String] = []
	var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/roster.json"))
	for slug: String in roster["pokemon"]:
		sprites.append(String(roster["pokemon"][slug]["sprite"]))
	var pk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/pokemon.json"))
	for group: String in ["player", "enemies"]:
		for id: String in pk[group]:
			sprites.append(String(pk[group][id]["sprite"]))
	var missing: Array[String] = []
	for sp: String in sprites:
		var path: String = "%s/%s.ogg" % [dir, AudioManager.cry_slug(sp)]
		if not ResourceLoader.exists(path):
			missing.append(AudioManager.cry_slug(sp))
	ok(missing.is_empty(), "every roster / pokemon.json Pokemon has a cry (missing: %s)" % [missing])
	ok(sprites.size() > 700, "cries checked for %d sprites" % sprites.size())


func _check_manager(cfg: Dictionary) -> void:
	var saved: Dictionary = GameSettings.load_all()
	var am := AudioManager.new()
	root.add_child(am)
	await process_frame
	ok(AudioServer.get_bus_index(AudioManager.MUSIC_BUS) >= 0 and AudioServer.get_bus_index(AudioManager.SFX_BUS) >= 0, "Music / SFX buses exist")
	ok(am.is_bus_muted(AudioManager.MUSIC_BUS) and am.is_bus_muted(AudioManager.SFX_BUS), "headless mutes both buses")

	am.play_music("map")
	ok(am.current_track() == "carte", "map -> carte")
	am.play_music("wild")
	ok(am.current_track() == "combat_sauvage", "wild -> combat_sauvage (crossfade)")
	await create_timer(float(cfg["crossfade_seconds"]) + 0.3).timeout
	ok(am.current_track() == "combat_sauvage", "track kept after the crossfade")
	am.play_music("final_boss_phase2", 0.0)
	ok(am.current_track() == "ethernatos_2", "phase 2 -> ethernatos_2 (no fade)")
	am.play_music("ethernatos_1")
	ok(am.current_track() == "ethernatos_1", "a track id is its own context")
	am.play_music("no_such_context")
	ok(am.current_track() == "ethernatos_1", "unknown context keeps the music, no crash")
	am.stop_music(0.0)
	ok(am.current_track() == "", "stop_music clears the track")

	ok(am.play_sfx("hit_super"), "play_sfx hit_super")
	for i: int in 12:
		am.play_sfx("card_draw")  # more than the pool: reuses players
	ok(am.play_event("item_bought"), "play_event item_bought")
	ok(not am.play_sfx("does_not_exist"), "missing sfx tolerated")
	ok(not am.play_sfx("does_not_exist"), "missing sfx tolerated twice (warned once)")
	ok(not am.play_event("no_event"), "unknown event tolerated")
	ok(am.play_cry("pikachu"), "play_cry pikachu")
	ok(am.play_cry("res://assets/sprites/pokemon/charizard.png"), "play_cry from a sprite path")
	ok(not am.play_cry("missingno"), "missing cry tolerated")
	ok(am.cry_plays_on("ko") and am.cry_plays_on("battle_enter") and not am.cry_plays_on("card_played"), "cries.play_on")

	am.set_music_volume(0.25)
	am.set_sfx_volume(1.7)
	ok(is_equal_approx(am.get_music_volume(), 0.25) and is_equal_approx(am.get_sfx_volume(), 1.0), "volumes set and clamped")
	ok(is_equal_approx(GameSettings.get_float(GameSettings.KEY_MUSIC_VOLUME, -1.0), 0.25), "music volume saved")
	var am2 := AudioManager.new()
	root.add_child(am2)
	ok(is_equal_approx(am2.get_music_volume(), 0.25) and is_equal_approx(am2.get_sfx_volume(), 1.0), "volumes reloaded by a new manager")
	am2.set_music_volume(0.0)
	ok(am2.is_bus_muted(AudioManager.MUSIC_BUS), "volume 0 mutes")

	var broken := AudioManager.new("res://does/not/exist.json")
	root.add_child(broken)
	broken.play_music("map")
	broken.play_sfx("hit_normal")  # falls back to sfx_dir default: must not crash
	ok(broken.current_track() == "", "missing config: no music")
	for n: Node in [am, am2, broken]:
		n.queue_free()
	await process_frame

	# Restore the player's settings file as it was.
	for key: String in [GameSettings.KEY_MUSIC_VOLUME, GameSettings.KEY_SFX_VOLUME]:
		if saved.has(key):
			GameSettings.set_value(key, saved[key])
		else:
			var data: Dictionary = GameSettings.load_all()
			data.erase(key)
			var f := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
			if f != null:
				f.store_string(JSON.stringify(data, "  "))
				f.close()


## Part 2: Main owns an AudioManager and picks the music per screen / fight; the options sliders save the volumes.
func _check_main() -> void:
	var saved: Dictionary = GameSettings.load_all()
	var main: Main = (load("res://src/main.tscn") as PackedScene).instantiate() as Main
	root.add_child(main)
	await process_frame
	var audio: AudioManager = main.get_audio()
	ok(audio != null, "Main has an AudioManager")
	if audio == null:
		return
	main.start_new_run(2020, "salameche")
	ok(audio.current_track() == "carte", "map screen -> carte (got %s)" % audio.current_track())
	main.start_encounter("trio_vol", "wild")
	ok(audio.current_track() == "combat_sauvage", "wild fight -> combat_sauvage (got %s)" % audio.current_track())
	main.qa_open_room("center")
	ok(audio.current_track() == "centre", "Centre -> centre (got %s)" % audio.current_track())
	main.qa_open_room("mart")
	ok(audio.current_track() == "mart", "Mart -> mart (got %s)" % audio.current_track())
	main.start_encounter("trio_vol", "boss")
	ok(audio.current_track() == "champion", "gym fight -> champion (got %s)" % audio.current_track())
	main.start_encounter("trio_vol", "")
	ok(audio.current_track() == "combat_sauvage", "unknown room -> wild music (got %s)" % audio.current_track())
	main.open_options()
	var panel: OptionsPanel = main.get_options_panel()
	panel.set_music_volume(0.35)
	panel.set_sfx_volume(0.55)
	ok(is_equal_approx(audio.get_music_volume(), 0.35) and is_equal_approx(audio.get_sfx_volume(), 0.55), "sliders drive the AudioManager")
	ok(is_equal_approx(AudioManager.saved_volume("music"), 0.35) and is_equal_approx(AudioManager.saved_volume("sfx"), 0.55), "sliders save the volumes")
	panel.close()
	panel.open()
	ok(is_equal_approx(float(panel.get_volumes()["music"]), 0.35), "panel reopens with the saved music volume")
	main.queue_free()
	await process_frame
	var f := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(saved, "  "))
		f.close()
