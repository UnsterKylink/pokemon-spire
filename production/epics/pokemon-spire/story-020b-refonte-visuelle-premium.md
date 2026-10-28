# Story 020b: Refonte visuelle premium

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-28

## Context

**GDD**: `design/game-brief.md` + `design/art-bible.md`
**Requirement**: retour du joueur sur la story 020 (2026-10-26) : « ça fait un peu jeu flash », viser le niveau visuel de Slay the Spire.

**ADR Governing Implementation**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH

---

## Acceptance Criteria

*Choix du joueur (2026-10-26) :*

- [x] **Pokémon animés** : en combat, les Pokémon utilisent des sprites animés (Showdown, convertis en planches d'images stockées dans le projet) ; le Pokémon du joueur est vu de dos ; repli sur l'artwork / le sprite fixe si l'animation manque.
- [x] **Sprites d'objets** : objets tenus, potions, Poké Balls (et baies) ont une illustration officielle (PokeAPI dream-world), affichée au Poké Mart, dans la barre du haut, dans les récompenses et les événements.
- [x] **Cartes premium** : cadre texturé (matière selon la rareté), effet holographique animé sur les cartes rares et légendaires, ombre portée, carte qui grandit et s'incline au survol ; lisibilité conservée.
- [x] **Polices et finitions** : vraies polices libres (titres + texte), effets d'image (vignette, grain, étalonnage, halo), panneaux texturés à la place des aplats.
- [x] **Carte style Pokémon** (retour du joueur : pas de parchemin) : la carte d'avancement ressemble à la carte de région des jeux Pokémon (vue du dessus, routes, Centre, Mart, arène).
- [x] **Décors peints prêts à intégrer** : prompts d'images (un par décor, style cohérent, 1280×720) fournis au joueur dans `design/art/backdrop-prompts.md` ; le jeu charge une image de décor si elle existe dans `assets/art/backdrops/<id>.png`, sinon le décor dessiné en code (amélioré par shaders : brume, lumière, profondeur).
- [x] Tous les écrans gardent 1280×720 sans coupure ni chevauchement.

---

## Out of Scope

- 021 : animations d'attaque et de combat (cartes qui glissent, impacts, chiffres de dégâts)
- 022 : son

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: captures conservées dans `production/qa/evidence/story-020b-refonte-visuelle-premium/` + validation dans `production/qa/evidence/story-020b-refonte-visuelle-premium-evidence.md`

**Status**: [x] Captures dans `production/qa/evidence/story-020b-refonte-visuelle-premium/` + validation dans `story-020b-refonte-visuelle-premium-evidence.md`

---

## Dependencies

- Depends on: Story 020
- Unlocks: Story 021

## Completion Notes
**Completed**: 2026-10-28
**Criteria**: 7/7 passing (validés par le joueur en jeu ; captures 1x-, 2x-, 3x- conservées)
**Deviations**: Advisory only — carte d'avancement : parchemin remplacé à la demande du joueur par des cartes de région et icônes IA fournies par lui (`assets/art/map/`, outil `tools/art/prepare_map_icons.py`) ; polices Lilita One + Jost (la police fan « Pokemon Solid » peut être déposée dans `assets/fonts/pokemon/`) ; décors peints du joueur au format JPG ; écran de choix du starter encore en sprites pixelisés ; pas d'option « réduire les animations » ; image d'écran titre fournie mais non affichée (story 023)
**Test Evidence**: Visual/Feel — captures et validation joueur dans `production/qa/evidence/story-020b-refonte-visuelle-premium(-evidence.md)`
**Code Review**: Skipped — Solo mode
