"""probe_eye_targets -- what each MPFB eye dial ACTUALLY does, one at a time.

MPFB ships 68 eye targets and the warrior generator uses ZERO of them. Before
composing any into a ramp, each gets applied ALONE and measured, because target
names promise things the geometry may not deliver -- `forehead-nubian-decr`
flattened the cranial vault and `forehead-trans-forward` saturated past 0.50,
both found exactly this way.

WHY THE METRIC IS DELIBERATELY DUMB

Four attempts were made to measure palpebral aperture directly, which is the
number that would say whether the upper lid cuts the iris. All four failed the
same way: the first read 0.03 mm on a plainly open eye, and restricting to a
central column only moved it to 0.53 mm, against a real adult eye that opens
10-12 mm. The probe was blind; the eye was not shut.

A metric whose failure mode is a PLAUSIBLE WRONG NUMBER is worse than none. So
this measures what cannot be misread: how far a dial moves the eye region, and
in which direction. Whether the result looks right is then decided by looking
at the ramp, which is where that call belonged anyway.

    blender -b <blend> --python-exit-code 1 \
        --python probe_eye_targets.py -- --obj char_warrior_male_mh

NO --factory-startup: it skips Blender extensions, and MPFB is one.
"""
from __future__ import annotations

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy
import numpy as np

from _char_common import morphed_coords

# Candidates picked from the defects seen in the LIT render, not from the
# catalogue. Left side only -- the mesh is symmetric, so probing both sides
# doubles the runtime for the same answer.
CANDIDATES = [
    # the upper lid: the fix for "the iris is a full circle"
    "l-eye-eyefold-down", "l-eye-eyefold-up",
    "l-eye-eyefold-concave", "l-eye-eyefold-convex",
    "l-eye-eyefold-angle-down", "l-eye-eyefold-angle-up",
    # aperture
    "l-eye-height1-decr", "l-eye-height2-decr", "l-eye-height3-decr",
    "l-eye-height1-incr", "l-eye-height2-incr",
    # axis tilt: in a real face the inner corner sits LOWER than the outer
    "l-eye-corner1-down", "l-eye-corner1-up",
    "l-eye-corner2-down", "l-eye-corner2-up",
    # set the globe into the socket
    "l-eye-push1-in", "l-eye-push2-in",
    "l-eye-push1-out", "l-eye-push2-out",
    # under-eye ridge / bags
    "l-eye-bag-incr", "l-eye-bag-decr", "l-eye-bag-height-incr",
    # overall size -- the globe measured 29.8 mm against a real 24 mm
    "l-eye-scale-decr", "l-eye-scale-incr",
    # translation
    "l-eye-trans-down", "l-eye-trans-up", "l-eye-trans-in", "l-eye-trans-out",
]

_TS = None


def target_service():
    """Resolve TargetService. The sys.modules alias is the whole trick.

    MPFB installs as a Blender EXTENSION, so its module is
    `bl_ext.blender_org.mpfb`. Its own internals then import `mpfb.*`
    ABSOLUTELY, so importing under the extension name raises TypeError partway
    through -- which reads like a broken install rather than a namespace
    problem. Aliasing it into sys.modules first is what makes those internal
    imports resolve.

    Already solved in gen_char_warrior_male_mh.py:156 (boot_mpfb). Third time
    this session the answer was already in the repo; the other two were
    morphed_coords() and the shape-key gotcha.
    """
    global _TS
    if _TS is not None:
        return _TS
    import addon_utils
    addon_utils.enable("bl_ext.blender_org.mpfb", default_set=True,
                       persistent=True)
    import bl_ext.blender_org.mpfb as mpfb
    sys.modules["mpfb"] = mpfb
    from mpfb.services.targetservice import TargetService
    _TS = TargetService
    return _TS


def eye_region(obj):
    """Body vertices within 35 mm of the left eye centre, plus that centre."""
    W, _ = morphed_coords(obj)
    gi = {g.name: g.index for g in obj.vertex_groups}

    def idx(name):
        g = gi.get(name)
        return [] if g is None else [
            v.index for v in obj.data.vertices
            if any(ge.group == g and ge.weight > 0.01 for ge in v.groups)]

    eye, body = idx("helper-l-eye"), idx("body")
    if not eye or not body:
        raise SystemExit("need helper-l-eye and body vertex groups")
    centre = W[eye].mean(axis=0)
    B = np.array(body)
    near = B[np.linalg.norm(W[B] - centre, axis=1) < 0.035]
    if len(near) < 50:
        raise SystemExit("only %d verts near the eye -- region too tight"
                         % len(near))
    return near, centre


def sample(obj, near) -> np.ndarray:
    W, _ = morphed_coords(obj)
    return W[near]


def displacement(before: np.ndarray, after: np.ndarray) -> tuple:
    """(max mm, mean mm, direction of the vertex that moved most)."""
    d = after - before
    n = np.linalg.norm(d, axis=1)
    if n.max() < 1e-9:
        return 0.0, 0.0, "-"
    v = d[int(np.argmax(n))]
    ax = int(np.argmax(np.abs(v)))
    # -Y is forward on this model, +Z is up, +X is the character's left.
    axis_names = [("in", "out"), ("fwd", "back"), ("down", "up")]
    lo, hi = axis_names[ax]
    return (float(n.max()) * 1000.0, float(n.mean()) * 1000.0,
            hi if v[ax] > 0 else lo)


def apply_target(obj, name: str, weight: float) -> bool:
    """load_target, never set_target_value.

    set_target_value() only retunes a shape key that is ALREADY loaded; on a
    fresh human it does nothing and has_target() stays False. A silent no-op.
    """
    ts = target_service()
    path = ts.target_full_path(name)
    if not path or not os.path.isfile(path):
        return False
    ts.load_target(obj, path, weight=weight)
    bpy.context.view_layer.update()
    return True


def clear_target(obj, name: str) -> None:
    ts = target_service()
    path = ts.target_full_path(name)
    if path and os.path.isfile(path):
        ts.load_target(obj, path, weight=0.0)
    sk = obj.data.shape_keys
    if sk:
        for kb in sk.key_blocks:
            if name in kb.name:
                kb.value = 0.0
    bpy.context.view_layer.update()


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", default="char_warrior_male_mh")
    ap.add_argument("--weight", type=float, default=1.0)
    args = ap.parse_args(argv)

    obj = bpy.data.objects.get(args.obj)
    if obj is None:
        raise SystemExit("no object %r" % args.obj)

    target_service()
    near, _centre = eye_region(obj)
    base = sample(obj, near)
    print("")
    print("  eye region: %d body verts within 35 mm of the globe centre"
          % len(near))
    print("")
    print("  %-28s %9s %9s  %s"
          % ("target @ w=%.1f" % args.weight, "max_mm", "mean_mm", "dir"))
    print("  " + "-" * 62)

    rows, missing = [], []
    for name in CANDIDATES:
        if not apply_target(obj, name, args.weight):
            missing.append(name)
            continue
        try:
            after = sample(obj, near)
        finally:
            clear_target(obj, name)
        mx, mean, direction = displacement(base, after)
        rows.append((name, mx, mean, direction))
        flag = "" if mx > 0.05 else "   <- inert"
        print("  %-28s %9.2f %9.2f  %-5s%s"
              % (name, mx, mean, direction, flag))

    moved = [r for r in rows if r[1] > 0.05]
    print("")
    print("  %d/%d targets moved the region." % (len(moved), len(rows)))
    # CONTROL: a probe reporting nothing everywhere is far likelier to be
    # broken than 29 anatomical dials to be inert. Refuse the conclusion.
    if rows and not moved:
        raise SystemExit(
            "NO target moved anything. Either load_target is not applying or"
            " the region is wrong -- do NOT read this as 'the dials do"
            " nothing'.")
    if missing:
        print("  not found on disk: %s" % ", ".join(missing))
    print("")
    print("  ranked by effect:")
    for name, mx, _mean, d in sorted(rows, key=lambda r: -r[1])[:10]:
        print("    %-28s %6.2f mm max   %s" % (name, mx, d))


if __name__ == "__main__":
    main()
