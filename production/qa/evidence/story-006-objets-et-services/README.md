# Evidence — Story 006: Objets, potions, Centre Pokémon et Poké Mart (UI half)

**Date:** 2026-10-21 · **Engine:** Godot 4.6.3-stable (Linux, cloud session, Xvfb 1280x720, gl_compatibility)
**How captured:** `xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <this folder>`. The story-006 shots (`_items_shots`) run right after the story-010 roster shots, on seed 2026 with Salamèche. Items, potions and money come from the QA cheats `qa_give_item` / `qa_give_potion` / `qa_set_money`. The fight is `start_encounter("solo_bidoof", "elite")`, which uses elite loot. The Centre and the Mart are opened with `qa_open_room`, which does not move on the map. The older stories' shots from the same run were deleted from this folder. The walkthrough's normal path still enters a real map Centre: it now calls `center_heal()` there, and it reported "missing room types: []".

| Shot | Observed |
|------|----------|
| `01-hud-carte.png` | The HUD bar sits above the act map: "50 P$", item chips Peau Métal / Bandeau / Restes (border colour = rarity), and 3 potion slots (Potion, Attaque +, Défense +). The map header sits below the bar with no overlap. |
| `02-combat-potions.png` | Battle under the HUD. Attaque + was drunk: its slot is gone, so the slots read Potion / Défense + / "— vide —", and the 2 left are clickable (bright border). Floating feedback "Bandeau !" (first attack) and "Potion : Attaque +" over Salamèche. Protection 4 (Peau Métal at battle start). The info row shows "Attaque +5 ce tour". Keunotor went from 40 to 24 HP (Flammèche 8 + Bandeau 3 + Attaque+ 5). The hand fits on screen. |
| `03-recompense-butin.png` | Reward screen with a "Butin :" row: "+34 P$" and "Objet : Ceinture Force" plus its description. The HUD already shows 84 P$ and the new chip. |
| `04-centre.png` | Centre Pokémon at PV 37/75. Two choices: "Se soigner (+23 PV) / 30 % des PV max" and "Améliorer une carte". No heal happened on entry. |
| `05a-centre-choix-carte.png` | Upgrade picker: the upgradable cards, grouped (Flammette ×5, Abri ×4, Flammèche ×1), and "Retour". |
| `05b-centre-amelioration.png` | Preview: "Avant" Flammette (6 damage) → "Après" Flammette+ (9 damage), "Dégâts 6 → 9", and the buttons Améliorer / Retour. |
| `05c-centre-resultat.png` | "Flammette devient Flammette+ !". Both options are locked, "Continuer" is shown, and HP is unchanged at 37/75 (one service only). |
| `06-mart.png` | Poké Mart at 260 P$: 5 cards drawn with CardView and their prices (75 / 50 P$), 3 held items (150 / 150 / 100 P$), 2 potions (45 P$), "Retirer une carte (75 P$)" and "Quitter". |
| `06b-mart-achats.png` | After buying Mur de Fumée and Attaque +: both are greyed out and marked "Vendu". Défense + shows "45 P$ · Pleine" (belt 3/3, the purchase was refused). The 150 P$ items are greyed with red prices (140 P$ left). Status line: "Acheté : Attaque +.". Deck 11 cards. |
| `07-mart-retrait.png` | Removal picker "Retirer une carte — 75 P$" over the dimmed Mart: the whole deck grouped (including Flammette+ and Mur de Fumée), and "Annuler". |
| `07b-mart-apres-retrait.png` | "Carte retirée : Abri.": deck 10 cards, 65 P$, and the next removal costs 100 P$ (button disabled because it is unaffordable). |

**Also verified headless:** the scratch tests t3 357, t4 1 348, t5b 484, t8 983, t9 232, t10 4 136 and t11 916 all pass with 0 failures. t5b was updated: on a map Centre the screen is now "center", nothing heals on entry, "Continuer" is ignored until a service is used, and `center_heal()` heals.

**Not covered:** real mouse clicks and hover tooltips (item / potion descriptions sit in `tooltip_text`); gamepad focus; potion loot from a wild fight on screen (covered by t11); the Mart reached through the map (t5b covers it headless).
