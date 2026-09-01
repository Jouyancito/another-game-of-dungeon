"""measure_eye_canon -- how many eyes wide is the face, measured not assumed.

The classical drawing canon says a face is FIVE eyes wide. Measured on the
Skyrim reference (01_skyrim_pair_closeup, male), it is about 3.4 -- so that
game's eyes are nearly 50% larger in proportion than the academic ideal. That
is not their mistake, it is a legibility decision: eyes are the focal point and
they vanish at gameplay distance.

Which means "24 mm because a real eyeball is 24 mm" was the wrong target. Our
reference is Skyrim, not an anatomy atlas, and Joan said so before I measured
it: "una cosa que sean ciertos milimetros realmente en la realidad, pero otra
que sean acorde al personaje".

Both numbers here come from pixels, not from placing landmarks by eye:

    face width  = silhouette against the background, on the pupil row
    eye width   = horizontal extent of sclera-coloured pixels

Doing it by colour matters. Every hand-placed landmark this session has been
wrong at least once, and the errors were invisible because the resulting
numbers looked reasonable.

    python measure_eye_canon.py render.png --bg 8 8 10
"""
from __future__ import annotations

import argparse

import numpy as np
from PIL import Image

SCLERA = (201, 188, 174)
IRIS = (74, 50, 32)
PUPIL = (16, 12, 9)
TOL_SCLERA = 34
TOL_IRIS = 22

SKYRIM_RATIO = 3.4       # measured on the reference
ACADEMIC_RATIO = 5.0     # the classical canon


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--bg", nargs=3, type=int, default=[8, 8, 10],
                    help="background RGB of the render")
    ap.add_argument("--bg-tol", type=int, default=26)
    args = ap.parse_args()

    arr = np.array(Image.open(args.image).convert("RGB")).astype(np.int16)
    h, w = arr.shape[:2]

    # Background is SAMPLED from the corners, never passed in. The value that
    # goes into the world shader is linear and the view transform (Filmic/AgX)
    # remaps it, so any hand-supplied RGB is wrong by construction -- which is
    # what made the frame-edge guard fire on a render that had plenty of margin.
    corners = np.concatenate([arr[:6, :6].reshape(-1, 3),
                              arr[:6, -6:].reshape(-1, 3),
                              arr[-6:, :6].reshape(-1, 3),
                              arr[-6:, -6:].reshape(-1, 3)])
    bg_rgb = np.median(corners, axis=0)
    bg = np.abs(arr - bg_rgb).max(axis=2) <= args.bg_tol
    subject = ~bg
    print("  background sampled from corners: %s" % bg_rgb.astype(int))
    if subject.sum() < 500:
        raise SystemExit("only %d non-background px -- wrong --bg colour?"
                         % int(subject.sum()))

    def near(rgb, tol):
        return np.abs(arr - np.array(rgb, dtype=np.int16)).max(axis=2) <= tol

    # The APERTURE is sclera + iris + pupil. Counting sclera alone measures two
    # slivers either side of the iris: it returned a 34 px eye and produced
    # "24 eyes wide". The reference was measured corner to corner, so this has
    # to match that.
    sclera = near(SCLERA, TOL_SCLERA)
    eye = sclera | near(IRIS, TOL_IRIS) | near(PUPIL, TOL_IRIS)
    if sclera.sum() < 30:
        raise SystemExit("only %d sclera px -- the eyes are not visible or the"
                         " colour differs" % int(sclera.sum()))

    rows = np.where(sclera.any(axis=1))[0]
    pupil_row = int(rows.mean())

    # Face width on the pupil row: the silhouette against the background.
    cols = np.where(subject[pupil_row])[0]
    face_w = int(cols.max() - cols.min())
    # CONTROL: if the head touches both frame edges the silhouette IS the
    # frame, and face_w is the image width rather than the face. That is how
    # this returned "24 eyes wide" once.
    if cols.min() <= 1 or cols.max() >= w - 2:
        raise SystemExit(
            "the head reaches the frame edge (cols %d..%d of %d) -- face width"
            " would be the image width. Re-render with the whole head inside"
            " the frame." % (int(cols.min()), int(cols.max()), w))

    # One eye's width: the sclera runs as two blobs, so split at the midpoint
    # between them and take the left one.
    #
    # RESTRICTED TO THE SCLERA ROWS. The pupil colour (16,12,9) at tolerance 22
    # also matches the brow (35,26,20), so searching the whole image counted
    # brow pixels as eye, the first gap fell inside that mass, and the "eye"
    # came out 14 px wide. The sclera is the one colour on this face nothing
    # else shares, so it defines where to look.
    band = np.zeros_like(eye)
    rows_s = np.where(sclera.any(axis=1))[0]
    band[rows_s.min():rows_s.max() + 1, :] = True
    eye = eye & band
    scols = np.where(eye.any(axis=0))[0]
    gaps = np.where(np.diff(scols) > 10)[0]
    if len(gaps) == 0:
        raise SystemExit("could not separate the two eyes -- they merge, so"
                         " an eye width cannot be taken")
    split = scols[gaps[0]]
    left = scols[scols <= split]
    eye_w = int(left.max() - left.min())
    if eye_w < 4:
        raise SystemExit("eye width %d px is too small to trust" % eye_w)

    ratio = face_w / eye_w
    # CONTROL: any real face lands between 3 and 6 eyes wide. Outside that the
    # measurement is broken, not the model.
    if not (2.5 <= ratio <= 7.0):
        raise SystemExit(
            "ratio %.2f is outside any plausible face (2.5..7.0). face_w=%d"
            " eye_w=%d -- the probe is wrong, not the mesh."
            % (ratio, face_w, eye_w))
    print("")
    print("  pupil row %d   face width %d px   eye width %d px"
          % (pupil_row, face_w, eye_w))
    print("")
    print("  FACE IS %.2f EYES WIDE" % ratio)
    print("    academic canon  %.2f  (eyes at their smallest)" % ACADEMIC_RATIO)
    print("    Skyrim measured %.2f  (our actual reference)" % SKYRIM_RATIO)
    if ratio > SKYRIM_RATIO * 1.12:
        need = ratio / SKYRIM_RATIO
        print("  -> our eyes are SMALLER than Skyrim's by %.0f%%."
              " Scale them up ~%.2fx to match." % ((need - 1) * 100, need))
    elif ratio < SKYRIM_RATIO * 0.88:
        print("  -> our eyes are LARGER than Skyrim's.")
    else:
        print("  -> in line with the reference.")


if __name__ == "__main__":
    main()
