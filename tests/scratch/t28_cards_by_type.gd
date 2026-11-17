extends SceneTree
## Story 028 scratch: card pool by type. Card count 180-200, each type >= 8 cards incl. >= 2 skills (skills carry a
## theme `type`), > 50 % of cards do more than plain damage, descriptions non-empty, carriers exist and have the type.
var fails: int = 0

const TYPES: Array[String] = ["normal", "fire", "water", "grass", "electric", "ice", "fighting", "poison", "ground",
		"flying", "psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"]
## Effect keys that count as "plain" (a card with only these, non-zero, is a plain damage/block card).
const PLAIN_EFFECT_KEYS: Array[String] = ["damage", "block"]

func ok(c: bool, msg: String) -> void:
	if not c:
		fails += 1
		print("FAIL ", msg)


## True if the card only deals damage (no status, zone, heal, block, multi-hit, keyword, effect or condition).
func is_plain(c: CardData) -> bool:
	if c.kind != CardData.KIND_ATTACK:
		return false
	if not c.status_id.is_empty() or c.target_all or c.heal > 0 or c.block > 0 or c.hits > 1 or c.exhaust or c.retain:
		return false
	if c.damage_from_block > 0.0 or not c.conditionals.is_empty() or not c.on_draw.is_empty() or not c.end_of_turn_in_hand.is_empty():
		return false
	for k: Variant in c.effect.keys():
		if String(k) in PLAIN_EFFECT_KEYS:
			continue
		var v: Variant = c.effect[k]
		if (v is Array and not (v as Array).is_empty()) or ((v is int or v is float) and float(v) != 0.0) or (v is bool and v):
			return false
	return true


func _initialize() -> void:
	var gd := GameData.new()
	ok(gd.load_all(), "data loads")
	var root: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/cards.json"))
	var ids: Array = (root["cards"] as Dictionary).keys()
	ok(ids.size() >= 180 and ids.size() <= 200, "card count 180-200 (%d)" % ids.size())
	var per_type: Dictionary = {}
	var skills: Dictionary = {}
	var non_plain: int = 0
	for id: String in ids:
		if not gd.has_card(id):
			ok(false, "card '%s' loaded" % id)
			continue
		var c: CardData = gd.get_card(id)
		ok(not c.description.strip_edges().is_empty(), "%s has a description" % id)
		if not c.type_id.is_empty():
			per_type[c.type_id] = int(per_type.get(c.type_id, 0)) + 1
			if c.kind == CardData.KIND_SKILL:
				skills[c.type_id] = int(skills.get(c.type_id, 0)) + 1
		if not is_plain(c):
			non_plain += 1
		if not c.pokemon_id.is_empty():
			var info: Dictionary = gd.get_pokemon_info(c.pokemon_id)
			ok(not info.is_empty(), "%s: carrier '%s' exists" % [id, c.pokemon_id])
			if c.rarity != "starter":  # starter moves follow the starter (e.g. Griffe on Salamèche)
				ok(c.type_id in (info.get("types", []) as Array), "%s: carrier '%s' has type %s" % [id, c.pokemon_id, c.type_id])
	for t: String in TYPES:
		ok(int(per_type.get(t, 0)) >= 8, "type %s has >= 8 cards (%d)" % [t, int(per_type.get(t, 0))])
		ok(int(skills.get(t, 0)) >= 2, "type %s has >= 2 skills (%d)" % [t, int(skills.get(t, 0))])
	ok(non_plain * 2 > ids.size(), "> 50 %% non-plain cards (%d / %d)" % [non_plain, ids.size()])
	print("t28: %d cards, %d non-plain, per type %s, skills %s" % [ids.size(), non_plain, str(per_type), str(skills)])
	print("t28 done, fails=", fails)
	quit(1 if fails > 0 else 0)
