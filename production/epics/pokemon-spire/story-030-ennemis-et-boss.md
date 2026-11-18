# Story 030: Ennemis variés et boss à mécanique

> **Epic**: Pokémon Spire
> **Status**: In Progress
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/game-brief.md` + `design/revue-complete-2026-11.md` (§3.4, étape A.4)
**Requirement**: choix du joueur « Nouvelles actions + boss à mécanique » (2026-11-16).

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**Engine**: Godot 4.6 | **Risk**: HIGH

---

## Acceptance Criteria

- [ ] **Nouvelles actions ennemies, en données** (pokemon.json / roster.json via des modèles par type) : infliger un statut au joueur (Brûlure, Poison, Paralysie, Sommeil, Gel, Faiblesse, Vulnérable), attaque multi-coups, attaque de zone sur la protection, se soigner, soigner / protéger un allié, gros coup « chargé » annoncé un tour à l'avance, retirer de la protection, voler de l'énergie, ajouter une carte « Débris » inutile dans le deck de combat. Les intentions affichent clairement l'action (icône + texte).
- [ ] Les Pokémon sauvages et élites du roster reçoivent des actions variées selon leur type (modèles par type, sans édition à la main de 720 entrées).
- [ ] **Règle de terrain par Champion** liée au type de son arène (ex. Feu : chaque tour, la carte la plus chère de ta main brûle ; Eau : les ennemis gagnent 3 protection par tour ; Électrik : la 1re carte du tour coûte +1…), affichée en bannière au début du combat et en rappel à l'écran.
- [ ] **Conseil 4 et Maître** : chaque membre a une règle propre ; **Éthernatos** a des phases (au moins 2 : à 50 % de PV il change de forme / d'actions, message affiché).
- [ ] Le simulateur joue contre ces nouvelles actions et règles ; rapport de simulation (pas de rééquilibrage fin : story 031).
- [ ] Tests headless dans `tests/scratch/` (chaque nouvelle action, règles de terrain, phases d'Éthernatos).
- [ ] Captures : intentions nouvelles, bannière de règle de Champion, phase 2 d'Éthernatos.

---

## Out of Scope

- 031 : rééquilibrage fin

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/scratch/t30_enemies.gd` + captures dans `production/qa/evidence/story-030-ennemis-et-boss/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 029
- Unlocks: Story 031
