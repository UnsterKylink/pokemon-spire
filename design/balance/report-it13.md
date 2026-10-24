# Rapport d'équilibrage — it13

Parties simulées : **3000** (commit ca726dd). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **1068 / 3000 = 35.6 %** (IC 95 % Wilson : 33.9 – 37.3 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 153 | 5.1 % | 5.1 % |
| zone1_elite | 55 | 1.8 % | 1.9 % |
| zone1_boss | 96 | 3.2 % | 3.4 % |
| zone2_wild | 9 | 0.3 % | 0.3 % |
| zone2_elite | 16 | 0.5 % | 0.6 % |
| zone2_boss | 70 | 2.3 % | 2.6 % |
| zone3_wild | 48 | 1.6 % | 1.8 % |
| zone3_elite | 77 | 2.6 % | 3.0 % |
| zone3_boss | 74 | 2.5 % | 3.0 % |
| zone4_wild | 33 | 1.1 % | 1.4 % |
| zone4_elite | 51 | 1.7 % | 2.2 % |
| zone4_boss | 97 | 3.2 % | 4.2 % |
| zone5_wild | 27 | 0.9 % | 1.2 % |
| zone5_elite | 50 | 1.7 % | 2.3 % |
| zone5_boss | 46 | 1.5 % | 2.1 % |
| zone6_wild | 57 | 1.9 % | 2.7 % |
| zone6_elite | 56 | 1.9 % | 2.7 % |
| zone6_boss | 73 | 2.4 % | 3.7 % |
| zone7_wild | 87 | 2.9 % | 4.6 % |
| zone7_elite | 62 | 2.1 % | 3.4 % |
| zone7_boss | 39 | 1.3 % | 2.2 % |
| zone8_wild | 59 | 2.0 % | 3.4 % |
| zone8_elite | 31 | 1.0 % | 1.9 % |
| zone8_boss | 72 | 2.4 % | 4.4 % |
| league_member_1 | 6 | 0.2 % | 0.4 % |
| league_member_2 | 1 | 0.0 % | 0.1 % |
| league_member_3 | 9 | 0.3 % | 0.6 % |
| league_member_4 | 20 | 0.7 % | 1.3 % |
| league_champion | 108 | 3.6 % | 7.1 % |
| league_eternatus | 350 | 11.7 % | 24.7 % |
| **Victoire** | 1068 | 35.6 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 304 |
| 1 | 95 |
| 2 | 199 |
| 3 | 181 |
| 4 | 123 |
| 5 | 186 |
| 6 | 188 |
| 7 | 162 |
| 8 | 1562 |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 3000 | 60.4 |
| Zone 2 | 2696 | 74.4 |
| Zone 3 | 2601 | 98.3 |
| Zone 4 | 2402 | 114.4 |
| Zone 5 | 2221 | 116.0 |
| Zone 6 | 2098 | 141.5 |
| Zone 7 | 1912 | 136.5 |
| Zone 8 | 1724 | 154.4 |
| Ligue | 1562 | 462.5 |

## Moyennes par partie

- Combats : 27.6; badges : 5.74
- Taille du deck en fin de partie : 25.4 (parties gagnées : 28.2)
- Potions utilisées : 2.70; potions achetées : 0.60; objets tenus : 8.23

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 17783 | 567 | 3.2 % |
| elite | 4043 | 398 | 9.8 % |
| league | 9163 | 494 | 5.4 % |
| wild | 51775 | 473 | 0.9 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| normal | 518 | 174 | 33.6 % |
| water | 432 | 184 | 42.6 % |
| grass | 391 | 72 | 18.4 % |
| bug | 315 | 80 | 25.4 % |
| fire | 258 | 93 | 36.0 % |
| electric | 170 | 62 | 36.5 % |
| poison | 128 | 58 | 45.3 % |
| ghost | 94 | 46 | 48.9 % |
| rock | 93 | 29 | 31.2 % |
| dark | 92 | 46 | 50.0 % |
| ground | 88 | 32 | 36.4 % |
| psychic | 88 | 33 | 37.5 % |
| dragon | 82 | 42 | 51.2 % |
| steel | 63 | 38 | 60.3 % |
| ice | 62 | 28 | 45.2 % |
| fairy | 51 | 23 | 45.1 % |
| fighting | 47 | 19 | 40.4 % |
| flying | 28 | 9 | 32.1 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 350 |
| dragonite | 108 |
| rhyperior | 41 |
| garchomp | 31 |
| mamoswine | 27 |
| salamence | 24 |
| emboar | 24 |
| seismitoad | 24 |
| golem | 22 |
| gholdengo | 22 |
| ceruledge | 22 |
| incineroar | 21 |
| hydreigon | 20 |
| skeledirge | 19 |
| aegislash | 18 |

Rencontres où l'on meurt le plus : `final_eternatus` (350), `league_champion` (108), `league_steel` (18), `elite_3` (8), `league_fighting` (8), `elite_1` (7), `trio_vol` (7), `trio_r3` (6), `elite_2` (5), `trio` (5)

Contrôles : combats bloqués (plafond de tours) = 61; actions refusées par le jeu = 0.

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
