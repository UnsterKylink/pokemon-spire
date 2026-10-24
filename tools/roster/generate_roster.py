#!/usr/bin/env python3
"""Generate assets/data/roster.json (+ sprites) from the PokeAPI CSV dumps. Stdlib only.

Story 013b part A. Usage:
    python3 tools/roster/generate_roster.py [--no-sprites] [--offline]
CSVs are cached in tools/roster/.cache/csv (override: ROSTER_CACHE env var); once cached the
data generation is fully offline and deterministic. Sprites are downloaded to
assets/sprites/pokemon/<slug>.png only when missing/invalid. See README.md.
"""
import csv, json, os, struct, subprocess, sys, zlib
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
CACHE = os.environ.get("ROSTER_CACHE", os.path.join(HERE, ".cache"))
DATA = os.path.join(ROOT, "assets", "data")
SPRITE_DIR = os.path.join(ROOT, "assets", "sprites", "pokemon")
OUT = os.path.join(DATA, "roster.json")
CSV_URL = "https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/%s.csv"
SPRITE_URL = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/%d.png"
CSV_FILES = ["pokemon", "pokemon_species", "pokemon_species_names", "pokemon_types", "pokemon_stats"]
SPRITE_RES_PREFIX = "res://assets/sprites/pokemon/"
PARALLEL_DOWNLOADS = 4

# ---------------------------------------------------------------- selection rules (documented in README)
MAX_DEX = 1025                       # nothing above the National Dex 1025
EXCLUDE_LEGENDARY = True             # pokemon_species.is_legendary
EXCLUDE_MYTHICAL = True              # pokemon_species.is_mythical
EXCLUDE_BABY = True                  # pokemon_species.is_baby
# Species has only default forms in pokemon_species.csv: Mega / regional / Gigantamax forms are
# separate rows of pokemon.csv (is_default=0) and are never read -> base forms only.
SINGLE_STAGE_BST_MAX = 540           # lone species (no evolution) above this BST = paradox/ultra-beast-like, skipped
STAGE3_CAP = None                    # None = keep every line complete; int = max number of stage-3-only extras (by lowest dex)
LANG_FR = 5
TYPE_IDS = {1: "normal", 2: "fighting", 3: "flying", 4: "poison", 5: "ground", 6: "rock", 7: "bug", 8: "ghost",
            9: "steel", 10: "fire", 11: "water", 12: "grass", 13: "electric", 14: "psychic", 15: "ice",
            16: "dragon", 17: "dark", 18: "fairy"}

# ---------------------------------------------------------------- HP / behaviour formulas (constants)
# tier = stage for evolving lines; a lone species (stage 1 by definition) uses BST bands to get a tier.
LONE_TIER_BST = [(400, 1), (480, 2), (10 ** 9, 3)]           # (bst <=, tier)
HP_RANGE = {1: (28, 48), 2: (42, 66), 3: (55, 85)}           # max_hp range per tier
HP_STAT_RANGE = (30, 150)                                     # base HP stat normalised on this span
BST_RANGE = {1: (180, 400), 2: (300, 520), 3: (400, 680)}     # BST normalised per tier
HP_MIX = 0.5                                                  # weight of the HP stat vs BST in the HP score
ATK_STAT_RANGE = (30, 150)                                    # max(atk, spa)
DEF_STAT_RANGE = (30, 150)                                    # mean(def, spd)
SPD_STAT_RANGE = (30, 150)
ATTACK_RANGE = {1: (4, 8), 2: (6, 11), 3: (8, 13)}
BLOCK_RANGE = {1: (4, 7), 2: (5, 9), 3: (7, 11)}
BUFF_VALUE = {1: 1, 2: 1, 3: 2}
HEAVY_FACTOR = 1.4                                            # heavy attack = attack * this
OFFENSE_MARGIN = 0.15                                         # atk_n - def_n above -> glass cannon
DEFENSE_MARGIN = 0.15                                         # def_n - atk_n above -> tank
FAST_THRESHOLD = 0.6                                          # speed_n above -> fast pattern
CANDIDATE_START_MAX_BST = 330

# Status rule (story 016): a roster Pokemon whose type has a status (first matching type in order) inflicts it with
# probability STATUS_CHANCE_PCT % (stable hash of the slug) through its STRONGEST attack action: "status": {"id", "value"}.
# Ids come from assets/data/statuses.json.
STATUS_BY_TYPE = {"fire": "burn", "poison": "poison", "electric": "paralysis", "ice": "freeze",
                  "psychic": "sleep", "ghost": "sleep", "grass": "sleep"}
STATUS_CHANCE_PCT = 40
STATUS_VALUE = {"burn": {1: 2, 2: 3, 3: 4}, "poison": {1: 2, 2: 3, 3: 5},
                "paralysis": {1: 1, 2: 1, 3: 1}, "freeze": {1: 1, 2: 1, 3: 1}, "sleep": {1: 1, 2: 1, 3: 1}}

STAT_IDS = {1: "hp", 2: "atk", 3: "def", 4: "spa", 5: "spd", 6: "spe"}


def clamp01(x):
    return max(0.0, min(1.0, x))


def norm(v, rng):
    return clamp01((v - rng[0]) / float(rng[1] - rng[0]))


def lerp_int(rng, t):
    return int(round(rng[0] + (rng[1] - rng[0]) * t))


# ---------------------------------------------------------------- CSV cache
def csv_path(name):
    return os.path.join(CACHE, "csv", name + ".csv")


def ensure_csvs(offline):
    os.makedirs(os.path.join(CACHE, "csv"), exist_ok=True)
    for n in CSV_FILES:
        p = csv_path(n)
        if os.path.exists(p) and os.path.getsize(p) > 100:
            continue
        if offline:
            sys.exit("missing cached CSV %s (run once online)" % p)
        subprocess.run(["curl", "-sS", "--fail", "--retry", "4", "-o", p, CSV_URL % n], check=True)


def rows(name):
    with open(csv_path(name), encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


# ---------------------------------------------------------------- PNG helpers
def png_ok(path):
    """True if the file is a structurally valid PNG (signature, IHDR, IDAT, IEND, CRCs)."""
    try:
        data = open(path, "rb").read()
    except OSError:
        return False
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        return False
    pos, seen = 8, []
    while pos + 12 <= len(data):
        (ln,) = struct.unpack(">I", data[pos:pos + 4])
        typ = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + ln]
        crc = data[pos + 8 + ln:pos + 12 + ln]
        if len(body) != ln or len(crc) != 4 or struct.unpack(">I", crc)[0] != zlib.crc32(typ + body) & 0xFFFFFFFF:
            return False
        seen.append(typ)
        pos += 12 + ln
        if typ == b"IEND":
            break
    return bool(seen) and seen[0] == b"IHDR" and b"IDAT" in seen and seen[-1] == b"IEND"


def download_sprite(job):
    dex, dest = job
    tmp = dest + ".part"
    for _ in range(3):
        r = subprocess.run(["curl", "-sS", "--fail", "--retry", "3", "-o", tmp, SPRITE_URL % dex],
                           capture_output=True)
        if r.returncode == 0 and png_ok(tmp):
            os.replace(tmp, dest)
            return dex, True
    if os.path.exists(tmp):
        os.remove(tmp)
    return dex, False


# ---------------------------------------------------------------- existing data
def existing_slugs():
    """Species slugs already used by pokemon.json (enemies, evolutions, players) = never duplicated."""
    p = json.load(open(os.path.join(DATA, "pokemon.json"), encoding="utf-8"))
    ids = set(p.get("enemies", {})) | set(p.get("player", {})) | set(p.get("evolutions", {}))
    sprites = []
    for sec in ("enemies", "player"):
        sprites += [v.get("sprite", "") for v in p.get(sec, {}).values()]
    for k, v in p.get("evolutions", {}).items():
        ids.add(v["id"])
        sprites.append(v.get("sprite", ""))
    for s in sprites:
        if s:
            ids.add(os.path.basename(s)[:-4])
    return ids, p


def attack_cards_by_type():
    cards = json.load(open(os.path.join(DATA, "cards.json"), encoding="utf-8"))["cards"]
    by = {}
    for cid, c in cards.items():
        if c.get("kind") == "attack":
            by.setdefault(c["type"], {}).setdefault(c["rarity"], []).append(cid)
    return by


# ---------------------------------------------------------------- generation helpers
def h(s):
    """Small stable hash (no randomness, no PYTHONHASHSEED dependence)."""
    return zlib.crc32(s.encode("utf-8"))


def tier_for(stage, line_len, bst):
    if line_len > 1:
        return stage
    for lim, t in LONE_TIER_BST:
        if bst <= lim:
            return t
    return 3


def make_hp(st, tier, bst):
    hp_n = norm(st["hp"], HP_STAT_RANGE)
    bst_n = norm(bst, BST_RANGE[tier])
    return lerp_int(HP_RANGE[tier], HP_MIX * hp_n + (1 - HP_MIX) * bst_n)


def make_behaviour(slug, st, tier):
    atk_n = norm(max(st["atk"], st["spa"]), ATK_STAT_RANGE)
    def_n = norm((st["def"] + st["spd"]) / 2.0, DEF_STAT_RANGE)
    spe_n = norm(st["spe"], SPD_STAT_RANGE)
    a = lerp_int(ATTACK_RANGE[tier], atk_n)
    heavy = min(int(round(a * HEAVY_FACTOR)), ATTACK_RANGE[tier][1])
    b = lerp_int(BLOCK_RANGE[tier], def_n)
    buff = BUFF_VALUE[tier]
    A = lambda v: {"type": "attack", "value": v}
    B = lambda v: {"type": "block", "value": v}
    U = lambda v: {"type": "buff", "value": v}
    if atk_n - def_n > OFFENSE_MARGIN:                       # glass cannon
        pat, acts = "sequence", [A(a), A(a), A(heavy)] if h(slug) % 2 else [U(buff), A(a), A(heavy)]
    elif def_n - atk_n > DEFENSE_MARGIN:                     # tank
        pat = "weighted"
        acts = [dict(A(a), weight=3), dict(B(b), weight=2)]
        if tier >= 2:
            acts.append(dict(A(heavy), weight=1))
    elif spe_n > FAST_THRESHOLD:                             # fast
        pat, acts = "sequence", [A(a), U(buff), A(a), A(a)]
    elif tier == 1:                                          # balanced, weak
        pat, acts = "weighted", [dict(A(a), weight=4), dict(B(b), weight=1)]
    else:                                                    # balanced
        pat, acts = "sequence", [A(a), A(a), B(b)]
    return pat, acts


def add_status(slug, types, tier, acts):
    """Story 016: puts the type-based status (see STATUS_BY_TYPE) on the strongest attack action, in place."""
    sid = next((STATUS_BY_TYPE[t] for t in types if t in STATUS_BY_TYPE), None)
    if sid is None or h(slug + "status") % 100 >= STATUS_CHANCE_PCT:
        return acts
    attacks = [a for a in acts if a["type"] == "attack"]
    if attacks:
        best = max(attacks, key=lambda a: a["value"])
        best["status"] = {"id": sid, "value": STATUS_VALUE[sid][tier]}
    return acts


def add_attack_types(types, acts):
    """Story 019: a dual-typed Pokemon's STRONGEST attack action (highest value, the last one on ties) attacks with its
    SECONDARY type ("attack_type"); its other attacks keep the default (primary type, no field). A single attack, or a
    single-typed Pokemon, is left unchanged. In place; idempotent."""
    attacks = [a for a in acts if a["type"] == "attack"]
    for a in attacks:
        a.pop("attack_type", None)
    if len(types) < 2 or len(attacks) < 2:
        return acts
    best = attacks[0]
    for a in attacks:
        if a["value"] >= best["value"]:
            best = a
    best["attack_type"] = types[1]
    return acts


def pick(lst, key, i=0):
    return lst[(h(key) + i) % len(lst)]


def make_teaches(slug, types, tier, by):
    """1-2 existing attack cards; ALWAYS one of the primary type; a 2nd one of the secondary type if any."""
    order = {1: ["common", "uncommon", "rare", "starter"],
             2: ["uncommon", "common", "rare", "starter"],
             3: ["rare", "uncommon", "common", "starter"]}[tier]
    second = {1: ["common", "starter", "uncommon", "rare"],
              2: ["common", "uncommon", "starter", "rare"],
              3: ["uncommon", "common", "rare", "starter"]}[tier]

    def card(t, prefs, salt, exclude):
        for r in prefs:
            c = [x for x in by.get(t, {}).get(r, []) if x not in exclude]
            if c:
                return pick(c, slug + t + salt)
        return None

    first = card(types[0], order, "a", [])
    out = [first]
    t2 = types[1] if len(types) > 1 else types[0]
    s = card(t2, second, "b", out)
    if s is None and t2 != types[0]:
        s = card(types[0], second, "c", out)
    if s:
        out.append(s)
    return out


# ---------------------------------------------------------------- main
def build():
    sp = {int(r["id"]): r for r in rows("pokemon_species")}
    names = {int(r["pokemon_species_id"]): r["name"] for r in rows("pokemon_species_names")
             if r["local_language_id"] == str(LANG_FR)}
    ident = {}
    for r in rows("pokemon"):
        if r["is_default"] == "1":
            ident[int(r["species_id"])] = (r["identifier"], int(r["id"]))
    types, stats = {}, {}
    for r in rows("pokemon_types"):
        types.setdefault(int(r["pokemon_id"]), {})[int(r["slot"])] = TYPE_IDS[int(r["type_id"])]
    for r in rows("pokemon_stats"):
        stats.setdefault(int(r["pokemon_id"]), {})[STAT_IDS[int(r["stat_id"])]] = int(r["base_stat"])

    def kept_species(d):
        s = sp[d]
        if d > MAX_DEX: return False
        if EXCLUDE_LEGENDARY and s["is_legendary"] == "1": return False
        if EXCLUDE_MYTHICAL and s["is_mythical"] == "1": return False
        if EXCLUDE_BABY and s["is_baby"] == "1": return False
        return True

    kept = {d for d in sp if kept_species(d)}
    for d in kept:
        assert ident[d][1] == d, "default pokemon id != species id for %d" % d

    def parent(d):                       # nearest kept ancestor
        p = sp[d]["evolves_from_species_id"]
        while p:
            if int(p) in kept: return int(p)
            p = sp[int(p)]["evolves_from_species_id"]
        return None

    par = {d: parent(d) for d in kept}
    children = {}
    for d, p in par.items():
        if p: children.setdefault(p, []).append(d)

    def depth(d):
        n = 1
        while par[d]:
            d = par[d]; n += 1
        return n

    def root(d):
        while par[d]: d = par[d]
        return d

    chain_len = {}
    for d in kept:
        r = root(d)
        chain_len[r] = max(chain_len.get(r, 1), depth(d))
    # lone species too strong (paradox / ultra-beast-like) are skipped entirely
    def bst_of(d): return sum(stats[d].values())
    kept = {d for d in kept if not (chain_len[root(d)] == 1 and bst_of(d) > SINGLE_STAGE_BST_MAX)}

    have, _ = existing_slugs()
    by = attack_cards_by_type()
    out = {}
    for d in sorted(kept):
        slug = ident[d][0]
        if slug in have:
            continue
        st = stats[d]
        bst = sum(st.values())
        stage = depth(d)
        r = root(d)
        tier = tier_for(stage, chain_len[r], bst)
        ty = [types[d][k] for k in sorted(types[d])]
        pat, acts = make_behaviour(slug, st, tier)
        acts = add_status(slug, ty, tier, acts)
        acts = add_attack_types(ty, acts)
        nxt = min(children[d]) if d in children else None
        out[slug] = {
            "name": names[d], "dex": d, "generation": int(sp[d]["generation_id"]), "types": ty,
            "stage": stage, "line_id": ident[r][0], "evolves_to": ident[nxt][0] if nxt else None,
            "tier": tier, "bst": bst, "max_hp": make_hp(st, tier, bst),
            "pattern": pat, "actions": acts, "teaches": make_teaches(slug, ty, tier, by),
            "sprite": SPRITE_RES_PREFIX + slug + ".png",
            "roles": {"wild_ok": True, "carrier_ok": True,
                      "candidate_start": stage == 1 and bst <= CANDIDATE_START_MAX_BST},
        }
    if STAGE3_CAP is not None:
        extras = [k for k, v in out.items() if v["stage"] == 3 and v["line_id"] == k]  # never splits a line
        for k in extras[STAGE3_CAP:]: del out[k]
    return out


DOC = (
    "Roster Pokemon (story 013b, genere par tools/roster/generate_roster.py depuis les CSV PokeAPI ; NE PAS editer a la main, "
    "relancer l'outil). 'pokemon': slug anglais -> {name (FR), dex, generation 1-9, types [1-2 ids de types.json], "
    "stage 1|2|3 (rang dans la ligne d'evolution, hors bebes/legendaires), line_id (slug du stade 1 de la ligne ; les "
    "membres deja presents dans pokemon.json restent referencables par leur slug), evolves_to (slug de l'evolution suivante, "
    "branche de plus petit dex, null si aucune ; peut designer un Pokemon de pokemon.json), tier 1|2|3 (puissance utilisee "
    "pour les formules : = stage sauf especes sans evolution, rangees par BST), bst (total des stats de base), max_hp, "
    "pattern 'sequence'|'weighted' + actions [{type attack|block|buff, value, weight? (weighted), status? {id, value} (attaque seulement, statuses.json), attack_type? (story 019 : type de l'attaque, absent = 1er type ; l'attaque la plus forte d'un double type = 2e type)}] (meme format que "
    "pokemon.json enemies), teaches [1-2 ids de cartes d'attaque de cards.json ; le 1er est toujours du type primaire], "
    "sprite (res://assets/sprites/pokemon/<slug>.png, 96px), roles {wild_ok: peut apparaitre sauvage/elite/arene, "
    "carrier_ok: peut porter une carte de recompense, candidate_start: stade 1 avec BST <= 330, proposable au depart}}. "
    "Les ids ne collisionnent jamais avec pokemon.json (enemies/player/evolutions). Un objet du roster a le meme format "
    "qu'une entree de 'enemies' (name, types, max_hp, sprite, teaches, pattern, actions) + les champs supplementaires."
)


def main():
    offline = "--offline" in sys.argv
    ensure_csvs(offline)
    roster = build()
    os.makedirs(SPRITE_DIR, exist_ok=True)
    if "--no-sprites" not in sys.argv:
        jobs = []
        for slug, v in roster.items():
            dest = os.path.join(SPRITE_DIR, slug + ".png")
            if not (os.path.exists(dest) and png_ok(dest)):
                jobs.append((v["dex"], dest))
        print("sprites to download: %d" % len(jobs))
        if jobs:
            if offline: sys.exit("offline: cannot download sprites")
            with ThreadPoolExecutor(PARALLEL_DOWNLOADS) as ex:
                bad = [d for d, ok in ex.map(download_sprite, jobs) if not ok]
            if bad: sys.exit("failed sprites (dex): %s" % bad)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write('{\n\t"_doc": %s,\n\t"pokemon": {\n' % json.dumps(DOC, ensure_ascii=False))
        items = list(roster.items())
        for i, (k, v) in enumerate(items):
            f.write("\t\t%s: %s%s\n" % (json.dumps(k), json.dumps(v, ensure_ascii=False), "," if i < len(items) - 1 else ""))
        f.write("\t}\n}\n")
    print("wrote %s (%d pokemon)" % (OUT, len(roster)))


if __name__ == "__main__":
    main()
