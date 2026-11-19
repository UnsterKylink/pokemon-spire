class_name PlayerStats
extends RefCounted
## Story 023 (story-023-menu-options-tutoriel): the player's lifetime statistics shown on the title screen — runs
## played, runs won, best result — plus the "tutorial seen" flag and the Pokémon shown on the last title screen (so the
## next launch shows another one). Stored in ONE json file (default user://player_stats.json, atomic write); a missing or
## broken file gives empty stats. Pure data: Main records a run end (victory / defeat / abandon) through record_run_end;
## the title screen only reads. The path is injected, so tests and QA never touch the real file.

const DEFAULT_PATH: String = "user://player_stats.json"
const TEMP_SUFFIX: String = ".tmp"
const KEY_PLAYED: String = "runs_played"
const KEY_WON: String = "runs_won"
const KEY_BEST_SCORE: String = "best_score"
const KEY_BEST_TEXT: String = "best_text"
const KEY_TUTORIAL: String = "tutorial_done"
const KEY_LAST_POKEMON: String = "last_title_pokemon"
## Story 026: highest difficulty level the player may choose (global, any starter) and the highest level won (-1 = none).
const KEY_LEVEL_UNLOCKED: String = "difficulty_unlocked"
const KEY_BEST_LEVEL_WON: String = "difficulty_best_won"
## Story 026: no level won yet.
const NO_LEVEL: int = -1
## Story 026: Options toggle of the prestige card frame (on by default).
const KEY_PRESTIGE_FRAME: String = "prestige_frame"
## Result scores (higher = better): badges = 0..8, league = LEAGUE_BASE + fights won, final boss beaten = VICTORY_SCORE.
const LEAGUE_BASE: int = 100
const VICTORY_SCORE: int = 1000
## No result recorded yet.
const NO_SCORE: int = -1
const TEXT_BADGES_ONE: String = "%d badge"
const TEXT_BADGES_MANY: String = "%d badges"
const TEXT_LEAGUE_MEMBER: String = "Conseil 4 — %d/%d"
const TEXT_LEAGUE_CHAMPION: String = "Maître de la Ligue atteint"
const TEXT_FINAL_BOSS_REACHED: String = "Éthernatos atteint"
const TEXT_VICTORY: String = "Éthernatos vaincu"
const TEXT_NONE: String = "—"

var path: String = DEFAULT_PATH
var runs_played: int = 0
var runs_won: int = 0
var best_score: int = NO_SCORE
var best_text: String = ""
var tutorial_done: bool = false
var last_title_pokemon: String = ""
## Story 026: difficulty levels 0..level_unlocked may be chosen; best_level_won = highest level of a full victory.
var level_unlocked: int = 0
var best_level_won: int = NO_LEVEL
## Story 026: show the prestige card frame (when one is unlocked).
var prestige_frame: bool = true


## Loads the stats stored at `stats_path` (empty stats when the file is missing / unreadable).
static func load_from(stats_path: String = DEFAULT_PATH) -> PlayerStats:
	var s := PlayerStats.new()
	s.path = stats_path
	if stats_path.is_empty() or not FileAccess.file_exists(stats_path):
		return s
	var f: FileAccess = FileAccess.open(stats_path, FileAccess.READ)
	if f == null:
		return s
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return s
	var d: Dictionary = parsed
	s.runs_played = maxi(0, int(d.get(KEY_PLAYED, 0)))
	s.runs_won = clampi(int(d.get(KEY_WON, 0)), 0, s.runs_played)
	s.best_score = int(d.get(KEY_BEST_SCORE, NO_SCORE))
	s.best_text = String(d.get(KEY_BEST_TEXT, ""))
	s.tutorial_done = bool(d.get(KEY_TUTORIAL, false))
	s.last_title_pokemon = String(d.get(KEY_LAST_POKEMON, ""))
	s.level_unlocked = maxi(0, int(d.get(KEY_LEVEL_UNLOCKED, 0)))
	s.best_level_won = maxi(NO_LEVEL, int(d.get(KEY_BEST_LEVEL_WON, NO_LEVEL)))
	s.prestige_frame = bool(d.get(KEY_PRESTIGE_FRAME, true))
	return s


## Writes the stats to `path` (temp file + rename). False on failure or without a path.
func save() -> bool:
	if path.is_empty():
		return false
	var tmp: String = path + TEMP_SUFFIX
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict(), "  "))
	f.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path)) == OK


## The stored fields as a Dictionary.
func to_dict() -> Dictionary:
	return {KEY_PLAYED: runs_played, KEY_WON: runs_won, KEY_BEST_SCORE: best_score, KEY_BEST_TEXT: best_text,
			KEY_TUTORIAL: tutorial_done, KEY_LAST_POKEMON: last_title_pokemon, KEY_LEVEL_UNLOCKED: level_unlocked,
			KEY_BEST_LEVEL_WON: best_level_won, KEY_PRESTIGE_FRAME: prestige_frame}


## How far `run` went: {score: int, text: String} ("5 badges", "Conseil 4 — 2/4", "Éthernatos vaincu"...).
static func result_of(run: RunState) -> Dictionary:
	if run == null:
		return {"score": 0, "text": TEXT_BADGES_ONE % 0}
	if run.final_boss_defeated:
		return {"score": VICTORY_SCORE, "text": TEXT_VICTORY}
	if run.is_in_league():
		var members: int = 0
		for f: Dictionary in run.league:
			if String(f.get("kind", "member")) == "member":
				members += 1
		var won: int = run.league_fights_won
		var text: String = TEXT_LEAGUE_MEMBER % [mini(won, members), members]
		if won > members:
			text = TEXT_FINAL_BOSS_REACHED
		elif won == members and members > 0:
			text = TEXT_LEAGUE_CHAMPION
		return {"score": LEAGUE_BASE + won, "text": text}
	var badges: int = run.badges.size()
	return {"score": badges, "text": (TEXT_BADGES_ONE if badges <= 1 else TEXT_BADGES_MANY) % badges}


## Counts one finished run (`victory` = won; a defeat and an abandon both count as lost) with its `result`
## (result_of) and keeps the best one. Does NOT save (call save()).
func record_run_end(result: Dictionary, victory: bool) -> void:
	runs_played += 1
	if victory:
		runs_won += 1
	var score: int = int(result.get("score", 0))
	if score > best_score:
		best_score = score
		best_text = String(result.get("text", ""))


## Story 026: a full victory at difficulty `level` unlocks level + 1 (never above `max_level`, never lowers the unlock)
## and raises best_level_won. Returns true when a NEW level was unlocked. Does NOT save (call save()).
func record_level_victory(level: int, max_level: int) -> bool:
	best_level_won = maxi(best_level_won, level)
	var before: int = level_unlocked
	level_unlocked = clampi(maxi(level_unlocked, level + 1), 0, maxi(max_level, before))
	return level_unlocked > before


## Story 026: the levels the player may choose now: 0..level_unlocked clamped to `max_level`.
func highest_selectable_level(max_level: int) -> int:
	return clampi(level_unlocked, 0, max_level)


## Best result text ("—" before the first finished run).
func best_result_text() -> String:
	return best_text if best_score != NO_SCORE and not best_text.is_empty() else TEXT_NONE
