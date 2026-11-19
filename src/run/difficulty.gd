class_name Difficulty
extends RefCounted
## Story 026 (story-026-niveaux-de-difficulte): the difficulty levels (« Ascension »), read from assets/data/difficulty.json.
## Level 0 = the normal game; level N applies the effects of levels 1..N (cumulative). Pure data + a small effect vocabulary
## (no per-level code): effects_for(level) folds the effects into one Dictionary read by RunState (money, heals, prices,
## starting HP / junk) and SpecialFights (enemy HP / Force, final boss phases). Cosmetics (prestige card frame, title badge
## colour) are also described here; they never change the game.

const DEFAULT_PATH: String = "res://assets/data/difficulty.json"
const EFFECT_ENEMY_HP: String = "enemy_hp"
const EFFECT_ENEMY_STRENGTH: String = "enemy_strength"
const EFFECT_MONEY_GAIN: String = "money_gain"
const EFFECT_CENTER_HEAL: String = "center_heal"
const EFFECT_LEAGUE_HEAL: String = "league_heal"
const EFFECT_SHOP_PRICES: String = "shop_prices"
const EFFECT_START_MAX_HP: String = "start_max_hp"
const EFFECT_START_JUNK: String = "start_junk"
const EFFECT_BOSS_PHASE_HEAL: String = "boss_phase_heal"
## Multiplicative effects (cumulative product, neutral 1.0).
const MULT_EFFECTS: Array[String] = [EFFECT_MONEY_GAIN, EFFECT_CENTER_HEAL, EFFECT_LEAGUE_HEAL, EFFECT_SHOP_PRICES]
## Additive effects (cumulative sum, neutral 0).
const ADD_EFFECTS: Array[String] = [EFFECT_START_MAX_HP, EFFECT_START_JUNK, EFFECT_BOSS_PHASE_HEAL]
## Fight categories an enemy_hp / enemy_strength effect may target (see room_key).
const ROOM_KEYS: Array[String] = ["wild", "elite", "boss", "rival", "rival_final", "legendary", "league_member",
		"league_champion", "league_final_boss"]

var max_level: int = 0
## levels[i] = level i + 1: {level, name, description, effects: Array}.
var levels: Array[Dictionary] = []
## cosmetics.card_frames sorted by min_level: {min_level, id, name, color: Color}.
var card_frames: Array[Dictionary] = []
## cosmetics.badge_colors sorted by min_level: {min_level, color: Color}.
var badge_colors: Array[Dictionary] = []
var _cache: Dictionary = {}


## Loads and validates `path`. Null (after push_error) when the file is missing or invalid.
static func load_from(path: String = DEFAULT_PATH) -> Difficulty:
	if not FileAccess.file_exists(path):
		push_error("Difficulty: missing %s" % path)
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		push_error("Difficulty: %s is not a JSON object" % path)
		return null
	return from_dict(parsed)


## Builds the table from a parsed difficulty.json. Null (after push_error) when invalid.
static func from_dict(root: Dictionary) -> Difficulty:
	var d := Difficulty.new()
	var ml: Variant = root.get("max_level", null)
	if not (ml is float or ml is int) or int(ml) < 0:
		push_error("Difficulty: max_level must be an integer >= 0")
		return null
	d.max_level = int(ml)
	var raw: Variant = root.get("levels", [])
	if not (raw is Array) or (raw as Array).size() != d.max_level:
		push_error("Difficulty: 'levels' must list exactly max_level (%d) levels" % d.max_level)
		return null
	for i: int in (raw as Array).size():
		var lv: Variant = (raw as Array)[i]
		if not (lv is Dictionary) or int((lv as Dictionary).get("level", -1)) != i + 1 \
				or not ((lv as Dictionary).get("name") is String) or not ((lv as Dictionary).get("description") is String):
			push_error("Difficulty: level #%d needs level = %d, name and description" % [i + 1, i + 1])
			return null
		var effects: Variant = (lv as Dictionary).get("effects", null)
		if not (effects is Array) or (effects as Array).is_empty():
			push_error("Difficulty: level %d needs a non-empty 'effects' array" % (i + 1))
			return null
		for e: Variant in (effects as Array):
			var reason: String = _check_effect(e)
			if not reason.is_empty():
				push_error("Difficulty: level %d: %s" % [i + 1, reason])
				return null
		d.levels.append({"level": i + 1, "name": String(lv["name"]), "description": String(lv["description"]),
				"effects": (effects as Array).duplicate(true)})
	var cos: Dictionary = root.get("cosmetics", {}) if root.get("cosmetics", {}) is Dictionary else {}
	for f: Variant in cos.get("card_frames", []):
		if f is Dictionary and (f as Dictionary).has("min_level") and (f as Dictionary).has("color"):
			d.card_frames.append({"min_level": int(f["min_level"]), "id": String(f.get("id", "")),
					"name": String(f.get("name", "")), "color": Color.from_string(String(f["color"]), Color.WHITE)})
	for b: Variant in cos.get("badge_colors", []):
		if b is Dictionary and (b as Dictionary).has("min_level") and (b as Dictionary).has("color"):
			d.badge_colors.append({"min_level": int(b["min_level"]), "color": Color.from_string(String(b["color"]), Color.WHITE)})
	d.card_frames.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["min_level"]) < int(b["min_level"]))
	d.badge_colors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["min_level"]) < int(b["min_level"]))
	return d


static func _check_effect(e: Variant) -> String:
	if not (e is Dictionary):
		return "an effect must be an object"
	var t: String = String((e as Dictionary).get("type", ""))
	var v: Variant = (e as Dictionary).get("value", null)
	if not (v is float or v is int):
		return "effect '%s' needs a numeric value" % t
	if t == EFFECT_ENEMY_HP or t == EFFECT_ENEMY_STRENGTH:
		var rooms: Variant = (e as Dictionary).get("rooms", null)
		if not (rooms is Array) or (rooms as Array).is_empty():
			return "effect '%s' needs a non-empty 'rooms' array" % t
		for r: Variant in (rooms as Array):
			if not ROOM_KEYS.has(String(r)):
				return "unknown room '%s' (expected one of %s)" % [r, ROOM_KEYS]
		if t == EFFECT_ENEMY_HP and float(v) <= 0.0:
			return "enemy_hp value must be > 0"
		if t == EFFECT_ENEMY_STRENGTH and int(v) < 0:
			return "enemy_strength value must be >= 0"
		return ""
	if MULT_EFFECTS.has(t):
		return "" if float(v) > 0.0 else "effect '%s' value must be > 0" % t
	if ADD_EFFECTS.has(t):
		if t == EFFECT_START_JUNK and int(v) < 0:
			return "start_junk value must be >= 0"
		if t == EFFECT_BOSS_PHASE_HEAL and (float(v) < 0.0 or float(v) > 100.0):
			return "boss_phase_heal value must be 0..100"
		return ""
	return "unknown effect type '%s'" % t


## `level` clamped to 0..max_level.
func clamp_level(level: int) -> int:
	return clampi(level, 0, max_level)


## The modifiers active at `level` (levels 1..level, in order): [{level, name, description}]. [] at level 0.
func modifiers_for(level: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i: int in clamp_level(level):
		out.append({"level": int(levels[i]["level"]), "name": String(levels[i]["name"]),
				"description": String(levels[i]["description"])})
	return out


## The modifier ADDED by `level` ({} for level 0 / out of range).
func modifier_of(level: int) -> Dictionary:
	if level < 1 or level > max_level:
		return {}
	return {"level": level, "name": String(levels[level - 1]["name"]), "description": String(levels[level - 1]["description"])}


## The folded effects of `level` (cumulative): {enemy_hp: {room: mult}, enemy_strength: {room: bonus}, money_gain,
## center_heal, league_heal, shop_prices (floats, neutral 1.0), start_max_hp, start_junk (ints, neutral 0),
## boss_phase_heal (float, neutral 0)}. Level 0 = every value neutral. Cached; the caller must not modify it.
func effects_for(level: int) -> Dictionary:
	var lvl: int = clamp_level(level)
	if _cache.has(lvl):
		return _cache[lvl]
	var out: Dictionary = neutral_effects()
	for i: int in lvl:
		for e: Dictionary in levels[i]["effects"]:
			var t: String = String(e["type"])
			if t == EFFECT_ENEMY_HP or t == EFFECT_ENEMY_STRENGTH:
				var map: Dictionary = out[t]
				for r: Variant in e["rooms"]:
					if t == EFFECT_ENEMY_HP:
						map[String(r)] = float(map.get(String(r), 1.0)) * float(e["value"])
					else:
						map[String(r)] = int(map.get(String(r), 0)) + int(e["value"])
			elif MULT_EFFECTS.has(t):
				out[t] = float(out[t]) * float(e["value"])
			elif t == EFFECT_BOSS_PHASE_HEAL:
				out[t] = float(out[t]) + float(e["value"])
			else:
				out[t] = int(out[t]) + int(e["value"])
	_cache[lvl] = out
	return out


## Effects of the normal game (level 0).
static func neutral_effects() -> Dictionary:
	return {EFFECT_ENEMY_HP: {}, EFFECT_ENEMY_STRENGTH: {}, EFFECT_MONEY_GAIN: 1.0, EFFECT_CENTER_HEAL: 1.0,
			EFFECT_LEAGUE_HEAL: 1.0, EFFECT_SHOP_PRICES: 1.0, EFFECT_START_MAX_HP: 0, EFFECT_START_JUNK: 0,
			EFFECT_BOSS_PHASE_HEAL: 0.0}


## The difficulty category of a fight: Main / simulator room type ("wild", "elite", "boss", "rival", "rival_final",
## "legendary", "league") + the league fight dict (kind member / champion / final_boss). "" = not affected (QA fights).
static func room_key(room_type: String, league_fight: Dictionary = {}) -> String:
	if room_type == "league":
		match String(league_fight.get("kind", "")):
			"member":
				return "league_member"
			"champion":
				return "league_champion"
			"final_boss":
				return "league_final_boss"
		return ""
	return room_type if ROOM_KEYS.has(room_type) else ""


## The prestige card frame unlocked by `best_level_won` ({} if none): the highest card_frames entry reached.
func card_frame_for(best_level_won: int) -> Dictionary:
	var best: Dictionary = {}
	for f: Dictionary in card_frames:
		if best_level_won >= int(f["min_level"]):
			best = f
	return best


## The title badge colour of `best_level_won` (Color.WHITE without data).
func badge_color_for(best_level_won: int) -> Color:
	var c: Color = Color.WHITE
	for b: Dictionary in badge_colors:
		if best_level_won >= int(b["min_level"]):
			c = b["color"]
	return c


## One French line per active modifier at `level` (« 1. Élites aguerris — ... »); ["Aucun modificateur"] at level 0.
func describe_lines(level: int) -> Array[String]:
	var out: Array[String] = []
	for m: Dictionary in modifiers_for(level):
		out.append("%d. %s — %s" % [int(m["level"]), String(m["name"]), String(m["description"])])
	if out.is_empty():
		out.append(TEXT_NO_MODIFIER)
	return out


const TEXT_NO_MODIFIER: String = "Niveau 0 : partie normale, aucun modificateur."
