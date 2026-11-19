# Crash test — version du 19 novembre 2026

Version testée : `main`, commit 589ee9f (les 35 stories sont terminées). Rien n'a été corrigé : ce document liste les problèmes.

**Ce qui a été fait :**
- **Tests et simulations.** 4 × 1000 parties simulées, au niveau de difficulté 0 (deux fois, avec un autre tirage au hasard), au niveau 5 et au niveau 10. Tous les scripts de test ont été lancés.
- **Fichiers abîmés.** Des sauvegardes, des options, des statistiques et un Pokédex abîmés exprès.
- **Cas extrêmes.** Un deck vide, un deck de 72 cartes, tous les objets en même temps, tous les starters au niveau 10.
- **Contrôle visuel.** 25 jeux de captures d'écran, tous les écrans regardés un par un.
- **Relecture du code.** Environ 60 % du code relu à la main.

Captures citées : `production/qa/evidence/crash-test-2026-11-19/`.

**Gravité :**
- **S1** : le jeu plante, ou la partie est bloquée.
- **S2** : tout joueur le voit, et c'est gênant.
- **S3** : un vrai bug, mais rare ou d'impact modéré.
- **S4** : finition, ou cas très improbable.

## Verdict

- **Aucun S1.** Aucun plantage du jeu en 4000 parties simulées.
- **Aucune impasse sur la carte.**
- **Aucun coup illégal.**
- **Les sauvegardes et les reprises marchent depuis tous les écrans.**
- **L'équilibrage tient :**

  | Niveau de difficulté | Parties gagnées |
  |---|---|
  | 0 | 35,3 % (35,4 % avec un autre tirage) |
  | 5 | 19,5 % |
  | 10 | 8,4 % |

La version est **solide pour jouer**. Les problèmes sont surtout visuels, et la plupart des bugs n'arrivent qu'avec un fichier abîmé.

---

## S2 — à corriger en premier

| id | Problème | Preuve |
|---|---|---|
| B-01 / B-12 | **Le bouton « Nouvelle partie » est à moitié coupé** par le bas de la fenêtre, sur l'écran de victoire comme sur celui de défaite. | `B-12-bouton-coupe-defaite.png` |
| B-11 | **Une bande noire apparaît en bas de l'écran de combat**, derrière la main, contre Éthernatos (138 px), les légendaires et dans l'arène Psy. **La cause est dans les images** `ethernatos.jpg`, `legendary.jpg` et `psychic.jpg` : leur bas n'est pas peint. On peut soit refaire ou recadrer ces 3 images, soit étirer le décor pour qu'il remplisse l'écran. | `B-11-bande-noire-*.png` |
| K-02 | **Le .exe n'a jamais tourné sur un vrai PC Windows.** On n'a mesuré ni les 60 images par seconde, ni l'icône du .exe. C'est à toi de le vérifier. | — |

## S3 — vrais bugs, mais rares ou modérés

### En jeu

| id | Problème | Effet pour le joueur |
|---|---|---|
| C-103 | **Le premier clic est avalé pendant une animation de combat**, même s'il vise le bouton « Fermer » du deck, un onglet ou une bulle du tutoriel. | Un bouton semble ne pas répondre. |
| C-104 | **Le clavier agit derrière le deck ouvert.** Sur l'écran de récompense, Entrée, Espace ou Tab peuvent prendre ou passer une récompense pendant que le deck est affiché par-dessus. | Récompense choisie sans le vouloir. |
| A-05 / C-006 | **Environ 1 % des combats ne finit jamais** : ni le joueur ni l'ennemi n'arrive à gagner. C'est surtout en zone 1, contre des trios d'ennemis. Le jeu n'a pas de limite de tours. | La partie tourne en rond. Il faut abandonner. |
| C-005 | **Une victoire est comptée à tort** si la zone suivante n'arrive pas à démarrer (erreur de données). | Statistiques faussées. Ne devrait pas arriver avec les données actuelles. |
| C-003 | **« Continuer » ne remet pas à zéro tout l'état de la partie**, contrairement à « Nouvelle partie ». | Possible reste de la partie précédente après un abandon. Non observé. |
| C-001 / C-002 | **Les animations de combat avancent pendant la pause.** Abandonner pendant une animation peut aussi provoquer des erreurs. | Erreurs en console, pas de plantage observé. |
| C-016 | **Les textes de résultat des événements utilisent le signe « ₽ »**, que la police n'a peut-être pas. Le palier Pokédex « dex_50 » aussi. | Possible carré vide à la place du symbole. Non observé. |

### Affichage

| id | Problème | Preuve |
|---|---|---|
| B-06 / B-20 | **Le bandeau « Règle de zone » ou « Règle de terrain » cache les ennemis du milieu** et leurs PV pendant 2 à 3 secondes. Ça arrive dans les combats sauvages, les arènes et contre Éthernatos. | `B-06-banniere-couvre-ennemi.png` |
| B-08 | **Le texte blanc de la ligne d'infos est peu lisible sur les décors clairs** : PV, Pioche, Défausse, Deck. On le voit sur le décor Fée et sur la prairie du tutoriel. | `B-08-B-10-contraste-tutoriel.png` |
| B-19 | **La fin de la ligne d'infos est coupée par « … »** : « Ton équipe dort : −2 … », « Ball : … ». L'information est perdue. | `B-19-ligne-info-tronquee.png` |
| B-02 | **Le bandeau « Palier du Pokédex débloqué » cache l'en-tête de la carte** (zone, PV). | `B-02-banniere-palier.png` |
| B-03 | **Sur la fiche Pokédex, le nom des mini-cartes « Cartes enseignées » est coupé en haut.** | `B-03-fiche-mini-cartes.png` |
| B-10 | **La bulle du tutoriel (étape 5) recouvre la barre du haut** et coupe le talent. | `B-08-B-10-contraste-tutoriel.png` |

### Fichiers de sauvegarde, options, statistiques et Pokédex

Ces bugs n'arrivent **que si un fichier est abîmé** : coupure de courant pendant l'écriture, modification à la main ou disque plein.

| id | Problème | Effet |
|---|---|---|
| C-101 | **Le Pokédex ou les statistiques abîmés sont effacés.** Le jeu repart de zéro et écrase l'ancien fichier, sans copie de secours. | Pokédex, niveaux de difficulté débloqués et statistiques perdus. |
| C-017 | **La sauvegarde peut disparaître.** Si l'écriture échoue deux fois de suite, il ne reste plus aucune sauvegarde. | Partie en cours perdue. |
| A-01 | **Un fichier de statistiques avec une mauvaise valeur casse l'écran titre.** Exemple : `"tutorial_done": "no"`. | Des erreurs s'affichent. La difficulté débloquée, le liseré de prestige et le Pokémon du titre ne marchent plus. On peut quand même jouer. |
| A-02 | **Une sauvegarde avec certains champs mal remplis bloque la reprise.** | Écran vide au moment de reprendre, sans moyen d'en sortir. |
| A-03 | **Le contrôle des sauvegardes accepte des valeurs absurdes** : argent −1, taille de main −1, niveau de difficulté « x ». | La partie reprend avec des valeurs fausses. |
| A-04 | **Un fichier d'options avec une mauvaise valeur provoque une erreur.** Le volume n'est pas non plus limité à 100 %. | Erreur en console, l'option revient à « non ». |

### Performance (non mesurée, déduite de la lecture du code)

| id | Problème |
|---|---|
| C-009 | **Le style des menus est réappliqué à tous les textes de l'écran toutes les 12 images.** Ça peut coûter cher sur les grands écrans (deck, Pokédex). À vérifier sur ton PC. |

### Tests et outils

| id | Problème |
|---|---|
| A-06 | **Le test t10 échoue une fois sur 1000** : l'écran de récompense propose parfois moins de 3 cartes, ou un doublon. C'est **peut-être un vrai bug**. La cause n'a pas été trouvée. |
| A-07 | **Le test t14 ne parvient pas à perdre en zone 4 après une victoire.** Ça peut venir de l'outil de test ou d'un vrai bug sur la défaite après une nouvelle partie. À examiner. |
| A-08 | **Le test t17 a 2 échecs connus** sur les cartes Fée `calinerie` et `pouvoir_lunaire`. Les données ont changé depuis l'écriture du test. |
| H-01 à H-04 | **Le script de captures d'écran est cassé sur 4 jeux** : default, 007, 012 et 013. Pour le jeu 013, il ne dépasse pas le rival d'avant le Conseil 4. **Le Conseil 4 n'a donc pas été contrôlé visuellement.** Rien ne prouve un bug du jeu : il marche dans les parties simulées. |

## S4 — finitions et cas très improbables

**Textes**
- « a remporté les 0 badges » : le pluriel n'est pas géré (B-04).
- « Choisissez une cible » vouvoie le joueur, alors que tout le jeu le tutoie (B-09).
- Le même mécanisme s'appelle « Règle de zone » à un endroit et « Règle de terrain » à un autre (B-18).
- Date de sauvegarde en format anglais « 2026-11-19 20:57:36 » (B-14).
- Option d'événement grisée : « Il te faut 110 P$ » au lieu de « Il te manque 80 P$ » (B-15).
- La carte « Zénith » porte le même nom que la règle de l'arène Feu. « Big Splash » et « Mach Punch » sont en anglais (C-024).

**Affichage**
- « Protection 0 » est toujours affiché, même à 0 (B-07).
- Liste des modificateurs mal alignée au niveau 10 (B-05).
- Une ligne du deck de fin de partie est grise et les autres noires (B-13).
- Après une capture, l'emplacement garde l'ancienne intention et la barre de PV (B-16).
- La pastille de mot-clé cache le rôle de la carte (B-17).
- Le texte flottant est peu lisible sur la prairie (B-21).
- Des cartes de compétence sans Pokémon montrent un cercle vide (B-22).

**Règles**
- Une carte « Épuisement » ratée à cause de la paralysie va à la défausse au lieu d'être épuisée (C-007).
- Une salle « garantie » (Centre ou Mart) peut très rarement manquer sur un étage (C-106).
- Un objet de poids 0 peut tomber très rarement (C-110).
- Double clic sur « Continuer » après une défaite : l'écran de fin s'affiche deux fois (C-021).

**Données et code**
- Quelques valeurs de jeu sont écrites en dur dans le code (C-008).
- 3 raccourcis de test ne sont pas désactivés dans le .exe (C-013, sans risque).
- Fichiers de code très longs : game_data 3423 lignes, battle_screen 2913, main 2430 (C-014).
- Textes français écrits en dur (C-015).
- Environ 4 Mo de fichiers inutiles (C-025).
- Les niveaux de difficulté 2 et 9 changent très peu le jeu (C-023).

**Performance**
- De petites allocations à chaque image en combat (C-010, C-011, C-113).
- Le Pokédex est sauvegardé à chaque combat (C-012).
- Les options sont relues sur le disque à chaque changement d'écran (C-018, C-019).
- Le cache des cris n'est jamais vidé (C-020).

**Erreurs en console sans effet visible**
- Erreur `!is_inside_tree` en combat (H-05).
- « Lambda capture freed » après une défaite (A-10).
- Avertissement de mise en page des Options (A-16).
- Débordement de l'argent au-delà de 9 milliards de milliards (A-13).

**Outils de test**
- `t.gd` et `tail16.gd` ne se lancent plus.
- t2, t4, t5, t5b et t8 vérifient des règles d'avant la story 032.
- `t5.gd` se bloque.
- `t4.gd` ne signale jamais ses échecs (A-14, A-15).
- Les tests sont des scripts dans `tests/scratch`, pas une vraie suite gdUnit4 (K-06).
- Plantage du moteur seulement si un script de test réutilise un écran de combat déjà fermé. Un joueur ne peut pas le provoquer (A-11, A-12).

## Problèmes déjà connus, toujours ouverts (rappel)

- **Licence Pokémon (K-01).** Le jeu ne peut pas être publié tel quel. Ton choix actuel : rester privé.
- **Poids (K-03).** Le .exe fait 215 Mo et l'historique git 728 Mo.
- **Équilibrage (K-04).** Les starters Insecte, Vol et Psy sont faibles (environ 25 % de victoires). La capture n'est pas mesurée par le simulateur.
- **Clavier et manette (K-10).** Pas de clavier ni de manette, infobulles seulement à la souris, barre de PV qui descend d'un coup sur une attaque à plusieurs coups.
- **Accessibilité (K-13).** Pas d'option pour réduire les animations, pas de taille de texte réglable, pas de mode daltonien.
- **Pokédex (K-17).** Pas d'accès au Pokédex depuis le menu pause.
- **Longueur d'une partie gagnée (K-24).** À confirmer en jouant réellement.

## Non vérifié (aucune conclusion possible)

- **Le .exe exporté n'a pas été lancé**, ni ici ni sur Windows.
- **Ni les sons ni le nombre d'images par seconde n'ont été vérifiés.**
- **Le Conseil 4 n'a pas été contrôlé visuellement** (voir H-04).
- **Plusieurs écrans n'ont pas été relus dans le code** : Mart, Centre, événement, évolution, Conseil 4, badge, titre, Pokédex, et environ la moitié de l'écran de combat. Ils ont été vus en capture, mais leur code n'a pas été lu en détail.
- **Une vraie partie jouée par un humain** : c'est ton propre test qui la remplacera.

## Ordre de correction proposé

1. **Lot 1 — S2 visuels**, rapide : bouton coupé (B-01, B-12) et bande noire (B-11).
2. **Lot 2 — bugs en jeu** :
   - premier clic avalé et clavier derrière le deck (C-103, C-104) ;
   - limite de tours pour les combats sans fin (C-006 et A-05, règle à choisir) ;
   - victoire comptée à tort, reprise mal remise à zéro, animations pendant la pause (C-005, C-003, C-001, C-002) ;
   - symbole ₽ (C-016) ;
   - écran de récompense : comprendre l'échec du test t10 (A-06), puis corriger s'il s'agit d'un vrai bug.
3. **Lot 3 — affichage en combat** :
   - bandeaux qui cachent les ennemis (B-06, B-20, B-02) ;
   - lisibilité sur les décors clairs (B-08) ;
   - ligne d'infos coupée (B-19) ;
   - fiche Pokédex (B-03) et bulle du tutoriel (B-10).
4. **Lot 4 — fichiers abîmés** : copie de secours `.bak` et vérification des types (C-101, C-017, A-01 à A-04).
5. **Lot 5 — outils de test** : réparer le script de captures pour contrôler le Conseil 4, mettre à jour ou supprimer les tests périmés, comprendre l'échec du test t14.
6. **Lot 6 — finitions S4**, au choix.
