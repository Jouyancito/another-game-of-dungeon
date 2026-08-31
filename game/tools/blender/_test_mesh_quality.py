"""Sanity harness for mesh_quality -- primitives whose answer is known ahead.

A metric that returns a plausible number on a real mesh proves nothing: a
broken probe and a clean mesh look identical. So every metric is first run
against geometry whose correct answer can be derived on paper, and the run
FAILS LOUDLY if it disagrees.

    blender -b --python _test_mesh_quality.py

Expected answers, derived rather than observed:

  cube        closed volume       -> BER 0.0, 0 border loops
              every corner has 3 edges, not 4, and none is a boundary vert
              -> valence_rate 1.0, so TS = 1 - 0.12 = 0.88. A cube is EIGHT
              poles; scoring it 1.0 would mean the valence term does nothing.
  plane       one quad            -> BER 1.0 (all 4 edges boundary), 1 loop
  grid 4x4    16 quads            -> 16 perimeter edges of 40 -> BER 0.4
  two spheres r=1.00 vs r=1.01    -> HD mean ~10 mm along the whole surface
  sphere vs itself                -> HD exactly 0.0
  non-manifold fin                -> nonmanifold_edges 1
"""
from __future__ import annotations

import sys
import os

import bpy
import bmesh

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mesh_quality import (boundary_edge_ratio, topology_score, hausdorff,
                          _bm_from)

FAILURES: list[str] = []


def check(label: str, got, want, tol=0.0):
    ok = abs(got - want) <= tol if isinstance(want, float) else got == want
    print("  %-4s %-46s got %-12s want %s"
          % ("OK" if ok else "FAIL", label, _fmt(got), _fmt(want)))
    if not ok:
        FAILURES.append("%s: got %s want %s" % (label, got, want))


def _fmt(v):
    return "%.4f" % v if isinstance(v, float) else str(v)


def wipe():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def bm_of(obj):
    return _bm_from(obj, evaluated=False)


# --------------------------------------------------------------------------

def test_cube():
    print("\n-- cube: closed volume, 8 corners of valence 3 --")
    wipe()
    bpy.ops.mesh.primitive_cube_add()
    bm = bm_of(bpy.context.object)
    b = boundary_edge_ratio(bm)
    t = topology_score(bm)
    check("cube BER", b["ber"], 0.0, 1e-9)
    check("cube border loops", b["border_loops"], 0)
    check("cube nonmanifold", t["nonmanifold_edges"], 0)
    check("cube degenerate", t["degenerate_faces"], 0)
    check("cube quads", t["quads"], 6)
    # Every corner is interior (closed volume) and has 3 edges, not 4.
    check("cube valence_rate (8 poles)", t["valence_rate"], 1.0, 1e-9)
    check("cube TS = 1 - 0.12", t["ts"], 0.88, 1e-9)
    check("cube nonplanar quads", t["nonplanar_quads"], 0)
    bm.free()


def test_plane():
    print("\n-- plane: one quad, every edge is a border --")
    wipe()
    bpy.ops.mesh.primitive_plane_add()
    bm = bm_of(bpy.context.object)
    b = boundary_edge_ratio(bm)
    t = topology_score(bm)
    check("plane BER", b["ber"], 1.0, 1e-9)
    check("plane border loops", b["border_loops"], 1)
    # No interior verts at all -> the valence term must not divide by zero.
    check("plane interior verts", t["interior_verts"], 0)
    check("plane valence_rate", t["valence_rate"], 0.0, 1e-9)
    bm.free()


# Blender counts primitive_grid_add subdivisions as FACES per side, not cuts.
# The first version of this test assumed cuts, derived 16 faces, and failed
# against the correct answer of 25 -- the harness caught a bad derivation, not
# a bad metric. Both are kept named N_SIDE so the arithmetic below stays
# checkable on paper.
N_SIDE = 5


def test_grid():
    print("\n-- grid %dx%d faces: perimeter is 4N of 2N(N+1) edges --"
          % (N_SIDE, N_SIDE))
    wipe()
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=N_SIDE, y_subdivisions=N_SIDE)
    bm = bm_of(bpy.context.object)
    b = boundary_edge_ratio(bm)
    # N x N quads -> (N+1)^2 verts. Edges: (N+1) rows of N horizontals, plus
    # (N+1) columns of N verticals = 2N(N+1). Perimeter: 4N.
    faces = N_SIDE * N_SIDE
    edges = 2 * N_SIDE * (N_SIDE + 1)
    perim = 4 * N_SIDE
    check("grid faces", len(bm.faces), faces)
    check("grid total edges", b["total_edges"], edges)
    check("grid boundary edges", b["boundary_edges"], perim)
    check("grid BER = 4N / 2N(N+1) = 2/(N+1)", b["ber"],
          2.0 / (N_SIDE + 1), 1e-9)
    check("grid border loops", b["border_loops"], 1)
    bm.free()


def test_two_holes():
    print("\n-- grid with 2 INTERIOR faces deleted: 3 border loops --")
    wipe()
    w = 8
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=w, y_subdivisions=w)
    obj = bpy.context.object
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    # Faces are row-major: index = row*w + col. A face is interior only when
    # 0 < row < w-1 AND 0 < col < w-1. The first version of this test picked
    # index 27 in a 7-wide grid -- row 3, col 6, which is the LAST column, so
    # its rim merged with the outer perimeter and the count read 2. Pick by
    # (row, col) instead of by raw index so the choice stays legible.
    def at(row, col):
        assert 0 < row < w - 1 and 0 < col < w - 1, "face is not interior"
        return bm.faces[row * w + col]

    bmesh.ops.delete(bm, geom=[at(1, 1), at(5, 5)], context="FACES")
    bm.to_mesh(obj.data)
    bm.free()
    bm = bm_of(obj)
    b = boundary_edge_ratio(bm)
    # outer perimeter + one rim per hole
    check("holed grid border loops", b["border_loops"], 3)
    check("holed grid boundary edges (4w + 4 + 4)", b["boundary_edges"],
          4 * w + 8)
    bm.free()


def test_nonmanifold():
    print("\n-- non-manifold fin: one edge carrying 3 faces --")
    wipe()
    bpy.ops.mesh.primitive_plane_add()
    obj = bpy.context.object
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.verts.ensure_lookup_table()
    bm.edges.ensure_lookup_table()
    e = bm.edges[0]
    a = bm.verts.new((e.verts[0].co.x, e.verts[0].co.y, 1.0))
    c = bm.verts.new((e.verts[1].co.x, e.verts[1].co.y, 1.0))
    bm.faces.new((e.verts[0], e.verts[1], c, a))   # 2nd face on that edge
    d = bm.verts.new((e.verts[0].co.x, e.verts[0].co.y, -1.0))
    f = bm.verts.new((e.verts[1].co.x, e.verts[1].co.y, -1.0))
    bm.faces.new((e.verts[0], e.verts[1], f, d))   # 3rd face on that edge
    bm.to_mesh(obj.data)
    bm.free()
    bm = bm_of(obj)
    t = topology_score(bm)
    check("fin nonmanifold edges", t["nonmanifold_edges"], 1)
    bm.free()


def test_degenerate():
    print("\n-- collapsed quad: zero area must be caught --")
    wipe()
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=3, y_subdivisions=3)
    obj = bpy.context.object
    me = obj.data
    # Collapse one face onto a single point.
    vi = list(me.polygons[0].vertices)
    target = me.vertices[vi[0]].co.copy()
    for i in vi[1:]:
        me.vertices[i].co = target
    bm = bm_of(obj)
    t = topology_score(bm)
    ok = t["degenerate_faces"] >= 1
    print("  %-4s %-46s got %d" % ("OK" if ok else "FAIL",
                                   "collapsed quad flagged degenerate",
                                   t["degenerate_faces"]))
    if not ok:
        FAILURES.append("degenerate face not detected")
    bm.free()


def test_hausdorff():
    print("\n-- HD: sphere r=1.00 vs r=1.01 must read ~10 mm --")
    wipe()
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, segments=64, ring_count=32)
    inner = bpy.context.object
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1.01, segments=64, ring_count=32)
    outer = bpy.context.object

    bm_i, bm_o = bm_of(inner), bm_of(outer)

    same = hausdorff(bm_i, bm_i)
    check("sphere vs ITSELF mean mm", same["mean_mm"], 0.0, 1e-6)
    check("sphere vs ITSELF max mm", same["max_mm"], 0.0, 1e-6)

    h = hausdorff(bm_i, bm_o)
    # Both spheres are faceted the same way, so the gap is the radius
    # difference minus a shared sagitta -- a hair under 10 mm, not over.
    print("       mean %.3f mm | p95 %.3f mm | max %.3f mm"
          % (h["mean_mm"], h["p95_mm"], h["max_mm"]))
    check("shell gap mean mm ~10", h["mean_mm"], 10.0, 1.0)
    check("shell gap max mm ~10", h["max_mm"], 10.0, 1.5)

    # The point that matters: a PATCH compared one-way looks perfect. Cut the
    # inner sphere down to a cap and confirm the symmetric max catches it.
    bmesh.ops.delete(
        bm_i, geom=[f for f in bm_i.faces if f.calc_center_median().z < 0.5],
        context="FACES")
    bm_i.verts.ensure_lookup_table()
    one_way = hausdorff(bm_i, bm_o, symmetric=False)
    both = hausdorff(bm_i, bm_o, symmetric=True)
    # `max_mm` is deliberately one-way in both calls; the symmetric answer
    # lives in `hausdorff_mm`. That split is the point: a cap measured against
    # a whole body must still report its own lift-off in max_mm.
    check("one-way max is unaffected by symmetric=True",
          both["max_mm"], one_way["max_mm"], 1e-9)
    print("       cap one-way max %.2f mm | true Hausdorff %.2f mm"
          % (one_way["max_mm"], both["hausdorff_mm"]))
    ok = both["hausdorff_mm"] > one_way["max_mm"] * 5
    print("  %-4s %s" % ("OK" if ok else "FAIL",
                         "symmetric HD catches the missing 3/4 of the sphere"))
    if not ok:
        FAILURES.append("symmetric HD blind to partial coverage")

    bm_i.free()
    bm_o.free()


def main():
    for fn in (test_cube, test_plane, test_grid, test_two_holes,
               test_nonmanifold, test_degenerate, test_hausdorff):
        fn()
    print("\n" + "=" * 66)
    if FAILURES:
        print("  %d CHECK(S) FAILED -- the probe is not trustworthy:" % len(FAILURES))
        for f in FAILURES:
            print("    - " + f)
        raise SystemExit(1)
    print("  all checks passed -- metrics agree with derived ground truth")


if __name__ == "__main__":
    main()
