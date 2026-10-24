# tools/roster — large Pokémon roster generator (story 013b, part A)

Produces `assets/data/roster.json` and the sprites in `assets/sprites/pokemon/` from the PokéAPI CSV dumps.

## Regenerate
```
python3 tools/roster/add_cards.py          # idempotent: appends new_cards.json to assets/data/cards.json (text insert)
python3 tools/roster/generate_roster.py    # roster.json + missing sprites (add --no-sprites / --offline)
python3 tools/roster/validate_roster.py    # exit 0 = OK, prints counts per type/stage/generation
godot --headless --path . --import         # create .import files for new PNGs
```
Offline cache: `tools/roster/.cache/csv/*.csv` (git-ignored; override with env `ROSTER_CACHE`). Once the 5 CSVs
(pokemon, pokemon_species, pokemon_species_names, pokemon_types, pokemon_stats) are cached, generation is offline and
deterministic (no randomness; hashes are crc32). Sprites: `PokeAPI/sprites/.../pokemon/<dex>.png`, saved as
`<english slug>.png`, validated as PNG (signature/chunks/CRC), existing valid files are kept. Total new PNG ≈ 0.7 MB.

## Selection rules (constants at the top of `generate_roster.py`)
- National Dex <= 1025, default forms only (no Mega / regional / Gigantamax rows); generations 1-9.
- Excluded: legendary, mythical, babies (`pokemon_species`), lone species with BST > 540 (paradox/ultra-beast-like).
- All stages of each line kept (babies skipped, so `stage` counts only kept members). `STAGE3_CAP=None`: no cap
  (the size budget allows every line to stay complete); an int would drop whole stage-3-only lines.
- Species already in `pokemon.json` (enemies / player / evolutions ids or sprite names) are skipped: no id collision.
- Types = current (Gen 6+) PokéAPI types; a Pokémon counts for each of its types.

## Schema of `roster.json`
`{"_doc": str, "pokemon": {slug: entry}}`, sorted by dex. `entry` has the same fields as a `pokemon.json` `enemies`
entry (`name`, `types`, `max_hp`, `sprite`, `teaches`, `pattern`, `actions`) plus:

| field | meaning |
|---|---|
| `dex`, `generation` | National Dex number, 1-9 |
| `stage` | 1/2/3 rank in the line (kept members only) |
| `line_id` | slug of the stage-1 member of the line (may be an id from `pokemon.json`) |
| `evolves_to` | slug of the next form (lowest-dex branch) or `null`; may point to a `pokemon.json` id |
| `tier` | 1/2/3 power class used by the formulas: = stage, except lone species (BST bands 400/480) |
| `bst` | base stat total |
| `max_hp` | `lerp(HP_RANGE[tier], 0.5*norm(HP stat) + 0.5*norm(BST))`; ranges 28-50 / 50-80 / 80-140 |
| `pattern`, `actions` | 2-4 actions from stats: glass cannon = sequence of attacks (+buff), tank = weighted attack/block, fast = attack/buff sequence, else balanced; attack 5-9 / 8-14 / 12-22 by tier, block 4-7 / 6-11 / 9-16, buff +1/+1/+2 |
| `teaches` | 1-2 existing attack card ids; first = primary type, second = secondary type (else same type); rarity by tier |
| `sprite` | `res://assets/sprites/pokemon/<slug>.png` |
| `roles.wild_ok` | may appear as wild / elite / gym Pokémon (all true) |
| `roles.carrier_ok` | may carry a reward card (all true) |
| `roles.candidate_start` | stage 1 and BST <= 330 (starter proposals; integration decides the draw) |

## Cards
`new_cards.json` lists the cards added so every one of the 18 types has >= 3 non-starter attack cards (a common cost 1,
an uncommon, usually a rare). Their `pokemon` carrier is an existing `pokemon.json` Pokémon (cosmetic); there is no
Fairy Pokémon in `pokemon.json`, so fairy cards were re-pointed to `clefairy` (a roster fairy) during integration.
