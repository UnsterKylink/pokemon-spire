# Story 023: Menu principal, pause, options et tutoriel

> **Epic**: Pokémon Spire
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief feuille de route, étape 6` (« Après le MVP », 2026-10-21)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (section « Après le MVP — feuille de route », étape 6), scoped to this story:*

- [ ] Menu principal : Continuer (si une sauvegarde existe), Nouvelle partie, Options, Quitter.
- [ ] Pause en partie (touche Échap) : reprendre, options, abandonner la partie, quitter.
- [ ] Options : volumes, vitesse des animations, plein écran, mémorisées.
- [ ] Infobulles sur les mots-clés (protection, statuts, types, efficacité…) au survol des cartes et intentions.
- [ ] Un tutoriel court au premier lancement explique le switch, l'énergie et les types ; il peut être passé et revu.

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 024 : version .exe

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: UI
**Required evidence**:
- UI : a retained screenshot of each screen touched, in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 022
- Unlocks: Story 024
