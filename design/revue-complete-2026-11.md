# Revue complète du jeu — 16 novembre 2026

Revue faite sur la version `main` (commit 804b4b3) : captures de tous les écrans rejouées
(jeux de captures 007, 012, 013, 014, 016, 017, 018, 020b), lecture des données
(`assets/data/`), du dernier rapport d'équilibrage (`design/balance/report-post018.md`,
2000 parties simulées) et de l'état du code. Je n'ai pas joué une partie à la main :
le ressenti (rythme, plaisir) reste à confirmer par toi et par des testeurs.

## 1. Verdict en une phrase

Le jeu est complet de bout en bout et joli par endroits, mais **la profondeur des cartes
est trop faible pour tenir une partie aussi longue**, et **il ne peut pas être publié tel
quel à cause de la licence Pokémon**. Ce sont les deux sujets à traiter avant tout le reste.

## 2. Ce qui est solide

- Boucle complète : starter → 8 zones → rival ×4 → Conseil 4 → Maître → Éthernatos, avec sauvegarde.
- Le twist « jouer une carte fait entrer son Pokémon » est une vraie identité.
- 720 Pokémon, 18 types, capture, évolutions, statuts, légendaires : beaucoup de contenu.
- Tout est en données (JSON) : on peut rééquilibrer et ajouter sans toucher au code.
- Un simulateur d'équilibrage qui joue 2000 parties : rare pour un projet de cette taille.
- Décors peints, cartes de région, effets d'attaque par type, Pokémon animés.

## 3. Boucle de jeu — les problèmes, du plus grave au moins grave

### 3.1 Les cartes ne font presque que « infliger X dégâts » (critique)
Sur 133 cartes : 123 attaques, 10 compétences. Effets existants : dégâts, protection (7 cartes),
statut (19), soin (2), une seule attaque de zone. **Aucune carte ne pioche, ne donne d'énergie,
ne frappe plusieurs fois, ne se renforce, ne s'épuise, ne réagit à une autre carte.**
Conséquences :
- les trois cartes proposées en récompense se comparent d'un coup d'œil (« 13 dégâts » contre « 13 dégâts ») ;
- pas de « build » : on ne construit pas un deck poison, un deck protection, un deck multi-coups ;
- les tours se ressemblent du combat 1 au combat 45.
C'est ce qui sépare le plus le jeu de Slay the Spire, bien plus que le visuel.

### 3.2 Le twist « switch » est sous-exploité (important)
Le Pokémon actif change la défense (ses types), et c'est tout. Rien ne récompense le fait de
rester sur un Pokémon ou d'en changer (pas de talent, pas de bonus d'entrée, pas de synergie
entre cartes du même Pokémon). L'idée la plus originale du jeu n'a presque pas de règles autour.

### 3.3 Une partie est très longue pour ce qu'elle propose (important)
Une partie gagnée = environ 45 à 50 combats (29 en moyenne toutes parties confondues), soit
2 à 3 heures à la main. Le brief visait 30–45 minutes. Avec des cartes aussi simples, la
deuxième moitié risque d'être répétitive. Il faut soit raccourcir, soit rendre chaque zone différente.

### 3.4 Les ennemis sont tous du même moule (important)
Trois actions seulement : attaquer, se protéger, se renforcer. Les Champions, le Conseil 4 et
Éthernatos sont des ennemis normaux avec plus de PV : pas de phases, pas de mécanique propre.

### 3.5 Objets peu variés (moyen)
15 objets, dont 4 baies d'immunité et 3 de PV max. Aucun ne change la façon de jouer.
Slay the Spire en a plus de 150 ; ici il en faudrait au moins 40, dont des objets « à build ».

### 3.6 Équilibre entre starters très inégal (moyen)
Taux de victoire simulé selon le type du starter : de 17,5 % (Combat) à 61,3 % (Spectre).
Le choix du départ décide trop de la partie. Mur aussi au premier membre du Conseil 4
(16,4 % de ceux qui l'atteignent y perdent, contre moins de 1 % pour les trois suivants).

### 3.7 Rien ne persiste entre les parties (moyen)
Pas de déblocages, pas de Pokédex, pas de niveaux de difficulté, pas de statistiques.
C'est ce qui fait relancer une partie. (Stories 025 et 026 prévues.)

### 3.8 La capture n'est pas mesurée
Le simulateur ne capture jamais : on ne sait pas si capturer est trop fort ou inutile.

## 4. Esthétique

- **Trois styles de Pokémon mélangés** : sprites animés en combat (pixel pour les anciens,
  rendu 3D pour les récents), illustrations officielles sur les cartes, petits sprites pixel
  fixes ailleurs (starter, évolution, rival, événements). C'est le défaut visuel n° 1.
- **Sprites de dos flous** : ils sont petits et étirés ×2 (Salamèche de dos est une tache beige).
- **Sprites larges déformés** : Goélise occupe un tiers de l'écran dans le combat du rival.
- **Deux langages d'interface** : panneaux blancs à cadre bleu (carte) et panneaux sombres
  violets (rival, événements, Mart). Il faut n'en garder qu'un.
- **Événements sans image** : un petit panneau de texte au milieu d'un écran vide.
- **Combat chargé** : en mode capture, 9 boutons flottent sur les ennemis ; « Super efficace ! »
  recouvre l'intention de l'ennemi.
- **Mart** : les articles déjà achetés ou « pleins » sont presque illisibles.
- **Pas d'écran titre** (ton image existe mais n'est pas affichée), pas de transitions entre écrans.
- Les décors peints et les cartes de région sont le point fort : c'est le niveau à atteindre partout.

## 5. Ce qui manque pour un jeu « présentable »

- **Son** : aucun (story 022).
- **Menu principal, pause, options, tutoriel, infobulles des mots-clés** (story 023).
- **Souris seulement** : pas de clavier ni de manette ; résolution fixe 1280×720.
- **Textes en dur en français** : aucune traduction possible aujourd'hui.
- **Pas de version .exe** (story 024) ; les raccourcis de test sont encore dans le jeu.
- **Accessibilité** : pas de taille de texte réglable, pas de mode daltonien (les types reposent sur la couleur).

## 6. Technique

- **Les tests ne sont pas dans le dépôt** : 39 scripts de test vivent dans un dossier temporaire
  de cette session et peuvent disparaître. À rapatrier dans `tests/`.
- **Dépôt lourd** : 513 Mo d'historique git, 194 Mo d'images (décors JPG de 2–3 Mo chacun en
  2752×1536, alors que le jeu affiche du 1280×720). À réduire avant tout export.
- **Captures 013 (Conseil 4) bloquées** : le script de captures reste coincé sur l'écran du rival
  final. À vérifier : défaut du script ou vrai blocage en jeu.
- 3 erreurs de script dans les jeux de captures 007 / 012 / 013 (dans l'outil de test, pas constaté en jeu).
- `battle_screen.gd` dépasse 1500 lignes : il faudra le découper.

## 7. Publication : le point bloquant

**Le jeu utilise les noms, sprites et illustrations Pokémon : il ne peut pas être vendu, et même
une diffusion gratuite expose à un retrait** (Nintendo / The Pokémon Company font fermer les
fan-games qui gagnent en visibilité). Le brief le dit d'ailleurs : « Publication : hors périmètre ».
Trois voies :

1. **Rester privé** (toi et tes amis) : rien à changer.
2. **Fan-game gratuit** : possible techniquement, mais sans garantie ; il peut être retiré du jour au lendemain. Jamais d'argent.
3. **Jeu original publiable** : remplacer les Pokémon par des créatures, noms, types et objets à toi.
   Tout étant en données, le code suit sans réécriture ; le gros du travail est artistique
   (créatures, cartes, icônes) et il faut vérifier les droits des images générées par IA.

Ce choix change la suite : inutile d'intégrer 720 Pokémon de plus si on vise la voie 3.

## 8. Plan proposé

**Étape A — Profondeur du combat (le plus rentable)**
1. Nouveaux effets de cartes : pioche, énergie, multi-coups, attaque de zone, épuisement,
   renforcement, « si le Pokémon était déjà actif… », « à l'entrée sur le terrain… ».
2. Règles autour du switch : un talent par Pokémon, bonus d'entrée, synergies par Pokémon / par type.
3. 40+ objets, dont des objets qui orientent un deck.
4. Ennemis : nouvelles actions (statuts, affaiblir, invoquer), Champions et boss avec une mécanique propre.
5. Rééquilibrage au simulateur (et lui apprendre à capturer).

**Étape B — Rythme** : raccourcir la partie (par exemple 4 salles par zone ou un mode court à 4 badges),
rendre chaque zone différente (règle de terrain par type d'arène).

**Étape C — Cohérence visuelle** : un seul style de Pokémon partout, un seul langage d'interface,
images d'événements, écran titre, transitions.

**Étape D — Finition déjà prévue** : son (022), menu / options / tutoriel (023), .exe (024),
Pokédex (025), difficulté (026), plus clavier / manette et tests dans le dépôt.

**Décision à prendre avant l'étape C** : voie 1, 2 ou 3 pour la publication.
