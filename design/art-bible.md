# Bible artistique — Pokémon Spire

> Story 020 « Style graphique ». Style validé par le joueur : **« Cartoon vectoriel lumineux »**.
> Code de référence : `src/ui/ui_style.gd` (`UiStyle`, constantes + fabriques de styles) et `src/ui/card_view.gd` (cartes).
> **Tout est dessiné en code** (StyleBoxFlat, `_draw`, dégradés) ; seules images : sprites et artworks officiels des Pokémon.

## 1. Principes

- Formes **arrondies**, aplats **vifs**, **contour sombre épais** (2–3 px, `OUTLINE`), dégradés **doux** (2 teintes proches, jamais d'arc-en-ciel).
- Lisibilité d'abord : texte clair sur fond sombre **ou** texte sombre sur fond crème ; jamais de texte posé directement sur une couleur de type vive sans contour.
- Écran **1280×720** fixe : rien de coupé, rien qui se chevauche. Marge minimale 8 px au bord de l'écran.
- Un relief « jeu mobile » : bas de bouton plus sombre (4 px), ombre portée douce (4–6 px, noir 35 %).
- Les couleurs ne sont **pas seules porteuses d'information** : chaque couleur de type ou de rareté est doublée d'un texte (nom du type, nom de la rareté).

## 2. Palette

### Neutres d'interface
| Nom | Hex | Usage |
|---|---|---|
| `BG_DEEP` | `#161B33` | fond d'écran (nuit bleutée) |
| `BG_PANEL` | `#252E5A` | panneaux, bandeaux |
| `BG_PANEL_LIGHT` | `#34407A` | panneau survolé, onglet actif |
| `OUTLINE` | `#11142A` | contours, ombres de texte |
| `CREAM` | `#FFF6E0` | cartouches de texte (description de carte, bulles) |
| `TEXT` | `#FFFFFF` | texte principal sur fond sombre |
| `TEXT_MUTED` | `#B4BEDD` | aides, légendes |
| `TEXT_DARK` | `#1E2233` | texte sur crème / couleurs claires |

### Accents
| Nom | Hex | Usage |
|---|---|---|
| `ACCENT_RED` | `#E8402A` | rouge Poké Ball, danger, attaques ennemies |
| `ACCENT_BLUE` | `#3B78E7` | boutons principaux |
| `ACCENT_YELLOW` | `#FFCB05` | énergie, argent, sélection, surbrillance |
| `HP_GREEN` | `#4CD964` | barre de PV pleine (> 50 %) |
| `HP_ORANGE` | `#FFA53A` | PV 25–50 % |
| `HP_RED` | `#FF4F45` | PV < 25 % |
| `BLOCK_BLUE` | `#5AB4FF` | protection |
| `SUCCESS` | `#5BD16E` | gains, confirmations |
| `SKILL` | `#7E9CCF` | cadre des cartes compétence (sans type) |

### Types (source : champ `color` de `assets/data/types.json`, lu par `UiStyle.type_color`)
Normal `#A8A77A` · Feu `#EE8130` · Eau `#6390F0` · Électrik `#F7D02C` · Plante `#7AC74C` · Glace `#96D9D6` ·
Combat `#C22E28` · Poison `#A33EA1` · Sol `#E2BF65` · Vol `#A98FF3` · Psy `#F95587` · Insecte `#A6B91A` ·
Roche `#B6A136` · Spectre `#735797` · Dragon `#6F35FC` · Ténèbres `#705746` · Acier `#B7B7CE` · Fée `#D685AD`.
Le texte posé sur une couleur de type est blanc **avec contour sombre**, ou sombre si la luminance > 0,6.

### Raretés (`UiStyle.rarity_color`)
| Rareté | Hex | Nom affiché |
|---|---|---|
| starter | `#A7B0C0` gris | Départ |
| common | `#E8ECF4` argent | Commune |
| uncommon | `#3FD0C0` turquoise | Peu commune |
| rare | `#FFAA2B` orange doré | Rare |
| légendaire | `#FFD23F` or (+ liseré `#FF7AD9`) | Légendaire |

## 3. Typographie

Police **par défaut de Godot** (pas de police embarquée), hiérarchie par taille et contour (`UiStyle.apply_label`) :

| Rôle | Taille | Contour | Couleur |
|---|---|---|---|
| `title` (titre d'écran) | 40 | 8 px `OUTLINE` | `TEXT` |
| `heading` (titre de panneau) | 28 | 6 px | `TEXT` |
| `number` (PV, énergie, coût) | 22 | 6 px | `TEXT` / accent |
| `body` | 18 | 0 | `TEXT` |
| `caption` (aide, légende) | 15 | 0 | `TEXT_MUTED` |
| `dark` (texte sur crème) | 14–18 | 0 | `TEXT_DARK` |

Carte 170×200 : nom 15, coût 18, description 13 (rétrécit jusqu'à 10 si nécessaire), type / porteur 11. Carte 220×270 : ×1,35.

## 4. Cadres

- Panneau : rayon **14**, contour **3 px** `OUTLINE`, fond `BG_PANEL`, ombre 6 px noir 35 %, marges internes 12/10.
- Bouton : rayon **12**, contour 2 px `OUTLINE` + **bas 5 px** couleur foncée (relief). Survol : +12 % clair. Appuyé : bas 2 px (le bouton « s'enfonce »). Désactivé : gris `#5A6078`, texte `#A0A6BC`. Focus clavier : anneau `ACCENT_YELLOW` 3 px.
- Pastille (badge de type, statut) : rayon 9, contour 2 px, texte 13–16.

## 5. Icônes (toutes dessinées en code)

| Icône | Dessin |
|---|---|
| Énergie / coût | gemme ronde `ACCENT_YELLOW`, reflet blanc en haut à gauche, contour 2 px, chiffre blanc contouré |
| Protection | écusson `BLOCK_BLUE` arrondi, contour sombre |
| PV | cœur `HP_RED` ou barre arrondie (couleur selon le seuil) |
| Combat sauvage | herbe haute / griffe, `#D95C4D` |
| Élite | étoile violette `#AD5CE6` |
| Champion | badge doré octogonal `#FFC238` |
| Rival | éclair / visage, `#F07A3A` |
| Centre Pokémon | croix blanche sur rond rose `#F280B3` |
| Poké Mart | sac / « M » sur rond bleu `#4D99F2` |
| Événement | « ? » sur rond vert `#59BF6B` |
| Légendaire | étoile or `#FFD23F` |
| Balls | `BallIcon` existant |

Chemin parcouru sur la carte : trait épais `ACCENT_YELLOW` (6 px) ; chemins non pris : pointillés `TEXT_MUTED` 40 %.

## 6. Fonds de combat (pour l'agent suivant)

Fond dessiné en code, plein écran derrière le combat : **ciel** (dégradé vertical 2 teintes, haut → horizon), **sol** (bande basse ~35 % de la hauteur, dégradé + 1 ellipse de « plateforme » sous chaque combattant), **silhouettes** (2 plans de formes simples à 50–70 % d'opacité), **particules** optionnelles (≤ 30, lentes, coupées si l'option « réduire les animations » est active). Contraste bas : le fond ne doit jamais concurrencer les cartes et les sprites (assombrir de 25 % sous la zone de la main).

| Zone | Ciel (haut → horizon) | Sol | Silhouettes | Particules |
|---|---|---|---|---|
| Route (sauvage) | `#7EC8F2` → `#D8F1FF` | prairie `#7AC74C` → `#5AA238` | collines rondes, arbres boules | pollen blanc |
| Centre Pokémon | `#FFD6E8` → `#FFF3F8` | carrelage `#F4F1F6` | comptoir, croix rose | bulles roses |
| Normal | `#9FD8F7` → `#EEF8FF` | herbe rase `#B8C77A` | maisons simples | — |
| Feu | `#FF9A52` → `#FFD27A` | roche `#8A4A2E` | volcans, flammes | braises |
| Eau | `#4FA3E8` → `#BFE6FF` | sable `#E8D7A0` + vagues | rochers, vagues | bulles |
| Électrik | `#2E3260` → `#5F64A8` | métal `#6E6A55` | pylônes, câbles | étincelles jaunes |
| Plante | `#8ED66A` → `#E2F7C8` | herbe `#5DA43C` | grands arbres, fougères | feuilles |
| Glace | `#BFE9F2` → `#F4FCFF` | neige `#EAF6FA` | stalagmites de glace | flocons |
| Combat | `#F2B26B` → `#FFE2B8` | ring/tatami `#C9A46A` | piliers de dojo | poussière |
| Poison | `#5B3A78` → `#9A6BB8` | marais `#5E4A6E` | tuyaux, bulles toxiques | bulles violettes |
| Sol | `#E8C37A` → `#FFF0C8` | sable `#CFA458` | dunes, cactus | grains de sable |
| Vol | `#8FC6FF` → `#FFFFFF` | nuages `#F2F6FF` | nuages ronds, pics | plumes |
| Psy | `#C77BE0` → `#FFD0EA` | dalles `#E3B8E8` | colonnes flottantes | orbes roses |
| Insecte | `#A9D86E` → `#EAF7C9` | sous-bois `#6E8A2E` | troncs, toiles | lucioles |
| Roche | `#C9B48A` → `#F1E6CC` | roche `#8F7D4A` | falaises, blocs | gravillons |
| Spectre | `#2A2148` → `#57427E` | dalles `#3A3050` | tombes, tours | feux follets |
| Dragon | `#3A2C8A` → `#7F67E0` | roche `#4F3E7A` | pics, crocs de pierre | écailles lumineuses |
| Ténèbres | `#1E1A2A` → `#3E3550` | pavés `#2F2A3A` | ruelle, lune | — |
| Acier | `#9EB2C8` → `#E4ECF4` | plaques `#A8AFBD` | engrenages, poutres | reflets |
| Fée | `#FFC3E1` → `#FFF0F8` | prairie rose `#F2B8D4` | arcs, fleurs géantes | paillettes |
| Conseil 4 | `#3A2A66` → `#7A5BC0` | marbre `#C9C3D8` | colonnes, bannières | — |
| Éthernatos | `#14081E` → `#5A1238` | arène brisée `#2A1630` | anneaux rouges, cristaux | étoiles rouges |

Un combat sauvage / élite / champion utilise le fond **du type de la zone** ; route = repli si la zone n'a pas de type.

## 7. Carte (spécification)

Tailles inchangées : **170×200** (main, Mart, deck, choix) — rétrécit en largeur jusqu'à ~115 px pour une main de 10 — et **220×270** (récompense, Centre, évolution).
Le bouton appelant garde son anneau extérieur (rareté, sélection, état) ; la face de carte est dessinée 3 px à l'intérieur.

```
┌─────────────────────────┐  cadre : dégradé de la couleur du type (compétence : SKILL),
│(2) [  Nom de la carte  ]│  contour 2,5 px OUTLINE, rayon 8 ; légendaire : contour or 3 px + liseré rose
│ ┌─────────────[Type]──┐ │  coût : gemme jaune (2) ; nom : bandeau crème, texte sombre, rétrécit pour tenir
│ │      artwork du      │ │  fenêtre d'illustration : fond clair du type + halo, artwork officiel
│ │   Pokémon porteur    │ │  (repli : sprite ; sinon rien) ; compétence : Poké Ball + « Équipe »
│ │▓▓▓▓ Nom Pokémon ▓▓▓▓▓│ │  pastille de type en haut à droite ; nom du porteur en bas (bande sombre)
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │  description : cartouche crème, texte sombre centré,
│ │  Inflige 6 dégâts.  │ │  13 px (rétrécit jusqu'à 10 px pour tout faire tenir)
│ └─────────────────────┘ │
└──────────◆──────────────┘  gemme de rareté (couleur de rareté) ; légendaire : ruban « Légendaire »
```
Survol : liseré blanc lumineux. Carte injouable : face à 45 % d'opacité (géré par l'écran de combat).
