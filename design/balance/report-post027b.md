# Rapport d'équilibrage — post027b

Parties simulées : **300** (commit af35604, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **236 / 300 = 78.7 %** (IC 95 % Wilson : 73.7 – 82.9 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 1 | 0.3 % | 0.3 % |
| zone1_elite | 1 | 0.3 % | 0.3 % |
| zone1_boss | 3 | 1.0 % | 1.0 % |
| zone2_wild | 1 | 0.3 % | 0.3 % |
| zone2_elite | 0 | 0.0 % | 0.0 % |
| zone2_boss | 4 | 1.3 % | 1.4 % |
| zone3_wild | 3 | 1.0 % | 1.0 % |
| zone3_elite | 5 | 1.7 % | 1.7 % |
| zone3_boss | 1 | 0.3 % | 0.4 % |
| zone4_wild | 0 | 0.0 % | 0.0 % |
| zone4_elite | 4 | 1.3 % | 1.4 % |
| zone4_boss | 5 | 1.7 % | 1.8 % |
| zone5_wild | 0 | 0.0 % | 0.0 % |
| zone5_elite | 1 | 0.3 % | 0.4 % |
| zone5_boss | 1 | 0.3 % | 0.4 % |
| zone6_wild | 1 | 0.3 % | 0.4 % |
| zone6_elite | 2 | 0.7 % | 0.7 % |
| zone6_boss | 4 | 1.3 % | 1.5 % |
| zone7_wild | 1 | 0.3 % | 0.4 % |
| zone7_elite | 0 | 0.0 % | 0.0 % |
| zone7_boss | 1 | 0.3 % | 0.4 % |
| zone8_wild | 2 | 0.7 % | 0.8 % |
| zone8_elite | 1 | 0.3 % | 0.4 % |
| zone8_boss | 2 | 0.7 % | 0.8 % |
| league_member_1 | 6 | 2.0 % | 2.3 % |
| league_member_2 | 2 | 0.7 % | 0.8 % |
| league_member_3 | 0 | 0.0 % | 0.0 % |
| league_member_4 | 0 | 0.0 % | 0.0 % |
| league_champion | 0 | 0.0 % | 0.0 % |
| league_eternatus | 4 | 1.3 % | 1.6 % |
| **Victoire** | 236 | 78.7 % | - |

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 5 |
| 1 | 7 |
| 2 | 11 |
| 3 | 10 |
| 4 | 3 |
| 5 | 8 |
| 6 | 2 |
| 7 | 5 |
| 8 | 249 |

### Progression garantie (exigence joueur du 2026-10-24)

| Mesure | Valeur | Repère joueur |
|---|---:|---|
| Parties avec au moins 3 badges | 92.3 % | >= 75 % |
| Parties qui atteignent le Conseil 4 | 83.0 % | >= 50 % |
| Défaites en zone 1 (toutes salles) | 1.7 % des parties | <= 5 % |
| Étape la plus meurtrière : league_member_1 | 9.4 % des défaites (2.0 % des parties) | <= ~20 % des défaites |
| Victoire parmi les parties qui atteignent Éthernatos | 98.3 % | difficile mais battable |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 300 | 35.7 |
| Zone 2 | 295 | 69.5 |
| Zone 3 | 288 | 66.0 |
| Zone 4 | 277 | 91.9 |
| Zone 5 | 267 | 67.2 |
| Zone 6 | 264 | 112.0 |
| Zone 7 | 256 | 76.2 |
| Zone 8 | 254 | 173.4 |
| Ligue | 249 | 266.8 |

## Moyennes par partie

- Combats : 36.0; badges : 7.17
- Taille du deck en fin de partie : 28.1 (parties gagnées : 29.2)
- Potions utilisées : 2.26; potions achetées : 0.62; objets tenus : 12.94

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 2171 | 21 | 1.0 % |
| elite | 456 | 14 | 3.1 % |
| league | 1450 | 12 | 0.8 % |
| legendary | 39 | 4 | 10.3 % |
| legendary_seen | 95 | 0 | 0.0 % |
| legendary_won | 35 | 0 | 0.0 % |
| rival | 835 | 3 | 0.4 % |
| rival_final | 249 | 1 | 0.4 % |
| wild | 5611 | 9 | 0.2 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| water | 49 | 46 | 93.9 % |
| normal | 42 | 30 | 71.4 % |
| bug | 39 | 29 | 74.4 % |
| grass | 36 | 22 | 61.1 % |
| fire | 29 | 22 | 75.9 % |
| electric | 19 | 17 | 89.5 % |
| poison | 13 | 9 | 69.2 % |
| fighting | 10 | 6 | 60.0 % |
| dark | 9 | 8 | 88.9 % |
| psychic | 9 | 7 | 77.8 % |
| ice | 8 | 8 | 100.0 % |
| ghost | 7 | 7 | 100.0 % |
| fairy | 7 | 7 | 100.0 % |
| steel | 6 | 6 | 100.0 % |
| dragon | 6 | 5 | 83.3 % |
| ground | 5 | 4 | 80.0 % |
| rock | 3 | 2 | 66.7 % |
| flying | 3 | 1 | 33.3 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 4 |
| copperajah | 3 |
| gengar | 3 |
| lugia | 3 |
| aegislash | 3 |
| gigalith | 2 |
| aerodactyl | 2 |
| ursaluna | 2 |
| gyarados | 2 |
| probopass | 2 |
| mamoswine | 2 |
| centiskorch | 1 |
| baxcalibur | 1 |
| magcargo | 1 |
| rayquaza | 1 |

Rencontres où l'on meurt le plus : `league_steel` (4), `final_eternatus` (4), `league_ghost` (3), `legendary_lugia` (3), `roster:centiskorch,scyther` (1), `roster:copperajah,skarmory` (1), `roster:baxcalibur,turtonator,goodra` (1), `roster:lairon,magcargo,tyrantrum` (1), `roster:aggron,aerodactyl,gigalith` (1), `legendary_rayquaza` (1)

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
 - Story 027: set-up skills (energy / draw / Force) are played first; attacks are scored with Battle.preview_card_damage
   (Force, Élan, talent bonus, conditionals, Vulnérable, multi-hit) + the value of their extra effects; switching Pokémon
   costs the Élan it loses (elan_loss_weight) and earns the talent it fires (talent_value).
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
Story 027: block a skill gives right now (its block + block per living enemy).
Story 027: value (in damage points) of what an attack card does besides its damage, in the current battle:
draw / energy / Force, minus self-damage, minus the Élan a switch loses, plus the talent a switch fires.
Story 027: a skill that only sets the turn up (energy / draw / Force, no target): played first when it pays for itself
(free, or energy is left for something else afterwards) and another card is in hand. {} if none.
Base value of a card per energy (no deck context).
Story 027: deck-building value of an EffectSpec effect (draw, energy, Force, block per enemy, statuses, self-damage).
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
	## Story 027. Battle + reward value of the new card effects, in "damage points" (correct, not expert).
	## One drawn card / one energy / one Force for the battle / one Force for the turn / enemies assumed for block per enemy.
	"draw_value": 3.0,
	"energy_value": 4.0,
	"strength_value": 4.0,
	"strength_turn_value": 2.0,
	"block_per_enemy_enemies": 1.5,
	## HP lost by a self-damaging card (score penalty per HP); such a card is never played under self_damage_min_hp_frac.
	"self_damage_weight": 1.0,
	"self_damage_min_hp_frac": 0.3,
	## Reward value of a conditional bonus = this share of its `then` (the condition is met about half the time).
	"conditional_share": 0.5,
	## Reward value of a "damage from block" card (typical block held when it is played).
	"damage_from_block_value": 6.0,
	## Battle: switching Pokémon loses the Élan: score penalty per point of Élan damage bonus lost...
	"elan_loss_weight": 1.5,
	## ...and gains the newcomer's talent: flat score bonus when the talent would fire.
	"talent_value": 2.0,
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
