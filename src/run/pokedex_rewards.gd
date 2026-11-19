class_name PokedexRewards
extends RefCounted
## Story 025 (story-025-pokedex): the permanent Pokédex milestones of assets/data/pokedex_rewards.json (see its _doc):
## a milestone is UNLOCKED once the number of distinct species caught reaches its `caught` threshold; every unlocked
## milestone applies its generic effects to each NEW run (apply_to_run, called by Main right after the RunState is
## created; never by the balance simulator). Data only, no Pokémon-specific code.

const DEFAULT_PATH: String = "res://assets/data/pokedex_rewards.json"
const EFFECT_ADD_BALL: String = "add_ball"
const EFFECT_GAIN_MONEY: String = "gain_money"
const EFFECT_GAIN_MAX_HP: String = "gain_max_hp"
const EFFECT_EXTRA_STARTERS: String = "extra_starter_choices"
const EFFECT_UPGRADE_STARTER_CARD: String = "upgrade_starter_card"
const KNOWN_EFFECTS: Array[String] = [EFFECT_ADD_BALL, EFFECT_GAIN_MONEY, EFFECT_GAIN_MAX_HP, EFFECT_EXTRA_STARTERS,
		EFFECT_UPGRADE_STARTER_CARD]

## Milestones sorted by threshold: {id, caught: int, name, description, effects: Array}.
var milestones: Array[Dictionary] = []
var starter_choices_max: int = 3
var banner_seconds: float = 4.0


## Loads and validates the milestones at `path` (bad entries skipped with push_error; missing file = no milestone).
static func load_from(path: String = DEFAULT_PATH) -> PokedexRewards:
	var r := PokedexRewards.new()
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("PokedexRewards: missing %s" % path)
		return r
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		push_error("PokedexRewards: %s is not a JSON object" % path)
		return r
	var root: Dictionary = parsed
	r.starter_choices_max = maxi(1, int(root.get("starter_choices_max", 3)))
	r.banner_seconds = maxf(0.5, float(root.get("banner_seconds", 4.0)))
	var seen_ids: Dictionary = {}
	for m_v: Variant in (root.get("milestones", []) as Array):
		if not (m_v is Dictionary):
			continue
		var m: Dictionary = m_v
		var id: String = String(m.get("id", ""))
		var threshold: int = int(m.get("caught", 0))
		var effects: Variant = m.get("effects", [])
		var ok: bool = not id.is_empty() and not seen_ids.has(id) and threshold >= 1 and effects is Array
		if ok:
			for e_v: Variant in (effects as Array):
				if not (e_v is Dictionary) or not KNOWN_EFFECTS.has(String((e_v as Dictionary).get("type", ""))):
					ok = false
		if not ok:
			push_error("PokedexRewards: invalid milestone '%s'" % id)
			continue
		seen_ids[id] = true
		r.milestones.append({"id": id, "caught": threshold, "name": String(m.get("name", id)),
				"description": String(m.get("description", "")), "effects": (effects as Array).duplicate(true)})
	r.milestones.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["caught"]) < int(b["caught"]))
	return r


## Milestones unlocked with `caught_species` distinct species caught (threshold order).
func unlocked(caught_species: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for m: Dictionary in milestones:
		if caught_species >= int(m["caught"]):
			out.append(m)
	return out


## Unlocked milestones whose id is not in `claimed` (to announce), threshold order.
func newly_unlocked(caught_species: int, claimed: Array[String]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for m: Dictionary in unlocked(caught_species):
		if not claimed.has(String(m["id"])):
			out.append(m)
	return out


## Number of starters to propose: `base` + every unlocked extra_starter_choices, capped by starter_choices_max
## (never below `base`).
func starter_choice_count(base: int, caught_species: int) -> int:
	var n: int = base
	for m: Dictionary in unlocked(caught_species):
		for e: Dictionary in m["effects"]:
			if String(e.get("type", "")) == EFFECT_EXTRA_STARTERS:
				n += maxi(0, int(e.get("count", 1)))
	return maxi(base, mini(n, starter_choices_max))


## Applies every unlocked milestone's run-start effects to the NEW run `run` (balls, money, max HP, starter card
## upgrade; extra_starter_choices is read by Main before the run exists). Returns the applied milestone names.
func apply_to_run(run: RunState, caught_species: int) -> Array[String]:
	var names: Array[String] = []
	if run == null:
		return names
	for m: Dictionary in unlocked(caught_species):
		var applied: bool = false
		for e: Dictionary in m["effects"]:
			match String(e.get("type", "")):
				EFFECT_ADD_BALL:
					for i: int in maxi(1, int(e.get("count", 1))):
						applied = run.add_ball(String(e.get("ball", ""))) or applied
				EFFECT_GAIN_MONEY:
					run.add_money(maxi(0, int(e.get("value", 0))))
					applied = true
				EFFECT_GAIN_MAX_HP:
					run.gain_max_hp(maxi(0, int(e.get("value", 0))))
					applied = true
				EFFECT_UPGRADE_STARTER_CARD:
					for i: int in maxi(1, int(e.get("count", 1))):
						var idx: int = run.best_upgradable_index(run.starter_pokemon_id)
						if idx >= 0 and run.upgrade_card(idx):
							applied = true
		if applied:
			names.append(String(m["name"]))
	return names
