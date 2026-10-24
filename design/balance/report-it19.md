# Rapport d'équilibrage — it19

Parties simulées : **3000** (commit 2843002, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **1031 / 3000 = 34.4 %** (IC 95 % Wilson : 32.7 – 36.1 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 16 | 0.5 % | 0.5 % |
| zone1_elite | 15 | 0.5 % | 0.5 % |
| zone1_boss | 99 | 3.3 % | 3.3 % |
| zone2_wild | 6 | 0.2 % | 0.2 % |
| zone2_elite | 11 | 0.4 % | 0.4 % |
| zone2_boss | 64 | 2.1 % | 2.2 % |
| zone3_wild | 44 | 1.5 % | 1.6 % |
| zone3_elite | 93 | 3.1 % | 3.4 % |
| zone3_boss | 85 | 2.8 % | 3.2 % |
| zone4_wild | 38 | 1.3 % | 1.5 % |
| zone4_elite | 61 | 2.0 % | 2.4 % |
| zone4_boss | 86 | 2.9 % | 3.5 % |
| zone5_wild | 31 | 1.0 % | 1.3 % |
| zone5_elite | 52 | 1.7 % | 2.2 % |
| zone5_boss | 46 | 1.5 % | 2.0 % |
| zone6_wild | 58 | 1.9 % | 2.6 % |
| zone6_elite | 49 | 1.6 % | 2.2 % |
| zone6_boss | 141 | 4.7 % | 6.6 % |
| zone7_wild | 123 | 4.1 % | 6.1 % |
| zone7_elite | 77 | 2.6 % | 4.1 % |
| zone7_boss | 58 | 1.9 % | 3.2 % |
| zone8_wild | 71 | 2.4 % | 4.1 % |
| zone8_elite | 34 | 1.1 % | 2.0 % |
| zone8_boss | 108 | 3.6 % | 6.6 % |
| league_member_1 | 3 | 0.1 % | 0.2 % |
| league_member_2 | 7 | 0.2 % | 0.5 % |
| league_member_3 | 12 | 0.4 % | 0.8 % |
| league_member_4 | 24 | 0.8 % | 1.6 % |
| league_champion | 98 | 3.3 % | 6.6 % |
| league_eternatus | 359 | 12.0 % | 25.8 % |
| **Victoire** | 1031 | 34.4 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 130 |
| 1 | 81 |
| 2 | 222 |
| 3 | 185 |
| 4 | 129 |
| 5 | 248 |
| 6 | 258 |
| 7 | 213 |
| 8 | 1534 |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 3000 | 51.1 |
| Zone 2 | 2870 | 74.4 |
| Zone 3 | 2789 | 98.2 |
| Zone 4 | 2567 | 114.6 |
| Zone 5 | 2382 | 115.2 |
| Zone 6 | 2253 | 148.2 |
| Zone 7 | 2005 | 140.7 |
| Zone 8 | 1747 | 158.5 |
| Ligue | 1534 | 475.0 |

## Moyennes par partie

- Combats : 28.9; badges : 6.05
- Taille du deck en fin de partie : 26.2 (parties gagnées : 28.2)
- Potions utilisées : 2.88; potions achetées : 0.64; objets tenus : 8.71

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 18834 | 687 | 3.6 % |
| elite | 4265 | 392 | 9.2 % |
| league | 8979 | 503 | 5.6 % |
| wild | 54611 | 387 | 0.7 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| normal | 518 | 171 | 33.0 % |
| water | 432 | 165 | 38.2 % |
| grass | 391 | 77 | 19.7 % |
| bug | 315 | 70 | 22.2 % |
| fire | 258 | 85 | 32.9 % |
| electric | 170 | 70 | 41.2 % |
| poison | 128 | 49 | 38.3 % |
| ghost | 94 | 49 | 52.1 % |
| rock | 93 | 31 | 33.3 % |
| dark | 92 | 37 | 40.2 % |
| ground | 88 | 49 | 55.7 % |
| psychic | 88 | 30 | 34.1 % |
| dragon | 82 | 40 | 48.8 % |
| steel | 63 | 34 | 54.0 % |
| ice | 62 | 25 | 40.3 % |
| fairy | 51 | 14 | 27.5 % |
| fighting | 47 | 22 | 46.8 % |
| flying | 28 | 13 | 46.4 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 359 |
| dragonite | 98 |
| rhyperior | 47 |
| emboar | 32 |
| garchomp | 30 |
| ceruledge | 29 |
| seismitoad | 28 |
| salamence | 26 |
| golem | 25 |
| gholdengo | 24 |
| mamoswine | 23 |
| chandelure | 23 |
| infernape | 23 |
| baxcalibur | 22 |
| tyranitar | 22 |

Rencontres où l'on meurt le plus : `final_eternatus` (359), `league_champion` (98), `league_steel` (19), `league_ghost` (12), `league_psychic` (5), `league_fighting` (5), `elite_1` (5), `elite_rock` (4), `league_ice` (4), `trio_vol` (4)

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
