# Story 019: Équilibrage et cartes manquantes

> **Epic**: Pokémon Spire
> **Status**: Ready
> **Layer**: Feature
> **Type**: Config/Data
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief feuille de route, étape 4` (« Après le MVP », 2026-10-21)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (section « Après le MVP — feuille de route », étape 4), scoped to this story:*

- [ ] Ajout de cartes peu communes et rares pour les types qui n'en ont pas (Insecte, Ténèbres, Combat…) afin que chaque type ait au moins 2 peu communes et 1 rare.
- [ ] Correction : un ennemi à double type attaque avec le type de l'action (défini en données) et non plus toujours avec son 1er type.
- [ ] PV, dégâts et modificateurs des ennemis ajustés zone par zone pour une courbe de difficulté régulière ; prix, gains d'argent et taux de potions/objets ajustés.
- [ ] Un outil ou script de simulation (hors jeu) estime la difficulté (ex. dégâts moyens reçus par zone) pour justifier les valeurs.
- [ ] Les valeurs modifiées et leur justification sont notées dans le dossier d'équilibrage (design/balance/).

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.
- **Question de design à trancher avec le joueur au début de `/dev-story`** (voir le brief : « à décider avant de coder »).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 020 : esthétique

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Config/Data
**Required evidence**:
- Config/Data : smoke check pass (`production/qa/smoke-*.md`) — advisory, plus a retained screenshot if anything on screen changes.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 018
- Unlocks: Story 020
