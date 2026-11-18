#!/usr/bin/env python3
"""Story 030 (story-030-ennemis-et-boss): gives every roster.json Pokemon (and the gym / league enemies of pokemon.json,
enemy_templates.json pokemon_json_targets) ONE new enemy action matching its primary type, from the per-type templates of
tools/roster/enemy_templates.json. Deterministic (seed + slug), idempotent (a Pokemon that already has a status or a
story-030 action is left alone), keeps the damage budget roughly equal (no balancing: story 031).
Run AFTER generate_roster.py / add_statuses.py. Usage: python3 tools/roster/add_enemy_variety.py"""
import json, os, random, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "..", "..", "assets", "data")
T = json.load(open(os.path.join(HERE, "enemy_templates.json"), encoding="utf-8"))
OLD_TYPES = ("attack", "block", "buff")


def tier_of(v):
    if "tier" in v:
        return int(v["tier"])
    hp = int(v["max_hp"])  # pokemon.json enemies have no tier: rough tier from HP
    return 1 if hp < 45 else (2 if hp < 75 else 3)


def already_varied(acts):
    return any(a["type"] not in OLD_TYPES or "status" in a or a.get("hits", 1) > 1 for a in acts)


def attacks(acts):
    return [a for a in acts if a["type"] == "attack"]


def utility_slot(acts):
    """Index of the action a utility replaces: first block, else first buff, else the weakest of 2+ attacks."""
    for kind in ("block", "buff"):
        for i, a in enumerate(acts):
            if a["type"] == kind:
                return i
    atk = attacks(acts)
    if len(atk) >= 2:
        weakest = min(atk, key=lambda a: a["value"])
        return acts.index(weakest)
    return -1


def apply(opt, acts, tier):
    """Applies one template option in place; False if it does not fit."""
    op = opt["op"]
    if op == "utility":
        i = utility_slot(acts)
        if i < 0:
            return False
        old = acts[i]
        base = old["value"] if old["type"] == "block" else (
            old["value"] if old["type"] == "attack" else T["buff_base_per_tier"] * tier + T["buff_base_flat"])
        new = {"type": opt["type"]}
        if opt["type"] == "status":
            new["status"] = {"id": opt["status"], "value": opt["value"][str(tier)]}
        elif "value" in opt:
            new["value"] = opt["value"][str(tier)]
        else:
            new["value"] = max(1, round(base * opt["factor"]))
        if "weight" in old:
            new["weight"] = old["weight"]
        acts[i] = new
        return True
    atk = attacks(acts)
    if not atk:
        return False
    if op == "rider":
        a = max(atk, key=lambda a: a["value"])
        a["value"] = max(1, round(a["value"] * opt["damage_pct"] / 100))
        a["status"] = {"id": opt["status"], "value": opt["value"][str(tier)]}
        return True
    if op == "hits":
        a = max(atk, key=lambda a: a["value"])
        if a["value"] < opt["hits"] * 2:
            return False
        a["value"] = max(1, round(a["value"] / opt["hits"]))
        a["hits"] = opt["hits"]
        return True
    if op == "charge":
        if len(atk) < 2:
            return False
        a = min(atk, key=lambda a: a["value"])
        i = acts.index(a)
        new = {"type": "charge", "value": max(1, round(a["value"] * opt["factor"]))}
        for k in ("attack_type", "weight"):
            if k in a:
                new[k] = a[k]
        acts[i] = new
        return True
    raise ValueError("unknown op %s" % op)


def vary(slug, v):
    if already_varied(v["actions"]):
        return False
    opts = T["options"].get(v["types"][0], [])
    if not opts:
        return False
    rng = random.Random("%d:%s" % (T["seed"], slug))
    start = rng.randrange(len(opts))
    tier = min(3, max(1, tier_of(v)))
    for k in range(len(opts)):
        acts = json.loads(json.dumps(v["actions"]))
        if apply(opts[(start + k) % len(opts)], acts, tier) and any(a["type"] == "attack" for a in acts):
            v["actions"] = acts
            return True
    return False


def patch_lines(path, fn):
    """Rewrites the one-line entries `\\t\\t"slug": {...}` that hold actions (same layout as the other roster tools)."""
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


if __name__ == "__main__":
    targets = set(T["pokemon_json_targets"])
    print("roster.json Pokemon varied:", patch_lines(os.path.join(DATA, "roster.json"), vary))
    print("pokemon.json enemies varied:", patch_lines(os.path.join(DATA, "pokemon.json"),
                                                       lambda k, v: k in targets and not v.get("boss") and vary(k, v)))
    sys.exit(0)
