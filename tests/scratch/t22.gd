extends SceneTree
## Story 019 scratch: immunity soft-lock fix (GameData.pick_encounter re-draws a wild / elite fight that the deck's
## attack types cannot damage), deterministic, no extra rolls without a blocked fight, softlock_rerolls validation.
var fails: int = 0
var passes: int = 0

func ok(c: bool, msg: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		print("FAIL ", msg)

func _deck(ids: Array) -> Array[CardData]:
	var d: Array[CardData] = []
	for id: String in ids:
		d.append(_gd.get_card(id))
	return d

var _gd: GameData

func _initialize() -> void:
	_gd = GameData.new()
	ok(_gd.load_all(), "data loads")
	ok(int(_gd._zones_cfg.get("softlock_rerolls", -1)) == 10, "softlock_rerolls = 10 in zones.json")
	# deck_attack_types: damaging attack cards only, distinct, deck order
	var normal_deck: Array[CardData] = _deck(["griffe", "griffe", "abri", "ecrasement"])
	ok(_gd.deck_attack_types(normal_deck) == (["normal"] as Array[String]), "normal deck -> [normal]")
	ok(_gd.deck_attack_types(_deck(["abri", "rugissement"])).is_empty(), "no attack -> []")
	ok(_gd.deck_attack_types(_deck(["griffe", "flammette", "griffe"])) == (["normal", "fire"] as Array[String]), "distinct types in order")
	# encounter_softlocks: league_ghost = ghost team (immune to normal), league_fighting not
	ok(_gd.encounter_softlocks("league_ghost", ["normal"] as Array[String]), "normal-only vs ghost team = soft-lock")
	ok(not _gd.encounter_softlocks("league_ghost", ["normal", "fire"] as Array[String]), "a second type unlocks it")
	ok(not _gd.encounter_softlocks("league_fighting", ["normal"] as Array[String]), "normal vs fighting fine")
	ok(not _gd.encounter_softlocks("league_ghost", [] as Array[String]), "empty types never block")
	ok(_gd.encounter_softlocks("roster:gastly", ["normal"] as Array[String]) == (_gd.get_encounter_enemy_ids("roster:gastly").size() > 0), "roster id decoded")
	# pick_encounter over many seeded draws in every zone: never a soft-lock for a normal-only / ground-only deck
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var zones: Array[Dictionary] = _gd.draw_zones(rng)
	var blocked_plain: int = 0
	var blocked_fixed: int = 0
	var same_when_fine: bool = true
	for types: Array in [["normal"], ["ground"], ["ghost"], ["electric"]]:
		var at: Array[String] = []
		at.assign(types)
		for zi: int in zones.size():
			for s: int in 150:
				for room: String in ["wild", "elite"]:
					var r1 := RandomNumberGenerator.new()
					r1.seed = 1000 * zi + s
					var r2 := RandomNumberGenerator.new()
					r2.seed = 1000 * zi + s
					var plain: String = _gd.pick_encounter(room, 2 if s % 2 == 0 else 4, r1, zones[zi])
					var fixed: String = _gd.pick_encounter(room, 2 if s % 2 == 0 else 4, r2, zones[zi], at)
					if _gd.encounter_softlocks(plain, at):
						blocked_plain += 1
					else:
						# first draw fine -> same result and the rng is in the same state (no extra roll)
						same_when_fine = same_when_fine and plain == fixed and r1.randi() == r2.randi()
					if _gd.encounter_softlocks(fixed, at):
						blocked_fixed += 1
	print("soft-locking draws without fix: ", blocked_plain, ", with fix: ", blocked_fixed)
	ok(blocked_plain > 0, "the problem exists without the fix")
	ok(blocked_fixed * 50 <= blocked_plain, "soft-locks cut by >= 98 %% with 10 re-draws (%d -> %d; fallback keeps the last draw)" % [blocked_plain, blocked_fixed])
	ok(same_when_fine, "no extra roll / same encounter when the first draw is fine")
	# determinism of the re-draw
	var a := RandomNumberGenerator.new(); a.seed = 99
	var b := RandomNumberGenerator.new(); b.seed = 99
	var at2: Array[String] = ["normal"]
	var sa: Array = []
	var sb: Array = []
	for i: int in 200:
		sa.append(_gd.pick_encounter("wild", 2, a, zones[0], at2))
		sb.append(_gd.pick_encounter("wild", 2, b, zones[0], at2))
	ok(sa == sb, "seeded re-draws are deterministic")
	# gym is never re-drawn (team fixed at run start)
	var g := RandomNumberGenerator.new(); g.seed = 1
	ok(_gd.pick_encounter("boss", 6, g, zones[0], at2) == String(zones[0]["gym_encounter"]), "gym unchanged")
	# validation: softlock_rerolls must be an integer >= 0
	var txt: String = FileAccess.get_file_as_string("res://assets/data/zones.json")
	var gd2 := GameData.new()
	ok(gd2.load_all(), "data loads (2)")
	ok(gd2._load_zones(JSON.parse_string(txt)), "control: real zones.json accepted")
	for bad: String in ["-1", "1.5", "\"x\""]:
		var root: Dictionary = JSON.parse_string(txt)
		root["softlock_rerolls"] = JSON.parse_string(bad)
		ok(not gd2._load_zones(root), "rejects softlock_rerolls " + bad)
	print("t22 passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)
