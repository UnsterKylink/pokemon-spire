# Evidence — Story 004: Récompenses et vol d'attaque

**Date:** 2026-10-18 · **Engine:** Godot 4.6.3-stable (Linux, cloud session, Xvfb 1280x720, gl_compatibility)
**How captured:** `godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <this folder>` (drives `src/main.tscn`; scripted, no real mouse events). Runs are random, so card names/HP differ from run to run.

| Shot | Observed |
|------|----------|
| `01-reward-screen.png` | "Victoire ! Choisis une carte", PV already reduced (persisted), 3 offers with cost / type badge / rarity, one marked "Attaque volée à <Pokémon battu>", Passer + Voir le deck |
| `02-deck-overlay.png` | "Ton deck (10 cartes)": Abri ×4, Flammèche ×1, Griffe ×5, Fermer button |
| `03-next-battle.png` | Next battle starts at the persisted HP, "Deck : 11 cartes" |
| `03b-nouvelle-carte-en-main.png` | The picked card shows up in hand |
| `04-passer-avant.png` / `04-passer-apres.png` | Second reward (stolen card from the 2nd Pokémon beaten); Passer → deck stays 11 |
| `05a-defaite.png` / `05-defaite-nouvelle-partie.png` | Defeat → Rejouer starts a fresh run: PV 75/75, Deck : 10 cartes |

**Defect found and fixed during the run:** the deck overlay panel was see-through (the title read through it) and its list touched the panel edge → opaque padded panel + word-wrapped rows.

**Also verified headless:** 1208/1208 throwaway assertions (RunState persistence/clamping, deck copy isolation, reward generator: 3 distinct cards, always one stolen card when available over 200 seeded runs, rarity frequencies 59.0/30.7/10.3 % vs 60/30/10, no starter cards offered, 28-card pool, malformed-data rejection) and 202/202 type assertions from story 003.

**Not covered:** real mouse clicks on the reward screen; web export.
