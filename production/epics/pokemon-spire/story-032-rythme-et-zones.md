# Story 032: Rythme de la partie et zones différentes

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/game-brief.md` + `design/revue-complete-2026-11.md` (§3.3, étape B)
**Requirement**: choix du joueur (2026-11-18) : partie gagnée d'environ **1 h – 1 h 15** ; **règle de terrain sur toute la zone**.

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**Engine**: Godot 4.6 | **Risk**: HIGH

---

## Acceptance Criteria

- [x] Chaque zone passe de 6 à **4 étages** (3 salles + l'arène) ; on garde 8 badges, le rival, le Conseil 4, le Maître et Éthernatos. Une partie gagnée compte environ 25–30 combats (mesuré par le simulateur), contre ~45–50 avant.
- [x] Les étages forcés (rival, Centre avant l'arène…), évolutions, badges, bonus de badge et équilibre des récompenses sont adaptés au nouveau nombre d'étages (assez de récompenses pour construire un deck en moins de combats).
- [x] **Règle de zone** : chaque zone applique une version légère de la règle de son arène à tous ses combats sauvages et élites (en données, valeurs plus faibles), affichée sur la carte (bandeau de zone) et en combat (pastille).
- [x] Récompenses thématiques : cartes et objets du type de la zone plus fréquents dans la zone (en données).
- [x] Rééquilibrage pour garder les cibles du joueur : ~35 % de victoires complètes, ≥ 75 % à 3 badges, ≥ 50 % au Conseil 4, zone 1 ≤ 5 %, aucune étape > ~20 % des défaites (≥ 2000 parties).
- [x] Sauvegardes anciennes (6 étages) : reprises sans plantage ou refusées proprement.
- [x] Tests `tests/scratch/` qui passent ; captures de la carte (4 étages, bandeau de règle de zone) et d'un combat sauvage avec la pastille de règle.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: rapport de simulation + tests + captures dans `production/qa/evidence/story-032-rythme-et-zones/`

**Status**: [x] Rapport `design/balance/report-final032.md` + `report-rob032.md`, test `tests/scratch/t32_pacing.gd`, captures `production/qa/evidence/story-032-rythme-et-zones/`

---

## Dependencies

- Depends on: Story 031

## Completion Notes
**Completed**: 2026-11-18
**Criteria**: 7/7 (validé par le joueur ; final032 : 35,0 % de victoires, ≥3 badges 80,0 %, Conseil 4 atteint 60,9 %, zone 1 4,2 %, Éthernatos 17,4 % des défaites, 29,2 combats par partie gagnée ; t32 38676/0 ; 5 captures)
**Deviations**: Advisory only — le rival ouvre les zones 2/4/6 à l'étage 1 (et non 2) pour garder l'étage 2 libre ; règles de zone Plante et Fée sans soin ennemi (Sommeil / Vulnérable) pour éviter des combats bloqués ; 10 combats bloqués sur 2000 (5 avant) surtout aux arènes de zone 1 ; seed 7 : 39,7 % de victoires et Éthernatos 23,8 % des défaites (petit échantillon) ; t17 garde 2 échecs préexistants (cartes Fée) ; les anciens jeux de captures (005, 012, 018…) non relancés sur 4 étages ; bannière de règle de zone de 3 s qui peut recouvrir un texte de Talent (traité en story 033) ; le résumé de fin d'une ancienne sauvegarde peut afficher trop d'étages
**Test Evidence**: Integration — `tests/scratch/t32_pacing.gd` + rapports de simulation + captures `production/qa/evidence/story-032-rythme-et-zones/`
**Code Review**: Skipped — Solo mode
