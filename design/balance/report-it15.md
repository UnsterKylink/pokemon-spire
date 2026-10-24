# Rapport d'équilibrage — it15

Parties simulées : **3000** (commit ca726dd, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **1158 / 3000 = 38.6 %** (IC 95 % Wilson : 36.9 – 40.4 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 106 | 3.5 % | 3.5 % |
| zone1_elite | 15 | 0.5 % | 0.5 % |
| zone1_boss | 43 | 1.4 % | 1.5 % |
| zone2_wild | 5 | 0.2 % | 0.2 % |
| zone2_elite | 7 | 0.2 % | 0.2 % |
| zone2_boss | 66 | 2.2 % | 2.3 % |
| zone3_wild | 34 | 1.1 % | 1.2 % |
| zone3_elite | 87 | 2.9 % | 3.2 % |
| zone3_boss | 76 | 2.5 % | 2.9 % |
| zone4_wild | 38 | 1.3 % | 1.5 % |
| zone4_elite | 60 | 2.0 % | 2.4 % |
| zone4_boss | 98 | 3.3 % | 4.0 % |
| zone5_wild | 27 | 0.9 % | 1.1 % |
| zone5_elite | 53 | 1.8 % | 2.3 % |
| zone5_boss | 42 | 1.4 % | 1.8 % |
| zone6_wild | 67 | 2.2 % | 3.0 % |
| zone6_elite | 44 | 1.5 % | 2.0 % |
| zone6_boss | 80 | 2.7 % | 3.8 % |
| zone7_wild | 120 | 4.0 % | 5.8 % |
| zone7_elite | 56 | 1.9 % | 2.9 % |
| zone7_boss | 49 | 1.6 % | 2.6 % |
| zone8_wild | 61 | 2.0 % | 3.3 % |
| zone8_elite | 27 | 0.9 % | 1.5 % |
| zone8_boss | 102 | 3.4 % | 5.9 % |
| league_member_1 | 4 | 0.1 % | 0.2 % |
| league_member_2 | 2 | 0.1 % | 0.1 % |
| league_member_3 | 9 | 0.3 % | 0.6 % |
| league_member_4 | 23 | 0.8 % | 1.4 % |
| league_champion | 107 | 3.6 % | 6.7 % |
| league_eternatus | 334 | 11.1 % | 22.4 % |
| **Victoire** | 1158 | 38.6 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 164 |
| 1 | 78 |
| 2 | 197 |
| 3 | 196 |
| 4 | 122 |
| 5 | 191 |
| 6 | 225 |
| 7 | 190 |
| 8 | 1637 |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 3000 | 44.3 |
| Zone 2 | 2836 | 74.4 |
| Zone 3 | 2758 | 97.7 |
| Zone 4 | 2561 | 114.9 |
| Zone 5 | 2365 | 115.7 |
| Zone 6 | 2243 | 141.0 |
| Zone 7 | 2052 | 138.0 |
| Zone 8 | 1827 | 153.7 |
| Ligue | 1637 | 464.9 |

## Moyennes par partie

- Combats : 29.1; badges : 6.09
- Taille du deck en fin de partie : 26.1 (parties gagnées : 28.2)
- Potions utilisées : 2.80; potions achetées : 0.63; objets tenus : 8.78

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 18835 | 556 | 3.0 % |
| elite | 4254 | 349 | 8.2 % |
| league | 9614 | 479 | 5.0 % |
| wild | 54585 | 458 | 0.8 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| normal | 518 | 208 | 40.2 % |
| water | 432 | 182 | 42.1 % |
| grass | 391 | 103 | 26.3 % |
| bug | 315 | 94 | 29.8 % |
| fire | 258 | 93 | 36.0 % |
| electric | 170 | 79 | 46.5 % |
| poison | 128 | 53 | 41.4 % |
| ghost | 94 | 37 | 39.4 % |
| rock | 93 | 37 | 39.8 % |
| dark | 92 | 42 | 45.7 % |
| ground | 88 | 32 | 36.4 % |
| psychic | 88 | 31 | 35.2 % |
| dragon | 82 | 48 | 58.5 % |
| steel | 63 | 38 | 60.3 % |
| ice | 62 | 30 | 48.4 % |
| fairy | 51 | 19 | 37.3 % |
| fighting | 47 | 22 | 46.8 % |
| flying | 28 | 10 | 35.7 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 334 |
| dragonite | 107 |
| rhyperior | 39 |
| emboar | 31 |
| garchomp | 28 |
| coalossal | 25 |
| seismitoad | 23 |
| glimmora | 23 |
| mamoswine | 22 |
| golem | 22 |
| salamence | 22 |
| chandelure | 21 |
| archaludon | 21 |
| aegislash | 21 |
| ceruledge | 21 |

Rencontres où l'on meurt le plus : `final_eternatus` (334), `league_champion` (107), `league_steel` (21), `solo_taillow` (8), `league_fighting` (6), `solo_nosferapti` (5), `solo_roucool` (5), `league_ghost` (5), `solo_starly` (5), `trio_vol` (5)

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
