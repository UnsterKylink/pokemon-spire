# Rapport d'équilibrage — rob-seed99

Parties simulées : **1000** (commit df894d2, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **353 / 1000 = 35.3 %** (IC 95 % Wilson : 32.4 – 38.3 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 50 | 5.0 % | 5.0 % |
| zone1_elite | 21 | 2.1 % | 2.2 % |
| zone1_boss | 47 | 4.7 % | 5.1 % |
| zone2_wild | 3 | 0.3 % | 0.3 % |
| zone2_elite | 5 | 0.5 % | 0.6 % |
| zone2_boss | 24 | 2.4 % | 2.7 % |
| zone3_wild | 17 | 1.7 % | 2.0 % |
| zone3_elite | 25 | 2.5 % | 3.0 % |
| zone3_boss | 19 | 1.9 % | 2.4 % |
| zone4_wild | 18 | 1.8 % | 2.3 % |
| zone4_elite | 20 | 2.0 % | 2.6 % |
| zone4_boss | 27 | 2.7 % | 3.6 % |
| zone5_wild | 7 | 0.7 % | 1.0 % |
| zone5_elite | 8 | 0.8 % | 1.1 % |
| zone5_boss | 9 | 0.9 % | 1.3 % |
| zone6_wild | 21 | 2.1 % | 3.0 % |
| zone6_elite | 26 | 2.6 % | 3.8 % |
| zone6_boss | 27 | 2.7 % | 4.1 % |
| zone7_wild | 27 | 2.7 % | 4.3 % |
| zone7_elite | 16 | 1.6 % | 2.7 % |
| zone7_boss | 17 | 1.7 % | 2.9 % |
| zone8_wild | 24 | 2.4 % | 4.2 % |
| zone8_elite | 12 | 1.2 % | 2.2 % |
| zone8_boss | 21 | 2.1 % | 4.0 % |
| league_member_1 | 2 | 0.2 % | 0.4 % |
| league_member_2 | 7 | 0.7 % | 1.4 % |
| league_member_3 | 2 | 0.2 % | 0.4 % |
| league_member_4 | 4 | 0.4 % | 0.8 % |
| league_champion | 31 | 3.1 % | 6.3 % |
| league_eternatus | 110 | 11.0 % | 23.8 % |
| **Victoire** | 353 | 35.3 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 118 |
| 1 | 32 |
| 2 | 61 |
| 3 | 65 |
| 4 | 24 |
| 5 | 74 |
| 6 | 60 |
| 7 | 57 |
| 8 | 509 |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 1000 | 60.8 |
| Zone 2 | 882 | 74.4 |
| Zone 3 | 850 | 96.2 |
| Zone 4 | 789 | 114.7 |
| Zone 5 | 724 | 115.2 |
| Zone 6 | 700 | 143.1 |
| Zone 7 | 626 | 142.0 |
| Zone 8 | 566 | 150.9 |
| Ligue | 509 | 460.2 |

## Moyennes par partie

- Combats : 27.1; badges : 5.65
- Taille du deck en fin de partie : 25.2 (parties gagnées : 28.3)
- Potions utilisées : 2.61; potions achetées : 0.57; objets tenus : 8.14

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 5837 | 191 | 3.3 % |
| elite | 1359 | 133 | 9.8 % |
| league | 2971 | 156 | 5.3 % |
| wild | 16923 | 167 | 1.0 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| normal | 148 | 46 | 31.1 % |
| water | 144 | 63 | 43.8 % |
| bug | 127 | 38 | 29.9 % |
| grass | 126 | 20 | 15.9 % |
| fire | 90 | 41 | 45.6 % |
| electric | 42 | 21 | 50.0 % |
| poison | 39 | 12 | 30.8 % |
| dark | 38 | 18 | 47.4 % |
| ghost | 35 | 15 | 42.9 % |
| ground | 34 | 9 | 26.5 % |
| psychic | 30 | 10 | 33.3 % |
| dragon | 25 | 16 | 64.0 % |
| steel | 23 | 12 | 52.2 % |
| fairy | 22 | 8 | 36.4 % |
| flying | 21 | 7 | 33.3 % |
| rock | 21 | 8 | 38.1 % |
| fighting | 19 | 3 | 15.8 % |
| ice | 16 | 6 | 37.5 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 110 |
| dragonite | 31 |
| emboar | 10 |
| archaludon | 10 |
| ursaluna | 9 |
| baxcalibur | 9 |
| skeledirge | 8 |
| aegislash | 8 |
| honedge | 8 |
| naganadel | 7 |
| chandelure | 7 |
| seismitoad | 7 |
| rhyperior | 7 |
| nidoking | 7 |
| centiskorch | 7 |

Rencontres où l'on meurt le plus : `final_eternatus` (110), `league_champion` (31), `league_steel` (8), `roster:honedge` (5), `league_ghost` (4), `trio_r10` (3), `solo_taillow` (3), `solo_pikipek` (3), `trio_vol` (3), `roster:sandygast` (2)

Contrôles : combats bloqués (plafond de tours) = 21; actions refusées par le jeu = 0.

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
