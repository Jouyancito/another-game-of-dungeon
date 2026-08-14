"""split_recording — cut a screen recording into the individual videos it contains.

Joan records references by scrolling a feed, so one recording holds several
clips back to back and the folder-per-reference assumption does not hold. The
descriptions arrive in order, so what is needed is the ordered list of segment
boundaries -- found by measurement, not by eyeballing thumbnails.

Two measurements do it:

  1. WHERE the video is. Most of a screen recording is static chrome: browser,
     taskbar, sidebar. Only the player changes. Per-pixel variance across a
     sample of frames therefore lights up the player and nothing else, and its
     bounding box is the crop. This matters beyond tidiness -- judging a
     reference means looking at the clip, not at the desktop around it.

  2. WHERE the cuts are. Inside that crop, consecutive frames of one clip are
     similar and a scroll to the next clip is not. Mean absolute difference
     between neighbours spikes at each transition.

The threshold is derived from the run's own statistics rather than hardcoded,
because brightness and motion differ per recording; a fixed number would work
on one session and silently mis-cut the next.

    python split_recording.py <sesiones_dir> --out <dir> [--every 2]
"""

import argparse
import glob
import os

import numpy as np
from PIL import Image

SMALL_W = 320          # analysis resolution; full frames are only read to crop


def usable(paths):
    """Drop frames the recorder was still writing when capture stopped.

    A live recording ends mid-file, so the tail decodes as a truncated PNG and
    kills the run on the first read. This is a known trait of the capture tool,
    not a corruption to investigate -- filter once, up front, and report how
    many went.
    """
    ok = []
    for p_ in paths:
        try:
            with Image.open(p_) as im:
                im.verify()
            ok.append(p_)
        except Exception:
            pass
    return ok


def load_gray(path, width=SMALL_W):
    im = Image.open(path).convert("L")
    h = round(im.size[1] * width / im.size[0])
    return np.asarray(im.resize((width, h)), dtype=np.float32)


def player_box(frames, sample=60):
    """Bounding box of the region that actually moves."""
    idx = np.linspace(0, len(frames) - 1, min(sample, len(frames))).astype(int)
    stack = np.stack([load_gray(frames[i]) for i in idx])
    var = stack.var(axis=0)

    # Keep the strongly-varying pixels. A high percentile rather than a fixed
    # value: a mostly-static recording and a busy one have different scales.
    thr = np.percentile(var, 96.0)
    ys, xs = np.where(var >= thr)
    if len(xs) == 0:
        return None, var
    pad = 4
    box = (max(0, xs.min() - pad), max(0, ys.min() - pad),
           min(var.shape[1], xs.max() + pad), min(var.shape[0], ys.max() + pad))
    return box, var


def cut_points(frames, box, every=2):
    """Indices where the cropped region changes abruptly."""
    x0, y0, x1, y1 = box
    prev = None
    diffs = []
    idxs = list(range(0, len(frames), every))
    for i in idxs:
        g = load_gray(frames[i])[y0:y1, x0:x1]
        if prev is not None:
            diffs.append(float(np.abs(g - prev).mean()))
        else:
            diffs.append(0.0)
        prev = g
    d = np.array(diffs)
    if len(d) < 4:
        return [], d, 0.0

    # Median + k*MAD: robust to the long tail of small diffs inside one clip,
    # and scale-free so it transfers between recordings.
    med = np.median(d)
    mad = np.median(np.abs(d - med)) + 1e-6
    thr = med + 6.0 * mad
    peaks = [idxs[i] for i in range(1, len(d)) if d[i] > thr]

    # Collapse peaks that sit within a second of each other: one scroll
    # produces a burst of changed frames, not a single one.
    merged = []
    for p in peaks:
        if not merged or p - merged[-1] > 12:
            merged.append(p)
    return merged, d, thr


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sessions")
    ap.add_argument("--out", required=True)
    ap.add_argument("--every", type=int, default=2)
    args = ap.parse_args()

    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)

    sess = sorted(d for d in os.listdir(args.sessions)
                  if os.path.isdir(os.path.join(args.sessions, d))
                  and not d.startswith("_"))

    seg_no = 0
    report = []
    for s in sess:
        folder = os.path.join(args.sessions, s)
        raw = sorted(glob.glob(os.path.join(folder, "*.png")) +
                     glob.glob(os.path.join(folder, "*.jpg")))
        frames = usable(raw)
        if len(frames) != len(raw):
            print("  %s: %d frames truncados descartados" % (s, len(raw) - len(frames)))
        if not frames:
            continue

        box, _var = player_box(frames)
        if box is None:
            print("  %s: sin region variable — se omite" % s)
            continue
        x0, y0, x1, y1 = box
        print("\n%s  %d frames  |  region %dx%d en analisis %dpx"
              % (s, len(frames), x1 - x0, y1 - y0, SMALL_W))

        cuts, d, thr = cut_points(frames, box, args.every)
        bounds = [0] + cuts + [len(frames)]
        print("  cortes detectados: %d  (umbral %.2f, diff max %.2f)"
              % (len(cuts), thr, d.max() if len(d) else 0))

        # Scale the analysis box back to full resolution for the crop.
        full = Image.open(frames[0])
        k = full.size[0] / float(SMALL_W)
        fx0, fy0, fx1, fy1 = (int(x0 * k), int(y0 * k), int(x1 * k), int(y1 * k))

        for a, b in zip(bounds, bounds[1:]):
            if b - a < 25:          # too short to be a real clip
                continue
            seg_no += 1
            picks = [frames[a + int(i * (b - a - 1) / 4.0)] for i in range(5)]
            sheet = None
            for j, p in enumerate(picks):
                im = Image.open(p).convert("RGB").crop((fx0, fy0, fx1, fy1))
                im.thumbnail((280, 460))
                if sheet is None:
                    sheet = Image.new("RGB", (im.size[0] * 5, im.size[1]), (14, 14, 16))
                sheet.paste(im, (j * im.size[0], 0))
            name = "seg%02d_%s_%05d-%05d.jpg" % (seg_no, s.replace("2026-08-13_", ""), a, b)
            sheet.save(os.path.join(out, name), "JPEG", quality=80)
            report.append((seg_no, s, a, b, b - a, name))
            print("    seg %02d  frames %5d-%5d  (%d)" % (seg_no, a, b, b - a))

    print("\n=== %d segmentos ===" % len(report))
    for n, s, a, b, c, name in report:
        print("  %02d  %s  %5d..%5d  %4d frames" % (n, s, a, b, c))
    print("\n  hojas de contacto -> %s" % out)


if __name__ == "__main__":
    main()
