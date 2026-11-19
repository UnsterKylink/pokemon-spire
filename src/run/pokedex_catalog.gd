class_name PokedexCatalog
extends RefCounted
## Story 025 (story-025-pokedex): the list of Pokémon species the Pokédex shows — its « Total ».
##
## TOTAL DEFINITION: every distinct species the game data can put in front of the player = every Pokémon of
## pokemon.json (`player` starters, `enemies` — wild / elite / gym / league / rival / legendary / final boss —, and the
## evolved forms of `evolutions`) plus every Pokémon of roster.json (whose evolutions are roster or pokemon.json ids),
## merged by species (sprite slug, see Pokedex). 893 species with the current data (gen. 1-9; all have an official
## artwork). Dex number / generation: roster.json `dex` / `generation`, else assets/data/pokedex_species.json (generated
## by tools/pokedex/generate_species.py). Built once from GameData; read-only.

const DEFAULT_SPECIES_PATH: String = "res://assets/data/pokedex_species.json"
const GENERATION_COUNT: int = 9

## Entries sorted by dex number then slug: {slug, ids: Array[String], name, dex: int, generation: int,
## types: Array[String], sprite_path, teaches: Array[String] (card ids)}.
var entries: Array[Dictionary] = []
var _by_slug: Dictionary = {}


## Builds the catalog from `data` (+ the dex table at `species_path`). Species without a dex number are skipped with a
## push_error (the data is then inconsistent: rerun tools/pokedex/generate_species.py).
static func build(data: GameData, species_path: String = DEFAULT_SPECIES_PATH) -> PokedexCatalog:
	var c := PokedexCatalog.new()
	if data == null:
		return c
	var table: Dictionary = {}
	var f: FileAccess = FileAccess.open(species_path, FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if parsed is Dictionary and (parsed as Dictionary).get("species", null) is Dictionary:
			table = (parsed as Dictionary)["species"]
	var ids: Array[String] = data.get_pokemon_ids()  # players + enemies (incl. roster)
	ids.append_array(data.get_evolved_form_ids())
	for pid: String in ids:
		var info: Dictionary = data.get_pokemon_info(pid)
		if info.is_empty():
			continue
		var slug: String = Pokedex.slug_of(String(info["sprite_path"]))
		if slug.is_empty():
			continue
		var e: Dictionary = c._by_slug.get(slug, {})
		if e.is_empty():
			var dex: int = 0
			var gen: int = 0
			var roster: Dictionary = data.get_roster_entry(pid)
			if not roster.is_empty():
				dex = int(roster.get("dex", 0))
				gen = int(roster.get("generation", 0))
			elif table.get(slug, null) is Dictionary:
				dex = int((table[slug] as Dictionary).get("dex", 0))
				gen = int((table[slug] as Dictionary).get("generation", 0))
			var types: Array[String] = []
			types.assign(info["types"])
			e = {"slug": slug, "ids": [] as Array[String], "name": String(info["name"]), "dex": dex, "generation": gen,
					"types": types, "sprite_path": String(info["sprite_path"]), "teaches": [] as Array[String]}
			c._by_slug[slug] = e
		elif int(e["dex"]) == 0:
			var r2: Dictionary = data.get_roster_entry(pid)
			if not r2.is_empty():
				e["dex"] = int(r2.get("dex", 0))
				e["generation"] = int(r2.get("generation", 0))
		(e["ids"] as Array[String]).append(pid)
		for cid: String in data.get_pokemon_teach_ids(pid):
			if not (e["teaches"] as Array[String]).has(cid):
				(e["teaches"] as Array[String]).append(cid)
	for slug: String in c._by_slug.keys():
		var e: Dictionary = c._by_slug[slug]
		if int(e["dex"]) <= 0 or int(e["generation"]) < 1 or int(e["generation"]) > GENERATION_COUNT:
			push_error("PokedexCatalog: no dex number / generation for '%s'" % slug)
			c._by_slug.erase(slug)
			continue
		c.entries.append(e)
	c.entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["dex"]) < int(b["dex"]) or (int(a["dex"]) == int(b["dex"]) and String(a["slug"]) < String(b["slug"])))
	return c


## Number of species (the Pokédex « Total »).
func size() -> int:
	return entries.size()


## Entry of species `slug` ({} if not in the catalog).
func get_entry(slug: String) -> Dictionary:
	return _by_slug.get(slug, {})


## True when `slug` is a catalog species.
func has(slug: String) -> bool:
	return _by_slug.has(slug)


## Every slug, dex order.
func slugs() -> PackedStringArray:
	var out := PackedStringArray()
	for e: Dictionary in entries:
		out.append(String(e["slug"]))
	return out


## Entries of generation `generation` (1..9; 0 = all) with type `type_id` ("" = any), filtered by `status`
## ("all", "seen", "caught") against `dex` (null = no status filter). Dex order.
func filtered(generation: int, type_id: String, status: String, dex: Pokedex) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in entries:
		if generation > 0 and int(e["generation"]) != generation:
			continue
		if not type_id.is_empty() and not (e["types"] as Array[String]).has(type_id):
			continue
		if dex != null:
			if status == "seen" and not dex.is_seen(String(e["slug"])):
				continue
			if status == "caught" and not dex.is_caught(String(e["slug"])):
				continue
		out.append(e)
	return out
