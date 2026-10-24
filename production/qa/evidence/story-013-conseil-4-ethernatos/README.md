# Story 013 — Conseil 4 et Éthernatos: screenshot evidence

Captured on 2026-10-24 with Godot 4.6.3-stable (Linux, xvfb, 1280x720):

```
xvfb-run -a -s "-screen 0 1280x720x24" /root/godot/Godot_v4.6.3-stable_linux.x86_64 --path . --windowed \
  --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- production/qa/evidence/story-013-conseil-4-ethernatos story-013
```

`_league_shots` in `tools/qa/battle_walkthrough.gd`. Run seed 2026 with Salamèche. Items and potions are given through
the QA cheats so the HUD is crowded. Badges 1–8 come from the real gym flow (`qa_win_gym`, reward skipped,
`badge_continue`). Then the league runs through the real screens: `league_continue()` → fight →
`qa_win_league_fight()` → reward skipped → league screen. HP is set to 60 during each league fight so the heal after it
shows.

| Shot | Observed |
|---|---|
| 01-route-victoire | League intro, right after badge 8. Title "Route Victoire" with the subtitle "Le Conseil 4 t'attend". The 6 fights are listed in order: Clément (Psy), Marion (Ténèbres), Agatha (Spectre), Thyméo (Acier), Peter (Maître de la Ligue, Dragon) and Éthernatos (Boss final, Poison + Dragon, on a dark red row). Clément is the current fight (arrow marker, border in his type colour, "Prochain combat"); the others show "À venir". The button reads "Affronter Clément". The HUD shows "Conseil 4 : 1/6" next to the 8 badges. |
| 02-conseil-combat | Fight against Clément (Xatu, Mentali, Alakazam, all Psy). The pill above the arena reads "Clément — Conseil 4" and does not overlap the enemy names. The HUD shows "Conseil 4 : 1/6". |
| 03-intermission | "Victoire contre Clément !" and "+39 PV récupérés (PV 99/156)", which is 25 % of 156 rounded up, applied to 60 HP. Clément has a green check and "Vaincu"; Marion is current, with "Prochain combat" in gold. The button reads "Affronter Marion". The HUD shows "2/6". |
| 04-maitre | Fight against the Maître. The header reads "Peter — Maître de la Ligue"; his team is Draco, Drattak and Dracolosse (all Dragon). The HUD shows "5/6". |
| 05-ethernatos-intro | Final-boss variant: dark purple background, red border and the title "Éthernatos surgit !". The subtitle "Une puissance colossale…" and the heal line sit above the Éthernatos sprite. The 5 beaten fights are checked and Éthernatos is current. The button reads "Affronter Éthernatos". The HUD shows "6/6". |
| 06-ethernatos-combat | Solo Éthernatos (PV 620/620, intent "Renforcement +2"). The header "Éthernatos — Boss final" uses the red boss palette. |
| 07-victoire-finale | Title "Victoire ! Tu as vaincu Éthernatos". The subtitle reads "…a remporté les 8 badges, battu le Conseil 4 et le Maître". The badges are 8/8. The deck panel opens with "Ligue : 6/6 combats gagnés" and 6 name chips, each in its type colour, followed by the final deck. |
| 08-defaite-conseil | Separate run (seed 2027), sent straight to league stage 2 with the QA cheats `qa_skip_to_league` + `qa_set_league_stage(1)`, then the fight is lost (`qa_lose_battle`). The screen shows "Défaite…" and the subtitle "Salamèche est K.O. face à Olga (Conseil 4 2/6). La partie est terminée.". The league row shows Agatha as beaten, Olga with a red border (the fight that was lost) and the rest in grey. |

## Not covered

- In 08, 0/8 badges is a side effect of the QA cheat: the defeat run skips the zones. A real run always has 8 badges.
- The fights against members 2–4 are not shot on their own. They follow the same path as 02 and their lines are in the log.
- The 25 % heal capped at max HP is not shot (logic: scratch t16).
- Hover tooltips (HUD league progress, chips on the end screen) are not visible in static shots.
- No gamepad or keyboard navigation: the game is mouse-only, as on the other screens.
