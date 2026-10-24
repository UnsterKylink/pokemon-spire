# Story 017 — Capture avec Poké Balls : preuves UI

Captures prises le 2026-10-24 à 1280x720 (Godot 4.6.3, xvfb) avec :

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --windowed --resolution 1280x720 \
  -s res://tools/qa/battle_walkthrough.gd -- <dossier> story-017
```

Graine de partie `CAPTURE_SEED = 1701`, Salamèche, rencontre sauvage `trio_r2` (Lépidonille / Ponchiot / Arcko).
Les Balls / objets / argent sont donnés par les triches QA (`qa_give_ball`, `qa_give_item`, `qa_set_money`).
Les lancers passent par `Main.battle_use_ball` → `BattleScreen.throw_ball`, le même chemin que le clic sur un bouton de Ball.

| Fichier | Ce qu'on voit | Critère |
|---|---|---|
| `01-hud-balls.png` | Barre du haut : « Balls : 5 » et 5 icônes dessinées en code (3 Poké, 1 Super, 1 Hyper), à côté de 8 badges, des objets repliés en « +4 », des potions et du Deck. Infobulle : « Poké Balls : 5/5 \| Poké Ball ×3 \| Super Ball ×1 \| Hyper Ball ×1 ». | 1, 5 |
| `02-mode-capture.png` | Combat sauvage, mode capture actif (« Annuler » dans la ligne d'infos, indice « Ball : 1 énergie »). Chaque ennemi montre un bouton par Ball avec sa chance : 10/14/20 % à PV pleins, 95 % (plafond) sur Ponchiot à 7/36 PV et endormi. Main entière visible (`hand_bottom=712/720 fits=true`). | 2 |
| `04-capture-ratee.png` | Poké Ball sur Lépidonille à PV pleins : « Raté… (10 %) » sous la cible, énergie 2/3, Balls : 4. L'ennemi reste. | 2 |
| `03-capture-reussie.png` | Hyper Ball sur Ponchiot (95 %) : « Capturé ! » à l'endroit où il était ; les emplacements sont reconstruits (2 ennemis, « Combat : 2 ennemis »), Balls : 3. | 2, 3 |
| `05-recompense-capture.png` | Récompense : « Capturé : Ponchiot rejoint l'équipe — +2 cartes » avec son sprite (Croc Fatal, Vive-Attaque) et la puce de butin « Ball : Poké Ball ». Deck 11 → 13. | 1, 3 |
| `06-mart-balls.png` | Poké Mart : rangée « Poké Balls » avec le prix, la Ball achetée affiche « Vendu » ; l'en-tête affiche « Balls 5/5 ». | 1 |
| `07-equipe.png` | Panneau du deck, onglet « Équipe (2) » : Salamèche (Pokémon de départ, 11 cartes) puis Ponchiot (Normal, 2 cartes, « Évolution : 0/4 combats », étiquette « Capturé »). | 5 |
| `08-dresseur-sans-capture.png` | Arène (Dresseur) avec 5 Balls : bouton « Capturer » désactivé, infobulle « Impossible de capturer un Pokémon de Dresseur. ». La carte capturée Croc Fatal (Ponchiot) est dans la main. | 3, 4 |

## Remarques

- **Butin « Ball » mis en scène** (05) : le tirage de butin de cette graine n'a pas donné de Ball (30 %). Le script
  ajoute une Poké Ball au dictionnaire *affiché* (`RewardScreen.set_loot`), sans toucher la partie. Le journal le dit
  (`017 05: ball loot chip staged`).
- **États du Mart** : ce Mart ne propose qu'une Ball, donc seul l'état « Vendu » est visible. « Sac plein » (tuile
  désactivée, « Sac de Balls plein (5/5). » en infobulle, « · Sac plein » à côté du prix) et le prix rouge quand on
  n'a pas assez d'argent suivent le même chemin que les potions, mais ne sont pas sur cette capture.
- Infobulles (01, 08) vérifiées dans le journal, pas visibles sur les PNG.
