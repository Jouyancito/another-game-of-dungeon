"""measure_ref_body — turn a character reference image into a numeric TARGET_SPEC.

Phase 0 of VISUAL_READING_PROTOCOL, which the inventory records as written but
never executed. Without it every "the proportions look right" is an opinion,
and the protocol's whole point is that an opinion is not a verdict.

Method: isolate the figure as a binary mask, then read the per-row width
profile. Landmarks come out of the profile's own structure -- the crotch is
where the mask splits into two runs, the shoulder is the widest row in the
upper fifth -- so they are found, not assumed.

Two honest limits, stated up front rather than buried:
  * A held weapon or a cape joins the silhouette. Only the largest connected
    component is kept, and anything that touches the body (an axe held against
    the leg) survives that filter. Columns are reported so a bad one is visible.
  * Clothing occludes. A belt or loincloth reads as "waist". Any measurement
    crossing fabric is flagged rather than presented as anatomy.

    python measure_ref_body.py <image> [--out spec.json] [--flip]
"""

import argparse
import json
import os
import sys

import numpy as np
from PIL import Image


def silhouette(path, bg_tol=28):
    """Binary mask of the figure. Background is sampled from the corners so a
    white studio plate and a dark one both work without a flag."""
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(np.int16)
    h, w, _ = a.shape

    corners = np.array([a[0, 0], a[0, w - 1], a[h - 1, 0], a[h - 1, w - 1]])
    bg = np.median(corners, axis=0)
    mask = (np.abs(a - bg).sum(axis=2) > bg_tol)

    # Keep the largest connected blob: drops logos, captions, drop shadows.
    lab = np.zeros((h, w), dtype=np.int32)
    cur = 0
    best, best_n = 0, 0
    for y in range(h):
        for x in range(w):
            if not mask[y, x] or lab[y, x]:
                continue
            cur += 1
            n = 0
            stack = [(y, x)]
            lab[y, x] = cur
            while stack:
                cy, cx = stack.pop()
                n += 1
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ny, nx = cy + dy, cx + dx
                    if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not lab[ny, nx]:
                        lab[ny, nx] = cur
                        stack.append((ny, nx))
            if n > best_n:
                best, best_n = cur, n
    return lab == best


def runs(row, min_len=3):
    """Contiguous True spans in a row, as (start, end) pairs."""
    out = []
    s = None
    for i, v in enumerate(row):
        if v and s is None:
            s = i
        elif not v and s is not None:
            if i - s >= min_len:
                out.append((s, i))
            s = None
    if s is not None and len(row) - s >= min_len:
        out.append((s, len(row)))
    return out


def find_landmarks(mask):
    h, w = mask.shape
    ys = np.where(mask.any(axis=1))[0]
    top, bot = int(ys[0]), int(ys[-1])
    height = bot - top + 1

    def frac(y):
        """Height above the ground as a fraction of total, 0 at the feet."""
        return (bot - y) / float(height)

    # Torso column: the horizontal band the body occupies at mid-height,
    # used to reject a held weapon that hangs clear of the body.
    mid = mask[(top + bot) // 2]
    mid_runs = runs(mid)
    body_run = max(mid_runs, key=lambda r: r[1] - r[0]) if mid_runs else (0, w)
    cx = (body_run[0] + body_run[1]) // 2

    def body_width(y, allow_split=False):
        """Width of the run(s) containing the body centreline at row y."""
        rs = runs(mask[y])
        if not rs:
            return 0, None
        hit = [r for r in rs if r[0] <= cx < r[1]]
        if hit:
            return hit[0][1] - hit[0][0], hit[0]
        if allow_split:
            near = min(rs, key=lambda r: abs((r[0] + r[1]) / 2 - cx))
            return near[1] - near[0], near
        return 0, None

    # Crotch: highest row where the legs read as two separate runs near the
    # centreline, scanning from mid-body downward.
    crotch = None
    for y in range((top + bot) // 2, bot):
        rs = [r for r in runs(mask[y]) if abs((r[0] + r[1]) / 2 - cx) < w * 0.22]
        if len(rs) >= 2:
            crotch = y
            break

    # Shoulder: widest body row in the upper 30%, skipping the very top
    # (the head) so a helmet crest cannot win.
    lo = top + int(height * 0.10)
    hi = top + int(height * 0.32)
    sh_y, sh_w = lo, 0
    for y in range(lo, hi):
        bw, _ = body_width(y)
        if bw > sh_w:
            sh_y, sh_w = y, bw

    # Waist: narrowest body row between the shoulder and the crotch.
    wl = sh_y + int(height * 0.08)
    wh = crotch if crotch else top + int(height * 0.55)
    wa_y, wa_w = wl, 10 ** 9
    for y in range(wl, max(wl + 1, wh)):
        bw, _ = body_width(y)
        if 0 < bw < wa_w:
            wa_y, wa_w = y, bw

    # Chest: widest body row between shoulder and waist.
    ch_y, ch_w = sh_y, 0
    for y in range(sh_y, max(sh_y + 1, wa_y)):
        bw, _ = body_width(y)
        if bw > ch_w:
            ch_y, ch_w = y, bw

    return {
        "height_px": height,
        "top_px": top,
        "bottom_px": bot,
        "centre_x": cx,
        "shoulder": {"y": sh_y, "w": sh_w, "frac": frac(sh_y)},
        "chest": {"y": ch_y, "w": ch_w, "frac": frac(ch_y)},
        "waist": {"y": wa_y, "w": wa_w, "frac": frac(wa_y)},
        "crotch": {"y": crotch, "frac": frac(crotch) if crotch else None},
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--out", default=None)
    ap.add_argument("--player-h", type=float, default=1.80)
    args = ap.parse_args()

    mask = silhouette(args.image)
    lm = find_landmarks(mask)

    H = lm["height_px"]
    k = args.player_h / H          # metres per pixel, if the figure IS 1.80 m
    name = os.path.basename(args.image)

    print("\n=== TARGET_SPEC — %s ===" % name)
    print("  figura        %d px de alto  (escala %.5f m/px si mide %.2f m)"
          % (H, k, args.player_h))
    print("\n  %-10s %8s %10s %10s" % ("rasgo", "px", "metros", "frac alt."))
    for key in ("shoulder", "chest", "waist"):
        d = lm[key]
        print("  %-10s %8d %10.3f %10.3f" % (key, d["w"], d["w"] * k, d["frac"]))
    if lm["crotch"]["y"]:
        print("  %-10s %8s %10s %10.3f" % ("crotch", "-", "-", lm["crotch"]["frac"]))

    ch, wa = lm["chest"]["w"], lm["waist"]["w"]
    ratio = wa / ch if ch else 0.0
    print("\n  cintura/pecho  %.3f" % ratio)
    print("  lectura        %s" % ("barril / strongman" if ratio >= 0.84
                                   else "taper — revisar si es ropa o cuerpo"))
    print("\n  AVISO: toda medida que cruce ropa (cinturón, faldón, hombreras)")
    print("         es de la SILUETA VESTIDA, no del cuerpo desnudo.")

    spec = {"source": name, "player_h": args.player_h, "m_per_px": k,
            "landmarks": lm, "waist_chest": ratio}
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            json.dump(spec, f, indent=2)
        print("\n  spec -> %s" % args.out)
    return spec


if __name__ == "__main__":
    main()
