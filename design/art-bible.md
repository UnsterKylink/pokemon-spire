# Bible artistique — Pokémon Spire

> Story 020 « Style graphique ». Style validé par le joueur : **« Cartoon vectoriel lumineux »**.
> Code de référence : `src/ui/ui_style.gd` (`UiStyle`, constantes + fabriques de styles) et `src/ui/card_view.gd` (cartes).
> **Tout est dessiné en code** (StyleBoxFlat, `_draw`, dégradés) ; seules images : sprites et artworks officiels des Pokémon.
> **Story 020b « Refonte premium »** (retour joueur : « ça fait jeu flash ») : polices embarquées, textures de matière
> générées en code (Python PIL, `assets/art/ui/`), cadres de carte selon la rareté, effet holographique, survol animé,
> finition d'image globale (`PostFx`). Shaders : `src/ui/shaders/` (`card_*`, `ui_*`, `post_*`).

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

**Story 020b (suite) — polices « esprit Pokémon » (SIL OFL 1.1, licences `OFL.txt` à côté des fichiers)** :
- **Lilita One** (`assets/fonts/lilita_one/`) — display ronde et massive, proche du logo Pokémon : titres d'écran et en-têtes (`UiStyle.font_title()`). Les grands titres (rôle `title`, ou Label d'écran ≥ 36 px sans couleur propre) prennent le **look du logo** : remplissage jaune `#FFCB05`, contour bleu épais `#2A62B8`, ombre portée bleu nuit `#16245E` (`UiStyle.apply_logo`).
- **Jost** (`assets/fonts/jost/`, variable) — sans-serif géométrique façon Futura, proche des jeux Pokémon récents et du JCC : Medium 500 pour le texte et les descriptions (`font_body()`, police par défaut du thème), Bold 700 pour boutons, pastilles et **noms de carte** (`font_bold()`), ExtraBold 800 pour les nombres — PV, énergie, **coût** (`font_number()`, rôle `number`).
- Un Label d'écran de taille ≥ 24 reçoit la police de titre automatiquement (`style_screen`).
- **Police de fan (optionnelle)** : déposez `Pokemon Solid.ttf` (ou n'importe quel `.ttf` / `.otf`) dans `assets/fonts/pokemon/` ; elle remplace automatiquement Lilita One pour tous les titres, sans toucher au code (`UiStyle.fan_font_path()`). Lilita One reste en secours pour les glyphes absents (accents É, é…). Attention : ces polices de fan ne sont pas libres — à n'utiliser que pour un usage personnel.
- Kreon / Nunito (story 020b initiale) ne sont plus utilisées ; leurs dossiers `assets/fonts/kreon/` et `assets/fonts/nunito/` peuvent être supprimés.

Hiérarchie par taille et contour (`UiStyle.apply_label`) :

| Rôle | Taille | Contour | Couleur |
|---|---|---|---|
| `title` (titre d'écran) — look logo | 40 | 8 px bleu `#2A62B8` + ombre | jaune `#FFCB05` |
| `heading` (titre de panneau) | 28 | 6 px | `TEXT` |
| `number` (PV, énergie, coût) — Jost ExtraBold | 22 | 6 px | `TEXT` / accent |
| `body` | 18 | 0 | `TEXT` |
| `caption` (aide, légende) | 15 | 0 | `TEXT_MUTED` |
| `dark` (texte sur crème) | 14–18 | 0 | `TEXT_DARK` |

Carte 170×200 : nom 15, coût 18, description 13 (rétrécit jusqu'à 10 si nécessaire), type / porteur 11. Carte 220×270 : ×1,35.

## 4. Cadres

- Panneau : rayon **14**, contour **3 px** `OUTLINE`, fond `BG_PANEL`, ombre 6 px noir 35 %, marges internes 12/10.
- Bouton : rayon **12**, contour 2 px `OUTLINE` + **bas 5 px** couleur foncée (relief). Survol : +12 % clair. Appuyé : bas 2 px (le bouton « s'enfonce »). Désactivé : gris `#5A6078`, texte `#A0A6BC`. Focus clavier : anneau `ACCENT_YELLOW` 3 px.
- Pastille (badge de type, statut) : rayon 9, contour 2 px, texte 13–16.
- **Finition matière (020b, `ui_sheen.gdshader`)** posée par `style_screen` sur chaque panneau / bouton opaque (StyleBoxFlat inchangé dessous, même rayon, sous le contour) : grain du bruit généré, léger marbrage, lumière douce en haut / ombre en bas, **liseré clair interne** sous le bord haut (biseau). Boutons : lumière plus marquée (dégradé + reflet), pas de grain fort. Panneaux et boutons transparents (< 50 %) : pas de finition.

### Textures générées (`assets/art/ui/`, 512 px sauf bruit 256 px, raccordables)
| Fichier | Matière | Usage |
|---|---|---|
| `ui_noise.png` | bruit gris fractal | grain des panneaux / boutons, grain d'image, étincelles du holo |
| `card_grain.png` | grain presque blanc | fond de carte (multiplie la couleur du type) |
| `ui_parchment.png` | parchemin crème, fibres | bandeau de nom, cartouche de description |
| `card_stone.png` | ardoise bleu-gris veinée | cadre des cartes Départ et Commune |
| `card_silver.png` | argent brossé | cadre des cartes Peu commune |
| `card_gold.png` | or brossé | cadre des cartes Rare et Légendaire |

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
│ │   Pokémon porteur    │ │  (repli : sprite ; sinon rien) ; sans porteur : illustration de l'effet (voir plus bas)
│ │▓▓▓▓ Nom Pokémon ▓▓▓▓▓│ │  pastille de type en haut à droite ; nom du porteur en bas (bande sombre)
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │  description : cartouche crème, texte sombre centré,
│ │  Inflige 6 dégâts.  │ │  13 px (rétrécit jusqu'à 10 px pour tout faire tenir)
│ └─────────────────────┘ │
└──────────◆──────────────┘  gemme de rareté (couleur de rareté) ; légendaire : ruban « Légendaire »
```
Survol : liseré blanc lumineux. Carte injouable : face à 45 % d'opacité (géré par l'écran de combat).

### Carte premium (story 020b, `CardFace`)
- **Cadre en matière selon la rareté** : bande de 6 px (réf. 194 px de haut) en ardoise (Départ / Commune), argent brossé (Peu commune), or (Rare), **or + deux gemmes taillées magenta** sur les côtés (Légendaire, + liseré rose interne). Matière teintée à 10 % par la couleur du type ; le **corps** reste à la couleur du type (dégradé sur grain).
- **Biseau** : liseré clair sur la bande, ombre interne sombre là où le corps passe sous le cadre ; ombre interne en haut de la fenêtre d'illustration et de la description.
- **Bandeau de nom et description en parchemin** (or brossé pour le bandeau légendaire) ; nom en Jost Bold, coût en Jost ExtraBold, description en Jost Medium.
- **Ombre portée douce** sous la carte (3 couches, 4 px ; 9 px au survol).
- **Holo animé** (`card_holo.gdshader`, superposition additive) sur Rare (0,30) et Légendaire (0,40) : bandes arc-en-ciel diagonales qui glissent avec le temps et la souris + étincelles ; atténué à 20 % sur la description pour garder le texte lisible.
- **Survol** (toutes les cartes, jouables ou non) : la face grandit à **×1,08** (pivot en bas au centre, tween 0,14 s), s'**incline jusqu'à 2,5°** vers le curseur, passe au premier plan (z 10) et reçoit un reflet discret qui suit la souris ; le liseré lumineux reste réservé aux cartes jouables. Purement visuel : le bouton garde sa taille, sa place et ses clics.

### Illustration des cartes sans Pokémon porteur (story 020b suite, `EffectArt`)
Plus de Poké Ball : la fenêtre montre l'**effet principal** de la carte, dessiné en code façon effets d'attaque Pokémon (couleurs vives, dégradé doux, contour sombre épais, reflet blanc), déduit des données de la carte (aucun code par carte). Priorité si plusieurs effets : statut > soin > protection > pioche > énergie > force > dégâts. La bande du bas affiche le mot de l'effet au lieu de « Équipe ».

| Effet (donnée) | Dessin | Bande |
|---|---|---|
| `block` > 0 | bulle hexagonale verte à facettes (Abri) | Protection |
| `heal` > 0 | cœur rose + étincelles | Soin |
| `draw` > 0 | trois cartes en éventail | Pioche |
| `energy` > 0 | orbe jaune + éclair | Énergie |
| statut `sleep` | « Zzz » lavande (couleur de `statuses.json`) | Sommeil |
| statut `paralysis` | éclair jaune + étincelles | Paralysie |
| statut `poison` | goutte violette + bulles | Poison |
| statut `burn` | flamme orange à cœur jaune | Brûlure |
| statut `freeze` | cristaux de glace | Gel |
| autre statut / `strength` | flèche rouge montante + étoiles | Renfort |
| `damage` > 0 seul | étoile d'impact orange | Attaque |

## 8. Finition d'image (story 020b, `PostFx`)

`PostFx` (CanvasLayer 120, au-dessus de tout, ignore la souris), ajouté une fois par `Main` ; `post_finish.gdshader` lit l'écran :
| Effet | Réglage par défaut | Remarque |
|---|---|---|
| Étalonnage | saturation ×1,06, contraste ×1,05, ombres légèrement froides / hautes lumières à peine chaudes | doux, la palette reste celle du §2 |
| Vignette | −38 % au bord, début à ~45 % du rayon | recentre le regard |
| Grain | ±2,2 %, rafraîchi 12 fois / s | grain de film, pas de scintillement |
| Halo | **désactivé** (`halo_strength` 0, seuil 0,92) | voilait les décors clairs et adoucissait le texte ; réglage disponible |
Coût : 1 appel de dessin + 1 copie d'écran par image, 2 lectures de texture par pixel (18 avec le halo). `set_enabled(false)` coupe tout (future option graphique).
