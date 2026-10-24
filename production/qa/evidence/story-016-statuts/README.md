# Story 016 — Statuts : preuves visuelles (UI)

Captured 2026-10-24 (re-captured the same day after the player-reported fixes: fit-in-720p layout and the anti-lock status rules), Godot 4.6.3-stable (linux, Xvfb 1280x720x24), run seed 2026, starter Salamèche.

## How captured

```
xvfb-run -a -s "-screen 0 1280x720x24" /root/godot/Godot_v4.6.3-stable_linux.x86_64 --path . --windowed \
  --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- production/qa/evidence/story-016-statuts story-016
```

`_status_shots()` in `tools/qa/battle_walkthrough.gd` uses these QA hooks: `start_encounter`,
`BattleScreen.qa_force_hand`, `BattleScreen.qa_apply_status(target_index, id, value)` (new; it goes through
`Battle.apply_status`, so immunities and feedback are the real ones) and `qa_give_potion`. Each shot prints a `016 <tag>:` line
to stdout with the chips, HP, energy, info-row hint and intents. Every `shot` line of a battle also prints
`cards=N card_h=H hand_bottom=Y/720 fits=true|false` (global rects of the hand buttons). Every battle shot below reports
`card_h=204 hand_bottom=712/720 fits=true`: the full card, bottom border included, is inside the frame. Every PNG was opened and checked.

## Shot → observed

| Shot | Observed |
|---|---|
| `07-carte-statut` | 3-enemy fight (Lépidonille / Ponchiot / Arcko). The forced hand holds the status cards Toxik, Feu Follet, Cage-Éclair and Hypnose (skills), plus Dard-Venin (attack, "Poison 3."). Each card description names its status. |
| `01-statuts-ennemis` | (Before the fix the Hypnose / Dard-Venin cards were cut at the bottom edge; now fully visible, bottom border at y≈710.) After Toxik + Feu Follet + Cage-Éclair on Lépidonille, plus QA statuses on the other two enemies. Chips under the HP: `PSN 4` `BRU 4 (3 t.)` `PAR (2 t.)` / `PSN 3` `BRU 2 (3 t.)` / `PAR (2 t.)`. The 3 chips fit the 3-enemy slot width. Floating feedback: one coloured line per message ("Poison +4", "Brûlure +4", "Paralysie !"). Nothing overlaps the HP bars or intents. |
| `02-tick-poison` | After "Fin de tour": "-4 PV (Poison)" / "-4 PV (Brûlure)" and "-3 PV (Poison)" / "-2 PV (Brûlure)" float over the enemies. HP drops from 33→25 and 36→31. The chips update: `PSN 3`, `BRU 4 (2 t.)`, `PAR (1 t.)`. |
| `03-immunite` | Héricendre (Feu): Toxik gives "Poison +4" and a `PSN 4` chip. Feu Follet gives "Immunisé !" and no burn chip. Its intent "Attaque 3 + Brûlure 2" fits. |
| `04-statut-joueur` | Aspicot's "Attaque + Poison 2" hit the team. "Poison +2" floats on the player's side (under "Ce n'est pas très efficace…") and a `PSN 2` chip sits under "Protection" on the player's panel. |
| `04b-joueur-endormi` | The team is asleep (QA sleep) and ends its turn: "-2 PV (Poison)" / "Dort…" / "Réveillé !" on the player. Info row: "Ton équipe dort : −2 énergie ce tour" (lilac), Énergie 1/3: the team still draws and can play with what is left. The sleep ended, so a `RÉPIT (2 t.)` chip (green) appears next to `PSN 1`. |
| `06-soin-statut` | Total Soin drunk from the HUD: "Potion : Total Soin" floats and the player's `PSN` chip is gone; `RÉPIT (2 t.)` stays (the aftermath immunity is not a status). The belt has one slot fewer. |
| `08-repit` | Same fight, QA freeze applied to the team during the immunity: refused, "Immunisé !" floats over Salamèche, `RÉPIT (2 t.)` chip under the HP row. |
| `05-sommeil-gel` | Roucool sleeping and Nosferapti frozen: intents "Dort" / "Gelé" in the status colour, with `DOR` / `GEL` chips. Aspicot's long intent "Attaque 13 + Poison 2" fits its slot. The panel without a chip stays aligned with the others. |
| `09-main-7-cartes-statuts` | Worst-case layout: 3 enemies with 3 chips each (`PSN 3` `BRU 2 (3 t.)` `PAR (2 t.)`), the team with `PSN 2` `PAR (2 t.)`, and a 7-card hand (narrowed cards). All 7 cards are fully visible (`hand_bottom=712/720`), nothing overlaps. |

## Not covered by a shot

- Player paralysis fizzle ("Raté ! (Paralysie)" on the player) and an enemy failing its action from paralysis. Both
  depend on the battle RNG, so they were not staged. The code path is `_on_status_blocked` / `_on_turn_skipped`.
- "Dégelé !" (a Fire hit on a frozen enemy) and "Gelé !" as the lost-turn float (only "Dort…" is shown).
- Chip tooltips (name + description) need a mouse hover, which Xvfb does not capture.
- The Antidote / Anti-Brûlure / Antigel potions (same `cure_status` path as Total Soin).
- The worst-case intent with a burn ("Attaque 13 + Brûlure 4") was not reached in data. The font shrink (22 → 14 px
  minimum) is shown working only on "Attaque 13 + Poison 2", which already fits at 22 px.
- "Paralysie : sans effet" (paralysis re-applied while active; covered by the scratch test t20).

## Layout fix (fit in 1280x720)

The battle screen sits under the 44 px HUD, so it has 676 px. Before the fix the hand row (card 200 + 10) started at y≈525 and
ran to ≈735, past the 720 px frame. Changes in `src/ui/battle_screen.gd`: vertical outer margin 16 → 8 px, row gap 8 → 4 px,
fighter panel gap 4 → 2 px, "PV" and "Protection" on one row (one line saved per fighter), hand row height card + 10 → card + 4,
"Fin de tour" 48 → 44 px high. Card size (170x200) and sprite sizes are unchanged. Hand cards are now at y 508–712.
`project.godot`: `window/stretch/mode="canvas_items"` was already set; `window/stretch/aspect="keep"` is now explicit
(it was absent, which in Godot 4 means `keep`), so the 1280x720 design is letterboxed, never cropped, in a smaller or
different-aspect window.
