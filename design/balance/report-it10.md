# Rapport d'équilibrage — it10

Parties simulées : **2000** (commit df894d2, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **620 / 2000 = 31.0 %** (IC 95 % Wilson : 29.0 – 33.1 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 93 | 4.7 % | 4.7 % |
| zone1_elite | 40 | 2.0 % | 2.1 % |
| zone1_boss | 72 | 3.6 % | 3.9 % |
| zone2_wild | 2 | 0.1 % | 0.1 % |
| zone2_elite | 11 | 0.6 % | 0.6 % |
| zone2_boss | 126 | 6.3 % | 7.1 % |
| zone3_wild | 34 | 1.7 % | 2.1 % |
| zone3_elite | 49 | 2.5 % | 3.0 % |
| zone3_boss | 46 | 2.3 % | 2.9 % |
| zone4_wild | 30 | 1.5 % | 2.0 % |
| zone4_elite | 47 | 2.4 % | 3.1 % |
| zone4_boss | 55 | 2.8 % | 3.8 % |
| zone5_wild | 22 | 1.1 % | 1.6 % |
| zone5_elite | 32 | 1.6 % | 2.3 % |
| zone5_boss | 28 | 1.4 % | 2.1 % |
| zone6_wild | 49 | 2.5 % | 3.7 % |
| zone6_elite | 30 | 1.5 % | 2.4 % |
| zone6_boss | 51 | 2.5 % | 4.1 % |
| zone7_wild | 62 | 3.1 % | 5.2 % |
| zone7_elite | 37 | 1.9 % | 3.3 % |
| zone7_boss | 25 | 1.2 % | 2.3 % |
| zone8_wild | 38 | 1.9 % | 3.6 % |
| zone8_elite | 13 | 0.7 % | 1.3 % |
| zone8_boss | 42 | 2.1 % | 4.2 % |
| league_member_1 | 3 | 0.1 % | 0.3 % |
| league_member_2 | 6 | 0.3 % | 0.6 % |
| league_member_3 | 9 | 0.5 % | 0.9 % |
| league_member_4 | 17 | 0.8 % | 1.8 % |
| league_champion | 94 | 4.7 % | 10.1 % |
| league_eternatus | 217 | 10.8 % | 25.9 % |
| **Victoire** | 620 | 31.0 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 205 |
| 1 | 139 |
| 2 | 129 |
| 3 | 132 |
| 4 | 82 |
| 5 | 130 |
| 6 | 124 |
| 7 | 93 |
| 8 | 966 |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 2000 | 59.0 |
| Zone 2 | 1795 | 86.4 |
| Zone 3 | 1656 | 96.9 |
| Zone 4 | 1527 | 113.1 |
| Zone 5 | 1395 | 116.9 |
| Zone 6 | 1313 | 139.8 |
| Zone 7 | 1183 | 135.0 |
| Zone 8 | 1059 | 150.0 |
| Ligue | 966 | 473.6 |

## Moyennes par partie

- Combats : 26.2; badges : 5.45
- Taille du deck en fin de partie : 25.0 (parties gagnées : 28.2)
- Potions utilisées : 2.67; potions achetées : 0.57; objets tenus : 7.86

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 11339 | 445 | 3.9 % |
| elite | 2578 | 259 | 10.0 % |
| league | 5602 | 346 | 6.2 % |
| wild | 32883 | 330 | 1.0 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| water | 326 | 120 | 36.8 % |
| normal | 287 | 79 | 27.5 % |
| bug | 245 | 55 | 22.4 % |
| grass | 242 | 43 | 17.8 % |
| fire | 166 | 62 | 37.3 % |
| electric | 118 | 39 | 33.1 % |
| poison | 86 | 39 | 45.3 % |
| dark | 80 | 24 | 30.0 % |
| rock | 78 | 22 | 28.2 % |
| psychic | 65 | 20 | 30.8 % |
| ghost | 60 | 24 | 40.0 % |
| ground | 48 | 14 | 29.2 % |
| ice | 45 | 15 | 33.3 % |
| dragon | 38 | 17 | 44.7 % |
| steel | 36 | 17 | 47.2 % |
| fairy | 33 | 12 | 36.4 % |
| fighting | 32 | 7 | 21.9 % |
| flying | 15 | 11 | 73.3 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 217 |
| dragonite | 94 |
| archaludon | 24 |
| mamoswine | 21 |
| rhyperior | 20 |
| salamence | 20 |
| ceruledge | 20 |
| glimmora | 19 |
| emboar | 15 |
| incineroar | 15 |
| swampert | 15 |
| aegislash | 14 |
| gholdengo | 14 |
| carkol | 14 |
| magnezone | 14 |

Rencontres où l'on meurt le plus : `final_eternatus` (217), `league_champion` (94), `league_steel` (14), `elite_3` (7), `league_dark` (6), `league_ghost` (6), `league_fighting` (5), `roster:sizzlipede` (4), `elite_grass` (3), `roster:pumpkaboo-average` (3)

Contrôles : combats bloqués (plafond de tours) = 47; actions refusées par le jeu = 0.

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
