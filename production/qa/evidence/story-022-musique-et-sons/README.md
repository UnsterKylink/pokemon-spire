# Story 022 — Musique et sons : captures

- `01-options-volumes.png` : panneau Options avec les curseurs « Musique » / « Effets » aux valeurs enregistrées (60 % / 80 % par défaut).
- `02-options-volumes-regles.png` : les mêmes curseurs réglés à 30 % / 90 % (enregistrés aussitôt dans `user://settings.json`, clés `music_volume` / `sfx_volume`).

Produit par `tools/qa/battle_walkthrough.gd` (jeu `story-022`, xvfb 1280x720). Le même passage affiche la musique choisie
par Main : carte -> `carte`, combat sauvage -> `combat_sauvage`, Centre -> `centre`, Mart -> `mart`. Les réglages du
joueur sont restaurés à la fin.
