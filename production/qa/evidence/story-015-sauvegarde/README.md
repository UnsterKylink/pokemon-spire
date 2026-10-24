# Story 015 — Sauvegarde / reprise : preuves

Capture (2026-10-24, Godot 4.6.3, xvfb 1280x720) :

```
xvfb-run -a -s "-screen 0 1280x720x24" /root/godot/Godot_v4.6.3-stable_linux.x86_64 --path . --windowed \
  --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- production/qa/evidence/story-015-sauvegarde story-015
```

Le walkthrough (`_save_shots`) passe par un fichier de sauvegarde de QA (`user://qa_story015_savegame.json`, défini avec
`Main.qa_set_save_path`, supprimé à la fin avec son `.bak`). Le vrai `user://savegame.json` n'est jamais touché.

| Image | Ce qu'on voit |
|---|---|
| `01-reprendre.png` | Écran « Reprendre la partie » après `qa_quit_to_title()` (relance simulée) : Reptincel (départ : Salamèche), type Feu, Zone 3/8 — Arène Acier, Badges 2/8, PV 102/102, P$ 312, Deck 17 cartes, date de sauvegarde ; boutons « Reprendre » / « Nouvelle partie ». |
| `02-apres-reprise.png` | Carte après « Reprendre » : même graphe (graine 2002032, salle f1_c0 visitée, f2_c0 accessible), HUD identique (2 badges, objets « Lunettes Choix +3 », 3 potions, 312 P$). Le log affiche `same_map=true same_summary=true` (comparaison du graphe sérialisé et du résumé avant/après). |
| `03-sauvegarde-illisible.png` | Fichier tronqué : « Sauvegarde illisible : JSON invalide (fichier tronqué ou corrompu) », note sur le `.bak`, seul bouton « Nouvelle partie ». Le fichier a été renommé en `.bak` (log `bak=true`). |
| `04-pas-de-sauvegarde-depart.png` | Après « Nouvelle partie » puis une relance sans fichier : écran de choix du starter, comme avant la story. |
| `05-apres-defaite.png` | Nouvelle partie → carte (sauvegarde écrite) → combat perdu (sauvegarde supprimée dès la défaite, log `has_save=false`) → écran de défaite → « Nouvelle partie » → relance : écran du starter, pas d'écran de reprise. |

Non couvert par les images : la reprise sur un entracte de ligue (couverte par le test t19), la victoire finale qui supprime
la sauvegarde (t19), l'écran de reprise dans le vrai jeu (vérifié à la main : un `savegame.json` corrompu dans le dossier
utilisateur a été renommé en `.bak` au lancement de `godot --path .`, et laissé intact avec `-- --seed=5`).
