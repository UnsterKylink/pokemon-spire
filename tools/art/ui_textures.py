"""Story 020b: procedural UI / card textures (tileable). Run: python3 tools/art/ui_textures.py assets/art/ui"""
import sys, os
import numpy as np
from PIL import Image
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
rng = np.random.default_rng(2020)

def tile_noise(n, scales, weights):
    """Tileable fractal noise via FFT-filtered white noise, normalised to 0..1."""
    acc = np.zeros((n, n))
    for s, w in zip(scales, weights):
        white = rng.standard_normal((n, n))
        f = np.fft.fftfreq(n)
        fx, fy = np.meshgrid(f, f)
        r = np.sqrt(fx**2 + fy**2)
        filt = np.exp(-(r * s) ** 2)
        layer = np.real(np.fft.ifft2(np.fft.fft2(white) * filt))
        layer = (layer - layer.mean()) / (layer.std() + 1e-9)
        acc += layer * w
    acc = (acc - acc.min()) / (acc.max() - acc.min())
    return acc

def streaks(n, length, vertical=False):
    """Brushed-metal streaks: white noise blurred along one axis (wraps)."""
    white = rng.standard_normal((n, n))
    f = np.fft.fftfreq(n)
    fx, fy = np.meshgrid(f, f)
    a, b = (fy, fx) if vertical else (fx, fy)
    filt = np.exp(-(a * length) ** 2 - (b * 1.2) ** 2)
    layer = np.real(np.fft.ifft2(np.fft.fft2(white) * filt))
    return (layer - layer.min()) / (layer.max() - layer.min())

def save(name, arr):
    arr = np.clip(arr, 0, 1)
    img = Image.fromarray((arr * 255).astype(np.uint8))
    img.save(os.path.join(out, name)); print(name, img.size, img.mode)

def lerp3(c0, c1, t):
    c0 = np.array(c0) / 255.0; c1 = np.array(c1) / 255.0
    return c0[None, None, :] * (1 - t[..., None]) + c1[None, None, :] * t[..., None]

N = 512
# Grain / panel noise (grey, 256 tile): fine + medium, centred on 0.5.
g = tile_noise(256, [180, 40, 8], [0.6, 0.3, 0.5])
save("ui_noise.png", g)
# Card body grain: near-white so it multiplies the type colour gently.
cg = tile_noise(N, [200, 30, 6], [0.5, 0.35, 0.4])
save("card_grain.png", np.stack([0.80 + 0.20 * cg] * 3, -1))
# Parchment: warm cream, fibres + soft blotches.
blot = tile_noise(N, [30, 10], [0.6, 0.6]); fib = streaks(N, 60)
t = 0.55 * blot + 0.25 * fib + 0.2 * tile_noise(N, [220], [1])
p = lerp3((222, 205, 168), (255, 250, 236), t)
save("ui_parchment.png", p)
# Slate / stone (common, starter): blue-grey mottled with darker veins.
st = tile_noise(N, [120, 40, 12, 4], [0.25, 0.4, 0.6, 0.5])
vein = np.abs(tile_noise(N, [14, 5], [0.7, 0.4]) - 0.5) < 0.018
s = lerp3((70, 76, 90), (160, 166, 178), st)
s[vein] *= 0.72
save("card_stone.png", s)
# Brushed silver (uncommon).
br = streaks(N, 140); mot = tile_noise(N, [10], [1])
t = 0.6 * br + 0.4 * mot
save("card_silver.png", lerp3((128, 136, 150), (236, 240, 246), t))
# Brushed gold (rare / legendary).
br = streaks(N, 140); mot = tile_noise(N, [12, 40], [0.8, 0.3])
t = 0.55 * br + 0.45 * mot
gold = lerp3((150, 98, 24), (255, 226, 120), t)
save("card_gold.png", gold)
