#!/usr/bin/env python3
"""Title logo « Or royal » (player choice 2026-11-19, mockup design/art/title-mockups/logo1-or-royal.png).

Renders assets/art/title/logo.png (transparent): « POKÉMON » in spaced Cinzel Bold between two gold rules with
diamond tips, « SPIRE » in Cinzel Decorative Black with a metallic gold gradient, dark bronze outline and a warm
glow, « ROGUELIKE DE CARTES » underneath. Fonts: assets/fonts/cinzel/ (SIL OFL).
Run from the repo root: python3 tools/art/make_logo.py
"""
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

OUT = "assets/art/title/logo.png"
DECO = "assets/fonts/cinzel/CinzelDecorative-Black.ttf"
CINZEL = "assets/fonts/cinzel/Cinzel-Variable.ttf"
W, H = 1300, 560          # rendered at 2x the in-game size for crispness
SCALE = 2


def font(path, size, var=None):
    f = ImageFont.truetype(path, size * SCALE)
    if var:
        f.set_variation_by_name(var)
    return f


def text_width(text, fnt, spacing=0):
    d = ImageDraw.Draw(Image.new("L", (1, 1)))
    return sum(d.textlength(c, font=fnt) for c in text) + spacing * SCALE * (len(text) - 1)


def text_mask(text, fnt, y, spacing=0):
    m = Image.new("L", (W * SCALE, H * SCALE), 0)
    d = ImageDraw.Draw(m)
    widths = [d.textlength(c, font=fnt) for c in text]
    total = sum(widths) + spacing * SCALE * (len(text) - 1)
    x = (W * SCALE - total) / 2
    for c, w in zip(text, widths):
        d.text((x, y * SCALE), c, font=fnt, fill=255)
        x += w + spacing * SCALE
    return m


def grow(m, r):
    return m.filter(ImageFilter.MaxFilter(r * SCALE * 2 + 1))


def gold_layer(y0, y1):
    stops = [(0, (255, 246, 200)), (0.45, (240, 190, 70)), (0.55, (180, 120, 30)), (1, (255, 220, 120))]
    g = Image.new("RGBA", (W * SCALE, H * SCALE))
    d = ImageDraw.Draw(g)
    for y in range(H * SCALE):
        t = min(max((y / SCALE - y0) / (y1 - y0), 0), 1)
        for (ta, ca), (tb, cb) in zip(stops, stops[1:]):
            if ta <= t <= tb:
                u = (t - ta) / max(1e-6, tb - ta)
                c = tuple(int(ca[k] + (cb[k] - ca[k]) * u) for k in range(3))
                break
        d.line([(0, y), (W * SCALE, y)], fill=c + (255,))
    return g


def main():
    big = text_mask("SPIRE", font(DECO, 190), 170)
    small_font = font(CINZEL, 52, "Bold")
    small = text_mask("POKÉMON", small_font, 110, spacing=20)
    # The gold rules start a clear gap away from « P » and « N » (they used to overlap them).
    half_word = text_width("POKÉMON", small_font, 20) / 2 / SCALE
    gap, rule_len = 26, 170
    both = ImageChops.lighter(big, small)
    out = Image.new("RGBA", (W * SCALE, H * SCALE), (0, 0, 0, 0))
    glow = Image.new("RGBA", out.size, 0)
    glow.paste((255, 190, 80, 200), (0, 0), grow(both, 7))
    out.alpha_composite(glow.filter(ImageFilter.GaussianBlur(20 * SCALE)))
    out.paste((40, 20, 6, 255), (0, 0), grow(both, 4))
    out.paste(gold_layer(120, 400), (0, 0), both)
    d = ImageDraw.Draw(out)
    cy = 140 * SCALE
    for side in (-1, 1):
        x0 = (W / 2 + side * (half_word + gap)) * SCALE
        x1 = (W / 2 + side * (half_word + gap + rule_len)) * SCALE
        d.line([(x0, cy), (x1, cy)], fill=(240, 200, 110, 255), width=3 * SCALE)
        t = 13 * SCALE
        d.polygon([(x1 + side * t, cy), (x1, cy - 8 * SCALE), (x1 - side * t, cy), (x1, cy + 8 * SCALE)], fill=(240, 200, 110, 255))
    sub = font(CINZEL, 30, "Bold")
    text = "ROGUELIKE DE CARTES"
    tw = d.textlength(text, font=sub)
    d.text(((W * SCALE - tw) / 2 + 2 * SCALE, 412 * SCALE + 2 * SCALE), text, font=sub, fill=(30, 14, 4, 220))
    d.text(((W * SCALE - tw) / 2, 412 * SCALE), text, font=sub, fill=(240, 220, 175, 255))
    out = out.crop(out.getbbox())
    out.save(OUT, optimize=True)
    print("logo", out.size)


if __name__ == "__main__":
    main()
