# Rapport d'équilibrage — it21

Parties simulées : **3000** (commit 2843002, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **1058 / 3000 = 35.3 %** (IC 95 % Wilson : 33.6 – 37.0 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 16 | 0.5 % | 0.5 % |
| zone1_elite | 15 | 0.5 % | 0.5 % |
| zone1_boss | 66 | 2.2 % | 2.2 % |
| zone2_wild | 5 | 0.2 % | 0.2 % |
| zone2_elite | 8 | 0.3 % | 0.3 % |
| zone2_boss | 71 | 2.4 % | 2.5 % |
| zone3_wild | 40 | 1.3 % | 1.4 % |
| zone3_elite | 86 | 2.9 % | 3.1 % |
| zone3_boss | 86 | 2.9 % | 3.2 % |
| zone4_wild | 40 | 1.3 % | 1.5 % |
| zone4_elite | 62 | 2.1 % | 2.4 % |
| zone4_boss | 104 | 3.5 % | 4.2 % |
| zone5_wild | 29 | 1.0 % | 1.2 % |
| zone5_elite | 48 | 1.6 % | 2.0 % |
| zone5_boss | 45 | 1.5 % | 1.9 % |
| zone6_wild | 55 | 1.8 % | 2.4 % |
| zone6_elite | 48 | 1.6 % | 2.2 % |
| zone6_boss | 134 | 4.5 % | 6.2 % |
| zone7_wild | 115 | 3.8 % | 5.6 % |
| zone7_elite | 75 | 2.5 % | 3.9 % |
| zone7_boss | 75 | 2.5 % | 4.0 % |
| zone8_wild | 71 | 2.4 % | 4.0 % |
| zone8_elite | 32 | 1.1 % | 1.9 % |
| zone8_boss | 118 | 3.9 % | 7.0 % |
| league_member_1 | 2 | 0.1 % | 0.1 % |
| league_member_2 | 6 | 0.2 % | 0.4 % |
| league_member_3 | 13 | 0.4 % | 0.8 % |
| league_member_4 | 20 | 0.7 % | 1.3 % |
| league_champion | 94 | 3.1 % | 6.2 % |
| league_eternatus | 363 | 12.1 % | 25.5 % |
| **Victoire** | 1058 | 35.3 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 97 |
| 1 | 84 |
| 2 | 212 |
| 3 | 206 |
| 4 | 122 |
| 5 | 237 |
| 6 | 265 |
| 7 | 221 |
| 8 | 1556 |

### Progression garantie (exigence joueur du 2026-10-24)

| Mesure | Valeur | Repère joueur |
|---|---:|---|
| Parties avec au moins 3 badges | 86.9 % | >= 75 % |
| Parties qui atteignent le Conseil 4 | 51.9 % | >= 50 % |
| Défaites en zone 1 (toutes salles) | 3.2 % des parties | <= 5 % |
| Étape la plus meurtrière : league_eternatus | 18.7 % des défaites (12.1 % des parties) | <= ~20 % des défaites |
| Victoire parmi les parties qui atteignent Éthernatos | 74.5 % | difficile mais battable |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 3000 | 47.1 |
| Zone 2 | 2903 | 74.1 |
| Zone 3 | 2819 | 98.0 |
| Zone 4 | 2607 | 114.3 |
| Zone 5 | 2401 | 114.9 |
| Zone 6 | 2279 | 148.4 |
| Zone 7 | 2042 | 141.7 |
| Zone 8 | 1777 | 159.9 |
| Ligue | 1556 | 474.8 |

## Moyennes par partie

- Combats : 29.3; badges : 6.13
- Taille du deck en fin de partie : 26.4 (parties gagnées : 28.2)
- Potions utilisées : 2.87; potions achetées : 0.64; objets tenus : 8.84

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 19083 | 699 | 3.7 % |
| elite | 4319 | 374 | 8.7 % |
| league | 9129 | 498 | 5.5 % |
| wild | 55279 | 371 | 0.7 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| normal | 518 | 188 | 36.3 % |
| water | 432 | 169 | 39.1 % |
| grass | 391 | 89 | 22.8 % |
| bug | 315 | 80 | 25.4 % |
| fire | 258 | 82 | 31.8 % |
| electric | 170 | 72 | 42.4 % |
| poison | 128 | 50 | 39.1 % |
| ghost | 94 | 46 | 48.9 % |
| rock | 93 | 31 | 33.3 % |
| dark | 92 | 35 | 38.0 % |
| ground | 88 | 45 | 51.1 % |
| psychic | 88 | 28 | 31.8 % |
| dragon | 82 | 46 | 56.1 % |
| steel | 63 | 28 | 44.4 % |
| ice | 62 | 21 | 33.9 % |
| fairy | 51 | 14 | 27.5 % |
| fighting | 47 | 22 | 46.8 % |
| flying | 28 | 12 | 42.9 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 363 |
| dragonite | 94 |
| rhyperior | 49 |
| emboar | 35 |
| garchomp | 32 |
| mamoswine | 29 |
| skeledirge | 27 |
| seismitoad | 26 |
| baxcalibur | 25 |
| golem | 25 |
| coalossal | 24 |
| ceruledge | 24 |
| glimmora | 24 |
| archaludon | 23 |
| infernape | 23 |

Rencontres où l'on meurt le plus : `final_eternatus` (363), `league_champion` (94), `league_steel` (12), `league_ghost` (10), `league_fighting` (6), `league_dark` (5), `trio_r4` (4), `league_ice` (4), `league_psychic` (4), `trio_vol` (4)

Contrôles : combats bloqués (plafond de tours) = 0; actions refusées par le jeu = 0.

## Joueur automatique (« correct, pas expert »)

Auto-player policy of the balance simulator (story 019): "correct, not expert". Deterministic given its RNG seed.
Every knob lives in DEFAULTS below (documented); override any of them with `--policy=<file.json>` on the simulator
command line (JSON object, same keys). The policy only calls LEGAL game actions and counts any refused one in
`illegal_moves` (must stay 0; checked by the scratch test t21).
Summary of the policy
 - Starter: picks one of the 3 proposals at random (the player has no information), or the first (`starter_pick`).
 - Map: Centre when HP < center_hp_frac, elite only when HP > elite_min_hp_frac, Mart when money >= mart_min_money,
   otherwise wild, then event (see MAP_SCORES).
 - Battle (per decision, repeated until nothing is worth playing): potions (heal below potion_heal_hp_frac or against a
   lethal threat, cures when a status is on, boosters in elite / gym / league fights) -> block first if the shown attacks
   total >= block_first_fraction of (HP + block) -> status skills on healthy targets -> attacks on the lowest-HP enemy
   (target order = lowest HP+block), best final damage per energy, never an immune (x0) target -> spare energy on block.
 - Rewards: score = (damage + block_weight*block + status_weight*status value) / max(cost, 0.5) + coverage bonus
   (new types hit super-effectively), take if >= take_min_score, never > max_copies copies of a low-value card,
   deck cap max_deck_size (then only cards >= replace_min_score).
 - Centre: heal if HP < center_heal_below_frac else upgrade the card with the best score gain. Mart: see play_mart.
 - Events: first option without HP loss / card loss.
Number of game actions the game refused (must be 0).
Id of the room to enter among `reachable` (ordered ids); ties are broken by the policy RNG (deterministic).
Plays the whole battle. `st` is a stats dictionary the caller owns (keys used: "potions_used" is counted by the caller).
Returns true if the fight was left unfinished (turn cap): the caller treats it as a defeat.
Returns true if a potion was drunk (the caller then re-evaluates).
Next card to play: {"index": hand index, "target": enemy index (-1 if none)} or {} (nothing worth playing).
Base value of a card per energy (no deck context).
Types (ids) that some attack card of the deck hits for >= coverage_min_mult.
Score of adding `c` to `deck` (-INF = never).
Index of the offer to take (-1 = skip). `offers` are CardData.
Centre Pokémon: heal or upgrade (applied through RunState, like Main).
Poké Mart: heal potion -> best item -> remove one basic card -> good card -> fill the belt with potions.
Option index of an event: the first option that loses neither HP nor a card (else the first).

Paramètres (`tools/balance/sim_policy.gd`, surchargeables par `--policy=fichier.json`) :

```gdscript
const DEFAULTS: Dictionary = {
	## "random" | "first": how the starter is picked among the 3 proposals.
	"starter_pick": "random",
	## Map: HP fraction under which a reachable Centre is preferred over everything.
	"center_hp_frac": 0.5,
	## Map: elite rooms are only entered above this HP fraction.
	"elite_min_hp_frac": 0.7,
	## Map: a Mart is preferred when the run holds at least this much money.
	"mart_min_money": 150,
	## Map: base preference of each room type (higher = preferred), before the HP / money rules above.
	"map_scores": {"wild": 30.0, "event": 20.0, "elite": 25.0, "center": 5.0, "mart": 3.0, "boss": 100.0},
	## Battle: block first when the total of shown attacks >= this fraction of (current HP + block).
	"block_first_fraction": 0.4,
	## Battle: a pure status skill is played only on a target with at least this much HP + block (not about to die).
	"status_min_target_hp": 12,
	## Battle: energy value of a 0-cost card when ranking damage per energy.
	"zero_cost_energy": 0.5,
	## Battle: score bonus for a hit that kills its target.
	"kill_bonus": 20.0,
	## Battle: drink a heal potion below this HP fraction.
	"potion_heal_hp_frac": 0.4,
	## Battle: use "booster" potions (damage +, energy +, draw) in these room types only.
	"booster_rooms": ["boss", "league", "elite"],
	## Battle: safety cap on player turns / actions per turn (a stalled fight counts as a defeat).
	"max_turns": 80,
	"max_actions_per_turn": 40,
	## Reward scoring.
	"block_weight": 0.8,
	"status_weight": 1.0,
	"coverage_bonus": 0.4,
	"coverage_min_mult": 2.0,
	"skill_bonus_if_few": 1.5,
	"desired_skills": 4,
	"take_min_score": 5.0,
	"max_copies": 2,
	"low_value_score": 7.5,
	"max_deck_size": 25,
	"replace_min_score": 9.0,
	## Centre: heal below this HP fraction, else upgrade.
	"center_heal_below_frac": 0.7,
	## Mart: card bought only when score >= this; remove one basic card once per run; item rating per effect point.
	"mart_buy_card_min_score": 7.5,
	"mart_remove_once": true,
	"mart_min_item_rating": 4.0,
	"item_effect_weight": {"energy_up_per_turn": 12.0, "draw_up": 9.0, "max_hp_up": 0.6, "damage_bonus": 2.5, "heal_flat": 0.7,
			"block_flat": 0.6, "money_bonus_on_win": 0.15, "status_immunity": 2.0, "heal_percent_max": 0.2},
}
```
