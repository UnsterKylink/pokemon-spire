# Evidence — Story 003: Types et multiplicateurs

**Date:** 2026-10-18 · **Engine:** Godot 4.6.3-stable (Linux, cloud session, Xvfb 1280x720, gl_compatibility)
**How captured:** `godot --path . --windowed --resolution 1280x720 -s res://tools/qa/battle_walkthrough.gd -- <this folder>` (scripted, no real mouse events).

| Shot | Observed |
|------|----------|
| `01-trio-mix-debut-types.png` | Type badges: Salamèche Feu; Mystherbe Plante, Pikachu Électrik, Racaillou Roche; Griffe cards "Normal". Intents already show final values vs Fire: Mystherbe "Attaque 2" (grass 5 × 0.5), Racaillou "Attaque 9" (rock 6 × 1.5) |
| `02-feu-sur-plante-super-efficace.png` | Flammèche (fire 8) on Mystherbe: 27 → 15 (12 = 8 × 1.5), green "Super efficace !" over it |
| `03-feu-sur-roche-pas-tres-efficace.png` | Flammèche on Racaillou: 34 → 30 (4 = 8 × 0.5), grey "Ce n'est pas très efficace…" over it, fully on screen |
| `04a-ptitard-intention-attaque-9.png` | Ptitard (Eau) shows "Attaque 9" (6 × 1.5 vs Fire) |
| `04b-ptitard-touche-le-joueur-super-efficace.png` | Player 75 → 66 (exactly the 9 shown), "Super efficace !" over Salamèche; Flammèche card shows the "Feu" badge |
| `05-victoire.png` | Victory; leftover effectiveness labels sit under the dim, the message stays on top |

**Defects found and fixed during the run:** the "Ce n'est pas très efficace…" label was too wide and covered the neighbouring enemy → floating label font 30 → 22; a label shown right after an encounter change was placed at a stale position and drawn above the end-of-battle dim → positioning deferred one frame (layout settled) and the float layer moved under the dim.

**Also verified headless:** 202/202 throwaway assertions (all 100 attacker/defender pairs vs an independent copy of the table, floor rounding, multiplier before block, strength before multiplier, displayed intent == damage dealt, `hit_resolved` values, 10 malformed-data cases rejected, all 9 enemies / 16 encounters build).

**Not covered:** real mouse clicks; web export.
