# Rapport d'équilibrage — it04

Parties simulées : **600** (commit 01eb4a9, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **1 / 600 = 0.2 %** (IC 95 % Wilson : 0.0 – 0.9 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 19 | 3.2 % | 3.2 % |
| zone1_elite | 25 | 4.2 % | 4.3 % |
| zone1_boss | 17 | 2.8 % | 3.1 % |
| zone2_wild | 0 | 0.0 % | 0.0 % |
| zone2_elite | 2 | 0.3 % | 0.4 % |
| zone2_boss | 10 | 1.7 % | 1.9 % |
| zone3_wild | 4 | 0.7 % | 0.8 % |
| zone3_elite | 17 | 2.8 % | 3.3 % |
| zone3_boss | 14 | 2.3 % | 2.8 % |
| zone4_wild | 13 | 2.2 % | 2.6 % |
| zone4_elite | 19 | 3.2 % | 4.0 % |
| zone4_boss | 14 | 2.3 % | 3.0 % |
| zone5_wild | 9 | 1.5 % | 2.0 % |
| zone5_elite | 12 | 2.0 % | 2.7 % |
| zone5_boss | 45 | 7.5 % | 10.6 % |
| zone6_wild | 49 | 8.2 % | 12.9 % |
| zone6_elite | 25 | 4.2 % | 7.6 % |
| zone6_boss | 73 | 12.2 % | 23.9 % |
| zone7_wild | 32 | 5.3 % | 13.7 % |
| zone7_elite | 11 | 1.8 % | 5.5 % |
| zone7_boss | 22 | 3.7 % | 11.6 % |
| zone8_wild | 14 | 2.3 % | 8.3 % |
| zone8_elite | 10 | 1.7 % | 6.5 % |
| zone8_boss | 21 | 3.5 % | 14.6 % |
| league_member_1 | 5 | 0.8 % | 4.1 % |
| league_member_2 | 28 | 4.7 % | 23.7 % |
| league_member_3 | 39 | 6.5 % | 43.3 % |
| league_member_4 | 26 | 4.3 % | 51.0 % |
| league_champion | 22 | 3.7 % | 88.0 % |
| league_eternatus | 2 | 0.3 % | 66.7 % |
| **Victoire** | 1 | 0.2 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 61 |
| 1 | 12 |
| 2 | 35 |
| 3 | 46 |
| 4 | 66 |
| 5 | 147 |
| 6 | 65 |
| 7 | 45 |
| 8 | 123 |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 600 | 60.2 |
| Zone 2 | 539 | 72.0 |
| Zone 3 | 527 | 99.3 |
| Zone 4 | 492 | 117.4 |
| Zone 5 | 446 | 143.6 |
| Zone 6 | 380 | 182.5 |
| Zone 7 | 233 | 162.4 |
| Zone 8 | 168 | 171.7 |
| Ligue | 123 | 314.1 |

## Moyennes par partie

- Combats : 22.6; badges : 4.85
- Taille du deck en fin de partie : 24.9 (parties gagnées : 29.0)
- Potions utilisées : 2.79; potions achetées : 0.61; objets tenus : 6.97

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 3124 | 216 | 6.9 % |
| elite | 711 | 121 | 17.0 % |
| league | 410 | 122 | 29.8 % |
| wild | 9288 | 140 | 1.5 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| water | 97 | 1 | 1.0 % |
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
| dragonite | 22 |
| aegislash | 21 |
| gengar | 20 |
| salamence | 19 |
| lapras | 18 |
| probopass | 16 |
| banette | 14 |
| machamp | 14 |
| houndoom | 14 |
| emboar | 12 |
| ursaluna | 11 |
| alakazam | 11 |
| seismitoad | 11 |
| swampert | 11 |
| rhyperior | 11 |

Rencontres où l'on meurt le plus : `league_champion` (22), `league_steel` (21), `league_ghost` (20), `league_ice` (18), `league_fighting` (14), `league_dark` (14), `league_psychic` (11), `elite_1` (3), `trio_r2` (2), `elite_fire` (2)

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
