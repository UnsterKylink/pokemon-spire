#!/usr/bin/env python3
"""Story 022: tiny Game Boy style tracker / synth that renders the ORIGINAL music of Pokemon Spire.

Run from the repo root:
    python3 tools/audio/chiptune.py            # render every track to assets/audio/music/<id>.ogg
    python3 tools/audio/chiptune.py carte mart # render only these tracks
    python3 tools/audio/chiptune.py --check    # decode the rendered files and print stats (no render)

Channels (Game Boy flavour): lead pulse (12.5 / 25 / 50 % duty, ADSR, delayed vibrato), second pulse
(arpeggio, counter-melody a third below, or echo), 4-bit stepped triangle bass ("wave" channel) and
LFSR noise drums. Rendered at 44.1 kHz (2x oversampling), low-passed, decimated to 22.05 kHz mono,
encoded to OGG Vorbis with ffmpeg (WAV fallback when ffmpeg is missing).

Looping tracks are rendered so that the file loops seamlessly: note releases that spill past the end
are folded back onto the start, and the filters run on a periodic signal. Godot loops them through the
.import setting loop=true AND AudioManager sets stream.loop at runtime (assets/data/audio.json "loop").

Notation (all compositions below are original):
  key + mode: tonic name and scale (major, minor, dorian, phrygian).
  melody: bars separated by "|", tokens "<degree>[accidental][octave]:<sixteenths>", e.g. "5:4 3':2 b7,:2".
          degree 1-9 of the scale, accidental "#"/"b" before or after the digit, "'" = octave up,
          "," = octave down, "r" = rest, "_" = tie (extends the previous note). Each bar must sum to 16.
  chords: one bar per "|", one or more chord tokens per bar (split evenly): "<degree>[quality]",
          quality M/m/d/+ (major/minor/dim/aug), 7 (diatonic 7th), M7 (dominant 7th), m7, s (sus4);
          no quality = diatonic triad of the mode.
  bass pattern (16 chars per bar): R root, T third, F fifth, O octave, L fifth below, S seventh,
          "-" hold, "." rest. arp pattern: 1 3 5 7 8 (root, 3rd, 5th, 7th, octave), 9 (3rd + octave).
  drums: k kick, s snare, h closed hat, o open hat, c crash, K timpani, t tom, "." rest.
"""
import math, os, re, shutil, subprocess, sys, tempfile, wave
import numpy as np

SR = 44100
OUT_SR = 22050
STEPS = 16
OUT_DIR = "assets/audio/music"
TAIL_S = 2.5

MODES = {
    "major": [0, 2, 4, 5, 7, 9, 11],
    "minor": [0, 2, 3, 5, 7, 8, 10],
    "dorian": [0, 2, 3, 5, 7, 9, 10],
    "phrygian": [0, 1, 3, 5, 7, 8, 10],
}
NOTE_PC = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6,
           "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}
QUALITY = {"M": [0, 4, 7], "m": [0, 3, 7], "d": [0, 3, 6], "+": [0, 4, 8], "s": [0, 5, 7],
           "M7": [0, 4, 7, 10], "m7": [0, 3, 7, 10]}
MEL_TOKEN = re.compile(r"^([#b]?)([1-9]|r|_)([#b]?)([',]*)(?::(\d+))?$")
CHORD_TOKEN = re.compile(r"^([#b]?)([1-7])(M7|m7|M|m|d|\+|s|7)?$")


# ----------------------------------------------------------------------------------------------- songs
# Every melody / progression below was written for this project (no existing game melody is copied).

SONGS = {
    "titre": {
        "mood": "thème principal, héroïque", "key": "D", "mode": "major", "bpm": 132, "lead_oct": 5,
        "lead": {"duty": 0.5, "env": (0.005, 0.12, 0.7, 0.06), "vib": (0.18, 5.5, 0.18)},
        "sections": {
            "I": {"chords": "1|4 5",
                  "melody": "1:2 1:2 1:2 5,:2 1:4 3:4|4:4 6:4 5:8",
                  "bass": "R-R-R-R-O-O-O-O-", "arp": "1.1.1.1.5.5.5.5.", "drums": "k.k.k.k.s.s.ssss"},
            "A": {"chords": "1|5|6|3|4|1|2|5",
                  "melody": "5:6 3:2 1:4 3:4|2:6 7,:2 5,:4 7,:4|1:6 6,:2 3:4 1:4|7,:4 3:4 5:8|"
                            "4:2 5:2 6:4 1':4 6:4|5:4 3:4 1:4 3:4|2:4 4:4 6:2 5:2 4:2 2:2|3:4 2:4 7,:2 1:2 2:4",
                  "bass": "R-.RO-.RR-.RO-R-", "arp": "1.3.5.3.1.3.5.8.",
                  "drums": "k.h.s.h.k.k.s.h.", "fill": "k.h.s.h.s.s.ssss"},
            "B": {"chords": "4|5|3|6|2|b7M|5|5M7",
                  "melody": "1':6 7:2 6:4 5:4|7:6 6:2 5:4 2':4|7:4 5:4 3:8|6:2 7:2 1':4 6:8|"
                            "6:4 5:4 4:4 2:4|4:4 2:4 b7,:4 2:4|5,:2 7,:2 2:2 4:2 5:4 7:4|2':6 1':2 7:4 6:4",
                  "bass": "R-R-O-R-F-R-O-R-", "harm": "counter",
                  "drums": "k.h.s.hkk.h.s.h.", "fill": "k.s.s.s.ssssc..."},
        },
        "form": ["I", "A", "B", {"like": "A", "harm": "counter", "arp": None}],
    },
    "carte": {
        "mood": "aventure joyeuse", "key": "G", "mode": "major", "bpm": 116, "lead_oct": 4,
        "lead": {"duty": 0.25, "env": (0.004, 0.10, 0.65, 0.05), "vib": (0.15, 5.0, 0.2)},
        "sections": {
            "A": {"chords": "1|4|1|5|1|4|2 5|1",
                  "melody": "1:3 2:1 3:4 5:4 3:4|4:3 5:1 6:4 1':4 6:4|5:4 3:2 5:2 1':6 7:2|7:4 6:2 5:2 2:4 r:4|"
                            "1:3 2:1 3:4 5:4 1':4|1':4 6:4 4:4 6:4|2:4 4:4 7,:4 2:4|1:8 5,:4 r:4",
                  "bass": "R.F.O.F.R.F.O.F.", "arp": "..3...5...3...5.",
                  "drums": "k.h.s.h.k.h.s.h.", "fill": "k.h.s.h.k.s.ssss"},
            "B": {"chords": "6|3|4|1|6|2|4|5",
                  "melody": "3:6 2:2 3:4 6:4|5:6 3:2 2:4 3:4|4:6 3:2 4:4 6:4|5:12 r:4|"
                            "6:4 5:4 3:4 5:4|6:4 4:4 2:4 1:4|1:4 3:4 4:4 6:4|5:4 7:4 2':4 7:4",
                  "bass": "R-.RF-.FO-.OF-.F", "arp": "1.3.5.8.5.3.1.3.",
                  "drums": "k.h.s.h.k.k.s.h.", "fill": "k.h.s.h.s.s.ssss"},
        },
        "form": ["A", {"like": "A", "oct": 1, "harm": "counter", "arp": None}, "B"],
    },
    "combat_sauvage": {
        "mood": "combat sauvage, énergique", "key": "A", "mode": "minor", "bpm": 168, "lead_oct": 4,
        "lead": {"duty": 0.25, "env": (0.003, 0.08, 0.75, 0.04), "vib": (0.2, 6.0, 0.15)},
        "sections": {
            "I": {"chords": "1|5M7",
                  "melody": "1':2 7:2 6:2 5:2 4:2 3:2 2:2 1:2|7#,:4 2:4 4:4 7#,:4",
                  "bass": "RORORORORORORORO", "arp": "1358135813581358", "drums": "k.h.k.h.k.h.ssss"},
            "A": {"chords": "1|6|7|5M|1|6|4|5M",
                  "melody": "1:4 3:2 5:2 1':6 7:2|6:4 5:2 6:2 1':4 6:4|7:6 5:2 2':4 7:4|7#:8 r:2 7#:2 1':2 2':2|"
                            "3':6 2':2 1':4 5:4|6:4 1':4 3':4 1':4|4:4 6:4 1':2 7:2 6:2 4:2|5:4 7#,:4 2:4 5:4",
                  "bass": "R-O-R-O-R-O-R-O-", "arp": "1358135813581358",
                  "drums": "k.h.s.h.k.hks.h.", "fill": "k.h.s.h.s.ssssss"},
            "B": {"chords": "4|5M|6|3|4|5M|1|5M",
                  "melody": "1':4 6:2 4:2 6:8|7#:4 5:2 2:2 5:8|1':6 2':2 3':4 1':4|7:6 5:2 3:4 5:4|"
                            "4:2 6:2 1':2 4':2 3':4 1':4|7#:2 2':2 4':2 3':2 2':4 7#:4|1':8 5:4 3:4|"
                            "2':2 1':2 7#:2 6:2 5:2 4:2 3:2 2:2",
                  "bass": "R-RRO-RRR-RRO-RR", "harm": "counter",
                  "drums": "k.hsk.h.k.hsk.hs", "fill": "k.s.k.s.ssssc..."},
        },
        "form": ["I", "A", "B", {"like": "A", "oct": 0, "harm": "counter", "arp": None, "lead_duty": 0.5}],
    },
    "combat_dresseur": {
        "mood": "combat de Dresseur, tendu", "key": "E", "mode": "minor", "bpm": 176, "lead_oct": 4,
        "lead": {"duty": 0.125, "env": (0.003, 0.07, 0.8, 0.04), "vib": (0.22, 6.5, 0.14)},
        "sections": {
            "I": {"chords": "1|1|b2M|5M",
                  "melody": "1:2 1':2 1:2 7:2 1:2 6:2 1:2 5:2|1:2 1':2 1:2 7:2 1:2 6:2 1:2 5:2|"
                            "b2:2 b2':2 b2:2 1':2 b2:2 7:2 b2:2 6:2|5,:4 7#,:4 2:4 5:4",
                  "bass": "R.RRR.RRR.RRO.RR", "arp": "1.5.8.5.1.5.8.5.",
                  "drums": "k...k...k...k.k.|k...k...k...k.k.|k.h.k.h.k.h.k.h.|k.s.k.s.s.s.ssss"},
            "A": {"chords": "1|6|4|5M|1|6|b2M|5M7",
                  "melody": "5:6 3:2 1:4 5:4|6:6 5:2 3:4 1:4|4:4 6:4 1':4 3':4|2':8 7#:4 5:4|"
                            "1':6 7:2 5:4 3:4|6:4 1':2 3':2 5':4 3':4|b2':6 1':2 6:4 4:4|5:4 7#:4 2':4 4':4",
                  "bass": "R.RRR.RRR.RRO.RR", "arp": "1.5.8.5.1.5.8.5.",
                  "drums": "k.h.s.hkk.h.s.hh", "fill": "k.h.s.hkk.s.ssss"},
            "B": {"chords": "6|7|1|1|4|5M|6|5M",
                  "melody": "3':8 1':4 6:4|2':8 7:4 4:4|1':4 5:4 3:4 5:4|1':12 r:4|"
                            "1':4 7:2 6:2 4:4 1:4|2:4 5:4 7#:4 2':4|3':4 2':2 1':2 6:4 3:4|5:2 7#:2 2':2 5':2 4':4 2':4",
                  "bass": "R-O-R-O-R-O-R-O-", "harm": "counter",
                  "drums": "k.hsk.hsk.hsk.hs", "fill": "k.s.s.s.ssssc..."},
        },
        "form": ["I", "A", "B", {"like": "A", "harm": "counter", "arp": None, "lead_duty": 0.25}],
    },
    "champion": {
        "mood": "Champion, épique", "key": "C", "mode": "minor", "bpm": 160, "lead_oct": 5,
        "lead": {"duty": 0.5, "env": (0.004, 0.10, 0.75, 0.05), "vib": (0.2, 5.5, 0.16)},
        "sections": {
            "I": {"chords": "6|7",
                  "melody": "1:4 1:2 1:2 3:4 5:4|4:4 4:2 4:2 2:4 7,:4",
                  "bass": "R-RRR-RRR-RRR-RR", "arp": "1358135813581358", "drums": "k.k.s.k.k.k.s.k.|k.k.s.k.s.ssssss"},
            "A": {"chords": "1|6|7|1|1|6|4|5M",
                  "melody": "1':8 5:4 3:4|1':6 3':2 6:8|2':6 1':2 7:4 4:4|5:12 r:4|"
                            "5:4 1':4 3':4 5':4|4':6 3':2 1':4 6:4|1':4 6:4 4:4 6:4|7#:8 2':4 5':4",
                  "bass": "R-RRR-RRR-RRR-RR", "arp": "1358135813581358",
                  "drums": "k.h.s.h.k.k.s.h.", "fill": "k.h.s.h.s.s.ssss"},
            "B": {"chords": "6|7|5m|1|4|7|3|5M",
                  "melody": "3':6 2':2 1':4 6:4|2':6 1':2 7:4 4:4|7:4 5:4 2':4 7:4|1':12 r:4|"
                            "4:4 6:4 1':4 4':4|4':6 2':2 7:8|3':4 7:4 5:4 3:4|2:2 3:2 4:2 5:2 6:2 7#:2 1':2 2':2",
                  "bass": "R-O-R-O-R-O-R-O-", "harm": "counter",
                  "drums": "k.hsk.h.k.hsk.hs", "fill": "k.s.k.s.ssssc..."},
        },
        "form": ["I", "A", "B", {"like": "A", "harm": "counter", "arp": None}],
    },
    "conseil": {
        "mood": "Conseil 4, solennel et grave", "key": "F", "mode": "minor", "bpm": 100, "lead_oct": 4,
        "lead": {"duty": 0.5, "env": (0.03, 0.3, 0.7, 0.15), "vib": (0.15, 4.5, 0.3)},
        "sections": {
            "A": {"chords": "1|6|4|5M|1|6|2d|5M",
                  "melody": "1:8 3:4 5:4|6:8 5:4 3:4|4:6 3:2 4:4 6:4|5:12 7#,:4|"
                            "1':8 7:2 6:2 5:4|6:6 5:2 4:4 3:4|2:8 4:4 6:4|7#,:8 5,:8",
                  "bass": "R-------L-------", "arp": "1-3-5-3-1-3-5-3-",
                  "drums": "K...............|........K.......", "fill": "K.......K...K.K."},
            "B": {"chords": "6|7|3|6|4|1|2d|5M",
                  "melody": "3':8 1':4 6:4|2':8 7:4 4:4|7:8 5:4 3:4|1:8 6:8|"
                            "4:6 5:2 6:4 1':4|1':12 r:4|2':6 1':2 7:4 6:4|7#:8 5:8",
                  "bass": "R---F---O---F---", "harm": "counter",
                  "drums": "K.......s.......", "fill": "K.......K.K.KKKK"},
        },
        "form": ["A", "B"],
    },
    "ethernatos_1": {
        "mood": "Éthernatos phase 1, sombre", "key": "Bb", "mode": "phrygian", "bpm": 150, "lead_oct": 4,
        "lead": {"duty": 0.125, "env": (0.003, 0.08, 0.8, 0.05), "vib": (0.3, 6.0, 0.12)},
        "sections": {
            "A": {"chords": "1|2|1|6|1|2|4|5M",
                  "melody": "1:2 r:2 1:2 2:2 1:4 5,:4|2:6 1:2 2:4 4:4|3:6 2:2 1:4 5,:4|6,:8 r:4 5,:2 6,:2|"
                            "5:6 6:2 5:4 3:4|6:6 5:2 6:4 2':4|4:4 6:4 1':4 6:4|5:4 7#:4 2#':4 5':4",
                  "bass": "R-R-O-R-R-R-O-R-", "arp": "1.5.1.5.8.5.1.5.",
                  "drums": "k.hsk.h.kkhsk.hs", "fill": "k.s.k.s.ssssssss"},
            "B": {"chords": "6|7|1|1|6|7|2|5M",
                  "melody": "1':8 6:4 3:4|7:8 2':4 4':4|1':4 5:4 3:4 1:4|2:2 1:2 2:2 3:2 5:8|"
                            "3':8 1':4 6:4|4':8 2':4 7:4|2':4 4':4 6':4 4':4|5':4 2#':4 7#:4 5:4",
                  "bass": "RRO.RRO.RRO.RRO.", "harm": "counter",
                  "drums": "k.h.s.hkk.h.s.hh", "fill": "k.s.s.s.ssssc..."},
        },
        "form": ["A", "B", {"like": "A", "harm": "counter", "arp": None, "lead_duty": 0.25}],
    },
    "ethernatos_2": {
        "mood": "Éthernatos phase 2 (Infinitamax), intense", "key": "B", "mode": "phrygian", "bpm": 184, "lead_oct": 4,
        "lead": {"duty": 0.25, "env": (0.002, 0.06, 0.85, 0.04), "vib": (0.35, 7.0, 0.1)},
        "sections": {
            "A": {"like_song": ("ethernatos_1", "A"),
                  "bass": "RORORORORORORORO", "arp": "1358135813581358",
                  "drums": "k.hsk.hskkhsk.hs", "fill": "k.s.k.s.ssssssss"},
            "C": {"chords": "1|2|6|5M|1|2|6|5M",
                  "melody": "5:2 1':2 5:2 2':2 5:2 3':2 2':2 1':2|6:2 2':2 6:2 4':2 6:2 2':2 4':2 6':2|"
                            "6:2 1':2 3':2 6':4 3':2 1':2 6:2|5:4 7#:4 2#':4 5':4|"
                            "5:2 1':2 5:2 2':2 5:2 3':2 2':2 1':2|6:2 2':2 6:2 4':2 6:2 2':2 4':2 6':2|"
                            "6:2 1':2 3':2 6':4 3':2 1':2 6:2|5':2 4':2 2#':2 1':2 7#:2 6:2 5:2 7#,:2",
                  "bass": "R-RRO-RRR-RRO-RR", "harm": "echo",
                  "drums": "kkhsk.hskkhsk.hs", "fill": "k.s.s.ssssssc..."},
        },
        "form": ["A", "C", {"like": "A", "harm": "counter", "arp": None}, "C"],
    },
    "victoire": {
        "mood": "jingle de victoire (non bouclé)", "key": "C", "mode": "major", "bpm": 140, "lead_oct": 5, "loop": False,
        "lead": {"duty": 0.5, "env": (0.004, 0.1, 0.75, 0.25), "vib": (0.2, 5.5, 0.15)},
        "sections": {
            "A": {"chords": "1|4|5|1",
                  "melody": "5,:2 5,:2 5,:2 1:4 3:2 5:4|6:4 4:2 6:2 1':8|7:2 7:2 7:2 1':2 2':4 7:4|1':16",
                  "bass": "R-R-R-R-R-R-O-O-|R-R-R-R-O-O-O-O-|R-R-R-R-F-F-F-F-|R---------------",
                  "arp": "1358135813581358|1358135813581358|1358135813581358|1-------........",
                  "drums": "k.h.s.h.k.h.s.h.|k.h.s.h.k.h.s.h.|k.h.s.h.s.s.ssss|c..............."},
        },
        "form": ["A"],
    },
    "defaite": {
        "mood": "défaite, court et triste (non bouclé)", "key": "D", "mode": "minor", "bpm": 76, "lead_oct": 4, "loop": False,
        "lead": {"duty": 0.25, "env": (0.02, 0.4, 0.6, 0.4), "vib": (0.25, 4.5, 0.25)},
        "sections": {
            "A": {"chords": "1 6|4 5M|1",
                  "melody": "5:6 4:2 3:4 2:4|1:6 2:2 7#,:8|1:16",
                  "bass": "R-------R-------|R-------R-------|R---------------",
                  "arp": "1...3...1...3...|1...3...1...3...|1...............", "drums": "................"},
        },
        "form": ["A"],
    },
    "centre": {
        "mood": "Centre Pokémon, doux et apaisant", "key": "F", "mode": "major", "bpm": 92, "lead_oct": 4,
        "lead": {"duty": 0.25, "env": (0.01, 0.25, 0.55, 0.12), "vib": (0.12, 4.5, 0.25)},
        "sections": {
            "A": {"chords": "1|6|2|5|1|6|2 5|1",
                  "melody": "3:4 5:4 1':6 7:2|6:4 5:4 6:8|4:4 2:4 6,:4 2:4|3:4 2:4 1:4 7,:4|"
                            "3:4 5:4 1':4 3':4|3':6 2':2 1':8|6:4 4:4 5:4 3:2 2:2|1:12 r:4",
                  "bass": "R---F---O---F---", "harm": "echo",
                  "drums": "....h.......h...", "fill": "....h.......h.h."},
            "B": {"chords": "4|5|3|6|2|5|1|5",
                  "melody": "4:4 6:4 1':6 2':2|2':8 7:4 5:4|7:6 6:2 5:4 3:4|6:12 r:4|"
                            "2':4 1':4 6:4 4:4|5:4 7:4 2':8|1':4 6:4 5:4 3:4|2:4 3:4 5:8",
                  "bass": "R---F---O---F---", "arp": "1.3.5.8.5.3.1.3.",
                  "drums": "....h.......h...", "fill": "....h.......h.h."},
        },
        "form": ["A", "B"],
    },
    "mart": {
        "mood": "Boutique, léger et sautillant", "key": "Bb", "mode": "major", "bpm": 132, "lead_oct": 4,
        "lead": {"duty": 0.125, "env": (0.003, 0.08, 0.5, 0.04), "vib": (0.1, 5.0, 0.2)},
        "sections": {
            "A": {"chords": "1|6|2|5|1|6|2|5",
                  "melody": "1:3 3:1 5:3 1':1 7:4 5:4|6:3 5:1 6:3 1':1 3:8|2:3 4:1 6:3 2':1 1':4 6:4|5:3 7:1 2':4 5:2 r:6|"
                            "1:3 3:1 5:3 1':1 3':4 1':4|2':3 1':1 6:3 5:1 6:8|4:4 2:4 6:4 4:2 2:2|5,:2 r:2 7,:2 r:2 2:2 r:2 5:4",
                  "bass": "R.F.O.F.R.F.O.F.", "arp": "..3...5...3...5.",
                  "drums": "k.h.s.h.k.h.s.hh", "fill": "k.h.s.h.k.s.s.ss"},
            "B": {"chords": "4|3|2|5|4|3|2|5",
                  "melody": "4:3 6:1 1':3 4':1 3':4 1':4|3':3 2':1 1':3 6:1 7:8|6:3 5:1 4:3 2:1 2':8|1':4 7:4 5:4 r:4|"
                            "6:2 1':2 4':2 1':2 6:2 1':2 4':4|5:2 7:2 3':2 7:2 5:2 7:2 3':4|"
                            "4:2 6:2 2':2 6:2 4:2 2:2 6,:4|5,:2 7,:2 2:2 5:2 7:2 2':2 5':4",
                  "bass": "R.R.F.F.O.O.F.F.", "harm": "counter",
                  "drums": "k.h.s.hkk.h.s.h.", "fill": "k.h.s.h.s.s.ssss"},
        },
        "form": ["A", "B", {"like": "A", "harm": "echo", "arp": None, "lead_duty": 0.25}],
    },
    "evenement": {
        "mood": "Événement, mystérieux", "key": "D", "mode": "dorian", "bpm": 96, "lead_oct": 4,
        "lead": {"duty": 0.125, "env": (0.02, 0.3, 0.6, 0.2), "vib": (0.3, 4.0, 0.2)},
        "sections": {
            "A": {"chords": "1|4|1|4|7|5|3|5",
                  "melody": "1:4 5:4 4:2 3:2 5:4|6:8 4:4 1':4|1':4 7:4 5:8|6:12 r:4|"
                            "7:4 2':4 4':4 2':4|5:4 7:4 2':8|3':8 7:4 5:4|5:4 4:4 3:4 2:4",
                  "bass": "R-------R---F---", "harm": "echo",
                  "drums": "k.........k.h...", "fill": "k.........k.h.h."},
            "B": {"chords": "7|4|7|4|2|5|2|5",
                  "melody": "4':6 3':2 2':8|1':6 7:2 6:8|2':4 4':4 7:4 4':4|6:4 4:4 1':4 6:4|"
                            "2':6 1':2 6:8|1':6 7:2 5:8|6:4 2':4 4':4 6':4|5':8 r:4 5:4",
                  "bass": "R-------R---F---", "arp": "1.5.3.8.1.5.3.8.",
                  "drums": "k.........k.h...", "fill": "k.......t.t.t.tt"},
        },
        "form": ["A", "B"],
    },
}


# ----------------------------------------------------------------------------------------------- parsing

def key_tonic(name, octave):
    """MIDI number of the tonic `name` in `octave` (C4 = 60)."""
    return 12 * (octave + 1) + NOTE_PC[name]


def split_bars(text):
    return [b.strip() for b in text.split("|")]


def parse_melody(song, sec_name, text, oct_shift):
    """-> list of bars, each a list of [start_step, dur, degree_index or None, acc] (None = rest)."""
    bars = []
    for bi, bar in enumerate(split_bars(text)):
        events, pos = [], 0
        for tok in bar.split():
            m = MEL_TOKEN.match(tok)
            if not m:
                raise ValueError("%s/%s bar %d: bad token %r" % (song, sec_name, bi + 1, tok))
            acc1, deg, acc2, octs, dur = m.groups()
            dur = int(dur) if dur else 4
            acc = acc1 or acc2
            if deg == "r":
                events.append([pos, dur, None, 0])
            elif deg == "_":
                events.append([pos, dur, "tie", 0])
            else:
                o = octs.count("'") - octs.count(",") + oct_shift
                events.append([pos, dur, int(deg) - 1 + 7 * o, {"#": 1, "b": -1}.get(acc, 0)])
            pos += dur
        if pos != STEPS:
            raise ValueError("%s/%s bar %d sums to %d, not %d: %s" % (song, sec_name, bi + 1, pos, STEPS, bar))
        bars.append(events)
    return bars


def parse_chord(tok, mode):
    m = CHORD_TOKEN.match(tok)
    if not m:
        raise ValueError("bad chord %r" % tok)
    acc1, deg, qual = m.groups()
    scale = MODES[mode]
    i = int(deg) - 1
    root = scale[i] + {"#": 1, "b": -1}.get(acc1, 0)
    if qual in QUALITY:
        ivs = list(QUALITY[qual])
    else:
        ivs = [(scale[(i + k) % 7] + 12 * ((i + k) // 7) - scale[i]) for k in (0, 2, 4)]
        if qual == "7":
            ivs.append(scale[(i + 6) % 7] + 12 * ((i + 6) // 7) - scale[i])
    return root, ivs


def parse_chords(text, mode):
    """-> list of bars, each a list of (start_step, root_pc, intervals)."""
    out = []
    for bar in split_bars(text):
        toks = bar.split()
        span = STEPS // len(toks)
        out.append([(k * span,) + parse_chord(t, mode) for k, t in enumerate(toks)])
    return out


def chord_at(bar_chords, step):
    cur = bar_chords[0]
    for c in bar_chords:
        if c[0] <= step:
            cur = c
    return cur[1], cur[2]


def pattern_for(pat, bar_index, nbars):
    if pat is None:
        return None
    pats = split_bars(pat)
    p = pats[bar_index % len(pats)]
    if len(p) != STEPS:
        raise ValueError("pattern %r is not %d steps" % (p, STEPS))
    return p


def resolve_section(song_id, song, entry):
    """A form entry (name or {'like': name, overrides}) -> a full section dict."""
    if isinstance(entry, str):
        sec = dict(song["sections"][entry])
        sec["_name"] = entry
    else:
        sec = dict(song["sections"][entry["like"]])
        sec.update({k: v for k, v in entry.items() if k != "like"})
        sec["_name"] = entry["like"] + "'"
    if "like_song" in sec:
        other, name = sec["like_song"]
        base = dict(SONGS[other]["sections"][name])
        base.update({k: v for k, v in sec.items() if k != "like_song"})
        sec = base
    return sec


# ----------------------------------------------------------------------------------------------- synthesis

def midi_hz(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def adsr(n_gate, env, n_total):
    a, d, s, r = env
    na, nd, nr = max(1, int(a * SR)), max(1, int(d * SR)), max(1, int(r * SR))
    e = np.empty(n_total)
    t = np.arange(n_gate)
    att = np.minimum(t / na, 1.0)
    dec = s + (1 - s) * np.exp(-np.maximum(t - na, 0) / nd * 3.0)
    e[:n_gate] = np.where(t < na, att, dec)
    last = e[n_gate - 1] if n_gate > 0 else 0.0
    rt = np.arange(n_total - n_gate)
    e[n_gate:] = last * np.maximum(1.0 - rt / nr, 0.0)
    return e


def pulse_wave(freq, n, duty, vib=None):
    t = np.arange(n) / SR
    f = np.full(n, freq)
    if vib and vib[0] > 0:
        depth, rate, delay = vib
        ramp = np.clip((t - delay) / 0.12, 0.0, 1.0)
        f = freq * 2.0 ** (depth * ramp * np.sin(2 * np.pi * rate * t) / 12.0)
    phase = np.cumsum(f) / SR
    frac = phase - np.floor(phase)
    w = (frac < duty).astype(float) - duty
    return w * (0.5 / math.sqrt(duty * (1 - duty)))


def tri_wave(freq, n):
    phase = np.arange(n) * freq / SR
    frac = phase - np.floor(phase)
    tri = 2.0 * np.abs(2.0 * frac - 1.0) - 1.0
    return np.round(tri * 7.5) / 7.5  # 4-bit stepped, like the Game Boy wave channel


def lfsr(bits):
    state, taps, out = (1 << bits) - 1, bits - 1, []
    for _ in range((1 << bits) - 1):
        b = (state ^ (state >> 1)) & 1
        state = (state >> 1) | (b << taps)
        out.append(1.0 if state & 1 else -1.0)
    return np.array(out)


LFSR15 = lfsr(15)
LFSR7 = lfsr(7)


def noise(rate, n, short=False):
    seq = LFSR7 if short else LFSR15
    idx = (np.arange(n) * rate / SR).astype(int) % len(seq)
    return seq[idx]


def drum(ch):
    if ch == "k":
        n = int(0.16 * SR)
        t = np.arange(n) / SR
        f = 45 + 120 * np.exp(-t * 35)
        body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 18)
        return body * 1.1 + noise(8000, n) * np.exp(-t * 120) * 0.35
    if ch == "s":
        n = int(0.18 * SR)
        t = np.arange(n) / SR
        return noise(11000, n) * np.exp(-t * 22) * 0.75 + np.sin(2 * np.pi * 190 * t) * np.exp(-t * 40) * 0.4
    if ch == "h":
        n = int(0.05 * SR)
        t = np.arange(n) / SR
        return noise(SR, n, short=True) * np.exp(-t * 90) * 0.35
    if ch == "o":
        n = int(0.2 * SR)
        t = np.arange(n) / SR
        return noise(SR, n, short=True) * np.exp(-t * 16) * 0.3
    if ch == "c":
        n = int(1.0 * SR)
        t = np.arange(n) / SR
        return noise(30000, n) * np.exp(-t * 4) * 0.45
    if ch == "K":
        n = int(0.7 * SR)
        t = np.arange(n) / SR
        f = 58 + 25 * np.exp(-t * 12)
        return tri_wave(1, 1) * 0 + np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 5) * 1.0 \
            + noise(3000, n) * np.exp(-t * 40) * 0.25
    if ch == "t":
        n = int(0.22 * SR)
        t = np.arange(n) / SR
        f = 90 + 70 * np.exp(-t * 20)
        return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 14) * 0.8
    raise ValueError("unknown drum %r" % ch)


DRUMS = {c: drum(c) for c in "ksho cKt".replace(" ", "")}


def add(buf, start, sig):
    end = min(len(buf), start + len(sig))
    if end > start:
        buf[start:end] += sig[:end - start]


def deg_midi(tonic, mode, idx, acc):
    scale = MODES[mode]
    return tonic + 12 * (idx // 7) + scale[idx % 7] + acc


def fold_root(tonic_pc, root, low):
    m = low + ((tonic_pc + root - low) % 12)
    return m


def render_song(song_id):
    song = SONGS[song_id]
    mode, bpm = song["mode"], song["bpm"]
    tonic_pc = NOTE_PC[song["key"]]
    lead_tonic = key_tonic(song["key"], song["lead_oct"])
    sps = SR * 60.0 / bpm / 4.0  # samples per sixteenth
    sections = [resolve_section(song_id, song, e) for e in song["form"]]

    # Flatten bars: (chords, melody events, bass pat, arp pat, drum pat, harm, lead duty)
    bars = []
    for sec in sections:
        chords = parse_chords(sec["chords"], mode)
        mel = parse_melody(song_id, sec["_name"], sec["melody"], sec.get("oct", 0))
        if len(chords) != len(mel):
            raise ValueError("%s/%s: %d chord bars vs %d melody bars" % (song_id, sec["_name"], len(chords), len(mel)))
        nb = len(chords)
        for i in range(nb):
            dp = pattern_for(sec["fill"], 0, 1) if (i == nb - 1 and sec.get("fill")) else pattern_for(sec.get("drums"), i, nb)
            bars.append({"chords": chords[i], "mel": mel[i], "bass": pattern_for(sec.get("bass"), i, nb),
                         "arp": pattern_for(sec.get("arp"), i, nb), "drums": dp, "harm": sec.get("harm"),
                         "duty": sec.get("lead_duty", song["lead"]["duty"])})
    total_steps = len(bars) * STEPS
    loop_len = int(round(total_steps * sps))
    buf_lead = np.zeros(loop_len + int(TAIL_S * SR))
    buf_harm = np.zeros_like(buf_lead)
    buf_bass = np.zeros_like(buf_lead)
    buf_drum = np.zeros_like(buf_lead)
    s0 = lambda step: int(round(step * sps))

    # Lead notes, merged across ties; keep degree for counter-melody.
    notes = []  # [abs_step, dur, idx, acc, duty, harm]
    for bi, bar in enumerate(bars):
        for pos, dur, idx, acc in bar["mel"]:
            if idx == "tie" and notes:
                notes[-1][1] += dur
            elif idx is not None and idx != "tie":
                notes.append([bi * STEPS + pos, dur, idx, acc, bar["duty"], bar["harm"]])
    lead = song["lead"]
    for st, dur, idx, acc, duty, harm in notes:
        midi = deg_midi(lead_tonic, mode, idx, acc)
        n_gate = max(1, int(dur * sps * (0.92 if dur >= 3 else 0.75)))
        n_tot = n_gate + int(lead["env"][3] * SR)
        sig = pulse_wave(midi_hz(midi), n_tot, duty, lead["vib"] if dur >= 4 else None) * adsr(n_gate, lead["env"], n_tot)
        add(buf_lead, s0(st), sig)
        if harm == "counter":
            hm = deg_midi(lead_tonic, mode, idx - 2, acc)
            add(buf_harm, s0(st), pulse_wave(midi_hz(hm), n_tot, 0.125) * adsr(n_gate, lead["env"], n_tot) * 0.75)
        elif harm == "echo":
            add(buf_harm, s0(st + 3), pulse_wave(midi_hz(midi), n_tot, 0.125, lead["vib"]) * adsr(n_gate, lead["env"], n_tot) * 0.55)

    # Bass, arpeggio and drums from per-bar patterns.
    for bi, bar in enumerate(bars):
        for kind in ("bass", "arp"):
            pat = bar[kind]
            if not pat:
                continue
            k = 0
            while k < STEPS:
                ch = pat[k]
                length = 1
                while k + length < STEPS and pat[k + length] == "-":
                    length += 1
                if ch not in ".-":
                    root, ivs = chord_at(bar["chords"], k)
                    if kind == "bass":
                        base = fold_root(tonic_pc, root, 40)
                        off = {"R": 0, "T": ivs[1], "F": ivs[2], "O": 12, "L": ivs[2] - 12,
                               "S": ivs[3] if len(ivs) > 3 else 10}[ch]
                        midi = base + off
                        n_gate = int(length * sps * 0.85)
                        n_tot = n_gate + int(0.02 * SR)
                        env = adsr(n_gate, (0.002, 0.2, 0.8, 0.02), n_tot)
                        add(buf_bass, s0(bi * STEPS + k), tri_wave(midi_hz(midi), n_tot) * env)
                    else:
                        base = fold_root(tonic_pc, root, 57)
                        off = {"1": 0, "3": ivs[1], "5": ivs[2], "7": ivs[3] if len(ivs) > 3 else 12,
                               "8": 12, "9": ivs[1] + 12}[ch]
                        midi = base + off
                        n_gate = int(length * sps * 0.6)
                        n_tot = n_gate + int(0.03 * SR)
                        env = adsr(n_gate, (0.002, 0.08, 0.5, 0.03), n_tot)
                        add(buf_harm, s0(bi * STEPS + k), pulse_wave(midi_hz(midi), n_tot, 0.125) * env * 0.8)
                k += length
        pat = bar["drums"]
        if pat:
            for k, ch in enumerate(pat):
                if ch != ".":
                    add(buf_drum, s0(bi * STEPS + k), DRUMS[ch])

    mix = buf_lead * 0.30 + buf_harm * 0.15 + buf_bass * 0.36 + buf_drum * 0.24
    loop = song.get("loop", True)
    if loop:
        tail = mix[loop_len:].copy()
        mix = mix[:loop_len]
        mix[:len(tail)] += tail[:loop_len]
    else:
        # Keep until the last audible sample, plus a short fade.
        audible = np.nonzero(np.abs(mix) > 1e-3)[0]
        end = (audible[-1] + 1) if len(audible) else loop_len
        mix = mix[:end]
        fade = min(len(mix), int(0.05 * SR))
        mix[-fade:] *= np.linspace(1, 0, fade)
    return finish(mix, loop), {"bpm": bpm, "bars": len(bars), "loop": loop}


def lowpass_fir(cut_hz, taps=63):
    n = np.arange(taps) - (taps - 1) / 2
    h = np.sinc(2 * cut_hz / SR * n) * np.hamming(taps)
    return h / h.sum()


def finish(mix, loop):
    """Low-pass + decimate to OUT_SR (periodic for loops), remove DC, normalise loudness."""
    h = lowpass_fir(9500)
    if loop:
        tripled = np.concatenate([mix, mix, mix])
        y = np.convolve(tripled, h, mode="same")[len(mix):2 * len(mix)]
        if len(y) % 2:
            y = y[:-1]
    else:
        y = np.convolve(mix, h, mode="same")
    y = y[::SR // OUT_SR]
    y = y - y.mean()
    rms = math.sqrt(float(np.mean(y ** 2))) or 1.0
    gain = 10 ** (-16 / 20) / rms
    peak = float(np.max(np.abs(y))) * gain
    if peak > 0.80:
        gain *= 0.80 / peak
    return y * gain


def write_wav(path, y):
    data = (np.clip(y, -1, 1) * 32767).astype("<i2").tobytes()
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(OUT_SR)
        w.writeframes(data)


def encode(track_id, y):
    os.makedirs(OUT_DIR, exist_ok=True)
    if shutil.which("ffmpeg") is None:
        path = os.path.join(OUT_DIR, track_id + ".wav")
        write_wav(path, y)
        return path
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, track_id + ".wav")
        write_wav(wav, y)
        path = os.path.join(OUT_DIR, track_id + ".ogg")
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "4", path], check=True)
    return path


# ----------------------------------------------------------------------------------------------- check

def decode(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "1", "-ar", str(OUT_SR), "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype="<f4").astype(float)


def check():
    """Objective stats of every rendered track: duration, peak, RMS, silent windows, loop seam."""
    print("%-16s %6s %6s %7s %7s %6s %9s %8s %6s" % ("track", "dur_s", "bpm", "peakdB", "rmsdB", "sil%", "seam_jump", "edge_dB", "kB"))
    worst = []
    for tid, song in SONGS.items():
        path = os.path.join(OUT_DIR, tid + ".ogg")
        if not os.path.exists(path):
            path = os.path.join(OUT_DIR, tid + ".wav")
        if not os.path.exists(path):
            print("%-16s MISSING" % tid)
            worst.append(tid)
            continue
        y = decode(path)
        peak = 20 * math.log10(max(np.max(np.abs(y)), 1e-9))
        rms = 20 * math.log10(max(math.sqrt(np.mean(y ** 2)), 1e-9))
        w = int(0.1 * OUT_SR)
        win = y[:len(y) // w * w].reshape(-1, w)
        wr = 20 * np.log10(np.maximum(np.sqrt(np.mean(win ** 2, axis=1)), 1e-9))
        sil = 100.0 * np.mean(wr < -45)
        typical = float(np.median(np.abs(np.diff(y)))) or 1e-9
        jump = abs(y[-1] - y[0]) / typical
        e = int(0.2 * OUT_SR)
        edge = 20 * math.log10(max(math.sqrt(np.mean(y[-e:] ** 2)), 1e-9)) - 20 * math.log10(max(math.sqrt(np.mean(y[:e] ** 2)), 1e-9))
        print("%-16s %6.1f %6d %7.2f %7.1f %6.1f %9.2f %8.1f %6d" % (
            tid, len(y) / OUT_SR, song["bpm"], peak, rms, sil, jump if song.get("loop", True) else float("nan"),
            edge, os.path.getsize(path) // 1024))
        if peak > -1.0 or (song.get("loop", True) and sil > 5):
            worst.append(tid)
    print("flagged:", worst or "none")


def main(argv):
    if "--check" in argv:
        check()
        return
    ids = [a for a in argv if not a.startswith("-")] or list(SONGS)
    for tid in ids:
        y, info = render_song(tid)
        path = encode(tid, y)
        print("%-16s %5.1f s  %3d bpm  %2d bars  loop=%s  -> %s" % (tid, len(y) / OUT_SR, info["bpm"], info["bars"], info["loop"], path))


if __name__ == "__main__":
    main(sys.argv[1:])
