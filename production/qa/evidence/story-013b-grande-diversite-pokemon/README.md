# Story 013b — Grande diversité de Pokémon (evidence)

Captured 2026-10-24, Godot 4.6.3 (xvfb, 1280x720) with:
`xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- production/qa/evidence/story-013b-grande-diversite-pokemon story-013b`
(`_diversity_shots` in `tools/qa/battle_walkthrough.gd`; seeds and picks are printed in the log).

| Shot | What it shows |
|---|---|
| `01-choix-depart.png` | Starter choice (run seed 2028): Spoink (Psy, gen 3) and Bombydou (Insecte/Fée, gen 7) come from the roster, Picassaut from the classic candidates; 3 different primary types; Spoink gets the new Psy starter cards (Rafale Psy / Psykoud'Boul). Bombydou is picked. |
| `02-sauvage-zone1.png` | Zone 1 wild fight generated from the roster (`roster:sneasel`): Farfuret (Ténèbres/Glace, gen 2, tier 1), solo on an early floor. |
| `03-sauvage-zone6.png` | Zone 6 wild trio from the roster (`roster:sneasler,meowscarada,magneton`): Farfurex (gen 8), Miascarade (gen 9), Magnéton (gen 1), tiers 2–3, zone modifiers applied (×1.4 HP, +1 strength). |
| `04-recompense.png` | Reward after that fight: carriers are roster Pokémon of the card's type — Gorythmic (Plante), Farfurex (stolen Dard-Venin, Poison), Trompignon (Plante). |
| `05-arene-nouveau-type.png` | A newly possible gym type: Arène Ténèbres (zone 6, Champion Peterson, run seed 2026), auto-built team of 3 Dark roster Pokémon: Félinferno, Spiritomb, Trioxhydre (gym modifiers ×1.75 / +2). |
| `06-deck.png` | The roster starter's deck (Bombydou): 10 cards = 5× Coup d'Insecte + 4× Abri + 1× Mégacorne, attacks carried by Bombydou. The map title behind it reads "Zone 6/8 — Arène Ténèbres (Champion Peterson)". |

Checked by opening every PNG: no clipped names or overlapping labels.
