# Game Brief: Pokémon Spire (titre provisoire)

<!-- Fiche d'une page — au niveau `minimal`, c'est le document de design complet. -->
<!-- Projet perso, non publié : utilise les Pokémon et sprites officiels (PokéAPI). -->

**One-sentence pitch:** Un roguelike deckbuilder façon Slay the Spire où chaque carte d'attaque appartient à un Pokémon qui entre sur le terrain quand on la joue : on choisit son Pokémon de départ parmi 3 (starters ou route 1, toutes générations), on vole les cartes des Pokémon mis K.O. sur les premières routes de toutes les générations, et on monte jusqu'au Champion d'arène.

## Core loop
- Début de partie : choisir 1 Pokémon de départ parmi 3 proposés (starters ou Pokémon de route 1, toutes générations, 3 types différents).
- Choisir son chemin sur la carte : combat sauvage, Dresseur élite, Centre Pokémon, Poké Mart, événement.
- Combattre avec ses cartes en gérant son énergie : jouer l'attaque d'un Pokémon le fait entrer sur le terrain (il devient la cible des ennemis, avec ses types).
- Après la victoire : choisir 1 carte parmi 3 (dont une volée à un Pokémon mis K.O.), parfois un objet.
- Deck plus fort → avancer vers le boss → recommencer une nouvelle partie.

## Player goal & fail state — what "working" looks like
- **But :** battre le Champion d'arène en fin d'acte 1, ce qui fait évoluer le starter (écran de victoire).
- **Défaite :** la barre de PV commune de l'équipe tombe à 0 → la partie est perdue, on recommence depuis le début.

## MVP — what must exist to be the game
- **Combat à cartes** : 3 énergies/tour, pioche/main/défausse, cartes d'attaque et de protection, intention de l'ennemi affichée.
- **Départ au choix** : 1 Pokémon parmi 3 (starters / route 1, 3 types différents, tirés au hasard) ; deck de départ de 10 cartes de ce Pokémon ; une seule barre de PV pour toute l'équipe (améliorable via événements et objets).
- **Types** : les 18 types, doubles types compris (multiplicateurs multipliés) ; super efficace ×1,5 / pas très efficace ×0,5 / immunité ×0 (comme dans les jeux : ex. Normal → Spectre, Sol → Vol).
- **Cartes Pokémon et switch** : chaque carte d'attaque porte un Pokémon ; la jouer fait entrer ce Pokémon (le même reste s'il est déjà actif) ; protection / renforcement ne font pas changer ; les ennemis frappent le Pokémon actif selon ses types.
- **Vol de carte** : après combat, choisir 1 carte parmi 3, dont une carte d'un Pokémon mis K.O. ; les autres cartes sont portées par des Pokémon des premières routes (toutes générations) du type de la carte.
- **Carte de l'acte 1** : chemins avec combats, élites, Centre Pokémon (repos), Poké Mart (boutique), boss Champion.
- **Objets** : ~10 objets tenus (équivalent reliques : Restes, Bandeau…) + ~5 potions à usage unique.
- **Évolution** : battre le Champion fait évoluer le Pokémon de départ (nouvelles cartes) → écran de victoire.

## Out of scope — not building this
- Autres starters, actes 2 et 3, Dracaufeu.
- Tous les Pokémon : seulement ceux des premières routes / starters, toutes générations (~50). Les Pokémon sont des données, donc en ajouter = ajouter des fiches.
- PV individuels par Pokémon, K.O. individuels (barre de PV commune à la place).
- Sauvegarde en cours de partie, méta-progression / déblocages.
- Son, animations élaborées, multijoueur.
- Publication / distribution publique (propriété intellectuelle Pokémon).

## Build order
1. Un combat contre 1 ennemi avec des cartes simples — prouver que le cœur est fun.
2. Intentions ennemies + plusieurs ennemis par combat.
3. Types et multiplicateurs.
4. Récompenses avec vol d'attaque.
5. Carte de l'acte (génération des chemins et des salles).
5b. (ajouté 2026-10-19) 18 types et doubles types → cartes Pokémon et switch → Pokémon des premières routes, toutes générations.
6. Objets tenus, potions, Centre Pokémon et Poké Mart.
7. Boss Champion + évolution + écran de victoire.

---
**Who it's for / what they feel:** Fans de Pokémon et de deckbuilders qui veulent des parties de 30–45 min où chaque choix de carte compte.

**Art & audio direction:** Sprites pixel officiels (PokéAPI), interface de cartes simple et lisible ; pas de son au début.

**Reference game:** Slay the Spire — l'acte 1 avec un seul personnage ; pas d'ascension ni de déblocages. Le switch de Pokémon actif est notre twist.
