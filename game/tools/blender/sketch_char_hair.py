"""sketch_char_hair -- blockout sketch of the warrior's undercut hairstyle.

This is deliberately NOT the final hair. It answers one question before any
shell geometry is cut: does the silhouette read as a head with hair, or as a
helmet sitting on top of a skull? Mass and outline only -- no strand detail, no
irregular shell borders, no braids.

Why a 3D sketch instead of a drawing: the hairline is defined relative to the
ear, and the ear is a fact about THIS skull. A 2D overlay would be guessing at
the very number the sketch exists to settle.

Three parts, matching how the reference actually works:

  hair   the mass above the undercut line: a shell raycast onto the skull and
         pushed out along its normal, thin at the border so it hugs the head
         and thicker over the crown where the volume lives.
  shave  the clipped sides. In the finished asset this is COLOUR painted on the
         skin, not geometry -- here it is a 1.5 mm skin so the sketch shows the
         look it will have. Do not carry this mesh forward.
  tail   the gathered ponytail falling down the back.

The scalp vertex group (376 verts) defines where hair may exist at all, so the
shell can never spill onto the face or below the hairline: that domain is read
off the model rather than typed in.
"""
from __future__ import annotations

import argparse
import importlib.util
import math
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

HERE = os.path.dirname(os.path.abspath(__file__))

spec = importlib.util.spec_from_file_location(
    "char_common", os.path.join(HERE, "_char_common.py"))
cc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cc)


# ---------------------------------------------------------------- utilities

def srgb_to_linear(hexstr):
    h = hexstr.lstrip("#")
    out = []
    for i in (0, 2, 4):
        v = int(h[i:i + 2], 16) / 255.0
        out.append(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4)
    return out


def body_mesh(obj):
    """Evaluated triangle soup with masks muted, in world space."""
    with cc.masks_muted(obj):
        dg = bpy.context.evaluated_depsgraph_get()
        ev = obj.evaluated_get(dg)
        me = ev.to_mesh()
        mw = obj.matrix_world
        verts = [mw @ v.co for v in me.vertices]
        polys = [tuple(p.vertices) for p in me.polygons]
        ev.to_mesh_clear()
    return verts, polys


def scalp_kd(obj, W):
    vg = obj.vertex_groups.get("scalp")
    if vg is None:
        raise SystemExit("el modelo no tiene grupo `scalp` -- sin dominio no hay recorte")
    idx = [v.index for v in obj.data.vertices
           if any(g.group == vg.index for g in v.groups)]
    kd = KDTree(len(idx))
    for k, i in enumerate(idx):
        kd.insert(Vector(W[i]), k)
    kd.balance()
    return kd, W[idx]


def new_mesh(name, verts, faces, colour):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], faces)
    me.update()
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    # FLOAT_COLOR, never BYTE_COLOR: the byte layer applies an sRGB decode on
    # read that the bmesh write does not encode, crushing every hand-picked
    # tone toward black (measured ~12x on golem_guardian).
    lay = bm.loops.layers.float_color.new("Col")
    for f in bm.faces:
        f.smooth = False
        for loop in f.loops:
            loop[lay] = (*colour, 1.0)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    return obj


# ------------------------------------------------------------------- shells

def cast_dome(bvh, centre, n_rings, n_seg, phi_max, radius=0.6):
    """Polar grid over the skull: ring 0 is the crown, ring N the lowest band.

    Returns surface points and normals as (n_rings+1, n_seg) arrays, with the
    pole duplicated across the whole first ring so the grid stays rectangular
    and the caller can index it without special-casing the tip.
    """
    P = np.full((n_rings + 1, n_seg, 3), np.nan)
    N = np.full((n_rings + 1, n_seg, 3), np.nan)
    for i in range(n_rings + 1):
        phi = phi_max * (i / n_rings)
        for j in range(n_seg):
            th = 2.0 * math.pi * j / n_seg
            d = Vector((math.sin(phi) * math.cos(th),
                        math.sin(phi) * math.sin(th),
                        math.cos(phi)))
            hit, nor, _, _ = bvh.ray_cast(centre + d * radius, -d)
            if hit is None:
                continue
            P[i, j] = hit
            N[i, j] = nor
    return P, N


def shell_from_grid(P, N, keep, out_t, in_t, name, colour, disp=None):
    """Two-layer shell over the kept cells of a polar grid, edges sewn shut.

    A single-layer surface renders with its backside showing wherever the head
    turns away, which reads as a hole; the sketch has to be judged from the
    nape, so it needs real thickness.
    """
    nr, ns = keep.shape
    idx_out = np.full((nr, ns), -1, dtype=int)
    idx_in = np.full((nr, ns), -1, dtype=int)
    verts = []
    for i in range(nr):
        for j in range(ns):
            if not keep[i, j] or np.isnan(P[i, j]).any():
                continue
            p, n = P[i, j], N[i, j]
            d = 0.0 if disp is None else disp[i, j]
            idx_out[i, j] = len(verts)
            verts.append(p + n * out_t[i, j] + d)
            idx_in[i, j] = len(verts)
            verts.append(p + n * in_t + (0.0 if disp is None else disp[i, j] * 0.85))

    faces = []
    for i in range(nr - 1):
        for j in range(ns):
            j2 = (j + 1) % ns
            quad = [(i, j), (i, j2), (i + 1, j2), (i + 1, j)]
            if any(idx_out[a, b] < 0 for a, b in quad):
                continue
            faces.append([idx_out[a, b] for a, b in quad])
            faces.append([idx_in[a, b] for a, b in reversed(quad)])

    # Border: any grid edge with a kept cell on one side and nothing on the
    # other gets a rim quad joining the outer and inner layers.
    def kept(i, j):
        return 0 <= i < nr and idx_out[i, j % ns] >= 0

    for i in range(nr):
        for j in range(ns):
            if idx_out[i, j] < 0:
                continue
            j2 = (j + 1) % ns
            for (ia, ja), (ib, jb) in (((i, j), (i, j2)),):
                if not kept(ia - 1, ja) or not kept(ib - 1, jb):
                    if kept(ib, jb):
                        faces.append([idx_out[ia, ja], idx_in[ia, ja],
                                      idx_in[ib, jb], idx_out[ib, jb]])
                if not kept(ia + 1, ja) or not kept(ib + 1, jb):
                    if kept(ib, jb):
                        faces.append([idx_out[ib, jb], idx_in[ib, jb],
                                      idx_in[ia, ja], idx_out[ia, ja]])
            if not kept(i, j - 1):
                if kept(i + 1, j):
                    faces.append([idx_out[i, j], idx_out[i + 1, j],
                                  idx_in[i + 1, j], idx_in[i, j]])
            if not kept(i, j + 1):
                if kept(i + 1, j):
                    faces.append([idx_in[i, j], idx_in[i + 1, j],
                                  idx_out[i + 1, j], idx_out[i, j]])
    return new_mesh(name, verts, faces, colour)


# --------------------------------------------------------------------- tail

def build_tail(root, length, thick, drop, name, colour, n_seg=8, n_ring=10):
    """Ponytail as a tapered swept tube falling down the back.

    The path is a quadratic that leaves the nape almost vertically and settles
    against the back, so the tail reads as hanging rather than as a stick
    poking out of the skull.
    """
    verts, faces = [], []
    prev = None
    for k in range(n_ring + 1):
        t = k / n_ring
        cz = root[2] - length * t
        cy = root[1] + drop * (t ** 1.6) - 0.006
        # Fat just under the tie, tapering to a point at the end.
        r = thick * (0.55 + 0.9 * math.sin(math.pi * min(1.0, 0.15 + t * 0.85)))
        r *= (1.0 - 0.75 * max(0.0, t - 0.72) / 0.28) if t > 0.72 else 1.0
        ring = []
        for j in range(n_seg):
            a = 2.0 * math.pi * j / n_seg
            ring.append(len(verts))
            verts.append((root[0] + math.cos(a) * r,
                          cy + math.sin(a) * r * 0.62,
                          cz))
        if prev is not None:
            for j in range(n_seg):
                j2 = (j + 1) % n_seg
                faces.append([prev[j], prev[j2], ring[j2], ring[j]])
        prev = ring
    return new_mesh(name, verts, faces, colour)


# --------------------------------------------------------------------- main

def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True, help="output .blend")
    ap.add_argument("--undercut-z", type=float, default=1.728,
                    help="world z of the shaved/hair transition line")
    ap.add_argument("--puff", type=float, default=0.017,
                    help="extra shell offset over the crown, metres")
    ap.add_argument("--tail-len", type=float, default=0.30)
    ap.add_argument("--line-tilt", type=float, default=0.022,
                    help="how much the shave line climbs toward the back")
    ap.add_argument("--sweep", type=float, default=0.026,
                    help="how far the mass is combed back, metres")
    ap.add_argument("--strip-halfwidth", type=float, default=0.030,
                    help="half width of the central strip running down the nape")
    ap.add_argument("--hair-hex", default="#6B4A2B")
    ap.add_argument("--shave-hex", default="#4A3526")
    ap.add_argument("--rings", type=int, default=26)
    ap.add_argument("--segments", type=int, default=48)
    args = ap.parse_args(argv)

    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    body = max(meshes, key=lambda o: len(o.data.vertices))
    W, _ = cc.morphed_coords(body)

    verts, polys = body_mesh(body)
    bvh = BVHTree.FromPolygons(verts, polys)
    kd, scalp_pts = scalp_kd(body, W)

    ear_top = None
    vg = body.vertex_groups.get("ears")
    if vg is not None:
        ei = [v.index for v in body.data.vertices
              if any(g.group == vg.index for g in v.groups)]
        ear_top = float(W[ei][:, 2].max())

    top = float(scalp_pts[:, 2].max())
    y_front = float(scalp_pts[:, 1].min())
    y_back = float(scalp_pts[:, 1].max())
    centre = Vector((0.0, (y_front + y_back) * 0.5, top - 0.075))
    print("  cráneo: top z=%.4f  scalp y[%.4f %.4f]  centro=(%.3f %.3f %.3f)"
          % (top, y_front, y_back, *centre))
    if ear_top is not None:
        print("  oreja tope z=%.4f -> línea de rapado %.1f mm por encima"
              % (ear_top, (args.undercut_z - ear_top) * 1000.0))

    P, N = cast_dome(bvh, centre, args.rings, args.segments, math.radians(105.0))

    nr, ns = args.rings + 1, args.segments
    in_domain = np.zeros((nr, ns), dtype=bool)
    for i in range(nr):
        for j in range(ns):
            if np.isnan(P[i, j]).any():
                continue
            _, _, dist = kd.find(Vector(P[i, j]))
            in_domain[i, j] = dist < 0.022

    Z = P[..., 2]
    X = P[..., 0]
    Y = P[..., 1]
    # The line is not level. In the reference it climbs from the temple toward
    # the back of the skull; a perfectly horizontal ring around the head is the
    # single strongest "hat brim" cue there is.
    with np.errstate(invalid="ignore"):
        z_line = args.undercut_z + args.line_tilt * np.clip((Y - 0.02) / 0.12, -1.0, 1.0)
        # Forehead hairline: high at the centre, dropping at the temples, so the
        # front edge reads as a hairline with recessions instead of a straight
        # band ruled across the brow.
        front = np.clip((-Y - 0.06) / 0.075, 0.0, 1.0)
        z_line = z_line + front * (0.008 - 0.026 * np.clip(np.abs(X) / 0.075, 0.0, 1.0))
    with np.errstate(invalid="ignore"):
        above = Z > z_line
        # The central strip carries on down the nape to where the tail is tied;
        # without it the hair stops dead at the line all the way around and the
        # ponytail sprouts from bare skin. It NARROWS as it descends -- at
        # constant width it renders as a rectangular board stuck to the neck.
        drop = np.clip((z_line - Z) / 0.075, 0.0, 1.0)
        half = args.strip_halfwidth * (1.0 - 0.62 * drop)
        strip = (np.abs(X) < half) & (Y > 0.0) & (Z > z_line - 0.075)
    hair_keep = in_domain & (above | strip)

    # Close single-cell holes: a raycast miss or a domain cell a hair over the
    # threshold punches a skin-coloured dot in the middle of the mass, which
    # reads as a bald patch and has nothing to do with the design.
    for _ in range(2):
        nb = np.zeros_like(hair_keep, dtype=int)
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nb += np.roll(np.roll(hair_keep, di, axis=0), dj, axis=1).astype(int)
        fill = (~hair_keep) & (nb >= 3) & (~np.isnan(P[..., 0]))
        hair_keep = hair_keep | fill

    shave_keep = in_domain & ~hair_keep & (Z > z_line - 0.115)

    # Snap the lower border of each column ONTO the undercut line. Clipping by
    # whole grid cells leaves a staircase whose step size is set by the ring
    # count -- a modelling artefact that reads as a design decision and was the
    # single loudest defect in the first sketch.
    for j in range(ns):
        col = np.where(hair_keep[:, j])[0]
        if len(col) == 0:
            continue
        i_last = int(col.max())
        if i_last + 1 >= nr or np.isnan(P[i_last + 1, j]).any():
            continue
        z0, z1 = Z[i_last, j], Z[i_last + 1, j]
        zl = z_line[i_last, j]
        if not (z0 > zl > z1):
            continue
        t = (z0 - zl) / max(z0 - z1, 1e-6)
        P[i_last, j] = P[i_last, j] * (1 - t) + P[i_last + 1, j] * t
        N[i_last, j] = N[i_last, j] * (1 - t) + N[i_last + 1, j] * t
        Z[i_last, j] = zl

    # Thin at the border, full volume over the crown: a constant offset makes
    # the shell stand off the skull at the hairline and read as a hat brim.
    with np.errstate(invalid="ignore"):
        ramp = np.clip((Z - z_line) / 0.055, 0.0, 1.0)
    ramp = np.nan_to_num(ramp)
    # The base offset has to be near zero AT the line: 4 mm of shell standing
    # off the skull all the way around the head is a hat brim, and no amount of
    # crown volume rescues that read.
    out_t = 0.0012 + args.puff * (ramp ** 0.75)

    # Hair is COMBED: it has a direction. Offsetting the skull along its own
    # normal produces a cap that fits the head equally in every direction,
    # which is the geometric definition of a hat. Pushing the mass backward --
    # more the higher it sits -- flattens the front, piles volume over the
    # crown and lets the silhouette overhang the nape, which is what actually
    # separates hair from headwear in profile.
    sweep = args.sweep * (ramp ** 1.4)
    disp = np.zeros(P.shape)
    disp[..., 1] = sweep
    disp[..., 2] = -sweep * 0.35

    hair_col = srgb_to_linear(args.hair_hex)
    shave_col = srgb_to_linear(args.shave_hex)

    hair = shell_from_grid(P, N, hair_keep, out_t, 0.0008, "sketch_hair", hair_col,
                           disp=disp)
    shave = shell_from_grid(P, N, shave_keep,
                            np.full((nr, ns), 0.0012), 0.0003,
                            "sketch_shave", shave_col)

    # Give each part its own material here rather than letting the previewer
    # fall back to one flat colour for everything without one -- the shaved
    # sides and the hair mass reading as the same tone is exactly the thing the
    # sketch has to show apart.
    tspec = importlib.util.spec_from_file_location(
        "toonmod", os.path.join(HERE, "preview_char_toon.py"))
    toon = importlib.util.module_from_spec(tspec)
    tspec.loader.exec_module(toon)
    hair.data.materials.append(toon.toon_material("sk_hair", args.hair_hex))
    shave.data.materials.append(toon.toon_material("sk_shave", args.shave_hex))

    # Tie point: highest kept strip cell at the back of the skull.
    # Restricted to the central strip: taking the whole back of the head picks
    # a cell out on the side of the skull, and the tail then hangs off the ear
    # instead of the nape.
    back = np.where(hair_keep & (Y > 0.02) & (np.abs(X) < args.strip_halfwidth * 1.2))
    if len(back[0]) == 0:
        raise SystemExit("no hay franja trasera -- la cola no tiene de dónde nacer")
    # Tie at the BACK-most kept cell, not the highest one: the highest is the
    # crown, and a tail rooted there sprouts from the top of the head like a
    # topknot instead of hanging off the occiput the way the reference does.
    k = int(np.argmax(P[back][:, 1]))
    root = P[back[0][k], back[1][k]]
    root = (0.0, float(root[1]) + 0.012, float(root[2]) - 0.004)
    tail = build_tail(root, args.tail_len, 0.026, 0.020, "sketch_tail", hair_col)
    tail.data.materials.append(hair.data.materials[0])
    print("  cola: nace en y=%.4f z=%.4f, cae %.0f mm" % (root[1], root[2], args.tail_len * 1000))

    for o, label in ((hair, "pelo"), (shave, "rapado"), (tail, "cola")):
        print("  %-7s %5d verts  %5d caras" % (label, len(o.data.vertices), len(o.data.polygons)))
        if len(o.data.polygons) == 0:
            raise SystemExit("%s salió vacío -- el recorte se comió la malla" % label)

    bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args.out))
    print("  guardado -> %s" % args.out)


if __name__ == "__main__":
    main()
