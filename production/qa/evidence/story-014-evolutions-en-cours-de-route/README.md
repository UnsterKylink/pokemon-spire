# Story 014 — Évolutions en cours de route : preuves

Capturé le 2026-10-24 (Godot 4.6.3, xvfb 1280x720) :
`xvfb-run -a -s "-screen 0 1280x720x24" /root/godot/Godot_v4.6.3-stable_linux.x86_64 --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- production/qa/evidence/story-014-evolutions-en-cours-de-route story-014`
(filtre `story-014`, `_evolution_shots` ; graine 2026). Chaque PNG a été ouvert et vérifié.

| Shot | Observé |
|---|---|
| 01-evolution-1.png | Après le badge 1 (vrai flux arène → récompense → badge) : « Quoi ? Salamèche évolue ! », Avant Salamèche (Feu) → Après Reptincel (Feu), « +15 PV max (PV 96/96) ». 1 badge au HUD. |
| 02-evolution-cartes.png | « Reptincel peut apprendre une attaque » : 3 cartes portées par Reptincel (Danse-Flamme peu commune, Lance-Flammes rare, Flammèche+ départ améliorée), bouton Passer. |
| 03-evolution-2.png | Après le badge 4 (badges 2-4 par le vrai flux arène ; 4 badges au HUD) : « Quoi ? Reptincel évolue ! », Reptincel → Dracaufeu (Feu/Vol), « +20 PV max (PV 130/130) ». |
| 04-sans-evolution.png | Raichu (Pikachu passé au stade 2 par `qa_set_evolution_stage(1)`, étape du badge 4 lancée par `qa_show_starter_evolution(4)`) : « Raichu n'évolue pas — il se renforce ! », « +10 PV max (PV 105/105) », « Raichu s'améliore : Électacle+ ! ». |
| 05-evolutions-equipe.png | Écran compact « Évolutions » (pas de choix de carte) : Roucool → Roucoups, Nidoran♂ → Nidorino, Machoc → Machopeur, +2 PV max chacun, total « +6 PV max (PV 111/111) ». Déclenché après 4 victoires (`qa_win_battles(4)` + `qa_check_team_evolution`). |
| 06-deck-apres.png | Deck (16 cartes) : Choc Volt portées par Machopeur ×2, Nidorino ×2, Roucoups ×2, Raichu ×5, Électacle+ (Raichu, carte améliorée du shot 04). Plus aucune carte des formes d'avant. |

Pas de clipping ni de chevauchement constaté.

Non couvert par les captures : le passage de l'équipe au stade 3 (9 victoires) et les lignes du roster en jeu (couverts par le test scratch t18) ; l'écran d'équipe apparaissant naturellement après une vraie récompense (chemin `_after_reward`, couvert par t5b/t14/t18) ; le shot 04 montre 0 badge au HUD car l'étape est forcée par un hook QA.
