"""Story 025: generate assets/data/pokedex_species.json — national dex number + generation of every Pokémon of
pokemon.json (player, enemies, evolutions) that is NOT in roster.json (the roster carries its own dex / generation).
Keyed by sprite slug (sprite file name without extension), the Pokédex species key. Stdlib only.

Usage: python3 tools/pokedex/generate_species.py <dir with PokeAPI pokemon.csv and pokemon_species.csv>
(https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/{pokemon,pokemon_species}.csv)
"""
import csv, json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "data", "pokedex_species.json")


def slug(path):
    return os.path.splitext(os.path.basename(path))[0]


def main():
    csv_dir = sys.argv[1]
    with open(os.path.join(csv_dir, "pokemon_species.csv"), encoding="utf-8", newline="") as f:
        species = {r["identifier"]: (int(r["id"]), int(r["generation_id"])) for r in csv.DictReader(f)}
    with open(os.path.join(csv_dir, "pokemon.csv"), encoding="utf-8", newline="") as f:
        forms = {}
        by_id = {v[0]: k for k, v in species.items()}
        for r in csv.DictReader(f):
            forms[r["identifier"]] = species[by_id[int(r["species_id"])]]
    with open(os.path.join(ROOT, "assets", "data", "pokemon.json"), encoding="utf-8") as f:
        pj = json.load(f)
    with open(os.path.join(ROOT, "assets", "data", "roster.json"), encoding="utf-8") as f:
        roster = json.load(f)["pokemon"]
    roster_slugs = {slug(v["sprite"]) for v in roster.values()}
    slugs = []
    for section in ("player", "enemies", "evolutions"):
        for v in pj[section].values():
            s = slug(v["sprite"])
            if s not in roster_slugs and s not in slugs:
                slugs.append(s)
    out = {}
    for s in slugs:
        hit = species.get(s) or forms.get(s)
        if hit is None:
            sys.exit("unknown species slug: %s" % s)
        out[s] = {"dex": hit[0], "generation": hit[1]}
    out = dict(sorted(out.items(), key=lambda kv: (kv[1]["dex"], kv[0])))
    doc = ("Story 025 (Pokédex) : numéro du Pokédex national (dex) et génération (1-9) de chaque Pokémon de pokemon.json "
           "(player, enemies, evolutions) absent de roster.json (le roster porte déjà dex / generation). Clé = slug du "
           "sprite (nom du fichier sans extension), la clé d'espèce du Pokédex. Généré par tools/pokedex/generate_species.py "
           "depuis les CSV PokéAPI ; NE PAS éditer à la main.")
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump({"_doc": doc, "species": out}, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("wrote %d species to %s" % (len(out), OUT))


if __name__ == "__main__":
    main()
