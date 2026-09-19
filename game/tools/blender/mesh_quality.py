"""mesh_quality -- judge a mesh with numbers instead of by eye.

Three metrics, taken from the evaluation stage of the Hunyuan3D Studio
game-ready pipeline (arXiv 2509.12815). They gate every mesh that pipeline
emits, and they are cheap: pure geometry, no GPU, no model weights.

    BER  Boundary Edge Ratio  -- holes and loose borders
    TS   Topology Score       -- structural sanity for a deforming asset
    HD   Hausdorff Distance   -- did the derived mesh drift off the source

Why this file exists: geometry in this project has been judged by eye and been
wrong. The hair cap was called "casi bien" twice while it was floating off the
skull, and the proxy used to catch it (thickening in mm/side) measured the
wrong thing -- it was structurally blind to a ponytail hanging below the band.
HD answers that question directly and does not care where the drift happens.

HONEST NOTE ON TS: the paper names a "Topology Score" but does not publish the
formula. BER and HD below are the standard definitions. TS is OUR composition
-- four defects that actually break a deforming game asset, weighted and
documented here. Do not cite it as theirs.

Usage (inside Blender):
    blender -b scene.blend --python mesh_quality.py -- --obj char_warrior_male_mh
    blender -b scene.blend --python mesh_quality.py -- \
        --obj char_warrior_male_hair --against char_warrior_male_mh

Or import it: from mesh_quality import report; report(obj, ref=other)
"""
from __future__ import annotations

import argparse
import sys

import bpy
import bmesh
from mathutils.bvhtree import BVHTree


# --------------------------------------------------------------------------
# depsgraph hygiene
# --------------------------------------------------------------------------

class masks_muted:
    """Turn off MASK modifiers for the duration of a block.

    Earned twice. bmesh.from_object() and evaluated_get() both go through the
    depsgraph, so a body carrying a MASK arrives with 13380 verts against
    19158 in the base. Indices stop mapping, and the failure is SILENT -- an
    AO bake was skipped for a whole session, and scalp_area() fell to its bbox
    fallback on every single run, off by 37%.

    Anything that needs 1:1 correspondence with base vertices runs in here.
    """

    def __init__(self, *objs):
        self.objs = [o for o in objs if o is not None]
        self.states: list[tuple] = []

    def __enter__(self):
        for o in self.objs:
            for m in o.modifiers:
                if m.type == "MASK":
                    self.states.append((m, m.show_viewport))
                    m.show_viewport = False
        bpy.context.view_layer.update()
        return self

    def __exit__(self, *exc):
        for m, was in self.states:
            m.show_viewport = was
        bpy.context.view_layer.update()
        return False


def _bm_from(obj, evaluated: bool = True):
    """World-space bmesh. evaluated=False gives the raw cage."""
    bm = bmesh.new()
    if evaluated:
        dg = bpy.context.evaluated_depsgraph_get()
        bm.from_object(obj, dg)
    else:
        bm.from_mesh(obj.data)
    bm.transform(obj.matrix_world)
    bm.verts.ensure_lookup_table()
    bm.faces.ensure_lookup_table()
    bm.edges.ensure_lookup_table()
    return bm


# --------------------------------------------------------------------------
# BER -- Boundary Edge Ratio
# --------------------------------------------------------------------------

def boundary_edge_ratio(bm) -> dict:
    """Fraction of edges owned by exactly one face.

    A closed volume scores 0.0. Anything above that is an open border, which
    for us means one of two things: a legitimate open shell (a hair cap IS a
    surface, not a solid -- it will always have a rim), or a hole where the
    mesh was supposed to close.

    So BER is not pass/fail on its own. It is read against intent: a jump in
    BER between two versions of the SAME asset means a hole appeared. The loop
    count separates one honest open rim from twelve punctures.
    """
    total = len(bm.edges)
    if total == 0:
        raise ValueError("mesh has no edges -- nothing to measure")
    boundary = [e for e in bm.edges if len(e.link_faces) == 1]
    return {
        "ber": len(boundary) / total,
        "boundary_edges": len(boundary),
        "total_edges": total,
        "border_loops": _count_border_loops(boundary),
    }


def _count_border_loops(boundary_edges) -> int:
    """Connected components of the boundary-edge graph."""
    by_index = {e.index: e for e in boundary_edges}
    remaining = set(by_index)
    loops = 0
    while remaining:
        loops += 1
        stack = [remaining.pop()]
        while stack:
            e = by_index[stack.pop()]
            for v in e.verts:
                for nb in v.link_edges:
                    if nb.index in remaining:
                        remaining.discard(nb.index)
                        stack.append(nb.index)
    return loops


# --------------------------------------------------------------------------
# TS -- Topology Score  (OUR composition, see module docstring)
# --------------------------------------------------------------------------

# Degenerate below this area, in square metres. A 0.1 mm triangle on a human
# is not detail, it is a vertex that failed to merge.
DEGENERATE_AREA = 1e-8

# A quad corner this far out of plane, relative to the face span, will shade
# as two visibly different halves once the engine triangulates it.
PLANARITY_TOL = 0.02


def topology_score(bm) -> dict:
    """0.0 (broken) .. 1.0 (clean), plus the four raw defect counts.

    The four defects, and why each one specifically breaks a GAME asset:

      non-manifold edges  -- an edge shared by 3+ faces. Normals become
          undefined, so lighting flips and the exporter may split the mesh.
      degenerate faces    -- zero area. No usable normal, and NaN tangents on
          export, which shows up as a black shard in Godot.
      irregular valence   -- interior quad vertices whose neighbour count is
          not 4. Poles are legitimate and unavoidable (you cannot cover a
          sphere in pure quads), so this is scored as a RATE, never a count.
      non-planar quads    -- a quad whose corners do not lie in a plane gets
          triangulated along an arbitrary diagonal, and the two halves shade
          differently. Reads as a crease that moves when the model deforms.

    The weights are ours and deliberately uneven: non-manifold and degenerate
    are hard errors that break export, so they dominate. Valence and planarity
    are quality signals -- bad, but the asset still ships.
    """
    nonmanifold = sum(1 for e in bm.edges if len(e.link_faces) > 2)
    degenerate = sum(1 for f in bm.faces if f.calc_area() < DEGENERATE_AREA)

    interior = [v for v in bm.verts
                if not v.is_boundary and not v.is_wire and v.link_faces]
    irregular = sum(1 for v in interior if len(v.link_edges) != 4)
    valence_rate = irregular / len(interior) if interior else 0.0

    quads = [f for f in bm.faces if len(f.verts) == 4]
    nonplanar = 0
    for f in quads:
        a, b, c, d = (v.co for v in f.verts)
        # Distance of the 4th corner from the plane of the first three,
        # normalised by face span -- an absolute threshold would flag every
        # large face and forgive every small one.
        span = max((a - c).length, (b - d).length)
        if span > 0 and abs((d - a).dot(f.normal)) / span > PLANARITY_TOL:
            nonplanar += 1
    planar_rate = nonplanar / len(quads) if quads else 0.0

    score = 1.0
    score -= min(0.40, 40.0 * nonmanifold / max(1, len(bm.edges)))
    score -= min(0.40, 40.0 * degenerate / max(1, len(bm.faces)))
    score -= 0.12 * valence_rate
    score -= 0.08 * planar_rate
    return {
        "ts": max(0.0, score),
        "nonmanifold_edges": nonmanifold,
        "degenerate_faces": degenerate,
        "irregular_valence": irregular,
        "valence_rate": valence_rate,
        "nonplanar_quads": nonplanar,
        "planar_rate": planar_rate,
        "interior_verts": len(interior),
        "quads": len(quads),
        "tris": sum(1 for f in bm.faces if len(f.verts) == 3),
        "ngons": sum(1 for f in bm.faces if len(f.verts) > 4),
    }


# --------------------------------------------------------------------------
# HD -- Hausdorff Distance
# --------------------------------------------------------------------------

def hausdorff(bm_a, bm_b, symmetric: bool = True) -> dict:
    """Distance from mesh A to the SURFACE of mesh B, in millimetres.

    Point-to-surface via BVH, not vertex-to-vertex. Vertex-to-vertex is the
    easy version and it lies exactly where we need the truth: a dense cap over
    a sparse skull reports a gap that is really just the nearest vertex being
    far away along a face passing right under the point.

    Reported three ways on purpose:
      max  -- the textbook Hausdorff. One bad vertex moves it, which is useful
              for catching a spike and useless for judging overall fit.
      p95  -- where the body of the surface actually sits.
      mean -- drift.

    For the hair cap against the skull, mean answers "is it glued down" and
    max answers "is anything poking through".
    """
    tree_b = BVHTree.FromBMesh(bm_b)
    d_ab = _distances(bm_a, tree_b)
    if not d_ab:
        raise ValueError("mesh A has no vertices to sample")
    out = {
        "max_mm": max(d_ab) * 1000.0,
        "p95_mm": _percentile(d_ab, 0.95) * 1000.0,
        "mean_mm": sum(d_ab) / len(d_ab) * 1000.0,
        "samples": len(d_ab),
    }
    if symmetric:
        tree_a = BVHTree.FromBMesh(bm_a)
        d_ba = _distances(bm_b, tree_a)
        if d_ba:
            # True Hausdorff is the max of BOTH directions, and it is reported
            # as `hausdorff_mm`. But it is NOT folded into `max_mm`: when A is
            # a part of B (a hair cap over a whole body), the reverse leg is
            # dominated by the feet and swallows the only number that answers
            # "how far does the cap lift off the skull". Keep the legs apart.
            out["max_mm_reverse"] = max(d_ba) * 1000.0
            out["hausdorff_mm"] = max(out["max_mm"], out["max_mm_reverse"])
    return out


def _distances(bm, tree) -> list[float]:
    out = []
    for v in bm.verts:
        hit = tree.find_nearest(v.co)
        if hit[0] is not None:
            out.append(hit[3])
    return out


def _percentile(values: list[float], q: float) -> float:
    s = sorted(values)
    if not s:
        return 0.0
    return s[min(len(s) - 1, int(round(q * (len(s) - 1))))]


# --------------------------------------------------------------------------
# report
# --------------------------------------------------------------------------

def report(obj, ref=None, evaluated: bool = True) -> dict:
    """Run all three and print. ref enables HD."""
    with masks_muted(obj, ref):
        bm = _bm_from(obj, evaluated)
        try:
            res = {"object": obj.name}
            res.update(boundary_edge_ratio(bm))
            res.update(topology_score(bm))
            res["verts"] = len(bm.verts)
            res["faces"] = len(bm.faces)

            if ref is not None:
                bm_ref = _bm_from(ref, evaluated)
                try:
                    res["hd_against"] = ref.name
                    res.update(hausdorff(bm, bm_ref))
                finally:
                    bm_ref.free()
        finally:
            bm.free()

    _print(res)
    return res


def _print(r: dict) -> None:
    print("\n  === %s ===  %d verts / %d faces  (%d quad, %d tri, %d ngon)"
          % (r["object"], r["verts"], r["faces"],
             r["quads"], r["tris"], r["ngons"]))
    print("  BER  %.4f   %d/%d boundary edges in %d border loop(s)"
          % (r["ber"], r["boundary_edges"], r["total_edges"],
             r["border_loops"]))
    print("  TS   %.4f   nonmanifold %d | degenerate %d | valence %d/%d"
          " (%.1f%%) | nonplanar quads %d (%.1f%%)"
          % (r["ts"], r["nonmanifold_edges"], r["degenerate_faces"],
             r["irregular_valence"], r["interior_verts"],
             100.0 * r["valence_rate"], r["nonplanar_quads"],
             100.0 * r["planar_rate"]))
    if "hd_against" in r:
        print("  HD   %s -> %s   mean %.2f mm | p95 %.2f mm | max %.2f mm"
              "  (%d samples)"
              % (r["object"], r["hd_against"], r["mean_mm"], r["p95_mm"],
                 r["max_mm"], r["samples"]))
        if "max_mm_reverse" in r:
            print("       %s -> %s   max %.2f mm"
                  % (r["hd_against"], r["object"], r["max_mm_reverse"]))
            print("       true (symmetric) Hausdorff  %.2f mm"
                  % r["hausdorff_mm"])
            print("       NOTE: when the measured object is a PART of the"
                  " reference, read the first line only --")
            print("             the reverse leg just measures how far the"
                  " rest of the body is.")


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", required=True, help="object to measure")
    ap.add_argument("--against", default=None,
                    help="reference object; enables HD")
    ap.add_argument("--raw", action="store_true",
                    help="measure the cage instead of the evaluated mesh")
    args = ap.parse_args(argv)

    obj = bpy.data.objects.get(args.obj)
    if obj is None:
        raise SystemExit("no object named %r -- have: %s"
                         % (args.obj, sorted(o.name for o in bpy.data.objects
                                             if o.type == "MESH")))
    ref = None
    if args.against:
        ref = bpy.data.objects.get(args.against)
        if ref is None:
            raise SystemExit("no reference object named %r -- have: %s"
                             % (args.against,
                                sorted(o.name for o in bpy.data.objects
                                       if o.type == "MESH")))

    report(obj, ref, evaluated=not args.raw)


if __name__ == "__main__":
    main()
