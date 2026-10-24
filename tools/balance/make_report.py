#!/usr/bin/env python3
"""Merges simulator shards (tools/balance/simulate.gd JSON) and writes design/balance/report-<tag>.md + a stdout summary.

Usage: python3 tools/balance/make_report.py --tag=baseline [--note="text"] shard1.json shard2.json ...
Pure observation: the script computes statistics, it never judges (no pass/fail).
"""
import json, math, subprocess, sys, os
from collections import Counter, defaultdict

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
STAGES = ([f"zone{z}_{r}" for z in range(1, 9) for r in ("wild", "elite", "boss")]
          + [f"league_member_{i}" for i in range(1, 5)] + ["league_champion", "league_eternatus", "victory"])


def wilson(k, n, z=1.96):
    if n == 0:
        return (0.0, 0.0)
    p = k / n
    d = 1 + z * z / n
    c = p + z * z / (2 * n)
    m = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n))
    return ((c - m) / d, (c + m) / d)


def load(paths):
    runs = []
    for p in paths:
        with open(p) as f:
            runs += json.load(f)["runs"]
    runs.sort(key=lambda r: r["i"])
    return runs


def summarize(runs):
    n = len(runs)
    wins = sum(1 for r in runs if r["won"])
    lo, hi = wilson(wins, n)
    s = {"games": n, "wins": wins, "win_rate": wins / n if n else 0.0, "ci95": [lo, hi]}
    s["deaths_by_stage"] = {st: sum(1 for r in runs if r["stage"] == st) for st in STAGES}
    other = Counter(r["stage"] for r in runs if r["stage"] not in STAGES)
    if other:
        s["deaths_by_stage_other"] = dict(other)
    # funnel: runs that cleared zone k (>= k badges), reached the league, cleared members...
    s["badges_hist"] = {k: sum(1 for r in runs if r["badges"] == k) for k in range(9)}
    # HP lost per zone averaged over the runs that ENTERED the zone
    entered = [sum(1 for r in runs if r["badges"] >= z) for z in range(9)]  # zone index z entered if badges >= z (z=8: league)
    hp = [sum(r["hp_lost_by_zone"][z] for r in runs) for z in range(9)]
    s["entered"] = entered
    s["avg_hp_lost_by_zone"] = [hp[z] / entered[z] if entered[z] else 0.0 for z in range(9)]
    s["avg_deck_size"] = sum(r["deck_size"] for r in runs) / n
    s["avg_deck_size_won"] = (sum(r["deck_size"] for r in runs if r["won"]) / wins) if wins else None
    s["avg_potions_used"] = sum(r["potions_used"] for r in runs) / n
    s["avg_potions_bought"] = sum(r["potions_bought"] for r in runs) / n
    s["avg_items"] = sum(r["items"] for r in runs) / n
    s["avg_fights"] = sum(r["fights"] for r in runs) / n
    s["avg_badges"] = sum(r["badges"] for r in runs) / n
    fights = Counter()
    deaths = Counter()
    for r in runs:
        for k, v in r["fights_by_room"].items():
            fights[k] += v
        if not r["won"] and r["room"]:
            deaths[r["room"]] += 1
    s["room_fights"] = dict(fights)
    s["room_deaths"] = dict(deaths)
    by_type = defaultdict(lambda: [0, 0])
    by_id = defaultdict(lambda: [0, 0])
    for r in runs:
        by_type[r["starter_type"]][0] += 1
        by_type[r["starter_type"]][1] += 1 if r["won"] else 0
        by_id[r["starter"]][0] += 1
        by_id[r["starter"]][1] += 1 if r["won"] else 0
    s["starter_types"] = dict(by_type)
    s["starters"] = dict(by_id)
    kill = Counter()
    for r in runs:
        for k in set(r["killers"]):
            kill[k] += 1
    s["top_killers"] = kill.most_common(15)
    enc = Counter(r["encounter"] for r in runs if not r["won"])
    s["top_death_encounters"] = enc.most_common(10)
    s["stalled"] = sum(1 for r in runs if r["stalled"])
    s["illegal_moves"] = sum(r["illegal"] for r in runs)
    return s


def pct(a, b):
    return f"{100.0 * a / b:.1f} %" if b else "-"


def render(s, tag, note):
    n = s["games"]
    L = []
    L.append(f"# Rapport d'équilibrage — {tag}\n")
    try:
        head = subprocess.run(["git", "-C", ROOT, "rev-parse", "--short", "HEAD"], capture_output=True, text=True).stdout.strip()
        dirty = subprocess.run(["git", "-C", ROOT, "status", "--porcelain", "assets/data"], capture_output=True, text=True).stdout.strip()
    except Exception:
        head, dirty = "?", ""
    if os.environ.get("REPORT_COMMIT"):
        head, dirty = os.environ["REPORT_COMMIT"], ""
    L.append(f"Parties simulées : **{n}** (commit {head}{', données modifiées non commitées' if dirty else ''}). {note}\n")
    L.append("## Résultat\n")
    L.append(f"- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **{s['wins']} / {n} = {100*s['win_rate']:.1f} %** "
             f"(IC 95 % Wilson : {100*s['ci95'][0]:.1f} – {100*s['ci95'][1]:.1f} %)")
    L.append("- Objectif joueur : environ 35 % des parties complètes gagnées.\n")
    L.append("## Où les parties se terminent (distribution des défaites)\n")
    L.append("| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |\n|---|---:|---:|---:|")
    reached = n
    for st in STAGES:
        c = s["deaths_by_stage"][st]
        if st == "victory":
            L.append(f"| **Victoire** | {c} | {pct(c, n)} | - |")
            continue
        L.append(f"| {st} | {c} | {pct(c, n)} | {pct(c, reached)} |")
        reached -= c
    L.append("")
    L.append("Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. "
             "« % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).\n")
    L.append("### Entonnoir (badges obtenus)\n")
    L.append("| Badges | Parties |\n|---:|---:|")
    for k in range(9):
        L.append(f"| {k} | {s['badges_hist'][str(k)] if str(k) in s['badges_hist'] else s['badges_hist'][k]} |")
    L.append("")
    L.append("## PV perdus par zone (moyenne sur les parties qui y entrent)\n")
    L.append("| Zone | Parties entrées | PV perdus / partie |\n|---|---:|---:|")
    for z in range(9):
        name = f"Zone {z+1}" if z < 8 else "Ligue"
        L.append(f"| {name} | {s['entered'][z]} | {s['avg_hp_lost_by_zone'][z]:.1f} |")
    L.append("")
    L.append("## Moyennes par partie\n")
    L.append(f"- Combats : {s['avg_fights']:.1f}; badges : {s['avg_badges']:.2f}")
    L.append(f"- Taille du deck en fin de partie : {s['avg_deck_size']:.1f}" + (f" (parties gagnées : {s['avg_deck_size_won']:.1f})" if s['avg_deck_size_won'] else ""))
    L.append(f"- Potions utilisées : {s['avg_potions_used']:.2f}; potions achetées : {s['avg_potions_bought']:.2f}; objets tenus : {s['avg_items']:.2f}\n")
    L.append("## Taux de défaite par type de salle\n")
    L.append("| Salle | Combats | Défaites | Défaite / combat |\n|---|---:|---:|---:|")
    for k in sorted(s["room_fights"]):
        d = s["room_deaths"].get(k, 0)
        L.append(f"| {k} | {s['room_fights'][k]} | {d} | {pct(d, s['room_fights'][k])} |")
    L.append("")
    L.append("## Type du starter vs victoire\n")
    L.append("| Type | Parties | Victoires | Taux |\n|---|---:|---:|---:|")
    for t, (g, w) in sorted(s["starter_types"].items(), key=lambda kv: -kv[1][0]):
        L.append(f"| {t} | {g} | {w} | {pct(w, g)} |")
    L.append("")
    L.append("## Principaux tueurs (ennemis encore en vie à la défaite)\n")
    L.append("| Ennemi | Parties terminées par lui |\n|---|---:|")
    for k, c in s["top_killers"]:
        L.append(f"| {k} | {c} |")
    L.append("")
    L.append("Rencontres où l'on meurt le plus : " + ", ".join(f"`{k}` ({c})" for k, c in s["top_death_encounters"]) + "\n")
    L.append(f"Contrôles : combats bloqués (plafond de tours) = {s['stalled']}; actions refusées par le jeu = {s['illegal_moves']}.\n")
    # policy description
    src = open(os.path.join(ROOT, "tools/balance/sim_policy.gd"), encoding="utf-8").read()
    doc = [ln[3:] for ln in src.splitlines() if ln.startswith("## ")]
    a = src.index("const DEFAULTS")
    b = src.index("\n}\n", a) + 2
    L.append("## Joueur automatique (« correct, pas expert »)\n")
    L.append("\n".join(doc) + "\n")
    L.append("Paramètres (`tools/balance/sim_policy.gd`, surchargeables par `--policy=fichier.json`) :\n")
    L.append("```gdscript\n" + src[a:b] + "\n```\n")
    return "\n".join(L)


def main():
    tag, note, paths = "baseline", "", []
    for a in sys.argv[1:]:
        if a.startswith("--tag="):
            tag = a[6:]
        elif a.startswith("--note="):
            note = a[7:]
        else:
            paths.append(a)
    runs = load(paths)
    s = summarize(runs)
    md = render(s, tag, note)
    out = os.path.join(ROOT, "design", "balance", f"report-{tag}.md")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        f.write(md)
    print(f"games={s['games']} wins={s['wins']} win_rate={100*s['win_rate']:.1f}% CI95=[{100*s['ci95'][0]:.1f},{100*s['ci95'][1]:.1f}]")
    print("deaths:", {k: v for k, v in s["deaths_by_stage"].items() if v})
    print("avg badges %.2f, avg deck %.1f, avg fights %.1f, potions used %.2f" % (s["avg_badges"], s["avg_deck_size"], s["avg_fights"], s["avg_potions_used"]))
    print("top killers:", s["top_killers"][:8])
    print("report:", out)
    with open(os.path.splitext(out)[0] + ".json", "w") as f:
        json.dump(s, f, indent=1)


if __name__ == "__main__":
    main()
