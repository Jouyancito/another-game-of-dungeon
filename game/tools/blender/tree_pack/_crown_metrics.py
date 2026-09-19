"""_crown_metrics.py — crown composition measured on the SHIPPED GLBs.

The v2 pack passed every metric it had and still read as "a cone lying on its
side". P11's centroid-offset number (12-24%, in band) does not capture the
failure: a long near-horizontal limb relocates a lot of visual mass while
barely moving the area-weighted centroid, because the centroid is an average
and the rest of the crown drags it back toward the axis.

What actually distinguishes a crown from a lobe is whether foliage SURROUNDS
the trunk. So this tool measures, on the geometry that ships:

  AZIMUTHAL COVERAGE — project every foliage polygon onto the ground plane,
    bin the 360 deg around the trunk axis into 36 x 10 deg, and report the
    fraction of bins holding foliage.
      `cov_any`    — bins with ANY foliage. Reported for completeness, but it
                     is a weak test: one clump sitting 0.5 m off the axis
                     subtends most of the circle on its own.
      `cov_frac25` — bins holding at least 25% of the share a perfectly even
                     crown would put there (mass/36). THIS is the headline
                     number: it is what an empty flank actually fails.
    Target: cov_frac25 >= 75%.

  GRAVITY BALANCE — horizontal distance from the trunk axis to the
    area-weighted foliage centroid, as a fraction of crown radius.
    Target: <= 20%.

  QUADRANT MASS — foliage area per 90 deg quadrant, as a fraction of the
    total. A biased crown is fine; an EMPTY quadrant is not.

The trunk axis is taken from the BARK geometry at crown mid-height, not from
the base: these trunks lean 8-12 deg, which at 7 m is over a metre of
horizontal travel and would swamp the asymmetry signal (v2 report, lesson 7a).

Run:
  blender.exe --background --factory-startup --python-exit-code 1 \
      --python _crown_metrics.py [-- --json out.json]
"""
import bpy
import json
import math
import os
import sys

import numpy as np
from mathutils import Vector

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ASSET_DIR = os.path.normpath(os.path.join(
    SCRIPT_DIR, "..", "..", "..", "assets", "art", "piso1_pradera",
    "vegetation", "tree_pack"))

VARIANTS = ["tree_prairie_01", "tree_prairie_tall_01", "tree_prairie_wide_01",
            "tree_young_01", "tree_dry_01"]

N_BINS = 36
COV_MIN_SHARE = 0.25          # of the even-crown share (1/N_BINS)
COVERAGE_TARGET = 0.75
BALANCE_TARGET = 0.20

out_json = None
argv = sys.argv
if "--" in argv:
    extra = argv[argv.index("--") + 1:]
    for i, a in enumerate(extra):
        if a == "--json" and i + 1 < len(extra):
            out_json = extra[i + 1]


def poly_area_centre(me, poly, mw):
    """World-space area and centroid of one polygon (fan triangulation)."""
    vs = [mw @ me.vertices[vi].co for vi in poly.vertices]
    if len(vs) < 3:
        return 0.0, Vector((0.0, 0.0, 0.0))
    area = 0.0
    acc = Vector((0.0, 0.0, 0.0))
    for k in range(1, len(vs) - 1):
        a = (vs[k] - vs[0]).cross(vs[k + 1] - vs[0]).length * 0.5
        area += a
        acc += (vs[0] + vs[k] + vs[k + 1]) / 3.0 * a
    if area <= 1e-12:
        return 0.0, sum(vs, Vector()) / len(vs)
    return area, acc / area


def trunk_centreline(bz, bxy, ba, nz=24):
    """z -> (x, y) of the trunk axis, robust to branches radiating outward.

    Per z-slice, area-weight the bark centres, then re-weight three times with a
    Cauchy falloff in distance so branch tubes — thin and far off-axis — fade
    out and the trunk ring dominates. Needed because these trunks lean 8-12 deg,
    and a crown centroid compared against an axis sampled at the wrong height is
    charged for the lean, which is P3 behaving correctly.

    The falloff is SOFT on purpose: a hard "keep the closest 60% of polygons"
    is tessellation-sensitive, and glTF export triangulates, so the builder and
    this tool disagreed by 12 points of crown radius on the same tree. With a
    smooth weight they agree, which is the check that the estimator is sound.
    """
    edges = np.linspace(bz.min(), bz.max(), nz + 1)
    zs, xs, ys = [], [], []
    for k in range(nz):
        sel = (bz >= edges[k]) & ((bz < edges[k + 1]) if k < nz - 1 else (bz <= edges[k + 1]))
        if sel.sum() < 3:
            continue
        w0, p = ba[sel], bxy[sel]
        cx = (p[:, 0] * w0).sum() / w0.sum()
        cy = (p[:, 1] * w0).sum() / w0.sum()
        for _ in range(3):
            d2 = (p[:, 0] - cx) ** 2 + (p[:, 1] - cy) ** 2
            s2 = max(float((d2 * w0).sum() / w0.sum()), 1e-12)
            w = w0 / (1.0 + d2 / s2)
            cx = (p[:, 0] * w).sum() / w.sum()
            cy = (p[:, 1] * w).sum() / w.sum()
        zs.append(0.5 * (edges[k] + edges[k + 1]))
        xs.append(cx)
        ys.append(cy)
    return np.array(zs), np.array(xs), np.array(ys)


def measure(name):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    path = os.path.join(ASSET_DIR, f"env_{name}.glb")
    bpy.ops.import_scene.gltf(filepath=path)

    fol = []      # (area, centre)
    bark = []     # (area, centre)
    fvx, fvy = [], []                     # foliage VERTICES, for crown radius
    for obj in [o for o in bpy.data.objects if o.type == 'MESH']:
        me = obj.data
        mw = obj.matrix_world
        slot_is_leaf = [bool(m and "leaf" in m.name.lower())
                        for m in me.materials] or [False]
        for poly in me.polygons:
            mi = min(poly.material_index, len(slot_is_leaf) - 1)
            a, c = poly_area_centre(me, poly, mw)
            if slot_is_leaf[mi]:
                fol.append((a, c))
                for vi in poly.vertices:
                    p = mw @ me.vertices[vi].co
                    fvx.append(p.x)
                    fvy.append(p.y)
            else:
                bark.append((a, c))

    if not fol:
        raise RuntimeError(f"{name}: no foliage polygons found")

    fz = np.array([c.z for _, c in fol])
    fx = np.array([c.x for _, c in fol])
    fy = np.array([c.y for _, c in fol])
    fa = np.array([a for a, _ in fol])

    crown_lo, crown_hi = fz.min(), fz.max()
    crown_mid = 0.5 * (crown_lo + crown_hi)

    # ---- trunk axis at crown mid-height, from the BARK geometry -------------
    bz = np.array([c.z for _, c in bark])
    bxy = np.array([[c.x, c.y] for _, c in bark])
    ba = np.array([a for a, _ in bark])
    band = 0.06 * max(1e-6, bz.max() - bz.min())
    sel = np.abs(bz - crown_mid) < band
    while sel.sum() < 8 and band < (bz.max() - bz.min()):
        band *= 1.6
        sel = np.abs(bz - crown_mid) < band
    if sel.sum():
        w = ba[sel]
        axis_x = float((bxy[sel, 0] * w).sum() / w.sum())
        axis_y = float((bxy[sel, 1] * w).sum() / w.sum())
    else:
        axis_x = axis_y = 0.0

    # Crown radius: mean of the two ground-plane half-extents of the foliage,
    # from VERTICES not polygon centres. Centres move outward when a quad is
    # split into two triangles and glTF export triangulates, so a centre-based
    # radius reads 12% wider here than in the build scene and made every offset
    # fraction disagree with the builder by a factor of two.
    crown_r = 0.25 * ((max(fvx) - min(fvx)) + (max(fvy) - min(fvy)))

    dx, dy = fx - axis_x, fy - axis_y
    ang = np.arctan2(dy, dx) % (2.0 * math.pi)
    idx = np.minimum((ang / (2.0 * math.pi) * N_BINS).astype(int), N_BINS - 1)

    mass = np.zeros(N_BINS)
    np.add.at(mass, idx, fa)
    total = mass.sum()
    share = mass / max(1e-12, total)
    even = 1.0 / N_BINS

    cov_any = float((mass > 0).mean())
    cov_frac25 = float((share >= COV_MIN_SHARE * even).mean())
    empty_bins = int((mass <= 0).sum())

    # longest contiguous run of failing bins, wrapped. A canopy with one 200 deg
    # hole and a canopy with twenty scattered thin spots score the same coverage
    # but only the first reads as half a tree — this is the `wide` failure.
    ok = share >= COV_MIN_SHARE * even
    gap = run = 0
    for b in np.concatenate([ok, ok]):
        run = 0 if b else run + 1
        gap = max(gap, run)
    max_gap_deg = min(gap, N_BINS) * 360.0 / N_BINS

    # quadrant mass, quadrant 0 = azimuth 0-90 deg
    quad = np.zeros(4)
    np.add.at(quad, np.minimum((ang / (math.pi / 2)).astype(int), 3), fa)
    quad = quad / max(1e-12, quad.sum())

    cen_x = float((fx * fa).sum() / fa.sum())
    cen_y = float((fy * fa).sum() / fa.sum())
    cen_z = float((fz * fa).sum() / fa.sum())
    zs, axs, ays = trunk_centreline(bz, bxy, ba)
    if len(zs):
        # Reference = the trunk axis sampled at every foliage polygon's OWN
        # height, averaged with the SAME mass weights as the crown centroid, so
        # the trunk's legal 8-12 deg lean and the upward branch arc both cancel
        # and only lateral asymmetry survives. See build_tree_pack.py for the
        # two rejected alternatives and why. Both are still reported below.
        ax_c = float((np.interp(fz, zs, axs) * fa).sum() / fa.sum())
        ay_c = float((np.interp(fz, zs, ays) * fa).sum() / fa.sum())
        ax_z = float(np.interp(cen_z, zs, axs))
        ay_z = float(np.interp(cen_z, zs, ays))
    else:
        ax_c, ay_c, ax_z, ay_z = axis_x, axis_y, axis_x, axis_y
    offset = math.hypot(cen_x - ax_c, cen_y - ay_c)
    offset_frac = offset / max(1e-6, crown_r)
    offset_mid = math.hypot(cen_x - axis_x, cen_y - axis_y) / max(1e-6, crown_r)
    offset_cenz = math.hypot(cen_x - ax_z, cen_y - ay_z) / max(1e-6, crown_r)

    # how far the single furthest foliage point sits from the axis, vs the
    # crown radius: a long limb shows up here even when the centroid does not
    reach = np.hypot(dx, dy)
    reach_max = float(reach.max()) / max(1e-6, crown_r)

    return dict(
        variant=name, crown_radius=float(crown_r),
        crown_lo=float(crown_lo), crown_hi=float(crown_hi),
        axis_xy=[axis_x, axis_y],
        cov_any=cov_any, cov_frac25=cov_frac25, empty_bins=empty_bins,
        max_gap_deg=float(max_gap_deg),
        quadrants=[float(q) for q in quad],
        min_quadrant=float(quad.min()),
        centroid_offset_m=float(offset), centroid_offset_frac=float(offset_frac),
        centroid_offset_frac_midaxis=float(offset_mid),
        centroid_offset_frac_cenz=float(offset_cenz),
        reach_max_frac=reach_max,
        pass_coverage=bool(cov_frac25 >= COVERAGE_TARGET),
        pass_balance=bool(offset_frac <= BALANCE_TARGET),
    )


rows = [measure(v) for v in VARIANTS]

print("\n" + "=" * 78)
print("CROWN COMPOSITION — measured on the shipped GLBs")
print("=" * 78)
print(f"{'variant':24s} {'cov>=25%':>9s} {'cov_any':>8s} {'gap':>6s} "
      f"{'balance':>8s} {'(mid)':>7s} {'minquad':>8s} {'reach':>7s}")
for r in rows:
    print(f"{r['variant']:24s} "
          f"{r['cov_frac25']*100:8.1f}% {r['cov_any']*100:7.1f}% "
          f"{r['max_gap_deg']:5.0f}d "
          f"{r['centroid_offset_frac']*100:7.1f}% {r['centroid_offset_frac_midaxis']*100:6.1f}% "
          f"{r['min_quadrant']*100:7.1f}% "
          f"{r['reach_max_frac']:6.2f}x "
          f"{'OK' if r['pass_coverage'] and r['pass_balance'] else 'FAIL'}")
print(f"\ntargets: azimuthal coverage (>=25% share bins) >= {COVERAGE_TARGET*100:.0f}%, "
      f"centroid offset <= {BALANCE_TARGET*100:.0f}% of crown radius")
print("quadrant mass fractions (0-90 / 90-180 / 180-270 / 270-360 deg):")
for r in rows:
    print(f"  {r['variant']:24s} " +
          " ".join(f"{q*100:5.1f}%" for q in r["quadrants"]))
print("=" * 78 + "\n")

if out_json:
    with open(out_json, "w", encoding="utf-8") as fh:
        json.dump(rows, fh, indent=1)
    print(f"[crown_metrics] -> {out_json}")
