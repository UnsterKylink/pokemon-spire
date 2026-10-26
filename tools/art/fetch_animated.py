#!/usr/bin/env python3
"""Story 020b: download the animated Showdown sprites (front + back) of every
Pokemon that has a sprite in assets/sprites/pokemon/ and store each animation as
a sprite sheet: assets/sprites/animated/<front|back>/<slug>.png.
Index: assets/data/animated_sprites.json -> {slug: {front|back: {w, h, frames, cols, ms}}}.

Run once from the repo root: python3 tools/art/fetch_animated.py
Source: PokeAPI sprites repo (other/showdown). Downloaded at build time only.
"""
import csv, io, json, math, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor
from PIL import Image, ImageSequence

CSV_URL = "https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/pokemon.csv"
GIF_URL = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/%s%d.gif"
SPRITES = "assets/sprites/pokemon"
OUT = "assets/sprites/animated"
INDEX = "assets/data/animated_sprites.json"
FORMS = {"aegislash": "aegislash-shield", "lycanroc": "lycanroc-midday", "oinkologne": "oinkologne-male"}


def fetch(url):
    return subprocess.run(["curl", "-sS", "--fail", "--retry", "3", url], capture_output=True, check=True).stdout


def sheet(data, dest):
    gif = Image.open(io.BytesIO(data))
    frames = [f.convert("RGBA") for f in ImageSequence.Iterator(gif)]
    ms = int(gif.info.get("duration", 40) or 40)
    # Crop every frame to the union of their visible pixels.
    box = None
    for f in frames:
        b = f.getbbox()
        if b:
            box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
    if box is None:
        box = (0, 0) + gif.size
    frames = [f.crop(box) for f in frames]
    w, h = frames[0].size
    cols = math.ceil(math.sqrt(len(frames)))
    rows = math.ceil(len(frames) / cols)
    out = Image.new("RGBA", (w * cols, h * rows))
    for k, f in enumerate(frames):
        out.paste(f, ((k % cols) * w, (k // cols) * h))
    out.quantize(colors=256, method=Image.FASTOCTREE).save(dest, optimize=True)
    return {"w": w, "h": h, "frames": len(frames), "cols": cols, "ms": ms}


def main():
    ids = {r["identifier"]: int(r["id"]) for r in csv.DictReader(io.StringIO(fetch(CSV_URL).decode()))}
    for slug, form in FORMS.items():
        if form in ids:
            ids[slug] = ids[form]
    slugs = sorted(f[:-4] for f in os.listdir(SPRITES) if f.endswith(".png") and f[:-4] in ids)
    index = json.load(open(INDEX)) if os.path.exists(INDEX) else {}
    index.pop("_doc", None)
    for side in ("front", "back"):
        os.makedirs(os.path.join(OUT, side), exist_ok=True)

    def work(job):
        slug, side = job
        dest = os.path.join(OUT, side, slug + ".png")
        if os.path.exists(dest) and side in index.get(slug, {}):
            return slug, side, index[slug][side]
        try:
            return slug, side, sheet(fetch(GIF_URL % ("back/" if side == "back" else "", ids[slug])), dest)
        except Exception as exc:  # noqa: BLE001 — missing animation: game falls back to the still sprite
            print("missing", side, slug, exc, file=sys.stderr)
            return slug, side, None

    jobs = [(s, side) for s in slugs for side in ("front", "back")]
    with ThreadPoolExecutor(16) as pool:
        for slug, side, meta in pool.map(work, jobs):
            if meta:
                index.setdefault(slug, {})[side] = meta
    doc = ("Story 020b : sprites animes Showdown (tools/art/fetch_animated.py). slug -> {front|back: {w, h (taille d'une "
           "image), frames, cols (images par ligne de la planche), ms (duree d'une image)}}. Planche : "
           "res://assets/sprites/animated/<front|back>/<slug>.png. Absent = sprite fixe.")
    out = {"_doc": doc}
    out.update(dict(sorted(index.items())))
    with open(INDEX, "w") as fh:
        json.dump(out, fh, ensure_ascii=False, separators=(",", ":"))
    print("animated: %d slugs, %d front, %d back" % (len(index), sum("front" in v for v in index.values()), sum("back" in v for v in index.values())))


if __name__ == "__main__":
    main()
