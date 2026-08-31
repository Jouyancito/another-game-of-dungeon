#!/usr/bin/env python3
"""Generate the placeholder SFX and music the game expects.

The repo shipped assets/sounds/sfx/ with a README listing 12 sounds "to be downloaded from
CC0 sources" and zero actual files, so AudioManager warned on every single sound the game
ever tried to play — the game was silent. These are synthesized stand-ins: no license, no
download, reproducible from this script.

They are PLACEHOLDERS, exactly as the README named them. Each one is shaped to read as the
thing it stands for (a punch thuds, a level-up rises, a slime dies wet) so the game can be
played and recorded with audio feedback. Replace them with real CC0 or authored audio when
that exists — the filenames and the AudioManager map do not change.

Stdlib only (wave/struct/math/random): no numpy, no ffmpeg, nothing to install.
Writes 16-bit mono PCM .wav at 44.1kHz, which Godot imports natively.

Usage: python gen_placeholder_sfx.py [out_root]     # default: ../../assets/sounds
"""

import math
import os
import random
import struct
import sys
import wave

RATE = 44100


def _write(path, samples):
    """Clamp, convert to 16-bit PCM and write."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
        )
        w.writeframes(frames)
    print("  %-28s %5.2fs" % (os.path.basename(path), len(samples) / RATE))


def _env(i, total, attack=0.005, release=0.4):
    """Attack/decay envelope. Without it every sound clicks on and off."""
    t = i / total
    a = min(1.0, (i / RATE) / attack) if attack > 0 else 1.0
    r = max(0.0, 1.0 - t) ** (1.0 / release)
    return a * r


def _noise():
    return random.uniform(-1.0, 1.0)


def tone(freq, dur, *, amp=0.5, attack=0.005, release=0.4, harmonics=1, sweep=1.0):
    """Sine with optional harmonics and a pitch sweep (sweep = end/start ratio)."""
    n = int(RATE * dur)
    out = []
    phase = 0.0
    for i in range(n):
        f = freq * (sweep ** (i / n))
        phase += 2 * math.pi * f / RATE
        s = math.sin(phase)
        for h in range(2, harmonics + 1):
            s += math.sin(phase * h) / h
        out.append(s * amp * _env(i, n, attack, release))
    return out


def noise_burst(dur, *, amp=0.5, attack=0.001, release=0.25, lowpass=0.35):
    """Filtered noise. Low-passed so it reads as a thud, not as static."""
    n = int(RATE * dur)
    out, prev = [], 0.0
    for i in range(n):
        prev += (_noise() - prev) * lowpass  # one-pole low-pass
        out.append(prev * amp * _env(i, n, attack, release))
    return out


def mix(*layers):
    """Sum layers of different lengths."""
    n = max(len(l) for l in layers)
    out = [0.0] * n
    for layer in layers:
        for i, s in enumerate(layer):
            out[i] += s
    return out


def loop_drone(dur, freqs, *, amp=0.18, wobble=0.12):
    """Seamless-ish ambient bed: stacked detuned sines + slow amplitude drift."""
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        s = sum(math.sin(2 * math.pi * f * t) for f in freqs) / len(freqs)
        drift = 1.0 + wobble * math.sin(2 * math.pi * 0.07 * t)
        # Fade both ends so the loop point does not click.
        fade = min(1.0, i / (RATE * 1.5), (n - i) / (RATE * 1.5))
        out.append(s * amp * drift * fade)
    return out


SFX = {
    # Combat — the punch has to land before it rings, so: thud first, snap on top.
    "punch_hit": lambda: mix(
        noise_burst(0.14, amp=0.55, lowpass=0.18),
        tone(95, 0.13, amp=0.42, release=0.18),
    ),
    "punch_hit_crit": lambda: mix(
        noise_burst(0.19, amp=0.62, lowpass=0.42),
        tone(155, 0.17, amp=0.5, release=0.2, harmonics=3),
        tone(880, 0.09, amp=0.22, release=0.12),  # the bright ping that says "crit"
    ),
    "dash_whoosh": lambda: noise_burst(0.32, amp=0.42, attack=0.06, release=0.7, lowpass=0.55),
    "dash_impact": lambda: mix(
        noise_burst(0.16, amp=0.5, lowpass=0.15),
        tone(70, 0.2, amp=0.45, release=0.25),
    ),
    # War cry: rises (activate), then holds (loop).
    "war_cry_activate": lambda: mix(
        tone(180, 0.55, amp=0.4, attack=0.03, release=0.6, harmonics=4, sweep=1.9),
        noise_burst(0.5, amp=0.16, attack=0.05, release=0.8, lowpass=0.3),
    ),
    "war_cry_loop": lambda: loop_drone(2.0, [110, 165, 220], amp=0.14),
    # Block: success rings metal, failure is dead.
    "block_success": lambda: mix(
        tone(1250, 0.28, amp=0.32, release=0.5, harmonics=3),
        tone(1870, 0.22, amp=0.16, release=0.4),
        noise_burst(0.07, amp=0.2, lowpass=0.7),
    ),
    "block_fail": lambda: mix(
        noise_burst(0.13, amp=0.4, lowpass=0.2),
        tone(210, 0.14, amp=0.28, release=0.2),
    ),
    # Enemies: flesh is wet and dull; the slime dies falling.
    "enemy_hit_flesh": lambda: mix(
        noise_burst(0.12, amp=0.45, lowpass=0.13),
        tone(130, 0.1, amp=0.3, release=0.15),
    ),
    "enemy_die_slime": lambda: mix(
        tone(320, 0.45, amp=0.35, release=0.55, sweep=0.35),  # pitch falls: it deflates
        noise_burst(0.4, amp=0.28, attack=0.02, release=0.6, lowpass=0.1),
    ),
    # Pickup: short and bright, two notes up. It must never feel like a hit.
    "item_pickup_common": lambda: mix(
        tone(880, 0.07, amp=0.26, release=0.25),
        [0.0] * int(RATE * 0.05) + tone(1320, 0.1, amp=0.24, release=0.3),
    ),
    # Level up: an arpeggio that climbs. The only sound in the game that should feel like a
    # reward, so it is the longest and the only one that resolves upward.
    "level_up": lambda: mix(
        tone(523, 0.16, amp=0.3, release=0.35),
        [0.0] * int(RATE * 0.11) + tone(659, 0.16, amp=0.3, release=0.35),
        [0.0] * int(RATE * 0.22) + tone(784, 0.18, amp=0.3, release=0.4),
        [0.0] * int(RATE * 0.33) + tone(1046, 0.42, amp=0.34, release=0.7, harmonics=2),
    ),
}

MUSIC = {
    # Beds, not songs. Low, slow, and out of the way — they exist so the floors are not
    # silent, and they must never compete with a combat cue.
    "dungeon_ambient": lambda: loop_drone(24.0, [55, 82.5, 110, 164.8], amp=0.10),
    "combat_loop": lambda: loop_drone(16.0, [73.4, 110, 146.8, 220], amp=0.13, wobble=0.22),
    "boss_theme": lambda: loop_drone(20.0, [49, 73.4, 98, 130.8, 196], amp=0.16, wobble=0.3),
    "taverna_ambient": lambda: loop_drone(20.0, [98, 146.8, 196, 246.9], amp=0.09, wobble=0.08),
}


def main():
    random.seed(7)  # reproducible: the same script always yields the same bytes
    root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.path.dirname(__file__), "..", "..", "assets", "sounds"
    )

    print("SFX:")
    for name, make in SFX.items():
        _write(os.path.join(root, "sfx", name + ".wav"), make())

    print("Music:")
    for name, make in MUSIC.items():
        _write(os.path.join(root, "music", name + ".wav"), make())


if __name__ == "__main__":
    main()
