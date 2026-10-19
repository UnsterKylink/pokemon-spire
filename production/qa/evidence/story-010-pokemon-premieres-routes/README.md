# Evidence — Story 010: Pokémon des premières routes, toutes générations

**Date:** 2026-10-19 · **Engine:** Godot 4.6.3-stable (Linux, cloud session, Xvfb 1280x720, gl_compatibility)
**How captured:** `godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <this folder>` — roster shots run first with seed 12345 and no forced starter; the older shots of the same run (stories 005/008/009, played with `forced_starter_id = "salameche"`) were not kept here. Shot 04 uses `start_encounter("trio_r2")` (debug entry point, floor 1).

| Shot | Observed |
|------|----------|
| `01-choix-depart.png` | "Choisis ton Pokémon de départ": Passerouge (Normal/Vol), Medhyèna (Ténèbres), Otaquin (Eau) — 3 different primary types, each with its deck line |
| `02-depart-choisi.png` | Medhyèna chosen: active Pokémon with Ténèbres badge, PV 75/75, hand of Poursuite cards carried by Medhyèna; enemy Crikzik (gen 4) |
| `03-carte-aleatoire-type-coherent.png` | Reward: Dard-Venin (Poison) carried by Bulbizarre (Plante/Poison), Fouet Lianes (Plante) carried by Poussacha (Plante), Piqûre stolen from Crikzik |
| `04-ennemis-varies.png` | Trio of roster enemies from three generations: Lépidonille (gen 6), Ponchiot (gen 5), Arcko (gen 3) with types and intents |
| `05-deck-du-depart.png` | Deck overlay of the chosen starter: Poursuite — Medhyèna ×5, Mâchouille — Medhyèna ×1, Abri ×4 |

**Data source:** French names, types and base stats of the 58 new Pokémon come from the PokéAPI CSV data; sprites from the PokéAPI sprites repository, stored in `assets/sprites/pokemon/`.

**Also verified headless:** t10 4 136 / 0 (500-seed starter draws with 3 distinct primary types, 68 candidate starter decks 5/4/1, create_with_starter identity, 1 000 seeded reward generations with 100 % type-coherent carriers, stolen card carried by the defeated Pokémon, all 67 Pokémon / all pool encounters build, all sprites exist, every Pokémon teaches a card of its type, data rejections); t3 357, t4 1 348, t5b 472, t8 983, t9 232 — all 0 failures.

**Not covered:** real mouse clicks; web export; a floor-4+ map battle on screen (shot 04 is a debug encounter).
