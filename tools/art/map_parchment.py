"""Story 020b: procedural parchment textures (fibres, stains, burnt/torn edges). Deterministic (fixed seeds)."""
import sys, math, random
import numpy as np
from PIL import Image, ImageFilter, ImageDraw

def noise(w, h, scale, rng):
    sw, sh = max(2, int(w / scale)), max(2, int(h / scale))
    a = rng.random((sh, sw)).astype(np.float32)
    im = Image.fromarray((a * 255).astype(np.uint8), "L").resize((w, h), Image.BICUBIC)
    return np.asarray(im, np.float32) / 255.0

def fbm(w, h, rng, scales=(256, 96, 40, 14, 5), weights=(0.4, 0.25, 0.17, 0.11, 0.07)):
    out = np.zeros((h, w), np.float32)
    for s, wt in zip(scales, weights):
        out += noise(w, h, s, rng) * wt
    return out

def make(w, h, seed, edge, out, burn=1.0):
    rng = np.random.default_rng(seed)
    pr = random.Random(seed)
    base = np.array([233, 214, 172], np.float32)
    n = fbm(w, h, rng)
    img = np.ones((h, w, 3), np.float32) * base
    img *= (0.9 + 0.2 * n)[..., None]
    # mottled warm/cool variation
    m = noise(w, h, 180, rng)
    img[..., 0] *= 1.0 + (m - 0.5) * 0.05
    img[..., 2] *= 1.0 - (m - 0.5) * 0.10
    pil = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    # fibres
    fib = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(fib)
    for _ in range(int(w * h / 900)):
        x, y = pr.uniform(0, w), pr.uniform(0, h)
        ang = pr.gauss(0.15, 0.6)
        ln = pr.uniform(6, 34)
        pts = []
        for k in range(6):
            t = k / 5.0
            pts.append((x + math.cos(ang) * ln * t + math.sin(t * 3 + x) * 1.5, y + math.sin(ang) * ln * t))
        dark = pr.random() < 0.55
        col = (110, 80, 45, pr.randint(14, 34)) if dark else (255, 248, 225, pr.randint(20, 45))
        d.line(pts, fill=col, width=1)
    pil = Image.alpha_composite(pil, fib.filter(ImageFilter.GaussianBlur(0.4)))
    # stains (coffee rings + soft blots)
    st = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(st)
    for _ in range(max(4, int(w * h / 90000))):
        cx, cy = pr.uniform(0, w), pr.uniform(0, h)
        r = pr.uniform(18, 90)
        a = pr.randint(10, 26)
        d.ellipse([cx - r, cy - r * pr.uniform(0.7, 1.0), cx + r, cy + r * pr.uniform(0.7, 1.0)], fill=(140, 95, 45, a))
        if pr.random() < 0.5:
            d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(120, 78, 35, a + 18), width=2)
    pil = Image.alpha_composite(pil, st.filter(ImageFilter.GaussianBlur(5)))
    # speckles
    sp = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(sp)
    for _ in range(int(w * h / 1800)):
        x, y = pr.uniform(0, w), pr.uniform(0, h)
        r = pr.uniform(0.4, 1.4)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(80, 55, 30, pr.randint(30, 90)))
    pil = Image.alpha_composite(pil, sp)
    arr = np.asarray(pil, np.float32).copy()
    # torn / burnt edges: distance to the border perturbed by noise
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    dist = np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy))
    rough = (fbm(w, h, np.random.default_rng(seed + 7), (120, 40, 12, 4), (0.45, 0.3, 0.17, 0.08)) - 0.5) * 2.0
    dd = dist - edge * (0.55 + 0.45 * rough) - edge * 0.25
    alpha = np.clip(dd / 1.6 + 0.5, 0, 1)
    burn_w = edge * 0.9 * burn
    b = np.clip(1.0 - dd / max(burn_w, 1.0), 0, 1) ** 1.6
    char = np.array([58, 30, 12], np.float32)
    arr[..., :3] = arr[..., :3] * (1 - b[..., None] * 0.92) + char * b[..., None] * 0.92
    # soft inner vignette
    v = np.clip(dist / (min(w, h) * 0.45), 0, 1)
    arr[..., :3] *= (0.86 + 0.14 * v ** 0.6)[..., None]
    arr[..., 3] = alpha * 255
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA").save(out, optimize=True)

root = sys.argv[1]
make(1280, 640, 2020, 34, root + "/parchment.png")
make(1280, 112, 2021, 14, root + "/parchment_strip.png", burn=0.8)
make(256, 256, 2022, 18, root + "/parchment_tag.png", burn=0.8)
print("ok")
