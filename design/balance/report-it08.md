# Rapport d'équilibrage — it08

Parties simulées : **600** (commit 01eb4a9, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **208 / 600 = 34.7 %** (IC 95 % Wilson : 31.0 – 38.6 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 19 | 3.2 % | 3.2 % |
| zone1_elite | 17 | 2.8 % | 2.9 % |
| zone1_boss | 17 | 2.8 % | 3.0 % |
| zone2_wild | 0 | 0.0 % | 0.0 % |
| zone2_elite | 2 | 0.3 % | 0.4 % |
| zone2_boss | 10 | 1.7 % | 1.8 % |
| zone3_wild | 4 | 0.7 % | 0.7 % |
| zone3_elite | 11 | 1.8 % | 2.1 % |
| zone3_boss | 13 | 2.2 % | 2.5 % |
| zone4_wild | 14 | 2.3 % | 2.8 % |
| zone4_elite | 13 | 2.2 % | 2.6 % |
| zone4_boss | 17 | 2.8 % | 3.5 % |
| zone5_wild | 7 | 1.2 % | 1.5 % |
| zone5_elite | 6 | 1.0 % | 1.3 % |
| zone5_boss | 8 | 1.3 % | 1.8 % |
| zone6_wild | 13 | 2.2 % | 2.9 % |
| zone6_elite | 13 | 2.2 % | 3.0 % |
| zone6_boss | 24 | 4.0 % | 5.8 % |
| zone7_wild | 19 | 3.2 % | 4.8 % |
| zone7_elite | 14 | 2.3 % | 3.8 % |
| zone7_boss | 8 | 1.3 % | 2.2 % |
| zone8_wild | 13 | 2.2 % | 3.7 % |
| zone8_elite | 6 | 1.0 % | 1.8 % |
| zone8_boss | 13 | 2.2 % | 3.9 % |
| league_member_1 | 1 | 0.2 % | 0.3 % |
| league_member_2 | 3 | 0.5 % | 0.9 % |
| league_member_3 | 2 | 0.3 % | 0.6 % |
| league_member_4 | 4 | 0.7 % | 1.3 % |
| league_champion | 33 | 5.5 % | 10.7 % |
| league_eternatus | 68 | 11.3 % | 24.6 % |
| **Victoire** | 208 | 34.7 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 53 |
| 1 | 12 |
| 2 | 28 |
| 3 | 44 |
| 4 | 21 |
| 5 | 50 |
| 6 | 41 |
| 7 | 32 |
| 8 | 319 |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 600 | 59.4 |
| Zone 2 | 547 | 71.9 |
| Zone 3 | 535 | 99.1 |
| Zone 4 | 507 | 116.7 |
| Zone 5 | 463 | 119.4 |
| Zone 6 | 442 | 147.1 |
| Zone 7 | 392 | 138.9 |
| Zone 8 | 351 | 150.0 |
| Ligue | 319 | 473.1 |

## Moyennes par partie

- Combats : 28.2; badges : 5.93
- Taille du deck en fin de partie : 25.7 (parties gagnées : 28.3)
- Potions utilisées : 2.88; potions achetées : 0.62; objets tenus : 8.53

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 3666 | 110 | 3.0 % |
| elite | 827 | 82 | 9.9 % |
| league | 1850 | 111 | 6.0 % |
| wild | 10585 | 89 | 0.8 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| water | 97 | 44 | 45.4 % |
| normal | 84 | 28 | 33.3 % |
| grass | 76 | 13 | 17.1 % |
| bug | 66 | 18 | 27.3 % |
| fire | 55 | 18 | 32.7 % |
| electric | 31 | 16 | 51.6 % |
| dark | 23 | 9 | 39.1 % |
| poison | 22 | 7 | 31.8 % |
| rock | 21 | 3 | 14.3 % |
| ghost | 20 | 10 | 50.0 % |
| ground | 17 | 8 | 47.1 % |
| fighting | 15 | 5 | 33.3 % |
| fairy | 15 | 2 | 13.3 % |
| dragon | 14 | 7 | 50.0 % |
| psychic | 14 | 4 | 28.6 % |
| steel | 12 | 9 | 75.0 % |
| ice | 12 | 5 | 41.7 % |
| flying | 6 | 2 | 33.3 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 68 |
| dragonite | 33 |
| skeledirge | 10 |
| salamence | 10 |
| rhyperior | 7 |
| ursaluna | 7 |
| garchomp | 6 |
| nidoking | 6 |
| geodude | 5 |
| infernape | 5 |
| emboar | 5 |
| typhlosion | 5 |
| decidueye | 5 |
| empoleon | 5 |
| coalossal | 5 |

Rencontres où l'on meurt le plus : `final_eternatus` (68), `league_champion` (33), `league_steel` (4), `trio_r6` (3), `league_fighting` (3), `elite_1` (3), `league_psychic` (2), `roster:torkoal,simisear` (2), `elite_3` (2), `elite_2` (2)

Contrôles : combats bloqués (plafond de tours) = 4; actions refusées par le jeu = 0.

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
