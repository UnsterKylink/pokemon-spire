# Story 011 — Accès au deck partout (evidence)

Capture (1280x720, Godot 4.6.3, xvfb):
`xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- production/qa/evidence/story-011-acces-au-deck story-011`
(Salamèche forced, seed 2026; panel opened through Main.open_deck / map_open_deck, i.e. the same path as the buttons; 45-card deck via the QA cheat Main.qa_give_cards.)

| Shot | Observed |
|---|---|
| 01-deck-carte | Map, panel open under the HUD (Deck button visible top right). No tabs outside a battle; title "Ton deck (10 cartes)"; groups Abri ×4, Flammette ×5, Flammèche ×1 with carrier Pokémon (sprite + name) or "Équipe" for skills. |
| 02-deck-combat | Battle, tab "Deck complet (10)" selected; tab titles carry counts (10 / 5 / 0). Battle screen dimmed behind. |
| 03-pioche-combat | Tab "Pioche (5)": Abri ×1, Flammette ×4, sorted by name with the hint "l'ordre de pioche reste secret". |
| 04-defausse-combat | After 2 attacks played: "Défausse (2)" = Flammette ×1, Flammèche ×1. |
| 05-deck-45-cartes | 45 cards = 34 groups, 6 columns, scrollbar visible, "Fermer" not covered. Upgraded "+" cards have a pink border + pink ×N, distinct from the rarity colours. |
| 05b-deck-45-cartes-bas | Same panel scrolled to the bottom (last row fully visible). |
| 06-deck-mart | Poké Mart with the panel open over it; HUD (P$ 260, Deck) stays visible. |

Console checks (same run): opening/closing leaves hand / draw / discard / energy / HP / block unchanged (map and battle); Mart removal picker open -> Deck button disabled and Main.open_deck refused; re-enabled after cancel.

Not covered: Escape key and mouse-click-through checked by design only (dim ControlRect STOP, `_input` ui_cancel), not by a real input event; gamepad; event / Centre / evolution / reward screens not captured (same HUD button, same panel); panel not refreshed if the battle changes while it is open (e.g. during the enemy turn).
