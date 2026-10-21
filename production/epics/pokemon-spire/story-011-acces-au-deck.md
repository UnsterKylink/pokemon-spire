# Story 011: Accès au deck partout

> **Epic**: Pokémon Spire
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief feuille de route, étape 1` (« Après le MVP », 2026-10-21)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (section « Après le MVP — feuille de route », étape 1), scoped to this story:*

- [ ] Un bouton « Deck » dans la barre du haut est visible et utilisable sur tous les écrans de partie (carte, combat, récompense, événement, Centre, Mart, évolution).
- [ ] En combat, on peut consulter séparément le deck complet, la pioche (ordre masqué, triée) et la défausse.
- [ ] L'affichage regroupe les copies identiques (×N), montre les cartes améliorées « + » distinctement et le Pokémon porteur de chaque carte.
- [ ] Ouvrir / fermer le deck ne modifie jamais l'état de la partie ni du combat (pas de tour perdu, pas de clic traversant).
- [ ] Le panneau tient en 1280×720 sans coupure, avec défilement si le deck est long (40+ cartes).

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Aucune autre fonctionnalité de la feuille de route.

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

- Depends on: None (MVP complete)
- Unlocks: Story 012
