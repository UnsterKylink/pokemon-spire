# Rapport d'équilibrage — niveaux de difficulté (story 026)

Simulateur `tools/balance/run.sh <parties> 1 <tag> 4 "" <niveau>` (option `--level` de `simulate.gd`), **500 parties par niveau**, graine 1, politique par défaut, données `assets/data/difficulty.json` finales. Le niveau N applique les modificateurs 1..N (cumulatifs). Niveau 0 = jeu actuel (référence `report-final032.md` : 35.0 % sur 2000 parties).

| Niveau | Modificateur ajouté | % victoires (IC 95 %) | % Conseil 4 atteint | % ≥ 3 badges | Défaites en zone 1 |
|---:|---|---:|---:|---:|---:|
| 0 | — (jeu normal) | **34.8 %** (30.8–39.1) | 60.8 % | 82.0 % | 3.4 % |
| 1 | **Élites aguerris** — Les dresseurs d'élite ont plus de PV et frappent plus fort. | **30.2 %** (26.3–34.4) | 51.0 % | 77.6 % | 4.0 % |
| 2 | **Champions motivés** — Les Champions d'arène et ton rival ont plus de PV. | **26.0 %** (22.3–30.0) | 45.0 % | 72.8 % | 4.8 % |
| 3 | **Bourse légère** — Tu gagnes 45 % d'argent en moins. | **24.2 %** (20.7–28.1) | 43.4 % | 72.8 % | 4.8 % |
| 4 | **Infirmière débordée** — Le Centre Pokémon et les pauses de la Ligue soignent 20 % de moins. | **22.8 %** (19.3–26.7) | 43.4 % | 72.8 % | 4.8 % |
| 5 | **Hautes herbes** — Les Pokémon sauvages et légendaires ont plus de PV et frappent plus fort. | **19.0 %** (15.8–22.7) | 38.8 % | 69.4 % | 5.4 % |
| 6 | **Sac encombré** — Ton deck de départ contient un « Débris » injouable. | **18.4 %** (15.2–22.0) | 35.8 % | 65.4 % | 5.0 % |
| 7 | **Départ fragile** — Tu commences la partie avec 8 PV max de moins. | **15.2 %** (12.3–18.6) | 28.4 % | 61.6 % | 6.8 % |
| 8 | **Inflation** — Les prix du Poké Mart augmentent de 40 %. | **14.0 %** (11.2–17.3) | 29.2 % | 61.4 % | 7.0 % |
| 9 | **Ligue d'élite** — Le Conseil 4 et le Maître ont plus de PV. | **11.2 %** (8.7–14.3) | 29.2 % | 61.4 % | 7.0 % |
| 10 | **Éthernatos déchaîné** — Éthernatos a plus de PV et récupère des PV à chaque changement de phase. | **9.0 %** (6.8–11.8) | 29.2 % | 61.4 % | 7.0 % |

## Lecture

- Le taux de victoire baisse à chaque niveau, de **34.8 %** (niveau 0) à **9.0 %** (niveau 10) : cible ≈ 35 % → 8–12 %, le niveau 10 reste gagnable.
- Paliers les plus marqués : 1 (élites ×1.3 PV, +1 Force), 2 (arènes / rival ×1.05 PV : les Champions sont déjà le principal goulot), 5 (sauvages ×1.2 PV, +1 Force), 7 (−8 PV max), 9 (Ligue ×1.08 PV). Paliers plus doux : 3 (argent ×0.55), 4 (soins ×0.8), 6 (1 Débris), 8 (Poké Mart ×1.4) — ils jouent surtout sur l'économie / la régularité, que le simulateur exploite peu (il achète peu au Mart).
- Écarts d'un niveau à l'autre de 0.6 à 4.6 points ; avec 500 parties l'IC 95 % fait ±3.5–4 points, donc deux niveaux voisins peuvent se chevaucher, mais la tendance est monotone.
- Premier essai (pour mémoire) : arènes +1 Force ×1.12 PV au niveau 2 faisait chuter de 34 % à 17.6 % d'un coup, et Éthernatos +1 Force ×1.15 + 10 % de soin par phase laissait le niveau 10 à 4 % : valeurs adoucies.

## Leviers (difficulty.json)

Vocabulaire d'effets générique : `enemy_hp` / `enemy_strength` par catégorie de combat (wild, elite, boss, rival, rival_final, legendary, league_member, league_champion, league_final_boss), `money_gain`, `center_heal`, `league_heal`, `shop_prices`, `start_max_hp`, `start_junk`, `boss_phase_heal`. Aucun code par niveau.
