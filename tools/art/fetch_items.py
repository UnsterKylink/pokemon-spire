#!/usr/bin/env python3
"""Story 020b: download the official illustration (PokeAPI dream-world, falls back
to the pixel sprite) of every held item, potion and ball into
assets/sprites/items/<game id>.png, downscaled to 96 px max.

Run once from the repo root: python3 tools/art/fetch_items.py
ITEM_ART maps the game's ids (items.json / potions.json / balls.json) to PokeAPI item names.
"""
import io, os, subprocess, sys
from PIL import Image

BASE = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/"
OUT = "assets/sprites/items"
SIZE = 96
ITEM_ART = {
    # held items (items.json)
    "restes": "leftovers", "bandeau": "muscle-band", "baie_oran": "oran-berry", "orbe_vie": "life-orb",
    "cloche_eclat": "shell-bell", "peau_metal": "metal-coat", "piece_rune": "amulet-coin",
    "lunettes_choix": "choice-specs", "ceinture_force": "focus-band", "gemme_energie": "normal-gem",
    "poudre_soin": "heal-powder", "baie_cheri": "cheri-berry", "baie_mitrons": "pecha-berry",
    "baie_ceriz": "chesto-berry", "baie_prine": "rawst-berry",
    # story 029 held items
    "charbon": "charcoal",
    "eau_mystique": "mystic-water",
    "graine_miracle": "miracle-seed",
    "aimant": "magnet",
    "ceinture_pro": "black-belt",
    "bec_pointu": "sharp-beak",
    "pic_venin": "poison-barb",
    "cuiller_tordue": "twisted-spoon",
    "plaque_flamme": "flame-plate",
    "plaque_hydro": "splash-plate",
    "plaque_prairie": "meadow-plate",
    "orbe_flamme": "flame-orb",
    "orbe_toxik": "toxic-orb",
    "boule_fumee": "smoke-ball",
    "pile_rapide": "cell-battery",
    "griffe_rasoir": "razor-claw",
    "poudre_eclat": "bright-powder",
    "lentille_zoom": "zoom-lens",
    "eclat_magique": "shiny-stone",
    "scope_lens": "scope-lens",
    "herbe_mental": "mental-herb",
    "cendre_sacree": "sacred-ash",
    "roche_lisse": "smooth-rock",
    "casque_brut": "rocky-helmet",
    "bonbon_rare": "rare-candy",
    "herbe_blanche": "white-herb",
    "miel": "honey",
    "sacoche_balls": "dive-ball",
    "sacoche_potions": "hyper-potion",
    "pepite": "nugget",
    "baie_sitrus": "sitrus-berry",
    # potions (potions.json)
    "potion": "potion", "super_potion": "super-potion", "attaque_plus": "x-attack", "defense_plus": "x-defense",
    "energie_plus": "ether", "pioche": "x-accuracy", "total_soin": "full-heal", "antidote": "antidote",
    "anti_brule": "burn-heal", "antigel": "ice-heal", "reveil": "awakening", "anti_para": "paralyze-heal",
    # balls (balls.json)
    "poke_ball": "poke-ball", "super_ball": "great-ball", "hyper_ball": "ultra-ball",
}


def fetch(url):
    r = subprocess.run(["curl", "-sS", "--fail", "--retry", "3", url], capture_output=True)
    return r.stdout if r.returncode == 0 else None


def main():
    os.makedirs(OUT, exist_ok=True)
    missing = []
    for gid, name in ITEM_ART.items():
        data = fetch(BASE + "dream-world/%s.png" % name) or fetch(BASE + "%s.png" % name)
        if not data:
            missing.append(gid)
            continue
        img = Image.open(io.BytesIO(data)).convert("RGBA")
        img = img.crop(img.getbbox() or (0, 0) + img.size)
        img.thumbnail((SIZE, SIZE), Image.LANCZOS)
        img.save(os.path.join(OUT, gid + ".png"), optimize=True)
    print("items: %d saved, missing %s" % (len(ITEM_ART) - len(missing), missing))


if __name__ == "__main__":
    main()
