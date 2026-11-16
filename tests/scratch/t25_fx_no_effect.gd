extends SceneTree
## Story 021 scratch: animations never change the combat result. Same seeded battle played twice through BattleScreen
## (Instantané vs Normal with the director really active, alternating waited / skipped actions).
var fails: int = 0
var gd: GameData

func ok(c: bool, msg: String) -> void:
	if not c:
		fails += 1
		print("FAIL ", msg)

func rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r

func play(speed: String, enc: String) -> Dictionary:
	var run := RunState.create_with_starter(gd, "salameche")
	run.set_zones(gd.draw_zones(rng(3)))
	var battle: Battle = run.create_battle(gd.create_enemies(enc), gd.get_type_chart(), rng(777), false)
	var bs: BattleScreen = (load("res://src/ui/battle_screen.tscn") as PackedScene).instantiate() as BattleScreen
	root.add_child(bs)
	bs.setup(battle, gd, run, enc)
	bs.set_fx_speed(speed)
	var fx: BattleFxDirector = bs.get_fx_director()
	ok(fx.is_enabled() == (speed != "instant"), "enabled for " + speed)
	var actions: int = 0
	var saw_busy: bool = false
	for turn: int in 14:
		if battle.state != Battle.State.PLAYER_TURN:
			break
		var guard: int = 0
		while guard < 12:
			guard += 1
			var idx: int = -1
			for i: int in battle.hand.size():
				if battle.can_play(i):
					idx = i
					break
			if idx < 0 or battle.state != Battle.State.PLAYER_TURN:
				break
			bs.play_card_direct(idx)
			actions += 1
			saw_busy = saw_busy or bs.is_fx_busy()
			if speed != "instant":
				if actions % 2 == 0:
					bs.skip_animations()
				else:
					await settle(bs, 8.0)
		if battle.state != Battle.State.PLAYER_TURN:
			break
		bs.press_end_turn()
		actions += 1
		saw_busy = saw_busy or bs.is_fx_busy()
		if speed != "instant":
			if actions % 2 == 0:
				bs.skip_animations()
			else:
				await settle(bs, 12.0)
	bs.skip_animations()
	var out := {"hp": battle.player.hp, "block": battle.player.block, "state": battle.state, "energy": battle.energy,
		"hand": battle.hand.map(func(c: CardData) -> String: return c.id), "draw": battle.draw_pile.map(func(c: CardData) -> String: return c.id),
		"discard": battle.discard_pile.map(func(c: CardData) -> String: return c.id),
		"enemies": battle.enemies.map(func(e: Combatant) -> Array: return [e.id, e.hp, e.block, e.strength]), "busy": saw_busy, "actions": actions}
	ok(not bs.is_fx_busy(), "idle at the end")
	bs.queue_free()
	await process_frame
	return out

func settle(bs: BattleScreen, max_s: float) -> void:
	var t0: int = Time.get_ticks_msec()
	while bs.is_fx_busy() and float(Time.get_ticks_msec() - t0) < max_s * 1000.0:
		await process_frame
	ok(not bs.is_fx_busy(), "queue ended by itself or by its cap")

func _initialize() -> void:
	_main.call_deferred()  # root enters the tree after _initialize: _ready of added screens runs only then


func _main() -> void:
	gd = GameData.new()
	ok(gd.load_all(), "data loads")
	BattleFxDirector.allow_headless = true
	for enc: String in ["trio_vol", "solo_pikachu"]:
		var a: Dictionary = await play("instant", enc)
		var b: Dictionary = await play("normal", enc)
		var c: Dictionary = await play("fast", enc)
		print(enc, " instant: ", a)
		print(enc, " normal : ", b)
		for k: String in ["hp", "block", "state", "energy", "hand", "draw", "discard", "enemies", "actions"]:
			ok(a[k] == b[k], "%s %s identical instant/normal (%s vs %s)" % [enc, k, a[k], b[k]])
			ok(a[k] == c[k], "%s %s identical instant/fast" % [enc, k])
		ok(not a["busy"], "instant never busy")
		ok(b["busy"], "normal was busy at some point (director really active)")
	print("t25 done, fails=", fails)
	quit(1 if fails > 0 else 0)
