# Rapport d'équilibrage — it16

Parties simulées : **3000** (commit ca726dd, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **1067 / 3000 = 35.6 %** (IC 95 % Wilson : 33.9 – 37.3 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 100 | 3.3 % | 3.3 % |
| zone1_elite | 9 | 0.3 % | 0.3 % |
| zone1_boss | 40 | 1.3 % | 1.4 % |
| zone2_wild | 7 | 0.2 % | 0.2 % |
| zone2_elite | 11 | 0.4 % | 0.4 % |
| zone2_boss | 54 | 1.8 % | 1.9 % |
| zone3_wild | 36 | 1.2 % | 1.3 % |
| zone3_elite | 81 | 2.7 % | 3.0 % |
| zone3_boss | 78 | 2.6 % | 2.9 % |
| zone4_wild | 40 | 1.3 % | 1.5 % |
| zone4_elite | 57 | 1.9 % | 2.2 % |
| zone4_boss | 98 | 3.3 % | 3.9 % |
| zone5_wild | 24 | 0.8 % | 1.0 % |
| zone5_elite | 53 | 1.8 % | 2.2 % |
| zone5_boss | 49 | 1.6 % | 2.1 % |
| zone6_wild | 58 | 1.9 % | 2.6 % |
| zone6_elite | 42 | 1.4 % | 1.9 % |
| zone6_boss | 87 | 2.9 % | 4.0 % |
| zone7_wild | 112 | 3.7 % | 5.4 % |
| zone7_elite | 67 | 2.2 % | 3.4 % |
| zone7_boss | 39 | 1.3 % | 2.1 % |
| zone8_wild | 74 | 2.5 % | 4.0 % |
| zone8_elite | 29 | 1.0 % | 1.6 % |
| zone8_boss | 92 | 3.1 % | 5.2 % |
| league_member_1 | 2 | 0.1 % | 0.1 % |
| league_member_2 | 2 | 0.1 % | 0.1 % |
| league_member_3 | 11 | 0.4 % | 0.7 % |
| league_member_4 | 19 | 0.6 % | 1.2 % |
| league_champion | 96 | 3.2 % | 5.9 % |
| league_eternatus | 466 | 15.5 % | 30.4 % |
| **Victoire** | 1067 | 35.6 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 149 |
| 1 | 72 |
| 2 | 195 |
| 3 | 195 |
| 4 | 126 |
| 5 | 187 |
| 6 | 218 |
| 7 | 195 |
| 8 | 1663 |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 3000 | 40.4 |
| Zone 2 | 2851 | 73.9 |
| Zone 3 | 2779 | 97.7 |
| Zone 4 | 2584 | 114.0 |
| Zone 5 | 2389 | 114.8 |
| Zone 6 | 2263 | 141.7 |
| Zone 7 | 2076 | 137.8 |
| Zone 8 | 1858 | 152.9 |
| Ligue | 1663 | 473.5 |

## Moyennes par partie

- Combats : 29.4; badges : 6.15
- Taille du deck en fin de partie : 26.2 (parties gagnées : 28.2)
- Potions utilisées : 2.80; potions achetées : 0.63; objets tenus : 8.87

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 19000 | 537 | 2.8 % |
| elite | 4294 | 349 | 8.1 % |
| league | 9793 | 596 | 6.1 % |
| wild | 55039 | 451 | 0.8 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| normal | 518 | 181 | 34.9 % |
| water | 432 | 170 | 39.4 % |
| grass | 391 | 83 | 21.2 % |
| bug | 315 | 75 | 23.8 % |
| fire | 258 | 90 | 34.9 % |
| electric | 170 | 78 | 45.9 % |
| poison | 128 | 56 | 43.8 % |
| ghost | 94 | 35 | 37.2 % |
| rock | 93 | 32 | 34.4 % |
| dark | 92 | 33 | 35.9 % |
| ground | 88 | 34 | 38.6 % |
| psychic | 88 | 31 | 35.2 % |
| dragon | 82 | 45 | 54.9 % |
| steel | 63 | 39 | 61.9 % |
| ice | 62 | 32 | 51.6 % |
| fairy | 51 | 19 | 37.3 % |
| fighting | 47 | 22 | 46.8 % |
| flying | 28 | 12 | 42.9 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 466 |
| dragonite | 96 |
| rhyperior | 45 |
| salamence | 27 |
| emboar | 27 |
| garchomp | 26 |
| gholdengo | 25 |
| ceruledge | 23 |
| mamoswine | 23 |
| typhlosion | 21 |
| coalossal | 21 |
| archaludon | 20 |
| incineroar | 20 |
| glimmora | 20 |
| skeledirge | 20 |

Rencontres où l'on meurt le plus : `final_eternatus` (466), `league_champion` (96), `league_steel` (19), `solo_taillow` (8), `league_fighting` (7), `solo_nosferapti` (5), `solo_roucool` (5), `trio_vol` (5), `solo_starly` (5), `solo_pikipek` (4)

Contrôles : combats bloqués (plafond de tours) = 59; actions refusées par le jeu = 0.

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
