# Story 016 — Statuts : preuves visuelles (UI)

Captured 2026-10-24, Godot 4.6.3-stable (linux, Xvfb 1280x720x24), run seed 2026, starter Salamèche.

## How captured

```
xvfb-run -a -s "-screen 0 1280x720x24" /root/godot/Godot_v4.6.3-stable_linux.x86_64 --path . --windowed \
  --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- production/qa/evidence/story-016-statuts story-016
```

`_status_shots()` in `tools/qa/battle_walkthrough.gd` uses these QA hooks: `start_encounter`,
`BattleScreen.qa_force_hand`, `BattleScreen.qa_apply_status(target_index, id, value)` (new; it goes through
`Battle.apply_status`, so immunities and feedback are the real ones) and `qa_give_potion`. Each shot prints a `016 <tag>:` line
to stdout with the chips, HP, energy, info-row hint and intents. Every PNG was opened and checked.

## Shot → observed

| Shot | Observed |
|---|---|
| `07-carte-statut` | 3-enemy fight (Lépidonille / Ponchiot / Arcko). The forced hand holds the status cards Toxik, Feu Follet, Cage-Éclair and Hypnose (skills), plus Dard-Venin (attack, "Poison 3."). Each card description names its status. |
| `01-statuts-ennemis` | After Toxik + Feu Follet + Cage-Éclair on Lépidonille, plus QA statuses on the other two enemies. Chips under the HP: `PSN 4` `BRU 4 (3 t.)` `PAR (2 t.)` / `PSN 3` `BRU 2 (3 t.)` / `PAR (2 t.)`. The 3 chips fit the 3-enemy slot width. Floating feedback: one coloured line per message ("Poison +4", "Brûlure +4", "Paralysie !"). Nothing overlaps the HP bars or intents. |
| `02-tick-poison` | After "Fin de tour": "-4 PV (Poison)" / "-4 PV (Brûlure)" and "-3 PV (Poison)" / "-2 PV (Brûlure)" float over the enemies. HP drops from 33→25 and 36→31. The chips update: `PSN 3`, `BRU 4 (2 t.)`, `PAR (1 t.)`. |
| `03-immunite` | Héricendre (Feu): Toxik gives "Poison +4" and a `PSN 4` chip. Feu Follet gives "Immunisé !" and no burn chip. Its intent "Attaque 3 + Brûlure 2" fits. |
| `04-statut-joueur` | Aspicot's "Attaque + Poison 2" hit the team. "Poison +2" floats on the player's side (under "Ce n'est pas très efficace…") and a `PSN 2` chip sits under "Protection" on the player's panel. |
| `04b-joueur-endormi` | The team is asleep (QA sleep) and ends its turn: "-2 PV (Poison)" / "Dort…" / "Réveillé !" on the player. Info row: "Ton équipe dort : 0 énergie ce tour" (lilac), Énergie 0/3, cards greyed out. |
| `06-soin-statut` | Total Soin drunk from the HUD: "Potion : Total Soin" floats and the player's `PSN` chip is gone. The belt has one slot fewer. |
| `05-sommeil-gel` | Roucool sleeping and Nosferapti frozen: intents "Dort" / "Gelé" in the status colour, with `DOR` / `GEL` chips. Aspicot's long intent "Attaque 13 + Poison 2" fits its slot. The panel without a chip stays aligned with the others. |

## Not covered by a shot

- Player paralysis fizzle ("Raté ! (Paralysie)" on the player) and an enemy failing its action from paralysis. Both
  depend on the battle RNG, so they were not staged. The code path is `_on_status_blocked` / `_on_turn_skipped`.
- "Dégelé !" (a Fire hit on a frozen enemy) and "Gelé !" as the lost-turn float (only "Dort…" is shown).
- Chip tooltips (name + description) need a mouse hover, which Xvfb does not capture.
- The Antidote / Anti-Brûlure / Antigel potions (same `cure_status` path as Total Soin).
- The worst-case intent with a burn ("Attaque 13 + Brûlure 4") was not reached in data. The font shrink (22 → 14 px
  minimum) is shown working only on "Attaque 13 + Poison 2", which already fits at 22 px.
