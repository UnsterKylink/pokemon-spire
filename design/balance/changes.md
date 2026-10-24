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

## Valeurs modifiées (fichier → clé → ancienne → nouvelle → pourquoi)

(rempli au fil des itérations ; la version finale est en bas)
