"""measure_skin_spectrum -- where does the colour variation LIVE, by scale.

Skin is not one signal. Texturing.xyz ships displacement as a MULTI-CHANNEL map
because real skin carries detail at three separate frequencies, and each one is
weighted on its own:

    macro  the big shading of muscle and bone -- the three thirds of the face
    meso   wrinkles, folds, eye bags, the nasolabial line
    micro  pores

Joan's verdict on skin v1 was "tiene un patron repetido". The hypothesis is that
v1 put ALL of its variation at MESH frequency: a per-vertex pore hash, which is
detail living at the frequency of the substrate that carries it. That reads as
woven cloth, never as skin -- and it is why removing it left the surface flat,
because macro and meso were never there to begin with.

This probe decides whether that hypothesis is true, before anything is repainted.

METHOD -- a Laplacian pyramid over the mesh graph:

    c_local(r) = colour blurred over radius r
    macro = c_local(R_BIG)   - c_global
    meso  = c_local(R_SMALL) - c_local(R_BIG)
    mesh  = c                - c_local(R_SMALL)

Each band gets its RMS energy. Healthy skin spreads energy across macro and
meso. Energy piled into `mesh` is the defect, and its share is the verdict.

The blur is iterated edge-neighbour averaging, not a KD-tree ball query. Same
result, and it stays inside numpy: diffusion is a random walk, so k steps reach
about `spacing * sqrt(k)`, which inverts to k = (radius / spacing)^2. A ball
query per vertex would be ~19k x thousands of neighbours in Python.

DISCRETE ZONES ARE EXCLUDED. Lips, brows, lashes, eyes, teeth, nails and scalp
are hard-stamped colour with intentionally sharp borders. Leaving them in would
dump their edges straight into the `mesh` band and the probe would score crisp
eyebrows as noise -- it would confirm the hypothesis for the wrong reason.

Usage:
    blender -b scene.blend --factory-startup --python-exit-code 1 \
        --python measure_skin_spectrum.py -- --obj char_warrior_male_mh
"""
from __future__ import annotations

import argparse
import sys

import bpy
import numpy as np

# Radii in metres, set by what THIS mesh can physically carry, not by anatomy.
#
# Measured on char_warrior_male_mh: median edge 4.07 mm on the head, 7.57 mm on
# the body. Nyquist puts the shortest representable wavelength at twice that --
# about 8 mm on the head. So:
#
#   a pore (~0.1 mm)             CANNOT EXIST on this mesh. Not close.
#   a fine wrinkle (~1 mm)       cannot exist either.
#   a nasolabial fold, an eye bag, the beard shadow (10-30 mm)  -> fits.
#   a facial third (60 mm+)                                      -> fits easily.
#
# That is the whole diagnosis of skin v1 in one line: the per-vertex pore hash
# was asking a 4 mm grid to draw a 0.1 mm feature, so what it actually drew was
# the grid. Micro is not underweighted here, it is UNREACHABLE -- it needs a
# normal map, which is a different decision (vertex paint vs UV) and not one to
# make sideways.
#
# A blur of radius r kills wavelengths under ~2r and passes those over ~4r, so
# these two radii cut the spectrum at roughly 20 mm and 120 mm.
R_MESO = 0.010
R_MACRO = 0.060

# Vertex groups that own a hard-stamped colour. Their borders are SUPPOSED to
# be sharp, so they are cut out of the measurement entirely.
DISCRETE_GROUPS = (
    "lips", "fingernails", "toenails", "nipple", "nippleTip", "scalp",
    "helper-upper-teeth", "helper-lower-teeth",
    "helper-l-eyelashes-1", "helper-l-eyelashes-2",
    "helper-r-eyelashes-1", "helper-r-eyelashes-2",
    "helper-l-eye", "helper-r-eye",
)


class masks_muted:
    """MASK modifiers off -- indices must map 1:1 to the base mesh."""

    def __init__(self, obj):
        self.obj = obj
        self.states: list[tuple] = []

    def __enter__(self):
        for m in self.obj.modifiers:
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


def vertex_colours(me, attr_name: str) -> np.ndarray:
    """(n, 3) linear colour per VERTEX, whatever domain it is stored in."""
    attr = me.color_attributes.get(attr_name)
    if attr is None:
        raise SystemExit("no colour attribute %r -- have: %s"
                         % (attr_name, [a.name for a in me.color_attributes]))
    n = len(me.vertices)
    raw = np.empty(len(attr.data) * 4, dtype=np.float32)
    attr.data.foreach_get("color", raw)
    raw = raw.reshape(-1, 4)[:, :3].astype(np.float64)

    if attr.domain == "POINT":
        return raw

    # FACE_CORNER -> average the corners that land on each vertex.
    loop_v = np.empty(len(me.loops), dtype=np.int32)
    me.loops.foreach_get("vertex_index", loop_v)
    sums = np.zeros((n, 3))
    counts = np.zeros(n)
    np.add.at(sums, loop_v, raw)
    np.add.at(counts, loop_v, 1.0)
    counts[counts == 0] = 1.0
    return sums / counts[:, None]


def edge_array(me) -> np.ndarray:
    e = np.empty(len(me.edges) * 2, dtype=np.int32)
    me.edges.foreach_get("vertices", e)
    return e.reshape(-1, 2)


def blur(colours: np.ndarray, edges: np.ndarray, steps: int) -> np.ndarray:
    """`steps` rounds of neighbour averaging over the edge graph."""
    n = len(colours)
    deg = np.zeros(n)
    np.add.at(deg, edges[:, 0], 1.0)
    np.add.at(deg, edges[:, 1], 1.0)
    deg[deg == 0] = 1.0

    out = colours.copy()
    for _ in range(steps):
        acc = np.zeros_like(out)
        np.add.at(acc, edges[:, 0], out[edges[:, 1]])
        np.add.at(acc, edges[:, 1], out[edges[:, 0]])
        # Keep half the vertex's own value: pure neighbour replacement on a
        # quad grid oscillates between the two checkerboard sublattices and
        # never converges to a blur.
        out = 0.5 * out + 0.5 * (acc / deg[:, None])
    return out


def steps_for(radius: float, spacing: float) -> int:
    """Diffusion reaches ~spacing*sqrt(k), so k = (radius/spacing)^2."""
    return max(1, int(round((radius / max(spacing, 1e-9)) ** 2)))


def rms(v: np.ndarray) -> float:
    return float(np.sqrt(np.mean(np.sum(v * v, axis=1))))


def discrete_mask(obj) -> np.ndarray:
    """True where the vertex belongs to a hard-stamped zone."""
    idx = {g.name: g.index for g in obj.vertex_groups}
    wanted = {idx[n] for n in DISCRETE_GROUPS if n in idx}
    n = len(obj.data.vertices)
    out = np.zeros(n, dtype=bool)
    if not wanted:
        return out
    for v in obj.data.vertices:
        for ge in v.groups:
            if ge.group in wanted and ge.weight > 0.01:
                out[v.index] = True
                break
    return out


def region_spacing(world: np.ndarray, edges: np.ndarray,
                   keep: np.ndarray) -> float:
    """Mean edge length among edges whose BOTH ends are in the region.

    Using the whole-body spacing to size the blur for a head-only measurement
    is wrong and it was wrong here: the body averages 12.54 mm but the head is
    6.49 mm, so the head was blurred with half the steps it needed and its
    `mesh` band was measured over the wrong window.
    """
    sub = edges[keep[edges[:, 0]] & keep[edges[:, 1]]]
    if len(sub) < 10:
        raise SystemExit("region has %d internal edges -- cannot size a blur"
                         % len(sub))
    return float(np.mean(np.linalg.norm(world[sub[:, 0]] - world[sub[:, 1]],
                                        axis=1)))


def analyse(label: str, col: np.ndarray, edges: np.ndarray, spacing: float,
            keep: np.ndarray) -> dict:
    """Split into bands on the FULL mesh, then score only `keep` vertices.

    Blurring must see the whole mesh -- masking first would make every excluded
    zone act as a wall and manufacture edges exactly where they were removed.
    `spacing` must be the spacing OF THE REGION, not of the whole object.
    """
    k_meso = steps_for(R_MESO, spacing)
    k_macro = steps_for(R_MACRO, spacing)
    if k_meso < 3:
        print("      WARNING: meso blur is only %d step(s) at %.2f mm spacing."
              " The mesh/meso split is barely resolved here -- read the mesh"
              " share as a floor, not a value." % (k_meso, spacing * 1000))

    local_meso = blur(col, edges, k_meso)
    local_macro = blur(local_meso, edges, k_macro - k_meso if k_macro > k_meso
                       else 1)

    sel = np.where(keep)[0]
    if len(sel) < 50:
        raise SystemExit("%s: only %d vertices survive the mask -- refusing to"
                         " report a number from that" % (label, len(sel)))
    global_mean = col[sel].mean(axis=0)

    band = {
        "macro": local_macro[sel] - global_mean,
        "meso": local_meso[sel] - local_macro[sel],
        "mesh": col[sel] - local_meso[sel],
    }
    energy = {k: rms(v) for k, v in band.items()}
    total = sum(energy.values()) or 1.0

    print("\n  --- %s ---   %d verts scored (%d excluded as hard-stamped)"
          % (label, len(sel), int((~keep).sum())))
    print("      blur steps: meso %d (r=%.0f mm) | macro %d (r=%.0f mm)"
          "  | mean edge %.2f mm"
          % (k_meso, R_MESO * 1000, k_macro, R_MACRO * 1000, spacing * 1000))
    for k in ("macro", "meso", "mesh"):
        bar = "#" * int(round(40 * energy[k] / total))
        print("      %-6s %7.5f   %5.1f%%  %s"
              % (k, energy[k], 100.0 * energy[k] / total, bar))
    return {k: energy[k] / total for k in energy}


def thirds(world: np.ndarray, normals: np.ndarray, keep: np.ndarray,
           col: np.ndarray) -> None:
    """The three thirds of the face, which is what "no flat colour" MEANS.

    Portrait canon, and both references confirm it (Skyrim Farkas, RDR Arthur
    close-up): skin colour tracks WHAT IS UNDERNEATH.

        forehead      more YELLOW -- thin skin over bone, few capillaries
        nose / cheek  more RED    -- the most vascular region of the face
        jaw / chin    COLDER      -- in a male, the beard sitting under the skin

    If the three come back the same colour, the paint is flat -- which is
    exactly the thing Joan asked not to happen. This is a separate question
    from the spectrum: paint can have plenty of macro energy and still put it
    in the wrong places.
    """
    face = keep & (normals[:, 1] < -0.30)          # front-facing only
    if face.sum() < 100:
        print("\n  thirds: only %d front-facing verts -- skipped" % face.sum())
        return
    z = world[face, 2]
    lo, hi = z.min(), z.max()
    # Split the FACE span, not the head span: the crown carries no face.
    cuts = [lo + (hi - lo) * f for f in (1 / 3, 2 / 3)]

    print("\n  --- the three thirds (front-facing skin only) ---")
    print("      face span z %.4f .. %.4f m" % (lo, hi))
    means = {}
    for name, sel in (
        ("jaw/chin", face & (world[:, 2] <= cuts[0])),
        ("nose/cheek", face & (world[:, 2] > cuts[0]) & (world[:, 2] <= cuts[1])),
        ("forehead", face & (world[:, 2] > cuts[1])),
    ):
        c = col[sel].mean(axis=0)
        means[name] = c
        s = c.sum() or 1.0
        print("      %-11s n=%-5d  RGB %.4f %.4f %.4f   redness %.4f  lum %.4f"
              % (name, int(sel.sum()), c[0], c[1], c[2], c[0] / s, c.mean()))

    print("      separation (euclidean in linear RGB):")
    keys = list(means)
    flat = True
    for i in range(len(keys)):
        for j in range(i + 1, len(keys)):
            d = float(np.linalg.norm(means[keys[i]] - means[keys[j]]))
            if d > 0.004:
                flat = False
            print("        %-11s vs %-11s  %.5f" % (keys[i], keys[j], d))
    if flat:
        print("      VERDICT: the three thirds are the SAME COLOUR. This is"
              " flat paint.")
    else:
        red = {k: v[0] / (v.sum() or 1.0) for k, v in means.items()}
        ok = red["nose/cheek"] > red["forehead"]
        print("      nose redder than forehead: %s  (%.4f vs %.4f)"
              % ("YES" if ok else "NO -- inverted vs anatomy",
                 red["nose/cheek"], red["forehead"]))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", default="char_warrior_male_mh")
    ap.add_argument("--attr", default="Col")
    ap.add_argument("--head-band", type=float, default=0.26,
                    help="metres below the crown that count as head")
    args = ap.parse_args(argv)

    obj = bpy.data.objects.get(args.obj)
    if obj is None:
        raise SystemExit("no object %r -- have: %s"
                         % (args.obj, sorted(o.name for o in bpy.data.objects
                                             if o.type == "MESH")))

    with masks_muted(obj):
        me = obj.data
        col = vertex_colours(me, args.attr)
        edges = edge_array(me)

        co = np.empty(len(me.vertices) * 3, dtype=np.float32)
        me.vertices.foreach_get("co", co)
        co = co.reshape(-1, 3).astype(np.float64)
        M = np.array(obj.matrix_world)
        world = co @ M[:3, :3].T + M[:3, 3]

        nrm = np.empty(len(me.vertices) * 3, dtype=np.float32)
        me.vertices.foreach_get("normal", nrm)
        nrm = nrm.reshape(-1, 3).astype(np.float64)
        # World normals use the TRANSPOSE of the inverse 3x3, and getting this
        # backwards once painted the belly onto the BACK (motor gotcha #1 in
        # paint_por_geometria.py).
        nw = nrm @ np.linalg.inv(M[:3, :3])
        nw /= np.maximum(np.linalg.norm(nw, axis=1, keepdims=True), 1e-9)

        keep = ~discrete_mask(obj)
        head = world[:, 2] > (world[:, 2].max() - args.head_band)

        print("\n  object %s -- %d verts, %d edges"
              % (obj.name, len(me.vertices), len(edges)))
        body = analyse("BODY", col, edges,
                       region_spacing(world, edges, keep), keep)
        face = analyse("HEAD ONLY", col, edges,
                       region_spacing(world, edges, keep & head), keep & head)
        thirds(world, nw, keep & head, col)

    print("\n  " + "=" * 62)
    print("  VERDICT -- the hypothesis under test is that v1 piled its"
          " variation")
    print("  at MESH frequency (per-vertex pore hash), which reads as woven"
          " cloth.")
    for label, r in (("body", body), ("head", face)):
        worst = max(r, key=r.get)
        print("    %-5s dominant band: %-5s (%.0f%%)   mesh share %.0f%%"
              % (label, worst, 100 * r[worst], 100 * r["mesh"]))
    print("  " + "=" * 62)


if __name__ == "__main__":
    main()
