#!/usr/bin/env python3
"""Story 020: download the official artwork of every Pokemon that has a sprite
in assets/sprites/pokemon/ and store a downscaled 256-colour copy in assets/sprites/artwork/.

Run once from the repo root: python3 tools/art/fetch_artwork.py [size]
Source: PokeAPI sprites repo (official-artwork), slug -> dex from PokeAPI pokemon.csv.
Files already present are skipped. Downloaded at build time only, never in game.
"""
import csv, io, os, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
from PIL import Image

SIZE = int(sys.argv[1]) if len(sys.argv) > 1 else 256
CSV_URL = "https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/pokemon.csv"
ART_URL = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/%d.png"
SPRITES = "assets/sprites/pokemon"
OUT = "assets/sprites/artwork"
# Slugs whose PokeAPI identifier is a default form.
FORMS = {"aegislash": "aegislash-shield", "lycanroc": "lycanroc-midday", "oinkologne": "oinkologne-male"}


def fetch(url):
    return subprocess.run(["curl", "-sS", "--fail", "--retry", "3", url], capture_output=True, check=True).stdout


def main():
    os.makedirs(OUT, exist_ok=True)
    ids = {row["identifier"]: int(row["id"]) for row in csv.DictReader(io.StringIO(fetch(CSV_URL).decode()))}
    for slug, form in FORMS.items():
        if form in ids:
            ids[slug] = ids[form]
    slugs = sorted(f[:-4] for f in os.listdir(SPRITES) if f.endswith(".png"))
    missing = [s for s in slugs if s not in ids]
    jobs = [s for s in slugs if s in ids and not os.path.exists(os.path.join(OUT, s + ".png"))]

    def work(slug):
        try:
            img = Image.open(io.BytesIO(fetch(ART_URL % ids[slug]))).convert("RGBA")
            bbox = img.getbbox()
            if bbox:
                img = img.crop(bbox)
            img.thumbnail((SIZE, SIZE), Image.LANCZOS)
            # 256-colour palette keeps the folder around 10 MB.
            img = img.quantize(colors=256, method=Image.FASTOCTREE, dither=Image.FLOYDSTEINBERG)
            img.save(os.path.join(OUT, slug + ".png"), optimize=True)
            return slug, True
        except Exception as exc:  # noqa: BLE001 — report and continue
            print("fail", slug, exc, file=sys.stderr)
            return slug, False

    with ThreadPoolExecutor(16) as pool:
        failed = [s for s, ok in pool.map(work, jobs) if not ok]
    print("artwork: %d downloaded, %d failed %s, %d without dex %s" % (len(jobs) - len(failed), len(failed), failed, len(missing), missing))


if __name__ == "__main__":
    main()
