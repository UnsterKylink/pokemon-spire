# Story 019 — Équilibrage : preuves visuelles

Capturées le 2026-10-24 avec Godot 4.6.3 (xvfb, 1280×720) :
`xvfb-run -a -s "-screen 0 1280x720x24" /root/godot/Godot_v4.6.3-stable_linux.x86_64 --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- production/qa/evidence/story-019-equilibrage story-019`
(filtre `story-019`, `_balance_shots`, graine 1907, starter Salamèche — PV max 90 et deck de 11 cartes après réglage).

| Capture | Ce qu'on voit | Observé |
|---|---|---|
| `01-intent-type.png` | Étourmi (Normal/Vol), 2e action = son attaque Vol : l'intention affiche « Attaque 7 (Vol) » (type de l'action, défini en données) | log : `starly:Attaque 7 (Vol)` ✔ |
| `02-arene-zone1.png` | Nouvelle arène de la zone 1 (type tiré : Plante) : équipe générée du roster, 3 Pokémon de tier 1 (Virovent, Chlorobule, Ceribou) à 24 PV chacun (×0.7), attaques 2 (résistées par le Feu) ; avant réglage l'arène pouvait être une équipe fixe avec un stade 3 (ex. Arcanin) | log : `roster:bramblin,petilil,cherubi`, 3 × 24/24 PV ✔ |

Rien d'autre ne change à l'écran (story Config/Data).
