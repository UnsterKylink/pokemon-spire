# Rapport d'équilibrage — final

Parties simulées : **3000** (commit ca726dd, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **1071 / 3000 = 35.7 %** (IC 95 % Wilson : 34.0 – 37.4 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 102 | 3.4 % | 3.4 % |
| zone1_elite | 17 | 0.6 % | 0.6 % |
| zone1_boss | 25 | 0.8 % | 0.9 % |
| zone2_wild | 5 | 0.2 % | 0.2 % |
| zone2_elite | 12 | 0.4 % | 0.4 % |
| zone2_boss | 68 | 2.3 % | 2.4 % |
| zone3_wild | 48 | 1.6 % | 1.7 % |
| zone3_elite | 70 | 2.3 % | 2.6 % |
| zone3_boss | 68 | 2.3 % | 2.6 % |
| zone4_wild | 52 | 1.7 % | 2.0 % |
| zone4_elite | 69 | 2.3 % | 2.7 % |
| zone4_boss | 96 | 3.2 % | 3.9 % |
| zone5_wild | 30 | 1.0 % | 1.3 % |
| zone5_elite | 40 | 1.3 % | 1.7 % |
| zone5_boss | 42 | 1.4 % | 1.8 % |
| zone6_wild | 58 | 1.9 % | 2.6 % |
| zone6_elite | 54 | 1.8 % | 2.5 % |
| zone6_boss | 128 | 4.3 % | 6.0 % |
| zone7_wild | 119 | 4.0 % | 5.9 % |
| zone7_elite | 60 | 2.0 % | 3.2 % |
| zone7_boss | 65 | 2.2 % | 3.5 % |
| zone8_wild | 86 | 2.9 % | 4.9 % |
| zone8_elite | 30 | 1.0 % | 1.8 % |
| zone8_boss | 89 | 3.0 % | 5.4 % |
| league_member_1 | 9 | 0.3 % | 0.6 % |
| league_member_2 | 8 | 0.3 % | 0.5 % |
| league_member_3 | 11 | 0.4 % | 0.7 % |
| league_member_4 | 16 | 0.5 % | 1.0 % |
| league_champion | 86 | 2.9 % | 5.6 % |
| league_eternatus | 366 | 12.2 % | 25.5 % |
| **Victoire** | 1071 | 35.7 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 144 |
| 1 | 85 |
| 2 | 186 |
| 3 | 217 |
| 4 | 112 |
| 5 | 240 |
| 6 | 244 |
| 7 | 205 |
| 8 | 1567 |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 3000 | 41.6 |
| Zone 2 | 2856 | 72.3 |
| Zone 3 | 2771 | 99.0 |
| Zone 4 | 2585 | 113.3 |
| Zone 5 | 2368 | 115.4 |
| Zone 6 | 2256 | 149.3 |
| Zone 7 | 2016 | 139.4 |
| Zone 8 | 1772 | 155.7 |
| Ligue | 1567 | 474.7 |

## Moyennes par partie

- Combats : 28.9; badges : 6.06
- Taille du deck en fin de partie : 26.1 (parties gagnées : 28.2)
- Potions utilisées : 2.84; potions achetées : 0.62; objets tenus : 8.76

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 18772 | 581 | 3.1 % |
| elite | 4273 | 352 | 8.2 % |
| league | 9174 | 496 | 5.4 % |
| wild | 54419 | 500 | 0.9 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| water | 476 | 207 | 43.5 % |
| normal | 466 | 159 | 34.1 % |
| grass | 379 | 84 | 22.2 % |
| bug | 343 | 96 | 28.0 % |
| fire | 239 | 86 | 36.0 % |
| poison | 136 | 50 | 36.8 % |
| electric | 131 | 54 | 41.2 % |
| rock | 113 | 49 | 43.4 % |
| dark | 111 | 40 | 36.0 % |
| psychic | 104 | 41 | 39.4 % |
| ghost | 94 | 35 | 37.2 % |
| ground | 72 | 27 | 37.5 % |
| ice | 67 | 26 | 38.8 % |
| dragon | 67 | 39 | 58.2 % |
| steel | 65 | 35 | 53.8 % |
| fairy | 54 | 12 | 22.2 % |
| flying | 42 | 22 | 52.4 % |
| fighting | 41 | 9 | 22.0 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 366 |
| dragonite | 86 |
| rhyperior | 38 |
| mamoswine | 38 |
| skeledirge | 34 |
| gholdengo | 32 |
| ceruledge | 28 |
| emboar | 26 |
| aegislash | 26 |
| coalossal | 25 |
| garchomp | 24 |
| salamence | 21 |
| glimmora | 21 |
| seismitoad | 21 |
| krookodile | 21 |

Rencontres où l'on meurt le plus : `final_eternatus` (366), `league_champion` (86), `league_steel` (26), `solo_taillow` (8), `solo_starly` (7), `solo_roucool` (7), `elite_3` (7), `elite_fire` (7), `solo_bunnelby` (6), `solo_pikipek` (6)

Contrôles : combats bloqués (plafond de tours) = 60; actions refusées par le jeu = 0.

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
