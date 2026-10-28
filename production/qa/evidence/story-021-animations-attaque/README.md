# Story 021 — Animations d'attaque et de combat : captures

- `01`–`05` : galerie des effets dessinés (`tools/qa/fx_gallery.gd`) — 18 types (projectile + impact), statuts, protection / soin / renfort / énergie.
- `1x-01`–`1x-08` : combat réel en vitesse Normal (`tools/qa/battle_walkthrough.gd`, jeu `story-021`) — charge + projectile, impact « Super efficace ! » + nombre flottant, protection, statut, ennemi qui charge, K.O. qui s'efface, switch qui glisse, lancer de Poké Ball. Main : `fits=true` partout.

Test (scratch t25) : le même combat avec graine joué en Instantané / Normal / Rapide donne exactement le même état final.
