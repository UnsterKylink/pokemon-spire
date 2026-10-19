# Evidence — Story 008: 18 types et doubles types

**Date:** 2026-10-19 · **Engine:** Godot 4.6.3-stable (Linux, cloud session, Xvfb 1280x720, gl_compatibility)
**How captured:** `godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <this folder>` (type shots run first; the act shots of the same run belong to story 005 and were not kept here). Shot 02/03 use the QA-only `BattleScreen.qa_force_hand` to put a given card in hand.

| Shot | Observed |
|------|----------|
| `01-types-doubles.png` | Dual-type badges: Roucool Normal/Vol, Nosferapti Poison/Vol, Aspicot Insecte/Poison; fits 1280x720 with 3 enemies |
| `02-super-efficace-double.png` | Pistolet à O (Eau, 7) on Racaillou (Roche/Sol): ×1.5 × ×1.5 = ×2.25 → 15 damage (34 → 19), "Super efficace !" |
| `03-immunite.png` | Éclair (Électrik) on Racaillou (Sol): ×0 → 0 damage, "Ça n'affecte pas Racaillou…" |

**Skipped:** an "Attaque 0" enemy intent on screen — nothing in the roster is immune against Salamèche's Fire type; covered by the headless test (Ground attacker vs a Flying player).

**Also verified headless:** t8 785 / 0 (all 324 attacker/defender pairs vs an independent copy of the official chart, dual-type products, immunities winning, floor rounding, 0-damage hit leaves block untouched, intent == executed damage vs a dual-type defender, 14 malformed-data rejections); t3 101 / 0, t4 1208 / 0, t5b 465 / 0.

**Not covered:** real mouse clicks; web export.
