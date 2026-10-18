# Evidence — Story 001: Combat de base contre 1 ennemi

**Date:** 2026-10-18 · **Engine:** Godot 4.6.3-stable (Linux, cloud session, Xvfb 1280x720, gl_compatibility)
**How captured:** `godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <this folder>`
(scripted fight through the BattleScreen public methods — no real mouse events).

| Shot | State | Observed |
|------|-------|----------|
| `01-debut-combat.png` | Turn 1 | Salamèche 75/75, Rattata 30/30, Énergie 3/3, hand of 5, Pioche 5 / Défausse 0 |
| `02-carte-selectionnee.png` | Attack selected | Selected Griffe highlighted yellow, hint "Cliquez sur l'ennemi…", enemy tinted |
| `03-attaque-et-protection.png` | Griffe + Abri played | Rattata 24/30, Protection 5, Énergie 1/3 |
| `04-tour-suivant.png` | After enemy turn | Rattata hit 7, 5 absorbed → PV 73/75; Protection reset to 0; Énergie 3/3; new hand of 5 |
| `05-victoire.png` | Enemy KO | "Victoire !" + Rejouer, cards and Fin de tour disabled |
| `06-defaite.png` | Player KO | "Défaite…" + Rejouer, PV 0/75 |
| `07-rejouer.png` | After Rejouer | Fresh battle, 75/75 vs 30/30 |

**Defects found and fixed during the run:** HP bars rendered grey with no visible fill (default theme) → coloured fill styles; layout taller than 720 px (cards cut off at the bottom) → sprite scale 3→2.5, card height 230→200; attack/skill cards now bordered red/blue.

**Not covered by this run:** real mouse clicks (harness calls the same methods the click handlers call); audio (none in this story); web export.
