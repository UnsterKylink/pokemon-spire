# Evidence — Story 002: Intentions des ennemis et combats à plusieurs

**Date:** 2026-10-18 · **Engine:** Godot 4.6.3-stable (Linux, cloud session, Xvfb 1280x720, gl_compatibility)
**How captured:** `godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <this folder>`
(scripted run through solo → duo → trio via BattleScreen public methods; no real mouse events). The battle RNG is unseeded in the game, so HP values differ run to run.

| Shot | Observed |
|------|----------|
| `01-solo-debut.png` | Rattata alone, intent "Attaque 7" above it |
| `03-duo-debut.png` | Roucool "Protection 5" (blue), Aspicot "Attaque 4" (red), "Combat : 2 ennemis" |
| `05-trio-debut.png` | Rattata "Attaque 7", Nosferapti "Renforcement +1" (yellow), Chenipan "Attaque 5"; all 3 fit with the hand visible |
| `06-trio-carte-selectionnee.png` | Griffe selected, hint "Choisissez une cible", living enemies tinted |
| `07-trio-un-ko.png` | Nosferapti K.O. (faded, "K.O.", PV 0/22); Rattata 7 + Chenipan 5 hit → PV 63/75 (matches displayed intents) |
| `02/04/08-*-victoire.png` | "Victoire !" only once all enemies are K.O.; arena dimmed behind the message |
| `09-rejouer-apres-victoire.png` | Rejouer picks a random encounter (never the same twice in a row) |
| `10-defaite.png`, `11-rejouer-apres-defaite.png` | Defeat, then Rejouer picks another random encounter |

**Defect found and fixed during the run:** the "Victoire !" text overlapped an enemy's HP label → added a dim backdrop behind the end-of-battle message.

**Also verified headless:** 42/42 throwaway assertions (sequence/weighted patterns, executed action == displayed intent incl. strength, dead/invalid target rejected, win only when all dead, block on both sides, 9 malformed-data cases rejected by GameData).

**Not covered:** real mouse clicks; web export.

**Change after play-test feedback (2026-10-18):** the developer kept getting Rattata alone. Encounters are now 10 (a solo fight for each of the 5 Pokémon, 3 duos, 2 trios) and each launch / Rejouer picks one at random, never the same twice in a row (200 picks: all 10 seen, 0 repeats). The label now reads "Combat : N ennemi(s)". Screenshots in this folder were re-captured after the change.
