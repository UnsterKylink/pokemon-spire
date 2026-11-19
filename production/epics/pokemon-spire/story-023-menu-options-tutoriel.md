# Story 023: Menu principal, pause, options et tutoriel

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-19

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

- [x] Menu principal : Continuer (si une sauvegarde existe), Nouvelle partie, Options, Quitter.
- [x] Pause en partie (touche Échap) : reprendre, options, abandonner la partie, quitter.
- [x] Options : volumes, vitesse des animations, plein écran, mémorisées.
- [x] Infobulles sur les mots-clés (protection, statuts, types, efficacité…) au survol des cartes et intentions.
- [x] Un tutoriel court au premier lancement explique le switch, l'énergie et les types ; il peut être passé et revu.
- [x] **Choix du joueur (2026-11-19)** : tutoriel = **premier combat guidé** (bulles pas à pas pointant énergie, carte, intention, switch, types, Élan, fin de tour ; passable ; revoyable depuis le menu). Écran titre = image `assets/art/title/title.jpg` + musique titre + **logo « Pokémon Spire »** (jaune, contour bleu) + **un Pokémon animé tiré au hasard** + **statistiques** (parties jouées / gagnées / meilleur résultat, sauvegardées).

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

**Status**: [x] Captures dans `production/qa/evidence/story-023-menu-options-tutoriel/` (19 PNG), `tests/scratch/t23_menus.gd`

---

## Dependencies

- Depends on: Story 022
- Unlocks: Story 024

## Completion Notes
**Completed**: 2026-11-19
**Criteria**: 6/6 (validé par le joueur ; t23_menus 58/0, t19 72/0, t9–t11, t18, t20–t22, t24–t30, t32 OK, t17 : 2 échecs préexistants ; captures 01–18)
**Deviations**: Advisory only — écran titre refait à la demande du joueur (maquette B « Deck de légende » + logo « Or royal » : fond du hall du Conseil 4, éventail de 5 vraies cartes tirées au hasard, boutons en ligne, une ligne de statistiques ; plus de Pokémon sur le titre) ; logo généré par `tools/art/make_logo.py` (polices Cinzel, OFL) ; la vignette de `PostFx` est coupée sur l'écran titre ; certaines bulles du tutoriel recouvrent un élément et l'étape « switch » n'a pas de flèche dans la toute première partie (un seul Pokémon dans le deck) ; il faut deux clics sur une bulle quand une animation joue ; `DisplayServer.window_set_mode` (plein écran) non couvert par `docs/engine-reference` ; `keywords.json` et `tutorial.json` suivent le nommage existant d'`assets/data`
**Test Evidence**: UI — captures `production/qa/evidence/story-023-menu-options-tutoriel/` ; `tests/scratch/t23_menus.gd`
**Code Review**: Skipped — Solo mode
