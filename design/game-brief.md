# Game Brief: Pokémon Spire (titre provisoire)

<!-- Fiche d'une page — au niveau `minimal`, c'est le document de design complet. -->
<!-- Projet perso, non publié : utilise les Pokémon et sprites officiels (PokéAPI). -->

**One-sentence pitch:** Un roguelike deckbuilder façon Slay the Spire où l'on guide son starter sur une route Pokémon, en volant les attaques des Pokémon vaincus et en évoluant jusqu'au Champion d'arène.

## Core loop
- Choisir son chemin sur la carte : combat sauvage, Dresseur élite, Centre Pokémon, Poké Mart, événement.
- Combattre avec ses cartes d'attaque (offensives / défensives) en gérant son énergie chaque tour.
- Après la victoire : choisir 1 nouvelle attaque parmi 3 (souvent celles du Pokémon vaincu), parfois un objet.
- Deck plus fort → avancer vers le boss → recommencer une nouvelle partie.

## Player goal & fail state — what "working" looks like
- **But :** battre le Champion d'arène en fin d'acte 1, ce qui fait évoluer le starter (écran de victoire).
- **Défaite :** les PV du starter tombent à 0 → la partie est perdue, on recommence depuis le début.

## MVP — what must exist to be the game
- **Combat à cartes** : 3 énergies/tour, pioche/main/défausse, cartes d'attaque et de protection, intention de l'ennemi affichée.
- **Un starter — Salamèche** : deck de départ de 10 cartes + ~25 cartes à gagner.
- **Types simplifiés** : super efficace ×1,5 / pas très efficace ×0,5.
- **Vol d'attaque** : après combat, choisir 1 carte parmi 3, dont celles du Pokémon battu.
- **Carte de l'acte 1** : chemins avec combats, élites, Centre Pokémon (repos), Poké Mart (boutique), boss Champion.
- **Objets** : ~10 objets tenus (équivalent reliques : Restes, Bandeau…) + ~5 potions à usage unique.
- **Évolution** : battre le Champion fait évoluer Salamèche en Reptincel (nouvelles cartes) → écran de victoire.

## Out of scope — not building this
- Autres starters, actes 2 et 3, Dracaufeu.
- Toutes les générations d'emblée : ~20 Pokémon ennemis au départ. Les Pokémon sont des données (data-driven), donc en ajouter = ajouter des fiches.
- Sauvegarde en cours de partie, méta-progression / déblocages.
- Son, animations élaborées, multijoueur.
- Publication / distribution publique (propriété intellectuelle Pokémon).

## Build order
1. Un combat contre 1 ennemi avec des cartes simples — prouver que le cœur est fun.
2. Intentions ennemies + plusieurs ennemis par combat.
3. Types et multiplicateurs.
4. Récompenses avec vol d'attaque.
5. Carte de l'acte (génération des chemins et des salles).
6. Objets tenus, potions, Centre Pokémon et Poké Mart.
7. Boss Champion + évolution + écran de victoire.

---
**Who it's for / what they feel:** Fans de Pokémon et de deckbuilders qui veulent des parties de 30–45 min où chaque choix de carte compte.

**Art & audio direction:** Sprites pixel officiels (PokéAPI), interface de cartes simple et lisible ; pas de son au début.

**Reference game:** Slay the Spire — l'acte 1 avec un seul personnage ; pas d'ascension ni de déblocages.
