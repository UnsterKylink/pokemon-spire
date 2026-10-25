# Rapport d'équilibrage — post018

Parties simulées : **2000** (commit bb4bcbc, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **690 / 2000 = 34.5 %** (IC 95 % Wilson : 32.4 – 36.6 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 17 | 0.8 % | 0.8 % |
| zone1_elite | 10 | 0.5 % | 0.5 % |
| zone1_boss | 41 | 2.0 % | 2.1 % |
| zone2_wild | 4 | 0.2 % | 0.2 % |
| zone2_elite | 19 | 0.9 % | 1.0 % |
| zone2_boss | 45 | 2.2 % | 2.4 % |
| zone3_wild | 26 | 1.3 % | 1.4 % |
| zone3_elite | 54 | 2.7 % | 2.9 % |
| zone3_boss | 31 | 1.6 % | 1.7 % |
| zone4_wild | 28 | 1.4 % | 1.6 % |
| zone4_elite | 35 | 1.8 % | 2.0 % |
| zone4_boss | 65 | 3.2 % | 3.8 % |
| zone5_wild | 8 | 0.4 % | 0.5 % |
| zone5_elite | 29 | 1.4 % | 1.8 % |
| zone5_boss | 21 | 1.1 % | 1.3 % |
| zone6_wild | 37 | 1.9 % | 2.4 % |
| zone6_elite | 33 | 1.6 % | 2.2 % |
| zone6_boss | 72 | 3.6 % | 4.8 % |
| zone7_wild | 52 | 2.6 % | 3.6 % |
| zone7_elite | 27 | 1.4 % | 2.0 % |
| zone7_boss | 21 | 1.1 % | 1.6 % |
| zone8_wild | 18 | 0.9 % | 1.4 % |
| zone8_elite | 14 | 0.7 % | 1.1 % |
| zone8_boss | 38 | 1.9 % | 2.9 % |
| league_member_1 | 206 | 10.3 % | 16.4 % |
| league_member_2 | 6 | 0.3 % | 0.6 % |
| league_member_3 | 5 | 0.2 % | 0.5 % |
| league_member_4 | 2 | 0.1 % | 0.2 % |
| league_champion | 11 | 0.6 % | 1.1 % |
| league_eternatus | 77 | 3.9 % | 7.5 % |
| **Victoire** | 690 | 34.5 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 68 |
| 1 | 94 |
| 2 | 134 |
| 3 | 183 |
| 4 | 70 |
| 5 | 212 |
| 6 | 106 |
| 7 | 70 |
| 8 | 1063 |

### Progression garantie (exigence joueur du 2026-10-24)

| Mesure | Valeur | Repère joueur |
|---|---:|---|
| Parties avec au moins 3 badges | 85.2 % | >= 75 % |
| Parties qui atteignent le Conseil 4 | 53.1 % | >= 50 % |
| Défaites en zone 1 (toutes salles) | 3.4 % des parties | <= 5 % |
| Étape la plus meurtrière : league_member_1 | 15.7 % des défaites (10.3 % des parties) | <= ~20 % des défaites |
| Victoire parmi les parties qui atteignent Éthernatos | 90.0 % | difficile mais battable |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 2000 | 48.3 |
| Zone 2 | 1932 | 95.0 |
| Zone 3 | 1838 | 94.1 |
| Zone 4 | 1704 | 132.3 |
| Zone 5 | 1521 | 108.4 |
| Zone 6 | 1451 | 168.1 |
| Zone 7 | 1239 | 126.8 |
| Zone 8 | 1133 | 255.8 |
| Ligue | 1063 | 298.8 |

## Moyennes par partie

- Combats : 29.3; badges : 5.94
- Taille du deck en fin de partie : 26.5 (parties gagnées : 28.7)
- Potions utilisées : 2.79; potions achetées : 0.61; objets tenus : 10.75

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 12215 | 334 | 2.7 % |
| elite | 2488 | 223 | 9.0 % |
| league | 4898 | 307 | 6.3 % |
| legendary | 267 | 65 | 24.3 % |
| legendary_seen | 583 | 0 | 0.0 % |
| legendary_won | 202 | 0 | 0.0 % |
| rival | 5075 | 125 | 2.5 % |
| rival_final | 1063 | 66 | 6.2 % |
| wild | 32551 | 190 | 0.6 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| normal | 313 | 96 | 30.7 % |
| water | 303 | 141 | 46.5 % |
| grass | 256 | 60 | 23.4 % |
| bug | 224 | 49 | 21.9 % |
| fire | 178 | 70 | 39.3 % |
| electric | 101 | 40 | 39.6 % |
| poison | 86 | 27 | 31.4 % |
| dark | 75 | 22 | 29.3 % |
| rock | 71 | 17 | 23.9 % |
| ghost | 62 | 38 | 61.3 % |
| psychic | 58 | 15 | 25.9 % |
| ground | 57 | 28 | 49.1 % |
| dragon | 43 | 19 | 44.2 % |
| fairy | 41 | 22 | 53.7 % |
| ice | 40 | 16 | 40.0 % |
| fighting | 40 | 7 | 17.5 % |
| steel | 36 | 16 | 44.4 % |
| flying | 16 | 7 | 43.8 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 77 |
| aegislash | 48 |
| alakazam | 44 |
| machamp | 41 |
| gengar | 38 |
| lapras | 33 |
| probopass | 30 |
| rayquaza | 29 |
| garchomp | 25 |
| kingambit | 23 |
| banette | 23 |
| centiskorch | 23 |
| mamoswine | 23 |
| houndoom | 23 |
| espeon | 22 |

Rencontres où l'on meurt le plus : `final_eternatus` (77), `league_steel` (49), `league_psychic` (44), `league_ghost` (38), `league_ice` (33), `league_fighting` (32), `legendary_rayquaza` (29), `league_dark` (23), `legendary_lugia` (21), `legendary_darkrai` (15)

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
