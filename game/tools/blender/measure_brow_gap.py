"""measure_brow_gap -- the eye-to-brow gap, read off pixels, not off my eye.

THE RULE THIS MEASURES, taken from Skyrim reference 01_skyrim_pair_closeup:

    eye aperture height       ~75 px
    upper lid -> brow bottom  ~55 px   = 0.73 of the aperture
    brow height               ~55 px   = 0.73 of the aperture

So the gap between lid and brow is about three quarters of the eye's own
height. That ratio lives INSIDE one face, which is why it is trustworthy in a
way my earlier Farkas reading was not: that one required me to place two pupils
by eye on a small image where the brow is a smudge, and it put the brow 5 mm
too LOW -- after an earlier pass had it too HIGH. Twice wrong by eyeballing.

Here nothing is eyeballed. Our render paints the sclera #C9BCAE and the brow
#231A14, so both are found by colour:

    lid_top   = highest row containing sclera pixels
    lid_bot   = lowest row containing sclera pixels
    brow_bot  = lowest row containing brow pixels above the lid
    gap       = lid_top - brow_bot
    ratio     = gap / (lid_bot - lid_top)

Target: 0.73, from the reference above.

    python measure_brow_gap.py render.png
"""
from __future__ import annotations

import argparse
import sys

import numpy as np
from PIL import Image

TARGET_RATIO = 0.73

# Sampled from what the generators write, converted to 0-255 sRGB.
SCLERA = (201, 188, 174)
BROW = (35, 26, 20)
TOL_SCLERA = 34
# 26 was too loose: the lid line painted at #3A2A20 sits 23 away from the brow
# colour, so the detector counted the lid line AS brow and the gap read 1 px no
# matter what the brow did. Thinning the brow to a third moved the number by
# 9 px, which is what exposed it.
TOL_BROW = 12


def mask_near(arr, rgb, tol):
    d = np.abs(arr.astype(np.int16) - np.array(rgb, dtype=np.int16))
    return (d.max(axis=2) <= tol)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--half", choices=["left", "right", "both"],
                    default="left",
                    help="which half of the image to measure")
    args = ap.parse_args()

    im = Image.open(args.image).convert("RGB")
    arr = np.array(im)
    h, w = arr.shape[:2]
    if args.half == "left":
        arr = arr[:, : w // 2]
    elif args.half == "right":
        arr = arr[:, w // 2:]

    sclera = mask_near(arr, SCLERA, TOL_SCLERA)
    brow = mask_near(arr, BROW, TOL_BROW)

    # CONTROL: both features must actually be found. A missing one would make
    # the ratio nonsense rather than raise, which is the failure mode that has
    # burned this session repeatedly.
    if sclera.sum() < 30:
        raise SystemExit("only %d sclera px found -- wrong colours or wrong"
                         " crop, the ratio would be meaningless"
                         % int(sclera.sum()))
    if brow.sum() < 30:
        raise SystemExit("only %d brow px found -- wrong colours or the brow"
                         " is not painted" % int(brow.sum()))

    rows_s = np.where(sclera.any(axis=1))[0]
    lid_top, lid_bot = int(rows_s.min()), int(rows_s.max())
    aperture = lid_bot - lid_top

    rows_b = np.where(brow.any(axis=1))[0]
    above = rows_b[rows_b < lid_top]
    if len(above) == 0:
        raise SystemExit("no brow pixels ABOVE the eye -- the brow is level"
                         " with or below the lid")
    brow_bot, brow_top = int(above.max()), int(above.min())
    gap = lid_top - brow_bot
    ratio = gap / max(aperture, 1)

    print("")
    print("  sclera rows %d..%d   aperture %d px" % (lid_top, lid_bot,
                                                     aperture))
    print("  brow rows   %d..%d   height   %d px" % (brow_top, brow_bot,
                                                     brow_bot - brow_top))
    print("  gap lid->brow          %d px" % gap)
    print("")
    print("  RATIO gap/aperture  %.2f      target %.2f (Skyrim ref)"
          % (ratio, TARGET_RATIO))
    print("  RATIO browh/aperture %.2f     target %.2f"
          % ((brow_bot - brow_top) / max(aperture, 1), TARGET_RATIO))
    if ratio < TARGET_RATIO * 0.6:
        print("  -> BROW SITS ON THE LID. Raise it by about %d px"
              % int(TARGET_RATIO * aperture - gap))
    elif ratio > TARGET_RATIO * 1.5:
        print("  -> brow too high, floating away from the eye")
    else:
        print("  -> in range")
    return ratio


if __name__ == "__main__":
    main()
