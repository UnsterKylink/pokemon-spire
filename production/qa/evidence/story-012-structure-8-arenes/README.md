# Evidence — Story 012 : Structure 8 arènes, zones et badges (UI)

Captured 2026-10-21, Godot 4.6.3-stable (Linux, Xvfb), 1280x720, run seed 2026 (defeat run: seed 2027), starter Salamèche.

## How captured

```
xvfb-run -a -s "-screen 0 1280x720x24" /root/godot/Godot_v4.6.3-stable_linux.x86_64 --path . --windowed \
  --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- production/qa/evidence/story-012-structure-8-arenes story-012
```

`tools/qa/battle_walkthrough.gd` → `_zones_shots()` (filter `story-012`, so it takes only this story's shots). Cheats it uses:
`qa_give_item` ×3 / `qa_give_potion` ×2 so the HUD is crowded, `qa_skip_to_gym` + `qa_win_gym` (each gym is won through
the real win handler: loot → card reward (skipped) → badge screen → `badge_continue` → evolution after badge 1 (skipped) → next zone map).
The 8 badges are all earned this way, one zone after another. `qa_set_zone(7)` is not used, so no zone is skipped.
`qa_lose_battle` is used for the defeat.

## Shots → observed

| Shot | Observed |
|---|---|
| `01-carte-zone-1.png` | Map header "Zone 1/8 — Arène Feu (Champion Auguste)", second line "Départ  PV 75/75 \| Deck : 10 cartes \| Graine : 2026". Orange banner "Zone 1 — Arène Feu / Le Champion Auguste t'attend au sommet de la carte." The legend's last entry is "Arène Feu". The gym node says "Arène Feu". HUD: 50 P$, "Badges :" with 8 grey empty octagons, 3 item chips, potions, Deck. Nothing is clipped. |
| `02-champion-zone-1.png` | Gym fight vs Gruikui / Chochodile / Arcanin, all Feu (40/40/60 PV, the zone 1 tier). HUD badges are still empty. |
| `03-badge.png` | Badge screen: "Tu as gagné le Badge Volcan !", "Tu as battu Auguste, Champion de l'arène [Feu]", a large orange emblem drawn in code, "Bonus : +6 PV max" in green. Below it: "Débloqué : de nouveaux groupes de Pokémon sauvages dans les zones suivantes.", "Salamèche va évoluer !", "Prochaine étape : Zone 2 — Arène Normal". Then "Badges : 1/8" with a row of 8 emblems (1 coloured) and "Continuer". The HUD already shows 1 orange badge. The 4th item (gym loot) is folded into a chip. |
| `04-carte-zone-2.png` | Zone 2 map: "Zone 2/8 — Arène Normal (Champion Norman)" with a new seed. Beige banner "Zone 2 — Arène Normal" with "Ton deck, tes PV, tes objets et ton argent te suivent." The gym node and legend say "Arène Normal". HUD: 1 coloured badge, the "+2" items chip, PV 96/96 (Reptincel after the evolution). |
| `05-champion-zone-8.png` | Zone 8 gym (Vol): Poichigeon 78 / Passerouge 72 / Roucarnage 132 PV, all with +3 strength (stronger than zone 1). HUD: 7 coloured badges (each in its type colour) and 1 empty. Items show "+8". Energy is 4/4 and the hand has 7 cards (badge bonuses). |
| `06-victoire-8-badges.png` | "Victoire !". Subtitle "Reptincel a remporté les 8 badges. Bravo, Dresseur !", then "Badges : 8/8" with 8 coloured emblems. Stats: "Zone atteinte 8/8 — Arène Vol", "Étages franchis 8/48" (whole run). The 11-item list is cut with "…" (the full list is in the tooltip). |
| `07-defaite-zone.png` | "Défaite…", "Reptincel est K.O. en zone 3/8 (Arène Plante). La partie est terminée.", "Badges : 2/8" (2 coloured, 6 grey). Stats: "Zone atteinte 3/8 — Arène Plante", "Étages franchis 3/48". |

## Not covered

- Tooltips: hovering is not captured, and the log does not print tooltip text. By code (`BadgeEmblem.tooltip_of`), earned = "Badge Volcan — Champion Auguste (Feu)" and empty = "Badge 2/8 — pas encore obtenu". The log does print the earned/empty state of each HUD slot.
- A full walk of every map: the floors count only the gym rooms entered by the cheat (8/48, 3/48).
- The "Terminer" button on the badge of zone 8 (the log only shows the flow reaching the victory).
- Resolutions other than 1280x720.
