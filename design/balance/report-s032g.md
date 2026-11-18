# Rapport d'équilibrage — s032g

Parties simulées : **800** (commit 208608e, données modifiées non commitées). 

## Résultat

- Victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos) : **305 / 800 = 38.1 %** (IC 95 % Wilson : 34.8 – 41.5 %)
- Objectif joueur : environ 35 % des parties complètes gagnées.

## Où les parties se terminent (distribution des défaites)

| Étape | Parties arrêtées | % des parties | % de celles qui l'atteignent |
|---|---:|---:|---:|
| zone1_wild | 1 | 0.1 % | 0.1 % |
| zone1_elite | 5 | 0.6 % | 0.6 % |
| zone1_boss | 21 | 2.6 % | 2.6 % |
| zone2_wild | 0 | 0.0 % | 0.0 % |
| zone2_elite | 14 | 1.8 % | 1.8 % |
| zone2_boss | 37 | 4.6 % | 4.9 % |
| zone3_wild | 2 | 0.2 % | 0.3 % |
| zone3_elite | 20 | 2.5 % | 2.8 % |
| zone3_boss | 32 | 4.0 % | 4.6 % |
| zone4_wild | 1 | 0.1 % | 0.1 % |
| zone4_elite | 35 | 4.4 % | 5.2 % |
| zone4_boss | 49 | 6.1 % | 7.8 % |
| zone5_wild | 3 | 0.4 % | 0.5 % |
| zone5_elite | 12 | 1.5 % | 2.1 % |
| zone5_boss | 17 | 2.1 % | 3.0 % |
| zone6_wild | 3 | 0.4 % | 0.5 % |
| zone6_elite | 13 | 1.6 % | 2.4 % |
| zone6_boss | 13 | 1.6 % | 2.4 % |
| zone7_wild | 1 | 0.1 % | 0.2 % |
| zone7_elite | 4 | 0.5 % | 0.8 % |
| zone7_boss | 6 | 0.8 % | 1.2 % |
| zone8_wild | 1 | 0.1 % | 0.2 % |
| zone8_elite | 2 | 0.2 % | 0.4 % |
| zone8_boss | 3 | 0.4 % | 0.6 % |
| league_member_1 | 37 | 4.6 % | 7.3 % |
| league_member_2 | 8 | 1.0 % | 1.7 % |
| league_member_3 | 5 | 0.6 % | 1.1 % |
| league_member_4 | 13 | 1.6 % | 2.9 % |
| league_champion | 7 | 0.9 % | 1.6 % |
| league_eternatus | 97 | 12.1 % | 22.3 % |
| **Victoire** | 305 | 38.1 % | - |

Autres étapes (rival, combats d'événement) : `rival_final` (7), `zone2_event_elite` (1), `zone2_rival` (13), `zone4_event_legendary` (1), `zone4_rival` (5), `zone5_event_legendary` (1), `zone6_event_elite` (1), `zone6_event_legendary` (1), `zone6_rival` (1), `zone7_event_legendary` (1), `zone8_event_legendary` (1)

Zones : `wild`/`elite` = salles de combat de la carte, `boss` = arène. « % de celles qui l'atteignent » = défaites à cette étape / parties encore en vie en y arrivant (étapes dans l'ordre de la partie).

### Entonnoir (badges obtenus)

| Badges | Parties |
|---:|---:|
| 0 | 27 |
| 1 | 65 |
| 2 | 54 |
| 3 | 91 |
| 4 | 33 |
| 5 | 32 |
| 6 | 12 |
| 7 | 7 |
| 8 | 479 |

### Progression garantie (exigence joueur du 2026-10-24)

| Mesure | Valeur | Repère joueur |
|---|---:|---|
| Parties avec au moins 3 badges | 81.8 % | >= 75 % |
| Parties qui atteignent le Conseil 4 | 59.9 % | >= 50 % |
| Défaites en zone 1 (toutes salles) | 3.4 % des parties | <= 5 % |
| Étape la plus meurtrière : league_eternatus | 19.6 % des défaites (12.1 % des parties) | <= ~20 % des défaites |
| Victoire parmi les parties qui atteignent Éthernatos | 75.9 % | difficile mais battable |

## PV perdus par zone (moyenne sur les parties qui y entrent)

| Zone | Parties entrées | PV perdus / partie |
|---|---:|---:|
| Zone 1 | 800 | 29.3 |
| Zone 2 | 773 | 78.5 |
| Zone 3 | 708 | 72.0 |
| Zone 4 | 654 | 94.1 |
| Zone 5 | 563 | 69.9 |
| Zone 6 | 530 | 96.2 |
| Zone 7 | 498 | 62.9 |
| Zone 8 | 486 | 117.3 |
| Ligue | 479 | 256.0 |

## Moyennes par partie

- Combats : 20.9 (parties gagnées : 29.1); badges : 5.86
- Taille du deck en fin de partie : 28.6 (parties gagnées : 34.7)
- Potions utilisées : 2.74; potions achetées : 0.41; objets tenus : 11.05

## Taux de défaite par type de salle

| Salle | Combats | Défaites | Défaite / combat |
|---|---:|---:|---:|
| boss | 4869 | 178 | 3.7 % |
| elite | 1674 | 107 | 6.4 % |
| league | 2567 | 167 | 6.5 % |
| legendary | 34 | 5 | 14.7 % |
| legendary_seen | 76 | 0 | 0.0 % |
| legendary_won | 29 | 0 | 0.0 % |
| rival | 1957 | 19 | 1.0 % |
| rival_final | 479 | 7 | 1.5 % |
| wild | 5106 | 12 | 0.2 % |

## Type du starter vs victoire

| Type | Parties | Victoires | Taux |
|---|---:|---:|---:|
| water | 130 | 58 | 44.6 % |
| normal | 125 | 35 | 28.0 % |
| grass | 101 | 40 | 39.6 % |
| bug | 86 | 23 | 26.7 % |
| fire | 69 | 33 | 47.8 % |
| electric | 42 | 16 | 38.1 % |
| poison | 30 | 14 | 46.7 % |
| ghost | 26 | 7 | 26.9 % |
| ground | 26 | 12 | 46.2 % |
| rock | 26 | 13 | 50.0 % |
| dark | 25 | 12 | 48.0 % |
| psychic | 20 | 5 | 25.0 % |
| fighting | 19 | 5 | 26.3 % |
| steel | 18 | 7 | 38.9 % |
| fairy | 18 | 11 | 61.1 % |
| dragon | 16 | 4 | 25.0 % |
| ice | 14 | 7 | 50.0 % |
| flying | 9 | 3 | 33.3 % |

## Principaux tueurs (ennemis encore en vie à la défaite)

| Ennemi | Parties terminées par lui |
|---|---:|
| eternatus | 97 |
| machamp | 22 |
| hitmonchan | 13 |
| centiskorch | 13 |
| alakazam | 12 |
| houndoom | 11 |
| aegislash | 10 |
| simisear | 9 |
| incineroar | 8 |
| lapras | 7 |
| probopass | 7 |
| dragonite | 7 |
| armarouge | 7 |
| espeon | 7 |
| hitmonlee | 6 |

Rencontres où l'on meurt le plus : `final_eternatus` (97), `league_fighting` (21), `league_psychic` (12), `league_dark` (10), `league_steel` (10), `league_ice` (7), `league_champion` (7), `legendary_rayquaza` (4), `league_ghost` (3), `elite_flying` (2)

Contrôles : combats bloqués (plafond de tours) = 4; actions refusées par le jeu = 0.

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
Fraction of `deck` an item effect concerns: cards of its card_type (attacks for damage_bonus_type), or cards inflicting its status.
Poké Mart: heal potion -> best item -> remove one basic card -> good card -> fill the belt with potions.
Option index of an event: the first option that loses neither HP nor a card (else the first).

Paramètres (`tools/balance/sim_policy.gd`, surchargeables par `--policy=fichier.json`) :

```gdscript
const DEFAULTS: Dictionary = {
	## Story 030: a charged (announced) enemy attack counts this many times its damage when deciding to block.
	"charged_attack_weight": 1.25,
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
			"block_flat": 0.6, "money_bonus_on_win": 0.15, "status_immunity": 2.0, "heal_percent_max": 0.2,
			# Story 029. Type / status scoped effects are multiplied by the deck share (see item_deck_share_scale).
			"damage_bonus_type": 2.5, "first_type_card_free": 5.0, "status_bonus": 2.5, "strength_start": 10.0,
			"draw_first_turn": 2.0, "energy_first_turn": 4.0, "apply_all_enemies": 3.0, "elan_cap_up": 3.0, "elan_keep_percent": 0.06,
			"talent_retrigger": 3.0, "exhaust_recycle": 2.0, "block_keep": 0.08, "capture_bonus": 0.1, "max_potions_up": 2.0,
			"add_ball": 0.5},
	## Story 029: a type / status scoped item is worth (share of the deck it concerns) x this (e.g. 1/3 of the deck x 6 = x2).
	"item_deck_share_scale": 6.0,
}
```
