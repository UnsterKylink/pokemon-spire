#!/usr/bin/env python3
"""Story 022: download the official cry of every Pokemon that has a sprite in
assets/sprites/pokemon/ and store it as assets/audio/cries/<slug>.ogg.

Run once from the repo root: python3 tools/audio/fetch_cries.py
Source: PokeAPI cries repo (latest cries, OGG Vorbis); slug -> dex from PokeAPI pokemon.csv,
same FORMS fallback as tools/art/fetch_artwork.py. Files already present are skipped.
Cries are Pokemon IP (Nintendo / Game Freak): fine for this private game only.
Prints the total size; if it ever exceeds MAX_MB the files are re-encoded with ffmpeg (mono, lower quality).
"""
import csv, io, os, shutil, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

CSV_URL = "https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/pokemon.csv"
CRY_URL = "https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/latest/%d.ogg"
SPRITES = "assets/sprites/pokemon"
OUT = "assets/audio/cries"
MAX_MB = 40.0
# Slugs whose PokeAPI identifier is a default form.
FORMS = {"aegislash": "aegislash-shield", "lycanroc": "lycanroc-midday", "oinkologne": "oinkologne-male"}


def fetch(url):
    return subprocess.run(["curl", "-sS", "--fail", "--retry", "3", url], capture_output=True, check=True).stdout


def folder_mb():
    return sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT) if f.endswith(".ogg")) / 1048576.0


def reencode_all():
    """Lower-quality mono re-encode, only used when the folder is over MAX_MB."""
    if shutil.which("ffmpeg") is None:
        print("cries over %.0f MB and no ffmpeg: keep as is" % MAX_MB)
        return
    for f in sorted(os.listdir(OUT)):
        if not f.endswith(".ogg"):
            continue
        src = os.path.join(OUT, f)
        tmp = src + ".tmp.ogg"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", src, "-ac", "1", "-ar", "22050", "-c:a", "libvorbis", "-q:a", "1", tmp], check=True)
        os.replace(tmp, src)


def main():
    os.makedirs(OUT, exist_ok=True)
    ids = {row["identifier"]: int(row["id"]) for row in csv.DictReader(io.StringIO(fetch(CSV_URL).decode()))}
    for slug, form in FORMS.items():
        if form in ids:
            ids[slug] = ids[form]
    slugs = sorted(f[:-4] for f in os.listdir(SPRITES) if f.endswith(".png"))
    missing = [s for s in slugs if s not in ids]
    jobs = [s for s in slugs if s in ids and not os.path.exists(os.path.join(OUT, s + ".ogg"))]

    def work(slug):
        try:
            data = fetch(CRY_URL % ids[slug])
            dest = os.path.join(OUT, slug + ".ogg")
            if data[:4] == b"OggS":
                with open(dest, "wb") as fh:
                    fh.write(data)
            else:
                # A few "latest" files are really MP3 (e.g. pikachu): convert them to OGG Vorbis with ffmpeg.
                subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", "pipe:0", "-c:a", "libvorbis", "-q:a", "3", dest],
                        input=data, check=True)
            return slug, True
        except Exception as exc:  # noqa: BLE001 — report and continue
            print("fail", slug, exc, file=sys.stderr)
            return slug, False

    with ThreadPoolExecutor(16) as pool:
        failed = [s for s, ok in pool.map(work, jobs) if not ok]
    size = folder_mb()
    if size > MAX_MB:
        reencode_all()
        size = folder_mb()
    count = len([f for f in os.listdir(OUT) if f.endswith(".ogg")])
    print("cries: %d downloaded, %d failed %s, %d without dex %s; folder %d files, %.1f MB" % (
        len(jobs) - len(failed), len(failed), failed, len(missing), missing, count, size))


if __name__ == "__main__":
    main()
