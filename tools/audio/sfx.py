#!/usr/bin/env python3
"""Story 022: sfxr-style generator of the 8-bit sound effects of Pokemon Spire.

Run from the repo root:  python3 tools/audio/sfx.py [ids...]   -> assets/audio/sfx/<id>.wav (22.05 kHz mono 16-bit)

Every sound is built from a few primitives (pulse / triangle / sine tones with pitch slides, LFSR noise
with a rate slide, exponential or linear envelopes, note sequences) so the whole set shares one palette:
square-wave Game Boy timbre, short attack, quick decay. All sounds are original and generated here.
Peaks are normalised to -3 dBFS (0.7) and every file starts and ends at zero (no clicks).
"""
import math, os, sys, wave
import numpy as np

SR = 22050
OUT = "assets/audio/sfx"
RNG = np.random.default_rng(22)  # fixed seed: the generator is deterministic


def t_axis(dur):
    return np.arange(int(dur * SR)) / SR


def lfsr(bits):
    state, out = (1 << bits) - 1, []
    for _ in range((1 << bits) - 1):
        b = (state ^ (state >> 1)) & 1
        state = (state >> 1) | (b << (bits - 1))
        out.append(1.0 if state & 1 else -1.0)
    return np.array(out)


L15, L7 = lfsr(15), lfsr(7)


def env_exp(dur, k, attack=0.003):
    t = t_axis(dur)
    return np.minimum(t / attack, 1.0) * np.exp(-t * k)


def env_lin(dur, attack=0.003, release_frac=0.3):
    t = t_axis(dur)
    n = len(t)
    e = np.minimum(t / attack, 1.0)
    r = int(n * release_frac)
    if r > 0:
        e[-r:] *= np.linspace(1, 0, r)
    return e


def tone(f0, f1, dur, wave="square", duty=0.5, curve="exp", vib=(0, 0)):
    """Oscillator with a pitch slide from f0 to f1 Hz (exponential or linear) and optional vibrato (Hz, semitones)."""
    t = t_axis(dur)
    x = t / max(dur, 1e-6)
    f = f0 * (f1 / f0) ** x if curve == "exp" else f0 + (f1 - f0) * x
    if vib[0]:
        f = f * 2 ** (vib[1] * np.sin(2 * np.pi * vib[0] * t) / 12)
    ph = np.cumsum(f) / SR
    fr = ph - np.floor(ph)
    if wave == "square":
        return np.where(fr < duty, 1.0, -1.0) - (2 * duty - 1)
    if wave == "tri":
        return np.round((2 * np.abs(2 * fr - 1) - 1) * 7.5) / 7.5
    if wave == "saw":
        return 2 * fr - 1
    return np.sin(2 * np.pi * ph)


def noise(r0, r1, dur, short=False):
    """LFSR noise clocked from r0 to r1 Hz (low rate = rumble, high rate = hiss)."""
    n = int(dur * SR)
    rate = np.geomspace(r0, r1, n) if n else np.zeros(0)
    idx = (np.cumsum(rate) / SR).astype(int)
    seq = L7 if short else L15
    return seq[idx % len(seq)]


def seq(notes, wave="square", duty=0.5, k=12.0, gap=0.0):
    """Concatenated notes [(freq_hz, dur_s), ...] with an exponential decay each (an arpeggio / jingle)."""
    parts = []
    for f, d in notes:
        parts.append(tone(f, f, d, wave, duty) * env_exp(d, k))
        if gap:
            parts.append(np.zeros(int(gap * SR)))
    return np.concatenate(parts)


def mix(*layers):
    n = max(len(l[1]) + int(l[0] * SR) for l in layers)
    out = np.zeros(n)
    for start, sig, *gain in layers:
        s = int(start * SR)
        out[s:s + len(sig)] += sig * (gain[0] if gain else 1.0)
    return out


def hz(note):
    """'A4' style -> Hz."""
    names = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    pc = names[note[0]] + (1 if "#" in note else -1 if note[1] == "b" else 0)
    octave = int(note[-1])
    return 440.0 * 2 ** ((12 * (octave + 1) + pc - 69) / 12)


def lowpass(x, cut):
    """One-pole low-pass (softens hits / thuds)."""
    a = math.exp(-2 * math.pi * cut / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def N(*a):
    return [hz(x) for x in a]


SFX = {
    # Cards
    "card_play": lambda: mix((0, noise(2000, 16000, 0.09) * env_exp(0.09, 30), 0.5),
                             (0.02, tone(500, 1100, 0.07, duty=0.25) * env_exp(0.07, 35), 0.6)),
    "card_draw": lambda: mix((0, noise(6000, 14000, 0.05) * env_exp(0.05, 70), 0.35),
                             (0.0, tone(900, 1500, 0.045, duty=0.125) * env_exp(0.045, 60), 0.5)),
    # Hits (by effectiveness)
    "hit_normal": lambda: mix((0, noise(9000, 1500, 0.16) * env_exp(0.16, 22), 0.9),
                              (0, tone(220, 70, 0.12, duty=0.5) * env_exp(0.12, 25), 0.6)),
    "hit_super": lambda: mix((0, noise(14000, 800, 0.35) * env_exp(0.35, 10), 1.0),
                             (0, tone(330, 55, 0.25, duty=0.25) * env_exp(0.25, 12), 0.7),
                             (0.06, noise(3000, 400, 0.2) * env_exp(0.2, 14), 0.6),
                             (0.0, tone(1200, 400, 0.08, duty=0.125) * env_exp(0.08, 30), 0.4)),
    "hit_weak": lambda: lowpass(mix((0, noise(3000, 700, 0.12) * env_exp(0.12, 30), 0.7),
                                    (0, tone(140, 90, 0.1, "tri") * env_exp(0.1, 30), 0.8)), 1800),
    "hit_immune": lambda: mix((0, tone(180, 170, 0.08, "tri") * env_exp(0.08, 25), 0.9),
                              (0.09, tone(400, 200, 0.18, duty=0.5) * env_exp(0.18, 12), 0.45)),
    "block": lambda: mix((0, tone(1400, 1350, 0.25, duty=0.125) * env_exp(0.25, 14), 0.5),
                         (0, tone(2100, 2050, 0.2, duty=0.5) * env_exp(0.2, 20), 0.3),
                         (0, noise(12000, 9000, 0.04) * env_exp(0.04, 80), 0.5)),
    "heal": lambda: seq([(f, 0.07) for f in N("C5", "E5", "G5", "C6", "E6", "G6")], duty=0.25, k=14) * 0.7,
    "status_apply": lambda: tone(700, 250, 0.35, duty=0.25, vib=(14, 1.5)) * env_exp(0.35, 7) * 0.7,
    "ko": lambda: mix((0, tone(800, 60, 0.7, duty=0.5) * env_lin(0.7, release_frac=0.4), 0.6),
                      (0.05, noise(4000, 300, 0.6) * env_exp(0.6, 5), 0.4)),
    "switch": lambda: mix((0, noise(1500, 12000, 0.12) * env_exp(0.12, 18), 0.4),
                          (0, tone(400, 900, 0.07, duty=0.25) * env_exp(0.07, 25), 0.5),
                          (0.09, tone(600, 1300, 0.07, duty=0.25) * env_exp(0.07, 25), 0.5)),
    "energy": lambda: mix((0, tone(300, 1800, 0.18, duty=0.125, vib=(30, 0.6)) * env_lin(0.18), 0.5),
                          (0.02, noise(8000, 16000, 0.12) * env_exp(0.12, 25), 0.15)),
    # Menus
    "button_click": lambda: tone(1050, 1000, 0.035, duty=0.25) * env_exp(0.035, 80) * 0.6,
    "button_hover": lambda: tone(1900, 1900, 0.018, duty=0.125) * env_exp(0.018, 140) * 0.35,
    "error": lambda: seq([(hz("A3"), 0.09), (hz("F3"), 0.16)], duty=0.5, k=8, gap=0.02) * 0.6,
    # Economy
    "coin": lambda: seq([(hz("B5"), 0.06), (hz("E6"), 0.3)], duty=0.5, k=9) * 0.6,
    "buy": lambda: mix((0, seq([(hz("E6"), 0.05), (hz("G6"), 0.05), (hz("C7"), 0.25)], duty=0.25, k=10), 0.55),
                       (0, noise(10000, 14000, 0.04) * env_exp(0.04, 60), 0.2)),
    # Capture
    "capture_throw": lambda: mix((0, noise(1200, 9000, 0.3) * env_lin(0.3, attack=0.05, release_frac=0.5), 0.45),
                                 (0, tone(300, 700, 0.3, duty=0.125) * env_lin(0.3, release_frac=0.5), 0.3)),
    "capture_shake": lambda: mix((0, tone(500, 300, 0.05, duty=0.5) * env_exp(0.05, 50), 0.6),
                                 (0, noise(5000, 2000, 0.05) * env_exp(0.05, 60), 0.4),
                                 (0.12, tone(450, 280, 0.05, duty=0.5) * env_exp(0.05, 50), 0.5)),
    "capture_success": lambda: mix((0, noise(9000, 4000, 0.06) * env_exp(0.06, 50), 0.5),
                                   (0.08, seq([(f, 0.1) for f in N("G5", "C6", "E6")] + [(hz("G6"), 0.45)], duty=0.5, k=7), 0.55),
                                   (0.08, seq([(f, 0.1) for f in N("E5", "G5", "C6")] + [(hz("E6"), 0.45)], duty=0.125, k=7), 0.3)),
    "capture_fail": lambda: mix((0, noise(3000, 12000, 0.15) * env_exp(0.15, 20), 0.6),
                                (0.12, tone(900, 200, 0.3, duty=0.25) * env_exp(0.3, 9), 0.5)),
    # Progression
    "evolution": lambda: mix((0, tone(200, 1600, 1.4, duty=0.25, vib=(9, 0.5)) * env_lin(1.4, attack=0.2, release_frac=0.25), 0.4),
                             (0.2, seq([(f, 0.08) for f in N("C5", "E5", "G5", "C6") * 3], duty=0.125, k=10), 0.25),
                             (1.25, seq([(hz("C6"), 0.12), (hz("G6"), 0.6)], duty=0.5, k=5), 0.5)),
    "level_up": lambda: seq([(f, 0.08) for f in N("C5", "E5", "G5")] + [(hz("C6"), 0.4)], duty=0.5, k=8) * 0.6,
    "badge": lambda: mix((0, seq([(hz("G5"), 0.1), (hz("G5"), 0.1), (hz("G5"), 0.1), (hz("C6"), 0.2), (hz("E6"), 0.15),
                                  (hz("G6"), 0.6)], duty=0.5, k=5), 0.5),
                         (0, seq([(hz("E5"), 0.1), (hz("E5"), 0.1), (hz("E5"), 0.1), (hz("G5"), 0.2), (hz("C6"), 0.15),
                                  (hz("E6"), 0.6)], duty=0.125, k=5), 0.3),
                         (0.5, noise(20000, 12000, 0.8) * env_exp(0.8, 5), 0.2)),
    # Talents / Élan / field
    "talent": lambda: mix((0, seq([(f, 0.06) for f in N("A5", "E6", "A6", "C#7")], "sine", k=6), 0.6),
                          (0.03, seq([(f, 0.06) for f in N("A5", "E6", "A6", "C#7")], duty=0.125, k=10), 0.2)),
    "elan": lambda: mix((0, tone(150, 900, 0.4, duty=0.5, vib=(22, 1.0)) * env_lin(0.4, attack=0.02, release_frac=0.3), 0.45),
                        (0.3, tone(900, 900, 0.2, duty=0.25) * env_exp(0.2, 12), 0.4)),
    "debris": lambda: mix(*[(i * 0.07, noise(2500 - i * 300, 600, 0.12) * env_exp(0.12, 25), 0.7 - i * 0.1) for i in range(5)]),
    "phase_change": lambda: mix((0, tone(90, 40, 1.2, "tri") * env_exp(1.2, 3), 0.9),
                                (0, noise(2000, 200, 1.0) * env_exp(1.0, 4), 0.5),
                                (0.3, tone(200, 1200, 0.9, duty=0.125, vib=(12, 1.0)) * env_lin(0.9, attack=0.1, release_frac=0.4), 0.35)),
}


# Peak level per sound (default 0.7 = -3 dBFS): UI ticks stay quieter than hits.
LEVEL = {"button_hover": 0.3, "button_click": 0.45, "card_draw": 0.45, "capture_shake": 0.55, "coin": 0.55}


def finish(x, level=0.7):
    x = x - np.mean(x)
    peak = float(np.max(np.abs(x))) or 1.0
    x = x * (level / peak)
    f = min(len(x) // 4, int(0.004 * SR))
    if f:
        x[:f] *= np.linspace(0, 1, f)
        x[-f:] *= np.linspace(1, 0, f)
    return x


def write(path, x):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())


def main(argv):
    os.makedirs(OUT, exist_ok=True)
    ids = argv or list(SFX)
    for sid in ids:
        x = finish(SFX[sid](), LEVEL.get(sid, 0.7))
        write(os.path.join(OUT, sid + ".wav"), x)
        print("%-16s %5.2f s" % (sid, len(x) / SR))


if __name__ == "__main__":
    main(sys.argv[1:])
