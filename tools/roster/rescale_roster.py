#!/usr/bin/env python3
"""Story 019 (balance): re-map the roster's max_hp / attack / block values from the ranges they were generated with
(story 013b: ORIGINAL_* below) to the CURRENT ranges of generate_roster.py (HP_RANGE, ATTACK_RANGE, BLOCK_RANGE), per
tier, WITHOUT the PokeAPI CSVs. Each value is placed at the same relative position t in its tier range
(v' = round(lo' + t * (hi' - lo'))), i.e. what generate_roster.lerp_int gives with the new ranges (heavy attacks were
capped at the range max and stay at the new max). Status values / attack types are untouched. Text-preserving.
NOT idempotent: always run it on a roster generated with ORIGINAL_* ranges, e.g.
    git show 9845d6b:assets/data/roster.json > /tmp/roster.orig.json
    python3 tools/roster/rescale_roster.py /tmp/roster.orig.json        # writes assets/data/roster.json
A full regeneration with generate_roster.py (current ranges) makes this script unnecessary."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import generate_roster as G
from add_statuses import patch_lines

ORIGINAL_HP_RANGE = {1: (28, 50), 2: (50, 80), 3: (80, 140)}
ORIGINAL_ATTACK_RANGE = {1: (5, 9), 2: (8, 14), 3: (12, 22)}
ORIGINAL_BLOCK_RANGE = {1: (4, 7), 2: (6, 11), 3: (9, 16)}


def remap(v, old, new):
    t = (v - old[0]) / float(old[1] - old[0])
    return max(1, int(round(new[0] + (new[1] - new[0]) * t)))


def fn(key, v):
    tier = int(v["tier"])
    v["max_hp"] = remap(v["max_hp"], ORIGINAL_HP_RANGE[tier], G.HP_RANGE[tier])
    for a in v["actions"]:
        if a["type"] == "attack":
            a["value"] = remap(a["value"], ORIGINAL_ATTACK_RANGE[tier], G.ATTACK_RANGE[tier])
        elif a["type"] == "block":
            a["value"] = remap(a["value"], ORIGINAL_BLOCK_RANGE[tier], G.BLOCK_RANGE[tier])
    return True


if __name__ == "__main__":
    src = sys.argv[1]
    open(G.OUT, "w", encoding="utf-8", newline="\n").write(open(src, encoding="utf-8").read())
    print("rescaled %d roster entries -> %s" % (patch_lines(G.OUT, fn), G.OUT))
