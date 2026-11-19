class_name Pokedex
extends RefCounted
## Story 025 (story-025-pokedex): the player's persistent Pokédex — how many times each Pokémon species was SEEN and
## CAUGHT across every run, plus the milestones already announced. Stored in ONE json file (default user://pokedex.json,
## atomic write: temp file + rename); a missing or broken file gives an empty Pokédex. Pure data, same pattern as
## PlayerStats: Main records (mark_seen / mark_caught, then save) — the balance simulator and the headless tests never
## do unless they opt in (Main.qa_set_pokedex_path); the Pokédex screen only reads.
##
## Species key = the SLUG of the Pokémon's sprite (file name without extension, e.g. "charmander"): several data ids
## can share one species (player "salameche" and its sprite "charmander"; an evolution entry and a roster entry of the
## same Pokémon), so the slug is what the Pokédex counts. See PokedexCatalog for the full list (Total).
##
## What counts (Main's hooks):
## - seen: every enemy present at the start of a battle (+1 per battle), the starter of a new run, the Pokémon shown
##   in an event, the new form reached when one of your Pokémon evolves;
## - caught: every capture (story 017 balls, legendary capture, event « add_pokemon ») and the starter of a new run.
## A caught species always counts as seen.

const DEFAULT_PATH: String = "user://pokedex.json"
const TEMP_SUFFIX: String = ".tmp"
const KEY_SEEN: String = "seen"
const KEY_CAUGHT: String = "caught"
const KEY_MILESTONES: String = "milestones_claimed"

var path: String = DEFAULT_PATH
## slug -> times seen (> 0).
var seen: Dictionary = {}
## slug -> times caught (> 0).
var caught: Dictionary = {}
## Ids of the milestones (pokedex_rewards.json) already announced, in unlock order.
var milestones_claimed: Array[String] = []


## Species key of a sprite path ("res://assets/sprites/pokemon/charmander.png" -> "charmander"); "" for "".
static func slug_of(sprite_path: String) -> String:
	return sprite_path.get_file().get_basename()


## Loads the Pokédex stored at `dex_path` (empty when the file is missing, unreadable or malformed; bad rows skipped).
static func load_from(dex_path: String = DEFAULT_PATH) -> Pokedex:
	var p := Pokedex.new()
	p.path = dex_path
	if dex_path.is_empty() or not FileAccess.file_exists(dex_path):
		return p
	var f: FileAccess = FileAccess.open(dex_path, FileAccess.READ)
	if f == null:
		return p
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return p
	var d: Dictionary = parsed
	p.seen = _counts(d.get(KEY_SEEN, {}))
	p.caught = _counts(d.get(KEY_CAUGHT, {}))
	var ms: Variant = d.get(KEY_MILESTONES, [])
	if ms is Array:
		for m: Variant in (ms as Array):
			if m is String and not p.milestones_claimed.has(m):
				p.milestones_claimed.append(String(m))
	return p


static func _counts(v: Variant) -> Dictionary:
	var out: Dictionary = {}
	if not (v is Dictionary):
		return out
	for k: Variant in (v as Dictionary).keys():
		var n: Variant = (v as Dictionary)[k]
		if k is String and not String(k).is_empty() and (n is float or n is int) and int(n) > 0:
			out[String(k)] = int(n)
	return out


## Writes the Pokédex to `path` (temp file + rename). False on failure or without a path.
func save() -> bool:
	if path.is_empty():
		return false
	var tmp: String = path + TEMP_SUFFIX
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict(), " "))
	f.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path)) == OK


## The stored fields as a Dictionary.
func to_dict() -> Dictionary:
	return {KEY_SEEN: seen.duplicate(), KEY_CAUGHT: caught.duplicate(), KEY_MILESTONES: milestones_claimed.duplicate()}


## One more sighting of species `slug` (ignored for "").
func mark_seen(slug: String) -> void:
	if not slug.is_empty():
		seen[slug] = int(seen.get(slug, 0)) + 1


## One more capture of species `slug` (it also becomes seen if it never was). Ignored for "".
func mark_caught(slug: String) -> void:
	if slug.is_empty():
		return
	caught[slug] = int(caught.get(slug, 0)) + 1
	if not seen.has(slug):
		seen[slug] = 1


## True when species `slug` was seen (or caught) at least once.
func is_seen(slug: String) -> bool:
	return seen.has(slug) or caught.has(slug)


## True when species `slug` was caught at least once.
func is_caught(slug: String) -> bool:
	return caught.has(slug)


## Times species `slug` was seen.
func seen_count(slug: String) -> int:
	return maxi(int(seen.get(slug, 0)), 1 if caught.has(slug) else 0)


## Times species `slug` was caught.
func caught_count(slug: String) -> int:
	return int(caught.get(slug, 0))


## Number of distinct species seen; with `catalog` (slug list) only the species of that list count.
func seen_total(catalog: PackedStringArray = PackedStringArray()) -> int:
	if catalog.is_empty():
		var keys: Dictionary = seen.duplicate()
		keys.merge(caught)
		return keys.size()
	var n: int = 0
	for s: String in catalog:
		if is_seen(s):
			n += 1
	return n


## Number of distinct species caught; with `catalog` only the species of that list count.
func caught_total(catalog: PackedStringArray = PackedStringArray()) -> int:
	if catalog.is_empty():
		return caught.size()
	var n: int = 0
	for s: String in catalog:
		if caught.has(s):
			n += 1
	return n
