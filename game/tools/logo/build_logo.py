"""Generator for the game wordmark: "another game of DUNGEON".

Design contract lives in game/docs/art/_references/logo/_synthesis.md. Short version:

  * Three lines. "another" / "game of" small, lowercase, deliberately messy. "DUNGEON" large,
    controlled, and carrying the gate.
  * The U of DUNGEON is a gate turned upside down. Its FRAME uses the exact same stroke treatment
    as every other letter, so the U reads as a letter first and a door second. The gate's leaves
    are filled in a different colour, so they read as material inside the letter rather than as
    part of the stroke. Legibility therefore never depends on the door being open.
  * The hand-drawn look comes from redrawing every stroke a few times with a small deterministic
    offset, the way the original pen sketch was scribbled over. Messiness is a parameter.

The core builds plain polylines. Two emitters consume them: SVG (the shipping asset, needed
because the mark scales to fullscreen during the title transition) and PNG via Pillow (preview,
since no SVG rasteriser is installed here).

Run:
    python build_logo.py                     # both outputs, default palette
    python build_logo.py --mono              # single-colour study, shape only
    python build_logo.py --seed 7 --scribble 1.6
"""

from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

# --------------------------------------------------------------------------------------------
# Geometry helpers. Design space has Y pointing up; emitters flip it.
# --------------------------------------------------------------------------------------------

Point = tuple[float, float]
Stroke = list[Point]


def line(p0: Point, p1: Point, steps: int = 8) -> Stroke:
    return [
        (p0[0] + (p1[0] - p0[0]) * i / steps, p0[1] + (p1[1] - p0[1]) * i / steps)
        for i in range(steps + 1)
    ]


def arc(cx: float, cy: float, rx: float, ry: float, a0: float, a1: float, steps: int = 24) -> Stroke:
    """Elliptical arc, angles in degrees, counter-clockwise from the +X axis."""
    r0, r1 = math.radians(a0), math.radians(a1)
    return [
        (cx + rx * math.cos(r0 + (r1 - r0) * i / steps), cy + ry * math.sin(r0 + (r1 - r0) * i / steps))
        for i in range(steps + 1)
    ]


def ellipse(cx: float, cy: float, rx: float, ry: float, steps: int = 40) -> Stroke:
    return arc(cx, cy, rx, ry, 0, 360, steps)


def moved(stroke: Stroke, dx: float, dy: float) -> Stroke:
    return [(x + dx, y + dy) for x, y in stroke]


def scaled(stroke: Stroke, sx: float, sy: float | None = None) -> Stroke:
    sy = sx if sy is None else sy
    return [(x * sx, y * sy) for x, y in stroke]


# --------------------------------------------------------------------------------------------
# Glyph library.
#
# Lowercase live in a box where the x-height is 1.0, the baseline is 0, ascenders reach ~1.8 and
# descenders drop to ~-0.45. Uppercase live in a box where the cap height is 1.0. Each entry is
# (strokes, advance).
# --------------------------------------------------------------------------------------------

def _lower() -> dict[str, tuple[list[Stroke], float]]:
    g: dict[str, tuple[list[Stroke], float]] = {}

    g["a"] = ([ellipse(0.42, 0.50, 0.38, 0.50), line((0.80, 1.00), (0.80, 0.0))], 1.00)
    g["o"] = ([ellipse(0.45, 0.50, 0.41, 0.50)], 1.02)
    g["n"] = ([
        line((0.10, 1.00), (0.10, 0.0)),
        arc(0.44, 0.68, 0.34, 0.36, 180, 0),
        line((0.78, 0.68), (0.78, 0.0)),
    ], 0.96)
    g["m"] = ([
        line((0.08, 1.00), (0.08, 0.0)),
        arc(0.38, 0.68, 0.30, 0.34, 180, 0),
        line((0.68, 0.68), (0.68, 0.0)),
        arc(0.98, 0.68, 0.30, 0.34, 180, 0),
        line((1.28, 0.68), (1.28, 0.0)),
    ], 1.46)
    g["t"] = ([
        line((0.38, 1.55), (0.38, 0.20)) + arc(0.56, 0.20, 0.18, 0.18, 180, 270),
        line((0.06, 1.00), (0.70, 1.00)),
    ], 0.80)
    g["h"] = ([
        line((0.10, 1.80), (0.10, 0.0)),
        arc(0.44, 0.68, 0.34, 0.36, 180, 0),
        line((0.78, 0.68), (0.78, 0.0)),
    ], 0.96)
    g["e"] = ([
        line((0.06, 0.52), (0.84, 0.52)),
        arc(0.45, 0.50, 0.39, 0.50, 0, 300),
    ], 0.96)
    g["r"] = ([
        line((0.14, 1.00), (0.14, 0.0)),
        arc(0.42, 0.66, 0.28, 0.34, 180, 60),
    ], 0.74)
    g["g"] = ([
        ellipse(0.44, 0.50, 0.38, 0.50),
        line((0.82, 1.00), (0.82, -0.20)),
        arc(0.52, -0.20, 0.30, 0.26, 0, -110),
    ], 1.04)
    g["f"] = ([
        arc(0.62, 1.44, 0.28, 0.30, 180, 90) + line((0.34, 1.44), (0.34, 0.0)),
        line((0.02, 1.00), (0.68, 1.00)),
    ], 0.74)
    return g


def _upper() -> dict[str, tuple[list[Stroke], float]]:
    g: dict[str, tuple[list[Stroke], float]] = {}

    g["D"] = ([
        line((0.10, 0.0), (0.10, 1.00)),
        line((0.10, 1.00), (0.42, 1.00)) + arc(0.42, 0.50, 0.46, 0.50, 90, -90) + line((0.42, 0.0), (0.10, 0.0)),
    ], 0.96)
    g["N"] = ([
        line((0.10, 0.0), (0.10, 1.00)),
        line((0.10, 1.00), (0.80, 0.0)),
        line((0.80, 0.0), (0.80, 1.00)),
    ], 0.98)
    g["G"] = ([
        arc(0.48, 0.50, 0.42, 0.50, 40, 320),
        line((0.90, 0.16), (0.90, 0.48)),
        line((0.58, 0.48), (0.92, 0.48)),
    ], 1.02)
    g["E"] = ([
        line((0.12, 0.0), (0.12, 1.00)),
        line((0.12, 1.00), (0.78, 1.00)),
        line((0.12, 0.52), (0.64, 0.52)),
        line((0.12, 0.0), (0.80, 0.0)),
    ], 0.90)
    g["O"] = ([ellipse(0.48, 0.50, 0.42, 0.50)], 1.02)
    return g


LOWER = _lower()
UPPER = _upper()

# Gate geometry is MEASURED off the 3D study in gate.blend (bounds 2.38 x 3.24 m) and normalised
# to cap height 1.0, rather than eyeballed. Guessing these by hand produced, in order: a gate too
# wide that unbalanced the word, and then one too narrow that shrank the door to a little square.
# The 3D door already has proportions that read; the drawing should inherit them, not re-invent
# them. width 2.38/3.24 = 0.735 | jamb 0.34/3.24 = 0.105 | bowl radius 1.19/3.24 = 0.367.
GATE_ADVANCE = 0.935

# The bowl of the gate is an ELLIPSE, not a circle. A circular bowl grows with the width, and at
# door proportions it eats the straight part of the U until the letter reads as an O. Pinning the
# vertical radius keeps a tall straight jamb no matter how wide the door gets.
GATE_BOWL_RY = 0.367


# --------------------------------------------------------------------------------------------
# The gate: the U of DUNGEON, drawn as an upside-down double door standing open-able.
#
# frame_strokes  -> drawn with the LETTER stroke, identical to every other glyph
# leaf_fill      -> filled polygon in the leaf colour, sits inside the frame
# leaf_detail    -> planks, rails and hardware, drawn in the letter stroke over the fill
# --------------------------------------------------------------------------------------------

def gate_parts(w: float = GATE_ADVANCE) -> tuple[list[Stroke], Stroke, list[Stroke]]:
    x0, x1 = 0.10, w - 0.10          # outer jambs
    t = 0.105                         # frame thickness, i.e. how deep the letter's stroke sits
    ix0, ix1 = x0 + t, x1 - t         # inner opening
    top = 1.00
    cx = (x0 + x1) / 2.0
    rx_out, rx_in = (x1 - x0) / 2.0, (ix1 - ix0) / 2.0
    ry_out = GATE_BOWL_RY
    ry_in = ry_out - t
    cy = ry_out                       # both bowls share a centre; the inner one is inset by t

    def bowl(rx: float, ry: float) -> Stroke:
        return arc(cx, cy, rx, ry, 180, 360)

    # --- frame: one continuous letter-U outline, outer down-around-up plus inner ---------------
    outer = line((x0, top), (x0, cy)) + bowl(rx_out, ry_out) + line((x1, cy), (x1, top))
    inner = line((ix0, top), (ix0, cy)) + bowl(rx_in, ry_in) + line((ix1, cy), (ix1, top))
    frame = [outer, inner]

    # --- fill: the timber, and ONLY over the straight run ---------------------------------------
    # This is the fix that took a 3D study to find. Earlier passes ran the fill down around the
    # bowl, following the inner curve — and timber that curves down into a rounded bottom is the
    # shape of a bucket, which is exactly how the letter kept reading. In a real gate the leaves
    # are RECTANGULAR and the curve belongs to the STONE. So the fill stops at the springing line
    # and the bowl below it stays empty; that empty belly is also where the camera flies through.
    d = 0.055
    fill = [(ix0 + d, top - d), (ix1 - d, top - d), (ix1 - d, cy), (ix0 + d, cy)]

    # --- leaf detail ---------------------------------------------------------------------------
    # Deliberately sparse. The first pass carried plank seams, two rails and eight rivets, and at
    # logo size all of it collapsed into noise that read as texture instead of as a door. What a
    # door actually needs to read is: a centre joint, one band across each leaf, and a pull.
    def leaf_bottom(x: float) -> float:
        dx = (x - cx) / rx_in
        return cy - ry_in * math.sqrt(max(1.0 - dx * dx, 0.0))

    # Everything on the leaves now lives inside the straight rectangle, so horizontal iron bands
    # finally work — the reason they read as a window mullion before was that they crossed the
    # curve. Matches the 3D study: planks + two bands + the centre joint, nothing else.
    z_bot = cy + 0.02          # leaves stop at the springing line
    detail: list[Stroke] = [line((cx, top), (cx, z_bot))]          # where the two leaves meet

    for side in (-1, 1):
        for f in (0.34, 0.68):                                # vertical planks
            detail.append(line((cx + side * rx_in * f, top - 0.02), (cx + side * rx_in * f, z_bot)))

    for y in (top - 0.14, z_bot + 0.14):                            # two iron bands
        detail.append(line((ix0 + 0.06, y), (ix1 - 0.06, y)))

    return frame, fill, detail


# --------------------------------------------------------------------------------------------
# Hand feel. Every stroke is redrawn a few times with a small wandering offset — the same way the
# original sketch was scribbled over. `scribble` scales the wander, `passes` how many redraws.
# --------------------------------------------------------------------------------------------

def hand(stroke: Stroke, rng: random.Random, scribble: float, passes: int, unit: float) -> list[Stroke]:
    out: list[Stroke] = []
    for _ in range(passes):
        amp = scribble * unit
        phase = rng.uniform(0, math.tau)
        freq = rng.uniform(1.2, 2.6)
        bias = (rng.uniform(-amp, amp) * 0.6, rng.uniform(-amp, amp) * 0.6)
        pts: Stroke = []
        n = max(len(stroke) - 1, 1)
        for i, (x, y) in enumerate(stroke):
            t = i / n
            wobble = math.sin(phase + t * math.tau * freq)
            pts.append((
                x + bias[0] + wobble * amp * rng.uniform(0.5, 1.0),
                y + bias[1] + wobble * amp * rng.uniform(0.5, 1.0) * 0.7,
            ))
        out.append(pts)
    return out


# --------------------------------------------------------------------------------------------
# Layout
# --------------------------------------------------------------------------------------------

class Logo:
    def __init__(self, seed: int, scribble: float) -> None:
        self.rng = random.Random(seed)
        self.scribble = scribble
        self.ink: list[tuple[Stroke, float]] = []   # (points, stroke width)
        self.fills: list[Stroke] = []               # leaf polygons, drawn under the ink

    # -- primitives ---------------------------------------------------------------------------

    def stroke(self, pts: Stroke, width: float, messy: float, passes: int) -> None:
        for s in hand(pts, self.rng, self.scribble * messy, passes, width):
            self.ink.append((s, width))

    def word(self, text: str, table: dict, origin: Point, size: float,
             width: float, messy: float, passes: int, tracking: float = 0.14) -> float:
        x, y = origin
        for ch in text:
            if ch == " ":
                x += size * 0.42
                continue
            strokes, adv = table[ch]
            for s in strokes:
                self.stroke(moved(scaled(s, size, size), x, y), width, messy, passes)
            x += size * (adv + tracking)
        return x - origin[0]

    def measure(self, text: str, table: dict, size: float, tracking: float = 0.14) -> float:
        w = 0.0
        for ch in text:
            w += size * 0.42 if ch == " " else size * (table[ch][1] + tracking)
        return w

    # -- the mark -----------------------------------------------------------------------------

    def build(self) -> None:
        cap = 260.0                     # DUNGEON cap height — the unit everything hangs off
        small = cap * 0.30              # x-height of the small lines
        w_big = cap * 0.085             # DUNGEON stroke: heavier, controlled
        w_small = cap * 0.050           # small lines: lighter
        tr_big, tr_small = 0.11, 0.16

        # --- DUNGEON, baseline at y = 0 --------------------------------------------------------
        big_w = (self.measure("D", UPPER, cap, tr_big)
                 + cap * (GATE_ADVANCE + tr_big)
                 + self.measure("NGEON", UPPER, cap, tr_big))
        # DUNGEON is TIDY. The design contract says "trabajado y limpio" and the owner asked for
        # "Dungeon en grande, bonito". An earlier pass gave it the same 0.55 wobble as the small
        # lines and it cost twice: the wordmark lost the modesty-above / craft-below tension that
        # is the whole joke of the title, and once extruded to stone every wobble broke a straight
        # stem into a string of loose pebbles. Tidy strokes stay solid.
        x = 0.0
        x += self._letter("D", x, 0.0, cap, w_big, 0.14, 1, tr_big)
        x += self._gate(x, 0.0, cap, w_big, tr_big)
        self.word("NGEON", UPPER, (x, 0.0), cap, w_big, 0.14, 1, tr_big)

        # --- the two small lines. Lowercase, messier, staggered like the sketch ----------------
        # "Messy" has a ceiling: past it the small line stops being a word. The first pass ran
        # 1.9 wobble over 3 redraws at this size and turned into an unreadable scribble. Small
        # type carries less absolute wobble than large type, not more.
        y_game = cap * 1.34
        y_another = y_game + small * 1.62
        self.word("game of", LOWER, (cap * 0.06, y_game), small, w_small, 0.50, 2, tr_small)
        self.word("another", LOWER, (cap * 0.46, y_another), small, w_small, 0.50, 2, tr_small)

        self.width = big_w
        self.height = y_another + small * 1.9

    def _letter(self, ch: str, x: float, y: float, size: float,
                width: float, messy: float, passes: int, tracking: float) -> float:
        strokes, adv = UPPER[ch]
        for s in strokes:
            self.stroke(moved(scaled(s, size, size), x, y), width, messy, passes)
        return size * (adv + tracking)

    def _gate(self, x: float, y: float, size: float, width: float, tracking: float) -> float:
        # The gate needs breathing room its neighbours don't: it is a wide, busy shape, and butted
        # straight against the D the two silhouettes merge into one blob.
        pad = 0.18
        ox = x + size * pad
        frame, fill, detail = gate_parts()
        self.fills.append(moved(scaled(fill, size, size), ox, y))
        for s in frame:
            self.stroke(moved(scaled(s, size, size), ox, y), width, 0.14, 1)
        # detail[0] is the centre joint and must outweigh the planks. With every vertical drawn at
        # the same weight the gate read as a palisade of identical slats instead of as two leaves
        # meeting — the join is the whole point, since that is the line the door opens along.
        for i, s in enumerate(detail):
            self.stroke(moved(scaled(s, size, size), ox, y),
                        width * (0.90 if i == 0 else 0.38), 0.20, 1)
        return size * (GATE_ADVANCE + pad * 2 + tracking)


# --------------------------------------------------------------------------------------------
# Emitters
# --------------------------------------------------------------------------------------------

PAD = 70.0


def _flip(logo: Logo, pts: Stroke) -> list[tuple[float, float]]:
    return [(x + PAD, logo.height - y + PAD) for x, y in pts]


def emit_svg(logo: Logo, path: Path, ink: str, leaf: str, bg: str | None) -> None:
    w = logo.width + PAD * 2
    h = logo.height + PAD * 2
    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:.1f} {h:.1f}" width="{w:.0f}" height="{h:.0f}">',
        "<title>another game of DUNGEON</title>",
    ]
    if bg:
        out.append(f'<rect width="{w:.1f}" height="{h:.1f}" fill="{bg}"/>')

    for poly in logo.fills:
        pts = " ".join(f"{x:.1f},{y:.1f}" for x, y in _flip(logo, poly))
        out.append(f'<polygon points="{pts}" fill="{leaf}"/>')

    out.append(f'<g fill="none" stroke="{ink}" stroke-linecap="round" stroke-linejoin="round">')
    for pts, width in logo.ink:
        d = " ".join(f"{x:.1f},{y:.1f}" for x, y in _flip(logo, pts))
        out.append(f'<polyline points="{d}" stroke-width="{width:.1f}"/>')
    out.append("</g></svg>")
    path.write_text("\n".join(out), encoding="utf-8")


def emit_png(logo: Logo, path: Path, ink: str, leaf: str, bg: str, supersample: int = 2) -> None:
    from PIL import Image, ImageDraw

    w = int((logo.width + PAD * 2) * supersample)
    h = int((logo.height + PAD * 2) * supersample)
    img = Image.new("RGB", (w, h), bg)
    d = ImageDraw.Draw(img)

    for poly in logo.fills:
        d.polygon([(x * supersample, y * supersample) for x, y in _flip(logo, poly)], fill=leaf)

    for pts, width in logo.ink:
        d.line([(x * supersample, y * supersample) for x, y in _flip(logo, pts)],
               fill=ink, width=max(int(width * supersample), 1), joint="curve")

    img.resize((w // supersample, h // supersample), Image.LANCZOS).save(path)


# --------------------------------------------------------------------------------------------

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", type=int, default=3)
    ap.add_argument("--scribble", type=float, default=1.0, help="hand-wobble multiplier")
    ap.add_argument("--mono", action="store_true", help="shape study: leaves same colour as ink")
    ap.add_argument("--outdir", type=Path, default=Path(__file__).parent / "out")
    args = ap.parse_args()

    # Placeholder palette. Colour is NOT decided yet — see _synthesis.md. Shape first.
    ink = "#191512"
    leaf = ink if args.mono else "#98876f"
    bg = "#f2ece1"

    logo = Logo(args.seed, args.scribble)
    logo.build()

    args.outdir.mkdir(parents=True, exist_ok=True)
    tag = "mono" if args.mono else "colour"
    emit_svg(logo, args.outdir / f"logo_main_{tag}.svg", ink, leaf, bg)
    emit_png(logo, args.outdir / f"logo_main_{tag}.png", ink, leaf, bg)
    print(f"wrote logo_main_{tag}.svg / .png  ({logo.width:.0f} x {logo.height:.0f} design units)")


if __name__ == "__main__":
    main()
