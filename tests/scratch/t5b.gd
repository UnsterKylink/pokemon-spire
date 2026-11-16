extends SceneTree
## Throwaway: walks whole acts through Main's QA methods (story 005 Part B).
var fails: int = 0
var passes: int = 0
var main: Main
var seen: Dictionary = {}

func ok(c: bool, msg: String) -> void:
	if c: passes += 1
	else:
		fails += 1
		print("FAIL ", msg)

## Path from a start node to the boss, preferring one with event + elite + mart.
func plan(g: MapGraph) -> Array[String]:
	var best: Array[String] = []
	var best_score: int = -1
	var stack: Array = []
	for s: String in g.start_node_ids():
		stack.append([s])
	var guard: int = 0
	while not stack.is_empty() and guard < 200000:
		guard += 1
		var path: Array = stack.pop_back()
		var n: MapNode = g.get_node(path[-1])
		if n.next.is_empty():
			var types: Dictionary = {}
			for id: String in path: types[g.get_node(id).room_type] = true
			var score: int = int(types.has("event")) * 4 + int(types.has("elite")) * 4 + int(types.has("mart"))
			if score > best_score:
				best_score = score
				best.assign(path)
			continue
		for nx: String in n.next:
			var p2: Array = path.duplicate()
			p2.append(nx)
			stack.append(p2)
	return best

func win() -> void:
	var guard: int = 0
	while main.get_current_screen_name() == "battle" and guard < 500:
		guard += 1
		var bs: BattleScreen = main.get_battle_screen()
		var b: Battle = bs.get_battle()
		main.qa_set_hp(9999)
		for e: Combatant in b.enemies:
			if e.is_alive():
				e.hp = 1
				e.block = 0
		var played: bool = false
		for i: int in b.hand.size():
			if b.hand[i].kind == CardData.KIND_ATTACK and b.can_play(i):
				bs.select_card(i)
				bs.click_enemy(b.first_living_enemy())
				played = true
				break
		if not played:
			bs.press_end_turn()
	ok(main.get_current_screen_name() in ["reward", "evolution"], "battle won -> reward/evolution (got %s)" % main.get_current_screen_name())

func walk(seed_value: int) -> void:
	main.start_new_run(seed_value)
	ok(main.get_current_screen_name() == "starter" and main.get_starter_choices().size() == 3, "starts on starter screen")
	main.starter_choose(0)
	var run: RunState = main.get_run_state()
	var g: MapGraph = run.act.graph
	ok(g.seed == seed_value, "seed used")
	ok(main.get_current_screen_name() == "map", "starts on map")
	ok(main.get_map_screen().get_info_text().contains("Graine : %d" % seed_value), "seed displayed")
	ok(not main.map_choose(g.boss_id()), "boss refused at start")
	ok(run.act.visited.is_empty() and main.get_current_screen_name() == "map", "refusal changes nothing")
	print("seed ", seed_value, " planning")
	var path: Array[String] = plan(g)
	print("path ", path)
	ok(path.size() == g.floors, "path length %d" % path.size())
	for step: int in path.size():
		var id: String = path[step]
		var reach: Array[String] = main.map_reachable_ids()
		ok(reach.has(id), "planned node reachable")
		# an unreachable node of the same floor (if any) is refused
		for n: MapNode in g.get_floor_nodes(step + 1):
			if not reach.has(n.id):
				ok(not main.map_choose(n.id), "unreachable %s refused" % n.id)
				break
		var rt: String = g.get_node(id).room_type
		seen[rt] = true
		print("step ", step, " ", rt)
		var hp_before: int = run.hp
		if rt == "center" or rt == "event":
			main.qa_set_hp(10)
			hp_before = run.hp
		ok(main.map_choose(id), "enter %s" % id)
		ok(run.act.visited.size() == step + 1, "visited grows")
		ok(run.act.current_floor() == step + 1, "floor %d" % (step + 1))
		var scr: String = main.get_current_screen_name()
		match rt:
			"wild", "elite", "boss":
				ok(scr == "battle", "%s -> battle (%s)" % [rt, scr])
				if rt == "elite" or rt == "boss":
					var base: Array[Combatant] = DataHolder.data.create_enemies(main.get_encounter_id())
					var live: Array[Combatant] = main.get_battle_screen().get_battle().enemies
					for i: int in live.size():
						# story 019: zone-1 multipliers may be < 1 (zones.json tiers[0] x act1 room): HP = ceil(base x multiplier)
						var mult: float = float(DataHolder.data.get_fight_modifiers(rt, main.get_zone())["hp_multiplier"])
						ok(live[i].max_hp == maxi(1, ceili(snappedf(base[i].max_hp * mult, 0.0001))), "%s modified hp %d (base %d x %.2f)" % [rt, live[i].max_hp, base[i].max_hp, mult])
				win()
				if rt == "elite":
					ok(main.get_reward_offers().size() > 0, "elite reward offers")
				if rt == "boss":
					# story 012: gym -> reward -> badge -> evolution (badge 1) -> zone 2 map; then jump to zone 8 -> victory
					ok(main.get_current_screen_name() == "reward", "gym -> reward (%s)" % main.get_current_screen_name())
					main.reward_skip()
					ok(main.get_current_screen_name() == "badge" and main.get_last_badge()["index"] == 1, "reward -> badge")
					main.badge_continue()
					ok(main.get_current_screen_name() == "evolution", "badge 1 -> evolution (%s)" % main.get_current_screen_name())
					main.evolution_continue()
					main.evolution_pick(0)
					main.evolution_continue()
					ok(main.get_current_screen_name() == "map" and main.get_zone_index() == 1 and run.act.visited.is_empty(), "evolution -> zone 2 map")
					ok(main.qa_set_zone(7), "jump to zone 8")
					main.qa_win_gym()
					main.reward_skip()
					main.badge_continue()
					for _e: int in 6:  # story 014: drain evolution screens (starter steps / team summary)
						if main.get_current_screen_name() == "evolution":
							if main.get_evolution_screen().get_step() == EvolutionScreen.Step.CHOOSE: main.evolution_skip()
							else: main.evolution_continue()
					for _k: int in 12:  # story 013: badge 8 -> league (5 fights + Éthernatos) -> victory
						if main.get_current_screen_name() == "battle": main.qa_win_current_fight()  # story 018: pre-league rival
						if main.get_current_screen_name() == "league": main.qa_win_league_fight()
						if main.get_current_screen_name() == "reward": main.reward_skip()
						for _e: int in 6:  # story 014: drain evolution screens (starter steps / team summary)
							if main.get_current_screen_name() == "evolution":
								if main.get_evolution_screen().get_step() == EvolutionScreen.Step.CHOOSE: main.evolution_skip()
								else: main.evolution_continue()
					ok(main.get_current_screen_name() == "victory", "zone 8 gym -> victory")
					break
				else:
					main.reward_skip()
					ok(main.get_current_screen_name() == "map", "reward -> map")
			"event":
				ok(scr == "event", "event screen")
				var ev: Dictionary = main.get_current_event()
				var before: String = "%d/%d/%s" % [run.hp, run.max_hp, ",".join(run.deck.map(func(c: CardData) -> String: return c.id))]
				main.event_continue()
				ok(main.get_current_screen_name() == "event", "continue ignored before choice")
				main.event_choose(0)
				ok(main.get_event_screen().is_result_shown(), "result shown")
				var after: String = "%d/%d/%s" % [run.hp, run.max_hp, ",".join(run.deck.map(func(c: CardData) -> String: return c.id))]
				var all_nothing: bool = true
				for e: Dictionary in ev["options"][0]["effects"]:
					if e["type"] != "nothing": all_nothing = false
				ok(all_nothing or before != after, "event %s effects applied %s -> %s (%s)" % [ev["id"], before, after, main.get_event_screen().get_summary_text()])
				main.event_continue()
				ok(main.get_current_screen_name() == "map", "event -> map")
			"center", "mart":
				# story 006: real Centre / Mart screens; the centre no longer auto-heals on entry
				ok(scr == rt, "%s -> %s screen (%s)" % [rt, rt, scr])
				if rt == "center":
					ok(run.hp == hp_before, "centre does not heal on entry %d -> %d" % [hp_before, run.hp])
					main.room_continue()
					ok(main.get_current_screen_name() == "center", "centre continue ignored before a service")
					main.center_heal()
					ok(run.hp > hp_before, "centre heals %d -> %d" % [hp_before, run.hp])
				else:
					ok(run.hp == hp_before, "mart does nothing")
				main.room_continue()
				ok(main.get_current_screen_name() == "map", "room -> map")
		if main.get_current_screen_name() == "map":
			ok(main.get_map_screen().get_title_text().contains("Étage %d/%d" % [step + 1, g.floors]), "header floor %d" % (step + 1))
	ok(main.get_current_screen_name() == "victory", "victory reached")
	main.victory_new_run()
	ok(main.get_current_screen_name() == "starter", "victory -> starter screen")
	main.starter_choose(0)
	ok(main.get_current_screen_name() == "map" and main.get_run_state() != run and main.get_run_state().act.visited.is_empty(), "new run after act end")

func _initialize() -> void:
	main = (load("res://src/main.tscn") as PackedScene).instantiate() as Main
	root.add_child(main)
	_go.call_deferred()

func _go() -> void:
	DataHolder.data = GameData.new()
	DataHolder.data.load_all()
	for s: int in [12345, 777, 4242]:
		walk(s)
	ok(seen.has("event") and seen.has("elite") and seen.has("center") and seen.has("mart"), "covered types %s" % [seen.keys()])
	# defeat -> Rejouer: new run, new map
	main.start_new_run(999)
	main.starter_choose(0)
	var old_seed: int = main.get_run_state().act.graph.seed
	main.map_choose(main.map_reachable_ids()[0])
	main.get_battle_screen().press_restart()
	ok(main.get_current_screen_name() == "battle", "Continuer ignored while the battle is not lost")
	ok(main.qa_lose_battle(), "battle lost")
	main.battle_defeat_continue()
	ok(main.get_current_screen_name() == "defeat", "defeat overlay -> defeat screen")
	main.defeat_new_run()
	ok(main.get_current_screen_name() == "starter", "Nouvelle partie -> starter screen")
	main.starter_choose(0)
	ok(main.get_current_screen_name() == "map" and main.get_run_state().act.graph.seed != old_seed, "Rejouer -> new map")
	print("t5b passes=%d fails=%d" % [passes, fails])
	quit(1 if fails > 0 else 0)

class DataHolder:
	static var data: GameData
