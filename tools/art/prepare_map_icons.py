#!/usr/bin/env python3
"""Prepare the Town Map room icons (story 020b).

For every image in assets/art/map/icons/ (png / jpg / jpeg / webp):
  1. if the image has no real transparency, remove its plain (near-)white background by a flood fill started from
     the borders (with a colour tolerance), so white INSIDE the icon (not connected to the border) is kept;
  2. give the cut a soft anti-aliased alpha edge (the pixels next to the removed background get a partial alpha
     from their distance to white, and their colour is "un-mixed" from the white so no white halo remains);
  3. trim to the visible content, pad to a transparent square, resize to SIZE x SIZE;
  4. save as <room>.png next to the source; a converted non-PNG source (and its Godot .import file) is deleted.

Idempotent: an already-transparent PNG is only trimmed / padded / resized, and a file that is already a trimmed
SIZE x SIZE icon is left untouched.

Usage: python3 tools/art/prepare_map_icons.py [icons_dir] [--size 256] [--tolerance 26] [--soft 70]
Needs Pillow and numpy. Prompts: design/art/map-prompts.md.
"""
from __future__ import annotations

import argparse
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

EXTENSIONS = (".png", ".jpg", ".jpeg", ".webp")
DEFAULT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "art", "map", "icons")


def has_transparency(img: Image.Image) -> bool:
    """True if the image already carries a meaningful alpha channel (some clearly transparent pixels)."""
    if img.mode not in ("RGBA", "LA", "PA") and not (img.mode == "P" and "transparency" in img.info):
        return False
    alpha = np.asarray(img.convert("RGBA"))[:, :, 3]
    return bool((alpha < 250).mean() > 0.01)


def remove_white_background(img: Image.Image, tolerance: int, soft: int) -> Image.Image:
    """Flood-fills the near-white background from the borders and returns an RGBA image with a soft edge."""
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    h, w = rgb.shape[:2]
    # Distance to pure white: how far the darkest channel is from 255 (0 = white).
    dist = 255.0 - rgb.min(axis=2)
    # Built from bytes (not a shared numpy buffer) so floodfill edits a real, writable copy.
    near_white = Image.frombytes("L", (w, h), np.where(dist <= tolerance, 255, 0).astype(np.uint8).tobytes())
    seeds = [(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)]
    seeds += [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)]
    for s in seeds:  # filled seeds are skipped by floodfill itself (value already 128)
        if near_white.getpixel(s) == 255:
            ImageDraw.floodfill(near_white, s, 128, thresh=0)
    bg = np.asarray(near_white) == 128
    # Edge band: up to 2 px around the removed background gets a partial alpha.
    band = bg.copy()
    for _ in range(2):
        grown = band.copy()
        grown[1:, :] |= band[:-1, :]
        grown[:-1, :] |= band[1:, :]
        grown[:, 1:] |= band[:, :-1]
        grown[:, :-1] |= band[:, 1:]
        band = grown
    band &= ~bg
    alpha = np.ones((h, w), np.float32)
    alpha[bg] = 0.0
    edge_alpha = np.clip((dist - tolerance * 0.5) / float(max(1, soft)), 0.0, 1.0)
    alpha[band] = edge_alpha[band]
    # Un-mix the white from the semi-transparent edge pixels: c = (c - (1 - a) * 255) / a.
    out = rgb.copy()
    a3 = alpha[:, :, None]
    semi = (alpha > 0.0) & (alpha < 1.0)
    unmixed = (rgb - (1.0 - a3) * 255.0) / np.maximum(a3, 1e-3)
    out[semi] = np.clip(unmixed[semi], 0.0, 255.0)
    rgba = np.dstack([out, alpha * 255.0]).round().astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def trim_square_resize(img: Image.Image, size: int) -> Image.Image:
    """Trims to the visible content (alpha > 8), pads to a centred transparent square, resizes to size x size."""
    img = img.convert("RGBA")
    alpha = np.asarray(img)[:, :, 3]
    ys, xs = np.nonzero(alpha > 8)
    if xs.size == 0:
        return img.resize((size, size), Image.LANCZOS)
    img = img.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))
    side = max(img.size)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.paste(img, ((side - img.size[0]) // 2, (side - img.size[1]) // 2))
    if side != size:
        square = square.resize((size, size), Image.LANCZOS)
    return square


def is_prepared(img: Image.Image, size: int) -> bool:
    """True for an RGBA size x size icon whose content already touches the square on two opposite sides."""
    if img.mode != "RGBA" or img.size != (size, size):
        return False
    alpha = np.asarray(img)[:, :, 3]
    ys, xs = np.nonzero(alpha > 8)
    if xs.size == 0:
        return False
    return (xs.min() == 0 and xs.max() == size - 1) or (ys.min() == 0 and ys.max() == size - 1)


def process(path: str, size: int, tolerance: int, soft: int) -> str:
    """Prepares one icon; returns a one-line report."""
    stem, ext = os.path.splitext(path)
    target = stem + ".png"
    with Image.open(path) as src:
        src.load()
        img = src.copy()
    if ext.lower() == ".png" and is_prepared(img, size):
        return "%s: already prepared, unchanged" % os.path.basename(path)
    if has_transparency(img):
        cut = img.convert("RGBA")
        how = "already transparent"
    else:
        cut = remove_white_background(img, tolerance, soft)
        how = "white background removed"
    out = trim_square_resize(cut, size)
    out.save(target, "PNG", optimize=True)
    note = ""
    if os.path.abspath(target) != os.path.abspath(path):
        os.remove(path)
        if os.path.exists(path + ".import"):
            os.remove(path + ".import")
        note = ", source %s deleted" % os.path.basename(path)
    return "%s: %s -> %s (%dx%d)%s" % (os.path.basename(path), how, os.path.basename(target), size, size, note)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("icons_dir", nargs="?", default=DEFAULT_DIR)
    parser.add_argument("--size", type=int, default=256)
    parser.add_argument("--tolerance", type=int, default=26, help="max distance to white of the background (0-255)")
    parser.add_argument("--soft", type=int, default=70, help="width of the soft alpha ramp at the edge (0-255)")
    args = parser.parse_args()
    folder = os.path.abspath(args.icons_dir)
    if not os.path.isdir(folder):
        print("No icons folder: %s" % folder)
        return 1
    names = sorted(f for f in os.listdir(folder) if os.path.splitext(f)[1].lower() in EXTENSIONS)
    stems_with_png = {os.path.splitext(f)[0] for f in names if f.lower().endswith(".png")}
    count = 0
    for name in names:
        stem, ext = os.path.splitext(name)
        if ext.lower() != ".png" and stem in stems_with_png:
            print("%s: skipped (a %s.png already exists — delete one of the two)" % (name, stem))
            continue
        print(process(os.path.join(folder, name), args.size, args.tolerance, args.soft))
        count += 1
    print("%d icon(s) processed in %s" % (count, folder))
    return 0


if __name__ == "__main__":
    sys.exit(main())
