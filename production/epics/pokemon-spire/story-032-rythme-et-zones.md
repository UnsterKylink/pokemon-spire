# Story 032: Rythme de la partie et zones différentes

> **Epic**: Pokémon Spire
> **Status**: In Progress
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

- [ ] Chaque zone passe de 6 à **4 étages** (3 salles + l'arène) ; on garde 8 badges, le rival, le Conseil 4, le Maître et Éthernatos. Une partie gagnée compte environ 25–30 combats (mesuré par le simulateur), contre ~45–50 avant.
- [ ] Les étages forcés (rival, Centre avant l'arène…), évolutions, badges, bonus de badge et équilibre des récompenses sont adaptés au nouveau nombre d'étages (assez de récompenses pour construire un deck en moins de combats).
- [ ] **Règle de zone** : chaque zone applique une version légère de la règle de son arène à tous ses combats sauvages et élites (en données, valeurs plus faibles), affichée sur la carte (bandeau de zone) et en combat (pastille).
- [ ] Récompenses thématiques : cartes et objets du type de la zone plus fréquents dans la zone (en données).
- [ ] Rééquilibrage pour garder les cibles du joueur : ~35 % de victoires complètes, ≥ 75 % à 3 badges, ≥ 50 % au Conseil 4, zone 1 ≤ 5 %, aucune étape > ~20 % des défaites (≥ 2000 parties).
- [ ] Sauvegardes anciennes (6 étages) : reprises sans plantage ou refusées proprement.
- [ ] Tests `tests/scratch/` qui passent ; captures de la carte (4 étages, bandeau de règle de zone) et d'un combat sauvage avec la pastille de règle.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: rapport de simulation + tests + captures dans `production/qa/evidence/story-032-rythme-et-zones/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 031
