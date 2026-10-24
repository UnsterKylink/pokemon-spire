# Story 019 — Valeurs modifiées et justification (phase 2 : réglage)

Simulateur : `tools/balance/run.sh <parties> <graine> <tag>` (joueur auto « correct, pas expert », politique inchangée).
Point de départ : `report-post-c.md` (0 / 600 victoires ; 51 % des parties meurent à l'arène de la zone 1).

## Journal des itérations

| Tag | Parties | Graine | Victoires | Principales étapes de défaite | Changement testé |
|---|---:|---:|---:|---|---|
| post-c | 600 | 1 | 0.0 % | zone1_boss 41 %, zone2_boss 19 % | (référence) |
| it01 | 600 | 1 | 0.0 % | zone3_boss 19.5 %, zone2_boss 14 %, zone1_elite 12 % | arènes tirées du roster (plus d'équipes fixes `gym_*`), paliers de zone adoucis ; +6 peu communes au pool |
| it02 | 600 | 1 | 0.0 % | zone4_boss 17.5 %, zone3_boss 17 %, zone2_boss 9.5 % | joueur 75→90 PV, deck de départ 2 attaques fortes, Centre 30→50 %, soin au badge 30→50 %, élites ×1.4/+1 → ×1.2/+0 |
| it03 | 600 | 1 | 0.0 % | zone6_wild 15 %, zone5_boss 12.5 %, zone4_boss 10.5 % | roster : PV et attaques des tiers 2-3 réduits (generate_roster.py + rescale_roster.py) |
| it04 | 600 | 1 | 0.2 % | Conseil (membres 2-4) 15.5 %, zone6_boss 12 % | multiplicateurs de zone aplatis (arène 0.85→1.25, sauvages 0.9→1.2) |
| it05 | 600 | 1 | 19.0 % | Éthernatos 21 % (51 % de ceux qui l'atteignent), zone6_wild 7 % | Conseil/Maître ×2.1-2.6 → ×1.3-1.55, soin Ligue 25→40 % ; tier 3 encore réduit |
| it06 | 600 | 1 | 20.8 % | Éthernatos 11.7 %, Maître 7.3 %, zone6_boss 6 % | Éthernatos 620→520 PV, force +5→+4 ; Conseil ×1.4-1.7, Maître ×1.8/+4 ; zone 1 élites plus petites |
| it07 | 600 | 1 | 29.5 % | Éthernatos 16.5 % (36 % des arrivants), Maître 5.5 % | arènes zones 5-8 : équipes un tier plus bas ; Maître ×1.75/+3 |
| it08 | 600 | 1 | 34.7 % | Éthernatos 11.3 % (25 % des arrivants), Maître 5.5 % | Éthernatos 520→470 PV |
| it09 | 2000 | 7 | 31.6 % | zone 1 11.8 % (sauvages 5.3 %), Éthernatos 11.8 %, Maître 4.5 % | (même config, graine neuve) |
| it10 | 2000 | 7 | 31.0 % | zone2_boss 6.3 %, Éthernatos 10.9 % | sauvages zone 1 ×0.8 ; arène zone 2 [1,2,2] (trop : mur en zone 2 → annulé) |
| it11 | 2000 | 7 | 32.2 % | Éthernatos 10.8 %, zone 1 10.5 % (dont 51 combats bloqués par immunité) | zone 1 : part roster des sauvages 0.7→0.35 ; arène zone 2 ×1.0, [1,1,2] |
| it12 | 2000 | 7 | 36.6 % | Éthernatos 9.5 % (21 % des arrivants), zone 1 10.5 %, Maître 2.8 % | Conseil ×1.4-1.6, Maître ×1.65/+3, Éthernatos 450 PV |
| it13 | 3000 | 2026 | 35.6 % | Éthernatos 12 %, zone 1 10.3 % | starter Plante : Lame Feuille 6→7, Canon Graine 9→11 (Plante 16 %→18 %, < moitié de la moyenne avant) |
| — | — | — | — | — | **nouvelle exigence joueur « progression garantie »** (≥ 75 % à 3 badges, ≥ 50 % au Conseil, zone 1 ≤ 5 %, aucune étape > ~20 % des défaites) |
| it14 | 3000 | 2026 | 37.1 % | Éthernatos 11.7 %, zone 1 6.6 % | zone 1 : arène ×0.7, sauvages ×0.7, sauvages surtout solo {1:4,2:1}, élites solo |
| it15 | 3000 | 2026 | 38.6 % | Éthernatos 11.1 %, zone 1 5.5 % | zone 1 : arène ×0.6, part « du type » 0.5→0.2, part roster 0.35→0.2 |
| it16 | 3000 | 2026 | 35.6 % | Éthernatos 15.5 % (24 % des défaites → trop), zone 1 5.0 % | sauvages zone 1 ×0.6, Éthernatos 500 PV |
| it17 | 3000 | 2026 | 34.7 % | Éthernatos 12.1 % (18.5 % des défaites), zones 6–8 7.5–8.8 % | arènes zones 6/7/8 force +1 (2/2/3), Conseil force 3 partout, Éthernatos 475 PV |
| it18 | 3000 | 2026 | 36.1 % | Éthernatos 12.2 %, zone 1 2.1 %, **0 combat bloqué** | **correctif soft-lock d'immunité** (code, voir plus bas) |
| it19 | 3000 | 2026 | 34.4 % | zone 1 4.3 % (arène 3.3 %) | zone 1 rétablie : arène ×0.8, sauvages ×0.7 (le correctif rend la zone 1 bien plus douce) |
| it20 | 3000 | 2026 | 34.1 % | Éthernatos 13.2 % (20 % des défaites), zone 1 3.2 % | arène zone 1 ×0.7 |
| it21 | 3000 | 2026 | 35.3 % | Éthernatos 12.1 % (18.7 % des défaites), zone 1 3.2 % | Éthernatos 460 PV — **configuration finale** |
| **final** | **3000** | **31415** (neuve) | **35.8 %** (IC 95 % 34.1–37.6) | Éthernatos 12.2 %, zones 6/7 8.0/8.1 %, zone 4 7.2 % ; zone 1 3.2 % | `report-final.md` |
| rob-seed99 | 1000 | 99 | 38.1 % (35.1–41.2) | Éthernatos 11.2 % | robustesse : 2e graine |
| rob-block030 | 1000 | 31415 | 35.7 % (32.8–38.7) | Éthernatos 11.9 % | politique `block_first_fraction` 0.30 (défaut 0.40 − 0.1) |
| rob-block040 | 1000 | 31415 | 36.5 % (33.6–39.5) | Éthernatos 12.1 % | politique par défaut (0.40), même graine |
| rob-block050 | 1000 | 31415 | 36.7 % (33.8–39.7) | Éthernatos 11.4 % | politique `block_first_fraction` 0.50 (+0.1) |

Contrôles « progression garantie » du rapport final (3000 parties) : ≥ 3 badges **87.9 %** (≥ 75 %), Conseil atteint **52.8 %** (≥ 50 %), défaites en zone 1 **3.2 %** (≤ 5 %), étape la plus meurtrière Éthernatos **12.2 % des parties = 19 % des défaites** (≤ ~20 %), victoire parmi les arrivants à Éthernatos **74.4 %**. Les 4 contrôles tiennent aussi sur les 4 runs de robustesse (≥ 3 badges 87–88 %, Conseil 52–54 %, zone 1 2.6–3.3 %).

## Valeurs modifiées (fichier → clé → ancienne → nouvelle → pourquoi)

Référence : commit 9845d6b (phase 1). Preuves : `report-post-c.md` (avant), rapports `report-itNN.md`, `report-final.md`.

| Fichier | Clé | Ancienne | Nouvelle | Pourquoi (étape corrigée / preuve) |
|---|---|---|---|---|
| zones.json | `gym_types.<rock,water,electric,grass,poison,fire,bug,flying,normal>.encounter` | `gym_<type>` (équipes fixes avec un stade 3 : Arcanin, Ronflex, Onix…) | supprimé → équipe tirée du roster selon `gym_team_tiers` | zone1_boss = 41 % des parties (post-c) : une arène fixe ignorait le palier de zone ; it01 |
| zones.json | `tiers[*].gym_modifiers` (hp, force) z1..z8 | 1.0/0, 1.15/0, 1.3/1, 1.45/1, 1.6/2, 1.75/2, 1.9/3, 2.0/3 | 0.7/0, 1.0/0, 1.0/0, 1.05/0, 1.1/1, 1.15/2, 1.2/2, 1.25/3 | mur arènes zones 1–6 (it01–it04, it07) ; zone 1 ≤ 5 % (it14–it20) ; défaites tardives zones 6–8 (it17) |
| zones.json | `tiers[*].modifiers` (sauvages/élites) z1..z8 | 1.0/0, 1.05/0, 1.1/0, 1.2/1, 1.3/1, 1.4/1, 1.5/2, 1.6/2 | 0.7/0, 0.95/0, 1.0/0, 1.0/0, 1.05/0, 1.1/0, 1.15/1, 1.2/1 | PV perdus par zone > PV max (it02–it03 : 135–190 PV/zone) ; zone6_wild 15 % (it03) |
| zones.json | `tiers[*].roster.gym_team_tiers` z1..z8 | [1,1,2], [1,2,2], [2,2,2], [2,2,3], [2,3,3], [3,3,3], [3,3,3], [3,3,3] | [1,1,1], [1,1,2], [1,2,2], [2,2,2], [2,2,2], [2,2,3], [2,3,3], [3,3,3] | arène zone 1 = 1 équipe tier 1 ; un tier plus bas en zones 5–7 (it07 : 20.8 → 29.5 %) |
| zones.json | `tiers[0].roster.wild_size_weights` / `elite_size_weights` | {1:3,2:2} / {1:1,2:2} | {1:4,2:1} / {1:1} | zone 1 ≤ 5 % (it14) |
| zones.json | `tiers[5].roster.wild_size_weights` / `elite_size_weights` (zone 6) | {1:1,2:3,3:3} / {2:1,3:2} | {1:2,2:3,3:1} / {2:2,3:1} | zone6_wild 7–15 % (it03–it05) |
| zones.json | `tiers[6..7].roster.wild_size_weights` (zones 7–8) | {1:1,2:3,3:3} | {1:2,2:3,3:2} | pic de PV perdus zones 7–8 (it04) |
| zones.json | `tiers[0].roster.wild_share` (zone 1) | 0.7 | 0.2 | moins de Pokémon roster (souvent Spectre/Acier) au tout début (it11, it15) |
| zones.json | `tiers[0].wild_type_share` (zone 1) | 0.5 | 0.2 | idem (it15) |
| zones.json | `badge_heal_percent` | 30 | 50 | PV perdus par zone > PV max (it02) |
| zones.json | `softlock_rerolls` (nouvelle clé) | — | 10 | correctif soft-lock d'immunité (it18) |
| act1.json | `room_types.elite.modifiers` | ×1.4 / +1 | ×1.2 / +0 | zone1_elite 13 % (post-c), élites +1 tier déjà via `elite_tier_bonus` (it02) |
| act1.json | `room_types.center.heal_percent` | 30 | 50 | PV perdus par zone > PV max (it02) |
| pokemon.json | `player.salameche.max_hp` (PV max de tout starter) | 75 | 90 | joueur 75 PV vs ≈ 77–120 PV perdus par zone (post-c) ; it02 |
| pokemon.json | `starter_deck_template.strong_count` | 1 | 2 (deck de départ 11 cartes) | ≈ 18 dégâts/tour contre ≈ 143 PV d'équipe en zone 1 (post-c) ; it02 |
| pokemon.json | `enemies.eternatus.max_hp` | 620 | 460 | Éthernatos tuait 51 % des arrivants (it05) → 25.5 % (final) |
| cards.json | `lame_feuille.damage` (+ description) | 6 | 7 | starter Plante 16 % de victoires < moitié de la moyenne (it09–it12) ; it13 |
| cards.json | `canon_graine.damage` (+ description) | 9 | 11 | idem |
| league.json | `member_modifiers` (×PV / force) | 2.1/3, 2.2/4, 2.3/4, 2.4/4 | 1.4/3, 1.45/3, 1.5/3, 1.6/3 | Conseil membres 2–4 = 15.5 % des parties (it04) ; doit rester ≥ arène zone 8 (1.25/3) |
| league.json | `champion.modifiers` | 2.6/5 | 1.65/3 | Maître 7.3 % (it06) |
| league.json | `final_boss.modifiers.strength_bonus` | 5 | 4 | Éthernatos 21 % des parties (it05) |
| league.json | `heal_percent_between_fights` | 25 | 40 | 6 combats d'affilée sans retour à la carte (it05) |
| rewards.json | `player_pool.salameche` | 77 cartes | + `laser_glace`, `casse_brique`, `psyko`, `ball_ombre`, `tete_de_fer`, `colere` (83) | décision joueur : chaque type ≥ 2 peu communes obtenables en récompense |
| tools/roster/generate_roster.py | `HP_RANGE` | {1:(28,50), 2:(50,80), 3:(80,140)} | {1:(28,48), 2:(42,66), 3:(55,85)} | tiers 2–3 : PV × 2–3 alors que le deck du joueur progresse peu (it02–it05) |
| tools/roster/generate_roster.py | `ATTACK_RANGE` | {1:(5,9), 2:(8,14), 3:(12,22)} | {1:(4,8), 2:(6,11), 3:(8,13)} | équipes de 3 tier 3 : jusqu'à 3 × 22+force par tour (it02–it05) |
| tools/roster/generate_roster.py | `BLOCK_RANGE` | {1:(4,7), 2:(6,11), 3:(9,16)} | {1:(4,7), 2:(5,9), 3:(7,11)} | cohérence avec les attaques réduites |
| roster.json | `pokemon.*.max_hp` et `actions[].value` (attack / block) des 720 entrées | valeurs générées avec les anciennes plages | re-projetées par `tools/roster/rescale_roster.py` : même position relative t dans la plage du tier, `v' = round(lo' + t·(hi'−lo'))` (= ce que `generate_roster.lerp_int` donne avec les nouvelles plages) ; statuts / types d'attaque inchangés ; `validate_roster.py` 0 erreur | régénération complète impossible hors ligne (cache CSV incomplet : 673 au lieu de 720 Pokémon) |

Inchangés (vérifiés, pas besoin d'y toucher) : statuses.json, shop.json (prix, butin, potions), items.json, potions.json, rareté des récompenses, `evolution_hp_bonus`, `badge_rewards`, `elite_tier_bonus`, politique du joueur auto (`sim_policy.gd` DEFAULTS).

## Correctif : combat impossible par immunité (soft-lock)

**Constat** (it11 : 51 combats bloqués sur 2000, presque tous au 1er combat de la zone 1) : un deck dont TOUTES les attaques font ×0 à un ennemi (deck Normal contre Spectre, Sol contre Vol, Spectre contre Normal, Électrik contre Sol…) ne peut pas gagner — vrai blocage pour un joueur humain, pas un artefact du simulateur.

**Règle** (données + code minimal) : quand un combat **sauvage ou élite** est tiré, si un des ennemis est immunisé à **tous** les types d'attaque présents dans le deck actuel du joueur, le combat est re-tiré avec le même RNG (graine), au plus `zones.json softlock_rerolls` fois (10) ; si tous les tirages sont bloqués, le dernier est gardé (repli). Aucun tirage supplémentaire quand le premier est bon : les parties sans combat bloqué sont identiques à avant. Les arènes ne sont pas re-tirées (équipe fixée au début de la partie ; le deck a alors reçu des récompenses d'autres types).

**Code** : `src/data/game_data.gd` — `pick_encounter(..., attack_types: Array[String] = [])` (boucle de re-tirage autour de l'ancien corps devenu `_pick_encounter_once`), `deck_attack_types(deck)`, `encounter_softlocks(encounter_id, attack_types)`, constante `DEFAULT_SOFTLOCK_REROLLS` + validation de `softlock_rerolls` (entier ≥ 0) dans `_load_zones` ; appels : `src/main.gd` `_start_room_fight` et `tools/balance/sim_run.gd` `_room_fight` passent `_data.deck_attack_types(_run.deck)`.

**Effet** : combats bloqués 51–61 → 0–2 par 3000 parties (les 2 restants = plafond de 80 tours, pas d'immunité) ; zone 1 10.3 % → 2.1 % des parties à réglage égal (it17 → it18). Test : scratch `t22` (20 assertions : 1931 tirages bloquants sans correctif → 24 avec, ≥ 98 % supprimés ; aucun tirage en plus quand le 1er est bon ; déterminisme ; validation).
