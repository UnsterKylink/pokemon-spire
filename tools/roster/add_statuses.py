#!/usr/bin/env python3
"""Story 016: post-process assets/data/roster.json (and the hand-written enemies of pokemon.json) to add the
status rule WITHOUT the PokeAPI CSVs. Same rule as generate_roster.add_status, so regenerating gives the same
result. Idempotent. Usage: python3 tools/roster/add_statuses.py"""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import generate_roster as G

# Hand-written enemies of pokemon.json: slug -> (status id, value) on their strongest attack.
HAND = {"weedle": ("poison", 2), "zubat": ("poison", 2), "oddish": ("sleep", 1), "pikachu": ("paralysis", 1),
        "cyndaquil": ("burn", 2), "haunter": ("sleep", 1), "gengar": ("sleep", 1), "glaceon": ("freeze", 1),
        "muk": ("poison", 4), "arcanine": ("burn", 3), "electabuzz": ("paralysis", 1), "venusaur": ("poison", 3)}


def strongest(acts):
    return max((a for a in acts if a["type"] == "attack"), key=lambda a: a["value"])


def patch_lines(path, fn):
    out, n = [], 0
    for line in open(path, encoding="utf-8").read().split("\n"):
        m = re.match(r'^(\t\t)("[^"]+"): (\{.*\})(,?)$', line)
        if m:
            key = json.loads(m.group(2))
            v = json.loads(m.group(3))
            if isinstance(v, dict) and "actions" in v and fn(key, v):
                line = "%s%s: %s%s" % (m.group(1), m.group(2), json.dumps(v, ensure_ascii=False), m.group(4))
                n += 1
        out.append(line)
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(out))
    return n


def roster_fn(key, v):
    for a in v["actions"]:
        a.pop("status", None)
    G.add_status(key, v["types"], v["tier"], v["actions"])
    return True


def hand_fn(key, v):
    if key not in HAND:
        return False
    sid, val = HAND[key]
    strongest(v["actions"])["status"] = {"id": sid, "value": val}
    return True


if __name__ == "__main__":
    r = os.path.join(G.DATA, "roster.json")
    print("roster lines rewritten:", patch_lines(r, roster_fn))
    p = os.path.join(G.DATA, "pokemon.json")
    # only the "enemies" section holds these slugs as top-level entries with actions
    print("pokemon.json enemies patched:", patch_lines(p, hand_fn))
    cnt = sum(1 for v in json.load(open(r, encoding="utf-8"))["pokemon"].values()
              if any("status" in a for a in v["actions"]))
    print("roster pokemon with a status:", cnt)
