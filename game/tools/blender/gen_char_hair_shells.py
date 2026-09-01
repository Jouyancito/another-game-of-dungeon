"""gen_char_hair_shells -- the warrior's undercut, built as overlapping shells.

Replaces gen_char_hair_plates.py, which built 39 narrow constant-width strips
advancing by raycast. The second batch of the hair_polygon_shells reference
corrects that reading: the technique is a DOZEN LARGE shells with irregular
cut-out borders, stacked like roof tiles. The border is the strand. There is no
alpha texture and there is no subdivision -- the detail is the outline.

The blockout that preceded this file (sketch_char_hair.py) proved the negative
that shapes this one: a single continuous surface offset from the skull cannot
read as hair no matter how clean its border is, because an offset that fits the
head equally in every direction is the geometric definition of a hat. What
produces the read is OVERLAP -- one layer showing past another. So overlap is
the metric this generator is judged by, and it is checked here rather than
eyeballed later.

The asset is self-contained by design (see the 2026-08-22 decision): the body
underneath is bald, so the shaved sides ship as a thin scalp cap INSIDE this
asset rather than as paint on the skin texture. A different hairstyle brings a
different shave pattern, or none.

Flow parametrisation: hair on this head is combed front-to-back, so the shells
run that way too. Each point gets

    psi   angle around the fore-aft axis -- 0 over the crown, +-pi/2 at the ears
    s     front-to-back progress, 0 at the hairline and 1 at the nape

and a shell is a band in psi spanning the whole of s. The polar raycast grid is
kept for sampling the skull because it covers it evenly; psi and s are computed
per sample rather than being the grid's own axes, which lets the shells run
across the pole instead of radiating out of it.
"""
from __future__ import annotations

import argparse
import importlib.util
import math
import os
import random
import sys

import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))

_spec = importlib.util.spec_from_file_location(
    "sketch_char_hair", os.path.join(HERE, "sketch_char_hair.py"))
sk = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sk)
cc = sk.cc


def wobble(s, phases, amps, freqs):
    """Low-frequency irregular edge offset in [-1, 1]-ish.

    Several incommensurate harmonics rather than one sine: a single sine reads
    as a scallop pattern, which is decoration. The reference border is uneven.
    """
    out = np.zeros_like(s)
    for ph, am, fr in zip(phases, amps, freqs):
        out = out + am * np.sin(fr * s * 2.0 * math.pi + ph)
    return out


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--glb", default="")
    ap.add_argument("--shells", type=int, default=12,
                    help="strand shells over the base cap (reference says 10-15)")
    ap.add_argument("--undercut-z", type=float, default=1.728)
    ap.add_argument("--line-tilt", type=float, default=0.022)
    ap.add_argument("--layer-step", type=float, default=0.011,
                    help="offset added per stacked shell, metres")
    ap.add_argument("--lift", type=float, default=1.7,
                    help="how much a shell peels away from the skull at its free end")
    ap.add_argument("--min-gap", type=float, default=0.008,
                    help="separation two stacked shells need before the eye reads them apart")
    ap.add_argument("--band", type=float, default=1.55,
                    help="shell width as a multiple of its share of the fan")
    ap.add_argument("--edge-amp", type=float, default=0.30,
                    help="border irregularity as a fraction of band half-width")
    ap.add_argument("--tail-len", type=float, default=0.30)
    ap.add_argument("--hair-hex", default="#6B4A2B")
    ap.add_argument("--shave-hex", default="#4A3526")
    ap.add_argument("--rings", type=int, default=40)
    ap.add_argument("--segments", type=int, default=72)
    ap.add_argument("--seed", type=int, default=7)
    args = ap.parse_args(argv)

    rng = random.Random(args.seed)

    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    body = max(meshes, key=lambda o: len(o.data.vertices))
    W, _ = cc.morphed_coords(body)
    verts, polys = sk.body_mesh(body)
    bvh = BVHTree.FromPolygons(verts, polys)
    kd, scalp_pts = sk.scalp_kd(body, W)

    top = float(scalp_pts[:, 2].max())
    y_front = float(scalp_pts[:, 1].min())
    y_back = float(scalp_pts[:, 1].max())
    centre = Vector((0.0, (y_front + y_back) * 0.5, top - 0.075))

    ear_top = None
    vg = body.vertex_groups.get("ears")
    if vg is not None:
        ei = [v.index for v in body.data.vertices
              if any(g.group == vg.index for g in v.groups)]
        ear_top = float(W[ei][:, 2].max())
        print("  oreja tope z=%.4f -> línea de rapado %.1f mm por encima"
              % (ear_top, (args.undercut_z - ear_top) * 1000.0))

    P, N = sk.cast_dome(bvh, centre, args.rings, args.segments, math.radians(108.0))
    nr, ns = args.rings + 1, args.segments

    in_domain = np.zeros((nr, ns), dtype=bool)
    for i in range(nr):
        for j in range(ns):
            if np.isnan(P[i, j]).any():
                continue
            _, _, dist = kd.find(Vector(P[i, j]))
            in_domain[i, j] = dist < 0.024

    X, Y, Z = P[..., 0], P[..., 1], P[..., 2]
    with np.errstate(invalid="ignore"):
        z_line = args.undercut_z + args.line_tilt * np.clip((Y - 0.02) / 0.12, -1.0, 1.0)
        hair_zone = in_domain & (Z > z_line)
        # The strip down the nape, where the mass gathers into the tie.
        strip = (np.abs(X) < 0.030) & (Y > 0.0) & (Z > z_line - 0.070)
        hair_zone = hair_zone | (in_domain & strip)

    for _ in range(2):
        nb = np.zeros_like(hair_zone, dtype=int)
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nb += np.roll(np.roll(hair_zone, di, axis=0), dj, axis=1).astype(int)
        hair_zone = hair_zone | ((~hair_zone) & (nb >= 3) & (~np.isnan(X)))

    shave_zone = in_domain & ~hair_zone & (Z > z_line - 0.115)

    # --- flow coordinates -------------------------------------------------
    with np.errstate(invalid="ignore"):
        psi = np.arctan2(X, np.maximum(Z - float(centre[2]), 1e-4))
        s = np.clip((Y - y_front) / max(y_back - y_front, 1e-4), 0.0, 1.0)
    psi = np.nan_to_num(psi)
    s = np.nan_to_num(s)

    psi_span = float(np.nanmax(np.abs(psi[hair_zone]))) if hair_zone.any() else 1.2
    print("  zona de pelo: %d celdas   psi max %.3f rad   s [%.2f %.2f]"
          % (hair_zone.sum(), psi_span, s[hair_zone].min(), s[hair_zone].max()))

    hair_col = sk.srgb_to_linear(args.hair_hex)
    shave_col = sk.srgb_to_linear(args.shave_hex)

    tspec = importlib.util.spec_from_file_location(
        "toonmod", os.path.join(HERE, "preview_char_toon.py"))
    toon = importlib.util.module_from_spec(tspec)
    tspec.loader.exec_module(toon)
    mat_hair = toon.toon_material("hair", args.hair_hex)
    mat_shave = toon.toon_material("shave", args.shave_hex)

    made = []

    # --- base cap ---------------------------------------------------------
    # Frames 65-171 of the reference: the strand shells sit ON a base shell,
    # they do not float over bare scalp. This is what guarantees no skin shows
    # between strands; the shells above it are what make it read as hair.
    base_t = np.full((nr, ns), 0.0022)
    base = sk.shell_from_grid(P, N, hair_zone, base_t, 0.0006, "hair_base", hair_col)
    base.data.materials.append(mat_hair)
    made.append(("base", base))

    # --- strand shells ----------------------------------------------------
    n = args.shells
    half = args.band * (psi_span / max(n - 1, 1))
    masks = []
    for k in range(n):
        # Centres spread across the fan; the outermost land near the shave line
        # so the lowest shells hang over it instead of stopping short.
        c = -psi_span + 2.0 * psi_span * (k / max(n - 1, 1))
        phases = [rng.uniform(0, 2 * math.pi) for _ in range(3)]
        amps = [0.55, 0.30, 0.15]
        freqs = [rng.uniform(0.8, 1.4), rng.uniform(1.9, 2.6), rng.uniform(3.4, 4.6)]
        edge_a = wobble(s, phases, amps, freqs) * args.edge_amp * half
        phases2 = [rng.uniform(0, 2 * math.pi) for _ in range(3)]
        edge_b = wobble(s, phases2, amps, freqs) * args.edge_amp * half
        # The trailing end stops at its own point, so the shells do not all end
        # on the same line across the nape.
        s_end = 0.80 + rng.uniform(0.0, 0.22)
        m = hair_zone & (psi > c - half + edge_a) & (psi < c + half + edge_b) & (s < s_end)
        if m.sum() < 12:
            continue
        masks.append((k, c, m))

    offsets = []
    for layer, (k, c, m) in enumerate(masks):
        # Centre shells ride highest, matching the reference where the parallel
        # runs closest to the parting sit above the ones toward the ear.
        height = 1.0 - min(1.0, abs(c) / max(psi_span, 1e-4))
        off = 0.0034 + args.layer_step * (0.35 + 1.65 * height)
        # Rooted at the hairline, PEELING AWAY toward the free end. This is the
        # correction that the first shell pass needed: shells that hug the skull
        # along their whole length overlap in the data and are invisible on
        # screen, because nothing separates one from the next. A lock of hair
        # lifts off as it runs, and that lift is what casts the edge into
        # shadow and cuts the silhouette.
        with np.errstate(invalid="ignore"):
            root = np.clip((s - 0.01) / 0.10, 0.10, 1.0)
            peel = 0.20 + args.lift * np.clip(s, 0.0, 1.0) ** 1.25
        out_t = np.nan_to_num(off * root * peel) + 0.0016
        offsets.append((m, np.nan_to_num(off * root * peel)))
        o = sk.shell_from_grid(P, N, m, out_t, 0.0010, "hair_shell_%02d" % k, hair_col)
        o.data.materials.append(mat_hair)
        made.append(("shell_%02d" % k, o))

    # --- shave cap (part of THIS asset, not of the skin texture) ----------
    shave = sk.shell_from_grid(P, N, shave_zone,
                               np.full((nr, ns), 0.0012), 0.0003,
                               "hair_shave_cap", shave_col)
    shave.data.materials.append(mat_shave)
    made.append(("shave", shave))

    # --- tail -------------------------------------------------------------
    back = np.where(hair_zone & (Y > 0.02) & (np.abs(X) < 0.036))
    ki = int(np.argmax(P[back][:, 1]))
    root = P[back[0][ki], back[1][ki]]
    tail = sk.build_tail((0.0, float(root[1]) + 0.012, float(root[2]) - 0.004),
                         args.tail_len, 0.026, 0.020, "hair_tail", hair_col)
    tail.data.materials.append(mat_hair)
    made.append(("tail", tail))

    # --- metrics ----------------------------------------------------------
    # OVERLAP is the number that decides this asset. Defined before building:
    # a shell that no other shell covers is a plate lying on a skull, which is
    # exactly the 2026-08-15 failure. Every shell must be partly buried.
    print("\n  SOLAPAMIENTO por cáscara (fracción cubierta por otra):")
    cover = np.zeros((nr, ns), dtype=int)
    for _, _, m in masks:
        cover += m.astype(int)
    lonely = []
    for k, c, m in masks:
        shared = float((m & (cover > 1)).sum()) / max(m.sum(), 1)
        flag = "" if shared >= 0.35 else "   <-- suelta"
        if shared < 0.35:
            lonely.append(k)
        print("    shell_%02d  celdas=%4d  solapada=%.0f%%%s"
              % (k, m.sum(), shared * 100.0, flag))

    covered = (cover > 0) | np.zeros_like(cover, dtype=bool)
    bare = int((hair_zone & (cover == 0)).sum())
    print("\n  cobertura: %d celdas de zona de pelo sin ninguna cáscara de mechón"
          " (la base las cubre igual)" % bare)
    print("  cáscaras: %d mechones + base + rapado + cola" % len(masks))

    tris = sum(len(o.data.polygons) for _, o in made)
    print("  malla total: %d verts  %d caras"
          % (sum(len(o.data.vertices) for _, o in made), tris))
    for label, o in made:
        if len(o.data.polygons) == 0:
            raise SystemExit("%s salió vacío" % label)
    if lonely:
        print("  *** %d cáscaras sin solapar: %s" % (len(lonely), lonely))

    bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args.out))
    print("  guardado -> %s" % args.out)

    if args.glb:
        for o in bpy.data.objects:
            o.select_set(o.name.startswith("hair_"))
        bpy.ops.export_scene.gltf(filepath=os.path.abspath(args.glb),
                                  export_format="GLB", use_selection=True,
                                  export_yup=True, export_apply=True)
        print("  glb -> %s" % args.glb)


if __name__ == "__main__":
    main()
