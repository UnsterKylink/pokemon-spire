# Identités de cartes par type (story 028)

> Source : `design/revue-complete-2026-11.md` §3.1 (étape A.1). Données : `assets/data/cards.json`.
> Grammaire des effets : story 027 (`_doc` de `cards.json`, `src/battle/effect_spec.gd`).

## Règles communes

- **Deck de départ inchangé** : 5 attaques de base + 4 Abri + 2 attaques fortes. Les 36 cartes `starter`
  restent de simples « Inflige X dégâts » (lisibles au premier combat).
- **Compétences typées** : une compétence peut porter un `type` (couleur et thème de la carte). Ce type
  n'a **aucun effet** de type en combat (pas de multiplicateur, pas de porteur, pas d'Élan). Abri reste neutre.
- **Signature** : chaque type a au moins une rare qui pousse son identité à l'extrême (colonne « Signature »).
- **Gabarit de puissance** (repère, l'équilibrage fin est en story 031) : 1 énergie ≈ 6–7 dégâts ou
  6–7 points de protection ; un effet (statut, pioche, soin…) coûte 2–4 dégâts ; un coût 0 ≈ 3–4 dégâts.
- **Texte** : environ 60 caractères maximum. Un même nombre ne doit pas apparaître deux fois dans une
  description, car l'amélioration remplace les nombres.

## Les 18 identités

| Type | Rôle | Effets favoris | Statut signature | Faiblesse (ce que le type ne fait pas) | Exemples | Signature (rare) |
|---|---|---|---|---|---|---|
| Normal | Polyvalent, remplissage solide | multi-coups, pioche, Force (Danse-Lames), Rétention | Faiblesse (léger) | Aucun pic : jamais le meilleur dans un domaine | Combo-Griffe, Vive-Attaque, Météores, Stockage | Ultralaser (30, Épuisement) |
| Feu | Gros coups qui brûlent | Brûlure, Force pour ce tour, perte de PV | Brûlure | Peu de protection, se blesse | Crocs Feu, Nitrocharge, Zénith, Feu Follet | Boutefeu (18, Brûlure 3, -4 PV) |
| Eau | Tenir et durer | protection, soin, Rétention | — | Dégâts moyens, peu de statuts | Pistolet à O, Bulle d'O, Repli, Anneau Hydro | Hydrocanon (20 + 10 protection, Rétention) |
| Plante | Durée et ressources | soin, Poison léger, pioche, zone légère | Poison (léger) | Coups faibles, peu de protection | Vole-Vie, Fouet Lianes, Vampigraine, Synthèse | Tempête Verte (14, soin 4, pioche 2) |
| Électrik | Tempo | énergie, Paralysie, multi-coups | Paralysie | Fragile, se blesse (Éclair Fou) | Étincelle, Poing-Éclair, Rayon Chargé, Chargeur | Tonnerre (7 ×3, Paralysie) |
| Glace | Contrôle défensif | Gel, protection, Faiblesse, zone | Gel | Peu de dégâts bruts, Gel avec Épuisement sur la rare | Éclats Glace, Poing-Glace, Grêle, Brume | Blizzard (zone 10 + Gel, Épuisement) |
| Combat | Discipline : rester en jeu | Force, multi-coups, « si déjà actif » | — | Puni si l'on change souvent de Pokémon | Poing-Karaté, Coup-Croix, Gonflette, Big Splash | Close Combat (5 ×4) |
| Poison | Usure qui s'empile | Poison cumulatif, bonus si la cible est empoisonnée, Faiblesse | Poison | Inutile contre Poison / Acier (immunisés), lent | Dard-Venin, Choc Venin, Crochet Venin, Toxik | Bombe Beurk / Poudre Toxik (Poison 5 à tous) |
| Sol | Lent mais lourd | zone, gros coûts, Faiblesse de zone | Faiblesse | Coûts élevés, peu de pioche | Ampleur, Massd'Os, Tunnel, Jet de Sable | Séisme (14 à tous) |
| Vol | Vitesse | pioche, coût 0, conditions d'Élan | — | Petits nombres, peu de protection | Acrobatie, Tornade, Lame d'Air, Vent Arrière | Rapace (12, 2 coups avec 3 Élan, -3 PV) |
| Psy | Cartes et contrôle | pioche, Faiblesse, Vulnérable, Sommeil | Vulnérable | Dégâts directs modestes | Choc Mental, Coupe Psycho, Hâte, Hypnose | Psycho-Boost (18, pioche 2, Épuisement) |
| Insecte | Essaim | multi-coups faibles, Poison, zone, Faiblesse de zone | Poison | Chaque coup est petit (protection ennemie) | Dard-Nuée, Double-Dard, Sécrétion, Papillodanse | Bourdon (9 à tous + Vulnérable à tous) |
| Roche | Mur qui frappe fort | protection, dégâts = protection, gros coûts | Vulnérable (Piège de Roc) | Coûts élevés, peu de pioche | Jet de Pierres, Garde Large, Roulade | Fracass'Tête (2 × protection, -4 PV) |
| Spectre | Malédictions | Vulnérable, Épuisement, Sommeil, perte de PV | Vulnérable | Cartes à usage unique, se blesse | Léchouille, Ombre Portée, Malédiction, Cauchemar | Hantise (18, Vulnérable 2, Épuisement) |
| Dragon | Montée en puissance | conditions d'Élan, gros coups, Force | — | Faible si l'on change de Pokémon (perd l'Élan) | Draco-Souffle, Draco-Griffe, Danse Draco | Draco Météore (24, +8 avec 3 Élan) / Vibrécaille |
| Ténèbres | Opportuniste | bonus si la cible a un statut / Faiblesse / peu de PV, prochaine attaque + | Faiblesse | Faible sur une cible saine et sans statut | Morsure, Tranche-Nuit, Tricherie, Machination | Vibrobscur (10, Faiblesse 2, +6 si statut) |
| Acier | Protection qui frappe | protection + dégâts, protection par ennemi, dégâts = protection | — | Peu de statuts, dégâts moyens | Griffe Acier, Queue de Fer, Gyroballe, Mur de Fer | Luminocanon (8 + protection) |
| Fée | Soutien | soin, Faiblesse (Charme), bonus si la cible a Faiblesse | Faiblesse | Dégâts faibles | Vent Féérique, Câlinerie, Doux Baiser, Rayon Lune | Pouvoir Lunaire (12, Faiblesse 2, soin 4) |

## Synergies voulues entre types

- **Faiblesse → Ténèbres / Fée** : Psy, Fée, Insecte, Sol et Glace appliquent Faiblesse ; Tricherie et Choc
  Émotionnel en profitent.
- **Vulnérable → multi-coups** : Spectre, Psy et Roche posent Vulnérable ; Combat, Insecte et Électrik
  frappent plusieurs fois.
- **Protection → dégâts** : Eau, Glace et Acier gagnent de la protection ; Big Splash, Luminocanon,
  Avalanche et Fracass'Tête la convertissent en dégâts.
- **Garder ou changer de Pokémon** : Combat et Dragon récompensent le Pokémon resté actif (« déjà actif »,
  Élan). Insecte (Demi-Tour) et Eau (Aqua-Jet) récompensent celui qui vient d'entrer.

## Points ouverts (story 031)

- Coûts et nombres sont des premiers jets ; seul « jeu gagnable » est vérifié au simulateur.
- Les compétences sont typées pour le thème seulement : l'événement `add_card_of_type` peut désormais
  proposer une compétence du type. C'est à vérifier en jeu.
