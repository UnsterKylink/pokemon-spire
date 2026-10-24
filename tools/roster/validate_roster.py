#!/usr/bin/env python3
"""Validate assets/data/roster.json (story 013b). Exit 0 = OK, 1 = errors. Stdlib only."""
import collections, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import generate_roster as G

MIN_PER_TYPE = 15
ROOT, DATA = G.ROOT, G.DATA


def main():
    err = []
    def bad(m): err.append(m)
    load = lambda n: json.load(open(os.path.join(DATA, n), encoding="utf-8"))
    roster = load("roster.json")
    types = set(load("types.json")["types"])
    cards = load("cards.json")["cards"]
    poke = load("pokemon.json")
    taken, _ = G.existing_slugs()
    taken |= set(poke["enemies"]) | set(poke.get("player", {}))
    if not isinstance(roster.get("_doc"), str) or not roster["_doc"]: bad("missing _doc")
    r = roster.get("pokemon", {})
    keys = {"name", "dex", "generation", "types", "stage", "line_id", "evolves_to", "tier", "bst", "max_hp",
            "pattern", "actions", "teaches", "sprite", "roles"}
    per_type, per_stage, per_gen = collections.Counter(), collections.Counter(), collections.Counter()
    dexes = set()
    for pid, v in r.items():
        w = "[%s] " % pid
        if pid in taken: bad(w + "id collides with pokemon.json")
        if set(v) != keys: bad(w + "keys differ: %s" % sorted(set(v) ^ keys)); continue
        if not (isinstance(v["name"], str) and v["name"]): bad(w + "name")
        if not (isinstance(v["dex"], int) and 1 <= v["dex"] <= 1025) or v["dex"] in dexes: bad(w + "dex invalid/duplicate")
        dexes.add(v["dex"])
        if v["generation"] not in range(1, 10): bad(w + "generation")
        if not (1 <= len(v["types"]) <= 2) or len(set(v["types"])) != len(v["types"]) or not set(v["types"]) <= types:
            bad(w + "types %s" % v["types"])
        if v["stage"] not in (1, 2, 3) or v["tier"] not in (1, 2, 3): bad(w + "stage/tier")
        if v["line_id"] not in r and v["line_id"] not in taken: bad(w + "line_id unknown %s" % v["line_id"])
        if v["evolves_to"] is not None and v["evolves_to"] not in r and v["evolves_to"] not in taken:
            bad(w + "evolves_to unknown %s" % v["evolves_to"])
        if v["stage"] == 1 and v["line_id"] != pid and v["line_id"] not in taken: bad(w + "stage 1 line_id")
        if not (isinstance(v["max_hp"], int) and 28 <= v["max_hp"] <= 140): bad(w + "max_hp %s" % v["max_hp"])
        if v["pattern"] not in ("sequence", "weighted"): bad(w + "pattern")
        acts = v["actions"]
        if not (2 <= len(acts) <= 4): bad(w + "actions count %d" % len(acts))
        for a in acts:
            if a.get("type") not in ("attack", "block", "buff") or not (isinstance(a.get("value"), int) and a["value"] > 0):
                bad(w + "action %s" % a)
            if v["pattern"] == "weighted" and not (isinstance(a.get("weight"), int) and a["weight"] > 0): bad(w + "weight")
            if v["pattern"] == "sequence" and "weight" in a: bad(w + "weight in sequence")
        if not any(a["type"] == "attack" for a in acts): bad(w + "no attack action")
        if v["sprite"] != G.SPRITE_RES_PREFIX + pid + ".png": bad(w + "sprite path")
        sp = os.path.join(G.SPRITE_DIR, pid + ".png")
        if not (os.path.exists(sp) and G.png_ok(sp)): bad(w + "sprite missing/invalid PNG")
        elif not os.path.exists(sp + ".import"): print("note: no .import yet for", pid) if "--strict-import" in sys.argv else None
        t = v["teaches"]
        if not (1 <= len(t) <= 2) or len(set(t)) != len(t): bad(w + "teaches count")
        for c in t:
            cd = cards.get(c)
            if cd is None or cd["kind"] != "attack": bad(w + "teaches %s not an attack card" % c)
            elif cd["type"] not in v["types"]: bad(w + "teaches %s type %s not in %s" % (c, cd["type"], v["types"]))
        if t and cards.get(t[0], {}).get("type") != v["types"][0]: bad(w + "teaches[0] not of primary type")
        ro = v["roles"]
        if set(ro) != {"wild_ok", "carrier_ok", "candidate_start"} or not all(isinstance(x, bool) for x in ro.values()):
            bad(w + "roles")
        for x in v["types"]: per_type[x] += 1
        per_stage[v["stage"]] += 1; per_gen[v["generation"]] += 1
    for t in sorted(types):
        if per_type[t] < MIN_PER_TYPE: bad("type %s has %d < %d pokemon" % (t, per_type[t], MIN_PER_TYPE))
    for t in sorted(types):
        by = collections.defaultdict(list)
        for c in cards.values():
            if c["kind"] == "attack" and c["type"] == t and c["rarity"] != "starter": by[c["rarity"]].append(c)
        if not any(c["cost"] == 1 for c in by["common"]) or not by["uncommon"] or len(sum(by.values(), [])) < 3:
            bad("type %s lacks card coverage (common cost1 / uncommon / >=3)" % t)
    print("roster: %d pokemon" % len(r))
    print("per type :", dict(sorted(per_type.items())))
    print("per stage:", dict(sorted(per_stage.items())))
    print("per gen  :", dict(sorted(per_gen.items())))
    for e in err[:60]: print("ERROR", e)
    print("%d error(s)" % len(err))
    return 1 if err else 0


if __name__ == "__main__":
    sys.exit(main())
