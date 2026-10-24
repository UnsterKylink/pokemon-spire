class_name SaveGame
extends RefCounted
## Story 015 (story-015-sauvegarde): autosave / resume of a run. Pure logic, no Node access, no autoload.
## One slot (DEFAULT_PATH, JSON). The file holds everything needed to rebuild the run EXACTLY at a SAFE point (the act map or
## a league intermission; never mid-battle): RunState (identity, form/evolution state, HP, deck as card id + carrier +
## upgraded flag, money, items, potions, badges, zones, league draw...), the current zone's map graph + ActProgress, and
## `extras` (Main's RNG seeds AND states, screen, CLI seed...). Ids are rebuilt through GameData, so a save that
## references unknown data is refused with a clear reason instead of crashing.
## Big integers (RNG seeds / states, map seed) are stored as STRINGS: JSON numbers are doubles and would lose bits.
## Every function takes the path / GameData as a parameter, so tests never touch the real user:// file.

const VERSION: int = 1
const DEFAULT_PATH: String = "user://savegame.json"
const BACKUP_SUFFIX: String = ".bak"
const TEMP_SUFFIX: String = ".tmp"
## Free-form data trees (copied from the data files) stored with their floats TAGGED ({"#f": value}): a JSON number comes
## back as a float, so untagged whole numbers are restored as ints and tagged ones as floats -- an exact round trip.
const TREE_FIELDS: Array[String] = ["evolution_history", "team_progress", "zones", "badges", "league"]
const FLOAT_TAG: String = "#f"
const INT_FIELDS: Array[String] = ["max_hp", "hp", "energy_per_turn", "hand_size", "bonus_hand_size", "bonus_energy",
		"battles_won", "enemies_defeated", "evolution_stage", "money", "card_removals", "zone_index", "floors_done",
		"league_stage", "league_fights_won"]
const STRING_FIELDS: Array[String] = ["player_id", "display_name", "sprite_path", "base_pokemon_id", "starter_pokemon_id",
		"base_map_seed"]
const BOOL_FIELDS: Array[String] = ["evolution_applied", "evolved", "final_boss_defeated"]
const ARRAY_FIELDS: Array[String] = ["type_ids", "deck", "evolution_history", "evolved_badges", "items", "potions", "zones",
		"badges", "league"]


# --- Serialisation --------------------------------------------------------------------------------

## The JSON-safe save dictionary of `run`. `extras` (JSON-safe, owned by the caller: RNG states, screen...) is stored as is.
static func to_dict(run: RunState, extras: Dictionary = {}) -> Dictionary:
	var deck: Array = []
	for c: CardData in run.deck:
		deck.append({"id": c.id, "pokemon": c.pokemon_id, "up": c.upgraded})
	var items: Array = []
	for it: ItemData in run.items:
		items.append(it.id)
	var potions: Array = []
	for p: PotionData in run.potions:
		potions.append(p.id)
	var badges: Array = []
	for b: Dictionary in run.badges:
		var copy: Dictionary = b.duplicate(true)
		copy["color"] = (b["color"] as Color).to_html() if b.get("color") is Color else ""
		badges.append(copy)
	var act: Variant = null
	if run.act != null and run.act.graph != null:
		var nodes: Array = []
		var ids: Array = run.act.graph.nodes.keys()
		ids.sort()
		for id: String in ids:
			var n: MapNode = run.act.graph.nodes[id]
			nodes.append({"id": n.id, "floor": n.floor, "col": n.col, "room_type": n.room_type, "next": n.next.duplicate()})
		act = {"graph": {"seed": str(run.act.graph.seed), "floors": run.act.graph.floors, "width": run.act.graph.width,
				"nodes": nodes}, "current_node_id": run.act.current_node_id, "visited": run.act.visited.duplicate()}
	var run_dict: Dictionary = {"player_id": run.player_id, "display_name": run.display_name, "type_ids": run.type_ids.duplicate(),
			"sprite_path": run.sprite_path, "max_hp": run.max_hp, "hp": run.hp, "energy_per_turn": run.energy_per_turn,
			"hand_size": run.hand_size, "bonus_hand_size": run.bonus_hand_size, "bonus_energy": run.bonus_energy,
			"deck": deck, "battles_won": run.battles_won, "enemies_defeated": run.enemies_defeated,
			"base_pokemon_id": run.base_pokemon_id, "starter_pokemon_id": run.starter_pokemon_id,
			"evolution_applied": run.evolution_applied, "evolved": run.evolved, "evolution_stage": run.evolution_stage,
			"evolution_history": _enc(run.evolution_history), "team_progress": _enc(run.team_progress),
			"evolved_badges": run._evolved_badges.duplicate(), "money": run.money, "items": items, "potions": potions,
			"card_removals": run.card_removals, "zones": _enc(run.zones), "zone_index": run.zone_index,
			"badges": _enc(badges), "base_map_seed": str(run._base_map_seed), "floors_done": run._floors_done,
			"league": _enc(run.league), "league_stage": run.league_stage,
			"league_fights_won": run.league_fights_won, "final_boss_defeated": run.final_boss_defeated, "act": act}
	return {"version": VERSION, "saved_at": Time.get_datetime_string_from_system(false, true),
			"saved_unix": int(Time.get_unix_time_from_system()), "run": run_dict, "extras": extras.duplicate(true)}


## Rebuilds a run from a save dictionary (parsed JSON or to_dict output). Never crashes on bad input:
## returns {"ok": bool, "run": RunState (ok only), "extras": Dictionary, "saved_at": String, "error": String (French reason)}.
static func from_dict(data: Variant, game: GameData) -> Dictionary:
	if not (data is Dictionary):
		return _fail("contenu invalide (objet attendu)")
	var d: Dictionary = data
	var migrated: Dictionary = _migrate(d)
	if not migrated.get("ok", false):
		return _fail(String(migrated["error"]))
	d = migrated["data"]
	if game == null:
		return _fail("données du jeu indisponibles")
	if not (d.get("run") is Dictionary):
		return _fail("section « run » manquante")
	var rd: Dictionary = (d["run"] as Dictionary).duplicate()
	for k: String in TREE_FIELDS:
		if rd.has(k):
			rd[k] = _dec(rd[k])
	var reason: String = _check_fields(rd)
	if reason.is_empty():
		reason = _check_references(rd, game)
	if not reason.is_empty():
		return _fail(reason)
	var run: RunState = _build_run(rd, game)
	var extras: Variant = d.get("extras", {})
	return {"ok": true, "run": run, "extras": extras if extras is Dictionary else {}, "saved_at": String(d.get("saved_at", "")),
			"error": ""}


## Data-free migration hook: only VERSION is accepted today. Returns {"ok", "data" | "error"}.
static func _migrate(d: Dictionary) -> Dictionary:
	var v: Variant = d.get("version")
	if not _is_num(v):
		return {"ok": false, "error": "version absente"}
	if int(v) != VERSION:
		return {"ok": false, "error": "version %d non prise en charge (attendue : %d)" % [int(v), VERSION]}
	return {"ok": true, "data": d}


static func _fail(reason: String) -> Dictionary:
	return {"ok": false, "run": null, "extras": {}, "saved_at": "", "error": reason}


static func _is_num(v: Variant) -> bool:
	return v is int or v is float


## Structure / type check of the "run" section. "" = fine, else the French reason.
static func _check_fields(rd: Dictionary) -> String:
	for k: String in INT_FIELDS:
		if not _is_num(rd.get(k)):
			return "champ manquant ou invalide : %s" % k
	for k: String in STRING_FIELDS:
		if not (rd.get(k) is String):
			return "champ manquant ou invalide : %s" % k
	for k: String in BOOL_FIELDS:
		if not (rd.get(k) is bool):
			return "champ manquant ou invalide : %s" % k
	for k: String in ARRAY_FIELDS:
		if not (rd.get(k) is Array):
			return "champ manquant ou invalide : %s" % k
	if not (rd.get("team_progress") is Dictionary):
		return "champ manquant ou invalide : team_progress"
	if not String(rd["base_map_seed"]).is_valid_int():
		return "graine de carte invalide"
	if int(rd["max_hp"]) < 1 or int(rd["hp"]) < 0 or int(rd["hp"]) > int(rd["max_hp"]):
		return "PV incohérents"
	for e: Variant in rd["deck"]:
		if not (e is Dictionary) or not (e.get("id") is String) or not (e.get("pokemon") is String) or not (e.get("up") is bool):
			return "carte du deck invalide"
	for k: String in ["items", "potions", "type_ids"]:
		for e: Variant in rd[k]:
			if not (e is String):
				return "liste invalide : %s" % k
	for e: Variant in rd["evolved_badges"]:
		if not _is_num(e):
			return "liste invalide : evolved_badges"
	for k: String in ["evolution_history", "zones", "badges", "league"]:
		for e: Variant in rd[k]:
			if not (e is Dictionary):
				return "liste invalide : %s" % k
	for k: Variant in (rd["team_progress"] as Dictionary).keys():
		var p: Variant = rd["team_progress"][k]
		if not (p is Dictionary) or not _is_num(p.get("battles")) or not _is_num(p.get("stage")):
			return "progression d'équipe invalide"
	if not (rd.has("act")) or not (rd["act"] == null or rd["act"] is Dictionary):
		return "carte de zone invalide"
	return ""


## Checks that every id / index of the save exists in the current data. "" = fine, else the French reason.
static func _check_references(rd: Dictionary, game: GameData) -> String:
	if game.get_player_definition(String(rd["player_id"])).is_empty():
		return "joueur inconnu : %s" % rd["player_id"]
	for k: String in ["starter_pokemon_id", "base_pokemon_id"]:
		if game.get_pokemon_info(String(rd[k])).is_empty():
			return "Pokémon inconnu : %s" % rd[k]
	for e: Dictionary in rd["deck"]:
		if not game.has_card(String(e["id"])):
			return "carte inconnue : %s" % e["id"]
		if not String(e["pokemon"]).is_empty() and game.get_pokemon_info(String(e["pokemon"])).is_empty():
			return "Pokémon inconnu : %s" % e["pokemon"]
	if (rd["deck"] as Array).is_empty():
		return "deck vide"
	for id: String in rd["items"]:
		if not game.has_item(id):
			return "objet inconnu : %s" % id
	for id: String in rd["potions"]:
		if not game.has_potion(id):
			return "potion inconnue : %s" % id
	for id: String in (rd["team_progress"] as Dictionary).keys():
		if game.get_pokemon_info(id).is_empty():
			return "Pokémon inconnu : %s" % id
	var zones: Array = rd["zones"]
	if zones.size() != game.get_zone_count():
		return "zones incompatibles (%d au lieu de %d)" % [zones.size(), game.get_zone_count()]
	for z: Dictionary in zones:
		for k: String in ["number", "type_id", "badge_id", "badge_name", "type_name", "leader", "gym_encounter"]:
			if not z.has(k):
				return "zone invalide (champ %s)" % k
	var zi: int = int(rd["zone_index"])
	if zi < 0 or zi >= maxi(zones.size(), 1):
		return "zone courante invalide"
	if (rd["badges"] as Array).size() > zones.size():
		return "trop de badges"
	for b: Dictionary in rd["badges"]:
		for k: String in ["id", "name", "index", "zone_index", "type_id", "leader"]:
			if not b.has(k):
				return "badge invalide (champ %s)" % k
	var league: Array = rd["league"]
	for f: Dictionary in league:
		for k: String in ["name", "title", "kind", "type_id", "encounter", "modifiers"]:
			if not f.has(k):
				return "combat de ligue invalide (champ %s)" % k
		if not (f["modifiers"] is Dictionary) or not _is_num(f["modifiers"].get("hp_multiplier")) \
				or not _is_num(f["modifiers"].get("strength_bonus")):
			return "combat de ligue invalide (modificateurs)"
	var ls: int = int(rd["league_stage"])
	if ls < -1 or ls >= maxi(league.size(), 1) or int(rd["league_fights_won"]) < 0 \
			or int(rd["league_fights_won"]) > league.size():
		return "étape de ligue invalide"
	if rd["act"] != null:
		return _check_act(rd["act"], game)
	return ""


static func _check_act(act: Dictionary, game: GameData) -> String:
	var g: Variant = act.get("graph")
	if not (g is Dictionary) or not String(g.get("seed", "x")).is_valid_int() or not _is_num(g.get("floors")) \
			or not _is_num(g.get("width")) or not (g.get("nodes") is Array) or (g["nodes"] as Array).is_empty():
		return "carte invalide"
	var ids: Dictionary = {}
	for n: Variant in g["nodes"]:
		if not (n is Dictionary) or not (n.get("id") is String) or not _is_num(n.get("floor")) or not _is_num(n.get("col")) \
				or not (n.get("room_type") is String) or not (n.get("next") is Array):
			return "salle de la carte invalide"
		if game.get_room_type(String(n["room_type"])).is_empty():
			return "type de salle inconnu : %s" % n["room_type"]
		ids[String(n["id"])] = true
	for n: Dictionary in g["nodes"]:
		for nx: Variant in n["next"]:
			if not (nx is String) or not ids.has(nx):
				return "liaison de la carte invalide"
	if not (act.get("current_node_id") is String) or not (act.get("visited") is Array):
		return "progression de carte invalide"
	var cur: String = String(act["current_node_id"])
	if not cur.is_empty() and not ids.has(cur):
		return "salle courante inconnue : %s" % cur
	for v: Variant in act["visited"]:
		if not (v is String) or not ids.has(v):
			return "salle visitée inconnue"
	return ""


static func _build_run(rd: Dictionary, game: GameData) -> RunState:
	var r := RunState.new()
	r._data = game
	r.player_id = String(rd["player_id"])
	r.display_name = String(rd["display_name"])
	for t: Variant in rd["type_ids"]:
		r.type_ids.append(String(t))
	r.sprite_path = String(rd["sprite_path"])
	r.max_hp = int(rd["max_hp"])
	r.hp = int(rd["hp"])
	r.energy_per_turn = int(rd["energy_per_turn"])
	r.hand_size = int(rd["hand_size"])
	r.bonus_hand_size = int(rd["bonus_hand_size"])
	r.bonus_energy = int(rd["bonus_energy"])
	for e: Dictionary in rd["deck"]:
		var card: CardData = game.get_card(String(e["id"]))
		if card.pokemon_id != String(e["pokemon"]):
			card = card.with_pokemon(String(e["pokemon"]))
		if bool(e["up"]):
			var up: CardData = card.upgraded_copy(game.get_upgrade_rules())
			if up != null:
				card = up
		r.deck.append(card)
	r.battles_won = int(rd["battles_won"])
	r.enemies_defeated = int(rd["enemies_defeated"])
	r.base_pokemon_id = String(rd["base_pokemon_id"])
	r.starter_pokemon_id = String(rd["starter_pokemon_id"])
	r.evolution_applied = bool(rd["evolution_applied"])
	r.evolved = bool(rd["evolved"])
	r.evolution_stage = int(rd["evolution_stage"])
	r.evolution_history.assign(rd["evolution_history"])
	r.team_progress = rd["team_progress"]
	for b: Variant in rd["evolved_badges"]:
		r._evolved_badges.append(int(b))
	r.money = int(rd["money"])
	for id: String in rd["items"]:
		r.items.append(game.get_item(id))
	for id: String in rd["potions"]:
		r.potions.append(game.get_potion(id))
	r.card_removals = int(rd["card_removals"])
	r.zones.assign(rd["zones"])
	r.zone_index = int(rd["zone_index"])
	var badges: Array = (rd["badges"] as Array).duplicate(true)
	for b: Dictionary in badges:
		b["color"] = game.get_type_color(String(b["type_id"]))
	r.badges.assign(badges)
	r._base_map_seed = int(String(rd["base_map_seed"]))
	r._floors_done = int(rd["floors_done"])
	r.league.assign(rd["league"])
	r.league_stage = int(rd["league_stage"])
	r.league_fights_won = int(rd["league_fights_won"])
	r.final_boss_defeated = bool(rd["final_boss_defeated"])
	# Pokémon lookup table: every base Pokémon + every form referenced by the save (evolved forms included).
	for pid: String in game.get_pokemon_ids():
		r._pokemon_infos[pid] = game.get_pokemon_info(pid)
	var wanted: Array[String] = [r.starter_pokemon_id, r.base_pokemon_id]
	for c: CardData in r.deck:
		wanted.append(c.pokemon_id)
	for k: Variant in r.team_progress.keys():
		wanted.append(String(k))
	for h: Dictionary in r.evolution_history:
		wanted.append(String(h.get("from_id", "")))
		wanted.append(String(h.get("to_id", "")))
	for pid: String in wanted:
		if not pid.is_empty() and not r._pokemon_infos.has(pid) and not game.get_pokemon_info(pid).is_empty():
			r._pokemon_infos[pid] = game.get_pokemon_info(pid)
	if rd["act"] != null:
		r.act = _build_act(rd["act"])
	return r


static func _build_act(a: Dictionary) -> ActProgress:
	var gd: Dictionary = a["graph"]
	var graph := MapGraph.new()
	graph.seed = int(String(gd["seed"]))
	graph.floors = int(gd["floors"])
	graph.width = int(gd["width"])
	for nd: Dictionary in gd["nodes"]:
		var n := MapNode.new()
		n.id = String(nd["id"])
		n.floor = int(nd["floor"])
		n.col = int(nd["col"])
		n.room_type = String(nd["room_type"])
		for nx: Variant in nd["next"]:
			n.next.append(String(nx))
		graph.nodes[n.id] = n
	var p := ActProgress.create(graph)
	p.current_node_id = String(a["current_node_id"])
	for v: Variant in a["visited"]:
		p.visited.append(String(v))
	return p


## Deep copy of a data tree with every float tagged {"#f": value} (see TREE_FIELDS).
static func _enc(v: Variant) -> Variant:
	if v is Dictionary:
		var out: Dictionary = {}
		for k: Variant in (v as Dictionary).keys():
			out[k] = _enc(v[k])
		return out
	if v is Array:
		var arr: Array = []
		for e: Variant in (v as Array):
			arr.append(_enc(e))
		return arr
	if v is float:
		return {FLOAT_TAG: v}
	return v


## Inverse of _enc after a JSON round trip: tagged values -> float, other whole numbers -> int (JSON parses all as float).
static func _dec(v: Variant) -> Variant:
	if v is Dictionary:
		var dv: Dictionary = v
		if dv.size() == 1 and dv.has(FLOAT_TAG) and _is_num(dv[FLOAT_TAG]):
			return float(dv[FLOAT_TAG])
		var out: Dictionary = {}
		for k: Variant in dv.keys():
			out[k] = _dec(dv[k])
		return out
	if v is Array:
		var arr: Array = []
		for e: Variant in (v as Array):
			arr.append(_dec(e))
		return arr
	if v is float and v == floorf(v) and absf(v) < 9.0e15:
		return int(v)
	return v


# --- RNG helpers (Main stores its generators with these) ------------------------------------------

## {"seed": "<int>", "state": "<int>"} (strings: 64-bit values do not survive a JSON number).
static func rng_to_dict(rng: RandomNumberGenerator) -> Dictionary:
	return {"seed": str(rng.seed), "state": str(rng.state)}


## Restores seed THEN state (setting the seed resets the state). False (rng untouched) if `d` is malformed.
static func rng_apply(rng: RandomNumberGenerator, d: Variant) -> bool:
	if not (d is Dictionary) or not String(d.get("seed", "x")).is_valid_int() or not String(d.get("state", "x")).is_valid_int():
		return false
	rng.seed = int(String(d["seed"]))
	rng.state = int(String(d["state"]))
	return true


# --- File access ---------------------------------------------------------------------------------

## True if a file exists at `path`.
static func exists(path: String) -> bool:
	return FileAccess.file_exists(path)


## Writes `dict` as JSON to `path` ATOMICALLY: temp file (path + ".tmp") then rename, so a crash never leaves a half file.
static func write(path: String, dict: Dictionary) -> bool:
	var tmp: String = path + TEMP_SUFFIX
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveGame: cannot write '%s' (error %d)" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(dict))
	f.flush()
	var write_error: Error = f.get_error()
	f.close()
	if write_error != OK:
		DirAccess.remove_absolute(tmp)
		return false
	var err: Error = DirAccess.rename_absolute(tmp, path)
	if err != OK:  # some platforms refuse to overwrite: drop the old file and retry
		DirAccess.remove_absolute(path)
		err = DirAccess.rename_absolute(tmp, path)
	if err != OK:
		DirAccess.remove_absolute(tmp)
		push_error("SaveGame: cannot move '%s' to '%s' (error %d)" % [tmp, path, err])
		return false
	return true


## Reads and parses `path`: {"ok", "missing": bool, "data": Variant, "error": String}.
static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "missing": true, "data": null, "error": "aucune sauvegarde"}
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {"ok": false, "missing": false, "data": null, "error": "fichier vide"}
	var json := JSON.new()
	if json.parse(text) != OK:
		return {"ok": false, "missing": false, "data": null, "error": "JSON invalide (fichier tronqué ou corrompu)"}
	return {"ok": true, "missing": false, "data": json.data, "error": ""}


## Reads + validates + rebuilds: from_dict's result plus "missing" (no file at all).
static func load_run(path: String, game: GameData) -> Dictionary:
	var rd: Dictionary = read(path)
	if not rd["ok"]:
		var res: Dictionary = _fail(String(rd["error"]))
		res["missing"] = rd["missing"]
		return res
	var result: Dictionary = from_dict(rd["data"], game)
	result["missing"] = false
	return result


## Deletes the save (and a stray temp file). True if nothing is left.
static func delete(path: String) -> bool:
	for p: String in [path, path + TEMP_SUFFIX]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	return not FileAccess.file_exists(path)


## Moves an unreadable save to path + ".bak" (replacing an older backup). True if the original is gone.
static func quarantine(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	var bak: String = path + BACKUP_SUFFIX
	if FileAccess.file_exists(bak):
		DirAccess.remove_absolute(bak)
	if DirAccess.rename_absolute(path, bak) != OK:
		DirAccess.remove_absolute(path)
	return not FileAccess.file_exists(path)
