#!/usr/bin/env python3
"""Append the cards of new_cards.json to assets/data/cards.json TEXTUALLY (idempotent).

Keeps the existing file byte-for-byte and inserts one line per missing card before the
closing of the "cards" object, in the same one-line format as the existing cards.
"""
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
CARDS = os.path.join(ROOT, "assets", "data", "cards.json")

def main():
    text = open(CARDS, encoding="utf-8").read()
    have = json.loads(text)["cards"]
    new = json.load(open(os.path.join(HERE, "new_cards.json"), encoding="utf-8"))["cards"]
    lines = []
    for cid, name, cost, rarity, typ, dmg, carrier in new:
        if cid in have:
            continue
        d = {"name": name, "cost": cost, "kind": "attack", "pokemon": carrier, "rarity": rarity,
             "type": typ, "damage": dmg, "block": 0, "description": "Inflige %d dégâts." % dmg}
        lines.append('\t\t%s: %s' % (json.dumps(cid), json.dumps(d, ensure_ascii=False)))
    if not lines:
        print("cards.json already up to date"); return
    marker = "\n\t}\n}"
    i = text.rindex(marker)
    text = text[:i] + ",\n" + ",\n".join(lines) + text[i:]
    json.loads(text)  # sanity
    open(CARDS, "w", encoding="utf-8", newline="").write(text)
    print("added %d cards" % len(lines))

if __name__ == "__main__":
    main()
