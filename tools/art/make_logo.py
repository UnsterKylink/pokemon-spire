#!/usr/bin/env python3
"""Story 023 polish: renders the title logo « Pokémon Spire » to assets/art/title/logo.png.

Pokémon-logo look: arched letters, yellow vertical gradient with a light top band, thin white inner rim,
thick blue outline, dark navy outer outline, 3D extrusion and soft drop shadow; subtitle on a ribbon.
Run from the repo root: python3 tools/art/make_logo.py
"""
import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops

FONT = "assets/fonts/lilita_one/LilitaOne-Regular.ttf"
OUT = "assets/art/title/logo.png"
SUB = "Roguelike de cartes"
W, H = 1400, 560
YELLOW_TOP, YELLOW_BOT = (255, 236, 92), (246, 176, 0)
BLUE, NAVY, EXTRUDE = (42, 98, 184), (18, 36, 94), (14, 28, 72)


def word_mask(text, size, arch, y0):
    """Alpha mask of `text` drawn letter by letter on an arch (centre letters higher)."""
    font = ImageFont.truetype(FONT, size)
    widths = [font.getlength(c) for c in text]
    total = sum(widths)
    x = (W - total) / 2
    mask = Image.new("L", (W, H), 0)
    n = len(text)
    for i, c in enumerate(text):
        t = (i + 0.5) / n * 2 - 1           # -1..1 across the word
        dy = -arch * (1 - t * t)            # parabola: centre rises
        rot = -t * arch * 0.06              # letters lean outward a little
        g = Image.new("L", (int(widths[i] + size), int(size * 1.6)), 0)
        ImageDraw.Draw(g).text((size * 0.5, size * 0.15), c, font=font, fill=255)
        g = g.rotate(rot, resample=Image.BICUBIC, expand=False)
        mask.paste(255, (int(x - size * 0.5), int(y0 + dy - size * 0.15)), g)
        x += widths[i]
    return mask


def grow(mask, r):
    return mask.filter(ImageFilter.MaxFilter(r * 2 + 1)) if r > 0 else mask


def gradient(top, bot, box):
    x0, y0, x1, y1 = box
    g = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(g)
    for y in range(H):
        t = min(max((y - y0) / max(1, y1 - y0), 0), 1)
        d.line([(0, y), (W, y)], fill=tuple(int(top[k] + (bot[k] - top[k]) * t) for k in range(3)) + (255,))
    return g


def main():
    top = word_mask("Pokémon", 150, 26, 40)
    big = word_mask("Spire", 230, 34, 175)
    letters = ImageChops.lighter(top, big)
    bbox = letters.getbbox()
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # soft drop shadow
    sh = grow(letters, 22).filter(ImageFilter.GaussianBlur(14))
    out.paste((0, 0, 30, 150), (10, 22), sh)
    # 3D extrusion (stacked offsets of the outer outline)
    outer = grow(letters, 20)
    for k in range(14, 0, -1):
        out.paste(EXTRUDE + (255,), (int(k * 0.35), k), outer)
    out.paste(NAVY + (255,), (0, 0), outer)
    out.paste(BLUE + (255,), (0, 0), grow(letters, 14))
    # light rim on the blue outline (top-left light)
    rim = ImageChops.subtract(grow(letters, 14), grow(letters, 14).transform((W, H), Image.AFFINE, (1, 0, 3, 0, 1, 4)))
    out.paste((120, 170, 240, 255), (0, 0), rim)
    out.paste((255, 255, 255, 255), (0, 0), grow(letters, 4))
    fill = gradient(YELLOW_TOP, YELLOW_BOT, bbox)
    out.paste(fill, (0, 0), letters)
    # light highlight on the upper part of each letter (soft, inside the letters only)
    hl = ImageChops.multiply(letters, letters.transform((W, H), Image.AFFINE, (1, 0, 0, 0, 1, 10)).point(lambda v: 255 - v))
    out.paste((255, 250, 200, 255), (0, 0), hl.filter(ImageFilter.GaussianBlur(3)).point(lambda v: v // 2))
    # ribbon with the subtitle
    font = ImageFont.truetype(FONT, 44)
    tw = font.getlength(SUB)
    cx, cy = W / 2, bbox[3] + 34
    rw, rh = tw + 90, 66
    d = ImageDraw.Draw(out)
    for dx in (-1, 1):  # ribbon tails
        x_in, x_out = cx + dx * (rw / 2 - 10), cx + dx * (rw / 2 + 44)
        d.polygon([(x_in, cy - rh / 2 + 12), (x_out, cy - rh / 2 + 12), (x_out - dx * 20, cy + 6 + 12), (x_out, cy + rh / 2 + 12), (x_in, cy + rh / 2 + 12)], fill=(150, 20, 30, 255), outline=NAVY + (255,))
    d.rounded_rectangle([cx - rw / 2, cy - rh / 2, cx + rw / 2, cy + rh / 2], 14, fill=(214, 44, 48, 255), outline=NAVY + (255,), width=5)
    d.rounded_rectangle([cx - rw / 2 + 8, cy - rh / 2 + 6, cx + rw / 2 - 8, cy - 4], 10, fill=(236, 92, 88, 255))
    d.text((cx - tw / 2 + 2, cy - 27 + 3), SUB, font=font, fill=NAVY + (255,))
    d.text((cx - tw / 2, cy - 27), SUB, font=font, fill=(255, 255, 255, 255))
    out = out.crop(out.getbbox())
    out.save(OUT, optimize=True)
    print("logo", out.size)


if __name__ == "__main__":
    main()
