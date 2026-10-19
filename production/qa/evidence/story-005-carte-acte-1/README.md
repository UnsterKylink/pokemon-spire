# Evidence — Story 005: Carte de l'acte 1

**Date:** 2026-10-19 · **Engine:** Godot 4.6.3-stable (Linux, cloud session, Xvfb 1280x720, gl_compatibility)
**How captured:** `godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <this folder>` — full act on map seed **12345**, path wild → wild → wild → mart → center → wild → elite → event → event → wild → center → wild → wild → center → boss. Scripted (no real mouse events); HP is topped up / lowered by the QA-only `Main.qa_set_hp` helper to keep the run alive and make effects visible.

| Shot | Observed |
|------|----------|
| `01-carte-debut.png` | 15-floor map, crossing paths, 6 room types with legend, 3 reachable floor-1 rooms (white border), "Graine : 12345" |
| `02-combat-etage-1.png` | Floor-1 wild room starts a fight from the early wild pool |
| `03-carte-apres-combat.png` | "Étage 1/15", visited room outlined gold, only its 2 connected rooms reachable, deck 11 after the reward |
| `04-evenement.png` / `05-evenement-resultat.png` | Event "Dresseur curieux" with 2 options → result text + effect summary ("Carte perdue : Abri, Carte obtenue : Dard-Venin"). Note: on 04 the header was drawn before the QA helper lowered HP to 37, so it still reads 75 |
| `06-combat-elite.png` | Elite room: Racaillou 48, Pikachu 40, Ptitard 37 PV (×1.4 HP) and +1 strength in intents |
| `07-recompense-elite.png` | Elite reward: Rare + Peu commune + stolen card |
| `08-centre.png` | Centre Pokémon placeholder heals 30 % ("+23 PV"); full centre/mart is story 006 |
| `09-boss.png` | Floor 15 boss room (placeholder champion trio; real boss is story 007) |
| `10-acte-termine.png` | After the boss: "Acte 1 terminé !" + Nouvelle partie |

**Also verified headless:** t5 (map generator, 400 seeds) 227 833 / 0; t5b (whole act through Main on seeds 12345 / 777 / 4242: screen per room type, unreachable rooms refused, visited +1 per room, floor 1→15, centre heal, event effects, elite HP boost, new run/new seed) 465 / 0; t3 202 / 0; t4 1208 / 0.

**Not covered:** real mouse clicks; web export.
