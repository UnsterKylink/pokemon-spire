# Rapport d'équilibrage — rob-seed99

Parties simulées : **1000** (commit 2843002, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **381 / 1000 = 38.1 %** (IC 95 % Wilson : 35.1 – 41.2 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 5 | 0.5 % | 0.5 % |
| zone1_elite | 8 | 0.8 % | 0.8 % |
| zone1_boss | 20 | 2.0 % | 2.0 % |
| zone2_wild | 2 | 0.2 % | 0.2 % |
| zone2_elite | 6 | 0.6 % | 0.6 % |
| zone2_boss | 25 | 2.5 % | 2.6 % |
| zone3_wild | 13 | 1.3 % | 1.4 % |
| zone3_elite | 24 | 2.4 % | 2.6 % |
| zone3_boss | 23 | 2.3 % | 2.6 % |
| zone4_wild | 17 | 1.7 % | 1.9 % |
| zone4_elite | 18 | 1.8 % | 2.1 % |
| zone4_boss | 29 | 2.9 % | 3.5 % |
| zone5_wild | 12 | 1.2 % | 1.5 % |
| zone5_elite | 14 | 1.4 % | 1.8 % |
| zone5_boss | 15 | 1.5 % | 1.9 % |
| zone6_wild | 21 | 2.1 % | 2.7 % |
| zone6_elite | 22 | 2.2 % | 2.9 % |
| zone6_boss | 46 | 4.6 % | 6.3 % |
| zone7_wild | 39 | 3.9 % | 5.7 % |
| zone7_elite | 13 | 1.3 % | 2.0 % |
| zone7_boss | 21 | 2.1 % | 3.3 % |
| zone8_wild | 23 | 2.3 % | 3.8 % |
| zone8_elite | 11 | 1.1 % | 1.9 % |
| zone8_boss | 33 | 3.3 % | 5.8 % |
| league_member_1 | 3 | 0.3 % | 0.6 % |
| league_member_2 | 4 | 0.4 % | 0.7 % |
| league_member_3 | 4 | 0.4 % | 0.8 % |
| league_member_4 | 2 | 0.2 % | 0.4 % |
| league_champion | 34 | 3.4 % | 6.5 % |
| league_eternatus | 112 | 11.2 % | 22.7 % |
| **Victoire** | 381 | 38.1 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 33 |
| 1 | 33 |
| 2 | 60 |
| 3 | 64 |
| 4 | 41 |
| 5 | 89 |
| 6 | 73 |
| 7 | 67 |
| 8 | 540 |

### Progression garantie (exigence joueur du 2026-10-24)

| Mesure | Valeur | Repère joueur |
|---|---:|---|
| Parties avec au moins 3 badges | 87.4 % | >= 75 % |
| Parties qui atteignent le Conseil 4 | 54.0 % | >= 50 % |
| Défaites en zone 1 (toutes salles) | 3.3 % des parties | <= 5 % |
| Étape la plus meurtrière : league_eternatus | 18.1 % des défaites (11.2 % des parties) | <= ~20 % des défaites |
| Victoire parmi les parties qui atteignent Éthernatos | 77.3 % | difficile mais battable |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 1000 | 47.7 |
| Zone 2 | 967 | 74.0 |
| Zone 3 | 934 | 96.6 |
| Zone 4 | 874 | 113.9 |
| Zone 5 | 810 | 114.8 |
| Zone 6 | 769 | 150.4 |
| Zone 7 | 680 | 141.9 |
| Zone 8 | 607 | 156.6 |
| Ligue | 540 | 465.3 |

## Moyennes par partie

- Combats : 29.5; badges : 6.18
- Taille du deck en fin de partie : 26.4 (parties gagnées : 28.2)
- Potions utilisées : 2.84; potions achetées : 0.60; objets tenus : 8.93

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 6393 | 212 | 3.3 % |
| elite | 1463 | 116 | 7.9 % |
| league | 3159 | 159 | 5.0 % |
| wild | 18439 | 132 | 0.7 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| normal | 148 | 52 | 35.1 % |
| water | 144 | 60 | 41.7 % |
| bug | 127 | 46 | 36.2 % |
| grass | 126 | 27 | 21.4 % |
| fire | 90 | 38 | 42.2 % |
| electric | 42 | 16 | 38.1 % |
| poison | 39 | 11 | 28.2 % |
| dark | 38 | 16 | 42.1 % |
| ghost | 35 | 19 | 54.3 % |
| ground | 34 | 15 | 44.1 % |
| psychic | 30 | 13 | 43.3 % |
| dragon | 25 | 15 | 60.0 % |
| steel | 23 | 14 | 60.9 % |
| fairy | 22 | 9 | 40.9 % |
| flying | 21 | 13 | 61.9 % |
| rock | 21 | 8 | 38.1 % |
| fighting | 19 | 5 | 26.3 % |
| ice | 16 | 4 | 25.0 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 112 |
| dragonite | 34 |
| nidoking | 13 |
| salamence | 12 |
| emboar | 11 |
| baxcalibur | 11 |
| garchomp | 11 |
| gyarados | 10 |
| hydreigon | 9 |
| gholdengo | 8 |
| rhyperior | 8 |
| coalossal | 8 |
| aerodactyl | 8 |
| kingambit | 7 |
| dracozolt | 7 |

Rencontres où l'on meurt le plus : `final_eternatus` (112), `league_champion` (34), `league_steel` (5), `elite_rock` (4), `elite_3` (3), `league_ghost` (3), `trio_r8` (2), `league_fighting` (2), `elite_grass` (2), `trio_r10` (2)

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
