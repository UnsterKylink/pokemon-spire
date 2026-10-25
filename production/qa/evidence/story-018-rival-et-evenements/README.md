# Story 018 — Rival et nouveaux événements : preuves visuelles

Capture (1280x720, Godot 4.6.3, xvfb) :

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --windowed --resolution 1280x720 \
  -s res://tools/qa/battle_walkthrough.gd -- <dossier> story-018
```

Graine de partie `RIVAL_SEED = 1801`, starter Salamèche (rival Régis : Goélise, Eau/Vol, avantage sur le Feu).
Les images 05 à 07 passent par `Main.qa_show_event(id)` (hook QA, sans tirage) ; 08 a reçu 3 Balls (cheat QA) avant le combat
et 1 énergie pour ouvrir le mode capture (le sommeil du cauchemar en coûte 2).

| Image | Ce qu'elle montre |
|---|---|
| 01-carte-salle-rival | Carte de la zone 2 : salles « Rival » violet foncé (texte clair) à l'étage 3, entrée « Rival » dans la légende (affichée seulement si la carte en a une). Infobulle : « Régis et son Goélise t'attendent ». |
| 02-rival-intro | Bandeau avant le combat : « Régis te défie ! », Rencontre 1/4, sprite du starter actuel du rival, « Son starter : Goélise », réplique. Bouton « Combattre ! » (ou clic / Entrée / bouton A). |
| 03-combat-rival | Combat contre le rival (en-tête « Rival Régis »), Goélise seul (taille d'équipe 1 tirée). Main entière visible : hand_bottom=712/720. |
| 04-recompense-rival | « Tu as battu Régis ! Choisis une carte », butin +30 P$ et objet (Baie Mitrons), carte volée proposée. |
| 05-evenement-choix | Le marchand ambulant avec 30 P$ : option grisée « Acheter un objet (110 P$) — Il te faut 110 P$ » (le « ₽ » des données est affiché « P$ »). |
| 06-oubli-carte | Après « Accepter l'échange » + « Continuer » : sélecteur « Choisis une carte à oublier (1 restante) », sans bouton Retour. Un clic retire la carte puis la partie reprend (carte). |
| 07-legendaire-evenement | Événement légendaire Darkrai « Cauchemar » : cadre noir/or, « Pokémon légendaire », grand sprite, 2 choix. |
| 08-combat-legendaire | Combat seul contre Darkrai (en-tête légendaire, 250 PV, l'équipe endormie) ; mode capture : 2 % / 2 % / 3 %. |
| 09-carte-legendaire | « Tu as vaincu Darkrai ! » : la carte Trou Noir (cadre or + liseré rose, nom doré, onglet « Légendaire », « Ajoutée au deck », non cliquable) puis les 3 cartes habituelles. |
| 10-rival-final | Après le 8e badge : « Dernier combat contre Régis avant le Conseil 4 », Rencontre 4/4, Bekipan + Muplodocus + Tyranocif. |

Pas capturé ici : la variante « Capturé : <Nom> » de l'écran de récompense (légendaire capturé). La chance est trop faible
pour une capture déterministe, et aucun cheat de capture n'existe.
