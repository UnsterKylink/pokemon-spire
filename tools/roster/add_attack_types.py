#!/usr/bin/env python3
"""Story 019: post-process assets/data/roster.json AND the hand-written enemies of pokemon.json to give the attacks of
dual-typed Pokemon their data type (action key "attack_type"), WITHOUT the PokeAPI CSVs. Same rule as
generate_roster.add_attack_types (strongest attack = secondary type), so regenerating gives the same result.
Idempotent, text-preserving (one entry per line). Usage: python3 tools/roster/add_attack_types.py"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import generate_roster as G
from add_statuses import patch_lines


def fn(key, v):
    before = json.dumps(v["actions"])
    G.add_attack_types(v["types"], v["actions"])
    return json.dumps(v["actions"]) != before


if __name__ == "__main__":
    r = os.path.join(G.DATA, "roster.json")
    print("roster lines rewritten:", patch_lines(r, fn))
    print("pokemon.json enemies rewritten:", patch_lines(os.path.join(G.DATA, "pokemon.json"), fn))
    cnt = sum(1 for v in json.load(open(r, encoding="utf-8"))["pokemon"].values()
              if any("attack_type" in a for a in v["actions"]))
    print("roster pokemon with a typed attack:", cnt)
