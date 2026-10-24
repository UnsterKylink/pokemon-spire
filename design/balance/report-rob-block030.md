# Rapport d'équilibrage — rob-block030

Parties simulées : **1000** (commit ca726dd, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **338 / 1000 = 33.8 %** (IC 95 % Wilson : 30.9 – 36.8 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 39 | 3.9 % | 3.9 % |
| zone1_elite | 5 | 0.5 % | 0.5 % |
| zone1_boss | 10 | 1.0 % | 1.0 % |
| zone2_wild | 1 | 0.1 % | 0.1 % |
| zone2_elite | 4 | 0.4 % | 0.4 % |
| zone2_boss | 19 | 1.9 % | 2.0 % |
| zone3_wild | 14 | 1.4 % | 1.5 % |
| zone3_elite | 32 | 3.2 % | 3.5 % |
| zone3_boss | 27 | 2.7 % | 3.1 % |
| zone4_wild | 14 | 1.4 % | 1.6 % |
| zone4_elite | 23 | 2.3 % | 2.8 % |
| zone4_boss | 34 | 3.4 % | 4.2 % |
| zone5_wild | 10 | 1.0 % | 1.3 % |
| zone5_elite | 17 | 1.7 % | 2.2 % |
| zone5_boss | 11 | 1.1 % | 1.5 % |
| zone6_wild | 17 | 1.7 % | 2.3 % |
| zone6_elite | 19 | 1.9 % | 2.6 % |
| zone6_boss | 49 | 4.9 % | 7.0 % |
| zone7_wild | 38 | 3.8 % | 5.8 % |
| zone7_elite | 22 | 2.2 % | 3.6 % |
| zone7_boss | 20 | 2.0 % | 3.4 % |
| zone8_wild | 22 | 2.2 % | 3.8 % |
| zone8_elite | 5 | 0.5 % | 0.9 % |
| zone8_boss | 31 | 3.1 % | 5.7 % |
| league_member_1 | 1 | 0.1 % | 0.2 % |
| league_member_2 | 6 | 0.6 % | 1.2 % |
| league_member_3 | 2 | 0.2 % | 0.4 % |
| league_member_4 | 9 | 0.9 % | 1.8 % |
| league_champion | 32 | 3.2 % | 6.4 % |
| league_eternatus | 129 | 12.9 % | 27.6 % |
| **Victoire** | 338 | 33.8 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 54 |
| 1 | 24 |
| 2 | 73 |
| 3 | 71 |
| 4 | 38 |
| 5 | 85 |
| 6 | 80 |
| 7 | 58 |
| 8 | 517 |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 1000 | 41.9 |
| Zone 2 | 946 | 72.0 |
| Zone 3 | 922 | 99.7 |
| Zone 4 | 849 | 113.5 |
| Zone 5 | 778 | 115.9 |
| Zone 6 | 740 | 150.1 |
| Zone 7 | 655 | 138.6 |
| Zone 8 | 575 | 159.1 |
| Ligue | 517 | 477.4 |

## Moyennes par partie

- Combats : 28.5; badges : 5.98
- Taille du deck en fin de partie : 26.0 (parties gagnées : 28.2)
- Potions utilisées : 2.82; potions achetées : 0.60; objets tenus : 8.68

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 6183 | 201 | 3.3 % |
| elite | 1442 | 127 | 8.8 % |
| league | 3017 | 179 | 5.9 % |
| wild | 17853 | 155 | 0.9 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| water | 152 | 65 | 42.8 % |
| normal | 148 | 45 | 30.4 % |
| grass | 111 | 24 | 21.6 % |
| bug | 111 | 36 | 32.4 % |
| fire | 86 | 25 | 29.1 % |
| poison | 53 | 21 | 39.6 % |
| electric | 45 | 16 | 35.6 % |
| dark | 45 | 14 | 31.1 % |
| psychic | 41 | 15 | 36.6 % |
| ghost | 37 | 9 | 24.3 % |
| rock | 29 | 14 | 48.3 % |
| ice | 27 | 12 | 44.4 % |
| ground | 23 | 7 | 30.4 % |
| steel | 22 | 9 | 40.9 % |
| fairy | 19 | 6 | 31.6 % |
| dragon | 19 | 11 | 57.9 % |
| fighting | 19 | 4 | 21.1 % |
| flying | 13 | 5 | 38.5 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 129 |
| dragonite | 32 |
| emboar | 16 |
| rhyperior | 15 |
| aegislash | 14 |
| skeledirge | 12 |
| glimmora | 12 |
| ceruledge | 10 |
| gholdengo | 10 |
| primarina | 9 |
| coalossal | 9 |
| salamence | 8 |
| aggron | 8 |
| mamoswine | 8 |
| incineroar | 8 |

Rencontres où l'on meurt le plus : `final_eternatus` (129), `league_champion` (32), `league_steel` (14), `solo_taillow` (4), `solo_starly` (3), `solo_bunnelby` (3), `elite_3` (3), `solo_pikipek` (3), `solo_sentret` (2), `solo_roucool` (2)

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
