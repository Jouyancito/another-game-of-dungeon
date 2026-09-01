"""compare_to_ref -- put our face beside a reference at the SAME eye scale.

Why this exists: the brow was placed on the supraorbital arch by ANATOMICAL
REASONING -- 20.7 mm above the eye centre, measured on our mesh, with a control
asserting it cleared the globe. Joan pushed back on exactly the right thing:
the reasoning was never checked against an image. Deducing where a feature
belongs and verifying where it actually sits are different acts, and only the
second one is evidence.

A face cannot be compared to a photo at arbitrary scale, so both are normalised
on the ONE landmark that is unambiguous in any frontal view: the distance
between the two pupils. Scale both to the same interpupillary distance and
every other proportion becomes directly comparable by eye and by pixel.

Usage:
    python compare_to_ref.py our_render.png ref.jpg out.png \
        --our-eyes X1 Y1 X2 Y2 --ref-eyes X1 Y1 X2 Y2

The four numbers per image are the pixel centres of the left and right pupils,
read off the image. They are inputs BECAUSE eye detection would be one more
instrument capable of failing quietly, and this file exists to stop trusting
unverified machinery.
"""
from __future__ import annotations

import argparse
import math

from PIL import Image, ImageDraw


def eye_span(pts) -> float:
    (x1, y1, x2, y2) = pts
    return math.hypot(x2 - x1, y2 - y1)


def normalise(img: Image.Image, pts, target_span: float, out_size):
    """Scale and translate so the pupils sit `target_span` apart, centred."""
    span = eye_span(pts)
    if span < 1.0:
        raise SystemExit("pupil span of %.1f px is too small to normalise"
                         % span)
    k = target_span / span
    w, h = img.size
    img = img.resize((max(1, int(w * k)), max(1, int(h * k))), Image.LANCZOS)

    cx = (pts[0] + pts[2]) / 2.0 * k
    cy = (pts[1] + pts[3]) / 2.0 * k
    ow, oh = out_size
    canvas = Image.new("RGB", out_size, (24, 25, 30))
    canvas.paste(img, (int(ow / 2 - cx), int(oh * 0.42 - cy)))
    return canvas


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ours")
    ap.add_argument("ref")
    ap.add_argument("out")
    ap.add_argument("--our-eyes", nargs=4, type=float, required=True)
    ap.add_argument("--ref-eyes", nargs=4, type=float, required=True)
    ap.add_argument("--span", type=float, default=190.0)
    ap.add_argument("--size", nargs=2, type=int, default=[440, 440])
    args = ap.parse_args()

    size = tuple(args.size)
    a = normalise(Image.open(args.ours).convert("RGB"), args.our_eyes,
                  args.span, size)
    b = normalise(Image.open(args.ref).convert("RGB"), args.ref_eyes,
                  args.span, size)

    out = Image.new("RGB", (size[0] * 2, size[1]), (24, 25, 30))
    out.paste(a, (0, 0))
    out.paste(b, (size[0], 0))

    # Rulers through the pupil line and at fixed fractions of the eye span
    # above it, so "how far above the eye is the brow" is readable as a number
    # of eye-spans instead of an impression.
    d = ImageDraw.Draw(out)
    eye_y = int(size[1] * 0.42)
    for frac, colour in ((0.0, (255, 90, 90)), (0.10, (90, 200, 255)),
                         (0.18, (255, 220, 90)), (0.26, (150, 255, 150))):
        y = eye_y - int(args.span * frac)
        d.line([(0, y), (out.width, y)], fill=colour, width=1)
        d.text((4, y + 2), "%+.2f" % frac, fill=colour)
    d.line([(size[0], 0), (size[0], size[1])], fill=(90, 90, 100), width=2)
    d.text((8, 8), "OURS", fill=(230, 230, 230))
    d.text((size[0] + 8, 8), "REF", fill=(230, 230, 230))

    out.save(args.out, "PNG")
    print("wrote %s  (pupil span normalised to %.0f px)"
          % (args.out, args.span))


if __name__ == "__main__":
    main()
