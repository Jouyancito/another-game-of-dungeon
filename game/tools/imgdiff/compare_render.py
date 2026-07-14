#!/usr/bin/env python3
"""
compare_render.py — quantitative render-vs-target image comparison (Tier-0 scaffold).

Implements the local, CPU-only metric panel from
game/docs/_tooling/image_comparison_rigor.md:

  align (ECC/bbox) -> silhouette IoU + matchShapes + bbox-aspect
                   -> per-zone CIEDE2000 palette delta
                   -> SSIM scalar + heatmap
                   -> L-channel histogram tripwire
                   -> grounding overlay board (PNG)
                   -> metric JSON

It does NOT judge. It produces grounded numbers + an overlay so the eye
(or Claude) scores the fixed rubric without hallucinating. A broken hand can
still score great here — these metrics quantify the nameable axes only.

Optional Tier-1 DISTS (texture/material) runs if `pyiqa` + torch are present;
otherwise it is skipped and reported as null. Keep the heavy deps in a
SEPARATE `critic` env — never the UniRig env.

Usage:
    python compare_render.py --render render.png --target target.png --out ./out
    python compare_render.py -r a.png -t b.png -o ./out --bg auto --align ecc

Tier-0 deps: numpy, opencv-python, scikit-image, scikit-learn
Tier-1 (optional): pyiqa (pulls torch)
"""

from __future__ import annotations

import argparse
import json
import os
import sys

import numpy as np
import cv2
from skimage.color import rgb2lab, deltaE_ciede2000
from skimage.metrics import structural_similarity
from sklearn.cluster import KMeans


# --------------------------------------------------------------------------- #
# IO + masking
# --------------------------------------------------------------------------- #
def load_rgba(path: str) -> np.ndarray:
    """Load an image as float RGBA in [0,1]. Adds an opaque alpha if absent."""
    img = cv2.imread(path, cv2.IMREAD_UNCHANGED)
    if img is None:
        raise FileNotFoundError(f"cannot read image: {path}")
    if img.ndim == 2:  # grayscale
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    if img.shape[2] == 3:
        a = np.full(img.shape[:2], 255, dtype=img.dtype)
        img = np.dstack([img, a])
    # BGRA -> RGBA, normalize
    rgba = img[:, :, [2, 1, 0, 3]].astype(np.float32) / 255.0
    return rgba


def foreground_mask(rgba: np.ndarray, bg: str = "auto", tol: float = 0.10) -> np.ndarray:
    """Boolean foreground mask.

    bg='alpha' : use the alpha channel (needs a real alpha, e.g. film_transparent).
    bg='white'/'black' : threshold against that background colour.
    bg='auto'  : if alpha is non-trivial use it, else estimate bg from the 4 corners.
    bg='none'  : everything is foreground.
    """
    h, w = rgba.shape[:2]
    alpha = rgba[:, :, 3]

    if bg == "none":
        return np.ones((h, w), dtype=bool)
    if bg == "alpha" or (bg == "auto" and alpha.min() < 0.95):
        return alpha > 0.5

    rgb = rgba[:, :, :3]
    if bg == "white":
        bg_col = np.array([1.0, 1.0, 1.0])
    elif bg == "black":
        bg_col = np.array([0.0, 0.0, 0.0])
    else:  # auto: median of the 4 corner patches
        k = max(4, min(h, w) // 50)
        corners = np.concatenate([
            rgb[:k, :k].reshape(-1, 3), rgb[:k, -k:].reshape(-1, 3),
            rgb[-k:, :k].reshape(-1, 3), rgb[-k:, -k:].reshape(-1, 3),
        ])
        bg_col = np.median(corners, axis=0)

    dist = np.linalg.norm(rgb - bg_col, axis=2)
    mask = dist > tol
    # clean specks / holes
    mask = mask.astype(np.uint8)
    kernel = np.ones((3, 3), np.uint8)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
    return mask.astype(bool)


def bbox_of(mask: np.ndarray):
    ys, xs = np.where(mask)
    if len(xs) == 0:
        return None
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1  # x0,y0,x1,y1


# --------------------------------------------------------------------------- #
# Alignment — the linchpin. Garbage-in for every metric without it.
# --------------------------------------------------------------------------- #
def align(render: np.ndarray, target: np.ndarray,
          rmask: np.ndarray, tmask: np.ndarray, mode: str):
    """Warp `render` onto `target`'s frame. Returns (render_aligned, rmask_aligned)."""
    h, w = target.shape[:2]
    if mode == "none":
        out = cv2.resize(render, (w, h), interpolation=cv2.INTER_AREA)
        outm = cv2.resize(rmask.astype(np.uint8), (w, h), interpolation=cv2.INTER_NEAREST)
        return out, outm.astype(bool)

    # bbox pre-center: translate+scale render's silhouette bbox onto target's.
    rb, tb = bbox_of(rmask), bbox_of(tmask)
    M = np.eye(2, 3, dtype=np.float32)
    if rb and tb:
        rcx, rcy = (rb[0] + rb[2]) / 2, (rb[1] + rb[3]) / 2
        tcx, tcy = (tb[0] + tb[2]) / 2, (tb[1] + tb[3]) / 2
        rw_, rh_ = rb[2] - rb[0], rb[3] - rb[1]
        tw_, th_ = tb[2] - tb[0], tb[3] - tb[1]
        s = min(tw_ / max(rw_, 1), th_ / max(rh_, 1))
        M = np.array([[s, 0, tcx - s * rcx], [0, s, tcy - s * rcy]], dtype=np.float32)

    render_pc = cv2.warpAffine(render, M, (w, h), flags=cv2.INTER_AREA)
    rmask_pc = cv2.warpAffine(rmask.astype(np.uint8), M, (w, h),
                              flags=cv2.INTER_NEAREST).astype(bool)

    if mode == "bbox":
        return render_pc, rmask_pc

    # ECC affine refine on grayscale (after pre-center, or it diverges).
    g_t = cv2.cvtColor((target[:, :, :3] * 255).astype(np.uint8), cv2.COLOR_RGB2GRAY)
    g_r = cv2.cvtColor((render_pc[:, :, :3] * 255).astype(np.uint8), cv2.COLOR_RGB2GRAY)
    warp = np.eye(2, 3, dtype=np.float32)
    crit = (cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 200, 1e-5)
    try:
        _, warp = cv2.findTransformECC(g_t, g_r, warp, cv2.MOTION_AFFINE, crit, None, 5)
        render_a = cv2.warpAffine(render_pc, warp, (w, h),
                                  flags=cv2.INTER_AREA + cv2.WARP_INVERSE_MAP)
        rmask_a = cv2.warpAffine(rmask_pc.astype(np.uint8), warp, (w, h),
                                 flags=cv2.INTER_NEAREST + cv2.WARP_INVERSE_MAP).astype(bool)
        return render_a, rmask_a
    except cv2.error:
        # ECC failed to converge (common on flat toon) — fall back to bbox.
        return render_pc, rmask_pc


# --------------------------------------------------------------------------- #
# Metrics
# --------------------------------------------------------------------------- #
def silhouette_metrics(rmask: np.ndarray, tmask: np.ndarray) -> dict:
    inter = np.logical_and(rmask, tmask).sum()
    union = np.logical_or(rmask, tmask).sum()
    iou = float(inter / union) if union else 0.0

    def biggest_contour(m):
        cs, _ = cv2.findContours(m.astype(np.uint8), cv2.RETR_EXTERNAL,
                                 cv2.CHAIN_APPROX_SIMPLE)
        return max(cs, key=cv2.contourArea) if cs else None

    rc, tc = biggest_contour(rmask), biggest_contour(tmask)
    match = (float(cv2.matchShapes(rc, tc, cv2.CONTOURS_MATCH_I1, 0.0))
             if rc is not None and tc is not None else None)

    def aspect(m):
        b = bbox_of(m)
        return (b[2] - b[0]) / max(b[3] - b[1], 1) if b else None

    ra, ta = aspect(rmask), aspect(tmask)
    aspect_err = abs(ra - ta) / max(ta, 1e-6) if (ra and ta) else None
    return {"iou": iou, "match_shapes_I1": match, "bbox_aspect_err": aspect_err}


def palette_delta(render: np.ndarray, target: np.ndarray,
                  rmask: np.ndarray, tmask: np.ndarray, k: int = 5) -> dict:
    """KMeans centroids in LAB, greedy-matched, mean CIEDE2000."""
    def centroids(rgb, mask):
        px = rgb[mask]
        if len(px) < k:
            return None
        lab = rgb2lab(px.reshape(-1, 1, 3)).reshape(-1, 3)
        km = KMeans(n_clusters=k, n_init=4, random_state=0).fit(lab)
        sizes = np.bincount(km.labels_, minlength=k)
        order = np.argsort(-sizes)
        return km.cluster_centers_[order], sizes[order] / sizes.sum()

    rcen = centroids(render[:, :, :3], rmask)
    tcen = centroids(target[:, :, :3], tmask)
    if rcen is None or tcen is None:
        return {"mean_ciede2000": None, "max_ciede2000": None, "per_zone": []}

    rc, rw = rcen
    tc, tw = tcen
    used, pairs = set(), []
    for i in range(len(tc)):
        best, bj = 1e9, -1
        for j in range(len(rc)):
            if j in used:
                continue
            d = float(deltaE_ciede2000(tc[i:i + 1], rc[j:j + 1])[0])
            if d < best:
                best, bj = d, j
        used.add(bj)
        pairs.append({"target_weight": float(tw[i]), "delta_e": best})
    des = [p["delta_e"] for p in pairs]
    return {"mean_ciede2000": float(np.mean(des)),
            "max_ciede2000": float(np.max(des)),
            "per_zone": pairs}


def ssim_metrics(render: np.ndarray, target: np.ndarray):
    g_r = cv2.cvtColor((render[:, :, :3] * 255).astype(np.uint8), cv2.COLOR_RGB2GRAY)
    g_t = cv2.cvtColor((target[:, :, :3] * 255).astype(np.uint8), cv2.COLOR_RGB2GRAY)
    score, smap = structural_similarity(g_t, g_r, full=True)
    return float(score), smap


def value_histogram_corr(render: np.ndarray, target: np.ndarray,
                         rmask: np.ndarray, tmask: np.ndarray) -> float:
    """L-channel histogram correlation — a global exposure/value tripwire only."""
    def lhist(rgb, mask):
        lab = rgb2lab(rgb.astype(np.float32))
        L = lab[:, :, 0][mask]
        h, _ = np.histogram(L, bins=32, range=(0, 100), density=True)
        return h.astype(np.float32)
    hr, ht = lhist(render[:, :, :3], rmask), lhist(target[:, :, :3], tmask)
    return float(cv2.compareHist(ht, hr, cv2.HISTCMP_CORREL))


def try_dists(render_path: str, target_path: str):
    """Tier-1 DISTS (material/value) if pyiqa+torch are installed; else None."""
    try:
        import torch
        import pyiqa
    except Exception:
        return None
    try:
        dev = "cuda" if torch.cuda.is_available() else "cpu"
        metric = pyiqa.create_metric("dists", device=dev)

        def load(p):
            im = cv2.imread(p, cv2.IMREAD_COLOR)
            im = cv2.cvtColor(im, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0
            return torch.from_numpy(im).permute(2, 0, 1).unsqueeze(0).to(dev)

        r, t = load(render_path), load(target_path)
        h = min(r.shape[2], t.shape[2])
        w = min(r.shape[3], t.shape[3])
        r = torch.nn.functional.interpolate(r, size=(h, w))
        t = torch.nn.functional.interpolate(t, size=(h, w))
        return float(metric(r, t).item())
    except Exception as e:  # noqa: BLE001
        return f"error: {e}"


# --------------------------------------------------------------------------- #
# Overlay board — the anti-hallucination grounding image
# --------------------------------------------------------------------------- #
def label(img: np.ndarray, text: str) -> np.ndarray:
    out = img.copy()
    cv2.rectangle(out, (0, 0), (out.shape[1], 22), (0, 0, 0), -1)
    cv2.putText(out, text, (6, 16), cv2.FONT_HERSHEY_SIMPLEX, 0.5,
                (255, 255, 255), 1, cv2.LINE_AA)
    return out


def to_bgr(rgba: np.ndarray) -> np.ndarray:
    return cv2.cvtColor((rgba[:, :, :3] * 255).astype(np.uint8), cv2.COLOR_RGB2BGR)


def build_overlay(target, render_a, tmask, rmask_a, smap, palette, out_path):
    h, w = target.shape[:2]
    tgt = label(to_bgr(target), "TARGET")
    rnd = label(to_bgr(render_a), "RENDER (aligned)")

    # IoU overlay: target=green, render=red, overlap=yellow
    iou_img = np.zeros((h, w, 3), np.uint8)
    iou_img[tmask] = (0, 180, 0)
    iou_img[rmask_a] = (0, 0, 200)
    iou_img[np.logical_and(tmask, rmask_a)] = (0, 220, 220)
    iou_img = label(iou_img, "IoU (G=target R=render Y=overlap)")

    # SSIM heatmap
    hm = ((1 - np.clip(smap, 0, 1)) * 255).astype(np.uint8)
    hm = cv2.applyColorMap(hm, cv2.COLORMAP_JET)
    hm = label(hm, "SSIM diff (hot = different)")

    # palette swatches
    sw = np.zeros((h, w, 3), np.uint8)
    pz = palette.get("per_zone", [])
    if pz:
        bar = h // max(len(pz), 1)
        for i, p in enumerate(pz):
            cv2.rectangle(sw, (0, i * bar), (w, (i + 1) * bar),
                          (60, 60, 60), -1)
            cv2.putText(sw, f"dE={p['delta_e']:.1f}", (8, i * bar + bar // 2),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1, cv2.LINE_AA)
    sw = label(sw, f"palette dE mean={palette.get('mean_ciede2000')}")

    row1 = np.hstack([tgt, rnd, iou_img])
    row2 = np.hstack([hm, sw, np.zeros_like(hm)])
    board = np.vstack([row1, row2])
    cv2.imwrite(out_path, board)


# --------------------------------------------------------------------------- #
def main() -> int:
    ap = argparse.ArgumentParser(description="render-vs-target metric panel + overlay")
    ap.add_argument("-r", "--render", required=True)
    ap.add_argument("-t", "--target", required=True)
    ap.add_argument("-o", "--out", default="./imgdiff_out")
    ap.add_argument("--bg", default="auto", choices=["auto", "alpha", "white", "black", "none"])
    ap.add_argument("--align", default="ecc", choices=["ecc", "bbox", "none"])
    ap.add_argument("--dists", action="store_true", help="also compute Tier-1 DISTS")
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    render = load_rgba(args.render)
    target = load_rgba(args.target)
    rmask = foreground_mask(render, args.bg)
    tmask = foreground_mask(target, args.bg)

    render_a, rmask_a = align(render, target, rmask, tmask, args.align)

    sil = silhouette_metrics(rmask_a, tmask)
    pal = palette_delta(render_a, target, rmask_a, tmask)
    ssim_score, smap = ssim_metrics(render_a, target)
    vhist = value_histogram_corr(render_a, target, rmask_a, tmask)
    dists = try_dists(args.render, args.target) if args.dists else None

    overlay_path = os.path.join(args.out, "overlay.png")
    build_overlay(target, render_a, tmask, rmask_a, smap, pal, overlay_path)

    report = {
        "render": args.render,
        "target": args.target,
        "align_mode": args.align,
        "bg_mode": args.bg,
        "silhouette": sil,
        "palette": pal,
        "ssim": ssim_score,
        "value_hist_corr": vhist,
        "dists": dists,
        "overlay": overlay_path,
        "notes": "Metrics quantify nameable axes only; naturalness stays the eye's call.",
    }
    json_path = os.path.join(args.out, "metrics.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)

    print(json.dumps(report, indent=2))
    print(f"\noverlay -> {overlay_path}\nmetrics -> {json_path}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
