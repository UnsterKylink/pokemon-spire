# Story 033: Cohérence visuelle (étape C de la revue)

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-19

## Context

**GDD**: `design/game-brief.md`, `design/art-bible.md`, `design/revue-complete-2026-11.md` (§4, étape C)
**Requirement**: choix du joueur (2026-11-18) : jeu privé ; illustrations officielles HD hors combat ; panneaux blancs à cadre bleu (style menus Pokémon, déjà sur la carte) partout ; pas de nouvelles images IA (le joueur ne peut plus en générer) → événements composés avec les images existantes.

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**Engine**: Godot 4.6 | **Risk**: HIGH

---

## Acceptance Criteria

- [x] **Un seul style de Pokémon hors combat** : illustrations officielles HD (`assets/sprites/artwork/`) sur le choix du starter, l'évolution, l'intro du rival, l'équipe (deck), les légendaires, la capture réussie, l'écran de fin, la reprise de partie ; les sprites animés restent en combat.
- [x] **Un seul langage d'interface** : panneaux blancs à cadre bleu (comme la carte) sur tous les écrans : événements, Mart, Centre, récompenses, badges, Conseil 4, rival, évolution, fin de partie, deck, options, reprise ; boutons, titres et couleurs cohérents ; la bible artistique est mise à jour.
- [x] **Événements illustrés sans nouvelle image** : fond = décor peint du type de la zone (flouté / assombri), au premier plan l'illustration du Pokémon ou de l'objet concerné (données d'événement : `art` optionnel = id de Pokémon ou d'objet), panneau de texte au style unique ; les légendaires gardent leur mise en scène.
- [x] **Combat plus lisible** : en mode capture, les boutons de Balls ne recouvrent plus les ennemis (un seul panneau) ; « Super efficace ! » ne recouvre plus l'intention ; la bannière de règle de zone est plus courte et ne recouvre pas les textes de Talent ; sprites de dos plus nets (échelle entière / filtre).
- [x] **Mart** : articles achetés ou « pleins » lisibles (grisés mais lisibles).
- [x] **Transitions** entre écrans (fondu court, désactivé en vitesse d'animation « Instantané »).
- [x] 1280×720 sans coupure ni chevauchement ; captures de chaque écran touché.

---

## Out of Scope

- 023 : menu principal / écran titre (l'image `assets/art/title/title.jpg` y sera utilisée)

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: captures de chaque écran dans `production/qa/evidence/story-033-coherence-visuelle/` + validation du joueur

**Status**: [x] 21 captures dans `production/qa/evidence/story-033-coherence-visuelle/`, validation du joueur

---

## Dependencies

- Depends on: Story 032

## Completion Notes
**Completed**: 2026-11-19
**Criteria**: 7/7 (validé par le joueur ; 21 captures vues ; t9 440/0, t11 950/0, t18, t20, t21, t24–t30, t32 OK ; t17 : 2 échecs préexistants sur les cartes Fée)
**Deviations**: Advisory only — les articles du Mart sont posés sur le fond bleu, pas dans une grande fenêtre blanche (pour tenir dans 720 px) ; la bannière de règle de zone recouvre encore un peu les ennemis pendant 1,8 s ; l'effet d'assombrissement des bords (`PostFx`) grise les côtés des fenêtres blanches (antérieur à la story) ; la capture « réussie » est prise pendant la secousse de la Ball ; `MenuBox` s'appuie sur l'API `StyleBox._draw` non documentée dans `docs/engine-reference` (fonctionne en 4.6.3) ; nouveau champ `art` dans `events.json` (`pokemon`, `item` ou `rival`)
**Test Evidence**: Visual/Feel — captures `production/qa/evidence/story-033-coherence-visuelle/` ; validation du joueur (2026-11-19)
**Code Review**: Skipped — Solo mode
