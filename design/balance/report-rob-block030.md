# Rapport d'équilibrage — rob-block030

Parties simulées : **1000** (commit df894d2, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **365 / 1000 = 36.5 %** (IC 95 % Wilson : 33.6 – 39.5 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 53 | 5.3 % | 5.3 % |
| zone1_elite | 17 | 1.7 % | 1.8 % |
| zone1_boss | 31 | 3.1 % | 3.3 % |
| zone2_wild | 1 | 0.1 % | 0.1 % |
| zone2_elite | 3 | 0.3 % | 0.3 % |
| zone2_boss | 20 | 2.0 % | 2.2 % |
| zone3_wild | 17 | 1.7 % | 1.9 % |
| zone3_elite | 27 | 2.7 % | 3.1 % |
| zone3_boss | 20 | 2.0 % | 2.4 % |
| zone4_wild | 15 | 1.5 % | 1.8 % |
| zone4_elite | 23 | 2.3 % | 2.9 % |
| zone4_boss | 36 | 3.6 % | 4.7 % |
| zone5_wild | 8 | 0.8 % | 1.1 % |
| zone5_elite | 13 | 1.3 % | 1.8 % |
| zone5_boss | 9 | 0.9 % | 1.3 % |
| zone6_wild | 24 | 2.4 % | 3.4 % |
| zone6_elite | 18 | 1.8 % | 2.6 % |
| zone6_boss | 21 | 2.1 % | 3.2 % |
| zone7_wild | 31 | 3.1 % | 4.8 % |
| zone7_elite | 19 | 1.9 % | 3.1 % |
| zone7_boss | 18 | 1.8 % | 3.0 % |
| zone8_wild | 24 | 2.4 % | 4.2 % |
| zone8_elite | 10 | 1.0 % | 1.8 % |
| zone8_boss | 37 | 3.7 % | 6.8 % |
| league_member_1 | 0 | 0.0 % | 0.0 % |
| league_member_2 | 0 | 0.0 % | 0.0 % |
| league_member_3 | 3 | 0.3 % | 0.6 % |
| league_member_4 | 4 | 0.4 % | 0.8 % |
| league_champion | 28 | 2.8 % | 5.6 % |
| league_eternatus | 105 | 10.5 % | 22.3 % |
| **Victoire** | 365 | 36.5 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 101 |
| 1 | 24 |
| 2 | 64 |
| 3 | 74 |
| 4 | 30 |
| 5 | 63 |
| 6 | 68 |
| 7 | 71 |
| 8 | 505 |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 1000 | 59.9 |
| Zone 2 | 899 | 74.8 |
| Zone 3 | 875 | 99.9 |
| Zone 4 | 811 | 115.2 |
| Zone 5 | 737 | 115.9 |
| Zone 6 | 707 | 141.5 |
| Zone 7 | 644 | 139.5 |
| Zone 8 | 576 | 157.6 |
| Ligue | 505 | 468.8 |

## Moyennes par partie

- Combats : 27.6; badges : 5.75
- Taille du deck en fin de partie : 25.4 (parties gagnées : 28.2)
- Potions utilisées : 2.65; potions achetées : 0.58; objets tenus : 8.25

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 5946 | 192 | 3.2 % |
| elite | 1335 | 130 | 9.7 % |
| league | 2985 | 140 | 4.7 % |
| wild | 17320 | 173 | 1.0 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| normal | 184 | 65 | 35.3 % |
| water | 132 | 59 | 44.7 % |
| grass | 126 | 19 | 15.1 % |
| bug | 109 | 36 | 33.0 % |
| fire | 85 | 36 | 42.4 % |
| electric | 57 | 22 | 38.6 % |
| rock | 39 | 10 | 25.6 % |
| poison | 37 | 16 | 43.2 % |
| psychic | 33 | 12 | 36.4 % |
| ghost | 32 | 17 | 53.1 % |
| dark | 30 | 12 | 40.0 % |
| dragon | 30 | 13 | 43.3 % |
| ground | 24 | 8 | 33.3 % |
| steel | 21 | 14 | 66.7 % |
| fairy | 19 | 10 | 52.6 % |
| fighting | 18 | 9 | 50.0 % |
| ice | 17 | 4 | 23.5 % |
| flying | 7 | 3 | 42.9 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 105 |
| dragonite | 28 |
| rhyperior | 15 |
| emboar | 13 |
| garchomp | 11 |
| coalossal | 11 |
| skeledirge | 10 |
| mamoswine | 10 |
| golem | 9 |
| cinderace | 9 |
| honedge | 8 |
| excadrill | 8 |
| duraludon | 8 |
| incineroar | 8 |
| glimmora | 7 |

Rencontres où l'on meurt le plus : `final_eternatus` (105), `league_champion` (28), `trio_r4` (4), `roster:pawniard` (3), `elite_2` (3), `trio_r5` (2), `roster:sandygast` (2), `league_ghost` (2), `roster:dreepy` (2), `elite_3` (2)

Contrôles : combats bloqués (plafond de tours) = 24; actions refusées par le jeu = 0.

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
