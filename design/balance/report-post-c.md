# Rapport d'équilibrage — post-c

Parties simulées : **600** (commit 5aca1d9). Mêmes 600 graines que la baseline, APRÈS le type d'attaque des doubles types + 18 cartes ajoutées (avant tout réglage).

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **0 / 600 = 0.0 %** (IC 95 % Wilson : 0.0 – 0.6 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 31 | 5.2 % | 5.2 % |
| zone1_elite | 78 | 13.0 % | 13.7 % |
| zone1_boss | 246 | 41.0 % | 50.1 % |
| zone2_wild | 3 | 0.5 % | 1.2 % |
| zone2_elite | 16 | 2.7 % | 6.6 % |
| zone2_boss | 116 | 19.3 % | 51.3 % |
| zone3_wild | 20 | 3.3 % | 18.2 % |
| zone3_elite | 16 | 2.7 % | 17.8 % |
| zone3_boss | 45 | 7.5 % | 60.8 % |
| zone4_wild | 8 | 1.3 % | 27.6 % |
| zone4_elite | 5 | 0.8 % | 23.8 % |
| zone4_boss | 13 | 2.2 % | 81.2 % |
| zone5_wild | 0 | 0.0 % | 0.0 % |
| zone5_elite | 0 | 0.0 % | 0.0 % |
| zone5_boss | 2 | 0.3 % | 66.7 % |
| zone6_wild | 1 | 0.2 % | 100.0 % |
| zone6_elite | 0 | 0.0 % | - |
| zone6_boss | 0 | 0.0 % | - |
| zone7_wild | 0 | 0.0 % | - |
| zone7_elite | 0 | 0.0 % | - |
| zone7_boss | 0 | 0.0 % | - |
| zone8_wild | 0 | 0.0 % | - |
| zone8_elite | 0 | 0.0 % | - |
| zone8_boss | 0 | 0.0 % | - |
| league_member_1 | 0 | 0.0 % | - |
| league_member_2 | 0 | 0.0 % | - |
| league_member_3 | 0 | 0.0 % | - |
| league_member_4 | 0 | 0.0 % | - |
| league_champion | 0 | 0.0 % | - |
| league_eternatus | 0 | 0.0 % | - |
| **Victoire** | 0 | 0.0 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 355 |
| 1 | 135 |
| 2 | 81 |
| 3 | 26 |
| 4 | 2 |
| 5 | 1 |
| 6 | 0 |
| 7 | 0 |
| 8 | 0 |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 600 | 77.9 |
| Zone 2 | 245 | 92.9 |
| Zone 3 | 110 | 98.8 |
| Zone 4 | 29 | 114.2 |
| Zone 5 | 3 | 157.3 |
| Zone 6 | 1 | 91.0 |
| Zone 7 | 0 | 0.0 |
| Zone 8 | 0 | 0.0 |
| Ligue | 0 | 0.0 |

## Moyennes par partie

- Combats : 6.1; badges : 0.65
- Taille du deck en fin de partie : 15.5
- Potions utilisées : 1.04; potions achetées : 0.21; objets tenus : 0.91

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 810 | 422 | 52.1 % |
| elite | 203 | 115 | 56.7 % |
| wild | 2671 | 63 | 2.4 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| water | 97 | 0 | 0.0 % |
| normal | 84 | 0 | 0.0 % |
| grass | 76 | 0 | 0.0 % |
| bug | 66 | 0 | 0.0 % |
| fire | 55 | 0 | 0.0 % |
| electric | 31 | 0 | 0.0 % |
| dark | 23 | 0 | 0.0 % |
| poison | 22 | 0 | 0.0 % |
| rock | 21 | 0 | 0.0 % |
| ghost | 20 | 0 | 0.0 % |
| ground | 17 | 0 | 0.0 % |
| fighting | 15 | 0 | 0.0 % |
| fairy | 15 | 0 | 0.0 % |
| dragon | 14 | 0 | 0.0 % |
| psychic | 14 | 0 | 0.0 % |
| steel | 12 | 0 | 0.0 % |
| ice | 12 | 0 | 0.0 % |
| flying | 6 | 0 | 0.0 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| arcanine | 22 |
| electabuzz | 18 |
| snorlax | 17 |
| onix | 17 |
| pidgeot | 14 |
| venusaur | 13 |
| roggenrola | 12 |
| vaporeon | 11 |
| crabominable | 11 |
| fuecoco | 10 |
| geodude | 10 |
| hakamo-o | 10 |
| doublade | 9 |
| archaludon | 9 |
| pinsir | 9 |

Rencontres où l'on meurt le plus : `gym_fire` (22), `gym_electric` (18), `gym_normal` (17), `gym_rock` (17), `gym_flying` (14), `gym_grass` (13), `gym_water` (11), `gym_bug` (9), `gym_poison` (9), `elite_2` (7)

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
