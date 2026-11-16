extends SceneTree
## Throwaway: story 007 data half (evolutions + Champion).
var fails: int = 0
var passes: int = 0
const SCR := "/tmp/claude-0/-home-user-pokemon-spire/a2b72075-2d8b-51e2-a914-9e4b612c161d/scratchpad/"

func ok(c: bool, msg: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		print("FAIL ", msg)

func rj(p: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(p))

func loads_mut(mut: Callable) -> bool:
	var p: Dictionary = rj("res://assets/data/pokemon.json")
	mut.call(p)
	var f := FileAccess.open(SCR + "t12_p.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(p))
	f.close()
	return GameData.new().load_all("res://assets/data/cards.json", SCR + "t12_p.json")

func _initialize() -> void:
	var gd := GameData.new()
	ok(gd.load_all(), "real data loads")
	ok(gd.get_evolution_hp_bonus_default() > 0, "default bonus")
	var cands: Array[String] = gd.get_starter_candidates()
	ok(cands.size() == 68, "68 candidates")
	var ids := {}
	var evolvers := 0
	for pid: String in cands:
		var e: Dictionary = gd.get_evolution(pid)
		if e.is_empty():
			print("non-evolving: ", pid)
			continue
		evolvers += 1
		ok(not ids.has(e["id"]), "unique evolved id " + pid)
		ids[e["id"]] = true
		ok(ResourceLoader.exists(e["sprite"]), "sprite exists " + pid)
		var tex: Texture2D = load(e["sprite"])
		ok(tex != null and tex.get_width() == 96, "sprite loads 96px " + pid)
		ok(int(e["max_hp_bonus"]) > 0, "bonus " + pid)
		ok((e["teaches"] as Array).size() == 2, "2 teaches " + pid)
		var cards := gd.get_evolution_cards(pid)
		ok(cards.size() == 2, "cards resolve " + pid)
		for c: CardData in cards:
			ok(c.kind == CardData.KIND_ATTACK and c.rarity in ["uncommon", "rare"], "card rarity " + pid)
		var info := gd.get_pokemon_info(e["id"])
		ok(info.get("name", "") == e["name"] and info["sprite_path"] == e["sprite"], "info for evolved " + pid)
		for t: String in e["types"]:
			ok(gd.get_type_chart().is_known_type(t), "type " + pid)
	ok(evolvers == 68, "all 68 evolve (%d)" % evolvers)
	ok(gd.get_evolution("nope").is_empty(), "unknown base -> empty")
	var sal := gd.get_evolution("salameche")
	ok(sal["id"] == "charmeleon" and sal["name"] == "Reptincel", "salameche -> Reptincel")
	# Champion
	var boss := gd.create_enemies("boss_champion", 1.5, 1)
	ok(boss.size() == 3, "champion has 3")
	var total := 0
	for b: Combatant in boss: total += b.max_hp
	var elite_max := 0
	for enc: String in ["elite_1", "elite_2", "elite_3"]:
		var t := 0
		for b: Combatant in gd.create_enemies(enc, 1.4, 1): t += b.max_hp
		elite_max = maxi(elite_max, t)
	ok(total > elite_max * 2, "champion total hp %d vs elite %d" % [total, elite_max])
	print("champion hp ", total, " elite max ", elite_max)
	for id: String in ["onix", "arcanine", "snorlax"]:
		ok(ResourceLoader.exists(gd.get_pokemon_info(id)["sprite_path"]), "boss sprite " + id)
	# pool still points to it
	var rng := RandomNumberGenerator.new()
	ok(gd.pick_encounter("boss", 15, rng) == "boss_champion", "boss pool")
	# validation negatives (must not crash, must fail)
	ok(not loads_mut(func(p): p["evolutions"]["salameche"]["sprite"] = "res://nope.png"), "bad sprite rejected")
	ok(not loads_mut(func(p): p["evolutions"]["salameche"]["types"] = ["zzz"]), "bad type rejected")
	ok(not loads_mut(func(p): p["evolutions"]["salameche"]["teaches"] = ["abri"]), "skill teach rejected")
	ok(not loads_mut(func(p): p["evolutions"]["salameche"]["teaches"] = ["nope"]), "unknown card rejected")
	ok(not loads_mut(func(p): p["evolutions"]["salameche"]["id"] = "salameche"), "id = base rejected")
	ok(not loads_mut(func(p): p["evolutions"]["salameche"]["max_hp_bonus"] = 0), "bonus 0 rejected")
	ok(not loads_mut(func(p): p["evolutions"]["ghostmon"] = p["evolutions"]["squirtle"].duplicate()), "unknown base rejected")
	ok(not loads_mut(func(p): p.erase("evolution_hp_bonus_default")), "missing default rejected")
	ok(not loads_mut(func(p): p.erase("evolutions")), "missing evolutions rejected")
	print("t12 passes=", passes, " fails=", fails)
	quit(1 if fails > 0 else 0)
