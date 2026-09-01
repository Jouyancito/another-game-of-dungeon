"""gen_char_brows -- build the brows as GEOMETRY, glued to the brow ridge.

WHY GEOMETRY: painting them is impossible on this mesh, and that is measured,
not felt. Verified against Skyrim's Farkas at matched interpupillary distance,
a real brow body sits ~8.6 mm above the pupil and is ~5.5 mm tall. The head
carries a 4.07 mm median edge, so a correct brow is ONE AND A HALF VERTICES.
No weighting fixes that. Same wall as the pores.

WHAT A BROW IS, which is what the painted version got wrong:
  Short dense hair over the supraorbital ridge, growing obliquely outward and
  up. It ARCHES, because its job is to shed sweat away from the eye. It is
  WIDE and dense at the HEAD (inner end, by the nose) and tapers to a thin
  TAIL (outer end). The peak of the arch falls about two thirds of the way
  out, not in the middle.
  The painted band was a symmetric horizontal slab. That is not a brow shape.

POSITION COMES FROM THE REFERENCE, NOT FROM THE BONE. The earlier attempt put
the band on the CREST of the supraorbital arch, reasoning that is where the
bone protrudes, and enforced a control demanding it clear the top of the globe
(14.9 mm). Farkas shows the brow sitting well below that line. The control was
not protecting against a defect, it was producing one -- and stamping it OK.

    blender -b <blend> --python-exit-code 1 --python gen_char_brows.py -- \
        --out brows.blend --strip strip.png
"""
from __future__ import annotations

import argparse
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

from _char_common import morphed_coords

# All from the Farkas measurement, in fractions of the interpupillary span so
# they transfer to any head. IPD on this model is 61.5 mm.
BODY_ABOVE_PUPIL = 0.140     # centre of the brow body
ARCH_RISE = 0.045            # how much the peak lifts above the head
HEAD_HALF = 0.048            # half-height at the inner end (thick)
TAIL_HALF = 0.016            # half-height at the outer end (thin)
INNER_X = 0.20               # inner end, as a fraction of IPD from centre
OUTER_X = 0.78               # outer end
PEAK_T = 0.62                # where along the brow the arch peaks

SEGMENTS = 14
PROUD = 0.0022               # metres above the skin -- motor recipe says 2-3.5


def smoothstep(t):
    t = np.clip(t, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def brow_profile(t: float):
    """(rise, half_height) along the brow, t=0 inner head .. t=1 outer tail.

    The arch is a single hump peaking at PEAK_T, and the thickness falls from
    HEAD_HALF to TAIL_HALF with a curve rather than a straight line -- a real
    brow keeps its body most of the way and then tapers quickly.
    """
    hump = math.sin(math.pi * min(1.0, t / PEAK_T * 0.5 + 0.5 * (
        t > PEAK_T) * ((t - PEAK_T) / max(1e-6, 1 - PEAK_T) * 0.5 + 1.0)))
    # simpler and monotone-safe: a raised cosine centred on PEAK_T
    hump = 0.5 * (1.0 - math.cos(2.0 * math.pi * min(t / (2 * PEAK_T), 1.0)))
    taper = 1.0 - float(smoothstep(np.array((t - 0.35) / 0.65)))
    half = TAIL_HALF + (HEAD_HALF - TAIL_HALF) * taper
    return ARCH_RISE * hump, half


def build_strip(name, side, ipd, pupil, scale=1.0):
    """A flat quad strip in the frontal plane, later glued onto the skin."""
    verts, faces = [], []
    for i in range(SEGMENTS + 1):
        t = i / SEGMENTS
        rise, half = brow_profile(t)
        half *= scale
        x = side * ipd * (INNER_X + (OUTER_X - INNER_X) * t)
        z = pupil[2] + ipd * (BODY_ABOVE_PUPIL + rise)
        verts.append((x, pupil[1] - 0.02, z - ipd * half))
        verts.append((x, pupil[1] - 0.02, z + ipd * half))
        if i:
            a = 2 * (i - 1)
            faces.append((a, a + 2, a + 3, a + 1))

    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def glue_to_surface(obj, body, proud=PROUD) -> float:
    """Motor recipe bvh_glue: every vertex to the nearest skin point + normal.

    BVH is built on the EVALUATED body -- the recipe's own gotcha #1. On this
    model that matters twice over: 41 shape keys mean the base cage is ~10 cm
    away from what renders.
    """
    deps = bpy.context.evaluated_depsgraph_get()
    bev = body.evaluated_get(deps)
    bme = bev.to_mesh()
    verts = [body.matrix_world @ v.co for v in bme.vertices]
    polys = [tuple(p.vertices) for p in bme.polygons]
    bvh = BVHTree.FromPolygons(verts, polys)
    bev.to_mesh_clear()

    mw = obj.matrix_world
    mwi = mw.inverted()
    moved = []
    for v in obj.data.vertices:
        loc, nrm, _idx, dist = bvh.find_nearest(mw @ v.co)
        if loc is None:
            continue
        v.co = mwi @ (loc + nrm * proud)
        moved.append(dist)
    obj.data.update()
    return float(np.mean(moved)) if moved else 0.0


def check_position(obj, body, ipd, pupil_z) -> None:
    """CONTROL: the brow body must land where the reference put it."""
    W = np.array([obj.matrix_world @ v.co for v in obj.data.vertices])
    frac = (W[:, 2].mean() - pupil_z) / ipd
    lo = (W[:, 2].min() - pupil_z) / ipd
    hi = (W[:, 2].max() - pupil_z) / ipd
    ok = 0.10 <= frac <= 0.18
    print("      [%s] body at %+.3f of IPD (Farkas: 0.10..0.18) | span"
          " %+.3f..%+.3f" % ("OK" if ok else "OFF-REF", frac, lo, hi))
    print("      height %.1f mm (Farkas ~5.5 mm at the body)"
          % ((W[:, 2].max() - W[:, 2].min()) * 1000))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", default="face_m100")
    ap.add_argument("--out", required=True)
    ap.add_argument("--strip", default=None)
    ap.add_argument("--thickness", type=float, default=1.0)
    args = ap.parse_args(argv)

    body = bpy.data.objects.get(args.obj)
    if body is None:
        raise SystemExit("no object %r -- have %s"
                         % (args.obj, sorted(o.name for o in bpy.data.objects
                                             if o.type == "MESH")))
    body.location = (0, 0, 0)
    bpy.context.view_layer.update()

    W, _ = morphed_coords(body)
    gi = {g.name: g.index for g in body.vertex_groups}

    def centre(gname):
        k = gi[gname]
        idx = [v.index for v in body.data.vertices
               if any(e.group == k and e.weight > 0.01 for e in v.groups)]
        return W[idx].mean(axis=0)

    cl, cr = centre("helper-l-eye"), centre("helper-r-eye")
    ipd = float(abs(cl[0] - cr[0]))
    pupil = (0.0, 0.5 * (cl[1] + cr[1]), 0.5 * (cl[2] + cr[2]))
    print("")
    print("  IPD %.1f mm | pupil line z %.4f" % (ipd * 1000, pupil[2]))

    made = []
    for side, name in ((1.0, "brow_l"), (-1.0, "brow_r")):
        b = build_strip(name, side, ipd, pupil, args.thickness)
        d = glue_to_surface(b, body)
        print("    %s: glued, mean travel %.1f mm" % (name, d * 1000))
        check_position(b, body, ipd, pupil[2])
        made.append(b)

    # Dark, matte, and slightly translucent-free: brow hair is the darkest
    # thing on a face after the pupil.
    mat = bpy.data.materials.new("brow")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (0.022, 0.016, 0.012, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.95
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.12
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    for b in made:
        b.data.materials.append(mat)
        # Solidify gives the strip a hair's thickness so it catches the key
        # light like a mass instead of reading as a decal.
        sol = b.modifiers.new("thick", "SOLIDIFY")
        sol.thickness = 0.0016
        sol.offset = 1.0

    bpy.ops.wm.save_as_mainfile(filepath=bpy.path.abspath(args.out))
    print("  saved %s" % args.out)


if __name__ == "__main__":
    main()
