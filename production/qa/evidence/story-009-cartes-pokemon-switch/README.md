# Evidence — Story 009: Cartes Pokémon, switch et PV communs

**Date:** 2026-10-19 · **Engine:** Godot 4.6.3-stable (Linux, cloud session, Xvfb 1280x720, gl_compatibility)
**How captured:** `godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <this folder>` (switch shots run first; the type/act shots of the same run belong to stories 008/005 and were not kept here). Encounter `solo_pikachu`; `jet_de_pierres` is put in hand with the QA-only `qa_force_hand`, then played through the real select/click path.

| Shot | Observed |
|------|----------|
| `01-actif-salameche.png` | "Pokémon actif" Salamèche (Feu); Pikachu "Attaque 7"; Griffe cards show a Salamèche icon + name, Abri shows "Équipe" |
| `02-switch-vers-racaillou.png` | Jet-Pierres (carried by Racaillou) played: Racaillou enters (Roche/Sol badges), "Racaillou, à toi !", Pikachu 28 → 20 and its intent recomputed to "Attaque 0" (Électrik vs Sol immunity) |
| `03-intention-recalculee.png` | Same state after the float faded: Racaillou active, shared PV 75/75, Pikachu still "Attaque 0" |
| `04-competence-sans-switch.png` | Abri played: protection 0 → 5, active Pokémon unchanged (Racaillou) |
| `05-fin-de-tour-immunite.png` | End of turn: Pikachu's attack does nothing ("Ça n'affecte pas Racaillou…", PV 75 → 75); Racaillou stays active; new hand shows each card's Pokémon |
| `06-recompense-carte-volee.png` | Stolen card Étincelle carried by Pikachu (icon + name, "Attaque volée à Pikachu"); other offers carried by Mystherbe and Rattata |
| `07-deck.png` | Deck grouped by card + Pokémon: "Griffe — Salamèche ×5", "Flammèche — Salamèche ×1", "Abri ×4" |

**Also verified headless:** t9 199 / 0 (switch before the hit, no switch on skills or invalid targets, intents recomputed without re-rolling, executed damage == displayed intent after a switch, shared HP/block, starter active at each battle start, stolen card carried by the defeated Pokémon, data rejections); t3 101 / 0, t4 1208 / 0, t5b 465 / 0, t8 785 / 0.

**Not covered:** real mouse clicks; web export.
