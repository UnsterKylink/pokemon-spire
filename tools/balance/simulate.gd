extends SceneTree
## Balance simulator (story 019): plays COMPLETE runs with the auto-player policy (tools/balance/sim_policy.gd) on the real
## game logic and writes one JSON record per run.
##   godot --headless --path . -s res://tools/balance/simulate.gd -- --games=N --seed=S --out=path.json [--offset=K] [--policy=file.json]
## Game i (i = offset .. offset+N-1) uses seed S * 1000003 + i * 101 + 1, so shards (--offset) concatenate to the same results as
## one long run. Reports: `python3 tools/balance/make_report.py --tag=<tag> a.json b.json ...` (merges shards, prints the summary and
## writes design/balance/report-<tag>.md); `tools/balance/run.sh <games> <seed> <tag>` does shards + report in one go.

const SimRun: GDScript = preload("res://tools/balance/sim_run.gd")


func _initialize() -> void:
	var games: int = 100
	var base_seed: int = 1
	var offset: int = 0
	var out_path: String = ""
	var policy_path: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--games="):
			games = int(arg.substr(8))
		elif arg.begins_with("--seed="):
			base_seed = int(arg.substr(7))
		elif arg.begins_with("--offset="):
			offset = int(arg.substr(9))
		elif arg.begins_with("--out="):
			out_path = arg.substr(6)
		elif arg.begins_with("--policy="):
			policy_path = arg.substr(9)
	var overrides: Dictionary = {}
	if not policy_path.is_empty():
		overrides = JSON.parse_string(FileAccess.get_file_as_string(policy_path))
	var data := GameData.new()
	if not data.load_all():
		push_error("simulate: could not load game data")
		quit(1)
		return
	var t0: int = Time.get_ticks_msec()
	var runs: Array[Dictionary] = []
	var wins: int = 0
	for i: int in range(offset, offset + games):
		var rec: Dictionary = SimRun.play_game(data, game_seed(base_seed, i), overrides)
		rec["i"] = i
		runs.append(rec)
		if bool(rec["won"]):
			wins += 1
	var elapsed: float = float(Time.get_ticks_msec() - t0) / 1000.0
	print("simulate: %d games, %d wins (%.1f %%), %.1f s (%.2f games/s)" % [games, wins, 100.0 * wins / maxi(games, 1), elapsed,
			games / maxf(elapsed, 0.001)])
	if not out_path.is_empty():
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		if f == null:
			push_error("simulate: cannot write %s" % out_path)
			quit(1)
			return
		f.store_string(JSON.stringify({"base_seed": base_seed, "offset": offset, "games": games, "elapsed_s": elapsed,
				"policy_overrides": overrides, "runs": runs}))
		f.close()
	quit(0)


## Seed of game `index` for the base seed.
static func game_seed(base_seed: int, index: int) -> int:
	return base_seed * 1000003 + index * 101 + 1
