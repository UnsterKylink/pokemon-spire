# Rapport d'équilibrage — post018

Parties simulées : **1000** (commit cbf99c6, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **451 / 1000 = 45.1 %** (IC 95 % Wilson : 42.0 – 48.2 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 9 | 0.9 % | 0.9 % |
| zone1_elite | 7 | 0.7 % | 0.7 % |
| zone1_boss | 19 | 1.9 % | 1.9 % |
| zone2_wild | 4 | 0.4 % | 0.4 % |
| zone2_elite | 9 | 0.9 % | 0.9 % |
| zone2_boss | 26 | 2.6 % | 2.7 % |
| zone3_wild | 10 | 1.0 % | 1.1 % |
| zone3_elite | 25 | 2.5 % | 2.7 % |
| zone3_boss | 11 | 1.1 % | 1.2 % |
| zone4_wild | 13 | 1.3 % | 1.5 % |
| zone4_elite | 17 | 1.7 % | 2.0 % |
| zone4_boss | 21 | 2.1 % | 2.5 % |
| zone5_wild | 0 | 0.0 % | 0.0 % |
| zone5_elite | 7 | 0.7 % | 0.8 % |
| zone5_boss | 7 | 0.7 % | 0.9 % |
| zone6_wild | 26 | 2.6 % | 3.2 % |
| zone6_elite | 16 | 1.6 % | 2.0 % |
| zone6_boss | 23 | 2.3 % | 3.0 % |
| zone7_wild | 16 | 1.6 % | 2.1 % |
| zone7_elite | 8 | 0.8 % | 1.1 % |
| zone7_boss | 3 | 0.3 % | 0.4 % |
| zone8_wild | 6 | 0.6 % | 0.8 % |
| zone8_elite | 3 | 0.3 % | 0.4 % |
| zone8_boss | 18 | 1.8 % | 2.5 % |
| league_member_1 | 35 | 3.5 % | 5.0 % |
| league_member_2 | 2 | 0.2 % | 0.3 % |
| league_member_3 | 0 | 0.0 % | 0.0 % |
| league_member_4 | 0 | 0.0 % | 0.0 % |
| league_champion | 3 | 0.3 % | 0.5 % |
| league_eternatus | 36 | 3.6 % | 5.5 % |
| **Victoire** | 451 | 45.1 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 35 |
| 1 | 56 |
| 2 | 46 |
| 3 | 63 |
| 4 | 14 |
| 5 | 198 |
| 6 | 28 |
| 7 | 27 |
| 8 | 533 |

### Progression garantie (exigence joueur du 2026-10-24)

| Mesure | Valeur | Repère joueur |
|---|---:|---|
| Parties avec au moins 3 badges | 86.3 % | >= 75 % |
| Parties qui atteignent le Conseil 4 | 53.3 % | >= 50 % |
| Défaites en zone 1 (toutes salles) | 3.5 % des parties | <= 5 % |
| Étape la plus meurtrière : league_eternatus | 6.6 % des défaites (3.6 % des parties) | <= ~20 % des défaites |
| Victoire parmi les parties qui atteignent Éthernatos | 92.6 % | difficile mais battable |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 1000 | 48.1 |
| Zone 2 | 965 | 95.7 |
| Zone 3 | 909 | 91.3 |
| Zone 4 | 863 | 129.7 |
| Zone 5 | 800 | 102.2 |
| Zone 6 | 786 | 184.0 |
| Zone 7 | 588 | 113.6 |
| Zone 8 | 560 | 224.0 |
| Ligue | 533 | 365.0 |

## Moyennes par partie

- Combats : 29.9; badges : 6.00
- Taille du deck en fin de partie : 26.5 (parties gagnées : 28.6)
- Potions utilisées : 2.76; potions achetées : 0.68; objets tenus : 10.96

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 6132 | 128 | 2.1 % |
| elite | 1254 | 93 | 7.4 % |
| league | 2976 | 76 | 2.6 % |
| legendary | 129 | 2 | 1.6 % |
| legendary_seen | 277 | 0 | 0.0 % |
| legendary_won | 127 | 0 | 0.0 % |
| rival | 2608 | 160 | 6.1 % |
| rival_final | 533 | 6 | 1.1 % |
| wild | 16260 | 84 | 0.5 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| water | 163 | 95 | 58.3 % |
| normal | 157 | 63 | 40.1 % |
| grass | 128 | 40 | 31.2 % |
| bug | 102 | 38 | 37.3 % |
| fire | 91 | 51 | 56.0 % |
| electric | 50 | 23 | 46.0 % |
| poison | 41 | 17 | 41.5 % |
| rock | 35 | 14 | 40.0 % |
| ghost | 34 | 23 | 67.6 % |
| dark | 32 | 17 | 53.1 % |
| ground | 29 | 10 | 34.5 % |
| fighting | 23 | 9 | 39.1 % |
| psychic | 23 | 9 | 39.1 % |
| fairy | 23 | 12 | 52.2 % |
| steel | 21 | 11 | 52.4 % |
| dragon | 20 | 6 | 30.0 % |
| ice | 18 | 10 | 55.6 % |
| flying | 10 | 3 | 30.0 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 36 |
| machamp | 13 |
| rhyperior | 12 |
| aegislash | 11 |
| flygon | 11 |
| centiskorch | 11 |
| annihilape | 11 |
| simisear | 10 |
| garchomp | 10 |
| magcargo | 9 |
| golurk | 9 |
| seismitoad | 9 |
| baxcalibur | 8 |
| darmanitan-standard | 8 |
| ninetales | 8 |

Rencontres où l'on meurt le plus : `final_eternatus` (36), `league_steel` (11), `league_fighting` (7), `league_psychic` (6), `league_ghost` (5), `league_ice` (5), `trio_vol` (4), `league_dark` (3), `league_champion` (3), `elite_2` (2)

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
	"map_scores": {"wild": 30.0, "event": 20.0, "elite": 25.0, "center": 5.0, "mart": 3.0, "boss": 100.0, "rival": 100.0},
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
	"booster_rooms": ["boss", "league", "elite", "rival", "rival_final", "legendary"],
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
